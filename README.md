# Stock Screener Backtesting Tool

This repository provides an R-based backtesting tool designed to analyze
the historical performance of top stocks identified by a custom stock
screener. The tool fetches historical price data from the Financial
Modeling Prep API, processes the data, and evaluates returns over
various timeframes.

## Features

-   **Automated File Identification**: Locates and loads Excel files
    containing stock screener outputs, stored across directories by
    date.
-   **Data Loading and Filtering**: Extracts the top 10 tickers per date
    from each file based on a specified ranking column and prepares the
    data for analysis.
-   **API Integration**: Fetches historical price data using the
    Financial Modeling Prep API, filling in price information for each
    ticker at intervals of 1, 2, and 3 years.
-   **Return Calculations**: Computes price changes and capital gains
    for each stock over 1, 2, and 3 years.
-   **Backtesting Performance Analysis**: Simulates investment returns,
    assuming \$1 invested in each of the top 10 stocks per screening
    date, and evaluates capital gains over time.

## Requirements

-   **R Version**: 4.0 or higher
-   **R Packages**:
    -   `tidyverse` for data manipulation
    -   `readxl` for reading Excel files
    -   `httr` and `jsonlite` for API requests and JSON handling
    -   `progress` for tracking processing progress
-   **Financial Modeling Prep API Key**: Sign up
    [here](https://financialmodelingprep.com/) and replace `XXX` in the
    script with your key.

## Installation

Clone this repository and ensure you have the required packages
installed:

\`\`\`r \# Install necessary packages if not already installed
install.packages(c("tidyverse", "readxl", "httr", "jsonlite",
"progress"))

## Usage

1.  **File Identification and Data Loading:** The script locates Excel
    files stored by date, extracts the top 10 tickers for each date, and
    organizes the data into a structured DataFrame.

2.  **Historical Data Retrieval:** The function
    update_backtest_data_with_prices() calls the Financial Modeling Prep
    API to retrieve historical adjusted close prices for each ticker, at
    the specified intervals of 1, 2, and 3 years from the screening
    date.

3.  **Return Calculation:** Calculates price changes over 1, 2, and 3
    years and stores the changes as Change_1Y, Change_2Y, and Change_3Y.

4.  **Backtesting Results and Visualization:**

    -   Generates multifaceted histograms for Change_1Y, Change_2Y, and
        Change_3Y, showing the distribution of returns. S

    -   Simulates backtesting by calculating the cumulative capital
        gains over time assuming \$1 investments in each of the top 10
        stocks.

**Example Output**

The histograms below illustrate the distribution of 1-year, 2-year, and
3-year changes in stock prices across all selected stocks. Positive or
negative price changes reflect the tool’s backtesting results for the
stock screener’s performance over these timeframes.

Contributing

Contributions are welcome! If you have suggestions or improvements, feel
free to open an issue or submit a pull request.

License

This project is licensed under the MIT License. See the LICENSE file for
details.

Disclaimer

This tool is for educational purposes and should not be used as
financial advice. Use it at your own risk.
