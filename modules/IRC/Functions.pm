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

sub OPERSTATS {
	&pBot::send_sock("STATS P\n");
}

1;