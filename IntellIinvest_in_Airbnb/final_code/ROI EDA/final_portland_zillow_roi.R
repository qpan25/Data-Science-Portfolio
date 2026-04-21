## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for portland & October 2022
zillow_portland <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "Portland" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "OR") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_portland)
#write.csv(zillow, "zillow_portland.csv")

## merging Zillow data with Airbnb data ##
portland_merged <- read_csv("portland_merge.csv")
head(portland_merged)
portland_merged$house_price <- zillow_portland$Price
unique(portland_merged$property_type)
#colnames(portland_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
portland_full_homes <- portland_merged %>% subset(.,portland_merged$property_type == "Entire condominium (condo)" |
                                                portland_merged$property_type == "Entire townhouse"  |
                                                portland_merged$property_type == "Entire cottage" |
                                                portland_merged$property_type == "Entire serviced apartment" |
                                                portland_merged$property_type == "Entire place"  |
                                                portland_merged$property_type == "Entire loft"   |
                                                portland_merged$property_type == "Entire rental unit"   |
                                                portland_merged$property_type == "Entire residential home"|
                                                portland_merged$property_type == "Tiny house"   |
                                                portland_merged$property_type == "Entire villa" |
                                                portland_merged$property_type == "Entire home/apt"|
                                                  portland_merged$property_type == "Entire cabin") %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(portland_full_homes, "portland_zillow_roi.csv")
head(portland_full_homes)
##histogram all data
par(mfrow=c(2,2))
hist(portland_full_homes$ROI,main="ROI% - Portland Houses-Oct 21",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(portland_full_homes[portland_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(portland_full_homes[portland_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(portland_full_homes[portland_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))
boxplot(portland_full_homes[portland_full_homes$ROI<= 500,]$ROI, main="Outliers Portland- ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(portland_full_homes, nbreaks = 8)+ ggplot2::labs(title = "Portland ROI Corr")
