#!/usr/bin/env Rscript

#R LIBRARIES
library(optparse)
library(smoof)
library(moleopt)
library(tidyverse) #reduce, %>%,

parse_instance_file <- function(filename){
    content <- readChar(filename, nchars=file.info(filename)$size)
    obj.fn <- eval(parse(text=content))
    return(obj.fn)
}

#ARGUMENTS
option_list = list(
  make_option("--instance", type = "character", default = NULL, help = "instance"),
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

#SET SEED
set.seed(42)

#INSTANCE LOADING
# NB: obj.fn is already a wrapped function!
obj.fn = parse_instance_file(opt$instance) #utils.R

abse <- ABSE::evaluate_results(populations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:4,
                                    keep_points=FALSE,
                                    join_fronts=FALSE)
    measures$ABSE.HV.MEAN <- -tail(abse$basin_separated_eval$mean_value, n=1)
    measures$ABSE.HV.AUC.MEAN <- -tail(abse$basin_separated_eval$auc_hv_mean, n=1)
    measures$ABSE.HV.AUC.B1 <- -tail(abse$basin_separated_eval$auc_hv1, n=1)

    cat("ABSE CUMULATIVE \n")
    absec <- ABSE::evaluate_results(populations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:4,
                                    keep_points=TRUE,
                                    join_fronts=FALSE,
                                    design=abse,
                                    efficient_sets = abse$efficientSets,
                                    dec_space_labels = abse$decSpaceLabels)
    measures$ABSE.CUM.HV.MEAN <- -tail(absec$basin_separated_eval$mean_value, n=1)
    measures$ABSE.CUM.HV.AUC.MEAN <- -tail(absec$basin_separated_eval$auc_hv_mean, n=1)
    measures$ABSE.CUM.HV.AUC.B1 <- -tail(absec$basin_separated_eval$auc_hv1, n=1)

    cat("ABSE JF ITERATIVE \n")
    absej <- ABSE::evaluate_results(populations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:4,
                                    keep_points=FALSE,
                                    join_fronts=TRUE,
                                    design=abse)
    measures$ABSE.JF.HV.MEAN <- -tail(absej$basin_separated_eval$mean_value, n=1)
    measures$ABSE.JF.HV.AUC.MEAN <- -tail(absej$basin_separated_eval$auc_hv_mean, n=1)
    measures$ABSE.JF.HV.AUC.B1 <- -tail(absej$basin_separated_eval$auc_hv1, n=1)

    cat("ABSE JF CUMULATIVE \n")
    absejc <- ABSE::evaluate_results(populations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:4,
                                    keep_points=TRUE,
                                    join_fronts=TRUE,
                                    design=abse,
                                    efficient_sets = absej$efficientSets,
                                    dec_space_labels = absej$decSpaceLabels)
    measures$ABSE.JF.CUM.HV.MEAN <- -tail(absejc$basin_separated_eval$mean_value, n=1)
    measures$ABSE.JF.CUM.HV.AUC.MEAN <- -tail(absejc$basin_separated_eval$auc_hv_mean, n=1)
    measures$ABSE.JF.CUM.HV.AUC.B1 <- -tail(absejc$basin_separated_eval$auc_hv1, n=1)