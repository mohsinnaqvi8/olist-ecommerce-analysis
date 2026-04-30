-- =====================================
-- OLIST E-COMMERCE ANALYSIS (SQL)
-- =====================================
-- Dataset: Brazilian E-commerce (Olist)
-- Goal: Analyze orders, revenue, customer behavior & delivery performance


-- =====================================
-- 1. MONTHLY ORDER TREND
-- =====================================
SELECT 
    strftime('%Y-%m', order_purchase_timestamp) AS month,
    COUNT(*) AS total_orders
FROM orders
GROUP BY month
ORDER BY month;


-- =====================================
-- 2. MONTHLY REVENUE TREND
-- =====================================
SELECT 
    strftime('%Y-%m', o.order_purchase_timestamp) AS month,
    SUM(oi.price + oi.freight_value) AS revenue
FROM orders o
LEFT JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY month
ORDER BY month;


-- =====================================
-- 3. ORDERS BY DAY OF WEEK
-- =====================================
SELECT 
    strftime('%A', order_purchase_timestamp) AS day_name,
    COUNT(*) AS total_orders
FROM orders
GROUP BY day_name
ORDER BY total_orders DESC;


-- =====================================
-- 4. ORDERS BY HOUR OF DAY
-- =====================================
SELECT 
    strftime('%H', order_purchase_timestamp) AS hour,
    COUNT(*) AS total_orders
FROM orders
GROUP BY hour
ORDER BY hour;


-- =====================================
-- 5. AVERAGE DELIVERY TIME
-- =====================================
SELECT 
    AVG(DATEDIFF('day', order_purchase_timestamp, order_delivered_customer_date)) AS avg_delivery_days
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- =====================================
-- 6. DELIVERY DELAY ANALYSIS
-- =====================================
SELECT 
    AVG(DATEDIFF('day', order_estimated_delivery_date, order_delivered_customer_date)) AS avg_delay,
    SUM(CASE 
        WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1 
        ELSE 0 
    END) * 100.0 / COUNT(*) AS late_percentage
FROM orders
WHERE order_delivered_customer_date IS NOT NULL;


-- =====================================
-- 7. TOTAL REVENUE + ORDERS + CUSTOMERS
-- =====================================
SELECT 
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(DISTINCT c.customer_unique_id) AS total_customers,
    SUM(oi.price + oi.freight_value) AS total_revenue
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN customers c ON o.customer_id = c.customer_id;


-- =====================================
-- 8. AVERAGE ORDER VALUE (AOV)
-- =====================================
SELECT 
    SUM(oi.price + oi.freight_value) / COUNT(DISTINCT oi.order_id) AS avg_order_value
FROM order_items oi;


-- =====================================
-- 9. TOP PRODUCT CATEGORIES BY REVENUE
-- =====================================
SELECT 
    p.product_category_name,
    SUM(oi.price + oi.freight_value) AS revenue
FROM order_items oi
LEFT JOIN products p ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue DESC
LIMIT 10;


-- =====================================
-- 10. REPEAT VS ONE-TIME CUSTOMERS
-- =====================================
WITH customer_orders AS (
    SELECT 
        c.customer_unique_id,
        COUNT(o.order_id) AS total_orders
    FROM orders o
    LEFT JOIN customers c 
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_unique_id
)

SELECT 
    CASE 
        WHEN total_orders = 1 THEN 'One-time'
        ELSE 'Repeat'
    END AS customer_type,
    COUNT(*) AS total_customers
FROM customer_orders
GROUP BY customer_type;


-- =====================================
-- 11. REVENUE CONTRIBUTION (%) BY CATEGORY
-- =====================================
SELECT 
    p.product_category_name,
    SUM(oi.price + oi.freight_value) AS revenue,
    SUM(oi.price + oi.freight_value) * 100.0 / 
        SUM(SUM(oi.price + oi.freight_value)) OVER() AS revenue_percentage
FROM order_items oi
LEFT JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue DESC;


-- =====================================
-- 12. CUMULATIVE REVENUE (PARETO ANALYSIS)
-- =====================================
SELECT 
    p.product_category_name,
    SUM(oi.price + oi.freight_value) AS revenue,
    SUM(SUM(oi.price + oi.freight_value)) OVER (ORDER BY SUM(oi.price + oi.freight_value) DESC) 
        AS cumulative_revenue
FROM order_items oi
LEFT JOIN products p 
    ON oi.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY revenue DESC;