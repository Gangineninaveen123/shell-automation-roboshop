#!/bin/bash
#start time
START_TIME=$(date +%s)
# Checking root access 
USER_ID=$(id -u)

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
if [ $USER_ID -ne 0 ]
then
    echo -e " $R ERROR:: Please run the shell script with root user $N" | tee -a $LOG_FILE # here $R which starts colour as Red, and at ending $N ll make it as Normal.
    exit 1 # give other than zero[1-127] as exit code, so it ll not move forward from this step.
else
    echo "You are running with root user" | tee -a $LOG_FILE

fi


#Root password to set up in order to start using the database service
echo -e "Please enter the root password to setup"
read -s MYSQL_ROOTPASSWORD


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

#installing MAVEN
dnf install maven -y &>> $LOG_FILE
VALIDATE $? "Installing MAVEN along with java"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user roboshop"
else
    echo -e "System user roboshop already created ... $Y Skipping $N"
fi


# Creating app directory to store our Catalogue code info
mkdir -p /app # if already create also, it ll not show error at run time [-p]
VALIDATE $? "Creating app directory"

#Downloading shipping code in tmp folder
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading shipping code"

#Unzipping shipping code info into app directory
rm -rf /app/* # i am deleteing the content in app directory, because in log files , its asking for oveeride the previous content, so simply ll delete the data, so no ovveride needed.
cd /app 
unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Unzipping shipping code info into app directory"

#Maven clean Package
mvn clean package &>> $LOG_FILE
VALIDATE $? "Packaging the shipping Application"

#Moving target/shipping-1.0.jar to shipping.jar file
mv target/shipping-1.0.jar shipping.jar  &>> $LOG_FILE
VALIDATE $? "Moving and renaming jar file"

#copying shipping.service file , dependencies in location /etc/systemd/system/shipping.service
cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service


#daemon-reload service to load to tell the systemd file
systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "DAEMON RELOADING"

#Enabling and starting shipping
systemctl enable shipping &>> $LOG_FILE
systemctl start shipping &>> $LOG_FILE
VALIDATE $? "Enable and Starting shipping"

#Installing MYSQL Client
dnf install mysql -y  &>> $LOG_FILE
VALIDATE $? "Installing mysql client"

#Load Schema, Schema in database is the structure to it like what tables to be created and their necessary application layouts.
mysql -h mysql.muruga.site -uroot -p$MYSQL_ROOTPASSWORD < /app/db/schema.sql &>> $LOG_FILE
mysql -h mysql.muruga.site -uroot -p$MYSQL_ROOTPASSWORD < /app/db/app-user.sql &>> $LOG_FILE
mysql -h mysql.muruga.site -uroot -p$MYSQL_ROOTPASSWORD < /app/db/master-data.sql &>> $LOG_FILE
VALIDATE $? "Loading MASTER data into mysql"


# Reastrt shipping
systemctl restart shipping  &>> $LOG_FILE
VALIDATE $? "Restarting shipping"

# endtime of script
END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))

echo -e " Script execution completed sucessfully, $Y Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
