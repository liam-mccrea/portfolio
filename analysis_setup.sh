#!/bin/bash

# analysis_setup.sh
# script sets up directories and writes downstream scripts for analysis in instrument and software-specicific storage/analysis locations
# writes hardcoded downstream scripts so no need to keep resetting variables in multiple scripts for each step in the analysis pipeline
# takes three arguments: (1) date (2) experiment name to name directories (3) microscope image storage parent directory name
# usage: bash analysis_setup.sh <date:YYYY.MM.DD> <Experiment_name> <image_storage_parent> <open> (4th = optional to open directories)

# set variables
enclave_id=11961300


# use help to give options if used incorrectly
Help()
{
   # Display Help
   echo "script HELP below."
   echo
   echo "usage: bash folder_setup.sh <date:YYYY.MM.DD> <Experiment_name> <image_storage_parent> <open>"
   echo
   echo "arg1: date"
   echo "arg2: experiment name"
   echo "arg3: image storage parent directory"
   echo "arg4: open folders in finder (or not if no 4th arg)"
   echo
   echo "to choose image parent directory as 3rd arg see the list of options below"
   echo
   ls -l /images/Liam/2024/
   echo
}

while getopts ":h" option; do
   case $option in
      h) # display Help
         Help
         exit;;
   esac
done



#######################  script functions below  #################


# make directories
mkdir -p other_data/Liam_RStudio/$1_$2 
mkdir -p CellProfiler/Liam/Overlay/$1_$2
mkdir -p CellProfiler/Liam/Metadata/$1_$2
mkdir -p images/Liam/2024/$3/$1_$2  
cp /Users/ltm20/Desktop/python_programs/take_columns.py other_data/Liam_RStudio/$1_$2
cp /Users/ltm20/Desktop/python_programs/Process_CSV_refactored.py other_data/Liam_RStudio/$1_$2


# make enclave directories
mkdir /Volumes/import_$enclave_id/$1_$2/
mkdir /Volumes/import_$enclave_id/$1_$2/images


# open directories 
$4 other_data/Liam_RStudio
# $4 CellProfiler/Liam/Overlay
# $4 CellProfiler/Liam/Metadata
$4 images/Liam/2024/$3



# write script 1: transfer images
cat >to_enclave.sh << EOF
#!/bin/bash
# purpose: 1. copies images from image storage to enclave import drive.
# usage: to_enclave.sh 

cp /Volumes/MGH-PERLISDATA/CellProfiler/Liam/Pipelies/*$2* /Volumes/import_$enclave_id/$1_$2
cp -r ./* /Volumes/import_$enclave_id/$1_$2/images
# mv -r /Volumes/import_$enclave_id/$1_$2/images /data/workspace/$1_$2/images # I don't know how to do this yet, its own script for now

echo
echo
echo "files copied to enclave import drive."
echo
echo

EOF
chmod +x to_enclave.sh
cp to_enclave.sh /Volumes/MGH-PERLISDATA/INCell/Liam/2021/$3/$1_$2



# write script 2: set up workspace on remote desktop
cat >to_workspace.sh << EOF1
#!/bin/bash
# purpose: 1. to make enclave workspace directories 2. to move images from import drive to enclave workspace.
# usage: to_workspace.sh 

mkdir /data/workspace/$1_$2
mkdir /data/workspace/$1_$2/output
mkdir /data/workspace/$1_$2/output/overlays
mkdir /data/workspace/$1_$2/output/metadata
mv ./* /data/workspace/$1_$2/

mkdir /data/export/$1_$2/
mkdir /data/export/$1_$2/overlays
mkdir /data/export/$1_$2/metadata
cp /data/import/$1_$2/to_export.sh /data/export/$1_$2/

echo
echo
echo "files moved to enclave workspace."
echo
echo


EOF1
chmod +x to_workspace.sh
# copy the new script for the next step
cp to_workspace.sh /Volumes/import_$enclave_id/$1_$2/



# write script 3: export back from remote desktop
cat >to_export.sh << EOF2
#!/bin/bash
# purpose: 1. to move enclave cellprofiler output to enclave export drive
# usage: to_export.sh 

mv /data/workspace/$1_$2/output/overlays/* ./overlays/
cp /data/workspace/$1_$2/output/metadata/* ./metadata/
cp /data/workspace/$1_$2/*.cpproj .


echo
echo "files copied to enclave export drive."
echo

rm -r /data/workspace/$1_$2/images
rm -r /data/workspace/$1_$2/output/overlays

echo
echo "image files deleted from workspace."
echo

EOF2
chmod +x to_export.sh
# copy the new script for the next step
cp to_export.sh /Volumes/import_$enclave_id/$1_$2/



# write script 4: clean resulting data output
cat >start_analysis.sh << EOF3
#!/bin/bash
# purpose: 1. copies metadata 2. runs python program to trim csv's  3. clears enclave storage
# usage: start_analysis.sh

cp /Volumes/export_$enclave_id/$1_$2/metadata/*.csv CellProfiler/Liam/Metadata/$1_$2/
cp /Volumes/export_$enclave_id/$1_$2/overlays/* CellProfiler/Liam/Overlay/$1_$2/
cp /Volumes/export_$enclave_id/$1_$2/*.cpproj CellProfiler/Liam/Pipelines/
cp CellProfiler/Liam/Metadata/$1_$2/*Cells*.csv .
cp CellProfiler/Liam/Metadata/$1_$2/*SYN*.csv .
rm CellProfiler/Liam/Metadata/$1_$2/*ALLCells*.csv 

echo
echo "files copied."
echo
echo "starting python program."
echo

python3 Process_CSV_refactored.py

echo 
echo "program finished."
echo
echo "clearing enclave space."
echo 

rm -r /Volumes/export_$enclave_id/$1_$2/overlays
rm -r /Volumes/import_$enclave_id/$1_$2

echo "done."
echo

EOF3
chmod +x start_analysis.sh
# copy the new script for the next step
cp start_analysis.sh /Volumes/MGH-PERLISDATA/other_data/Liam_RStudio/$1_$2 



####### finished ##########

echo
echo 
echo "1. experiment subdirectories created in microscope, CellProfiler, R analysis, and enclave directories. " 
echo 
echo "2. custom bash script 'to_enclave.sh' copied to image storage folder."
echo
echo "3. custom bash scripts 'to_workspace.sh' and to_export.sh copied to enclave for use on this remote desktop. "
echo
echo "4. custom bash script 'start_analysis.sh' copied to R analysis folder. "
echo 
echo "            script complete."
echo
echo



