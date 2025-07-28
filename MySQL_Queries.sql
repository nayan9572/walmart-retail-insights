-- Title 
/*
   Sales Performance Analysis and Insights for Walmart Stores
   Using Advanced MySQL Techniques"
*/

-- Problem statement 
/*
   Walmart operates a vast network of stores across different
   regions, generating significant transactional data. However,
   the ability to leverage this data for strategic decision-making
   remains a challenge. Analyzing sales performance, customer
   segmentation, and operational trends requires robust tools 
   and advanced techniques. This project aims to uncover actionable
   insights from Walmart's sales data to optimize business strategies
   and improve efficiency.
*/
-- Objective 
/*
   The primary objective of this project is to use advanced MySQL
   queries and techniques to analyze Walmart's historical sales data. 
   The analysis focuses on:

1. Identifying top-performing branches and product lines.

2. Classifying customers into segments based on spending patterns.

3. Detecting anomalies to improve operational accuracy.

4. Analyzing payment methods and customer preferences.

5. Highlighting trends in sales distribution by gender and customer type.

6. Detecting repeat customers and rewarding loyalty.

7. Providing actionable insights to guide Walmart’s business strategy.
*/

-- Task 1: Identifying the Top Branch by Sales Growth Rate

/*
   This query calculates the total sales for each branch per month
   and then calculates the month-over-month growth rate to identify
   the top-performing branch in terms of sales growth.
*/
WITH MonthlySales As (SELECT branch, 
                Date_Format(str_to_date(Date, '%d-%m-%y'),  '%y-%m') AS 
                Sale_Month, 
                SUM(Total) AS Total_Sales
		FROM 
                WalmartSales 
		GROUP BY 
                branch,
                Sale_Month
),
PreviousSales As (SELECT  branch, Sale_Month,Total_Sales, 
Lag(Total_Sales, 1, 0)
 OVER (PARTITION BY branch ORDER BY Sale_Month) AS prev_month_sales
          FROM MonthlySales)
SELECT branch, Sale_Month,Total_Sales, 
           (Total_Sales - prev_month_sales) / prev_month_sales * 100 AS Growth_Rate
FROM 
          PreviousSales
ORDER BY 
         Growth_Rate DESC
         LIMIT 1;
-- Insight: This query calculates the percentage growth rate,
-- allowing Walmart to identify which branches are expanding
-- their sales most rapidly. This information is crucial for
-- resource allocation and strategic planning.

-- Task 2: Finding the Most Profitable Product Line for Each Branch

/*
   This query calculates the profit for each 'Product line' within each 'Branch'
   using 'gross income' and 'cogs' (Cost of Goods Sold). It then identifies the
   'Product line' with the highest profit for each 'Branch'.
*/

WITH ProductLineProfit AS (SELECT Branch, Product_line,
        SUM(`gross income` - cogs) AS profit
    FROM
        WalmartSales
    GROUP BY
        Branch,
        Product_line
),
RankedProfit AS (SELECT Branch, Product_line, profit,
        ROW_NUMBER() OVER (PARTITION BY Branch ORDER BY profit DESC) AS rn
    FROM
        ProductLineProfit
)
SELECT Branch, Product_line,
    profit
FROM
    RankedProfit
WHERE
    rn = 1;

-- Insight: By determining the most profitable 'Product line' in each 'Branch', Walmart can make informed decisions
-- about inventory management, product placement, and promotional activities to maximize profitability at a local level.

-- Task 3: Analyzing Customer Segmentation Based on Spending

/*
   This query segments customers into High, Medium, and Low spenders based on their
   total purchase amount ('Total'). It uses quartiles to define the spending tiers.
*/

WITH CustomerSpending AS ( SELECT `Customer ID`,
        SUM(Total) AS total_spending
    FROM
        WalmartSales
    GROUP BY
        `Customer ID`
),
SpendingPercentiles AS ( SELECT `Customer ID`, Total_spending, PERCENT_RANK() OVER (ORDER BY total_spending) AS spending_percentile
    FROM
        CustomerSpending )
SELECT `Customer ID`, Total_spending,
    CASE
        WHEN spending_percentile >= 0.66 THEN 'High'
        WHEN spending_percentile >= 0.33 THEN 'Medium'
        ELSE 'Low'
    END AS spending_tier
FROM
    SpendingPercentiles;

-- Insight: Segmenting customers based on their spending ('Total') allows Walmart to understand different customer
-- value groups. This enables targeted marketing campaigns, personalized offers, and loyalty programs tailored to
-- high, medium, and low-spending customers.

-- Task 4: Detecting Anomalies in Sales Transactions

/*
   This query identifies sales transactions that are considered anomalies by comparing
   the 'Total' sales amount to the average 'Total' sales for the respective 'product_line'.
   Anomalies are defined as those significantly deviating (e.g., 2 standard deviations)
   from the mean. For simplicity, I'm using a factor based on the average.
*/

WITH ProductLineAvgSales AS ( SELECT product_line,
 AVG(Total) AS avg_sales, 
STDDEV(Total) AS std_dev_sales
    FROM
        walmartsales
    GROUP BY
        product_line
)
SELECT `Invoice ID`, s.product_line, s.Total, p.avg_sales, p.std_dev_sales,
    CASE
        WHEN s.Total > p.avg_sales + 2 * p.std_dev_sales THEN 'High Anomaly'
        WHEN s.Total < p.avg_sales - 2 * p.std_dev_sales THEN 'Low Anomaly'
        ELSE 'Normal'
    END AS anomaly_status
FROM
    walmartsales s
JOIN
    ProductLineAvgSales p ON s.product_line = p.product_line;

-- Insight: Identifying anomalies in 'Total' sales for each 'product_line' can help detect potential data entry errors,
-- fraudulent activities, or unusual market events that require investigation.

-- Task 5: Most Popular Payment Method by City

/*
   This query determines the most popular payment method in each city
   by counting the occurrences of each payment method and selecting
   the one with the highest frequency.
*/

WITH PaymentMethodCounts AS ( SELECT city, payment,
        COUNT(*) AS method_count,
        ROW_NUMBER() OVER (PARTITION BY city ORDER BY COUNT(*) DESC) as rn
    FROM
   WalmartSales
    GROUP BY
        city,
        payment
)
SELECT
    city,
    payment,
    method_count
FROM
    PaymentMethodCounts
WHERE
    rn = 1;

-- Insight:  Understanding payment method preferences by city
-- allows Walmart to tailor its payment options and marketing
-- strategies to local customer behavior, potentially increasing
-- customer satisfaction and sales.

-- Task 6: Monthly Sales Distribution by Gender

/*
   This query analyzes the sales distribution between male and female
   customers on a monthly basis to identify any gender-specific
   sales trends.
*/

SELECT
    DATE_FORMAT(str_to_date(Date, '%d-%m-%y'),  '%y-%m') AS sale_month,
    gender,
    SUM(Total) AS total_sales
FROM
    WalmartSales
GROUP BY
    sale_month,
    gender
ORDER BY
    sale_month,
    gender;

-- Insight:  Analyzing sales by gender helps Walmart understand
-- customer demographics and tailor marketing campaigns and
-- product offerings to specific gender preferences.

-- Task 7: Best Product Line by Customer Type

/*
   This query identifies the product lines preferred by different
   customer types (Member vs. Normal) to understand customer
   preferences and tailor product offerings.
*/

WITH CustomerProductLineSales AS (
    SELECT customer_type, product_line,
        SUM(Total) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY customer_type ORDER BY SUM(Total) DESC) as rn
    FROM
        WalmartSales
    GROUP BY
        customer_type,
        product_line
)
SELECT
    customer_type,
    product_line,
    total_sales
FROM
    CustomerProductLineSales
WHERE
    rn = 1;

-- Insight:  Understanding product line preferences by customer
-- type enables Walmart to personalize marketing and promotions,
-- improving customer retention and sales.

-- Task 8: Identifying Repeat Customers
/*
   This query identifies customers who have made more than one purchase based on their
   'Customer ID'.
*/
SELECT
    ws1.`Customer ID`,
    MIN(STR_TO_DATE(ws1.Date, '%d-%m-%Y')) AS First_Purchase_Date,
    MIN(STR_TO_DATE(ws2.Date, '%d-%m-%Y')) AS Second_Purchase_Date,
    COUNT(*) AS Purchase_Frequency
FROM
    WalmartSales ws1
JOIN
    WalmartSales ws2 ON ws1.`Customer ID` = ws2.`Customer ID`
    AND STR_TO_DATE(ws2.Date, '%d-%m-%Y') > STR_TO_DATE(ws1.Date, '%d-%m-%Y')
    AND DATEDIFF(
        STR_TO_DATE(ws2.Date, '%d-%m-%Y'),
        STR_TO_DATE(ws1.Date, '%d-%m-%Y')
    ) <= 30
GROUP BY
    ws1.`Customer ID`
HAVING
    COUNT(*) > 0;
-- Insight: Identifying repeat customers based on multiple transactions is crucial for building loyalty programs and
-- understanding customer retention. These customers are valuable assets for Walmart.

-- Task 9: Finding Top 5 Customers by Sales Volume

/*
   This query identifies the top 5 customers who have generated the highest 'Total'
   sales revenue.
*/

SELECT
    `Customer ID`,
    SUM(Total) AS total_sales
FROM
  WalmartSales
GROUP BY
    `Customer ID`
ORDER BY
    total_sales DESC
LIMIT 5;

-- Insight: Identifying the top 5 customers by 'Total' sales volume allows Walmart to recognize and potentially
-- reward its most valuable customers, fostering stronger relationships and encouraging continued business.

-- Task 10: Analyzing Sales Trends by Day of the Week

/*
   This query analyzes the 'Total' sales trends by the day of the week to determine
   which days have the highest sales.
*/

SELECT
                DayName(str_to_date(Date, '%d-%m-%y')) AS Day_of_Week,
    SUM(Total) AS total_sales
FROM
    WalmartSales
GROUP BY
  Day_of_Week
ORDER BY
    SUM(Total) DESC;

-- Insight: Understanding daily sales trends helps Walmart optimize staffing levels, schedule promotions, 
-- and manage inventory based on peak and off-peak sales days.