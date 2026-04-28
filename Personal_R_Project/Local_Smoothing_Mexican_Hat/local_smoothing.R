library(ggplot2)
library(dplyr)
library(tidyr)

m <- 1000 #Monte Carlo runs: j
n <- 101 #sample size :i
x <- 2*pi*seq(-1, 1, length=n)
y_true <- (1-x^2)*exp(-0.5*x^2)
# EDA 画图
ggplot() +
  geom_point(aes(x = x, y = y_true), color = "blue", pch=1,size = 2, alpha = 0.8)

set.seed(7406)
error<-rnorm(length(x), sd=0.2)
ggplot() +
  geom_point(aes(x = x, y = y_true+error), color = "blue", pch=1,size = 2, alpha = 0.8)

#matrix of to store fitted values for three methods
fv_loess <- fv_kernel <- fv_spline <- matrix(0, nrow= n, ncol= m)#每一列是一套样本，一共1000列

##Generate all true y value+error, fit 3 models and store the fitted values
set.seed(7406)
for (j in 1:m){
  ## simulate y-values
  y <- (1-x^2)*exp(-0.5*x^2) + rnorm(length(x), sd=0.2);
  ## Get the estimates and store them
  fv_loess[,j] <- predict(loess(y ~ x, span = 0.75), newdata = x);
  fv_kernel[,j] <- ksmooth(x, y, kernel="normal", bandwidth= 0.2, x.points=x)$y;
  fv_spline[,j] <- predict(smooth.spline(y ~ x), x=x)$y
}
# calculate and plot the mean of three estimators in a single plot
mean_loess <- apply(fv_loess,1,mean)
mean_kernel <- apply(fv_kernel,1,mean)
mean_spline <- apply(fv_spline,1,mean)
#dmin <- min( mean_loess, mean_kernel,mean_spline)
#dmax <- max( mean_loess, mean_kernel, mean_spline)

dim(fv_loess) #测试维度101*1000

df_meanplot <- data.frame(x = x, True = y_true,Loess = mean_loess,Kernel = mean_kernel,
  Spline = mean_spline)
ggplot() +
  geom_point(aes(x = x, y = y_true), color = "black", size = 1.5, alpha = 0.6) +
  geom_line(data = df_meanplot , aes(x = x, y = Loess, color = "Loess"), size = 0.5) +
  geom_line(data = df_meanplot , aes(x = x, y = Kernel, color = "Kernel"), size = 0.5) +
  geom_line(data = df_meanplot , aes(x = x, y = Spline, color = "Spline"), size = 0.5) +
  labs(title = "Monte Carlo Fitted Mean Curve of Three Methods",x = "x", y = "y", color ="Smoothing Method") +
  theme_minimal(base_size = 14)

# calculate and plot the bias 
bias_loess<-mean_loess-y_true
bias_kernel<-mean_kernel-y_true
bias_spline<-mean_spline-y_true

df_biasplot <- data.frame(x = x,Loess = bias_loess,Kernel = bias_kernel,Spline = bias_spline)
df_biasplot %>% ggplot() +
  geom_line(aes(x = x, y = Loess, color = "Loess"), size = 0.5) +
  geom_line(aes(x = x, y = Kernel, color = "Kernel"), size = 0.5) +
  geom_line(aes(x = x, y = Spline, color = "Spline"), size = 0.5) +
  labs(title = "Bias of Three Methods by Monte Carlo CV",x = "x", y = "Bias", color ="Smoothing Method") +
  theme_minimal(base_size = 14)

# calculate and plot the Var
var_loess<-rowMeans((fv_loess - rowMeans(fv_loess))^2)
var_kernel<-rowMeans((fv_kernel - rowMeans(fv_kernel))^2)
var_spline<-rowMeans((fv_spline - rowMeans(fv_spline))^2)

df_varplot <- data.frame(x = x,Loess = var_loess,Kernel = var_kernel,Spline = var_spline)
df_varplot %>% ggplot() +
  geom_line(aes(x = x, y = Loess, color = "Loess"), size = 0.5) +
  geom_line(aes(x = x, y = Kernel, color = "Kernel"), size = 0.5) +
  geom_line(aes(x = x, y = Spline, color = "Spline"), size = 0.5) +
  labs(title = "Variance of Three Methods by Monte Carlo CV",x = "x", y = "Variance", color ="Smoothing Method") +
  theme_minimal(base_size = 14)

# calculate and plot the MSE
mse_loess<-rowMeans((fv_loess - y_true)^2)
mse_kernel<-rowMeans((fv_kernel - y_true)^2)
mse_spline<-rowMeans((fv_spline - y_true)^2)

df_mseplot <- data.frame(x = x,Loess = mse_loess,Kernel = mse_kernel,Spline = mse_spline)
df_mseplot %>% ggplot() +
  geom_line(aes(x = x, y = Loess, color = "Loess"), size = 0.5) +
  geom_line(aes(x = x, y = Kernel, color = "Kernel"), size = 0.5) +
  geom_line(aes(x = x, y = Spline, color = "Spline"), size = 0.5) +
  labs(title = "MSE of Three Methods by Monte Carlo CV",x = "x", y = "MSE", color ="Smoothing Method") +
  theme_minimal(base_size = 14)

####-------Extra Experiment for equidistant dataset--------
#matrix of to store fitted values LOESS with 4 diff span values
fv_loess75 <- fv_loess50 <- fv_loess25 <- fv_loess10 <-matrix(0, nrow= n, ncol= m)

##Generate all true y value+error, fit 3 models and store the fitted values
set.seed(7406)
for (j in 1:m){
  ## simulate y-values
  y <- (1-x^2)*exp(-0.5*x^2) + rnorm(length(x), sd=0.2);
  ## Get the estimates and store them
  fv_loess75[,j] <- predict(loess(y ~ x, span = 0.75), newdata = x);
  fv_loess50[,j] <- predict(loess(y ~ x, span = 0.5), newdata = x);
  fv_loess25[,j] <- predict(loess(y ~ x, span = 0.25), newdata = x);
  fv_loess10[,j] <- predict(loess(y ~ x, span = 0.1), newdata = x);
}
# calculate and plot the mean 
mean_loess75 <- apply(fv_loess75,1,mean)
mean_loess50 <- apply(fv_loess50,1,mean)
mean_loess25 <- apply(fv_loess25,1,mean)
mean_loess10 <- apply(fv_loess10,1,mean)

df_meanplotLOESS <- data.frame(x = x, True = y_true,span75 = mean_loess75,
                               span50 = mean_loess50,span25 = mean_loess25,
                               span10 = mean_loess10)
ggplot() +
  geom_point(aes(x = x, y = y_true), color = "black", size = 1.5, alpha = 0.6) +
  geom_line(data = df_meanplotLOESS , aes(x = x, y = span75, color = "span75"), size = 0.5) +
  geom_line(data = df_meanplotLOESS , aes(x = x, y = span50, color = "span50"), size = 0.5) +
  geom_line(data = df_meanplotLOESS , aes(x = x, y = span25, color = "span25"), size = 0.5) +
  geom_line(data = df_meanplotLOESS , aes(x = x, y = span10, color = "span10"), size = 0.5) +
  labs(title = "Monte Carlo Fitted Mean Curve of 4 LOESS Span Values",x = "x", y = "y", color ="span value") +
  scale_color_discrete(labels = c("span75" = "span = 0.75", "span50" = "span = 0.50",
                                "span25" = "span = 0.25", "span10" = "span = 0.10"))+
  theme_minimal(base_size = 14)
# calculate and plot the bias 
bias_loess75<-mean_loess75-y_true
bias_loess50<-mean_loess50-y_true
bias_loess25<-mean_loess25-y_true
bias_loess10<-mean_loess10-y_true

df_biasplotLOESS <- data.frame(x = x,span75 = bias_loess75,span50 = bias_loess50,
                               span25 = bias_loess25,span10 = bias_loess10)

df_biasplotLOESS  %>% ggplot() +
  geom_line(aes(x = x, y = span75, color = "span75"), size = 0.5) +
  geom_line(aes(x = x, y = span50, color = "span50"), size = 0.5) +
  geom_line(aes(x = x, y = span25, color = "span25"), size = 0.5) +
  geom_line(aes(x = x, y = span10, color = "span10"), size = 0.5) +
  labs(title = "Bias of 4 LOESS Fitted Curves by Monte Carlo CV",x = "x", y = "Bias", color ="span value") +
  scale_color_discrete(labels = c("span75" = "span = 0.75", "span50" = "span = 0.50",
                                  "span25" = "span = 0.25", "span10" = "span = 0.10"))+
  theme_minimal(base_size = 14)
# calculate and plot the Var
var_loess75<-rowMeans((fv_loess75 - rowMeans(fv_loess75))^2)
var_loess50<-rowMeans((fv_loess50 - rowMeans(fv_loess50))^2)
var_loess25<-rowMeans((fv_loess25 - rowMeans(fv_loess25))^2)
var_loess10<-rowMeans((fv_loess10 - rowMeans(fv_loess10))^2)

df_varplotLOESS <- data.frame(x = x, span75=var_loess75,span50 = var_loess50,
                         span25 = var_loess25,span10 = var_loess10)
 df_varplotLOESS %>% ggplot() +
  geom_line(aes(x = x, y = span75, color = "span75"), size = 0.5) +
  geom_line(aes(x = x, y = span50, color = "span50"), size = 0.5) +
  geom_line(aes(x = x, y = span25, color = "span25"), size = 0.5) +
  geom_line(aes(x = x, y = span10, color = "span10"), size = 0.5) +
  labs(title = "Variance of 4 LOESS Fitted Curves by Monte Carlo CV",x = "x", y = "Variance", color ="span value") +
  scale_color_discrete(labels = c("span75" = "span = 0.75", "span50" = "span = 0.50",
                                  "span25" = "span = 0.25", "span10" = "span = 0.10"))+
  theme_minimal(base_size = 14)
# calculate and plot the MSE
mse_loess75<-rowMeans((fv_loess75 - y_true)^2)
mse_loess50<-rowMeans((fv_loess50 - y_true)^2)
mse_loess25<-rowMeans((fv_loess25 - y_true)^2)
mse_loess10<-rowMeans((fv_loess10 - y_true)^2)

df_mseplotLOESS <- data.frame(x = x,span75=mse_loess75,span50=mse_loess50,
                              span25=mse_loess25,span10=mse_loess10)
df_mseplotLOESS %>% ggplot() +
  geom_line(aes(x = x, y = span75, color = "span75"), size = 0.5) +
  geom_line(aes(x = x, y = span50, color = "span50"), size = 0.5) +
  geom_line(aes(x = x, y = span25, color = "span25"), size = 0.5) +
  geom_line(aes(x = x, y = span10, color = "span10"), size = 0.5) +
  labs(title = "MSE of 4 LOESS Fitted Curves by Monte Carlo CV",x = "x", y = "MSE", color ="span value") +
  scale_color_discrete(labels = c("span75" = "span = 0.75", "span50" = "span = 0.50",
                                  "span25" = "span = 0.25", "span10" = "span = 0.10"))+
  theme_minimal(base_size = 14)

#Non-equidistant dataset
x <- read.table(file="HW04part2-1.x.csv", sep=",", header=TRUE)[,1] #x is a vector
y_true <- (1-x^2)*exp(-0.5*x^2)
# EDA 画图
ggplot() +
  geom_point(aes(x = x, y = y_true), color = "blue", pch=1,size = 2, alpha = 0.8)

set.seed(7406)
error<-rnorm(length(x), sd=0.2)
ggplot() +
  geom_point(aes(x = x, y = y_true+error), color = "blue", pch=1,size = 2, alpha = 0.8)

#matrix of to store fitted values for three methods
fv_loess <- fv_kernel <- fv_spline <- matrix(0, nrow= n, ncol= m)
##Generate all true y value+error, fit 3 models and store the fitted values
set.seed(7406)
for (j in 1:m){
  ## simulate y-values
  y <- (1-x^2)*exp(-0.5*x^2) + rnorm(length(x), sd=0.2)
  ## Get the estimates and store them
  fv_loess[,j] <- predict(loess(y ~ x, span = 0.3365), newdata = x)
  fv_kernel[,j] <- ksmooth(x, y, kernel="normal", bandwidth= 0.2, x.points=x)$y
  fv_spline[,j] <- predict(smooth.spline(y ~ x,spar=0.7163), x=x)$y
}
# calculate and plot the mean of three estimators in a single plot
mean_loess <- apply(fv_loess,1,mean)
mean_kernel <- apply(fv_kernel,1,mean)
mean_spline <- apply(fv_spline,1,mean)

df_meanplot <- data.frame(x = x, True = y_true,Loess = mean_loess,Kernel = mean_kernel,
                          Spline = mean_spline)
ggplot() +
  geom_point(aes(x = x, y = y_true), color = "black", size = 1.5, alpha = 0.6) +
  geom_line(data = df_meanplot , aes(x = x, y = Loess, color = "Loess"), size = 0.5) +
  geom_line(data = df_meanplot , aes(x = x, y = Kernel, color = "Kernel"), size = 0.5) +
  geom_line(data = df_meanplot , aes(x = x, y = Spline, color = "Spline"), size = 0.5) +
  labs(title = "Monte Carlo Fitted Mean Curve of Three Methods",x = "x", y = "y", color ="Smoothing Method") +
  theme_minimal(base_size = 14)

# calculate and plot the bias 
bias_loess<-mean_loess-y_true
bias_kernel<-mean_kernel-y_true
bias_spline<-mean_spline-y_true

df_biasplot <- data.frame(x = x,Loess = bias_loess,Kernel = bias_kernel,Spline = bias_spline)
df_biasplot %>% ggplot() +
  geom_line(aes(x = x, y = Loess, color = "Loess"), size = 0.5) +
  geom_line(aes(x = x, y = Kernel, color = "Kernel"), size = 0.5) +
  geom_line(aes(x = x, y = Spline, color = "Spline"), size = 0.5) +
  labs(title = "Bias of Three Methods by Monte Carlo CV",x = "x", y = "Bias", color ="Smoothing Method") +
  theme_minimal(base_size = 14)

# calculate and plot the Var
var_loess<-rowMeans((fv_loess - rowMeans(fv_loess))^2)
var_kernel<-rowMeans((fv_kernel - rowMeans(fv_kernel))^2)
var_spline<-rowMeans((fv_spline - rowMeans(fv_spline))^2)

df_varplot <- data.frame(x = x,Loess = var_loess,Kernel = var_kernel,Spline = var_spline)
df_varplot %>% ggplot() +
  geom_line(aes(x = x, y = Loess, color = "Loess"), size = 0.5) +
  geom_line(aes(x = x, y = Kernel, color = "Kernel"), size = 0.5) +
  geom_line(aes(x = x, y = Spline, color = "Spline"), size = 0.5) +
  labs(title = "Variance of Three Methods by Monte Carlo CV",x = "x", y = "Variance", color ="Smoothing Method") +
  theme_minimal(base_size = 14)

# calculate and plot the MSE
mse_loess<-rowMeans((fv_loess - y_true)^2)
mse_kernel<-rowMeans((fv_kernel - y_true)^2)
mse_spline<-rowMeans((fv_spline - y_true)^2)

df_mseplot <- data.frame(x = x,Loess = mse_loess,Kernel = mse_kernel,Spline = mse_spline)
df_mseplot %>% ggplot() +
  geom_line(aes(x = x, y = Loess, color = "Loess"), size = 0.5) +
  geom_line(aes(x = x, y = Kernel, color = "Kernel"), size = 0.5) +
  geom_line(aes(x = x, y = Spline, color = "Spline"), size = 0.5) +
  labs(title = "MSE of Three Methods by Monte Carlo CV",x = "x", y = "MSE", color ="Smoothing Method") +
  theme_minimal(base_size = 14)

####-------Extra Experiment for non-equidistant dataset--------
#matrix of to store fitted values LOESS with 4 diff span values
fv_spline7163 <- fv_spline50 <- fv_spline25 <- fv_spline_df <-matrix(0, nrow= n, ncol= m)

##Generate all true y value+error, fit 3 models and store the fitted values
set.seed(7406)
for (j in 1:m){
  ## simulate y-values
  y <- (1-x^2)*exp(-0.5*x^2) + rnorm(length(x), sd=0.2);
  ## Get the estimates and store them
  fv_spline7163[,j] <- predict(smooth.spline(y ~ x,spar=0.7163), x=x)$y
  fv_spline50[,j] <- predict(smooth.spline(y ~ x,spar=0.5), x=x)$y
  fv_spline25[,j] <- predict(smooth.spline(y ~ x,spar=0.25), x=x)$y
  fv_spline_df[,j] <- predict(smooth.spline(y ~ x), x=x)$y
}
# calculate and plot the mean 
mean_spline7163 <- apply(fv_spline7163,1,mean)
mean_spline50 <- apply(fv_spline50,1,mean)
mean_spline25 <- apply(fv_spline25,1,mean)
mean_spline_df <- apply(fv_spline_df,1,mean)

df_meanplotspline <- data.frame(x = x, True = y_true,spar7163 = mean_spline7163,
                               spar50 = mean_spline50,spar25 = mean_spline25,
                               spardf = mean_spline_df)
ggplot() +
  geom_point(aes(x = x, y = y_true), color = "black", size = 1.5, alpha = 0.6) +
  geom_line(data = df_meanplotspline , aes(x = x, y = spar7163, color = "spar7163"), size = 0.5) +
  geom_line(data = df_meanplotspline, aes(x = x, y = spar50, color = "spar50"), size = 0.5) +
  geom_line(data = df_meanplotspline, aes(x = x, y = spar25, color = "spar25"), size = 0.5) +
  geom_line(data = df_meanplotspline, aes(x = x, y = spardf, color = "spardf"), size = 0.5) +
  labs(title = "Monte Carlo Fitted Mean Spline Smoothing Curve",x = "x", y = "y", color ="spar value") +
  scale_color_discrete(labels = c("spar7163" = "spar = 0.7163", "spar50" = "spar = 0.50",
                                  "spar25" = "spar = 0.25", "spardf" = "spar = default"))+
  theme_minimal(base_size = 14)
# calculate and plot the bias 
bias_spline7163<-mean_spline7163-y_true
bias_spline50<-mean_spline50-y_true
bias_spline25<-mean_spline25-y_true
bias_spline_df<-mean_spline_df-y_true

df_biasplotSPLINE <- data.frame(x = x,spar7163 = bias_spline7163,spar50 = bias_spline50,
                               spar25 = bias_spline25,spardf = bias_spline_df)

df_biasplotSPLINE  %>% ggplot() +
  geom_line(aes(x = x, y = spar7163, color = "spar7163"), size = 0.5) +
  geom_line(aes(x = x, y = spar50, color = "spar50"), size = 0.5) +
  geom_line(aes(x = x, y = spar25, color = "spar25"), size = 0.5) +
  geom_line(aes(x = x, y = spardf, color = "spardf"), size = 0.5) +
  labs(title = "Bias of 4 Spline Smoothing by Monte Carlo CV",x = "x", y = "Bias", color ="spar value") +
  scale_color_discrete(labels = c("spar7163" = "spar = 0.7163", "spar50" = "spar = 0.50",
                                  "spar25" = "spar = 0.25", "spardf" = "spar = default"))+
  theme_minimal(base_size = 14)
# calculate and plot the Var
var_spline7163<-rowMeans((fv_spline7163 - rowMeans(fv_spline7163))^2)
var_spline50<-rowMeans((fv_spline50 - rowMeans(fv_spline50))^2)
var_spline25<-rowMeans((fv_spline25 - rowMeans(fv_spline25))^2)
var_spline_df<-rowMeans((fv_spline_df - rowMeans(fv_spline_df))^2)

df_varplotSPLINE <- data.frame(x = x, spar7163=var_spline7163,spar50 = var_spline50,
                              spar25 = var_spline25,spardf = var_spline_df)
df_varplotSPLINE %>% ggplot() +
  geom_line(aes(x = x, y = spar7163, color = "spar7163"), size = 0.5) +
  geom_line(aes(x = x, y = spar50, color = "spar50"), size = 0.5) +
  geom_line(aes(x = x, y = spar25, color = "spar25"), size = 0.5) +
  geom_line(aes(x = x, y = spardf, color = "spardf"), size = 0.5) +
  labs(title = "Variance of 4 Spline Smoothing by Monte Carlo CV",x = "x", y = "Variance", color ="spar value") +
  scale_color_discrete(labels = c("spar7163" = "spar = 0.7163", "spar50" = "spar = 0.50",
                                  "spar25" = "spar = 0.25", "spardf" = "spar = default"))+
  theme_minimal(base_size = 14)

# calculate and plot the MSE
mse_spline7163<-rowMeans((fv_spline7163 - y_true)^2)
mse_spline50<-rowMeans((fv_spline50 - y_true)^2)
mse_spline25<-rowMeans((fv_spline25 - y_true)^2)
mse_spline_df<-rowMeans((fv_spline_df - y_true)^2)

df_mseplotSPLINE <- data.frame(x = x,spar7163=mse_spline7163,spar50=mse_spline50,
                              spar25=mse_spline25,spardf=mse_spline_df)
df_mseplotSPLINE %>% ggplot() +
  geom_line(aes(x = x, y = spar7163, color = "spar7163"), size = 0.5) +
  geom_line(aes(x = x, y = spar50, color = "spar50"), size = 0.5) +
  geom_line(aes(x = x, y = spar25, color = "spar25"), size = 0.5) +
  geom_line(aes(x = x, y = spardf, color = "spardf"), size = 0.5) +
  labs(title = "MSE of 4 Spline Smoothing by Monte Carlo CV",x = "x", y = "MSE", color ="spar value") +
  scale_color_discrete(labels = c("spar7163" = "spar = 0.7163", "spar50" = "spar = 0.50",
                                  "spar25" = "spar = 0.25", "spardf" = "spar = default"))+
  theme_minimal(base_size = 14)





