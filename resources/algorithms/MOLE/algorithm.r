#!/usr/bin/env Rscript

#R LIBRARIES
library(optparse)
library(smoof)
library(moleopt)
library(tidyverse) #reduce, %>%,

source("utils.r")

#ARGUMENTS
option_list = list(
  make_option("--instance", type = "character", default = NULL, help = "instance"),
  make_option("--budget", type = "numeric", default = 10000L, help = "The maximum number of allowed function evaluations"),
  make_option("--seed", type = "numeric", default = 0, help = "The random seed"),
  make_option("--save_solution", type= "character", default = NULL, "save solution set to an Rdata object"),
  make_option("--visualise", type= "character", default = NULL, "visualise populations and solution set to an Rdata object"),
  #Add parameters here
  make_option("--max_local_sets", type = "numeric", default = 1000L),
  make_option("--epsilon_gradient", type = "numeric", default = 1e-8, help = ""),
  make_option("--descent_direction_min", type = "numeric", default = 1L, help = ""),
  make_option("--descent_step_min", type = "numeric", default = 1e-6, help = ""),
  make_option("--descent_step_max", type = "numeric", default = 1e-1, help = ""),
  make_option("--descent_scale_factor", type = "numeric", default = 2, help = ""),
  make_option("--descent_armijo_factor", type = "numeric", default = 1e-4, help = "[recCrossover, recIntermediate, recOX, recPMX, recSBX]"),
  make_option("--descent_history_size", type = "numeric", default = 100, help = ""),
  make_option("--descent_max_iter", type = "numeric", default = 1000, help = ""),
  make_option("--explore_step_min", type = "numeric", default = 1e-4, help = ""),
  make_option("--explore_step_max", type = "numeric", default = 1e-1, help = ""),
  make_option("--explore_angle_max", type = "numeric", default = 45, help = ""),
  make_option("--explore_scale_factor", type = "numeric", default = 2, help = ""),
  make_option("--refine_after_nstarts", type = "numeric", default = 100, help = ""),
  make_option("--refine_hv_target", type = "numeric", default = 2e-5, help = "")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

# print(opt)

#SET SEED
set.seed(opt$seed)

#INSTANCE LOADING
# NB: obj.fn is already a wrapped function!
obj.fn = parse_instance_file(opt$instance) #utils.R
writeLines(paste("c REFERENCE POINT", paste(c(smoof::getRefPoint(obj.fn)), collapse=" ")))

fn.lower = smoof::getLowerBoxConstraints(obj.fn)
fn.upper = smoof::getUpperBoxConstraints(obj.fn)

#ALGORITHM (MOLE)
writeLines('c ALGORITHM MOLE')

runif_box = function(lower, upper) {
  u = runif(length(lower))
  u * (upper - lower) + lower
}

nstarts = 100
starting_points = lapply(seq_len(nstarts), function(x) runif_box(fn.lower, fn.upper))
starting_points = do.call(rbind, starting_points)

# We currently do nothing with the intermediate results, so we do not need the for-loop and can just run with the budget
optimizer =  run_mole(
  obj.fn,
  starting_points,
  max_local_sets = as.integer(opt$max_local_sets),
  epsilon_gradient = opt$epsilon_gradient,
  descent_direction_min = opt$descent_direction_min,
  descent_step_min = opt$descent_step_min,
  descent_step_max = opt$descent_step_max,
  descent_scale_factor = opt$descent_scale_factor,
  descent_armijo_factor = opt$descent_armijo_factor,
  descent_history_size = as.integer(opt$descent_history_size),
  descent_max_iter = as.integer(opt$descent_max_iter),
  explore_step_min = opt$explore_step_min,
  explore_step_max = opt$explore_step_max,
  explore_angle_max = opt$explore_angle_max,
  explore_scale_factor = opt$explore_scale_factor,
  refine_after_nstarts = as.integer(opt$refine_after_nstarts),
  refine_hv_target = opt$refine_hv_target,
  lower = fn.lower,
  upper = fn.upper,
  max_budget = opt$budget,
  logging = "none")

logged_values = smoof::getLoggedValues(obj.fn)
dec = logged_values$pars
obj = t(logged_values$obj.vals)
colnames(obj) = c('y1', 'y2')

# Parse the solution set to a common interface
population <- dec
solution_set <- obj

# just pretend each 100 evaluations is a single population
# that means: only cumulative measures are useful for now!
fun_calls = rep(100 * 1:(opt$budget / 100), each = 100)
populations = cbind(fun_calls = fun_calls, population, solution_set)

df = as_tibble(populations)
print(df)

process_run(df, obj.fn, opt)
