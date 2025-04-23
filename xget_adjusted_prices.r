# Downloads OHLCV data for symbols and saves to individual CSV files

# Load required package
if (!requireNamespace("quantmod", quietly = TRUE)) {
  install.packages("quantmod")
}
library(quantmod)

# Function to download and save stock data
download_stock_data <- function(symbols,
                                start_date,
                                end_date,
                                output_dir,
                                verbose = TRUE,
                                summary_df = TRUE,
                                include_symbol_in_colnames = FALSE,
                                adjusted = FALSE,
                                nround = 4) {
  
  # Create output directory if it doesn't exist
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  
  # Container for summary info
  summary_list <- list()
  
  for (sym in symbols) {
    if (verbose) message("Downloading data for ", sym, " ...")
    
    # Fetch data; skip on error
    stock_xts <- tryCatch(
      getSymbols(sym, src = "yahoo",
                 from = start_date, to = end_date,
                 auto.assign = FALSE),
      error = function(e) {
        warning("  ✗ Failed to download ", sym, ": ", e$message)
        return(NULL)
      }
    )
    if (is.null(stock_xts)) next
    
    # If requested, adjust OHLC for dividends & splits
    if (adjusted) {
      stock_xts <- adjustOHLC(stock_xts, use.Adjusted = TRUE)
    }
    
    # Drop any 'Adjusted' column
    adj_cols <- grep("Adjusted$", colnames(stock_xts), value = TRUE)
    if (length(adj_cols) > 0) {
      stock_xts <- stock_xts[, setdiff(colnames(stock_xts), adj_cols)]
    }
    
    # Optionally remove symbol prefix from column names
    if (!include_symbol_in_colnames) {
      colnames(stock_xts) <- sub(paste0("^", sym, "\\."), "", colnames(stock_xts))
    }
    
    # Convert to data.frame with a Date column
    df <- data.frame(
      Date = index(stock_xts),
      coredata(stock_xts),
      row.names = NULL,
      stringsAsFactors = FALSE
    )
    
    # Round Open, High, Low, Close to nround decimals
    cols_to_round <- intersect(c("Open", "High", "Low", "Close"), colnames(df))
    if (length(cols_to_round) > 0) {
      df[cols_to_round] <- lapply(df[cols_to_round], function(x) round(x, nround))
    }
    
    # Write to CSV without quoting values or column names
    file_path <- file.path(output_dir, paste0(sym, ".csv"))
    write.csv(df, file = file_path, row.names = FALSE, quote = FALSE)
    if (verbose) message("  ✓ Saved data to ", file_path)
    
    # Collect summary info
    if (summary_df) {
      summary_list[[sym]] <- data.frame(
        Symbol = sym,
        Start  = as.character(min(df$Date)),
        End    = as.character(max(df$Date)),
        Rows   = nrow(df),
        stringsAsFactors = FALSE
      )
    }
  }
  
  # Print and return summary table if requested
  if (summary_df && length(summary_list) > 0) {
    summary_tbl <- do.call(rbind, summary_list)
    message("\nDownload summary:")
    print(summary_tbl)
    invisible(summary_tbl)
  }
}

# -----------------------------
# Example usage

# User settings
start_date  <- "2000-01-01"
end_date    <- Sys.Date()
verbose     <- TRUE
output_dir  <- "stock_data"
ticker_file <- "tickers.txt"      # Set to "" if not using a file
summary_df  <- TRUE
include_symbol_in_colnames <- FALSE
adjusted    <- TRUE               # Toggle: FALSE = raw, TRUE = adjusted
nround      <- 4                  # Number of decimals for OHLC
max_sym     <- 4

# Determine symbols
if (nzchar(ticker_file) && file.exists(ticker_file)) {
  symbols <- readLines(ticker_file)
  symbols <- trimws(symbols)
  if (length(symbols) == 0) stop("Ticker file is empty")
} else {
  symbols <- c("SPY", "EFA", "EEM")
}

# Limit to max_sym
if (length(symbols) > max_sym) {
  symbols <- symbols[1:max_sym]
}

# Download and save
download_stock_data(symbols,
                    start_date,
                    end_date,
                    output_dir,
                    verbose = verbose,
                    summary_df = summary_df,
                    include_symbol_in_colnames = include_symbol_in_colnames,
                    adjusted = adjusted,
                    nround = nround)
