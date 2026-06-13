# Strata — Terraform Project Checklist

## Phase 1 — Flat Working Code

### Networking
- [x] VPC
- [x] Internet Gateway
- [x] Public Subnets (3 AZs, AZ as key)
- [x] Private Subnets (3 AZs, AZ as key)
- [x] Data Subnets (2 AZs, AZ as key)
- [x] NAT Gateways (2, in us-east-1a and us-east-1b)
- [x] Elastic IPs for NAT Gateways
- [x] Public Route Table + Routes (IGW)
- [x] Private Route Tables + Routes (NAT, per AZ with az_to_nat local map)
- [x] Data Route Tables + Routes
- [x] Route Table Associations (public, private, data)
- [x] NACLs (public, private, data) with dynamic ingress/egress blocks

### Security
- [x] Security Group — App Server
- [x] Security Group — Database
- [ ] Security Group rules — verify least privilege, no 0.0.0.0/0 on internal SGs
- [ ] Bastion Security Group — port 22 from your IP only

### KMS
- [x] KMS Key (for RDS encryption)

### Secrets Manager
- [x] aws_secretsmanager_secret
- [x] aws_secretsmanager_secret_version (username + password)
- [ ] Remove aws_secretsmanager_secret_policy if same-account access only

### IAM
- [x] IAM Policy — read_secrets_policy (GetSecretValue)
- [ ] IAM Role — strata_app (trust policy for EC2)
- [ ] IAM Role Policy Attachment — attach read_secrets_policy to strata_app role
- [ ] IAM Instance Profile — wrap role for EC2 use

### Database
- [x] DB Subnet Group
- [x] RDS PostgreSQL Instance (db.t3.medium, Multi-AZ)
- [ ] Verify username/password pulled from Secrets Manager, not variables
- [ ] Verify skip_final_snapshot = false for prod

### Compute
- [ ] Bastion Host — EC2 in public subnet, port 22 from your IP only
- [ ] App Server — EC2 in private subnet, port 22 from bastion SG only
- [ ] Attach IAM Instance Profile to App Server
- [ ] Fetch latest Amazon Linux 2023 AMI via data source (no hardcoded AMI ID)

### Backend + State
- [ ] S3 bucket for remote state
- [ ] DynamoDB table for state locking
- [ ] Configure S3 backend in each environment

---

## Phase 2 — Multi-Environment

- [ ] Create directory structure: dev/, staging/, prod/
- [ ] Separate tfvars per environment
- [ ] Separate state file per environment (S3 key per env)
- [ ] Verify dev deploys cleanly
- [ ] Verify staging deploys cleanly
- [ ] Verify prod deploys cleanly
- [ ] Set billing alert in AWS to catch forgotten resources

---

## Phase 3 — Modularize

- [ ] Extract VPC + Networking into a module
- [ ] Extract Compute (Bastion + App Server) into a module
- [ ] Extract RDS + Secrets into a module
- [ ] Extract IAM into a module
- [ ] Root module calls all child modules
- [ ] Verify all environments still deploy cleanly after modularization

---

## Phase 4 — Dynamic Refactor

- [ ] Convert SG rules to dynamic ingress/egress blocks driven by variables
- [ ] Replace hardcoded values with locals-heavy derived config
- [ ] Programmatic CIDR generation via for expressions
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

## GitHub Structure (after Phase 1 is working)

- [ ] Create branch `phase/flat` — commit working flat code
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