INSERT INTO datamart.dm_sales
SELECT
    -- fact_sales
    fs.SalesID AS Sales_SalesID,
    fs.DateKey AS Sales_DateKey,
    fs.CustomerKey AS Sales_CustomerKey,
    fs.ProductKey AS Sales_ProductKey,
    fs.StoreKey AS Sales_StoreKey,
    fs.Quantity AS Sales_Quantity,
    fs.UnitPrice AS Sales_UnitPrice,
    fs.DiscountAmount AS Sales_DiscountAmount,
    fs.TotalAmount AS Sales_TotalAmount,
    fs.PaymentMethod AS Sales_PaymentMethod,
    fs.OrderChannel AS Sales_OrderChannel,
    fs.OrderStatus AS Sales_OrderStatus,
    fs.TransactionTime AS Sales_TransactionTime,

    -- dim_date
    d.FullDate AS Date_FullDate,
    d.Day AS Date_Day,
    d.DayOfWeek AS Date_DayOfWeek,
    d.WeekOfYear AS Date_WeekOfYear,
    d.Month AS Date_Month,
    d.Year AS Date_Year,
    d.Quarter AS Date_Quarter,
    d.IsWeekend AS Date_IsWeekend,

    -- dim_customer
    c.CustomerID AS Customer_CustomerID,
    c.Nickname AS Customer_Nickname,
    c.Gender AS Customer_Gender,
    c.BirthYear AS Customer_BirthYear,
    c.MembershipLevel AS Customer_MembershipLevel,
    c.City AS Customer_City,
    c.Province AS Customer_Province,

    -- dim_product
    p.ProductID AS Product_ProductID,
    p.ProductName AS Product_ProductName,
    p.Category AS Product_Category,
    p.Size AS Product_Size,
    p.Price AS Product_Price,

    -- dim_store
    s.StoreID AS Store_StoreID,
    s.StoreName AS Store_StoreName,
    s.City AS Store_City,
    s.Province AS Store_Province,
    s.Address AS Store_Address

FROM star.fact_sales fs
LEFT JOIN star.dim_date d ON fs.DateKey = d.DateKey
LEFT JOIN star.dim_customer c ON fs.CustomerKey = c.CustomerKey
LEFT JOIN star.dim_product p ON fs.ProductKey = p.ProductKey
LEFT JOIN star.dim_store s ON fs.StoreKey = s.StoreKey;