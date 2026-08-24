#!/usr/bin/env bash
# Run after terraform apply to verify all key resources are up.
# Usage: bash verify.sh
set -euo pipefail

REGION="ap-south-1"
PROFILE="default"
RDS_ID="strata-db"
REDIS_ID="strata-redis"
ECS_CLUSTER="strata-app-cluster"
ECS_SERVICE="mongodb"
ALB_NAME="strataLB"
ECR_REPO="strata-repo"
ACCOUNT_ID=$(aws sts get-caller-identity --profile "$PROFILE" --query Account --output text)
STATE_BUCKET="strata-tfstate-${ACCOUNT_ID}"

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; PASS=$((PASS + 1)); }
fail() { echo "  [FAIL] $1 — $2"; FAIL=$((FAIL + 1)); }

echo ""
echo "Strata infrastructure check — region: $REGION  account: $ACCOUNT_ID"
echo "====================================================================="

# ── VPC ──────────────────────────────────────────────────────────────────────
echo ""
echo "[ Networking ]"
VPC_JSON=$(aws ec2 describe-vpcs \
  --profile "$PROFILE" --region "$REGION" \
  --filters "Name=tag:Project,Values=Strata" \
  --query "Vpcs[0].{State:State,VpcId:VpcId}" --output json 2>/dev/null)
VPC_STATE=$(echo "$VPC_JSON" | grep -o '"State": *"[^"]*"' | cut -d'"' -f4)
VPC_ID=$(echo "$VPC_JSON"   | grep -o '"VpcId": *"[^"]*"' | cut -d'"' -f4)
[[ "$VPC_STATE" == "available" ]] \
  && pass "VPC ($VPC_ID) — available" \
  || fail "VPC" "state=${VPC_STATE:-not found}"

# Public subnets (3) — tagged Name=public-*
PUB_COUNT=$(aws ec2 describe-subnets \
  --profile "$PROFILE" --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=public-*" \
  --query "length(Subnets)" --output text 2>/dev/null)
[[ "${PUB_COUNT:-0}" -ge 3 ]] \
  && pass "Public subnets — $PUB_COUNT found" \
  || fail "Public subnets" "found=${PUB_COUNT:-0} (expected 3)"

# Private subnets (3) — tagged Name=private-*
PRIV_COUNT=$(aws ec2 describe-subnets \
  --profile "$PROFILE" --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=private-*" \
  --query "length(Subnets)" --output text 2>/dev/null)
[[ "${PRIV_COUNT:-0}" -ge 3 ]] \
  && pass "Private subnets — $PRIV_COUNT found" \
  || fail "Private subnets" "found=${PRIV_COUNT:-0} (expected 3)"

# NAT Gateways
NAT_COUNT=$(aws ec2 describe-nat-gateways \
  --profile "$PROFILE" --region "$REGION" \
  --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" \
  --query "length(NatGateways)" --output text 2>/dev/null)
[[ "${NAT_COUNT:-0}" -ge 1 ]] \
  && pass "NAT Gateways — $NAT_COUNT available" \
  || fail "NAT Gateways" "found=${NAT_COUNT:-0}"

# Internet Gateway
IGW_ID=$(aws ec2 describe-internet-gateways \
  --profile "$PROFILE" --region "$REGION" \
  --filters "Name=attachment.vpc-id,Values=$VPC_ID" \
  --query "InternetGateways[0].InternetGatewayId" --output text 2>/dev/null)
[[ -n "$IGW_ID" && "$IGW_ID" != "None" ]] \
  && pass "Internet Gateway — $IGW_ID" \
  || fail "Internet Gateway" "not attached to VPC"

# ── Security ──────────────────────────────────────────────────────────────────
echo ""
echo "[ Security ]"

# KMS Key
KMS_ID=$(aws kms describe-key \
  --profile "$PROFILE" --region "$REGION" \
  --key-id "alias/strata-key" \
  --query "KeyMetadata.KeyId" --output text 2>/dev/null || echo "")
[[ -n "$KMS_ID" && "$KMS_ID" != "None" ]] \
  && pass "KMS key (alias/strata-key) — $KMS_ID" \
  || fail "KMS key" "alias/strata-key not found"

# Secrets Manager
SECRET_ARN=$(aws secretsmanager describe-secret \
  --profile "$PROFILE" --region "$REGION" \
  --secret-id "starta_secrets_manager" \
  --query "ARN" --output text 2>/dev/null || echo "")
[[ -n "$SECRET_ARN" && "$SECRET_ARN" != "None" ]] \
  && pass "Secrets Manager — starta_secrets_manager exists" \
  || fail "Secrets Manager" "secret not found"

# CloudTrail
TRAIL_STATUS=$(aws cloudtrail get-trail-status \
  --profile "$PROFILE" --region "$REGION" \
  --name "strata-trail" \
  --query "IsLogging" --output text 2>/dev/null || echo "false")
[[ "$TRAIL_STATUS" == "True" ]] \
  && pass "CloudTrail (strata-trail) — logging" \
  || fail "CloudTrail (strata-trail)" "IsLogging=${TRAIL_STATUS:-false}"

# CloudWatch Log Group
CW_ARN=$(aws logs describe-log-groups \
  --profile "$PROFILE" --region "$REGION" \
  --log-group-name-prefix "strata-cloudwatch-log-group" \
  --query "logGroups[0].arn" --output text 2>/dev/null)
[[ -n "$CW_ARN" && "$CW_ARN" != "None" ]] \
  && pass "CloudWatch log group — strata-cloudwatch-log-group" \
  || fail "CloudWatch log group" "not found"

# ── Compute ───────────────────────────────────────────────────────────────────
echo ""
echo "[ Compute ]"

# Bastion EC2 — single call fetching both fields
BASTION_JSON=$(aws ec2 describe-instances \
  --profile "$PROFILE" --region "$REGION" \
  --filters "Name=tag:Name,Values=strata-bastion" "Name=instance-state-name,Values=running" \
  --query "Reservations[0].Instances[0].{State:State.Name,Id:InstanceId}" --output json 2>/dev/null)
BASTION_STATE=$(echo "$BASTION_JSON" | grep -o '"State": *"[^"]*"' | cut -d'"' -f4)
BASTION_ID=$(echo "$BASTION_JSON"   | grep -o '"Id": *"[^"]*"'    | cut -d'"' -f4)
[[ "$BASTION_STATE" == "running" ]] \
  && pass "Bastion EC2 ($BASTION_ID) — running" \
  || fail "Bastion EC2" "state=${BASTION_STATE:-not found}"

# ASG
ASG_DESIRED=$(aws autoscaling describe-auto-scaling-groups \
  --profile "$PROFILE" --region "$REGION" \
  --auto-scaling-group-names "strata-asg" \
  --query "AutoScalingGroups[0].DesiredCapacity" --output text 2>/dev/null)
ASG_RUNNING=$(aws autoscaling describe-auto-scaling-groups \
  --profile "$PROFILE" --region "$REGION" \
  --auto-scaling-group-names "strata-asg" \
  --query "length(AutoScalingGroups[0].Instances[?LifecycleState=='InService'])" --output text 2>/dev/null)
[[ "${ASG_DESIRED:-0}" -gt 0 ]] \
  && pass "ASG (strata-asg) — $ASG_RUNNING/$ASG_DESIRED InService" \
  || fail "ASG (strata-asg)" "not found or no instances"

# Launch Template
LT_ID=$(aws ec2 describe-launch-templates \
  --profile "$PROFILE" --region "$REGION" \
  --launch-template-names "strata-app-lt" \
  --query "LaunchTemplates[0].LaunchTemplateId" --output text 2>/dev/null || echo "")
[[ -n "$LT_ID" && "$LT_ID" != "None" ]] \
  && pass "Launch Template (strata-app-lt) — $LT_ID" \
  || fail "Launch Template" "strata-app-lt not found"

# ── Load Balancer ─────────────────────────────────────────────────────────────
echo ""
echo "[ Load Balancer ]"

# ALB — single call fetching all three fields
ALB_JSON=$(aws elbv2 describe-load-balancers \
  --profile "$PROFILE" --region "$REGION" \
  --names "$ALB_NAME" \
  --query "LoadBalancers[0].{State:State.Code,DNS:DNSName,ARN:LoadBalancerArn}" --output json 2>/dev/null)
ALB_STATE=$(echo "$ALB_JSON" | grep -o '"State": *"[^"]*"' | cut -d'"' -f4)
ALB_DNS=$(echo "$ALB_JSON"   | grep -o '"DNS": *"[^"]*"'   | cut -d'"' -f4)
ALB_ARN=$(echo "$ALB_JSON"   | grep -o '"ARN": *"[^"]*"'   | cut -d'"' -f4)
[[ "$ALB_STATE" == "active" ]] \
  && pass "ALB ($ALB_NAME) — $ALB_DNS" \
  || fail "ALB ($ALB_NAME)" "state=${ALB_STATE:-not found}"

# Target group health
if [[ -n "$ALB_ARN" && "$ALB_ARN" != "None" ]]; then
  TG_ARNS=$(aws elbv2 describe-target-groups \
    --profile "$PROFILE" --region "$REGION" \
    --load-balancer-arn "$ALB_ARN" \
    --query "TargetGroups[*].TargetGroupArn" --output text 2>/dev/null)
  for TG_ARN in $TG_ARNS; do
    TG_NAME=$(aws elbv2 describe-target-groups \
      --profile "$PROFILE" --region "$REGION" \
      --target-group-arns "$TG_ARN" \
      --query "TargetGroups[0].TargetGroupName" --output text)
    HEALTHY=$(aws elbv2 describe-target-health \
      --profile "$PROFILE" --region "$REGION" \
      --target-group-arn "$TG_ARN" \
      --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" \
      --output text 2>/dev/null)
    [[ "${HEALTHY:-0}" -gt 0 ]] \
      && pass "Target group ($TG_NAME) — $HEALTHY healthy" \
      || fail "Target group ($TG_NAME)" "0 healthy targets"
  done
fi

# ── ECS ───────────────────────────────────────────────────────────────────────
echo ""
echo "[ ECS ]"

CLUSTER_STATUS=$(aws ecs describe-clusters \
  --profile "$PROFILE" --region "$REGION" \
  --clusters "$ECS_CLUSTER" \
  --query "clusters[0].status" --output text 2>/dev/null)
[[ "$CLUSTER_STATUS" == "ACTIVE" ]] \
  && pass "ECS cluster ($ECS_CLUSTER) — ACTIVE" \
  || fail "ECS cluster ($ECS_CLUSTER)" "status=${CLUSTER_STATUS:-not found}"

RUNNING=$(aws ecs describe-services \
  --profile "$PROFILE" --region "$REGION" \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --query "services[0].runningCount" --output text 2>/dev/null)
DESIRED=$(aws ecs describe-services \
  --profile "$PROFILE" --region "$REGION" \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --query "services[0].desiredCount" --output text 2>/dev/null)
[[ "${RUNNING:-0}" -gt 0 ]] \
  && pass "ECS service ($ECS_SERVICE) — $RUNNING/$DESIRED tasks running" \
  || fail "ECS service ($ECS_SERVICE)" "running=${RUNNING:-0}, desired=${DESIRED:-0}"

# ECR
ECR_URI=$(aws ecr describe-repositories \
  --profile "$PROFILE" --region "$REGION" \
  --repository-names "$ECR_REPO" \
  --query "repositories[0].repositoryUri" --output text 2>/dev/null)
[[ -n "$ECR_URI" && "$ECR_URI" != "None" ]] \
  && pass "ECR repo ($ECR_REPO) — $ECR_URI" \
  || fail "ECR repo ($ECR_REPO)" "not found"

# ── Data ──────────────────────────────────────────────────────────────────────
echo ""
echo "[ Data ]"

# RDS — single call
RDS_JSON=$(aws rds describe-db-instances \
  --profile "$PROFILE" --region "$REGION" \
  --db-instance-identifier "$RDS_ID" \
  --query "DBInstances[0].{S:DBInstanceStatus,E:Endpoint.Address}" --output json 2>/dev/null)
RDS_STATUS=$(echo "$RDS_JSON"   | grep -o '"S": *"[^"]*"' | cut -d'"' -f4)
RDS_ENDPOINT=$(echo "$RDS_JSON" | grep -o '"E": *"[^"]*"' | cut -d'"' -f4)
[[ "$RDS_STATUS" == "available" ]] \
  && pass "RDS ($RDS_ID) — $RDS_ENDPOINT" \
  || fail "RDS ($RDS_ID)" "status=${RDS_STATUS:-not found}"

# Redis — single call
REDIS_JSON=$(aws elasticache describe-replication-groups \
  --profile "$PROFILE" --region "$REGION" \
  --replication-group-id "$REDIS_ID" \
  --query "ReplicationGroups[0].{S:Status,E:NodeGroups[0].PrimaryEndpoint.Address}" --output json 2>/dev/null)
REDIS_STATUS=$(echo "$REDIS_JSON"  | grep -o '"S": *"[^"]*"' | cut -d'"' -f4)
REDIS_PRIMARY=$(echo "$REDIS_JSON" | grep -o '"E": *"[^"]*"' | cut -d'"' -f4)
[[ "$REDIS_STATUS" == "available" ]] \
  && pass "Redis ($REDIS_ID) — primary=$REDIS_PRIMARY" \
  || fail "Redis ($REDIS_ID)" "status=${REDIS_STATUS:-not found}"

# EFS
EFS_STATE=$(aws efs describe-file-systems \
  --profile "$PROFILE" --region "$REGION" \
  --query "FileSystems[?Tags[?Key=='Name' && Value=='strata-efs-strata_efs']].LifeCycleState | [0]" \
  --output text 2>/dev/null)
[[ "$EFS_STATE" == "available" ]] \
  && pass "EFS (strata-efs) — available" \
  || fail "EFS (strata-efs)" "state=${EFS_STATE:-not found}"

# ── Storage ───────────────────────────────────────────────────────────────────
echo ""
echo "[ Storage ]"

for BUCKET in "strata-bucket-${ACCOUNT_ID}" "strata-logging-bucket-${ACCOUNT_ID}" "$STATE_BUCKET"; do
  if aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" --profile "$PROFILE" 2>/dev/null; then
    pass "S3 bucket ($BUCKET) — exists"
  else
    fail "S3 bucket ($BUCKET)" "not found or no access"
  fi
done

# ── Summary ───────────────────────────────────────────────────────────────────
echo ""
echo "====================================================================="
echo "Result: $PASS passed, $FAIL failed"
echo ""
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
