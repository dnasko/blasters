#!/usr/bin/perl -w

# MANUAL FOR btab2clusters.pl

=pod

=head1 NAME

btab2clusters.pl -- perform nearest neighbor clustering on tabular BLAST results

=head1 SYNOPSIS

 btab2clusters.pl --btab=/Path/to/infile.btab --out=/Path/to/clusters.txt
                     [--help] [--manual]

=head1 DESCRIPTION

 Creates a UCLUST file of neartest neighbor clusters based on tabular BLAST
 results.
 
=head1 OPTIONS

=over 3

=item B<-b, --btab>=FILENAME

Input file in tabular BLAST format (outfmt 6). (Required) 

=item B<-o, --out>=FILENAME

Output file in UCLUST format. (Required) 

=item B<-h, --help>

Displays the usage message.  (Optional) 

=item B<-m, --manual>

Displays full manual.  (Optional) 

=back

=head1 DEPENDENCIES

Requires the following Perl libraries:

Statistics::R

Requires that R be installed and the `igraph` R package be installed as well.

=head1 AUTHOR

Written by Daniel Nasko, 
Center for Bioinformatics and Computational Biology, University of Delaware.

=head1 REPORTING BUGS

Report bugs to dan.nasko@gmail.com

=head1 COPYRIGHT

Copyright 2018 Daniel Nasko.  
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>.  
This is free software: you are free to change and redistribute it.  
There is NO WARRANTY, to the extent permitted by law.  

=cut


use strict;
use Getopt::Long;
use File::Basename;
use Pod::Usage;
use Statistics::R;

#ARGUMENTS WITH NO DEFAULT
my($btab,$outfile,$help,$manual);

GetOptions (	
				"b|btab=s"	=>	\$btab,
				"o|out=s"	=>	\$outfile,
				"h|help"	=>	\$help,
				"m|manual"	=>	\$manual);

# VALIDATE ARGS
pod2usage(-verbose => 2)  if ($manual);
pod2usage( {-exitval => 0, -verbose => 2, -output => \*STDERR} )  if ($help);
pod2usage( -msg  => "\n\n ERROR!  Required argument --btab not found.\n\n", -exitval => 2, -verbose => 1)  if (! $btab );
pod2usage( -msg  => "\n\n ERROR!  Required argument --outfile not found.\n\n", -exitval => 2, -verbose => 1)  if (! $outfile);

my %cluster;
my %id;
my $c=1;
my $tmp_file = "./tmp_network";
my %CLUSTERS;

open(OUT,">$tmp_file") || die "\n Cannot open the file: $tmp_file\n";
open(IN,"<$btab") || die "\n Cannot open the file: $btab\n";
while(<IN>) {
    chomp;
    my @a = split(/\t/, $_);
    unless (exists $cluster{$a[0]}) {
    	$cluster{$a[0]} = $c;
	$id{$c} = $a[0];
	$c++;
    }
    unless (exists $cluster{$a[1]}) {
    	$cluster{$a[1]} = $c;
	$id{$c}= $a[1];
    	$c++;
    }
    print OUT $cluster{$a[0]} . "\n" . $cluster{$a[1]} . "\n";
}        
close(IN);
close(OUT);

my $R = Statistics::R->new() ;
$R->startR ;
$R->send(qq`require(igraph)`);
$R->send(qq`data <- read.table("$tmp_file")`);
$R->send(qq`data <- data[,1]`);
$R->send(qq`data.g <- graph(data, directed=FALSE)`);
$R->send(qq`write(clusters(data.g)\$membership, file="./r_out")`);
$R->stopR() ;

$c=1;
open(IN,"<./r_out") || die "\n Error: Cannot open the file: ./r_out\n";
while(<IN>) {
    chomp;
    my @a = split(/ /, $_);
    foreach my $i (@a) {
	if (exists $id{$c}) {
	    # print $id{$c} . "\t" . $c . "\t" . $i . "\n";
	    push(@{$CLUSTERS{$i}}, $id{$c});
	}
	else {
	    die "\n Cannot find $c in hash ID\n";
	}
	$c++;
    }
}
close(IN);

foreach my $clstr (sort {$a<=> $b} keys %CLUSTERS) {
    print $clstr;
    foreach my $id ( @{$CLUSTERS{$clstr}} ) {
	print "\t" . $id;
    }
    print "\n";
}

print `rm $tmp_file`;
print `rm ./r_out`;

exit 0;


