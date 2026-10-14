-- =====================================================================
-- ENIAC x MAGIST case study
--
-- Time period: 1 April 2017 to 31 March 2018 (same 12 months as Eniac's figures)
--
-- "Tech" = these 10 product categories (chosen by the team):
--   audio, cine_photo, computers, computers_accessories, consoles_games,
--   electronics, pc_gamer, tablets_printing_image, telephony, watches_gifts

-- =====================================================================

USE magist;

-- =====================================================================
-- PART 1: REVENUE
-- =====================================================================

-- ---------------------------------------------------------------------
-- Tech revenue over 12 months and per month
-- ---------------------------------------------------------------------
-- Result: about 1,835,546 over 12 months (= €1.84M)
--         about 152,962 a month (= €153k)
SELECT
    ROUND(SUM(oi.price))      AS tech_revenue_12_months,
    ROUND(SUM(oi.price) / 12) AS tech_revenue_per_month
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01';


-- ---------------------------------------------------------------------
-- Eniac compared with all Magist tech revenue
-- ---------------------------------------------------------------------
-- Eniac's figures (€1.17M a month, €14M a year) come from the case brief.
-- Result: Eniac earns about 7.6 times more a month.
--         Magist tech revenue is about 13% of Eniac's monthly revenue.
SELECT
    ROUND(1170000 / 152962, 1)       AS eniac_times_bigger,
    ROUND(152962 / 1170000 * 100, 1) AS magist_tech_as_pct_of_eniac;


-- =====================================================================
-- PART 2: PRICES
-- =====================================================================

-- ---------------------------------------------------------------------
-- Average price of a tech item
-- ---------------------------------------------------------------------
-- Result: about 130 (14,430 tech items)
SELECT
    ROUND(AVG(oi.price), 2) AS avg_tech_item_price,
    COUNT(*)                AS tech_items
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01';


-- ---------------------------------------------------------------------
-- Average price of any item (all categories)
-- ---------------------------------------------------------------------
-- Result: about 118 (68,718 items)
SELECT
    ROUND(AVG(oi.price), 2) AS avg_item_price_all,
    COUNT(*)                AS all_items
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01';


-- ---------------------------------------------------------------------
-- Eniac's average price compared with Magist tech
-- ---------------------------------------------------------------------
-- Eniac's €540 comes from the case brief.
-- Result: about 4.2 (said as "about 4 times")
SELECT ROUND(540 / 130, 1) AS eniac_price_times_magist;


-- =====================================================================
-- PART 3: BOX PLOT OF TECH ITEM PRICES
-- =====================================================================
-- How a box plot works:
--   - Sort all tech item prices from cheapest to most expensive
--   - Q1 (bottom of box)  = the price a quarter of the way up the list
--   - Median (line)       = the price halfway up the list
--   - Q3 (top of box)     = the price three quarters of the way up the list
--   - Upper whisker limit = Q3 + 1.5 x (Q3 - Q1)
--   - Anything above the whisker limit is an "outlier" (unusually expensive)

-- ---------------------------------------------------------------------
-- Box plot: number of items, cheapest and most expensive
-- ---------------------------------------------------------------------
-- Result: 14,430 items, min 3.90, max 4,099.99
SELECT
    COUNT(*)      AS tech_items,
    MIN(oi.price) AS min_price,
    MAX(oi.price) AS max_price
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01';


-- ---------------------------------------------------------------------
-- Box plot: Q1 (bottom of the box)
-- ---------------------------------------------------------------------
-- 25% of 14,430 items = item number 3,608 in the sorted list.
-- OFFSET 3607 skips the first 3,607 rows and returns the next one.
-- Result: 29
SELECT oi.price AS q1_price
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
ORDER BY oi.price
LIMIT 1 OFFSET 3607;


-- ---------------------------------------------------------------------
-- Box plot: median (line in the box)
-- ---------------------------------------------------------------------
-- 14,430 is an even number, so the middle sits between items 7,215 and
-- 7,216. OFFSET 7214 with LIMIT 2 returns both. Both are 65.
-- Result: 65 (half of tech items cost 65 or less)
SELECT oi.price AS median_price
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
ORDER BY oi.price
LIMIT 2 OFFSET 7214;


-- ---------------------------------------------------------------------
-- Box plot: Q3 (top of the box)
-- ---------------------------------------------------------------------
-- 75% of 14,430 items = item number 10,823 in the sorted list.
-- Result: 149.90 (shown as €150)
SELECT oi.price AS q3_price
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
ORDER BY oi.price
LIMIT 1 OFFSET 10822;


-- ---------------------------------------------------------------------
-- Box plot: upper whisker limit (the "expensive" cut-off)
-- ---------------------------------------------------------------------
-- Box height = Q3 - Q1 = 150 - 29 = 121
-- Whisker limit = Q3 + 1.5 x box height = 150 + 181.5 = 331.5
-- Result: 331.5 (shown as €331)
SELECT
    150 - 29              AS box_height,
    150 + 1.5 * (150 - 29) AS upper_whisker_limit;


-- ---------------------------------------------------------------------
-- Box plot: where the upper whisker actually ends
-- ---------------------------------------------------------------------
-- The whisker stops at the most expensive item that is still inside the limit.
-- Result: 329.99 (about €330)
SELECT MAX(oi.price) AS upper_whisker_end
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
  AND oi.price <= 331.5;


-- ---------------------------------------------------------------------
-- Price bands: cheap, mid and expensive
-- ---------------------------------------------------------------------
-- Cheap     = 65 or less (at or below the median)
-- Mid       = over 65 up to 331 (up to the whisker limit)
-- Expensive = over 331 (outliers)
-- Result: Cheap 7,244 (50.2%), Mid 6,178 (42.8%), Expensive 1,008 (7.0%)
SELECT
    SUM(CASE WHEN oi.price <= 65 THEN 1 ELSE 0 END)                    AS cheap_items,
    SUM(CASE WHEN oi.price > 65 AND oi.price <= 331 THEN 1 ELSE 0 END) AS mid_items,
    SUM(CASE WHEN oi.price > 331 THEN 1 ELSE 0 END)                    AS expensive_items,
    ROUND(SUM(CASE WHEN oi.price <= 65 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1)                    AS cheap_pct,
    ROUND(SUM(CASE WHEN oi.price > 65 AND oi.price <= 331 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS mid_pct,
    ROUND(SUM(CASE WHEN oi.price > 331 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1)                    AS expensive_pct
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01';


-- ---------------------------------------------------------------------
-- Tech items cheaper than Eniac's €540 average
-- ---------------------------------------------------------------------
-- Result: 639 items cost €540 or more, so Eniac's average is higher than
--         about 95.6% of Magist tech items (said as "95%")
SELECT
    SUM(CASE WHEN oi.price >= 540 THEN 1 ELSE 0 END)                       AS items_540_or_more,
    ROUND(SUM(CASE WHEN oi.price < 540 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS pct_cheaper_than_eniac
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01';


-- ---------------------------------------------------------------------
-- Tech items above €1,000 (not shown on the chart axis)
-- ---------------------------------------------------------------------
-- Result: 195
SELECT COUNT(*) AS items_over_1000
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
JOIN product_category_name_translation t
    ON p.product_category_name = t.product_category_name
WHERE t.product_category_name_english IN
      ('audio', 'cine_photo', 'computers', 'computers_accessories',
       'consoles_games', 'electronics', 'pc_gamer',
       'tablets_printing_image', 'telephony', 'watches_gifts')
  AND o.order_status NOT IN ('canceled', 'unavailable')
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
  AND oi.price > 1000;


-- =====================================================================
-- PART 4: DELIVERIES
-- =====================================================================
-- Deliveries are counted per ORDER, not per item.
-- A "tech order" = an order with at least one tech item in it.
-- The subquery (WHERE o.order_id IN (...)) finds those orders, so each
-- order is only counted once, even if it has several items.

-- ---------------------------------------------------------------------
-- On-time and late tech orders
-- ---------------------------------------------------------------------

-- Result: 12,699 orders; 11,582 on time (91.2%); 1,117 late (8.8%)
SELECT
    COUNT(*) AS delivered_tech_orders,
    SUM(CASE WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) AS on_time_orders,
    SUM(CASE WHEN DATE(o.order_delivered_customer_date) >  DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) AS late_orders,
    ROUND(SUM(CASE WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS on_time_pct,
    ROUND(SUM(CASE WHEN DATE(o.order_delivered_customer_date) >  DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS late_pct
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
  AND o.order_id IN (
        SELECT oi.order_id
        FROM order_items oi
        JOIN products p
            ON oi.product_id = p.product_id
        JOIN product_category_name_translation t
            ON p.product_category_name = t.product_category_name
        WHERE t.product_category_name_english IN
              ('audio', 'cine_photo', 'computers', 'computers_accessories',
               'consoles_games', 'electronics', 'pc_gamer',
               'tablets_printing_image', 'telephony', 'watches_gifts')
  );


-- ---------------------------------------------------------------------
-- Average delivery time and average estimated delivery time
-- ---------------------------------------------------------------------
-- DATEDIFF(later date, earlier date) = number of days between them.
-- Result: actual 14.3 days (said as 14), estimated 24.9 days (said as 25)
SELECT
    COUNT(*) AS delivered_tech_orders,
    ROUND(AVG(DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)), 1) AS avg_days_to_deliver,
    ROUND(AVG(DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp)), 1) AS avg_days_estimated
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
  AND o.order_id IN (
        SELECT oi.order_id
        FROM order_items oi
        JOIN products p
            ON oi.product_id = p.product_id
        JOIN product_category_name_translation t
            ON p.product_category_name = t.product_category_name
        WHERE t.product_category_name_english IN
              ('audio', 'cine_photo', 'computers', 'computers_accessories',
               'consoles_games', 'electronics', 'pc_gamer',
               'tablets_printing_image', 'telephony', 'watches_gifts')
  );


-- ---------------------------------------------------------------------
-- Orders and late % per month (data for the orders vs late % chart)
-- ---------------------------------------------------------------------
-- Result: March 2018 = 1,684 orders, 20.0% late
--         (highest month in the period)
SELECT
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
    COUNT(*) AS delivered_tech_orders,
    SUM(CASE WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) AS late_orders,
    ROUND(SUM(CASE WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS late_pct
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
  AND o.order_id IN (
        SELECT oi.order_id
        FROM order_items oi
        JOIN products p
            ON oi.product_id = p.product_id
        JOIN product_category_name_translation t
            ON p.product_category_name = t.product_category_name
        WHERE t.product_category_name_english IN
              ('audio', 'cine_photo', 'computers', 'computers_accessories',
               'consoles_games', 'electronics', 'pc_gamer',
               'tablets_printing_image', 'telephony', 'watches_gifts')
  )
GROUP BY order_month
ORDER BY order_month;


-- ---------------------------------------------------------------------
-- Late % in Black Friday week
-- ---------------------------------------------------------------------
-- Black Friday 2017 was Friday 24 November.
-- Black Friday week = orders placed 24 to 30 November 2017 (7 days).
-- Result: 698 orders, 16.0% late
SELECT
    COUNT(*) AS delivered_tech_orders,
    SUM(CASE WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) AS late_orders,
    ROUND(SUM(CASE WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS late_pct
FROM orders o
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-11-24'
  AND o.order_purchase_timestamp <  '2017-12-01'
  AND o.order_id IN (
        SELECT oi.order_id
        FROM order_items oi
        JOIN products p
            ON oi.product_id = p.product_id
        JOIN product_category_name_translation t
            ON p.product_category_name = t.product_category_name
        WHERE t.product_category_name_english IN
              ('audio', 'cine_photo', 'computers', 'computers_accessories',
               'consoles_games', 'electronics', 'pc_gamer',
               'tablets_printing_image', 'telephony', 'watches_gifts')
  );


-- ---------------------------------------------------------------------
-- Late % in a normal month (the middle month of the 12)
-- ---------------------------------------------------------------------
-- Step 1 (inner query): late % for each of the 12 months.
-- Step 2: sort the 12 months from lowest to highest late %.
-- Step 3: the middle of 12 values sits between month 6 and month 7,
--         so skip 5 months (OFFSET 5), take 2 (LIMIT 2) and average them.
-- Result: 4.8% (said as 5%)
SELECT ROUND(AVG(late_pct), 1) AS normal_month_late_pct
FROM (
    SELECT late_pct
    FROM (
        SELECT
            DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
            SUM(CASE WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) / COUNT(*) * 100 AS late_pct
        FROM orders o
        WHERE o.order_status = 'delivered'
          AND o.order_delivered_customer_date IS NOT NULL
          AND o.order_purchase_timestamp >= '2017-04-01'
          AND o.order_purchase_timestamp <  '2018-04-01'
          AND o.order_id IN (
                SELECT oi.order_id
                FROM order_items oi
                JOIN products p
                    ON oi.product_id = p.product_id
                JOIN product_category_name_translation t
                    ON p.product_category_name = t.product_category_name
                WHERE t.product_category_name_english IN
                      ('audio', 'cine_photo', 'computers', 'computers_accessories',
                       'consoles_games', 'electronics', 'pc_gamer',
                       'tablets_printing_image', 'telephony', 'watches_gifts')
          )
        GROUP BY order_month
    ) AS monthly
    ORDER BY late_pct
    LIMIT 2 OFFSET 5
) AS middle_two;


-- =====================================================================
-- PART 5: REVIEWS
-- =====================================================================

-- ---------------------------------------------------------------------
-- Review scores: late orders compared with on-time orders
-- ---------------------------------------------------------------------
-- Same delivered tech orders as above, joined to their reviews.
-- Result: Late    = 1,108 reviews, 2.2 stars on average, 55.7% are 1-star
--         On time = 11,479 reviews, 4.2 stars on average, 7.5% are 1-star
--         Total   = 12,587 reviews
--         55.7 / 7.5 = about 7, so a late order is about 7 times more
--         likely to get a 1-star review.
SELECT
    CASE
        WHEN DATE(o.order_delivered_customer_date) > DATE(o.order_estimated_delivery_date) THEN 'Late'
        ELSE 'On time'
    END AS delivery_status,
    COUNT(*) AS reviews,
    ROUND(AVG(r.review_score), 1) AS avg_review_score,
    SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) AS one_star_reviews,
    ROUND(SUM(CASE WHEN r.review_score = 1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 1) AS one_star_pct
FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
  AND o.order_id IN (
        SELECT oi.order_id
        FROM order_items oi
        JOIN products p
            ON oi.product_id = p.product_id
        JOIN product_category_name_translation t
            ON p.product_category_name = t.product_category_name
        WHERE t.product_category_name_english IN
              ('audio', 'cine_photo', 'computers', 'computers_accessories',
               'consoles_games', 'electronics', 'pc_gamer',
               'tablets_printing_image', 'telephony', 'watches_gifts')
  )
GROUP BY delivery_status;


-- ---------------------------------------------------------------------
-- Review score spread: late compared with on time (data for the chart)
-- ---------------------------------------------------------------------
-- Number of reviews at each star level (1 to 5) for late and on-time orders.
SELECT
    r.review_score,
    SUM(CASE WHEN DATE(o.order_delivered_customer_date) >  DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) AS late_reviews,
    SUM(CASE WHEN DATE(o.order_delivered_customer_date) <= DATE(o.order_estimated_delivery_date) THEN 1 ELSE 0 END) AS on_time_reviews
FROM orders o
JOIN order_reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
  AND o.order_id IN (
        SELECT oi.order_id
        FROM order_items oi
        JOIN products p
            ON oi.product_id = p.product_id
        JOIN product_category_name_translation t
            ON p.product_category_name = t.product_category_name
        WHERE t.product_category_name_english IN
              ('audio', 'cine_photo', 'computers', 'computers_accessories',
               'consoles_games', 'electronics', 'pc_gamer',
               'tablets_printing_image', 'telephony', 'watches_gifts')
  )
GROUP BY r.review_score
ORDER BY r.review_score;


-- ---------------------------------------------------------------------
-- Reviews mentioning Apple, iPhone or Lightning (all reviews, all dates)
-- ---------------------------------------------------------------------
-- Searches both the review title and the review message.
-- Result: 13 reviews
SELECT
    r.review_score,
    DATE(o.order_purchase_timestamp) AS order_date,
    r.review_comment_title,
    r.review_comment_message
FROM order_reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE r.review_comment_title   LIKE '%apple%'
   OR r.review_comment_message LIKE '%apple%'
   OR r.review_comment_title   LIKE '%iphone%'
   OR r.review_comment_message LIKE '%iphone%'
   OR r.review_comment_title   LIKE '%lightning%'
   OR r.review_comment_message LIKE '%lightning%'
ORDER BY order_date;


-- ---------------------------------------------------------------------
-- 1-star reviews mentioning Apple, iPhone or Lightning (12-month period)
-- ---------------------------------------------------------------------
-- Same search, narrowed to 1-star reviews from April 2017 to March 2018.
-- Result: 4 reviews. 3 are about fake or wrong Apple products
-- (January 2018 x2, March 2018). The 4th is about a bad mp3 player,
-- not Apple, so it was not used.
-- Reviews are in Portuguese; they were translated into English.
SELECT
    r.review_score,
    DATE(o.order_purchase_timestamp) AS order_date,
    r.review_comment_title,
    r.review_comment_message
FROM order_reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE (   r.review_comment_title   LIKE '%apple%'
       OR r.review_comment_message LIKE '%apple%'
       OR r.review_comment_title   LIKE '%iphone%'
       OR r.review_comment_message LIKE '%iphone%'
       OR r.review_comment_title   LIKE '%lightning%'
       OR r.review_comment_message LIKE '%lightning%')
  AND r.review_score = 1
  AND o.order_purchase_timestamp >= '2017-04-01'
  AND o.order_purchase_timestamp <  '2018-04-01'
ORDER BY order_date;
