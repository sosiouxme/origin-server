Interpreted example of MCollective logs
=======================================

Here is a walkthrough of some common MCollective interactions with
commentary on what is going on. This is `/var/log/mcollective.log`
cleaned up a bit for readability. Note that line numbers in openshift.rb
may differ from what is shipped currently.

Simple application with a database
==================================

We start with creating a PHP application:

	INFO: cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc9059e9988
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"phpapp",
	     "--with-app-name"=>"phpapp",
	     "--with-container-uuid"=>"cc9beb39785a45b9b97bdc6951fc8dbf",
	     "--with-app-uuid"=>"cc9beb39785a45b9b97bdc6951fc8dbf",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-create"},
	 @sender="broker.test.example.com",
	 @time=1361976817,
	 @uniqid="7c7d7bf75b978e2dad6707a3e89d278c">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = openshift-origin-node app-create --with-container-namephpapp--with-app-namephpapp--with-container-uuidcc9beb39785a45b9b97bdc6951fc8dbf--with-app-uuidcc9beb39785a45b9b97bdc6951fc8dbf--with-namespacedemo
	INFO: openshift.rb:27:in 'oo_app_create' COMMAND: oo-app-create
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)
	------

	------)

This just creates an empty gear (action "app-create" and note the dummy
cartridge "openshift-origin-node") with the given parameters. You could
run the "oo-app-create" command on the node host with the same args given
here (--with-container-name and so on) to manually test the same operation
(similar for the log entries below).

* It is a non-scaled app so the app-uuid is just the container-uuid.
* This succeeds (return code 0) so there is no output to report back.
* Caller is "uid=48" meaning the apache user, which is what the broker runs as.
* In this example we are operating without districts. If there were a
district, the --with-uid parameter would be added to all gear creations
specifying the UID from the district pool that should be used. As it is,
the node just uses the next UID available.

Next we add a public ssh key for git/ssh access.

	INFO: execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc905952ab0
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--with-ssh-key-comment"=>"default",
		  "--with-ssh-key-type"=>"ssh-rsa",
		  "--with-container-uuid"=>"cc9beb39785a45b9b97bdc6951fc8dbf",
		  "--with-ssh-key"=>
		   "AAAAB3NzaC1yc2EAAAADAQABAAABAQDhZfWE2M4jp0ql9E5kzzC73ysqDwaxSHnY/oJhahKe+9r/onjanjNZ74AU1h9WKERVnh9T9c6hDHF6fIKX77zWma393e5XsUAR/WMqaRcFlog/vwuI4FKvQWDXlTwyd+51cQbDhY+FXTOT5T3Sea6yb3v1M3Mx59szws8wBTNIMBBjwCX0FG/7ZlvvEae5GzHhRtHPq/AfRn77AEaFyadPhK57+Bl7Lt1+UMXmXxh8B4L6prc55i1r6pgkwxGbV2YYYJ48awgzCsBnPy/MUCn9iRewNzaEEBjw6XOrpf9ORZpxFIYHAPBTFxqVIVDN6sK8rtgH5c8u53YOzYmUcM29",
		  "--with-app-uuid"=>"cc9beb39785a45b9b97bdc6951fc8dbf"},
		:cartridge=>"openshift-origin-node",
		:action=>"authorized-ssh-key-add"},
	      :result_exit_code=>"",
	      :gear=>"cc9beb39785a45b9b97bdc6951fc8dbf",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976818,
	 @uniqid="4aee6ea45540d3767f17baa72f6aac6b">
	INFO: openshift.rb:78:in 'oo_authorized_ssh_key_add' COMMAND: oo-authorized-ssh-key-add

This is what a "parallel" execution looks like (could conceivably be
adding multiple keys to the gear here). There is only one job in
this case; look for the :job=> hash.  Again, there is not much to report
on success.

Now we need to add the framework cartridge (php-5.3 in this case) into the empty gear.

	INFO: cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905902cb8
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'phpapp' 'demo' 'cc9beb39785a45b9b97bdc6951fc8dbf'",
	   :cartridge=>"php-5.3",
	   :process_results=>true,
	   :action=>"configure"},
	 @sender="broker.test.example.com",
	 @time=1361976818,
	 @uniqid="5d271b64c598341c2c4947a0014d617d">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = php-5.3 configure 'phpapp' 'demo' 'cc9beb39785a45b9b97bdc6951fc8dbf'
	INFO: openshift.rb:342:in 'handle_cartridge_action' handle_cartridge_action executing /usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/php-5.3/info/hooks/configure 'phpapp' 'demo' 'cc9beb39785a45b9b97bdc6951fc8dbf' 2>&1
	INFO: openshift.rb:329:in 'complete_process_gracefully' (0)
	------
	Initialized empty Git repository in /var/lib/openshift/cc9beb39785a45b9b97bdc6951fc8dbf/git/phpapp.git/
	/var/lib/openshift/cc9beb39785a45b9b97bdc6951fc8dbf/git/phpapp.git /tmp
	/tmp

	------)
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

This is where the php cartridge "configure" hook got called. Among other
things it creates a git repo. There is no DSL content between the dashed
lines though, so this is just fluff output.

Notice in the "handle_cartridge_action" method it logs exactly the command it runs. The SELinux context
is partially specified so the cartridge runs under the right MCS label.

Now the client issues a call to add the mysql-5.1 cartridge to the application.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc90583c568
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'phpapp' 'demo' 'cc9beb39785a45b9b97bdc6951fc8dbf'",
	   :cartridge=>"embedded/mysql-5.1",
	   :process_results=>true,
	   :action=>"configure"},
	 @sender="broker.test.example.com",
	 @time=1361976851,
	 @uniqid="7ad43028a75dba3df9a4e71d76e2062b">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = embedded/mysql-5.1 configure 'phpapp' 'demo' 'cc9beb39785a45b9b97bdc6951fc8dbf'
	INFO: openshift.rb:342:in 'handle_cartridge_action' handle_cartridge_action executing /usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/embedded/mysql-5.1/info/hooks/configure 'phpapp' 'demo' 'cc9beb39785a45b9b97bdc6951fc8dbf' 2>&1

This time, the return result is a little more interesting. It includes instructions for the broker to follow.

	INFO: openshift.rb:329:in 'complete_process_gracefully' (0)
	------
	CLIENT_RESULT: 
	CLIENT_RESULT: MySQL 5.1 database added.  Please make note of these credentials:
	CLIENT_RESULT: 
	CLIENT_RESULT:    Root User: admin
	CLIENT_RESULT:    Root Password: MQMuQz1_S5ng
	CLIENT_RESULT:    Database Name: phpapp
	CLIENT_RESULT: 
	CLIENT_RESULT: Connection URL: mysql://$OPENSHIFT_MYSQL_DB_HOST:$OPENSHIFT_MYSQL_DB_PORT/
	CLIENT_RESULT: 
	CLIENT_RESULT: You can manage your new MySQL database by also embedding phpmyadmin-3.4.
	CLIENT_RESULT: The phpmyadmin username and password will be the same as the MySQL credentials above.
	CART_PROPERTIES: connection_url=mysql://127.0.253.129:3306/
	CART_PROPERTIES: username=admin
	CART_PROPERTIES: password=MQMuQz1_S5ng
	CART_PROPERTIES: database_name=phpapp
	APP_INFO: Connection URL: mysql://127.0.253.129:3306/

	------)
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

* CLIENT_RESULT lines are simply sent back verbatim for the client to display to the user.
* CART_PROPERTIES specify properties to be added to other gears; not really needed in a simple app, but pay attention to the scaled app example below.
* Honestly not sure what APP_INFO is for. It appears to just be separate output for the client to pass on.

Finally, to complete the lifecycle, the client requests deletion of the app.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc9077a7448
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"phpapp",
	     "--with-app-name"=>"phpapp",
	     "--with-container-uuid"=>"cc9beb39785a45b9b97bdc6951fc8dbf",
	     "--with-app-uuid"=>"cc9beb39785a45b9b97bdc6951fc8dbf",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-destroy"},
	 @sender="broker.test.example.com",
	 @time=1361976873,
	 @uniqid="a874068ab275f3ff942ccd2d93489f8a">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = openshift-origin-node app-destroy --with-container-namephpapp--with-app-namephpapp--with-container-uuidcc9beb39785a45b9b97bdc6951fc8dbf--with-app-uuidcc9beb39785a45b9b97bdc6951fc8dbf--with-namespacedemo
	INFO: openshift.rb:55:in 'oo_app_destroy' COMMAND: oo-app-destroy
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)
	------
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_GEAR_DNS
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_GEAR_UUID
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_HOST
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_PASSWORD
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_PORT
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_SOCKET
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_URL
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_USERNAME
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_GEAR_DNS
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_GEAR_UUID
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_HOST
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_PASSWORD
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_PORT
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_SOCKET
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_URL
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_USERNAME

	------)

This also uses the dummy cartridge for the "app-destroy" action. As
a byproduct of the destroy, the cartridges are deconfigured; here the
mysql cartridge issues commands to remove its env vars from any gears
in the app. Since this is the only gear in the app and it is being
destroyed, it is moot, but in a scaled app removing the mysql cartridge
would require followup multi-gear operations.


Scaled app example
==================

### Gear creation ###

A scaled app creation looks similar to begin with, with just a gear creation.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905afafc0
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"sphpapp",
	     "--with-app-name"=>"sphpapp",
	     "--with-container-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-create"},
	 @sender="broker.test.example.com",
	 @time=1361976894,
	 @uniqid="9bab6eddfdd77a91f17b18973cb4102e">

Notice that the container and app UUIDs are the same. This will be the head gear.

Next we add a public ssh key as before. We will omit logs as it is no different from a simple app.

Next we get another gear creation command.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc90598e600
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"f81fb70064",
	     "--with-app-name"=>"sphpapp",
	     "--with-container-uuid"=>"f81fb70064064a35a9a25169481d490b",
	     "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-create"},
	 @sender="broker.test.example.com",
	 @time=1361976897,
	 @uniqid="df07e52e079b0bd1792590301aec5e7a">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = openshift-origin-node app-create --with-container-namef81fb70064--with-app-namesphpapp--with-container-uuidf81fb70064064a35a9a25169481d490b--with-app-uuid16f54529c1fa436981fce29b0499c0b6--with-namespacedemo
	INFO: openshift.rb:27:in 'oo_app_create' COMMAND: oo-app-create
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

Everything is the same as the previous gear in the app except the container UUID is different.
Every gear in the scaled app must have a different container UUID, but all share the app UUID.

Next the public ssh key is added to this gear - again omitted for brevity.

We now have two empty gears.

### Adding the PHP cartridge to the head gear ###

Adding the PHP cartridge begins the same as with a simple app.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905877e10
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'sphpapp' 'demo' '16f54529c1fa436981fce29b0499c0b6'",
	   :cartridge=>"php-5.3",
	   :process_results=>true,
	   :action=>"configure"},
	 @sender="broker.test.example.com",
	 @time=1361976899,
	 @uniqid="9bd5bab7ad80667f854cb790185ec105">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = php-5.3 configure 'sphpapp' 'demo' '16f54529c1fa436981fce29b0499c0b6'
	INFO: openshift.rb:342:in 'handle_cartridge_action' handle_cartridge_action executing /usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/php-5.3/info/hooks/configure 'sphpapp' 'demo' '16f54529c1fa436981fce29b0499c0b6' 2>&1
	INFO: openshift.rb:329:in 'complete_process_gracefully' (0)
	------
	Initialized empty Git repository in /var/lib/openshift/16f54529c1fa436981fce29b0499c0b6/git/sphpapp.git/
	/var/lib/openshift/16f54529c1fa436981fce29b0499c0b6/git/sphpapp.git /tmp
	/tmp

	------)
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

Next is something unique to gears in scaled apps. The broker calls the
"expose-port" hook on the cartridge which reserves an external port on
the node which is proxied directly to the web server the gear runs.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc90584c918
	 @action="cartridge_do",
	 @agent="openshift", @caller="uid=48",
	 @data=
	  {:args=>"'sphpapp' 'demo' '16f54529c1fa436981fce29b0499c0b6'",
	   :cartridge=>"php-5.3",
	   :process_results=>true,
	   :action=>"expose-port"},
	 @sender="broker.test.example.com",
	 @time=1361976902,
	 @uniqid="22c96b70a3b22cac0bf92e37d0678dfb">

In a simple app, this would not be needed as the node front proxy would
connect requests directly to the gear web server based on the Host given
in the request. But in a scaled application, all such requests go through
the app HAproxy, and since gears may be on other nodes, HAproxy connects
to each via an external port.

So this time, there is something interesting for the cartridge to respond with:

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = php-5.3 expose-port 'sphpapp' 'demo' '16f54529c1fa436981fce29b0499c0b6'
	INFO: openshift.rb:342:in 'handle_cartridge_action' handle_cartridge_action executing /usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/php-5.3/info/hooks/expose-port 'sphpapp' 'demo' '16f54529c1fa436981fce29b0499c0b6' 2>&1
	INFO: openshift.rb:329:in 'complete_process_gracefully' (0)
	------
	CART_DATA: PROXY_HOST=sphpapp-demo.test.example.com
	CART_DATA: PROXY_PORT=35566
	CART_DATA: HOST=127.0.253.129
	CART_DATA: PORT=8080

	------)
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

This gives both the internal and external contact information for the
gear web server. Here port 35566 on the node has been mapped to the gear
web server. The output is standard for any expose-port call; we will see
the same thing when adding a DB connection later.

### Adding the haproxy cartridge to the head gear ###

Now that the main cartridge is in place, we add the proxy that will
distribute load to the various gears in the app.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc90780d518
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'sphpapp' 'demo' '16f54529c1fa436981fce29b0499c0b6'",
	   :cartridge=>"embedded/haproxy-1.4",
	   :process_results=>true,
	   :action=>"configure"},
	 @sender="broker.test.example.com",
	 @time=1361976903,
	 @uniqid="5f51e81cdc540acbe0aa2a335d72c731">
	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = embedded/haproxy-1.4 configure 'sphpapp' 'demo' '16f54529c1fa436981fce29b0499c0b6'
	INFO: openshift.rb:342:in 'handle_cartridge_action' handle_cartridge_action executing /usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/embedded/haproxy-1.4/info/hooks/configure 'sphpapp' 'demo' '16f54529c1fa436981fce29b0499c0b6' 2>&1

The haproxy cartridge creates a private ssh key that it will use to
synchronize to the other gears in the application and reports the public
key back to the broker so that it can propagate to future gears allowing
the rsync to occur.

	INFO: openshift.rb:329:in 'complete_process_gracefully' (0)
	------
	APP_SSH_KEY_ADD: haproxy AAAAB3NzaC1yc2EAAAABIwAAAQEAzPP4vpf6vL4C88B/yPZfgfrH+iizJxWZ3qmE0sBGu6Esybx8sgy9Oz/sOXp6Z3WIfVtPcWFPxVGsXTBaZbXTcqjbyZ3gjVM3ijxBF4TeQA4maQ/zIpONEMeYaObWFpNf+vFjo/VurQqG0T5zRAw1XsvfidLjevoL8zIx0+5ZAfMsinCkgqaOX1Tc+pqCz4QZr2GwDaUtJgsGuq2dbipjr4cUqFthaGnd2r7gP+xPLnvVHZKICl8aZpr/zxqichNWOKyHaY3k8o4nslJIdUfiXkUY6smwhIFbTsUEITrp0oFIBPTAbsfNFEb3/xnePGBvt3s8fxXrVdpNpmuS9cUgNw==
	BROKER_AUTH_KEY_ADD: 
	httpd (pid 10334) already running

	------)
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

Next the broker provisions a private key for the HAproxy gear to use with the broker when it needs to request scaling up or down (gear creation / destruction). This is only really needed on the head gear in the current architecture,
but it is added to all. Since both gears are on the same node, this comes through as a parallel request.

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc90771c988
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--with-iv"=>
		   "JGN7rFmblbODDnqdaA/g6j9o2+V3Xm7D/AKluhxNnU4rrBxZZz4tx4NqODSl\n+1mlcKThjeE+EeW05OKWbOgJIuYOA1s45RxdT/FskReUz0K7L3mlj7OSj8cf\nCVJb0eluepREYt8UwrJNusCDa7EetgYuODjPv3pgTU8AyntFAHBT196C9ZHo\nZ7zdCjFj+c8qfKlif88KR0wGGkOQFFL78b+uWPQbkWTiOnOILP8eu9kVwvjZ\nl1xAPsaP9rPs7V9cO4lcHZS/96R/U4yBkJSgFpQSFn+A3xEoexX6mE5nGfFQ\n7tPGO5Ldtbkobr8HjrCuRR9CiaZtML0O5ohh9AtgKg==\n",
		  "--with-token"=>
		   "ilTK4mfWGuIYi15D1OV0AB9VmsKAlGwn+c/8yJM7sG3pib/2RKG6i7B8x6PH\nP6E46c1hZtO4qFG4YbQiAKuRIYw9AsoTtuZDzV68yA7ej1M/JsCSpPzjYhFF\nJXoJ7FFw\n",
		  "--with-container-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
		  "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6"},
		:cartridge=>"openshift-origin-node",
		:action=>"broker-auth-key-add"},
	      :result_exit_code=>"",
	      :gear=>"16f54529c1fa436981fce29b0499c0b6",
	      :result_stdout=>"",
	      :result_stderr=>""},
	     {:tag=>"",
	      :job=>
	       {:args=>
		 {"--with-iv"=>
		   "JGN7rFmblbODDnqdaA/g6j9o2+V3Xm7D/AKluhxNnU4rrBxZZz4tx4NqODSl\n+1mlcKThjeE+EeW05OKWbOgJIuYOA1s45RxdT/FskReUz0K7L3mlj7OSj8cf\nCVJb0eluepREYt8UwrJNusCDa7EetgYuODjPv3pgTU8AyntFAHBT196C9ZHo\nZ7zdCjFj+c8qfKlif88KR0wGGkOQFFL78b+uWPQbkWTiOnOILP8eu9kVwvjZ\nl1xAPsaP9rPs7V9cO4lcHZS/96R/U4yBkJSgFpQSFn+A3xEoexX6mE5nGfFQ\n7tPGO5Ldtbkobr8HjrCuRR9CiaZtML0O5ohh9AtgKg==\n",
		  "--with-token"=>
		   "ilTK4mfWGuIYi15D1OV0AB9VmsKAlGwn+c/8yJM7sG3pib/2RKG6i7B8x6PH\nP6E46c1hZtO4qFG4YbQiAKuRIYw9AsoTtuZDzV68yA7ej1M/JsCSpPzjYhFF\nJXoJ7FFw\n",
		  "--with-container-uuid"=>"f81fb70064064a35a9a25169481d490b",
		  "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6"},
		:cartridge=>"openshift-origin-node",
		:action=>"broker-auth-key-add"},
	      :result_exit_code=>"",
	      :gear=>"f81fb70064064a35a9a25169481d490b",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976906,
	 @uniqid="0e121906cd282d54a5a01e819cf9dfd6">

	INFO: openshift.rb:119:in 'oo_broker_auth_key_add' COMMAND: oo-broker-auth-key-add
	INFO: openshift.rb:119:in 'oo_broker_auth_key_add' COMMAND: oo-broker-auth-key-add
	INFO: openshift.rb:579:in 'execute_parallel_action' execute_parallel_action call - <omitted>

Next the public ssh key that the haproxy cartridge requested be added is propagated to all existing gears. Since this is a test scenario, both are on this node.

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc905a8ddd0
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--with-ssh-key-comment"=>"haproxy",
		  "--with-container-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
		  "--with-ssh-key"=>
		   "AAAAB3NzaC1yc2EAAAABIwAAAQEAzPP4vpf6vL4C88B/yPZfgfrH+iizJxWZ3qmE0sBGu6Esybx8sgy9Oz/sOXp6Z3WIfVtPcWFPxVGsXTBaZbXTcqjbyZ3gjVM3ijxBF4TeQA4maQ/zIpONEMeYaObWFpNf+vFjo/VurQqG0T5zRAw1XsvfidLjevoL8zIx0+5ZAfMsinCkgqaOX1Tc+pqCz4QZr2GwDaUtJgsGuq2dbipjr4cUqFthaGnd2r7gP+xPLnvVHZKICl8aZpr/zxqichNWOKyHaY3k8o4nslJIdUfiXkUY6smwhIFbTsUEITrp0oFIBPTAbsfNFEb3/xnePGBvt3s8fxXrVdpNpmuS9cUgNw==",
		  "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6"},
		:cartridge=>"openshift-origin-node",
		:action=>"authorized-ssh-key-add"},
	      :result_exit_code=>"",
	      :gear=>"16f54529c1fa436981fce29b0499c0b6",
	      :result_stdout=>"",
	      :result_stderr=>""},
	     {:tag=>"",
	      :job=>
	       {:args=>
		 {"--with-ssh-key-comment"=>"haproxy",
		  "--with-container-uuid"=>"f81fb70064064a35a9a25169481d490b",
		  "--with-ssh-key"=>
		   "AAAAB3NzaC1yc2EAAAABIwAAAQEAzPP4vpf6vL4C88B/yPZfgfrH+iizJxWZ3qmE0sBGu6Esybx8sgy9Oz/sOXp6Z3WIfVtPcWFPxVGsXTBaZbXTcqjbyZ3gjVM3ijxBF4TeQA4maQ/zIpONEMeYaObWFpNf+vFjo/VurQqG0T5zRAw1XsvfidLjevoL8zIx0+5ZAfMsinCkgqaOX1Tc+pqCz4QZr2GwDaUtJgsGuq2dbipjr4cUqFthaGnd2r7gP+xPLnvVHZKICl8aZpr/zxqichNWOKyHaY3k8o4nslJIdUfiXkUY6smwhIFbTsUEITrp0oFIBPTAbsfNFEb3/xnePGBvt3s8fxXrVdpNpmuS9cUgNw==",
		  "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6"},
		:cartridge=>"openshift-origin-node",
		:action=>"authorized-ssh-key-add"},
	      :result_exit_code=>"",
	      :gear=>"f81fb70064064a35a9a25169481d490b",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976906,
	 @uniqid="cad7246088d5a9abd662f735649c4829">

	<processing and response omitted>

### Adding the PHP cartridge to the second gear ###

First the cartridge is added. This is no different than usual.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905b6b5b8
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'f81fb70064' 'demo' 'f81fb70064064a35a9a25169481d490b'",
	   :cartridge=>"php-5.3",
	   :process_results=>true,
	   :action=>"configure"},
	 @sender="broker.test.example.com",
	 @time=1361976907,
	 @uniqid="5ed9d73e9d4518baa64dce96ee144da3">

	<processing and response omitted>

Once again the cartridge must have its port exposed as a target for HAproxy.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905b132f0
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'f81fb70064' 'demo' 'f81fb70064064a35a9a25169481d490b'",
	   :cartridge=>"php-5.3",
	   :process_results=>true,
	   :action=>"expose-port"},
	 @sender="broker.test.example.com",
	 @time=1361976910,
	 @uniqid="1910dc97e6507a457f71017d9d6c34ce">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = php-5.3 expose-port 'f81fb70064' 'demo' 'f81fb70064064a35a9a25169481d490b'
	INFO: openshift.rb:342:in 'handle_cartridge_action' handle_cartridge_action executing /usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/php-5.3/info/hooks/expose-port 'f81fb70064' 'demo' 'f81fb70064064a35a9a25169481d490b' 2>&1
	INFO: openshift.rb:329:in 'complete_process_gracefully' (0)
	------
	CART_DATA: PROXY_HOST=f81fb70064-demo.test.example.com
	CART_DATA: PROXY_PORT=35571
	CART_DATA: HOST=127.0.254.1
	CART_DATA: PORT=8080

	------)
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

Note that non-head gears do get a hostname (a dummy consisting of part of the gear UUID) which can be used directly. It is just not displayed via the client.

Next we see our first connector. Here the broker requests that the second gear publish its information for an HTTP connection by the HAproxy.

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc905ac6f68
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--hook-name"=>"publish-http-url",
		  "--input-args"=>"f81fb70064 demo f81fb70064064a35a9a25169481d490b",
		  "--cart-name"=>"php-5.3",
		  "--gear-uuid"=>"f81fb70064064a35a9a25169481d490b"},
		:cartridge=>"openshift-origin-node",
		:action=>"connector-execute"},
	      :result_exit_code=>"",
	      :gear=>"f81fb70064064a35a9a25169481d490b",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976910,
	 @uniqid="29d9b0d7bed152bb4da8a526b2803e4e">

	INFO: openshift.rb:264:in 'oo_connector_execute' COMMAND: connector-execute
	INFO: openshift.rb:619:in 'reap_output' cartridge_do_action (0)
	------
	f81fb70064-demo.test.example.com|192.168.59.144:35571

	------)

The response includes both the hostname and the current node IP and exposed port for reaching the gear web server.

You may wonder: why not simply use the hostname and port 80, or even
port 443? In fact, in a previous implementation, HAproxy did proxy
to the hostname of each gear and no exposed port was needed. This was
changed to use the IP and an exposed port because slow DNS propagation
times sometimes would result in losing traffic going to new gears with
addresses not yet resolvable.

Next, for the other side of the connector, the broker reports to the
head gear the proxy target for reaching the second gear.

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc905a71338
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--hook-name"=>"set-proxy",
		  "--input-args"=>
		   "sphpapp demo 16f54529c1fa436981fce29b0499c0b6 \\'f81fb70064064a35a9a25169481d490b\\'\\=\\'f81fb70064-demo.test.example.com\\|192.168.59.144:35571'\n'\\'",
		  "--cart-name"=>"haproxy-1.4",
		  "--gear-uuid"=>"16f54529c1fa436981fce29b0499c0b6"},
		:cartridge=>"openshift-origin-node",
		:action=>"connector-execute"},
	      :result_exit_code=>"",
	      :gear=>"16f54529c1fa436981fce29b0499c0b6",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976911,
	 @uniqid="b5beae9915ab8bcbc012fea62c856003">

HAproxy adds the gear to its configuration and reloads.

	INFO: openshift.rb:264:in `oo_connector_execute' COMMAND: connector-execute
	INFO: openshift.rb:619:in `reap_output' cartridge_do_action (0)
	------
	Wed Feb 27 09:55:11 EST 2013: Conditionally reloading HAProxy service 

	------)

Now traffic is ready to go to both gears. But the first gear needs to know how to synchronize application data with the second. So the broker runs another connector for that purpose.

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc905a1d648
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--hook-name"=>"publish-gear-endpoint",
		  "--input-args"=>"f81fb70064 demo f81fb70064064a35a9a25169481d490b",
		  "--cart-name"=>"php-5.3",
		  "--gear-uuid"=>"f81fb70064064a35a9a25169481d490b"},
		:cartridge=>"openshift-origin-node",
		:action=>"connector-execute"},
	      :result_exit_code=>"",
	      :gear=>"f81fb70064064a35a9a25169481d490b",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976915,
	 @uniqid="f205e2f9d6bb8f37c03fbe7fc1393f65">

The second gear responds with ssh contact info, the directory to sync, and its hostname.

	INFO: openshift.rb:264:in `oo_connector_execute' COMMAND: connector-execute
	INFO: openshift.rb:619:in `reap_output' cartridge_do_action (0)
	------
	f81fb70064064a35a9a25169481d490b@192.168.59.144:php-5.3;f81fb70064-demo.test.example.com

	------)

This is then communicated to the head gear.

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc9059d99e8
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--hook-name"=>"set-gear-endpoints",
		  "--input-args"=>
		   "sphpapp demo 16f54529c1fa436981fce29b0499c0b6 \\'f81fb70064064a35a9a25169481d490b\\'\\=\\'f81fb70064064a35a9a25169481d490b@192.168.59.144:php-5.3\\;f81fb70064-demo.test.example.com'\n'\\'",
		  "--cart-name"=>"haproxy-1.4",
		  "--gear-uuid"=>"16f54529c1fa436981fce29b0499c0b6"},
		:cartridge=>"openshift-origin-node",
		:action=>"connector-execute"},
	      :result_exit_code=>"",
	      :gear=>"16f54529c1fa436981fce29b0499c0b6",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976915,
	 @uniqid="fc0cf2f9352722ec0fe7747a9ef005a7">

The head gear immediately uses this information to rsync with the second
gear and restart it. A great deal of debug output is included in the log,
some of which we omit, but the remainder illustrate hooks called during
sync and restart.

	INFO: openshift.rb:264:in `oo_connector_execute' COMMAND: connector-execute
	INFO: openshift.rb:619:in `reap_output' cartridge_do_action (0)
	------
	SSH_CMD: ssh f81fb70064064a35a9a25169481d490b@192.168.59.144
	++ date
	+ echo 'Syncing to gear: f81fb70064064a35a9a25169481d490b@192.168.59.144:php-5.3 @ ' Wed Feb 27 09:55:15 EST 2013
	Syncing to gear: f81fb70064064a35a9a25169481d490b@192.168.59.144:php-5.3 @  Wed Feb 27 09:55:15 EST 2013
	+ for rpccall in '"${OPENSHIFT_SYNC_GEARS_PRE[@]}"'
	+ ssh f81fb70064064a35a9a25169481d490b@192.168.59.144 'ctl_all stop'

	<ssh gear access message omitted>

	Waiting for stop to finish
	Done
	+ for subd in '"${OPENSHIFT_SYNC_GEARS_DIRS[@]}"'
	+ '[' -d /var/lib/openshift/16f54529c1fa436981fce29b0499c0b6//php-5.3/repo ']'
	+ rsync -v --delete-after -az /var/lib/openshift/16f54529c1fa436981fce29b0499c0b6//php-5.3/repo/ f81fb70064064a35a9a25169481d490b@192.168.59.144:php-5.3/repo/
	building file list ... done
	./

	sent 787 bytes  received 15 bytes  534.67 bytes/sec
	total size is 14320  speedup is 17.86

	<other directory syncs omitted>

	+ for rpccall in '"${OPENSHIFT_SYNC_GEARS_POST[@]}"'
	+ ssh f81fb70064064a35a9a25169481d490b@192.168.59.144 deploy.sh
	Running .openshift/action_hooks/deploy
	+ for rpccall in '"${OPENSHIFT_SYNC_GEARS_POST[@]}"'
	+ ssh f81fb70064064a35a9a25169481d490b@192.168.59.144 'ctl_all start'

	<ssh gear access message omitted>

	Done
	+ for rpccall in '"${OPENSHIFT_SYNC_GEARS_POST[@]}"'
	+ ssh f81fb70064064a35a9a25169481d490b@192.168.59.144 post_deploy.sh
	Running .openshift/action_hooks/post_deploy
	Exit code: 0
	Wed Feb 27 09:55:19 EST 2013: Conditionally reloading HAProxy service 

------)

Both gears of the scaled application are now fully initialized and the
proxy can direct traffic to both.

### Adding the MySQL DB cartridge ###

Because this is a scaled application, when the mysql-5.1 cartridge is added, it is given its own gear to run in.
So first we create another empty gear for this application.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc90586d3e8
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"ec920d39b2",
	     "--with-app-name"=>"sphpapp",
	     "--with-container-uuid"=>"ec920d39b257412984fdcc40041c7d5e",
	     "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-create"},
	 @sender="broker.test.example.com",
	 @time=1361976951,
	 @uniqid="3b82a18d3e13977fb26d3831ad70822e">

	<response omitted>

Next the broker adds public ssh keys, both from the user and haproxy.
These are somewhat superfluous for the DB, but the broker does not distinguish.

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc90771bc40
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--with-ssh-key-comment"=>"default",
		  "--with-ssh-key-type"=>"ssh-rsa",
		  "--with-container-uuid"=>"ec920d39b257412984fdcc40041c7d5e",
		  "--with-ssh-key"=>
		   "AAAAB3NzaC1yc2EAAAADAQABAAABAQDhZfWE2M4jp0ql9E5kzzC73ysqDwaxSHnY/oJhahKe+9r/onjanjNZ74AU1h9WKERVnh9T9c6hDHF6fIKX77zWma393e5XsUAR/WMqaRcFlog/vwuI4FKvQWDXlTwyd+51cQbDhY+FXTOT5T3Sea6yb3v1M3Mx59szws8wBTNIMBBjwCX0FG/7ZlvvEae5GzHhRtHPq/AfRn77AEaFyadPhK57+Bl7Lt1+UMXmXxh8B4L6prc55i1r6pgkwxGbV2YYYJ48awgzCsBnPy/MUCn9iRewNzaEEBjw6XOrpf9ORZpxFIYHAPBTFxqVIVDN6sK8rtgH5c8u53YOzYmUcM29",
		  "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6"},
		:cartridge=>"openshift-origin-node",
		:action=>"authorized-ssh-key-add"},
	      :result_exit_code=>"",
	      :gear=>"ec920d39b257412984fdcc40041c7d5e",
	      :result_stdout=>"",
	      :result_stderr=>""},
	     {:tag=>"",
	      :job=>
	       {:args=>
		 {"--with-ssh-key-comment"=>"haproxy",
		  "--with-container-uuid"=>"ec920d39b257412984fdcc40041c7d5e",
		  "--with-ssh-key"=>
		   "AAAAB3NzaC1yc2EAAAABIwAAAQEAzPP4vpf6vL4C88B/yPZfgfrH+iizJxWZ3qmE0sBGu6Esybx8sgy9Oz/sOXp6Z3WIfVtPcWFPxVGsXTBaZbXTcqjbyZ3gjVM3ijxBF4TeQA4maQ/zIpONEMeYaObWFpNf+vFjo/VurQqG0T5zRAw1XsvfidLjevoL8zIx0+5ZAfMsinCkgqaOX1Tc+pqCz4QZr2GwDaUtJgsGuq2dbipjr4cUqFthaGnd2r7gP+xPLnvVHZKICl8aZpr/zxqichNWOKyHaY3k8o4nslJIdUfiXkUY6smwhIFbTsUEITrp0oFIBPTAbsfNFEb3/xnePGBvt3s8fxXrVdpNpmuS9cUgNw==",
		  "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6"},
		:cartridge=>"openshift-origin-node",
		:action=>"authorized-ssh-key-add"},
	      :result_exit_code=>"",
	      :gear=>"ec920d39b257412984fdcc40041c7d5e",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976952,
	 @uniqid="d3d13da5187c4ec21b008f5e9e94c628">

Next the mysql-5.1 cartridge is added:

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905c25080
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'ec920d39b2' 'demo' 'ec920d39b257412984fdcc40041c7d5e'",
	   :cartridge=>"embedded/mysql-5.1",
	   :process_results=>true,
	   :action=>"configure"},
	 @sender="broker.test.example.com",
	 @time=1361976953,
	 @uniqid="b04b1c109b2a944df4e20c613efaf8e7">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = embedded/mysql-5.1 configure 'ec920d39b2' 'demo' 'ec920d39b257412984fdcc40041c7d5e'
	INFO: openshift.rb:342:in 'handle_cartridge_action' handle_cartridge_action executing /usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/embedded/mysql-5.1/info/hooks/configure 'ec920d39b2' 'demo' 'ec920d39b257412984fdcc40041c7d5e' 2>&1
	INFO: openshift.rb:329:in 'complete_process_gracefully' (0)
	------
	CART_DATA: PROXY_HOST=ec920d39b2-demo.test.example.com
	CART_DATA: PROXY_PORT=35576
	CART_DATA: HOST=127.0.254.129
	CART_DATA: PORT=3306
	CLIENT_RESULT: 
	CLIENT_RESULT: MySQL 5.1 database added.  Please make note of these credentials:
	CLIENT_RESULT: 
	CLIENT_RESULT:    Root User: admin
	CLIENT_RESULT:    Root Password: WHWYjN1yxqiS
	CLIENT_RESULT:    Database Name: sphpapp
	CLIENT_RESULT: 
	CLIENT_RESULT: Connection URL: mysql://$OPENSHIFT_GEAR_DNS:$OPENSHIFT_MYSQL_DB_PROXY_PORT/
	CLIENT_RESULT: MySQL gear-local connection URL: mysql://$OPENSHIFT_MYSQL_DB_HOST:$OPENSHIFT_MYSQL_DB_PORT/
	CLIENT_RESULT: 
	CART_PROPERTIES: connection_url=mysql://ec920d39b2-demo.test.example.com:35576/
	CART_PROPERTIES: username=admin
	CART_PROPERTIES: password=WHWYjN1yxqiS
	CART_PROPERTIES: database_name=sphpapp
	APP_INFO: Connection URL: mysql://ec920d39b2-demo.test.example.com:35576/

	------)
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

As with adding to a simple app, client messages are returned and
CART_PROPERTIES communicated. However, as the cartridge finds itself alone
in the gear, the expose-port hook is called (which is what causes the
CART_DATA to be published with internal/external connection information)
and the connection information is specified for external use.

For some reason, the broker requests that the mysql cartridge expose the port again:

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905bbbf68
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'ec920d39b2' 'demo' 'ec920d39b257412984fdcc40041c7d5e'",
	   :cartridge=>"mysql-5.1",
	   :process_results=>true,
	   :action=>"expose-port"},
	 @sender="broker.test.example.com",
	 @time=1361976959,
	 @uniqid="cc1fd9049154548f1640a3728bb7a3eb">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = mysql-5.1 expose-port 'ec920d39b2' 'demo' 'ec920d39b257412984fdcc40041c7d5e'
	INFO: openshift.rb:342:in 'handle_cartridge_action' handle_cartridge_action executing /usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/mysql-5.1/info/hooks/expose-port 'ec920d39b2' 'demo' 'ec920d39b257412984fdcc40041c7d5e' 2>&1
	INFO: openshift.rb:329:in 'complete_process_gracefully' (0)
	------
	CART_DATA: PROXY_HOST=ec920d39b2-demo.test.example.com
	CART_DATA: PROXY_PORT=35576
	CART_DATA: HOST=127.0.254.129
	CART_DATA: PORT=3306

	------)
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

Fortunately the port is the same.

The broker now executes a connector so that the DB gear publishes
environment variables for the DB connection:

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc905b5fee8
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--hook-name"=>"publish-db-connection-info",
		  "--input-args"=>"ec920d39b2 demo ec920d39b257412984fdcc40041c7d5e",
		  "--cart-name"=>"mysql-5.1",
		  "--gear-uuid"=>"ec920d39b257412984fdcc40041c7d5e"},
		:cartridge=>"openshift-origin-node",
		:action=>"connector-execute"},
	      :result_exit_code=>"",
	      :gear=>"ec920d39b257412984fdcc40041c7d5e",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976959,
	 @uniqid="ed223e905cfe7a21c4a8dba752b07f8c">

	INFO: openshift.rb:264:in 'oo_connector_execute' COMMAND: connector-execute
	INFO: openshift.rb:619:in 'reap_output' cartridge_do_action (0)
	------
	OPENSHIFT_MYSQL_DB_GEAR_UUID=ec920d39b257412984fdcc40041c7d5e; OPENSHIFT_MYSQL_DB_GEAR_DNS=ec920d39b2-demo.test.example.com; OPENSHIFT_MYSQL_DB_USERNAME=admin; OPENSHIFT_MYSQL_DB_PASSWORD=WHWYjN1yxqiS; OPENSHIFT_MYSQL_DB_HOST=ec920d39b2-demo.test.example.com; OPENSHIFT_MYSQL_DB_PORT=35576; OPENSHIFT_MYSQL_DB_URL=mysql://admin:WHWYjN1yxqiS@ec920d39b2-demo.test.example.com:35576/; OPENSHIFT_MYSQL_DB_SOCKET=/var/lib/openshift/ec920d39b257412984fdcc40041c7d5e//mysql-5.1/socket/mysql.sock; 

	------)

This is then published to the non-head gear.

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc905afe1e8
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--hook-name"=>"set-db-connection-info",
		  "--input-args"=>
		   "f81fb70064 demo f81fb70064064a35a9a25169481d490b \\'ec920d39b257412984fdcc40041c7d5e\\'\\=\\'OPENSHIFT_MYSQL_DB_GEAR_UUID\\=ec920d39b257412984fdcc40041c7d5e\\;\\ OPENSHIFT_MYSQL_DB_GEAR_DNS\\=ec920d39b2-demo.test.example.com\\;\\ OPENSHIFT_MYSQL_DB_USERNAME\\=admin\\;\\ OPENSHIFT_MYSQL_DB_PASSWORD\\=WHWYjN1yxqiS\\;\\ OPENSHIFT_MYSQL_DB_HOST\\=ec920d39b2-demo.test.example.com\\;\\ OPENSHIFT_MYSQL_DB_PORT\\=35576\\;\\ OPENSHIFT_MYSQL_DB_URL\\=mysql://admin:WHWYjN1yxqiS@ec920d39b2-demo.test.example.com:35576/\\;\\ OPENSHIFT_MYSQL_DB_SOCKET\\=/var/lib/openshift/ec920d39b257412984fdcc40041c7d5e//mysql-5.1/socket/mysql.sock\\;\\ '\n'\\'",
		  "--cart-name"=>"php-5.3",
		  "--gear-uuid"=>"f81fb70064064a35a9a25169481d490b"},
		:cartridge=>"openshift-origin-node",
		:action=>"connector-execute"},
	      :result_exit_code=>"",
	      :gear=>"f81fb70064064a35a9a25169481d490b",
	      :result_stdout=>"",
	      :result_stderr=>""}],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361976959,
	 @uniqid="c9eb8b4dd16f18d681b47ac020165001">

	INFO: openshift.rb:264:in 'oo_connector_execute' COMMAND: connector-execute
	INFO: openshift.rb:619:in 'reap_output' cartridge_do_action (0)
	------

	------)

Next, an odd little dance occurs.

* The broker requests that the non-head gear run the publish-http-url
connector again. The gear responds as before.
* The head gear haproxy cartridge receives the published url, reconfigures itself, and reloads.
* The broker requests that the non-head gear run the publish-gear-endpoint
connector again. The gear responds as before.
* The head gear haproxy cartridge receives the published ssh endpoint, reconfigures itself, and reloads.

This seems utterly superfluous and repetitive, so we omit the logs here.

Next, the broker runs a connector to update the head gear with the DB connection.

* The broker has the DB gear run the publish-db-connection-info hook again.
* The result is transmitted to the head gear via the set-db-connection-info hook.

This are the same as for the non-head gear, so we omit the logs here.

The scaled app is now configured with the mysql-5.1 cartridge.

### Scaling up the application ###

We now cause the app to add a gear.

First, the empty gear is created.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc90585c2f0
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"acc082fd44",
	     "--with-app-name"=>"sphpapp",
	     "--with-container-uuid"=>"acc082fd449e4a2eaca2868149f76a67",
	     "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-create"},
	 @sender="broker.test.example.com",
	 @time=1361976986,
	 @uniqid="c93e07a701520cf5b6ebd8d8f9c70f23">

Public ssh keys are added as usual (logs omitted).

The PHP cartridge is added to the new gear as usual.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905bfea98
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'acc082fd44' 'demo' 'acc082fd449e4a2eaca2868149f76a67'",
	   :cartridge=>"php-5.3",
	   :process_results=>true,
	   :action=>"configure"},
	 @sender="broker.test.example.com",
	 @time=1361976988,
	 @uniqid="8569f5d78c9ddaa9491f53ad9f1461ae">

The expose-port hook is called.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905b9ba10
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>"'acc082fd44' 'demo' 'acc082fd449e4a2eaca2868149f76a67'",
	   :cartridge=>"php-5.3",
	   :process_results=>true,
	   :action=>"expose-port"},
	 @sender="broker.test.example.com",
	 @time=1361976991,
	 @uniqid="97ea21d61b13438ada8867d732b0ca15">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = php-5.3 expose-port 'acc082fd44' 'demo' 'acc082fd449e4a2eaca2868149f76a67'
	INFO: openshift.rb:342:in 'handle_cartridge_action' handle_cartridge_action executing /usr/bin/runcon -l s0-s0:c0.c1023 /usr/libexec/openshift/cartridges/php-5.3/info/hooks/expose-port 'acc082fd44' 'demo' 'acc082fd449e4a2eaca2868149f76a67' 2>&1
	INFO: openshift.rb:329:in 'complete_process_gracefully' (0)
	------
	CART_DATA: PROXY_HOST=acc082fd44-demo.test.example.com
	CART_DATA: PROXY_PORT=35581
	CART_DATA: HOST=127.0.255.1
	CART_DATA: PORT=8080

	------)
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)

Next other connector actions are repeated for the new gear. Logs omitted.

* publish-db-connection-info is called against the DB gear.
* set-db-connection-info transmits this to both non-head gears (including the new one).
* publish-http-url is called against both non-head gears (including the new one).
* set-proxy is called to transmit these to the head gear, which reconfigures itself and reloads.
* publish-gear-endpoint is called against both non-head gears (including the new one).
* set-gear-endpoints is called to transmit these to the head gear, which rsyncs and reloads the new gear, then reconfigures itself and reloads.
* publish-db-connection-info is called against the DB gear again.
* set-db-connection-info transmits this to the head gear (again).

### Scaling down the application ###

If we issue a scale-down request, a gear is destroyed. In this case, the newest one.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905876510
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"acc082fd44",
	     "--with-app-name"=>"sphpapp",
	     "--with-container-uuid"=>"acc082fd449e4a2eaca2868149f76a67",
	     "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-destroy"},
	 @sender="broker.test.example.com",
	 @time=1361977014,
	 @uniqid="878ad7bffc5f86743d595547e6d0375e">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = openshift-origin-node app-destroy --with-container-nameacc082fd44--with-app-namesphpapp--with-container-uuidacc082fd449e4a2eaca2868149f76a67--with-app-uuid16f54529c1fa436981fce29b0499c0b6--with-namespacedemo
	INFO: openshift.rb:55:in 'oo_app_destroy' COMMAND: oo-app-destroy
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)
	------

	------)

The response is empty, but the broker knows it needs to reconfigure, so it runs through all the connectors again. (Logs omitted)

* publish-db-connection-info on the DB gear, set-db-connection-info on the non-head gear.
* publish-http-url on the non-head gear, set-proxy on the head gear.
* publish-gear-endpoint on the non-head gear, set-gear-endpoints on the head gear.
* publish-db-connection-info on the DB gear, set-db-connection-info on the head gear.

### Destroying the scaled app ###

Finally we issue the app delete command.

First, the non-head gear is destroyed.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc9059b9f30
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"f81fb70064",
	     "--with-app-name"=>"sphpapp",
	     "--with-container-uuid"=>"f81fb70064064a35a9a25169481d490b",
	     "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-destroy"},
	 @sender="broker.test.example.com",
	 @time=1361977050,
	 @uniqid="22d8763f37881bed0284098ca6d47734">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = openshift-origin-node app-destroy --with-container-namef81fb70064--with-app-namesphpapp--with-container-uuidf81fb70064064a35a9a25169481d490b--with-app-uuid16f54529c1fa436981fce29b0499c0b6--with-namespacedemo
	INFO: openshift.rb:55:in 'oo_app_destroy' COMMAND: oo-app-destroy
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)
	------

	------)

Next, the DB gear.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc9058db208
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"ec920d39b2",
	     "--with-app-name"=>"sphpapp",
	     "--with-container-uuid"=>"ec920d39b257412984fdcc40041c7d5e",
	     "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-destroy"},
	 @sender="broker.test.example.com",
	 @time=1361977051,
	 @uniqid="9e9f2b11acc39c17bd31f2fa50e7b2f3">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = openshift-origin-node app-destroy --with-container-nameec920d39b2--with-app-namesphpapp--with-container-uuidec920d39b257412984fdcc40041c7d5e--with-app-uuid16f54529c1fa436981fce29b0499c0b6--with-namespacedemo
	INFO: openshift.rb:55:in 'oo_app_destroy' COMMAND: oo-app-destroy
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)
	------
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_GEAR_DNS
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_GEAR_UUID
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_HOST
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_PASSWORD
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_PORT
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_SOCKET
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_URL
	APP_ENV_VAR_REMOVE: OPENSHIFT_DB_USERNAME
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_GEAR_DNS
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_GEAR_UUID
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_HOST
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_PASSWORD
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_PORT
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_SOCKET
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_URL
	APP_ENV_VAR_REMOVE: OPENSHIFT_MYSQL_DB_USERNAME

	------)

This time, the DB gear request to remove env vars has a result. The env
vars are removed from the remaining head gear.

	INFO: openshift.rb:526:in 'execute_parallel_action' execute_parallel_action call / request = #<MCollective::RPC::Request:0x7fc905832a40
	 @action="execute_parallel",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {"broker.test.example.com"=>
	    [{:tag=>"",
	      :job=>
	       {:args=>
		 {"--with-key"=>"OPENSHIFT_DB_GEAR_DNS",
		  "--with-container-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
		  "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6"},
		:cartridge=>"openshift-origin-node",
		:action=>"env-var-remove"},
	      :result_exit_code=>"",
	      :gear=>"16f54529c1fa436981fce29b0499c0b6",
	      :result_stdout=>"",
	      :result_stderr=>""},

	<copy of the same job for every env var in the list above>

	      ],
	   :process_results=>true},
	 @sender="broker.test.example.com",
	 @time=1361977052,
	 @uniqid="1a1c31c4b5ed5b3ca6b61ea645bb5973">

	INFO: openshift.rb:177:in 'oo_env_var_remove' COMMAND: oo-env-var-remove
	<repeated for every env var>

Finally, the head gear is destroyed.

	INFO: openshift.rb:360:in 'cartridge_do_action' cartridge_do_action call / request = #<MCollective::RPC::Request:0x7fc905a9aff8
	 @action="cartridge_do",
	 @agent="openshift",
	 @caller="uid=48",
	 @data=
	  {:args=>
	    {"--with-container-name"=>"sphpapp",
	     "--with-app-name"=>"sphpapp",
	     "--with-container-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-app-uuid"=>"16f54529c1fa436981fce29b0499c0b6",
	     "--with-namespace"=>"demo"},
	   :cartridge=>"openshift-origin-node",
	   :process_results=>true,
	   :action=>"app-destroy"},
	 @sender="broker.test.example.com",
	 @time=1361977052,
	 @uniqid="9b950ab91235f8b9a41288c675d9d898">

	INFO: openshift.rb:361:in 'cartridge_do_action' cartridge_do_action validation = openshift-origin-node app-destroy --with-container-namesphpapp--with-app-namesphpapp--with-container-uuid16f54529c1fa436981fce29b0499c0b6--with-app-uuid16f54529c1fa436981fce29b0499c0b6--with-namespacedemo
	INFO: openshift.rb:55:in 'oo_app_destroy' COMMAND: oo-app-destroy
	INFO: openshift.rb:388:in 'cartridge_do_action' cartridge_do_action (0)
	------
	APP_SSH_KEY_REMOVE: haproxy

	------)

Since there are no gears left, the broker does not have anywhere to
execute the last key removal requested there, so we are done.

