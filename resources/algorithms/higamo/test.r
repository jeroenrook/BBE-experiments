#!/usr/bin/env Rscript
library(optparse)
library(smoof)
library(reticulate)

# # tell reticulate which python version to use
#use_python("/Applic.HPC/Easybuild/skylake/2020b/software/Python/3.8.6-GCCcore-10.2.0/bin/python3")
use_virtualenv("/home/r/rookj/projects/MMMOO/nenv")

print(Sys.which("python"))

virtualenv_list()


print(py_discover_config())
print(py_config())

py_available(initialize = FALSE)

os <- import("os")
os$listdir(".")

py_available(initialize = FALSE)

# source("utils.r")
# #source("../_shared/utils.r")
source_python("moo_gradient.py")
#
# # ARGUMENTS
# option_list = list(
#   make_option("--instance", type = "character", default = NULL, help = "instance"),
#   make_option("--budget", type = "numeric", default = 10000L, help = "The maximum number of allowed function evaluations"),
#   make_option("--seed", type = "numeric", default = 0, help = "The random seed"),
#   make_option("--save_solution", type= "character", default = NULL, "save solution set to an Rdata object"),
#   #Add parameters here
#   make_option("--mu", type = "numeric", default = 100L),
#   make_option("--step_size", type = "numeric", default = 0.001),
#   make_option("--sampling", type = "character", default = "uniform", help = "[uniform, LHS, grid]"),
#   make_option("--dominated_steer", type = "character", default = "NDS", help = "[M1, M2, M3, M4, M5, M6, NDS]")
# )
#
# opt_parser = OptionParser(option_list=option_list)
# opt = parse_args(opt_parser)
# # print(opt)
#
# #SET SEED
# # JAKOB: do we need to set the numpy random seed instead?
# set.seed(opt$seed)
#
# #INSTANCE LOADING
# obj.fn = parse_instance_file(opt$instance) # utils.R
# #print(paste(c(smoof::getRefPoint(obj.fn))))
# writeLines(paste("c REFERENCE POINT", paste(c(smoof::getRefPoint(obj.fn)), collapse = " ")))
#
# fn.lower = smoof::getLowerBoxConstraints(obj.fn)
# fn.upper = smoof::getUpperBoxConstraints(obj.fn)
#
# #ALGORITHM (HIGA-MO)
# writeLines('c ALGORITHM HIGA-MO')
#
# # Returns function that approximtes the gradient
# getGradientFun = function(fn, prec = 1e-8) {
#   function(x) {
#     f = fn(x)
#     n = length(x)
#     gr = lapply(seq_len(n), function(i) {
#       tmp = x
#       tmp[i] = tmp[i] + prec
#       return((fn(tmp) - f) / prec)
#     })
#   }
# }
#
# max.iter = floor(opt$budget / (4 * opt$mu))
# optimizer = MOO_HyperVolumeGradient( # via reticulate python interface
#   dim_d = smoof::getNumberOfParameters(obj.fn),
#   dim_o = smoof::getNumberOfObjectives(obj.fn),
#   fitness = obj.fn,
#   ref = smoof::getRefPoint(obj.fn),
#   gradient = getGradientFun(obj.fn),
#   maximize = !smoof::shouldBeMinimized(obj.fn),
#   maxiter = max.iter, # TODO: MAX.ITER / 2 / MU
#   lb = fn.lower,
#   ub = fn.upper,
#   mu = as.integer(opt$mu),
#   step_size = as.numeric(opt$step_size),
#   sampling = opt$sampling,
#   dominated_steer = opt$dominated_steer
# )
# result = optimizer$optimize()
# #print(result)
#
# writeLines(paste("c EVALUATIONS", smoof::getNumberOfEvaluations(obj.fn)))
#
# pareto_set = optimizer$pop # each column is a point
# solution_set = as.data.frame(t(apply(pareto_set, 2L, obj.fn)))
#
# # Parse the solution set to a common interface
# print_and_save_solution_set(solution_set)  # utils.R
#
# measures = compute_performance_metrics(solution_set, obj.fn, opt$instance) # utils
# print_measures(measures) # utils
