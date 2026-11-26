# Data Quality & Edge-Case Verification Report

## 1. Dataset Summary
- **Source:** UCI Online Retail Dataset (ID: 352)
- **Date Range:** `2010-12-01` to `2011-12-09`
- **Raw Records Loaded:** 541,909
- **Clean Valid Records Retained:** 392,692 (72.46%)
- **Total Noisy Records Removed:** 149,217 (27.54%)

## 2. Data Quality Issues Identified & Resolved
| Issue Category | Row Count | Share of Raw Data | Resolution Applied |
| :--- | :---: | :---: | :--- |
| Missing `CustomerID` | 135,080 | 24.93% | Dropped (cannot attribute to a customer for RFM) |
| Refund / Cancellation Rows (`InvoiceNo` starting with `C` or `Quantity <= 0`) | 10,624 | 1.96% | Isolated into `df_refunds` and excluded from net purchase RFM |
| Exact Duplicate Rows | 5,268 | 0.97% | Deduplicated via `drop_duplicates()` |
| Invalid Unit Price (`UnitPrice <= 0`) | 2,517 | 0.46% | Filtered out zero/negative pricing adjustments |

*(Note: Individual issue counts overlap where a single row had multiple defects.)*

## 3. Clean Dataset Totals
- **Unique Active Customers:** 4,338
- **Unique Valid Invoices:** 18,532
- **Total Clean Net Revenue:** £8,887,208.89
- **Average Order Value (AOV):** £479.56

## 4. Acceptance Criteria & Edge-Case Verification
- **Single-Order Customers:** 1,493 customers (34.42%) identified and accurately scored without error.
- **Score Ties Handling:** 4,279 frequency ties (across 59 unique order frequencies) cleanly resolved using `rank(method='first')`, matching Oracle SQL `NTILE(5)` deterministic ordering.
- **Unassigned Customers:** 0 (All 4,338 customers mapped to a valid segment).
- **Empty Segments:** 0 (All 6 business segments populated).
- **20-Customer Manual Audit:** Sampled 20 customers (`random_state=42`) exported in `manual_verification_20_customers.xlsx` alongside their raw invoice rows for manual hand-check reconciliation.
