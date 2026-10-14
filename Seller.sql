-- Seller hub
SELECT 
    g.state AS seller_state,
    COUNT(s.seller_id) AS seller_count,
    ROUND(COUNT(s.seller_id) * 100.0 / (SELECT COUNT(*) FROM sellers), 2) AS seller_pct
FROM sellers s
LEFT JOIN (
    SELECT zip_code_prefix, MAX(state) AS state 
    FROM geo 
    GROUP BY zip_code_prefix
) g ON s.seller_zip_code_prefix = g.zip_code_prefix
GROUP BY g.state
ORDER BY seller_count DESC
LIMIT 5;

-- Total revenue tech/Non-Tech

SELECT 
    CASE 
        WHEN pt.product_category_name_english IN (
            'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
            'computers_accessories', 'electronics', 'cine_photo', 
            'audio', 'tablets_printing_image', 'consoles_games'
        ) THEN 'Tech / Electronics'
        ELSE 'Non-Tech'
    END AS category_group,
    COUNT(DISTINCT oi.order_id) AS total_orders,
    -- Calculates percentage of total orders cleanly
    ROUND(COUNT(DISTINCT oi.order_id) * 100.0 / SUM(COUNT(DISTINCT oi.order_id)) OVER (), 2) AS order_percentage,
    ROUND(SUM(oi.price), 2) AS total_revenue,
    -- Calculates percentage of total revenue cleanly
    ROUND(SUM(oi.price) * 100.0 / SUM(SUM(oi.price)) OVER (), 2) AS revenue_percentage,
    ROUND(AVG(oi.price), 2) AS avg_item_price
FROM order_items oi
JOIN products p USING (product_id)
JOIN product_category_name_translation pt USING (product_category_name)
GROUP BY category_group;

-- Delay due to carrier and seller
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
    COUNT(*) AS total_delayed_orders,

    -- Late due to seller: seller handed over to carrier AFTER shipping_limit_date
    COUNT(DISTINCT CASE 
        WHEN o.order_delivered_carrier_date > oi.shipping_limit_date 
        THEN o.order_id 
    END) AS seller_delayed_orders,

    -- Late due to carrier: seller handed over on time, but customer delivery was late
    COUNT(DISTINCT CASE 
        WHEN o.order_delivered_carrier_date <= oi.shipping_limit_date 
         AND o.order_delivered_customer_date > o.order_estimated_delivery_date
        THEN o.order_id 
    END) AS carrier_delayed_orders,

    -- Percentage share of fault
    ROUND(
        COUNT(DISTINCT CASE 
            WHEN o.order_delivered_carrier_date > oi.shipping_limit_date 
            THEN o.order_id 
        END) * 100.0 / COUNT(DISTINCT o.order_id), 
        2
    ) AS pct_caused_by_seller,

    ROUND(
        COUNT(DISTINCT CASE 
            WHEN o.order_delivered_carrier_date <= oi.shipping_limit_date 
             AND o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN o.order_id 
        END) * 100.0 / COUNT(DISTINCT o.order_id), 
        2
    ) AS pct_caused_by_carrier

    -- Average duration splits (in days)
    -- ROUND(AVG(TIMESTAMPDIFF(DAY, o.order_purchase_timestamp, o.order_delivered_carrier_date)), 1) AS avg_seller_handling_days,
    -- ROUND(AVG(TIMESTAMPDIFF(DAY, o.order_delivered_carrier_date, o.order_delivered_customer_date)), 1) AS avg_carrier_transit_days

FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p USING (product_id)
JOIN product_category_name_translation pt USING (product_category_name)
WHERE o.order_status = 'delivered'
  AND o.order_delivered_carrier_date IS NOT NULL
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY category_group;

