# 📦 Blinkit City Insights – SQL Inventory Analysis

A real-world SQL project submitted as part of a Data Analyst Task for **Dcluttr**. This project involved analyzing SKU-level inventory movement across Blinkit's dark stores to estimate product sales, handle restocks, and generate a city-wise sales summary using SQL.

---

## 🧠 Problem Statement

Estimate the **quantity sold** of products listed on BlinkIt using raw inventory snapshots taken at various time intervals across different stores. The goal was to build a new table `blinkit_city_insights` that provides:

- Daily sales estimates (`est_qty_sold`)
- Aggregated by **City**, **L1 Category**, and **L2 Category**

---

## 🧰 Tech Stack

- **SQL Server (T-SQL)**
- **Common Table Expressions (CTEs)**
- **Window Functions** (`LEAD()`, `AVG() OVER(...)`)
- **Joins**, **CASE statements**, **Query Optimization**

---

## 🗂️ Datasets Used

- `all_blinkit_category_scraping_stream` – SKU-level inventory snapshots by store and time  
- `blinkit_city_map` – Maps dark store IDs to cities  
- `blinkit_categories` – Maps L2 category IDs to L1 & L2 category names

---

## 🔁 Estimation Logic

1. **Sales Case:**  
   If inventory **decreased** between two time points →  
   `est_qty_sold = curr_inventory - next_inventory`

2. **Restock Case:**  
   If inventory **increased**, sales were estimated using the **rolling average of the last 3 actual sales intervals** for that SKU + store.

3. **Aggregation:**  
   Results were grouped by `city`, `date`, `l1_category`, and `l2_category`.

---

## 📈 Output Table: `blinkit_city_insights`

| date       | city        | l1_category | l2_category     | est_qty_sold |
|------------|-------------|-------------|------------------|---------------|
| 2025-03-06 | Bangalore   | Munchies    | Bhujia & Mixtures | 126           |
| 2025-03-06 | Mumbai      | Beverages   | Cold Drinks      | 92            |
| ...        | ...         | ...         | ...              | ...           |

---

## 📄 Files Included

- `blinkit_city_insights_query.txt` – Final optimized SQL query
- `blinkit_city_insights.csv` – Sample output table (exported from SQL Server)
- `README.md` – Project overview and documentation

---

## ✅ Key Highlights

- Used **window functions** and **rolling averages** to intelligently estimate sales even during restocks
- Handled missing mappings and nulls with defensive logic
- Optimized for performance on a local SQL Server setup with large input data

---

## 🙋‍♂️ Author

**Uday Kumar**  
📍 Bokaro Steel City, Jharkhand  
🔗 [LinkedIn](https://www.linkedin.com/in/uday-kumar-contact)  
✉️ udaykumar7928@gmail.com

---

## 📌 Note

This project was completed as part of a **SQL-based analyst evaluation task** by Dcluttr. The code and logic reflect practical business scenarios using real-like data.

