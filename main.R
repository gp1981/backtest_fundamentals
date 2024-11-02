# Load necessary libraries
library(tidyverse)
library(fs)
library(readxl)
library(lubridate)
library(httr)
library(jsonlite)
library(progress)

# Ensure progress package is installed
if (!requireNamespace(c("progress","tcltk"), quietly = TRUE)) {
  install.packages("progress")
}

library(progress)
# library(tcltk)

# Function to robustly extract date from file name
extract_date_from_filename <- function(filename) {
  date_str <- str_extract(filename, "\\d{8}")
  if (!is.na(date_str)) {
    return(ymd(date_str))
  } else {
    return(NA)
  }
}

# Step 1: Identify Excel Files in Folder Structure with Specified Suffixes
identify_excel_files <- function(root_dir) {
  excel_files <- dir_ls(root_dir, recurse = TRUE, glob = "*.xlsx")
  matched_files <- excel_files %>%
    str_subset("ALL_DF_last_FQ_\\d{8}(?:_1000M)?\\.xlsx$") %>%
    tibble(file_path = .) %>%
    mutate(date_output = map(file_path, extract_date_from_filename)) %>%
    unnest(date_output)
  return(matched_files)
}

# Step 2: Load Excel Files One by One and Extract Top 10 Tickers
extract_top_tickers <- function(file_path, date_output) {
  data <- read_excel(file_path)
  top_tickers <- data %>%
    arrange(`ID_Rank.Combined.EY_ROC.Greenblatt.Today`) %>%
    slice_head(n = 10) %>%
    select(Ticker) %>%
    mutate(date_output = date_output,
           Price = NA,
           Price_1Y = NA,
           Price_2Y = NA,
           Price_3Y = NA)
  return(top_tickers)
}

# Main Function to Perform Backtest Data Preparation with Progress Bar
prepare_backtest_data <- function(root_dir) {
  excel_files <- identify_excel_files(root_dir)
  message("Total files found: ", nrow(excel_files))
  
  # Check for missing dates as before
  expected_dates <- seq.Date(from = min(excel_files$date_output),
                             to = max(excel_files$date_output),
                             by = "2 weeks")
  missing_dates <- setdiff(expected_dates, excel_files$date_output)
  if (length(missing_dates) > 0) {
    warning("Missing dates found: ", paste(missing_dates, collapse = ", "))
  }
  
  # Initialize progress bar
  pb <- progress_bar$new(
    format = "  Processing [:bar] :percent in :elapsed",
    total = nrow(excel_files),
    clear = FALSE,
    width = 60
  )
  
  # Loop through each file with progress bar
  backtest_data <- map_dfr(1:nrow(excel_files), function(i) {
    file_info <- excel_files[i, ]
    pb$tick()  # Update progress bar
    extract_top_tickers(file_info$file_path, file_info$date_output)
  })
  
  return(backtest_data)
}

# Run the backtest data preparation function
root_dir <- "root"  # Update to your directory path
API
backtest_data <- prepare_backtest_data(root_dir)

# View the result
print(backtest_data)
