#!/usr/bin/env perl
use strict;
use warnings;

my %h;
open my $bb, 'b264_bp_robust_scrapped.txt' or die "cannot open file: $!\n";
while(<$bb>) {
   chomp;
   my ($roiNum,$def,$rob,$srp) = (split /,/)[3,4,5,6];

   push @{$h{def}->{$def}}, $roiNum; 
   push @{$h{rob}->{$rob}}, $roiNum; 
   push @{$h{srp}->{$srp}}, $roiNum; 
}

$,="\t";
my %cmp;

print "aType","a|Ci|","bType","b|Ci|","match", "%a","%b","\n";
for my $type (keys %h){
   for my $cmptype (keys %h){
     next if $cmptype eq $type;

     for my $clust (keys %{$h{$type}}) {
        for my $cmpclust (keys %{$h{$cmptype}}) {

          my %count;

          # the count of each item is stored in %count
          # if count is greater than 1, map puts true(1) into @counts
          my @counts = map {++$count{$_}>1} @{$h{$type}->{$clust}}, @{$h{$cmptype}->{$cmpclust}};

          # pull out all the ones
          @counts = grep {$_==1} @counts;

          # update best cluster
          my $match       = scalar(@counts);
          my $size          = scalar(@{$h{$type}->{$clust}});
          my $cmpsize       = scalar(@{$h{$cmptype}->{$cmpclust}});
          my $pcentIdentity = sprintf("%.3f",$match/$size);
          my $pcentIdBack   = sprintf("%.3f",$match/$cmpsize);

          if(! $cmp{"${type}->${cmptype}"}->{$clust} or $cmp{"${type}->${cmptype}"}->{$clust}->[4] < $pcentIdentity) {
             $cmp{"${type}->${cmptype}"}->{$clust}=[$cmpclust, $match, $size,$cmpsize,$pcentIdentity, $pcentIdBack];
          }


          print "${type}_$clust", 
                $size,
                "${cmptype}_$cmpclust",
                $cmpsize,
                $match,
                $pcentIdentity,
                $pcentIdBack,
                "\n" if @counts;


        }
     }

   }
}

print "aType->bType","aC","bC","match", "|aC|","|bC|","%a", "%b","\n";
for my $comp (keys %cmp){
 for my $clust (sort {$a<=>$b} keys %{$cmp{$comp}} ){
   
   print $comp,$clust, @{$cmp{$comp}->{$clust}},"\n";


 }
}
