# Strata — Terraform Project Checklist

## Phase 1 — Flat Working Code

### Networking

### Security

### KMS

### Secrets Manager

### IAM

### Database

### Compute

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