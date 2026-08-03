-- ============================================================
-- Loan Default Risk Scorecard (Weight-of-Evidence style)
-- Dataset: German Credit Data (UCI / Statlog, 1000 records)
-- Author: Prince Pal
-- ============================================================

-- STEP 1: Points are assigned per category based on each
-- category's OBSERVED bad-credit rate in the data (higher
-- observed default rate -> more risk points). This mirrors
-- how real bank scorecards are built (Weight of Evidence).

CREATE VIEW IF NOT EXISTS risk_scored AS
SELECT
  *,
  -- Checking account status (strongest signal: no account = lowest risk here)
  CASE
    WHEN status = '... < 100 DM' THEN 3
    WHEN status = '0 <= ... < 200 DM' THEN 2
    WHEN status = '... >= 200 DM / salary for at least 1 year' THEN 1
    ELSE 0
  END AS pts_status,

  -- Savings account balance
  CASE
    WHEN savings = '... < 100 DM' THEN 3
    WHEN savings = '100 <= ... < 500 DM' THEN 2
    WHEN savings IN ('unknown/no savings account','500 <= ... < 1000 DM') THEN 1
    ELSE 0
  END AS pts_savings,

  -- Employment stability
  CASE
    WHEN employment_duration IN ('... < 1 year','unemployed') THEN 3
    WHEN employment_duration = '1 <= ... < 4 years' THEN 2
    ELSE 1
  END AS pts_employment,

  -- Credit history (counter-intuitive: "no credit history" scores riskier
  -- than "critical account" in THIS data -- flagged in README as a real
  -- adverse-selection pattern, not a data error)
  CASE
    WHEN credit_history IN ('no credits taken/all credits paid back duly',
                             'all credits at this bank paid back duly') THEN 3
    WHEN credit_history IN ('existing credits paid back duly till now',
                             'delay in paying off in the past') THEN 2
    ELSE 0
  END AS pts_credit_history,

  -- Installment rate = % of disposable income going to this loan (DTI proxy)
  CASE
    WHEN installment_rate = 4 THEN 2
    WHEN installment_rate = 3 THEN 1
    WHEN installment_rate = 2 THEN 1
    ELSE 0
  END AS pts_dti,

  -- Age (younger borrowers = higher observed risk)
  CASE
    WHEN age < 25 THEN 2
    WHEN age < 35 THEN 1
    ELSE 0
  END AS pts_age

FROM loans;

CREATE VIEW IF NOT EXISTS risk_final AS
SELECT
  *,
  (pts_status + pts_savings + pts_employment + pts_credit_history + pts_dti + pts_age) AS risk_score,
  CASE
    WHEN (pts_status + pts_savings + pts_employment + pts_credit_history + pts_dti + pts_age) <= 4 THEN 'Low Risk'
    WHEN (pts_status + pts_savings + pts_employment + pts_credit_history + pts_dti + pts_age) <= 8 THEN 'Medium Risk'
    WHEN (pts_status + pts_savings + pts_employment + pts_credit_history + pts_dti + pts_age) <= 11 THEN 'High Risk'
    ELSE 'Very High Risk'
  END AS risk_tier
FROM risk_scored;

-- STEP 2: Validate the scorecard -- a good scorecard should show
-- bad-credit rate rising monotonically across risk tiers.
SELECT
  risk_tier,
  COUNT(*) AS num_loans,
  SUM(amount) AS total_exposure_dm,
  ROUND(100.0 * (COUNT(*) - SUM(credit_risk)) / COUNT(*), 1) AS actual_bad_pct
FROM risk_final
GROUP BY risk_tier
ORDER BY MIN(risk_score);
