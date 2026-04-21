# Setting Up R and RStudio
**Team Connected Insights:** Xufei Lang, Qi Pan, Gulmira Zhavgasheva

---

## Prerequisites

- **Environment:** Windows virtual machine
- **RStudio availability:** Not installed by default

---

## RStudio Recommendation

- **Recommended IDE:** RStudio Desktop
- **Purpose:** Running all R scripts and R markdown files developed by Team Connected Insights
- RStudio is the **recommended environment** for executing this project’s code due to:
  - Integrated package management
  - Native support for .R, .Rmd, and pipeline workflows
  - Built‑in tools for debugging, visualization, and reproducibility
- **RStudio is required** to run the **Shiny UI application**
  - The Shiny app relies on RStudio’s “**Run App**” functionality
  - Running the app outside RStudio is not supported for this project

---

## Enable Long Paths

If you are administrator and have Long Paths enabled, skip this section. Otherwise, follow the steps:   

- Open **Terminal**
- Right‑click the top bar and select **Settings**
- Navigate to **Windows PowerShell**
- Enable **Run this profile as Administrator**
- Click **Save**
- Close Terminal and reopen it
- Run the Long Paths command provided by Maile's `ADS-Accessing Snowflake Data-220126-224913.pdf`
  - Start the windows terminal as administrator and then run New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force

---

## Install R and RStudio

- **Action required:** Install R and RStudio after enabling Long Paths
- **Reason:** Installing before enabling Long Paths may cause package or file‑path errors
- **Download link:**
  - RStudio Desktop — https://posit.co/download/rstudio-desktop/

---

## R Markdown Support

- **Required package:** rmarkdown
- **Purpose:**
  - Running .Rmd files used for data cleaning and Pipelines
  - Rendering R scripts
- Install the package in RStudio if it is not already available:
  - install.packages("rmarkdown")
- The rmarkdown package is recommended to execute all .Rmd files from Team Connected Insights

---

## Snowflake Connection (ODBC Setup)

Skip if you don't need to run the data cleaning Rmd file. 

- **Purpose:** Pull data directly from Snowflake into RStudio
- **Requirement:** Snowflake ODBC driver
- **Instructions and code location:**
  - `data_cleaning/engagement_espalier_surveys.Rmd` → **Download and install ODBC driver through this link:**
- Follow the comments and setup steps in the provided .Rmd file

---

## Running the Shiny Application

- **Required package:** shiny
- Install if needed: 
  - install.packages("shiny")
- Note: Required packages may also be installed automatically when the app runs
- **Do not rename app.R**
  - Renaming the file may cause the “**Run App**” button in RStudio to disappear

---

Maintained by Xufei Lang  
Last updated: 2026‑03‑20

