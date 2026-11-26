-- 1. DDL: Star Schema Tables (Dimension & Fact)

CREATE TABLE dim_customers (
    customer_id     NUMBER(10) PRIMARY KEY,
    country         VARCHAR2(100)
);

CREATE TABLE fact_transactions (
    transaction_id  NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    invoice_no      VARCHAR2(20) NOT NULL,
    stock_code      VARCHAR2(30),
    description     VARCHAR2(255),
    quantity        NUMBER(10) CHECK (quantity > 0),
    invoice_date    DATE NOT NULL,
    unit_price      NUMBER(10, 2) CHECK (unit_price > 0),
    customer_id     NUMBER(10) NOT NULL,
    total_amount    NUMBER(12, 2),
    CONSTRAINT fk_customer FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id)
);


-- 2. RFM Scoring View using Oracle NTILE(5) Window Functions

CREATE OR REPLACE VIEW vw_customer_rfm AS
WITH base_rfm AS (
    SELECT
        t.customer_id,
        c.country,
        TRUNC((SELECT MAX(invoice_date) + 1 FROM fact_transactions) - MAX(t.invoice_date)) AS recency_days,
        COUNT(DISTINCT t.invoice_no) AS frequency,
        ROUND(SUM(t.quantity * t.unit_price), 2) AS monetary
    FROM fact_transactions t
    JOIN dim_customers c ON t.customer_id = c.customer_id
    GROUP BY t.customer_id, c.country
),
scored_rfm AS (
    SELECT
        customer_id,
        country,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC, customer_id ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency ASC, customer_id ASC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary ASC, customer_id ASC)      AS m_score
    FROM base_rfm
)
SELECT
    customer_id,
    country,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    (r_score || f_score || m_score) AS rfm_code,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 3 AND f_score >= 4                  THEN 'Loyal Customers'
        WHEN r_score >= 4 AND f_score <= 3                  THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND (f_score >= 3 OR m_score >= 3) THEN 'At Risk'
        WHEN r_score <= 2 AND f_score <= 2 AND m_score <= 2 THEN 'Hibernating / Lost'
        ELSE 'Need Attention'
    END AS segment
FROM scored_rfm;


-- 3. Analytical Summary Query: Segment Size & Revenue Share

SELECT
    segment,
    COUNT(customer_id) AS customer_count,
    ROUND(COUNT(customer_id) * 100.0 / SUM(COUNT(customer_id)) OVER (), 2) AS customer_pct,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(SUM(monetary) * 100.0 / SUM(SUM(monetary)) OVER (), 2) AS revenue_pct,
    ROUND(AVG(recency_days), 1) AS avg_recency,
    ROUND(AVG(frequency), 1) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary
FROM vw_customer_rfm
GROUP BY segment
ORDER BY total_revenue DESC;
