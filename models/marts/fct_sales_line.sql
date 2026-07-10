
with sales as (

    select * from {{ ref('int_sales_line') }}

),

store as (

    select * from {{ ref('dim_store') }}

),

product as (

    select * from {{ ref('dim_product') }}

)

select
    sales.item_id,
    sales.order_id,
    sales.sku,
    sales.store_id,
    store.store_name,
    sales.customer_id,
    sales.order_date,
    product.product_name,
    product.product_type,
    product.is_perishable,
    sales.revenue,
    sales.cost,
    sales.margin

from sales
left join store on sales.store_id = store.store_id
left join product on sales.sku = product.sku
