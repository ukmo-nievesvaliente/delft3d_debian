#!/bin/bash


# ================
# === Usage    ===
# ================
function print_usage_info {
    echo
    echo
    echo "Usage: ${0##*/} <CONFIG> [OPTIONS]"
    echo "- Only when <CONFIG>=all: Compile all engines that are not CMaked yet in the traditional way"
    echo "- Create directory 'build_<CONFIG>'"
    echo "  Delete it when it already existed"
    echo "- Execute '. src/setenv.sh' to load modules"
    echo "- Execute 'CMake <CONFIG>' to create makefile inside 'build_<CONFIG>'"
    echo "- Execute 'make VERBOSE=1 install'"
    echo "- Only when <CONFIG>=all: Combine all binaries in 'build_<CONFIG>\lnx64'"
    echo
    echo "<CONFIG>:"
    echo "- If <CONFIG> is missing, this usage will be print"
    echo "- all: All CMaked projects, currently D-Flow FM, DWAQ and DIMR"
    echo "- dflowfm"
    echo "- dwaq"
    echo "- dwaves"
    echo "- dimr"
    echo "- tests"
    echo "- swan"
    echo "- delft3d4"
    echo "- flow2d3d"
    echo
    echo "Options:"
    echo "-p, --prepareonly"
    echo "       Only CMake, no make"
    echo
    echo "--debug"
    echo "      Compile in debug mode"
    echo
    echo "More info  : https://oss.deltares.nl/web/delft3d/source-code"
    echo "About CMake: https://svn.oss.deltares.nl/repos/delft3d/trunk/src/cmake/doc/README"
    echo
    exit 1
}

# =========================
# === CheckUtils        ===
# =========================
function CheckUtils () {
    if ! command -v patchelf &> /dev/null; then
       echo "'patchelf' is not found."
    fi 

    if ! command -v svnversion &> /dev/null; then
       echo "'svnversion' is not found."
    fi
}



# =========================
# === CreateCMakedir    ===
# =========================
function CreateCMakedir () {
    echo
    echo "Create CMake dir for $1$2 ..."
    cd     $root
    rm -rf $root/build_$1$2
    mkdir  $root/build_$1$2

    return
}



# ==================
# === DoCMake    ===
# ==================
function DoCMake () {
    echo
    echo "Executing CMake for $1 ..."
    cd    $root/build_$1$2
    echo "cmake ../src/cmake -G "$generator" -B "." -D CONFIGURATION_TYPE="$1" -D CMAKE_BUILD_TYPE=${buildtype} &>build_$1$2/cmake_$1.log"
          cmake ../src/cmake -G "$generator" -B "." -D CONFIGURATION_TYPE="$1" -D CMAKE_BUILD_TYPE=${buildtype} &>cmake_$1.log
    if [ $? -ne 0 ]; then
        echo "CMake configure resulted in an error. Check log files."
        exit 1
    fi

    return
}



# =====================
# === BuildCMake    ===
# =====================
function BuildCMake () {
    echo
    echo "Building (make) based on CMake preparations for $1 ..."
    cd    $root/build_$1$2
    echo "make VERBOSE=1 install &>build_$1$2/make_$1.log"
          make VERBOSE=1 install &>make_$1.log
    if [ $? -ne 0 ]; then
        echo "CMake build resulted in an error. Check log files."
        exit 1
    fi

    return
}



# =========================
# === InstallAll        ===
# =========================
function InstallAll () {
    if [ ${1} = "all"  ]; then
        echo
        echo "Installing in build_$1$2 ..."
        cd     $root
        rm -rf $root/build_$1$2/lnx64
        mkdir -p $root/build_$1$2/lnx64/bin
        mkdir -p $root/build_$1$2/lnx64/lib
        mkdir -p $root/build_$1$2/lnx64/share/delft3d/esmf/lnx64/bin
        mkdir -p $root/build_$1$2/lnx64/share/delft3d/esmf/lnx64/bin_COS7

        ## The traditional build is not executed anymore
        ## Start with artifacts from traditional build
        #cp -rf $root/src/bin/ $root/build_$1$2/lnx64/ &>/dev/null
        #cp -rf $root/src/lib/ $root/build_$1$2/lnx64/ &>/dev/null
        #cp -rf $root/src/share/ $root/build_$1$2/lnx64/ &>/dev/null
        ## Delete DIMR/D-Flow FM/D-WAQ/D-WAVES related files: they will be added from the CMake build tasks
        #rm -f $root/build_$1$2/lnx64/bin/dflowfm        &>/dev/null
        #rm -f $root/build_$1$2/lnx64/bin/dimr           &>/dev/null
        #rm -f $root/build_$1$2/lnx64/lib/libdflowfm.so* &>/dev/null
        #rm -f $root/build_$1$2/lnx64/lib/libdimr.so*    &>/dev/null
        #
        #rm -f $root/build_$1$2/lnx64/bin/delwaq*                      &>/dev/null
        #rm -f $root/build_$1$2/lnx64/lib/libdelwaq.so*                &>/dev/null
        #rm -f $root/build_$1$2/lnx64/lib/libwaq_plugin_wasteload.so*  &>/dev/null
        #rm -f $root/build_$1$2/lnx64/share/delft3d/bloom*             &>/dev/null
        #rm -f $root/build_$1$2/lnx64/share/delft3d/proc_def*          &>/dev/null
        #
        #rm -f $root/build_$1$2/lnx64/bin/wave*                        &>/dev/null
        #rm -f $root/build_$1$2/lnx64/bin/swan*                        &>/dev/null
        #rm -f $root/build_$1$2/lnx64/lib/libwave*                     &>/dev/null

        # CMaked stuff
        cp -rf $root/build_$1$2/install/* $root/build_$1$2/lnx64/ &>/dev/null

        # Additional step to copy ESMF stuff needed by D-WAVES
        cp -rf $root/src/third_party_open/esmf/lnx64/bin/ESMF_RegridWeightGen                          $root/build_$1$2/lnx64/bin                               &>/dev/null
        cp -rf $root/src/third_party_open/esmf/lnx64/scripts/ESMF_RegridWeightGen_in_Delft3D-WAVE.sh   $root/build_$1$2/lnx64/bin                               &>/dev/null
        cp -rf $root/src/third_party_open/esmf/lnx64/bin/lib*                                          $root/build_$1$2/lnx64/share/delft3d/esmf/lnx64/bin      &>/dev/null
        cp -rf $root/src/third_party_open/esmf/lnx64/bin_COS7/lib*                                     $root/build_$1$2/lnx64/share/delft3d/esmf/lnx64/bin_COS7 &>/dev/null
    fi

    return
}



# ============
# === MAIN ===
# ============

#
## Defaults
prepareonly=0
mode=quiet
config=
generator="Unix Makefiles"
compiler=intel21
buildtype=Release
buildDirExtension=""

## check if Deltares system
isdeltares=$([ -f "/opt/apps/deltares/.nl" ] && echo "yes" || echo "no")

#
## Start processing command line options:

while [[ $# -ge 1 ]]
do
key="$1"

case $key in
    -c|--compiler)
    shift
    compiler="$1"
    shift
    ;;
    -p|--prepareonly)
    prepareonly=1
    shift
    ;;
    -h|--help)
    print_usage_info
    ;;
    all)
    config="all"
    shift
    ;;
    dflowfm)
    config="dflowfm"
    shift
    ;;
    dwaq)
    config="dwaq"
    shift
    ;;
    dwaves)
    config="dwaves"
    shift
    ;;
    dimr)
    config="dimr"
    shift
    ;;
    tests)
    config="tests"
    shift
    ;;
    swan)
    config="swan"
    shift
    ;;
    delft3d4)
    config="delft3d4"
    shift
    ;;
    flow2d3d)
    config="flow2d3d"
    shift
    ;;
    --debug)
    buildtype=Debug
    buildDirExtension="_debug"
    shift
    ;;
    *)
    echo ERROR: Unknown command line argument $key
    exit 1
    ;;
esac
done

#
# Check config parameter
if [ -z $config ]; then
    print_usage_info
fi

scriptdirname=`readlink \-f \$0`
scriptdir=`dirname $scriptdirname`
root=$scriptdir


if [ "$isdeltares" = "yes" ]; then
    # On Deltares systems only
    echo
    echo "    config          : $config" "${buildtype}"
    echo "    deltares system : $isdeltares"
    echo "    compiler        : $compiler"
    echo "    prepareonly     : $prepareonly"
    echo

    # Check if modules exist
    module list > /dev/null
    if [ $? -ne 0 ]; then
        # No, modules do not exist: "Dot" setenv.sh version without modules
        echo ". $root/src/setenv_no_modules.sh $compiler"
              . $root/src/setenv_no_modules.sh $compiler
    else
        # Yes, modules do exist: "Dot" setenv.sh to load the modules needed
        echo ". $root/src/setenv.sh $compiler"
              . $root/src/setenv.sh $compiler
    fi
    if [ $? -ne 0 ]; then
        echo "Setenv.sh resulted in an error. Check log files."
        exit 1
    fi

else
    # On nieves systems
    echo ". $root/src/setenv_no_modules_nieves.sh"
          . $root/src/setenv_no_modules_nieves.sh
    echo
    echo "    config          : $config" "${buildtype}"
    echo "    prepareonly     : $prepareonly"
    echo
fi

# check required utilities
chkutils=$(CheckUtils)
if [ ! -z "$chkutils" ]; then
    echo "$chkutils"
    echo "Install missing programs and retry."
    exit 1
fi

CreateCMakedir ${config} ${buildDirExtension}

DoCMake ${config} ${buildDirExtension}

if [ "$prepareonly" = "1" ]; then
    echo Finished with preparations only
    exit 0
fi

BuildCMake ${config} ${buildDirExtension}

InstallAll ${config} ${buildDirExtension}

echo Finished
