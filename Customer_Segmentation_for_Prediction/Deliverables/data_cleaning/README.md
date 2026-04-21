# Data Cleaning Overview
**Team Connected Insights:** Qi Pan, Xufei Lang, Gulmira Zhavgasheva

This folder contains the data extraction, cleaning, transformation, and integration workflows used to produce analysis‑ready datasets for downstream pipelines and the Shiny UI application.
Technical logic is implemented across Snowflake SQL, Excel, and R/R Markdown, which together serve as the authoritative implementation source.

---

## Core Data Cleaning Approaches

Two core data cleaning approaches are used to construct the **initial base feature table** that supports Target 1 and serves as the foundation for subsequent targets.

### Set A: R Markdown + Snowflake Connector

- Tables are queried directly from Snowflake using an R‑based connector
- Cleaning and transformation are performed within .Rmd workflows
- Outputs are exported as cleaned tables for downstream integration
- **Primary entry file:** `engagement_espalier_surveys.Rmd` (by Xufei Lang)

This approach is used where direct database access and reproducible, notebook‑style documentation are preferred.

### Set B: SQL + CSV + Excel + R

- Initial filtering is performed using SQL in Snowflake
- Tables are exported as CSV files
- Limited manual imputations and adjustments are applied in Excel where required, and the updated files are reloaded into R
- Additional cleaning, harmonization, aggregation, and merging are performed in R
- **Primary entry file:** `df_merge_english.R` (by Qi Pan)

This approach is used where SQL‑based preprocessing or manual review is necessary prior to integration.

---

## Target‑Specific Data Preparation

In addition to the core data cleaning workflows, Targets 2 and 3 require additional target‑specific preparation steps to incorporate features not used in Target 1, including both newly derived features and features already present in the initial base feature table.

These steps extend the existing cleaned dataset rather than replacing the core data cleaning approaches.

### Target 2 Extensions

- Target variable: Growth Rate of CSC SUBSCRIBER COUNT in 3 Month
- One additional target‑specific feature derived from an existing source table
- **Primary entry file:** `df_merge_CSC.R` (by Qi Pan)

### Target 3 Extensions

- Target variable: Engagement Cloud Intensity
- One additional feature derived from the initial base feature table
- **Primary entry file:** `3rd_target_CEAR.Rmd` (by Gulmira Zhavgasheva)

---

## Integration and Merge Logic

- Cleaned tables from Set A and Set B are merged in R
- `account_id` is used as the primary join key at the customer level
- Tables at finer granularity are aggregated prior to merging
- Integration produces three consolidated, target‑specific datasets

The merge logic and join order are documented directly in the corresponding R scripts and R Markdown.

---

## Reproducibility and Limitations

- Set A workflows are fully reproducible via R Markdown
- Set B workflows include limited manual steps and are not fully reproducible end‑to‑end
- Manual steps and assumptions are documented inline within the relevant scripts

---

## Where to Find Implementation Details

- **R Markdown files:** Snowflake connectivity, table‑level cleaning, and aggregation  
- **R scripts:** Data cleaning, integration logic, merging and validation checks  
- **Inline comments:** Special‑case handling and implementation notes

This README is intended to provide a **technical overview of the data cleaning workflows** and to guide readers to the appropriate entry points. It is not a replacement for the code‑level documentation.

---

Last updated: 2026‑03‑25

