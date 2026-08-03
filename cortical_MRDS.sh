#!/bin/bash
source `which my_do_cmd`



print_help () {
  echo "
  `basename $0`  [options]  <sID>

  Options:

  -roi <roi>     : Binary mask (nii[.gz], but NOT mif format) to use for MRDS fitting.
                   If not provided, will use the mask in the dwi directory.
                   Remember that you can use cortical_select_streamlines_by_label.sh
                   to create a mask from a parcellation.
                   Caution: If the mask is too small and does not contain enough white matter voxels,
                   then the response function should be provided explicitly (not implemented yet).
  -help          : Print this help message and exit.
  "
}


if [ $# -lt 1 ]
then
  echolor red "Not enough arguments"
  print_help
  exit 0
fi

for arg in "$@"
do
  case "${arg}" in
    -h|-help)
        print_help
        exit 0
    ;;
    -roi)
      roi=$2
      if [ ! -f $roi ]
      then
        echolor red "[ERROR] Cannot find roi file: $roi"
        exit 2
      fi
      shift;shift
    ;;
    -h|help)
      print_help
      exit 0
    ;;
  esac
done


sID=$1;      # subject ID in the form of sub-74277
echolor green "[INFO] sID is $sID"

if [ ! -d ${SUBJECTS_DIR}/${sID} ]
then
  echolor red "[ERROR] Cannot find directory ${SUBJECTS_DIR}/${sID}"
  echolor red "        Check your SUBJECTS_DIR and sID"
  exit 2
fi


dwi=${SUBJECTS_DIR}/${sID}/dwi/dwi.nii.gz
bvec=${SUBJECTS_DIR}/${sID}/dwi/dwi.bvec
bval=${SUBJECTS_DIR}/${sID}/dwi/dwi.bval
scheme=${SUBJECTS_DIR}/${sID}/dwi/dwi.scheme
outdir=${SUBJECTS_DIR}/${sID}/dwi/mrds
outbase=${outdir}/${sID}

if [ ! -z "$roi" ]
then
  echolor green "[INFO] Using roi: $roi"
  mask=$roi
else
  mask=${SUBJECTS_DIR}/${sID}/dwi/mask.nii.gz
  echolor green "[INFO] No roi provided, using mask: $mask"
fi


isOK=1
for f in $dwi $scheme $mask
do
  if [ -f "$f" ]
  then
    echolor green "[INFO] Found $f"
  else
    echolor red "[ERROR] File not found: $f"
    isOK=0
  fi
done
if [ $isOK -eq 0 ]; then exit 2; fi



nVoxels=$(mrstats -ignorezero $mask -output count)
echolor green "[INFO] Will fit MRDS in $nVoxels voxels"



doComputeMRDS=1
fcheck=$(ls ${outbase}_MRDS_Diff_FTest_FA.ni*)
echolor green "[INFO] Looking for file: $fcheck"
if [ ! -z ${fcheck} ]
then
  echolor yellow "[INFO] File found $fcheck"
  echolor yellow "[INFO] Will not re-compute MRDS files. Delete previous output if you want to re-run."
  doComputeMRDS=0
fi



if [ $doComputeMRDS -eq 1 ]
then
  mkdir -pv $outdir
    my_do_cmd dti \
      -mask $mask \
      -response 0 \
      -correction 0 \
      -fa -md \
      $dwi \
      $scheme \
      ${outbase}
    nAnisoVoxels=`fslstats ${outbase}_DTInolin_ResponseAnisotropicMask.nii -V | awk '{print $1}'`
  if [ $nAnisoVoxels -lt 1 ]
  then
    echolor red "[ERROR] Not enough anisotropic voxels found for estimation of response. Found $nAnisoVoxels"
  fi
  echolor yellow "Getting lambdas for response (from $nAnisoVoxels voxels)"
  response=`cat ${outbase}_DTInolin_ResponseAnisotropic.txt | awk '{OFS = "," ;print $1,$2}'`

  
  cmd="mdtmrds \
  $dwi \
  $scheme \
  ${outbase} \
  -correction 0 \
  -response "$response" \
  -mask $mask \
  -modsel ftest \
  -fa -md -mse \
  -method diff \
  -lowb 2000 \
  -ntensors 3 \
  -iso \
  1"
  # save the command to a text file for reproducibility
  echo "$cmd" > ${outbase}_MRDS_cmd.txt
  my_do_cmd $cmd

else
  echolor yellow "[INFO] Will not run MRDS"
fi

gzip -v ${outbase}_DTInolin*.nii ${outbase}_MRDS_*.nii


doFixels=1
fcheck=${outdir}/mrds_fixels/index.mif
echolor green "[INFO] Looking for file: $fcheck"
if [ -f $fcheck ]
then
  echolor yellow "[INFO] File found $fcheck"
  echolor yellow "       Will not overwrite."
  doFixels=0
fi


for f in ${outbase}_MRDS_Diff_FTest_{PDDs_CARTESIAN,COMP_SIZE,FA,MD}.ni*
do
  if [ ! -f $f ]
  then
    echolor red "[ERROR] File not found: $f "
    doFixels=0
  fi 
done


if [ $doFixels -eq 1 ]
then
   mkdir -pv ${outdir}/mrds_fixels
   for v in FA MD COMP_SIZE
   do
   tmpDir=$(mktemp -u)
    my_do_cmd inb_mrds_scalePDDs.sh \
        -e 0.0000000000000001 \
        ${outbase}_MRDS_Diff_FTest_PDDs_CARTESIAN.nii.gz \
        ${outbase}_MRDS_Diff_FTest_${v}.nii.gz \
        ${outbase}_MRDS_Diff_FTest_PDDs_CARTESIAN_scaled-by-${v}.nii.gz

    my_do_cmd peaks2fixel \
        ${outbase}_MRDS_Diff_FTest_PDDs_CARTESIAN_scaled-by-${v}.nii.gz \
        $tmpDir
    cp -v ${tmpDir}/amplitudes.mif \
        ${outdir}/mrds_fixels/MRDS_Diff_FTest_${v}.mif
    cp -v ${tmpDir}/{directions,index}.mif ${outdir}/mrds_fixels/
    my_do_cmd rm -fR $tmpDir
    done
fi

echolor green "[INFO] Finished MRDS for $sID"