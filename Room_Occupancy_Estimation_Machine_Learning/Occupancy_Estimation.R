library(ggplot2)
library(dplyr)
library(ggcorrplot)
library(nnet)
library(MASS)
library(e1071)
library(class)
library(randomForest)
library(gbm)

occ <- read.table(file="Occupancy_Estimation.csv", sep=",", header=TRUE)

#EDA 
head(occ)
summary(occ)
dim(occ) #10129*19
#check whether there is any NA value
occ%>%summarise_all(~ sum(is.na(.))) # there is no NA value

ggcorrplot(cor(occ[,3:19]),hc.order = F, type = "lower",lab=TRUE,
           lab_size = 2, colors = c("#6D9EC1", "white", "#E46726"))+
  theme(axis.text.x = element_text(size = 8, angle = 45, hjust = 1),
        axis.text.y = element_text(size = 8))
#多少%是label=0,1,2,3
sum(occ$Room_Occupancy_Count==0)/10129 #81.23%
sum(occ$Room_Occupancy_Count==1)/10129 #4.53%
sum(occ$Room_Occupancy_Count==2)/10129 #7.38%
sum(occ$Room_Occupancy_Count==3)/10129 #6.85%

#density plot for each column
occ%>%pivot_longer(cols=S1_Temp:Room_Occupancy_Count,names_to='Variable',values_to = 'value')%>%
  ggplot(aes(x=value,group=Variable,fill=Variable))+
  geom_density(alpha=0.4)+
  facet_wrap(~Variable,scales='free')

#box plot for each column,可以看出需要标准化
occ%>%pivot_longer(cols=S1_Temp:Room_Occupancy_Count,names_to='Variable',
                   values_to = 'value')%>%
  ggplot(aes(x=value,group=Variable,fill=Variable))+
  geom_boxplot(alpha=0.4)+
  facet_wrap(~Variable,scales='free')+coord_flip()
  
#随时间变化，房间内的人数变化
Index <- 1:nrow(occ)
ggplot(occ, aes(x = Index, y = Room_Occupancy_Count)) +
  geom_line(color = "red") +
  labs(title = "Room Occupancy (by row index)",
       x = "Index",
       y = "Occupancy Count") +
  theme_minimal()
#直接标准化,不要Date, Time, S6_PIR,S7_PIR是binary，Room_Occupancy_Count也不标准化
unique(occ$S6_PIR)
unique(occ$S7_PIR)

occ<-occ[,-c(1, 2)]#不要Date, Time
occ[, 1:14] <- scale(occ[,1:14])
occ$Room_Occupancy_Count <- as.factor(occ$Room_Occupancy_Count)
head(occ)
dim(occ) #10129*17

#拆分80%train=occ1, 20%test=occ_test
set.seed(1234)
flag <- sort(sample(1:10129, round(0.2 * 10129) ))

occ_train <- occ[-flag,] #这个是training set
dim(occ_train) # 8103*17

occ_test <- occ[flag,] #这个是test set
dim(occ_test) # 2026*17

#只fit on training and test on test set for following models:

# Method 1: LDA
mod_lda <- lda(Room_Occupancy_Count ~ ., data = occ_train)
pred1test <- predict(mod_lda,newdata = occ_test[,1:16])$class
TE_lda <- mean(pred1test != occ_test[,17]) 
TE_lda #0.01530109

# Method 2: QDA
mod_qda <- qda(Room_Occupancy_Count ~ ., data = occ_train)
pred2test <- predict(mod_qda,newdata = occ_test[,1:16])$class
TE_qda <- mean(pred2test != occ_test[,17])
TE_qda #0.01085884

# Method 3: Naive Bayes
mod_NB <- naiveBayes(Room_Occupancy_Count ~ ., data = occ_train)
pred3test <- predict(mod_NB, newdata = occ_test[,1:16])
TE_NB <- mean(pred3test != occ_test[,17])
TE_NB #0.03010859

#logistic regression
mod_logi <- multinom(Room_Occupancy_Count ~ ., data = occ_train)
pred4test <- predict(mod_logi,newdata = occ_test[,1:16])
TE_logi <- mean(pred4test != occ_test[,17])
TE_logi #0.005923001

#random forest 
# 使用OOB error 来找到最优Random Forest参数
# #默认500 tree, mtry=sqart(16)=4 个variable
# Parameter grids
ntree_grid <- c(400, 500, 600)
nodesize_grid <- c(1, 2, 3)
mtry_grid <- c(1, 2, 3, 4, 5)

grid <- expand.grid(ntree = ntree_grid,
                    nodesize = nodesize_grid,
                    mtry = mtry_grid) #一共5*3*3种组合
results <- data.frame(ntree = integer(),
                      nodesize = integer(),
                      mtry = integer(),
                      OOB_error = numeric())
set.seed(7406)
# 遍历每组参数
for(i in 1:nrow(grid)){
  rf_fit <- randomForest(Room_Occupancy_Count ~ ., 
                         data = occ_train,
                         ntree = grid$ntree[i],
                         mtry = grid$mtry[i],
                         nodesize = grid$nodesize[i])
  
  # 最终森林的 OOB error
  OOB_err <- rf_fit$err.rate[nrow(rf_fit$err.rate), "OOB"]
  
  results <- rbind(results,
                   data.frame(ntree = grid$ntree[i],
                              nodesize = grid$nodesize[i],
                              mtry = grid$mtry[i],
                              OOB_error = OOB_err))
}
# 排序，取 OOB error 最小的 Top 3
top3 <- results[order(results$OOB_error), ][1:3, ]
print(top3)
#最优的组合就是ntree=400,nodesize=1,mtry=2,OOB_error=0.001604344
# tie with : ntree=400,nodesize=3,mtry=2

write.csv(
  x = results,              # 要输出的 data frame
  file = "results_rf.csv",       # 文件名（包括路径），文件会保存在当前工作目录下
  row.names = FALSE               # 阻止 R 将 data frame 的行号（第一列）输出到文件中
)


#单独测试random forest, 使用最优参数：
set.seed(7406)
rf_fit <- randomForest(Room_Occupancy_Count ~ ., 
                       data = occ_train, 
                       ntree = 400,
                       nodesize = 1,
                       mtry = 2,
                       importance = TRUE)


rf_fit
plot(rf_fit)
importance(rf_fit)
varImpPlot(rf_fit) #画图，哪个variable重要
rf.pred <- predict(rf_fit, occ_test, type='class')
table(rf.pred, occ_test[,17])    #confusion matrix
TE_rf <- mean(rf.pred != occ_test[,17])
TE_rf #0.003948667

#GBM booosting, 使用自带的cv
shrinkage_grid <- c(0.01, 0.05, 0.1)
interaction_depth_grid <- c(1, 2, 3)
boosting_results <- data.frame()

set.seed(7406)
for (shrink in shrinkage_grid) {
  for (depth in interaction_depth_grid) {
    gbm_fit <- gbm(Room_Occupancy_Count ~ .,
                  data = occ_train,
                  distribution = "multinomial",
                  n.trees = 5000,
                  shrinkage = shrink,
                  interaction.depth = depth,
                  cv.folds = 10,
                  verbose = FALSE)
    best_iter <- gbm.perf(gbm_fit,method = "cv",plot.it = FALSE) 
    cv_error <- min(gbm_fit$cv.error)
    
    boosting_results<- rbind(boosting_results, data.frame(
      Shrinkage = shrink,
      Depth = depth,
      Best_Trees = best_iter,
      CV_Error = cv_error))
    
  }
}

boosting_results
#最优参数：shrinkage=0.01,depth=2,Best_Trees=3211,CV_Error=0.01171295
#根据最优参数fit最优boosting model：
set.seed(7406)
gbm_bestfit <- gbm(Room_Occupancy_Count ~ .,
               data = occ_train,
               distribution = "multinomial",
               n.trees = 3211,
               shrinkage = 0.01,
               interaction.depth = 2,
               cv.folds = 0,
               verbose = FALSE)
gbm.perf(gbm_bestfit) #画图,这个是OOB error,不要include，使用3211！

summary(gbm_bestfit) #会出画图的
pred_probs <- predict(gbm_bestfit, occ_test, n.trees = 3211, type = "response")
pred_probs
pred_class <- apply(pred_probs, 1, which.max) - 1 #因为class=0~3
table(pred_class, occ_test[,17])    #confusion matrix
TE_boosting <- mean(pred_class != occ_test[,17])
TE_boosting #0.0029615


# Monte Carlo Cross Validation with fold=60 for KNN
B <- 60
n <- nrow(occ_train)
n1=round(0.2 * n) #n1 是test size=20%
TE_all<-c()

set.seed(7406)
for (b in 1:B){
  flag <- sort(sample(1:n, n1))
  train <- occ_train[-flag,]
  test <- occ_train[flag,]
  error_temp<-c()

  #KNN
  kk <- c(1,3,5,7,9)
  for (i in kk){
    pred5test <- knn(train[,1:16],test[,1:16],train[,17],k=i)
    TE_knn <- mean(pred5test != test[,17])
    error_temp<-cbind(error_temp, TE_knn)
  }
  
  TE_all<-rbind(TE_all,error_temp)
}
dim(TE_all)

apply(TE_all, 2, mean)
apply(TE_all, 2, var)
#best is k=3:      TE_knn      TE_knn      TE_knn      TE_knn      TE_knn 
#               0.006580300 0.006025087 0.006251285 0.007022414 0.007330866 
#final testing error of KNN with k=3
pred_knn_test <- knn(occ_train[,1:16],occ_test[,1:16],occ_train[,17],k=3)
TE_knn <- mean(pred_knn_test != occ_test[,17])
TE_knn #0.004442251




#----------PCA-----------
#Columns 1–14: already standardized, binary 列不要standard,所以“scale.=FALSE”
#PCA only on the training data, then rotate and shrink the test dataset
occpca <- prcomp(occ_train[,1:16],scale.=FALSE) 
occpca$sdev
plot(occpca$sdev,type="l", ylab="SD of PC", xlab="PC number",col="blue")
abline(v=5,col='red',lty=2)
abline(v=9,col='red',lty=2)
abline(v=11,col='red',lty=2)
abline(v=15,col='red',lty=2)
text(5,2.3,"PC = 5", col="blue", cex=1, pos=4)
text(6.5,1,"PC = 9", col="blue", cex=1, pos=4)
text(11,1.5,"PC = 11", col="blue", cex=1, pos=4)
text(12.2,0.5,"PC = 15", col="blue", cex=1, pos=4)


results <- data.frame(Model = character(),
                      PC_Num = integer(),
                      Test_Error = numeric(),
                      stringsAsFactors = FALSE)
B <- 60
set.seed(7406)
for(pc in c(5,9,11,15)){
  train_pca <- data.frame(occpca$x[, 1:pc],
                        Room_Occupancy_Count = occ_train$Room_Occupancy_Count)
  test_pca  <- data.frame(predict(occpca, newdata = occ_test[, 1:16])[, 1:pc],
                          Room_Occupancy_Count = occ_test$Room_Occupancy_Count)

  # LDA
  mod_lda <- lda(Room_Occupancy_Count ~ ., data = train_pca)
  pred_lda <- predict(mod_lda, newdata = test_pca)$class
  TE_lda <- mean(pred_lda != test_pca$Room_Occupancy_Count)
  results <- rbind(results, data.frame(Model="LDA", PC_Num=pc, Test_Error=TE_lda))
  # QDA
  mod_qda <- qda(Room_Occupancy_Count ~ ., data = train_pca)
  pred_qda <- predict(mod_qda, newdata = test_pca)$class
  TE_qda <- mean(pred_qda != test_pca$Room_Occupancy_Count)
  results <- rbind(results, data.frame(Model="QDA", PC_Num=pc, Test_Error=TE_qda))
  # Naive Bayes 
  mod_nb <- naiveBayes(Room_Occupancy_Count ~ ., data = train_pca)
  pred_nb <- predict(mod_nb, newdata = test_pca)
  TE_nb <- mean(pred_nb != test_pca$Room_Occupancy_Count)
  results <- rbind(results, data.frame(Model="NaiveBayes", PC_Num=pc, Test_Error=TE_nb))
  # Logistic Regression 
  mod_log <- multinom(Room_Occupancy_Count ~ ., data = train_pca, trace=FALSE)
  pred_log <- predict(mod_log, newdata = test_pca)
  TE_log <- mean(pred_log != test_pca$Room_Occupancy_Count)
  results <- rbind(results, data.frame(Model="Logistic", PC_Num=pc, Test_Error=TE_log))
  
  # --- Monte Carlo CV for KNN ---
  n <- nrow(train_pca)
  n1 <- round(0.2 * n)
  kk <- c(1,3,5,7,9)
  TE_all <- matrix(NA, nrow = B, ncol = length(kk))
  for (b in 1:B){
    flag <- sort(sample(1:n, n1))
    train_cv <- train_pca[-flag, ]
    val_cv   <- train_pca[flag, ]
    for (i in 1:length(kk)) {
      pred_knn <- knn(train_cv[, 1:pc], val_cv[, 1:pc], train_cv$Room_Occupancy_Count, k = kk[i])
      TE_all[b, i] <- mean(pred_knn != val_cv$Room_Occupancy_Count)
    }
  }
  TE_mean <- colMeans(TE_all)
  k_best <- kk[which.min(TE_mean)]
  cat('Best k =',k_best,'for PC =', pc, 'with mean validation error =',min(TE_mean),"\n")
  
  # test set evaluation for best k
  pred_knn_test <- knn(train_pca[, 1:pc], test_pca[, 1:pc], train_pca$Room_Occupancy_Count, k = k_best)
  TE_knn <- mean(pred_knn_test != test_pca$Room_Occupancy_Count)
  model_name <- paste0("KNN with best k=", k_best, " for PC=", pc)
  results <- rbind(results, data.frame(Model=model_name, PC_Num=pc, Test_Error=TE_knn))
  
}

results 



