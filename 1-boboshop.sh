#!/bin/bash

# creating AMI ID , from ec2 previous instance

AMI_ID="ami-09c813fb71547fc4f"
# SAME LIKE AMI, TAKE SG ID
SG_ID="sg-0d8d7189bee7912bc"
#Subnet its going to default, so no worries for now

# Creating Instance Array to install
#here whatever we are doing in the console, that can be done from command line
INSTANCES=("mongodb" "reddis" "mysql" "rabbitmq" "catalougue" "user" "cart" "shipping" "payment" "dispatch" "frtontend")


#Creating Zone id in route53
ZONE_ID="Z0373351299AU3JG23M5V"
#Creating Domain Name in route 53
DOMAIN_NAME="muruga.site"

#Now using loop concept to download all the instances

for instance in ${INSTANCES[@]}
do

    INSTACE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t2.micro --security-group-ids sg-0d8d7189bee7912bc --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=test}]' --query 'Instances[0].InstanceId' --output text)  # have instance id is replaced in the place of private ip, due to which public ip need to be query in this soo
    if [ $instance != "frontend" ]
    then
        PRIVATE_IP=$(aws ec2 describe-instances --instance-ids $INSTACE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        echo "$instance PRICATE IP Address : $PRIVATE_IP"
    else
        PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTACE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        echo "$instance PUBLIC IP Address : $PUBLIC_IP"

    fi
    echo "$instance IP Address : $PUBLIC_IP"
    echo "$instance IP Address : $PRIVATE_IP"

done

