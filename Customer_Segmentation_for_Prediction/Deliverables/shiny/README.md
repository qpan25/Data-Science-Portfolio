## Shiny App: Cluster‑Aware Prediction (PAM + Gower)
**Team Connected Insights:** Xufei Lang, Qi Pan, Gulmira Zhavgasheva

---

**File:** `shiny/app.R` (by Xufei Lang) 

**Inputs:**

- Data:
  - Target 1 (growth rate of GigaSpire): `/data/final/final_target.csv`
  - Target 2 (growth rate of CSC): `/data/final/final_target_CSC_giga.csv`
  - Target 3 (Engagament Cloud Insentity): `/data/final/final_target_CEA_rate_upd.csv`
- PAM bundle:
  - Target 1 (growth rate of GigaSpire): `/outputs/pam_bundles/pam_bundle_1st.rds`
  - Target 2 (growth rate of CSC): `/outputs/pam_bundles/pam_bundle_2nd.rds`
  - Target 3 (Engagament Cloud Intensity): `/outputs/pam_bundles/pam_bundle_3rd.rds`

---

## Prerequisites

- R environment and required packages must be installed before running this app
- Please refer to `SETUP.md` for environment setup, package installation, and dependency details

---

## Purpose

- Interactive Shiny application for **segmentation and cluster‑specific prediction**
- Uses **PAM clustering with Gower distance** and **pre‑trained per‑cluster models**
- The same codebase is reused across all three targets (GigaSpire, CSC, etc.) with minimal changes to inputs and bundle files

---

## How to Run the App
- Open `shiny/app.R` in RStudio
- Click the **Run App** button in the editor

---

## What the App Does

### Step 1 — Cluster Assignment

- Upload a finalized dataset (`/data/final/*.csv`)
- Upload a saved PAM bundle (`/outputs/pam_bundles/*.rds`)
- Assign a record to the nearest medoid (cluster) using Gower distance

### Step 2 — Cluster‑Specific Prediction

- Automatically select the appropriate model based on assigned cluster
- Accept cluster‑specific prediction features
- Predict the target value (e.g., growth rate) using GBM or Random Forest

User inputs and actions are guided by the app interface

---

## Visualization & Exploration

- 3D MDS visualization of clustering results (Gower distance)
- Color‑coded clusters with interactive hover information
- User input point highlighted
- Optional highlighting of a selected `account_id`
- Medoid profiles table for cluster interpretation

---

## Data Output

- Downloadable dataset with appended Cluster label
- Outputs are intended for internal analysis and exploration only, not final deliverables

---

## Notes

- Assumes cleaned and finalized input data
- No model training or re‑clustering is performed in the app
- Designed for internal analysis, validation, and presentation
- If the app crashes, press `Esc` in the R console and rerun the app
- This code was initially generated with the assistance of **Microsoft Copilot (AI)** and was subsequently **guided, reviewed, and refined by the author**, including design decisions, logic adjustments, and domain‑specific customization.

---

Last updated: 2026‑03‑25

