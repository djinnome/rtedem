## ------------------------------------------------------------------------
library(rtedem)
library(ggplot2)
library(FME)
library(reshape2)
library(plyr)

## ----setUpParameters, fig.width=6, cache=TRUE----------------------------
##par.ls <- publishedParameters()[['TECO']]
##par <- c(rep(0.1, length(par.ls$tau)-1), par.ls$tau, par.ls$trans$val)
##names(par) <- c(sprintf('label1.a%d', 1:(length(par.ls$tau)-1)), sprintf('tau%d', 1:length(par.ls$tau)), as.character(par.ls$trans$name))

par <- unlist(list('label1.a1'=0.1, tau1=180, tau2=100*365))
parLimit <- list(lower=unlist(list('label1.a1'=0, tau1=1, tau2=10*365)),
                 upper=unlist(list('label1.a1'=1, tau1=10*365, tau2=1e3*365)))

C_bulk <- 1
dt <- 1
tauStr <- 'tau'
transStr <- 'A'
allocationStr <- 'a'
relTime <- list(C1=4)
temporalSplit <- c(10)

refData <- createSynData(par=par, timeArr=floor(2^(seq(1, 10, length=50))), 
                        C_bulk=C_bulk, dt=dt, relTime=list(),
                        tauStr=tauStr, transStr=transStr, allocationStr=allocationStr, 
                        relSd.ls = list(dCO2=0.2, relC=0),
                        verbose=FALSE)
refData <- refData[refData$time != 0, ]
print(head(refData))
ggplot(refData[refData$variable %in% 'dCO2',]) + 
  geom_point(aes(x=time, y=mean, color=label)) + 
  geom_errorbar(aes(x=time, ymin=mean-sd, ymax=mean+sd, group=label)) + scale_x_log10()

print(measure.firstOrderModel(par, refData[refData$variable %in% 'dCO2',], relTime=relTime, temporalSplit=c(), return.df=TRUE))
print(measure.firstOrderModel(par, refData[refData$variable %in% 'dCO2',], relTime=relTime, temporalSplit=c()))

## ----runMCMC, fig.width=4, cache=TRUE------------------------------------
optResults <- modMCMC(f=measure.firstOrderModel, 
                      p=par*rnorm(length(par), mean=1, sd=0.1),
                      lower=parLimit$lower,
                      upper=parLimit$upper,
                      refData=refData[refData$variable %in% 'dCO2',], weighByCount=FALSE,
                      niter=1e4)

ggplot(melt(optResults$par)) + geom_line(aes(x=Var1, y=value)) + facet_wrap(~Var2, scales='free')

modelResults <- createSynData(par=optResults$bestpar, timeArr=unique(floor(2^(seq(1, 10, length=50)))), C_bulk=C_bulk, dt=dt, relTime=list(), tauStr=tauStr, transStr=transStr, allocationStr=allocationStr, relSd.ls = list(dCO2=0, relC=0))
modelResults$index <- 0
for(parIndex in sample(floor(dim(optResults$par)[1]*0.75):dim(optResults$par)[1], size=100)){
  temp <- createSynData(par=optResults$par[parIndex,], 
                        timeArr=unique(floor(2^(seq(1, 10, length=50)))), 
                        C_bulk=C_bulk, dt=dt, relTime=list(), 
                        tauStr=tauStr, transStr=transStr, allocationStr=allocationStr,
                        relSd.ls = list(dCO2=0, relC=0))
  temp$index <- parIndex
  
  modelResults <- rbind.fill(modelResults, temp)
}

## ----plots, fig.width=6--------------------------------------------------
ggplot(refData[refData$variable %in% 'dCO2',])  + 
  geom_line(data=modelResults, aes(x=time, y=mean, group=index), color='red', alpha=0.1) +
  geom_point(aes(x=time, y=mean)) +
  geom_errorbar(aes(x=time, ymin=mean-sd, ymax=mean+sd))+ 
  scale_y_log10() + scale_x_log10() + 
  labs(title='Model-SynData fit', x='CO2 flux [g-C-CO2 g^-1-C-soil day^-1]') 


for(varStr in names(par)){
  parPlotData <- melt(optResults$par[unique(modelResults$index),varStr])
  print(ggplot(parPlotData) + 
          geom_histogram(aes(x=value), binwidth=diff(range(parPlotData$value))/30) +
          xlim(c(parLimit$lower[varStr], parLimit$upper[varStr])) + 
          labs(title=varStr) + geom_vline(xintercept=par[[varStr]], color='red'))
}

