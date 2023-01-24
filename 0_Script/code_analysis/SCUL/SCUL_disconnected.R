############################ Instalation
#   https://hollina.github.io/scul/articles/scul-tutorial.html
#   FL: Install manually any error package

# Install development version from GitHub (CRAN coming soon) using these two lines of code
# if (!require("devtools")) install.packages("devtools")
# devtools::install_github("hollina/scul")
############################# Implementation on MLF
library(scul)
library(dplyr)
library(ggplot2)
library(rio)
####
# Clear working directory/RAM
rm(list=ls())
#### Stata Inputs
TreatmentBeginsAt <- 16

####
# Directory and files definition
box_dir="C:/Users/fal20381/Indiana University/Navarro Ulloa, Luis Enrique - MLF_Volatility/1_Data/Temp/SCUL"
setwd(box_dir)
id = 1
import_dta = file.path(box_dir,paste('MatReady_id',id,'.dta', sep = ""))
export_dta = file.path(box_dir,paste('Export_id',id,'.dta', sep = ""))

####
#Importing Data
Data <- import(import_dta)

AllYData <- Data %>% 
  select(c("month_exp", "Y0"))
AllXData <- Data %>%
  select(-c("month_exp", "Y0"))

####
#Running SCUL According to
processed.AllYData <- Preprocess(AllYData)
PostPeriodLength <- nrow(processed.AllYData) - TreatmentBeginsAt + 1
PrePeriodLength <- TreatmentBeginsAt-1
NumberInitialTimePeriods <- 7
processed.AllYData <- PreprocessSubset(processed.AllYData,
                                       TreatmentBeginsAt ,
                                       NumberInitialTimePeriods,
                                       PostPeriodLength,
                                       PrePeriodLength)


SCUL.input <- OrganizeDataAndSetup (
  time =  AllYData %>% select(month_exp),
  y = AllYData %>% select(Y0),
  TreatmentBeginsAt = TreatmentBeginsAt,
  x.DonorPool = AllXData,
  CohensDThreshold = 0.25,
  NumberInitialTimePeriods = NumberInitialTimePeriods,
  TrainingPostPeriodLength = 5,
  x.PlaceboPool = AllXData,
  OutputFilePath="vignette_output/"
)

SCUL.output <- SCUL(plotCV == TRUE)

PlotActualvSCUL()
PlotShareTable()



