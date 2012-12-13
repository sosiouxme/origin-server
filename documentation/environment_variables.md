Environment Variables
=====================

Environment variables are stored in two locations: under .env/ in the gear's
home directory, and in the data store.  Interfaces are provided for setting
environment variables from the broker or from the cartridge.  The broker can
direct a gear to create a new environment variable:

1. Application.add_env_var calls Gear.add_env_var on the appropriate Gear.

2. Gear.add_env_var executes /usr/bin/oo-env-var-add on the node.

3. /usr/bin/oo-env-var-add calls OpenShift::UnixUser.add_env_var for the
   appropriate UnixUser.

4. OpenShift::UnixUser.add_env_var creates a file in .env/.

In particular, when an application is created, the broker uses these interfaces
to replicate all of the environment variables stored in the data-store for the
OpenShift user into the new application's gear.  (In detail, Application.create
calls GroupInstance.add_gear, which calls Application.add_node_settings, which
calls Gear.env_var_job_add for each environment variable, which calls
OpenShift::ApplicationContainerProxy.provider.get_env_var_add_job, which calls
RemoteJob.new with "env-var-add" to run the env-var-add action on the node,
which calls OpenShift::UnixUser.add_env_var.)

Going in the other direction, a cartridge can instruct the broker to add a
variable to the OpenShift user's record in the data-store using the
add_env_var() routine in the info/lib/util library of the abstract cartridge:

1. add_env_var() issues an ENV_VAR_ADD command to the broker.

2. The mcollective proxy on the broker calls CloudUser.add_env_var for the appropriate OpenShift user.

3. CloudUser.add_env_var puts the variable in the data-store.

Thus if a cartridge uses the add_env_var() shell routine, the environment
variable is stored in the data-store, whence it will be propagated to
subsequently created gears.  The cartridge must also add the appropriate file
directly .env/ for the gear on which it is running.  If the cartridge adds the
file under .env/ without invoking add_env_var(), the new environment variable is
not stored in the data-store and is not shared with other gears.

If the broker calls the Application.add_env_var or Gear.add_env_var method, the
environment variable is stored in .env/ on the gear.  If the broker calls
CloudUser.add_env_var (e.g.  via Application.user), the environment variable is
stored in the data-store.

For each of the add methods or commands above, there exists a corresponding
remove method or command: Application.remove_env_var, Gear.remove_env_var,
oo-env-var-remove, OpenShift::UnixUser.remove_env_var, remove_env_var(),
CloudUser.remove_env_var, and ENV_VAR_REMOVE.

Additionally, for variables that are stored only in .env/ and not in the
data-store, the info/lib/util library of the abstract cartridge provides an
app_remove_env_var() routine.  app_remove_env_var() causes the named environment
variable to be deleted from every gear.  It does not attempt to remove the
environment variable from the data-store.  Thus app_remove_env_var() is suitable
for cleaning up variables that were created by writing directly to .env/.

app_remove_env_var() works as follows:

1. app_remove_env_var() issues an APP_ENV_VAR_REMOVE.

2. The mcollective proxy on the broker calls Gear.env_var_job_remove for each gear.

3. Gear.env_var_job_remove executes oo-env-var-remove on the node.

4. oo-env-var-remove calls remove_env_var for the appropriate OpenShift::UnixUser.

5. OpenShift::UnixUser.remove_env_var deletes the file from .env/.
