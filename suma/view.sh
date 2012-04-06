specFile=suma_mni/N27_both.spec
nb=2000

function newSuma {
   let nb++
   file=$1
   xterm -e "cd $(pwd); suma -spec $specFile -niml -np $nb" &

   echo -e "\t\twaiting 15secs for suma to load"; sleep 15;

   echo -e "\t\tPutting all roi's up"; 
   DriveSuma -echo_edu        \
             -com viewer_cont \
             -np $nb          \
             -load_do vis/none.all_coor.spheres.1D.niml.do 


   echo -e "\t\tPutting connects"; 
   DriveSuma -echo_edu        \
             -com viewer_cont \
             -np $nb          \
             -load_do $file
}

echo "### blue (-) -> white (0) ->  red (+) "
   echo "###	delt r: bpregs vs simult (Normal)"; 
newSuma vis/roiRoiDeltR_bpregsNormalVSsimultNormal.1D.do

   echo "###	delt r: normal vs scrapped (bpreg)"; 
newSuma vis/roiRoiDeltR_bpregsNormalVSbpregsScrapped.1D.do
