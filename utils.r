non_na_ranges <- function(df) {
  # Returns a data frame with the first and last non-NA index values and count 
  # for each column in df, using Date column or row names as indices.
  # Args: df (data frame)
  # Returns: data frame with columns: Symbol, First, Last, NumObs

  # Get row indices (e.g., row names or Date column)
  if ("Date" %in% names(df)) {
    # Use Date column if present
    row_indices <- df[["Date"]]
  } else {
    # Use row names if no Date column
    row_indices <- rownames(df)
    if (is.null(row_indices)) {
      stop("Data frame has no Date column or row names to use as indices")
    }
  }
  # Initialize lists to store results
  col_names <- names(df)
  if ("Date" %in% col_names) {
    col_names <- col_names[col_names != "Date"]  # Exclude Date column
  }
  first_indices <- character(length(col_names))
  last_indices <- character(length(col_names))
  num_obs <- integer(length(col_names))
  
  # Populate indices and counts for each column
  for (i in seq_along(col_names)) {
    col <- col_names[i]
    non_na_positions <- which(!is.na(df[[col]]))
    
    if (length(non_na_positions) > 0) {
      first_pos <- min(non_na_positions)
      last_pos <- max(non_na_positions)
      first_indices[i] <- as.character(row_indices[first_pos])
      last_indices[i] <- as.character(row_indices[last_pos])
      num_obs[i] <- length(non_na_positions)
    } else {
      first_indices[i] <- NA
      last_indices[i] <- NA
      num_obs[i] <- 0
    }
  }
  # Create and return data frame
  result <- data.frame(
    Symbol = col_names,
    First = first_indices,
    Last = last_indices,
    NumObs = num_obs,
    stringsAsFactors = FALSE
  )
  return(result)
}