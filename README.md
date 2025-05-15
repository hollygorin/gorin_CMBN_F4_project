# Matlab Code for Data Processing, Visualization, and Analysis of:

**The use of autonomic pupil and cardiorespiratory metrics to evaluate engagement during gamified upper extremity rehabilitation activities in healthy adults and adults post-stroke**

This project investigates the use of autonomic measurements, specifically pupil size, respiratory rate, and heart rate, to evaluate subject engagement during varying difficulty levels of a gamified upper extremity rehabilitation task. The study compares these measures across difficulty levels and between healthy adults and post-stroke adults, aiming to assess their sensitivity to engagement and differences in autonomic responses in individuals with intact vs impaired nervous systems. This repository focuses on the data extraction, processing, visualization, and analysis for the above aims.

Additional objectives, not directly addressed in this repository, include comparing and assessing correlations between these physiological metrics to subjective measures of engagement. Code in this repository includes extracting and organizing this subjective assessment data, but analysis for this aim has not been started yet.

---

## Repository Contents  

### General Notes  
- All code written in MATLAB R2024b  
- **Toolboxes used**:  
  - Statistics and Machine Learning Toolbox  
  - Curve Fitting Toolbox  
  - Signal Processing Toolbox  

### Core Configuration  
- `thesisDataAnalysisSettings.m`: Defines all paths, constants, variable groupings, and configuration parameters used across scripts.  
  - Called in: `selectTrials.m`, `trimming.m`, `extractAll.m`, `exportDataToFiles.m`, `simpleStatsComparisons.m`, `visualizeDataind.m`, 'spaghettiPlot.m', 'barScatterPlot.m', 'groupLinePlot.m'   

### Data Selection and Preprocessing  
- `selectSubject.m` (function): Select subjects for analysis; generates a subject ID map from folder structures.  
  - Nested Function: `createSubjectIDMap.m`  
  - Called in: `trimming.m`, `extractAll.m`  

- `selectTrials.m` (function): Selects trials for analysis (manual input or defaults to all trials).  
  - Called in: `extractAll.m`  

- `trimming.m`: Preprocess raw `.csv` files (pupil, accuracy, speed data); removes first 30 seconds and trims to 3 minutes total.  
  - Raw files: `EyeLog.csv` and `KinematicLog.csv` in `RawData/SubjectFolder/RawLogs`  
  - Processed `.csv` files saved in `Data/SubjectFolder/Logs`  

- Additional MATLAB scripts (external) further process these `.csv` files and BIOPAC `.mat` files to extract and store variable values per condition (`HR`, `pupil diameter`, etc.) in `.mat` files located in `RawData/SubjectFolder/MatlabOutputFiles`.  
  - See `matVars` in `thesisDataAnalysisSettings` for the full list.  

- `processResp.m` (function): Processes BIOPAC respiration data to extract average respiratory rate (RR), respiratory depth (RD), and peak RD per trial.  
  - BIOPAC `.mat` files located in `RawData/SubjectFolder/Biopac`  
  - RD is not currently used but is processed for future projects.  
  - Uses Signal Processing Toolbox  

---

### Data Extraction and Integration  
- `extractAll.m`: Main data integration pipeline.  
  - Selects subjects and trials via `selectSubject` and `selectTrials` (or selects all).  
  - Calls `mergeTables.m` throughout to handle table compatibility, fill missing columns, and resolve duplicate rows.  
  - Extracts and merges `.mat` and `.csv` data.  
  - Additional subject info (demographics, subjective assessments) stored in `.csv` files under `gorin_CMBN_F4_project/DataTables`.  
  - Calls `processResp.m` to extract respiratory data.  
  - Computes normalized metrics (percent baseline, raw changes), z-scores, and additional fields.  
  - Outputs `integratedDataTable.mat` (long format).  
  - Calls `exportDataToFiles.m` to export data to `.csv` or `.xlsx` for review.  
  - See 'integratedDataTable.mat' in 'DataTables' folder 

---

### Statistical Analysis  
- `runDVANOVAS.m` (function), called in `simpleStatsComparisons.m`  
  - Performs mixed-methods ANOVAs and post-hoc tests.  
  - Handles assumption testing:  
    - Uses `swtest.m` for normality.  
    - Levene’s test for variance assumptions.  
    - Sphericity assessment via MATLAB’s `ranova`.  
  - If assumptions fail, evaluates sample size and runs non-parametric alternatives via `runNonParametricTests.m`.  
  - Automatically marks statistically significant results.  
  - Uses Statistics and Machine Learning Toolbox.  
  - *Future plans include linear mixed-effects models (currently in early stages).*  
  

---

### Data Visualization  (example output in 'DataFigures' folder)

- `visualizeDataInd.m`:  
  - Generates subject-level bar plots for selected or all DVs.  
  - Options for standardized or individually scaled Y-axes.  

- **Group-Level Visualization Scripts**:  
  - Each script can plot all DVs listed in `DVsToPlot`, either by group or all subjects combined, and export plots as PDF.  
  - Option to visualize a single DV quickly.  

- `spaghettiPlot.m`:  
  - Creates spaghetti plots by group and/or all subjects combined.  
  - Optionally includes line for mean ± SEM.  

- `barScatterPlot.m`:  
  - Creates bar scatter plots by group and/or all subjects combined.  
  - Marks statistically significant differences in combined data using results from `simpleStatsComparisons.m`.  

- `groupLinePlot.m`:  
  - Creates line plots with options for 1 line per group, all subjects combined, and/or showing all 3 lines together.  
