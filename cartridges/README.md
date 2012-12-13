Logical View of a Cartridge
===========================

Logically, a cartridge comprises a set of hooks, connection hooks,
cartridge-specific files, and metadata.  We define the terms "hooks" and
"connection hooks" now.

Hooks
: Define methods to which the cartridge responds.
Hooks are executed by the mcollective agent on the node on behalf of the broker.
Hooks are used to handle instantiation and deletion of instances (lifecycle control)
Hooks output a sequence of commands in a DSL that is parsed by the broker and
described below.

Connection hooks
: Define methods to which the cartridge responds.  Connection hooks are executed
directly by hooks and facilitate inter-cartridge communication.  A typical
example is that a database cartridge provides a connection hook that outputs the
URL for connecting to the database.  The output of connection hooks is
unstructured data

The cartridge must have hooks that the node (specifically the OpenShift
mcollective agent) can invoke to control the life-cycle of an instance of the
cartridge (i.e., configure, start, stop, deconfigure).  These hooks may execute
system binaries (such as the system httpd binary) or binaries that are included
in the cartridge (such as a custom server binary).

A cartridge may include cartridge-specific data such as configuration
files, executable binaries, or other files required by an instance of the
cartridge and used by its hooks.

The metadata included in a cartridge include the following:

* Name, version, description, licence, and Web site.

* Dependences on other cartridges and on system packages.

* Environment variables and arbitrary "properties" (key-value pairs associated
  with the cartridge).

* Description of profiles and components (described below).


Profiles, Components, and Connectors
====================================

For complex cartridges such as database systems, a cartridge may comprise
multiple distinct "components" that can run on one or more gears.
For example, the MySQL cartridge can be configured with a master-slave profile
that has a master component and separate slave components.

Profile
: TODO.

Component
: TODO.

A particular component may publish "connectors" to which other components may
subscribe.  For example, the MySQL cartridge's master component publishes the
get-master connector and subscribes to the get-slave connector while the slave
component publishes a get-slave connector and subscribes to the get-master
connector.

Connector
: TODO.


Physical Layout of a Gear
=========================

Logically, a cartridge is instantiated on a gear.  Concretely, the files of an
instantiated cartridge are stored within a gear's directory structure.  The base
directory structure of a gear has the  following layout:

    .env/
        .uservars
    .ssh/
    .tmp/
    .sandbox/
    app-root/
        data/
        runtime/
            data -> ../data
            repo/
        repo -> runtime/repo (writable symlink)
    git/ (non-writable area for git repositories)

The gear user can write to app-root/ and the directories thereunder, .env/,
and .ssh/.  Access is restricted to all other directories.

.env/  contains  shell scripts, conventionally one per variable, where each
shell script is named by the variable's name and contains a single export
command that sets and exports that variable.  For example, the file .env/FOO
might contain the line "export FOO=foo".

.env/uservars is for future use.

.ssh/ contains authorized public keys.

git/ hosts the gear's git repository and is populated by the Web cartridge.
As said above, the gear user cannot write to this directory.  However, an
instantiated Web cartridge will typically put a repository underneath git/
to which the user will be able to write to push changes.


Physical Layout of a Cartridge
==============================

The  following describes the structure of a cartridge as installed on a node host (as opposed to a cartridge that has been instantiated on a gear):

    /usr/libexec/openshift/cartridges/name/
        info/
            bin/
                app_ctl.sh
            hooks/
            connection-hooks/ (optional)
            data/
                git_template.git/ (optional)
            build/ (optional)
                NOTES.txt
            changelog (optional)
            configuration/ (optional)
            control (optional)
            manifest.yml
        LICENSE
        COPYRIGHT
    /etc/openshift/cartridges/name -> /usr/libexec/openshift/cartridges/name/info/configuration

info/bin/ contains helper scripts for hooks and other cartridge-specific
executable binaries.

info/bin/app_ctl.sh provides life-cycle control, including start and
stop actions.  This hook must be included in any cartridge.

info/hooks/ contains hooks for mcollective.

info/data/git_template.git/ contains the initial git repository that is cloned
to the git/ directory when the cartridge is instantiated.

info/connection-hooks/ contains hooks that other cartridges can call to get
information from the cartridge.

info/data/ contains larger cartridge-specific data required for instantiation.

info/build/NOTES.txt contains the name, build steps, dependences, and other
packaging notes for the cartridge.  NOTES.txt files follow a common structure,
but they are intended for human readers.

info/configuration/ contains cartridge-specific configuration templates.

The info/changelog, LICENSE, and COPYRIGHT files are not used by any code, but
they are all conventionally included in a cartridge.

The manifest.yml file contains the descriptor of the cartridge, which comprises
the name, description, dependences, environment variables, and other metadata
about the cartridge.

The top-level /usr/libexec/openshift/cartridges/name/ directory may include
additional directories.  For example, the cron cartridge includes a jobs/
directory with cronjob files for different intervals.


Descriptor
==========

The descriptor of a cartridge, stored in info/manifest.yml, is read by
OpenShift::Node#get_cartridge_list and #get_cartridge_info class methods.  The
get_cartridge_list method is used, in turn, by the cartridge-list action,
described in the [documentation on communication between broker and node](../documentation/communication-between-broker-and-node.md).
(The get_cartridge_info command is exposed by the
/usr/bin/oo-cartridge-list executable and is otherwise unused.) The
broker uses the cartridge-list action to get the descriptors for all the
cartridges available on a node.  The broker uses these descriptors to
instantiate cartridges on the node.


Hooks
=====

A typical cartridge defines pre-install, configure, and deconfigure hooks, and
other hooks may be defined as well.  However, it is not required to define any
hooks.  In this section, we will describe the purpose and typical behaviours of
different hooks.

The pre-install hook is run before a cartridge is instantiated and typically
checks for dependencies to ensure that it will be possible to instantiate the
cartridge.  For example, the php cartridge checks that the httpd and php
packages are installed.  If they are not both installed, the pre-install signals
an error to inhibit the instantiation from proceeding.

The configure hook typically performs the following steps:

1. Disable cgroups for performance increase during configuration.

2. Verify that the cartridge is not already instantiated (as indicated by the
   presence of a cart_name/ directory on the gear).

3. Clone info/data/git_template.git (or an external repository, if one is
   specified) to git/app_name.git.

4. Create the directory structure for the cartridge instance on the gear:

       ```
       cart_name/
           run/
           tmp/
           ci/
           repo -> ../app-root/repo
           data -> ../app-root/data
           runtime -> ../app-root/runtime
       ```

5. Check git/app_name.git out into app-root/repo.
       
6. Set appropriate ownership:
       
   * the gear's home directory is owned by root:root;
       
   * app-root/ is owned by the gear user;
       
   * everything under app-root/ is owned by the root and the gear user's group;
       
   * cart_name/ is owned by root;
       
   * cart_name/app_name_ctl.sh is owned by root;
       
   * everything else under cart_name/ is owned by the gear user.
    
7. Set appropriate SELinux contexts on the following (recursively):

       ```
       git/
       app-root/
       cart_name/
       the gear's home directory
       .env/uservars
       ```

8. Populate the .env/ directory:

   1. create .env/.uservars/ and the .env/USER_VARS script, which sets
      variables according to the contents of .env/.uservars (currently unused);

   2. create .env/OPENSHIFT_cart_name_LOG_DIR with the value cart_name/logs/
      (cart_name is sanitised in the filename to remove any non-alphabetic
      symbols and convert the remaining symbols to upper-case);

   3. create .env/OPENSHIFT_INTERNAL_IP with the node's IP address as its value;

   4. create .env/OPENSHIFT_INTERNAL_PORT with the value 8080 (the default port
      to which the port proxy forwards connections to the application);

   5. create .env/OPENSHIFT_cart_name_IP and .env/OPENSHIFT_cart_name_PORT,
      usually with the same values as OPENSHIFT_INTERNAL_IP and
      OPENSHIFT_INTERNAL_PORT, respectively (cart_name is again sanitised as
      described above);

   6. create .env/OPENSHIFT_REPO_DIR this is now done by the UnixUser model;

   7. create .env/PATH.

9. Start the app by executing `info/bin/app_ctl.sh start`.

10. Restart httpd if the cartridge needs it.

11. Re-enable cgroups.


TODO: The following hooks need to be documented:
* configure-jbosseap-6.0
* control-scripts
* deconfigure
* deploy-httpd-proxy
* move
* post-move
* pre-destroy
* pre-install
* pre-move
* reload
* remove-httpd-proxy
* restart
* start
* status
* stop
* threaddump

The following hooks are deprecated:

* expose-port, show-port, and conceal-port ([announced 2013-01-14](http://lists.openshift.redhat.com/openshift-archives/dev/2013-January/msg00038.html)).


Logical View of an Instantiated Cartridge
=========================================

An instantiated cartridge has the hooks, connection hooks, and metadata of the
cartridge of which it is an instance, as well as data for the instance—i.e.,
state.  This state is stored in two places: some state is stored in the
OpenShift data-store while some is stored on-disk.  Some state is stored
redundantly in both locations.


Physical Layout of an Instantiated Cartridge
============================================

A cartridge is instantiated by cloning parts of its file structure into a gear
and running the configure hook.  This configure hook may create files and send
commands back to the broker to add metadata to the datastore.

An instantiated cartridge has state associated with its application in the
db.user.username.apps collection in the data store:

* app name;

* namespace;

* installed cartridges;

* cartridge properties (e.g., authentication credentials);

* scaling data;

* ssh keys;

* environment variables.

An instantiated cartridge also has state associated with its gear on disk under /var/lib/openshift/uuid/:

    .env/
    app-root/
        data/
        repo -> runtime/repo
        runtime/
            repo/
            data -> ../data
    git/
        app_name.git/
        hooks/
            pre-receive
            post-receive
            (other hooks)
    *cart_name*/
       ci/
       data -> ../app-root/data
       run/
       tmp/
       repo -> ../app-root/repo
       runtime -> ../app-root/runtime

app-root/data is unstructured data; it typically includes deployed application
code.

app-root/repo/*name*.git/ is the checked out contents of the bare git repo
stored under git/*name*.git/.

*cart_name*/ci/ is used by Jenkins to clone and build the application.

*cart_name*/data/ is used for ephemeral data.
       
*cart_name*/run/ is used for PID files for any daemons that constitute the
cartridge.

As you can see, the instantiated cartridge is provided a top-level directory
(/var/lib/openshift/uuid/*cart_name*) underneath the gear's home directory
(/var/lib/openshift/uuid/).  Under this top-level directory, there are symlinks
to gear-level directories for state (app-root/data), the git repo
(app-root/repo), and other run-time state (app-root/runtime).  There are also
directories that are private to the instantiated cartridge for Jenkins
continuous integration (ci/) and other, cartridge-specific purposes.  For
example, the php cartridge (which is named php-5.3) includes a php-5.3/sessions/
directory for application session information and a php-5.3/logs/ directory for
log files for httpd.
