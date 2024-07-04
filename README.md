[![Actions Status](https://github.com/massa/SSH-LibSSH-Tunnel/actions/workflows/linux.yml/badge.svg)](https://github.com/massa/SSH-LibSSH-Tunnel/actions) [![Actions Status](https://github.com/massa/SSH-LibSSH-Tunnel/actions/workflows/macos.yml/badge.svg)](https://github.com/massa/SSH-LibSSH-Tunnel/actions) [![Actions Status](https://github.com/massa/SSH-LibSSH-Tunnel/actions/workflows/windows.yml/badge.svg)](https://github.com/massa/SSH-LibSSH-Tunnel/actions)

NAME
====

SSH::LibSSH::Tunnel - establish remote forwarding SSH tunnel

SYNOPSIS
========

```raku
use SSH::LibSSH::Tunnel;

my SSH::LibSSH::Tunnel:D $ssh-tunnel .= new: :tunnel-host<intermediary>,
   :tunnel-user<useratintermediary>,
   :tunnel-port(22), # default is 22 (ssh)
   :local-host<127.0.0.1>, # default is 127.0.0.1 (localhost)
   :local-port<33333>, # default (zero) means "let the OS choose"
   :remote-host<finaldestination>,
   :remote-port<3306>,
   :private-key-file($*HOME.add: '.ssh/some_key'),
   :timeout(30); # default is 30s -- passed to SSH::LibSSH
my $connection = $ssh-tunnel.connect;
# at this point, the tunnel is already connected
my $port-to-connect = $ssh-tunnel.local-port; # useful if passed the default
```

DESCRIPTION
===========

SSH::LibSSH::Tunnel is a library (based on SSH::LibSSH) to simplify the setup of forwarding SSH tunnels.

FIELDS
======

### has Str $.local-host

address that will listen locally for the tunnel

### has Int(Any) $.local-port

port that will listen locally for the tunnel

### has Str $.tunnel-host

intermediary host (will connect on it via ssh)

### has Int(Any) $.tunnel-port

intermediary SSH service port

### has Str $.tunnel-user

SSH user on the intermediary host

### has IO(Any) $.private-key-file

SSH private key file for connection (no password, for now)

### has Str $.remote-host

destination tunnel host

### has Int(Any) $.remote-port

destination tunnel port

### has Int(Any) $.timeout

destination tunnel port

METHOD
======

### method connect

```raku
method connect() returns SSH::LibSSH::Tunnel
```

Establish the connection, synchronously. Returns self.

AUTHOR
======

Humberto Massa <humbertomassa@gmail.com>

COPYRIGHT AND LICENSE
=====================

Copyright © 2023 - 2024 Humberto Massa

This library is free software; you can redistribute it and/or modify it under either the Artistic License 2.0 or the LGPL v3.0, at your convenience.

