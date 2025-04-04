-- create database tele;
use tele;

-- Find the churn rate by state

select state, count(*) as total_customers, 
sum(case when churn then 1 else 0 end) as churned_customers,
round(sum(case when churn then 1 else 0 end) * 100.0 / count(*), 2) as churn_rate_percent
from sql_telecom_data
group by state
order by churn_rate_percent desc;

-- Find the average call minutes by churn

select churn,
       avg(total_day_minutes) as avg_day_minutes,
       avg(total_eve_minutes) as avg_eve_minutes,
       avg(total_night_minutes) as avg_night_minutes,
       avg(total_intl_minutes) as avg_intl_minutes
from sql_telecom_data
group by churn;

-- Customer service calls & churn correlation

select customer_service_calls, count(*) as total_customers,
sum(case when churn then 1 else 0 end) as churned_customers,
round(sum(case when churn then 1 else 0 end) * 100.0 / count(*), 2) as churn_rate_percent
from sql_telecom_data
group by customer_service_calls
order by customer_service_calls;

-- Effectiveness of voice mail plan

select voice_mail_plan, count(*) as total_customers,
sum(case when churn then 1 else 0 end) as churned_customers,
round(sum(case when churn then 1 else 0 end) * 100.0 / count(*), 2) as churn_rate_percent
from sql_telecom_data
group by voice_mail_plan;

-- International plan and churn

select international_plan, count(*) as total_customers,
sum(case when churn then 1 else 0 end) as churned_customers,
round(sum(case when churn then 1 else 0 end) * 100.0 / count(*), 2) as churn_rate_percent
from sql_telecom_data
group by international_plan;

-- Top 10 customers by total charges

select phone_number,
       (total_day_charge + total_eve_charge + total_night_charge + total_intl_charge) as total_charge
from sql_telecom_data
order by total_charge desc
limit 10;

-- Average charges and usage by area code

select area_code,
avg(total_day_charge + total_eve_charge + total_night_charge + total_intl_charge) as avg_total_charge,
avg(total_day_minutes + total_eve_minutes + total_night_minutes + total_intl_minutes) as avg_total_minutes
from sql_telecom_data
group by area_code;

