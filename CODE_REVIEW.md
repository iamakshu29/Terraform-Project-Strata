# Terraform Code Review — Phase 1 (Flat Code, Single Env)

> Scope: Flat code review only. No modularization or multi-env comments.
> Focus: Bugs, security gaps, bad practices, naming issues.

---

## 1. vpc.tf -> FIXED

### [BUG] Route table routes are wrong — public routes should go to IGW, not specific CIDRs
```hcl
# terraform.tfvars
public_routes = {
  ap-south-1a = { destination_cidr = "10.0.1.0/24" }
}
```
**Problem:** A public route table's default route should be `0.0.0.0/0 → IGW`. You don't add per-AZ subnet CIDR routes — those are local routes added automatically by AWS. The current config routes public traffic to its own subnet, which is pointless.
**Fix:** Public routes should be a single entry: `{ internet = { destination_cidr = "0.0.0.0/0" } }`. Same issue in private and data routes — they should route `0.0.0.0/0 → NAT`, not to their own subnet CIDRs.

### [LOW] `az_to_nat` map in locals.tf is hardcoded with AZ strings
```hcl
az_to_nat = {
  "ap-south-1a" = "ap-south-1a"
  "ap-south-1b" = "ap-south-1b"
  "ap-south-1c" = "ap-south-1b"
}
```
**Problem:** This is a manual AZ-to-NAT mapping. If `nat_gateway_azs` changes, this map must be updated manually in sync. It's a hidden coupling.
**Fix:** At a minimum, add a comment explaining the coupling and that both must be updated together. Better: derive it programmatically if possible.

---

## 2. security_group.tf

### [MEDIUM] ALB only has HTTPS ingress, no HTTP→HTTPS redirect
```hcl
alb = {
  ingress = {
    https = { from_port = 443, to_port = 443 }
  }
}
```
**Problem:** No port 80 ingress on the ALB security group or listener. Users who visit `http://` will get a connection timeout instead of being redirected.
**Fix:** Add port 80 ingress to the ALB SG and configure an `aws_lb_listener` for port 80 that redirects to HTTPS.

### [LOW] All egress is wide open for all security groups
```hcl
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4_strata_server_rule" {
  for_each          = var.security_group
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"   # all ports, all protocols
}
```
**Problem:** Every SG (ALB, EC2, Bastion, RDS) gets unrestricted egress. This is a common shortcut but violates least privilege. The RDS instance especially should never need to initiate outbound internet traffic.
**Fix:** Define egress rules per SG in `var.security_group` the same way you did for ingress, and apply them selectively.

### [LOW] Security group description is generic
```hcl
description = "Allow TLS inbound traffic and all outbound traffic"
```
**Problem:** Every SG gets the same description regardless of its purpose. Descriptions show up in the console and in security audits.
**Fix:** Include the SG name in the description: `description = "${each.key} security group"`.

---

## 3. alb.tf

### [MEDIUM] ALB has no HTTPS listener defined
The `aws_lb` resource is created but there is no `aws_lb_listener` resource anywhere. Without a listener, the ALB accepts no traffic.
**Fix:** Add an `aws_lb_listener` for port 443 (HTTPS) that forwards to the target group. This requires an ACM certificate. Also add a port 80 listener that redirects to 443.

### [MEDIUM] Target group uses HTTP (port 80) with no health check configured
```hcl
resource "aws_lb_target_group" "strata" {
  port     = 80
  protocol = "HTTP"
}
```
**Problem:** No `health_check` block is defined. AWS will use defaults, but the threshold, path, and interval will not match your actual app. A bad health check means the ALB may route to unhealthy instances or mark healthy ones as unhealthy.
**Fix:** Add an explicit `health_check` block with `path`, `interval`, `healthy_threshold`, and `unhealthy_threshold`.

---

## 4. asg.tf

### [LOW] Launch template has no `key_name` -> (used the same key as Bastian - Temp FIXED)
The bastion `aws_instance` uses `aws_key_pair.strata_key.key_name`, but the launch template does not. ASG instances will be launched with no SSH key, making them inaccessible for debugging (even from the bastion).
**Fix:** Add `key_name = aws_key_pair.strata_key.key_name` to the launch template.

### [LOW] ASG version pinned to `"$Latest"` with no description
```hcl
version = "$Latest"
```
**Problem:** `$Latest` means every ASG refresh picks up whatever the newest launch template version is, including accidental ones. This is unpredictable in production.
**Fix:** For a learning project this is fine. In a real setup, prefer `$Default` and explicitly bump the default version intentionally.

---

## 5. secrets_manager.tf

### [HIGH] DB credentials are in `terraform.tfvars` and will land in state
```hcl
variable "secrets" {
  default = {
    key1 = "value1"
    key2 = "value2"
  }
}
```
```hcl
secret_string = jsonencode(var.secrets)
```
**Problem:** Passing credentials through a Terraform variable means:
1. The actual password ends up in `terraform.tfstate` in plaintext.
2. If `terraform.tfvars` is committed, credentials are in git history.

You already have `terraform.tfstate` committed to this repo (it's in your workspace listing).

**Fix (Phase 1):**
- Add `terraform.tfstate` and `terraform.tfvars` to `.gitignore` immediately.
- For secrets: create the secret value manually in AWS Secrets Manager or via a separate `null_resource` with a `local-exec` that never touches state. Reference the secret ARN in Terraform without storing the value.

---

## Summary Table

| Severity | File | Issue |
|---|---|---|
| BUG | route_tables.tf | Route destinations are subnet CIDRs, not `0.0.0.0/0` |
| MEDIUM | security_group.tf | Bastion SSH open to `0.0.0.0/0` | TEMP FIX DONE
| MEDIUM | alb.tf | No ALB listener defined — ALB accepts zero traffic |
| LOW | data.tf | `aws_availability_zones` data source unused |