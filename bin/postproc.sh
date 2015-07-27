#!/bin/sh

# these has to be changed before running the program
#---------------------------------------------------
if [ $# -eq 0 ]
  then
    echo "Directory must be specified as argument"
    exit 1
fi

# the base directory where all the data recides
BASE_DIR=$1

PREPROC_DIR_NAME=preproc
YEARLY_PREPROC_DIR_NAME=$PREPROC_DIR_NAME/yearly
GLOBAL_PREPROC_DIR_NAME=$PREPROC_DIR_NAME/global

POSTPROC_DIR_NAME=postproc/unweighted
POSTPROC_INTERMEDIATE_DIR_NAME=$POSTPROC_DIR_NAME/intermediate
YEARLY_POSTPROC_DIR_NAME=$POSTPROC_DIR_NAME/yearly
GLOBAL_POSTPROC_DIR_NAME=$POSTPROC_DIR_NAME/global

MDS_DIR_NAME=mds/unweighted
YEARLY_MDS_DIR_NAME=$MDS_DIR_NAME/yearly
GLOBAL_MDS_DIR_NAME=$MDS_DIR_NAME/global

#### names of directories inside the base dir
# directory where histograms are created
HIST_DIR_NAME=$POSTPROC_INTERMEDIATE_DIR_NAME/histogram
# directory where the global vectors
GLOBAL_VEC_DIR_NAME=$GLOBAL_PREPROC_DIR_NAME/vectors
# directory where the global stock file with all stocks for that period
GLOBAL_STOCK_DIR_NAME=input
# directory name of the vectors
VECS_DIR_NAME=$YEARLY_PREPROC_DIR_NAME/vectors
#directory name of common points
COMMON_POINTS_DIR_NAME=$POSTPROC_INTERMEDIATE_DIR_NAME/common_points
#directory name of where points are created by damds
POINTS_DIR_NAME=$YEARLY_MDS_DIR_NAME
# directory where global points
GLOBAL_POINTS_DIR_NAME=$GLOBAL_MDS_DIR_NAME
# directory where rotated files are stored
ROTATE_FINAL_DIR_NAME=$YEARLY_POSTPROC_DIR_NAME/rotate/points
ROTATE_FINAL_SUMMARY_DIR_NAME=$YEARLY_POSTPROC_DIR_NAME/rotate/summary
# directory where final labeled point output
LABEL_OUT_DIR_NAME=$YEARLY_POSTPROC_DIR_NAME/rotate/points/labeled/byhist
# directory where output of rotation program stored
ROTATE_OUT_DIR_NAME=$POSTPROC_INTERMEDIATE_DIR_NAME/rotate_ops
# name of the global stock file name
STOCK_FILE_NAME=2004_2014.csv
#global points file name, this should be in the global points directory
GLOBAL_POINTS_FILE_NAME=2004_2014.txt

mkdir -p $BASE_DIR/$ROTATE_FINAL_DIR_NAME
mkdir -p $BASE_DIR/$ROTATE_FINAL_SUMMARY_DIR_NAME
mkdir -p $BASE_DIR/$LABEL_OUT_DIR_NAME

MANXCAT_JAR=$HOME/.m2/repository/com/google/guava/guava/15.0/guava-15.0.jar:$HOME/.m2/repository/commons-cli/commons-cli/1.2/commons-cli-1.2.jar:$HOME/.m2/repository/habanero-java-lib/habanero-java-lib/0.1.4-SNAPSHOT/habanero-java-lib-0.1.4-SNAPSHOT.jar:$HOME/.m2/repository/ompi/ompijavabinding/1.8.1/ompijavabinding-1.8.1.jar:$HOME/.m2/repository/org/jblas/jblas/1.2.3/jblas-1.2.3.jar:/$HOME/.m2/repository/edu/indiana/salsahpc/mdsaschisq/1.0-ompi1.8.1/mdsaschisq-1.0-ompi1.8.1.jar

### don't change the following uness you know exactly what you change
# -------------------------------------------------------------------
GLOBAL_VECS=$BASE_DIR/$GLOBAL_VEC_DIR_NAME
GLOBAL=$BASE_DIR/$GLOBAL_STOCK_DIR_NAME
ORIGINAL_STOCK_FILE=$GLOBAL/$STOCK_FILE_NAME
#CAT_FILE=$BASE_DIR/all_companylist.csv
CAT_FILE=$BASE_DIR/$HIST_DIR_NAME
GLOBAL_POINTS=$BASE_DIR/$GLOBAL_POINTS_DIR_NAME
CONT_VECS=$BASE_DIR/$VECS_DIR_NAME
CONT_POINTS=$BASE_DIR/$POINTS_DIR_NAME
CONT_COMMON_POINTS=$BASE_DIR/$COMMON_POINTS_DIR_NAME
HIST_DIR=$BASE_DIR/$HIST_DIR_NAME

mkdir -p $CONT_COMMON_POINTS

# generate the common points
# --------------------------
java -cp ../mpi/target/stocks-1.0-ompi1.8.1-jar-with-dependencies.jar PointTransformer -g $GLOBAL_VECS/$STOCK_FILE_NAME -gp $GLOBAL_POINTS/$GLOBAL_POINTS_FILE_NAME -v $CONT_VECS -p $CONT_POINTS -d $CONT_COMMON_POINTS | tee $BASE_DIR/$POSTPROC_INTERMEDIATE_DIR_NAME/common.points.out.txt
# generate histogram
# --------------------
java -cp ../mpi/target/stocks-1.0-ompi1.8.1-jar-with-dependencies.jar Histogram -v $CONT_VECS -s $ORIGINAL_STOCK_FILE -d $HIST_DIR -b 10 | tee $BASE_DIR/$POSTPROC_INTERMEDIATE_DIR_NAME/histogram.out.txt

# rotate the points
# ******************
ROTATE_POINTS=$CONT_COMMON_POINTS/*
ROTATE_POINT_DIR=$CONT_COMMON_POINTS
ROTATE_BASE_FILE=$CONT_COMMON_POINTS/2004_2014.csv
ROTATE_OUT=$BASE_DIR/$ROTATE_OUT_DIR_NAME
ROTATE_CONTROL=$ROTATE_OUT/rotate_control
FULL_POINTS=$CONT_POINTS

mkdir -p $ROTATE_OUT
mkdir -p $ROTATE_CONTROL

FINAL_ROTATE_SUMMARY=$BASE_DIR/$ROTATE_FINAL_SUMMARY_DIR_NAME

for f in $ROTATE_POINTS
do
  common_filename="${f##*/}"
  common_filename_ext="${common_filename%.*}"
  common_file=$CONT_COMMON_POINTS/$common_filename
  echo 'common file' $common_file
  no_of_common_lines=`sed -n '$=' $common_file`
  echo $no_of_common_lines

  ext='.txt'
  full_file=$FULL_POINTS/$common_filename_ext$ext
  echo 'full file' $full_file
  no_of_full_lines=`sed -n '$=' $full_file`
  echo $no_of_full_lines

  echo $FINAL_ROTATE_SUMMARY/$common_filename.rotation.summary.txt
  
  full='full'
  java -DBaseResultDirectoryName=$ROTATE_OUT \
  -DControlDirectoryName=$ROTATE_CONTROL \
  -DInitializationFileName=$ROTATE_BASE_FILE -DReducedVectorOutputFileName=$ROTATE_OUT/$common_filename_ext$ext \
  -DRotationLabelsFileName=$common_file \
  -DfinalRotationFileName=$full_file \
  -DfinalRotationPointCount=$no_of_full_lines \
  -DDataPoints=$no_of_common_lines \
  -cp $MANXCAT_JAR salsa.mdsaschisq.ManxcatCentral -c mconfig.properties -n 1 -t 1 2>&1 | tee $FINAL_ROTATE_SUMMARY/$common_filename.rotation.summary.txt
done

# apply labels to points
# ------------------------
# copy the fully rotated files to directory
FINAL_ROTATE=$BASE_DIR/$ROTATE_FINAL_DIR_NAME
mkdir -p $FINAL_ROTATE
cp $ROTATE_OUT/*full.txt $FINAL_ROTATE
dir=`pwd`
cd $FINAL_ROTATE
for i in SIMPLE*
do
    mv "$i" "`echo $i | sed 's/SIMPLE//'`"
done
for i in *full.txt
do
    mv "$i" "`echo $i | sed 's/full\.txt//'`"
done
cd $dir
LABEL_OUT=$BASE_DIR/$LABEL_OUT_DIR_NAME
mkdir -p $LABEL_OUT

java -cp ../mpi/target/stocks-1.0-ompi1.8.1-jar-with-dependencies.jar LabelApply \
-v $CONT_VECS \
-p $FINAL_ROTATE \
-d $LABEL_OUT \
-o $ORIGINAL_STOCK_FILE \
-s $HIST_DIR -h