#!/bin/sh

# file names
orgCoordsFile=../b264_bp_robust_scrapped.txt
specFile=/home/foranw/afni/suma_demo/suma_mni/N27_both.spec
doFile="all_coor.spheres.1D.niml.do"



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
    sed 's/,/ /g' $orgCoordsFile |
    while read x y z nr reg robust scrap; do
      color=$(perl -slane "print if \$.==int(${!pipeline}*19/14)" colors/rgbScale.txt)
      #echo $pipeline ${!pipeline} $color
     
      cat >> vis/$pipeline.$doFile  << EOF
      <S
      coord = '$x $y $z'
      coord_type = 'fixed'
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
   #sleep 10
done
