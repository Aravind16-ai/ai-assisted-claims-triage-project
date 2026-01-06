***AI-Assisted Health Insurance Claims Triage & Fraud Detection***
An end-to-end Python + SQL project that cleans and scores health insurance claims, runs automated fraud/risk rules (duplicates, overcharging, risk spikes, high-risk patients), and stores alerts in a relational model ready for dashboards.

# What this project demonstrates
- End-to-end data product thinking: from raw CSVs → Python cleaning & feature engineering → SQL schema → business rules → alerts → dashboards.
- Ability to design a normalized database + ERD for claims, claimants, providers, and alerts.
- Design and implementation of rule-based fraud & risk detection (duplicate claims, overcharging, risk spikes, high-risk patients).
- Use of Python + SQL + MySQL together (ETL, analytics, automation, testing).
- Clear business documentation and communication of a technical solution for non-technical stakeholders.

# What files to open first
- README.md: this file (project overview + how everything fits together).
- images/ERD_latest.pdf: data model for claims, claimants, providers, and real_time_alerts.
- ipynb/AI_Triage_Model.pdf: how Python prepares data and computes risk scores.
- ipynb/Automation_Business_Rules.pdf: how rules are automated and alerts are written.
- ipynb/Testing_with_Mock_Data.pdf: how each rule is validated with mock data.

# Business Problem
**Health insurance teams deal with thousands of claims every month. Today, most fraud and risk reviews are:**
- Manual: analysts trawl through spreadsheets or static reports.
- Reactive: issues are discovered after payments are made.
- Fragmented: claim, patient, and provider data sit in different systems with no unified risk view.

**This creates several problems:**
- Suspicious duplicate claims can be paid multiple times.
- Providers can systematically overcharge above agreed caps without being noticed.
- High-risk patients who visit many providers (potential “doctor shopping”) are hard to spot.
- Spikes in overall risk score (e.g., due to a new fraud pattern) are invisible until it’s too late.

**The business need is a repeatable, auditable system that:**
- Standardises and scores claims as they arrive.
- Applies clear, explainable business rules.
- Surfaces actionable alerts to fraud and operations teams.

# Solution Overview
**This project implements an AI-assisted triage and fraud detection pipeline:**
**Data Preparation (Python)**
- Load raw claims and insurance data from CSV files.
- Clean and standardise fields (dates, text, missing values, outliers).
- Join patient and claim data into a single enriched dataset.

**Risk Scoring (Python)**
- Compute a claim-level risk score on a 0–100 scale using age, BMI, and smoker status.
- Set fraud_flag and needs_review based on risk thresholds and amount patterns.
- Output to a curated staging table cleaned_merged_claims.

**Relational Schema (SQL / MySQL)**
- Normalize data into claimants, providers, claims, and real_time_alerts tables.
- Add indexes and partitioning for scalable performance.

**Business Rules Engine (SQL + Python)**
- Implement 6 rules to detect duplicate claims, overcharging, repeated procedures, risk spikes, and high fraud scores.
- Convert rule output into structured alerts and store them in real_time_alerts.

**Analytics & Dashboards (conceptual)**
- High-risk patients view, risk trend view, duplicate claims per month, and a combined fraud dashboard.
- Designed to drive investigations and continuous improvement of rules.

# Tech Stack
**Language & Analysis**
- Python (Pandas, SQLAlchemy, Jupyter notebooks)

**Database**
- MySQL
- Two main schemas:
   - AI_Assisted_Claims_Triage_Project – staging (cleaned_merged_claims)
   - claims_project – normalized model (claimants, providers, claims, real_time_alerts)
- Data / Visual Documentation
   - PDFs: ERD, AI Triage Model, Automation Business Rules, Testing with Mock Data
   - Dashboards (e.g., High-Risk Patients, Risk Score Trend, Duplicate Claims per Month, Fraud Claims Dashboard)
-Dev & Docs
   - Git / GitHub
   - Markdown + PDF documentation
 
# Architecture / Flow
**End-to-end flow**

1. Source Data
   - enhanced_health_insurance_claims.csv – claim facts (dates, amounts, procedures, status, type)
   - insurance.csv – claimant attributes (age, BMI, smoker, region)

2. Python – AI Triage Model
   - Clean & merge into cleaned_merged_claims
   - Compute risk scores, fraud flags, needs_review
   - Export to MySQL (AI_Assisted_Claims_Triage_Project.cleaned_merged_claims)

3. SQL – Core Analytics Schema
   - Populate claimants, providers, claims (in claims_project) from staging.
   - Enforce referential integrity and add performance indexes.

4. Python + SQL – Business Rules Automation
   - Call SQL for each rule (duplicates, overcharging, etc.).
   - Enrich results with rule metadata and risk/alert scores.
   - Insert results into claims_project.real_time_alerts.

5. Analytics / BI
   - Dashboards and reports sit on top of claims and real_time_alerts.
   - Analysts filter by rule, alert level, region, provider, and date ranges.
  
You can see the architecture visually in images/ERD_latest.pdf and the flow in ipynb/Automation_Business_Rules.ipynb.

# Business Rules Implemented
**Each rule is explainable, with clear business meaning and SQL/Python implementation.**

Rule 1: Duplicate Claims Detection
   - Detects claims for the same claimant with similar procedure codes (e.g., same first 3 characters) within 0–90 days.
   - Flags potential duplicates for manual review.

Rule 2: High-Risk Patient Profiling (Multiple Providers)
   - Finds claimants visiting 3 or more distinct providers.
   - Highlights possible “doctor shopping” or fragmented care that increases risk.

Rule 3: Capped Amount Variance / Provider Overcharging
   - Compares amount vs amount_capped for each provider and procedure.
   - Calculates average overcharge percentage; flags providers systematically charging above cap.

Rule 4: Duplicate Service Prevention (Same Procedure)
   - Identifies claims where the same claimant receives the same procedure again within 1–90 days.
   - Flags potential unnecessary or fraudulent repeat services.

Rule 5: Sudden Surge in Risk Score
   - Calculates today’s average risk score and compares it to the previous 7 days.
   - Raises an alert when today’s value exceeds 120% of the prior 7-day average.

Rule 6: High Fraud Score Alerts
   - Flags claims with either:
      fraud_flag = 1, or
      Risk score above thresholds (e.g., > 75 for High, > 90 for Critical).
   - Enriches alerts with provider fraud history (how many prior fraudulent claims).

All rule outputs are written to real_time_alerts with: rule_name, rule_triggered, alert_level, alert_score, timestamps, and related IDs.

# Results / Impact
**This project is built on synthetic / mock data, so impact is described in terms of capabilities rather than production KPIs:**

- Automatically triages every claim with a 0–100 risk score and review flags.
- Detects candidate duplicate claims and repeat procedures across configurable time windows (e.g., 0–90 days).
- Surfaces overcharging patterns for providers based on capped amount variance.
- Monitors the health of the portfolio via daily risk score spike detection.
- Provides an auditable trail of alerts in real_time_alerts for future dashboards and investigations.

# Folder Guide

- notebooks/
  AI_Triage_Model.ipynb: data prep, risk score calculation.
  Automation_Business_Rules.ipynb: rules automation and alert writing.
  Testing_with_Mock_Data.ipynb: mock data tests for all rules.

- sql/
  sql_queries.sql: database creation, table DDL, and core queries.

- tableau/
  claims_export.csv file
  claimants_export.csv file
  providers_export.csv file
  real_time_alerts.csv file  

- pdf/
  fraud claims dashbaord
  high risk patients
  risk score trend
  duplicate claims
  
- docs/
  BRD documentation file.pdf

- images/
  ERD_latest.jpg: data model for staging, claims, claimants, providers, alerts.

- README.md
  overall documentation.

# Links
Github profile: https://github.com/Aravind16-ai
Project Repository: https://github.com/Aravind16-ai/ai-assisted-claims-triage-project
Linked In: https://www.linkedin.com/in/avindkumar-thupilly/
Portfolio Website: https://aravind16.lovable.app/
