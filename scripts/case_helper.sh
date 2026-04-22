#!/bin/bash
set -euo pipefail

# -----------------------------
# USER INPUTS
# -----------------------------
CASE_NAME=${1:-abl_test}
TEMPLATE=${2:-Exec/CanonicalTests/ABL}
INPUT_FILE=${3:-inputs_most}

BASE=/flare/gpu_hack/dfytanidis
ERF_DIR=$BASE/ERF
RUN_DIR=$BASE/runs/$CASE_NAME




EXE=$ERF_DIR/install_aurora/bin/erf_exec
ENV_SCRIPT=$ERF_DIR/Build/machines/aurora_erf.profile
# -----------------------------
# STEP 1: CREATE RUN DIRECTORY
# -----------------------------
echo "===> Creating run directory"
mkdir -p "$RUN_DIR"
cd "$RUN_DIR"

# -----------------------------
# STEP 2: COPY TEST CASE
# -----------------------------
echo "===> Copying template: $TEMPLATE"
cp -r "$ERF_DIR/$TEMPLATE"/* .

# -----------------------------
# STEP 3: CLEAN OLD OUTPUTS
# -----------------------------
echo "===> Cleaning old outputs"
rm -rf plt* chk* *.old || true

# -----------------------------
# STEP 4: RUN INTERACTIVELY
# -----------------------------
echo "===> Loading environment"
echo "===> Loading environment"

module load mpich/opt/4.2.3-intel
module load hdf5/1.14.6
module load netcdf-cxx4
module load netcdf-c
module load netcdf-fortran
module load cmake

export MPICH_CC=icx
export MPICH_CXX=icpx
export MPICH_FC=ifx
export MPICH_F90=ifx

export NETCDF_FORTRAN_ROOT=$(module show netcdf-fortran 2>&1 | sed -n 's/.*setenv("NETCDF_FORTRAN_ROOT","\([^"]*\)").*/\1/p')
export CPPFLAGS="-I${NETCDF_C_ROOT}/include -I${NETCDF_FORTRAN_ROOT}/include -I${HDF5_ROOT}/include"
export LDFLAGS="-L${NETCDF_C_ROOT}/lib64 -L${NETCDF_FORTRAN_ROOT}/lib64 -L${HDF5_ROOT}/lib"
export LD_LIBRARY_PATH="${NETCDF_C_ROOT}/lib64:${NETCDF_FORTRAN_ROOT}/lib64:${HDF5_ROOT}/lib:${LD_LIBRARY_PATH:-}"

echo "===> Running ERF"
echo "Case: $CASE_NAME"
echo "Executable: $EXE"
echo "Input: $INPUT_FILE"
echo "Directory: $(pwd)"

mpiexec -n 1 "$EXE" "$INPUT_FILE"

echo "===> Done"
