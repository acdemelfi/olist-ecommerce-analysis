CREATE OR REPLACE VIEW powerbi_customer_experience AS

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

SELECT *
FROM category_delivery_reviews;

SELECT
    COUNT(review_score) AS total_reviews,
    COUNT(review_score) FILTER (WHERE review_score < 3) AS poor_reviews,
    ROUND(
        100.0 * COUNT(review_score) FILTER (WHERE review_score < 3)
        / COUNT(review_score),
        1
    ) AS poor_review_rate
FROM powerbi_customer_experience;