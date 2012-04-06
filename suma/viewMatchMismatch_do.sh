#!/usr/bin/env bash
idx=0
for D in {rois/within4.1D,rois/rejects.1D}; do
   let idx++
   perl -anle \
    'BEGIN{print "#spheres"; $,=" "} 
     print @F[2..4],1,1,0+'$idx'*.5,(.5)x3' \
     < $D \
     > $D.do
   DriveSuma -echo_edu -com viewer_cont -load_do $D.do
done
