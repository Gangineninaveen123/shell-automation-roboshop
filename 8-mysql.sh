#!/bin/bash
source ./commoncode.sh

App_Name=mysql

#checking app is running with root access or not and calling function
check_root
#Setting up MYSQL ROOT PASSWORD - RoboShop@1
echo "Please enter the root password"
read -s MYSQL_ROOT_PASSWORD
echo -e "$MYSQL_ROOT_PASSWORD"

#installing mysql server
dnf install mysql-server -y &>> $LOG_FILE
VALIDATE $? "Installing mysql server"

#Enabling mysql
systemctl enable mysqld &>> $LOG_FILE
VALIDATE $? "Enabling mysql"

#starting mysql
systemctl start mysqld &>> $LOG_FILE
VALIDATE $? "Starting mysql"

#Setting up root password - Next, We need to change the default root password in order to start using the database service. Use password RoboShop@1 or any other as per your choice.
mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD &>> $LOG_FILE
VALIDATE $? "Starting mysql"


# endtime of script
print_time