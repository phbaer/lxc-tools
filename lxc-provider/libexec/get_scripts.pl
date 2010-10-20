#!/usr/bin/perl -w

#get_scripts.sh
#This script parses directories corresponding to a query string (like debian/ubuntu/hardy) to produce an sorted list of scripts.
#Usage : get_scripts.sh path_to_script_home query/string

use strict;

use File::Basename;
use Data::Dumper;

my $debug=0;
$debug=1 if $ENV{lxc_DEBUG};

#Checks args
die "usage: $0 path_to_script_home query/string" if $#ARGV<1;
die "$ARGV[0] is not a dir" unless -d $ARGV[0];
my @query=split(/\//,$ARGV[1]);
die "$ARGV[1] doesn't seems to be a good query string because $ARGV[0]/$query[0] is not a dir" unless -d "$ARGV[0]/$query[0]";

my $result={};

foreach my $dir ( get_tree({root=>$ARGV[0], query=>\@query}) ) {
	debug("Loading scripts from $dir");
	load_scripts_from_dir($dir);
}
debug("Result data :\n".Dumper($result));

display();

sub get_tree {
	#This lists dirs by order of depth
	my ($arg) = @_;
	my @list;
	my $CurrentDir=$arg->{root};
	
	push @list,$CurrentDir;
	foreach my $step ( @{$arg->{query}} ) {
		$CurrentDir=$CurrentDir.'/'.$step;
		last unless -d $CurrentDir;
		push @list,$CurrentDir;
	}

	return @list;
}

sub load_scripts_from_dir {
	#This lists executables on a dir and call store() for each one
	my ($dir) = @_;
	debug("looking for scripts in $dir");
	opendir ( DIR, $dir ) || die "Error in opening dir $dir\n";
	foreach my $file (readdir(DIR)){
		if ( -f "$dir/$file" && -x "$dir/$file" ) { 
			debug("found $file in $dir");
			store($dir,$file);
		}
	}
	closedir(DIR);
}


sub store {
	#store full path and basename of scripts in 3 category pre, main, post
	#deepest one overwrites last found, even if extensions are different 
	#example : /toto/tata/myscript.pl will overwrite /toto/myscript.py

	my ($dir,$file) = @_;
	debug("store($dir,$file)");
	my @fileparts=split(/\./,$file);
	if ($#fileparts == 0) {
		debug("store() : found 1 part filename : $file");
		$result->{main}->{$fileparts[0]}="$dir/$file";
	} elsif ($#fileparts == 1) {
		debug("store() : found 2 part filename : $file");
		if ($fileparts[0] =~ /^(pre|post)/) {
			debug("store() : found 2 part filename with post or pre : $file");
			$result->{$fileparts[0]}->{$fileparts[1]}="$dir/$file";
		} else {
			debug("store() : found 2 part filename without post or pre : $file");
			$result->{main}->{$fileparts[0]}="$dir/$file";
		}
	} elsif ($#fileparts == 2) {
		debug("store() : found 3 part filename : $file");
		$result->{$fileparts[0]}->{$fileparts[1]}="$dir/$file";
	} else {
		die "$file as more than 3 parts, remember filename format : (pre.|post.)?filename(.ext)?";
	}
}

sub display {
	#Prints path of scripts in main category (sorted by basename)
	#pre prefixed are displayed just before there main equivalent
	#post are after
	foreach my $filename ( sort keys %{$result->{main}} ) {
		print $result->{pre}->{$filename}."\n" if $result->{pre}->{$filename};
		print $result->{main}->{$filename}."\n";
		print $result->{post}->{$filename}."\n" if $result->{post}->{$filename};
	}
}

sub debug {
	my ($msg) = @_;
	my $date=`date`;
	chomp $date;
	print STDERR "\e[0;34m$date : get_scripts.pl : debug : $msg\e[0m\n" if $debug && $ENV{'TERM'};
}

sub log {
	my ($msg) = @_;
	print STDERR "$msg\n";
}
