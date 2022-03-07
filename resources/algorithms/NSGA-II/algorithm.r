#!/usr/bin/env Rscript

#R LIBRARIES
library(optparse)
library(smoof)
library(ecr)

source("utils.r")

#ARGUMENTS
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

#INSTANCE LOADING
obj.fn = parse_instance_file(opt$instance) #utils.R
#print(paste(c(smoof::getRefPoint(obj.fn))))
writeLines(paste("c REFERENCE POINT", paste(c(smoof::getRefPoint(obj.fn)), collapse=" ")))

fn.lower = smoof::getLowerBoxConstraints(obj.fn)
fn.upper = smoof::getUpperBoxConstraints(obj.fn)

#ARGUMENT PROCESSING
#Mutator
if (opt$mutator == "mutGauss"){
    mutator = setup(mutGauss, p=opt$mutGauss_p, sdev=opt$mutGauss_sdev, lower=fn.lower, upper=fn.upper)
} else if (opt$mutator == "mutPolynomial"){
    mutator = setup(mutPolynomial, p=opt$mutPolynomial_p, eta=opt$mutPolynomial_eta, lower=fn.lower, upper=fn.upper)
} else if (opt$mutator == "mutUniform"){
    mutator = setup(mutUniform, lower=fn.lower, upper=fn.upper)
}

#Recombinator
if (opt$recombinator == "recSBX"){
    recombinator = setup(recSBX, eta=opt$recSBX_eta, p=opt$recSBX_p, lower=fn.lower, upper=fn.upper)
} else {
    recombinator = setup(eval(parse(text=opt$recombinator)))
}

#ALGORITHM (SMSEMOA)
writeLines('c ALGORITHM NGSA-II')
# We currently do nothing with the intermediate results, so we do not need the for-loop and can just run with the budget
optimizer = ecr::nsga2(
  obj.fn,
  smoof::getNumberOfObjectives(obj.fn),
  lower = fn.lower,
  upper = fn.upper,
  terminators = list(stopOnEvals(max.evals = opt$budget)),
  #ADD parameters here
  mu = opt$mu,
  mutator = mutator,
  recombinator = recombinator
)

writeLines(paste("c EVALUATIONS", smoof::getNumberOfEvaluations(obj.fn)))

# Parse the solution set to a common interface
population <- do.call(rbind.data.frame, optimizer$pareto.set)
for (dim in 1:length(population)){
    names(population)[dim] <- paste0("x", as.character(dim))
}

solution_set <- optimizer$pareto.front
print_and_save_solution_set(solution_set)  #utils.R

measures <- compute_performance_metrics(population, solution_set, obj.fn, opt$instance) #utils
print_measures(measures) #utils




