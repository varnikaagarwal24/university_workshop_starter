
with stores as (

    select * from {{ ref('dim_store') }}

),

growth as (

    select distinct
        store_id,
        trend_classification

    from {{ ref('int_store_growth') }}

),

concentration as (

    select * from {{ ref('int_store_revenue_concentration') }}

),

perishable as (

    select * from {{ ref('int_perishable_exposure') }}

),

pricing_rollup as (

    select
        sales.store_id,
        sum(sales.revenue) as total_revenue,
        sum(case when price.pricing_opportunity_flag then sales.revenue else 0 end) as pricing_opportunity_revenue

    from {{ ref('int_sales_line') }} sales
    inner join {{ ref('int_price_sensitivity') }} price on sales.sku = price.sku
    group by sales.store_id

),

pricing as (

    select
        store_id,
        round(safe_divide(pricing_opportunity_revenue, total_revenue), 4) as pricing_opportunity_exposure_pct

    from pricing_rollup

),

combined as (

    select
        stores.store_id,
        stores.store_name,
        stores.opened_at,
        growth.trend_classification,
        concentration.revenue_concentration_pct,
        pricing.pricing_opportunity_exposure_pct,
        perishable.perishable_exposure_pct

    from stores
    left join growth on stores.store_id = growth.store_id
    left join concentration on stores.store_id = concentration.store_id
    left join pricing on stores.store_id = pricing.store_id
    left join perishable on stores.store_id = perishable.store_id

),

scored as (

    select
        store_id,
        store_name,
        opened_at,
        trend_classification,
        case trend_classification
            when 'growing' then 1.0
            when 'plateaued' then 0.5
            when 'declining' then 0.0
            else null
        end as growth_score,
        revenue_concentration_pct,
        round(1 - revenue_concentration_pct, 4) as concentration_score,
        pricing_opportunity_exposure_pct,
        round(1 - pricing_opportunity_exposure_pct, 4) as pricing_score,
        perishable_exposure_pct,
        round(1 - perishable_exposure_pct, 4) as perishable_score

    from combined

)

select
    store_id,
    store_name,
    opened_at,
    trend_classification,
    growth_score,
    revenue_concentration_pct,
    concentration_score,
    pricing_opportunity_exposure_pct,
    pricing_score,
    perishable_exposure_pct,
    perishable_score,
    round((growth_score + concentration_score + pricing_score + perishable_score) / 4, 4) as growth_readiness_score

from scored
