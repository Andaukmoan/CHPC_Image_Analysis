### This repository is for the basics of running our image analysis pipeline on the University of Utah's CHPC.

In order to use PaternaBio's allocation on the Redwood cluster, you will need to get an account with CHPC, complete their protected enivronment(PE) application, ask for access to proj_paternabio (redwood cluster), and ask for access to submit batches to paternabio-rw.
More details for setting up your CHPC account can be found on their website. ([CHPC Documentation](https://www.chpc.utah.edu/documentation/gettingstarted.php))

# Setup

Install stardist:

The dependencies for stardist are in the module "deeplearning/2022.1"
```
module load deeplearning/2022.1
```
You will then need to install stardist into your home directory with deeplearning/2022.1 loaded into the environment.
1. Set user base to your home directory if not already set.
```
export PYTHONUSERBASE=/uufs/chpc.utah.edu/common/HIPAA/<your ID>
```
2. Install stardist to user directory (you can't write to the deeplearning/2022.1 module which is the default directory for pip install when the module is loaded).
```
python -m pip install --user stardist
```

# Submit batch

The pipelines from this repository can be found in proj_paternabio/image_analysis/slurm.
```
cd /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/slurm
```

Open the pipeline you are going to run.

Example:
```
nano DDX4_EdU_batch.sh
```

Set "#SBATCH --mail-user=" to your email. You will receive emails when jobs start and finish.

Set "INIMG=" to the location of the images you are analyzing. This pipeline assumes only files that need to be analyzed are in that folder. Remove any files in the folder that are not meant to be analyzed before running the script. Most often the issue comes from jpg and scanprotocol files. You can remove them using:
```
cd /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/image_analysis/images/<your folder>
rm *.jpg
rm *.scanprotocol
```

Set "OUTXL=" to the location for your output. This should be a unique location so that files from multiple analysis are not merged in the output. The pipeline will make the directory if it does not yet exist.

Press ctrl+X to leave the file. Save it with a unique file name to create a record of analyses that have been run and prevent making unintended changes to the base file.

Set the permissions of your new file to be executable:
```
chmod 755 <your_file_name>
```

Run your analysis:
```
sbatch <your_file_name>
```

Your analysis will be added to the queue and you will receive an email that it has started running. 

You can check the status of your analysis in the queue with:
```
squeue
```
or
```
squeue --account=paternabio-rw
```

When your run is finished, you will receive an email and a slurm output file will be generated. You can check this file for information about how your job ran and to troubleshoot errors.
```
nano slurm-<jobID>.out
```

The output will be in a subfolder of the output path you gave named "counts". There will be three files that hold the raw output from cellprofiler for the whole data set. 

    1. The cell counts from your analysis will be named <date>_<time>_<pipeline>_all_images.csv.  

    2. The cell relationships for colony counts will be named <data>_<time>_<pipeline>_object_relationships.csv.
    
    3. The measurements for the cells will be named <data>_<time>_<pipeline>_filtered_nuclei.csv.
For example:

    1. 2024-03-15_09-49-57_DDX4_EdU_all_images.csv
    2. 2024-03-15_09-50-03_DDX4_EdU_object_relationships.csv
    3. 2024-03-15_09-50-04_DDX4_EdU_filtered_nuclei.csv
There will also be four formatted counts files per unique plate name in the data set:

    1. Raw cell counts
    
    2. Cell counts per well
    
    3. Raw colony counts
    
    4. Colony counts per well

Download all the results by putting this code with your specific details into your terminal:
```
scp -r /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/<your output path>/counts <path to where you want to save it to your device>
```
For example:
```
scp -r /uufs/chpc.utah.edu/common/HIPAA/proj_paternabio/user/SLURM/output/test_stardist/counts /Users/user/Desktop
```

The results can then be uploaded to google drive and used for downstream analysis or visualization.  


