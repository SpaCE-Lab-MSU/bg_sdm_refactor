# test_java_for_wallace.R

# the geodiv model requires a java program to be installed and this can be tricky
# this test checks that things are installed correctly.  
# See the readme for instructions
library(testthat)

testthat::test_that("can run maxent.jar java program", {
  # based on https://stackoverflow.com/questions/44813048/maxent-rjava-situation-1001
  # and 
  testthat::expect_no_error(requireNamespace('rJava'))
  testthat::expect_no_error(rJava::.jpackage('dismo'))
  
  # need to confirm that the jar file actually goes where I think it does
  
  # TODO look for the R java folder 
  
  # TODO fix this! 
  maxtent_jar_file_path <- file.path(system.file("java", package="dismo"), "maxent.jar")  
  maxtent_jar_file_alternative <- file.path(system.file("java", package="rJava"), "maxent.jar")
  testthat::expect_true(file.exists(maxtent_jar_file_path) || file.exists( maxtent_jar_file_alternative ))
  testthat::expect_true(dismo::maxent())
})
