## Zillow Data Wrangling ##

set.seed(2022)
library(dplyr)
library(tidyverse)
library(ggplot2)
library(corrplot)
library(RColorBrewer)
library(GGally)


## filter data for Austin & October 2022
zillow_Austin <- City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month %>% 
  subset(.,City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$RegionName == "Austin" & 
           City_zhvi_uc_sfrcondo_tier_0_33_0_67_sm_sa_month$State == "TX") %>% 
  select(., SizeRank, RegionName, State, Price = `2021-10-31` )
head(zillow_Austin)
#write.csv(zillow, "zillow_dallas.csv")

## merging Zillow data with Airbnb data ##
austin_merged <- read_csv("austin_merge.csv")
head(austin_merged)
austin_merged$house_price <- zillow_Austin$Price
unique(austin_merged$property_type)
#colnames(dallas_merged)

##calculate ROI for entire houses
## equation used is monthly income /monthly cost of the house price
#monthly cost of the house price is calculated as follow:
# (((house price- 20% downpayment)+ 5% interest rate )/20 years/ 12 months) - (1% property tax/12 months)

# filter dataset for entire homes
austin_full_homes <- austin_merged %>% subset(.,austin_merged$property_type == "Entire condominium (condo)" |
                                                austin_merged$property_type == "Entire townhouse"  |
                                                austin_merged$property_type == "Entire cottage" |
                                                austin_merged$property_type == "Entire serviced apartment" |
                                                austin_merged$property_type == "Entire place"  |
                                                austin_merged$property_type == "Entire loft"   |
                                                austin_merged$property_type == "Entire rental unit"   |
                                                austin_merged$property_type == "Entire residential home"|
                                                austin_merged$property_type == "Tiny house"   |
                                                austin_merged$property_type == "Entire villa" |
                                                austin_merged$property_type == "Entire guesthouse"|
                                                austin_merged$property_type == "Entire chalet" |
                                                austin_merged$property_type == "Entire cabin") %>%
  mutate(ROI = round((income/((((house_price- (house_price*.2))+ (house_price*.05))/20/12)-(house_price*.01/12)))*100,0)) 
  
write.csv(austin_full_homes, "austin_zillow_roi.csv")
#head(austin_full_homes)

##histogram all data
par(mfrow=c(2,2))

hist(austin_full_homes$ROI,main="ROI% - Austin Houses-Oct,2021",
     xlab="ROI%",
     col="light blue", breaks=10,
     freq=FALSE)

##histogram houses >= 2000 ROI
hist(austin_full_homes[austin_full_homes$ROI<= 2000,]$ROI,main=" ROI% <= 2000%",
     xlab="ROI%",
     col="#FF9999", breaks=10,
     freq=FALSE)

##histogram houses >= 1000 ROI
hist(austin_full_homes[austin_full_homes$ROI<= 1000,]$ROI,main="ROI% <= 1000%",
     xlab="ROI%",
     col="#66CC99", breaks=10,
     freq=FALSE)

##histogram houses >= 500 ROI
hist(austin_full_homes[austin_full_homes$ROI<= 500,]$ROI,main="ROI% <= 500%",
     xlab="ROI%",
     col="#f37735", breaks=10,
     freq=FALSE)

#boxplot for ROI <= 500%
par(mfrow=c(1,1))

boxplot(austin_full_homes[austin_full_homes$ROI<= 500,]$ROI, main="Outliers Austin - ROI% <= 500%",
        col= "#9999CC")

##test correlation

ggcorr(austin_full_homes, nbreaks = 8)+ ggplot2::labs(title = "Austin ROI Corr")
