unit class SSH::LibSSH::Tunnel;

=begin pod

=head1 NAME

SSH::LibSSH::Tunnel - establish remote forwarding SSH tunnel

=head1 SYNOPSIS

=begin code :lang<raku>

use SSH::LibSSH::Tunnel;

my SSH::LibSSH::Tunnel:D $ssh-tunnel .= new: :tunnel-host<intermediary>, :tunnel-user<useratintermediary>,
  :local-host<127.0.0.1>, :local-port<33333>, # zero local-port means "let the OS choose"
  :remote-host<finaldestination>, :remote-port<3306>, :private-key-file($*HOME.add: '.ssh/some_key');
my $connection = $ssh-tunnel.connect;
# at this point, the tunnel is already connected

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

=begin pod

=head1 METHOD

=end pod

#| Establish the connection, synchronously. Returns self.
method connect(--> SSH::LibSSH::Tunnel) {
  my Promise $tunnel-server .= new;
  my $remote-connection = await SSH::LibSSH.connect: host => $.tunnel-host, :port($.tunnel-port//0),
    user => $.tunnel-user, private-key => $.private-key-file;
  start {
    react {
      $tunnel-server.keep: do
        whenever IO::Socket::Async.listen($.local-host, $.local-port) -> IO::Socket::Async:D $connection {
          whenever $remote-connection.forward($.remote-host, $.remote-port, $.local-host, $.local-port) -> $channel {
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

Copyright 2023 - 2024 Humberto Massa

This library is free software; you can redistribute it and/or modify it under either the Artistic License 2.0 or the LGPL v3.0, at your convenience.

=end pod


