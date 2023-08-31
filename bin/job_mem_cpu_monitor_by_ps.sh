#!/bin/bash

#set -x

# if jobs has --mem
reservedMem=$SLURM_MEM_PER_NODE

# if job has --mem-per-cpu and -c
[ -z "$reservedMem" ] && reservedMem=$((SLURM_MEM_PER_CPU * SLURM_JOB_CPUS_PER_NODE))

# if job has --mem-per-cpu and -n
[ -z "$reservedMem" ] &&  reservedMem=$((SLURM_MEM_PER_CPU * SLURM_CPUS_PER_TASK))

reservedCpu=$SLURM_JOB_CPUS_PER_NODE

[ -z "$reservedCpu" ] && reservedCpu=SLURM_CPUS_PER_TASK

echo "Timestamp ReservedRam(M) Ram(M) Ram_Utilization(%) ReservedCpu CPU_Utilization(%)" > $SLURM_JOBID.memCpuLog

function calculate_resource_usage {
    local pid=$1
    local total_memory=0
    local total_cpu=0

    # Get memory and CPU usage of the current process
    local process_info=$(ps -o rss=,%cpu=,cmd= -p $pid)
    [[ "$process_info" == *job_mem_cpu_monitor* ]] && echo 5000 2.0 && return
    
    local memory=$(echo "$process_info" | awk '{print $1}')
    local cpu=$(echo "$process_info" | awk '{print $2}')

    # Calculate memory and CPU usage of children
    local children=$(ps --ppid $pid -o pid=)
    for child_pid in $children; do
        local output=$(calculate_resource_usage $child_pid)
        local child_memory=${output% *}
        local child_cpu=${output#* }
        total_memory=$((total_memory + child_memory))
        total_cpu=$(echo "scale=4; $total_cpu + $child_cpu"|bc)
    done

    # Calculate total memory and CPU usage
    total_memory=$((total_memory + memory))
    total_cpu=$(echo "scale=4; $total_cpu + $cpu"|bc)

    echo "$total_memory $total_cpu"
}

while true; do
    total_memory_usage=0; total_cpu_usage=0
    job_pids=`ps -AF | grep $SLURM_JOBID | grep slurmstepd|awk '{print $2}'`
    if [ -n "$job_pids" ]; then
        for job_pid in $job_pids; do
            output=$(calculate_resource_usage $job_pid)
            mem=${output% *}
            cpu=${output#* }
            total_memory_usage=$((total_memory_usage + mem))
            total_cpu_usage=$(echo "scale=4; $total_cpu_usage + $cpu"|bc)
        done

        total_memory_usage=$((total_memory_usage/1024))
 
        echo $(date +"%Y-%m-%d %H:%M:%S") $reservedMem $(echo "scale=4; $total_memory_usage/1024" | bc) $(echo "scale=4; $total_memory_usage/10.24/ $reservedMem" | bc) $reservedCpu $total_cpu_usage >> $SLURM_JOBID.memCpuLog
    else
        exit
    fi
    sleep 5
done
