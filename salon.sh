#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

echo -e "\n~~~~~ Welcome to my Salon. How can I help you? ~~~~~\n"

MAIN_MENU() {
    if [[ $1 ]]; then
        echo -e "\n$1"
    fi

    DISPLAY_SERVICES
}

DISPLAY_SERVICES() {
     if [[ $1 ]]; then
        echo -e "\n$1"
    fi
    echo -e "\nHere are the services we have available:"
    AVAILABLE_SERVICES=$($PSQL "select service_id,name from services order by service_id;")
    echo "$AVAILABLE_SERVICES" | while read SERVICE_ID BAR NAME; do
        echo "$SERVICE_ID) $NAME"
    done
}
CHOOSE_SERVICE(){
    echo "Choose a service"
    read SERVICE_ID_SELECTED

    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]; then
        # send to main menu
        DISPLAY_SERVICES "That is not a valid service number."
    fi

    SERVICE_ID=$($PSQL "select service_id from services where service_id=$SERVICE_ID_SELECTED order by service_id")

    # check if service in database
    if [[ -z $SERVICE_ID ]]; then
        MAIN_MENU "Service with number does not exist."

    else
        # get customer info
        echo -e "\nWhat's your phone number?"
        read CUSTOMER_PHONE_INPUT

        #get phone from database
        CUSTOMER_PHONE=$($PSQL "select phone from customers where phone='$CUSTOMER_PHONE_INPUT'")
        if [[ -z $CUSTOMER_PHONE ]]; then
            #add customer to customers and appointments
            echo -e "\nWhat's your name?"
            read CUSTOMER_NAME
            #insert into customers
            INSERT_CUSTOMER=$($PSQL "insert into customers(phone,name) values('$CUSTOMER_PHONE_INPUT','$CUSTOMER_NAME')")

            #Get Service time
            echo -e "\nAt what time?"
            read SERVICE_TIME
            #insert into appointments
            CUSTOMER_ID=$($PSQL "select customer_id from customers where phone='$CUSTOMER_PHONE_INPUT' and name='$CUSTOMER_NAME'")
            INSERT_APPOINTMENT=$($PSQL "insert into appointments(customer_id,service_id,time) values($CUSTOMER_ID,$SERVICE_ID,'$SERVICE_TIME')")
            #Final note I put you down
            SERVICE_NAME=$($PSQL "select name from services where service_id=$SERVICE_ID")
            echo "I have put you down for a $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g') at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
        else
            #Customer already exists in db
            echo -e "\nAt what time?"
            read SERVICE_TIME

            #insert into appointments
            CUSTOMER_ID=$($PSQL "select customer_id from customers where phone='$CUSTOMER_PHONE_INPUT'")
            INSERT_APPOINTMENT=$($PSQL "insert into appointments(customer_id,service_id,time) values($CUSTOMER_ID,$SERVICE_ID,'$SERVICE_TIME')")
            #Final note I put you down
            SERVICE_NAME=$($PSQL "select name from services where service_id=$SERVICE_ID")
            CUSTOMER_NAME=$($PSQL "select name from customers where customer_id=$CUSTOMER_ID")
            echo "I have put you down for a $(echo $SERVICE_NAME | sed -r 's/^ *| *$//g') at $SERVICE_TIME, $(echo $CUSTOMER_NAME | sed -r 's/^ *| *$//g')."
        fi

    fi

}

EXIT() {
  echo -e "\nThank you for stopping in.\n"
}

MAIN_MENU
CHOOSE_SERVICE
EXIT
