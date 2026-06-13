# CLAUDE.md — Strata Terraform Project

This file gives Claude (and any AI assistant) persistent context about this project so every session starts with the right mental model.

---

## Project Overview

**Project name:** Strata
**Goal:** Build a production-grade, multi-tier AWS infrastructure using Terraform — flat first, then multi-environment, then modularized.
**Region:** `us-east-1`
**Terraform version:** `>= 1.9.0, < 2.0.0`
**AWS Provider version:** `~> 6.46`

---

## Architecture Summary

Three-tier network layout across 3 AZs (`us-east-1a`, `us-east-1b`, `us-east-1c`):

| Tier    | Resources                          | Subnets        |
|---------|------------------------------------|----------------|
| Public  | ALB, NAT Gateways, Bastion Host    | 3 AZs          |
| Private | App Servers (EC2/ASG), ECS Fargate | 3 AZs          |
| Data    | RDS PostgreSQL, ElastiCache        | 2 AZs          |

**NAT Gateways:** Only 2 — in `us-east-1a` and `us-east-1b`. `us-east-1c` private subnet routes through `us-east-1b` NAT. This is captured in the `az_to_nat` local map in `locals.tf`.

---

## File Map

| File                       | Purpose                                                    |
|----------------------------|------------------------------------------------------------|
| `provider.tf`              | Terraform + AWS provider version constraints               |
| `variables.tf`             | All input variable declarations                            |
| `locals.tf`                | Computed locals: VPC CIDR, tags, `az_to_nat` map           |
| `vpc.tf`                   | VPC, IGW, subnets (public/private/data), NACLs             |
| `route_tables.tf`          | Route tables + associations for all 3 tiers                |
| `security_group.tf`        | SGs for App Server and Database                            |
| `kms_key.tf`               | KMS key for RDS encryption                                 |
| `secrets_manager.tf`       | DB credentials stored in Secrets Manager                   |
| `iam_role_and_policy.tf`   | IAM policy for EC2 to read secrets; role + profile pending |
| `rds.tf`                   | RDS PostgreSQL (db.t3.medium, Multi-AZ), DB subnet group   |
| `alb.tf`                   | Application Load Balancer                                  |
| `asg.tf`                   | Auto Scaling Group                                         |
| `ec2.tf`                   | Bastion Host + App Server EC2 instances                    |
| `s3.tf`                    | S3 bucket (remote state target — not yet wired as backend) |
| `data.tf`                  | Data sources (e.g., latest AMI lookup)                     |
| `test.tf`                  | Scratch / experimental resources                           |
| `variables.tf`             | Variable definitions (no tfvars — those are gitignored)    |

---

## Key Design Decisions

### Keys over Indexes
When infrastructure has uneven topology (e.g., 3 subnets but only 2 NAT gateways), use **key-based maps** instead of positional indexes. See `Tips_to_remember.md` for the full rationale.

```hcl
# az_to_nat map — maps every private AZ to its correct NAT GW AZ
az_to_nat = {
  "us-east-1a" = "us-east-1a"
  "us-east-1b" = "us-east-1b"
  "us-east-1c" = "us-east-1b"   # us-east-1c shares us-east-1b's NAT
}
```

### Secrets Manager over Variables
DB credentials (username + password) live in AWS Secrets Manager — never in `.tfvars` or hardcoded.

### NACLs with Dynamic Blocks
Public, private, and data NACLs use `dynamic` ingress/egress blocks driven by `var.*_nacl_rules` maps.

---

## Current Phase & Status

**Active phase:** Phase 1 — Flat Working Code

### Done
- VPC, IGW, all subnets (public × 3, private × 3, data × 2)
- NAT Gateways (2) + Elastic IPs
- Route tables + associations for all tiers
- NACLs (public, private, data) with dynamic rules
- Security Groups (App Server, Database)
- KMS Key
- Secrets Manager (secret + version)
- IAM Policy (`read_secrets_policy`)
- RDS PostgreSQL (Multi-AZ, KMS encrypted)

### In Progress / Blocked
- IAM Role (`strata_app`) + Instance Profile for EC2 — declared but needs attachment verified
- Bastion Host EC2 (public subnet, port 22 from personal IP only)
- App Server EC2 (private subnet, port 22 from Bastion SG only)
- Security Group rules — verify least privilege, no `0.0.0.0/0` on internal SGs
- Remote state backend (S3 + DynamoDB) — not yet wired into `backend` block

### Phase 2 (next)
- Multi-environment directory structure: `dev/`, `staging/`, `prod/`
- Separate `.tfvars` and state file per environment

### Phase 3 (future)
- Extract VPC, Compute, RDS, IAM into child modules
- Root module calls all child modules

---

## Important Rules & Reminders

- `*.tfvars` are **gitignored** — never commit them. Supply values locally.
- `skip_final_snapshot` must be `false` before promoting to prod.
- Always reference AMIs via `data` source — no hardcoded AMI IDs.
- `aws_secretsmanager_secret_policy` is not needed for same-account access — remove it.
- Set a billing alert in AWS after every deploy to catch forgotten resources.
- `test.tf` is scratch — clean it up before any Phase 2 work.
