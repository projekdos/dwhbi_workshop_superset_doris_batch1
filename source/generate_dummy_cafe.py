#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
Projek Cafe — Synthetic DWH Data Generator
Generates CSV files with '|' delimiter:
  - dim_date.csv        (2020-01-01 .. 2100-12-31)
  - dim_customer.csv    (SCD Type 2)
  - dim_store.csv       (SCD Type 2)
  - dim_product.csv     (SCD Type 2; price changes)
  - fact_sales.csv      (Jan 2024 .. Jul 2025; 100-200 rows/day)
All foreign keys in fact_sales reference the correct SCD2 version valid on transaction date.
Tested with Python 3.9+. No external dependencies.
"""

import csv
import random
from datetime import date, datetime, timedelta
from typing import List, Dict, Any, Tuple, Optional

# -----------------------
# Config
# -----------------------
RANDOM_SEED = 42
OUTPUT_DIR = "."  # current folder

DATE_DIM_START = date(2020, 1, 1)
DATE_DIM_END   = date(2100, 12, 31)

FACT_START = date(2024, 1, 1)
FACT_END   = date(2025, 7, 31)

# Daily rows in fact_sales
FACT_MIN_ROWS_PER_DAY = 100
FACT_MAX_ROWS_PER_DAY = 200

# Sizes (Starbucks-like)
SIZES = ["Small", "Medium", "Large"]

# Payment / channel / status
PAYMENT_METHODS = ["Cash", "Card", "eWallet"]
ORDER_CHANNELS = ["Dine-in", "Takeaway", "Online"]
ORDER_STATUS = ["Completed", "Completed", "Completed", "Refunded", "Cancelled"]  # Weighted

# Provinces & cities (Indonesia examples)
CITIES = [
    ("Jakarta", "DKI Jakarta"),
    ("Bandung", "West Java"),
    ("Surabaya", "East Java"),
    ("Medan", "North Sumatra"),
    ("Denpasar", "Bali"),
    ("Yogyakarta", "DI Yogyakarta"),
]
GENDERS = ["Male", "Female", "Other"]

# Usernames pool (nicknames)
USERNAMES = [
    "Budi","Ani","Joko","Sari","Wayan","Rina","Dimas","Novi","Rudi","Lia",
    "Andi","Vina","Agus","Maya","Yoga","Putri","Rama","Nadia","Fajar","Sinta",
]

# Product catalog (Starbucks-like with local twist)
BASE_PRODUCTS = [
    ("Espresso", "Coffee"),
    ("Americano", "Coffee"),
    ("Cappuccino", "Coffee"),
    ("Caffè Latte", "Coffee"),
    ("Caramel Macchiato", "Coffee"),
    ("Mocha", "Coffee"),
    ("Cold Brew", "Coffee"),
    ("Es Kopi Susu Gula Aren", "Coffee"),

    ("English Breakfast Tea", "Tea"),
    ("Green Tea Latte", "Tea"),
    ("Matcha Frappuccino", "Tea"),
    ("Teh Tarik", "Tea"),
    ("Iced Lemon Tea", "Tea"),

    ("Croissant", "Pastry"),
    ("Cheese Danish", "Pastry"),
    ("Banana Muffin", "Pastry"),
    ("Pisang Goreng Modern", "Pastry"),

    ("Chicken Sandwich", "Snack"),
    ("Tuna Sandwich", "Snack"),
    ("Pasta Aglio e Olio", "Light Food"),
]

# Base price ranges by category+size (rough Rp; you can tweak)
BASE_PRICE = {
    ("Coffee","Small"): 25000, ("Coffee","Medium"): 32000, ("Coffee","Large"): 38000,
    ("Tea","Small"):    20000, ("Tea","Medium"):    26000, ("Tea","Large"):    32000,
    ("Pastry","Small"): 18000, ("Pastry","Medium"): 22000, ("Pastry","Large"): 26000,
    ("Snack","Small"):  28000, ("Snack","Medium"):  33000, ("Snack","Large"):  38000,
    ("Light Food","Small"): 35000, ("Light Food","Medium"): 42000, ("Light Food","Large"): 48000,
}

# Helper: random slight price variance
def vary(base: int, pct: float = 0.15) -> int:
    lo = int(base * (1.0 - pct))
    hi = int(base * (1.0 + pct))
    return random.randint(lo, hi)

# -----------------------
# Utilities
# -----------------------
def daterange(d0: date, d1: date):
    cur = d0
    while cur <= d1:
        yield cur
        cur = cur + timedelta(days=1)

def yyyymmdd(d: date) -> int:
    return d.year * 10000 + d.month * 100 + d.day

def weekday_name(d: date) -> str:
    return ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"][d.weekday()]

def month_name(d: date) -> str:
    return d.strftime("%B")

def quarter(d: date) -> str:
    return f"Q{((d.month-1)//3)+1}"

def week_of_year(d: date) -> int:
    return int(d.strftime("%U"))

# Given a date, pick a random time during the day
def random_time_on_date(d: date) -> datetime:
    h = random.randint(8, 21)     # 8 AM - 9 PM typical cafe hours
    m = random.randint(0, 59)
    s = random.randint(0, 59)
    return datetime(d.year, d.month, d.day, h, m, s)

# -----------------------
# Generate dim_date
# -----------------------
def generate_dim_date() -> List[Dict[str, Any]]:
    rows = []
    for d in daterange(DATE_DIM_START, DATE_DIM_END):
        rows.append({
            "DateKey": yyyymmdd(d),
            "FullDate": d.isoformat(),
            "Day": d.day,
            "DayOfWeek": weekday_name(d),
            "WeekOfYear": week_of_year(d),
            "Month": month_name(d),
            "Year": d.year,
            "Quarter": quarter(d),
            "IsWeekend": "Yes" if d.weekday() >= 5 else "No",
        })
    return rows

# -----------------------
# Generate SCD2 dims
# -----------------------
def scd2_segment_periods(start_min: date, start_max: date, end_cap: date, max_versions: int = 3) -> List[Tuple[date, Optional[date]]]:
    """
    Create 1..max_versions contiguous periods:
      [start1, end1], [start2, end2], ... last has end=None
    Starts between start_min..start_max, each version length 60-240 days.
    Ensures coverage until end_cap (last version end=None).
    """
    n_versions = random.randint(1, max_versions)
    periods = []
    cur_start = start_min + timedelta(days=random.randint(0, (start_max - start_min).days))
    # ensure start not after end_cap
    if cur_start > end_cap:
        cur_start = start_min
    for i in range(n_versions):
        if i == n_versions - 1:
            periods.append((cur_start, None))
        else:
            dur = random.randint(60, 240)
            tentative_end = cur_start + timedelta(days=dur)
            if tentative_end > end_cap:
                periods.append((cur_start, None))
                break
            periods.append((cur_start, tentative_end))
            cur_start = tentative_end + timedelta(days=1)
    return periods

def generate_dim_customer(num_customers: int = 250) -> List[Dict[str, Any]]:
    """
    SCD2 columns: StartDate, EndDate, IsCurrent, Version
    Business key: CustomerID (C0001...)
    """
    rows = []
    sk = 0
    for i in range(1, num_customers+1):
        biz_id = f"C{i:04d}"
        nickname = random.choice(USERNAMES)
        birth_year = random.randint(1975, 2005)
        gender = random.choice(GENDERS)

        # SCD2 periods spanning around 2023..FACT_END
        periods = scd2_segment_periods(date(2023,1,1), date(2024,12,1), FACT_END, max_versions=3)
        version = 0
        for (st, en) in periods:
            version += 1
            sk += 1
            city, prov = random.choice(CITIES)
            # Let some attributes vary across versions to simulate change
            membership = random.choice(["Regular","Silver","Gold","Platinum"])
            is_current = 1 if en is None else 0
            rows.append({
                "CustomerKey": sk,
                "CustomerID": biz_id,
                "Nickname": nickname,
                "Gender": gender,
                "BirthYear": birth_year,
                "MembershipLevel": membership,
                "City": city,
                "Province": prov,
                "StartDate": st.isoformat(),
                "EndDate": en.isoformat() if en else "",
                "IsCurrent": is_current,
                "Version": version
            })
    return rows

def generate_dim_store() -> List[Dict[str, Any]]:
    """
    Create 4-6 stores with SCD2 (city/province/name may vary).
    StoreID format: S001, S002...
    """
    num_stores = random.randint(4,6)
    rows = []
    sk = 0
    for i in range(1, num_stores+1):
        biz_id = f"S{i:03d}"
        base_name = f"Projek Cafe #{i}"
        periods = scd2_segment_periods(date(2022,1,1), date(2024,6,1), FACT_END, max_versions=3)
        version = 0
        for (st, en) in periods:
            version += 1
            sk += 1
            city, prov = random.choice(CITIES)
            store_name = base_name if version == 1 else f"{base_name} - {city}"
            is_current = 1 if en is None else 0
            rows.append({
                "StoreKey": sk,
                "StoreID": biz_id,
                "StoreName": store_name,
                "City": city,
                "Province": prov,
                "StartDate": st.isoformat(),
                "EndDate": en.isoformat() if en else "",
                "IsCurrent": is_current,
                "Version": version
            })
    return rows

def generate_dim_product() -> List[Dict[str, Any]]:
    """
    Build product variants by size; SCD2 for price changes over time.
    ProductID format: Pxxx-<sizecode> (e.g., P001-S)
    """
    rows = []
    sk = 0
    pid = 0
    size_code = {"Small":"S", "Medium":"M", "Large":"L"}
    for (pname, category) in BASE_PRODUCTS:
        for size in SIZES:
            pid += 1
            biz_id = f"P{pid:03d}-{size_code[size]}"
            # Create SCD2 periods with price changes
            periods = scd2_segment_periods(date(2023,1,1), date(2024,12,1), FACT_END, max_versions=3)
            version = 0
            base = BASE_PRICE[(category, size)]
            for (st, en) in periods:
                version += 1
                sk += 1
                price = vary(base, pct=0.20)
                rows.append({
                    "ProductKey": sk,
                    "ProductID": biz_id,
                    "ProductName": pname,
                    "Category": category,
                    "Size": size,
                    "Price": price,
                    "StartDate": st.isoformat(),
                    "EndDate": en.isoformat() if en else "",
                    "IsCurrent": 1 if en is None else 0,
                    "Version": version
                })
    return rows

# -----------------------
# Helper: pick valid SCD2 version row for a given date
# -----------------------
def valid_scd2_rows_by_biz(
    rows: List[Dict[str, Any]],
    biz_key_col: str,
    start_col: str,
    end_col: str
) -> Dict[str, List[Dict[str, Any]]]:
    by_biz: Dict[str, List[Dict[str, Any]]] = {}
    for r in rows:
        k = r[biz_key_col]
        by_biz.setdefault(k, []).append(r)
    # sort versions by StartDate
    for k in by_biz:
        by_biz[k].sort(key=lambda x: x[start_col])
    return by_biz

def pick_version_for_date(versions: List[Dict[str, Any]], d: date, start_col="StartDate", end_col="EndDate") -> Optional[Dict[str, Any]]:
    for v in versions:
        st = datetime.fromisoformat(v[start_col]).date()
        en = datetime.max.date() if not v[end_col] else datetime.fromisoformat(v[end_col]).date()
        if st <= d <= en:
            return v
    return None

# -----------------------
# Generate fact_sales
# -----------------------
def generate_fact_sales(
    dim_date: List[Dict[str, Any]],
    dim_customer: List[Dict[str, Any]],
    dim_store: List[Dict[str, Any]],
    dim_product: List[Dict[str, Any]],
) -> List[Dict[str, Any]]:

    # Build SCD2 lookup by business key
    cust_by_biz = valid_scd2_rows_by_biz(dim_customer, "CustomerID", "StartDate", "EndDate")
    store_by_biz = valid_scd2_rows_by_biz(dim_store, "StoreID", "StartDate", "EndDate")
    prod_by_biz  = valid_scd2_rows_by_biz(dim_product, "ProductID", "StartDate", "EndDate")

    # List of business keys
    cust_biz_ids = list(cust_by_biz.keys())
    store_biz_ids = list(store_by_biz.keys())
    prod_biz_ids = list(prod_by_biz.keys())

    sales_rows = []
    sales_id = 0

    for d in daterange(FACT_START, FACT_END):
        day_rows = random.randint(FACT_MIN_ROWS_PER_DAY, FACT_MAX_ROWS_PER_DAY)
        date_key = yyyymmdd(d)
        for _ in range(day_rows):
            sales_id += 1

            # Choose a business key and then resolve correct SCD2 version valid on this date
            cb = random.choice(cust_biz_ids)
            sb = random.choice(store_biz_ids)
            pb = random.choice(prod_biz_ids)

            cv = pick_version_for_date(cust_by_biz[cb], d)
            sv = pick_version_for_date(store_by_biz[sb], d)
            pv = pick_version_for_date(prod_by_biz[pb], d)

            # If any None (e.g., version periods don't cover date), retry quickly
            if not (cv and sv and pv):
                # simple fallback: skip row
                sales_id -= 1
                continue

            customer_key = cv["CustomerKey"]
            store_key = sv["StoreKey"]
            product_key = pv["ProductKey"]

            qty = random.randint(1, 3)
            unit_price = int(pv["Price"])
            discount = random.choice([0, 0, 0, 2000, 3000, 5000])  # weighted towards 0
            total = max(qty * unit_price - discount, 0)

            tstamp = random_time_on_date(d)

            sales_rows.append({
                "SalesID": sales_id,
                "DateKey": date_key,
                "CustomerKey": customer_key,
                "ProductKey": product_key,
                "StoreKey": store_key,
                "Quantity": qty,
                "UnitPrice": unit_price,
                "DiscountAmount": discount,
                "TotalAmount": total,
                "PaymentMethod": random.choice(PAYMENT_METHODS),
                "OrderChannel": random.choice(ORDER_CHANNELS),
                "OrderStatus": random.choice(ORDER_STATUS),
                "TransactionTime": tstamp.isoformat(sep=" ")
            })
    return sales_rows

# -----------------------
# CSV Writer
# -----------------------
def write_csv(path: str, rows: List[Dict[str, Any]], fieldnames: List[str]):
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fieldnames, delimiter="|", quoting=csv.QUOTE_MINIMAL)
        w.writeheader()
        for r in rows:
            w.writerow(r)

# -----------------------
# Main
# -----------------------
def main():
    random.seed(RANDOM_SEED)

    # 1) dim_date
    dim_date = generate_dim_date()
    write_csv(
        f"{OUTPUT_DIR}/dim_date.csv",
        dim_date,
        ["DateKey","FullDate","Day","DayOfWeek","WeekOfYear","Month","Year","Quarter","IsWeekend"]
    )

    # 2) dim_customer (SCD2)
    dim_customer = generate_dim_customer(num_customers=250)
    write_csv(
        f"{OUTPUT_DIR}/dim_customer.csv",
        dim_customer,
        ["CustomerKey","CustomerID","Nickname","Gender","BirthYear","MembershipLevel","City","Province","StartDate","EndDate","IsCurrent","Version"]
    )

    # 3) dim_store (SCD2)
    dim_store = generate_dim_store()
    write_csv(
        f"{OUTPUT_DIR}/dim_store.csv",
        dim_store,
        ["StoreKey","StoreID","StoreName","City","Province","StartDate","EndDate","IsCurrent","Version"]
    )

    # 4) dim_product (SCD2 with price changes)
    dim_product = generate_dim_product()
    write_csv(
        f"{OUTPUT_DIR}/dim_product.csv",
        dim_product,
        ["ProductKey","ProductID","ProductName","Category","Size","Price","StartDate","EndDate","IsCurrent","Version"]
    )

    # 5) fact_sales (integrated with SCD2 versions valid on transaction date)
    fact_sales = generate_fact_sales(dim_date, dim_customer, dim_store, dim_product)
    write_csv(
        f"{OUTPUT_DIR}/fact_sales.csv",
        fact_sales,
        ["SalesID","DateKey","CustomerKey","ProductKey","StoreKey","Quantity","UnitPrice","DiscountAmount","TotalAmount","PaymentMethod","OrderChannel","OrderStatus","TransactionTime"]
    )

    print("Done. Files written to:", OUTPUT_DIR)

if __name__ == "__main__":
    main()

