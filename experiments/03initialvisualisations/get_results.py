#!/usr/bin/env python3
import os
import sys
import itertools
import argparse
import pandas as pd
import joblib

if __name__ == "__main__":
    EXP_NAME = os.path.basename(os.getcwd())
    # Make scratch directory
    EXP_DIR = f"/scratch/tmp/rookj/tmp/ABSE/{EXP_NAME}"
    output_dir = f"{EXP_DIR}/validation"

    df = None
    for n, pickle in enumerate([os.path.join(output_dir, p) for p in os.listdir(output_dir)]):
        print(pickle)
        result = joblib.load(pickle)
        rdf = pd.DataFrame(result["table"])
        rdf["solver"] = [result["args"].solver.split("/")[-1]]*len(rdf)
        rdf["instance"] = [result["args"].instance.split("/")[-1]]*len(rdf)
        rdf["configuration"] = [result["args"].configuration]*len(rdf)

        if df is None:
            df = rdf
        else:
            df = pd.concat([df, rdf], ignore_index=True)
    print(df)
    df.to_csv("results.csv")

    output_dir = f"{EXP_DIR}/visualisation"
    os.system("cp -r {output_dir} visualisation")