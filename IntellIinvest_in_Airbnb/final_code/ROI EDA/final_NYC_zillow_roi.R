## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for NYC & October 2022
zillow_NYC <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "New York" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "NY") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_NYC)
#write.csv(zillow, "zillow_NYC.csv")

## merging Zillow data with Airbnb data ##
NYC_merged <- read_csv("newyork_merge.csv")
head(NYC_merged)
NYC_merged$house_price <- zillow_NYC$Price
unique(NYC_merged$property_type)
#colnames(NYC_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
NYC_full_homes <- NYC_merged %>% subset(.,NYC_merged$property_type == "Entire condominium (condo)" |
                                                NYC_merged$property_type == "Entire townhouse"  |
                                                NYC_merged$property_type == "Entire cottage" |
                                                NYC_merged$property_type == "Entire serviced apartment" |
                                                NYC_merged$property_type == "Entire place"  |
                                                NYC_merged$property_type == "Entire loft"   |
                                                NYC_merged$property_type == "Entire rental unit"   |
                                                NYC_merged$property_type == "Entire residential home"|
                                                NYC_merged$property_type == "Tiny house"   |
                                                NYC_merged$property_type == "Entire villa" |
                                                NYC_merged$property_type == "Entire home/apt"|
                                                NYC_merged$property_type == "Entire cabin"|
                                                NYC_merged$property_type == "Entire bed and breakfast"|
                                                NYC_merged$property_type == "Entire chalet"|
                                                NYC_merged$property_type == "Entire vacation home" ) %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(NYC_full_homes, "NYC_zillow_roi.csv")
head(NYC_full_homes)
##histogram all data
par(mfrow=c(2,2))
hist(NYC_full_homes$ROI,main="ROI% - NYC Houses-Oct 21",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(NYC_full_homes[NYC_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(NYC_full_homes[NYC_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(NYC_full_homes[NYC_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))
boxplot(NYC_full_homes[NYC_full_homes$ROI<= 500,]$ROI, main="Outliers NYC- ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(NYC_full_homes, nbreaks = 8)+ ggplot2::labs(title = "NYC ROI Corr")
