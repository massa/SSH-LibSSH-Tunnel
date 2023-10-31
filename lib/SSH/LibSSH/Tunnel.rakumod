unit class SSH::LibSSH::Tunnel;

=begin pod

=head1 NAME

SSH::LibSSH::Tunnel - blah blah blah

=head1 SYNOPSIS

=begin code :lang<raku>

use SSH::LibSSH::Tunnel;

=end code

=head1 DESCRIPTION

SSH::LibSSH::Tunnel is ...

=head1 AUTHOR

Humberto Massa <humbertomassa@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2023 Humberto Massa

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

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
  #  my Promise $tunnel-established .= new;
  start {
    my $session = await SSH::LibSSH.connect: host => $.tunnel-host, port => $.tunnel-port,
      user => $.tunnel-user, private-key => $.private-key-file;
    react {
      whenever IO::Socket::Async.listen($.local-host, $.local-port) -> $connection {
        $.local-port = $connection.socket-port;
        $.local-host = $connection.socket-host;
        #      $tunnel-established.keep(1);
        whenever $session.forward($.remote-host, $.remote-port, $.local-host, $.local-port) -> $channel {
          whenever $connection.Supply(:bin) {
            $channel.write($_);
            LAST $channel.close;
          }
          whenever $channel.Supply(:bin) {
            $connection.write($_);
            LAST $connection.close;
          }
        }
      }
      whenever signal(SIGINT) {
        #yap "Shutting down tunnel to $remote-host:$remote-port at $local-port thru $host";
        $session.close;
        done;
      }
    }
  }
  #  await $tunnel-established;
  sleep 5;
  self
}


