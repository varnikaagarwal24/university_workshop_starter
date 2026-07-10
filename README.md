# University Workshop Starter
This repository is a **starting point** for an end-to-end analytics engineering project in dbt as experienced in a dbt Labs University Workshop. This repo uses the legendary [Jaffle Shop](https://github.com/dbt-labs/jaffle-shop) project for its curated sample data, but with a much smaller scope: **only seeds** are included so you can get started easily. Your job in the workshop will be to design and build your own staging layer (guided) and then the intermediate and mart layer (independently) to ultimately answer specified analytics/business question(s).

## What you’re building
By the end of the workshop, you should have:
- A specific, relevant analytics question (or small set) stated up front; perhaps opting for 1 primary, 2–4 supporting questions
- A dbt project that runs end-to-end on **BigQuery**
- At least one **`dim_*`** and/or **`fct_*`** model that clearly answers the stated question(s)
- 2–4 tests (at minimum `not_null` and `unique` on primary keys, plus one business-logic test)
- Descriptions for key models and columns so someone new can easily follow the work
- A short write-up in the README, or elsewhere in the repo, with at least one insight stated and supported by data evidence and at least one realistic next step that follows from the insight(s)

---

## Prerequisites
- BigQuery project + dataset you can write to
- dbt (Fusion + VS Code extension) installed and working
- Git installed and a GitHub account
- A working BigQuery connection configured in `profiles.yml`

If needed, detailed setup instructions can be found [here](https://docs.google.com/document/d/1_9MhrFGBjv0MShmynGwTzi2aHLPFDkD7ZTcCxj-iyag/edit?usp=sharing)

---

## Quickstart

### 1) Fork this repo
Follow [these instructions](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo#forking-a-repository) to create your own fork/version of this repo.

Optionally, [sync your forked repo](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo#configuring-git-to-sync-your-fork-with-the-upstream-repository) to the main upstream starter repo so you can pull any changes to it later.

### 2) Clone that repo locally using VS Code
Follow [these instructions](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/fork-a-repo#cloning-your-forked-repository) to clone your forked repo for local development in VS Code.
```
git clone <YOUR_REPO_URL>
cd <YOUR_REPO_NAME>
```

### 3) Confirm your dbt profile name matches `dbt_project.yml` (important)
This project’s `dbt_project.yml` includes a `profile:` value (for example, `default`). **That value must match the profile name you have configured for BigQuery dev credentials in your `profiles.yml`.**

- If your `dbt_project.yml` says `profile: default`, then your `profiles.yml` must have a top-level profile named `default:`. In this starter repo, the `dbt_project.yml` says `profile: university_workshop`, so make sure you have a top-level profile named `university_workshop` in your `profiles.yml` file.

Typical locations:
- In the hidden `.dbt` folder: `~/.dbt/profiles.yml`
- If you are using a repo-local profile (optional): `./profiles.yml`, make sure it is gitignored, otherwise your credentials will be made public!

If the names do not match, dbt will fail with a “profile not found” style error.

### 4) Seed the curated source data (raw layer)
This starter uses dbt **seeds** as the “raw” tables for the project.

Run: `dbt seed`

---

## Project structure
You have:
- `seeds/`  
  Curated CSVs that dbt loads into your warehouse (commonly into a `raw` schema or dataset).

You do **not** have staging or marts models in this repo. You will create the staging layer in the guided portion of the workshop and the marts layer based on the question(s) you have chosen to answer.

### Recommended build-out

#### Staging (`models/staging/`)

Create `stg_*` models that:

- rename fields consistently (`customer` → `customer_id`, `type` → `product_type`, etc.)
- cast types (BigQuery: `CAST(...)` / `SAFE_CAST(...)`)
- standardize timestamps/dates

Example BigQuery casts:

```
SAFE_CAST(price AS NUMERIC) AS price,
TIMESTAMP(ordered_at) AS ordered_at
```

To guide you through the staging layer build, you can follow [these instructions](https://docs.google.com/document/d/1Gy0f35WMmFM0Sh8kWpfQ1nSeFnmhWrFatISbTA3B534/edit?usp=sharing).

#### Intermediate (`models/intermediate/`)

Reusable joins / business logic:

- `int_sales_enriched`: items + orders + products + stores (+ supplies)
- `int_customer_orders`: customer order history + sequencing
- `int_item_finance`: item-level revenue/cost/margin fields

#### Marts (`models/marts/`)

Final models that answer your question(s):

- `dim_*` for entities (customer, product, store, date)
- `fct_*` for measurable events (order, sale line, daily rollups)

---

## BigQuery notes (common gotchas)
- Make sure your BigQuery credential (typically the locally saved JSON file) has permission to:
  - create tables/views
  - create and write to datasets
  It is easiest to just give the service account `Owner` permissions
- Be explicit about your target dataset (schema) in `profiles.yml` so you can easily find your outputs.
- If you switch GCP projects or datasets, rerun `dbt debug` to confirm everything is wired correctly.

Useful commands:
```
dbt debug
dbt parse
dbt compile
dbt ls
```

---

## Suggested workflow (ADLC)
1. **Plan**
   - Write questions, entities, grain, and expected outputs
   - You can place these in a top-level `plan.md` file in your project
2. **Develop**
   - Add staging, marts (and, optionally, intermediate) models with clear naming and layering
3. **Test**
   - Add tests early, document columns and models whilst you're in the YAML files
4. **Deploy**
   - Ensure everything builds end-to-end locally and push changes to `main`
5. **Operate (optional for workshop)**
   - Schedule your project to run via a job (optionally, schedule it) on dbt Platform
6. **Observe**
   - Check lineage and data quality signals via test results
7. **Discover**
   - Add any additional useful descriptions and documentation to the project, models, and columns.
8. **Analyze**
   - Query your marts (or build an output artifact) and write 1–2 insights plus next steps

---

## Suggested analytics questions (if you're struggling to create your own)

Pick **1 primary question** and **2–4 supporting questions**. Then build:

- `models/staging/` → clean + standardize seeded raw tables
- `models/intermediate/` → reusable joins + business logic (`int_*`)
- `models/marts/` → business-facing outputs (`dim_*`, `fct_*`) that answer the question(s)

**Seeded raw tables:**

- `raw_customers(id, name)`
- `raw_orders(id, customer, ordered_at, store_id, subtotal, tax_paid, order_total)`
- `raw_items(id, order_id, sku)`
- `raw_products(sku, name, type, price, description)`
- `raw_stores(id, name, opened_at, tax_rate)`
- `raw_supplies(id, name, cost, perishable, sku)`

### Join map

- `raw_orders.customer` → `raw_customers.id`
- `raw_orders.store_id` → `raw_stores.id`
- `raw_items.order_id` → `raw_orders.id`
- `raw_items.sku` → `raw_products.sku`
- `raw_supplies.sku` → `raw_products.sku` (and to `raw_items.sku`)

## Option A: Profitability — Which products and stores are most profitable?

**Primary question:** Which products (and stores) drive the most profit?

**Supporting questions:**

- Which **product types** have the highest **gross margin** and **margin %**?
- Which **stores** drive the most **profit** vs the most **revenue** (not always the same)?
- How much profit comes from **perishable** vs **non-perishable** products?

**Suggested marts:**

- `dim_product` (SKU-level attributes, including cost/perishable)
- `dim_store`
- `fct_sales_line` (one row per sold item) **or** `fct_product_profit_daily` (aggregated)

**Implementation hint:** `raw_items` is line-level but doesn’t include quantity. A simple, consistent approach is to treat **each row in `raw_items` as 1 unit sold** and use `raw_products.price` as revenue per unit and `raw_supplies.cost` as cost per unit.

## Option B: Product performance — What are customers buying, and how does mix vary by store over time?

**Primary question:** What products sell best, and how does the product mix differ by store and over time?

**Supporting questions:**

- What are the **top SKUs** and **top product types** by **units sold** and **revenue**?
- Do stores have distinct “bestsellers” (store-specific product mix)?
- How does product mix change over time (`ordered_at`)?

**Suggested marts:**

- `dim_product`, `dim_store` (and optionally `dim_date`)
- `fct_product_sales_daily` (grain: `order_date + sku (+ store_id)`)

## Option C: Customers — Who are repeat customers and what do they buy?

**Primary question:** Who are our repeat customers, and what patterns predict repeat purchasing?

**Supporting questions:**

- What % of customers are **one-time vs repeat** purchasers?
- What is **time-to-second-order** for repeat customers?
- Do repeat customers prefer certain **product types** (and do they have higher order totals)?

**Suggested marts:**

- `dim_customer`
- `fct_orders` (order grain, enriched with customer + store)
- `dim_customer_summary` (customer grain: order_count, repeat_flag, days_to_second_order, total_spend)

---

## My analytics project: Store Growth Readiness Scorecard

**Primary question:** Which stores are genuinely positioned to keep growing, and what's quietly holding the others back?

### Model summary

Built the standard staging → intermediate → marts layering on top of the seeds:

- `models/staging/` — one `stg_*` model per raw seed table (unchanged from the guided portion).
- `models/intermediate/` — `int_product_cost` (supply cost/margin rollup by sku), `int_sales_line` (grain: 1 row per item sold — the base fact everything else rolls up from), `int_store_growth` (weekly revenue + trend by store), `int_store_revenue_concentration` (top-decile-order revenue share), `int_price_sensitivity` (price vs. units-sold rank within product_type), `int_perishable_exposure` (revenue tied to slow, thin-margin perishables).
- `models/marts/` — `dim_store`, `dim_product`, `fct_sales_line`, and the payoff model `fct_store_scorecard`: one row per store combining all four signals, each normalized to 0–1, into a composite `growth_readiness_score`.
- Tests: `unique`/`not_null` on all primary keys and the `fct_sales_line` grain, plus `dbt_utils.accepted_range(0, 1)` on `growth_readiness_score`.

**Data limitation (important):** the seed data in this repo is a stripped-down slice of Jaffle Shop — all 686 orders belong to a single store (Philadelphia), spanning just 16 days (2016-09-01 to 2016-09-16). The other 5 stores have zero orders. So the scorecard is fully built and runs correctly for all 6 stores, but only Philadelphia has real signal — the other 5 correctly return `growth_readiness_score = null` (no sales to compute anything from) rather than a misleading 0.

### The insight (with real numbers)

Philadelphia's `growth_readiness_score` comes out to **0.53** — a moderate, mixed profile, not the "obviously fragile" or "obviously healthy" extreme:

- **Growth trajectory**: classified `declining` (`growth_score = 0.0`) — weekly revenue was $3,031 → $3,123 → $664. But that last data point is a **partial week** (the seed data cuts off mid-week, on day 16), not a real slowdown — so this component is likely an artifact of the data window, not a genuine trend, and should be discounted.
- **Revenue concentration**: `32.85%` of revenue comes from the top decile of orders (`concentration_score = 0.67`) — moderate, not alarming.
- **Perishable exposure**: only `8.01%` of revenue ($546 of $6,818) is tied to slow-moving, thin-margin perishables (`perishable_score = 0.92`) — low risk. (Caveat: every one of the 10 SKUs in this seed dataset has at least one perishable supply component, so this signal is really being driven by the velocity/margin filters, not by perishability itself — worth re-checking against a fuller product catalog.)
- **Pricing opportunity — the real finding**: `46.91%` of revenue is tied to SKUs that show untapped pricing power (`pricing_score = 0.53`). Concretely: **`BEV-004` ("for richer or pourover") is priced at $7 — the most expensive of the 5 beverages — yet it's also the single best-selling beverage at 168 units sold**, ahead of the $5 option (`BEV-002`, 158 units) and the $6 option (`BEV-001`, 154 units). The same pattern shows up in jaffles: `JAF-004` ($14, the priciest jaffle) is the #2 seller by units, and `JAF-003` ($12) is the #1 seller despite not being the cheapest. Demand isn't dropping at the top of the price band — that's evidence of room to raise price further without losing volume.

**Bottom line:** Philadelphia's growth looks middling on paper, but the weak spot isn't fragility or wasted inventory — it's underpricing. Roughly half its revenue runs through products that could plausibly support a higher price with no observed volume penalty.

### Next step

Run a controlled price test on `BEV-004`: raise it ~10–15% (e.g. $7 → $8) for a 2–4 week window and monitor whether unit sales hold relative to the cheaper beverages. If volume doesn't drop, extend the same test to `JAF-003`/`JAF-004` and treat the pattern as a repeatable pricing-power signal to check for future menu items and other stores once they have order volume.

---

## Workshop requirements checklist (use this to self-review)
- [ ] Defined primary + supporting analytics questions
- [ ] Built at least one `dim_*` and/or `fct_*` model
- [ ] Added schema tests for keys (unique, not_null)
- [ ] Added at least one “business logic” test (accepted values, or custom test)
- [ ] Added descriptions to key models and columns
- [ ] Ran `dbt build` successfully with a clean output
- [ ] README (or a file elsewhere in the repo) includes: At least one insight stated and supported by data evidence (numbers, comparison, trend, segment, etc.) and at least one realistic next step that follows from the insight(s)

---

## Workshop deliverables
At the end of the workshop you will:
- Have a link to your GitHub repo
- Present what you have done covering the items in the `Workshop requirements checklist` above
- Bonus: You may choose to also produce a dashboard (can be screenshots), SQL queries in BigQuery, or a Python notebook that tells the story.
