#!/bin/sh

# file names
prefix=xyz
oneD=$prefix.1D
demoDir=/home/foranw/afni/suma_demo/afni/
doFile="spheres.1D.niml.do"

# get xyz of interesting points
[ -r $oneD ] || awk -F, '{print $1,$2,$3}' ../b264_bp_robust_scrapped.txt > $oneD

# find closests nodes
if [ ! -r $prefix.closest.1D.dset ]; then
   SurfaceMetrics                                         \
     -closest_node $oneD                                  \
     -prefix $prefix                                      \
     -sv $demoDir/DemoSubj_SurfVol_Alnd_Exp+tlrc          \
     -spec $demoDir/../SurfData/SUMA/std.DemoSubj_lh.spec 

    echo -n "MEAN/STD: "
    awk '($2 ~ /[0-9]+$/){sum+=$2; sumsq+=$2*$2;count++} END {print sum/count, sqrt(sumsq/count - (sum/count)**2)}' $prefix.closest.1D.dset
fi

cat  > $doFile << EOF
<nido_head
   default_color = '1.0 1.0 1.0 1'
   default_font = 'he18'
/>

EOF

sed 's/#.*//;/^$/d' $prefix.closest.1D.dset |cut -f1 | while read node; do
   cat >> $doFile  << EOF
   <S
   node = '$node'
   col = '0.9 0.1 0.61'
   rad = '4'
   line_width = '1.5'
   style = 'fill'
   stacks = '20'
   slices = '20'
   />

EOF

done
