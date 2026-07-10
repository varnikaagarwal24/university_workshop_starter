
with sales as (

    select * from {{ ref('int_sales_line') }}

),

order_totals as (

    select
        store_id,
        order_id,
        sum(revenue) as order_revenue

    from sales
    group by store_id, order_id

),

ranked as (

    select
        store_id,
        order_id,
        order_revenue,
        row_number() over (partition by store_id order by order_revenue desc) as revenue_rank,
        count(*) over (partition by store_id) as order_count

    from order_totals

),

flagged as (

    select
        store_id,
        order_id,
        order_revenue,
        revenue_rank <= greatest(ceil(order_count * 0.10), 1) as is_top_decile

    from ranked

),

store_totals as (

    select
        store_id,
        sum(order_revenue) as total_revenue,
        sum(case when is_top_decile then order_revenue else 0 end) as top_decile_revenue

    from flagged
    group by store_id

)

select
    store_id,
    total_revenue,
    top_decile_revenue,
    round(safe_divide(top_decile_revenue, total_revenue), 4) as revenue_concentration_pct

from store_totals
