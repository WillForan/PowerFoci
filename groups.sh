# for each bpreg type
for type in {4,5,6}; do
   case $type in
   4)
    echo ===bpreg======
    ;;
   5)
    echo ===robust=====
    ;;
   6)
    echo ===scrapped===
    ;;
   esac

   # print list of roinums for each class
   #   make a hash (%h) with "class/cluster" ($F[4,5, or 6]) key
   #   push roi number ($F[3]) onto hash based on the class
   perl -F, -slane 'push @{$h{$F['$type']}}, $F[3]; END { print "$_\t@{$h{$_}}" for sort {$a<=>$b} keys %h}' b264_bp_robust_scrapped.txt 
done
