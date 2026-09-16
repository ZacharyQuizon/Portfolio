"""Prepare Tableau Superstore data for the MySQL portfolio project.

Run with the bundled or system Python after installing pandas and xlrd:
    python tools/prepare_data.py path/to/sample_-_superstore.xls
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

import pandas as pd


def snake_case(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def main() -> None:
    source = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(r"D:\Downloads\sample_-_superstore.xls")
    project = Path(__file__).resolve().parents[1]
    data_dir = project / "data"
    data_dir.mkdir(parents=True, exist_ok=True)

    orders = pd.read_excel(source, sheet_name="Orders")
    people = pd.read_excel(source, sheet_name="People")
    returns = pd.read_excel(source, sheet_name="Returns")

    for frame in (orders, people, returns):
        frame.columns = [snake_case(column) for column in frame.columns]

    for column in ("order_date", "ship_date"):
        orders[column] = pd.to_datetime(orders[column]).dt.strftime("%Y-%m-%d")

    orders["postal_code"] = (
        orders["postal_code"].astype("string").str.replace(r"\.0$", "", regex=True).fillna("")
    )
    orders.to_csv(data_dir / "orders.csv", index=False, encoding="utf-8")
    people.to_csv(data_dir / "people.csv", index=False, encoding="utf-8")
    returns.to_csv(data_dir / "returns.csv", index=False, encoding="utf-8")

    dated = orders.assign(order_date_dt=pd.to_datetime(orders["order_date"]))
    last_year = int(dated["order_date_dt"].dt.year.max())
    prior_year = last_year - 1
    prior = dated[dated["order_date_dt"].dt.year.eq(prior_year)].copy()
    prior["budget_month"] = (
        (prior["order_date_dt"] + pd.DateOffset(years=1)).dt.to_period("M").dt.to_timestamp()
    )

    budget = (
        prior.groupby(["budget_month", "region", "category"], as_index=False)
        .agg(prior_sales=("sales", "sum"), prior_profit=("profit", "sum"))
    )
    budget["budget_sales"] = (budget["prior_sales"] * 1.08).round(2)
    prior_margin = budget["prior_profit"].div(budget["prior_sales"]).fillna(0)
    budget["budget_profit"] = (budget["budget_sales"] * (prior_margin + 0.01)).round(2)
    budget["budget_method"] = "Prior-year actual + 8% sales growth; prior margin + 1 percentage point"
    budget["budget_month"] = budget["budget_month"].dt.strftime("%Y-%m-01")
    budget[["budget_month", "region", "category", "budget_sales", "budget_profit", "budget_method"]].to_csv(
        data_dir / "simulated_budget.csv", index=False, encoding="utf-8"
    )

    tableau_dir = project / "tableau"
    tableau_dir.mkdir(parents=True, exist_ok=True)

    tableau_orders = orders.merge(
        returns.assign(returned=True)[["order_id", "returned"]], on="order_id", how="left"
    ).merge(people, on="region", how="left")
    tableau_orders["returned"] = tableau_orders["returned"].fillna(False).astype(bool)
    tableau_orders["order_month"] = pd.to_datetime(tableau_orders["order_date"]).dt.strftime("%Y-%m-01")
    tableau_orders["shipping_days"] = (
        pd.to_datetime(tableau_orders["ship_date"]) - pd.to_datetime(tableau_orders["order_date"])
    ).dt.days
    tableau_orders.to_csv(tableau_dir / "tableau_order_lines.csv", index=False, encoding="utf-8")

    actual = dated.copy()
    actual["budget_month"] = actual["order_date_dt"].dt.to_period("M").dt.to_timestamp().dt.strftime("%Y-%m-01")
    actual = actual.groupby(["budget_month", "region", "category"], as_index=False).agg(
        actual_sales=("sales", "sum"), actual_profit=("profit", "sum")
    )
    tableau_budget = budget[[
        "budget_month", "region", "category", "budget_sales", "budget_profit", "budget_method"
    ]].merge(actual, on=["budget_month", "region", "category"], how="left")
    tableau_budget[["actual_sales", "actual_profit"]] = tableau_budget[["actual_sales", "actual_profit"]].fillna(0)
    tableau_budget["sales_variance"] = tableau_budget["actual_sales"] - tableau_budget["budget_sales"]
    tableau_budget["profit_variance"] = tableau_budget["actual_profit"] - tableau_budget["budget_profit"]
    tableau_budget["sales_variance_pct"] = tableau_budget["sales_variance"].div(
        tableau_budget["budget_sales"].replace(0, pd.NA)
    )
    tableau_budget["profit_variance_pct"] = tableau_budget["profit_variance"].div(
        tableau_budget["budget_profit"].replace(0, pd.NA)
    )
    tableau_budget["profit_status"] = tableau_budget["profit_variance"].ge(0).map(
        {True: "Favorable", False: "Unfavorable"}
    )
    tableau_budget.to_csv(tableau_dir / "tableau_budget_variance.csv", index=False, encoding="utf-8")

    monthly_actual = orders.assign(
        month=pd.to_datetime(orders["order_date"]).dt.to_period("M").dt.to_timestamp()
    ).groupby(["month", "region", "category"], as_index=False).agg(
        sales=("sales", "sum"), profit=("profit", "sum")
    )
    monthly_actual["result_type"] = "Actual"
    monthly_actual["profit_margin"] = monthly_actual["profit"].div(monthly_actual["sales"])
    monthly_actual["source_year"] = monthly_actual["month"].dt.year
    monthly_actual["sales_growth_assumption"] = pd.NA
    monthly_actual["margin_improvement_assumption"] = pd.NA
    monthly_actual["forecast_method"] = "Source actual"
    forecast = monthly_actual[monthly_actual["source_year"].eq(last_year)][
        ["month", "region", "category", "sales", "profit", "profit_margin", "source_year"]
    ].copy()
    forecast["month"] = forecast["month"] + pd.DateOffset(years=1)
    forecast["result_type"] = "Forecast"
    forecast["sales_growth_assumption"] = 0.06
    forecast["margin_improvement_assumption"] = 0.005
    forecast["sales"] = forecast["sales"] * 1.06
    forecast["profit_margin"] = forecast["profit_margin"] + 0.005
    forecast["profit"] = forecast["sales"] * forecast["profit_margin"]
    forecast["forecast_method"] = "Prior-year monthly actual; 6% sales growth; margin +0.5 percentage points"
    tableau_forecast = pd.concat([monthly_actual, forecast], ignore_index=True)
    tableau_forecast["month"] = tableau_forecast["month"].dt.strftime("%Y-%m-01")
    tableau_forecast.to_csv(tableau_dir / "tableau_forecast.csv", index=False, encoding="utf-8")

    print(
        f"Prepared {len(orders):,} order lines and three Tableau Public extracts; "
        f"actual-vs-budget comparison year: {last_year}."
    )


if __name__ == "__main__":
    main()
