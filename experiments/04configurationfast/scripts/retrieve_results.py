#!/usr/bin/env python3
import re
import os
import pandas as pd
# import matplotlib.pyplot as plt
# import seaborn as sns

solvers = ["SMS-EMOA", "NSGA-II", "omnioptimizer", "MOGSA", "higamo", "MOLE", "MOEAD", "DN-NSGAII"]
result_path = "Components/smac-v2.10.03-master-778/example_scenarios/"

if __name__ == "__main__":

    df = None

    for solver in solvers:
        print(f"Collecting for: {solver}")
        dirs = [result_path + d for d in os.listdir(result_path) if d[:len(solver)] == solver and os.path.isdir(result_path + d)]
        match = "outdir_instances_test_.+"

        result_df = []
        print("Found ", dirs)
        for outdir in dirs:
            targetdirs = [d for d in os.listdir(outdir) if re.match(match, d)]
            if len(targetdirs) != 2:
                print(f"skipping {outdir}")
                continue

            if targetdirs[0][-7:] == "default":
                defaultdir = targetdirs[0]
                configdir = targetdirs[1]
            else:
                defaultdir = targetdirs[1]
                configdir = targetdirs[0]

            try:
                ddf = pd.read_csv(outdir + "/" + defaultdir + "/" + "validationRunResultLineMatrix-cli-1-walltime.csv")
                cdf = pd.read_csv(outdir + "/" + configdir + "/" + "validationRunResultLineMatrix-configuration_for_validation-walltime.csv")

                configuration = ""
                try:
                    config = open(outdir + "/configuration_for_validation.txt","r").read()
                    print(config)
                    configuration = config
                except:
                    raise

                for i in range(len(ddf)):
                    result = {
                        "instance":ddf["Problem Instance"][i].split("/")[-1],
                        "default":-float(ddf["Run result line of validation config #1"][i].split(", ")[-2]),
                        "config":-float(cdf["Run result line of validation config #1"][i].split(", ")[-2]),
                        "configuration":configuration
                    }
                    result_df.append(result)
            except:
                print(f"Could not load {defaultdir}")
                pass

        if len(result_df) == 0:
            continue

        result_df = pd.DataFrame(result_df)

        result_df["difference"] = (result_df["config"] - result_df["default"]) / result_df["default"]
        result_df["solver"] = [solver]*len(result_df)

        # fig, ax = plt.subplots(figsize=(8,8))
        # ax.scatter(result_df["default"],result_df["config"])
        # ax.plot([0.001,10000],[0.001,10000],c="black")
        # ax.set_xscale('log')
        # ax.set_yscale('log')
        # ax.set_xlabel("default HV")
        # ax.set_ylabel("configured HV")
        # ax.set_title(f"Configuration results for {solver}")
        # plt.savefig(f"scatter_{solver}.pdf")

        print(result_df)

        if df is None:
            df = result_df
        else:
            df = df.append(result_df, ignore_index=True)

    print(df)
    df.to_csv("results.csv")
    # df.groupby("solver")["difference"].boxplot()
    # fig, ax = plt.subplots(figsize=(8, 8))
    # sns.boxplot(x="solver",y="difference",data=df)
    #
    # ax.set_title("Procentual improvement after configuration [HV]")
    # ax.set_ylabel("Difference [%]")
    # ax.set_xlabel("Solver")
    # plt.savefig("boxplot.pdf")
