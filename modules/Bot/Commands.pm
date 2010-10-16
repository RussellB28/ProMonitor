use strict;
use warnings;

package pBot::Commands;


sub cmd_eval {
	my($owner,$chan,$cmd,$message) = @_;
 	chomp($owner);
 	chomp($chan);
 	chomp($cmd);
 	chomp($message);
	my $onick = &pBot::config('me', 'onick');
	if($owner =~ m/($onick)/)
	{
		eval($message);
		&pBot::Functions::MSG($chan,"3[SUCCESS] Evaluated Code");
	}
	else
	{
		&pBot::Functions::MSG($chan,"4[FAILURE] You not have permission to use this command");
	}
}

sub cmd_uptime {
	my($owner,$chan,$cmd,$varz) = @_;
 	chomp($owner);
 	chomp($chan);
 	chomp($cmd);
 	chomp($varz);

	if(&pBot::trim($varz) =~ m/BOT/)
	{
		&pBot::Functions::MSG($chan,"2[UPTIME] ProMonitor: Unavailable");
	}
	elsif(&pBot::trim($varz) =~ m/SYSTEM/)
	{
		my $result = `uptime`;
		&pBot::Functions::MSG($chan,"2[UPTIME] System: ".$result);
	}
	else
	{
		&pBot::Functions::MSG($chan,"4[FAILURE] Syntax: !uptime [SYSTEM | BOT]");
	}
}

sub cmd_stest {
	my($owner,$chan,$cmd,$message) = @_;
 	chomp($owner);
 	chomp($chan);
 	chomp($cmd);
 	chomp($message);

	&pBot::Functions::MSG($chan,"4[SERVER-CMD] ProMonitor is still connected to ".&pBot::config('server','host')." and active!");
}

sub cmd_netops {
	my($owner,$chan,$cmd,$message) = @_;
 	chomp($owner);
 	chomp($chan);
 	chomp($cmd);
 	chomp($message);
	$pBot::c_netop = $chan;
	&pBot::Functions::OPERSTATS();
}

1;