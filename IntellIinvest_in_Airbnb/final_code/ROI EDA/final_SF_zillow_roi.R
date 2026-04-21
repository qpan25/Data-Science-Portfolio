## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for SF & October 2022
zillow_SF <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "San Francisco" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "CA") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_SF)
#write.csv(zillow, "zillow_SF.csv")

## merging Zillow data with Airbnb data ##
SF_merged <- read_csv("sfo_merge.csv")
head(SF_merged)
SF_merged$house_price <- zillow_SF$Price
unique(SF_merged$property_type)
#colnames(SF_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
SF_full_homes <- SF_merged %>% subset(.,SF_merged$property_type == "Entire condominium (condo)" |
                                                SF_merged$property_type == "Entire townhouse"  |
                                                SF_merged$property_type == "Entire cottage" |
                                                SF_merged$property_type == "Entire serviced apartment" |
                                                SF_merged$property_type == "Entire place"  |
                                                SF_merged$property_type == "Entire loft"   |
                                                SF_merged$property_type == "Entire rental unit"   |
                                                SF_merged$property_type == "Entire residential home"|
                                                SF_merged$property_type == "Tiny house"   |
                                                SF_merged$property_type == "Entire villa" |
                                                SF_merged$property_type == "Entire home/apt"|
                                                SF_merged$property_type == "Entire cabin"|
                                                SF_merged$property_type == "Entire bed and breakfast") %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(SF_full_homes, "SF_zillow_roi.csv")
head(SF_full_homes)
##histogram all data
par(mfrow=c(2,2))
hist(SF_full_homes$ROI,main="ROI% - SF Houses-Oct 21",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(SF_full_homes[SF_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(SF_full_homes[SF_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(SF_full_homes[SF_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))
boxplot(SF_full_homes[SF_full_homes$ROI<= 500,]$ROI, main="Outliers SF- ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(SF_full_homes, nbreaks = 8)+ ggplot2::labs(title = "SF ROI Corr")
