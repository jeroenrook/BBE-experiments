#!/usr/bin/env bash

CWD=$(pwd)
BASE_DIR="/home/r/rookj/projects/ABSE"
EXP_NAME=$(basename $(pwd))
#Make scratch directory

EXP_DIR="${TMP}/ABSE/${EXP_NAME}"
echo $EXP_DIR
mkdir -p -- $EXP_DIR

#Prepare wrappers
cd "${BASE_DIR}/intermediates/algorithms"
./generate_algorithms.py

#targets=("SPD" "HV")
targets=("HVN" "SP" "ABSEHVMEANNORM" "ABSECUMHVMEANNORM" "ABSECUMHVAUCMEANNORM")
for target in "${targets[@]}"; do
  echo $target

  cd $EXP_DIR
  mkdir $target
  cd $target

  #Clone sparkle
  if [[ -d "sparkle" ]]
  then
      echo "sparkle/ exists."
      cd sparkle
  else
    git clone git@bitbucket.org:sparkle-ai/sparkle.git
    cd sparkle
    git checkout 9336661208ee3b857b420ae3dd5460d9d1c21f16
  fi

  #Copy settings and scripts
  cp -r "${CWD}/Settings" .
  cp -r "${CWD}/scripts/"* .

  cd "$EXP_DIR/$target/sparkle"

  ./Commands/initialise.py
  #Add all solvers

  python generate_sparkle_commands.py "${BASE_DIR}/resources/instances/" "${BASE_DIR}/intermediates/algorithms/" -t $target
  #Created by create_instance_partitions.py

  ./solvers.sh

  ./instances.sh

  #./configurations0.sh

done

JOBID=$(sbatch -p joblauncher.py)
sbatch --dependecy=afterany:"$JOBID" do_validation.py


