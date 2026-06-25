# Strata Terraform Infrastructure — Status & What's Left

**Project Goal:** Production-grade multi-tier AWS infrastructure across 3 AZs (ap-south-1) using Terraform.

**Current Spec Target:** Align with the comprehensive AWS spec provided (VPC, ALB+ECS+ASG, RDS Aurora, ElastiCache, observability, IAM, KMS, Secrets Manager).

---

## ✅ COMPLETED (Phase 1 — Networking & Core Infra)

### Networking
- ✅ VPC (`10.0.0.0/16`)
- ✅ Internet Gateway
- ✅ Public Subnets (3 AZs: `10.0.1/2/3.0/24`)
- ✅ Private Subnets (3 AZs: `10.0.11/15/19.0/22`)
- ✅ Data Subnets (3 AZs, but only 2 currently used for RDS: `10.0.101/102/103.0/24`)
- ✅ NAT Gateways (2 only, in ap-south-1a and ap-south-1b)
- ✅ Elastic IPs for NAT GWs
- ✅ Public Route Tables + IGW routes
- ✅ Private Route Tables + NAT routes (with `az_to_nat` map handling the 3rd AZ routing through ap-south-1b NAT)
- ✅ Data Route Tables (no outbound internet route)
- ✅ Route Table Associations (all 3 tiers)
- ✅ NACLs (public, private, data) with dynamic ingress/egress blocks

### Security Groups
- ✅ SG for ALB (port 443 from `0.0.0.0/0`)
- ✅ SG for EC2 (port 8080 from ALB SG)
- ✅ SG for RDS (port 5432 from EC2 and ECS SGs)
- ✅ SG for Bastion (port 22, currently open)
- ✅ SG for ECS (port 8080 from ALB SG) — *declared but not yet used*
- ✅ SG for Redis (port 6379 from EC2 and ECS SGs) — *declared but not yet used*
- ⚠️ **Issue:** Bastion SG allows `0.0.0.0/0:22` — needs to be restricted to your IP

### KMS & Encryption
- ✅ KMS CMK for general encryption (RDS, S3, EBS)
- ✅ KMS Alias

### Secrets Manager
- ✅ Secrets storage (RDS username + password)
- ✅ Secret version
- ⚠️ **TODO:** Remove `aws_secretsmanager_secret_policy` if same-account access only

### IAM (Partial)
- ✅ IAM Policy: `read_secrets_policy` (GetSecretValue on Secrets Manager)
- ✅ IAM Roles declared:
  - `role_ec2_instance` — for EC2
  - `role_ecs_task` — for ECS tasks
  - `role_vpc_flow_log` — for VPC Flow Logs
- ✅ IAM Policy Attachments (policies attached to roles)
- ✅ IAM Instance Profile (for EC2 to assume role)
- ⚠️ **Issue:** Complex policy structure in `iam_role_and_policy.tf` needs verification; locals map might not work as expected

### Database Layer
- ✅ DB Subnet Group (across data subnets)
- ✅ RDS PostgreSQL (Multi-AZ, `db.t3.medium`)
  - ✅ Encrypted with KMS CMK
  - ✅ Credentials from Secrets Manager (not hardcoded)
  - ✅ 7-day backup retention
  - ✅ `deletion_protection = true`
  - ✅ `skip_final_snapshot = false` (will require manual intervention on destroy)

### Compute Layer (Partial)
- ✅ ALB
  - ✅ Public subnets across 3 AZs
  - ✅ Deletion protection enabled
  - ⚠️ **Missing:** HTTPS listener (port 443), HTTP→HTTPS redirect, ACM certificate, WAF v2 attachment, access logs to S3
- ✅ ALB Target Group — now **2 separate target groups**:
  - ✅ `strata_instance` (`target_type = "instance"`) — for ASG/EC2
  - ✅ `strata_ecs` (`target_type = "ip"`) — for ECS Fargate (awsvpc requires ip)
  - ⚠️ **Missing:** Health check config, stickiness settings on both

- ✅ ASG + Launch Template
  - ✅ Latest Ubuntu 22.04 AMI (via data source, no hardcoded ID)
  - ✅ Across private subnets (3 AZs)
  - ✅ Mixed instance policy (on-demand + spot capable)
  - ✅ EBS encryption with KMS
  - ✅ IAM instance profile attached
  - ✅ Attached to ALB target group
  - ⚠️ **Missing:** 
    - Target tracking scaling policy (should scale on ALBRequestCountPerTarget)
    - Lifecycle hook for graceful connection draining on termination
    - SSM agent bootstrap in user data (no SSH keypair should be needed)

- ⚠️ **Bastion Host (EC2 in public subnet)**
  - ✅ Deployed in public subnet (ap-south-1a)
  - ✅ Associated public IP
  - ✅ Attached EBS volume
  - ⚠️ **Issue:** SSH key pair attached; should either restrict SG to your IP or remove SSH entirely (use SSM)

- ⚠️ **App Server (EC2 in private subnet)**
  - ⚠️ **Missing:** Not yet deployed separately; ASG handles this role
  - ⚠️ **Would need:** Restrict SSH to Bastion SG only (not directly from internet)

- ⚠️ **ECS Fargate (In Progress)**
* KEEP a FLOW Diagram for it ALSO
  - ✅ ECS Cluster (`aws_ecs_cluster`, Container Insights enabled, `for_each` over `var.ecs_cluster`)
  - ✅ ECS Task Definition (`aws_ecs_task_definition`, FARGATE, `awsvpc`, dynamic containers via `for` expression, dynamic volumes via `dynamic "volume"`)
  - ✅ ECS Service (`aws_ecs_service` with service connect, load balancer block, alarms block, network_configuration)
  - ✅ EFS (`aws_efs_file_system`, encrypted with KMS, lifecycle policy)
  - ✅ Service Discovery HTTP Namespace (`aws_service_discovery_http_namespace` for internal service-to-service DNS)
  - ✅ `service_to_task` / `service_to_cluster` / `service_to_namespace` locals for cross-resource wiring
  - ⚠️ **Still to fix:**
    - `depends_on` references wrong resource (`aws_iam_role_policy.foo` doesn't exist)
    - `aws_cloudwatch_log_group.example` → should be `strata_log_group`
    - `data.aws_region.current.name` — data source not declared in `data.tf`
    - `execution_role_arn` and `task_role_arn` — empty strings, need real IAM role ARNs
    - `network_configuration` subnets and security_groups — still empty `[]`
    - `locals.` typo → `local.` (2 places in service resource)
  - ❌ ECR Repository (image scanning + lifecycle policy)
  - ❌ `role_ecs_task_execution` missing from `assume_role_policy` in tfvars

### Storage Layer
- ✅ Main S3 bucket
  - ✅ Versioning enabled
  - ✅ Public access blocked (all 4 settings)
  - ✅ KMS encryption
  - ✅ Lifecycle rules (IA after 30 days, Glacier after 90)
  
- ✅ Logging S3 bucket (for ALB/CloudTrail logs)
  - ⚠️ Versioning enabled
  - ⚠️ Public access blocked
  - ⚠️ Bucket policy allowing CloudWatch Logs to write
  - ⚠️ S3 logging configured (destination for access logs)

### Observability
- ✅ CloudWatch Log Group (`strata-cloudwatch-log-group`)
  - ✅ 30-day retention
  
- ✅ VPC Flow Logs
  - ✅ Enabled on VPC
  - ✅ Published to CloudWatch Logs
  - ✅ All traffic (`traffic_type = ALL`)
  
- ⚠️ **Missing:**
  - CloudWatch Metric Alarms (ALB 5XX, ECS CPU, RDS connections, Redis memory)
  - CloudWatch Dashboard (as JSON templatefile)
  - Container Insights on ECS cluster
  - X-Ray tracing setup
  - CloudTrail (account-level API audit)

### SSM Parameter Store
- ✅ Parameters created for:
  - DB endpoint
  - S3 bucket name
  - ALB DNS name
  - ⚠️ **Missing:** Redis endpoint (commented out)

---

## ❌ NOT STARTED (Critical Gaps)

### ElastiCache Redis — COMPLETELY MISSING
**Spec requirement:** Redis cluster (multi-AZ, no cluster mode for now)

- ❌ ElastiCache Subnet Group
- ❌ Redis Cluster
- ❌ Auth token (stored in Secrets Manager)
- ❌ KMS encryption at-rest
- ❌ In-transit encryption
- ❌ Parameter store endpoint

### ACM Certificate — MISSING
**Spec requirement:** HTTPS listener on ALB (port 443)

- ❌ ACM Certificate
- ❌ ALB HTTPS listener (port 443)
- ❌ ALB HTTP→HTTPS redirect listener (port 80)
- ❌ ALB access logs to S3

### WAF v2 — MISSING
**Spec requirement:** Web ACL attached to ALB

- ❌ WAF v2 IP Set (if custom rules needed)
- ❌ WAF v2 Web ACL
- ❌ WAF v2 Association to ALB

### CloudTrail — MISSING
**Spec requirement:** Account-level API audit trail

- ❌ CloudTrail
- ❌ CloudTrail logging to S3 with integrity validation

### Advanced IAM — PARTIALLY MISSING
**Spec requirement:** Granular role separation

- ✅ Basic roles created but needs cleanup
- ❌ Dedicated KMS key admin role (separate from key usage role)
- ❌ `ecsTaskExecutionRole` for ECS
- ❌ GitHub Actions OIDC role (for CI/CD)
- ❌ Secrets Manager rotation lambda role
- ⚠️ **Issue:** Current IAM policy structure is complex; needs verification that policies are correctly attached

### Advanced RDS — PARTIALLY MISSING
**Spec requirement:** Aurora PostgreSQL Cluster (not single instance)

- ❌ Convert from `aws_db_instance` to `aws_rds_cluster` + `aws_rds_cluster_instance`
- ❌ Custom RDS parameter group (with `log_min_duration_statement = 1000` for slow query logging)
- ❌ RDS automated backups with lifecycle rules
- ❌ Secrets Manager rotation lambda for RDS password

### Advanced S3 & Data Layer
- ⚠️ ALB access logs not being written to S3 (ALB listener missing)
- ❌ S3 access logging on main bucket (currently only has logging bucket for ALB)
- ❌ S3 replication (if multi-region planned later)

### Observability & Monitoring — CRITICAL GAPS
- ❌ CloudWatch Metric Alarms:
  - ALB 5XX error rate > 1%
  - ECS CPU > 80%
  - RDS connections > 80% of max
  - Redis memory > 75%
- ❌ CloudWatch Dashboard (as `templatefile()` JSON)
- ❌ Container Insights on ECS cluster
- ❌ X-Ray tracing (X-Ray daemon sidecar in ECS task)
- ❌ Custom metrics / application instrumentation setup

### Multi-Environment Structure — MISSING
**Phase 2 requirement:** Directory layout for dev/staging/prod

- ❌ `dev/`, `staging/`, `prod/` folders with separate `.tfvars` and state
- ❌ Root module refactoring to support multi-env

### Modularization — MISSING
**Phase 3 requirement:** Extract into child modules

- ❌ `modules/vpc/`, `modules/compute/`, `modules/data/`, `modules/iam/`, etc.
- ❌ Root module calling all child modules
- ❌ Module outputs wired to SSM Parameter Store

---

## ⚠️ KNOWN ISSUES & GOTCHAS

### 1. **Bastion Host SSH too permissive**
   - **Current:** `cidr_ipv4 = "0.0.0.0/0"` on port 22
   - **Should be:** Your IP only, or remove SSH entirely and use SSM Session Manager
   - **File:** `security_group.tf`, variable `security_group.bastion.ingress.ssh`

### 2. **IAM Policy Structure Complexity**
   - **Current:** `iam_role_and_policy.tf` uses complex `locals` maps and dynamic policy generation
   - **Risk:** Policies may not attach correctly; verify with `terraform plan`
   - **Fix:** Simplify or test thoroughly before applying

### 3. **RDS `skip_final_snapshot` enforcement**
   - **Current:** `skip_final_snapshot = false` and `deletion_protection = true`
   - **Impact:** `terraform destroy` will fail; you must manually disable both and re-apply before destroy
   - **Intended behavior:** Prevents accidental data loss in prod

### 4. **NAT Gateway redundancy is intentional**
   - **Current:** Only 2 NAT GWs (ap-south-1a, ap-south-1b); ap-south-1c routes through ap-south-1b
   - **Cost optimization:** Real AWS pattern to reduce NAT costs; subnet route tables handle it via `az_to_nat` local
   - **Risk:** If ap-south-1b NAT fails, ap-south-1c instances also lose internet; consider upgrading to 3 NATs in prod

### 5. **ASG missing scaling policies**
   - **Current:** Desired capacity fixed at 2; no target tracking
   - **Missing:** Scale on `ALBRequestCountPerTarget` metric
   - **Impact:** Won't auto-scale with traffic

### 6. **Launch Template uses deprecated `instance_type` in ASG**
   - **Current:** Single `instance_type` in launch template
   - **Missing:** `mixed_instances_policy` in ASG for on-demand + spot instances
   - **Check:** Verify asg.tf actually implements mixed instances

### 7. **Secrets Manager policy is unnecessary**
   - **Current:** `aws_secretsmanager_secret_policy` may be defined
   - **Fix:** Remove if same-account access only (role permissions alone are enough)

### 8. **Test.tf is scratch work**
   - **Status:** Contains experimental locals; should be cleaned up before Phase 2

---

## 📋 PRIORITY BUILD ORDER (Recommended)

### Immediate (fixes & validation)
1. **Verify & Fix IAM Policy Attachment** — ensure `role_ec2_instance` and `role_ecs_task` have correct policies attached
2. **Fix Bastion SG** — restrict SSH to your IP or remove key pair
3. **Remove unnecessary Secrets Manager policy** — clean up if same-account only
4. **Clean up test.tf** — delete experimental code

### Phase 1B (complete the flat tier)
5. **Add ASG Scaling Policy** — target tracking on `ALBRequestCountPerTarget`
6. **Add ASG Lifecycle Hook** — graceful connection draining on termination
7. **Add ALB HTTPS Listener** — provision ACM cert, add port 443 listener, HTTP→HTTPS redirect
8. **Add ALB Access Logs** — enable ALB to log to S3 logging bucket
9. **Create WAF v2 Web ACL** — attach to ALB
10. **Deploy CloudWatch Alarms** — 5 key metrics (ALB 5XX, ECS CPU, RDS connections, Redis memory, custom app metric)

### Phase 1C (complete observability)
11. **Create CloudWatch Dashboard** — as `templatefile()` JSON
12. **Deploy CloudTrail** — account-level API audit
13. **Enable Container Insights** — on ECS cluster (once cluster exists)
14. **Setup X-Ray Tracing** — ECS task sidecar + instrumentation

### Phase 2 (data layer completion)
15. **Deploy ElastiCache Redis** — multi-AZ, KMS encryption, auth token in Secrets Manager
16. **Convert RDS to Aurora Cluster** — `aws_rds_cluster` + `aws_rds_cluster_instance`
17. **Setup RDS custom parameter group** — slow query logging
18. **Setup RDS password rotation** — Secrets Manager lambda

### Phase 2B (application compute)
19. ✅ **ECS Cluster** — done (`for_each`, Container Insights enabled)
20. ✅ **ECS Task Definition** — done (FARGATE, awsvpc, dynamic containers + volumes)
21. ✅ **ECS Service** — done (service connect, ALB, alarms, network_configuration skeleton)
22. ✅ **ECS Service Discovery** — done (`aws_service_discovery_http_namespace`)
23. **Fix ECS wiring** — IAM role ARNs, CloudWatch log group ref, data source, subnets/SGs
24. **Deploy ECR Repository** — image scanning, lifecycle policy (keep last 10)
25. **Add `role_ecs_task_execution`** to `assume_role_policy` in tfvars

### Phase 3 (multi-environment & modularization)
24. **Refactor to multi-env structure** — `dev/`, `staging/`, `prod/` with separate `.tfvars` and state
25. **Extract modules** — VPC, compute, data, IAM into separate module folders
26. **Refactor root module** — call child modules, wire outputs to SSM

---

## 📊 CURRENT STATE SUMMARY

| Category | Status | Notes |
|----------|--------|-------|
| **Networking** | ✅ Complete | VPC, subnets (3 tiers, 3 AZs), NAT (2 only), routing |
| **Security Groups** | ⚠️ 95% | Declared but Bastion too permissive; missing SG rule validations |
| **KMS & Encryption** | ✅ Complete | Single CMK, used for RDS/S3/EBS |
| **Secrets Manager** | ✅ Complete | DB credentials stored; needs policy cleanup |
| **IAM** | ⚠️ 60% | Roles declared, complex policy structure, needs verification |
| **RDS** | ✅ 80% | Single instance (not cluster); encrypted; multi-AZ; needs Aurora migration |
| **ALB** | ⚠️ 50% | ALB + 2 target groups (instance + ip); missing HTTPS listener, WAF, access logs |
| **ASG + EC2** | ⚠️ 70% | Launch template, ASG deployed; missing scaling policy, lifecycle hook |
| **ECS Fargate** | ⚠️ 60% | Cluster, task def, service, EFS, service discovery done; wiring fixes + ECR remaining |
| **ElastiCache** | ❌ 0% | Not started |
| **ACM** | ❌ 0% | Not started |
| **WAF v2** | ❌ 0% | Not started |
| **CloudTrail** | ❌ 0% | Not started |
| **CloudWatch** | ⚠️ 20% | Log group + Flow Logs only; missing alarms, dashboard |
| **SSM Parameter Store** | ✅ 80% | Endpoints stored; missing Redis endpoint |
| **Multi-env structure** | ❌ 0% | Still flat; Phase 2 work |
| **Modules** | ❌ 0% | Not yet extracted; Phase 3 work |

**Overall: ~55% complete** — Core networking & database done; ECS skeleton in progress; compute & observability need significant work; monitoring is a critical gap.

---

## 🔍 FILES TO REVIEW & CLEAN UP

1. **iam_role_and_policy.tf** — Complex policy structure; verify it works or simplify
2. **asg.tf** — Add scaling policy and lifecycle hook
3. **alb.tf** — Add HTTPS listener, access logs, WAF
4. **test.tf** — Delete (scratch work)
5. **s3_logging_bucket.tf** — Verify ALB access logs are wired once ALB listener exists
6. **cloudwatch.tf** — Add alarms and dashboard
7. **ssm_parameter_store.tf** — Add Redis endpoint once ElastiCache is built

---

## ✨ Next Steps

1. **Run `terraform plan` to identify any errors** in current code
2. **Fix and validate Phase 1** (especially IAM, ASG, Bastion SG)
3. **Build Phase 1B** (ALB listeners, WAF, alarms)
4. **Then tackle Phase 2** (ElastiCache, Aurora, ECS)
