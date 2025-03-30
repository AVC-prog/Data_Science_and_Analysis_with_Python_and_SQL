-- create database finance;
use finance;

-- Check the data

select *
from finance_data;

-- Fix the mistakes in the dates (check for various types of mistakes)

with fixed_dates as (select *, coalesce(
        str_to_date(`transaction_date`, '%Y/%m/%d'),
        str_to_date(`transaction_date`, '%d-%m-%Y'),
        str_to_date(`transaction_date`, '%m-%d-%Y'),
        str_to_date(`transaction_date`, '%Y.%m.%d'),
        `transaction_date`  -- keeps already correct dates
    ) as formatted_date
from finance_data)
select transaction_id, customer_id, transaction_amount, formatted_date  -- select the rest later if you need to
from fixed_dates;

-- Since we want to use this again later, let's create a view:

create view fixed_dates as
select *, coalesce(
        str_to_date(`transaction_date`, '%Y/%m/%d'),
        str_to_date(`transaction_date`, '%d-%m-%Y'),
        str_to_date(`transaction_date`, '%m-%d-%Y'),
        str_to_date(`transaction_date`, '%Y.%m.%d'),
        `transaction_date`  -- keeps already correct dates
    ) as formatted_date
from finance_data;

-- Check for missing values (not null values, it's literally empty)

-- From python we already saw which columns we need to check:

select count(loan_amount) as missing_values    -- 29 missing values, pandas says there are 31 missing 
from fixed_dates
where loan_amount = '';

select count(previous_loan_status) as missing_values
from fixed_dates
where previous_loan_status = '';                 -- python says 1 missing, but here there aren't any

select count(account_balance)
from fixed_dates
where account_balance = '';

-- drop the overdraft status column (you can't do something like this in views)
-- you must create the view how you want it from scratch

alter table finance_data
drop column `overdraft_status`;

-- Check the maximum disparity in Total_deposits, Account_balance, Total_Withdrawals

select (max(total_deposits) - min(total_deposits)) as deposits_disparity,
(max(total_withdrawals) - min(total_withdrawals)) as withdrawal_disparity,
(max(account_balance) - min(account_balance)) as balance_disparity
from finance_data;


-- Top 10 spending customers (there are only 10)

select customer_id, sum(transaction_amount) as total_spending
from finance_data
group by customer_id
order by total_spending desc
limit 10;

-- Average transaction amount per customer

select customer_id, avg(transaction_amount) as average_spending
from finance_data
group by customer_id
order by average_spending desc
limit 10;

-- What's the preferred transaction type? 

select count(transaction_type) as deposits
from fixed_dates
where transaction_type = "Deposit";

select count(transaction_type) as withdrawals
from fixed_dates
where transaction_type = "Withdrawal";

select transaction_type, count(transaction_type) as counts
from fixed_dates
group by transaction_type;

-- Top spenders per transaction location

select transaction_location, sum(transaction_amount) as total_spent
from finance_data
group by transaction_location
order by total_spent desc
limit 10;

-- Remove white spaces from Transaction_Description

set sql_safe_updates = 0;  -- temporarily disable safe update mode

update finance_data
set `transaction_description` = replace(`transaction_description`, ' ', '')
where `transaction_description` is not null;

set sql_safe_updates = 1;  -- bring it back to safe mode

-- Add an underscore to separate them again

update finance_table
set `transaction_description` = replace(`transaction_description`, ' ', '_')
where `transaction_description` is not null;

-- Remove non-alphanumeric characters

update your_table
set `transaction_description` = regexp_replace(`transaction_description`, '[^a-zA-Z0-9]', '')
where `transaction_description` is not null;

-- Get a random substring of the strings

select customer_id, 
       `transaction_description`,
       substring(`transaction_description`, 
                 floor(1 + (rand() * length(`transaction_description`))), 
                 floor(1 + (rand() * length(`transaction_description`)))) as random_substring
from your_table;

-- Replace multiple substrings with different values

update your_table
set `transaction_description` = replace(replace(replace(`transaction_description`, 'old_substring1', 'new_value1'), 'old_substring2', 'new_value2'),'old_substring3', 'new_value3');


-- Create a stored procedure that allows for a transaction from one customer to two  others by splitting the money
-- under the conditions that it can't be higher than $100 and there should be a savepoint for that.
-- Also, create a transaction_log table to store all the transactions made with who sent the money and who received it, how much and when 

create table transaction_log (
    transaction_id int auto_increment primary key,
    sender_id int,
    receiver_id_1 int,
    receiver_id_2 int,
    amount_sent dec(10,2),
    amount_split dec(10,2),
    transaction_date timestamp default current_timestamp
);

delimiter $$

create procedure transfers (in sender_id int, in receiver_id_1 int, in receiver_id_2 int, in transfer_amount dec(10,2))
begin
    declare total_balance dec(10,2);
    select account_balance into total_balance from finance_data where customer_id = sender_id;

    if transfer_amount > 100 then signal sqlstate '45000'
        set message_text = 'Transfer amount is too high, it exceeds $100 limit.';
    end if;
    
    if total_balance < transfer_amount then signal sqlstate '45000'
        set message_text = 'Insufficient funds to preform the transaction.';
    end if;

    start transaction;
    update finance_data set account_balance = account_balance - transfer_amount where customer_id = sender_id;

    savepoint before_receivers_update;

    update finance_data set account_balance = account_balance + (transfer_amount / 2) where customer_id = receiver_id_1;
    update finance_data set account_balance = account_balance + (transfer_amount / 2) where customer_id = receiver_id_2;

    insert into transaction_log (sender_id, receiver_id_1, receiver_id_2, amount_sent, amount_split)
    values (sender_id, receiver_id_1, receiver_id_2, transfer_amount, transfer_amount / 2);
    commit;
end$$

delimiter ;
