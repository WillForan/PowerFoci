#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Std;
#use v5.14;
#max and min

my %opts=(n=>'../matrix/bb264_bp_robust_scrapped.txt', # node file
          #r=>'../matrix/top30Low.adjlist', # relationship (adjlist) file matching glob
          t=>'300',                        # top ### of connections to consider
          p=>'vis/compare',                # output prefix
          m=>'0',                          # min distance
          M=>'200');                       # max distance

getopts('n:r:t:T:p:m:M:s:S:c:C:hd',\%opts);
######
# 
#  o make hash from node_coord file   { roi# -> node }
#
#  o write line segments node -> node if roi# mapping exists
#  o colorize based on deltaR
# 
#####
if ( exists $opts{T} && $opts{T} >1 ) { print "-T percent should be <= 1\n"; exit }
if ( $opts{t} < 1 ) { print "-t > 1 and an int\n"; exit }

if (exists $opts{h} || !exists $opts{r}) {
 print <<HERE;
$0 
   -r relationship (adj list or matrix)
   -t how many segmants to show (top) ($opts{t})
   -T percent segments to keep (precedence over -t)
   -p output prefix ($opts{p})
   -m min dist of connection  ($opts{m})
   -M max dist of connection  ($opts{M})
   -n ROI (nodes) e.g ../matrix/bb244_coordinate  ($opts{n})
   -s spectrum min corr (default unset)
   -S spectrum max corr (default unset)
   -c corr min          (default unset)
   -C corr max          (default unset)
   -d display  write to temp file [.tmp* must already exist]
               and do suma thing
   -h help

ROI node file delm. by [,\\s]+
determines matrix or adj by first line being more than 3 columns
m <= dist <= max

bb2*4 must match matrix dimensions. 
There is no check to make sure this is the case
It should be okay to always use bb264 for adj list format. 

HERE

   exit;
}

#collect stats
use Statistics::Descriptive;
my $stat = Statistics::Descriptive::Full->new();

# all ROIs
#

my %roiNode;
my %roiXYZ;
my $OutOfRange=0;
my $isAdj=0;

# euclid dist function
# also checks corr range if given
sub getDist {
 my ($n1,$n2,$dr) = @_;
 ## get euclidean dist between cors (stored as space delm. in n{1,2})
 my @xyz; my $edist=0;
 # get cords
 push @xyz, [split /\s/,$_ ] for ($n1,$n2);
 # sum dist of pairwise addition
 $edist += $_ for map { ($xyz[0][$_] - $xyz[1][$_] )**2 } 0..2; 
 # sqrt
 $edist = $edist**.5;

 $stat->add_data($edist); 
 #  min <= dist <= max 
 unless( $opts{m} <= $edist && $edist <= $opts{M}) {  $OutOfRange++;  return}

 # min <= corr <= max
 if( exists $opts{c} && $dr <= $opts{c}) {  $OutOfRange++;  return}
 if( exists $opts{C} && $dr >= $opts{C}) {  $OutOfRange++;  return}

 return $edist;


}

# determine matrix or adj list
# set isAdj to true if less than 4 feilds
open my $RRdR, $opts{r} or die "cannot open $opts{r}: $!\n";
$_=<$RRdR>;
$isAdj = 1 if scalar(split/\s/)<4;
print STDERR "Adj? $isAdj\n";
close $RRdR;

# find node coordinates
# use line number for ROI if input is  matrix
# use 4th column          if           adj list
open my $nodeCoor, $opts{n} or die "cannot open coord file $opts{n}: $!\n";
while(<$nodeCoor>){
 my ($x,$y,$z) = (split /[,\s]+/)[0..2];
 # if this is a matrix use the line number as the ROI number
 my $idx=$.;
 # if this is an adj matrix, need the actual ROI number (should be next in coord file)
 $idx=(split /[,\s]+/)[3] if $isAdj; 
 # add to hash
 $roiXYZ{$idx}="$x $y $z";
}
close $nodeCoor;

# read in colors
#   two spectrums. one for positive, one for negative
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


# what are the changes in correlation?
#
my ($max,$min) = (0,100);

# set up output file
# if we want percent, put that in filename - otherwise use num top
my $fnt=(exists $opts{"T"})?"$opts{T}p":"$opts{t}";
my $filename="$opts{p}-T${fnt}Dm$opts{m}M$opts{M}";
# add any other defined options
for (qw/c C s S/){ $filename.="$_$opts{$_}" if exists $opts{$_} }
# add file extension
$filename.=".dset.do";

open my $output, ">$filename" or die "cannot open '>$filename..': $!\n";
print $output "#segments\n";

my @deltRs = ();

# read in file
open $RRdR, $opts{r} or die "cannot open $opts{r}: $!\n";
##### READ MATRIX
sub readMatrix {
   while (<$RRdR>) {
    next if $.<2; # no information in first line that's not elsewhere
    chomp;
    my @row= split;
    my $n1=$roiXYZ{$.};
    #exists
    if(!$n1) { print STDERR "$.: not in roi range skipping row\n"; next}

    for (0..$.-2) {
     my $r2=$_+1; # roi's are one based
     my $dr=$row[$_];
     my $n2=$roiXYZ{$r2};
     # have node?
     if(!$n2) { print STDERR "$r2: not in roi range, skipping column\n"; next}
      


     ## store corrilation
     # maybe something bad happens if distance == 0, shouldn't happend anyway
     my $edist = getDist($n1,$n2,$dr);
     push @deltRs, [$n1,$n2,$dr,$edist] if $edist;

    }
   }
}
##### READ adjlist
sub readAdjList {
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
    my $edist=getDist($n1,$n2,$dr);
    push @deltRs, [$n1,$n2,$dr,$edist] if $edist;
   }
}

if ($isAdj) { readAdjList }
else        { readMatrix  }

#### Stats #####
print "$OutOfRange out of range\n";

print join ("\t", qw/set count max min mean std_dev variance/),"\n";
print join ("\t", "all", $stat->count, map {sprintf "%.3f",$_} 
                      ($stat->max, $stat->min, $stat->mean, 
                       $stat->standard_deviation, $stat->variance)),"\n";
#start again for only what is cept
$stat = Statistics::Descriptive::Full->new();
$stat->add_data(map {$_->[3]} @deltRs); 

print join ("\t", "$opts{m}-$opts{M}", $stat->count, map {sprintf "%.3f",$_} 
                      ($stat->max, $stat->min, $stat->mean, 
                       $stat->standard_deviation, $stat->variance)),"\n";




###############
# only take top of the top
# set listmax to the number of comparisons if less than what is specified as -t on cli
# or use percent, percent takes precedence
$opts{t} = int($opts{T}*$#deltRs) if exists $opts{T};
my $listmax=$#deltRs<$opts{t}?$#deltRs:$opts{t}-1;

my @topDelts = sort { abs($b->[2])<=>abs($a->[2]) } @deltRs[0..$listmax];

## get new max and min for color spectrum calculation
$min = 100; $max = 0;
for(map {$_->[2]} @topDelts){
   my $dr=abs($_);
   $max = $dr if $dr > $max;
   $min = $dr if $dr < $min;
}

# undo all that work if we have spectrum max/mins
$max = $opts{S} if exists $opts{S};
$min = $opts{s} if exists $opts{s};

print "Top $opts{t} Rmin Rmax $min $max\n";
################

# set step  
my $colorstep = ($max-$min)/$numColors;

#draw the line
for my $cor (@topDelts) {
 # red is positive, blue is negative
 my $sign='Red';
 $sign='Blue' if $cor->[2] < 0;

 ## set color
 # delta-min/steps ==> where in spectrum value is
 my $coloridx = int((abs($cor->[2])-$min)/$colorstep);
 # sometimes we go over
 $coloridx=$numColors if $coloridx > $numColors;
 # get rgb given a color idx
 my @rgb = @{@{$color{$sign}}[ $coloridx  ]};

 # print endpoints (both cords) color (r g b) and width
 print $output join(" ",@{$cor}[0,1], @rgb, .1),"\n";
}

close $output;
print "DriveSuma -echo_edu -com viewer_cont -load_do $filename\n";
my $cmd=<<CMDEND;
f=\$(ls -tc .tmp* 2>/dev/null|sed 1q); 
[ -n "\$f" ] && cp "$filename" "\$f" \\
 && DriveSuma -echo_edu -com viewer_cont -load_do "\$f"   
CMDEND

system("$cmd") if exists $opts{d};
