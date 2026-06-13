SELECT plan,
COUNT(*) AS total_customers,
SUM(CASE WHEN churned='Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN churned='Yes' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS churn_rate
FROM subscriptions 
GROUP BY plan
ORDER BY churn_rate DESC;

SELECT billing_cycle,
COUNT(*) AS total_customers,
SUM(CASE WHEN churned='Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN churned='Yes' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS churn_rate
FROM subscriptions 
GROUP BY billing_cycle
ORDER BY churn_rate DESC;

SELECT acquisition_channel,
COUNT(*) AS total_customers,
SUM(CASE WHEN churned='Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN churned='Yes' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS churn_rate
FROM subscriptions 
GROUP BY acquisition_channel
ORDER BY churn_rate DESC;

SELECT company_size,
COUNT(*) AS total_customers,
SUM(CASE WHEN churned='Yes' THEN 1 ELSE 0 END) AS churned_customers,
ROUND(SUM(CASE WHEN churned='Yes' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS churn_rate
FROM subscriptions 
GROUP BY company_size
ORDER BY churn_rate DESC;

SELECT month,total_mrr
FROM monthly_revenue
ORDER BY month;

SELECT churned,AVG(feature_usage_pct) AS avg_feature_usage
FROM subscriptions 
GROUP BY churned;

SELECT churned,ROUND(AVG(nps_score),2) AS avg_nps
FROM subscriptions
GROUP BY churned;

SELECT churned,ROUND(AVG(support_tickets_12mo),2) AS avg_tickets
FROM subscriptions
GROUP BY churned;

WITH CTE1 AS(
SELECT plan,
ROUND(AVG(monthly_revenue),2) AS avg_mrr,
ROUND(
AVG(DATEDIFF(STR_TO_DATE(churn_date,'%d-%m-%Y'),
STR_TO_DATE(signup_date,'%d-%m-%Y'))/30),
2
) AS avg_lifespan_months
FROM subscriptions
WHERE churned='Yes'
AND churn_date IS NOT NULL
GROUP BY plan)
SELECT plan,avg_mrr,avg_lifespan_months,avg_mrr*avg_lifespan_months AS estimated_clv
FROM CTE1;


WITH clv_data AS (
SELECT plan,
ROUND(AVG(monthly_revenue),2) AS avg_mrr,
ROUND(
AVG(
DATEDIFF(STR_TO_DATE(churn_date,'%d-%m-%Y'),
STR_TO_DATE(signup_date,'%d-%m-%Y'))/30),2) AS avg_lifespan_months,
ROUND(AVG(monthly_revenue) *
AVG(
DATEDIFF(STR_TO_DATE(churn_date,'%d-%m-%Y'),
STR_TO_DATE(signup_date,'%d-%m-%Y'))/30),2) AS estimated_clv
FROM subscriptions
WHERE churned='Yes'
AND churn_date IS NOT NULL
GROUP BY plan
),
cac_data AS (
SELECT AVG(customer_acquisition_cost) AS avg_cac
FROM monthly_revenue
)
SELECT c.plan,c.avg_mrr,c.avg_lifespan_months,c.estimated_clv,
ROUND(c.estimated_clv / ca.avg_cac,2) AS clv_cac_ratio
FROM clv_data c
CROSS JOIN cac_data ca;

WITH avg_revenue AS(
SELECT month,new_customers,churned_customers,avg_revenue_per_customer,
ROUND(new_customers*avg_revenue_per_customer,2) as new_mrr,ROUND(churned_customers*avg_revenue_per_customer,2) AS churned_mrr
FROM monthly_revenue
ORDER BY month)
SELECT *,ROUND(new_mrr-churned_mrr) AS net_revenue_retention
FROM avg_revenue
ORDER BY net_revenue_retention DESC;

SELECT COUNT(*) AS high_risk_customers,
ROUND(
COUNT(*) * 100.0 /
(
SELECT COUNT(*)
FROM subscriptions
WHERE churned='No'
),
2
) AS high_risk_percentage
FROM subscriptions
WHERE feature_usage_pct < 20 AND nps_score < 5 AND support_tickets_12mo > 10
AND churned='No';
