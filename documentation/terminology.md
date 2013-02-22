Glossary
========

Following is a glossary of terms for key low-level concepts within OpenShift.

<dl>
  <dt>The abstract cartridge</dt>
  <dd>A quasi cartridge that cannot be instantiated but which provides default hooks on which other cartridges can fall back as well as a library of shell scripts which hooks can call.  The abstract cartridge can be regarded as an abstract class and the superclass of all other cartridges.</dd>

  <dt>Application</dt>
  <dd>A set of one or more instantiated cartridges running on one or more gears.</dd>
  <dd>Sometimes confounded with the term "gear" as an application often has only one gear, but conceptually it is a container of gears.</dd>

  <dt>Cartridge</dt>
  <dd>A plug-in that is installed on nodes, and is instantiated in ("added to" or "embedded in") gears, that provides functionality to applications running on OpenShift.</dd>
  <dd>A cartridge instantiation into a particular gear.</dd>

  <dt>Container</dt>
  <dd>When used without clarifying context in code or docs, refers to a gear.</dd>

  <dt>Custom cartridge</dt>
  <dd>A cartridge not supplied as part of the OpenShift Origin/Online/Enterprise projects, but rather created custom for an installation of OpenShift.</dd>

  <dt>Gear</dt>
  <dd>A container that includes a limited amount of CPU resources, memory, and storage.  A gear is hosted on a node and can be thought of as a VM, but it is implemented as a Unix user and contained using cgroups, SELinux, and other Linux security features instead of virtualisation.</dd>

  <dt>Regular cartridge</dt>
  <dd>Provides support for functionality on which an OpenShift application may rely.  For example, cartridges exist for the MySQL and PostgreSQL database servers.  Formerly known as an "embedded" cartridge.</dd>

  <dt>Web cartridge</dt>
  <dd>Provides support for a specific type of application to run on OpenShift.  For example, a Web cartridge exists that supports PHP development, and another exists for Ruby development.  Formerly known as a "standalone" cartridge or "framework" cartridge.</dd>
</dl>
