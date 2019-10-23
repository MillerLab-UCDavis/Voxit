#!/bin/sh
#
# train_make_ftr_file.sh
#
# Create a pfile with sbpca features from a list of wavs
# that can be used with train_SAcC
# but which can be distributed across machines.
#
# 2013-03-14 Dan Ellis dpwe@ee.columbia.edu

# Paths to commands
BINDIR=../icsi-scenic-tools/H-`uname -m`-`uname -s | tr 'A-Z' 'a-z'`

RANGE=$BINDIR/feacat-1.02/Range
FEACAT=$BINDIR/feacat-1.02/feacat
QNNORM=$BINDIR/quicknet-v3_31/qnnorm

SAcC=./SAcC_prj/distrib/run_SAcC.sh

# Check args
if [ $# != 2 ]; then
    echo "usage: $0 inputwavfilelist outputpfile"
    echo "  will calculate 240-dim subband pca features for every 10ms hop "
    echo "  in each wav file listed in the input file, and write them to a "
    echo "  output feature pfile."
    exit 1
fi

INWAVLIST=$1
OUTPFILE=$2

# Working directory (will be deleted at the end)
WORKDIR=$TMPDIR/tmff-$$
mkdir $WORKDIR

## Break up list file into several parts
# How many parts?
NPARTS=4
# so how many files per part?
NFILES=`wc -l keele.list | awk '{print $1}'`
FILESPERPART=`expr 1 + $NFILES / $NPARTS`

# Create a master list of input/output file pairs
REMSFILE=$WORKDIR/remains
# paste on output file names
OPFILELIST=$WORKDIR/opfilelist
TXTDIR=$WORKDIR/txt
mkdir $TXTDIR
$RANGE 0:`expr $NFILES - 1` | awk "{print \"$TXTDIR/\"\$1\".txt\"}" > $OPFILELIST
paste -d ',' $INWAVLIST $OPFILELIST > $REMSFILE

# Segment into the right number of parts
PART=1
while [ $PART -lt $NPARTS ]; do
    head -n $FILESPERPART < $REMSFILE > $WORKDIR/part$PART.list
    mv $REMSFILE $REMSFILE~
    tail -n +`expr $FILESPERPART + 1` < $REMSFILE~ > $REMSFILE
    PART=`expr $PART + 1`
done
# last part is whatever's left
mv $REMSFILE $WORKDIR/part$NPARTS.list


## Now run SAcC on each part
STARTUTT=0
PART=1
while [ $PART -le $NPARTS ]; do

    $SAcC $WORKDIR/part$PART.list sbpca_out.config 0 "start_utt $STARTUTT"

    PART=`expr $PART + 1`
    STARTUTT=`expr $STARTUTT + $FILESPERPART`
done

## Feed all the output text files, in the right order, to create pfile
cat `cat $OPFILELIST` | $FEACAT -ipf ascii -width 240 -opf pfile -o $OUTPFILE

# create norms file
NORMSFILENAME=`echo $OUTPFILE | sed -e 's/\.pf//'`.norms
$QNNORM norm_ftrfile=$OUTPFILE output_normfile=$NORMSFILENAME

# remove all temporary files
rm -rf $WORKDIR

exit 0
