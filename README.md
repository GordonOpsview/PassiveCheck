# PassiveCheck

Scripts to submit passive check results using curl and the REST API. Useful if run as a `cron` job on a monitored host.

### passivecheck.sh

`passivecheck.sh` requires 3 arguments: **command**, **warn** and **crit**.
 - **Command**: A command or script that passivecheck.sh will run. At present, it must return a number.
 - **Warn** and **crit** are values to test the number against.

Example: Check how many processes user “bob” is running, with warn=100 and crit=250.
```
passivecheck.sh "ps -u bob | wc -l" 100 250
```
If `command` returns an error or a non-number, the new service check state will be set to `UNKNOWN`, and the comment and perfdata will describe the error.

For more complex tests than number value comparisons, this script will need editing.

### passivesubmitter.sh

`passivesubmitter.sh` submits a result, but accepts the state and perfdata as arguments instead of doing any checking itself.

It should be called by a script or command that does a more complex test and passes the new state and perfdata as arguments.
