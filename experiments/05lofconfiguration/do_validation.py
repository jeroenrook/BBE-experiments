#!/usr/bin/env python3

import os
import sys
import itertools
import argparse
import re

#Default
#Dir

#Target / validation /
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--solver', default=None, type=str, help='Solver name')
    parser.add_argument('--instance', default=None, type=str, help='instance name')
    parser.add_argument('--target', default="default", type=str, help='Target')
    args = parser.parse_args()

    EXP_NAME = os.path.basename(os.getcwd())
    # Make scratch directory
    EXP_DIR = f"/scratch/tmp/rookj/tmp/MMMOO/{EXP_NAME}"

    target = args.target if args.target in ["default", "HV", "SPD", "HVN"] else "default"
    targetdirname = "HVN" if target == "default" else target

    solver_dir = f"{EXP_DIR}/{targetdirname}/sparkle/Solvers"

    if args.solver is None:
        solvers = os.listdir(solver_dir)
    else:
        solvers = [args.solver]


    instance_dir = f"{EXP_DIR}/{targetdirname}/sparkle/Instances/"

    instances = [i for i in os.listdir(instance_dir) if re.match("\d+test", i)]
    instances = [(i, os.listdir(instance_dir + i)[0]) for i in instances]
    if args.instance is not None:
        instances = [i for i in instances if i[1] == args.instance]
    if len(instances) == 0:
        print("Instance not found!")
        exit()

    output_dir = f"{EXP_DIR}/validation"
    os.system(f"mkdir {output_dir}")

    print("Starting validation on {} solvers and {} instances of 25 runs: {}".format(len(solvers),len(instances), 25*len(solvers)*len(instances)))

    for solver in solvers:
        for instance in instances:
            print(f"{solver} - {instance[1]}")
            configarg = ""
            if target != "default":
                # Retrieve configuration
                print("GET CONFIG")
                instance_train = instance[0].replace("test","train")
                config_path = f"{EXP_DIR}/{targetdirname}/sparkle/Components/smac-v2.10.03-master-778/example_scenarios/{solver}_{instance_train}/configuration_for_validation.txt"
                print(config_path)
                if (os.path.isfile(config_path)):
                    config = open(config_path, "r").read().strip()
                    configarg = f"--configuration \"{config}\""
                else:
                    print(f"No configuration found for this target. Skipping {solver}")
                    continue
            solver_path = os.path.join(solver_dir, solver)
            instance_path = os.path.join(instance_dir, "/".join(instance))
            output_name = f"{target}_{solver}_{instance[1]}.pickle"
            output_path = os.path.join(output_dir,output_name)
            command = f"sbatch ../06validation/validation.py --instance {instance_path} --solver {solver_path} --runs 25  --output {output_path} {configarg}"
            print(command)
