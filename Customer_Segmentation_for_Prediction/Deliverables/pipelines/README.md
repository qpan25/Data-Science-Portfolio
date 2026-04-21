# Pipelines Overview
**Team Connected Insights:** Xufei Lang, Qi Pan, Gulmira Zhavgasheva

This folder contains the **analytical pipelines** responsible for feature selection, clustering, predictive models comparison, and artifact generation (optimal models) used by Shiny UI.

The pipelines operate on **analysis‑ready datasets** produced by the data cleaning workflows and are designed to be executed sequentially and run automatically with minimum data preparation.

---

## Scope and Responsibilities

The pipelines in this folder are responsible for:

- Performing feature selection and customer‑level clustering
- Training, evaluating and comparing predictive models within each cluster
- Evaluating and comparing top candidate models based on predefined performance and complexity criteria
- Producing serialized artifacts for downstream consumption and deployment

All pipelines are implemented in **R Markdown** and rely on datasets stored in the `data/final` folder.

---

## Pipeline Summary

- **Pipeline 1:** Feature Selection and Clustering  
- **Pipeline 2:** Predictive Models Comparison  
- **Pipeline 3:** Optimal Models for Shiny  

---

## Pipeline 1: Feature Selection and Clustering

- **File:** `pipeline1_3_feature_selection_clustering_optimal_models_for_shiny.Rmd` (by Xufei Lang, Qi Pan)

### Purpose

- Identify meaningful customer segments by applying clustering algorithms to the full cleaned dataset

### Input

- Final cleaned dataset from `data/final/`

### Process

- Preparing features for clustering analysis
- Applying a consensus ranking method to identify the most informative features
- Performing clustering on the dataset using the selected top features
- Generating cluster assignments for each observation

### Output

- Dataset augmented with cluster labels
- Saved for downstream modeling pipelines

---

## Pipeline 2: Predictive Models Comparison

- **File:** `pipeline2_predictive_models_comparison.Rmd` (by Xufei Lang)

### Purpose

- To identify the best-performing model configuration within each cluster by selecting optimal models, feature sets, and tuned parameters.

### Input

- Clustered dataset produced by Pipeline 1

### Process

- Preparing features for prediction analysis
- Partitioning the data by cluster
- Training multiple models independently for full dataset and within each cluster
- Evaluating model performance using RMSE and R²
- Conducting statistical comparisons of candidate models using t-tests and Wilcoxon tests
- Recording feature counts and model complexity measures
- Summarizing performance metrics and tuning results to support informed manual selection of final cluster-specific models

### Feature Count Selection Policy

Model configurations with RMSE within 1% of the best-performing model were retained, and those using 5–6 features were prioritized to balance predictive performance and usability in the Shiny application. When multiple candidates met this criterion, the configuration with the highest R² was selected; if none fell within the preferred feature range, the configuration with the smallest feature count within the RMSE tolerance was chosen, using R² as a tie‑breaker.

This policy was applied during model selection to balance predictive performance with feature parsimony, rather than selecting models solely based on the lowest RMSE.

---

### Output

- Rendered HTML reports generated from R Markdown
- Model performance metrics and optimal hyperparameter configurations for each cluster
- Candidate model results used as input for downstream review and artifact generation

---

## Pipeline 3: Optimal Models for Shiny

- **File:** `pipeline1_3_feature_selection_clustering_optimal_models_for_shiny.Rmd` (by Xufei Lang, Qi Pan, Gulmira Zhavgasheva)

### Purpose

- Consolidate clustering results and selected models into serialized artifacts for use in Shiny-based deployment and visualization

### Input

- Clustering results from Pipeline 1
  - Clustering assignments
  - Medoid profiles
  - Clustering features set 
- Selected modeling outputs from Pipeline 2
  - Cluster-specific predictive feature sets
  - Final selected model and optimal parameters for each cluster
  - n.trees (GBM only)
  - Target variable name 
  
### Process

- Manually specifying the selected predictive features at the cluster level
- Verifying consistency between the target variable used in Pipeline 1 and the features recorded for modeling
- Preparing modeling data at the cluster level
- Manually inputting the selected model and optimal parameters for each cluster and fitting the models
- Saving the resulting PAM bundle as a serialized .rds file

### Implementation Note

- Pipeline 3 is implemented within the same R Markdown document as Pipeline 1 
- Clustering results produced in Pipeline 1 and model information generated in Pipeline 3 are consolidated and saved together into a single serialized `.rds` artifact 

### Output

- Rendered HTML reports generated from R Markdown
- Serialized `.rds` artifact containing:
  - Cluster results
  - Final selected model for each cluster
  - Associated metadata supporting model interpretation and reuse

These combined artifacts are consumed directly by the Shiny application.

---

## Execution Order

The pipelines are intended to be run in the following order:

1. Pipeline 1 — Feature Selection and Clustering  
2. Pipeline 2 — Predictive Models Comparison  
3. Pipeline 3 — Optimal Models for Shiny  

Each pipeline depends on the outputs of the previous step.

---

## Reproducibility Notes

- Pipelines are deterministic given identical inputs and environment
- All assumptions, parameter choices, and evaluation logic are documented inline within the pipeline scripts
- Upstream data reproducibility depends on the data cleaning workflows documented in `data_cleaning/README.md`

---

## Relationship to Other Project Components

- **Inputs**
  - `data/final/` (analysis‑ready datasets)

- **Outputs**
  - `outputs/pam_bundles/`
  - `outputs/reports/pipeline1_3/`
  - `outputs/reports/pipeline2/`

- **Downstream Consumers**
  - Shiny application (`shiny/app.R`)

---

## Where to Find Details

- Inline comments within each pipeline script document:
  - Parameter choices
  - Model configurations
  - Evaluation logic
  - Selection criteria

This README provides a **conceptual overview** of the analytical pipelines and
their responsibilities. For full technical details, refer directly to the
corresponding R Markdowns.

---

Last updated: 2026‑03‑20

