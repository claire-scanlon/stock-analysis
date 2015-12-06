## Time Series Analysis of Stocks

This is a guide to show how to install and run the project.

A detailed description of the details project can be found in the technical paper

https://github.com/DSC-SPIDAL/publications/raw/master/stocks/stocks_visualization.pdf

and the poster

https://github.com/DSC-SPIDAL/publications/raw/master/stocks/stock_poster.pdf

Prerequisites
-----
1. Operating System
  * This program is extensively tested and known to work on,
    *  Red Hat Enterprise Linux Server release 5.10 (Tikanga)
    *  Ubuntu 12.04.3 LTS
    *  Ubuntu 12.10
 
2. Java
  * Download Oracle JDK 8 from http://www.oracle.com/technetwork/java/javase/downloads/index.html
  * Extract the archive to a folder named `jdk1.8.0`
  * Set the following environment variables.
  ```
    JAVA_HOME=<path-to-jdk1.8.0-directory>
    PATH=$JAVA_HOME/bin:$PATH
    export JAVA_HOME PATH
  ```
3. Apache Maven
  * Download latest Maven release from http://maven.apache.org/download.cgi
  * Extract it to some folder and set the following environment variables.
  ```
    MVN_HOME=<path-to-Maven-folder>
    $PATH=$MVN_HOME/bin:$PATH
    export MVN_HOME PATH
  ```

4. OpenMPI
  * We recommend using `OpenMPI 1.8.1` although it works with the previous 1.7 versions. The Java binding is not available in versions prior to 1.7, hence are not recommended. Note, if using a version other than 1.8.1 please remember to set Maven dependency appropriately in the `pom.xml`.
  * Download OpenMPI 1.8.1 from http://www.open-mpi.org/software/ompi/v1.8/downloads/openmpi-1.8.1.tar.gz
  * Extract the archive to a folder named `openmpi-1.8.1`
  * Also create a directory named `build` in some location. We will use this to install OpenMPI
  * Set the following environment variables
  ```
    BUILD=<path-to-build-directory>
    OMPI_181=<path-to-openmpi-1.8.1-directory>
    PATH=$BUILD/bin:$PATH
    LD_LIBRARY_PATH=$BUILD/lib:$LD_LIBRARY_PATH
    export BUILD OMPI_181 PATH LD_LIBRARY_PATH
  ```
  * The instructions to build OpenMPI depend on the platform. Therefore, we highly recommend looking into the `$OMPI_181/INSTALL` file. Platform specific build files are available in `$OMPI_181/contrib/platform` directory.
  * In general, please specify `--prefix=$BUILD` and `--enable-mpi-java` as arguments to `configure` script. If Infiniband is available (highly recommended) specify `--with-verbs=<path-to-verbs-installation>`. In summary, the following commands will build OpenMPI for a Linux system.
  ```
    cd $OMPI_181
    ./configure --prefix=$BUILD --enable-mpi-java
    make;make install
  ```
  * If everything goes well `mpirun --version` will show `mpirun (Open MPI) 1.8.1`. Execute the following command to instal `$OMPI_181/ompi/mpi/java/java/mpi.jar` as a Maven artifact.
  ```
    mvn install:install-file -DcreateChecksum=true -Dpackaging=jar -Dfile=$OMPI_181/ompi/mpi/java/java/mpi.jar -DgroupId=ompi -DartifactId=ompijavabinding -Dversion=1.8.1
  ```
  * Few examples are available in `$OMPI_181/examples`. Please use `mpijavac` with other parameters similar to `javac` command to compile OpenMPI Java programs. Once compiled `mpirun [options] java -cp <classpath> class-name arguments` command with proper values set as arguments will run the program. 

5. Cluster with Slurm Job Manager
  * The scripts assume a cluster with Slurm job manager. You are welcome to convert the scripts to another Job management system as well.
  * Also the programs assumes that the files are in a shared directory which can be accessed by all the nodes in the cluster
  
Compiling the Projects
-----

Now lets look at the Projects we need to compile and install in-order to run the system. 

Common Project
------

In order to build the DAMDS project first you will need to build the common project. Common holds some utilities used by other projects in the DSC-SPIDAL project.

Download the project from https://github.com/DSC-SPIDAL/common and build it.

```
git clone https://github.com/DSC-SPIDAL/common.git
cd common
mvn clean install
```

Stock Analysis Project
------
This is the main project for doing the analysis. Download the source from https://github.com/iotcloud/stock-analysis and build.
You will use the scripts inside the bin directory of stock-analysis project to run the analysis.

```
git clone https://github.com/iotcloud/stock-analysis.git
cd stock-analysis
git fetch
git checkout stockbench
mvn clean install
```

DAMDS Project
------

Damds is the MDS algorithm for producing the 3D plots. Download the project from https://github.com/DSC-SPIDAL/damds and checkout the workingmmap branch and build it.

```
git clone https://github.com/DSC-SPIDAL/damds.git
cd damds
git fetch
git checkout workingmmap
mvn clean install
```

MDSasChisq
-----
MDSasChisq project is used by the analysis to transform the 3D points generated by DAMDS so that they can be visualize. 
Download the project from https://github.com/DSC-SPIDAL/MDSasChisq and switch to the ompi1.8.1 branch and build.

```
git clone git@github.iu.edu:skamburu/MDSasChisq.git
cd MDSasChisq
git fetch
git checkout ompi1.8.1
mvn clean install
```

Stock Workflow
----

We first pre-process the data to create distance matrix files that are required by the MDS algorithm. 
Then we apply the MDS algorithm to these files. After this we do some post processing to create the final output.

Pre-Processing
-----

The stock files are obtained from the CRSP database through the Wharton Research Data Services https://wrds-web.wharton.upenn.edu/wrds/

First the input stock file has to be downloaded. This file contains daily stock records for each stock present in the stock exchange.

Format of stock files
-----

The stock input file should contain the following information in a comma delimited csv format.

```
Trading Symbol, Price, Number of Shares Outstanding, Factor to adjust price, Factor to adjust shares
```

At the moment we consider stocks from 2004-01-01 to 2014-Dec-31. The input file name is hard coded in the scripts and you should use the name

2004_2014.csv as the input file name.

PSVectorGenerator
-----

This program creates a file with stocks in a vector format. Each row of the file contains stock identifier, stock cap and daily prices as a vector.
For each data segment of the time series, a separate vector file is created.

```
PermNo,Cap,prices.....
```

DistanceCalculator
-----

Produces a distance file given a vector file. Various measures like correlation, correlation squared, euclidean are implemented as distance measures.

WeightCalculator
-----

Produces a weight matrix file given the vector files.

The preprocessing steps of Vector generation, Distance calculation and WeightCalculation are invoked using the script preproc.sh.

Algorithm
----

We use the MPI version of the MDS algorithm given above to map the distances to 3d space. The algorithm is invoked using the mds_weighted.sh script file.


Post-Processing
----

The post processing includes, tranformation of 3D files generated by damds program, generate histograms for data labeling 

HistoGram
-----

Create a Histogram from the vector files. This histogram can be used to label the classes

PointRotation
-----

This program is used to create a common set of points across all the years to rotate the points.

MDSasChisq
-----

We use this program to transform the point files generated by the MDS to align with a global points.

LabelApply
-----

Apply labels to the final rotated points.

How to Run
---

You need to create a directory with the input data. Right now the script assumes an input file with the name 2004_2014.csv. 
 
```
mkdir STOCK_ANALYSIS
cd STOCK_ANALYSIS
mkdir input
cp [stock_file] input/2004_2014.csv
```

There are files in bin directory that can be used to run the programs.

### Pre-Processing

To run the pre-process steps, use the file preproc.sh. You can change the parameters in this file.

```
sbatch preproc.sh path_to_stocks_base_directory
```

The pre-processing creates the following directories and files.

```
STOCK_ANALYSIS/preproc/global
STOCK_ANALYSIS/preproc/yearly
```

global directory contains the vector files, distance files and weight files for the whole 2004 to 2014 period.

The yearly directory contains the vector files, distance files and weight files for each of the data segments from the 2004 to 2014 period.

### Algorithm

To run the damnds algorithm use the the command.

```
sh mds_weighted.sh path_to_stocks_base_directory
```

The output of the damnds program will be in the folder

```
STOCK_ANALYSIS/mds/weighted 
```

It will have two folders with running the algorithm on global data as well as yearly segments.

```
STOCK_ANALYSIS/mds/weighted/global
STOCK_ANALYSIS/mds/weighted/yearly
```

### Post processing

To run the post-processing steps, use the postproc_all.sh

```
sh postproc_all.sh STOCK_ANALYSIS
```

The post processing will provide the final outputs. They will be in a directory called

```
STOCK_ANALYSIS/postproc
```

Again postproc will contain global and yearly directories.

The final label applied pviz files which are ready to display will be found in

```
STOCK_ANALYSIS/postproc/weighted/yearly/rotate/points/labeled/byhist/pviz
```

Example Run of the Application
----

Here is an example run of the application. We assume you have downloaded and compiled all the projects required. 
In this example run the stockbench and stock-analysis directories are created in the user's home directory.

```
mkdir ~\stockbench
cd ~\stockbench
mkdir input
# assume we have the input file in the home folder
cp ~/2004_2014.csv input/
```

Now we are ready to run the pre-processing steps

```
cd ~\stock-analysis/bin
sbatch preproc.sh ~/stockbench
```

Wait until the job finishes. You can monitor the job by using the squeue command

```
squeue
```

You'll see a output like following indicating your job is still running. i.e ST is R (Running). 

```
JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
  930   general preproc. skamburu  R       0:03      2 j-[097-098]
```

You can monitor the output of the pre-processing steps by looking at the slurm job output file. For example in the above case a file name slurm-930.out is created.

```
tail -f slurm-930.out
```

After the jobs is finished, look at the files to make sure they are created. The preproc files are created inside preproc directory.

```
cd ~\stockbench
# vector files
ls -l preproc/yearly/vectors/
total 17944
-rw-r--r--. 1 skamburu users 9100765 Dec  6 01:51 20040101_20050101.csv
-rw-r--r--. 1 skamburu users 9269864 Dec  6 01:51 20040101_20050108.csv


# distance files
ls -l preproc/yearly/distances/

total 152960
-rw-r--r--. 1 skamburu users 78425288 Dec  6 01:53 20040101_20050101.csv
-rw-r--r--. 1 skamburu users 78200018 Dec  6 01:53 20040101_20050108.csv

# weight files
ls -l preproc/yearly/weights/matrix/
total 152956
-rw-r--r--. 1 skamburu users 78425288 Dec  6 01:57 20040101_20050101.csv
-rw-r--r--. 1 skamburu users 78200018 Dec  6 01:57 20040101_20050108.csv
```

Now lets run the mds algorithm




