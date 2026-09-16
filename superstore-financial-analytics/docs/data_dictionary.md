# Data dictionary

| Table/view | Grain | Purpose |
|---|---|---|
| `fact_order_line` | One product line on an order | Sales, quantity, discount, and profit analysis |
| `dim_customer` | One customer | Customer and segment analysis |
| `dim_product` | One product | Category, sub-category, and product analysis |
| `dim_geography` | One unique location | Region and geographic analysis |
| `fact_return` | One returned order | Returned-order exposure analysis |
| `fact_budget` | Month × region × category | Simulated budget-versus-actual analysis |
| `vw_tableau_order_lines` | One product line on an order | Tableau-ready denormalized view |
| `vw_tableau_budget_variance` | Month × region × category | Tableau-ready variance view |
| `tableau_order_lines.csv` | One product line on an order | Tableau Public extract mirroring the order-line view |
| `tableau_budget_variance.csv` | Month × region × category | Tableau Public extract mirroring the variance view |
| `vw_tableau_forecast` | Month × result type × region × category | Historical actuals and the 12-month base forecast |
| `tableau_forecast.csv` | Month × result type × region × category | Tableau Public extract for forecast reporting |

`Sales` is gross sales in the source data. `Profit` is source-provided profit. `Discount` is expressed as a decimal from 0 to 1. A return is identified only at order level; returned sales are therefore described as **exposure**, not confirmed revenue loss.
