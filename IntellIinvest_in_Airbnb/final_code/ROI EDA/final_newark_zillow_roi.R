## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for newark & October 2022
zillow_newark <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "Newark" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "NJ") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_newark)
#write.csv(zillow, "zillow_newark.csv")

## merging Zillow data with Airbnb data ##
newark_merged <- read_csv("newark_merge.csv")
head(newark_merged)
newark_merged$house_price <- zillow_newark$Price
unique(newark_merged$property_type)
#colnames(newark_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
newark_full_homes <- newark_merged %>% subset(.,newark_merged$property_type == "Entire condominium (condo)" |
                                                newark_merged$property_type == "Entire townhouse"  |
                                                newark_merged$property_type == "Entire cottage" |
                                                newark_merged$property_type == "Entire serviced apartment" |
                                                newark_merged$property_type == "Entire place"  |
                                                newark_merged$property_type == "Entire loft"   |
                                                newark_merged$property_type == "Entire rental unit"   |
                                                newark_merged$property_type == "Entire residential home"|
                                                newark_merged$property_type == "Tiny house"   |
                                                newark_merged$property_type == "Entire villa" |
                                                  newark_merged$property_type == "Entire home/apt") %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(newark_full_homes, "newark_zillow_roi.csv")
head(newark_full_homes)
##histogram all data
par(mfrow=c(2,2))
hist(newark_full_homes$ROI,main="ROI% - Newark Houses-Oct 21",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(newark_full_homes[newark_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(newark_full_homes[newark_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(newark_full_homes[newark_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))
boxplot(newark_full_homes[newark_full_homes$ROI<= 500,]$ROI, main="Outliers Newark- ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(newark_full_homes, nbreaks = 8)+ ggplot2::labs(title = "newark ROI Corr")
