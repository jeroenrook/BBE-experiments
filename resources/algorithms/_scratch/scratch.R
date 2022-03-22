#!/usr/bin/env Rscript

options(error=traceback)

#R LIBRARIES
library(optparse)
library(smoof)
library(ecr)

source("~/Documents/Work/Projects/MMMOO/ABSE/resources/algorithms/_shared/utils.r")

#ARGUMENTS
option_list = list(
  make_option("--instance", type = "character", default = "./instances/MMF2", help = "instance"),
  make_option("--budget", type = "numeric", default = 20000L, help = "The maximum number of allowed function evaluations"),
  make_option("--seed", type = "numeric", default = 1, help = "The random seed"),
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

#Load instance #TODO move to utils.r
parse_instance_file = function(filename){
    content = readChar(filename, nchars=file.info(filename)$size)
    obj.fn <- eval(parse(text=content))
    # obj.fn <- smoof::makeDTLZ1Function(dimensions = 2L, n.objectives = 2L)
    obj.fn = smoof::addLoggingWrapper(obj.fn, logg.x = TRUE, logg.y = TRUE, size=opt$budget)
    return(obj.fn)
}

obj.fn = parse_instance_file(opt$instance) #TODO move to parse_instance_file in utils.R
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

#ALGORITHM (NGSA-II)
writeLines('c ALGORITHM NGSA-II')
# From ECR source:
# nsga2 = function(
#   fitness.fun,
#   n.objectives = NULL,
#   n.dim = NULL,
#   minimize = NULL,
#   lower = NULL,
#   upper = NULL,
#   mu = 100L,
#   lambda = mu,
#   mutator = setup(mutPolynomial, eta = 25, p = 0.2, lower = lower, upper = upper),
#   recombinator = setup(recSBX, eta = 15, p = 0.7, lower = lower, upper = upper),
#   terminators = list(stopOnIters(100L)),
#   ...)
# DEFAULT NSGA2 call
# optimizer = ecr::nsga2(
#   obj.fn,
#   smoof::getNumberOfObjectives(obj.fn),
#   lower = fn.lower,
#   upper = fn.upper,
#   terminators = list(stopOnEvals(max.evals = opt$budget)),
#   #ADD parameters here
#   mu = opt$mu,
#   mutator = mutator,
#   recombinator = recombinator,
#   log.pop = TRUE,
# )

optimizer = ecr(
  fitness.fun = obj.fn,
  n.objectives = smoof::getNumberOfObjectives(obj.fn),
  n.dim = n.dim,
  minimize = NULL,
  lower = fn.lower,
  upper = fn.upper,
  mu = opt$mu,
  lambda = opt$mu,
  representation = "float",
  survival.strategy = "plus",
  parent.selector = selSimple,
  mutator = mutator,
  recombinator = recombinator,
  log.pop = TRUE,
  survival.selector = selNondom,
  terminators = list(stopOnEvals(max.evals = opt$budget)))

#Create Tibble from the run
df <- tibble::tibble(fun_calls = numeric(), x1 = numeric(), x2 = numeric(), y1 = numeric(),y2 = numeric())
populations = getPopulations(optimizer$log)
for (gen in 1:length(populations)){
  # cat(gen)
  pop = populations[[gen]]
  for (individual in pop$population){
    # cat(".")
    fitness = attributes(individual)$fitness
    df <- df %>% add_row(fun_calls=gen, x1=individual[1], x2=individual[2], y1=fitness[1], y2=fitness[2])
  }
}

# The following should be handled in the generic utils.r file
# populations: a Tibble with fun_calls, decision space vector, obective space vector
# fn: smoof function
# instance_path: string of instance path
compute_performance_metrics <- function (populations, fn, instance_path){
  #Get reference data
  instance_name <- tail(unlist(strsplit(instance_path,"/")), n=1)
  load("refdata.RData")
  reference.point <- smoof::getRefPoint(fn)
  if (is.null(reference.point)){
      reference.point <- references[[instance_name]]$refpoint
  }
  refoffset <- references[[instance_name]]$newoffset
  besthv <- references[[instance_name]]$newhv

  #Destil last population from tibble
  # population <- t(data.matrix(population))
  # colnames(population) <- 1:dim(population)[2]
  # popnondom <- nondominated(apply(population, 2, fn))
  # print(popnondom)
  # populationnd <- population[, popnondom] #Filter non dominated set
  # solution_set <- t(data.matrix(solution_set)) #No guarantee of non-domination

  last_pop <- populations %>% filter(max(populations$fun_calls) == populations$fun_calls)
  # last non-dominated population's objective space for HV
  solution_set <- t(as.matrix(last_pop %>% select(y1, y2)))
  solution_set <- solution_set[, ecr::nondominated(solution_set)]
  # last population's desision space for SP
  population <- t(as.matrix(last_pop %>% select(x1, x2)))

  #Compute measures
  measures <- list()
  #HV MAXIMISE, hence minimise
  #refpoint=pareto.refpoint, newrefpoint=newrefpoint, newoffset=newoffset, newfront=newfront
  #Only use non-dominated set:
  # print(ecr::nondominated(solution_set))
  # pareto.matrix <- solution_set[, ecr::nondominated(solution_set)]
  # populationnd <- population[, ecr::nondominated(solution_set)]
  # print(pareto.matrix)
  # print(populationnd)

  #HV
  if(is.matrix(solution_set)){
      #Limit for MOGSA to prevent memory issues
      if(ncol(solution_set) > 2000) solution_set <- solution_set[,sample(ncol(solution_set), 2000)]
      measures$HV <- -ecr3vis::hv(solution_set, reference.point)
      #print(pareto.matrix + newoffset)
      measures$HVN <- -ecr3vis::hv(solution_set + refoffset, reference.point)
      # measures$SP <- -ecr3vis::solow_polasky(pareto.matrix)
  }
  else {
      if(sum(reference.point < solution_set) == length(reference.point)){
          measures$HV <- -prod(reference.point - solution_set)
          measures$HVN <- -prod(reference.point - (solution_set+refoffset))
      } else {
          measures$HV <- 0
          measures$HVN <- 0
      }
      # measures$SP <- -1
  }
  measures$HVN <- measures$HVN / besthv #Normalized

  #SP
  if(is.matrix(population)){
      if(ncol(population) > 2000) population <- population[,sample(ncol(population), 2000)]
      measures$SP <- -ecr3vis::solow_polasky(population)
  }
  else{
      measures$SP <- -1
  }

  #IDG+ MINIMISE
  measures$IGDP <- NULL #ecr3vis::igdp(pareto.matrix, reference.front) #JEROEN: Not used so do not waste resources

  #ABSE
  abse <- ABSE::evalutate_results(populations, fn, ref.point=reference.point, basins = 1:5, join_fronts=FALSE)
  measures$ABSE <- abse$basin_separated_eval
  #AUC of trajectory
  #AUC of cummulative population
  #

  #ABSE Join fronts
  #TODO: reuse redundant computation somehow
  measures$ABSEJF <- NULL#ABSE::evalutate_results(populations, fn, ref.point=reference.point, basins = 1:5, join_fronts=TRUE)

  #Administrative procedures
  #TODO: move to seperate functions
  if (!is.null(opt$save_solution)){
      writeLines("Save to file")
      #save(solution_set, file=opt$save_solution)
      measuresdf <- data.frame(Reduce(rbind, measures))

      HV = measures$HV
      HVN = measures$HVN
      IGDP = measures$IGDP
      SP = measures$SP
      ABSE = measure$ABSE
      ABSEJF = measure$ABSEJF

      # save(pareto.matrix, populationnd, measuresdf , HV, SP, SPD , IGDP, reference.point, file=opt$save_solution)
      save(HV, SP, HVN, ABSE, ABSEJF, file=opt$save_solution)
  }

  if(!is.null(opt$visualise)){
      output <- opt$visualise
      pdf(output)

      plot(t(population), main="Decision space")
      plot(t(solution_set), main="Objective space")
      plot(t(pareto.matrix), main="Non-dominated set in objective space")
      dev.off()

      output <- paste0(opt$visualise,".Rdata")
      save(populationnd, pareto.matrix, file=output)
  }
  #writeLines(paste0("s REFERENCE", paste(reference.point,collapse=","), " POPSIZE (", toString(dim(population)), ") NON-DOMINATED POP (", toString(dim(populationnd)), ") NON-DOMINATED OBJ (", toString(dim(pareto.matrix)), ")"))
  return(measures)
}

compute_performance_metrics(df, obj.fn, opt$instance)
# writeLines(paste("c EVALUATIONS", smoof::getNumberOfEvaluations(obj.fn)))
# last_pop <- df %>% filter(max(df$fun_calls) == df$fun_calls)

# load("refdata.RData")
# instance_path = opt$instance
# instance_name <- tail(unlist(strsplit(instance_path,"/")), n=1)
# if (is.null(reference.point)){
#     reference.point <- references[[instance_name]]$refpoint
# }
#
#
# abse <- ABSE::evalutate_results(df, obj.fn, ref.point=reference.point, basins = 1:5)
# a = abse$basin_separated_eval
# ggplot(a, aes(x=fun_calls)) + geom_line(aes(y=value_basin1, colour = "basin1")) + geom_line(aes(y=value_basin2, colour = "basin2")) + geom_line(aes(y=value_basin3, colour = "basin3")) + geom_line(aes(y=value_basin4, colour = "basin4"))
#
# dest <- paste0("figures/",instance_name,"-abse.pdf")
# print(dest)
# ggsave(dest, width=4, height=3, units="in")

#
# Tibble of populations: Generation, Decision space points, Objective space points


# Parse the solution set to a common interface
# population <- do.call(rbind.data.frame, optimizer$pareto.set)
# for (dim in 1:length(population)){
#     names(population)[dim] <- paste0("x", as.character(dim))
# }

# solution_set <- optimizer$pareto.front
# print_and_save_solution_set(solution_set)  #utils.R
#
# measures <- compute_performance_metrics(population, solution_set, obj.fn, opt$instance) #utils
# print_measures(measures) #utils