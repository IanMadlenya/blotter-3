#!/usr/bin/Rscript --vanilla
#
# Jan Humme (@opentrades) - August 2012, revised April 2013
#
# Tested and found to work correctly using blotter r1420
#
# From Jaekle & Tamasini: A new approach to system development and portfolio optimisation (ISBN 978-1-905641-79-6)
#
# Paragraph 3.2: luxor with $30 slippage and transaction costs

options(width = 240)
Sys.setenv(TZ="UTC")

###

.fast = 10
.slow = 30

.orderqty = 100000
.threshold = 0.0005
.txn.fees = -30

##### PLACE DEMO AND TEST DATES HERE #################
#
#if(isTRUE(options('in_test')$in_test))
#  # use test dates
#  {initDate="2011-01-01" 
#  endDate="2012-12-31"   
#  } else
#  # use demo defaults
#  {initDate="1999-12-31"
#  endDate=Sys.Date()}

initDate = '2002-10-21'

.from='2002-10-21'
#.to='2008-07-04'
.to='2002-10-31'

####

strategy.st = 'luxor'
portfolio.st = 'forex'
account.st = 'IB1'

### packages
#
# quantstrat package will pull in some other packages:
# FinancialInstrument, quantmod, blotter, xts

require(quantstrat)

### FinancialInstrument

currency(c('GBP', 'USD'))

exchange_rate('GBPUSD', tick_size=0.0001)

### quantmod

getSymbols.FI(Symbols='GBPUSD',
	      dir=system.file('extdata',package='quantstrat'),
	      from=.from, to=.to
)

# ALTERNATIVE WAY TO FETCH SYMBOL DATA
#setSymbolLookup.FI(system.file('extdata',package='quantstrat'), 'GBPUSD')
#getSymbols('GBPUSD', from=.from, to=.to, verbose=FALSE)

### xts

GBPUSD = to.minutes30(GBPUSD)
GBPUSD = align.time(to.minutes30(GBPUSD), 1800)

### blotter

initPortf(portfolio.st, symbols='GBPUSD', initDate=initDate, currency='USD')
initAcct(account.st, portfolios=portfolio.st, initDate=initDate, currency='USD')

### quantstrat

initOrders(portfolio.st, initDate=initDate)

### define strategy

strategy(strategy.st, store=TRUE)

### indicators

add.indicator(strategy.st, name = "SMA",
	arguments = list(
		x = quote(Cl(mktdata)[,1]),
		n = .fast
	),
	label="nFast"
)

add.indicator(strategy.st, name="SMA",
	arguments = list(
		x = quote(Cl(mktdata)[,1]),
		n = .slow
	),
	label="nSlow"
)

### signals

add.signal(strategy.st, 'sigCrossover',
	arguments = list(
		columns=c("nFast","nSlow"),
		relationship="gte"
	),
	label='long'
)

add.signal(strategy.st, 'sigCrossover',
	arguments = list(
		columns=c("nFast","nSlow"),
		relationship="lt"
	),
	label='short'
)

### rules

add.rule(strategy.st, 'ruleSignal',
	arguments=list(sigcol='long' , sigval=TRUE,
		orderside='short',
		ordertype='market',
		orderqty='all',
		TxnFees=.txn.fees,
		replace=TRUE
	),
	type='exit',
	label='Exit2LONG'
)

add.rule(strategy.st, 'ruleSignal',
	arguments=list(sigcol='short', sigval=TRUE,
		orderside='long' ,
		ordertype='market',
		orderqty='all',
		TxnFees=.txn.fees,
		replace=TRUE
	),
	type='exit',
	label='Exit2SHORT')

add.rule(strategy.st, 'ruleSignal',
	arguments=list(sigcol='long' , sigval=TRUE,
		orderside='long' ,
		ordertype='stoplimit', prefer='High', threshold=.threshold,
		orderqty=+.orderqty,
		replace=FALSE
	),
	type='enter',
	label='EnterLONG'
)

add.rule(strategy.st, 'ruleSignal',
	arguments=list(sigcol='short', sigval=TRUE,
		orderside='short',
		ordertype='stoplimit', prefer='Low', threshold=-.threshold,
		orderqty=-.orderqty,
		replace=FALSE
	),
	type='enter',
	label='EnterSHORT'
)

###############################################################################

applyStrategy(strategy.st, portfolio.st, verbose = FALSE)

View(getOrderBook(portfolio.st)[[portfolio.st]]$GBPUSD)

###############################################################################

updatePortf(portfolio.st, Symbols='GBPUSD', Dates=paste('::',as.Date(Sys.time()),sep=''))

chart.Posn(portfolio.st, "GBPUSD")

###############################################################################

View(tradeStats(portfolio.st, 'GBPUSD'))

###############################################################################

# save the strategy in an .RData object for later retrieval

save.strategy(strategy.st)

##### PLACE THIS BLOCK AT END OF DEMO SCRIPT ################### 
# book  = getOrderBook(port)
# stats = tradeStats(port)
# rets  = PortfReturns(acct)
################################################################
