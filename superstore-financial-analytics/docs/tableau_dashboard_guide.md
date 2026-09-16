# Tableau Public build guide

Tableau Public uses three separate CSV data sources. Do not join them because they have different levels of detail.

## Data source 1: order line analysis

Connect to `tableau/tableau_order_lines.csv` as a text file. Confirm these data types:

| Field | Tableau type |
|---|---|
| `order_date`, `ship_date`, `order_month` | Date |
| `row_id`, `quantity`, `shipping_days` | Number (whole) |
| `sales`, `profit`, `discount` | Number (decimal) |
| `returned` | Boolean |
| IDs and `postal_code` | String |

The data pane should contain `Order Month` and `Shipping Days` and should not contain generic fields such as `F25`, `F26`, or `F27`. Generic `F` fields mean Tableau opened a malformed CSV, usually a Workbench result-grid export that did not quote product names containing commas. Remove that data source and connect directly to the supplied `tableau/tableau_order_lines.csv` file. Do not use a Workbench-exported file for the initial build.

Create these calculated fields:

```text
Profit Margin
SUM([Profit]) / SUM([Sales])
```

```text
Order Count
COUNTD([Order Id])
```

```text
Average Order Value
SUM([Sales]) / COUNTD([Order Id])
```

```text
Return Rate
COUNTD(IF [Returned] THEN [Order Id] END) / COUNTD([Order Id])
```

```text
Discount Band
IF [Discount] = 0 THEN "0%"
ELSEIF [Discount] <= 0.10 THEN "1–10%"
ELSEIF [Discount] <= 0.20 THEN "11–20%"
ELSEIF [Discount] <= 0.30 THEN "21–30%"
ELSEIF [Discount] <= 0.50 THEN "31–50%"
ELSE "Over 50%"
END
```

### Dashboard 1: executive performance

Create KPI sheets for Sales, Profit, Profit Margin, Order Count, and Return Rate. Add:

- Monthly Sales and Profit trend
- Profit by Region
- Profit by Category and Sub-Category
- Filters for Order Date, Region, Segment, and Category

### Dashboard 2: margin risk

Add:

- Sales versus Profit scatter plot by Sub-Category
- Profit Margin by Discount Band
- Bottom 10 products by Profit
- Returned-order sales exposure by Category
- Filters for Region, Category, Segment, and year

Describe returned sales as exposure because the source does not include refund amounts.

## Data source 2: budget variance

Add a new text-file data source using `tableau/tableau_budget_variance.csv`. Confirm `budget_month` is a Date and all actual, budget, variance, and percentage fields are decimal numbers.

### Dashboard 3: budget variance

Create KPI sheets for Actual Sales, Budget Sales, Sales Variance, Actual Profit, Budget Profit, and Profit Variance. Add:

- Monthly Sales Variance bars
- Monthly Profit Variance bars
- Profit Variance by Region
- Profit Variance by Category
- Filters for Budget Month, Region, and Category

Use `profit_status` for favorable/unfavorable color. Keep favorable green and unfavorable red.

Place this note on the dashboard:

> Portfolio assumption: budget is simulated from prior-year actuals using 8% sales growth and a 1 percentage-point margin improvement.

## Publishing

Before publishing, select **Data → [data source] → Extract Data** if Tableau asks for an extract. Tableau Public saves the data with the workbook. Do not include database credentials because these dashboards use local CSV extracts.

Use a restrained navy and gray palette. Reserve green and red for variance status. Keep each dashboard to approximately five or six views and put the main finding in the subtitle.

## Data source 3: forecast

Add a new text-file data source using `tableau/tableau_forecast.csv`. Rename the source **Forecast**. Confirm these data types:

| Field | Tableau type |
|---|---|
| `month` | Date |
| `result_type`, `region`, `category`, `forecast_method` | String |
| `source_year` | Number (whole) |
| `sales`, `profit` | Number (decimal) |
| `profit_margin`, `sales_growth_assumption`, `margin_improvement_assumption` | Number (decimal) |

Create these calculated fields:

```text
Forecast Margin
SUM([Profit]) / SUM([Sales])
```

```text
Forecast Sales KPI
SUM(IF [Result Type] = "Forecast" THEN [Sales] END)
```

```text
Forecast Profit KPI
SUM(IF [Result Type] = "Forecast" THEN [Profit] END)
```

Format Sales and Profit as currency. Format Forecast Margin and both assumption fields as percentages. Do not average the row-level `profit_margin` field when regions or categories are combined; use `SUM([Profit]) / SUM([Sales])`.

### Forecast section

Create KPI sheets for Forecast Sales, Forecast Profit, and Forecast Margin. For the margin KPI, filter `Result Type` to Forecast.

Create a monthly Sales trend:

1. Drag `Month` to Columns and choose continuous Month.
2. Drag `Sales` to Rows.
3. Drag `Result Type` to Color.
4. Set Marks to Line.
5. Use a solid navy line for Actual and a contrasting orange line for Forecast.

Duplicate the sheet and replace Sales with Profit for the monthly Profit trend.

Create Forecast Sales by Region:

1. Filter `Result Type` to Forecast.
2. Drag `Region` to Rows and `Sales` to Columns.
3. Use bars, show currency labels, and sort descending.

Create Forecast Margin by Category:

1. Filter `Result Type` to Forecast.
2. Drag `Category` to Rows and `Forecast Margin` to Columns.
3. Use bars, show percentage labels, and sort descending.

Add Region and Category filters and apply them only to worksheets using the Forecast data source. Keep `Result Type` as an internal sheet filter where needed rather than a prominent dashboard control.

Place this note beside the forecast charts:

> 2027 base forecast uses 2026 monthly seasonality, 6% sales growth, and a 0.5 percentage-point improvement in profit margin. This is a planning assumption, not company guidance.

Arrange the three KPIs across the top, the Sales and Profit trend charts in the middle, and the Region and Category forecast bars beneath them. This can be a fourth dashboard named **Forecast outlook** or a clearly separated forecast section beneath the budget-variance dashboard.

## Replacing an incorrect extract

If a Workbench-exported file is already connected:

1. Select **Data → New Data Source → Text File**.
2. Open the supplied `tableau/tableau_order_lines.csv` from this project.
3. If worksheets already exist, select **Data → Replace Data Source** and replace the old source with the new one.
4. Right-click the old data source and select **Close**.
5. Confirm that `Order Month` and `Shipping Days` appear and the generic `F25`–`F28` fields are gone.

For later SQL exports, configure Workbench to include column names and quote text fields. Product names contain commas, so an unquoted export will be split into extra columns by Tableau.
