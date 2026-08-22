#!/usr/bin/env bash
# Run after terraform apply to verify all key resources are up.
# Usage: bash verify.sh
set -euo pipefail

REGION="ap-south-1"
RDS_ID="strata-db"
REDIS_ID="strata-redis"
ECS_CLUSTER="strata-app-cluster"
ECS_SERVICE="mongodb"
ALB_NAME="strataLB"
ECR_REPO="strata-repo"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

PASS=0
FAIL=0

pass() { echo "  [PASS] $1"; ((PASS++)); }
fail() { echo "  [FAIL] $1 — $2"; ((FAIL++)); }

echo ""
echo "Strata infrastructure check — region: $REGION"
echo "-------------------------------------------------------"

# VPC
VPC_STATE=$(aws ec2 describe-vpcs \
  --region "$REGION" \
  --filters "Name=tag:Project,Values=Strata" \
  --query "Vpcs[0].State" --output text 2>/dev/null)
[[ "$VPC_STATE" == "available" ]] \
  && pass "VPC — available" \
  || fail "VPC" "state=${VPC_STATE:-not found}"

# ALB
ALB_STATE=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --names "$ALB_NAME" \
  --query "LoadBalancers[0].State.Code" --output text 2>/dev/null)
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --names "$ALB_NAME" \
  --query "LoadBalancers[0].DNSName" --output text 2>/dev/null)
[[ "$ALB_STATE" == "active" ]] \
  && pass "ALB — $ALB_DNS" \
  || fail "ALB" "state=${ALB_STATE:-not found}"

# ALB target group health
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --region "$REGION" \
  --names "$ALB_NAME" \
  --query "LoadBalancers[0].LoadBalancerArn" --output text 2>/dev/null)
if [[ -n "$ALB_ARN" && "$ALB_ARN" != "None" ]]; then
  TG_ARNS=$(aws elbv2 describe-target-groups \
    --region "$REGION" \
    --load-balancer-arn "$ALB_ARN" \
    --query "TargetGroups[*].TargetGroupArn" --output text 2>/dev/null)
  for TG_ARN in $TG_ARNS; do
    TG_NAME=$(aws elbv2 describe-target-groups \
      --region "$REGION" \
      --target-group-arns "$TG_ARN" \
      --query "TargetGroups[0].TargetGroupName" --output text)
    HEALTHY=$(aws elbv2 describe-target-health \
      --region "$REGION" \
      --target-group-arn "$TG_ARN" \
      --query "length(TargetHealthDescriptions[?TargetHealth.State=='healthy'])" \
      --output text 2>/dev/null)
    [[ "${HEALTHY:-0}" -gt 0 ]] \
      && pass "  Target group $TG_NAME — $HEALTHY healthy target(s)" \
      || fail "  Target group $TG_NAME" "0 healthy targets"
  done
fi

# RDS
RDS_STATUS=$(aws rds describe-db-instances \
  --region "$REGION" \
  --db-instance-identifier "$RDS_ID" \
  --query "DBInstances[0].DBInstanceStatus" --output text 2>/dev/null)
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --region "$REGION" \
  --db-instance-identifier "$RDS_ID" \
  --query "DBInstances[0].Endpoint.Address" --output text 2>/dev/null)
[[ "$RDS_STATUS" == "available" ]] \
  && pass "RDS ($RDS_ID) — available, endpoint=$RDS_ENDPOINT" \
  || fail "RDS ($RDS_ID)" "status=${RDS_STATUS:-not found}"

# Redis
REDIS_STATUS=$(aws elasticache describe-replication-groups \
  --region "$REGION" \
  --replication-group-id "$REDIS_ID" \
  --query "ReplicationGroups[0].Status" --output text 2>/dev/null)
REDIS_PRIMARY=$(aws elasticache describe-replication-groups \
  --region "$REGION" \
  --replication-group-id "$REDIS_ID" \
  --query "ReplicationGroups[0].NodeGroups[0].PrimaryEndpoint.Address" --output text 2>/dev/null)
[[ "$REDIS_STATUS" == "available" ]] \
  && pass "Redis ($REDIS_ID) — available, primary=$REDIS_PRIMARY" \
  || fail "Redis ($REDIS_ID)" "status=${REDIS_STATUS:-not found}"

# ECS
RUNNING=$(aws ecs describe-services \
  --region "$REGION" \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --query "services[0].runningCount" --output text 2>/dev/null)
DESIRED=$(aws ecs describe-services \
  --region "$REGION" \
  --cluster "$ECS_CLUSTER" \
  --services "$ECS_SERVICE" \
  --query "services[0].desiredCount" --output text 2>/dev/null)
[[ "${RUNNING:-0}" -gt 0 ]] \
  && pass "ECS service ($ECS_SERVICE) — $RUNNING/$DESIRED tasks running" \
  || fail "ECS service ($ECS_SERVICE)" "running=${RUNNING:-0}, desired=${DESIRED:-0}"

# ECR
ECR_URI=$(aws ecr describe-repositories \
  --region "$REGION" \
  --repository-names "$ECR_REPO" \
  --query "repositories[0].repositoryUri" --output text 2>/dev/null)
[[ -n "$ECR_URI" && "$ECR_URI" != "None" ]] \
  && pass "ECR repo ($ECR_REPO) — $ECR_URI" \
  || fail "ECR repo ($ECR_REPO)" "not found"

# S3
for BUCKET in "strata-bucket-$ACCOUNT_ID" "strata-logging-bucket-$ACCOUNT_ID" "strata-bucket" "strata-logging-bucket"; do
  if aws s3api head-bucket --bucket "$BUCKET" --region "$REGION" 2>/dev/null; then
    pass "S3 bucket ($BUCKET) — exists"
    break
  fi
done

echo "-------------------------------------------------------"
echo "Result: $PASS passed, $FAIL failed"
echo ""
[[ $FAIL -eq 0 ]] && exit 0 || exit 1
