#!/bin/bash
source ./commoncode.sh

App_Name=rabbitmq

#checking app is running with root access or not and calling function
check_root

#Setting up rabbitmq PASSWORD, but give the pasword as - roboshop123[y beacause, its already setup with rabbitmq, payment and dispatchaswell by shiva]
echo "Please enter the root password"
read -s RABBITMQ_PASSWORD
echo -e "$RABBITMQ_PASSWORD"

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
print_time


