#!/bin/bash
#https://www.evonshahriar.com
tickers=("$@")
if [ -z "$tickers" ]; then
  echo "
====================================================
                 [stock.sh Help]
====================================================
 Description:
    Find the data of a certain stock/crypto/commodity/forex/
    etf/futures using this script.
 Usage:
    To make the script executable:
    chmod +x stock.sh
    To see the price update of an asset:
    ./stock.sh {symbol/ticker}
 Examples:
    ./stock.sh TSLA (Tinker Symbol Of Tesla Inc.)
    ./stock.sh 600883.SS (600883 = Yunnan Bowin Tech; SS = Shanghai Stock Exchange)
    ./stock.sh BTC-USD (Cryptocurrency - CCC)
    ./stock.sh GOLD (Commodity)
    ./stock.sh USDCNY=X (Forex Rate)
    ./stock.sh BRK-A (ETF)
 Sample command: 
    ./stock.sh TSLA 600883.SS BTC-USD GOLD USDCNY=X BRK-A
    watch -n 1 -c ./stock.sh TSLA 600883.SS BTC-USD GOLD USDCNY=X BRK-A (to see the updates of every sec)
 Ticker/Symbol lookup:
    https://finance.yahoo.com/lookup
=====================================================
  "
  exit
fi
yahoo_api="https://query1.finance.yahoo.com/v7/finance/quote?lang=en-US&region=US&corsDomain=finance.yahoo.com"
modules=(symbol marketState regularMarketPrice regularMarketChange / 
	regularMarketChangePercent preMarketPrice preMarketChange preMarketChangePercent / 
	postMarketPrice postMarketChange postMarketChangePercent)
symbols=$(IFS=,; echo "${tickers[*]}")
fields=$(IFS=,; echo "${modules[*]}")
if [ -z "$color" ]; then
  : "${default:=\e[00m}"
  : "${bnw:=\e[1;30m\e[47m}"
  : "${green:=\e[1;97m\e[42m}"
  : "${yellow:=\e[43m}"
  : "${red:=\e[1;97m\e[41m}"
fi
results=$(curl -s "$yahoo_api&fields=$fields&symbols=$symbols" \
  | jq '.quoteResponse .result')

query () {
  echo $results | jq -r ".[] | select(.symbol == \"$1\") | .$2"
}
for symbol in $(IFS=' '; echo "${tickers[*]}"); do
  market="$(query $symbol 'market')"
  if [ -z $market ]; then
  	echo "
====================================================
                  [Stock Help]
====================================================
 Advice:
    Nothing found for symbol $symbol
    Lookup the right one: finance.yahoo.com/lookup
===================================================== 
  	"
    continue
  fi
  preMarketChange="$(query $symbol 'preMarketChange')"
  postMarketChange="$(query $symbol 'postMarketChange')"
  if [ $market == "PRE" ] \
    && [ $preMarketChange != "0" ] \
    && [ $preMarketChange != "null" ]; then
    stock_price=$(query $symbol 'preMarketPrice')
    difference=$preMarketChange
    percent=$(query $symbol 'preMarketChangePercent')
  elif [ $market != "REGULAR" ] \
    && [ $postMarketChange != "0" ] \
    && [ $postMarketChange != "null" ]; then
    stock_price=$(query $symbol 'postMarketPrice')
    difference=$postMarketChange
    percent=$(query $symbol 'postMarketChangePercent')
  else
    stock_price=$(query $symbol 'regularMarketPrice')
    difference=$(query $symbol 'regularMarketChange')
    percent=$(query $symbol 'regularMarketChangePercent')
  fi
  if [ "$difference" == "0" ]; then
    color=$yellow
  elif ( echo "$difference" | grep -q ^- ); then
    color=$red
  else
    color=$green
  fi
  if [ "$stock_price" != "null" ]; then
    printf "%-10s$bnw%12.4f$default" $symbol $stock_price
    printf "$color%10.2f%12s$default" $difference $(printf "(%.2f%%)" $percent) 
    printf "\n"
  fi
done
if ! $(type jq > /dev/null 2>&1); then
  echo "
====================================================
                  [Stock Help]
====================================================
 Advice:
    JQ is not installed. 
    To install try: sudo apt-get install jq
=====================================================
"
  exit 1
fi
