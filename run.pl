#!/usr/bin/perl


use strict;
use warnings;
use lib 'modules';
package pBot;
use Net::DNS;
use Config::Scoped;
use Socket;
use Net::SSLeay qw(die_now die_if_ssl_error copy_session_id);
use IRC::CallBacks;
use IRC::Functions;
use Bot::Commands;
use Bot::DNSBL;
use Bot::Port;
use Bot::Info;
our $VERSION = "1.0a";
our (%rawcmds, %timers, %COMMANDS);
our $c_netop;

Net::SSLeay::load_error_strings();
Net::SSLeay::SSLeay_add_ssl_algorithms();
Net::SSLeay::randomize();

# Get configuration values
my $conf = Config::Scoped->new(
    file => "configs/bot.conf",
) or error("bot", "We couldn't open the config file!\n");

# Put them into variables	
my $settings = $conf->parse;

# Open the socket
my $dest_ip = gethostbyname(config('server', 'host'));
my $dest_serv_params = sockaddr_in(config('server', 'port'), $dest_ip );

socket( S, &AF_INET, &SOCK_STREAM, 0 ) or error("bot", "The Socket could not be created.\n");
connect( S, $dest_serv_params ) or error("bot", "The Connection to the server failed :(!\n");

my $ctx = Net::SSLeay::CTX_new() or die_now("Cannot create SSL_CTX $!");
Net::SSLeay::CTX_set_options( $ctx,&Net::SSLeay::OP_NO_SSLv2 ) and die_if_ssl_error("SSL_CTX_SETOPTIONS Failed!");
Net::SSLeay::CTX_use_RSAPrivateKey_file ($ctx, config('ssl', 'key'), &Net::SSLeay::FILETYPE_PEM) and die_if_ssl_error("Error: Private Key not Found or Valid");
Net::SSLeay::CTX_use_certificate_file ($ctx, config('ssl', 'cert'),&Net::SSLeay::FILETYPE_PEM) and die_if_ssl_error("Error: Certificate not Found or Valid");

my $ssl1 = Net::SSLeay::new($ctx) or die_now("Cannot create SSL $!");

Net::SSLeay::set_fd( $ssl1, fileno(S) );
my $res = Net::SSLeay::connect($ssl1) and die_if_ssl_error("SSL failed to Connect!");

# Throw the program into an infinite while loop
while (1) {
	my $data = Net::SSLeay::read($ssl1);
	unless (defined($data)) {
		sleep 3;
		#$socket = IO::Socket::SSL->new(
		#	Proto => "tcp",
		#	LocalAddr => config('server', 'vhost'),
		#	PeerAddr => config('server', 'host'),
		#	PeerPort => config('server', 'port'),
		#	SSL_verify_mode => 0x01,
		#) or error("bot", "Connection to ".config('server', 'host')." failed.\n");
		#&pBot::CallBacks::irc_connect();
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

	 if(&pBot::config('server', 'ircd') eq lc("shadowircd"))
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
	elsif(&pBot::config('server', 'ircd') eq lc("inspircd"))
	{
        	if ($data =~ m/Client connecting/) {
			$ex[7] =~ s/\[//g;
			$ex[7] =~ s/\]//g;
			&pBot::CallBacks::irc_cliconnect(&pBot::config('me', 'lchan'),$ex[8],$ex[8],$ex[8],$ex[7]);
	 	}

        	if ($data =~ m/Client exiting/) {
			&pBot::CallBacks::irc_cliexit(&pBot::config('me', 'lchan'),$ex[6],$ex[6],$ex[6]);
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
    $res = Net::SSLeay::write( $ssl1, $str."\r\n");
    die_if_ssl_error("Send Socket Error while Writing via SSL (Content: $str)");
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



