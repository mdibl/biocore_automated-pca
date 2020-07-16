#!/bin/bash
# Calls for each step in the automated PCA pipeline

### Check that the user gave the right number of arguments (2) in the terminal ###
if [ "$#" -ne 4 ]; then
    echo "--- Error. Illegal number of parameters"
    echo "Please give 4 arguments when calling the bash:"
    echo "Argument 1 : path to the script directory where the R scripts are stored"
    echo "Argument 2 : path to the data directory where your data, design, count files are stored"
    echo "Argument 3 : path to the analysis directory where your results will be stored"
    echo "Argument 4 : name of the json input file"
    exit 1
fi

### Assign the command arguments ###
SCRIPT_DIR=$1
DATA_DIR=$2
ANALYSIS_DIR=$3
JSON_FILE_NAME=$4

### Check that all directories exist ###

# Check for the script directory
if [ -d ${SCRIPT_DIR} ] 
then
    echo "Directory ${SCRIPT_DIR} exists." 
else
    echo "Error: Directory ${SCRIPT_DIR} does not exist."
    exit 1
fi

# Check for the data directory
if [ -d ${DATA_DIR} ] 
then
    echo "Directory ${DATA_DIR} exists." 
else
    echo "Error: Directory ${DATA_DIR} does not exist."
    exit 1
fi

# Check for the analysis directory
if [ -d ${ANALYSIS_DIR} ] 
then
    echo "Directory ${ANALYSIS_DIR} exists." 
else
    echo "Error: Directory ${ANALYSIS_DIR} does not exist."
    exit 1
fi

### Check that json file exists (argument 2) ###
if [ -f ${JSON_FILE_NAME} ] 
then
    echo "File ${JSON_FILE_NAME} exists." 
else
    echo "Error: File ${JSON_FILE_NAME} does not exists or is not stored in the right location."
    exit 1
fi


### Create folders to store the outputs ###

echo "*** Create a report folder if it does not exist ***"
if [ ! -d ${ANALYSIS_DIR}/report ] 
then
    mkdir -p ${ANALYSIS_DIR}/report
fi 


echo "*** Create a results folder if it does not exist ***"
if [ ! -d ${ANALYSIS_DIR}/results ] 
then
    mkdir -p ${ANALYSIS_DIR}/results
fi 

echo "*** Create a figures folder if it does not exist ***"
if [ ! -d ${ANALYSIS_DIR}/figures ] 
then
    mkdir -p ${ANALYSIS_DIR}/figures
fi 


DATA_FOLDER=${DATA_DIR}
SCRIPTS_FOLDER=${SCRIPT_DIR}
REPORT_FOLDER=${ANALYSIS_DIR}pca_report/
RESULTS_FOLDER=${ANALYSIS_DIR}pca_results/
FIGURES_FOLDER=${ANALYSIS_DIR}pca_figures/

JSON_PATH=$JSON_FILE_NAME


echo "********************************************"
echo File paths provided
echo data folder: ${DATA_FOLDER}
echo report folder: ${REPORT_FOLDER}
echo scripts folder: ${SCRIPTS_FOLDER}
echo results folder: ${RESULTS_FOLDER}
echo json path: ${JSON_PATH}

echo "********************************************"
echo Entering step_00.R
Rscript ${SCRIPTS_FOLDER}step_00.R
if [ $? != 0 ]; then
  echo "script00.R failed"
  exit 0
fi
echo Leaving step_00.R

echo "********************************************"
echo Entering step_01.R
Rscript ${SCRIPTS_FOLDER}step_01.R ${JSON_PATH}
if [ $? != 0 ]; then
  echo "script01.R failed"
  exit 0
fi
echo Leaving step_01.R

echo "********************************************"
echo Entering step_02.R
Rscript ${SCRIPTS_FOLDER}step_02.R ${JSON_PATH}
if [ $? != 0 ]; then
  echo "script02.R failed"
  exit 0
fi
echo Leaving step_02.R

echo "********************************************"
echo Entering step_03.R
Rscript ${SCRIPTS_FOLDER}step_03.R ${JSON_PATH}
if [ $? != 0 ]; then
  echo "script03.R failed"
  exit 0
fi
echo Leaving step_03.R

echo "********************************************"
echo Entering step_04.R
Rscript ${SCRIPTS_FOLDER}step_04.R ${JSON_PATH}
if [ $? != 0 ]; then
  echo "script04.R failed"
  exit 0
fi
echo Leaving step_04.R

echo "********************************************"
echo Entering step_05.R
Rscript ${SCRIPTS_FOLDER}step_05.R ${JSON_PATH}
if [ $? != 0 ]; then
  echo "script05.R failed"
  exit 0
fi
echo Leaving step_05.R

echo "********************************************"
echo Entering step_06.R
Rscript ${SCRIPTS_FOLDER}step_06.R ${JSON_PATH}
if [ $? != 0 ]; then
  echo "script06.R failed"
  exit 0
fi
echo Leaving step_06.R

echo "********************************************"
echo Entering step_07.R
Rscript ${SCRIPTS_FOLDER}step_07.R ${JSON_PATH}
if [ $? != 0 ]; then
  echo "script07.R failed"
  exit 0
fi
echo Leaving step_07.R

echo "********************************************"
echo Entering automated_report.R
echo "*** This script calls an R markdown that will save an automated report file in the report folder ***"
Rscript ${SCRIPTS_FOLDER}automated_report.R ${JSON_PATH}
if [ $? != 0 ]; then
  echo "automated_report.R failed"
  exit 0
fi
echo Leaving automated_report.R

