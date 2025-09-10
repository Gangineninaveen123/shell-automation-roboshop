#!/bin/bash

# creating AMI ID , from ec2 previous instance

AMI_ID="ami-09c813fb71547fc4f"
# SAME LIKE AMI, TAKE SG ID
SG_ID="sg-0d8d7189bee7912bc"  # replace with our own SG_ID
#Subnet its going to default, so no worries for now

# Creating Instance Array to install
#here whatever we are doing in the console, that can be done from command line
INSTANCES=("mongodb" "reddis" "mysql" "rabbitmq" "catalougue" "user" "cart" "shipping" "payment" "dispatch" "frontend")


#Creating Zone id in route53
ZONE_ID="Z0373351299AU3JG23M5V" # Replace with own ZONE_ID
#Creating Domain Name in route 53
DOMAIN_NAME="muruga.site"  #Replace with own DOMAIN_NAME

#Now using loop concept to download all the instances

for instance in ${INSTANCES[@]}
do

    INSTACE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f --instance-type t3.micro --security-group-ids sg-0d8d7189bee7912bc --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query 'Instances[0].InstanceId' --output text)  # have instance id is replaced in the place of private ip, due to which public ip need to be query in this soo
    if [ $instance != "frontend" ]
    then
        IP=$(aws ec2 describe-instances --instance-ids $INSTACE_ID --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
        echo "$instance PRIVATE IP Address : $IP"
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTACE_ID --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
        echo "$instance PUBLIC IP Address : $IP"

    fi
    
    echo "$instance IP Address is : $IP"

    # Updating or creating records route 53 through aws cli  ->  its in stack over flow take the code from it and update records

    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating or updating record set for cognito endpoint"
        ,"Changes": [{
        "Action"              : "UPSERT"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$instance'.'$DOMAIN_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP'"
            }]
        }
        }]
    }'
done




  