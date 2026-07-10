
select
    sku,
    product_name,
    product_type,
    product_price,
    supply_cost,
    margin,
    margin_pct,
    is_perishable

from {{ ref('int_product_cost') }}
