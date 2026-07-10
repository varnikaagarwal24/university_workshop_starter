
with sales as (

    select * from {{ ref('int_sales_line') }}

),

product_cost as (

    select * from {{ ref('int_product_cost') }}

),

units_sold as (

    select
        sku,
        count(*) as units_sold

    from sales
    group by sku

),

sku_stats as (

    select
        product_cost.sku,
        product_cost.is_perishable,
        product_cost.margin_pct,
        coalesce(units_sold.units_sold, 0) as units_sold

    from product_cost
    left join units_sold on product_cost.sku = units_sold.sku

),

medians as (

    select
        approx_quantiles(units_sold, 2)[offset(1)] as median_units_sold,
        approx_quantiles(margin_pct, 2)[offset(1)] as median_margin_pct

    from sku_stats

),

flagged_skus as (

    select
        sku_stats.sku,
        (sku_stats.is_perishable
            and sku_stats.units_sold < medians.median_units_sold
            and sku_stats.margin_pct < medians.median_margin_pct) as is_slow_thin_perishable

    from sku_stats
    cross join medians

),

store_revenue as (

    select
        sales.store_id,
        sum(sales.revenue) as total_revenue,
        sum(case when flagged_skus.is_slow_thin_perishable then sales.revenue else 0 end) as exposed_revenue

    from sales
    inner join flagged_skus on sales.sku = flagged_skus.sku
    group by sales.store_id

)

select
    store_id,
    total_revenue,
    exposed_revenue,
    round(safe_divide(exposed_revenue, total_revenue), 4) as perishable_exposure_pct

from store_revenue
