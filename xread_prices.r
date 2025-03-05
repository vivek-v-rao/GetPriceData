suppressMessages(library(xts))
source("utils.r")

prices_file <- "prices.csv"
df <- read.csv(prices_file, stringsAsFactors = FALSE)
df_xts <- xts(df[, -1], order.by = as.Date(df$Date))
cat("prices file:", prices_file, "\n\nhead\n")
print(head(df_xts, 3))
cat("\ntail\n")
print(tail(df_xts, 3))
cat("\n")
print(non_na_ranges(df))
