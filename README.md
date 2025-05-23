### GetPriceData
Get historical stock or futures price data, either daily or intraday using the R quantmod package

Running the script `xget_prices_compute_returns.r` to get daily prices and print
return statistics gives sample output

```
Performance Metrics (Risk-Free Rate = 0.03 ):
                          SPY     TLT     HYG
Annualized_Returns     0.0962  0.0325  0.0476
Annualized_Volatility  0.1984  0.1541  0.1117
Sharpe_Ratio           0.3336  0.0165  0.1576
Skewness              -0.3639  0.0167  0.3060
Kurtosis              16.4761  6.0711 40.9703
Minimum               -0.1159 -0.0690 -0.0844
Maximum                0.1356  0.0725  0.1157

Correlation Matrix of Returns:
        SPY     TLT     HYG
SPY  1.0000 -0.3316  0.6820
TLT -0.3316  1.0000 -0.1445
HYG  0.6820 -0.1445  1.0000

wrote price table to prices.csv 

date ranges:
  Symbol      First       Last NumObs
1    SPY 2000-01-03 2025-03-05   6331
2    TLT 2002-07-30 2025-03-05   5687
3    HYG 2007-04-11 2025-03-05   4505
```

Running `xget_write_prices.r` just gets price data, with sample output
```
output directory: ETF/20250305 

Summary of Downloaded Data:
  Symbol Num_Days First_Date  Last_Date
1    SPY     6331 2000-01-03 2025-03-05
2    TLT     5687 2002-07-30 2025-03-05
3    HYG     4505 2007-04-11 2025-03-05
```

Running `xcombine_price_data.r` combines data from per-symbol prices file into a table, getting
a field such as the closing price, with sample output
```
read data for HYG from ETF/20250305/HYG.csv 4505 days from 2007-04-11 to 2025-03-05 
read data for QQQ from ETF/20250305/QQQ.csv 6331 days from 2000-01-03 to 2025-03-05 
read data for SPY from ETF/20250305/SPY.csv 6331 days from 2000-01-03 to 2025-03-05 
read data for TLT from ETF/20250305/TLT.csv 5687 days from 2002-07-30 to 2025-03-05 

Combined prices written to temp.csv
```

Running `xget_write_intraday_prices.r` to get intraday prices gives sample output

```
ticker file: good_futures_symbols.txt
#symbols: 5
output directory: futures/1min/20250305 


Summary of Downloaded Intraday Data:
     Symbol NumTimes           FirstTime            LastTime
1 ESH25.CME     8634 2025-02-25 19:00:00 2025-03-04 18:59:00
2 ESM25.CME     8625 2025-02-25 19:09:00 2025-03-04 18:59:00
3 ESU25.CME     8544 2025-02-25 20:30:00 2025-03-04 18:59:00
4 ESZ25.CME     6108 2025-02-27 10:34:00 2025-03-04 16:24:02
5 NQH25.CME     8634 2025-02-25 19:00:00 2025-03-04 18:59:00

 Time elapsed(s):  1.69
```
