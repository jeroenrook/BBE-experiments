#!/usr/bin/env Rscript

#R LIBRARIES
library(optparse)
library(smoof)
library(omnioptr)

source("utils.r")

#ARGUMENTS
option_list = list(
  make_option("--instance", type = "character", default = NULL, help = "instance"),
  make_option("--budget", type = "numeric", default = 20000L, help = "The maximum number of allowed function evaluations"),
  make_option("--seed", type = "numeric", default = 0, help = "The random seed"),
  make_option("--save_solution", type= "character", default = NULL, "save solution set to an Rdata object"),
  make_option("--visualise", type= "character", default = NULL, help = "visualise population and solution set to a pdf"),
  #Add parameters here
  make_option("--pop_size", type = "numeric", default = 4L),
  make_option("--p_cross", type = "numeric", default = 0.6, help = ""),
  make_option("--p_mut", type = "numeric", default = 0.1, help = ""),
  make_option("--eta_cross", type = "numeric", default = 20, help = ""),
  make_option("--eta_mut", type = "numeric", default = 20, help = ""),
  make_option("--mate", type = "character", default = "normal", help = "[normal, restricted]"),
  make_option("--delta", type = "numeric", default = 0.001, help = ""),
  make_option("--space_niching", type = "character", default = "obj", help = ""),
  make_option("--init", type = "character", default = "random", help = "[random, lhs]")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)
print(opt)

# SET SEED
set.seed(opt$seed)

# INSTANCE LOADING
obj.fn = parse_instance_file(opt$instance) #utils.R
#print(paste(c(smoof::getRefPoint(obj.fn))))
writeLines(paste("c REFERENCE POINT", paste(c(smoof::getRefPoint(obj.fn)), collapse=" ")))

fn.lower = smoof::getLowerBoxConstraints(obj.fn)
fn.upper = smoof::getUpperBoxConstraints(obj.fn)


var.space.niching <- FALSE
if(opt$space_niching == "var" || opt$space_niching == "both"){
    var.space.niching <- TRUE
}

obj.space.niching <- FALSE
if(opt$space_niching == "obj" || opt$space_niching == "both"){
    obj.space.niching <- TRUE
}

#ALGORITHM (OmniOptimizer)
writeLines('c ALGORITHM OmniOptimizer')

budget = floor(opt$budget / (4 * opt$pop_size)) # number of generations
optimizer = omniopt(
  obj.fn,
  pop.size = 4 * opt$pop_size, # NOTE: requireed to always be a multiple of 4
  n.gens = budget,
  frequency =  budget, # do not store intermediate results
  p.cross = opt$p_cross,
  p.mut = opt$p_mut,
  eta.cross = opt$eta_cross,
  eta.mut = opt$eta_mut,
  mate = opt$mate,
  delta = opt$delta,
  var.space.niching = var.space.niching,
  obj.space.niching = obj.space.niching,
  init = opt$init,
  seed = opt$seed / .Machine$integer.max, # omnioptimizer requires seed in [0,1]
  verbose = FALSE
)

writeLines(paste("c EVALUATIONS", smoof::getNumberOfEvaluations(obj.fn)))

# Parse the solution set to a common interface
population <- as.data.frame(t(optimizer$dec))
solution_set <- as.data.frame(t(optimizer$obj))
print_and_save_solution_set(solution_set)  #utils.R

measures <- compute_performance_metrics(population, solution_set, obj.fn, opt$instance) #utils
print_measures(measures) #utils

