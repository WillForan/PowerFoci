#!/usr/bin/env perl

use strict;
use warnings;
#use Getopt::Std;
#use v5.14;

######
# 
#  o make hash from node_coord file   { roi# -> node }
#
#  o write line segments node -> node if roi# mapping exists
#  o colorize based on deltaR
#
#####

# all ROIs
#

my %roiNode;
my %roiXYZ;
open my $nodeCoor, '../b264_bp_robust_scrapped.txt' or die "cannot open node_coord.1D: $!\n";
while(<$nodeCoor>){
 my ($x,$y,$z,$roiNum) = (split /,/)[0..2,3];
 $roiXYZ{$roiNum}="$x $y $z";
}
close $nodeCoor;

# read in colors
#
my @color=();
open my $colorFile, 'colors/rgbWhiteRed.spec' or die "cannot open 'rgbWhiteRed.spec': $!\n";
while (<$colorFile>) {

 next unless m/#(.{2})(.{2})(.{2})/;
 
 # make 0-1 rgb
 push @color, [map {(hex $_)/256} ($1,$2,$3) ];
}
close $colorFile;


# what are the changes in corrilation?
#

for my $RRdRfile (glob('../matlab/txt/*txt')){

   my ($max,$min) = (0,100);
   #my (%min, %max);
   #(@max{'-','+'},@min{'-','+'}) = (0,0,0,0);
   
   # what do we call our do file
   my $name = (split /\//, $RRdRfile)[-1];
   $name =~ s/txt$/1D.do/;

   open my $output, ">vis/$name" or die "cannot open '>vis/$name': $!\n";
   print $output "#oriented_segments\n";
   my @deltRs = ();
   open my $RRdR, $RRdRfile or die "cannot open $RRdRfile: $!\n";
   while (<$RRdR>) {
    chomp;
    my ($r1,$r2, $dr) = split;
    # what is the node for the roi
    #my $n1 = $roiNode{$r1};
    #my $n2 = $roiNode{$r2};
    my $n1 = $roiXYZ{$r1};
    my $n2 = $roiXYZ{$r2};

    # are the nodes visible?
     print STDERR "$r1: not in rois/node_coord.1D\n" if !$n1;
     print STDERR "$r2: not in rois/node_coord.1D\n" if !$n2;
     next if (!$n1 or !$n2);

    # store corrilation
    push @deltRs, [$n1,$n2,$dr];

    #get min and max for colors
    #my $sign = $dr>0?'+':'-';
    #$max{$sign}=$dr if $dr > $max{$sign};
    #$min{$sign}=$dr if $dr < $min{$sign};
    $dr = $dr;
    $max = $dr if $dr > $max; 
    $min = $dr if $dr < $min; 
   }


   # set step  
   my $colorstep = ($max-$min)/$#color;

   #draw the line
   for my $cor (@deltRs) {
    my $coloridx = int((abs($cor->[2])-$min)/$colorstep);
    $coloridx-- if $coloridx > $#color;
    my @rgb = @{$color[ $coloridx  ]};
    print $output join(" ",@{$cor}[0,1], @rgb, 1),"\n";
   }
   close $output;
   print "DriveSuma -echo_edu -com viewer_cont -load_do vis/$name\n";
}