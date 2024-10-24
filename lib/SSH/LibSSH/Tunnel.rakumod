unit class SSH::LibSSH::Tunnel;

=begin pod

=head1 NAME

SSH::LibSSH::Tunnel - establish remote forwarding SSH tunnel

=head1 SYNOPSIS

=begin code :lang<raku>

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

=end code

=head1 DESCRIPTION

SSH::LibSSH::Tunnel is a library (based on SSH::LibSSH) to simplify the setup of forwarding SSH tunnels.

=head1 FIELDS

=end pod

use SSH::LibSSH;

constant LOCALHOST = '127.0.0.1';
#| address that will listen locally for the tunnel
has Str $.local-host is rw = LOCALHOST;
#| port that will listen locally for the tunnel
has Int() $.local-port is rw = 0;
#| intermediary host (will connect on it via ssh)
has Str $.tunnel-host is required;
#| intermediary SSH service port
has Int() $.tunnel-port = 22;
#| SSH user on the intermediary host
has Str $.tunnel-user is required;
#| SSH private key file for connection (no password, for now)
has IO() $.private-key-file is required;
#| destination tunnel host
has Str $.remote-host is required;
#| destination tunnel port
has Int() $.remote-port is required;
#| destination tunnel port
has Int() $.timeout = 30;

=begin pod

=head1 METHOD

=end pod

#| Establish the connection, synchronously. Returns self.
method connect(--> SSH::LibSSH::Tunnel) {
  my Promise $tunnel-server .= new;
  my $remote-connection = await SSH::LibSSH.connect: host => $!tunnel-host, port => $!tunnel-port.Int,
    user => $!tunnel-user, private-key => $!private-key-file, timeout => $!timeout;
  start {
    react {
      my $s = do
        whenever IO::Socket::Async.listen($.local-host, $.local-port.Int) -> IO::Socket::Async:D $connection {
          whenever $remote-connection.forward($.remote-host, $.remote-port.Int, $.local-host, $.local-port.Int) -> $channel {
            whenever $connection.Supply(:bin) {
              $channel.write: $_;
              QUIT { default { warn .raku } }
              LAST $channel.close
            }
            whenever $channel.Supply(:bin) {
              $connection.write: $_;
              QUIT { default { warn .raku } }
              LAST $connection.close
            }
            QUIT { $remote-connection.close; .rethrow }
          }
        }
      whenever $s.socket-port {
        $tunnel-server.keep: $s
      }
      whenever signal(SIGINT) {
        QUIT { default { warn .raku } }
        $remote-connection.close;
        done
      }
      QUIT { default { warn .raku } }
    }
  }
  my $server = await $tunnel-server;
  $.local-host = await $server.socket-host;
  $.local-port = await $server.socket-port;
  self
}

=begin pod

=head1 AUTHOR

Humberto Massa <humbertomassa@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright © 2023 - 2024 Humberto Massa

This library is free software; you can redistribute it and/or modify it under either the Artistic License 2.0 or the LGPL v3.0, at your convenience.

=end pod


