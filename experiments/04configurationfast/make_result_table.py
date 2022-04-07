#!/usr/bin/env python3
import os
import sys
import itertools
import argparse
import pandas as pd
import numpy as np
import joblib
from tqdm import tqdm
import rpy2.robjects as robjects
import rpy2.robjects.numpy2ri
rpy2.robjects.numpy2ri.activate()
import rpy2.robjects.pandas2ri
rpy2.robjects.pandas2ri.activate()

if __name__ == "__main__":
    EXP_NAME = os.path.basename(os.getcwd())
    # Make scratch directory
    EXP_DIR = f"/scratch/tmp/rookj/tmp/ABSE/{EXP_NAME}"
    output_dir = f"{EXP_DIR}/validation"

    df = None
    for n, pickle in enumerate([os.path.join(output_dir,p) for p in os.listdir(output_dir)]):
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
    print (df)
    df.to_csv("results.csv")


    def load_rdata(filepath):
        data = robjects.r['load'](filepath)

        objnames = ["dec.space", "dims", "step.sizes", "obj.space", "efficientSets", "decSpaceLabels",
                    "basin_separated_eval"]

        result = {}

        for i, objname in enumerate(data):
            obj = robjects.r[objname]
            objdict = {}
            for j, field in enumerate(obj):
                if j < 6:
                    o = np.array(obj[j])
                else:
                    o = pd.DataFrame(obj[j])
                objdict[objnames[j]] = o
            result[objname] = objdict

        return result

    df = None
    for file in tqdm(os.listdir("visualisation")):
        if file[-6:] != ".Rdata":
            continue
        target, solver, config, instance = file[:-6].split("_")
        #     print(f"{instance} - {solver}")

        data = load_rdata(os.path.join("visualisation", file))
        #     tdf = data["abse"]["basin_separated_eval"]
        for absetype in ["abse", "absec"]:
            tdf = data[absetype]["basin_separated_eval"].T
            tdf = tdf.set_axis(
                ['fun_calls', 'value_basin1', 'value_basin2', 'value_basin3', 'value_basin4', 'mean_value',
                 'auc_hv_mean', 'auc_hv1'],
                axis=1,
                inplace=False)
            tdf["type"] = absetype
            tdf["target"] = target
            tdf["instance"] = instance
            tdf["solver"] = solver

            if df is None:
                df = tdf
            else:
                df = pd.concat([df, tdf], ignore_index=True)
    print(df)
    df.to_csv("abse_tables.csv")

