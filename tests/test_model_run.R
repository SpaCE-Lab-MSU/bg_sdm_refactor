# test_model_run.R

# NOTE when using the testthat lib, this test currently throws several warnings and errors and does not pass
# however if you copy/paste the code inside the test into the R console it will run ok and save data, 
# so simply source/run this file to do a test run on the model

# note we need to source the script here since this is not a package
# source('../sdm_model_eval.R')
# library(testthat)

# test_that("can run the ENM model with maxent AND save it", {

test_model_run <- function() {
  TEST_SPECIES <- "Alouatta_palliata"
  TEST_RADIUS  <- 1
  
  # run test, but assume all paths are set via Renviron
  test.e.mx <- sdm_read_and_run(species=TEST_SPECIES, radiusKm = TEST_RADIUS, runNumber = 1, outputPath = NULL)
  print("test results:")
  print(test.e.mx@results)
  
  print('some tests...')
  testthat::expect_equal(typeof(test.e.mx), 'S4')
  testthat::expect_equal(typeof(test.e.mx@results), "list")

  
  TEST_OUTPUT_PATH <- tempfile(pattern = "file", tmpdir = tempdir(), fileext = "")
  dir.create(TEST_OUTPUT_PATH)
  print('saving data to')
  print(TEST_OUTPUT_PATH)
  
  another.test.e.mx <- save_model(test.e.mx, species=TEST_SPECIES, radiusKm = TEST_RADIUS, runNumber =1 , outputPath = TEST_OUTPUT_PATH )

  # get a list of the files in this tmp directory, which will only have output from this run. 
  # test there are ANY that have CSV extension *
  #. any - are any values true?
  #. grepl - match patter to a list of strings
  #. file.list = create list of file names from a dir
  output_file_list <- list.files(TEST_OUTPUT_PATH)
  print("file saved from this model run:")
  print(output_file_list)
  # test there are some csvs
  testthat::expect_true( any(grepl("*.csv",output_file_list )))
  
  # then test if these CSVs can be read in from R.  
  csvs <- output_file_list[grepl("*.csv",output_file_list )]
  print('attempting to read in all the CSVs and see if they have rows')
  for(f in csvs) { 
    print(f)
    testthat::expect_no_error(
      {x<-read.csv(file.path(TEST_OUTPUT_PATH,f))}
    )
    print(paste("file has", nrow(x), "rows"))
    testthat::expect_gt(nrow(x), 0)
    
  }
  
  emx_filename <- file.path(TEST_OUTPUT_PATH, "test.e.mx.rdata")
  print(paste("saving model variable to ", emx_filename))
  save(test.e.mx, file = emx_filename ) 
  return(test.e.mx) 
}
#})

