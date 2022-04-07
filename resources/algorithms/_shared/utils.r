library("smoof")
library("ecr3vis")
library("ABSE")
library("tidyverse")
library("moPLOT")

#options(error = quote({dump.frames(to.file=TRUE); q()}))

parse_instance_file <- function(filename,budget=1000){
    content <- readChar(filename, nchars=file.info(filename)$size)
    obj.fn <- eval(parse(text=content))
    obj.fn <- smoof::addLoggingWrapper(obj.fn, logg.x = TRUE, logg.y = TRUE, size=budget)
    return(obj.fn)
}

process_run <- function(populations, fn, opt, ...){
    measures <- compute_performance_metrics(df, obj.fn, opt)

    if (!is.null(opt$save_solution)){
        writeLines("Save to file", opt$save_solution)
        saveRDS(as.data.frame(measures), file=opt$save_solution)
    }

    print_measures(measures)
}

 get_reference_point <- function(fn, instance_path){
     instance_name <- tail(unlist(strsplit(instance_path,"/")), n=1)
     load("refdata.RData")
     reference.point <- references[[instance_name]]$refpoint
     return (reference.point)
 }

get_tibble_logger <- function(fn){
    logged_values <- smoof::getLoggedValues(fn)
    dec <- logged_values$pars
    obj <- t(logged_values$obj.vals)
    colnames(dec) <- c('x1', 'x2')
    colnames(obj) <- c('y1', 'y2')
    # just pretend each 100 evaluations is a single population
    # that means: only cumulative measures are useful for now!
    fun_calls = rep(100 * 1:(dim(dec)[1] / 100), each = 100)
    populations = cbind(fun_calls = fun_calls, dec, obj)
    populations = as_tibble(populations)

    return(populations)
}

# populations: a Tibble with fun_calls, decision space vector, obective space vector
# fn: smoof function
# instance_path: string of instance path
compute_performance_metrics <- function (populations, fn, opt, last_pop=NULL){
    #Get reference data
    instance_path = opt$instance
    instance_name <- tail(unlist(strsplit(instance_path,"/")), n=1)
    load("refdata.RData")
    reference.point <- get_reference_point(fn, instance_path)
    #refoffset <- references[[instance_name]]$newoffset
    besthv <- references[[instance_name]]$hv

    if(is.null(last_pop)){
        #Destil last population from tibble
        last_pop <- populations %>% filter(max(populations$fun_calls) == populations$fun_calls)
    }
    # last non-dominated population's objective space for HV
    solution_set <- t(as.matrix(last_pop %>% select(y1, y2)))
    # last population's desision space for SP
    population <- t(as.matrix(last_pop %>% select(x1, x2)))

    #Compute measures
    measures <- list()
    #HV MAXIMISE, hence minimise
    if(is.matrix(solution_set)){
        # cat("ecr3vis::hv \n")
        #Limit for MOGSA and MOLE to prevent memory issues
        if(ncol(solution_set) > 2000) solution_set <- solution_set[,sample(ncol(solution_set), 2000)]
        measures$HV <- -ecr3vis::hv(solution_set, reference.point)
    }
    else if(sum(reference.point < solution_set) == length(reference.point)){
        # cat("prod(reference.point - (solution_set)) \n")
        measures$HV <- -prod(reference.point - (solution_set))
    }
    else {
        # cat("HV = 0 \n")
        measures$HV <- 0
    }
    measures$HVN <- measures$HV / besthv #Normalized

    #SP
    if(is.matrix(population)){
    #TODO move outside and merge to single sampling
        if(ncol(population) > 2000) population <- population[,sample(ncol(population), 2000)]
        measures$SP <- -ecr3vis::solow_polasky(population)
    }
    else{
        measures$SP <- -1
    }

    cat("ABSE ITERATIVE! \n")
    unwrapped.fn = smoof::getWrappedFunction(fn)
    abse <- ABSE::evalutate_results(populations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:40,
                                    keep_points=FALSE,
                                    join_fronts=FALSE)
    measures$ABSEHVMEAN <- -tail(abse$basin_separated_eval$mean_value, n=1)
    measures$ABSEHVMEANNORM <- measures$ABSEHVMEAN / besthv
    # measures$ABSEHVAUCMEAN <- -tail(abse$basin_separated_eval$auc_hv_mean, n=1)
    # measures$ABSEHVAUCMEANNORM <- measures$ABSEHVAUCMEAN / besthv
    # measures$ABSEHVAUCB1 <- -tail(abse$basin_separated_eval$auc_hv1, n=1)

    cat("ABSE CUMULATIVE \n")

    fnpopulations = get_tibble_logger(fn)
    absec <- ABSE::evalutate_results(fnpopulations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:40,
                                    keep_points=TRUE,
                                    join_fronts=FALSE,
                                    design=abse,
                                    efficient_sets = abse$efficientSets,
                                    dec_space_labels = abse$decSpaceLabels)
    measures$ABSECUMHVMEAN <- -tail(absec$basin_separated_eval$mean_value, n=1)
    measures$ABSECUMHVMEANNORM <- measures$ABSECUMHVMEAN / besthv
    measures$ABSECUMHVAUCMEAN <- -tail(absec$basin_separated_eval$auc_hv_mean, n=1)
    measures$ABSECUMHVAUCMEANNORM <- measures$ABSECUMHVAUCMEAN / besthv
    # measures$ABSECUMHVAUCB1 <- -tail(absec$basin_separated_eval$auc_hv1, n=1)

    # cat("ABSE JF ITERATIVE \n")
    # absej <- ABSE::evalutate_results(populations,
    #                                 unwrapped.fn,
    #                                 ref.point=reference.point,
    #                                 basins = 1:4,
    #                                 keep_points=FALSE,
    #                                 join_fronts=TRUE,
    #                                 design=abse)
    # measures$ABSEJFHVMEAN <- -tail(absej$basin_separated_eval$mean_value, n=1)
    # measures$ABSEJFHVAUCMEAN <- -tail(absej$basin_separated_eval$auc_hv_mean, n=1)
    # measures$ABSEJFHVAUCB1 <- -tail(absej$basin_separated_eval$auc_hv1, n=1)
    #
    # cat("ABSE JF CUMULATIVE \n")
    # absejc <- ABSE::evalutate_results(populations,
    #                                 unwrapped.fn,
    #                                 ref.point=reference.point,
    #                                 basins = 1:4,
    #                                 keep_points=TRUE,
    #                                 join_fronts=TRUE,
    #                                 design=abse)
    # measures$ABSEJFCUMHVMEAN <- -tail(absejc$basin_separated_eval$mean_value, n=1)
    # measures$ABSEJFCUMHVAUCMEAN <- -tail(absejc$basin_separated_eval$auc_hv_mean, n=1)
    # measures$ABSEJFCUMHVAUCB1 <- -tail(absejc$basin_separated_eval$auc_hv1, n=1)


    if(!is.null(opt$visualise)){
        output <- opt$visualise
        # pdf(output)
        # plot(t(population), main="Decision space")
        # plot(t(solution_set), main="Objective space")
        # plot(t(pareto.matrix), main="Non-dominated set in objective space")
        # dev.off()
        design <- abse
        output <- paste0(opt$visualise,".Rdata")
        save(abse, absec, absej, absejc, file=output)
    }

    return(measures)
}

print_measures <- function (measures){
    writeLines("s MEASURES")
    writeLines(paste("s",names(measures), measures))
}