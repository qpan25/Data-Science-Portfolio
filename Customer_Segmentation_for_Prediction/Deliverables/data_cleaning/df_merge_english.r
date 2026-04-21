# Purpose: Data Cleaning & Preparation for 1st target
# Author: Qi Pan

library(ggplot2)
library(dplyr)
library(readxl)
#---------ACCOUNT TABLE--------------
account<-read.csv(file="ACCOUNT.csv",na.strings=c("","NA","NULL"),header=TRUE)
head(account)
dim(account) #1750*14
account %>% summarise_all(~sum(is.na(.))) #16 NA in TOTAL_BROADBAND_SUBS_SALES_INPUT

#-----keep 10 columns------
account_sub <- account %>%
  select(
    ACCOUNT_ID,
    BUSINESS_TYPE_PRIMARY,
    REGION,
    SERVICE_TIER,
    TIER_LEVEL,
    OF_ACTIVE_CONTACTS,
    OF_FUNDED_PROGRAMS,
    TOTAL_BROADBAND_SUBS_SALES_INPUT,
    ACCOUNT_CREATED_AT_DATE,
    ACCOUNT_SUCCESS_LEADER
  )

#-----use "ACCOUNT_CREATED_AT_DATE" to create "customer_age"-----------------
account_sub$ACCOUNT_CREATED_AT_DATE <- as.Date(account_sub$ACCOUNT_CREATED_AT_DATE, format ="%Y-%m-%d")
#to calculate customer_age
today <- Sys.Date()  # today's date
account_sub$customer_age <- as.numeric(difftime(today, account_sub$ACCOUNT_CREATED_AT_DATE, units = "days")) / 365.25
account_sub$customer_age
#remove ACCOUNT_CREATED_AT_DATE
account_sub <- account_sub %>% select(-ACCOUNT_CREATED_AT_DATE)
colnames(account_sub)
account_sub %>% summarise_all(~sum(is.na(.)))

#------ACCOUNT_SUCCESS_LEADER, null=0, someone=1, Boolean value-----
account_sub$ACCOUNT_SUCCESS_LEADER <- as.integer(!is.na(account_sub$ACCOUNT_SUCCESS_LEADER))
head(account_sub)

#------NA VALUE in SERVICE_TIER， TIER_LEVEL， fill in “Unknown”， change to factor-------
account_sub$SERVICE_TIER <- as.factor(account_sub$SERVICE_TIER)
account_sub$TIER_LEVEL <- as.factor(account_sub$TIER_LEVEL)

levels(account_sub$SERVICE_TIER) <- c(levels(account_sub$SERVICE_TIER),"Unknown")
levels(account_sub$TIER_LEVEL) <- c(levels(account_sub$TIER_LEVEL),"Unknown")
account_sub$SERVICE_TIER[is.na(account_sub$SERVICE_TIER)] <- "Unknown"
account_sub$TIER_LEVEL[is.na(account_sub$TIER_LEVEL)] <- "Unknown"
sum(account_sub$TIER_LEVEL=="Unknown") #47, correct!
sum(account_sub$SERVICE_TIER=="Unknown") #421 correct！

#------ deal with NA VALUE in OF_ACTIVE_CONTACTS,  OF_FUNDED_PROGRAMS -----------
account_sub <- account_sub %>% 
mutate(OF_ACTIVE_CONTACTS = if_else(is.na(OF_ACTIVE_CONTACTS),0L,OF_ACTIVE_CONTACTS)) #integer, use "0L"

account_sub <- account_sub %>% 
mutate(OF_FUNDED_PROGRAMS = if_else(is.na(OF_FUNDED_PROGRAMS),0L,OF_FUNDED_PROGRAMS))


head(account_sub)
dim(account_sub)

#----- import B2C_size.csv--------------------
b2c<-read.csv(file="B2C_size.csv",na.strings=c("","NA","NULL"),header=TRUE)
head(b2c)
dim(b2c)
b2c %>% summarise_all(~sum(is.na(.))) #no NA
b2c$N_UNIQUE_ZIP_log <- log10(b2c$N_UNIQUE_ZIP)
median(b2c$N_UNIQUE_ZIP_log)#1.230449
colnames(b2c)


account_sub_join <- account_sub %>% 
left_join(b2c[,c(1,3)],by = c("ACCOUNT_ID"="CALIX_ACCOUNT_ID"))
dim(account_sub_join)#1750*11
account_sub_join %>% summarise_all(~sum(is.na(.))) #901 NA values for N_UNIQUE_ZIP

#fill in median for NA
account_sub_join <- account_sub_join %>%
  mutate(
    N_UNIQUE_ZIP_log = coalesce(N_UNIQUE_ZIP_log, 1.230449)
  )

#-----import bookings.csv--------------------
booking<-read.csv(file="bookings.csv",header=TRUE)
tail(booking) #having negative value for return amount of giga
dim(booking) #924*2
booking %>% summarise_all(~sum(is.na(.))) #no NA, need signed log
#there is negative,0, positive number,need to use "signed log"
booking$GIGA_PURCHASED_AMOUNT_log <- sign(booking$GIGA_PURCHASED_AMOUNT) * log10(1 + abs(booking$GIGA_PURCHASED_AMOUNT))

#join on main table
account_sub_join <- account_sub_join %>% 
left_join(booking[,c(1,3)],by = c("ACCOUNT_ID"="ACCOUNT_ID"))

dim(account_sub_join)#1750*12
head(account_sub_join)
account_sub_join %>% summarise_all(~sum(is.na(.))) #826 NA values for GIGA_PURCHASED_AMOUNT_log
#fill NA with 0
account_sub_join <- account_sub_join %>%
  mutate(
    GIGA_PURCHASED_AMOUNT_log = coalesce(GIGA_PURCHASED_AMOUNT_log, 0)
  )


#-----import competitor.csv--------------------
competitor <- read.csv(file="competitor.csv",header=TRUE)
head(competitor) 
dim(competitor) #1688*3
competitor %>% summarise_all(~sum(is.na(.)))
str(competitor) #COMPETITOR_AS_PRIMARY_VENDOR is char, change to Boolean
unique(competitor$COMPETITOR_AS_PRIMARY_VENDOR) #"false" "true"
table(competitor$COMPETITOR_AS_PRIMARY_VENDOR)
competitor$COMPETITOR_AS_PRIMARY_VENDOR <- ifelse(competitor$COMPETITOR_AS_PRIMARY_VENDOR=="false",0,1)
#join on main table
account_sub_join <- account_sub_join %>% 
left_join(competitor,by = c("ACCOUNT_ID"="ACCOUNT_ID"))
dim(account_sub_join)#1750*14
account_sub_join %>% summarise_all(~sum(is.na(.))) #62 missing values

#-----import engagement.xlsx--------------------
engagement <- read_excel("engagement.xlsx")
head(engagement) 
engagement <- engagement[,c(1,3,4,6)]
dim(engagement) #1750*4
engagement %>% summarise_all(~sum(is.na(.))) #no NA
#join on main table
account_sub_join <- account_sub_join %>% 
left_join(engagement,by = c("ACCOUNT_ID"="ACCOUNT_ID"))
dim(account_sub_join)#1750*17
account_sub_join %>% summarise_all(~sum(is.na(.))) #no new NA

#-----import espalier.csv--------------------
espalier <- read.csv(file="espalier.csv",header=TRUE)
head(espalier) 
dim(espalier) #1275*3
espalier %>% summarise_all(~sum(is.na(.))) #no NA

median(espalier$CUSTOMER_JOURNEY_WEIGHTED_SCORE) #2.7
median(espalier$SERVE_SIZE_BUSINESS) #3

#join on main table
account_sub_join <- account_sub_join %>% 
left_join(espalier,by = c("ACCOUNT_ID"="ACCOUNT_ID"))
dim(account_sub_join)#1750*19
account_sub_join %>% summarise_all(~sum(is.na(.))) #NA=475

#fill median for NA
account_sub_join <- account_sub_join %>%
  mutate(CUSTOMER_JOURNEY_WEIGHTED_SCORE = coalesce(CUSTOMER_JOURNEY_WEIGHTED_SCORE, 2.7))

account_sub_join <- account_sub_join %>%
  mutate(SERVE_SIZE_BUSINESS = coalesce(SERVE_SIZE_BUSINESS, 3L))
head(account_sub_join)

#----- import surveys.csv--------------------
survey <- read.csv(file="surveys.csv",header=TRUE)
head(survey) 
survey <- survey[,c(1,4)]
dim(survey) #831*2
survey %>% summarise_all(~sum(is.na(.))) #no NA

# Is there any repeated ACCOUNT_ID in survey?
survey %>%
  count(ACCOUNT_ID, sort = TRUE) %>%
  filter(n > 1) %>%
  head(20)
# 6 account_id is repeated in surveym, need manually remove

#join on main table
account_sub_join <- account_sub_join %>% 
left_join(survey,by = c("ACCOUNT_ID"="ACCOUNT_ID"))
dim(account_sub_join)#1756*20, 

dup_ids <- c(
  "0017000000SbV53AAF",
  "0017000000SbVEEAA3",
  "0017000000kakKfAAI",
  "0017000000qx3QRAAY",
  "0017000000y28jcAAA",
  "0017000001XQlqvAAD"
)
account_sub_join <- account_sub_join %>%
  mutate(.rowid = row_number())  # create row index , from index 1

head(account_sub_join)

dup_rows <- account_sub_join %>%
  filter(ACCOUNT_ID %in% dup_ids) %>%
  arrange(ACCOUNT_ID, .rowid)

dup_rows[,c(1,20,21)]

account_sub_join[264,]==account_sub_join[265,]

rows_to_drop <- c(264,415,1716,129,330,164)

account_sub_join <- account_sub_join %>%
  filter(!.rowid %in% rows_to_drop) %>%
  select(-.rowid)

dim(account_sub_join) #1750*20

#fill NA with 0="passive"
account_sub_join <- account_sub_join %>%
  mutate(NPS_GROUP_SCORE= coalesce(NPS_GROUP_SCORE, 0))

account_sub_join %>% summarise_all(~sum(is.na(.)))

#------ calculate the penetration rate= newest Gateway_30_days_count/TOTAL_BROADBAND_SUBS_SALES_INPUT
penetration <- read_excel("penetration_rate.xlsx")
head(penetration) 
penetration <- penetration[,c(1,5)]
dim(penetration) #1109*2
penetration %>% summarise_all(~sum(is.na(.))) #no NA
length(unique(penetration$ACCOUNT_ID)) #1109, no repeat ACCOUNT_ID

#join on main table
account_sub_join <- account_sub_join %>% 
left_join(penetration, by = c("ACCOUNT_ID"="ACCOUNT_ID"))
dim(account_sub_join)#1750*21
account_sub_join %>% summarise_all(~sum(is.na(.))) #NA=641 PENETRATION_RATE
head(account_sub_join)

#save the final df：“account_join_FINAL_without_target.csv”
write.csv(account_sub_join,file="account_join_FINAL_without_target.csv",row.names=TRUE)

#-----import target column： growth_rate_calculate_FINAL.csv--------------------
growth_rate <- read.csv(file="growth_rate_calculate_FINAL.csv",header=TRUE)
head(growth_rate) 
growth_rate <- growth_rate[,c(1,4)]
dim(growth_rate) #1110*2
growth_rate %>% summarise_all(~sum(is.na(.))) #no NA

#join on main table
final_df <- growth_rate %>% 
inner_join(account_sub_join, by = c("ACCOUNT_ID"="ACCOUNT_ID"))
dim(final_df)#1110*22
final_df %>% summarise_all(~sum(is.na(.))) 
#NA OF PENETRATION_RATE=13, N_COMPETITORS， COMPETITOR_AS_PRIMARY_VENDOR的NA=30, manually check!
#remove TOTAL_BROADBAND_SUBS_SALES_INPUT
final_df <- final_df %>%
  dplyr::select(-TOTAL_BROADBAND_SUBS_SALES_INPUT)
dim(final_df)#1110*21
head(final_df)

#save final df with target=growth_rate，name it：“final_target.csv”
#manually fill in some NA with excel.
write.csv(final_df,file="final_target.csv",row.names=TRUE)




# The full flow of integration for 1st target is below: 
# Use ACCOUNTS table to filter GS_DEPLOYS_AND_CLOUD_SUBSCRIBERS table, left 1132 unique account_id 
# If from 2025-01-01 to the most recent date, there is no record, no snapshot_date, then delete this account. Since according to Tessa, they might left Calix. Left 1124 unique account_id 
# Try to find for each account, what is their LATEST_GATEWAY_30D, what is their OLD_GATEWAY_3MONTH, calculate the growth_rate=(new-old)/old 
# There are some anomaly accounts, checked 1  by 1 and we left 1110 unique accounts!  
# if latest_gateway=0, old_gateway=0, manually changed the latest_gateway=1, old_gateway= 1，so the denominator is not 0！ 

