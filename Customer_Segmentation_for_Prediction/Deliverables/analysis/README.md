## Cluster Analysis
**Team Connected Insights:** Qi Pan, Xufei Lang, Gulmira Zhavgasheva

This directory contains post‑clustering analysis and validation for the second target (CSC).

---

## Code Location
- `analysis/segmentation_CSC.R` (by Qi Pan)
- Reused across all three targets with minimal changes to input data and target variables

---

## Scope

- Feature relationship analysis (correlation, PPS)
- Feature importance ranking (PPS, RF, LightGBM, Elastic Net)
- PAM clustering with Gower distance
- Cluster evaluation (ASW, silhouette plots)
- Cluster stability assessment (bootstrap Jaccard index)
- Statistical comparison between clusters
  - t‑tests for numerical variables
  - Chi‑square tests for categorical variables

---

## Outputs (Internal Use)

- Diagnostic plots and evaluation figures generated for **analysis and presentation purposes only**
- Cluster‑labeled dataset used as an **intermediate input for predictive modeling**, which informed subsequent modifications to Pipeline 1

**Note:** These artifacts are not part of the final deliverables. The clustered dataset was used upstream during predictive model development, and Pipeline 1 was refined based on insights derived from that modeling workflow.

---

Last updated: 2026‑03‑21

