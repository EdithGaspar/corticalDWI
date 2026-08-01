#!/bin/bash
source `which my_do_cmd`

subjid=$1
fakeflag=$2


my_do_cmd $fakeflag rm ${SUBJECTS_DIR}/${subjid}/mri/laplace-*
my_do_cmd $fakeflag rm ${SUBJECTS_DIR}/${subjid}/mri/*_proc.nii.gz
my_do_cmd $fakeflag rm ${SUBJECTS_DIR}/${subjid}/mri/T1_over_FLAIR.nii.gz
my_do_cmd $fakeflag rm ${SUBJECTS_DIR}/${subjid}/mri/?h_*.tck
my_do_cmd $fakeflag rm ${SUBJECTS_DIR}/${subjid}/surf/*.gii

my_do_cmd $fakeflag find "${SUBJECTS_DIR}/${subjid}/dwi" -mindepth 1 -maxdepth 1 \
  ! -name 'dwi.nii.gz' \
  ! -name 'dwi.bvec' \
  ! -name 'dwi.bval' \
  ! -name 'dwi.scheme' \
  ! -name 'mask.nii.gz' \
  ! -name 'b0.nii.gz' \
  -exec rm -rf {} +