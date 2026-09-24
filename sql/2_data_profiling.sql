SELECT 
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM olist_orders_dataset;

SELECT
    COUNT(DISTINCT customer_id) AS unique_customer_ids,
    COUNT(DISTINCT customer_unique_id) AS unique_customers 
FROM olist_customers_dataset;

SELECT
	COUNT(*) AS total_rows,
	COUNT(DISTINCT order_id) AS total_orders
FROM olist_order_items_dataset;

SELECT 
	order_id, 
	COUNT(*) AS items_in_order
FROM olist_order_items_dataset
GROUP BY order_id
ORDER BY items_in_order DESC
LIMIT 1;

SELECT 
	COUNT(order_id) AS orders, 
	order_status
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY orders DESC;

SELECT
	MIN(order_purchase_timestamp) AS earliest_order_purchase,
	MAX(order_purchase_timestamp) AS latest_order_purchase
FROM olist_orders_dataset;

SELECT
	COUNT(*) - COUNT(order_approved_at) AS nulls_in_approved,
	COUNT(*) - COUNT(order_delivered_carrier_date) AS nulls_in_carrier_date,
	COUNT(*) - COUNT(order_delivered_customer_date) AS nulls_in_customer_date
FROM olist_orders_dataset;

SELECT 
	COUNT(order_id) AS appearances,
	order_id
FROM olist_order_payments_dataset
GROUP BY order_id
ORDER BY appearances DESC
LIMIT 10;

-- Inspect an order with multiple payment records
SELECT *
FROM olist_order_payments_dataset
WHERE order_id = 'fa65dad1b0e818e3ccc5cb0e39231352';

SELECT 
	COUNT(review_score) AS rating_total,
	review_score
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score DESC;

SELECT COUNT(DISTINCT product_category_name)
FROM olist_products_dataset;

SELECT
	COUNT(DISTINCT seller_state) AS distinct_states,
	COUNT(DISTINCT seller_id) AS distinct_sellers
FROM olist_sellers_dataset;