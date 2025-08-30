#!/bin/bash

# ================================
# Doris Stream Load for Star Schema
# ================================

# Common configs
USER="root"
PASSWORD=""
HOST="http://localhost:8030"
DB_NAME="star"
DATA_FOLDER="/home/administrator/script/generate-dummy"

# ================================
# Load fact_sales
# ================================
curl --location-trusted -u ${USER}:"${PASSWORD}" \
-H "Expect:100-continue" \
-H "column_separator:|" \
-H "skip_header: 1" \
-H "columns:SalesID,DateKey,CustomerKey,ProductKey,StoreKey,Quantity,UnitPrice,DiscountAmount,TotalAmount,PaymentMethod,OrderChannel,OrderStatus,TransactionTime" \
-T "${DATA_FOLDER}/fact_sales.csv" \
-H "max_filter_ratio:0.1" \
-XPUT "${HOST}/api/${DB_NAME}/fact_sales/_stream_load"

# ================================
# Load dim_date
# ================================
curl --location-trusted -u ${USER}:"${PASSWORD}" \
-H "Expect:100-continue" \
-H "column_separator:|" \
-H "skip_header: 1" \
-H "columns:DateKey,FullDate,Day,DayOfWeek,WeekOfYear,Month,Year,Quarter,IsWeekend" \
-T "${DATA_FOLDER}/dim_date.csv" \
-H "max_filter_ratio:0.1" \
-XPUT "${HOST}/api/${DB_NAME}/dim_date/_stream_load"

# ================================
# Load dim_customer
# ================================
curl --location-trusted -u ${USER}:"${PASSWORD}" \
-H "Expect:100-continue" \
-H "column_separator:|" \
-H "skip_header: 1" \
-H "columns:CustomerKey,CustomerID,Nickname,Gender,BirthYear,MembershipLevel,City,Province,StartDate,EndDate,IsCurrent,Version" \
-T "${DATA_FOLDER}/dim_customer.csv" \
-H "max_filter_ratio:0.1" \
-XPUT "${HOST}/api/${DB_NAME}/dim_customer/_stream_load"

# ================================
# Load dim_product
# ================================
curl --location-trusted -u ${USER}:"${PASSWORD}" \
-H "Expect:100-continue" \
-H "column_separator:|" \
-H "skip_header: 1" \
-H "columns:ProductKey,ProductID,ProductName,Category,Size,Price,StartDate,EndDate,IsCurrent,Version" \
-T "${DATA_FOLDER}/dim_product.csv" \
-H "max_filter_ratio:0.1" \
-XPUT "${HOST}/api/${DB_NAME}/dim_product/_stream_load"

# ================================
# Load dim_store
# ================================
curl --location-trusted -u ${USER}:"${PASSWORD}" \
-H "Expect:100-continue" \
-H "column_separator:|" \
-H "skip_header: 1" \
-H "columns:StoreKey,StoreID,StoreName,City,Province,Address,StartDate,EndDate,IsCurrent,Version" \
-T "${DATA_FOLDER}/dim_store.csv" \
-H "max_filter_ratio:0.1" \
-XPUT "${HOST}/api/${DB_NAME}/dim_store/_stream_load"

echo "✅ All data loaded into Doris successfully!"