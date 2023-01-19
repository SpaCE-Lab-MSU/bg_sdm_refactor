# test_sdm_enviro_vars.R
# Descriptiontesting functions in sdm_enviro_vars.R

# Project: Using geodiversity to improve Species Distribution Models (SDM)s for data poor species

# authors: Pat Bills, Beth Gerstner
#


source('../geodiv_model_eval.R')
library(testthat)


test_that("sdmBasePath creates a path", {
    # this is a trick test becuase this function has a side effect
    # so need to preserve the original value and reset it
    origin_bath_path_var <- Sys.getenv('BASE_PATH')

    expect_true(file.exists(sdmBasePath()))
    expect_equal(".", sdmBasePath("."))
    expect_equal("/tmp",sdmBasePath("/tmp"))

    do.call(Sys.setenv, as.list(setNames(origin_bath_path_var, "BASE_PATH")))
    expect_true(file.exists(sdmBasePath()))


})

test_that("can find thinned data for a species", {
    EXAMPLE_SPECIES="Alouatta_palliata"
    test_occs_data_filename = file.path(occsDataPath(EXAMPLE_SPECIES), occsDataFilename(EXAMPLE_SPECIES))
    expect_true(file.exists(test_occs_data_filename))
})


test_that("can find envs dir", {
    # requires access to directory where Chelsa4 data is, mounted or set in
    # CHELSA_PATH
    expect_true(file.exists(set_envs_dir()))
})


test_that("can read envs file",{
    e <- read_envs()
    testthat::expect_false(is.null(e))
})

test_that("can read species occurence data", {

    # requires access to directory where occurrence data is
    EXAMPLE_SPECIES <- "Alouatta_palliata"
    occ <- read_occs(EXAMPLE_SPECIES)
    expect_true(typeof(occ)=="list")
    expect_true(nrow(occ) > 0 )
    expect_true("occID" %in% names(occ))

})

# simple check that default params are as expected
test_that("can make a polygon",{
    p<- region_polygon()
    expect_equal(typeof(p), "double")
    expect_gte(nrow(p),1)
    expect_equal(ncol(p),2)
    # regional polygon is expected to
    expect_named(p)

})

test_that("can process occurrence data", {
    EXAMPLE_SPECIES <- "Alouatta_palliata"
    occs <- read_occs(EXAMPLE_SPECIES)
    p = region_polygon()
    envs = read_envs()
    processed_occs <- process_occs(occs, envs=envs, poly_matrix=p)

    expect_false(is.null(processed_occs))

})
