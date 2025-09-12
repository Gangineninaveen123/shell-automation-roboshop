#!/bin/bash

#Start time of the script in seconds format
START_TIME=$(date +%s)
# Checking root access 
USERID=$(id -u)

# Creating Variables for Colours
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

# Creatring Logs folder variable , where logs ll be saved
LOGS_FOLDER="/var/log/roboshop-logs"
# not to have two end endpoints extension, so removing .sh for our convienince
SCRIPT_NAME=$(echo $0 | awk -F "." '{print $1F}')
# Creating Log file ending with .log ectenstion, ex: var/log/roboshop-logs/13-logs.log
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
#Creating absolute path, so we can access the app in any location with out any error, for ex: /app-> from this location also i can acces caatalogue code i app tier
SCRIPT_DIR=$PWD

# ************** note vvvvvv imp, where ever log is store in LOG_FILE, which shows on screen as output ex: echo, there i am going to use tee command [tee -a $LOG_FILE], so it can show  in screen as well as it store the info in LOG_FILE too.

# creating LOGS_FOLDER so, we can store our logs in it. [-p -> means, if same folder already created also it wont give error]
mkdir -p $LOGS_FOLDER
# script starting date and time, so easy like like which script executes at what time and need to store in LOG_FILE
echo "Script started and executed at: $(date)" | tee -a $LOG_FILE

# Checking user has root previlages to run or not
if [ $USERID -ne 0 ]
then
    echo -e " $R ERROR:: Please run the shell script with root user $N" | tee -a $LOG_FILE # here $R which starts colour as Red, and at ending $N ll make it as Normal.
    exit 1 # give other than zero[1-127] as exit code, so it ll not move forward from this step.
else
    echo "You are running with root user" | tee -a $LOG_FILE

fi

#, here $1 -> means takes exit code $? as input $2 argument, which is given in the code, while calliong function

VALIDATE()
{
     if [ $1 -eq 0 ]  # the exit code represents always sucess
    then
        echo -e " $2 is $G  Sucessfull.... $N" | tee -a $LOG_FILE
    else
        echo -e " $2 $R  is failure.... $N" | tee -a $LOG_FILE
        exit 1 # when ever the failure is there in shell script, then we should automatically give exit than zero, mainly 1
    fi
}

#disabling redis
dnf module disable redis -y &>> $LOG_FILE
VALIDATE $? "Disabling default redis version"

# Enabvling redis:7 version
dnf module enable redis:7 -y &>> $LOG_FILE
VALIDATE $? " Enabling Redis version:7 "

# Installing redis:7 version
dnf install redis -y &>> $LOG_FILE
VALIDATE $? "Installing redis:7 latest version"

# using stream line editor sed for changing local host 127.0.0.1 to 0.0.0.0 for connecting to external servers

sed -i -e "s/127.0.0.1/0.0.0.0/g" -e "/protected-mode/ c protected-mode no" /etc/redis/redis.conf  # here we are changing protected mode to no aswell [-e -> expression] i-> means permanenet
VALIDATE $? "Edited redis.conf to accept remote connections"

#enabling redis
systemctl enable redis &>> $LOG_FILE
VALIDATE $? "Enabling redis"

#Restart redis
systemctl start redis  &>> $LOG_FILE
VALIDATE $? "Restarting redis"

# endtime of script
END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e " Script execution completed sucessfully, $Y Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
