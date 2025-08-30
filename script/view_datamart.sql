-- =========================================
-- Projek Cafe Analytic Views for Superset

/*
-- =========================================
Category Report (Widget):
A. Customer Insights

- Top Customers by Revenue (view_top_customers)
- Average Order Value by Customer (view_avg_order_value)
- Customer Gender Analysis (view_customer_gender)
- Customer Membership Level Analysis (view_membership_revenue)
- Customer Lifetime Value (CLV) (view_customer_ltv)
- Repeat Purchase Frequency (view_repeat_purchase)
- High-Value Customers (view_high_value_customers)
- New vs Returning Customers (view_new_vs_returning)

B. Product Performance

- Top Products by Revenue (view_top_products)
- Revenue by Product Category (view_revenue_category)
- Product Size Performance (view_product_size)
- Top Product by Store (view_top_product_store)
- Category Trends Over Time (view_category_trends)

C. Store Performance

- Revenue by Store (view_revenue_store)
- Store Customer Count (view_store_customers)
- Store Performance by Month (view_store_performance)

D. Time-Based Trends

- Revenue Over Time (view_revenue_time)
- Orders by Weekday (view_orders_weekday)
- Orders by Hour (view_orders_by_hour)
- Weekend vs Weekday Revenue (view_weekend_vs_weekday)
- Monthly Repeat Orders (view_monthly_repeat_orders)

E. Discount & Promotion Analysis

- Discount Usage (view_discount_usage)
- Top Discounted Products (view_top_discounted_products)
- Discount Effectiveness (view_discount_effectiveness)


-- =========================================
-- Dashboard Design
-- Dashboards combine multiple reports or KPIs into an executive view.

📊 Executive Dashboard (C-Level)

Purpose: High-level KPIs for revenue, orders, customers
Widgets:
- Total Revenue (from view_revenue_time)
- Top 5 Customers (from view_top_customers)
- Top 5 Products (from view_top_products)
- Revenue Trend by Month (from view_revenue_time)
- Discount vs Full Price Revenue (from view_discount_effectiveness)

👥 Customer 360 Dashboard

Purpose: Complete customer profile & behavior insights
Widgets:
- CLV Distribution (from view_customer_ltv)
- Repeat Purchase Frequency (from view_repeat_purchase)
- New vs Returning Customers (from view_new_vs_returning)
- Gender Analysis (from view_customer_gender)
- Membership Revenue (from view_membership_revenue)

📦 Product Performance Dashboard

Purpose: Track product sales and trends
Widgets:
- Top Products (from view_top_products)
- Category Trends (from view_category_trends)
- Product Size Performance (from view_product_size)
- Discounted Products Ranking (from view_top_discounted_products)

🏪 Store Performance Dashboard

Purpose: Store-level performance monitoring
Widgets:
- Revenue by Store (from view_revenue_store)
- Unique Customers per Store (from view_store_customers)
- Store Monthly Trend (from view_store_performance)
- Top Product per Store (from view_top_product_store)

⏳ Time & Seasonality Dashboard

Purpose: Understand when revenue & orders peak
Widgets:
Revenue Over Time (from view_revenue_time)
Orders by Weekday (from view_orders_weekday)
Orders by Hour (from view_orders_by_hour)
Weekend vs Weekday Comparison (from view_weekend_vs_weekday)

💰 Promotions & Discount Effectiveness Dashboard

Purpose: Evaluate promotional impact
Widgets:
- Discount Usage % (from view_discount_usage)
- Revenue by Discounted vs Non-Discounted Orders (from view_discount_effectiveness)
- Top Discounted Products (from view_top_discounted_products)

*/


-- =========================================
-- SQL VIEW
-- =========================================
-- CATEGORY: Customer Views
-- =========================================

-- View: Top Customers by Revenue
-- Description: Shows top customers ranked by total revenue and number of orders
-- Chart Type: Bar / Table
CREATE OR REPLACE VIEW datamart.view_top_customers AS
SELECT
    Customer_CustomerID,
    Customer_Nickname,
    SUM(Sales_TotalAmount) AS TotalRevenue,
    COUNT(Sales_SalesID) AS TotalOrders
FROM datamart.dm_sales
GROUP BY Customer_CustomerID, Customer_Nickname
ORDER BY TotalRevenue DESC;

-- View: Average Order Value by Customer
-- Description: Calculates average order value for each customer
-- Chart Type: Scatter
CREATE OR REPLACE VIEW datamart.view_avg_order_value AS
SELECT
    Customer_CustomerID,
    Customer_Nickname,
    SUM(Sales_TotalAmount)/COUNT(Sales_SalesID) AS AvgOrderValue,
    COUNT(Sales_SalesID) AS TotalOrders
FROM datamart.dm_sales
GROUP BY Customer_CustomerID, Customer_Nickname;

-- View: Customer Gender Analysis
-- Description: Distribution of revenue and customer count by gender
-- Chart Type: Pie
CREATE OR REPLACE VIEW datamart.view_customer_gender AS
SELECT
    Customer_Gender,
    COUNT(DISTINCT Customer_CustomerID) AS TotalCustomers,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY Customer_Gender;

-- View: Customer Membership Level Analysis
-- Description: Analyzes customer count and revenue by membership level
-- Chart Type: Bar
CREATE OR REPLACE VIEW datamart.view_membership_revenue AS
SELECT
    Customer_MembershipLevel,
    COUNT(DISTINCT Customer_CustomerID) AS TotalCustomers,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY Customer_MembershipLevel;

-- View: Customer Lifetime Value (CLV)
-- Description: Total revenue generated by each customer
-- Chart Type: Bar / Table
CREATE OR REPLACE VIEW datamart.view_customer_ltv AS
SELECT
    Customer_CustomerID,
    Customer_Nickname,
    SUM(Sales_TotalAmount) AS LifetimeRevenue,
    COUNT(Sales_SalesID) AS TotalOrders
FROM datamart.dm_sales
GROUP BY Customer_CustomerID, Customer_Nickname;

-- View: Repeat Purchase Frequency
-- Description: Measures how often each customer places orders
-- Chart Type: Scatter
CREATE OR REPLACE VIEW datamart.view_repeat_purchase AS
SELECT
    Customer_CustomerID,
    Customer_Nickname,
    COUNT(Sales_SalesID) AS TotalOrders,
    COUNT(DISTINCT Date_FullDate) AS ActiveDays
FROM datamart.dm_sales
GROUP BY Customer_CustomerID, Customer_Nickname;

-- View: High-Value Customers
-- Description: Customers with revenue above a threshold
-- Chart Type: Table / Bar
CREATE OR REPLACE VIEW datamart.view_high_value_customers AS
SELECT
    Customer_CustomerID,
    Customer_Nickname,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY Customer_CustomerID, Customer_Nickname
HAVING SUM(Sales_TotalAmount) > 100000;

-- View: New vs Returning Customers
-- Description: Segments customers based on first purchase date
-- Chart Type: Pie
CREATE OR REPLACE VIEW datamart.view_new_vs_returning AS
WITH first_purchase AS (
    SELECT
        Customer_CustomerID,
        MIN(Date_FullDate) AS FirstPurchaseDate,
        MAX(Date_FullDate) AS LastPurchaseDate,
        SUM(Sales_TotalAmount) AS TotalRevenue,
        COUNT(Sales_SalesID) AS TotalOrders
    FROM datamart.dm_sales
    GROUP BY Customer_CustomerID
)
SELECT
    CASE 
        WHEN FirstPurchaseDate = LastPurchaseDate THEN 'New'
        ELSE 'Returning'
    END AS CustomerType,
    COUNT(Customer_CustomerID) AS CustomerCount,
    SUM(TotalRevenue) AS TotalRevenue
FROM first_purchase
GROUP BY CASE 
           WHEN FirstPurchaseDate = LastPurchaseDate THEN 'New'
           ELSE 'Returning'
         END;

-- =========================================
-- CATEGORY: Product Views
-- =========================================

-- View: Top Products by Revenue
-- Description: Top-selling products by revenue and orders
-- Chart Type: Bar
CREATE OR REPLACE VIEW datamart.view_top_products AS
SELECT
    Product_ProductID,
    Product_ProductName,
    SUM(Sales_TotalAmount) AS TotalRevenue,
    COUNT(Sales_SalesID) AS TotalOrders
FROM datamart.dm_sales
GROUP BY Product_ProductID, Product_ProductName;

-- View: Revenue by Product Category
-- Description: Revenue and order count by product category
-- Chart Type: Bar / Pie
CREATE OR REPLACE VIEW datamart.view_revenue_category AS
SELECT
    Product_Category,
    SUM(Sales_TotalAmount) AS TotalRevenue,
    COUNT(Sales_SalesID) AS TotalOrders
FROM datamart.dm_sales
GROUP BY Product_Category;

-- View: Product Size Performance
-- Description: Revenue and orders by product size
-- Chart Type: Bar
CREATE OR REPLACE VIEW datamart.view_product_size AS
SELECT
    Product_Size,
    SUM(Sales_TotalAmount) AS TotalRevenue,
    COUNT(Sales_SalesID) AS TotalOrders
FROM datamart.dm_sales
GROUP BY Product_Size;

-- View: Top Product by Store
-- Description: Top-selling product per store
-- Chart Type: Table / Bar
CREATE OR REPLACE VIEW datamart.view_top_product_store AS
SELECT
    Store_StoreID,
    Store_StoreName,
    Product_ProductID,
    Product_ProductName,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY Store_StoreID, Store_StoreName, Product_ProductID, Product_ProductName
ORDER BY Store_StoreID, TotalRevenue DESC;

-- View: Category Trends Over Time
-- Description: Revenue trend for each product category by month
-- Chart Type: Line / Area
CREATE OR REPLACE VIEW datamart.view_category_trends AS
SELECT
    Product_Category,
    Date_Year,
    Date_Month,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY Product_Category, Date_Year, Date_Month
ORDER BY Product_Category, Date_Year, Date_Month;

-- =========================================
-- CATEGORY: Store Views
-- =========================================

-- View: Revenue by Store
-- Description: Total revenue and orders per store
-- Chart Type: Bar
CREATE OR REPLACE VIEW datamart.view_revenue_store AS
SELECT
    Store_StoreID,
    Store_StoreName,
    SUM(Sales_TotalAmount) AS TotalRevenue,
    COUNT(Sales_SalesID) AS TotalOrders
FROM datamart.dm_sales
GROUP BY Store_StoreID, Store_StoreName;

-- View: Store Customer Count
-- Description: Number of unique customers visiting each store
-- Chart Type: Bar
CREATE OR REPLACE VIEW datamart.view_store_customers AS
SELECT
    Store_StoreID,
    Store_StoreName,
    COUNT(DISTINCT Customer_CustomerID) AS UniqueCustomers
FROM datamart.dm_sales
GROUP BY Store_StoreID, Store_StoreName;

-- View: Store Performance by Month
-- Description: Revenue and orders per store over time
-- Chart Type: Line / Heatmap
CREATE OR REPLACE VIEW datamart.view_store_performance AS
SELECT
    Store_StoreID,
    Store_StoreName,
    Date_Year,
    Date_Month,
    SUM(Sales_TotalAmount) AS TotalRevenue,
    COUNT(Sales_SalesID) AS TotalOrders
FROM datamart.dm_sales
GROUP BY Store_StoreID, Store_StoreName, Date_Year, Date_Month;

-- =========================================
-- CATEGORY: Time Views
-- =========================================

-- View: Revenue Over Time
-- Description: Tracks revenue and orders trends by year and month
-- Chart Type: Line / Area
CREATE OR REPLACE VIEW datamart.view_revenue_time AS
SELECT
    Date_Year,
    Date_Month,
    SUM(Sales_TotalAmount) AS TotalRevenue,
    COUNT(Sales_SalesID) AS TotalOrders
FROM datamart.dm_sales
GROUP BY Date_Year, Date_Month
ORDER BY Date_Year, Date_Month;

-- View: Orders by Weekday
-- Description: Order counts and revenue distribution by day of the week
-- Chart Type: Bar
CREATE OR REPLACE VIEW datamart.view_orders_weekday AS
SELECT
    Date_DayOfWeek,
    COUNT(Sales_SalesID) AS TotalOrders,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY Date_DayOfWeek;

-- View: Orders by Hour
-- Description: Distribution of orders by hour of day
-- Chart Type: Line / Heatmap
CREATE OR REPLACE VIEW datamart.view_orders_by_hour AS
SELECT
    EXTRACT(HOUR FROM Sales_TransactionTime) AS HourOfDay,
    COUNT(Sales_SalesID) AS TotalOrders,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY EXTRACT(HOUR FROM Sales_TransactionTime)
ORDER BY HourOfDay;



-- View: Weekend vs Weekday Revenue
-- Description: Compare revenue and orders between weekends and weekdays
-- Chart Type: Bar
CREATE OR REPLACE VIEW datamart.view_weekend_vs_weekday AS
SELECT
    Date_IsWeekend,
    COUNT(Sales_SalesID) AS TotalOrders,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY Date_IsWeekend;

-- View: Monthly Repeat Orders
-- Description: Customers with multiple orders in a month
-- Chart Type: Table / Heatmap
CREATE OR REPLACE VIEW datamart.view_monthly_repeat_orders AS
SELECT
    Date_Year,
    Date_Month,
    Customer_CustomerID,
    COUNT(Sales_SalesID) AS OrdersThisMonth
FROM datamart.dm_sales
GROUP BY Date_Year, Date_Month, Customer_CustomerID
HAVING COUNT(Sales_SalesID) > 1;

-- =========================================
-- CATEGORY: Discount & Promotion Views
-- =========================================

-- View: Discount Usage
-- Description: % of orders using a discount and total revenue
-- Chart Type: Pie
CREATE OR REPLACE VIEW datamart.view_discount_usage AS
SELECT
    CASE WHEN Sales_DiscountAmount > 0 THEN 'Yes' ELSE 'No' END AS DiscountUsed,
    COUNT(Sales_SalesID) AS TotalOrders,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY DiscountUsed;

-- View: Top Discounted Products
-- Description: Products with the highest total discount applied
-- Chart Type: Bar
CREATE OR REPLACE VIEW datamart.view_top_discounted_products AS
SELECT
    Product_ProductID,
    Product_ProductName,
    SUM(Sales_DiscountAmount) AS TotalDiscount
FROM datamart.dm_sales
GROUP BY Product_ProductID, Product_ProductName
ORDER BY TotalDiscount DESC;

-- View: Discount Effectiveness
-- Description: Compares revenue from discounted vs non-discounted orders
-- Chart Type: Pie / Bar
CREATE OR REPLACE VIEW datamart.view_discount_effectiveness AS
SELECT
    CASE WHEN Sales_DiscountAmount > 0 THEN 'Discounted' ELSE 'FullPrice' END AS OrderType,
    COUNT(Sales_SalesID) AS TotalOrders,
    SUM(Sales_TotalAmount) AS TotalRevenue
FROM datamart.dm_sales
GROUP BY OrderType;

-- =========================================
-- END OF ALL ANALYTIC VIEWS
-- =========================================
