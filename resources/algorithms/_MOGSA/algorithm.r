#!/usr/bin/env Rscript
library(optparse)
library(smoof)
library(mogsa) # remotes::install_github("kerschke/mogsa")

source("utils.r")

# ARGUMENTS
option_list = list(
  make_option("--instance", type = "character", default = NULL, help = "instance"),
  make_option("--budget", type = "numeric", default = 10000L, help = "The maximum number of allowed function evaluations"),
  make_option("--seed", type = "numeric", default = 0, help = "The random seed"),
  make_option("--save_solution", type= "character", default = NULL, "save solution set to an Rdata object"),
  make_option("--visualise", type= "character", default = NULL, help = "visualise population and solution set to a pdf"),
  #Add parameters here
  make_option("--max_no_basins", type = "numeric", default = 50L),
  make_option("--max_no_steps_ls", type = "numeric", default = 500L, help = ""),
  make_option("--scale_step", type = "numeric", default = 0.5, help = ""),
  make_option("--exploration_step", type = "numeric", default = 0.2, help = ""),
  make_option("--prec_grad", type = "numeric", default = 1e-6, help = ""),
  make_option("--prec_norm", type = "numeric", default = 1e-6, help = ""),
  make_option("--prec_angle", type = "numeric", default = 1e-4, help = ""),
  make_option("--ls_method", type = "character", default = "both", help = "[bisection, mo-ls, both]")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)
# print(opt)

#SET SEED
set.seed(opt$seed)

#INSTANCE LOADING
obj.fn = parse_instance_file(opt$instance) #utils.R
#print(paste(c(smoof::getRefPoint(obj.fn))))
writeLines(paste("c REFERENCE POINT", paste(c(smoof::getRefPoint(obj.fn)), collapse=" ")))

fn.lower = smoof::getLowerBoxConstraints(obj.fn)
fn.upper = smoof::getUpperBoxConstraints(obj.fn)

#ALGORITHM (MOGSA)
writeLines('c ALGORITHM MOGSA')

# We currently do nothing with the intermediate results, so we do not need the for-loop and can just run with the budget
runif_box = function(lower, upper) {
  u = runif(length(lower))
  u * (upper - lower) + lower
}

# run algorithm
optimizer = runMOGSA(
  ind = runif_box(fn.lower, fn.upper),
  fn = obj.fn,
  lower = fn.lower,
  upper = fn.upper,
  max.no.basins = as.integer(opt$max_no_basins),
  max.no.steps = as.integer(opt$max_no_steps),
  scale.step = opt$scale_step,
  max.no.steps.exploration =  400, # Christian said that this one should not be tuned
  exploration.step = opt$exploration_step,
  prec.norm = opt$prec_norm,
  prec.angle = opt$prec_angle,
  prec.grad = opt$prec_grad,
  ls.method = opt$ls_method,
  show.info = FALSE
)

#print(str(optimizer))

writeLines(paste("c EVALUATIONS", smoof::getNumberOfEvaluations(obj.fn)))

# Parse the solution set to a common interface
# is this what we need? No, we need to compute the function values ourselves :)
# Checked with DTZL2, which is visualised on the MOGSA github page for comparison
# print(optimizer[, c("x1", "x2"), drop = FALSE])
population <- optimizer[, c("x1", "x2"), drop = FALSE]
solution_set <- as.data.frame(t(apply(population, 1, obj.fn)))
print_and_save_solution_set(solution_set)  #utils.R

measures <- compute_performance_metrics(population, solution_set, obj.fn, opt$instance) #utils
print_measures(measures) #utils
