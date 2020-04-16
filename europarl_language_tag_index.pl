#!/usr/bin/perl

# This script is used to build a large index file, containing all the language tags
# gathered in all the small daily text files of the europarl corpus.
# Execute it with:
# 
# perl europarl_language_tag_index.pl
#
# on the directory level, where you have your original europarl corpus files in a 
# directory structure like the following:
# en_fr/en
# en_fr/fr
# en_de/en
# en_de/de
# etc.
#
# The script first gathers all language tags (generating a file "index_all.txt") and
# then cleans this file up so that it has either a unique language tag for each speaker
# or, if the info in the europarl files was not consistent, it concatenates the diverging
# tags with a #. The clean file is called "europarl_language_index.txt".
#
# To generate the directional corpora afterwards copy this file into the directory(ies)
# where you want to build your direction, e.g. into "./en_fr" - on that level, too,
# then run the script "europarl_direct_ctags.pl"
#
# Acknowledgements:
# The scripting for generating this language tag index was mainly done by another
# COMTIS project member:
# 
# Bruno Cartoni, Bruno.Cartoni@unige.ch
#
# COMTIS, Thomas Meyer, 03.11.2010, Thomas.Meyer@idiap.ch

use strict;
use warnings;


# declare index hash
my %index;

my $subdirs = ".";
my $dailyfile;

while (defined($dailyfile = glob("*/*/*.txt"))) {
	open (DAILYFILE, "<$dailyfile") or die "cannot open $dailyfile: $!"; 
	
# get file name from directory names

my $dirfilename = "$subdirs/$dailyfile";
$dirfilename =~ /(.+)\/(.*)\.txt/; 	 # dirname/filename.txt
my $dirname = $1;
my $filename = $2;

	# go through the files
	
	while (<DAILYFILE>){
	   if ($_ =~ /^<SPEAKER\s+ID=([0-9]+)\s+LANGUAGE="([A-Z]+)"/) {
		my $speakerid = $1;
		my $language= $2;
		my $new_index = $filename."-SP".$speakerid;
		# feed the hash (even if the key (filename-SPXY) is already there, values (LANGUAGE tags) are added, #-separated
		$index{$new_index}.= "#".$language;
	   }
	}
}
		
close (DAILYFILE);

# (Re-)write the index file, with new fed hash info

open (INDEX, ">index_all.txt");
	while ((my $key, my $value) = each %index){
		print (INDEX $key."\t".$value."\n");
	}
close (INDEX);

# start cleaning index

open (INDEX_GEN, "<index_all.txt"); 		    # Index generated before
open (INDEX_CLEAN, ">europarl_language_index.txt"); # Clean index to be created now


# see old index file

while (<INDEX_GEN>) {
	$_ =~ /(.*)\t(.*)/; # index pattern filename<tab>LANGUAGE tag info
	my $key =$1;
	my $value=$2;

	# create a unique hash to process the values
	my @values = (split /#/, $value); # split after each #VW#XY LANGUAGE tag info
	my %seen;
	my @unique;
	
	foreach my $item (@values){
		push(@unique, $item) unless $seen{$item}++; 
	}
	shift @unique;

	if ($#unique == 0) { 	# if there is one unique value, print it as is with its key
		print (INDEX_CLEAN $key."\t@unique\n");
	}
	else {			# otherwise, print the alternating tags separated by "#"
		print (INDEX_CLEAN $key."\t".join("#",@unique)."\n");
	}
}
close (INDEX_GEN);
close (INDEX_CLEAN);
print "Cleaned index file 'europarl_language_index.txt' has been generated\n";