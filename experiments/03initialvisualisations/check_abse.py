#!/usr/bin/env python3
import os
import itertools

if __name__ == "__main__":
    EXP_NAME = os.path.basename(os.getcwd())
    # Make scratch directory
    EXP_DIR = f"tmp/"
    output_dir = f"{EXP_DIR}"
    os.system(f"mkdir {output_dir}")

    #Load instances
    instances_path = "../../resources/instances"
    instances = []
    for i in os.listdir(instances_path):
        instances.append(i)

    algorithms_path = "../../resources/algorithms"

    #Launch abse for all
    for instance in instances:
        algorithm = "NSGA-II"
        output_name = f"{instance}_{algorithm}"
        output_path = os.path.join(output_dir, output_name) + ".pickle"

        visualisation_path = os.path.join("visualisation", output_name)

        instance_path = os.path.join(instances_path, instance)
        algorithm_path = os.path.join(algorithms_path, algorithm)

        command = f"../02validation/validation.py --instance {instance_path} --solver {algorithm_path} --runs 1 --budget 5000 --output {output_path}"
        print(command)
        os.system(command)