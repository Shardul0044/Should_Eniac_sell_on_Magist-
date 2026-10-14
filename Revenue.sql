-- Eniac vs Magist monthly revenue

WITH monthly_tech_revenue AS (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS sales_month,
        COUNT(DISTINCT o.order_id) AS tech_orders,
        ROUND(SUM(oi.price), 2) AS monthly_revenue_brl,
        -- Approximate conversion used in the case study (~4.5 BRL to 1 EUR for 2017-2018)
        ROUND(SUM(oi.price) / 4.5, 2) AS monthly_revenue_eur
    FROM orders o
    JOIN order_items oi USING (order_id)
    JOIN products p USING (product_id)
    JOIN product_category_name_translation pt USING (product_category_name)
    WHERE o.order_status = 'delivered'
      AND pt.product_category_name_english IN (
            'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
            'computers_accessories', 'electronics', 'cine_photo', 
            'audio', 'tablets_printing_image', 'consoles_games'
      )
    GROUP BY sales_month
)
SELECT 
    sales_month,
    tech_orders,
    monthly_revenue_eur,
    ROUND(monthly_revenue_eur * 100.0 / 1170000, 2) AS pct_of_eniac_monthly_rev
FROM monthly_tech_revenue
-- Exclude ramp-up/cut-off months with incomplete order capture
WHERE sales_month BETWEEN '2017-01' AND '2018-08'
ORDER BY sales_month;

-- montly revenue
SELECT 
    -- Average monthly tech revenue across active operational months
    ROUND(AVG(monthly_revenue_eur), 2) AS avg_monthly_tech_revenue_eur,
    
    -- Eniac monthly benchmark
    1170000 AS eniac_monthly_revenue_eur,
    
    -- Magist tech revenue as a percentage of Eniac
    ROUND(AVG(monthly_revenue_eur) * 100.0 / 1170000, 2) AS percentage_of_eniac
FROM (
    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS sales_month,
        ROUND(SUM(oi.price), 2) AS monthly_revenue_eur
    FROM orders o
    JOIN order_items oi USING (order_id)
    JOIN products p USING (product_id)
    JOIN product_category_name_translation pt USING (product_category_name)
    WHERE o.order_status = 'delivered'
      AND pt.product_category_name_english IN (
            'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
            'computers_accessories', 'electronics', 'cine_photo', 
            'audio', 'tablets_printing_image', 'consoles_games'
      )
    GROUP BY sales_month
    -- Restrict to full operational months (Jan 2017 - Aug 2018) to avoid partial month skews
    -- HAVING sales_month BETWEEN '2017-01' AND '2018-08'
) monthly_totals;


-- On time and late deliveries and reviews


WITH order_level_reviews AS (
    -- Pre-aggregate review metrics per order to prevent cartesian row duplication
    SELECT 
        order_id,
        AVG(review_score) AS avg_order_review_score,
        MAX(CASE WHEN review_score = 1 THEN 1 ELSE 0 END) AS has_1_star_review,
        MAX(CASE WHEN review_score = 5 THEN 1 ELSE 0 END) AS has_5_star_review
    FROM order_reviews
    GROUP BY order_id
),
tech_orders AS (
    -- Identify unique delivered tech orders
    SELECT DISTINCT 
        o.order_id,
        o.order_estimated_delivery_date,
        o.order_delivered_customer_date
    FROM orders o
    JOIN order_items oi USING (order_id)
    JOIN products p USING (product_id)
    JOIN product_category_name_translation pt USING (product_category_name)
    WHERE o.order_status = 'delivered'
      AND o.order_delivered_customer_date IS NOT NULL
      AND pt.product_category_name_english IN (
            'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
            'computers_accessories', 'electronics', 'cine_photo', 
            'audio', 'tablets_printing_image', 'consoles_games'
      )
)
SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(DAY, t.order_estimated_delivery_date, t.order_delivered_customer_date) <= 0 
            THEN 'Delivered On-Time / Early'
        ELSE 'Delivered Late'
    END AS delivery_status,
    
    COUNT(t.order_id) AS total_orders,
    
    -- Average overall review score
    ROUND(AVG(r.avg_order_review_score), 2) AS avg_review_score,
    
    -- 1-Star Review Counts and Percentages
    SUM(r.has_1_star_review) AS count_1_star_orders,
    ROUND(SUM(r.has_1_star_review) * 100.0 / COUNT(t.order_id), 2) AS pct_1_star_reviews,
    
    -- 5-Star Review Counts and Percentages
    SUM(r.has_5_star_review) AS count_5_star_orders,
    ROUND(SUM(r.has_5_star_review) * 100.0 / COUNT(t.order_id), 2) AS pct_5_star_reviews

FROM tech_orders t
JOIN order_level_reviews r USING (order_id)
GROUP BY delivery_status;

-- delivery status and 1* review


SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) <= 0 
            THEN 'On-Time or Early'
        ELSE 'Delivered Late'
    END AS delivery_status,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    COUNT(DISTINCT CASE WHEN r.review_score = 1 THEN o.order_id END) AS one_star_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN r.review_score = 1 THEN o.order_id END) * 100.0 
        / COUNT(DISTINCT o.order_id), 
        2
    ) AS pct_1_star_reviews
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p USING (product_id)
JOIN product_category_name_translation pt USING (product_category_name)
JOIN order_reviews r ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND pt.product_category_name_english IN (
        'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
        'computers_accessories', 'electronics', 'cine_photo', 
        'audio', 'tablets_printing_image', 'consoles_games'
  )
GROUP BY delivery_status;


-- avg montly income all sellers vs tech sellers


SELECT 
    -- Average monthly income across all sellers
    ROUND(AVG(total_revenue / 25), 2) AS avg_monthly_income_all_sellers,
    
    -- Average monthly income strictly across sellers who sold at least one tech item
    ROUND(
        AVG(
            CASE 
                WHEN tech_revenue > 0 THEN tech_revenue / 25 
                ELSE NULL 
            END
        ), 
        2
    ) AS avg_monthly_income_tech_sellers
FROM (
    SELECT 
        oi.seller_id,
        SUM(oi.price) AS total_revenue,
        SUM(
            CASE 
                WHEN pt.product_category_name_english IN (
                    'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
                    'computers_accessories', 'electronics', 'cine_photo', 
                    'audio', 'tablets_printing_image', 'consoles_games'
                ) THEN oi.price 
                ELSE 0 
            END
        ) AS tech_revenue
    FROM order_items oi
    LEFT JOIN products p 
        USING (product_id)
    LEFT JOIN product_category_name_translation pt 
        USING (product_category_name)
    GROUP BY oi.seller_id
) AS seller_metrics;

-- tech/non_tech delay


SELECT 
    CASE 
        WHEN pt.product_category_name_english IN (
            'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
            'computers_accessories', 'electronics', 'cine_photo', 
            'audio', 'tablets_printing_image', 'consoles_games'
        ) THEN 'Tech / Electronics'
        ELSE 'Non-Tech'
    END AS category_group,

    -- Total late customer deliveries
    COUNT(distinct o.order_id) AS total_delayed_orders
    FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p USING (product_id)
JOIN product_category_name_translation pt USING (product_category_name)
WHERE o.order_status = 'delivered'
  AND o.order_delivered_carrier_date IS NOT NULL
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY category_group;
select * from order_reviews where review_score=1 and review_creation_date='2018-01-13 01:00:00';