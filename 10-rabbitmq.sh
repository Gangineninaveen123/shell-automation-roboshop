#!/bin/bash
#start time
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

#Setting up rabbitmq PASSWORD, but give the pasword as - roboshop123[y beacause, its already setup with rabbitmq, payment and dispatchaswell by shiva]
echo "Please enter the root password"
read -s RABBITMQ_PASSWORD
echo -e "$RABBITMQ_PASSWORD"

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

#Copying rabbit mq file to yum.reposd for dependencies configurations
cp $SCRIPT_DIR/10-rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo
VALIDATE $? "Copying raqbbitmq repo file to yum.repos.d file for dependencies configurations"

#Installing rabbitmq server
dnf install rabbitmq-server -y &>> $LOG_FILE
VALIDATE $? "Installing rabbitmq server"

#Enable rabbitmq server
systemctl enable rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Installing rabbit mq server"

#Starting rabitmq server
systemctl start rabbitmq-server &>> $LOG_FILE
VALIDATE $? "Starting rabitmq server"

#RabbitMQ comes with a default username / password as guest/guest. But this user cannot be used to connect. Hence, we need to create one user-roboshop Password-roboshop123
rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD &>> $LOG_FILE
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $LOG_FILE


# endtime of script
END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e " Script execution completed sucessfully, $Y Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE


