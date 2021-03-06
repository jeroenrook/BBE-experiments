#!/usr/bin/env Rscript

library(optparse)
library(smoof)
library(ecr)
library(ecr3vis)
library (plyr)

source("utils.r")

# ARGUMENTS
# ===
option_list = list(
  make_option("--instance", type = "character", default = NULL, help = "instance"),
  make_option("--budget", type = "numeric", default = 10000L, help = "The maximum number of allowed function evaluations"),
  make_option("--seed", type = "numeric", default = 0, help = "The random seed"),
  make_option("--save_solution", type= "character", default = NULL, "save solution set to an Rdata object"),
  make_option("--visualise", type= "character", default = NULL, help = "visualise population and solution set to a pdf"),
  #Add parameters here
  make_option("--mu", type = "numeric", default=100L),
  make_option("--mutator", type = "character", default = "mutPolynomial", help = "[mutGauss, mutPolynomial, mutUniform]"),
  make_option("--mutGauss_p", type = "numeric", default = 1L, help = ""),
  make_option("--mutGauss_sdev", type = "numeric", default = 0.05, help = ""),
  make_option("--mutPolynomial_p", type = "numeric", default = 0.2, help = ""),
  make_option("--mutPolynomial_eta", type = "numeric", default = 10, help = ""),
  make_option("--recombinator", type = "character", default = "recSBX", help = "[recCrossover, recIntermediate, recOX, recPMX, recSBX]"),
  make_option("--recSBX_eta", type = "numeric", default = 5, help = ""),
  make_option("--recSBX_p", type = "numeric", default = 1, help = "")
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

# print(opt)

#SET SEED
set.seed(opt$seed)

# INSTANCE LOADING
# ===
obj.fn = parse_instance_file(opt$instance) #utils.R
fn.lower = smoof::getLowerBoxConstraints(obj.fn)
fn.upper = smoof::getUpperBoxConstraints(obj.fn)
#print(paste(c(smoof::getRefPoint(obj.fn))))
writeLines(paste("c REFERENCE POINT", paste(c(smoof::getRefPoint(obj.fn)), collapse=" ")))

# ARGUMENT PROCESSING
# ===

# Mutator
if (opt$mutator == "mutGauss"){
    mutator = setup(mutGauss, p=opt$mutGauss_p, sdev=opt$mutGauss_sdev, lower=fn.lower, upper=fn.upper)
} else if (opt$mutator == "mutPolynomial"){
    mutator = setup(mutPolynomial, p=opt$mutPolynomial_p, eta=opt$mutPolynomial_eta, lower=fn.lower, upper=fn.upper)
} else if (opt$mutator == "mutUniform"){
    mutator = setup(mutUniform, lower=fn.lower, upper=fn.upper)
}

# Recombinator
if (opt$recombinator == "recSBX"){
    recombinator = setup(recSBX, eta=opt$recSBX_eta, p=opt$recSBX_p, lower=fn.lower, upper=fn.upper)
} else {
    recombinator = setup(eval(parse(text=opt$recombinator)))
}

# ALGORITHM (SMSEMOA)
# ===
writeLines('c ALGORITHM SMS
writeLines(paste("c REFERENCE POINT", paste(c(smoof::getRefPoint(obj.fn)), collapse=" ")))EMOA')
# We currently do nothing with the intermediate results, so we do not need the for-loop and can just run with the budget
# optimizer = ecr::smsemoa(
#   obj.fn,
#   smoof::getNumberOfObjectives(obj.fn),
#   lower=fn.lower,
#   upper=fn.upper,
#   terminators = list(stopOnEvals(max.evals = opt$budget)),
#   #ADD parameters here
#   mu = opt$mu,
#   mutator = mutator,
#   recombinator = recombinator,
#   );

# smsemoa = function(
#   obj.fn,
#   n.objectives = smoof::getNumberOfObjectives(obj.fn),
#   n.dim = NULL,
#   minimize = NULL,
#   lower = NULL,
#   upper = NULL,
#   mu = 100L,
#   ref.point = NULL,
#   mutator = setup(mutPolynomial, eta = 25, p = 0.2, lower = lower, upper = upper),
#   recombinator = setup(recSBX, eta = 15, p = 0.7, lower = lower, upper = upper),
#   terminators = list(stopOnIters(100L)),
#   ...) {

reference.point <- get_reference_point(obj.fn, opt$instance)
print(reference.point)
optimizer <- ecr(
    fitness.fun = obj.fn,
    n.objectives = smoof::getNumberOfObjectives(obj.fn),
    n.dim = n.dim,
    lower = fn.lower,
    upper = fn.upper,
    mu = opt$mu,
    lambda = 1L,
    mutator = mutator,
    recombinator = recombinator,
    representation = "float",
    survival.strategy = "plus",
    parent.selector = ecr::selSimple,
    survival.selector = setup(ecr::selDomHV, ref.point = reference.point),
    terminators = list(stopOnEvals(max.evals = opt$budget)),
    log.pop = TRUE,
)

#Create Tibble from the run
#TODO make more computational efficient
df <- tibble::tibble(fun_calls = numeric(), x1 = numeric(), x2 = numeric(), y1 = numeric(), y2 = numeric())
populations = getPopulations(optimizer$log)
for (gen in 1:length(populations)){
  if (gen %% 100 != 0){
    next
  }
  pop = populations[[gen]]
  for (individual in pop$population){
    # cat(".")
    fitness = attributes(individual)$fitness
    df <- df %>% add_row(fun_calls=gen, x1=individual[1], x2=individual[2], y1=fitness[1], y2=fitness[2])
  }
}

process_run(df, obj.fn, opt)
