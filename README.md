# uptime.sh

Shell / Curl based website uptime checker and notifier. Poor man's pingdom.

Uses [Twilio](https://www.twilio.com/) to send sms. For email, uses `mail`, `sendmail`, `ssmtp`, or [Mandrill](https://www.mandrillapp.com).

- Check just the connection, http status, or a string in the content fetched
- Configurable multiple retries before notifying

## Usage

Edit `config.sh` and modify the variables.

Run `run.sh` using cron job at desired intervals. The script will go through the list in `urls.txt` for uptime and send notifications for any errors.

## Log format

The script writes the log to file `logs/YYYYMMDD.log`, where YYYY = year, MM = month, DD = day. The line is in the following format:

`unix_timestamp hostname url status http_code time_total time_namelookup time_connect time_appconnect time_pretransfer time_redirect time_starttransfer`

The `time_*` values are from curl `--write-out` format variables. 

## URLs file format 

The urls to test are in `urls.txt` file, one per line, and are in one of the following formats:

`https://www.example.com`

Try to connect to the url and send notification if connection fails.

`https://www.example.com 200`

Try to connect to the url and verify that the return http status is 200.

`https://www.example.com 200 <title>Example</title>`

Try to connect to the url and verify that the return http status is 200, and the content contains the string `<title>Example</title>`
