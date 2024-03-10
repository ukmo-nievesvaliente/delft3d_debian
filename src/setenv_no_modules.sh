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
# As explained in https://community.intel.com/t5/Intel-C-Compiler/Build-failure-with-with-newer-2022-2-compiler-in-pipeline/m-p/1419482), 
# INTEL compilers are much stricter after version 2022.1 and some warnings are now treated as errors. Indeed, older compilations of Delft3D 
# (https://oss.deltares.nl/documents/portlet_file_entry/183920/log_v67888_compilation.txt/d71cf5ba-8515-6604-165c-983f79e29fad?download=true) 
# used to give warning for '-Wimplicit-function-declaration' and '-Wimplicit-int' while now we have errors. 
# In order to avoid this, the '-Wno-implicit-function-declaration', '-Wno-implicit-int' and '-Wno-c++11-narrowing' compilation keys have been 
# added in the configuration above.
export CXXFLAGS="-Wno-implicit-function-declaration -Wno-implicit-int -Wno-c++11-narrowing -diag-disable=10441"
export CFLAGS="-m64 -Wno-implicit-function-declaration -Wno-implicit-int -Wno-c++11-narrowing -diag-disable=10441"


echo "FC=$FC"
echo "CXX=$CXX"
echo "CC=$CC"
echo "CXXFLAGS=$CXXFLAGS"
echo "CFLAGS=$CFLAGS"
