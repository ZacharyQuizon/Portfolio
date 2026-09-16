# Retail Profitability & Forecast Risk — Case Study

## Business question

Where is the company generating profitable growth, what is creating margin risk, and how is the latest year performing against a reasonable planning baseline?

## Approach

I converted 10,194 Superstore order lines into a MySQL star schema, validated row counts and sales totals, and developed reusable SQL analyses using CTEs, window functions, conditional aggregation, views, and indexed joins. I exported the reporting views to CSV for Tableau Public because it cannot connect directly to a local MySQL database. Because the source has no budget, I created a transparent simulated budget for the latest year based on prior-year monthly actuals: 8% sales growth and a 1 percentage-point margin improvement.

## Executive findings

- 2026 sales were **$745,567.53** and profit was **$95,926.35**, producing a **12.87% margin**.
- Sales beat the simulated plan by **$82,519.30**, but profit was only **$17.42 above plan**. This indicates growth did not translate into improved profitability.
- Central missed its profit target by **$15,672.43** and South missed by **$11,281.12**. West and East offset those shortfalls.
- Furniture generated **$219,312.93** of sales but only **$3,349.24** of profit, a **1.53% margin**.
- Order lines discounted above 50% produced a combined **$27,480.63 loss**. Lines discounted 31–50% lost another **$16,418.21**.
- Approximately **6.09% of 2026 orders** were marked returned. Returned-order sales are treated as exposure because the dataset does not provide refund amounts or return dates.

## Recommendations

1. Require approval for discounts above 30%, especially in Furniture and weak regions.
2. Review product and customer combinations that generate high sales but negative profit before pursuing additional volume.
3. Assign recovery plans to Central and South regional management, using category-level profit variance as the diagnostic.
4. Add actual refund values, fulfillment cost, and budget inputs before using the model for real financial decisions.

## Forecast

The 2027 base forecast preserves the 2026 monthly Region × Category pattern, applies 6% sales growth, and improves each segment's profit margin by 0.5 percentage points. The model retains historical monthly actuals alongside the forecast so the Tableau trend clearly separates recorded results from modeled values. This is a transparent planning baseline rather than company guidance or a statistical forecast.

## Limitations

This is a synthetic portfolio analysis. The budget is explicitly simulated; the data contains profit but not a full income statement, inventory cost detail, tax, cash flow, or operating-expense accounts. The project therefore demonstrates commercial FP&A and profitability analysis rather than audited financial reporting.
