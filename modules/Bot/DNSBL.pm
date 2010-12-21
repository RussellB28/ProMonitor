# Copyright (c) 2010 ProMonitor. All rights reserved.

#use strict;
use warnings;
use Net::DNS;
use Config::Scoped;


package pBot::DNSBL;


sub Check {

	if(&pBot::config('dnsbl', 'active') eq lc("no"))
	{
		return 0;
	}

	my ( $ip ) = @_;
	my ($ipp1,$ipp2,$ipp3,$ipp4)=split /\./,$ip;
	my $reverse = "$ipp4.$ipp3.$ipp2.$ipp1";
	my $dconf = `pwd`;
	chomp $dconf;
   	my $parser = Config::Scoped->new( file => "$dconf/configs/bl/dnsbl.conf", );
   	my $config = $parser->parse;
	my $count = 0;
	my $bls;

	for (my $i = 0; $i < 20; $i++)
	{
		if($config->{list}->{$i})
		{
			my $res = new Net::DNS::Resolver;
			my $query = $res->search("$reverse.$config->{list}->{$i}", "A");
			my $rr;

			if ($query) {
       			foreach $rr ($query->answer) {
        				next unless $rr->type eq "A";
					my ($ipr1,$ipr2,$ipr3,$ipr4)=split /\./,$rr->address;
					if($ipr4 > 0 and $ipr4 < 30)
					{
						&pBot::Functions::MSG(&pBot::config('me', 'lchan'),>> HOST $ip has been found in $config->{list}->{$i} (Reason: $ipr4)");
						$bls = $config->{list}->{$i};
						$count++;
					}
       			}
			}
		}
	}

	if($count > 0)
	{
		&pBot::Functions::MSG(&pBot::config('me', 'lchan'),>> HOST $ip found in $count blacklists [Action: ".uc(&pBot::config('dnsbl', 'action'))."]");
		if(&pBot::config('dnsbl', 'action') eq lc("kline"))
		{
			&pBot::Functions::KLINE(&pBot::config('dnsbl', 'time'),"$ip","Your host is listed in the following blacklist: $bls");
			return 1;
		}
		elsif(&pBot::config('dnsbl', 'action') eq lc("akill"))
		{
			&pBot::Functions::AKILL(&pBot::config('dnsbl', 'time'),"*@".$ip,"Your host is listed in the following blacklist: $bls");
			return 1;
		}
	}
	else
	{
		&pBot::Functions::MSG(&pBot::config('me', 'lchan'),>> HOST $ip found in $count blacklists");
		return 1;
	}
}


sub CheckL {

	if(&pBot::config('dnsbl', 'active') eq lc("no"))
	{
		return 0;
	}

	my ( $ip ) = @_;
	my $dconf = `pwd`;
	chomp $dconf;
   	my $parser = Config::Scoped->new( file => "$dconf/configs/bl/dnsbl.conf", );
   	my $config = $parser->parse;

		if($config->{badip}->{$ip})
		{
			&pBot::Functions::MSG(&pBot::config('me', 'lchan'),>> HOST $ip is listed in ProBL (Reason: $config->{badip}->{$ip}) [ACTION: ".uc(&pBot::config('dnsbl', 'action'))."]");

                        if(&pBot::config('dnsbl', 'action') eq lc("kline"))
			{
				&pBot::Functions::KLINE(&pBot::config('dnsbl', 'time'),"*@$ip","Your host is listed in ProBL: $config->{badip}->{$ip}");
				return 1;
			}
			elsif(&pBot::config('dnsbl', 'action') eq lc("akill"))
			{
				&pBot::Functions::AKILL(&pBot::config('dnsbl', 'time'),"*@".$ip,"Your host is listed in ProBL: $config->{badip}->{$ip}");
				return 1;
			}
		}
		else
		{
			&pBot::Functions::MSG(&pBot::config('me', 'lchan'),>> HOST $ip was not found in ProBL (Local List)");
		}

}

1;
