# Copyright (c) 2010 ProMonitor. All rights reserved.

use strict;
use warnings;
use Net::DNS;
use Config::Scoped;


package pBot::Port;
use IO::Socket::PortState qw(check_ports);


sub CheckPort {

        if(&pBot::config('port', 'active') eq lc("no"))
        {
                return 0;
        }

	my ( $ip ) = @_;
   	my %porthash = (
      			tcp => {
         			8080 => {
            				name => 'Proxy Port 1', 
         			},
         			3127 => {
            				name => 'Proxy Port 2',
         			},
      			}, 
      			udp => {
      			},
   	);
	my $count = 0;

   	check_ports($ip,60,\%porthash);

   	for my $proto (keys %porthash) {
      		for(keys %{ $porthash{$proto} }) {
			if($porthash{$proto}->{$_}->{open})
			{
				&pBot::Functions::MSG(&pBot::config('me', 'chan'),">> PORT: $proto $_ is open on $ip");
				$count++;
			}
      		}
   	}
	&pBot::Functions::MSG(&pBot::config('me', 'chan'),">> PORT: $count proxy ports found open on $ip");
}

1;
