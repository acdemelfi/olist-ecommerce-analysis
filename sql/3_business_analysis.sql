/*Query 1: Compare product categories by item volume and sales value to
identify categories where commercial importance differs by metric*/

WITH category_metrics AS (
    SELECT
        COALESCE(trans.product_category_name_english, 'other/unnamed') AS product_category,
        COUNT(oi.product_id) AS items_sold,
        SUM(oi.price) AS sales_value,
        SUM(oi.price) / COUNT(oi.product_id) AS avg_sales_per_item,
        RANK() OVER (ORDER BY COUNT(oi.product_id) DESC) AS amount_rank,
        RANK() OVER (ORDER BY SUM(oi.price) DESC) AS sales_rank
    FROM olist_order_items_dataset AS oi
    LEFT JOIN olist_products_dataset AS opd
        ON oi.product_id = opd.product_id
    LEFT JOIN product_category_name_translation AS trans
        ON opd.product_category_name = trans.product_category_name
    GROUP BY trans.product_category_name_english
)
/*Absolute rank difference identifies the largest discrepancies.
Signed difference shows direction:
negative = stronger volume rank
positive = stronger sales-value rank */

SELECT
    product_category,
    items_sold,
    sales_value,
    avg_sales_per_item,
    amount_rank,
    sales_rank,
    amount_rank - sales_rank AS rank_difference,
    ABS(amount_rank - sales_rank) AS absolute_rank_difference,
	ROUND(1.0*(sales_rank + amount_rank) / 2, 1) AS avg_rank 
FROM category_metrics
ORDER BY avg_rank;


/*Query 2: Identify product categories with the highest rates of 
poor customer reviews (1–2 stars) */

SELECT COUNT(DISTINCT order_id) AS orders_with_reviews
FROM olist_order_reviews_dataset;
--98,673 orders have reviews

--Find out whether order-level reviews can reasonably be assigned to a single category

SELECT 
	oi.order_id,
	COUNT(DISTINCT COALESCE(trans.product_category_name_english, 'other/unnamed')) AS cat_in_order
FROM olist_order_items_dataset AS oi
LEFT JOIN olist_products_dataset AS opd
	ON oi.product_id = opd.product_id
LEFT JOIN product_category_name_translation AS trans
	ON opd.product_category_name = trans.product_category_name
GROUP BY oi.order_id
HAVING COUNT(DISTINCT COALESCE(trans.product_category_name_english, 'other/unnamed')) > 1;
--786 orders contain items from multiple categories (~0.8%)

WITH reviews AS (
	SELECT
    	order_id,
    	review_id,
    	review_score,
    	review_creation_date,
    	review_answer_timestamp,
		ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS review_rank
	FROM olist_order_reviews_dataset
), --Some orders have multiple reviews; ROW_NUMBER numbers them from newest to oldest 

order_categories AS (
	SELECT 
		oi.order_id,
		MAX(COALESCE(trans.product_category_name_english, 'other/unnamed')) AS order_category
	FROM olist_order_items_dataset AS oi
	LEFT JOIN olist_products_dataset AS opd
	    ON oi.product_id = opd.product_id
	LEFT JOIN product_category_name_translation AS trans
	    ON opd.product_category_name = trans.product_category_name
	GROUP BY oi.order_id
	HAVING COUNT(DISTINCT COALESCE(trans.product_category_name_english, 'other/unnamed')) = 1
)

SELECT
	oc.order_category,
	SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS one_star,
    SUM(CASE WHEN r.review_score = 2 THEN 1 ELSE 0 END) AS two_star,
    SUM(CASE WHEN r.review_score = 3 THEN 1 ELSE 0 END) AS three_star,
    SUM(CASE WHEN r.review_score = 4 THEN 1 ELSE 0 END) AS four_star,
    SUM(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END) AS five_star,
	SUM(CASE WHEN r.review_score < 3 THEN 1 ELSE 0 END) AS poor_review,
	COUNT(r.review_score) AS total_reviews,
	ROUND(100.0*SUM(CASE WHEN r.review_score < 3 THEN 1 ELSE 0 END) / COUNT(r.review_score), 2) AS poor_review_rate
FROM order_categories AS oc
LEFT JOIN reviews AS r
	ON oc.order_id = r.order_id
WHERE r.review_rank = 1
GROUP BY oc.order_category
HAVING COUNT(r.review_score) >= 100 
ORDER BY poor_review_rate DESC;
/*Limit comparison to categories with at least 100 reviews to reduce
distortion from very small sample sizes. This removes 20 categories */


/*Query 3: Identify observable order and delivery factors associated
with poor customer reviews (1–2 stars)

First, compare poor-review rates between on-time and late deliveries */

WITH reviews AS (
	SELECT
    	order_id,
    	review_id,
    	review_score,
    	review_creation_date,
    	review_answer_timestamp,
		ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS review_rank
	FROM olist_order_reviews_dataset
),

delivery_reviews AS (
    SELECT
        o.order_id,
        r.review_score,
        CASE WHEN o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date
			THEN 'Late'
		ELSE 'On time'
        END AS delivery_status
    FROM olist_orders_dataset AS o
    LEFT JOIN reviews AS r
        ON o.order_id = r.order_id
    WHERE r.review_rank = 1
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
)
/*Estimated delivery timestamps are recorded at 00:00:00, indicating only
the date is estimated, not the time. Calendar dates are compared so orders
delivered on the estimated date are not incorrectly classified as late */
SELECT
    delivery_status,
    COUNT(review_score) AS total_reviews,
    SUM(CASE WHEN review_score < 3 THEN 1 ELSE 0 END) AS poor_reviews,
    ROUND(100.0*SUM(CASE WHEN review_score < 3 THEN 1 ELSE 0 END) / COUNT(review_score), 2) AS poor_review_rate
FROM delivery_reviews
GROUP BY delivery_status
ORDER BY poor_review_rate DESC; 

/*Query 3B: Determine if review outcomes worsen as delivery lateness increases */

WITH reviews AS (
	SELECT
    	order_id,
    	review_id,
    	review_score,
    	review_creation_date,
    	review_answer_timestamp,
		ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS review_rank
	FROM olist_order_reviews_dataset
),

delay_reviews AS (
    SELECT
        o.order_id,
        r.review_score,
		CASE WHEN o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date
			THEN o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date
		ELSE 0 
		END AS days_late
    FROM olist_orders_dataset AS o
    LEFT JOIN reviews AS r
        ON o.order_id = r.order_id
    WHERE r.review_rank = 1
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT
	CASE WHEN days_late BETWEEN 1 AND 3 THEN '1-3 days'
	WHEN days_late BETWEEN 4 AND 7 THEN '4-7 days'
    WHEN days_late BETWEEN 8 AND 14 THEN '8-14 days'
    WHEN days_late BETWEEN 15 AND 30 THEN '15-30 days'
    WHEN days_late >= 31 THEN '31+ days'
	END AS lateness_group,
	COUNT(review_score) AS total_reviews,
    SUM(CASE WHEN review_score < 3 THEN 1 ELSE 0 END) AS poor_reviews,
    ROUND(100.0*SUM(CASE WHEN review_score < 3 THEN 1 ELSE 0 END) / COUNT(review_score), 2) AS poor_review_rate
FROM delay_reviews
WHERE days_late > 0
GROUP BY 1
ORDER BY total_reviews DESC;
/* There is a clear and significant increase in poor review rate
as the lateness of orders increases as well */


/*Query 4: Determine how delivery lateness and poor-review 
rates vary across product categories */

WITH reviews AS (
	SELECT
    	order_id,
    	review_id,
    	review_score,
    	review_creation_date,
    	review_answer_timestamp,
		ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS review_rank
	FROM olist_order_reviews_dataset
),

order_categories AS (
	SELECT 
		oi.order_id,
		MAX(COALESCE(trans.product_category_name_english, 'other/unnamed')) AS order_category
	FROM olist_order_items_dataset AS oi
	LEFT JOIN olist_products_dataset AS opd
	    ON oi.product_id = opd.product_id
	LEFT JOIN product_category_name_translation AS trans
	    ON opd.product_category_name = trans.product_category_name
	GROUP BY oi.order_id
	HAVING COUNT(DISTINCT COALESCE(trans.product_category_name_english, 'other/unnamed')) = 1
),

category_delivery_reviews AS (
	SELECT 
		r.order_id,
		oc.order_category,
		r.review_score,
		CASE WHEN o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date
			THEN o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date
		ELSE 0 
		END AS days_late
	FROM olist_orders_dataset AS o
    INNER JOIN reviews AS r
        ON o.order_id = r.order_id
    INNER JOIN order_categories AS oc
        ON r.order_id = oc.order_id
    WHERE r.review_rank = 1
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT 
	order_category,
	COUNT(review_score) AS total_reviews,
	SUM(CASE WHEN days_late > 0 THEN 1 ELSE 0 END) AS late_orders,
	ROUND(100.0*SUM(CASE WHEN days_late > 0 THEN 1 ELSE 0 END) / COUNT(review_score), 2) AS reviewed_orders_late_rate,
	SUM(CASE WHEN review_score < 3 THEN 1 ELSE 0 END) AS poor_reviews,
    ROUND(100.0*SUM(CASE WHEN review_score < 3 THEN 1 ELSE 0 END) / COUNT(review_score), 2) AS poor_review_rate
FROM category_delivery_reviews
GROUP BY order_category;
/*This analysis is limited to single-category delivered orders with reviews.
Late rate therefore represents the percentage of reviewed orders delivered late,
not the overall late-delivery rate for each category */

WITH reviews AS (
    SELECT
        order_id,
        review_id,
        review_score,
        review_creation_date,
        review_answer_timestamp,
        ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY review_answer_timestamp DESC) AS review_rank
    FROM olist_order_reviews_dataset
),

order_categories AS (
    SELECT 
        oi.order_id,
        MAX(COALESCE(trans.product_category_name_english, 'other/unnamed')) AS order_category
    FROM olist_order_items_dataset AS oi
    LEFT JOIN olist_products_dataset AS opd
        ON oi.product_id = opd.product_id
    LEFT JOIN product_category_name_translation AS trans
        ON opd.product_category_name = trans.product_category_name
    GROUP BY oi.order_id
    HAVING COUNT(DISTINCT COALESCE(trans.product_category_name_english, 'other/unnamed')) = 1
),

category_delivery_reviews AS (
    SELECT 
        o.order_id,
        oc.order_category,
        r.review_score,
        CASE WHEN o.order_delivered_customer_date::date > o.order_estimated_delivery_date::date
            THEN o.order_delivered_customer_date::date - o.order_estimated_delivery_date::date
		ELSE 0 
        END AS days_late
    FROM olist_orders_dataset AS o
    INNER JOIN order_categories AS oc
        ON o.order_id = oc.order_id
    LEFT JOIN reviews AS r
        ON o.order_id = r.order_id
        AND r.review_rank = 1
    WHERE o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
)

SELECT 
    order_category,
    COUNT(order_id) AS total_delivered_orders,
    SUM(CASE WHEN days_late > 0 THEN 1 ELSE 0 END) AS late_orders,
    ROUND(100.0*SUM(CASE WHEN days_late > 0 THEN 1 ELSE 0 END) / COUNT(order_id), 2) AS late_rate,
    COUNT(review_score) AS total_reviews,
    SUM(CASE WHEN review_score < 3 THEN 1 ELSE 0 END) AS poor_reviews,
    ROUND(100.0*SUM(CASE WHEN review_score < 3 THEN 1 ELSE 0 END) / COUNT(review_score), 2) AS poor_review_rate
FROM category_delivery_reviews
GROUP BY order_category
HAVING COUNT(review_score) >= 100
ORDER BY poor_review_rate DESC;
/*This time, delivery metrics use all eligible delivered single-category orders,
while review metrics use only the subset of those orders with a recorded review.
Once again, limit comparison to categories with at least 100 reviews to reduce
distortion from very small sample sizes. This removes 20 categories */