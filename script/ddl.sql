-- ===========================
-- FACT TABLE: fact_sales
-- ===========================
CREATE TABLE star.fact_sales (
    SalesID BIGINT NOT NULL,
    DateKey INT NOT NULL,
    CustomerKey INT NOT NULL,
    ProductKey INT NOT NULL,
    StoreKey INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice FLOAT NOT NULL,
    DiscountAmount FLOAT DEFAULT 0,
    TotalAmount FLOAT NOT NULL,
    PaymentMethod VARCHAR(100),
    OrderChannel VARCHAR(100),
    OrderStatus VARCHAR(100),
    TransactionTime DATETIME
)
DUPLICATE KEY(SalesID)
DISTRIBUTED BY HASH(SalesID) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 1"
);

-- ===========================
-- DIMENSION TABLE: dim_date
-- ===========================
CREATE TABLE star.dim_date (
    DateKey INT NOT NULL,
    FullDate date,
    Day TINYINT,
    DayOfWeek VARCHAR(50),
    WeekOfYear TINYINT,
    Month VARCHAR(50),
    Year SMALLINT,
    Quarter VARCHAR(10),
    IsWeekend VARCHAR(10)
)
DUPLICATE KEY(DateKey)
DISTRIBUTED BY HASH(DateKey) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 1"
);

-- ===========================
-- DIMENSION TABLE: dim_customer
-- ===========================
CREATE TABLE star.dim_customer (
    CustomerKey INT NOT NULL,
    CustomerID VARCHAR(100),
    Nickname VARCHAR(100),
    Gender VARCHAR(50),
    BirthYear SMALLINT,
    MembershipLevel VARCHAR(100),
    City VARCHAR(255),
    Province VARCHAR(255),
    StartDate DATE,
    EndDate DATE,
    IsCurrent TINYINT,
    Version INT
)
DUPLICATE KEY(CustomerKey)
DISTRIBUTED BY HASH(CustomerKey) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 1"
);

-- ===========================
-- DIMENSION TABLE: dim_product
-- ===========================
CREATE TABLE star.dim_product (
    ProductKey INT NOT NULL,
    ProductID VARCHAR(100),
    ProductName VARCHAR(255),
    Category VARCHAR(255),
    Size VARCHAR(50),
    Price FLOAT,
    StartDate DATE,
    EndDate DATE,
    IsCurrent TINYINT,
    Version INT
)
DUPLICATE KEY(ProductKey)
DISTRIBUTED BY HASH(ProductKey) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 1"
);

-- ===========================
-- DIMENSION TABLE: dim_store
-- ===========================
CREATE TABLE star.dim_store (
    StoreKey INT NOT NULL,
    StoreID VARCHAR(100),
    StoreName VARCHAR(255),
    City VARCHAR(255),
    Province VARCHAR(255),
    Address VARCHAR(255),
    StartDate DATE,
    EndDate DATE,
    IsCurrent TINYINT,
    Version INT
)
DUPLICATE KEY(StoreKey)
DISTRIBUTED BY HASH(StoreKey) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 1"
);


CREATE TABLE datamart.dm_sales (
    -- From fact_sales
    Sales_SalesID BIGINT NOT NULL,
    Sales_DateKey INT NOT NULL,
    Sales_CustomerKey INT NOT NULL,
    Sales_ProductKey INT NOT NULL,
    Sales_StoreKey INT NOT NULL,
    Sales_Quantity INT NOT NULL,
    Sales_UnitPrice FLOAT NOT NULL,
    Sales_DiscountAmount FLOAT DEFAULT 0,
    Sales_TotalAmount FLOAT NOT NULL,
    Sales_PaymentMethod VARCHAR(100),
    Sales_OrderChannel VARCHAR(100),
    Sales_OrderStatus VARCHAR(100),
    Sales_TransactionTime DATETIME,

    -- From dim_date
    Date_FullDate DATE,
    Date_Day TINYINT,
    Date_DayOfWeek VARCHAR(50),
    Date_WeekOfYear TINYINT,
    Date_Month VARCHAR(50),
    Date_Year SMALLINT,
    Date_Quarter VARCHAR(10),
    Date_IsWeekend VARCHAR(10),

    -- From dim_customer
    Customer_CustomerID VARCHAR(100),
    Customer_Nickname VARCHAR(100),
    Customer_Gender VARCHAR(50),
    Customer_BirthYear SMALLINT,
    Customer_MembershipLevel VARCHAR(100),
    Customer_City VARCHAR(255),
    Customer_Province VARCHAR(255),

    -- From dim_product
    Product_ProductID VARCHAR(100),
    Product_ProductName VARCHAR(255),
    Product_Category VARCHAR(255),
    Product_Size VARCHAR(50),
    Product_Price FLOAT,

    -- From dim_store
    Store_StoreID VARCHAR(100),
    Store_StoreName VARCHAR(255),
    Store_City VARCHAR(255),
    Store_Province VARCHAR(255),
    Store_Address VARCHAR(255)
)
DUPLICATE KEY(Sales_SalesID)
DISTRIBUTED BY HASH(Sales_SalesID) BUCKETS 10
PROPERTIES (
    "replication_allocation" = "tag.location.default: 1"
);


CREATE USER viewer IDENTIFIED BY 'viewer';
GRANT SELECT ON ALL TABLES IN DATABASE star TO viewer;
GRANT SELECT ON ALL TABLES IN DATABASE datamart TO viewer;