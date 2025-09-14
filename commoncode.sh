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

# Creating app directory and app setup
app_setup(){
    #Creating system user roboshop to run the roboshop app
    #while, running it on second time, i got an error at system user gort failed, so using idempotency : sol for this is idempotency->, which irrespective of the number of times you run, nothing changes

    id roboshop &>>$LOG_FILE
    if [ $? -ne 0 ]
    then
        useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
        VALIDATE $? "Creating system user roboshop"
    else
        echo -e "System user roboshop already created ... $Y Skipping $N"
    fi

    # Creating app directory and app setup to store our apptier module code info
    mkdir -p /app # if already create also, it ll not show error at run time [-p]
    VALIDATE $? "Creating app directory"

    #Downloading app code in tmp folder
    curl -o /tmp/$App_Name.zip https://roboshop-artifacts.s3.amazonaws.com/$App_Name-v3.zip &>>$LOG_FILE
    VALIDATE $? "Downloading $App_Name code"

    #Unzipping app code info into app directory
    rm -rf /app/* # i am deleteing the content in app directory, because in log files , its asking for oveeride the previous content, so simply ll delete the data, so no ovveride needed.
    cd /app 
    unzip /tmp/$App_Name.zip &>>$LOG_FILE
    VALIDATE $? "Unzipping $App_Name code info into app directory"

}
#nodejs install
nodejs_setup(){
    # Disabling default nodejs Version
    dnf module disable nodejs -y &>>$LOG_FILE
    VALIDATE $? "Disabling default nodejs Version"

    #Enabling nodejs Version 20 as per developers choice
    dnf module enable nodejs:20 -y &>>$LOG_FILE
    VALIDATE $? "Enabling nodejs Version 20 as per developers choice"

    #Installing Nodejs
    dnf install nodejs -y &>>$LOG_FILE
    VALIDATE $? "Installing nodejs 20 version"

    #installoing dependencies
    npm install &>>$LOG_FILE
    VALIDATE $? "Installing npm dependencies"

}

#system d setup service file
systemd_setup(){
    cp $SCRIPT_DIR/$App_Name.service /etc/systemd/system/$App_Name.service
    VALIDATE $? "Copying $App_Name service file for systemctl services"

    #daemon-reload, enable and start $App_Name
    systemctl daemon-reload &>>$LOG_FILE
    systemctl enable $App_Name &>>$LOG_FILE
    systemctl start $App_Name &>>$LOG_FILE
    VALIDATE $? "daemon-reload, enable and start $App_Name"
}
# Checking user has root previlages to run or not
check_root(){
    if [ $USERID -ne 0 ]
    then
        echo -e " $R ERROR:: Please run the shell script with root user $N" | tee -a $LOG_FILE # here $R which starts colour as Red, and at ending $N ll make it as Normal.
        exit 1 # give other than zero[1-127] as exit code, so it ll not move forward from this step.
    else
        echo "You are running with root user" | tee -a $LOG_FILE

    fi
}


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

#Printing total time, how much the app takes to executes all the code

print_time()
{
    # endtime of script
    END_TIME=$(date +%s)
    TOTAL_TIME=$(($END_TIME - $START_TIME))

    echo -e " Script execution completed sucessfully, $Y Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
}