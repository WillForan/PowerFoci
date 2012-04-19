# mod and run CommunitySimilarities.R
perl -F, -slane 'BEGIN{ %c=(1=>2,2=>1,4=>5,5=>4) } $F[5]=$c{$F[5]} if exists $c{$F[5]}; print join(",", @F)' bb244_communities_bpreg_simult.csv > bb244_communities_bpreg_simult-corrected.csv 

# make 1d.do file for suma/vis
awk -F, 'BEGIN{print "#spheres"} ($5 != $6){print $1,$2,$3,"   1 0 0 1   3"}' bb244_communities_bpreg_simult-corrected.csv > ../suma/vis/spheres.breg_simult_changed.1D.do
