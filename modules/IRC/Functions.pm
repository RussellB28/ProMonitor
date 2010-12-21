# Copyright (c) 2010 ProMonitor. All rights reserved.

use strict;
use warnings;

package pBot::Functions;


sub MSG {
	my($chan,$msg) = @_;
 	chomp($chan);
 	chomp($msg);
	&pBot::send_sock("PRIVMSG ".$chan." :".$msg."\n");
}

sub NICK {
	my($nick) = @_;
 	chomp($nick);
	&pBot::send_sock("NICK ".$nick."");
}

sub JOIN {
	my($chan,$key) = @_;
 	chomp($chan);
 	chomp($key);
	&pBot::send_sock("JOIN ".$chan." ".$key."\n");
}

sub PART {
	my($chan,$reason) = @_;
 	chomp($chan);
 	chomp($reason);
	&pBot::send_sock("PART ".$chan." ".$reason."\n");
}

sub KLINE {
	my($time,$host,$reason) = @_;
        chomp($time);
        chomp($host);
        chomp($reason);
        &pBot::send_sock("KLINE $time $host :$reason\n");
}

sub AKILL {
	my($time,$host,$reason) = @_;
        chomp($time);
        chomp($host);
        chomp($reason);
	&pBot::send_sock("PRIVMSG OperServ :AKILL ADD $host !T $time $reason\n");
}

1;
