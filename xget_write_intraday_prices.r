# Downloads intraday OHLCV data for stocks or futures and saves to individual CSV files in an output directory."

.proctime00 = proc.time()
source("price_utils.r") # download_intraday_data()

# Example usage
start_date <- "2000-01-01"
end_date <- "2025-03-05"
verbose <- FALSE # TRUE
# create an output subdirectory named by the current date
ticker_file <- "good_futures_symbols.txt" # "futures_symbols.txt" # "tickers.txt" # Set to "" for no file, or e.g., "tickers.txt"
summary_df <- TRUE           # Set to TRUE to print summary dataframe
include_symbol_in_colnames <- FALSE  # Set to FALSE to exclude symbol from column names
max_sym = 10^6
interval <- "1min"
output_dir <- paste0("futures/", interval, "/",
	format(Sys.Date(), "%Y%m%d"))

# Determine symbols based on ticker_file
if (ticker_file != "" && file.exists(ticker_file)) {
  symbols <- readLines(ticker_file)
  symbols <- trimws(symbols)  # Remove any leading/trailing whitespace
  if (length(symbols) == 0) stop("Ticker file is empty")
  cat("\nticker file:", ticker_file)
} else {
  # Default symbols if no ticker file is specified or exists
  symbols <- c("SPY", "EFA", "EEM")
}
if (length(symbols) > max_sym) symbols <- symbols[1:max_sym]
cat("\n#symbols:", length(symbols))
cat("\noutput directory:", output_dir, "\n\n")
# Download data and save to files
download_intraday_data(symbols, start_date, end_date,
	interval = interval, output_dir = output_dir, verbose = verbose,
	summary_df = summary_df,
	include_symbol_in_colnames = include_symbol_in_colnames)
cat("\n Time elapsed(s): ", (proc.time() - .proctime00)[3],"\n")
