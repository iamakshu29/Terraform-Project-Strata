# Strata — Terraform Project Checklist

## Phase 1 — Flat Working Code ✅ COMPLETE

### Networking
- [x] VPC, IGW, public/private/data subnets (3 AZs)
- [x] NAT Gateways (2) + Elastic IPs
- [x] Per-AZ private route tables using `az_to_nat` map
- [x] Data subnets isolated (no internet route)
- [x] NACLs (public, private, data) with dynamic rules
- [x] VPC Endpoints — S3 Gateway + 8 interface endpoints (ECR, SSM, Secrets Manager, KMS, Logs)

### Security
- [x] Security Groups (ALB, EC2, ECS, RDS, Redis, EFS, Bastion)
- [x] Bastion: SSM Session Manager only — no SSH ingress, no key pair
- [x] KMS CMK (RDS, S3, EBS, EFS, ElastiCache, SSM params)
- [x] Secrets Manager (RDS credentials)
- [x] ACM certificate with Route 53 DNS auto-validation
- [x] ALB HTTPS listeners + HTTP→HTTPS redirect
- [x] S3 buckets: all public access blocked, KMS encrypted

### IAM
- [x] 4 roles: EC2, ECS task execution, ECS task, VPC Flow Logs
- [x] Custom policies per role (S3, Secrets Manager, SSM, RDS, ECR, X-Ray)
- [x] `AmazonSSMManagedInstanceCore` managed policy on EC2 role

### Database & Cache
- [x] RDS PostgreSQL Multi-AZ, KMS encrypted, Secrets Manager credentials
- [x] ElastiCache Redis replication group, KMS at-rest + TLS in-transit, auto failover
- [x] DB + Redis in data subnets (no internet route)

### Compute
- [x] ALB (public, deletion protection, access logs to S3)
- [x] Two target groups: instance (ASG) + ip (ECS Fargate)
- [x] ASG + Launch Template (Ubuntu 22.04, EBS KMS, IAM profile, SSM access)
- [x] ASG target tracking scaling policy (ALBRequestCountPerTarget)
- [x] ECS Cluster (Container Insights), Task Definition, Service
- [x] EFS file system (KMS encrypted) + mount targets (one per private AZ)
- [x] Service Discovery HTTP namespace
- [x] Bastion EC2 (SSM Session Manager, no SSH)
- [x] ECR repository (KMS, scan on push, lifecycle policies)

### DNS
- [x] Route 53 public hosted zone
- [x] ACM validation CNAME records (auto-created)
- [x] ALB alias A record

### Observability
- [x] CloudWatch Log Group (30-day retention)
- [x] VPC Flow Logs → CloudWatch
- [x] CloudWatch Metric Alarm (ALB 5XX)
- [x] CloudWatch Dashboard (ALB, RDS, Redis, ECS, ASG widgets)
- [x] CloudTrail → S3 logging bucket

### Storage & Audit
- [x] S3 app bucket (versioning, lifecycle IA→Glacier→expire, KMS, bucket policy)
- [x] S3 logging bucket (single consolidated policy: S3 logs + CloudTrail + ALB logs)
- [x] SSM Parameter Store (SecureString/KMS): DB, S3, Redis, ALB endpoints

### Backend + State
- [x] S3 state bucket (KMS, versioning, public access blocked, prevent_destroy)
- [x] S3 native locking (`use_lockfile = true`, Terraform ≥ 1.10 — no DynamoDB needed)
- [ ] Uncomment backend block in `provider.tf` and run `terraform init -migrate-state`
- [ ] Set `domain_name` in tfvars to your real domain before first apply
- [ ] Set Route 53 NS records at your domain registrar after first apply

---

## Phase 2 — Multi-Environment

- [ ] Create directory structure: `dev/`, `staging/`, `prod/`
- [ ] Separate `terraform.tfvars` per environment
- [ ] Separate S3 state key per environment (`strata/dev/`, `strata/staging/`, `strata/prod/`)
- [ ] Verify dev deploys cleanly
- [ ] Verify staging deploys cleanly
- [ ] Verify prod deploys cleanly
- [ ] Set AWS billing alert at $5 before every apply session

---

## Phase 3 — Modularize

- [ ] Extract modules: `vpc/`, `compute/`, `data/`, `iam/`, `observability/`
- [ ] Root module calls all child modules
- [ ] Module outputs wired to SSM Parameter Store
- [ ] Publish to private Terraform registry or local `modules/` directory

---

## Phase 4 — Dynamic Refactor

- [ ] Convert SG rules to dynamic ingress/egress blocks driven by variables
- [ ] Programmatic CIDR generation via `for` expressions
- [ ] Consolidate tag logic into a single local
- [ ] Make modules reusable enough for a second project to consume

---

## Phase 5 — CI/CD Pipeline + API Integration

### Option 1 — Terraform CI/CD Pipeline (GitHub Actions)
- [ ] GitHub Actions workflow — `terraform fmt` and `terraform validate` on every push
- [ ] GitHub Actions workflow — `terraform plan` on every PR, post output as PR comment
- [ ] GitHub Actions workflow — `terraform apply` on merge to main
- [ ] Store AWS credentials as GitHub Secrets (never in code)
- [ ] Store Terraform state in S3, lock with DynamoDB (reuse Phase 2 backend)
- [ ] Add plan diff check — fail PR if plan has unexpected destroys
- [ ] Test full PR → plan → merge → apply cycle

### Option 2 — FastAPI App for Infrastructure Management
- [ ] FastAPI endpoint — `POST /environment` triggers terraform apply for a new env
- [ ] FastAPI endpoint — `DELETE /environment/{name}` triggers terraform destroy
- [ ] FastAPI endpoint — `GET /environment/{name}` returns terraform output (VPC ID, subnet IDs etc)
- [ ] Run Terraform as subprocess from FastAPI using Python `subprocess` module
- [ ] Stream terraform output back to API response
- [ ] Add basic auth to protect endpoints
- [ ] Dockerize the FastAPI app
- [ ] Deploy FastAPI app on the App Server EC2 created in Phase 1

---

## GitHub Structure

- [ ] Create branch `phase/flat` — commit current working flat code
- [ ] Create branch `phase/modular` — commit after Phase 3
- [ ] Merge final dynamic version into `main`

---

## Cost Reminder

> **Always run `terraform destroy` after testing.**
> Estimated cost if left running:
> - NAT Gateways (x2): ~$65/month
> - RDS db.t3.medium Multi-AZ: ~$100-120/month
> - EC2 instances: negligible
>
> Set a **AWS billing alert at $5** before every apply session.