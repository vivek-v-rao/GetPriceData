# Reads price data for invididual stocks from CSV files and writes combined prices to a CSV file

# Source the utility function
source("price_utils.r") # combine_price_data()

# Parameters
input_dir <- "etfs"              # Directory containing CSV files
output_file <- "temp.csv"        # Output file for combined prices
price_field <- "Close"           # Field to extract (e.g., "Close", "Open")
verbose <- TRUE                  # Print status messages

# Combine price data from CSV files
combined_data <- combine_price_data(input_dir, price_field, verbose)

# Ensure combined_data is a dataframe with Date column and write it
if (is.xts(combined_data)) {
  # If it's still an xts object, convert to dataframe with Date
  combined_df <- as.data.frame(combined_data)
  combined_df <- cbind(Date = index(combined_data), combined_df)
} else {
  # It's already a dataframe with Date column from combine_price_data
  combined_df <- combined_data
}

# Write to file with dates
write.table(combined_df, output_file, sep = ",", quote = FALSE, row.names = FALSE)
if (verbose) {
  cat("\nCombined prices written to", output_file, "\n")
}
