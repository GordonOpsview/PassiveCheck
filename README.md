# PassiveCheck

A script to submit passive check results using curl and the REST API. Useful if run as a `cron` job on a monitored host.

It requires 3 arguments: **command**, **warn** and **crit**.
 - **Command**: A command or script that passivecheck.sh will run. At present, it must return a number.
 - **Warn** and **crit** are values to test the number against.

Example: Check how many processes user “bob” is running, with warn=100 and crit=250.
```
passivecheck.sh "ps -u bob | wc -l" 100 250
```
If command returns an error or a non-number, the new service check state will be set to `UNKNOWN`, and the comment and perfdata  will describe the error.

For more complex tests than number values, this script will need editing.
