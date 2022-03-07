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

# Jakob: need to check
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


# JAKOB: C&P from RMMMOO group script. Need to check what we really need.
  # # extract relevant data, here the decision space points
  # # and append meta-data
  # res = lapply(mole_trace$sets, function(x)
  #   return(as.data.frame(x$dec_space))
  #   )
  # res = res %>% reduce(rbind)
  #print(optimizer$sets)
  dec = lapply(optimizer$sets, function(x)
    return(as.data.frame(x$dec_space))
  )
  dec = dec %>% reduce(rbind)
  names(dec) <- c('x1', 'x2')

  obj = lapply(optimizer$sets, function(x)
    return(as.data.frame(x$obj_space))
  )
  obj = obj %>% reduce(rbind)
  names(obj) <- c('y1', 'y2')
  # names(res) <- c('x1', 'x2')
  # n.rows = nrow(obj)

  #print(obj)

  # res$algorithm = rep_len('MOLE', n.rows)
  # res$prob = rep_len(smoof::getID(data$fun), n.rows)
  # if(smoof::getID(data$fun) == 'biobj_bbob_2d_2o')
  #   res$prob = smoof::getName(data$fun)
  # res$repl = rep_len(job$repl, n.rows)
  # res$y1 = obj$y1
  # res$y2 = obj$y2
  # res$fun_calls = smoof::getNumberOfEvaluations(data$fun)
  # end_time = Sys.time()
  # res$rep_time = rep_len(as.double(end_time - start_time), n.rows)
  # res = as.data.frame(res)
  # print(res)


writeLines(paste("c EVALUATIONS", smoof::getNumberOfEvaluations(obj.fn)))

# Parse the solution set to a common interface
population <- dec
solution_set <- obj
print_and_save_solution_set(solution_set)  #utils.R

measures <- compute_performance_metrics(population, solution_set, obj.fn, opt$instance) #utils
print_measures(measures) #utils
