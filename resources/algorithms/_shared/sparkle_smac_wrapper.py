#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

import os
import sys
import time
import re

def get_last_level_directory_name(filepath):
    if filepath[-1] == r'/':
        filepath = filepath[0:-1]
    right_index = filepath.rfind(r'/')
    if right_index < 0:
        pass
    else:
        filepath = filepath[right_index + 1:]
    return filepath

def build_param_string(params):
    def pairwise(lst):
        lst = iter(lst)
        return zip(lst, lst)

    paramstring = []
    for param, value in pairwise(params):
        paramstring.append(f"-{param} {value}")
    return " ".join(paramstring)

def parse_solution_set(output_list):
    measure = {"HV": None, "IGDP": None, "SP": None}
    do_match = False
    for line in output_list:
        line = line.strip()
        print(line)

        if line == "s MEASURES":
            do_match = True

        m = re.match(r"s HV ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["HV"] = float(m.group(1))
        m = re.match(r"s HVN ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["HVN"] = float(m.group(1))
        m = re.match(r"s IGDP ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["IGDP"] = float(m.group(1))
        m = re.match(r"s SP ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["SP"] = float(m.group(1))
        m = re.match(r"s SPD ([\d\.e-]+)", line)
        if do_match and m is not None:
            measure["SPD"] = float(m.group(1))

    if measure["HV"] is None:
        measure["HV"] = None
        measure["IGDP"] = 2**32-1
        measure["SP"] = 0
        measure["SPD"] = 0
    return measure

# Exemplary manual call
# ./sparkle_smac_wrapper.py ../../instances/DTLZ2 dummy 3 10 123 -mu 30
if __name__ == "__main__":
    assert (len(sys.argv) >= 6)

    # Argument parsing
    instance = sys.argv[1]
    specifics = sys.argv[2] # not used
    cutoff_time = int(float(sys.argv[3]) + 1)
    run_length = int(sys.argv[4]) # not used
    seed = int(sys.argv[5])
    params = sys.argv[6:]
    print(params)

    # Constants
    solver_binary = r'./algorithm.r'

    # Build command
    assert(len(params) % 2 == 0) #require even number of parameters
    paramstring = build_param_string(params)

    command = f"{solver_binary} --instance {instance} --seed {seed} --budget 20000 {paramstring}"
    print(command)

    # get output
    start_time = time.time()
    output_list = os.popen(command).readlines()
    end_time = time.time()
    run_time = end_time - start_time #Wallclock time

    # parse output
    measures = parse_solution_set(output_list)
    print(measures)
    status = "SUCCESS"
    if measures["HV"] is None:
        status = "CRASHED"
        measures["HV"] = 0
        measures["IGDP"] = 2**32-1
        measures["SP"] = 0
    target = "HV"
    ##TARGET-REPLACE
    result_line = "Result for SMAC: {status}, {runtime}, {runlength}, {quality}, {seed}".format(status=status,
                                                                                      runtime=run_time,
                                                                                      runlength=0,
                                                                                      quality=measures[target],
                                                                                      seed=seed)
    print(result_line)