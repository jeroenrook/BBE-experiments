#!/usr/bin/env python3

import os
import sys
import itertools
import argparse

#Default
#Dir

#Target / validation /
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('--solver', default=None, type=str, help='Solver name')
    parser.add_argument('--instance', default=None, type=str, help='instance name')
    parser.add_argument('--target', default=None, type=str, help='Target')
    args = parser.parse_args()

    EXP_NAME = os.path.basename(os.getcwd())
    # Make scratch directory
    EXP_DIR = f"/scratch/tmp/rookj/tmp/ABSE/{EXP_NAME}"

    targets = ["default", "HVN", "SP", "ABSEHVMEANNORM", "ABSEHVAUCMEANNORM", "ABSECUMHVMEANNORM", "ABSECUMHVAUCMEANNORM"]
    if args.target is not None:
        target = args.target if args.target in targets else "default"
        targets = [target]

    for target in targets:
        targetdirname = "HVN" if target == "default" else target

        solver_dir = f"{EXP_DIR}/{targetdirname}/sparkle/Solvers"
        instance_dir = f"{EXP_DIR}/{targetdirname}/sparkle/Instances/instances"

        if args.solver is None:
            solvers = os.listdir(solver_dir)
        else:
            solvers = [args.solver]

        if args.instance is None:
            instances = os.listdir(instance_dir)
        else:
            instances = [args.instance]

        output_dir = f"{EXP_DIR}/validation"
        os.system(f"mkdir {output_dir}")

        for solver in solvers:
            configarg = ""
            if target != "default":
                # Retrieve configuration
                print("GET CONFIG")
                config_path = f"{EXP_DIR}/{targetdirname}/sparkle/Components/smac-v2.10.03-master-778/example_scenarios/{solver}_instances/configuration_for_validation.txt"
                if(os.path.isfile(config_path)):
                    config = open(config_path, "r").read().strip()
                    configarg = f"--configuration \"{config}\""
                else:
                    print(f"No configuration found for this target. Skipping {solver}")
                    continue

            for instance in instances:
                print(f"{solver} - {instance}")
                solver_path = os.path.join(solver_dir, solver)
                instance_path = os.path.join(instance_dir, instance)
                output_name = f"{target}_{solver}_{instance}.pickle"
                output_path = os.path.join(output_dir, output_name+".pickle")

                visualisation_path = os.path.join("visualisation", output_name)
                command = f"sbatch ../02validation/validation.py --instance {instance_path} --solver {solver_path} --runs 5 --budget 20000 --output {output_path} --visualise {visualisation_path} {configarg}"
                print(command)
                os.system(command)