# test_sdm_enviro_vars.R
# Descriptiontesting functions in sdm_enviro_vars.R

# Project: Using geodiversity to improve Species Distribution Models (SDM)s for data poor species

# authors: Pat Bills, Beth Gerstner
#


source('../geodiv_model_eval.R')
library(testthat)


TEST_SPECIES="Alouatta_palliata"
TEST_RADIUS=1


test_that("sdmBasePath creates a path", {
    # this is a trick test because this function has a side effect
    # so need to preserve the original value and reset it
    origin_bath_path_var <- Sys.getenv('BASE_PATH')

    expect_true(file.exists(sdmBasePath()))
    expect_equal(".", sdmBasePath("."))
    expect_equal("/tmp",sdmBasePath("/tmp"))

    do.call(Sys.setenv, as.list(setNames(origin_bath_path_var, "BASE_PATH")))
    expect_true(file.exists(sdmBasePath()))


})

test_that("can find thinned data for a species", {
    test_occs_data_filename = file.path(occsDataPath(TEST_SPECIES), occsDataFilename(TEST_SPECIES))
    expect_true(file.exists(test_occs_data_filename))
})

test_that("can find occs dir and file",{
  expect_true(file.exists(occsDataPath(TEST_SPECIES)))
  expect_true(file.exists(occsDataFilePath(TEST_SPECIES)))
})


test_that("can read species occurence data", {

    # requires access to directory where occurrence data is
    occ <- read_occs(TEST_SPECIES)
    expect_true(typeof(occ)=="list")
    expect_true(nrow(occ) > 0 )
    expect_true("occID" %in% names(occ))

})


test_that("can find envs dir", {
  # requires access to directory where Chelsa4 data is, mounted or set in
  # CHELSA_PATH
  expect_true(file.exists(envsDataPath(radius=TEST_RADIUS)))
})


test_that("can read envs file",{
  e <- read_envs(radius=TEST_RADIUS)
  testthat::expect_false(is.null(e))
})


test_that("can process occurrence data", {
    occs <- read_occs(TEST_SPECIES)
    envs <- read_envs(TEST_RADIUS)
    processed_occs <- process_occs(occs, envs=envs)

    expect_false(is.null(processed_occs))

})


