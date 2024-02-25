# How to install Delft3D in Debian 12
These notes describe how to install Delft3D on my workstation mounting Debian 12 - adapted from [here](https://gist.github.com/H0R5E/c4af6db788b227de702a12e01b64cf46).
## Pre-requisities
### 1) Dependencies from package manager
```
sudo apt -y update && sudo apt list --upgradable && sudo apt -y upgrade
sudo apt install -y build-essential m4 ruby wget subversion pkg-config
sudo apt install -y zlib1g zlib1g-dev curl libcurl4 libcurl4-openssl-dev
sudo apt install -y uuid uuid-dev expat libexpat1-dev autoconf libtool bison flex
```
### 2) Intel oneAPI
```
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
sudo apt update
#sudo apt install -y intel-hpckit-2022.2.0
sudo apt install -y intel-hpckit
```
### 3) Dependencies that needs to be compiled
```
mkdir -p ~/tmp
cd ~/tmp
```
#### HDF5-1.10.7 with parallel I/O support
```
mkdir -p ${HOME}/local/hdf5/hdf5-1_10_7
wget github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-1_10_7.tar.gz
tar -xf hdf5-1_10_7.tar.gz
cd hdf5-hdf5-1_10_7
source /opt/intel/oneapi/setvars.sh
./configure CC=mpiicx CXX=mpiicpx FC=mpiifort --enable-parallel --enable-shared --prefix=${HOME}/local/hdf5/hdf5-1_10_7 CFLAGS="-m64 -diag-disable=10441"
source /opt/intel/oneapi/setvars.sh
make install
```
#### NetCDF c-libs with parallel I/O support
```
mkdir -p ${HOME}/local/netcdf/netcdf-c-4.6.1
wget github.com/Unidata/netcdf-c/archive/refs/tags/v4.6.1.tar.gz -O netcdf-c-4.6.1.tar.gz
tar -xf netcdf-c-4.6.1.tar.gz
cd netcdf-c-4.6.1
source /opt/intel/oneapi/setvars.sh
export HDF5=${HOME}/local/hdf5/hdf5-1_10_7
./configure CC=mpiicx CPPFLAGS="-I${HDF5}/include" LDFLAGS="-L${HDF5}/lib" --enable-parallel --enable-shared --prefix=${HOME}/local/netcdf/netcdf-c-4.6.1 --enable-fortran --enable-remote-fortran-bootstrap --disable-dap-remote-tests CFLAGS="-m64 -diag-disable=10441"
source /opt/intel/oneapi/setvars.sh
make install
```
#### NetCDF fortran-libs
```
mkdir -p ${HOME}/local/netcdf/netcdf-f-4.5.0
wget github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.5.0.tar.gz -O netcdf-fortran-4.5.0.tar.gz
tar -xf netcdf-fortran-4.5.0.tar.gz
export NDFC=${HOME}/local/netcdf/netcdf-c-4.6.1
export LD_LIBRARY_PATH=${NDFC}/lib:${LD_LIBRARY_PATH}
source /opt/intel/oneapi/setvars.sh
./configure CC=mpiicx CXX=mpiicpx FC=mpiifort F77=mpiifort --prefix=${HOME}/local/netcdf/netcdf-f-4.5.0 --disable-fortran-type-check CPPFLAGS="-I${NDFC}/include" LDFLAGS="-L${NDFC}/lib" CFLAGS="-m64 -diag-disable=10441" --enable-shared --host=x86_64-pc-linux
source /opt/intel/oneapi/setvars.sh
make install
```
#### Clean up src of dependencies
```
cd ~
rm -rf ~/tmp
```
## Delft3D
```
#mkdir -p ~/local/delft3d/fm-68819
mkdir -p ~/local/delft3d/4-142586
mkdir ~/tmp
cd ~/tmp
#svn checkout --username <username> --password <password> https://svn.oss.deltares.nl/repos/delft3d/tags/delft3dfm/68819/ delft3dfm-68819
svn checkout --username <username> --password <password> https://svn.oss.deltares.nl/repos/delft3d/tags/delft3d4/142586 delft3d4-142586
```
#### Copy missing files: fix for known issue
```
#cp delft3dfm-68819/src/third_party_open/swan/src/*.[fF]* delft3dfm-68819/src/third_party_open/swan/swan_mpi
#cp delft3dfm-68819/src/third_party_open/swan/src/*.[fF]* delft3dfm-68819/src/third_party_open/swan/swan_omp
cp delft3d4-142586/src/third_party_open/swan/src/*.[fF]* delft3dfm-68819/src/third_party_open/swan/swan_mpi
cp delft3d4-142586/src/third_party_open/swan/src/*.[fF]* delft3dfm-68819/src/third_party_open/swan/swan_omp
```
#### Configure the build
```
#cd delft3dfm-68819/src
cd delft3d4-142586/src
export I_MPI_SHM="off"
export FC=mpiifort
export HDF5=${HOME}/local/hdf5/hdf5-1_10_7
export NDFC=${HOME}/local/netcdf/netcdf-c-4.6.1
export NDFF=${HOME}/local/netcdf/netcdf-f-4.5.0
export INTL=/opt/intel/oneapi/compiler/2024.0/lib
export LD_LIBRARY_PATH=${INTL}:${LD_LIBRARY_PATH}
source /opt/intel/oneapi/setvars.sh
./autogen.sh --verbose
./configure CC=mpiicx CXX=mpiicpx MPICXX=mpiicpx F77=mpiifort MPIF77=mpiifort FC=mpiifort MPIFC=mpiifort AM_FFLAGS='-lifcoremt -liomp5' FFLAGS="-qopenmp -L${INTL}" AM_FCFLAGS='-lifcoremt -liomp5' FCFLAGS="-qopenmp -L${INTL}" AM_LDFLAGS='-lifcoremt -liomp5' CPPFLAGS="-I${HDF5}/include -qopenmp -L${INTL} -diag-disable=10441" CFLAGS="-m64 -diag-disable=10441 -qopenmp -L${INTL}" NETCDF_CFLAGS="-I${NDFC}/include -I${NDFF}/include -qopenmp -L${INTL}" NETCDF_LIBS="-L${NDFC}/lib -L${NDFF}/lib -lnetcdf -qopenmp -L${INTL}" --prefix="${HOME}/local/delft3d/fm-68819"

make ds-install
```
Some problems, I changed:
1) utils_lgpl/deltares_common/packages/deltares_common_c/src/meminfo.cpp
2) utils_lgpl/ods/packages/ods/src/dlwbin.c

```
make ds-install -C engines_gpl/dflowfm
cd ..
```
