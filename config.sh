#!/bin/bash

# Retries
RETRY_TIMES=3
RETRY_WAIT=10 # seconds, wait before retrying

# Log path
LOG_PATH="./logs/"

# connection timeouts
CURL_CONNECT_TIMEOUT=5 # seconds
CURL_MAX_TIME=10 # seconds

# NOTIFY numbers and emails. leave empty to disable
NOTIFY_NUMBERS="+11234567890,+12223334567"
NOTIFY_EMAILS="test@example.com,hello@test.com"

# SMS
TWILIO_ACCOUNT_SID=""
TWILIO_AUTH_TOKEN=""
TWILIO_FROM_NUMBER=""

# EMAIL
# email method: one of "mail", "ssmtp", "sendmail", or "mandrill"
# for methods except "mandrill", make sure your env is configured
# for "mandrill" (mandrillapp.com), fill vars MANDRILL_KEY and MANDRILL_FROM_EMAIL
EMAIL_METHOD="mail"
MANDRILL_KEY=""
MANDRILL_FROM_EMAIL=""
