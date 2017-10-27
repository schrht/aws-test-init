#!/bin/bash

# Resource should be created:
# vpc-12345678 | cheshi_vpc_perf
# igw-12345678 | cheshi_igw_perf
# subnet-12345678 | cheshi_subnet_perf
# rtb-12345678 | cheshi_rtb_perf
# sg-12345678 | cheshi_sg_perf


function tag2id()
{
    # Query resource by tag and show its resource-id
    [ -z "$1" ] && exit 1
    aws ec2 describe-tags --filters "Name=value,Values=$1" --output json | jq -r .Tags[].ResourceId
}


function create_vpc()
{
    # Name tag: cheshi_vpc_perf
    # IPv4 CIDR block*: 10.22.0.0/16
	# IPv6 CIDR block*: Amazon provided IPv6 CIDR block
	# Tenancy: Default
    # DNS Hostnames: Yes

    # Create VPC
    x=$(aws ec2 create-vpc --cidr-block 10.22.0.0/16 --amazon-provided-ipv6-cidr-block --tenancy default --output json)
    if [ $? -eq 0 ]; then
        vpcid=$(echo $x | jq -r .VpcId)
        echo "new vpc created, resource-id = $vpcid."
    else
        echo "$0: line $LINENO: \"aws ec2 create-vpc\" failed."
        exit 1
    fi

    # Create tag
    x=$(aws ec2 create-tags --resources $vpcid --tags Key=Name,Value=cheshi_vpc_perf --output json)
    if [ $? -eq 0 ]; then
        echo "tag created for this resource."
    else
        echo "$0: line $LINENO: \"aws ec2 create-tags\" failed."
        exit 1
    fi

    # Enable DNS
    x=$(aws ec2 modify-vpc-attribute --vpc-id $vpcid --enable-dns-hostnames --enable-dns-support --output json)
    if [ $? -eq 0 ]; then
        echo "enabled dns for this vpc."
    else
        echo "$0: line $LINENO: \"aws ec2 modify-vpc-attribute\" failed."
        exit 1
    fi

    exit 0
}


function describe_vpc()
{
    [ -z "$1" ] && exit 1

    vpcid=$1
    aws ec2 describe-vpcs --vpc-id $vpcid --output table
    aws ec2 describe-vpc-attribute --vpc-id $vpcid --attribute enableDnsSupport --output table
    aws ec2 describe-vpc-attribute --vpc-id $vpcid --attribute enableDnsHostnames --output table

    exit 0
}


function create_igw()
{
    # Name tag: cheshi_igw_perf
    # VPC: vpc-12345678 | cheshi_vpc_perf

    # Create IGW
    x=$(aws ec2 create-internet-gateway --output json)
    if [ $? -eq 0 ]; then
        igwid=$(echo $x | jq -r .InternetGateway.InternetGatewayId)
        echo "new igw created, resource-id = $igwid."
    else
        echo "$0: line $LINENO: \"aws ec2 create-internet-gateway\" failed."
        exit 1
    fi

    # Create tag
    x=$(aws ec2 create-tags --resources $igwid --tags Key=Name,Value=cheshi_igw_perf --output json)
    if [ $? -eq 0 ]; then
        echo "tag created for this resource."
    else
        echo "$0: line $LINENO: \"aws ec2 create-tags\" failed."
        exit 1
    fi

    # Attach to VPC
    vpcid=$(tag2id cheshi_vpc_perf)
    x=$(aws ec2 attach-internet-gateway --internet-gateway-id $igwid --vpc-id $vpcid --output json)
    if [ $? -eq 0 ]; then
        echo "attached igw to the vpc."
    else
        echo "$0: line $LINENO: \"aws ec2 attach-internet-gateway\" failed."
        exit 1
    fi

    exit 0
}


function describe_igw()
{
    [ -z "$1" ] && exit 1

    igwid=$1
    aws ec2 describe-internet-gateways --internet-gateway-ids $igwid --output table

    exit 0
}




function main()
{
    date
    #describe_vpc $(tag2id cheshi_vpc_perf)
    describe_igw $(tag2id cheshi_igw_perf)
}

main

exit 0
