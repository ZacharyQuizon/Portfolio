"""Build Tableau Public extracts from the validated staging CSV files."""

from pathlib import Path

import pandas as pd


def main() -> None:
    project = Path(__file__).resolve().parents[1]
    data_dir = project / "data"
    tableau_dir = project / "tableau"
    tableau_dir.mkdir(parents=True, exist_ok=True)

    orders = pd.read_csv(data_dir / "orders.csv", dtype={"postal_code": "string"})
    people = pd.read_csv(data_dir / "people.csv")
    returns = pd.read_csv(data_dir / "returns.csv")
    budget = pd.read_csv(data_dir / "simulated_budget.csv")

    tableau_orders = orders.merge(
        returns.assign(returned=True)[["order_id", "returned"]], on="order_id", how="left"
    ).merge(people, on="region", how="left")
    tableau_orders["returned"] = tableau_orders["returned"].fillna(False).astype(bool)
    order_dates = pd.to_datetime(tableau_orders["order_date"])
    tableau_orders["order_month"] = order_dates.dt.to_period("M").dt.to_timestamp().dt.strftime("%Y-%m-01")
    tableau_orders["shipping_days"] = (
        pd.to_datetime(tableau_orders["ship_date"]) - order_dates
    ).dt.days
    tableau_orders.to_csv(tableau_dir / "tableau_order_lines.csv", index=False, encoding="utf-8")

    actual = orders.assign(
        budget_month=pd.to_datetime(orders["order_date"]).dt.to_period("M").dt.to_timestamp().dt.strftime("%Y-%m-01")
    ).groupby(["budget_month", "region", "category"], as_index=False).agg(
        actual_sales=("sales", "sum"), actual_profit=("profit", "sum")
    )
    tableau_budget = budget.merge(actual, on=["budget_month", "region", "category"], how="left")
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

    latest_year = int(monthly_actual["source_year"].max())
    forecast = monthly_actual[monthly_actual["source_year"].eq(latest_year)][
        ["month", "region", "category", "sales", "profit", "profit_margin", "source_year"]
    ].copy()
    forecast["month"] = forecast["month"] + pd.DateOffset(years=1)
    forecast["result_type"] = "Forecast"
    forecast["sales_growth_assumption"] = 0.06
    forecast["margin_improvement_assumption"] = 0.005
    forecast["sales"] = forecast["sales"] * (1 + forecast["sales_growth_assumption"])
    forecast["profit_margin"] = forecast["profit_margin"] + forecast["margin_improvement_assumption"]
    forecast["profit"] = forecast["sales"] * forecast["profit_margin"]
    forecast["forecast_method"] = "Prior-year monthly actual; 6% sales growth; margin +0.5 percentage points"

    tableau_forecast = pd.concat([monthly_actual, forecast], ignore_index=True)
    tableau_forecast["month"] = tableau_forecast["month"].dt.strftime("%Y-%m-01")
    tableau_forecast[["sales", "profit", "profit_margin"]] = tableau_forecast[
        ["sales", "profit", "profit_margin"]
    ].round(6)
    tableau_forecast.to_csv(tableau_dir / "tableau_forecast.csv", index=False, encoding="utf-8")

    print(
        f"Created {len(tableau_orders):,} order-line rows, {len(tableau_budget):,} variance rows, "
        f"and {len(tableau_forecast):,} actual/forecast rows."
    )


if __name__ == "__main__":
    main()
