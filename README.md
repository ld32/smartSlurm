=============================
# SmartSlurm

- [Smart sbatch](#smart-sbatch)
    - [ssbatch features](#ssbatch-features)
    - [How to use ssbatch](#how-to-use-ssbatch)
    - [How does ssbatch work](#how-does-ssbatch-work) 
      
- [Use ssbatch in Snakemake pipeline](#Use-ssbatch-in-Snakemake-pipeline)

- [Use ssbatch in Cromwell pipeline](#Use-ssbatch-in-Cromwell-pipeline])

- [Use ssbatch in Nextflow pipeline](#Use-ssbatch-in-Nextflow-pipeline)

- [Run bash script as smart pipeline using smart sbatch](#Run-bash-script-as-smart-pipeline-using-smart-sbatch)
    - [Smart pipeline features](#smart-pipeline-features)
    - [How to use smart pipeline](#how-to-use-smart-pipeline)
    - [How does smart pipeline work](#how-does-smart-pipeline-work)

- [sbatchAndTop](#sbatchAndTop)


# Smart sbatch
[Back to top](#SmartSlurm)

ssbath was originally designed to run https://github.com/ENCODE-DCC/atac-seq-pipeline, so that users don't have to modify the original workflow and ssbatch can automatially modify the partitions according user's local cluster partition settings. The script was later improved to have more features.

![](https://github.com/ld32/smartSlurm/blob/main/stats/back/findNumber.none.time.png)

##As the figure shown above, the memory usage is roughly co-related to the input size. We can use input size to allocate memory when submit new jobs.

![](https://github.com/ld32/smartSlurm/blob/main/stats/back/barchartMem.png)

##As the figure shown above, Ssbatch runs the first 5 jobs, it use default memory, then based on the first five jobs, it estimates memory for future jobs. The wasted memory is dramatially decreased for the future jobs.

![](https://github.com/ld32/smartSlurm/blob/main/stats/back/barchartTime.png)

##As the figure shown above, Ssbatch runs the first 5 jobs, it use default time, then based on the first five jobs, it estimates time future jobs. The wasted time is dramatially decreased for the future jobs.

## ssbatch features:
[Back to top](#SmartSlurm)

1) Auto adjust memory and run-time according to statistics from earlier jobs
2) Auto choose partition according to run-time request
3) Auto re-run failed OOM (out of memory) and OOT (out of run-time) jobs
4) (Optional) Generate checkpoint before job runs out of time or memory, and use the checkpoint to re-run jobs.
5) Get good emails: by default Slurm emails only have a subject. ssbatch attaches the content of the sbatch script, the output and error log to email

## How to use ssbatch
[Back to top](#SmartSlurm)

``` bash
# Download 
cd $HOME
git clone https://github.com/ld32/smartSlurm.git  

# Setup path
export PATH=$HOME/smartSlurm/bin:$PATH  

# Create 5 files with numbers for testing
createNumberFiles.sh

# Run 3 jobs to get memory and run-time statistics for script findNumber.sh
# findNumber is just a random name. You can use anything you like.

ssbatch --mem 2G -t 2:0:0 -P findNumber -I numbers3.txt -F numberFile3 \
    --wrap="findNumber.sh 1234 numbers3.txt"

ssbatch --mem 2G -t 2:0:0 -P findNumber -I numbers4.txt -F numberFile4 \
    --wrap="findNumber.sh 1234 numbers4.txt"

ssbatch --mem 2G -t 2:0:0 -P findNumber -I numbers5.txt -F numberFile5 \
    --wrap="findNumber.sh 1234 numbers5.txt"

# After the 5 jobs finish, when submitting more jobs, ssbatch auto adjusts 
# memory and run-time according input file size
# Notice: this command submits the job to short partition, and reserves 21M memory 
# and 13 minute run-time 
ssbatch --mem 2G -t 2:0:0 -P findNumber -I numbers1.txt -F numberFile1 \
    --wrap="findNumber.sh 1234 numbers1.txt"

# You can have multiple inputs: 
ssbatch --mem 2G -t 2:0:0 -P findNumber -I "numbers1.txt numbers2.txt" 
    -F numberFile12 --wrap="findNumber.sh 1234 numbers1.txt numbers2.txt"

# If input file is not given for option -I. ssbatch will choose the memory 
# and run-time threshold so that 90% jobs can finish successfully
ssbatch --mem 2G -t 2:0:0 -P findNumber -F numberFile2 \
    --wrap="findNumber.sh 1234 numbers2.txt"

# check job status: 
checkRun

# cancel all jobs submitted from the current directory
cancelAllJobs 

# rerun jobs: 
# when re-run a job with the same flag (option -F), if the previous run was successful, 
# ssbatch will ask to confirm you do want to re-run
ssbatch --mem 2G -t 2:0:0 -P findNumber -I numbers1.txt -F numberFile1 \
    --wrap="findNumber.sh 1234 numbers1.txt"

```

## How does ssbatch work    
[Back to top](#SmartSlurm)

1) Auto adjust memory and run-time according to statistics from earlier jobs

$smartSlurmJobRecordDir/jobRecord.txt contains job memory and run-time records. There are three important columns: 
   
   1st colume is job ID
   
   2rd colume is input size
   
   7th column is actual memory usage
   
   8th column is actual time usage
   
The data from the three columns are plotted and statistics  
__________________________________________________________________________________________________________________   
1jobID,2inputSize,3mem,4time,5mem,6time,7mem,8time,9status,10useID,11path,12software,13reference

46531,1465,4G,2:0:0,4G,0-2:0:0,3.52,1,COMPLETED,ld32,,findNumber,none

46535,2930,4G,2:0:0,4G,0-2:0:0,6.38,2,COMPLETED,ld32,,findNumber,none

46534,4395,4G,2:0:0,4G,0-2:0:0,9.24,4,COMPLETED,ld32,,findNumber,none

\#Here is the input size vs memory plot for findNumber: 

![](https://github.com/ld32/smartSlurm/blob/main/stats/back/findNumber.none.mem.png)

\#Here is the input size vs run-time plot for findNumber: 

![](https://github.com/ld32/smartSlurm/blob/main/stats/back/findNumber.none.time.png)

\#Here is the run-time vs memory plot for findNumber: 

![](https://github.com/ld32/smartSlurm/blob/main/stats/back/findNumber.none.stat.noInput.png)

2) Auto choose partition according to run-time request

smartSlrm/config/config.txt contains partion time limit and bash function adjustPartition to adjust partion for sbatch jobs: 

\# Genernal partions, ordered by maximum allowed run-time in hours 

partition1Name=short; partition1TimeLimit=12  # run-time > 0 hours and <= 12 hours 

partition2Name=medium; partition2TimeLimit=120 # run-time > 12 hours and <= 5 days

partition3Name=long; partition3TimeLimit=720 # run-time > 5 days and <= 30 days

...        

\#function 

adjustPartition() {         
    ... # please open the file to see the content         
} ; export -f adjustPartition 

3) Auto re-run failed OOM (out of memory) and OOT (out of run-time) jobs
    
    At end of the job, $smartSlurmJobRecordDir/bin/cleanUp.sh checkes memory and time usage, save the data in to log $smartSlurmJobRecordDir/myJobRecord.txt. If job fails, ssbatch re-submit with double memory or double time, clear up the statistic fomular, so that later jobs will re-caculate statistics, 

4) Checkpoint
    
    If checkpoint is enabled, before the job run out of memory or time, ssbatch generate checkpoint and resubmit the job.

5) Get good emails: by default Slurm emails only have a subject. ssbatch attaches the content of the sbatch script, the output and error log to email

    $smartSlurmJobRecordDir/bin/cleanUp.sh also sends a email to user. The email contains the content of the Slurm script, the sbatch command used, and also the content of the output and error log files.


# Use ssbatch in Snakemake pipeline
[Back to top](#SmartSlurm)

``` bash
# Download smartSlurm if it is not done yet 
cd $HOME
git clone https://github.com/ld32/smartSlurm.git  
export PATH=$HOME/smartSlurm/bin:$PATH

cp $HOME/smartSlurm/bin/Snakefile .
cp $HOME/smartSlurm/bin/config.yaml .

# Create Snakemake conda env (from: https://snakemake.readthedocs.io/en/v3.11.0/tutorial/setup.html)
module load miniconda3
mamba env create --name snakemakeEnv --file $PWD/smartSlurm/config/snakemakeEnv.yaml

# Review Snakefile, activate the snakemake env and run test
module load miniconda3
source activate snakemakeEnv
export PATH=$PWD/smartSlurm/bin:$PATH
cat Snakefile
snakemake -p -j 999 --latency-wait=80 --cluster "ssbatch -t 100 --mem 1G -p short"

If you have multiple Slurm account:
snakemake -p -j 999 --latency-wait=80 --cluster "ssbatch -A mySlurmAccount -t 100 --mem 1G"

```

# Use ssbatch in Cromwell pipeline
[Back to top](#SmartSlurm)

``` bash
# Download (only need download once)
cd $HOME
git clone https://github.com/ld32/smartSlurm.git  

# Setup path
export PATH=$HOME/smartSlurm/bin:$PATH  

# Create some text files for testing
createNumberFiles.sh

# Use ssbatch to replace regular sbatch, set up a fuction. 
# This way, whenever you run sbatch, ssbatch is called. 
sbatch() { $HOME/smartSlurm/bin/ssbatch "$@"; }; export -f sbatch                                 

# Run 3 jobs to get memory and run-time statistics for findNumber
for i in {1..3}; do
    sbatch --mem 2G -t 2:0:0 --commen="S=findNumber" \
        --wrap="findNumber.sh $i"
done

# After the 3 jobs finish, when submitting more jobs, ssbatch auto adjusts memory 
# and run-time so that 90% jobs can finish successfully
# Notice: this command submits this job to short partition, and reserves 19M memory and 7 minute run-time 
sbatch --mem 2G -t 2:0:0 --mem 2G --commen="S=findNumber" --wrap="findNumber.sh 1"

# Run 3 jobs to get memory and run-time statistics for findNumber
for i in {1..3}; do
    sbatch -t 2:0:0 --mem 2G --commen="S=findNumber I=bigText$i.txt" \
        --wrap="findNumber.sh bigText$i.txt"
done

# After the 5 jobs finish, when submitting more jobs, ssbatch auto adjusts memory and run-time according input file size
# Notice: this command submits the job to short partition, and reserves 21M memory and 13 minute run-time 
sbatch -t 2:0:0 --mem 2G --commen="S=findNumber \
    I=bigText1.txt,bigText2.txt" --wrap="findNumber.sh bigText1.txt bigText2.txt"

# The second way to tell the input file name: 
sbatch -t 2:0:0 --mem 2G job.sh

cat job.sh
#!/bin/bash
#SBATCH --commen="S=findNumber I=bigText1.txt,bigText2.txt"
findNumber.sh bigText1.txt bigText$2.txt

# After you finish using ssbatch, run these command to disable ssbatch:    
unset sbatch

```

# Use ssbatch in Nextflow pipeline
[Back to top](#SmartSlurm)

``` bash
# Download smartSlurm if it is not done yet 
cd $HOME
git clone https://github.com/ld32/smartSlurm.git  

# Create Nextflow conda env
module load miniconda3
mamba create -n  nextflowEnv -c bioconda -y nextflow

# Review nextflow file, activate the nextflow env and run test
module load miniconda3
export PATH=$HOME/smartSlurm/bin:$PATH  
source activate nextflowEnv
cp $HOME/smartSlurm/bin/nextflow.nf .
cp $HOME/smartSlurm/config/nextflow.config .

# If you have multiple Slurm account, modify the config file:
nano nextflow.config

#change:
//process.clusterOptions = '--account=mySlurmAcc'
to 
process.clusterOptions = '--account=mySlurmAcc'

# save the file 

# Ready to run:
nextflow run nextflow.nf -profile slurm

```
# Run bash script as smart pipeline using smart sbatch
[Back to top](#SmartSlurm)

Smart pipeline was originally designed to run bash script as pipelie on Slurm cluster. We added dynamic memory/run-time feature to it and now call it Smart pipeline. The runAsPipeline script converts an input bash script to a pipeline that easily submits jobs to the Slurm scheduler for you.

\#Here is the memeory usage by the optimzed workflow: The orignal pipeline has 11 steps. Most of the steps only need less than 10G memory to run. But one of the step needs 140G. Because the original pipeline is submitted as a single huge job, 140G is reserved for all the steps. (Each compute node in the cluster has 256 GB RAM.) By submitting each step as a separate job, most steps only need to reserve 10G, which decreases the memory usage dramatically. (The pink part of the graph below shows these savings.) Another optimization is to dynamically allocate memory based on the reference genome size and input sequencing data size. (This in shown in the yellow part of the graph.)
Because of the decreased resource demand, the jobs can start earlier, and in turn increase the overall throughput.

![](https://github.com/ld32/smartSlurm/blob/main/stats/back/barchartMemSaved.png)

## smart pipeline features:
[Back to top](#SmartSlurm)

1) Submit each step as a cluster job using ssbatch, which auto adjusts memory and run-time according to statistics from earlier jobs, and re-run OOM/OOT jobs with doubled memory/run-time
2) Automatically arrange dependencies among jobs
3) Email notifications are sent when each job fails or succeeds
4) If a job fails, all its downstream jobs automatically are killed
5) When re-running the pipeline on the same data folder, if there are any unfinished jobs, the user is asked to kill them or not
6) When re-running the pipeline on the same data folder, the user is asked to confirm to re-run or not if a job or a step was done successfully earlier
7) For re-run, if the script is not changed, runAsPipeline does not re-process the bash script and directly use old one
8) If user has more than one Slurm account, adding -A or —account= to command line to let all jobs to use that Slurm account
9) When adding new input data and re-run the workflow, affected successfully finished jobs will be auto re-run.Run bash script as smart slurm pipeline

## How to use smart pipeline
[Back to top](#SmartSlurm)

``` bash
# Download if it is not downlaod yet
cd $HOME
git clone https://github.com/ld32/smartSlurm.git  

# Setup path
export PATH=$HOME/smartSlurm/bin:$PATH  

# Take a look at a regular exmaple bash script
cat $HOME/smartSlurm/scripts/bashScriptV1.sh

# Below is the content of a regular bashScriptV1.sh 
 1 #!/bin/sh
 2
 3 number=$1
 4
 5 [ -z "$number" ] && echo -e "Error: number is missing.\nUsage: bashScript <numbert>" && exit 1
 6
 7 for i in {1..5}; do
 8
 9     input=numbers$i.txt
10
11     findNumber.sh 1234 $input > $number.$i.txt
12
13 done
14
15 cat $number.*.txt > all$number.txt


# Notes about bashScriptV1.sh: 
#The script first finds a certain nubmer given from commandline in file numbers1.txt until numbers5.txt in row 11, then merges the results into all.txt in orow 15 

# In order tell smart pipeline which step/command we want to submit as Slurm jobs, 
# we add comments above the commands also some helping commands:  
cat $HOME/smartSlurm/scripts/bashScriptV2.sh

# below is the content of bashScriptV2.sh
 1 #!/bin/sh
 2
 3 number=$1
 4
 5 [ -z "$number" ] && echo -e "Error: number is missing.\nUsage: bashScript <numbert>" && exit     1
 6
 7 for i in {1..5}; do
 8
 9     input=numbers$i.txt
10
11     #@1,0,findNumber,,input,sbatch -p short -c 1 --mem 2G -t 50:0
12     findNumber.sh 1234 $input > $number.$i.txt
13
14 done
15
16 #@2,1,mergeNumber,,,sbatch -p short -c 1 --mem 2G -t 50:0
17 cat $number.*.txt > all$number.txt
   
```

## Notice that there are a few things added to the script here:
[Back to top](#SmartSlurm)

Step 1 is denoted by #@1,0,findNumber,,input,sbatch -p short -c 1 --mem 2G -t 2:0:0 (line 11 above), which means this is step 1 that depends on no other step, run software findNumber, use the value of $i as unique job identifier for this this step, does not use any reference files, and file $input is the input file, needs to be copied to the /tmp directory if user want to use /tmp. The sbatch command tells the pipeline runner the sbatch parameters to run this step.

Step 2 is denoted by #@2,1,findNumber,,input (line 16), which means that this is step1 that depends on step1, and the step runs software mergeNumber with no reference file, does not need unique identifier because there is only one job in the step, and use $input as input file. Notice, there is no sbatch here,  so the pipeline runner will use default sbatch command from command line (see below).   

Notice the format of step annotation is #@stepID,dependIDs,sofwareName,reference,input,sbatchOptions. Reference is optional, which allows the pipeline runner to copy data (file or folder) to local /tmp folder on the computing node to speed up the software. Input is optional, which is used to estimate memory/run-time for the job. sbatchOptions is also optional, and when it is missing, the pipeline runner will use the default sbatch command given from command line (see below).

Here are two more examples:

#@4,1.3,map,,in,sbatch -p short -c 1 -t 2:0:0  #Means step4 depends on step1 and step3, this step run software 'map', there is no reference data to copy, there is input $in and submits this step with sbatch -p short -c 1 -t 2:0:0

#@3,1.2,align,db1.db2   # Means step3 depends on step1 and step2, this step run software 'align', $db1 and $db2 are reference data to be copied to /tmp , there is no input and submit with the default sbatch command (see below).

# Test run the modified bash script as a pipeline
[Back to top](#SmartSlurm)

```
runAsPipeline bashScriptV2.sh "sbatch -p short -t 10:0 -c 1" useTmp

```

This command will generate new bash script of the form slurmPipeLine.checksum.sh in log folder. The checksum portion of the filename will have a MD5 hash that represents the file contents. We include the checksum in the filename to detect when script contents have been updated. If it is not changed, we don not re-create the pipeline script.

This runAsPipeline command will run a test of the script, meaning does not really submit jobs. It will only show a fake job ids like 1234 for each step. If you were to append run at the end of the command, the pipeline would actually be submitted to the Slurm scheduler.

Ideally, with useTmp, the software should run faster using local /tmp disk space for database/reference than the network storage. For this small query, the difference is small, or even slower if you use local /tmp. If you don't need /tmp, you can use noTmp.

With useTmp, the pipeline runner copy related data to /tmp and all file paths will be automatically updated to reflect a file's location in /tmp when using the useTmp option. 
Sample output from the test run

Note that only step 2 used -t 2:0:0, and all other steps used the default -t 10:0. The default walltime limit was set in the runAsPipeline command, and the walltime parameter for step 2 was set in the bash_script_v2.sh script.
runAsPipeline bashScriptV2.sh "sbatch -p short -t 10:0 -c 1" useTmp

# here is the outputs:
[Back to top](#SmartSlurm)

```
runAsPipeline "bashScriptV2.sh 1234" "sbatch -p short -t 10:0 -c 1" useTmp run


runAsPipeline run date: 2024-04-28_16-03-36_4432
Running: /home/ld32/smartSlurm/bin/runAsPipeline /home/ld32/smartSlurm/scripts/bashScriptV2.sh 1234
    sbatch -A rccg -p short -c 1 --mem 2G -t 50:0 noTmp run

Converting /home/ld32/smartSlurm/scripts/bashScriptV2.sh to 
    /home/ld32/scratch/smartSlurmTest/log/slurmPipeLine.eccd33a67760d5928f1c4cfea17ae574.run.sh

find for loop start: for i in {1..5}; do

find job marker:
#@1,0,findNumber,,input,sbatch -p short -c 1 --mem 2G -t 50:0
sbatch options: sbatch -p short -c 1 --mem 2G -t 50:0

find job:
findNumber.sh 1234 $input > $number.$i.txt
findNumber.sh 1234 $input > $number.$i.txt --before parsing
findNumber.sh 1234 $input > $number.$i.txt --after parseing

find loop end: done

find job marker:
#@2,1,mergeNumber,,,sbatch -p short -c 1 --mem 2G -t 50:0
sbatch options: sbatch -p short -c 1 --mem 2G -t 50:0

find job:
cat $number.*.txt > all$number.txt
cat $number.*.txt > all$number.txt --before parsing
cat $number.*.txt > all$number.txt --after parseing
/home/ld32/scratch/smartSlurmTest/log/slurmPipeLine.
    7ae574.run.sh /home/ld32/smartSlurm/scripts/bashScriptV2.sh is ready to run. Starting to run ...
Running /home/ld32/scratch/smartSlurmTest/log/slurmPipeLine.7ae574.run.sh 
    /home/ld32/smartSlurm/scripts/bashScriptV2.sh

---------------------------------------------------------

step: 1, depends on: 0, job name: findNumber, flag: 1.0.findNumber.1
Got output from ssbatch: Submitted batch job 69308

step: 1, depends on: 0, job name: findNumber, flag: 1.0.findNumber.2
Got output from ssbatch: Submitted batch job 69309

step: 1, depends on: 0, job name: findNumber, flag: 1.0.findNumber.3
Got output from ssbatch: Submitted batch job 69310

step: 1, depends on: 0, job name: findNumber, flag: 1.0.findNumber.4
Got output from ssbatch: Submitted batch job 69311

step: 1, depends on: 0, job name: findNumber, flag: 1.0.findNumber.5
Got output from ssbatch: Submitted batch job 69312

step: 2, depends on: 1, job name: mergeNumber, flag: 2.1.mergeNumber
Got output from ssbatch: Submitted batch job 69313

All submitted jobs:

job_id       depend_on              job_flag     software    reference  inputs
69308       null                  1.0.findNumber.1 findNumber none       ,numbers1.txt
69309       null                  1.0.findNumber.2 findNumber none       ,numbers2.txt
69310       null                  1.0.findNumber.3 findNumber none       ,numbers3.txt
69311       null                  1.0.findNumber.4 findNumber none       ,numbers4.txt
69312       null                  1.0.findNumber.5 findNumber none       ,numbers5.txt
69313       69308:69309:69310:69311:69312  2.1.mergeNumber mergeNumber none       none
---------------------------------------------------------
Please check .smartSlurm.log for detail logs.

You can use the command:
ls -l log

This command list all the logs created by the pipeline runner. *.sh 
    files are the slurm scripts for each step, *.out files are output files 
    for each step, *.success files means job successfully finished for each 
    step and *.failed means job failed for each steps.

You can use the command to cancel running and pending jobs:
cancelAllJobs 

```

In case you wonder how it works, here is a simple example to explain.

## How does smart pipeline work
[Back to top](#SmartSlurm)

runAsPipeline goes through the bash script, read the for loop and job decorators, 
    set up slurm script for each step and job dependencies, and submit the jobs.  

=======

# sbatchAndTop
## How to use sbatchAndTop
[Back to top](#SmartSlurm)

```
cd ~    
git clone git@github.com:ld32/smartSlurm.git  
export PATH=$HOME/smartSlurm/bin:$PATH    
sbatchAndTop <sbatch option1> <sbatch option 2> <sbatch option 3> <...> 

# Such as:    
sbatchAndTop -p short -c 1 -t 2:0:0 --mem 2G --wrap "my_application para1 para2" 
# Here -p short is optional, because ssbatch chooses partition according to run time.  

# or:     
sbatchAndTop job.sh 

## sbatchAndTop features:
1) Submit slurm job using ssbatch (scrool up to see ssbatch features) and run scontrol top on the job
