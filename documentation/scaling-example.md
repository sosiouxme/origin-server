Scaling Example
===============

Suppose we have a scaled application running PHP 5.3 with an embedded MongoDB
database.  When the application scales, additional gears are created that run
the php-5.3 and mongodb-2.2 cartridges, run httpd instances that listen for
incoming requests, and run the appropriate user code.  This user code may need
to use the database.  However, in this scenario, there is only one mongod
process! Although all the gears have the MongoDB cartridge, only the original
gear is running the daemon.

The MongoDB cartridge is written to the handle this situation.  There
are to aspects to handling this scaled situation:

* User code (PHP code, in this case) must connect to the appropriate
  database.

* Broker commands related to MONGODB must be forwarded to the MONGODB
  control script on the appropriate gear (the one running the daemon).

The app_ctl.sh script for the MONGODB cartridge handles the second
aspect by checking for the presence of the
$OPENSHIFT_MONGODB_DB_GEAR_UUID environment variable.  If this variable
exists, it has the UUID for the gear with the MongoDB daemon, and
$OPENSHIFT_MONGODB_DB_GEAR_DNS has the IP address of that gear.  The
app_ctl.sh script then uses these variables to open a ssh connection to
the appropriate gear, where it runs mongodb_ctl.sh to carry out the
action.  If $OPENSHIFT_MONGODB_DB_GEAR_UUID is not set on the gear
receiving the request, then this gear must be running the daemon, and so
it runs mongodb_ctl.sh directly.
