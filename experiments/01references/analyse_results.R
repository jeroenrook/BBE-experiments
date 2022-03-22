#!/usr/bin/env Rscript

library(moPLOT)
library(ecr)
library(ecr3vis)

parse_instance_file = function(filename){
    content = readChar(filename, nchars=file.info(filename)$size)
    return(eval(parse(text=content)))
}

tmp.path <- "/scratch/tmp/rookj/MMMOO/01references/"
results <- list.files(tmp.path)

solutions <- list()

for (res in results){
  meta.data <- unlist(strsplit(res,"_"))
  print(meta.data)
  algorithm <- meta.data[1]
  instance <- meta.data[2]

  load(paste(tmp.path, res, sep=""))

  #print(algorithm)
  #print(names(solution_set))

  for (obj in 1:length(solution_set)){
    names(solution_set)[obj] <- paste("y", as.character(obj), sep="")
  }

  if(is.null(solutions[[instance]])){
    solutions[[instance]] <- solution_set
    # writeLines("init")
  }
  else{
    #merge
    # writeLines("add")
    solutions[[instance]] <- rbind(solutions[[instance]], solution_set, make.row.names=FALSE)
  }
}

references <- list()
for (instance in names(solutions)){
  print(instance)
  if(instance == "MMF13") next

  #Get pareto front
  solution.matrix <- t(data.matrix(solutions[[instance]]))
  #print(t(solution.matrix))



  #plot(t(solution.matrix)[1], t(solution.matrix)[2], main=instance)

  pareto.idx <- ecr::nondominated(solution.matrix)
  pareto.front <- as.data.frame(t(solution.matrix[, pareto.idx, drop = FALSE]))
  #pareto.front <- pareto.front[sample(nrow(pareto.front), 100), ]
  pareto.refpoint <- as.vector(sapply(pareto.front, max))

  #png(paste("plots/", instance, ".png", sep=""), width=600, height=600)
  plot(pareto.front$y1, pareto.front$y2, main=instance)
  dev.off()


  instances.path <- "../../resources/instances/"
  # instances <- list.files(instances.path)
  fn = parse_instance_file(paste0(instances.path,instance))

  fn.lower <- smoof::getLowerBoxConstraints(fn)
  fn.upper <- smoof::getUpperBoxConstraints(fn)

  # Generate a design in the (rectangular) decision space of fn
  design <- moPLOT::generateDesign(fn, 200^2)

  design$obj.space <- calculateObjectiveValues(design$dec.space, fn, parallelize = T)
  nds <- design$obj.space[nondominated(t(design$obj.space)),]

  writeLines("REFSET")
  newfront <- rbind(pareto.front, nds)
  newfront <- as.matrix(newfront)
  newfront <- newfront[ecr::nondominated(t(newfront)), ]
  # print(newfront)
  # print(dim(pareto.front))
  # print(dim(nds))
  # print(dim(newfront))
  newrefpoint <- as.vector(apply(newfront,2, max)) + 1
  # print(newrefpoint)
  minpoints = as.vector(apply(newfront,2, min))
  # print(minpoints)
  # print(min(minpoints))
  newoffset = 0
  if(min(minpoints) < 0)
    newoffset = (-1*(min(minpoints)))
    newrefpoint = newrefpoint + newoffset
  # print(newoffset)
  # print(newrefpoint)
  newhvrefpoint <- smoof::getRefPoint(fn)
  if (is.null(reference.point)){
      newhvrefpoint <- newrefpoint
  }
  newhv = ecr3vis::hv(t(newfront)+newoffset, newhvrefpoint)
  # print(newhv)

  pareto <- apply(nds, 2, max)

  print(list(refpoint=as.vector(pareto.refpoint), moplot=as.vector(pareto), newrefpoint=newrefpoint, newoffset=newoffset, newhv=newhv))
  pareto.front = pareto.front[sample(nrow(pareto.front), 100), ]
  references[[instance]] <- list(approxfront=pareto.front, refpoint=pareto.refpoint, newrefpoint=newrefpoint, newoffset=newoffset, newhv=newhv)
}

save(references, file="refdata2.RData")