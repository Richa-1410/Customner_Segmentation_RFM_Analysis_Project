-- Oracle SQL*Loader Control File to load cleaned_transactions.csv
OPTIONS (SKIP=1)
LOAD DATA
INFILE 'cleaned_transactions.csv'
INTO TABLE fact_transactions
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
    invoice_no,
    stock_code,
    description,
    quantity,
    invoice_date DATE "YYYY-MM-DD HH24:MI:SS",
    unit_price,
    customer_id,
    country FILLER,
    total_amount
)
