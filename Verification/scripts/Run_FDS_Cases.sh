#!/bin/bash

# This script runs the FDS Verification Cases on a linux machine with
# a batch queuing system

queue=batch
DEBUG=
IB=
nthreads=1
resource_manager=
walltime=
errfileoption=
RUNOPTION=
CURDIR=`pwd`
BACKGROUND=

if [ "$FDSNETWORK" == "infiniband" ] ; then
  IB=ib
fi

function usage {
echo "Run_FDS_Cases.sh [ -d -h -m max_iterations -o nthreads -q queue_name "
echo "                   -s -r resource_manager ]"
echo "Runs FDS verification suite"
echo ""
echo "Options"
echo "-d - use debug version of FDS"
echo "-E - redirect stderr to a file if the 'none' queue is used"
echo "-h - display this message"
echo "-m max_iterations - stop FDS runs after a specifed number of iterations (delayed stop)"
echo "     example: an option of 10 would cause FDS to stop after 10 iterations"
echo "-M - run only cases that use multiple processes"
echo "-o nthreads - run FDS with a specified number of threads [default: $nthreads]"
echo "-q queue_name - run cases using the queue queue_name"
echo "     default: batch"
echo "     other options: fire70s, vis"
echo "-r resource_manager - run cases using the resource manager"
echo "     default: PBS"
echo "     other options: SLURM"
echo "-s - stop FDS runs"
echo "-S - run only cases that use one process"
echo "-w time - walltime request for a batch job"
echo "     default: empty"
echo "     format for PBS: hh:mm:ss, format for SLURM: dd-hh:mm:ss"
exit
}

cd ../..
export SVNROOT=`pwd`
cd $CURDIR

while getopts 'c:dEhMm:o:q:r:Ssw:' OPTION
do
case $OPTION in
  d)
   DEBUG=_db
   ;;
  E)
   errfileoption="-E"
   ;;
  h)
   usage;
   ;;
  m)
   export STOPFDSMAXITER="$OPTARG"
   ;;
  M)
   RUNOPTION="-M"
   ;;
  o)
   nthreads="$OPTARG"
   ;;
  q)
   queue="$OPTARG"
   ;;
  r)
   resource_manager="$OPTARG"
   ;;
  s)
   export STOPFDS=1
   ;;
  S)
   RUNOPTION="-S"
   ;;
  w)
   walltime="-w $OPTARG"
   ;;
esac
done

size=_64

OS=`uname`
if [ "$OS" == "Darwin" ]; then
  PLATFORM=osx$size
else
  PLATFORM=linux$size
fi

IB=
if [ "$FDSNETWORK" == "infiniband" ]; then
  IB=ib
fi

export FDS=$SVNROOT/FDS_Compilation/${OPENMP}intel_$PLATFORM$DEBUG/fds_${OPENMP}intel_$PLATFORM$DEBUG
export FDSMPI=$SVNROOT/FDS_Compilation/mpi_intel_$PLATFORM$IB$DEBUG/fds_mpi_intel_$PLATFORM$IB$DEBUG
export QFDSSH="$SVNROOT/Utilities/Scripts/qfds.sh $RUNOPTION"

if [ "$resource_manager" == "SLURM" ]; then
   export RESOURCE_MANAGER="SLURM"
else
   export RESOURCE_MANAGER="PBS"
fi
if [ "$queue" != "" ]; then
   if [ "$queue" == "none" ]; then
      BACKGROUND="-B background"
   fi
   queue="-q $queue"
fi

export BASEDIR=`pwd`

export QFDS="$QFDSSH $BACKGROUND $walltime $errfileoption -n $nthreads -e $FDSMPI $queue" 
cd ..
./FDS_Cases.sh
cd $CURDIR

echo FDS cases submitted