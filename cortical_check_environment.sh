#!/bin/bash

status=1


# Freesurfer
if ! command -v mris_convert &> /dev/null; then
    echolor red "[ERROR] Freesurfer is not installed or not in your PATH. Please install Freesurfer and ensure it is in your PATH."
    echolor red "        Suggested version is 8.1"
    status=0
fi


if [ -z "$SUBJECTS_DIR" ]; then
  echolor red "[ERROR] SUBJECTS_DIR is not set. Please set it to the freesurfer subjects directory."
  status=0
fi

# MRtrix
if ! command -v mrconvert &> /dev/null; then
    echolor red "[ERROR] MRtrix is not installed or not in your PATH. Please install MRtrix and ensure it is in your PATH."
    echolor red "        Suggested version is 3.0"
    status=0
fi

# ANTs
if ! command -v ANTS &> /dev/null; then
    echolor red "[ERROR] ANTs is not installed or not in your PATH. Please install ANTs and ensure it is in your PATH."
    echolor red "        Suggested version is 2.4.4"
    status=0
fi


# custom MRtrix modules
if ! command -v tcksamplefixels &> /dev/null; then
    echolor red "[ERROR] custom MRtrix modules are not installed or not in your PATH. Please install them and ensure they are in your PATH."
    echolor red "        Grab the at https://github.com/lconcha/inb_mrtrix_modules"
    status=0
fi
if ! command -v tckresample_and_truncate &> /dev/null; then
    echolor red "[ERROR] custom MRtrix scripts are not installed or not in your PATH. Please install them and ensure they are in your PATH."
    echolor red "        Grab the at https://github.com/lconcha/inb_mrtrix_modules" 
    status=0
fi

# MRDS
if ! command -v mdtmrds &> /dev/null; then
    echolor red "[ERROR] MRDS binaries are not installed or not in your PATH. Please install them and ensure they are in your PATH."
    status=0
fi


# dipy
if ! command -v dipy_fit_dti &> /dev/null; then
    echolor red "[ERROR] dipy is not installed or not in your PATH. Please install dipy and ensure it is in your PATH."
    status=0
fi

# corticalDWI configuration
if [ ! -f "${SUBJECTS_DIR}/corticalDWI_params.conf" ]; then
    echolor red "[ERROR] corticalDWI configuration file not found: ${SUBJECTS_DIR}/corticalDWI_params.conf"
    echolor red "        Please create a configuration file named corticalDWI_params.conf in your SUBJECTS_DIR."
    status=0
fi



echo $status