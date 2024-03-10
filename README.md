# How to install Delft3D in Debian 12

## Pre-requisities
### 1) Dependencies from package manager
```
sudo apt -y update && sudo apt list --upgradable && sudo apt -y upgrade
sudo apt install -y build-essential m4 ruby wget subversion pkg-config
sudo apt install -y zlib1g zlib1g-dev curl libcurl4 libcurl4-openssl-dev
sudo apt install -y uuid uuid-dev expat libexpat1-dev autoconf libtool bison flex
sudo apt install -y patchelf libtiff-dev sqlite3 libsqlite3-dev #petsc-dev libmetis-dev
```
#### Intel oneAPI
```
wget -O- https://apt.repos.intel.com/intel-gpg-keys/GPG-PUB-KEY-INTEL-SW-PRODUCTS.PUB | gpg --dearmor | sudo tee /usr/share/keyrings/oneapi-archive-keyring.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/oneapi-archive-keyring.gpg] https://apt.repos.intel.com/oneapi all main" | sudo tee /etc/apt/sources.list.d/oneAPI.list
sudo apt update
sudo apt install intel-hpckit=2022.2.0-191
#sudo apt install -y intel-hpckit
```
### 2) Dependencies that needs to be compiled
```
sudo mkdir /opt/{hdf5,netcdf,proj,gdal,petsc,metis,delft3d4}
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
rm -rf ~/tmp
```
## Delft3D
```
svn checkout --username <username> --password <password> https://svn.oss.deltares.nl/repos/delft3d/tags/delft3d4/142586 /opt/delft3d4/v142586
cd /opt/delft3d4/v142586
```
#### Cloning building code and using it
```
git clone https://github.com/ukmo-nievesvaliente/delft3d_debian.git my_src
mv build.sh build_ori.sh
cp my_src/src/build.sh .
ln -s ${PWD}/my_src/src/setenv_no_modules.sh ${PWD}/src/setenv_no_modules_nieves.sh
```

#### Copy missing files: fix for known issue
```
cp src/third_party_open/swan/src/*.[fF]* src/third_party_open/swan/swan_mpi
cp src/third_party_open/swan/src/*.[fF]* src/third_party_open/swan/swan_omp
```
#### Bugfix for Debian 12
Newer versions of linux do not have `sys/sysctl.h` anymore but they have `linux/sysctl.h` instead. Therefore, Line 3 of `src/utils_lgpl/deltares_common/packages/deltares_common_c/src/meminfo.cpp` needs to be changed accordingly.

#### Build and install

```
./build.sh delft3d4
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
