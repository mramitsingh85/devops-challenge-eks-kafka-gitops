#!/bin/bash

REGION="ap-south-1"

for VPC in \
vpc-004000fe2a9d28e0f \
vpc-0d1fae7ea7481cf40 \
vpc-0d2fbd1de5000a593 \
vpc-0f6489a9f8f98837c
do
echo ""
echo "================================================="
echo "VPC: $VPC"
echo "================================================="

echo "SUBNETS"
aws ec2 describe-subnets \
  --filters Name=vpc-id,Values=$VPC \
  --region $REGION \
  --query 'Subnets[*].[SubnetId]' \
  --output table

echo "ROUTE TABLES"
aws ec2 describe-route-tables \
  --filters Name=vpc-id,Values=$VPC \
  --region $REGION \
  --query 'RouteTables[*].[RouteTableId]' \
  --output table

echo "SECURITY GROUPS"
aws ec2 describe-security-groups \
  --filters Name=vpc-id,Values=$VPC \
  --region $REGION \
  --query 'SecurityGroups[*].[GroupId,GroupName]' \
  --output table

echo "NETWORK INTERFACES"
aws ec2 describe-network-interfaces \
  --filters Name=vpc-id,Values=$VPC \
  --region $REGION \
  --query 'NetworkInterfaces[*].[NetworkInterfaceId,Description,Status]' \
  --output table

echo "INTERNET GATEWAYS"
aws ec2 describe-internet-gateways \
  --filters Name=attachment.vpc-id,Values=$VPC \
  --region $REGION \
  --query 'InternetGateways[*].[InternetGatewayId]' \
  --output table

echo "NAT GATEWAYS"
aws ec2 describe-nat-gateways \
  --filter Name=vpc-id,Values=$VPC \
  --region $REGION \
  --query 'NatGateways[*].[NatGatewayId,State]' \
  --output table

echo "VPC ENDPOINTS"
aws ec2 describe-vpc-endpoints \
  --filters Name=vpc-id,Values=$VPC \
  --region $REGION \
  --query 'VpcEndpoints[*].[VpcEndpointId,State]' \
  --output table

echo "LOAD BALANCERS"
aws elbv2 describe-load-balancers \
  --region $REGION \
  --query "LoadBalancers[?VpcId=='$VPC'].[LoadBalancerArn]" \
  --output table

done
