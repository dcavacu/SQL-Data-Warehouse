/*
===============================================================================
DDL Script: Create Gold Views
===============================================================================
Script Purpose:
	This script creates views for the Gold layer in the data warehouse. 
    The Gold layer represents the final dimension and fact tables (Star Schema)
	Run this script to re-define the DDL structure of 'gold' Views
===============================================================================
*/

if object_id('gold.dim_customers', 'v') is not null
	drop view gold.dim_customers
go

create view gold.dim_customers AS
select row_number() over (order by cst_id) AS customer_key,
	   ci.cst_id AS customer_id,
	   ci.cst_key AS customer_number,
	   ci.cst_firstname AS first_name,
	   ci.cst_lastname AS last_name,
	   la.cntry AS country,
	   ci.cst_marital_status AS marital_status,
	   case when ci.cst_gndr != 'n/a' then ci.cst_gndr
	   else coalesce(ca.gen, 'n/a')
	   end as gender,
	   ca.bdate AS birthdate,
	   ci.cst_create_date AS create_date
from silver.crm_cust_info ci
left join silver.erp_cust_az12 ca
	   on ci.cst_key = ca.cid
left join silver.erp_loc_a101 la
	   on ci.cst_key = la.cid
go

if object_id('gold.dim_products', 'V') is not null
    drop view gold.dim_products;
go

create view gold.dim_products AS
select row_number() over (order by pn.prd_start_dt, pn.prd_key) AS product_key,
    pn.prd_id       AS product_id,
    pn.prd_key      AS product_number,
    pn.prd_nm       AS product_name,
    pn.cat_id       AS category_id,
    pc.cat          AS category,
    pc.subcat       AS subcategory,
    pc.maintenance  AS maintenance,
    pn.prd_cost     AS cost,
    pn.prd_line     AS product_line,
    pn.prd_start_dt AS start_date
from silver.crm_prd_info pn
left join silver.erp_px_cat_g1v2 pc
	   on pn.cat_id = pc.id
where pn.prd_end_dt IS null
go

if object_id('gold.fact_sales', 'V') is not null
    drop view gold.fact_sales;
go

create view gold.fact_sales AS
select
    sd.sls_ord_num  AS order_number,
    pr.product_key  AS product_key,
    cu.customer_key AS customer_key,
    sd.sls_order_dt AS order_date,
    sd.sls_ship_dt  AS shipping_date,
    sd.sls_due_dt   AS due_date,
    sd.sls_sales    AS sales_amount,
    sd.sls_quantity AS quantity,
    sd.sls_price    AS price
from silver.crm_sales_details sd
left join gold.dim_products pr
       on sd.sls_prd_key = pr.product_number
left join gold.dim_customers cu
       on sd.sls_cust_id = cu.customer_id;
go
