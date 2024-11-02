# Add your API key here
api_key <- "YOUR_API_KEY"

# Function to retrieve historical prices and fill in price columns
get_prices_for_ticker <- function(ticker, date_output) {
  # Construct API URL
  url <- paste0("https://financialmodelingprep.com/api/v3/historical-price-full/", ticker, "?apikey=", api_key)
  
  # Make API call
  response <- GET(url)
  
  # Check if the response is valid
  if (status_code(response) != 200) {
    warning("Failed to retrieve data for ticker: ", ticker)
    return(rep(NA, 4))  # Return NA values if API fails
  }
  
  # Parse JSON response
  data <- fromJSON(content(response, "text"))$historical
  
  # Ensure data is available
  if (is.null(data)) {
    warning("No historical data found for ticker: ", ticker)
    return(rep(NA, 4))
  }
  
  # Convert JSON to dataframe and parse date column
  prices_df <- data %>%
    as_tibble() %>%
    mutate(date = ymd(date)) %>%
    arrange(date)  # Ensure dates are in ascending order
  
  # Function to find closest available date price
  get_adj_close_for_date <- function(target_date) {
    closest_price <- prices_df %>%
      filter(date >= target_date) %>%
      slice(1) %>%
      pull(adjClose)
    if (length(closest_price) == 0) return(NA) else return(closest_price)
  }
  
  # Calculate Price, Price_1Y, Price_2Y, Price_3Y based on date_output
  price <- get_adj_close_for_date(date_output)
  price_1y <- get_adj_close_for_date(date_output + years(1))
  price_2y <- get_adj_close_for_date(date_output + years(2))
  price_3y <- get_adj_close_for_date(date_output + years(3))
  
  return(c(price, price_1y, price_2y, price_3y))
}

# Add percentage changes based on Prices
calculate_price_changes <- function(backtest_data) {
  backtest_data %>%
    mutate(
      Change_1Y = (Price_1Y - Price) / Price * 100,
      Change_2Y = (Price_2Y - Price) / Price * 100,
      Change_3Y = (Price_3Y - Price) / Price * 100
    )
}

# Main function to update backtest_data with prices
update_backtest_data_with_prices <- function(backtest_data) {
  # Initialize columns for prices
  backtest_data <- backtest_data %>%
    mutate(Price = NA, Price_1Y = NA, Price_2Y = NA, Price_3Y = NA)
  
  # Initialize progress bar
  pb <- progress_bar$new(
    format = "  Processing [:bar] :percent in :elapsed",
    total = nrow(backtest_data),
    clear = FALSE,
    width = 60
  )
  
  # Loop through each row to fetch prices
  for (i in seq_len(nrow(backtest_data))) {
    ticker <- backtest_data$Ticker[i]
    date_output <- backtest_data$date_output[i]
    
    # Get prices for the current ticker and date
    prices <- get_prices_for_ticker(ticker, date_output)
    
    # Update the backtest_data with retrieved prices
    backtest_data$Price[i] <- prices[1]
    backtest_data$Price_1Y[i] <- prices[2]
    backtest_data$Price_2Y[i] <- prices[3]
    backtest_data$Price_3Y[i] <- prices[4]
    
    # Update progress bar
    pb$tick()
  }
  
  # Calculate percentage changes
  backtest_data <- calculate_price_changes(backtest_data)
  
  return(backtest_data)
}

# Example usage of the update function
# Assuming backtest_data is your initial dataframe from previous steps
backtest_data <- update_backtest_data_with_prices(backtest_data)
# print(backtest_data)


# Function to create multifaceted histogram
create_multifaceted_histogram <- function(backtest_data) {
  # Transform the data into long format for ggplot2
  long_data <- backtest_data %>%
    select(Change_1Y, Change_2Y, Change_3Y) %>%
    pivot_longer(cols = everything(), names_to = "Time_Period", values_to = "Change") %>%
    filter(!is.na(Change))  # Remove NA values
  
  # Create the histogram
  p <- ggplot(long_data, aes(x = Change)) +
    geom_histogram(binwidth = 5, fill = "skyblue", color = "black", alpha = 0.7) +
    facet_wrap(~ Time_Period, scales = "free_y") +  # Create separate plots for each time period
    labs(title = "Multifaceted Histogram of Changes",
         x = "Capital gain or price change (%) ",
         y = "Number of Stocks") +
    scale_x_continuous(labels = scales::percent_format(scale = 1)) +  # Format x-axis as percentage
    theme_minimal() +
    theme(axis.title.x = element_text(size = 12),  # Adjust x-axis label size
          axis.title.y = element_text(size = 12),  # Adjust y-axis label size
          plot.title = element_text(size = 14, face = "bold"))  # Adjust plot title size
  
  return(p)
}


# Function to calculate and display descriptive statistics
calculate_statistics <- function(backtest_data) {
  stats <- backtest_data %>%
    summarise(
      Mean_Change_1Y = mean(Change_1Y, na.rm = TRUE),
      Median_Change_1Y = median(Change_1Y, na.rm = TRUE),
      SD_Change_1Y = sd(Change_1Y, na.rm = TRUE),
      Mean_Change_2Y = mean(Change_2Y, na.rm = TRUE),
      Median_Change_2Y = median(Change_2Y, na.rm = TRUE),
      SD_Change_2Y = sd(Change_2Y, na.rm = TRUE),
      Mean_Change_3Y = mean(Change_3Y, na.rm = TRUE),
      Median_Change_3Y = median(Change_3Y, na.rm = TRUE),
      SD_Change_3Y = sd(Change_3Y, na.rm = TRUE)
    )
  
  print(stats)
  return(stats)
}

# Function to simulate the backtest
simulate_backtest <- function(backtest_data) {
  top_tickers <- backtest_data %>%
    slice_head(n = 10)  # Get top 10 tickers based on whatever criteria you have (e.g., highest returns)
  
  # Calculate investment after 1Y, 2Y, 3Y
  investments <- top_tickers %>%
    mutate(
      Investment_1Y = (1 + Change_1Y / 100) * 1,
      Investment_2Y = (1 + Change_2Y / 100) * Investment_1Y,
      Investment_3Y = (1 + Change_3Y / 100) * Investment_2Y
    )
  
  # Total capital gain after each period
  total_capital_gain <- investments %>%
    summarise(
      Total_Investment_1Y = sum(Investment_1Y, na.rm = TRUE),
      Total_Investment_2Y = sum(Investment_2Y, na.rm = TRUE),
      Total_Investment_3Y = sum(Investment_3Y, na.rm = TRUE)
    )
  
  print(total_capital_gain)
  return(total_capital_gain)
}

# Assuming backtest_data is already defined and contains the necessary Change columns
multifaceted_histogram <- create_multifaceted_histogram(backtest_data)

# Display the multifaceted histogram
print(multifaceted_histogram)


# Calculate and print statistics
statistics <- calculate_statistics(backtest_data)

# Run backtest simulation
backtest_results <- simulate_backtest(backtest_data)
