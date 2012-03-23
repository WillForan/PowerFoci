#!/usr/bin/env bash
for type in {5,6,7}; do
   case $type in
      5) name=reg    ;;
      6) name=robust ;;
      7) name=scrap  ;;
   esac

   3dUndump  -xyz -srad 7 -overwrite                          \
             -prefix left_$name.nii.gz                        \
             -master mni_icbm152_t1_tal_nlin_asym_09c_2mm.nii \
             <(awk -F,  '($1<0){print $1,$2,$3,$'$type'}'     \
                        ../b264_bp_robust_scrapped.txt)
           
done
