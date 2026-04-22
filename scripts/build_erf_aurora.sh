#!/bin/bash
set -euo pipefail

echo "===> Entering ERF repo"
cd "$(dirname "$0")"

echo "===> Loading Aurora ERF environment"
source Build/machines/aurora_erf.profile || true

echo "===> Loaded modules"
module list

echo "===> Checking compilers"
which mpicc
which mpicxx
which mpifort
which icpx

echo "===> Discovering package roots"
echo "NETCDF_C_ROOT=${NETCDF_C_ROOT:-}"
echo "NETCDF_FORTRAN_ROOT=${NETCDF_FORTRAN_ROOT:-}"
echo "HDF5_ROOT=${HDF5_ROOT:-}"

if [[ -z "${NETCDF_FORTRAN_ROOT:-}" ]]; then
  export NETCDF_FORTRAN_ROOT=$(module show netcdf-fortran 2>&1 | \
    sed -n 's/.*setenv("NETCDF_FORTRAN_ROOT","\([^"]*\)").*/\1/p')
fi

echo "===> Final package roots"
echo "NETCDF_C_ROOT=${NETCDF_C_ROOT:-}"
echo "NETCDF_FORTRAN_ROOT=${NETCDF_FORTRAN_ROOT:-}"
echo "HDF5_ROOT=${HDF5_ROOT:-}"

if [[ -z "${NETCDF_C_ROOT:-}" ]]; then
  echo "ERROR: NETCDF_C_ROOT is not set"
  exit 1
fi

if [[ -z "${NETCDF_FORTRAN_ROOT:-}" ]]; then
  echo "ERROR: NETCDF_FORTRAN_ROOT is not set"
  exit 1
fi

if [[ -z "${HDF5_ROOT:-}" ]]; then
  echo "ERROR: HDF5_ROOT is not set"
  exit 1
fi

echo "===> Verifying required files"
ls "${NETCDF_C_ROOT}/include/netcdf.h"
ls "${NETCDF_C_ROOT}"/lib64/libnetcdf*
ls "${NETCDF_FORTRAN_ROOT}/include/netcdf.mod"
ls "${NETCDF_FORTRAN_ROOT}"/lib*/libnetcdff*
ls "${HDF5_ROOT}"/lib/libhdf5* || ls "${HDF5_ROOT}"/lib64/libhdf5*

echo "===> Setting search paths"
export CPPFLAGS="-I${NETCDF_C_ROOT}/include -I${NETCDF_FORTRAN_ROOT}/include -I${HDF5_ROOT}/include"
export LDFLAGS="-L${NETCDF_C_ROOT}/lib64 -L${NETCDF_FORTRAN_ROOT}/lib64 -L${HDF5_ROOT}/lib"
export LD_LIBRARY_PATH="${NETCDF_C_ROOT}/lib64:${NETCDF_FORTRAN_ROOT}/lib64:${HDF5_ROOT}/lib:${LD_LIBRARY_PATH:-}"

echo "===> Syncing submodules"
git submodule update --init --recursive

echo "===> Cleaning old build/install directories"
rm -rf build_aurora install_aurora

echo "===> Configuring ERF"
cmake -S . -B build_aurora \
  -DCMAKE_INSTALL_PREFIX="$(pwd)/install_aurora" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_C_COMPILER=mpicc \
  -DCMAKE_CXX_COMPILER=mpicxx \
  -DCMAKE_Fortran_COMPILER=mpifort \
  -DCMAKE_PREFIX_PATH="${NETCDF_C_ROOT};${NETCDF_FORTRAN_ROOT};${HDF5_ROOT}" \
  -DCMAKE_CXX_FLAGS="-fsycl-max-parallel-link-jobs=8 --offload-compress -flink-huge-device-code" \
  -DERF_ENABLE_MPI=ON \
  -DERF_ENABLE_NETCDF=ON \
  -DERF_ENABLE_HDF5=ON \
  -DERF_ENABLE_NOAHMP=ON \
  -DERF_ENABLE_RRTMGP=ON \
  -DERF_ENABLE_SYCL=ON \
  -DAMReX_GPU_BACKEND=SYCL \
  -DAMReX_INTEL_ARCH=pvc \
  -DAMReX_SYCL_AOT=ON \
  -DAMReX_SYCL_SPLIT_KERNEL=NO \
  -DKokkos_ENABLE_SERIAL=ON \
  -DKokkos_ENABLE_SYCL=ON \
  -DKokkos_ENABLE_SYCL_RELOCATABLE_DEVICE_CODE=ON \
  -DKokkos_ARCH_INTEL_PVC=ON

echo "===> Building ERF"
cmake --build build_aurora -j 10

#echo "===> Installing ERF"
#cmake --install build_aurora

#echo "===> Done"
#echo "Installed under: $(pwd)/install_aurora"
