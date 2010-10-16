#!/usr/bin/perl


use strict;
use warnings;
use lib 'modules';
package pBot;
use IO::Socket;
use Net::DNS;
use Config::Scoped;
use IRC::CallBacks;
use IRC::Functions;
use Bot::Commands;
use Bot::DNSBL;
use Bot::Port;
use Bot::Info;
our $VERSION = "1.0a";
our (%rawcmds, %timers, %COMMANDS);
our $c_netop;

# Get configuration values
my $conf = Config::Scoped->new(
    file => "configs/bot.conf",
) or error("bot", "We couldn't open the config file!\n");

# Put them into variables	
my $settings = $conf->parse;

# Open the socket
my $socket = IO::Socket::INET->new(
    Proto => "tcp",
    LocalAddr => config('server', 'vhost'),
    PeerAddr => config('server', 'host'),
    PeerPort => config('server', 'port'),
) or error("bot", "Connection to ".config('server', 'host')." failed.\n");


# Connect!
#irc_connect();


# Throw the program into an infinite while loop
while (1) {
	my $data = <$socket>;
	unless (defined($data)) {
		sleep 3;
		$socket = IO::Socket::INET->new(
			Proto => "tcp",
			LocalAddr => config('server', 'vhost'),
			PeerAddr => config('server', 'host'),
			PeerPort => config('server', 'port'),
		) or error("bot", "Connection to ".config('server', 'host')." failed.\n");
		&pBot::CallBacks->irc_connect();
	}

    chomp($data);
    #undef $ex;
    my @ex = split(' ', $data);

    print("[IRC-RAW] ".$data."\n");
    my $USER = substr($ex[0], 1);
	my $bnick = config('me', 'nick');

        if ($data =~ m/Found your hostname/) {
		&pBot::CallBacks::irc_connect();
	 }

        if ($data =~ m/MODE ($bnick)/) {
		&pBot::CallBacks::irc_onconnect();
	 }

	 if(&pBot::config('me', 'ircd') eq lc("charybdis"))
	 {

        	if ($data =~ m/Client connecting/) {
			$ex[10] =~ s/\[//g;
			$ex[10] =~ s/\]//g;
			$ex[9] =~ s/\(//g;
			$ex[9] =~ s/\)//g;
 			my @sex = split('@', $ex[9]);
			&pBot::CallBacks::irc_cliconnect(&pBot::config('me', 'lchan'),$ex[8],$sex[0],$sex[1],$ex[10]);
	 	}

        	if ($data =~ m/Client exiting/) {
			$ex[9] =~ s/\(//g;
			$ex[9] =~ s/\)//g;
 			my @sex = split('@', $ex[9]);
			&pBot::CallBacks::irc_cliexit(&pBot::config('me', 'lchan'),$ex[8],$sex[0],$sex[1]);
	 	}

        	if ($data =~ m/Possible Flooder/) {
			&pBot::CallBacks::irc_cliflood(&pBot::config('me', 'lchan'),$ex[8],$ex[12]);
	 	}
	 }


        if ($ex[1] eq "JOIN") {
		$ex[2] =~ s/://g;
		&pBot::CallBacks::irc_onchanjoin($ex[2]);
	 }

        if ($ex[1] eq "INVITE") {
		$ex[3] =~ s/://g;
		&pBot::CallBacks::irc_onchaninvite($ex[3]);
	 }

        if ($ex[1] eq "249") {
		$ex[0] =~ s/://g;
		#$ex[3] =~ s/://g;
		my($argz) = substr($ex[3], 1);
		my ($i);
    		for ($i = 4; $i < count(@ex); $i++) { $argz .= ' '.$ex[$i]; }
		&pBot::send_sock("PRIVMSG ".$c_netop." :".$argz."\n");
	 }

        if ($ex[1] eq "KICK" && $ex[3] == $bnick) {
		&pBot::CallBacks::irc_onchankick($ex[2]);
	 }

        if ($ex[1] eq "PRIVMSG") {
		$ex[0] =~ s/://g;
		$ex[3] =~ s/://g;
		my($argz) = substr($ex[4], 1);
		my ($i);
    		for ($i = 4; $i < count(@ex); $i++) { $argz .= ' '.$ex[$i]; }
		&pBot::CallBacks::irc_onprivmsg($ex[0],$ex[2],$ex[3],$argz);
	 }


        if ($ex[0] eq "PING") {
		&pBot::CallBacks::irc_onping($ex[1]);
	 }

    # Handle a server command, if a handler is defined in the protocol module
    if ($rawcmds{$ex[1]}{handler}) 
    {
        my $sub_ref = $rawcmds{$ex[1]}{handler};
        eval 
        {
            &{ $sub_ref }($data);
        };
    }
}



sub send_sock {
    my ($str) = @_;
    chomp($str);
    send($socket, $str."\r\n", 0);
    print("[BOT-RAW] ".$str."\n");
}

sub config {
    my ($block, $name) = @_;
    $block = lc($block);
    $name = lc($name);
    if (defined $settings->{$block}->{$name}) 
    {
        return $settings->{$block}->{$name};
    } else 
    {
        return 0;
    }
}

sub error {
    my ( $type, $msg ) = @_;
    my ($file);
    if ( $type ne 0 ) {
        $type = lc($type);
        print("Error: $type - $msg");
    }
    exit;
}


sub count {
	my (@array) = @_;
	my ($i, $ai);
	foreach $ai (@array) {
		$i += 1;
	}
	return $i;
}

sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}



