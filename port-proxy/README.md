OpenShift Origin - Port Proxy
=============================

Linux handles the loopback interface's 127.0.0.0/8 address block
specially: A request from an address in this block can only go to an
address in the same block (put another way, a connection on the loopback
interface is confined to the loopback interface).  OpenShift uses this
fact to contain hosted applications: a gear is prohibited by iptables
from listening on an external network interface, and so a given gear can
only respond to connections that come from processes on the same node.

For the common case of Web connections, the system Apache instance acts
as a reverse proxy, forwarding requests that come in on the external
interface to the appropriate 127.x.y.z address; see [the documentation
on the node component](../node/README.md).

However, sometimes gears need to accept other types of connections.
The two most common such scenarios are the following:

* A gear needs to connect to another gear (which may be on the same node
  or another node).

* A gear needs to listen for connections on a public interface besides
  HTTP connections to port 80.

For example, a game server needs to expose a port to receive incoming
connections from clients, and a database needs to expost a port so that
other gears can connect to it.

To meet these needs, OpenShift uses haproxy to proxy TCP connections
between an external-facing network interface and the loopback interface.
Each gear is assigned five exposable ports, and the gear may establish
a forwarding rule for each of these ports to forward connections on the
the port on the external interface to an arbitrary port on the gear's
assigned loopback address.

To provide haproxy with adequate ports, we shift the ephemeral port
range down to 15000-35530, so that Linux will not use ports outside of
this range for connections for which no port is given explicitly.  This
means that ports 35531-65535 will be available for haproxy's exclusive
use.

Note: Given that each gear is assigned 5 ports, this imposes a limit of
6000 gears per node.

The interaction with haproxy is implemented on the cartridge side in
cartridges/openshift-origin-cartridge-abstract/abstract/info/lib/network
