Use this version instead:

# Terraform Note — When to Use Keys Instead of Indexes

## Problem

Suppose infrastructure looks like this:

* 3 public subnets
* 3 private subnets
* only 2 NAT gateways

Example:

```hcl id="ykjlwm"
public_1
public_2
public_3
```

But NAT gateways exist only in:

```hcl id="4mr2l1"
public_1
public_2
```

Now there is no clean positional relationship.

This becomes unclear:

```hcl id="kwjlwm"
subnet[0] -> nat[0]
subnet[1] -> nat[1]
subnet[2] -> ?
```

Indexes stop being meaningful because some resources do not exist for every position.

---

# Better Approach

Use explicit keys/names to model relationships.

Example:

```hcl id="jlwm0z"
nat_subnets = [
  "public_1",
  "public_2"
]
```

Now the relationship is clear:

```text id="m2q8wd"
public_1 -> has NAT
public_2 -> has NAT
public_3 -> no NAT
```

---

# Core Idea

Indexes represent position.

Keys represent infrastructure intent.

Use key-based relationships when infrastructure has:

* uneven topology
* partial relationships
* selective resource placement
* AZ-specific architecture
* routing dependencies

---

# Practical Rule

If infrastructure relationships cannot be explained clearly with:

```text id="5xjv7n"
resource[0]
resource[1]
```

then use named keys instead:

```text id="jlwmzz"
resource["public_1"]
resource["public_2"]
```

because names model architecture more safely than positions.


---
``` Another TIP ```
How for_each works (example taken from aws_network_acl.strata_public)

for_each iterates the top-level keys of that map.
for_each = <map>
              │
              ├── each.key   = the KEY   of current iteration
              └── each.value = the VALUE of current iteration
                               (everything on the right side of that key)
Rule: each.value is never a { key = value } pair — it's always the raw value sitting after = for that key.
Rule: for_each always iterates the map you point it at. each.key is always a top-level key inside that specific map.

Example -> nacl = { "public_nacl" = {"ingress_1" = { protocol = "tcp" } } }
nacl is just the variable name — it is never a key. Keys are what's inside the { } of that map.
var.nacl means {} <-complete MAP
each.key = "public_nacl"
each.value = {"ingress_1" = { protocol = "tcp" } } }

---
``` Another TIP ```
DYNAMIC BLOCKS

Static ingress {} block
Used when you know the rules at the time of writing the code. You write one block per rule, values are hardcoded.

Dynamic dynamic "ingress" block
Used when rules come from a variable or local. You write the block once, Terraform generates one ingress {} block per item in the collection at plan/apply time. Number of rules is controlled by the variable — adding a rule means adding to the variable, not touching the resource code.

The dynamic keyword itself
It tells Terraform — "this block type is repeatable, generate one instance of it for each item in for_each." The label after dynamic must match the block type name in that resource. For aws_network_acl the block types are ingress and egress, so you write dynamic "ingress" and dynamic "egress". For a different resource with a block called rule, you'd write dynamic "rule".

In your current code, for_each is on the resource — so the entire NACL repeats once per key in the variable. That's why you're getting 3 NACLs.
With dynamic, for_each moves to inside the block — so only the ingress block repeats, not the resource. The NACL is created once, and inside it, Terraform generates one ingress {} block per item in the collection.

So the repetition scope is:

for_each on resource → entire resource repeats
for_each on dynamic block → only that block repeats, resource stays single

Inside a dynamic block the iterator is named after the block label by default, not each.
So inside dynamic "ingress", it's ingress.key and ingress.value.
Inside dynamic "egress", it's egress.key and egress.value.
each only exists when for_each is on the resource itself.

resource "aws_network_acl" "strata_data" {
  vpc_id = aws_vpc.strata.id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      rule_no    = ingress.value.rule_no # not each.value.rule_no
      from_port  = ingress.value.from_port
      to_port    = ingress.value.to_port
    }
  }
}

---
``` Another TIP ```
When to use Locals
1. You're referencing a resource output
2. You're repeating the same expression in multiple places
3. You're doing a transformation or computation
4. You're building a lookup/resolution map
5. A complex expression would hurt readability inline

When NOT to Use Locals
Situation                                           Why not
Value is user-provided input                        Use variable
Simple one-time direct reference                    Inline it, no need for local
You're tempted to put business logic in locals      Reconsider module structure instead
Overusing locals for every tiny value                Creates indirection with no benefit

---
``` Another TIP ```
locals is not a resource block. It does not support for_each or each.value
each only exists inside resource, data, module blocks that have for_each on them.

---
```Another TIP ```
While defining the schema in variables.tf
for 
type = object({}) -> Use it for fixed set of attributes
type = map() -> use it for dynamic attributes

Also if using object({}) its important to define those fixed keys as well...check for nacl_rules as example in variables.tf


---
``` How to use Terraform Graph ```
If you haven't done so already, install Terraform
Open command palette using Ctrl+Shift+P
Select command Generate Terraform Graph

---
``` Another TIP ```
## IAM Role — Two concerns, always

| | Question | Terraform |
|---|---|---|
| Trust Policy (assume role) | **Who** can use this role? | `assume_role_policy` arg inside `aws_iam_role` — NOT a separate resource |
| Permission Policy | **What** can it do? | `aws_iam_policy` + `aws_iam_role_policy_attachment` — separate resources |

### Trust Policy is baked into the role
It is an argument on `aws_iam_role`, not a standalone resource. You cannot create a role without one.
In the plan you won't see a separate `aws_iam_trust_policy` resource — it shows up as an attribute inside `aws_iam_role`.

### Permission Policy is 3 separate resources
```
aws_iam_policy                   → the policy document (what actions are allowed)
aws_iam_role_policy_attachment   → glues the policy to the role
aws_iam_role                     → the role that gets the permissions
```

### Why AWS-managed services also need a trust policy
Services like VPC Flow Logs, Lambda, etc. run on your behalf but cannot use access keys.
The only way they get permissions is by assuming your IAM role.
So you must explicitly allow them in the trust policy:
- `ec2.amazonaws.com`           → so your EC2 instance can read secrets / write S3
- `ecs-tasks.amazonaws.com`     → so your ECS container can access RDS / secrets
- `vpc-flow-logs.amazonaws.com` → so the Flow Logs service can write to CloudWatch

### AWS Console hides this split
Step 1 "Select trusted entity" → sets trust policy | Step 2 "Add permissions" → attaches permission policy.
Feels like one thing in the console. In Terraform you define both explicitly.