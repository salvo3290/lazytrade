#' Function to train Deep Learning Classification model for Market Type recognition
#'
#' @description  Function is training h2o deep learning model to match manually classified patterns of the financial
#' indicator. Main idea is to be able to detect Market Type by solely relying on the current indicator pattern.
#' This is in the attempt to evaluate current market type and to use proper trading strategy.
#' Function will always try to gather mode data to update the model.
#'
#' Selected Market Periods according to the theory from Van K. Tharp:
#' 1. Bull normal, BUN
#' 2. Bull volatile, BUV
#' 3. Bear normal, BEN
#' 4. Bear volatile, BEV
#' 5. Sideways quiet, RAN
#' 6. Sideways volatile, RAV
#'
#' @details Function is using manually prepared dataset and tries several different random neural network structures.
#' Once the best neural network is found then the better model is trained and stored.
#'
#' @author (C) 2020 Vladimir Zhbanko
#' @backref Market Type research of Van Tharp Institute: <https://www.vantharp.com/>
#'
#' @param indicator_dataset   Dataframe, Dataset containing indicator patterns to train the model
#' @param num_bars            Integer, Number of bars used to detect pattern
#' @param timeframe           Integer, Data timeframe in Minutes.
#' @param path_model          String, Path where the models are be stored
#' @param path_data           String, Path where the aggregated historical data is stored, if exists in rds format
#' @param activate_balance    Boolean, option to choose if to balance market type classes or not, default TRUE
#' @param num_nn_options      Integer, value from 1 to 20 or more. Used to change number of variants
#'                            of the random neural network structures
#'
#' @return Function is writing file object with the model
#' @export
#'
#' @examples
#'
#' \donttest{
#'
#' library(dplyr)
#' library(magrittr)
#' library(readr)
#' library(h2o)
#' library(lazytrade)
#'
#' path_model <- normalizePath(tempdir(),winslash = "/")
#' path_data <- normalizePath(tempdir(),winslash = "/")
#'
#' data(macd_ML60M)
#'
#' Sys.sleep(5)
#'
#' # start h2o engine
#' h2o.init(nthreads = 2)
#'
#'
#' # performing Deep Learning Regression using the custom function
#' mt_make_model(indicator_dataset = macd_ML60M,
#'               num_bars = 64,
#'               timeframe = 60,
#'               path_model = path_model,
#'               path_data = path_data,
#'               activate_balance = TRUE,
#'               num_nn_options = 2)
#'
#' # stop h2o engine
#' h2o.shutdown(prompt = FALSE)
#'
#' #set delay to insure h2o unit closes properly before the next test
#' Sys.sleep(5)
#'
#' }
#'
#'
#'
mt_make_model <- function(indicator_dataset,
                          num_bars,
                          timeframe = 60,
                          path_model, path_data,
                          activate_balance = TRUE,
                          num_nn_options = 24){

  requireNamespace("dplyr", quietly = TRUE)
  requireNamespace("readr", quietly = TRUE)
  requireNamespace("h2o", quietly = TRUE)



  ## check if the latest data is available
  # construct path to the new data
  path_file_name <- paste0("macd_ai_classified_", timeframe, "M.rds")
  path_newdata <- file.path(path_data, path_file_name)
  if(file.exists(path_newdata)){
    # use new data...
    macd_ML2 <- read_rds(path_newdata) %>%
      # and add new data
      bind_rows(indicator_dataset) %>%
      # convert one column to factor
      mutate_at("M_T", as.factor)
  } else {
    # use input data and transform dataset column to factor
    macd_ML2 <- indicator_dataset %>% mutate_at("M_T", as.factor)
  }

  # check if we don't have too much data
  x1_nrows <- macd_ML2 %>% nrow()
  # what to do if too much rows?
  if(x1_nrows > 50000){
    # read all the data
    macd_ML2 <- macd_ML2 %>%
      # use only last 40000 rows, 40000 is to avoid this code to run so often...
      utils::head(40000)
  }

  # get this data into h2o:
  macd_ML  <- as.h2o(x = macd_ML2, destination_frame = "macd_ML")

  # try different models and choose the best one...
  ### random network structure
  nn_sets <- sample.int(n = 100, num_nn_options) %>% matrix(ncol = 3)

  for (i in 1:dim(nn_sets)[1]) {

    # i <- 1


  ModelC <- h2o.deeplearning(
    model_id = paste0("DL_Classification", "_", timeframe, "M"),
    x = names(macd_ML[,1:num_bars]),
    y = "M_T",
    training_frame = macd_ML,
    activation = "Tanh",
    overwrite_with_best_model = TRUE,
    autoencoder = FALSE,
    hidden = nn_sets[i, ],
    loss = "Automatic",
    sparse = TRUE,
    l1 = 1e-4,
    distribution = "AUTO",
    stopping_metric = "AUTO",
    balance_classes = activate_balance,
    epochs = 200)

  #ModelC
  #summary(ModelC)
  #h2o.performance(ModelC)
  RMSE <- h2o::h2o.performance(ModelC)@metrics$RMSE %>% as.data.frame()
  names(RMSE) <- 'RMSE'

  # record results of modelling
  if(!exists("df_res")){
    df_res <- nn_sets[i,] %>% t() %>% as.data.frame() %>% dplyr::bind_cols(RMSE)
  } else {
    df_row <- nn_sets[i,] %>% t() %>% as.data.frame() %>% dplyr::bind_cols(RMSE)
    df_res <- df_res %>% dplyr::bind_rows(df_row)
  }




  } # end of for loop

  # find which row in the df_res has the smallest RMSE value slice(which.min(Employees))
  lowest_RMSE <- df_res %>% dplyr::slice(which.min(RMSE)) %>% select(-RMSE) %>% unlist() %>% unname()

  ModelC <- h2o.deeplearning(
    model_id = paste0("DL_Classification", "_", timeframe, "M"),
    x = names(macd_ML[,1:num_bars]),
    y = "M_T",
    training_frame = macd_ML,
    activation = "Tanh",
    overwrite_with_best_model = TRUE,
    autoencoder = FALSE,
    hidden = lowest_RMSE,
    loss = "Automatic",
    sparse = TRUE,
    l1 = 1e-4,
    distribution = "AUTO",
    stopping_metric = "AUTO",
    balance_classes = activate_balance,
    epochs = 200)

h2o.saveModel(ModelC, path = path_model, force = TRUE)

  #h2o.shutdown(prompt = FALSE)


}

