#!/usr/bin/env python3
#SBATCH --job-name=validation
#SBATCH --output=out/%A.log
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH -c 1
#SBATCH --mem=4000mb
#SBATCH --time=03:00:00
#SBATCH --partition=normal
import os
import sys
import argparse
import time
import pandas as pd

# import matplotlib.pyplot as plt
import numpy as np
import tempfile
import pyreadr
import joblib

def build_param_string(params):
    def pairwise(lst):
        lst = iter(lst)
        return zip(lst, lst)

    paramstring = []
    for param, value in pairwise(params):
        paramstring.append(f"-{param} {value}")
    return " ".join(paramstring)

TMP = tempfile.gettempdir()
if __name__ == "__main__":
    # Define command line arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('--instance', required=True, type=str, help='path to instance to run on')
    parser.add_argument('--solver', required=True, type=str, help='path to solver')
    parser.add_argument('--runs', default=1, type=int)
    parser.add_argument('--budget', default=20000, type=int)
    parser.add_argument('--configuration', default=None)
    parser.add_argument("--visualise", default=None)
    parser.add_argument("--output", default=None)
    args = parser.parse_args()
    np.random.seed(0)
    seeds = np.random.randint(1, 2**16 -1, 1000)

    instance_path = os.path.abspath(args.instance)

    paramsstring = ""
    if args.configuration is not None:
        params = args.configuration.split(" ")
        assert (len(params)%2==0)
        paramsstring = build_param_string(params)
        print(paramsstring)

    performances = np.zeros(args.runs)
    table = []
    for i in range(args.runs):
        seed = seeds[i]
        row = {"run": i,
               "seed": seed}
        filehash = str(hash(instance_path+args.solver+str(seed)+str(time.time())))
        tmp_file = f"{TMP}/data_{filehash}.Rds"
        arguments = f"--budget {args.budget} --seed {seed} --save_solution {tmp_file} --instance {instance_path} {paramsstring}"
        if args.visualise is not None and i == 0:
            pwd = os.getcwd()
            arguments += f" --visualise {pwd}/{args.visualise}"
        #Run algorithm
        command = f"cd {args.solver}; ./algorithm.r {arguments}"
        print(command)
        os.system(command)
        try:
            result = pyreadr.read_r(tmp_file)  # also works for Rds
            result = result[None].iloc[0]
            for key, value in result.iteritems():
                print(key, value)
                row[key] = abs(float(value))
            table.append(row)
            os.system(f"rm {tmp_file}")
        except:
            pass

    print(pd.DataFrame(table))

    if args.output is not None:
        output = {
            "args": args,
            "table": table,
        }
        print(output)
        joblib.dump(output, args.output)