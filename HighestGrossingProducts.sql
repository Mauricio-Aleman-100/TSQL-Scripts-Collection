Problem Statement: Top Two Highest-Grossing Products

As a Business Intelligence Analyst at Amazon, the objective is to analyze sales performance for the year 2022. 
The manager requires a focused report identifying the top two highest-grossing products within each distinct product category.

product_spend: Contains category, product, spend (transaction amount), and transaction_date.

Requirements:

Time Constraint: Only consider transactions that occurred during the calendar year 2022.
Aggregation: Calculate the total spend (gross revenue) for every unique product within its category.
Grouping & Ranking: Within each category, rank the products based on their total spend (highest spend = rank 1).
Filtering: Select only those products that achieve a rank of 1 or 2.
Output: Display the category, product, and the calculated total_spend.


WITH ViewTotalSpend AS (
SELECT 
  category,
  product,
  SUM(spend) as Total_spend
FROM product_spend
WHERE 
  transaction_date BETWEEN '2022-01-01 00:00:00' AND '2022-12-31 23:59:59'
GROUP BY 
  category, 
  product
),
ProductsRank AS (
SELECT 
  category,
  product,
  total_spend,
  
  RANK() OVER(
    PARTITION BY category
    ORDER BY total_spend DESC
    ) AS product_rank
    
FROM ViewTotalSpend
)
SELECT
  category,
  product,
  total_spend
FROM ProductsRank
WHERE product_rank <=2
ORDER BY 
  category,
  total_spend DESC;





  
