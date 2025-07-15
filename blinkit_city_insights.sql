CREATE TABLE blinkit_city_insights (
    date DATE,
    city VARCHAR(100),
    l1_category VARCHAR(255),
    l2_category VARCHAR(255),
    est_qty_sold INT
);

-- 1. Rank inventory records
WITH inv_ranked AS (
    SELECT
        sku_id,
        store_id,
        inventory,
        created_at,
        CAST(created_at AS DATE) AS date,
        ROW_NUMBER() OVER (PARTITION BY sku_id, store_id ORDER BY created_at) AS rn
    FROM all_blinkit_category_scraping_stream
),

-- 2. Join with next time slot
inv_with_next AS (
    SELECT
        curr.sku_id,
        curr.store_id,
        curr.created_at,
        curr.date,
        curr.inventory AS curr_inventory,
        next.inventory AS next_inventory,
        next.created_at AS next_created_at
    FROM inv_ranked curr
    LEFT JOIN inv_ranked next
        ON curr.sku_id = next.sku_id
        AND curr.store_id = next.store_id
        AND curr.rn + 1 = next.rn
),

-- 3. Calculate sales per interval (only where inventory drops)
sales_only AS (
    SELECT
        *,
        curr_inventory - next_inventory AS qty_sold
    FROM inv_with_next
    WHERE next_inventory IS NOT NULL AND curr_inventory > next_inventory
),

-- 4. Use window function to get rolling avg of last 3 sales per SKU-store
rolling_avg_sales AS (
    SELECT
        sku_id,
        store_id,
        created_at,
        AVG(qty_sold * 1.0) OVER (
            PARTITION BY sku_id, store_id
            ORDER BY created_at
            ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
        ) AS avg_recent_sales
    FROM sales_only
),

-- 5. Combine with all inventory movement data and estimate est_qty_sold
estimates AS (
    SELECT
        i.sku_id,
        i.store_id,
        i.date,
        i.created_at,
        i.curr_inventory,
        i.next_inventory,
        CASE
            WHEN i.curr_inventory > i.next_inventory THEN i.curr_inventory - i.next_inventory
            WHEN i.curr_inventory < i.next_inventory THEN COALESCE(r.avg_recent_sales, 0)
            ELSE 0
        END AS est_qty_sold
    FROM inv_with_next i
    LEFT JOIN rolling_avg_sales r
        ON i.sku_id = r.sku_id
       AND i.store_id = r.store_id
       AND i.created_at = r.created_at
),

-- 6. Join with city map
with_city AS (
    SELECT e.*, m.city_name
    FROM estimates e
    JOIN blinkit_city_map m ON e.store_id = m.store_id
),

-- 7. Join with categories
joined_all AS (
    SELECT
        wc.date,
        wc.city_name,
        cat.l1_category,
        cat.l2_category,
        wc.est_qty_sold
    FROM with_city wc
    JOIN all_blinkit_category_scraping_stream s
        ON wc.sku_id = s.sku_id
       AND wc.store_id = s.store_id
       AND CAST(s.created_at AS DATE) = wc.date
    JOIN blinkit_categories cat
        ON s.l2_category_id = cat.l2_category_id
),

-- 8. Aggregate final output
final_result AS (
    SELECT
        date,
        city_name,
        l1_category,
        l2_category,
        SUM(CAST(ISNULL(est_qty_sold, 0) AS INT)) AS est_qty_sold
    FROM joined_all
    GROUP BY date, city_name, l1_category, l2_category
)

-- 9. Insert into final output table
INSERT INTO blinkit_city_insights (date, city, l1_category, l2_category, est_qty_sold)
SELECT * FROM final_result;


SELECT * FROM [dbo].[blinkit_city_insights]
