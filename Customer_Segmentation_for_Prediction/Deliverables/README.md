## Customer Segmentation for Prediction
**Team Connected Insights:** Xufei Lang, Qi Pan, Gulmira Zhavgasheva

---

## Project Overview

This project builds a **customer‑level analytics pipeline** that integrates data from multiple Snowflake sources, performs full‑dataset clustering, and trains cluster‑specific predictive models. The project is structured into three sequential pipelines, encompassing feature selection and clustering, predictive model comparison, and final model selection for Shiny deployment.

All clustering and modeling artifacts are stored and exposed through an **interactive Shiny application**, allowing users to assign clusters, generate predictions, and visualize cluster structure using 3D multidimensional scaling (MDS).

---

## Project Structure

```text
Team Connected Insights/ 
│ 
├── README.md      # Project overview (this file) 
├── README.html    # Project overview preview (open in browser) 
│ 
├── SETUP.md       # Setting up R and RStudio 
├── SETUP.html     # Setting up R and RStudio preview (open in browser)
│ 
├── data/ 
│   ├── raw/             # Placeholder, data directly extracted from Snowflake 
│   ├── intermediate/    # Initial base feature table without target
│   ├── final/           # Final full datasets used by pipeline1 and Shiny UI 
│   ├── README.md        # Data overview 
│   └── README.html      # Data overview preview (open in browser) 
│ 
├── data_cleaning/ 
│   ├── engagement_espalier_surveys.Rmd    # Data cleaning and aggregation for Target 1
│   ├── df_merge_english.R                 # Data cleaning, integration and merging for Target 1 
│   ├── df_merge_CSC.R                     # Target 2 data preparation
│   ├── 3rd_target_CEAR.Rmd                # Target 3 data preparation
│   ├── README.md                          # Data cleaning overview
│   └── README.html                        # Data cleaning overview preview (open in browser)
│ 
├── analysis/ 
│   ├── segmentation_CSC.R    # Post‑clustering analysis and validation for Target 2
│   ├── README.md             # Cluster analysis overview
│   └── README.html           # Cluster analysis overview preview (open in browser) 
│
├── pipelines/ 
│   ├── pipeline1_3_feature_selection_clustering_optimal_models_for_shiny.Rmd    # Pipeline 1&3 
│   ├── pipeline2_predictive_models_comparison.Rmd                               # Pipeline 2
│   ├── README.md      # Pipelines overview 
│   └── README.html    # Pipelines overview preview (open in browser) 
│ 
└── outputs/ 
│   ├── pam_bundles/        # Serialized `.rds` artifact used by Shiny UI 
│   └── reports/            # Rendered HTML reports from pipelines
│       ├── pipeline1_3/    # Rendered HTML reports from pipeline1_3
|       └── pipeline2/      # Rendered HTML reports from pipeline2
│
└── shiny/ 
    ├── app.R          # Shiny UI application 
    ├── README.md      # Shiny app instructions 
    └── README.html    # Shiny app instructions preview (open in browser) 
```

---

## Data Sources

The project uses 10 tables from Snowflake, divided into two sets based on extraction and cleaning approach.

- Source system: Snowflake
- Data type: Relational tables
- Granularity: Customer-level (post-merge)
- See `data/README` for schema and variable definitions.

---

## Data Cleaning & Integration Process

- **Core Data Preparation:** Data from multiple relational tables in Snowflake is cleaned and integrated to construct a unified, customer‑level base feature table.

- **Cleaning Approaches:** Two complementary workflows are used: (1) direct extraction and transformation using R Markdown and a Snowflake connector, and (2) SQL‑based preprocessing in Snowflake followed by CSV export, limited manual adjustments in Excel, and further cleaning in R.

- **Integration Logic:** Cleaned outputs from both workflows are merged in R using `account_id` as the primary join key, with finer‑granularity tables aggregated prior to integration.

- **Pipeline Readiness:**
The resulting base dataset is extended with lightweight, target‑specific preparation steps to produce the final datasets used in Pipelines1 and Shiny UI.

- Detailed data cleaning steps, merge logic, and transformations are documented in `data_cleaning/README`.

---

## Cluster Analysis

- Analysis outputs are not part of the final deliverables.
- Diagnostic plots were used for **internal analysis and presentation**, and the cluster‑labeled dataset served as an **intermediate input for early predictive modeling**, which informed subsequent refinements to Pipeline 1.
- Detailed Analysis steps are documented in `analysis/README`.

---

## Analytical Pipelines Overview

- **Pipeline Structure:** The analytical workflow is organized into three sequential pipelines that transform the cleaned customer‑level dataset into deployable clustering and prediction artifacts.

- **Pipeline 1 - Feature Selection and Clustering:** Feature selection and clustering are applied to identify meaningful customer segments and generate cluster assignments.

- **Pipeline 2 - Predictive Models Comparison:** Multiple predictive models are trained and evaluated within each cluster to identify the best‑performing configurations.

- **Pipeline 3 - Optimal Models for Shiny:** Final clustering results and selected models are consolidated into serialized artifacts for use in the Shiny application.

- Detailed pipeline logic and modeling decisions are documented in the corresponding `pipelines/README` file.
- Detailed outputs are stored in `outputs/reports/`.

---

## Shiny App (Segmentation & Prediction)

- An interactive Shiny app for **cluster assignment, cluster‑aware prediction, and 3D MDS visualization** using PAM (Gower) and pre‑trained per‑cluster models.
- Intended for internal analysis, validation, and presentation, consuming finalized data and saved PAM bundles.
- **File:** `shiny/app.R`
- **Inputs:** `/data/final/*.csv`, `/outputs/pam_bundles/*.rds`
- Detailed Shiny app instructions are provided in `shiny/README` file.

**Prerequisites:** Refer to `SETUP.md` for environment setup and required R packages.

**Note:** This code was generated with the assistance of **Microsoft Copilot (AI)** and refined by the author through iterative guidance, adjustments, and validation.

---

## Execution Order (High Level)

### Prerequisites

- Refer to `SETUP.md` for environment setup and dependency details
- Required R packages are loaded directly in the code  

### Standard Usage (Recommended)

Launch the Shiny app (instruction in `shiny/README`)

All required intermediate datasets, models, and artifacts have already been generated and saved.
This is the intended path for most users.

### Full End‑to‑End Reproduction (Optional)

1. Data extraction and cleaning (Rmd, SQL, R, Excel, check out `data_cleaning/README`)
2. Merge all cleaned tables into the final dataset (see `data/README`)
3. Cluster analysis (see `analysis/README`)
4. Run Pipeline 1 (Feature Selection & Clustering) (see `pipelines/README`)
5. Run Pipeline 2 (Per‑cluster model comparison)
6. Run Pipeline 3 (Artifact generation)
7. Launch the Shiny app (instruction in `shiny/README`)

---

## Assumptions & Limitations

- Manual Excel imputations introduce subjectivity and must be documented
- Snowflake data represents a snapshot in time
- Models are cluster-specific and may not generalize outside observed patterns

---

## Authors & Responsibilities
- Database investigation & EDA: [Qi Pan, Xufei Lang]
- Data extraction & Rmd cleaning, integration for Target 1: [Xufei Lang]
- SQL, Excel & R-based cleaning, integration and merging for Target 1: [Qi Pan]
- Clustering analysis & visualization for Target 1: [Qi Pan]
- Midterm presentation slides: [Xufei Lang, Gulmira Zhavgasheva, Qi Pan]
- Predictive modeling for Target 1: [Qi Pan, Xufei Lang]  
- Pipeline1 development: [Xufei Lang, Qi Pan]
- Pipeline2 development: [Xufei Lang]
- Target 2 preparation & pipeline results report: [Qi Pan]
- Target 3 preparation & pipeline results report: [Gulmira Zhavgasheva]
- Pipeline3 model packaging: [Xufei Lang, Qi Pan, Gulmira Zhavgasheva]
- Clustering analysis & visualization for Target 2: [Qi Pan]
- Clustering analysis & visualization for Target 3: [Gulmira Zhavgasheva]  
- Shiny UI development: [Xufei Lang]
- Final report writing: [Qi Pan, Xufei Lang, Gulmira Zhavgasheva]
- Final presentation slides: [Gulmira Zhavgasheva]
- Project deliverables structure and documentation (`README.md`): [Xufei Lang]

---

## Deliverables

- Final curated dataset used for analysis and modeling
- Source code and pipelines used for analysis and modeling
- Shiny UI App
- Project documentation (`README.md`, `README.html`)
- Final report used to document analysis methodology, results and conclusions
- Presentation slides used to communicate analysis results and conclusions

---

Maintained by Xufei Lang  
Last updated: 2026‑03‑26

