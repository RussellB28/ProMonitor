# Copyright (c) 2010 Russell M Bradford. All rights reserved.

#use strict;
use warnings;
use Net::DNS;
use Config::Scoped;


package pBot::Info;


sub CheckNick {
	my ( $nick ) = @_;
	my $dconf = `pwd`;
	chomp $dconf;
   	my $parser = Config::Scoped->new( file => "$dconf/configs/bl/nicks.conf", );
   	my $config = $parser->parse;

		if($config->{badnick}->{$nick})
		{
			&pBot::Functions::MSG(&pBot::config('me', 'chan'),">> NICK: $nick is listed in ProBL (Reason: $config->{badnick}->{$nick})");
		}
		else
		{
			&pBot::Functions::MSG(&pBot::config('me', 'chan'),">> NICK: $nick was not found in ProBL (Local List)");
		}

}

sub CheckIdent {
	my ( $ident ) = @_;
	my $dconf = `pwd`;
	chomp $dconf;
   	my $parser = Config::Scoped->new( file => "$dconf/configs/bl/idents.conf", );
   	my $config = $parser->parse;
		
		if(length($ident) < 4)
		{
			&pBot::Functions::MSG(&pBot::config('me', 'chan'),">> USER: WARNING -- $ident is less than 4 characters. Possible Bot?");
		}

		if($config->{badident}->{$ident})
		{
			&pBot::Functions::MSG(&pBot::config('me', 'chan'),">> USER: $ident is listed in ProBL (Reason: $config->{badident}->{$ident})");
		}
		else
		{
			&pBot::Functions::MSG(&pBot::config('me', 'chan'),">> USER: $ident was not found in ProBL (Local List)");
		}

}

1;