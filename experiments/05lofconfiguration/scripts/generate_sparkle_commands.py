#!/usr/bin/env python3
import argparse
import os
import sys
import copy

PDIR = "partitions/"

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('instancepath')
    parser.add_argument('wrapperpath')
    parser.add_argument('-t', dest='target', default=None)
    args = parser.parse_args()
    if args.instancepath[-1] != "/":
        args.instancepath += "/"
    if args.wrapperpath[-1] != "/":
        args.wrapperpath += "/"


    solvers = [os.path.join(args.wrapperpath, dir) for dir in os.listdir(args.wrapperpath) if
                  (os.path.isdir(os.path.join(args.wrapperpath, dir))) and (dir[0] != "_")]

    if args.target is not None:
        print("FILTER ON TARGET:", args.target)
        solvers = [s for s in solvers if s[-len(args.target):] == args.target]
    solvers = sorted(solvers)

    print(solvers)

    sfh = open("solvers.sh","w")
    sfh.write("#!/usr/bin/env bash\n\n")
    for solver in solvers:
        sfh.write(f"./Commands/add_solver.py --deterministic 0 --run-solver-later {solver}\n")
    sfh.close()
    os.system("chmod 755 solvers.sh")

    # Get instances
    instances = os.listdir(args.instancepath)
    print(len(instances))
    os.system(f"rm -rf {PDIR}")
    os.mkdir(f"{PDIR}")

    ifh = open("instances.sh", "w")
    ifh.write("#!/usr/bin/env bash\n\n")

    partition_count = 0
    configurations_sh = f"configurations{partition_count}.sh"
    cfh = open(configurations_sh, "w")
    cfh.write("#!/usr/bin/env bash\n\n")

    # For each instance make train-test split
    counter = 0
    for i, test in enumerate(instances):
        print(i)
        tedest = f"{PDIR}{i}test"
        os.mkdir(tedest)
        os.system(f"cp {args.instancepath}{test} {tedest}")

        trdest = f"{PDIR}{i}train"
        os.mkdir(trdest)
        temp = copy.copy(instances)
        temp.remove(test)
        for instance in temp:
            os.system(f"cp {args.instancepath}{instance} {trdest}")

        ifh.write(f"./Commands/add_instances.py --run-extractor-later --run-solver-later {tedest}\n")
        ifh.write(f"./Commands/add_instances.py --run-extractor-later --run-solver-later {trdest}\n")

        for solver in solvers:
            solver_name = solver.split("/")[-1]
            cfh.write(f"./Commands/configure_solver.py --solver Solvers/{solver_name}/ --instance-set-train Instances/{i}train/ --instance-set-test Instances/{i}test/ --validate\n")
            counter += 1
            if counter >= 150:
                counter = 0
                cfh.close()
                os.system(f"chmod 755 {configurations_sh}")

                partition_count += 1
                configurations_sh = f"configurations{partition_count}.sh"

                cfh = open(configurations_sh, "w")
                cfh.write("#!/usr/bin/env bash\n\n")


    ifh.close()
    os.system("chmod 755 instances.sh")

    cfh.close()
    os.system(f"chmod 755 {configurations_sh}")

