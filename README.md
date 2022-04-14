## BBE: Basin-Based Evaluation of Multimodal Multi-Objective Optimization Problems

This repository contains the experimental pipeline and analysis for our paper. 

Automated algorithm configuration and optimization runs were conducted with help of a compute cluster running SLURM. 
We used [PALMA](https://confluence.uni-muenster.de/display/HPC/) the high performance compute cluster of the University of Münster.
In case of need to reproduce the full experimental pipeline, please make sure to modify the scripts such that they can run on your compute environment.

## Procedure to fully run the experimental pipeline
```
cd experiments/01references/
./compute_references.R
cp refdata.Rdata ../../_shared/
cd ../../resources/algorithms
./distribute_shared_files.sh
#Now you can test if each algorithm works
cd ../../experiments/05lofconfiguration
./run_experiment.sh #Prepares all the configuration experiments
./joblauncher.py #Schedules all the configurations while keeping the joblimit under control
#Once all jobs are finished; do
./do_validation.py
#Once all jobs are finished; do
./make_result_table.py #this creates results.csv 
#Run the Jupyter notebooks in 'experiments/04configurationfast' to obtain the figures presented in the paper
```

Alternatively, just the `experiments/05lofconfiguration/results.csv` can be used to work with the provided notebooks. 
