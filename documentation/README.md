Documentation
=============

The files in this directory aim to provide links into the code and documentation
files elsewhere in the repository, which are always the ultimate authority on
how things work.  The goal of the files in this directory is __not__ to
duplicate the wealth of knowledge available on the Internet or the various
README files in the package directories but merely to be a tool for assisting
the developer to understand where to look to find out more information.

Ideally to be included in this directory the document should:

* be less than < 750 words
* deal with a subject that touches multiple OpenShift packages or libraries

Developers are encouraged to ship documentation in the form of READMEs alongside
the code or inlined for generation with yard.  We realize there a handful of
systems in OpenShift whose functionality is distributed amongst several
packages.   In these cases, the corresponding documentation files can be placed
in this directory.  However, where possible, this file and the documents in this
directory should provide pointers to documentation elsewhere in the repository
or on the Internet.

Index
=====

Following is an index of documentation contained within this repository.

* [Architecture](../README.md).  Describes the basic components of an OpenShift
installation.

* [Cartridges Overview](../cartridges/README.md).  Defines the concepts of hooks,
connection hooks, profiles, components, and connectors and describes cartridges
in logical and concrete terms.

* [Creating a New Cartridge](../cartridges/creating-a-new-cartridge.md).
Explains, step-by-step, how to create a new cartridge.

* [Communication between Broker and Node](./communication-between-broker-and-node.md).
Describes how the broker commands a node to carry out certain operations.

* [Console](../console/README.md).  Describes configuration and development
guidelines.

* [Environment variables](./environment_variables.md).  Describes how cartridges
use environment variables and how they are stored by and communicated between
broker and node.

* [How nodes act on behalf of users](./how_nodes_act_on_behalf_of_users.md).
Describes how cartridges such haproxy and jenkins authenticate with the broker
to carry out certain operations.

* [Idler](../node-util/README-Idler.md).  Describes installation, configuration,
and use of the idler.

* [Node](../node/README.md).  Describes the role of the node in the
OpenShift architecture.

* [Port proxy](../port-proxy/README.md).  Describes the role of the
port-proxy in the OpenShift architecture.

* [Scaling](./scaling.md).  Describes the technical aspects of how OpenShift
scales applications across gears.

* [Scaling example](./scaling-example.md).  Provides an example of how
scaling works with the MongoDB embedded cartridge.

* [Terminology](./terminology.md).  Provides a glossary of the terms used
throughout the documentation.
