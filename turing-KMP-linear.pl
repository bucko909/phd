#!/usr/bin/perl

# Simulates a Turing machine with finite state set, 5 tracks and 6 heads which
# uses the KMP method for sybstring matching. The head count and track count
# can be reduced by being more clever with the R and S tracks (they store only
# numbers).

# It takes at most 40 operations per input character (when both strings are
# length 1).

use strict;
use warnings;

our %tracks;
our %heads;

our ($reads, $writes, $moves) = (0, 0, 0);
sub head_read {
	$reads++;
	my ($pos, $tape) = @{$heads{$_[0]}};
	return substr($tracks{$tape}, $pos, 1);
}

sub head_write {
	$writes++;
	my ($pos, $tape) = @{$heads{$_[0]}};
	substr($tracks{$tape}, $pos, 1, $_[1]);
}

sub head_left {
	$moves++;
	$heads{$_[0]}[0]--;
}

sub head_right {
	$moves++;
	$heads{$_[0]}[0]++;
	$tracks{$heads{$_[0]}[1]} .= "." if $heads{$_[0]}[0] >= length($tracks{$heads{$_[0]}[1]});
}

sub tape_swap {
	($tracks{$_[0]}, $tracks{$_[1]}) = ($tracks{$_[1]}, $tracks{$_[0]});
	($heads{$_[0]}[0], $heads{$_[1]}[0]) = ($heads{$_[1]}[0], $heads{$_[0]}[0]);
}

sub head_new {
	die "duplicate head $_[0]" if $heads{$_[0]};
	$heads{$_[0]} = [ 0, $_[1] ];
}

sub head_kill {
	head_reset($_[0]);
	delete $heads{$_[0]};
}

sub head_reset {
	head_left($_[0]) while head_read($_[0]) ne "!";
}

sub print_heads {
	print "Heads list:\n";
	for my $n (sort keys %heads) {
		print "$n:\n";
		print "\t$tracks{$heads{$n}[1]}\n";
		print "\t".(" " x $heads{$n}[0])."^\n";
	}
}

# 16 ticks init. 40 ops absolute max per needle char.
sub generate_table {
	head_new("needle_1", "needle");
	head_new("needle_2", "needle");
	head_new("table_1", "table");
	head_new("table_2", "table");
	head_new("R", "R");
	head_new("S", "S");
	head_right("needle_2");
	head_right("table_2");
	head_right("R");
	while(head_read("needle_2") ne "#") {
		head_write("table_2", "+");
		head_right("table_2");
		while(head_read("needle_1") ne head_read("needle_2") && head_read("R") ne "!" && head_read("needle_1") ne "!") {
			while(head_read("R") ne "!") {
				head_left("needle_1");
				head_left("table_1");
				head_left("R");
				head_right("S");
				while(head_read("table_1") eq "-") {
					head_left("table_1");
					head_left("S");
				}
				head_write("table_2", "-");
				head_right("table_2");
			}
			tape_swap("R", "S");
		}
		if (head_read("needle_1") eq head_read("needle_2")) {
			head_right("needle_1");
			head_right("table_1");
			while (head_read("table_1") eq "-") {
				head_right("table_1");
				head_right("R");
			}
		}
		if (head_read("needle_1") eq "!") {
			head_right("needle_1");
			head_right("table_1");
		}
		head_right("needle_2");
	}
	head_kill("needle_1");
	head_kill("needle_2");
	head_kill("table_1");
	head_kill("table_2");
	head_kill("R");
	head_kill("S");
}

# 18 ticks init. 35 ops absolute max per haystack char.
sub check_string {
	head_new("needle", "needle");
	head_new("haystack", "haystack");
	head_new("table", "table");
	head_new("R", "R");
	head_new("S", "S");
	head_right("needle");
	head_right("table");
	head_right("haystack");
	head_right("R");
	my $r = 0;
	while(head_read("haystack") ne "#") {
		while(head_read("needle") ne head_read("haystack") && head_read("R") ne "!" && head_read("needle") ne "!") {
			while(head_read("R") ne "!") {
				head_left("needle");
				head_left("table");
				head_left("R");
				head_right("S");
				while(head_read("table") eq "-") {
					head_left("table");
					head_left("S");
				}
			}
			tape_swap("R", "S");
		}
		if (head_read("needle") eq "!") {
			head_right("needle");
			head_right("table");
		}
		if (head_read("needle") eq head_read("haystack")) {
			head_right("needle");
			head_right("table");
			while (head_read("table") eq "-") {
				head_right("table");
				head_right("R");
			}
		}
		if (head_read("needle") eq "#") {
			$r = 1;
			last;
		}
		head_right("haystack");
	}
	head_kill("needle");
	head_kill("haystack");
	head_kill("table");
	head_kill("R");
	head_kill("S");
	return $r;
}

sub strstr {
	my ($needle, $haystack) = @_;
	$tracks{R} = "!";
	$tracks{S} = "!";
	$tracks{table} = "!";
	$tracks{needle} = "!$needle#";
	generate_table();
	$tracks{haystack} = "!$haystack#";
	return check_string();
}
