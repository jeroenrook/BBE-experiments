#!/usr/bin/env bash

./compute_references.R
chmod 755 script.sh
jobid=$(sbatch --parsable script.sh)
echo "script launched with ${jobid}"
sbatch --dependency=afterany:${jobid} ./analyse_results.R