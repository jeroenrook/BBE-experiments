#!/usr/bin/env python3
# -*- coding: UTF-8 -*-

import os
import sys
import re
import itertools

targets = ["HVN", "SP", "ABSEHVMEANNORM", "ABSEHVAUCMEANNORM", "ABSECUMHVMEANNORM", "ABSECUMHVAUCMEANNORM"]

algodir = "../../resources/algorithms"
algorithms = [os.path.join(algodir, dir) for dir in os.listdir(algodir) if (os.path.isdir(os.path.join(algodir, dir))) and (dir[0] != "_")]

os.system(f"cd {algodir}; ./distribute_shared_files.sh")

for target, algorithm in itertools.product(targets, algorithms):
    print(target, algorithm)
    algoname = algorithm.split("/")[-1]
    dirname = f"./{algoname}_{target}"
    os.system(f"rm -rf {dirname}; cp -r {algorithm} {dirname}")

    wrapper_path = os.path.join(dirname, "sparkle_smac_wrapper.py")

    fh = open(wrapper_path, "r")
    wrapper_code = fh.read()
    fh.close()

    m = re.search("##TARGET-REPLACE", wrapper_code, re.MULTILINE)
    if m is None:
        raise "CANNOT REPLACE TARGET. CHECK YOUR WRAPPER BEFORE CONTINUING!"
    else:
        wrapper_code = re.sub("##TARGET-REPLACE", f"target = \"{target}\"", wrapper_code)
        fh = open(wrapper_path, "w")
        fh.write(wrapper_code)
        fh.close()
        os.system(f"chmod 755 {wrapper_path}")
        print(f"Changed target in {wrapper_path} to {target}")
