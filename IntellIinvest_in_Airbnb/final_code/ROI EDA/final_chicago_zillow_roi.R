## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for chicago & October 2022
zillow_chicago <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "Chicago" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "IL") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_chicago)
#write.csv(zillow, "zillow_chicago.csv")

## merging Zillow data with Airbnb data ##
chicago_merged <- read_csv("chicago_merge.csv")
head(chicago_merged)
chicago_merged$house_price <- zillow_chicago$Price
unique(chicago_merged$property_type)
#colnames(chicago_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
chicago_full_homes <- chicago_merged %>% subset(.,chicago_merged$property_type == "Entire condominium (condo)" |
                                                chicago_merged$property_type == "Entire townhouse"  |
                                                chicago_merged$property_type == "Entire cottage" |
                                                chicago_merged$property_type == "Entire serviced apartment" |
                                                chicago_merged$property_type == "Entire place"  |
                                                chicago_merged$property_type == "Entire loft"   |
                                                chicago_merged$property_type == "Entire rental unit"   |
                                                chicago_merged$property_type == "Entire residential home"|
                                                chicago_merged$property_type == "Tiny house"   |
                                                chicago_merged$property_type == "Entire villa" |
                                                  chicago_merged$property_type == "Entire home/apt") %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(chicago_full_homes, "chicago_zillow_roi.csv")
head(chicago_full_homes)
##histogram all data
par(mfrow=c(2,2))
hist(chicago_full_homes$ROI,main="ROI% - Chicago Houses-Oct 21",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(chicago_full_homes[chicago_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(chicago_full_homes[chicago_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(chicago_full_homes[chicago_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))
boxplot(chicago_full_homes[chicago_full_homes$ROI<= 500,]$ROI, main="Outliers Chicago- ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(chicago_full_homes, nbreaks = 8)+ ggplot2::labs(title = "Chicago ROI Corr")
