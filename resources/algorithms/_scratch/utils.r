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
    measures <- compute_performance_metrics(df, obj.fn, opt$instance)

    if (!is.null(opt$save_solution)){
        writeLines("Save to file")
        saveRDS(measures, file=opt$save_solution)
    }

    #Depricated
    # if(!is.null(opt$visualise)){
    #     output <- opt$visualise
    #     pdf(output)
    #     plot(t(population), main="Decision space")
    #     plot(t(solution_set), main="Objective space")
    #     plot(t(pareto.matrix), main="Non-dominated set in objective space")
    #     dev.off()
    #     output <- paste0(opt$visualise,".Rdata")
    #     save(populationnd, pareto.matrix, file=output)
    # }

    print_measures(measures)
}

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
        measures$HV <- -ecr3vis::hv(solution_set + refoffset, reference.point)
    }
    else if(sum(reference.point < solution_set) == length(reference.point)){
        measures$HV <- -prod(reference.point - (solution_set+refoffset))
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
    abse <- ABSE::evaluate_results(populations, fn, ref.point=reference.point, basins = 1:5, join_fronts=FALSE)
    measures$ABSE <- abse$basin_separated_eval
    #AUC of trajectory
    #AUC of cummulative population generations#TODO Jonathan:  in ABSE package as option
    #ABSE score of all function calls combined (From smoof logger = fn)
    #ABSE score for last population

    #ABSE Join fronts
    #TODO Jonathan: reuse redundant computation somehow: return object from previous abse call
    measures$ABSEJF <- NULL#ABSE::evaluate_results(populations, fn, ref.point=reference.point, basins = 1:5, join_fronts=TRUE)

    return(measures)
}

print_measures <- function (measures){
    writeLines("s MEASURES")
    writeLines(paste("s",names(measures), measures))
}