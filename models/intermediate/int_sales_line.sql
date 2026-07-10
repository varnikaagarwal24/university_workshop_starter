
with items as (

    select * from {{ ref('stg_items') }}

),

orders as (

    select * from {{ ref('stg_order') }}

),

product_cost as (

    select * from {{ ref('int_product_cost') }}

)

select
    items.item_id,
    orders.order_id,
    items.sku,
    orders.store_id,
    orders.customer_id,
    orders.order_date,
    product_cost.product_price as revenue,
    product_cost.supply_cost as cost,
    product_cost.margin as margin

from items
inner join orders on items.order_id = orders.order_id
inner join product_cost on items.sku = product_cost.sku
