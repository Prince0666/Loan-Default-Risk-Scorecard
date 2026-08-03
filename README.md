# Loan Default Risk Scorecard & Dashboard

**Author:** Prince Pal
**Tools:** SQL (SQLite), Tableau
**Dataset:** [Statlog (German Credit Data)](https://archive.ics.uci.edu/ml/datasets/Statlog+(German+Credit+Data)) — UCI Machine Learning Repository, 1000 real bank loan records, 20 features per applicant, CC BY 4.0 license.

## Problem Statement
Banks need to decide, before disbursing a loan, how likely an applicant is to default. This project builds a transparent, rule-based **risk scorecard** — similar to what credit risk teams at NBFCs and banks use — that converts raw applicant attributes into a single risk score and risk tier (Low / Medium / High / Very High), and validates whether that score actually predicts real-world default behavior.

## Approach

1. **Data profiling (SQL):** Grouped loans by each categorical attribute (checking account status, savings, employment duration, credit history) and measured the *actual* bad-credit rate per category.
2. **Weight-of-Evidence scoring:** Assigned risk points to each category based on its observed bad-credit rate — the same method real bank scorecards use, rather than guessing weights.
3. **DTI proxy:** Used the dataset's `installment_rate` field (installment as % of disposable income) as a debt-to-income indicator — bad-credit rate rises from 25.0% → 33.4% as this ratio increases, confirming it's a real risk driver.
4. **Composite scorecard:** Combined 6 weighted factors (checking status, savings, employment stability, credit history, DTI proxy, age) into a single `risk_score`, bucketed into 4 tiers.
5. **Validation:** Checked whether actual default rate rises monotonically across tiers — the standard test for whether a scorecard is usable.

## Key Result

| Risk Tier | Loans | Total Exposure (DM) | Actual Bad-Credit Rate |
|---|---|---|---|
| Low Risk | 57 | 192,919 | **1.8%** |
| Medium Risk | 363 | 1,190,714 | **13.8%** |
| High Risk | 376 | 1,324,967 | **34.6%** |
| Very High Risk | 204 | 562,658 | **58.3%** |

The default rate increases monotonically across tiers (1.8% → 58.3%), confirming the scorecard separates genuinely low-risk and high-risk applicants — the core requirement for a usable credit risk model.

## Notable Finding
Applicants with **no prior credit history** showed a *higher* bad-credit rate (62.5%) than applicants with an existing "critical account" (17.1%) — a counter-intuitive, adverse-selection pattern rather than a data error: applicants without a track record are harder for the bank to evaluate, and this shows up directly in outcomes. This is called out explicitly in the SQL comments rather than smoothed over.

## Files
- `risk_scorecard.sql` — full SQL: scoring logic + validation query
- `german_credit_scored.csv` — original dataset enriched with per-factor points, total risk score, and risk tier (for Tableau)
- `german_credit_raw.csv` — original unmodified dataset

## Next Step
Import `german_credit_scored.csv` into Tableau Public to build an interactive dashboard: risk-tier distribution, exposure by tier, and bad-rate by individual factor (status, savings, employment, age).
