#!/usr/bin/env python3
#SBATCH --job-name=scheduler
#SBATCH --output=%A.log
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -c 2
#SBATCH --mem=4000mb
#SBATCH --partition=normal
import os
import re
import subprocess
import time

def check_jobs():
    result = subprocess.check_output("squeue -u rookj --array | wc -l", shell=True, text=True)
    return int(result.strip())

targets = ["HVN", "SP", "ABSEHVMEANNORM", "ABSECUMHVMEANNORM", "ABSECUMHVAUCMEANNORM"]
files = "/scratch/tmp/rookj/tmp/ABSE/05lofconfiguration/{}/sparkle"

commands = []
for target in targets:
    expdir = files.format(target)
    os.chdir(expdir)
    with open("configurations0.sh") as fh:
        for line in fh.readlines():
            if line[:2] == "./":
                commands.append((expdir, line.strip()))
        fh.close()

while len(commands) > 0:
    print(check_jobs())
    while check_jobs() > 1950:
        print(".", end="")
        time.sleep(60)
    print("")

    expdir, command = commands[0]
    print("Launching new script")
    os.chdir(expdir)
    print(command)
    result = subprocess.check_output(command, shell=True, text=True)
    print("done")
    commands = commands[1:] #pop
    time.sleep(2)


