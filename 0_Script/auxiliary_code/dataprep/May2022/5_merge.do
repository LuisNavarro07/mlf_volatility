
/// Create the Volatility Measure 

twoway (line BAMLC0A4CBBBEY daten, sort) (line BAMLC0A1CAAAEY daten, sort) (line BAMLC0A2CAAEY daten, sort) (line BAMLC0A3CAEY daten, sort), legend(on order(1 "BBB" 2 "AAA" 3 "AA" 4 "A") rows(1) cols(4) size(small)) name(icebofa1,replace) title("ICE BofA US Corporate Index Effective Yield", pos(11) size(small))

/// 
use "${bt}\secondary_rating.dta",clear 

sort rating_agg TRADE_DATE
asrol YIELD, window(date -7 0) stat(sd) gen(sd_bond)
gen yr = year(TRADE_DATE)

twoway line sd_bond TRADE_DATE if rating_agg > 0 & yr == 2020, by(rating_agg)