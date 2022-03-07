#!/usr/bin/env Rscript
library(optparse)
library(smoof)
library(MOEADr) #devtools::install_github("fcampelo/MOEADr")

source("utils.r")

# ARGUMENTS
option_list = list(
  make_option("--instance", type = "character", default = NULL, help = "instance"),
  make_option("--budget", type = "numeric", default = 10000L, help = "The maximum number of allowed function evaluations"),
  make_option("--seed", type = "numeric", default = 1, help = "The random seed"),
  make_option("--save_solution", type= "character", default = NULL, help = "save solution set to an Rdata object"),
  make_option("--visualise", type= "character", default = NULL, help = "visualise population and solution set to a pdf"),
  #Add parameters here
# decomp categorical {SLD, Uniform} [SLD]
# neighbor categorical {lambda,x} [lambda]
# T integer [10,40] [20]
# deltap real [0.1,1] [1]
# aggfunction categorical {wt,awt,pbi} [wt]
# theta real [2,20] [10]
# update categorical {standard,best,restricted} [standard]
# archive categorical {0,1} [0]
# nr integer [1,10] [1]
# Tr integer [4,20] [8]
  make_option("--decomp", type = "character", default = "SLD"),
  make_option("--neighbor", type = "character", default = "lambda"),
  make_option("--T", type = "numeric", default = 20L),
  make_option("--deltap", type = "numeric", default = 1.0),
  make_option("--aggfunction", type = "character", default = "wt"),
  make_option("--theta", type = "numeric", default = 10L),
  make_option("--update", type = "character", default = "standard"),
  make_option("--archive", type = "numeric", default = 0),
  make_option("--nr", type = "numeric", default = 1L),
  make_option("--Tr", type = "numeric", default = 8L),
# varop1 categorical {binrec,diffmut,polymut,sbx} [sbx]
# varop2 categorical {binrec,diffmut,polymut,sbx} [polymut]
# varop3 categorical {binrec,diffmut,polymut,sbx,none} [none]
# varop4 categorical {localsearch,none} [none]
   make_option("--varop1", type = "character", default = "sbx"),
   make_option("--varop2", type = "character", default = "polymut"),
   make_option("--varop3", type = "character", default = "none"),
   make_option("--varop4", type = "character", default = "none"),
# varop1binrec real [0,1] []
# varop2binrec real [0,1] []
# varop3binrec real [0,1] []
   make_option("--varop1binrec", type = "numeric", default = 0.5),
   make_option("--varop2binrec", type = "numeric", default = 0.5),
   make_option("--varop3binrec", type = "numeric", default = 0.5),
# varop1diffmut categorical {rand,mean,wgi} []
# varop2diffmut categorical {rand,mean,wgi} []
# varop3diffmut categorical {rand,mean,wgi} []
   make_option("--varop1diffmut", type = "character", default = "rand"),
   make_option("--varop2diffmut", type = "character", default = "rand"),
   make_option("--varop3diffmut", type = "character", default = "rand"),
# varop1polymuteta real [1,100] []
# varop1polymutpm real [0,1] []
# varop2polymuteta real [1,100] []
# varop2polymutpm real [0,1] []
# varop3polymuteta real [1,100] []
# varop3polymutpm real [0,1] []
   make_option("--varop1polymuteta", type = "numeric", default = 20),
   make_option("--varop1polymutpm", type = "numeric", default = 0.5),
   make_option("--varop2polymuteta", type = "numeric", default = 20),
   make_option("--varop2polymutpm", type = "numeric", default = 0.5),
   make_option("--varop3polymuteta", type = "numeric", default = 20),
   make_option("--varop3polymutpm", type = "numeric", default = 0.5),
# varop1sbxeta real [1,100] []
# varop1sbxpc real [0,1] []
# varop2sbxeta real [1,100] []
# varop2sbxpc real [0,1] []
# varop3sbxeta real [1,100] []
# varop3sbxpc real [0,1] []
   make_option("--varop1sbxeta", type = "numeric", default = 20),
   make_option("--varop1sbxpc", type = "numeric", default = 1),
   make_option("--varop2sbxeta", type = "numeric", default = 20),
   make_option("--varop2sbxpc", type = "numeric", default = 1),
   make_option("--varop3sbxeta", type = "numeric", default = 20),
   make_option("--varop3sbxpc", type = "numeric", default = 1),
# lstype categorical {tpqa,dvls} []
# gammals real [0,0.5] []
  make_option("--lstype", type = "character", default = "tpqa"),
  make_option("--gammals", type = "numeric", default = 0.2)
)

# make_option("--variation", type = "character", default = "", help="[diffmut, localsearch, none, polymut]"),
# make_option("--variation_diffmut_phi", type = "numeric", default = 0.5, help="Mutation parameter. Either a scalar numeric constant, or NULL for randomly chosen between 0 and 1 (independently sampled for each operation)."),
# make_option("--variation_diffmut_basis", type = "character", default = 0.5, help="[rand, mean]"),
# make_option("--constraint", type = "character", default = "", help="[nmone, penalty, vbr]"),
# make_option("--scaling", type = "character", default = "", help=""),


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

#ALGORITHM (MOEAD)
writeLines('c ALGORITHM MOEA/Dr')

make_vectorized_smoof_fun = function (myfun, ...) {
  force(myfun)
  function(X, ...) {
    t(apply(X, MARGIN = 1, FUN = myfun))
  }
}

#Taken from https://fcampelo.github.io/MOEADr/articles/Comparison_Usage.html
#problem
objfun <- make_vectorized_smoof_fun(obj.fn)
problem <- list(name       = 'objfun',
               xmin = fn.lower,
               xmax = fn.upper,
               m = 2L)

## 2. Decomp
  decomp <- list(name = opt$decomp)
  if(decomp$name == "SLD") decomp$H <- 99 # <-- yields N = 100
  if(decomp$name == "Uniform") decomp$N <- 100

  ## 3. Neighbors
  neighbors <- list(name    = opt$neighbor,
                    T       = opt$T,
                    delta.p = opt$deltap)

  ## 4. Aggfun
  aggfun <- list(name = opt$aggfunction)
  if (aggfun$name == "pbi") aggfun$theta <- opt$theta

  ## 5. Update
  update <- list(name       = opt$update,
                 UseArchive = as.logical(opt$archive))
  if (update$name != "standard") update$nr <- opt$nr
  if (update$name == "best")     update$Tr <- opt$Tr

  ## 6. Scaling
  scaling <- list(name = "simple")
  ## 7. Constraint
  constraint<- list(name = "none")
  ## 8. Stop criterion
  stopcrit = list(list(name = "maxeval", maxeval = opt$budget))
  ## 9. Echoing
  showpars  <- list(show.iters = "none")

  ## 10. Variation stack
  variation <- list(list(name = opt$varop1),
                    list(name = opt$varop2),
                    list(name = opt$varop3),
                    list(name = opt$varop4),
                    list(name = "truncate"))

  for (i in seq_along(variation)){
    if (variation[[i]]$name == "binrec") {
      variation[[i]]$rho <- get(paste0("varop", i ,"binrec"), opt)
    }
    if (variation[[i]]$name == "diffmut") {
      variation[[i]]$basis <- get(paste0("varop", i ,"diffmut"), opt)
      variation[[i]]$Phi   <- NULL
    }
    if (variation[[i]]$name == "polymut") {
      variation[[i]]$etam <- get(paste0("varop", i ,"polymuteta"), opt)
      variation[[i]]$pm   <- get(paste0("varop", i ,"polymutpm"), opt)
    }
    if (variation[[i]]$name == "sbx") {
      variation[[i]]$etax <- get(paste0("varop", i ,"sbxeta"), opt)
      variation[[i]]$pc   <- get(paste0("varop", i ,"sbxpc"), opt)
    }
    if (variation[[i]]$name == "localsearch") {
      variation[[i]]$type     <- opt$lstype
      variation[[i]]$gamma.ls <- opt$gammals
    }
  }

  ## 11. Seed
  seed <- opt$seed

optimizer <- moead(preset = NULL,
               problem, decomp,  aggfun, neighbors, variation, update,
               constraint, scaling, stopcrit, showpars, seed)

population = as.data.frame(optimizer$X)
solution_set = as.data.frame(optimizer$Y)
#pareto_set = as.data.frame(res$X)

writeLines(paste("c EVALUATIONS", smoof::getNumberOfEvaluations(obj.fn)))

# Parse the solution set to a common interface
print_and_save_solution_set(solution_set)  #utils.R

measures <- compute_performance_metrics(population, solution_set, obj.fn, opt$instance) #utils
print_measures(measures) #utils
