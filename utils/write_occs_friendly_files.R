#write_occs_friendly_files.R

# author: Pat Bills
# project: Neotropical Frugivores North Andes SDM (Beth Gerstner)
# summary: this is a quick script just to rename columns in existing data files
# so that they can be read by Wallace.  Wallace accepts file paths as param for reading occurrence data (occs), 
# and those must have correct columns names.  This script reads from a dir and file suffix, changes column names
# and writes to the same folder with new column name, with command line params
# I did not explore if theare are other fns in Wallace to read occurrentces
species_occs_file <- function(species,base_path){
  f<- paste0(species,"_thinned_full/",species,"_thinned_thin1.csv")
  return(file.path(base_path,f))
}

new_species_occs_file <- function(species,base_path,suffix ="_thinned_wallace" ){
 f <- paste0(species,"_thinned_full/",species,suffix,".csv")
 return(file.path(base_path,f))
}

save_with_new_columns <- function(species,base_path,suffix="_thinned_wallace"){
  occs <- read.csv(species_occs_file(species,base_path))
  names(occs) <- c("scientific_name","longitude","latitude")
  new_filename <- new_species_occs_file(species,base_path,suffix)
  write.csv(occs,new_filename)
  return(new_filename)
}

species_from_path <- function(occs_path){
   b <- basename(occs_path)
   sp = stringr::str_match(b,"[A-Z][a-z]+_[a-z]+")
   return(sp)
}


species_list <- function(base_path){
   # list only those dirs "thinned_full"
   species_dirs <- list.files(base_path,pattern=".+thinned_full$")
   species_list <- unlist(lapply(species_dirs, species_from_path))
   return(species_list)

}

make_new_files <- function(base_path,new_suffix){
  for(species in species_list(base_path)) {
     print(species)
     f<- save_with_new_columns(species, base_path,new_suffix)
     print(file.exists(f))

 }
}

# this is a trick to run this code ONLY if it's started from
# Rscript on the command line. It won't run if you source it from an R session
# or source it in a different file. 

if (sys.nframe() == 0){

  args = commandArgs(trailingOnly= TRUE)
  if (length(args) < 2) {
    stop("two args: base_path for occs and new suffix", call.=FALSE)
  }

  base_path = args[1]
  new_suffix = args[2]
  make_new_files(base_path,new_suffix)
}