# Purpose: Data Cleaning & Preparation for 2nd target
# Author: Qi Pan

library(ggplot2)
library(dplyr)
library(readxl)


df <- read.csv(file="account_join_FINAL_without_target.csv",header=TRUE)
df<-df%>% select(-X)
str(df) #1750*21, with ACCOUNT_ID, TOTAL_BROADBAND_SUBS_SALES_INPUT
df %>% summarise_all(~sum(is.na(.))) # many NA in different features


#-----load in 2nd target： growth_rate_CSC.xlsx--------------------
growth_rate_CSC <- read_excel("growth_rate_CSC.xlsx")
growth_rate_CSC <- growth_rate_CSC[,c(1,3,7)] # load in account_id, growth_rate_CSC, & LATEST_CSC(to calculate penetration_rate_CSC)
head(growth_rate_CSC) 
dim(growth_rate_CSC) #1114*3
growth_rate_CSC %>% summarise_all(~sum(is.na(.))) #no NA

#--------join on main table------
final_df_CSC <- growth_rate_CSC %>% inner_join(df, by = c("ACCOUNT_ID"="ACCOUNT_ID"))

dim(final_df_CSC)#1112*23
sum(is.na(final_df_CSC %>% summarise_all(~sum(is.na(.))) )) #no NA
head(final_df_CSC$PENETRATION_RATE)

#---------to calculate new PENETRATION_RATE_CSC
final_df_CSC$PENETRATION_RATE_CSC <- final_df_CSC$LATEST_CSC/final_df_CSC$TOTAL_BROADBAND_SUBS_SALES_INPUT
dim(final_df_CSC) #1112*24
head(final_df_CSC$PENETRATION_RATE_CSC)
sum(is.na(final_df_CSC)) # 88 NA, need manual exam

#--------discard old penetration rate， TOTAL_BROADBAND_SUBS_SALES_INPUT, LATEST_CSC
# final_df_CSC <- final_df_CSC %>%
#   dplyr::select(-TOTAL_BROADBAND_SUBS_SALES_INPUT)

# final_df_CSC <- final_df_CSC %>%
#   dplyr::select(-PENETRATION_RATE)

# final_df_CSC <- final_df_CSC %>%
#   dplyr::select(-LATEST_CSC)

# dim(final_df_CSC) #1112*21
# colnames(final_df_CSC)

write.csv(final_df_CSC,file="final_target_CSC.csv",row.names=TRUE)



try<-read.csv("final_target_CSC.csv",header=TRUE)
try<-try%>% select(-X)
try %>% summarise_all(~sum(is.na(.))) 

dim(try)
# add new giga_30 days as a feature
csc_giga<-read.csv("csc_giga.csv",header=TRUE)
head(csc_giga)
csc_giga %>% summarise_all(~sum(is.na(.))) 
csc_giga <- csc_giga %>% select(-SNAPSHOT_DATE)
head(try)
#join 2 tables
result <- left_join(try, csc_giga, by = "ACCOUNT_ID")
dim(result)
result %>% summarise_all(~sum(is.na(.))) # 4 NA in GATEWAY_30_DAYS_COUNT

result <- result %>%
  mutate(GATEWAY_30_DAYS_COUNT = coalesce(GATEWAY_30_DAYS_COUNT, 0))

result$GATEWAY_30_DAYS_COUNT<- log10(1+result$GATEWAY_30_DAYS_COUNT)

# save plot to check out if log transformation is needed for GATEWAY_30
p_giga_hist <- ggplot(result, aes(x = GATEWAY_30_DAYS_COUNT)) +
  geom_histogram(
    bins = 40, fill = "steelblue", color = "white", alpha = 0.8
  ) +
#   geom_density(
#     aes(y = after_stat(..count..)),  # same scale as histogram
#     color = "firebrick", linewidth = 1
#   ) +
  labs(
    title = "Distribution of Newest GATEWAY_30_DAYS_COUNT(log10 scale)",
    x = "GATEWAY_30_DAYS_COUNT(log10,+1)",
    y = "Frequency"
  ) +
  theme_minimal() +
  theme(plot.title = element_text(hjust = 0.5))

# save plot to check out and make adjustment if needed
ggsave(
  filename = "p_giga_hist_log.png",
  plot = p_giga_hist,
  bg = "white",
  width = 8,
  height = 5
)
str(result)
dim(result) #1112*22, -account id,-target,with 20 predictor
write.csv(result,file="final_target_CSC_giga.csv",row.names=TRUE)




# The full flow of integration for 2nd target is below: 
#   
# In SQL: 
#   
# Use ACCOUNTS table to filter this table’s account_id 
# If from 2025-01-01 to the most recent date, there is no record, no snapshot_date, then delete this account. (Seems there is system bug  start from 2026-1-1, all accounts ‘s CSC is NULL. So only use 2025 data) 
# Try to find for each account, what is their LATEST_CSC, what is their OLD_CSC_3MONTH 
# 
# 
# In Excel(manually input and change): 
#   
# calculate the growth_rate=(new-old)/old  
# TOTAL with 1119 account_id, and 23 customer has “OLD_CSC_3MONTH=NULL “ 
# Need to check one by one 
# Delete “0010g00001Z5LiyAAF” which only has half a month record  
# Delete “0014u000028wZzfAAE” which only has half a month record 
# Delete “0010g00001gM1DYAA0” which only has 8 days in May 2025 
# Delete “0014u000028wmV8AAI” which only has half a month record  
# Delet “0017000000SbVAfAAN” which only has half a month record 
# Left 1114 row 
# if latest_CSC=0, old_CSC=0,  manully changed the latest_CSC=1, old_CSC 1，so the denominator is not 0！ 
# If latest_CSC=5, old_CSC=0,  manully changed the latest_CSC=6, old_CSC 1，so the denominator is not 0！ 
# 
# 
# In R: 
#   
# Merge the main df without target("account_join_FINAL_without_target.csv") with “growth_rate_csc.xlsx” get df: “final_df_CSC” with 1112*24 
# 
# 
# In Excel： 
# 
# There are 88 NA need to remove. Save as a excel file and manually change and check 

