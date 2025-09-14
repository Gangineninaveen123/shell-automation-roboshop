#!/bin/bash
source ./commoncode.sh

App_Name=mysql

#checking app is running with root access or not and calling function
check_root
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
print_time