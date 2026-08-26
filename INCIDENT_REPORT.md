# Incident Report — Terraform-Project-Strata

**Date:** 2026-08-26  
**Environment:** AWS ap-south-1 (dev)  
**Status:** Resolved

---

## Issue 1: Target Groups Unhealthy (ALB Health Checks Failing)

### Root Cause — Misconfigured NACLs (Private + Public Subnets)

NACLs are **stateless** — unlike Security Groups, every direction of traffic needs its own explicit rule. The rules were written only for inbound traffic patterns, completely missing the return-traffic direction and the NAT Gateway path.

### Private NACL — What Was Missing

| Direction | Was Present | Was Missing |
|---|---|---|
| Ingress | `tcp 80`, `tcp 443` (ALB → instance) | `tcp 1024-65535` (ephemeral return traffic for outbound connections) |
| Egress | `tcp 1024-65535` (responses back to ALB) | `tcp 80`, `tcp 443` (outbound requests via NAT Gateway) |

ALB sends health check requests to port 8080 on ASG instances. The response from the instance back to the ALB travels on an ephemeral port (1024-65535) — that ingress rule was missing, so responses were silently dropped. Health checks never got a reply → target groups stayed unhealthy.

The missing egress `tcp 443` also meant `apt-get install nginx` in `user_data` was timing out — instances never actually had nginx running to respond to health checks even when a packet did get through.

### Public NACL — What Was Missing

The NAT Gateway sits in the **public subnet**. Traffic from private ASG instances going to the internet passes through the public subnet NACL twice:

- **Outbound path:** instance → private NACL egress → public subnet → **public NACL ingress** → NAT GW → **public NACL egress** → internet
- **Return path:** internet → **public NACL ingress** → NAT GW → **public NACL egress** → private subnet → private NACL ingress → instance

| Direction | Was Present | Was Missing |
|---|---|---|
| Ingress | `tcp 80`, `tcp 443` (internet → ALB) | `tcp 1024-65535` (internet responses back to NAT GW + ASG→ALB responses) |
| Egress | `tcp 1024-65535` (ALB responses to internet clients) | `tcp 80`, `tcp 443` (NAT GW → internet outbound requests) |

Without egress `tcp 443` on the public NACL, every outbound request from a private instance was dropped the moment it reached the public subnet — making the NAT Gateway completely non-functional despite being correctly configured at the routing level.

---

## Issue 2: Bastion Server Not Creating (30+ Minutes)

This had **four compounding causes**, each hiding the next.

### Cause 1 — Wrong Terraform Timeout (Primary)

The `aws_instance` resource has a default `create` timeout of **10 minutes**. Terraform declared failure at exactly 10 minutes even if AWS was still successfully provisioning. The instance was genuinely taking longer due to the NACL issues below, so Terraform gave up before AWS finished.

**Fix:** Explicit `timeouts { create = "20m" }` added to the resource.

### Cause 2 — Public NACL Blocking SSM Agent Startup

The bastion is in the **public subnet** and reaches SSM over the internet (VPC endpoints are in private subnets, not accessible from public subnet routing). The SSM agent in `user_data` needed outbound `tcp 443` to register with the SSM service. The old public NACL had no egress rule for `tcp 443`, so:

- SSM agent silently failed to connect on every retry
- Instance status checks were delayed or failing
- Terraform kept waiting → hit the 10-minute default timeout

Once the public NACL was fixed with egress `tcp 443` and ingress `tcp 1024-65535`, the SSM agent communicated normally and the instance stabilised within 2-3 minutes.

### Cause 3 — IAM Race Condition (Intermittent Failures)

The `depends_on` only listed `strata_ssm_core` (the AWS-managed SSM policy) but not `strata_attach_policy` (the custom policies). Terraform could create the instance before the custom IAM policies finished globally propagating through AWS IAM's eventual-consistency replication — causing permission failures on some days and not others depending on IAM replication speed that day.

**Fix:** Both `strata_ssm_core` and `strata_attach_policy` added to `depends_on`.

### Cause 4 — AWS Capacity Shortage (Final Blocker)

Once everything else was fixed, the final error was `InsufficientInstanceCapacity` for `t2.micro` in `ap-south-1a`. AWS advised switching to `ap-south-1b` which had available capacity.

**Fix:** `subnet_az` changed from `ap-south-1a` to `ap-south-1b` in `terraform.tfvars`.

---

## Resolution Summary

| Problem | Root Cause | Fix Applied |
|---|---|---|
| nginx never installed on ASG instances | Private NACL missing egress `tcp 80/443` | Added outbound HTTP/HTTPS egress to private NACL |
| ALB health check responses dropped | Private NACL missing ingress `tcp 1024-65535` | Added ephemeral port ingress to private NACL |
| NAT Gateway non-functional | Public NACL missing egress `tcp 80/443` | Added outbound HTTP/HTTPS egress to public NACL |
| Internet responses not reaching NAT GW | Public NACL missing ingress `tcp 1024-65535` | Added ephemeral port ingress to public NACL |
| SSM agent on bastion couldn't start | Same public NACL egress issue | Same public NACL fix above |
| Terraform timed out at 10 minutes | Default `create` timeout too short | Set `timeouts { create = "20m" }` on `aws_instance` |
| Bastion IAM intermittent failures | Incomplete `depends_on` (missing `strata_attach_policy`) | Added `strata_attach_policy` to `depends_on` |
| Bastion stuck at AWS level | `t2.micro` capacity exhausted in `ap-south-1a` | Moved bastion to `ap-south-1b` |

---

## Key Lessons

1. **NACLs require symmetric rules.** Every connection needs both a send rule and a receive rule — for both the initiator's subnet AND any intermediate subnet (e.g. public subnet where NAT GW lives).
2. **NAT Gateway traffic crosses the public NACL twice** (once inbound from private subnet, once outbound to internet). The public NACL must allow both directions for NAT to work.
3. **`depends_on` must cover all policy attachments**, not just one. IAM is eventually consistent — partial dependencies cause intermittent failures.
4. **Always set an explicit `timeouts { create }` on `aws_instance`** when using KMS-encrypted EBS or SSM agent init, as these can push past the 10-minute default.
5. **`TF_LOG=DEBUG`** is the fastest way to surface the real AWS API error (e.g. `InsufficientInstanceCapacity`) instead of a generic Terraform timeout message.
