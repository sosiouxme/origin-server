OpenShift Hooks for Git
=======================

When a user installs a cartridge with a git repository, the user may
modify the OpenShift hooks stored under .openshift/action_hooks in the
git repo.

    $ vim my-new-cartridge/template/.openshift/action_hooks/start my-new-cartridge/template/.openshift/action_hooks/stop

These hooks are called by the cartridge's app_ctl.sh script.
(Specifically, most app_ctl.sh scripts call run_user_hook with the
appropriate action.  For example, `app_ctl.sh start` will perform its
work and then run `run_user_hook start`, which will run
`${OPENSHIFT_REPO_DIR}.openshift/action_hooks/start`.) In this manner,
application developers can hook into or extend the standard OpenShift
cartridge hooks.

List of Hooks
=============

TODO

Notes
=====

Hooks should return immediately, so if one starts a daemon in the start
hook, one must be sure that the daemon forks and returns to the start
hook (nohup(1) may be useful) so that the start hook may then return.

Hooks should not print output; any output should be discarded or
redirected to a log file.  Log files can be stored under
$OPENSHIFT_HOMEDIR/*cartridge-name*/logs/.

Hooks should return with an exit-status of 0.
