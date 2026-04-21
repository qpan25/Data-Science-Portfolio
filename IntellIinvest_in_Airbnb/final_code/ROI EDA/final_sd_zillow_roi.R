## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for SD & October 2022
zillow_SD <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "San Diego" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "CA") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_SD)
#write.csv(zillow, "zillow_SD.csv")

## merging Zillow data with Airbnb data ##
SD_merged <- read_csv("san_diego_merge.csv")
head(SD_merged)
SD_merged$house_price <- zillow_SD$Price
unique(SD_merged$property_type)
#colnames(SD_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
SD_full_homes <- SD_merged %>% subset(.,SD_merged$property_type == "Entire condominium (condo)" |
                                                SD_merged$property_type == "Entire townhouse"  |
                                                SD_merged$property_type == "Entire cottage" |
                                                SD_merged$property_type == "Entire serviced apartment" |
                                                SD_merged$property_type == "Entire place"  |
                                                SD_merged$property_type == "Entire loft"   |
                                                SD_merged$property_type == "Entire rental unit"   |
                                                SD_merged$property_type == "Entire residential home"|
                                                SD_merged$property_type == "Tiny house"   |
                                                SD_merged$property_type == "Entire villa" |
                                                SD_merged$property_type == "Entire home/apt"|
                                                SD_merged$property_type == "Entire cabin"|
                                                SD_merged$property_type == "Entire bed and breakfast") %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(SD_full_homes, "SD_zillow_roi.csv")
head(SD_full_homes)
##histogram all data
par(mfrow=c(2,2))
hist(SD_full_homes$ROI,main="ROI% - SD Houses-Oct 21",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(SD_full_homes[SD_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(SD_full_homes[SD_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(SD_full_homes[SD_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))
boxplot(SD_full_homes[SD_full_homes$ROI<= 500,]$ROI, main="Outliers SD- ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(SD_full_homes, nbreaks = 8)+ ggplot2::labs(title = "SD ROI Corr")
