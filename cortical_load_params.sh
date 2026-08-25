#!/bin/bash
# cortical_load_params.sh
# Source this file (do not execute) to load corticalDWI pipeline parameters.
#
# Loading priority (later sources override earlier ones):
#   1. Repo defaults  — corticalDWI_params.conf next to this file
#                       (found via BASH_SOURCE[0] or $CORTICAL_DWI_DIR)
#   2. Study overrides — $SUBJECTS_DIR/corticalDWI_params.conf
#
# CLI arguments passed to the calling script always take final priority
# (handled in each script individually, after sourcing this file).
#
# Required env variables:
#   CORTICAL_DWI_DIR  — path to the corticalDWI scripts directory
#                       Set this alongside SUBJECTS_DIR in your environment or
#                       pipeline entry-point script (cortical_singlesubject_fullprocess.sh).

# ── Locate repo conf ──────────────────────────────────────────────────────────
# BASH_SOURCE[0] is this file's path when sourced with a full/relative path.
# Fall back to CORTICAL_DWI_DIR when sourced by basename via PATH.
_clp_dir=""
if [[ "${BASH_SOURCE[0]}" == */* ]]; then
    _clp_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
elif [[ -n "$CORTICAL_DWI_DIR" ]]; then
    _clp_dir=$CORTICAL_DWI_DIR
fi

if [[ -n "$_clp_dir" && -f "${_clp_dir}/corticalDWI_params.conf" ]]; then
    # shellcheck source=corticalDWI_params.conf
    source "${_clp_dir}/corticalDWI_params.conf"
fi
unset _clp_dir

# ── Study-level overrides ─────────────────────────────────────────────────────
if [[ -n "$SUBJECTS_DIR" && -f "${SUBJECTS_DIR}/corticalDWI_params.conf" ]]; then
    echo " [INFO] Loading study-specific parameters: ${SUBJECTS_DIR}/corticalDWI_params.conf"
    source "${SUBJECTS_DIR}/corticalDWI_params.conf"
fi

# ── ITK/ANTs header tolerance ─────────────────────────────────────────────────
# ITK's NIfTI writer round-trips the direction-cosine matrix through a quaternion
# on every write, perturbing it by ~1e-6 even when no resampling occurred. This
# routinely trips ITK's default "same physical space" check (also ~1e-6) between
# files that passed through different writers (ANTs/ITK vs MRtrix vs FSL), e.g.
# "Inputs do not occupy the same physical space" from N4BiasFieldCorrection or
# DenoiseImage. Loosen the tolerance globally instead of re-syncing headers
# after every ANTs call.
export ITK_GLOBAL_DEFAULT_COORDINATE_TOLERANCE=1e-4
export ITK_GLOBAL_DEFAULT_DIRECTION_TOLERANCE=1e-4
