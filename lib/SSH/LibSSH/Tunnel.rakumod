unit class SSH::LibSSH::Tunnel;

=begin pod

=head1 NAME

SSH::LibSSH::Tunnel - blah blah blah

=head1 SYNOPSIS

=begin code :lang<raku>

use SSH::LibSSH::Tunnel;

=end code

=head1 DESCRIPTION

SSH::LibSSH::Tunnel is a library (based on SSH::LibSSH) to simplify the setup of forwarding SSH tunnels.

=head1 AUTHOR

Humberto Massa <humbertomassa@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Humberto Massa

This library is free software; you can redistribute it and/or modify it under either the Artistic License 2.0 or the LGPL v3.0, at your convenience.

=end pod

use SSH::LibSSH;

constant LOCALHOST = '127.0.0.1';
has Str $.local-host is rw = LOCALHOST;
has Int $.local-port is rw = 0;
has Str $.tunnel-host is required;
has Int $.tunnel-port = 22;
has Str $.tunnel-user is required;
has Str $.remote-host is required;
has Int $.remote-port is required;
has IO() $.private-key-file is required;

method connect() {
  my Promise $tunnel-server .= new;
  my $remote-connection = await SSH::LibSSH.connect: host => $.tunnel-host, port => $.tunnel-port,
    user => $.tunnel-user, private-key => $.private-key-file;
  start {
    react {
      $tunnel-server.keep: do
        whenever IO::Socket::Async.listen($.local-host, $.local-port) -> IO::Socket::Async:D $connection {
          whenever $remote-connection.forward($.remote-host, $.remote-port, $.local-host, $.local-port) -> $channel {
            whenever $connection.Supply(:bin) {
              $channel.write: $_;
              LAST $channel.close
            }
            whenever $channel.Supply(:bin) {
              $connection.write: $_;
              LAST $connection.close
            }
            QUIT { $tunnel-server.close; .rethrow }
          }
        }
      whenever signal(SIGINT) {
        #yap "Shutting down tunnel to $remote-host:$remote-port at $local-port thru $host";
        $remote-connection.close;
        done
      }
    }
  }
  my $server = await $tunnel-server;
  $.local-host = await $server.socket-host;
  $.local-port = await $server.socket-port;
  self
}


