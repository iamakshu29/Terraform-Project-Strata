# Strata Terraform Infrastructure — Current Status

**Phase 1 (flat working code) is complete.** All resources are implemented and `terraform validate` passes.

---

## ✅ COMPLETE

### Networking
- VPC `10.0.0.0/16`, IGW, 9 subnets across 3 AZs (public / private / data)
- NAT Gateways (2) — `ap-south-1a` and `ap-south-1b`; `ap-south-1c` routes through `ap-south-1b` via `az_to_nat` local
- Per-AZ private route tables (one per AZ, each with its own NAT route)
- Data subnets isolated — no internet route
- NACLs (public, private, data) with dynamic ingress/egress blocks
- VPC Endpoints: S3 Gateway (free) + 8 Interface endpoints (ECR API, ECR DKR, Secrets Manager, SSM, SSM Messages, EC2 Messages, CloudWatch Logs, KMS)

### Security & Encryption
- Security Groups: ALB (80+443), EC2, ECS, RDS, Redis, EFS, Bastion (no SSH — SSM only)
- KMS CMK with rotation — used by RDS, S3, EBS, EFS, ElastiCache, SSM Parameter Store
- Secrets Manager — RDS credentials (username + password)
- ACM public certificate with wildcard SAN, DNS-validated automatically via Route 53
- ALB: HTTPS listeners (8443 instance, 8442 ECS) + HTTP→HTTPS redirect on port 80
- TLS policy: `ELBSecurityPolicy-TLS13-1-2-2021-06`
- All S3 buckets: public access blocked, KMS encrypted, versioned

### IAM
- 4 roles: `role_ec2_instance`, `role_ecs_task_execution`, `role_ecs_task`, `role_vpc_flow_log`
- Custom inline policies per role (S3, Secrets Manager, SSM, RDS, ECR, CloudWatch, X-Ray)
- `AmazonSSMManagedInstanceCore` managed policy on EC2 role (enables SSM Session Manager)
- IAM instance profile attached to both bastion and ASG launch template

### Database & Cache
- RDS PostgreSQL `db.t3.medium` Multi-AZ, KMS encrypted, Secrets Manager credentials, deletion protection on
- ElastiCache Redis replication group — 2 nodes, KMS at-rest + TLS in-transit, automatic failover, 7-day snapshots
- Both in isolated data subnets (no internet route)
- DB subnet group + ElastiCache subnet group across all 3 data subnet AZs

### Compute
- ALB (public, deletion protection, access logs → S3 logging bucket)
- 2 target groups: `strataInstance` (type=instance, ASG) + `strataECS` (type=ip, Fargate)
- Health checks on both target groups (`/health`, 200-299)
- ASG + Launch Template: Ubuntu 22.04 (dynamic AMI), `t3.large`, EBS gp3 KMS encrypted, SSM access
- ASG target tracking scaling policy on `ALBRequestCountPerTarget` (threshold 1000 req/min)
- ECS Cluster (Container Insights enabled), Task Definition (FARGATE, awsvpc), Service (service connect, alarms, LB)
- EFS file system (KMS encrypted, lifecycle to IA after 30 days) + mount targets in all 3 private subnet AZs
- ECR repository (KMS, IMMUTABLE tags, scan on push, lifecycle: keep last 30, archive after 90 days)
- Bastion EC2 in public subnet — SSM Session Manager only (no SSH key, no port 22 open)
- Service Discovery HTTP namespace

### DNS
- Route 53 public hosted zone for `var.domain_name`
- ACM DNS validation CNAME records (auto-created by Terraform)
- ALB alias A record

### Observability
- CloudWatch Log Group (`strata-cloudwatch-log-group`, 30-day retention)
- VPC Flow Logs → CloudWatch (all traffic)
- CloudWatch Metric Alarm (ALB 5XX, dynamic metric query block)
- CloudWatch Dashboard (`strata-<env>`) — 6 widgets: ALB requests/errors/latency, RDS CPU/connections, Redis memory/connections, ECS CPU/memory, ASG healthy hosts
- CloudTrail → S3 logging bucket (with integrity check conditions)

### Storage & Audit
- S3 app bucket (`strata_bucket`) — versioning, lifecycle (IA 30d → Glacier 90d → expire 365d), KMS, bucket policy for ECS+EC2 roles
- S3 logging bucket — single consolidated bucket policy covering S3 server access logging + CloudTrail + ALB access logs
- SSM Parameter Store (SecureString/KMS) — DB endpoint, S3 buckets, Redis primary+reader endpoints, ALB DNS

### Remote State
- S3 state bucket (KMS encrypted, versioned, `prevent_destroy`, account-ID suffixed name)
- S3 native locking (`use_lockfile = true`) — requires Terraform ≥ 1.10, no DynamoDB needed

---

## ⚠️ MANUAL STEPS BEFORE FIRST APPLY

1. **Set `domain_name`** in `terraform.tfvars` to a domain you own (not `strata.example.com`)
2. **First apply** with local backend to create state bucket + all resources
3. **After first apply** — copy `route53_name_servers` output to your domain registrar's NS records
4. **Uncomment the `backend "s3"` block** in `provider.tf`, fill in the state bucket name from the `state_bucket_name` output
5. **Run `terraform init -migrate-state`** to move local state into S3

---

## ❌ INTENTIONALLY DEFERRED (future phases)

| Item | Phase | Reason deferred |
|---|---|---|
| Aurora cluster (`aws_rds_cluster`) | Phase 4 refactor | `aws_db_instance` is simpler for learning; Aurora adds ~3x cost |
| Secrets Manager rotation lambda | Phase 3+ | Requires Lambda + rotation schedule; significant complexity |
| GitHub Actions OIDC role | Phase 5 CI/CD | Not needed until pipeline phase |
| WAF v2 WebACL | Phase 4+ | Optional security layer; adds cost |
| CloudWatch Dashboard as `templatefile()` | Phase 3 | Currently inline `jsonencode` — works fine for flat code |
| Multi-env directory structure | Phase 2 | Current flat code is single-env by design |
| Terraform modules | Phase 3 | Flat first, then extract modules |
