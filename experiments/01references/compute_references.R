#!/usr/bin/env Rscript
library(smoof)
library(moPLOT)

#ALl instances
#Get all instances
instances.path <- "../../resources/instances/"
instances <- list.files(instances.path)

parse_instance_file = function(filename){
    content = readChar(filename, nchars=file.info(filename)$size)
    return(eval(parse(text=content)))
}
print(instances)

manual_references <- read.csv(file = 'manual_points.csv')
print(manual_references)

references <- list()
for (instance in instances){
  instance.path = paste0(instances.path,instance)
  fn <- readChar(instance.path, nchars=file.info(instance.path)$size)
  fn <- eval(parse(text=fn))

  #Use moPLOT to approximate the achievable HV
  design <- moPLOT::generateDesign(fn, points.per.dimension=512)
  design$obj.space <- calculateObjectiveValues(design$dec.space, fn, parallelize = T)
  nds <- design$obj.space[ecr::nondominated(t(design$obj.space)),] #Perato front


  ref <- ceiling(as.vector(apply(design$obj.space, 2, max))) + 1
  print(ref)
  # if(instance %in% manual_references$Instance){
  #   # 1. Check for manual entry
  #   ref <- manual_references[manual_references$Instance == instance, c("y1", "y2")]
  #   ref <- as.double(ref)
  # } else if(!is.null(smoof::getRefPoint(fn))){
  #   # 2. Check for smoof reference
  #   ref <- smoof::getRefPoint(fn)
  # } else{
  #   # 3. moPLOT
  #   ref <- as.vector(apply(nds, 2, max))
  # }

  #Compute max hv
  hv = ecr3vis::hv(t(nds), ref)

  references[[instance]] <- list(refpoint=ref, hv=hv)
}

save(references, file="refdata.RData")