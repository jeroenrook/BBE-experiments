#!/usr/bin/env python3
import os
import itertools



if __name__ == "__main__":
    PWD = os.getcwd()
    EXP_NAME = os.path.basename(os.getcwd())
    # Make scratch directory
    EXP_DIR = f"/scratch/tmp/rookj/tmp/ABSE/{EXP_NAME}"
    output_dir = f"{EXP_DIR}/validation"
    #os.system(f"rm -rf {output_dir}")
    os.system(f"mkdir {output_dir}")

    visualisations_path = "visualisation"
    os.system(f"rm -rf ./{visualisations_path}")
    os.system(f"mkdir ./{visualisations_path}")

    #Load instances
    instances_path = "../../resources/instances"
    instances = []
    for i in os.listdir(instances_path):
        instances.append(i)

    #Load algorithms
    algorithms_path = "../../resources/algorithms"
    algorithms = []
    for a in os.listdir(algorithms_path):
        if a not in ["SMS-EMOA", "NSGA-II", "omnioptimizer", "MOLE"]:
            continue
        algorithms.append(a)

    os.system(f"cd {algorithms_path}; ./distribute_shared_files.sh; cd {PWD}")

    #Launch validation for all
    for instance, algorithm in itertools.product(instances, algorithms):
        output_name = f"{instance}_{algorithm}"
        output_path = os.path.join(output_dir, output_name) + ".pickle"

        visualisation_path = os.path.join(visualisations_path, output_name)

        instance_path = os.path.join(instances_path, instance)
        algorithm_path = os.path.join(algorithms_path, algorithm)

        command = f"sbatch ../02validation/validation.py --instance {instance_path} --solver {algorithm_path} --runs 5 --budget 25000 --output {output_path} --visualise {visualisation_path}"
        # command = f"sbatch ../02validation/validation.py --instance {instance_path} --solver {algorithm_path} --runs 1 --budget 20000 --visualise {visualisation_path}"
        print(command)
        os.system(command)