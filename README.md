#This repository is for the basics of running our image analysis pipeline on the University of Utah's CHPC.

In order to use PaternaBio's allocation on the Redwood cluster, you will need to get an account with CHPC and complete their protected enivronment(PE) application.
There are more details for setting up your CHPC account that can be found on their website.

#Stardist
The dependencies for stardist are in the module "deeplearning/2022.1"
```
module load deeplearning/2022.1
```
You will then need to install stardist into your home directory.
1. Set user base to your home directory if not already set
```
export PYTHONUSERBASE=/uufs/chpc.utah.edu/common/HIPAA/<your ID>
```
2. Install stardist
```
python -m pip install --user stardist
```

#CellProfiler
CHPC staff set up a CellProfiler module for us. You just have to load it.
```
module load cellprofiler
```
