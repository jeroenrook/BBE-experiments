library("smoof")
library("ecr3vis")
library("ABSE")
library("tidyverse")

options(error = quote({dump.frames(to.file=TRUE); q()}))

parse_instance_file <- function(filename,budget=1000){
    content <- readChar(filename, nchars=file.info(filename)$size)
    obj.fn <- eval(parse(text=content))
    obj.fn <- smoof::addLoggingWrapper(obj.fn, logg.x = TRUE, logg.y = TRUE, size=budget)
    return(obj.fn)
}

process_run <- function(populations, fn, opt){
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
     reference.point <- smoof::getRefPoint(fn)
     if (is.null(reference.point)){
         reference.point <- references[[instance_name]]$refpoint
     }
     return (reference.point)
 }

# populations: a Tibble with fun_calls, decision space vector, obective space vector
# fn: smoof function
# instance_path: string of instance path
compute_performance_metrics <- function (populations, fn, opt){
    #Get reference data
    instance_path = opt$instance
    instance_name <- tail(unlist(strsplit(instance_path,"/")), n=1)
    load("refdata.RData")
    reference.point <- get_reference_point(fn, instance_path)
    #refoffset <- references[[instance_name]]$newoffset
    besthv <- references[[instance_name]]$hv

    #Destil last population from tibble
    last_pop <- populations %>% filter(max(populations$fun_calls) == populations$fun_calls)
    # last non-dominated population's objective space for HV
    solution_set <- t(as.matrix(last_pop %>% select(y1, y2)))
    solution_set <- solution_set[, ecr::nondominated(solution_set)]
    # last population's desision space for SP
    population <- t(as.matrix(last_pop %>% select(x1, x2)))

    #Compute measures
    measures <- list()
    #HV MAXIMISE, hence minimise
    if(is.matrix(solution_set)){
        #Limit for MOGSA and MOLE to prevent memory issues
        if(ncol(solution_set) > 2000) solution_set <- solution_set[,sample(ncol(solution_set), 2000)]
        measures$HV <- -ecr3vis::hv(solution_set, reference.point)
    }
    else if(sum(reference.point < solution_set) == length(reference.point)){
        measures$HV <- -prod(reference.point - (solution_set))
    }
    else {
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

    #ABSE
    #TODO: IDEA: Make also a tibble of the smoof logging wrapper and use that to compute the ABSE measures

    #TODO Jonathan: basins levels sorted on HV
    cat("ABSE ITERATIVE! \n")
    unwrapped.fn = smoof::getWrappedFunction(fn)
    abse <- ABSE::evalutate_results(populations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:4,
                                    keep.points=TRUE,
                                    join_fronts=FALSE)
    measures$ABSE.HV.MEAN <- -tail(abse$basin_separated_eval$mean_value, n=1)
    measures$ABSE.HV.AUC.MEAN <- -tail(abse$basin_separated_eval$auc_hv_mean, n=1)
    measures$ABSE.HV.AUC.B1 <- -tail(abse$basin_separated_eval$auc_hv1, n=1)

    cat("ABSE CUMULATIVE \n")
    absec <- ABSE::evalutate_results(populations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:4,
                                    keep.points=TRUE,
                                    join_fronts=FALSE,
                                    design=abse,
                                    efficient_sets = abse$efficientSets,
                                    dec_space_labels = abse$decSpaceLabels)
    measures$ABSE.CUM.HV.MEAN <- -tail(absec$basin_separated_eval$mean_value, n=1)
    measures$ABSE.CUM.HV.AUC.MEAN <- -tail(absec$basin_separated_eval$auc_hv_mean, n=1)
    measures$ABSE.CUM.HV.AUC.B1 <- -tail(absec$basin_separated_eval$auc_hv1, n=1)

    cat("ABSE JF ITERATIVE \n")
    absej <- ABSE::evalutate_results(populations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:4,
                                    keep.points=TRUE,
                                    join_fronts=FALSE,
                                    design=abse)
    measures$ABSE.JF.HV.MEAN <- -tail(absej$basin_separated_eval$mean_value, n=1)
    measures$ABSE.JF.HV.AUC.MEAN <- -tail(absej$basin_separated_eval$auc_hv_mean, n=1)
    measures$ABSE.JF.HV.AUC.B1 <- -tail(absej$basin_separated_eval$auc_hv1, n=1)

    cat("ABSE JF CUMULATIVE \n")
    absejc <- ABSE::evalutate_results(populations,
                                    unwrapped.fn,
                                    ref.point=reference.point,
                                    basins = 1:4,
                                    keep.points=TRUE,
                                    join_fronts=FALSE,
                                    design=abse,
                                    efficient_sets = abse$efficientSets,
                                    dec_space_labels = abse$decSpaceLabels)
    measures$ABSE.JF.CUM.HV.MEAN <- -tail(absejc$basin_separated_eval$mean_value, n=1)
    measures$ABSE.JF.CUM.HV.AUC.MEAN <- -tail(absejc$basin_separated_eval$auc_hv_mean, n=1)
    measures$ABSE.JF.CUM.HV.AUC.B1 <- -tail(absejc$basin_separated_eval$auc_hv1, n=1)

    #AUC of trajectory
    #AUC of cummulative population generations#TODO Jonathan:  in ABSE package as option
    #ABSE score of all function calls combined (From smoof logger = fn)
    #ABSE score for last population


    if(!is.null(opt$visualise)){
        output <- opt$visualise
        # pdf(output)
        # plot(t(population), main="Decision space")
        # plot(t(solution_set), main="Objective space")
        # plot(t(pareto.matrix), main="Non-dominated set in objective space")
        # dev.off()
        output <- paste0(opt$visualise,".Rdata")
        save(abse, absec, absej, absejc, file=output)
    }

    return(measures)
}

print_measures <- function (measures){
    writeLines("s MEASURES")
    writeLines(paste("s",names(measures), measures))
}