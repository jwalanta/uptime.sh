#!/bin/bash

#
# url uptime checker
#

cd "$(dirname "$0")"
source config.sh
mkdir -p $LOG_PATH

# send_email $subject $body
function send_email() {
    subject=$1
    body=$2
    for email in $(echo $NOTIFY_EMAILS | sed "s/,/ /g"); do
        case "$EMAIL_METHOD" in
            mail)
                echo "$body" | mail -s "$subject" "$email"
                ;;
            ssmtp)
                echo "Subject: $subject\n\n$body" | ssmtp $email
                ;;
            sendmail)
                echo "Subject: $subject\n\n$body" | sendmail $email
                ;;
            mandrill)
                mandril_data="{\"key\": \"$MANDRILL_KEY\",\"raw_message\": \"From: $MANDRILL_FROM_EMAIL\nTo: $email\nSubject: $subject\n\n$body\"}"
                curl -s -o /dev/null 'https://mandrillapp.com/api/1.0/messages/send-raw.json' -d "$mandril_data"
                ;;
        esac
    done

}

# send_sms $message
function send_sms() {
    message=$1
    for n in $(echo $NOTIFY_NUMBERS | sed "s/,/ /g"); do
        curl -s -o /dev/null -X POST https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json \
        --data-urlencode "Body=$message" \
        --data-urlencode "From=$TWILIO_FROM_NUMBER" \
        --data-urlencode "To=$n" \
        -u $TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN    
    done
}

LOGFILE="$LOG_PATH/$(date +"%Y%m%d").log"
NOTIFICATIONS_LOGFILE="$LOG_PATH/notifications.log"
touch $NOTIFICATIONS_LOGFILE

CURL_WRITE_OUT="%{http_code} %{time_total} %{time_namelookup} %{time_connect} %{time_appconnect} %{time_pretransfer} %{time_redirect} %{time_starttransfer}"
CURL_OPTS="-s --write-out '$CURL_WRITE_OUT' --connect-timeout $CURL_CONNECT_TIMEOUT --max-time $CURL_MAX_TIME"

while read line; do
    url=$(echo "$line" | awk '{print $1}')
    status=$(echo "$line" | awk '{print $2}' | xargs)
    content=$(echo "$line" | awk '{$1=""; $2=""; print $0}' | xargs)
    
    # temp file for url content
    tmpfile=$(mktemp)
    
    CURL_CMD="curl $CURL_OPTS '$url' -o '$tmpfile'"

    for ((n=1;n<=$RETRY_TIMES;n++)); do

        CURL_OUTPUT=$(eval $CURL_CMD)
        CURL_EXIT_CODE=$?
        CURL_STATUS=$(echo $CURL_OUTPUT | awk '{print $1}')

        # check
        UPTIME_STATUS="OK"
        ERROR_MESSAGE=""

        # check for exit code
        if [ $CURL_EXIT_CODE -ne 0 ]; then
            UPTIME_STATUS="ERROR_CONNECT"
            ERROR_MESSAGE="Connection Error. Code: $CURL_EXIT_CODE"
        fi

        # check for status if needed
        if [[ "$UPTIME_STATUS" == "OK" && "$status" != "" && "$CURL_STATUS" != "$status" ]]; then
            UPTIME_STATUS="ERROR_STATUS"
            ERROR_MESSAGE="HTTP status error. Expected: $status, Returned: $CURL_STATUS"
        fi

        # check for content if needed
        if [[ "$UPTIME_STATUS" == "OK" && "$content" != "" ]]; then
            if ! grep -q "$content" $tmpfile; then
                UPTIME_STATUS="ERROR_CONTENT"
                ERROR_MESSAGE="Content error. '$content' missing"
            fi
        fi

        # save to log
        echo "$(date +%s) $(hostname) $url $UPTIME_STATUS $CURL_OUTPUT" >> $LOGFILE

        if [[ "$UPTIME_STATUS" == "OK" || "$n" == "$RETRY_TIMES" ]]; then 
            break
        else 
            # wait before retry
            sleep $RETRY_WAIT
        fi

    done

    # notify if error
    if [[ "$UPTIME_STATUS" != "OK" ]]; then 

        # check how many messages have been sent in the last one hour
        ONE_HR_AGO=$(date +%s -d '1 hour ago')
        NOTIFICATIONS_COUNT=$(awk -v ts="$ONE_HR_AGO" '$1 > ts' $NOTIFICATIONS_LOGFILE | wc -l)

        if [[ "$NOTIFY_LIMIT_PER_HOUR" == "" || "$NOTIFY_LIMIT_PER_HOUR" == "0" || "$NOTIFICATIONS_COUNT" -lt "$NOTIFY_LIMIT_PER_HOUR" ]]; then
            echo "$(date +%s) $url $ERROR_MESSAGE" >> $NOTIFICATIONS_LOGFILE
            send_email "Uptime fail $url" "$ERROR_MESSAGE"
            send_sms "Uptime fail $url. $ERROR_MESSAGE"
        fi

    fi

    rm $tmpfile

done < urls.txt
