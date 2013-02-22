Communication between Broker and Node
=====================================

The main vector of command and control in OpenShift is MCollective,
which adds a logical layer on top of a messaging bus joined by brokers
and nodes.

The broker issues requests to the node via MCollective, and the
MCollective agent on the node responds to these requests.  The node only
listens for MCollective communications from the broker.  The node cannot
initiate communications via MCollective; only the broker can. This is
part of the design for security isolation.

The broker can request information from the node or direct the node to
take actions, such as starting or stopping a gear, or configuring
or deconfiguring a cartridge.  The MCollective agent on the node responds
using a domain-specific language (DSL) described below.  Using this DSL,
the node can inform the broker about errors or direct the broker to
modify state related to the application in the data store.

Broker interaction with MCollective is mediated
by the OpenShift::MCollectiveApplicationContainerProxy class
[mcollective_application_container_proxy.rb](../plugins/msg-broker/mcollective/lib/openshift/mcollective_application_container_proxy.rb)
which acts as an MCollective client.

Node hosts supply an MCollective agent that reponds to requests defined in
[/usr/libexec/mcollective/mcollective/agent/openshift.ddl](../msg-common/agent/openshift.ddl)
and handled in
[/usr/libexec/mcollective/mcollective/agent/openshift.rb](../plugins/msg-node/mcollective/src/openshift.rb).
The standard rpcinfo MCollective agent is also used
(/usr/libexec/mcollective/mcollective/agent/rpcutil.{ddl,rb}). A great way
to watch requests on the node host is to set the logging level to "info"
in /etc/mcollective/server.cfg and watch the /var/log/mcollective.log
file as you interact with the broker.

## Anatomy of an MCollective request ##

First, each request specifies an agent. We will only discuss the openshift
agent; the rpcinfo agent is standard MCollective functionality, typically
retrieving facts or discovering nodes via filter.

Each openshift request specifies an overall @action corresponding to
a method of the same name with the _action suffix in the [node
agent](../plugins/msg-node/mcollective/src/openshift.rb).

At this writing, the most common actions are:

* execute: directly executes an arbitrary oo_ method in the agent.
* cartridge_do: this is the workhorse for gear and cartridge actions. It
wraps the execute action, but does a lot of parameter validation and
sanitizing. In addition to calling hooks on actual cartridges, the
"openshift-origin-node" cartridge may be specified for node actions like
retrieving cartridge manifests or creating an empty gear.
* execute_parallel: something of a misnomer, actually performs multiple
"execute" actions, but at time of writing they are executed sequentially
to avoid known concurrency problems.

These generic actions delegate to a more specific oo_ method in the agent
according to an :action parameter (for clarity we call these sub:actions
below).  These methods are typically thin wrappers to functionality
implemented in other parts of the code. For testing purposes, many of
these are paralleled in similarly-named scripts on the node host.

### Example ###

An example may help illuminate this. Here is an example request
as displayed in the MCollective agent log:

	INFO -- : openshift.rb:359:in 'cartridge_do_action' cartridge_do_action call /
	request = #<MCollective::RPC::Request:0x7fcf836c91e8
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:cartridge=>"openshift-origin-node",
	   :args=>
	    {"--with-app-uuid"=>"2cdbea4dbde8407ea523592eba9246f2",
	     "--with-namespace"=>"demo",
	     "--with-container-name"=>"jbs",
	     "--with-container-uuid"=>"2cdbea4dbde8407ea523592eba9246f2",
	     "--with-app-name"=>"jbs"},
	   :action=>"app-create",
	   :process_results=>true},
	 @sender="broker.example.com",
	 @time=1361453856,
	 @uniqid="8180d4886cf94f18a8391995bfcfc9d8">

Here, a request with @action "cartridge_do" and sub:action "app-create"
calls the oo_app_create agent method with specified :args. This method is
paralleled by the /usr/bin/oo-app-create script with the same parameters
as :args.

A quick explanation of the :args above, as you will see them frequently:

* --with-container-uuid specifies a UUID for the gear.
* --with-app-uuid specifies a UUID for the *application*. The same UUID
is used for the first gear of an application, so this will often
be the same as the gear UUID, but is different for gears of a scaled app.
* --with-app-name gives the user-specified application name, or for
extra gears in a scaled application, part of the UUID is used.
* --with-namespace gives the namespace, or user "domain" name, for the application.

Other parameters may be documented with the agent methods, or you may
need to comb through the source code or watch the request log to discover
the expected parameters and their meanings. N.B.: you will also see that
the client often supplies parameters that are unnecessary.

### Other available actions ###

Other _action methods defined in the [node
agent](../plugins/msg-node/mcollective/src/openshift.rb) are:

* echo
* get_all_gears
* get_all_active_gears
* set_district
* has_app
* has_embedded_app
* has_uid_or_gid

Be aware that most of these do not log their actions, so you will not
see them in the logs.

### Available sub:actions ###

These are translated to oo_ methods in the agent which wrap the
functionality in other parts of the code:

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

These should really be documented in the code, but most are not yet.

## How the broker knows cartridge specifics ##

Cartridge manifests are defined in cartridges on the node hosts, but the
broker initiates the calls to the hooks specific to each cartridge. How
does the broker know that e.g. the jbosseap cartridge requires the
publish_jboss_cluster hook to be called?

The broker uses the cartridge-list sub:action to retrieve the
list of available cartridges, as determined by scanning the
/usr/libexec/openshift/cartridges directory on a single node. Each
cartridge manifest is also retrieved so that the broker knows how to
interact with each cartridge. The result is cached at the broker
to avoid repeating the fairly-lengthy and rarely-changing response.

## The response ##

In some cases the node (MCollective agent) responds
to the broker with a command DSL that is parsed in
[Application.process_cartridge_commands](../controller/app/models/application.rb).
The following commands are recognised:

* SYSTEM_SSH_KEY_ADD key —  add the given system ssh key (unused).

* SYSTEM_SSH_KEY_REMOVE —  remove the current system ssh key (unused).

* APP_SSH_KEY_ADD name key —  add the given key with the given name to the
  application (useful for scaled applications where the head gear syncs to the other gears).

* APP_SSH_KEY_REMOVE name —  delete the key with the given name from the application.

* ENV_VAR_ADD key value —  see [section on environment variables](environment_variables.md).

* ENV_VAR_REMOVE key —  ditto.

* APP_ENV_VAR_REMOVE key —  ditto.

* BROKER_KEY_ADD —  see [section on broker authentication keys](how_nodes_act_on_behalf_of_users.md).

* BROKER_KEY_REMOVE —  ditto.

