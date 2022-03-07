library("smoof")
library("ecr3vis")
library("ABSE")
library("tidyverse")

options(error = quote({dump.frames(to.file=TRUE); q()}))

parse_instance_file = function(filename){
    content = readChar(filename, nchars=file.info(filename)$size)
    obj.fn <- eval(parse(text=content))
    obj.fn = smoof::addCountingWrapper(obj.fn)
    return(obj.fn)
}

print_and_save_solution_set <- function (solution_set){
    writeLines("s SOLUTION SET (not showed)")
    print(solution_set)
    # if (!is.null(opt$save_solution)){
    #     writeLines("Save to file")
    #     #save(solution_set, file=opt$save_solution)
    #     write.table(solution_set, file=opt$save_solution)
    # }
}

compute_performance_metrics <- function (population, solution_set, fn, instance_path){
    #Get reference data
    population <- t(data.matrix(population))
    colnames(population) <- 1:dim(population)[2]
    popnondom <- nondominated(apply(population, 2, fn))
    print(popnondom)
    populationnd <- population[, popnondom] #Filter non dominated set

    solution_set <- t(data.matrix(solution_set)) #No guarantee of non-domination
    instance_name <- tail(unlist(strsplit(instance_path,"/")), n=1)

    load("refdata.RData")

    reference.point <- smoof::getRefPoint(fn)
    #newrefpoint <- smoof::getRefPoint(fn)
    if (is.null(reference.point)){
        reference.point <- references[[instance_name]]$refpoint
        #newrefpoint <- references[[instance_name]]$newrefpoint
    }

    newoffset <- references[[instance_name]]$newoffset
    newhv <- references[[instance_name]]$newhv

    #print(population)
    #print(solution_set)

    #Compute measures
    measures <- list()
    #HV MAXIMISE, hence minimise
    #refpoint=pareto.refpoint, newrefpoint=newrefpoint, newoffset=newoffset, newfront=newfront
    #Only use non-dominated set:
    print(ecr::nondominated(solution_set))
    pareto.matrix <- solution_set[, ecr::nondominated(solution_set)]
    populationnd <- population[, ecr::nondominated(solution_set)]
    # print(pareto.matrix)
    # print(populationnd)
    if(is.matrix(pareto.matrix)){
        if(ncol(pareto.matrix) > 2000) pareto.matrix <- pareto.matrix[,sample(ncol(pareto.matrix), 2000)]
        measures$HV <- -ecr3vis::hv(pareto.matrix, reference.point)
        #print(pareto.matrix + newoffset)
        measures$HVN <- -ecr3vis::hv(pareto.matrix + newoffset, reference.point)
        measures$SP <- -ecr3vis::solow_polasky(pareto.matrix)
    }
    else {
        if(sum(reference.point < pareto.matrix) == length(reference.point)){
            measures$HV <- -prod(reference.point - pareto.matrix)
            measures$HVN <- -prod(newrefpoint - (pareto.matrix+newoffset))
        } else {
            measure$HV <- 0
            measure$HVN <- 0
        }
        measures$SP <- -1
    }
    if(is.matrix(populationnd)){
        if(ncol(populationnd) > 2000) populationnd <- populationnd[,sample(ncol(populationnd), 2000)]
        measures$SPD <- -ecr3vis::solow_polasky(populationnd)
    }
    else{
        measures$SPD <- -1
    }

    measures$HVN <- measures$HVN / newhv #Normalized

    #IDG+ MINIMISE
    measures$IGDP <- NULL #ecr3vis::igdp(pareto.matrix, reference.front) #JEROEN: Not used so do not waste resources
    #TODO: implement Approach for Basin Separated Evaluation
    # results, fn, ...,
    #                          eval_fn = ecr::computeHV,
    #                          grid_size = 300L,
    #                          basins = 1:3,
    #                          join_fronts = FALSE,
    #                          efficient_sets = NULL,
    #                          dec_space_labels = NULL
    tb <- tibble::tibble(fun_calls = 1:dim(populationnd)[2], x1 = populationnd[1,], x2 = populationnd[2,], y1 = pareto.matrix[1,],y2 = pareto.matrix[2,])
    print(tb)
    measures$ABSE <- ABSE::evalutate_results(tb, fn, ref.point=reference.point, basins = 1:2)
    measures$ABSEJF <- ABSE::evalutate_results(tb, fn, ref.point=reference.point, basins = 1:2)

    if (!is.null(opt$save_solution)){
        writeLines("Save to file")
        #save(solution_set, file=opt$save_solution)
        measuresdf <- data.frame(Reduce(rbind, measures))

        HV = measures$HV
        HVN = measures$HVN
        IGDP = measures$IGDP
        SP = measures$SP
        SPD = measures$SPD
        ABSE = measure$ABSE
        ABSEJF = measure$ABSEJF

        # save(pareto.matrix, populationnd, measuresdf , HV, SP, SPD , IGDP, reference.point, file=opt$save_solution)
        save(HV, SP, SPD, HVN, ABSE, ABSEJF, file=opt$save_solution)
    }

    if(!is.null(opt$visualise)){
        output <- opt$visualise
        pdf(output)
        # print(dim(as.data.frame(t(population))))
        # print(dim(as.data.frame(t(solution_set))))
        # print(dim(as.data.frame(t(pareto.matrix))))
        #plot(t(apply(population, 2, obj.fn)), main="Pop -> Obj")
        #plot(t(apply(populationnd, 2, obj.fn)), main="Pop ND -> Obj")

        plot(t(population), main="Decision space")
        plot(t(solution_set), main="Objective space")
        plot(t(pareto.matrix), main="Non-dominated set in objective space")
        dev.off()

        output <- paste0(opt$visualise,".Rdata")
        save(populationnd, pareto.matrix, file=output)
    }
    writeLines(paste0("s REFERENCE", paste(reference.point,collapse=","), " POPSIZE (", toString(dim(population)), ") NON-DOMINATED POP (", toString(dim(populationnd)), ") NON-DOMINATED OBJ (", toString(dim(pareto.matrix)), ")"))
    return(measures)
}

print_measures <- function (measures){
    writeLines("s MEASURES")
    writeLines(paste("s HV",as.character(measures$HV)))
    writeLines(paste("s IGDP",as.character(measures$IGDP)))
    writeLines(paste("s SP",as.character(measures$SP)))
    writeLines(paste("s SPD",as.character(measures$SPD)))
    writeLines(paste("s HVN",as.character(measures$HVN)))
    writeLines(paste("s ABSE",as.character(measures$ABSE)))
    writeLines(paste("s ABSE Join Fronts",as.character(measures$ABSEJF)))
}

plot_solutions <- function(solution_set, fn, instance_path){
    measures = compute_performance_metrics(solution_set, fn, instance_path)

    load("refdata.RData")

    reference.front <- references[[instance_name]]$approxfront
    reference.front <- t(data.matrix(reference.front))

    reference.point <- smoof::getRefPoint(fn)
}