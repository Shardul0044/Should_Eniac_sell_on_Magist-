-- business questions

SELECT DISTINCT
    pt.product_category_name_english
FROM
    products p
        JOIN
    product_category_name_translation pt USING (product_category_name)
WHERE
    pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games');
        
-- How many products of these tech categories have been sold (within the time window of the database snapshot)? What percentage does that represent from the overall number of products sold?


SELECT 
    COUNT(*) AS num_tech_sold,
    (SELECT 
            COUNT(*)
        FROM
            order_items) AS num_total_sold,
    COUNT(*) / (SELECT 
            COUNT(*)
        FROM
            order_items) * 100 AS percentage_tech_sold
FROM
    products p
        LEFT JOIN
    product_category_name_translation pt USING (product_category_name)
        LEFT JOIN
    order_items oi USING (product_id)
        LEFT JOIN
    orders o USING (order_id)
WHERE
    pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games');
        
        
 -- alternative solution:
 
SELECT 
    COUNT(CASE WHEN pt.product_category_name_english IN (
        'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
        'computers_accessories', 'electronics', 'cine_photo', 
        'audio', 'tablets_printing_image', 'consoles_games'
    ) THEN 1 END) AS num_tech_sold,
    
    COUNT(*) AS num_total_sold,
    
    -- Multiplying by 100.0 turns the numerator into a float to prevent integer division
    COUNT(CASE WHEN pt.product_category_name_english IN (
        'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
        'computers_accessories', 'electronics', 'cine_photo', 
        'audio', 'tablets_printing_image', 'consoles_games'
    ) THEN 1 END) * 100.0 / COUNT(*) AS percentage_tech_sold

FROM order_items oi
JOIN products p USING (product_id)
JOIN product_category_name_translation pt USING (product_category_name);


-- avg privce of the products being sold

SELECT 
    round(avg(oi.price),2) as Avg_price_tech, (select round(avg(oi.price),2) from  products p
        LEFT JOIN
    product_category_name_translation pt USING (product_category_name)
        LEFT JOIN
    order_items oi USING (product_id)
        LEFT JOIN
    orders o USING (order_id)) as Avg_price
FROM
    products p
        LEFT JOIN
    product_category_name_translation pt USING (product_category_name)
        LEFT JOIN
    order_items oi USING (product_id)
        LEFT JOIN
    orders o USING (order_id)
WHERE
    pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games');
        
SELECT 
    ROUND(AVG(price), 2) AS avg_price_overall
FROM
    order_items;
    
-- Are expensive tech products popular?6735,0.85
SELECT 
    CASE
        WHEN oi.price < 50 THEN 'Budget'
        WHEN oi.price >= 50 AND oi.price < 200 THEN 'Mid-range'
        WHEN oi.price >=200 AND oi.price < 1000 THEN 'High-end'
        WHEN oi.price >=1000 THEN 'Luxury'
        ELSE 'not cstegorized'
    END AS Price_category,
    COUNT(*) AS num_products,
    ROUND((COUNT(*) * 100.0) / (
        SELECT COUNT(*) 
        FROM order_items oi2
        JOIN products p2 USING (product_id)
        JOIN product_category_name_translation pt2 USING (product_category_name)
        WHERE pt2.product_category_name_english IN (
            'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
            'computers_accessories', 'electronics', 'cine_photo', 
            'audio', 'tablets_printing_image', 'consoles_games'
        )
    ), 2) AS percentage_tech
FROM
    products p
        LEFT JOIN
    product_category_name_translation pt USING (product_category_name)
        LEFT JOIN
    order_items oi USING (product_id) where  pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games')
GROUP BY Price_category;


-- How many months of data are included in the magist database?
SELECT 
    TIMESTAMPDIFF(MONTH,
        MIN(order_purchase_timestamp),
        MAX(order_purchase_timestamp)) AS elapsed_full_months
FROM
    orders;

-- How many sellers are there? How many Tech sellers are there? What percentage of overall sellers are Tech sellers?

SELECT 
    COUNT(DISTINCT s.seller_id) AS tech_sellers,
    (SELECT 
            COUNT(DISTINCT s.seller_id)
        FROM
            order_items oi
                JOIN
            sellers s USING (seller_id)) AS Tot_sellers,
    ROUND((COUNT(DISTINCT s.seller_id) * 100) / (SELECT 
                    COUNT(DISTINCT s.seller_id)
                FROM
                    order_items oi
                        JOIN
                    sellers s USING (seller_id)),
            2) AS percentage_techsellers
FROM
    products p
        JOIN
    product_category_name_translation pt USING (product_category_name)
        JOIN
    order_items oi USING (product_id)
        JOIN
    sellers s USING (seller_id)
WHERE
    pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games');
        
       
        
-- What is the total amount earned by all sellers? What is the total amount earned by all Tech sellers?
SELECT 
    ROUND(SUM(oi.price), 2) AS tot_tech_sales,
    (SELECT 
            ROUND(SUM(oi.price), 2) AS tot_tech_sales
        FROM
            products p
                JOIN
            product_category_name_translation pt USING (product_category_name)
                JOIN
            order_items oi USING (product_id)
                JOIN
            sellers s USING (seller_id)) AS Tot_sales
FROM
    products p
        JOIN
    product_category_name_translation pt USING (product_category_name)
        JOIN
    order_items oi USING (product_id)
        JOIN
    sellers s USING (seller_id)
WHERE
    pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games');
        
-- Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?

SELECT 
    (SELECT 
            COUNT(*)
        FROM
            sellers) registered,
    (SELECT 
            COUNT(DISTINCT seller_id)
        FROM
            order_items) active;
            
-- Can you work out the average monthly income of all sellers? Can you work out the average monthly income of Tech sellers?
-- all sellers

SELECT 
    ROUND(AVG(seller_total_revenue / 25), 2) AS avg_monthly_income_all_sellers
FROM (
    SELECT 
        seller_id,
        SUM(price) AS seller_total_revenue
    FROM 
        order_items
    GROUP BY 
        seller_id
) AS seller_revenues;

-- tech

SELECT 
    ROUND(AVG(seller_total_revenue / 25), 2) AS avg_monthly_income_tech_sellers
FROM (
    SELECT 
        oi.seller_id,
        SUM(oi.price) AS seller_total_revenue
    FROM 
        order_items oi
    JOIN 
        products p USING (product_id)
    JOIN 
        product_category_name_translation pt USING (product_category_name)
    WHERE 
        pt.product_category_name_english IN (
            'telephony', 'watches_gifts', 'computers', 'pc_gamer', 
            'computers_accessories', 'electronics', 'cine_photo', 
            'audio', 'tablets_printing_image', 'consoles_games'
        )
    GROUP BY 
        oi.seller_id
) AS tech_seller_revenues;
select distinct order_status from orders;
-- delivery time
SELECT 
    *,
    TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date) AS time_for_delivery,
    TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_estimated_delivery_date) AS estimated_delivery
FROM
    orders;
    
SELECT 
   
    avg(TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date)) AS avg_time_for_delivery,
    avg(TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_estimated_delivery_date) )AS avg_estimated_delivery
FROM
    orders o join order_items oi using(order_id) join products p using(product_id) join product_category_name_translation pt using(product_category_name) where pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games');

    
SELECT 
    order_status,
    COUNT(*) AS num_orders,
    ROUND((COUNT(*) * 100) / (SELECT 
                    COUNT(*)
                FROM
                    orders),
            2) AS percentage_orders
FROM
    orders
GROUP BY order_status;

select round(sum(payment_value),2),op.payment_type from orders o join order_payments op using(order_id) group by op.payment_type;
-- o join order_items oi using(order_id) join products p using(product_id) join product_category_name_translation pt using(product_category_name);




SELECT 
    op.payment_type,
    o.order_status,
    COUNT(*) AS num_payments, count(*)*100/(select count(*) from orders o 
JOIN order_payments op USING(order_id) WHERE op.payment_type = 'boleto') as percentage
    
FROM orders o 
JOIN order_payments op USING(order_id) 
WHERE op.payment_type = 'boleto' 
GROUP BY op.payment_type, o.order_status;

SELECT 
    orr.review_score, COUNT(*) as num_orders
FROM
    orders o
        JOIN
    order_reviews orr USING (order_id) 
GROUP BY orr.review_score;


SELECT 
    ROUND(AVG(review_score), 2) AS avg_review
FROM
    orders o
        JOIN
    order_reviews orr USING (order_id)
        JOIN
    order_items oi USING (order_id)
        JOIN
    products p USING (product_id)
        JOIN
    product_category_name_translation pt USING (product_category_name)
WHERE
    TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date) > 12
        AND pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games');
-- GROUP BY orr.review_score;
select distinct order_status from orders;


-- order delivery and product size

SELECT 
    ROUND(AVG(product_weight_g), 2) AS avg_weight,
    ROUND(AVG(product_length_cm), 2) AS avg_length,
    ROUND(AVG(product_height_cm), 2) AS avg_height,
    ROUND(AVG(product_width_cm), 2) AS avg_width
FROM
    products p
        JOIN
    product_category_name_translation pt USING (product_category_name)
        JOIN
    order_items oi USING (product_id)
        JOIN
    orders o USING (order_id)
WHERE
    TIMESTAMPDIFF(DAY,
        order_purchase_timestamp,
        order_delivered_customer_date) >12
        AND pt.product_category_name_english IN ('telephony' , 'watches_gifts',
        'computers',
        'pc_gamer',
        'computers_accessories',
        'electronics',
        'cine_photo',
        'audio',
        'tablets_printing_image',
        'consoles_games');
        
	