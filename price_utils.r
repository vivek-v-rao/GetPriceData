# price_utils.R
# Utility functions for price data handling

# Load required libraries quietly
suppressPackageStartupMessages(library(quantmod))
suppressPackageStartupMessages(library(moments))

get_prices <- function(symbols, start_date, end_date, verbose = TRUE) {
  # download adjusted closing prices for several symbols and merge
  # them into one dataframe
  
  # Create empty list to store prices
  price_list <- list()
  
  # Download data for each symbol
  for (symbol in symbols) {
    tryCatch({
      # Get stock data
      stock_data <- getSymbols(symbol, from = start_date, to = end_date, 
                              auto.assign = FALSE)
      
      # Store adjusted closing prices
      prices <- Ad(stock_data)
      colnames(prices) <- symbol
      price_list[[symbol]] <- prices
      
      # Print download status if verbose is TRUE
      if (verbose) {
        cat("Successfully downloaded data for", symbol, "\n")
      }
    }, error = function(e) {
      cat("Error downloading", symbol, ":", conditionMessage(e), "\n")
    })
  }
  
  # Merge all prices into a dataframe
  price_df <- do.call(merge, price_list)
  
  # Always print date range and number of dates
  date_range <- range(index(price_df))
  num_dates <- nrow(price_df)
  cat("\n", num_dates, "days of prices from", 
      as.character(date_range[1]), "to", 
      as.character(date_range[2]), "\n")
  
  return(price_df)
}

combine_price_data <- function(input_dir, price_field = "Close", verbose = TRUE) {
  # Reads CSV files from a directory, extracts a price field, combines into a dataframe
  # Args: input_dir (string), price_field (string, default 'Close'), verbose (logical)
  # Returns: Combined dataframe
  
  # Get list of CSV files in the input directory
  csv_files <- list.files(input_dir, pattern = "\\.csv$", full.names = TRUE)
  if (length(csv_files) == 0) stop("No CSV files found in ", input_dir)
  
  # List to store price data
  price_list <- list()
  
  # Process each CSV file
  for (file in csv_files) {
    tryCatch({
      # Extract symbol from filename (remove directory and .csv extension)
      symbol <- sub("\\.csv$", "", basename(file))
      
      # Read CSV file
      df <- read.csv(file, stringsAsFactors = FALSE)
      
      # Check if price_field exists in the file
      field_name <- if (price_field %in% colnames(df)) {
        price_field
      } else {
        paste(symbol, price_field, sep=".")
      }
      if (!(field_name %in% colnames(df))) {
        stop("Field '", field_name, "' not found in ", file)
      }
      
      # Extract Date and specified price field
      price_series <- xts(df[[field_name]], order.by = as.Date(df$Date))
      colnames(price_series) <- symbol
      
      # Store in list
      price_list[[symbol]] <- price_series
      
      # Verbose output with first/last dates and number of days
      if (verbose) {
        first_date <- as.character(min(index(price_series)))
        last_date <- as.character(max(index(price_series)))
        num_days <- nrow(price_series)
        cat("read data for", symbol, "from", file, 
            num_days, "days from", first_date, "to", last_date, "\n")
      }
    }, error = function(e) {
      cat("Error reading", file, ":", conditionMessage(e), "\n")
    })
  }
  
  # Combine all price series into a single dataframe
  combined_df <- do.call(merge, price_list)
  
  # Convert to dataframe with Date as a column
  output_df <- as.data.frame(combined_df)
  output_df <- cbind(Date = index(combined_df), output_df)
  
  return(combined_df)
}

download_stock_data <- function(symbols, start_date, end_date, output_dir, 
                               verbose = TRUE, summary_df = FALSE, 
                               include_symbol_in_colnames = TRUE) {
# Downloads OHLCV data for symbols and writes to CSV files.
# Args: symbols (vector), start_date/end_date (YYYY-MM-DD), output_dir (string),
#         verbose (logical), summary_df (logical), include_symbol_in_colnames (logical)
# Returns: None (writes files), optionally prints summary dataframe"
  
  # Ensure output directory exists
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    if (verbose) cat("Created output directory:", output_dir, "\n")
  }
  
  # List to store summary data
  summary_list <- list()
  
  # Download and process data for each symbol
  for (symbol in symbols) {
    tryCatch({
      # Get stock data
      stock_data <- getSymbols(symbol, from = start_date,
		  to = end_date, auto.assign = FALSE)
      # Define column names based on include_symbol_in_colnames
      if (include_symbol_in_colnames) {
        data_cols <- c("Open", "High", "Low", "Close", "Volume")
        col_names <- paste(symbol, data_cols, sep=".")
        df <- as.data.frame(stock_data[, col_names])
        if (paste(symbol, "Open.Interest", sep=".") %in% colnames(stock_data)) {
          df[[paste(symbol, "Open.Interest", sep=".")]] <- stock_data[, paste(symbol, "Open.Interest", sep=".")]
        }
      } else {
        data_cols <- c("Open", "High", "Low", "Close", "Volume")
        col_names <- data_cols
        df <- as.data.frame(stock_data[, paste(symbol, data_cols, sep=".")])
        colnames(df) <- col_names
        if (paste(symbol, "Open.Interest", sep=".") %in% colnames(stock_data)) {
          df[["Open_Interest"]] <- stock_data[, paste(symbol, "Open.Interest", sep=".")]
        }
      }
      
      # Add Date column
      df <- cbind(Date = index(stock_data), df)
      
      # Write to CSV file named by symbol
      output_file <- file.path(output_dir, paste0(symbol, ".csv"))
      write.table(df, output_file, sep = ",", quote = FALSE, row.names = FALSE)
      
      # Collect summary info if requested
      if (summary_df) {
        summary_list[[symbol]] <- data.frame(
          Symbol = symbol,
          Num_Days = nrow(df),
          First_Date = as.character(min(index(stock_data))),
          Last_Date = as.character(max(index(stock_data))),
          stringsAsFactors = FALSE,
          row.names = NULL  # Prevent row names from affecting output
        )
      }
      
      if (verbose) cat("saved data for", symbol, "to", output_file, "\n")
  }, error = function(e) {})
  }
  
  # Optionally create and print summary dataframe
  if (summary_df && length(summary_list) > 0) {
    summary_df <- do.call(rbind, summary_list)
    # Reset row names to avoid duplication in printing
    rownames(summary_df) <- NULL
    cat("\nSummary of Downloaded Data:\n")
    print(summary_df)
  }
}

analyze_returns <- function(price_df, trading_days_per_year = 252, 
                           risk_free_rate = 0.0, verbose = TRUE,
                           print_correlation = TRUE) {
# Function to analyze returns and compute statistics
#   Args: price_df (dataframe), trading_days_per_year (int), risk_free_rate (float),
#         verbose (logical), print_correlation (logical)
#   Returns: List of prices, returns, stats"
  
  # Get symbol names from price dataframe
  symbols <- colnames(price_df)
  
  # Calculate daily returns for each symbol, preserving symbol names
  return_list <- lapply(seq_along(symbols), function(i) {
    returns <- dailyReturn(price_df[, i], type = "log")
    colnames(returns) <- symbols[i]
    returns
  })
  
  # Merge returns into a dataframe
  return_df <- do.call(merge, return_list)
  
  # Remove NA values from returns for calculations
  return_df_clean <- na.omit(return_df)
  
  # Calculate metrics
  annualized_returns <- apply(return_df_clean, 2, function(x) 
    mean(x) * trading_days_per_year)
  
  annualized_vol <- apply(return_df_clean, 2, function(x) 
    sd(x) * sqrt(trading_days_per_year))
  
  rf_annualized <- risk_free_rate
  sharpe_ratios <- (annualized_returns - rf_annualized) / annualized_vol
  skew_vals <- apply(return_df_clean, 2, skewness)
  kurt_vals <- apply(return_df_clean, 2, kurtosis)
  min_vals <- apply(return_df_clean, 2, min)
  max_vals <- apply(return_df_clean, 2, max)
  
  # Correlation matrix
  cor_matrix <- cor(return_df_clean)
  
  # Combine metrics into a single table
  results_table <- rbind(
    Annualized_Returns = annualized_returns,
    Annualized_Volatility = annualized_vol,
    Sharpe_Ratio = sharpe_ratios,
    Skewness = skew_vals,
    Kurtosis = kurt_vals,
    Minimum = min_vals,
    Maximum = max_vals
  )
  
  # Print results as a single table
  cat("\nPerformance Metrics (Risk-Free Rate =", rf_annualized, "):\n")
  print(round(results_table, 4))
  
  # Print correlation matrix if print_correlation is TRUE
  if (print_correlation) {
    cat("\nCorrelation Matrix of Returns:\n")
    print(round(cor_matrix, 4))
  }
  
  # Prepare price data for writing without quotes
  price_df_formatted <- as.data.frame(price_df)
  price_df_formatted <- cbind(Date = index(price_df), price_df_formatted)
  
  # Return results as a list
  return(list(
    prices = price_df_formatted,
    returns = return_df,
    annualized_returns = annualized_returns,
    volatility = annualized_vol,
    sharpe_ratios = sharpe_ratios,
    skewness = skew_vals,
    kurtosis = kurt_vals,
    minimum = min_vals,
    maximum = max_vals,
    correlation = cor_matrix
  ))
}

get_intraday_prices <- function(symbols, start_date, end_date, interval = "5min", verbose = TRUE) {
  # Download intraday prices for several symbols and merge them into one dataframe
  
  # Create empty list to store prices
  price_list <- list()
  
  # Download data for each symbol
  for (symbol in symbols) {
    tryCatch({
      # Get intraday stock data
      stock_data <- getSymbols(symbol, from = start_date, to = end_date, 
                               periodicity = interval, auto.assign = FALSE)
      
      # Store adjusted closing prices (or use Cl() for close prices if Ad() is not available)
      prices <- Cl(stock_data)  # Use Cl() for close prices
      colnames(prices) <- symbol
      price_list[[symbol]] <- prices
      
      # Print download status if verbose is TRUE
      if (verbose) {
        cat("Successfully downloaded intraday data for", symbol, "\n")
      }
    }, error = function(e) {
      cat("Error downloading", symbol, ":", conditionMessage(e), "\n")
    })
  }
  
  # Merge all prices into a dataframe
  price_df <- do.call(merge, price_list)
  
  # Always print date range and number of timestamps
  timestamp_range <- range(index(price_df))
  num_timestamps <- nrow(price_df)
  cat("\n", num_timestamps, "intraday timestamps from", 
      as.character(timestamp_range[1]), "to", 
      as.character(timestamp_range[2]), "\n")
  
  return(price_df)
}

download_intraday_data <- function(symbols, start_date, end_date, interval = "5min", 
                                   output_dir, verbose = TRUE, summary_df = FALSE, 
                                   include_symbol_in_colnames = TRUE) {
  # Downloads intraday OHLCV data for symbols and writes to CSV files.
  # Args: symbols (vector), start_date/end_date (YYYY-MM-DD), interval (string, e.g., "5min"),
  #       output_dir (string), verbose (logical), summary_df (logical), 
  #       include_symbol_in_colnames (logical)
  # Returns: None (writes files), optionally prints summary dataframe
  
  # Ensure output directory exists
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
    if (verbose) cat("Created output directory:", output_dir, "\n")
  }
  
  # List to store summary data
  summary_list <- list()
  
  # Download and process data for each symbol
  for (symbol in symbols) {
    tryCatch({
      # Get intraday stock data
      stock_data <- getSymbols(symbol, from = start_date, to = end_date, 
                               periodicity = interval, auto.assign = FALSE)
      
      # Define column names based on include_symbol_in_colnames
      if (include_symbol_in_colnames) {
        data_cols <- c("Open", "High", "Low", "Close", "Volume")
        col_names <- paste(symbol, data_cols, sep = ".")
        df <- as.data.frame(stock_data[, col_names])
        if (paste(symbol, "Open.Interest", sep = ".") %in% colnames(stock_data)) {
          df[[paste(symbol, "Open.Interest", sep = ".")]] <- stock_data[, paste(symbol, "Open.Interest", sep = ".")]
        }
      } else {
        data_cols <- c("Open", "High", "Low", "Close", "Volume")
        col_names <- data_cols
        df <- as.data.frame(stock_data[, paste(symbol, data_cols, sep = ".")])
        colnames(df) <- col_names
        if (paste(symbol, "Open.Interest", sep = ".") %in% colnames(stock_data)) {
          df[["Open_Interest"]] <- stock_data[, paste(symbol, "Open.Interest", sep = ".")]
        }
      }
      
      # Add Timestamp column
      df <- cbind(Timestamp = index(stock_data), df)
      
      # Write to CSV file named by symbol
      output_file <- file.path(output_dir, paste0(symbol, ".csv"))
      write.table(df, output_file, sep = ",", quote = FALSE, row.names = FALSE)
      
      # Collect summary info if requested
      if (summary_df) {
        summary_list[[symbol]] <- data.frame(
          Symbol = symbol,
          NumTimes = nrow(df),
          FirstTime = as.character(min(index(stock_data))),
          LastTime = as.character(max(index(stock_data))),
          stringsAsFactors = FALSE,
          row.names = NULL  # Prevent row names from affecting output
        )
      }
      
    }, error = function(e) {
      cat("Error downloading", symbol, ":", conditionMessage(e), "\n")
    })
  }
  
  # Optionally create and print summary dataframe
  if (summary_df && length(summary_list) > 0) {
    summary_df <- do.call(rbind, summary_list)
    # Reset row names to avoid duplication in printing
    rownames(summary_df) <- NULL
    cat("\nSummary of Downloaded Intraday Data:\n")
    print(summary_df)
  }
}
