SELECT 
    COUNT(*), product_id
FROM
    order_items
GROUP BY product_id;


-- customer region

SELECT 
    CASE
        WHEN c_geo.state IN ('SP' , 'RJ', 'MG', 'ES') THEN 'Southeast'
        WHEN c_geo.state IN ('PR' , 'SC', 'RS') THEN 'South'
        WHEN c_geo.state IN ('DF' , 'GO', 'MT', 'MS') THEN 'Central-West'
        WHEN
            c_geo.state IN ('BA' , 'PE',
                'CE',
                'MA',
                'PB',
                'RN',
                'AL',
                'SE',
                'PI')
        THEN
            'Northeast'
        WHEN c_geo.state IN ('AM' , 'PA', 'AC', 'RO', 'RR', 'AP', 'TO') THEN 'North'
        ELSE 'Unknown'
    END AS customer_region,
    COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(AVG(TIMESTAMPDIFF(DAY,
                o.order_purchase_timestamp,
                o.order_delivered_carrier_date)),
            1) AS avg_seller_handling_days,
    ROUND(AVG(TIMESTAMPDIFF(DAY,
                o.order_delivered_carrier_date,
                o.order_delivered_customer_date)),
            1) AS avg_carrier_transit_days,
    ROUND(AVG(TIMESTAMPDIFF(DAY,
                o.order_purchase_timestamp,
                o.order_delivered_customer_date)),
            1) AS avg_total_delivery_days,
    ROUND(COUNT(DISTINCT CASE
                    WHEN
                        TIMESTAMPDIFF(DAY,
                            o.order_estimated_delivery_date,
                            o.order_delivered_customer_date) > 0
                    THEN
                        o.order_id
                END) * 100.0 / COUNT(DISTINCT o.order_id),
            2) AS delayed_delivery_rate_pct,
    ROUND(AVG(CASE
                WHEN
                    TIMESTAMPDIFF(DAY,
                        o.order_estimated_delivery_date,
                        o.order_delivered_customer_date) > 0
                THEN
                    TIMESTAMPDIFF(DAY,
                        o.order_estimated_delivery_date,
                        o.order_delivered_customer_date)
            END),
            1) AS avg_days_late_when_delayed
FROM
    orders o
        JOIN
    customers c ON o.customer_id = c.customer_id
        LEFT JOIN
    (SELECT 
        zip_code_prefix, MAX(state) AS state
    FROM
        geo
    GROUP BY zip_code_prefix) c_geo ON c.customer_zip_code_prefix = c_geo.zip_code_prefix
WHERE
    o.order_status = 'delivered'
        AND o.order_delivered_carrier_date IS NOT NULL
        AND o.order_delivered_customer_date IS NOT NULL
        AND c_geo.state IS NOT NULL
GROUP BY customer_region
ORDER BY avg_carrier_transit_days ASC;


-- Price category

SELECT 
    CASE
        WHEN oi.price < 50 THEN 'Budget'
        WHEN oi.price >= 50 AND oi.price < 200 THEN 'Mid-range'
        WHEN oi.price >= 200 AND oi.price < 1000 THEN 'High-end'
        WHEN oi.price >= 1000 THEN 'Luxury'
        ELSE 'Not Categorized'
    END AS price_category,
    
    -- Product distribution
    COUNT(DISTINCT oi.order_id) AS num_orders,
    ROUND((COUNT(DISTINCT oi.order_id) * 100.0) / SUM(COUNT(DISTINCT oi.order_id)) OVER (), 2) AS percentage_tech_orders,
    
    -- Logistic performance layers
    COUNT(DISTINCT CASE WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 THEN o.order_id END) AS delayed_orders,
    ROUND(
        COUNT(DISTINCT CASE WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 THEN o.order_id END) * 100.0 
        / COUNT(DISTINCT oi.order_id), 2
    ) AS delay_rate_pct,
    
    ROUND(AVG(CASE WHEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) > 0 
        THEN TIMESTAMPDIFF(DAY, o.order_estimated_delivery_date, o.order_delivered_customer_date) END), 1) AS avg_days_late,
    
    ROUND(AVG(oi.freight_value), 2) AS avg_freight_cost

FROM products p
LEFT JOIN product_category_name_translation pt USING (product_category_name)
LEFT JOIN order_items oi USING (product_id)
-- Joined orders to extract the actual shipment timestamps
LEFT JOIN orders o USING (order_id)
WHERE pt.product_category_name_english IN (
    'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
    'computers_accessories', 'electronics', 'cine_photo', 
    'audio', 'tablets_printing_image', 'consoles_games'
)
  AND o.order_status = 'delivered'
GROUP BY price_category
ORDER BY MIN(oi.price) ASC;



-- orders on monthly basis



SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS purchase_month,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT CASE
            WHEN
                TIMESTAMPDIFF(DAY,
                    o.order_estimated_delivery_date,
                    o.order_delivered_customer_date) > 0
            THEN
                o.order_id
        END) AS late_orders,
    ROUND(COUNT(DISTINCT CASE
                    WHEN
                        TIMESTAMPDIFF(DAY,
                            o.order_estimated_delivery_date,
                            o.order_delivered_customer_date) > 0
                    THEN
                        o.order_id
                END) * 100.0 / COUNT(DISTINCT o.order_id),
            2) AS late_rate_pct,
    ROUND(AVG(CASE
                WHEN
                    TIMESTAMPDIFF(DAY,
                        o.order_estimated_delivery_date,
                        o.order_delivered_customer_date) > 0
                THEN
                    TIMESTAMPDIFF(DAY,
                        o.order_estimated_delivery_date,
                        o.order_delivered_customer_date)
            END),
            1) AS avg_days_late
FROM
    orders o
        JOIN
    order_items oi USING (order_id)
        JOIN
    products p USING (product_id)
        JOIN
    product_category_name_translation pt USING (product_category_name)
WHERE
    o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games')
GROUP BY purchase_month
ORDER BY purchase_month ASC;


-- customer state ,orders and delivery delay


SELECT 
    c_geo.state AS customer_state,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    COUNT(DISTINCT CASE
            WHEN
                TIMESTAMPDIFF(DAY,
                    o.order_estimated_delivery_date,
                    o.order_delivered_customer_date) > 0
            THEN
                o.order_id
        END) AS late_orders_count,
    ROUND(COUNT(DISTINCT CASE
                    WHEN
                        TIMESTAMPDIFF(DAY,
                            o.order_estimated_delivery_date,
                            o.order_delivered_customer_date) > 0
                    THEN
                        o.order_id
                END) * 100.0 / COUNT(DISTINCT o.order_id),
            2) AS late_rate_pct,
    ROUND(AVG(CASE
                WHEN
                    TIMESTAMPDIFF(DAY,
                        o.order_estimated_delivery_date,
                        o.order_delivered_customer_date) > 0
                THEN
                    TIMESTAMPDIFF(DAY,
                        o.order_estimated_delivery_date,
                        o.order_delivered_customer_date)
            END),
            1) AS avg_days_late,
    ROUND(AVG(TIMESTAMPDIFF(DAY,
                o.order_purchase_timestamp,
                o.order_delivered_customer_date)),
            1) AS avg_total_delivery_days
FROM
    orders o
        JOIN
    customers c ON o.customer_id = c.customer_id
        LEFT JOIN
    (SELECT 
        zip_code_prefix, MAX(state) AS state
    FROM
        geo
    GROUP BY zip_code_prefix) c_geo ON c.customer_zip_code_prefix = c_geo.zip_code_prefix
WHERE
    o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND c_geo.state IS NOT NULL
GROUP BY c_geo.state
ORDER BY late_rate_pct DESC;


-- review and delay in delivery



SELECT 
    c_geo.state AS customer_state,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders,
    COUNT(DISTINCT CASE
            WHEN
                TIMESTAMPDIFF(DAY,
                    o.order_estimated_delivery_date,
                    o.order_delivered_customer_date) > 0
            THEN
                o.order_id
        END) AS late_orders_count,
    ROUND(COUNT(DISTINCT CASE
                    WHEN
                        TIMESTAMPDIFF(DAY,
                            o.order_estimated_delivery_date,
                            o.order_delivered_customer_date) > 0
                    THEN
                        o.order_id
                END) * 100.0 / COUNT(DISTINCT o.order_id),
            2) AS late_rate_pct,
    ROUND(AVG(r.avg_review_score), 2) AS overall_avg_review_score,
    COUNT(DISTINCT CASE
            WHEN r.avg_review_score = 1 THEN o.order_id
        END) AS one_star_orders_count,
    ROUND(COUNT(DISTINCT CASE
                    WHEN r.avg_review_score = 1 THEN o.order_id
                END) * 100.0 / COUNT(DISTINCT o.order_id),
            2) AS one_star_rate_pct,
    ROUND(AVG(CASE
                WHEN
                    TIMESTAMPDIFF(DAY,
                        o.order_estimated_delivery_date,
                        o.order_delivered_customer_date) <= 0
                THEN
                    r.avg_review_score
            END),
            2) AS avg_score_when_ontime,
    ROUND(AVG(CASE
                WHEN
                    TIMESTAMPDIFF(DAY,
                        o.order_estimated_delivery_date,
                        o.order_delivered_customer_date) > 0
                THEN
                    r.avg_review_score
            END),
            2) AS avg_score_when_late
FROM
    orders o
        JOIN
    customers c ON o.customer_id = c.customer_id
        LEFT JOIN
    (SELECT 
        zip_code_prefix, MAX(state) AS state
    FROM
        geo
    GROUP BY zip_code_prefix) c_geo ON c.customer_zip_code_prefix = c_geo.zip_code_prefix
        JOIN
    (SELECT 
        order_id, AVG(review_score) AS avg_review_score
    FROM
        order_reviews
    GROUP BY order_id) r ON o.order_id = r.order_id
WHERE
    o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND c_geo.state IS NOT NULL
GROUP BY c_geo.state
HAVING total_delivered_orders >= 50
ORDER BY late_rate_pct DESC;

