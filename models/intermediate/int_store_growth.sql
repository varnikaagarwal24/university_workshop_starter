
with sales as (

    select * from {{ ref('int_sales_line') }}

),

stores as (

    select * from {{ ref('stg_store') }}

),

sales_with_week as (

    select
        sales.store_id,
        cast(floor(date_diff(sales.order_date, date(stores.opened_at), day) / 7) as int64) as week_number_since_opening,
        sales.revenue

    from sales
    inner join stores on sales.store_id = stores.store_id

),

weekly_revenue as (

    select
        store_id,
        week_number_since_opening,
        sum(revenue) as weekly_revenue

    from sales_with_week
    group by store_id, week_number_since_opening

),

store_week_bounds as (

    select
        store_id,
        max(week_number_since_opening) as max_week

    from weekly_revenue
    group by store_id

),

store_period_avgs as (

    select
        weekly_revenue.store_id,
        avg(case when weekly_revenue.week_number_since_opening <= store_week_bounds.max_week / 2
            then weekly_revenue.weekly_revenue end) as early_avg_revenue,
        avg(case when weekly_revenue.week_number_since_opening > store_week_bounds.max_week / 2
            then weekly_revenue.weekly_revenue end) as recent_avg_revenue

    from weekly_revenue
    inner join store_week_bounds on weekly_revenue.store_id = store_week_bounds.store_id
    group by weekly_revenue.store_id

),

trend as (

    select
        store_id,
        early_avg_revenue,
        recent_avg_revenue,
        case
            when early_avg_revenue is null or recent_avg_revenue is null then 'insufficient_data'
            when recent_avg_revenue > early_avg_revenue * 1.10 then 'growing'
            when recent_avg_revenue < early_avg_revenue * 0.90 then 'declining'
            else 'plateaued'
        end as trend_classification

    from store_period_avgs

)

select
    weekly_revenue.store_id,
    weekly_revenue.week_number_since_opening,
    weekly_revenue.weekly_revenue,
    trend.trend_classification

from weekly_revenue
inner join trend on weekly_revenue.store_id = trend.store_id
