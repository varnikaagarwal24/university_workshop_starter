
with product as (

    select * from {{ ref('stg_product') }}

),

supply as (

    select * from {{ ref('stg_supply') }}

),

supply_agg as (

    select
        sku,
        sum(supply_cost) as supply_cost,
        logical_or(is_perishable) as is_perishable

    from supply
    group by sku

)

select
    product.sku,
    product.product_name,
    product.product_type,
    product.product_price,
    coalesce(supply_agg.supply_cost, 0) as supply_cost,
    coalesce(supply_agg.is_perishable, false) as is_perishable,
    product.product_price - coalesce(supply_agg.supply_cost, 0) as margin,
    round(safe_divide(product.product_price - coalesce(supply_agg.supply_cost, 0), product.product_price), 4) as margin_pct

from product
left join supply_agg on product.sku = supply_agg.sku
