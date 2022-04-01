#!/usr/bin/env python3

import numpy as np

np.random.seed()
seeds = np.random.randint(1,2**32-1,200)
fh = open("seeds.txt","w")
for seed in seeds:
    fh.write(f"{seed}\n")
fh.close()