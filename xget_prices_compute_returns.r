# Downloads stock prices, computes returns and stats, optionally
# saves to CSV.

source("price_utils.r")
source("utils.r")

start_date <- "2000-01-01"
end_date <- "2100-01-01"
trading_days <- 252       # Standard number of trading days in a year
rf_rate <- 0.03           # 3% annual risk-free rate
verbose <- TRUE
output_prices_file <- "prices.csv"
ticker_file <- "etf_symbols.txt" # "futures_symbols.txt" Set to "" for no file
max_sym = 100

# Determine symbols based on ticker_file
if (ticker_file != "" && file.exists(ticker_file)) {
  symbols <- readLines(ticker_file)
  symbols <- trimws(symbols)  # Remove any leading/trailing whitespace
  if (length(symbols) == 0) stop("Ticker file is empty")
} else {
  # Default symbols if no ticker file is specified or exists
  symbols <- c("SPY", "TLT", "LQD", "FALN", "LQD", "HYG")
}
if (length(symbols) > max_sym) symbols <- symbols[1:max_sym]

sink(nullfile())
prices <- get_prices(symbols, start_date, end_date, verbose = verbose)
sink()

# Analyze returns with correlation matrix
x <- suppressWarnings(analyze_returns(prices, trading_days, rf_rate,
	verbose = verbose, print_correlation = TRUE))
if (output_prices_file != "") {
	write.table(x$prices, output_prices_file, sep = ",", quote = FALSE,
	row.names = FALSE)
	cat("\nwrote price table to", output_prices_file, "\n")}
x$prices$Date <- NULL
cat("\ndate ranges:\n")
print(non_na_ranges(x$prices))
