-- 1. What is the total amount each customer spent in the restaurant?
SELECT customer_id,SUM(price) As Total
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id,COUNT(DISTINCT order_date) As Days
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer? ******************
WITH customer_first_purchase AS(
	SELECT s.customer_id, MIN(s.order_date) AS first_purchase_date
	FROM sales s
	GROUP BY s.customer_id
)
SELECT cte.customer_id, cte.first_purchase_date, m.product_name
FROM customer_first_purchase cfp
INNER JOIN sales s ON s.customer_id = cte.customer_id
AND cte.first_purchase_date = s.order_date
INNER JOIN menu m on m.product_id = s.product_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT menu.product_name,COUNT(sales.product_id) as Total
FROM sales
JOIN menu
ON sales.product_id = menu.product_id
GROUP BY menu.product_name
ORDER BY total DESC
LIMIT 1;
-- 5. Which item was the most popular for each customer? **********
WITH customer_popularity AS (
    SELECT s.customer_id, m.product_name, COUNT(*) AS purchase_count,
       ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(*) DESC) AS 'rank'
    FROM sales s
    INNER JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id, m.product_name
)
SELECT customer_id, product_name, purchase_count
FROM customer_popularity
ORDER BY purchase_count DESC;

-- 6. Which item was purchased first by the customer after they became a member?
WITH first_purchases_after_membership AS (SELECT s.customer_id,MIN(order_date) AS first_purchased_date
	FROM members mb
	JOIN sales s
	ON mb.customer_id = s.customer_id
	WHERE s.order_date >= mb.join_date
	GROUP BY s.customer_id)
    SELECT fpam.customer_id,m.product_name
    FROM first_purchases_after_membership fpam
    JOIN sales s
    ON s.customer_id = fpam.customer_id
    AND fpam.first_purchased_date = s.order_date
    JOIN menu m 
    ON m.product_id = s.product_id;
    
    -- 7. Which item was purchased just before the customer became a member?
   WITH last_purchase_before_membership AS (SELECT s.customer_id,MAX(s.order_date) AS last_purchase_date
   FROM sales s
   JOIN members mb
   ON s.customer_id = mb.customer_id
   WHERE s.order_date < mb.join_date
   GROUP BY s.customer_id)
   SELECT lpbm.customer_id,product_name
   FROM last_purchase_before_membership lpbm
   JOIN sales s 
   ON lpbm.customer_id = s.customer_id
   AND lpbm.last_purchase_date = s.order_date
   JOIN menu m ON s.product_id = m.product_id;
-- 8. What is the total items and amount spent for each member before they became a member?
SELECT s.customer_id,COUNT(*)AS Total_items,SUM(price) As Total_spend
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
JOIN members mb
ON s.customer_id = mb.customer_id
WHERE s.order_date < mb.join_date
GROUP BY s.customer_id;
-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT s.customer_id,SUM(
CASE 
WHEN m.product_name = 'Sushi' THEN price*20
ELSE price *10
END) AS Points
FROM menu m
JOIN sales s
ON m.product_id = s.product_id
GROUP BY s.customer_id;

/* 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - 
how many points do customer A and B have at the end of January?*/   
SELECT s.customer_id,SUM(
	CASE
    WHEN s.order_date BETWEEN mb.join_date AND date_add('2021-01-31',INTERVAL 7 DAY) THEN m.price*20
    WHEN m.product_name = 'sushi' THEN m.price*20 
        ELSE m.price*10 
    END) AS total_points
FROM sales s
JOIN menu m
ON s.product_id = m.product_id
LEFT JOIN members mb ON s.customer_id = mb.customer_id
WHERE s.customer_id IN ('A', 'B') AND s.order_date <= '2021-01-31'
-- WHERE s.customer_id = mb.customer_id AND s.order_date <= '2021-01-31'
GROUP BY s.customer_id;

-- 11. Recreate the table output using the available data
SELECT s.customer_id,s.order_date,m.product_name,m.price,
CASE
WHEN s.order_date >= mb.join_date THEN "Y"
ELSE "N"
END AS "member"
FROM menu m
JOIN sales s
ON m.product_id=s.product_id
LEFT JOIN members mb
ON mb.customer_id = s.customer_id
ORDER BY s.customer_id,s.order_date;

-- 12. Rank all the things:

WITH customer_data AS 
	(SELECT s.customer_id,s.order_date,m.product_name,m.price,
	CASE
	WHEN s.order_date >= mb.join_date THEN "Y"
	ELSE "N"
	END AS "member"
	FROM menu m
	JOIN sales s
	ON m.product_id=s.product_id
	LEFT JOIN members mb
	ON mb.customer_id = s.customer_id)
    SELECT *,
    CASE
    WHEN member = "N" THEN NULL
    ELSE RANK () OVER (PARTITION BY customer_id,member
    ORDER BY order_date) end AS ranking
    FROM customer_data
    ORDER BY s.customer_id,s.order_date;

