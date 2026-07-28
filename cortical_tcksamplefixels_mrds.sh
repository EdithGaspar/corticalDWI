#!/bin/bash
source `which my_do_cmd`

# ── Defaults (lowest priority) ────────────────────────────────────────────────
target_type=ico6_sym
angle=45
nDepths=30

# ── Config file(s) ────────────────────────────────────────────────────────────
source cortical_load_params.sh 2>/dev/null || true

# The config's global 'fixel_dir' is used for CSD sampling at dwi/{fixel_dir}/...
# MRDS fixels live at dwi/mrds/{fixel_dir}/..., a different subtree, so it needs
# its own default rather than inheriting the CSD-oriented value from config.
fixel_dir=mrds_fixels

help() {
  echo "
  Usage: $(basename $0) <subjID> [fixel_dir] [angle] [nDepths] [target_type]

  <subjID>       subject ID in the form of sub-74277
  [fixel_dir]    directory containing fixel files, e.g., mrds_fixels (default: ${fixel_dir})
  [angle]        Maximum angle (in degrees) between the streamline and the fixel direction (default: ${angle})
  [nDepths]      number of depth points to keep in the txt file (default: ${nDepths})
                 This is in steps, not mm,
                 and has to be less than or equal to the number of depth points in the tsf file.
  [target_type]  target type (default: ${target_type})

  MRDS-derived metrics values are sampled, and separated into parallel and perpendicular components.
  Metrics sampled are FA, MD, and COMP_SIZE.
  Each metric has two components: par and perp to the streamline segment.
  Perpendicular can be defined in two ways:
  - The fixel with the lowest dot product to the streamline segment (FA-perp)
  - The average of all fixels except for the most parallel to the streamline segment (FA-perp-av)

  "
}

if [ $# -lt 1 ]
then
  echolor red "Wrong number of arguments (subjID is required)"
  help
  exit 0
fi

# ── CLI args (highest priority) ───────────────────────────────────────────────
subjID=$1
[ -n "$2" ] && fixel_dir=$2; # mrds_fixels (or something else, but it has to be mrds)
[ -n "$3" ] && angle=$3
[ -n "$4" ] && nDepths=$4; # number of depth points to keep in the txt file. The tsf saves them all.
[ -n "$5" ] && target_type=$5


isOK=1

fixel_dir=${SUBJECTS_DIR}/${subjID}/dwi/mrds/${fixel_dir}
if [ ! -d $fixel_dir ]
then
  echolor red "[ERROR] Fixel directory does not exist: $fixel_dir"
  isOK=0
  #exit 2
fi


for hemi in lh rh
do
  tck=${SUBJECTS_DIR}/${subjID}/dwi/${hemi}_${target_type}_laplace-wm-streamlines_dwispace.tck
  for v in FA MD COMP_SIZE
  do
      this_f=${fixel_dir}/MRDS_DIFF_FTest_${v}.mif
      for f in $tck $this_f
      do
      if [ ! -f $f ]
      then
          echolor red "[ERROR] Cannot find file: $f"
          isOK=0
      else
          echolor green "[INFO] Found file: $f"
      fi
      done


      fcheck=${fixel_dir}/${hemi}_${target_type}_${v}-par-perp-indices.tsf
      echo "looking for $fcheck"
      if [ -f $fcheck ]
      then
      echolor yellow "[WARN] File exists, will not overwrite: $fcheck"
      exit 0
      fi


      if [ $isOK -eq 1 ]
      then
      my_do_cmd tcksamplefixels \
      -angle $angle \
      $this_f \
      $tck \
      ${fixel_dir}/${hemi}_${target_type}_${v}-par-perp-indices.tsf \
      ${fixel_dir}/${hemi}_${target_type}_${v}-par.tsf \
      ${fixel_dir}/${hemi}_${target_type}_${v}-perp.tsf \
      ${fixel_dir}/${hemi}_${target_type}_${v}-perp-av.tsf
      else
      echolor red "[ERROR] Cannot continue, see above errors"
      exit 2
      fi
  done
done


cortical_tsf2txt_in_fixeldir.sh $fixel_dir $nDepths



