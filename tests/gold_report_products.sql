
if object_id('gold.report_products', 'v') is not null
	drop view gold.report_products
go

create view gold.report_products as

with base_query as (

select 
	f.order_number,
	f.order_date,
	f.customer_key,
	f.sales_amount,
	f.quantity,
	p.product_key,
	p.product_name,
	p.category_id,
	p.subcategory,
	p.cost
from gold.fact_sales f
left join gold.dim_products p
on		  f.product_key = p.product_key
where order_date IS NOT NULL
),

product_aggregation as (
select 
	product_key,
	product_name,
	category_id,
	subcategory,
	cost,
	datediff(month, min(order_date), max(order_date)) as lifespan,
	max(order_date) as last_sale_date,
	count(distinct order_number) as total_orders,
	count(distinct customer_key) as total_customers,
	sum(sales_amount) as total_sales,
	sum(quantity) as total_quantity,
	round(avg(cast(sales_amount as float) / nullif(quantity,0)),1) as avg_selling_price
from base_query
group by 
	product_key,
	product_name,
	category_id,
	subcategory,
	cost
)

select
	product_key,
	product_name,
	category_id,
	subcategory,
	cost,
	last_sale_date,
	datediff(month, last_sale_date, getdate()) as recency_in_months,
	case
		when total_sales > 50000 then 'High-Performer'
		when total_sales >= 100000 then 'Mid-Range'
		else 'Low-Performance'
	end as product_segment,
	lifespan,
	total_orders,
	total_sales,
	total_quantity,
	total_customers,
	avg_selling_price,
	case
		when total_orders = 0 then 0
		else total_sales / total_orders
	end as avg_order_revenue,
	case
		when lifespan = 0 then 0
		else total_sales / lifespan
	end as avg_monthly_revenue
from product_aggregation