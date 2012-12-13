Communication between Broker and Node
=====================================

The node listens for communications from the broker.  The node cannot
initiate communications; only the broker can.  The broker issues requests to the
node via mcollective, and the mcollective agent on the node responds to these
requests.  The broker can request information from the node or direct the node
to take actions, such as starting or stopping an application, or configuring or
deconfiguring a cartridge.  The mcollective agent on the node responds using a
domain-specific language, which is described later in this document.  Using this
DSL, the node can inform the broker about errors or direct the broker to modify
state related to the application in the data store.

XXX Document the actions handled by the mcollective agent on the node.

The node runs an mcollective agent that reponds to requests defined in
/usr/libexec/mcollective/mcollective/agent/openshift.ddl and handled in
/usr/libexec/mcollective/mcollective/agent/openshift.rb.

The recognised requests include the "cartridge_do" request, which is used to
command the node to carry out a cartridge-related action.  To carry out these
actions, the agent uses oo-connectors (not to be confused with the connection
hooks of cartridges) to carry out actions.  oo-connectors are executable files
stored on the node under  /usr/bin/ named with the "oo-" prefix.  XXX Turns out
I misunderstood the oo- commands.  They actually are redundant: the
implementations of oo-app-create, oo-app-destroy, oo-authorized-ssh-key-add,
oo-authorized-ssh-key-remove, oo-broker-auth-key-add, oo-broker-auth-key-remove,
oo-cartridge-list, oo-connector-execute, oo-env-var-add, oo-env-var-remove,
oo-get-quota, and oo-set-quota are just thin code wrappers that do exactly the
same as the mcollective agent code.  Presumably, they are provided for
convenience, so that a system administrator can run oo-action to perform
manually the action that the mcollective agent performs.

The following requests are defined for the mcollective agent:

* cartridge_do name action args —  run the specified action on the specified
  cartridge.

* execute_parallel joblist —  run the specified actions in parallel.

* get_all_gears —  get information about all gears (note: OSE-1.0 requires an
  empty hash for its argument, but I cannot figure out how to pass that argument
  in).

* get_all_active_gears —  get a list of active gears (note: this action is not
  defined in OSE-1.0).

* set_district gear_uuid active —  set the node's district to the given uuid and
  set its active flag.

* has_app uuid application —  returns whether the node contains an instance of
  the named cartridge.

* has_embedded_app uuid application —  returns whether the node contains an
  instance of the named embedded cartridge (note: instead of application, the
  parameter is named embedded_type in OSE-1.0).

* has_uid_or_gid —  returns whether the specified uid or gid are used on the
  node.

* echo —  echoes a string back.

Following is an explanation of the parameters for the above actions:

TODO: Improvement needed below.

* name —  the name of a cartridge (string).

* action —  the name of an action (string).

* args —  an array of arguments (array of strings).

* joblist —  an array of triplets of name action args.

* gear_uuid —  the uuid of a district.

* active —  a Boolean value (true or false) indicating whether the district is
  active.

* uuid —  the uuid of a gear.

TODO: Differentiate between arguments in the args array and named parameters.

The following actions are defined:

* app-create

* app-destroy

* env-var-add

* env-var-remove

* broker-auth-key-add

* broker-auth-key-remove

* authorized-ssh-key-add

* authorized-ssh-key-remove

* configure

* deconfigure

* update-namespace

* tidy

* deploy-httpd-proxy

* remove-httpd-proxy

* move

* pre-move

* post-move

* info

* post-install

* post-remove

* pre-install

* reload

* restart

* start

* status

* stop

* force-stop

* add-alias

* remove-alias

* threaddump

* cartridge-list

* expose-port

* conceal-port

* show-port

* system-messages

* connector-execute

* get-quota

* set-quota

cartridge-list returns the list of available cartridge, as determined by
scanning the /usr/libexec/openshift/cartridges directory.

TODO: Document them!

The DSL by which the node (mcollective agent) can issue commands to the broker
is parsed in Application.process_cartridge_commands
(controller/app/models/application.rb).  The following commands are recognised:

* SYSTEM_SSH_KEY_ADD key —  add the given system ssh key (unused).

* SYSTEM_SSH_KEY_REMOVE —  remove the current system ssh key (unused).

* APP_SSH_KEY_ADD name key —  add the given key with the given name to the
  application.

* APP_SSH_KEY_REMOVE name —  delete the key with the given name from the
  application.

* ENV_VAR_ADD key value —  see section on environment variables.

* ENV_VAR_REMOVE key —  ditto.

* APP_ENV_VAR_REMOVE key —  ditto.

* BROKER_KEY_ADD —  see section on broker authentication keys.

* BROKER_KEY_REMOVE —  ditto.
