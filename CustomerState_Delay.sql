-- freight value

SELECT 
    *
FROM order_items oi
JOIN products p USING (product_id)
JOIN product_category_name_translation pt USING (product_category_name)
JOIN orders o ON oi.order_id = o.order_id
JOIN sellers s ON oi.seller_id = s.seller_id
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN (
    SELECT zip_code_prefix, MAX(state) AS state
    FROM geo
    GROUP BY zip_code_prefix
) c_geo ON c.customer_zip_code_prefix = c_geo.zip_code_prefix
LEFT JOIN (
    SELECT zip_code_prefix, MAX(state) AS state
    FROM geo
    GROUP BY zip_code_prefix
) s_geo ON s.seller_zip_code_prefix = s_geo.zip_code_prefix
WHERE o.order_status = 'delivered' 
  AND o.order_delivered_customer_date IS NOT NULL
  AND pt.product_category_name_english IN (
        'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
        'computers_accessories', 'electronics', 'cine_photo', 
        'audio', 'tablets_printing_image', 'consoles_games'
  ) and TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)>100;
;

SELECT 
    MAX(product_weight_g),
    MAX(product_length_cm),
    MAX(product_height_cm),
    MAX(product_width_cm)
FROM
    products;
 -- customer state and delay pct
 
SELECT 
    c_geo.city AS customer_city,
    c_geo.state AS customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    
    -- Count of orders delivered past the estimated date
    COUNT(DISTINCT CASE 
        WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 
        THEN o.order_id 
    END) AS delayed_orders_count,
    
    -- Percentage of orders that were delayed
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 
            THEN o.order_id 
        END) * 100.0 / COUNT(DISTINCT o.order_id), 
        2
    ) AS delayed_rate_pct,
    
    -- Severity metrics
    ROUND(AVG(CASE 
        WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 
        THEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) 
    END), 1) AS avg_days_late,
    MAX(TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date)) AS max_days_late

FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
-- Deduplicated lookup for customer city and state
LEFT JOIN (
    SELECT 
        zip_code_prefix, 
        MAX(LOWER(TRIM(city))) AS city, 
        MAX(state) AS state
    FROM geo
    GROUP BY zip_code_prefix
) c_geo ON c.customer_zip_code_prefix = c_geo.zip_code_prefix
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND c_geo.city IS NOT NULL
GROUP BY c_geo.city, c_geo.state
-- Filter out cities with very low sample size to avoid skew (e.g. 1 order that was late = 100%)
HAVING total_orders >= 50
ORDER BY delayed_orders_count DESC
LIMIT 20;

-- SP state

SELECT 
    g.state,
    
    COUNT(oi.order_id) AS total_orders,
    ROUND(AVG(CASE 
        WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 
        THEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) 
    END), 1) AS avg_days_late,
    ROUND(AVG(orv.review_score), 2) AS avg_review_score
FROM order_items oi
JOIN orders o ON oi.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN sellers s ON oi.seller_id = s.seller_id
join geo g on g.zip_code_prefix=s.seller_zip_code_prefix
JOIN order_reviews orv ON o.order_id = orv.order_id
join  products p using(product_id) join product_category_name_translation pt using(product_category_name)
WHERE g.state = 'SP' -- Assuming most tech sellers are in SP
  AND o.order_status = 'delivered' and pt.product_category_name_english in('telephony', 'watches_gifts', 'computers', 'pc_gamer', 
                'computers_accessories', 'electronics', 'cine_photo', 
                'audio', 'tablets_printing_image', 'consoles_games')
GROUP BY g.state
ORDER BY avg_days_late DESC;
-- customer state and delay
SELECT 
    c_geo.state AS customer_state,
    COUNT(DISTINCT o.order_id) AS total_orders,
    
    -- Volume of late deliveries
    COUNT(DISTINCT CASE 
        WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 
        THEN o.order_id 
    END) AS delayed_orders_count,
    
    -- Percentage of orders arriving after estimated date
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 
            THEN o.order_id 
        END) * 100.0 / COUNT(DISTINCT o.order_id), 
        2
    ) AS delay_rate_pct,
    
    -- Average days late for delayed shipments
    ROUND(AVG(CASE 
        WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 
        THEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) 
    END), 1) AS avg_days_late_when_delayed,
    
    -- Overall door-to-door delivery duration
    ROUND(AVG(TIMESTAMPDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_customer_date)), 1) AS avg_delivery_days

FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
-- Deduplicate geo lookup to prevent row multiplication
LEFT JOIN (
    SELECT zip_code_prefix, MAX(state) AS state
    FROM geo
    GROUP BY zip_code_prefix
) c_geo ON c.customer_zip_code_prefix = c_geo.zip_code_prefix

WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND c_geo.state IS NOT NULL
GROUP BY c_geo.state
ORDER BY delay_rate_pct DESC;
-- state and orders

SELECT 
    g.state,
    COUNT(*) AS total_orders,
    SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) AS late_orders,
    ROUND(
        (SUM(CASE WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 
        2
    ) AS late_percentage
FROM orders o
JOIN customers c using(customer_id)
join geo g on g.zip_code_prefix=c.customer_zip_code_prefix
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
GROUP BY g.state
ORDER BY late_percentage DESC;

