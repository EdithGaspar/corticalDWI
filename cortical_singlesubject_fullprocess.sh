#!/bin/bash

# Make sure that the following environment variables are set:
# module load freesurfer/8.1 mrtrix/3.0.4 workbench_con/2.0.1 ANTs/2.4.4 mrds/1.2.0
# SUBJECTS_DIR: path to the freesurfer subjects directory
#  path_add /misc/lauterbur2/lconcha/code/corticalDWI/
#  path_add /misc/lauterbur2/lconcha/code/inb_mrtrix_modules/bin
#  path_add /misc/lauterbur2/lconcha/code/inb_mrtrix_modules/scripts
#
# Make sure you have a configuration file named $SUBJECTS_DIR/corticalDWI_params.conf

source `which my_do_cmd`



status=$(cortical_check_environment.sh)

if [ $status -eq 0 ]; then
  echolor red "[ERROR] Environment check failed. Please fix the issues above and try again."
  exit 2
fi

if [ $# -lt 1 ]; then
  echolor red "[ERROR] Not enough arguments"
  echolor red "Usage: $(basename $0) <subjID>"
  exit 2
fi

subjid=$1
if [ ! -d ${SUBJECTS_DIR}/${subjid} ]; then
  echolor red "[ERROR] Subject $subjid does not exist: ${SUBJECTS_DIR}/${subjid}"
  exit 2
fi



echolor green "[INFO] Environment check passed. Start processing..."
echolor green "[INFO] SUBJECTS_DIR is set to: $SUBJECTS_DIR"
echolor green "[INFO] Using configuration file: $SUBJECTS_DIR/corticalDWI_params.conf"
echolor green "[INFO] Will process the following subject: $subjid"


date
hostname
# --- Begin --------------------------------------
# Prepare streamlines
my_do_cmd cortical_compute_laplacian.sh $subjid
my_do_cmd cortical_resample_surface_ico6_sym.sh $subjid
my_do_cmd cortical_compute_streamlines.sh $subjid
my_do_cmd cortical_register_t1_to_dwi.sh $subjid
my_do_cmd cortical_warp_tck_to_dwi.sh $subjid

# DTI
my_do_cmd cortical_DTI.sh $subjid
my_do_cmd cortical_tcksample_dti.sh $subjid

# CSD
my_do_cmd cortical_CSD_individual_response.sh $subjid
#cortical_CSD_average_response.sh; # this is a step that needs to run once all subjects had cortical_individual_response_CSD.sh run, to create the average response function
my_do_cmd cortical_CSD_compute_fod.sh $subjid
my_do_cmd cortical_tcksamplefixels_afd.sh $subjid

# MRDS
my_do_cmd cortical_MRDS.sh $subjid
my_do_cmd cortical_tcksamplefixels_mrds.sh $subjid

# DKI
my_do_cmd cortical_DKI.sh $subjid
my_do_cmd cortical_tcksample_dki.sh $subjid

# NODDI
my_do_cmd cortical_NODDI.sh $subjid
my_do_cmd cortical_tcksample_noddi.sh $subjid

# Structural imaging
my_do_cmd cortical_proc_t1.sh $subjid
my_do_cmd cortical_proc_FLAIR.sh $subjid
my_do_cmd cortical_tcksample_mri.sh $subjid

# --- END --------------------------------------
date

