Creating a New Cartridge
========================

This guide explains how to create a new Web or regular cartridge,
step by step.

The reader is assumed to be familiar with the definitions provided in
the [terminology document](../documentation/terminology.md).  The
general [documentation on cartridges](./README.md) may be helpful in
understanding this guide.  That document provides a lot of high-level
concepts, low-level technical details, and explanations of why things
are done as they are.  However, it is not assumed that the reader has
read that document, and it should be possible to follow the steps in
this guide without having read the other document.

It is assumed that the reader is operating in a checked-out clone of the
origin-server git repo under the cartridges/ directory.


Copy Template
-------------

A template for new cartridges exists in the template/ directory.  The
first step in creating a new cartridge is to make a copy of this
template/ directory:

    $ cp -r template my-new-cartridge/


Update Documentation
--------------------

Change the copyright, license information, and README as appropriate:

    $ vim my-new-cartridge/COPYRIGHT my-new-cartridge/LICENSE my-new-cartridge/README.md


Update Packaging Information
----------------------------

Rename and edit the RPM .spec file:

    $ mv my-new-cartridge/openshift-origin-cartridge-foo.1.spec my-new-cartridge/openshift-origin-cartridge-my-new-cartridge-0.1.spec
    $ vim my-new-cartridge/openshift-origin-cartridge-my-new-cartridge-0.1.spec

Modify the name, version, source, URL, and description information as
appropriate.  Also be sure to add Requires: lines for any packages that
are required on the node.

Note that later on, we will be using a tool, tito, that automatically
increments the version number.  Thus if you want an initial version of
0.1 for the built cartridge, you should set a version of 0.0 now.  Tito
will also automatically add an initial changelog entry, so leave the
%changelog stanza empty for now.

Within the %install section of the .spec file, you will see that many
symlinks are created of the form info/hooks/*foo* ->
../abstract/info/hooks/*foo*.  Cartridges use these symlinks to use the
default hooks provided by the abstract cartridge.  If you need a custom
implementation of any of these hooks, you can delete the command that
creates the symlink and ship your own custom hook instead.


Edit Control Scripts and Manifest
---------------------------------

Edit the info/bin/app_ctl.sh script:

    $ vim my-new-cartridge/info/bin/app_ctl.sh

Modify the start and stop functions as appropriate for your application.
You can search for the string 'foo' to find the parts of the file that
you need to modify.

Edit info/bin/build.sh, deploy_httpd_proxy.sh:

    $ vim my-new-cartridge/info/bin/build.sh my-new-cartridge/info/bin/deploy_httpd_proxy.sh

In each file, change the ```CART_NAME``` and ```CART_VERSION```
assignments to reflect the name and version of your new cartridge.

Update the build notes:

    $ vim my-new-cartridge/info/build/NOTES.txt

Change the space-separated cartridge name and version number
appropriately.

Update the Jenkins build information:

    $ vim my-new-cartridge/info/configuration/jenkins_job_template.xml

Jenkins is used for automated builds.  If you will not need this
functionality in your cartridge, you can ignore or delete this file.

Update the cartridge hooks:

    $ vim my-new-cartridge/info/hooks/configure my-new-cartridge/info/hooks/deconfigure

Change every instance of "foo" to the actual name of your cartridge, and
update CARTRIDGE_VERSION appropriately.

Update the cartridge manifest:

    $ vim my-new-cartridge/info/manifest.yml

Update the Name:, Display-Name:, Description:, and Help-Topics: fields
as appropriate.  Add any Requires: lines for other ***cartridges*** (not
RPM packages) on which your cartridge depends, and update Provides: to
reflect the functionality that your cartridge provides (you may simply
want to repeat the name of your cartridge).  Finally, if you cartridge
will be a standalone cartridge (i.e., a Web cartridge), add the
following line to manifest.yml:

    Cart-Type: standalone


Modify the template/
--------------------

The included template includes a template git repository, under the
template/ directory.  When a cartridge is instantiated, it creates a new
git repo for the instantiated cartridge, and the contents of the
cartridge's template/ directory are used as the initial contents of the
instances's new git repo.

For most cartridges, it makes sense to have a git repository for
application developers' code.  If having a git repository does not make
sense for the cartridge you are creating, you can delete the template/
directory entirely:

    $ rm -rf my-new-cartridge/template

If you do not include a git repository in the cartridge, you can drop
the corresponding lines from the .spec file:

    $ vim my-new-cartridge/openshift-origin-cartridge-my-new-cartridge-0.1.spec


* Delete 'BuildRequires: git'.

* Delete the stanza under "%build" (everything from the first line
  following "%build" to the next empty line).

* Delete the line begining with "cp -rp git_template.git."

The template git repository includes a template README file and
a .openshift/ directory.  Modify the README file as appropriate:

    $ vim my-new-cartridge/template/README

Within the .openshift directory, there are two additionial directories:
action_hooks/ and cron/:

    my-new-cartridge/template/.openshift/
        action_hooks/
            ...
        cron/
            daily/
            hourly/
            minutely/
            monthly/
            README.cron/
            weekly/
                ...

See [the documentation on git hooks](./git-hooks.md) for an explanation
of the action_hooks/ directory and a list of the hooks thereunder.  The
cron/ directory is used if the cron cartridge is installed; the
cartridge looks for the cronjobs here.


Build the RPM
-------------

You can now build an RPM with your new cartridge.  Change directories
into your new cartridge's directory:

    $ cd my-new-cartridge

Add the new cartridge to the git repo:

    $ git add .

Issue the tito tag command:

    $ tito tag --offline

If there is an error with your .spec file, tito will inform you and give
a hint on how to diagnose the problem.  Otherwise, tito will prompt for
an initial commit message for your new cartridge and commit it to your
local git repo.

Issue the tito build command:

    $ tito build --offline --test --rpm

This should produce a new RPM that you can upload to and install on your
node hosts.


Using your New Cartridge
------------------------

After installing your newly built cartridge on the nodes, be sure to
clear the cache on your broker host (or hosts) so that they will fetch
updated cartridge information from the nodes:

    # cd /var/www/openshift/broker
    # bundle exec rake tmp:clear

You should now be able to use your new cartridge.
