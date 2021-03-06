% Generated by roxygen2: do not edit by hand
% Please edit documentation in www.vantharp.com/>
\name{mt_make_model}
\alias{mt_make_model}
\title{Function to train Deep Learning Classification model for Market Type recognition}
\usage{
mt_make_model(
  indicator_dataset,
  num_bars,
  timeframe = 60,
  path_model,
  path_data,
  activate_balance = TRUE,
  num_nn_options = 24
)
}
\arguments{
\item{indicator_dataset}{Dataframe, Dataset containing indicator patterns to train the model}

\item{num_bars}{Integer, Number of bars used to detect pattern}

\item{timeframe}{Integer, Data timeframe in Minutes.}

\item{path_model}{String, Path where the models are be stored}

\item{path_data}{String, Path where the aggregated historical data is stored, if exists in rds format}

\item{activate_balance}{Boolean, option to choose if to balance market type classes or not, default TRUE}

\item{num_nn_options}{Integer, value from 1 to 20 or more. Used to change number of variants
of the random neural network structures}
}
\value{
Function is writing file object with the model
}
\description{
Function is training h2o deep learning model to match manually classified patterns of the financial
indicator. Main idea is to be able to detect Market Type by solely relying on the current indicator pattern.
This is in the attempt to evaluate current market type and to use proper trading strategy.
Function will always try to gather mode data to update the model.

Selected Market Periods according to the theory from Van K. Tharp:
1. Bull normal, BUN
2. Bull volatile, BUV
3. Bear normal, BEN
4. Bear volatile, BEV
5. Sideways quiet, RAN
6. Sideways volatile, RAV
}
\details{
Function is using manually prepared dataset and tries several different random neural network structures.
Once the best neural network is found then the better model is trained and stored.
}
\examples{

\donttest{

library(dplyr)
library(magrittr)
library(readr)
library(h2o)
library(lazytrade)

path_model <- normalizePath(tempdir(),winslash = "/")
path_data <- normalizePath(tempdir(),winslash = "/")

data(macd_ML60M)

Sys.sleep(5)

# start h2o engine
h2o.init(nthreads = 2)


# performing Deep Learning Regression using the custom function
mt_make_model(indicator_dataset = macd_ML60M,
              num_bars = 64,
              timeframe = 60,
              path_model = path_model,
              path_data = path_data,
              activate_balance = TRUE,
              num_nn_options = 2)

# stop h2o engine
h2o.shutdown(prompt = FALSE)

#set delay to insure h2o unit closes properly before the next test
Sys.sleep(5)

}



}
\author{
(C) 2020 Vladimir Zhbanko
}
