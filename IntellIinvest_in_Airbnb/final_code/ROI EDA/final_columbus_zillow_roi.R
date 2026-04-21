## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for columbus & October 2022
zillow_columbus <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "Columbus" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "OH") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_columbus)
#write.csv(zillow, "zillow_columbus.csv")

## merging Zillow data with Airbnb data ##
columbus_merged <- read_csv("columbus_merge.csv")
head(columbus_merged)
columbus_merged$house_price <- zillow_columbus$Price
unique(columbus_merged$property_type)
#colnames(columbus_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
columbus_full_homes <- columbus_merged %>% subset(.,columbus_merged$property_type == "Entire condominium (condo)" |
                                                columbus_merged$property_type == "Entire townhouse"  |
                                                columbus_merged$property_type == "Entire cottage" |
                                                columbus_merged$property_type == "Entire serviced apartment" |
                                                columbus_merged$property_type == "Entire place"  |
                                                columbus_merged$property_type == "Entire loft"   |
                                                columbus_merged$property_type == "Entire rental unit"   |
                                                columbus_merged$property_type == "Entire residential home"|
                                                columbus_merged$property_type == "Tiny house"   |
                                                columbus_merged$property_type == "Entire villa" |
                                                  columbus_merged$property_type == "Entire home/apt") %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(columbus_full_homes, "columbus_zillow_roi.csv")
head(columbus_full_homes)
##histogram all data
par(mfrow=c(2,2))
hist(columbus_full_homes$ROI,main="ROI% - Columbus Houses-Oct 21",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(columbus_full_homes[columbus_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(columbus_full_homes[columbus_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(columbus_full_homes[columbus_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))
boxplot(columbus_full_homes[columbus_full_homes$ROI<= 500,]$ROI, main="Outliers Columbus- ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(columbus_full_homes, nbreaks = 8)+ ggplot2::labs(title = "Columbus ROI Corr")
