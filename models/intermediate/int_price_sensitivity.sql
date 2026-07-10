
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
        product_cost.product_type,
        product_cost.product_price,
        coalesce(units_sold.units_sold, 0) as units_sold

    from product_cost
    left join units_sold on product_cost.sku = units_sold.sku

),

ranked as (

    select
        sku,
        product_type,
        product_price,
        units_sold,
        rank() over (partition by product_type order by product_price desc) as price_rank_in_type,
        rank() over (partition by product_type order by units_sold desc) as units_sold_rank_in_type,
        count(*) over (partition by product_type) as products_in_type

    from sku_stats

)

select
    sku,
    product_type,
    product_price,
    units_sold,
    price_rank_in_type,
    units_sold_rank_in_type,
    products_in_type,
    (price_rank_in_type <= ceil(products_in_type / 2.0)
        and units_sold_rank_in_type <= ceil(products_in_type / 2.0)) as pricing_opportunity_flag

from ranked
