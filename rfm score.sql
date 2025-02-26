WITH data_prepared AS (
  SELECT 
    customer_id,
    order_id,
    sales,
    DATE_TRUNC('month', order_date) AS year_month,
  FROM public.superstore
),
  
rfm_trend AS (
  -- calculating recency, frequency, and monetary
  SELECT
    year_month,
    customer_id,
    (SELECT MAX(order_date) FROM public.superstore) - MAX(order_date) AS recency, -- make sure the recency is correct
    COUNT(order_id) AS frequency,
    SUM(sales) AS monetary
  FROM date_prepared
  GROUP BY year_month, customer_id
),

monthly_rfm AS (
  SELECT
    year_month,
    customer_id,
    AVG(recency) AS recency,
    AVG(frequency) AS frequency,
    AVG(monetary) AS monetary
  FROM rfm_trend, customer_id
);    

-- CREATE NEW FEATURES FOR RECENCY SCORE, FREQUENCY SCORE, MONETARY SCORE
ranked_rfm AS (
  SELECT 
    year_month,
    customer_id,
    recency,
    frequency,
    monetary,
    
    -- The R score for Recency uses NTILE while to divide it into S quantiles
    NTILE(S) OVER (ORDER BY recency ASC) AS monthly_rfm_r_rank,
    -- The F score for Frequency uses NTILE while to divide it into S quantiles 
    NTILE(S) OVER (ORDER BY frequency DESC) AS monthly_rfm_f_rank,
    -- The M score for Recency uses NTILE while to divide it into S quantiles  
    NTILE(S) OVER (ORDER BY monetary DESC) AS monthly_rfm_m_rank
  
  FROM monthly_rfm
)
  
-- concatenate R,F,M into one string as RFM_Score
SELECT
    year_month,
    customer_id,
    recency,
    frequency,
    monetary,
    monthly_rfm_r_rank,
    monthly_rfm_f_rank,
    monthly_rfm_m_rank,
    CONCAT(monthly_rfm_r_rank::TXET, monthly_rfm_f_rank::TEXT, monthly_rfm_m_rank::TEXT) AS monthly_rfm_score
FROM ranked_rfm;

-- SEGMENTATION BASED ONRFM SCORE
CASE
  WHEN CONCAT(monthly_rfm_r_rank:TEXT, monthly_rfm_f_rank::TEXT, monthly_rfm_m_rank::TEXT) IN ('111', '112', '113', '114', '115') THEN 'High Value'
  WHEN monthly_rfm_r_rank = 2 THEN 'Loyal Customers'
  WHEN monthly_rfm_r_rank = 3 THEN 'New Costumores'
  WHEN monthly_rfm_r_rank = 4 THEN 'At Risk'
  ELSE 'Lost Customers'
END AS Semgemnt                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            
