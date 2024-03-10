#!/bin/bash
###############################################
### load your build environment 	    ###
###############################################
echo "Load dependencies:"

# Intel MPI compiler:
myconfig=$config
. /opt/intel/oneapi/setvars.sh --force
export config=$myconfig
 
# Netcdf
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/opt/netcdf/c4.6.1-f4.5.0/lib/pkgconfig
export LD_LIBRARY_PATH=/opt/intel/oneapi/compiler/2023.2.3/linux/compiler/lib/intel64_lin:${LD_LIBRARY_PATH}

# PetSc
export PKG_CONFIG_PATH=$PKG_CONFIG_PATH:/opt/petsc/v3.20.5/lib/pkgconfig
  
# Metis:
export METIS_DIR=/opt/metis/v5.1.0

# PROJ
export PKG_CONFIG_PATH=/opt/proj/v7.1.0/lib/pkgconfig:$PKG_CONFIG_PATH

# GDAL
export PKG_CONFIG_PATH=/opt/gdal/v3.1.2/lib/pkgconfig:$PKG_CONFIG_PATH

echo "Export environment variables"
export FC=mpiifort
export CXX=mpiicpx
export CC=mpiicx
export MPICXX=mpiicpx 
export F77=mpiifort 
export MPIF77=mpiifort 
export FC=mpiifort 
export MPIFC=mpiifort 
export CXXFLAGS="-Wno-implicit-function-declaration -Wno-implicit-int -Wno-c++11-narrowing -diag-disable=10441"
export CFLAGS="-m64 -Wno-implicit-function-declaration -Wno-implicit-int -Wno-c++11-narrowing -diag-disable=10441"


echo "FC=$FC"
echo "CXX=$CXX"
echo "CC=$CC"
echo "CXXFLAGS=$CXXFLAGS"
echo "CFLAGS=$CFLAGS"
