## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for seattle & October 2022
zillow_seattle <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "Seattle" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "WA") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_seattle)
#write.csv(zillow, "zillow_seattle.csv")

## merging Zillow data with Airbnb data ##
seattle_merged <- read_csv("seattle_merge.csv")
head(seattle_merged)
seattle_merged$house_price <- zillow_seattle$Price
unique(seattle_merged$property_type)
#colnames(seattle_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
seattle_full_homes <- seattle_merged %>% subset(.,seattle_merged$property_type == "Entire condominium (condo)" |
                                                seattle_merged$property_type == "Entire townhouse"  |
                                                seattle_merged$property_type == "Entire cottage" |
                                                seattle_merged$property_type == "Entire serviced apartment" |
                                                seattle_merged$property_type == "Entire place"  |
                                                seattle_merged$property_type == "Entire loft"   |
                                                seattle_merged$property_type == "Entire rental unit"   |
                                                seattle_merged$property_type == "Entire residential home"|
                                                seattle_merged$property_type == "Tiny house"   |
                                                seattle_merged$property_type == "Entire villa" |
                                                seattle_merged$property_type == "Entire home/apt"|
                                                seattle_merged$property_type == "Entire cabin"|
                                                seattle_merged$property_type == "Entire bed and breakfast") %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(seattle_full_homes, "seattle_zillow_roi.csv")
head(seattle_full_homes)
##histogram all data
par(mfrow=c(2,2))
hist(seattle_full_homes$ROI,main="ROI% - Seattle Houses-Oct 21",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(seattle_full_homes[seattle_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(seattle_full_homes[seattle_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(seattle_full_homes[seattle_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))
boxplot(seattle_full_homes[seattle_full_homes$ROI<= 500,]$ROI, main="Outliers Seattle- ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(seattle_full_homes, nbreaks = 8)+ ggplot2::labs(title = "Seattle ROI Corr")
