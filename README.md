# How to install Delft3D in Debian 12
#These notes describe how to install Delft3D on my workstation mounting Debian 12 - adapted from [here](https://gist.github.com/H0R5E/c4af6db788b227de702a12e01b64cf46).
## Pre-requisities
### 1) Dependencies from package manager
```
sudo apt -y update && sudo apt list --upgradable && sudo apt -y upgrade
sudo apt install -y build-essential m4 ruby wget subversion pkg-config
sudo apt install -y zlib1g zlib1g-dev curl libcurl4 libcurl4-openssl-dev
sudo apt install -y uuid uuid-dev expat libexpat1-dev autoconf libtool bison flex
sudo apt install -y patchelf libtiff-dev sqlite3 libsqlite3-dev #petsc-dev libmetis-dev
```
### 2) Intel oneAPI
```
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
sudo apt update
sudo apt install intel-hpckit=2022.2.0-191
#sudo apt install -y intel-hpckit
```
### 3) Dependencies that needs to be compiled
```
sudo mkdir /opt/{hdf5,netcdf,proj,gdal,petsc,metis}
sudo chown nievesg:nievesg /opt/*
mkdir -p ~/tmp
cd ~/tmp
```
#### HDF5-1.10.7 with parallel I/O support
```
mkdir -p /opt/hdf5/hdf5-1_10_7
wget github.com/HDFGroup/hdf5/archive/refs/tags/hdf5-1_10_7.tar.gz
tar -xf hdf5-1_10_7.tar.gz
cd hdf5-hdf5-1_10_7
source /opt/intel/oneapi/setvars.sh
./configure CC=mpiicx CXX=mpiicpx FC=mpiifort --enable-parallel --enable-shared --prefix=/opt/hdf5/hdf5-1_10_7 CFLAGS="-m64 -diag-disable=10441"
make install
```
#### NetCDF c-libs with parallel I/O support
```
mkdir -p /opt/netcdf/c4.6.1-f4.5.0
wget github.com/Unidata/netcdf-c/archive/refs/tags/v4.6.1.tar.gz -O netcdf-c-4.6.1.tar.gz
tar -xf netcdf-c-4.6.1.tar.gz
cd netcdf-c-4.6.1
source /opt/intel/oneapi/setvars.sh --force
export HDF5=/opt/hdf5/hdf5-1_10_7
./configure CC=mpiicx CPPFLAGS="-I${HDF5}/include" LDFLAGS="-L${HDF5}/lib" --enable-parallel --enable-shared --prefix=/opt/netcdf/c4.6.1-f4.5.0 --enable-fortran --enable-remote-fortran-bootstrap --disable-dap-remote-tests CFLAGS="-m64 -diag-disable=10441"
make install
```
#### NetCDF fortran-libs
```
wget github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.5.0.tar.gz -O netcdf-fortran-4.5.0.tar.gz
tar -xf netcdf-fortran-4.5.0.tar.gz
cd netcdf-fortran-4.5.0
export NDFC=/opt/netcdf/c4.6.1-f4.5.0
export LD_LIBRARY_PATH=${NDFC}/lib:${LD_LIBRARY_PATH}
source /opt/intel/oneapi/setvars.sh --force
./configure CC=mpiicx CXX=mpiicpx FC=mpiifort F77=mpiifort --prefix=/opt/netcdf/c4.6.1-f4.5.0 --disable-fortran-type-check CPPFLAGS="-I${NDFC}/include" LDFLAGS="-L${NDFC}/lib" CFLAGS="-m64 -diag-disable=10441" --enable-shared --host=x86_64-pc-linux
make install
```
#### PROJ4
GDAL needs proj > 6.0
```
mkdir /opt/proj/v7.1.0
wget https://download.osgeo.org/proj/proj-7.1.0.tar.gz
tar -xvzf proj-7.1.0.tar.gz
cd proj-7.1.0
mkdir nad
cd nad
wget https://download.osgeo.org/proj/proj-data-1.1.tar.gz
tar -xvzf proj-data-1.1.tar.gz
cd ../
./configure --prefix=/opt/proj/v7.1.0
make
make install
```
#### GDAL
```
mkdir -p /opt/gdal/v3.1.2
wget https://github.com/OSGeo/gdal/releases/download/v3.1.2/gdal-3.1.2.tar.gz
tar -xvzf gdal-3.1.2.tar.gz
cd gdal-3.1.2
export LD_LIBRARY_PATH=/opt/proj/v7.1.0/lib:$LD_LIBRARY_PATH
./configure --with-proj=/opt/proj/v7.1.0 --prefix=/opt/gdal/v3.1.2
```
We need to modify `./ogr/ogrsf_frmts/cad/libopencad/dwg/r2000.cpp` addying `#inclue <limits>` at L41.
```
make
make install
```
#### PETSC
```
mkdir -p /opt/petsc/v3.20.5
wget https://web.cels.anl.gov/projects/petsc/download/release-snapshots/petsc-3.20.5.tar.gz
tar -xvzf petsc-3.20.5.tar.gz
cd petsc-3.20.5
source /opt/intel/oneapi/setvars.sh --force
./configure --prefix=/opt/petsc/v3.20.5 --with-blaslapack-dir=/opt/intel/oneapi/mkl --with-cc=mpiicx --with-cxx=mpiicpx --with-fc=mpiifx
make PETSC_DIR=/home/nievesg/tmp/petsc-3.20.5 PETSC_ARCH=arch-linux-c-debug all
make PETSC_DIR=/home/nievesg/tmp/petsc-3.20.5 PETSC_ARCH=arch-linux-c-debug install
```
#### METIS
```
mkdir -p /opt/metis/v5.1.0
wget http://glaros.dtc.umn.edu/gkhome/fetch/sw/metis/metis-5.1.0.tar.gz
tar -xvzf metis-5.1.0.tar.gz
cd metis-5.1.0
```
As explained in `Install.txt` , you need to adapt `include/metis.h` to your needs:

L33 -> `#define IDXTYPEWIDTH 64`

L43 -> `#define REALTYPEWIDTH 64`

After, as explained in `BUILD.txt`:
```
source /opt/intel/oneapi/setvars.sh --force
make config prefix=/opt/metis/v5.1.0 cc=mpiicx
make install
```
#### Clean up src of dependencies
```
cd ~
rm -rf ~/tmp/*
```
## Delft3D
```
mkdir -p /opt/delft3d/s4-142586
cd ~/tmp
svn checkout --username <username> --password <password> https://svn.oss.deltares.nl/repos/delft3d/tags/delft3d4/142586 delft3d4-142586
```
#### Copy missing files: fix for known issue
```
cp delft3d4-142586/src/third_party_open/swan/src/*.[fF]* delft3d4-142586/src/third_party_open/swan/swan_mpi
cp delft3d4-142586/src/third_party_open/swan/src/*.[fF]* delft3d4-142586/src/third_party_open/swan/swan_omp
```
#### Configure the build
Go in the work directory:
```
cd delft3d4-142586/
```
Load the environment:
```
export I_MPI_SHM="off"
export FC=mpiifort
export HDF5=${HOME}/local/hdf5/hdf5-1_10_7
export NCDF=${HOME}/local/netcdf/c4.6.1-f4.5.0
export INTL=/opt/intel/oneapi/compiler/2023.2.3/linux/compiler/lib/intel64_lin
export LD_LIBRARY_PATH=${INTL}:${LD_LIBRARY_PATH}
source /opt/intel/oneapi/setvars.sh
./autogen.sh --verbose
```
Newer version of linux do not have `sys/sysctl.h` anymore but they have `linux/sysctl.h` instead. Therefore, line 3 of `utils_lgpl/deltares_common/packages/deltares_common_c/src/meminfo.cpp` needs to be changed accordingly.


Configure the build:
```
./configure CC=mpiicx CXX=mpiicpx MPICXX=mpiicpx F77=mpiifort MPIF77=mpiifort FC=mpiifort MPIFC=mpiifort AM_FFLAGS='-lifcoremt -liomp5' FFLAGS="-qopenmp -L${INTL}" AM_FCFLAGS='-lifcoremt -liomp5' FCFLAGS="-qopenmp -L${INTL}" AM_LDFLAGS='-lifcoremt -liomp5' CPPFLAGS="-I${HDF5}/include -qopenmp -L${INTL} -diag-disable=10441 -Wno-implicit-function-declaration -Wno-implicit-int" CFLAGS="-m64 -diag-disable=10441 -qopenmp -L${INTL} -Wno-implicit-function-declaration -Wno-implicit-int" NETCDF_CFLAGS="-I${NCDF}/include -qopenmp -L${INTL}" NETCDF_LIBS="-L${NCDF}/lib -lnetcdf -qopenmp -L${INTL}" --prefix="${HOME}/local/delft3d/s4-142586"
```
As explained [here](https://community.intel.com/t5/Intel-C-Compiler/Build-failure-with-with-newer-2022-2-compiler-in-pipeline/m-p/1419482), INTEL compilers are much stricter after version 2022.1 and some warnings are now treated as errors. Indeed, older compilations of Delft3D (see e.g., [here](https://oss.deltares.nl/documents/portlet_file_entry/183920/log_v67888_compilation.txt/d71cf5ba-8515-6604-165c-983f79e29fad?download=true)) used to give warning for `-Wimplicit-function-declaration` and `-Wimplicit-int` while now we have errors. In order to avoid this, the `-Wno-implicit-function-declaration` and `-Wno-implicit-int` compilation keys have been added in the configuration above. 

#### Install
```
make ds-install
#make ds-install -C engines_gpl/dflowfm
cd ..
```
#### Test the build
```
pushd examples/01_standard
```
Modify `run.sh` as follows:
```
#../../build_delft3d4/install/bin/run_dflow2d3d.sh
~/local/delft3d/4-142586/bin/run_dflow2d3d.sh
```
Then run the test as follows:
```
./run.sh
popd
```
