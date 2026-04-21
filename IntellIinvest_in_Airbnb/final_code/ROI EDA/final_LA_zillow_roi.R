## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for LA & October 2022
zillow_LA <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "Los Angeles" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "CA") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_LA)
#write.csv(zillow, "zillow_LA.csv")

## merging Zillow data with Airbnb data ##
LA_merged <- read_csv("la_merge.csv")
head(LA_merged)
LA_merged$house_price <- zillow_LA$Price
unique(LA_merged$property_type)
#colnames(LA_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
LA_full_homes <- LA_merged %>% subset(.,LA_merged$property_type == "Entire condominium (condo)" |
                                                LA_merged$property_type == "Entire townhouse"  |
                                                LA_merged$property_type == "Entire cottage" |
                                                LA_merged$property_type == "Entire serviced apartment" |
                                                LA_merged$property_type == "Entire place"  |
                                                LA_merged$property_type == "Entire loft"   |
                                                LA_merged$property_type == "Entire rental unit"   |
                                                LA_merged$property_type == "Entire residential home"|
                                                LA_merged$property_type == "Tiny house"   |
                                                LA_merged$property_type == "Entire villa" |
                                                LA_merged$property_type == "Entire home/apt"|
                                                LA_merged$property_type == "Entire cabin"|
                                                LA_merged$property_type == "Entire bed and breakfast"|
                                                LA_merged$property_type == "Entire chalet"|
                                                LA_merged$property_type == "Entire vacation home" ) %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(LA_full_homes, "LA_zillow_roi.csv")
head(LA_full_homes)
##histogram all data
par(mfrow=c(2,2))
hist(LA_full_homes$ROI,main="ROI% - LA Houses-Oct 21",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(LA_full_homes[LA_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(LA_full_homes[LA_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(LA_full_homes[LA_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))
boxplot(LA_full_homes[LA_full_homes$ROI<= 500,]$ROI, main="Outliers LA- ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(LA_full_homes, nbreaks = 8)+ ggplot2::labs(title = "LA ROI Corr")
