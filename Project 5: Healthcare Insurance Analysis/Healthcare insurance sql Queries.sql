-- create database health;
use health;

-- Let's use the validation_dataset first
-- Check if there are any negative values fo children

select *
from validation_dataset
where children < 0;       -- no

-- Create a view that is the clean validation_dataset and create a column named "charges_dollars"
-- that has random values between 1000-10000

create view clean_validation as
select age, sex, bmi, children, smoker, 
case when region = 'southwest' then 'Southwest'
when region = 'northwest' then 'Northwest'
when region = 'northeast' then 'Northeast'
when region = 'southeast' then 'Southeast'
else region end as region,
cast((rand() * (10000 - 1000) + 1000) as decimal(10,2)) as charges_dollars
from validation_dataset; 

-- How many children do the female clients have compared to the males? 
-- (assuming none of them are couples)

select sex, sum(children) as nr_of_young
from validation_dataset
group by sex
order by nr_of_young desc;

-- Which region has the highest average number of children?

select region, avg(children) as avg_child
from validation_dataset
group by region
order by avg_child desc
limit 1;                         -- southeast

-- Which sex has the highest bmi among smokers?

select sex, avg(bmi) as avg_bmi_smoker
from validation_dataset
where smoker = 'yes'
group by sex
order by avg_bmi_smoker desc;

-- How many people are in each sex and smoker category?

select sex,smoker, count(*) as count
from validation_dataset
group by sex, smoker
order by sex, smoker;

-- Use the previous table as a view to calculate the total amount of female and male smokers.

with smoke_count as (select sex,smoker, count(*) as count
from validation_dataset
group by sex, smoker
order by sex, smoker)
select sex, sum(count) as total
from smoke_count
group by sex;

-- Find the average number of children per age group.

select case 
        when age between 0 and 20 then '0-20'
        when age between 21 and 40 then '21-40'
        when age between 41 and 60 then '41-60'
        else '60+' 
end as age_group, avg(children) as avg_children
from validation_dataset
group by age_group
order by age_group;

-- Find the ratio of smokers to non-smokers within each region.

select region, 
sum(case when smoker = 'yes' then 1 else 0 end) / 
nullif(sum(case when smoker = 'no' then 1 else 0 end), 0) as smoker_to_non_smoker_ratio
from validation_dataset
group by region;

-- Find the average bmi for each sex, but exclude the top 10% of bmi values in each sex category.

with bmi_rank as (select sex, bmi,
percent_rank() over (partition by sex order by bmi) as bmi_rank
from validation_dataset)
select sex, avg(bmi) as avg_bmi
from bmi_rank
where bmi_rank <= 0.90  
group by sex;

-- Now let's clean up the insurance dataset and create a view called "clean_insurance"
-- (keep in mind that only 1224 rows of data were imported and the select statements seem to limit 1000 rows)

create view clean_insurance as
select abs(age) as age, 
case when sex = 'F' then 'female'
when sex = 'M' then 'male'
when sex = 'man' then 'male'
when sex = 'woman' then 'female'
else sex end as sex,
bmi,
abs(children) as children,
case 
when smoker = '' then 'yes'
else smoker
end as smoker,
case 
when region = 'southwest' then 'Southwest'
when region = 'northwest' then 'Northwest'
when region = 'northeast' then 'Northeast'
when region = 'southeast' then 'Southeast'
else region end as region,
cast(replace(replace(cast(charges as char), '$', ''), ',', '') as decimal(10,2)) as charges_dollars
from insurance
where sex != '' and region != '';

-- Find the total charges by sex.

select sex, sum(charges_dollars) as total_charges
from clean_insurance
group by sex
order by total_charges desc;

-- Unite both of the clean datasets (by stacking the rows) 
-- by creating a view called "heath_data" 

create view health_data as
select *
from clean_insurance
union all
select *
from clean_validation

