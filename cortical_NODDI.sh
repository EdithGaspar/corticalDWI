source `which my_do_cmd`


sID=$1;      # subject ID in the form of sub-74277

help() {
  echo "
  Usage: $(basename $0) <subjID>

  <subjID>         subject ID in the form of sub-74277

  This script will compute NODDI metrics using AMICO.

  "
}


if [ $# -lt 1 ]
then
  echolor red "[ERROR] Not enough arguments"
  help
  exit 0
fi


if [ ! -d ${SUBJECTS_DIR}/${sID} ]
then
  echolor red "[ERROR] Cannot find directory ${SUBJECTS_DIR}/${sID}"
  echolor red "        Check your SUBJECTS_DIR and sID"
  exit 2
fi


fcheck=${SUBJECTS_DIR}/${sID}/dwi/noddi/ODI.nii.gz
if [ -f $fcheck ]
then
  echolor green "[INFO] Found existing NODDI results, will not overwrite: $fcheck"
  exit 2
fi

dwi=${SUBJECTS_DIR}/${sID}/dwi/dwi.nii.gz
bvec=${SUBJECTS_DIR}/${sID}/dwi/dwi.bvec
bval=${SUBJECTS_DIR}/${sID}/dwi/dwi.bval
scheme=${SUBJECTS_DIR}/${sID}/dwi/dwi.scheme
mask=${SUBJECTS_DIR}/${sID}/dwi/mask.nii.gz

isOK=1
for f in $dwi $mask $scheme
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


outdir=${SUBJECTS_DIR}/${sID}/dwi/noddi
mkdir -pv $outdir
cd $outdir || exit 2

python3 << EOF
import amico

dwi    = '$dwi'
scheme = '$scheme'
bval   = '$bval'
bvec   = '$bvec'
mask   = '$mask'
b0_thr = 50

amico.core.setup()
ae = amico.Evaluation('.', '$sID', output_path='results')
ae.load_data(dwi_filename=dwi, scheme_filename=scheme,
             mask_filename=mask, b0_thr=b0_thr)
ae.set_model('NODDI')
ae.generate_kernels()
ae.load_kernels()
ae.fit()
ae.save_results()
EOF

# AMICO writes results into a dedicated "results" subdir (so its wipe-before-write
# cleanup never collides with the "kernels" subdir) and hardcodes a "fit_" prefix
# on filenames; flatten and strip the prefix here.
for f in ${outdir}/results/fit_*.nii.gz
do
  my_do_cmd mv "$f" "${outdir}/$(basename "$f" | sed 's/^fit_//')"
done
my_do_cmd mv "${outdir}/results/config.pickle" "${outdir}/config.pickle"
rmdir "${outdir}/results"