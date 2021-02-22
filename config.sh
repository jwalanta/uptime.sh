#!/bin/bash

# Retries
RETRY_TIMES=3
RETRY_WAIT=10 # seconds, wait before retrying

# Log path
LOG_PATH="./logs/"

# connection timeouts
CURL_CONNECT_TIMEOUT=5 # seconds
CURL_MAX_TIME=10 # seconds

# NOTIFY
NOTIFY_NUMBERS="+11234567890,+12223334567"
NOTIFY_EMAILS="test@example.com,hello@test.com"

# SMS
TWILIO_ACCOUNT_SID=""
TWILIO_AUTH_TOKEN=""
TWILIO_FROM_NUMBER=""

# EMAIL
MANDRILL_KEY=""
MANDRILL_FROM_EMAIL=""
