### GetPriceData
Get historical stock or futures price data using R

Running the script `xget_prices_compute_returns.r` gives sample output

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
