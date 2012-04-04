#!/bin/sh

# file names
prefix=xyz
demoDir=/home/foranw/afni/suma_demo/afni/
orgCoordsFile=../b264_bp_robust_scrapped.txt
coordsFile=cords_clust.txt

oneD=$prefix.1D
specFile=$demoDir/../SurfData/SUMA/std.DemoSubj_rh.spec
doFile="spheres.1D.niml.do"

# get xyz of interesting points
# 125 neg, 2 zero, 137 pos
# use left hemisphere only grab neg x (127->89 survive)
# use right hemisphere only grab pos x  (139->94 survive)
[ -r $coordsFile ] || awk -F, '($1>=0){print $0}' $orgCoordsFile > $coordsFile
[ -r $oneD ] || awk -F, '($1>=0){print $1,$2,$3}' $coordsFile > $oneD

# find closests nodes
if [ ! -r $prefix.closest.1D.dset -o ! -r node_coord.1D ]; then
   SurfaceMetrics        \
     -closest_node $oneD \
     -prefix $prefix     \
     -spec $specFile
     #-sv $demoDir/DemoSubj_SurfVol_Alnd_Exp+tlrc          \

    echo -n "MEAN/STD: "
    awk '($2 ~ /[0-9]+$/){sum+=$2; sumsq+=$2*$2;count++} END {print sum/count, sqrt(sumsq/count - (sum/count)**2)}' $prefix.closest.1D.dset

    # combine first part of closest (node and dist) with coordinate file
    # to get node dist xyz num(1..264) regClust robostClust scrapClust
    sed -e 's/#.*//;/^$/d' $prefix.closest.1D.dset   | # remove comments
     cut -f1-2                                       | # grab node and dist 
     paste - ${coordsFile} | sed 'y/,/ /'            | # combined node dist with coord and clust
     cat > node_coord.1D                               # record
fi

# for each pipeline
# create a nilm file where nodes are colored based on their cluster
none=1 #color to use for none -- 1st in file
for pipeline in {none,reg,robust,scrap}; do
   # write niml header
   cat  > $pipeline.$doFile << EOF
   <nido_head
      default_color = '1.0 1.0 1.0 1'
      default_font = 'he18'
   />

EOF

   # create sphere for each node
   #   add sphere with color uniq to cluster (14 clusters, rgbScale has 19 colors)
   #   only look at xyz's that are close to their node (with 4)
    awk '{dist=$2<0?-$2:$2; if(dist<4) {print $0}}' node_coord.1D | # only take close nodes
    while read node dist x y z nr reg robust scrap; do
      color=$(perl -slane "print if \$.==int(${!pipeline}*19/14)" rgbScale.txt)
      #echo $pipeline ${!pipeline} $color
      cat >> $pipeline.$doFile  << EOF
      <S
      node = '$node'
      col = '$color'
      rad = '3'
      line_width = '1.5'
      style = 'fill'
      stacks = '20'
      slices = '20'
      />

EOF

   done

   # if no suma, launch suma
   if [ "$(ps aux | grep suma|grep -v grep) x" == " x" ]; then
    # launch suma
    xterm -e "suma -spec $specFile -niml" &
    #suma  -spec $demoDir/../SurfData/SUMA/std.DemoSubj_lh.spec \
    #      -niml 2>/dev/null 1>/dev/null &
    #      #-sv   $demoDir/DemoSubj_SurfVol_Alnd_Exp+orig        \
    
    sleep 15
   fi

   #load file
   #DriveSuma -echo_edu -com viewer_cont -load_do $pipeline.$doFile
done
