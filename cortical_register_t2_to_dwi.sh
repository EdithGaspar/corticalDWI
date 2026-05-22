#!/bin/bash

sID=$1

if [ ! -d ${SUBJECTS_DIR}/${sID} ]
then
  echolor red "[ERROR] Cannot find directory ${SUBJECTS_DIR}/${sID}"
  echolor red "        Check your SUBJECTS_DIR and sID"
  exit 2
fi


fcheck=${SUBJECTS_DIR}/${sID}/dwi/t2native_to_b0_1Warp.nii.gz
if [ -f $fcheck ]
then
  echolor orange "[INFO] File found $fcheck"
  echolor orange "       Will not overwrite. Exitting now."
  exit 0
fi


## Intermodal registration
t2=${SUBJECTS_DIR}/${sID}/dwi/${sID}_flair.nii.gz
b0=${SUBJECTS_DIR}/${sID}/dwi/b0.nii.gz



isOK=1
for f in $t2 $b0
do
  if [ -f "$f" ]
  then
    echo "."
  else
    echolor red "[ERROR] File not found: $f"
    isOK=0
  fi
done
if [ $isOK -eq 0 ]; then exit 2; fi



inb_synthreg.sh \
  -fixed $b0 \
  -moving $t2 \
  -outbase ${SUBJECTS_DIR}/${sID}/dwi/t2native_to_b0_ \
  -threads_max