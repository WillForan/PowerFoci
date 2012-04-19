#!/bin/sh

# file names
orgCoordsFile=../b264_bp_robust_scrapped.txt
coordsFile=rois/cords_clust.txt

prefix=rois/xyz
oneD=$prefix.1D
specFile=/home/foranw/afni/suma_demo/suma_mni/N27_rh.spec
doFile="spheres.1D.niml.do"

# get xyz of interesting points
# 125 neg, 2 zero, 137 pos
# use left hemisphere only grab neg x (127->89 survive)
# use right hemisphere only grab pos x  (139->94 survive)
[ -r $coordsFile ] || awk -F, '($1>=0){print $0}' $orgCoordsFile > $coordsFile

echo -n "points on this hemisphere: "; wc -l $coordsFile 
#
# should be LPI -> RAI -1*$1, -1*$2, $3  -- but then no nodes match
[ -r $oneD ] || awk -F, '{print $1,$2,$3}' $coordsFile > $oneD


# find closests nodes
if [ ! -r $prefix.closest.1D.dset -o ! -r node_coord.1D ]; then
   SurfaceMetrics        \
     -overwrite          \
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
     cat > rois/node_coord.1D                          # record
     

    awk '{dist=$2<0?-$2:$2; if(dist<4) {print $0 > "rois/within4.1D"} else {print $0 > "rois/rejects.1D"}}' rois/node_coord.1D
fi

echo -en "points within 4 of surface:   "; wc -l rois/within4.1D
echo -en "points more than 4 from node: "; wc -l rois/rejects.1D

# for each pipeline
# create a nilm file where nodes are colored based on their cluster
none=1 #color to use for none -- 1st in file
for pipeline in {none,reg,robust,scrap}; do
   # write niml header
   cat  > vis/$pipeline.$doFile << EOF
   <nido_head
      default_color = '1.0 1.0 1.0 1'
      default_font = 'he18'
   />

EOF

   # create sphere for each node
   #   add sphere with color uniq to cluster (14 clusters, rgbScale has 19 colors)
   #   only look at xyz's that are close to their node (with 4)
    cat rois/within4.1D |
    while read node dist x y z nr reg robust scrap; do
      color=$(perl -slane "print if \$.==int(${!pipeline}*19/14)" colors/rgbScale.txt)
      #echo $pipeline ${!pipeline} $color
      cat >> vis/$pipeline.$doFile  << EOF
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
   #if [ "$(ps aux | grep suma|grep -v grep) x" == " x" ]; then
   # # launch suma
   # xterm -e "suma -spec $specFile -niml" &
   # #suma  -spec $demoDir/../SurfData/SUMA/std.DemoSubj_lh.spec \
   # #      -niml 2>/dev/null 1>/dev/null &
   # #      #-sv   $demoDir/DemoSubj_SurfVol_Alnd_Exp+orig        \
   # 
   # sleep 15
   #fi

   #load file
   echo DriveSuma -echo_edu -com viewer_cont -load_do vis/$pipeline.$doFile
done

