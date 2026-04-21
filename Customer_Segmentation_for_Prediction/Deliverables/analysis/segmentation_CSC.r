# Purpose: Visualization & statistical tests for 2nd target
# Author: Qi Pan

library(ggplot2)
library(dplyr)
library(tidyverse)
library(ppsr)     # To calculate Predictive Power Score (PPS)
library(ggcorrplot) # For visualization
library(caret)    
library(cluster)
library(forcats)
library(randomForest)
library(lightgbm)
library(e1071)
library(stats)
library(glmnet)
library(mgcv)

# Load in data
df<-read.csv("final_target_CSC_giga.csv",header=TRUE)
str(df)
# Remove irrelevant columns; If doing other target, remove the 1st target. 
ACCOUNT_ID <- df$ACCOUNT_ID 

df <- df %>% select(-c(X, ACCOUNT_ID))  # ACCOUNT_ID will be added back for Shiny UI.
str(df)

df <- df %>% 
  mutate(across(where(is.character), as.factor)) %>%
  mutate(ACCOUNT_SUCCESS_LEADER = factor(ACCOUNT_SUCCESS_LEADER)) %>%
  mutate(COMPETITOR_AS_PRIMARY_VENDOR = factor(COMPETITOR_AS_PRIMARY_VENDOR))

# Replace spaces or special characters in factor levels. 
df$BUSINESS_TYPE_PRIMARY <- factor(gsub("[^A-Za-z0-9]", "_", df$BUSINESS_TYPE_PRIMARY))
df$REGION <- factor(gsub("[^A-Za-z0-9]", "_", df$REGION))

# Merge parts of BUSINESS_TYPE_PRIMARY, REGION levels
#sort(prop.table(table(df$REGION)),decreasing=TRUE)  # check levels, keep n=10
#sort(prop.table(table(df$BUSINESS_TYPE_PRIMARY)),decreasing=TRUE)  # keep n=8
df <- df %>% mutate(
    REGION = fct_lump_n(REGION, n=10, other_level="Other"), # keep top 10
    BUSINESS_TYPE_PRIMARY = fct_lump_n(BUSINESS_TYPE_PRIMARY, n=8, other_level="Other") # keep top 8
)

str(df)
df %>% summarise_all(~sum(is.na(.))) 

# Calculate the correlation matrix for numerical variables
num_df <- df %>% select(where(is.numeric))
ggcorrplot(cor(num_df),hc.order=F, type="lower",lab=TRUE,lab_size=2, colors=c("#6D9EC1","white","#E46726"))+
theme(axis.text.x = element_text(size=8,angle=45,hjust=1),
    axis.text.y = element_text(size=8))
#Save the image, automatically detecting the most recently generated plot
ggsave(
  filename = "correlation_heatmap_CSC_giga.png",
  width = 8,
  height = 8,
  dpi = 900
)
#Plot the PPS feature correlation matrix
ppsr::visualize_pps(df=df,cv_folds=10, seed=1234,color_text = "transparent")+
    geom_text(aes(label = sprintf("%.2f", pps)), size = 2, color = "grey") +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, vjust = 1),
    axis.text.y = element_text(size = 8)  # change as needed
  )

#Save the image, automatically detecting the most recently generated plot
ggsave(
  filename = "pps_tree_heatmap_CSC_giga.png",
  width = 8,
  height = 8,
  dpi = 900
)

#feature selection
rank_features <- function(df, response) {

  # Prepare formula and target
  formula <- as.formula(paste(response, "~."))
  y <- df[[response]]
  
  # Predictive Power Score:
  # Captures non-linear and asymmetric predictive relationships.
  pps_df <- ppsr::score_predictors(df, y=response)
  pps_imp_df <- data.frame(Feature=pps_df$x, PPS=pps_df$pps)
  
  # Random Forest:
  # Captures non-linear relationships and interactions.
  set.seed(1234)
  rf <- randomForest(formula, df, importance=TRUE)
  rf_imp <- importance(rf, type=1)
  rf_imp_df <- data.frame(Feature=rownames(rf_imp), RF=rf_imp[,1])

  # LightGBM:
  # Captures non-linear patterns, interactions and boosted relationships. 
  set.seed(1234)
  x <- model.matrix(formula,df)[,-1]
  lgb <- lightgbm(data=x, label=y, nrounds=200, verbose=-1)
  lgb_imp <- lgb.importance(lgb)
  lgb_imp_df <- data.frame(Feature=lgb_imp$Feature, LGB=lgb_imp$Gain)
  
  # Elastic Net:
  # Captures linear relationships and collinearity structure. 
  set.seed(1234)
  enet <- cv.glmnet(x,y,alpha=0.5,standardize=TRUE)
  coef_enet <- coef(enet, s="lambda.min")
  enet_imp_df <- data.frame(Feature=rownames(coef_enet), ENet=as.numeric(abs(coef_enet[,1])))
  enet_imp_df <- enet_imp_df[enet_imp_df$Feature != "(Intercept)",, drop=FALSE]
  if (nrow(enet_imp_df)==0) {
    enet_imp_df <- data.frame(Feature=colnames(x), ENet=0)
  }
  
  
  # Merge all importance measures.
  importance <- merge(pps_imp_df, rf_imp_df, by="Feature", all=TRUE)
  importance <- merge(importance, lgb_imp_df, by="Feature", all=TRUE)
  importance <- merge(importance, enet_imp_df, by="Feature", all=TRUE)
  # Replace NAs with 0.
  importance[is.na(importance)] <- 0
  
  # Consensus Ranking: convert each method to rank then average.
  importance$Total <- rowMeans(cbind(rank(-importance$PPS, ties.method="average"),
                                     rank(-importance$RF, ties.method="average"),
                                     rank(-importance$LGB, ties.method="average"),
                                     rank(-importance$ENet, ties.method="average")))
  # Sort by Consensus Ranking (smallest rank = top feature).
  importance <- importance[order(importance$Total),]
  # Remove response if accidentally included (safety check)
  importance <- importance[importance$Feature != response, ]
  
  # If feature is dummy, change back to original feature. 
  importance <- importance %>%
    mutate(across(everything(), ~ ifelse(str_starts(., fixed("REGION")), "REGION", .))) %>%
    mutate(across(everything(), ~ ifelse(str_starts(., fixed("SERVICE_TIER")), "SERVICE_TIER", .)))
  
  return(importance)
}

# Rank features for full dataset. 
importance_df <- rank_features(df, response="growth_rate_CSC")
top10 <- importance_df[1:10, c("Feature")]
top10 

# clustering
clustering_func <- function(df, top10, k_grid=2:10, topN_max=10) {
  stopifnot(is.data.frame(df))
  stopifnot(is.numeric(k_grid) && all(k_grid >= 2))

  set.seed(1234)

  # Clean top feature list
  top_features <- top10[!is.na(top10)]
  if (length(top_features) < 2) {
    stop("Need at least 2 non-NA features.")
  }

  topN_max <- min(topN_max, length(top_features), 10)
  topN_grid <- 2:topN_max

  # Initialize ASW results (rows = k, cols = topN)
  ASW_rank <- matrix(NA_real_, nrow = length(k_grid), ncol = length(topN_grid))
  rownames(ASW_rank) <- paste0("k=", k_grid)
  colnames(ASW_rank) <- paste0("top", topN_grid)

  # Map k to row index
  k_row_index <- setNames(seq_along(k_grid), as.character(k_grid))

  # Loop through topN and k
  for (j in seq_along(topN_grid)) {
    topN <- topN_grid[j]
    selected_features <- top_features[seq_len(topN)]

    df_sub <- df %>% dplyr::select(dplyr::all_of(selected_features))
    gower_dist <- cluster::daisy(df_sub, metric = "gower")

    for (k in k_grid) {
      pam_result <- cluster::pam(gower_dist, diss = TRUE, k = k)
      ASW_rank[k_row_index[as.character(k)], j] <- pam_result$silinfo$avg.width
    }
  }

  # Identify best (k, topN)
  best_idx <- arrayInd(which.max(ASW_rank), dim(ASW_rank))
  best_k   <- k_grid[best_idx[1]]
  best_topN <- topN_grid[best_idx[2]]
  best_features <- top_features[seq_len(best_topN)]

  # Final PAM
  df_best <- df %>% dplyr::select(dplyr::all_of(best_features))
  gower_best <- cluster::daisy(df_best, metric = "gower")
  final_pam <- cluster::pam(gower_best, diss = TRUE, k = best_k)

  medoids <- df_best[final_pam$medoids, , drop = FALSE]

  df_final <- df %>% dplyr::mutate(Cluster = as.factor(final_pam$clustering))

  # Print only the info you care about
  cat("Best number of clusters:", best_k, "\n")
  cat("Best top features:", paste(best_features, collapse = ", "), "\n\n")

  # Return ONLY essential outputs
  list(
    final_pam        = final_pam,
    df_final         = df_final,
    cluster_features = best_features,
    medoid_profiles  = medoids, 
    ASW_rank         = ASW_rank   # keep for diagnostics
  )
}

ASW <- clustering_func(df,top10=top10) #best K=2, TOP 5 FEATURES="Log_Community_Cnt", "PENETRATION_RATE_CSC"
ASW$ASW_rank

# Plot ASW versus K 
df_for_clustering <- df %>% select(all_of(c( "PENETRATION_RATE_CSC", "N_UNIQUE_ZIP_log",
    "Log_Community_Cnt", "GATEWAY_30_DAYS_COUNT_log")))
gower_dist <- daisy(df_for_clustering, metric = "gower")

sil_values <- c()
for(k in 2:10) {
  pam_result <- pam(gower_dist, diss = TRUE, k = k)
  sil_values[k] <- pam_result$silinfo$avg.width # Save avg silhouette value，bigger is better
}
sil_values #Improved！max=0.4633098

# Plot the silhouette coefficient chart
sil_tb <- data.frame(k=2:10,avg_silhouette = sil_values[2:10])# The first value is NA, corresponding to K = 1

ggplot(sil_tb, aes(x = k, y = avg_silhouette)) +
  geom_line(color = "#2E86C1", linewidth = 0.8) +
  geom_point(color = "#2E86C1", size = 2) +
  scale_x_continuous(breaks = 2:10) +
  labs(
    title = "Choosing the Number of Clusters (PAM with Gower)",
    subtitle = "Average silhouette width across K",
    x = "Number of clusters (K)",
    y = "Average silhouette width"
  ) +
  theme_minimal(base_size = 12)

#Save the image, automatically detecting the most recently generated plot
ggsave(
  filename = "best_k_GOWER_PAM_CSC_giga(4feature).png",
  width = 8,
  height = 8,
  dpi = 600
)

# PAM clustering with best_k, best_top_features

final_pam <- pam(gower_dist, diss = TRUE, k = 2)
# compute silhouette
sil <- silhouette(final_pam$clustering, gower_dist)

# plot silhouette 
library(factoextra)
p4 <- fviz_silhouette(
  sil,
  label   = FALSE,          # Do not label values on each bar to avoid clutter
  palette = "Set3"          # change as needed
) +
  labs(
    title = sprintf("Silhouette plot (PAM, Gower) — K = %d", 2),
    x     = "Silhouette width",
    y     = "Clusters"
  ) +
  theme_minimal(base_size = 12)

# Save
ggsave(
  filename = "Silhouette_plot_CSC_giga.png",
  plot     = p4,
  width    = 8,
  height   = 8,
  dpi      = 600
)

#Test cluster stability,bootstrap
library(fpc)
set.seed(1234)
cb <- clusterboot(as.matrix(gower_dist),B=100, diss = TRUE,clustermethod=pamkCBI, 
    usepam = TRUE, k=2, bootmethod = "boot",)

#Per-cluster Jaccard index (stability core): 
#>0.85: very stable; 0.75–0.85: stable; 0.6–0.75: moderate; <0.6: unstable
cb$bootmean #0.9745863 0.9523297
cb$bootbrd  # 100，100，Across all resampling runs, both clusters remained intact

# check medoids
final_pam$medoids #36,30 for only csc, 785,122 for csc+giga
df[785,] #group 1's center
df[122,] #group 2's center
#add new Cluster column
df_final <- df %>%
   mutate(Cluster = as.factor(final_pam$clustering))

unique(final_pam$clustering) #only 1 & 2
dim(df_final)
sum(final_pam$clustering==1)/1112 # 0.6648649 percentage of Cluster 1
sum(final_pam$clustering==2)/1112 # 0.3351351 percentage of Cluster 2

#Test the difference in means between two groups for continuous data
cluster_description <- df_final %>% group_by(Cluster) %>% summarise(mean_growth_rate_CSC=mean(growth_rate_CSC),
    mean_Log_Community_Cnt=mean(Log_Community_Cnt),
    mean_PENETRATION_RATE_CSC=mean(PENETRATION_RATE_CSC),
    mean_customer_age=mean(customer_age),
    mean_GIGA_PURCHASED_AMOUNT_log=mean(GIGA_PURCHASED_AMOUNT_log),
    mean_Log_Virtual_Cnt=mean(Log_Virtual_Cnt),
    mean_OF_ACTIVE_CONTACTS=mean(OF_ACTIVE_CONTACTS),
    mean_CUSTOMER_JOURNEY_WEIGHTED_SCORE=mean(CUSTOMER_JOURNEY_WEIGHTED_SCORE)
    )
print(cluster_description[,c(4,5,6)])

#Test differences in proportions between two groups for categorical variables
#REGION, BUSINESS_TYPE_PRIMARY,
cat1 <- df_final %>% group_by(Cluster,BUSINESS_TYPE_PRIMARY) %>% summarise(n=n(), .groups="drop") %>%
    group_by(Cluster) %>% mutate(prop=n/sum(n)) %>% arrange(Cluster,desc(prop))
cat1[8:13,]

# t test: evaluate whether clusters differ significantly on key numerical variables 
t.test(growth_rate_CSC ~ Cluster, df_final) # p-value = 0.02045
t.test(Log_Community_Cnt~ Cluster, df_final) # p-value < 2.2e-16
t.test(PENETRATION_RATE_CSC~ Cluster, df_final) # p-value < 2.2e-16
t.test(GIGA_PURCHASED_AMOUNT_log~ Cluster, df_final) # p-value < 2.2e-16
t.test(customer_age~ Cluster, df_final) # p-value < 2.2e-16
t.test(Log_Virtual_Cnt~ Cluster, df_final) # p-value < 2.2e-16
t.test(OF_ACTIVE_CONTACTS~ Cluster, df_final) # p-value = 3.911e-11
t.test(CUSTOMER_JOURNEY_WEIGHTED_SCORE~ Cluster, df_final) #  1.296e-10

# Chi‑square test for categorical data
chisq.test(table(df_final$Cluster,df_final$REGION)) # p-value = 5.08e-09
chisq.test(table(df_final$Cluster,df_final$BUSINESS_TYPE_PRIMARY))#  p-value < 2.2e-16
chisq.test(table(df_final$Cluster,df_final$ACCOUNT_SUCCESS_LEADER))# p-value = 4.501e-14
chisq.test(table(df_final$Cluster,df_final$COMPETITOR_AS_PRIMARY_VENDOR))# p-value = 0.01579
chisq.test(table(df_final$Cluster,df_final$TIER_LEVEL))# p-value = 0.00635
chisq.test(table(df_final$Cluster,df_final$SERVICE_TIER))# p-value < 2.2e-16

str(df_final)
df_final$ACCOUNT_ID <- ACCOUNT_ID
str(df_final)
write.csv(df_final,file="df_cluster_CSC_giga.csv",row.names=TRUE)

#merge with account_id column
df1<-read.csv("final_target_CSC.csv",header=TRUE)
# Remove irrelevant columns; If doing other target, remove the 1st target. 
head(df1[,c(1,2,3,4)])
account_id_csc<- df1$ACCOUNT_ID

account_id_csc[c(1,2,3,4)]

df2<-read.csv("df_cluster_CSC.csv",header=TRUE)
df2$ACCOUNT_ID <- account_id_csc
str(df2)
write.csv(df2,file="df_cluster_CSC.csv",row.names=TRUE)
