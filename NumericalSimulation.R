#CDS数值模拟
#@Yu Nongxin
#@2017.4.16

runs<-100000
n<-10000
R<--0.035
sim<-RVineSim(runs,Rcop$RVM)#for compute the cdf
def<-RVineSim(n,Rcop$RVM)#simulate the CDS
deftime<-matrix(data = NA,nrow = n,ncol = 5)#stopping time
deftime[,1]<--log(1-def[,1])/0.02
deftime[,2]<--log(1-def[,2])/0.04
deftime[,3]<--log(1-def[,3])/0.10
deftime[,4]<--log(1-def[,4])/0.11
deftime[,5]<--log(1-def[,5])/0.12
stoptime<-pmin(deftime[,1],deftime[,2],deftime[,3],deftime[,4],deftime[,5])
udef<-cbind(def,stoptime)
paydef<-udef[udef[,6]<=5,]#再固定期限内违约的样本

#dpdf表示违约支付概率
dpdf<-function(u){
  #u表示违约时间的均匀分布,rand表示Copula分布的随机数;
  w1<-sim[(sim[,1]>pexp(u,0.02))&(sim[,2]>pexp(u,0.04))&((sim[,3]<=pexp(u,0.10))|(sim[,4]<=pexp(u,0.11))|(sim[,5]<=pexp(u,0.12))),]
  return(dim(w1)[1]/runs)
}


p<-sapply(paydef[,6],dpdf,simplify = "array")
#p<-as.array(as.numeric(p))
EB<-(1-0.4)*p*exp(R*paydef[,6])
EB<-mean(EB)

#pay表示保费支付额,ppdf表示保费支付的概率
ppdf<-function(u,rand){
  #u表示违约时间,rand表示Copula分布的随机数;
  w1<-rand[(rand[,1]>=pexp(u,0.02))&(rand[,2]>=pexp(u,0.04))&(rand[,3]>=pexp(u,0.10))&(rand[,4]>=pexp(u,0.11))&(rand[,5]>=pexp(u,0.12)),]
  return(dim(w1)[1]/runs)
}
#停时位于两个支付日之间的违约利息
apdf<-function(u,rand){
  t<-floor(u/0.25)*0.25
  t1<-t+0.25
  w3<-rand[((rand[,1]>=pexp(t,0.02))&(rand[,2]>=pexp(t,0.04))&(rand[,3]>=pexp(t,0.10))&(rand[,4]>=pexp(t,0.11))&(rand[,5]>=pexp(t,0.12)))&((rand[,1]<=pexp(t1,0.02))|(rand[,2]<=pexp(t1,0.04))|(rand[,3]<=pexp(t1,0.10))|(rand[,4]<=pexp(t1,0.11))|(rand[,5]<=pexp(t1,0.12))),]
  return(dim(w3)[1]/runs)
}

#支付额
pay<-function(time,rand){
  t0<-floor(time[,6]/0.25)
  t1<-rep(20,length(time[,1]))
  t<-pmin(t0,t1)
  st<-pmin(time[,6],5)
  prob<-sapply(st,ppdf,rand=sim,simplify = "array")
  #未违约部分
  f<-function(x) sum(exp(R*c(1:x)*0.25))*ppdf(x*0.25,sim)
  undefpay<-sapply(t,f,simplify = "array")
  #违约时超出时间利息
  accrued<-function(t){
    if(t<5){
      dt<-t%%0.25
      accrue<-dt*exp(R*t)*apdf(t,sim)
    }
    else{
      accrue<-0
    }
    return(accrue) 
  }
  accruedpay<-sapply(st,accrued,simplify = "array")
  EA<-mean(undefpay)+mean(accruedpay)
  return(EA)
}
EA<-pay(udef,sim)
#CDS-spreads
s<-EB/EA
