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
open my $nodeCoor, 'node_coord.1D' or die "cannot open node_coord.1D: $!\n";
while(<$nodeCoor>){
 my ($node, $roiNum) = (split)[0,5];
 $roiNode{$roiNum}=$node;
 #print join("\t",$node, $roiNum),"\n";
}
close $nodeCoor;



# which nodes are visible?
#

my %visibleNode;
open my $ROIspheres, 'reg.spheres.1D.niml.do' or die "cannot open 'reg.spheres.1D.niml.do': $!\n";
while(<$ROIspheres>){
 $visibleNode{$1}=1 if m/node = '(\d+)'/;
}
close $ROIspheres;

my ($max,$min) = (0,100);
#my (%min, %max);
#(@max{'-','+'},@min{'-','+'}) = (0,0,0,0);

# what are the changes in corrilation?
#

open my $output, ">VSRobust.1D.do" or die "cannot open '>VSRobust.1D.do': $!\n";
print $output "#node-based_oriented_segments";
my @deltRs = ();
open my $RRdR, '../matlab/roiRoiDeltR_regVSRobust.txt' or die "cannot open '../matlab/roiRoiDeltR_regVSRobust.txt': $!\n";
while (<$RRdR>) {
 chomp;
 my ($r1,$r2, $dr) = split;
 # what is the node for the roi
 my $n1 = $roiNode{$r1};
 my $n2 = $roiNode{$r2};

 # are the nodes visible?
 if( !$n1 or !$n2 or ! exists $visibleNode{$n1}  or ! exists $visibleNode{$n2} ){
  #print STDERR "either $r1 or $r2 does not have a visible node\n";
  next;
 }

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




# read in colors
#
my @color=();
open my $colorFile, 'rgbWhiteRed.spec' or die "cannot open 'rgbWhiteRed.spec': $!\n";
while (<$colorFile>) {
 next unless m/#(.{2})(.{2})(.{2})/;
 push @color, [map {(hex $_)/256} ($1,$2,$3) ];
 #push @color, [(hex $1)/256, (hex $2)/256, (hex $3)/256];
 push @rgbColor, "#$1$2$3";

}
close $colorFile;

# set step  
my $colorstep = ($max-$min)/$#color;

open my $colorspec, '>colorspec.html' or die "cannot open '>colorspec.html': $!\n";
 print $colorspec "<div style='display:block;padding:0;margin:0;background: #$1$2$3'>", $min+$colorspec*$., "</div>\n";
close $colorspec;



#draw the line
for my $cor (@deltRs) {
 my $coloridx = int((abs($cor->[2])-$min)/$colorstep);
 $coloridx-- if $coloridx > $#color;
 my @rgb = @{$color[ $coloridx  ]};
 print $output join(" ",@{$cor}[0,1], @rgb, 1),"\n";
}
close $output;

