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
my %color=();
my $numColors;
# for colors white to xxxx
for my $colorfile ('Blue','Red') {
   open my $colorFile, "colors/rgbWhite$colorfile.spec" or die "cannot open 'rgbWhite$colorfile.spec': $!\n";
   while (<$colorFile>) {
    next unless m/#(.{2})(.{2})(.{2})/;
    # push hex converted to rgb 0->1 => hash{blue|red}= ([1 1 0], [.5 .5 .5], ...)
    push @{$color{$colorfile}}, [map {(hex $_)/256} ($1,$2,$3) ];
   }
   close $colorFile;
   # numColors to use is min of colors in either file
   $numColors = $#{$color{$colorfile}} if (!$numColors || $numColors > $#{$color{$colorfile}});
}


# what are the changes in corrilation?
#

for my $RRdRfile (glob('../matlab/txt/*txt')){
#for my $RRdRfile (qw"vis/roiRoiDeltR_bpregsNormalVSsimultNormal.1D.do vis/roiRoiDeltR_bpregsNormalVSbpregsRobust.1D.do"){



   my ($max,$min) = (0,100);
   #my (%min, %max);
   #(@max{'-','+'},@min{'-','+'}) = (0,0,0,0);
   
   # what do we call our do file
   my $name = (split /\//, $RRdRfile)[-1];
   $name =~ s/txt$/1D.do/;

   open my $output, ">vis/$name" or die "cannot open '>vis/$name': $!\n";
   print $output "#segments\n";
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
    $dr = abs($dr);
    $max = $dr if $dr > $max; 
    $min = $dr if $dr < $min; 
   }




   ###############
   # only take top of the top
   my @topDelts = sort {abs($b->[2]) <=> abs($a->[2])} @deltRs[0..299];
   # get new max and min
   $min = 100;
   $max = 0;
   for(map {$_->[2]} @topDelts){
      my $dr=abs($_);
      $max = $dr if $dr > $max;
      $min = $dr if $dr < $min;
   }
   print "$name\t$min $max\n";
   ################

   # set step  
   my $colorstep = ($max-$min)/$numColors;

   #draw the line
   for my $cor (@topDelts) {
    # red is positive, blue is negative
    my $sign='Red';
    $sign='Blue' if $cor->[2] < 0;

    my $coloridx = int((abs($cor->[2])-$min)/$colorstep);
    $coloridx=$numColors if $coloridx > $numColors;
    my @rgb = @{@{$color{$sign}}[ $coloridx  ]};
    print $output join(" ",@{$cor}[0,1], @rgb, 1),"\n";
   }
   close $output;
   print "DriveSuma -echo_edu -com viewer_cont -load_do vis/$name\n";
}
