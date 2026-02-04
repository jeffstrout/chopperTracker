# AWS Teardown Checklist

Run these commands from AWS CloudShell or a terminal with valid AWS credentials for account `958933162000`.

**IMPORTANT**: Do NOT delete Route53 or the ACM certificate until Digital Ocean DNS is fully configured and the choppertracker.com domain is pointing to DO nameservers.

## Step 1: Stop ECS Service

```bash
aws ecs update-service --cluster flight-tracker-cluster --service flight-tracker-backend --desired-count 0 --region us-east-1
```

## Step 2: Delete ECS Service and Cluster

```bash
aws ecs delete-service --cluster flight-tracker-cluster --service flight-tracker-backend --force --region us-east-1
aws ecs delete-cluster --cluster flight-tracker-cluster --region us-east-1
```

## Step 3: Delete ECR Repository

```bash
aws ecr delete-repository --repository-name flight-tracker-backend --force --region us-east-1
```

## Step 4: Delete Load Balancer and Target Group

```bash
# Get the ALB ARN
ALB_ARN=$(aws elbv2 describe-load-balancers --names flight-tracker-alb --query 'LoadBalancers[0].LoadBalancerArn' --output text --region us-east-1)

# Delete listeners first
LISTENERS=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query 'Listeners[*].ListenerArn' --output text --region us-east-1)
for LISTENER in $LISTENERS; do
  aws elbv2 delete-listener --listener-arn "$LISTENER" --region us-east-1
done

# Delete the ALB
aws elbv2 delete-load-balancer --load-balancer-arn "$ALB_ARN" --region us-east-1

# Wait for ALB to be fully deleted, then delete target group
sleep 60
TG_ARN=$(aws elbv2 describe-target-groups --names flight-tracker-tg --query 'TargetGroups[0].TargetGroupArn' --output text --region us-east-1)
aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region us-east-1
```

## Step 5: Delete ElastiCache Redis

```bash
aws elasticache delete-cache-cluster --cache-cluster-id flight-tracker-redis --region us-east-1
```

## Step 6: Empty and Delete S3 Bucket

```bash
aws s3 rm s3://flight-tracker-web-ui-1750266711 --recursive --region us-east-1
aws s3 rb s3://flight-tracker-web-ui-1750266711 --region us-east-1
```

## Step 7: Disable and Delete CloudFront Distribution

```bash
# Disable the distribution first
aws cloudfront get-distribution-config --id EWPRBI0A74MVL --region us-east-1 > /tmp/cf-config.json
# Edit the config to set Enabled: false, then update
# This is complex via CLI - easier to do in the AWS Console
# Console: CloudFront > Distributions > EWPRBI0A74MVL > Disable > Wait > Delete
```

## Step 8: Delete Security Groups

```bash
# Get security group IDs by name
ALB_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=flight-tracker-alb-sg" --query 'SecurityGroups[0].GroupId' --output text --region us-east-1)
ECS_SG=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=flight-tracker-ecs-sg" --query 'SecurityGroups[0].GroupId' --output text --region us-east-1)

aws ec2 delete-security-group --group-id "$ECS_SG" --region us-east-1
aws ec2 delete-security-group --group-id "$ALB_SG" --region us-east-1
```

## Step 9: Delete CloudWatch Log Group

```bash
aws logs delete-log-group --log-group-name /ecs/flight-tracker --region us-east-1
```

## Step 10: Delete IAM Roles

```bash
# Detach policies first
aws iam list-attached-role-policies --role-name flight-tracker-task-execution-role --query 'AttachedPolicies[*].PolicyArn' --output text | tr '\t' '\n' | while read ARN; do
  aws iam detach-role-policy --role-name flight-tracker-task-execution-role --policy-arn "$ARN"
done

aws iam list-attached-role-policies --role-name flight-tracker-task-role --query 'AttachedPolicies[*].PolicyArn' --output text | tr '\t' '\n' | while read ARN; do
  aws iam detach-role-policy --role-name flight-tracker-task-role --policy-arn "$ARN"
done

# Delete inline policies
aws iam list-role-policies --role-name flight-tracker-task-execution-role --query 'PolicyNames[]' --output text | tr '\t' '\n' | while read POLICY; do
  aws iam delete-role-policy --role-name flight-tracker-task-execution-role --policy-name "$POLICY"
done

aws iam list-role-policies --role-name flight-tracker-task-role --query 'PolicyNames[]' --output text | tr '\t' '\n' | while read POLICY; do
  aws iam delete-role-policy --role-name flight-tracker-task-role --policy-name "$POLICY"
done

# Delete roles
aws iam delete-role --role-name flight-tracker-task-execution-role
aws iam delete-role --role-name flight-tracker-task-role
```

## Step 11: Delete EventBridge Rules (if any)

```bash
# List rules with flight-tracker prefix
aws events list-rules --name-prefix flight-tracker --region us-east-1
# For each rule, remove targets then delete
```

## Step 12: DNS Migration (DO THIS LAST)

Only after Digital Ocean is fully configured:

1. Set up DNS in Digital Ocean: `doctl compute domain create choppertracker.com`
2. Update GoDaddy nameservers to: `ns1.digitalocean.com`, `ns2.digitalocean.com`, `ns3.digitalocean.com`
3. Wait for DNS propagation (up to 48 hours)
4. Then delete Route53:

```bash
# Delete DNS records (A records for choppertracker.com and api.choppertracker.com, CNAME for www)
# This is easier in the AWS Console: Route53 > Hosted Zones > choppertracker.com > Delete records > Delete zone

# Delete ACM certificate
aws acm delete-certificate --certificate-arn arn:aws:acm:us-east-1:958933162000:certificate/02d66134-03c5-4974-8846-9ddeafb05bcd --region us-east-1
```

## Verification

After teardown, verify no resources remain:

```bash
aws resourcegroupstaggingapi get-resources --tag-filters Key=Project,Values=ChopperTracker --region us-east-1
```
