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
    mandril_data="{\"key\": \"$MANDRILL_KEY\",\"raw_message\": \"From: $MANDRILL_FROM_EMAIL\nTo: $NOTIFY_EMAILS\nSubject: $subject\n\n$body\"}"
    curl -s -o /dev/null 'https://mandrillapp.com/api/1.0/messages/send-raw.json' -d "$mandril_data"
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
CURL_WRITE_OUT="%{http_code} %{time_total} %{time_namelookup} %{time_connect} %{time_appconnect} %{time_pretransfer} %{time_redirect} %{time_starttransfer}"
CURL_OPTS="-s --write-out '$CURL_WRITE_OUT' --connect-timeout $CURL_CONNECT_TIMEOUT --max-time $CURL_MAX_TIME"

while read line; do
    url=$(echo "$line" | awk '{print $1}')
    status=$(echo "$line" | awk '{print $2}' | xargs)
    content=$(echo "$line" | awk '{$1=""; $2=""; print $0}' | xargs)
    
    # temp file for url content
    tmpfile=$(mktemp)
    
    CURL_CMD="curl $CURL_OPTS '$url' -o '$tmpfile'"

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
    echo "$(date +%s) $url $UPTIME_STATUS $CURL_OUTPUT" >> $LOGFILE

    # notify if error
    if [[ "$UPTIME_STATUS" != "OK" ]]; then 
        send_email "Uptime fail $url" "$ERROR_MESSAGE"
        send_sms "Uptime fail $url. $ERROR_MESSAGE"
    fi

done < urls.txt