# University Workshop — Store Growth Readiness Scorecard

A dbt project on BigQuery, built from the Jaffle Shop seed data, answering:

> **Which stores are genuinely positioned to keep growing, and what's quietly holding the others back?**

## Analytics question

**Primary question:** Which stores are positioned to keep growing, and what's holding the others back?

**Supporting signals combined into one scorecard:**

| Signal | What it measures | Risk it flags |
|---|---|---|
| Growth trajectory | Weekly revenue trend by weeks-since-opening | Growth has stalled |
| Revenue concentration | % of store revenue from its top-decile orders | Growth is fragile — over-reliant on a few big baskets |
| Price sensitivity | Whether higher-priced SKUs sell fewer units within their product type | Pricing/margin upside being left on the table |
| Perishable exposure | % of store revenue tied to slow-moving, thin-margin perishable products | Growth being eaten by wasted/slow inventory |

Each signal is normalized and combined into a single `growth_readiness_score` (0–1) per store.

## A known limitation of the data (read this before the scores)

All 686 orders in this seed dataset belong to a single store — **Philadelphia** —
spanning just 16 days. The other 5 stores have zero orders. This is a
limitation of the seed data, not of the model: every model was built and
tested to work across any number of stores, and stores with no order data
correctly return `null` scores rather than a misleading `0`. The scorecard
below reflects what the framework produces for the one store we do have
data on.

## Key insight (Philadelphia — the only store with data)

**Overall growth readiness score: 0.53**

The standout finding: **47% of Philadelphia's revenue is tied to underpriced
strong sellers.** `BEV-004`, priced at $7, consistently outsells cheaper
beverages in its category — a clear signal of under-pricing rather than low
demand.

**Next step:** Run a controlled price test on `BEV-004` (and similarly
positioned SKUs) — a modest price increase is unlikely to meaningfully dent
volume given current sell-through, and represents low-risk, high-confidence
margin upside.

## Project structure

```
models/
  staging/        stg_jaffle_shop__*.sql        — 1:1 with raw source tables
  intermediate/   int_product_cost.sql
                  int_sales_line.sql             — base fact: one row per item sold
                  int_store_growth.sql
                  int_store_revenue_concentration.sql
                  int_price_sensitivity.sql
                  int_perishable_exposure.sql
  marts/          dim_store.sql
                  dim_product.sql
                  fct_sales_line.sql
                  fct_store_scorecard.sql        — final payoff model
```

`intermediate/` holds single-purpose calculation steps that only exist to
feed something else downstream. `marts/` holds the final, business-facing
models — `fct_store_scorecard` is the one that answers the primary question.

All thresholds (percentiles, medians, score normalization bounds) are
computed dynamically from the data using SQL window/aggregate functions —
nothing is hardcoded, so the model stays correct as more data lands.

## Testing

- `unique` + `not_null` on the primary keys of `dim_store`, `dim_product`,
  and `fct_sales_line`
- Business-logic test on `fct_store_scorecard`: `growth_readiness_score` must
  fall between 0 and 1
- **A test caught a real modeling bug during development:** the fact table's
  grain was initially assumed to be `(order_id, sku)`. A uniqueness test on
  that combination failed — 41 orders legitimately contain 2+ units of the
  same SKU. The fix was to carry `item_id` through as the true primary key.
  This is a good example of tests doing their job, not just being present.

`dbt build` passes 35/35.

## How to run

```bash
dbt deps
dbt seed
dbt build
```

## Process notes

This project also went through a structured 8-angle code review
(correctness, cleanup, altitude, and conventions) after the initial build,
which surfaced 10 findings. The most significant — `int_store_revenue_concentration`
mixing tax-inclusive and tax-exclusive revenue across signals — was fixed.
See `docs/session_summary.md` for the full list of findings, including any
left unfixed and why.
