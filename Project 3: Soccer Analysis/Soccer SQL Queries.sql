-- create database soccer;
use soccer;

-- Check the data

select *
from results;

select *
from stats;

-- Check the dispossessed column, the initial values don't exist
-- Like we assumed in the jupyter notebook, we'll assume these as being zero

select case when dispossessed is null or dispossessed='' then 0 else dispossessed end as dispossessed
from stats;

-- Do the same for the big_chance_missed column

select case 
when big_chance_missed is null or big_chance_missed='' then 0 
else big_chance_missed end as big_chance_missed
from stats;

-- Check if the results column is accurate. Recreate the results column
-- and with that compare the counts of A,D, and H to see if it's accurate

with cte as (select home_goals, away_goals, result,
case when home_goals > away_goals then  'h'
when away_goals > home_goals then  'a'
when away_goals = home_goals then  'd'
end as result_2
from results)
select result, count(result) as result_count,
result_2, count(result_2) as result_2_count
from cte
group by result, result_2;    -- they are correct!

-- Top 10 teams that scored the most goals home  

select home_team, sum(home_goals) as total_home_goals
from results
group by home_team
order by total_home_goals desc
limit 10;

-- The results aren't the same as the ones in jupyter notebook, but that may be due to
-- the data not being formatted correctly when it was imported here

-- Top 10 teams that scored the most away

select away_team, sum(away_goals) as total_away_goals
from results
group by away_team
order by total_away_goals desc
limit 10;

-- Give a ranking to each game based on the disparity of goals 
-- (5 goals "A rank", 3-4 goals "B rank", 2 goals "C rank", 1 goal "D rank", 0 goals "E rank")

select *, case 
when (abs(home_goals - away_goals)) >= 5 then 'A rank'
when (abs(home_goals - away_goals)) between 3 and 4 then 'B rank'
when (abs(home_goals - away_goals)) = 2 then 'C rank'
when (abs(home_goals - away_goals)) = 1 then  'D rank'
when (abs(home_goals - away_goals)) =0 then 'E rank'
end as disparity
from results;

-- Count the number of games per rank (build upon the precious query)

with games_per_rank as (select *, case 
when (abs(home_goals - away_goals)) >= 5 then 'A rank'
when (abs(home_goals - away_goals)) between 3 and 4 then 'B rank'
when (abs(home_goals - away_goals)) = 2 then 'C rank'
when (abs(home_goals - away_goals)) = 1 then  'D rank'
when (abs(home_goals - away_goals)) =0 then 'E rank'
end as disparity
from results)
select disparity, count(disparity) as nr_of_games
from games_per_rank
group by disparity
order by nr_of_games desc;

-- There is another issue with the B rank in jupyter notebook (185/640)?


-- The team with the most A rank performances

with home_A_rank_wins as (select *, case 
when (abs(home_goals - away_goals)) >= 5 and home_goals > away_goals then 'A rank'
when (abs(home_goals - away_goals)) between 3 and 4 and home_goals > away_goals then 'B rank'
when (abs(home_goals - away_goals)) = 2 and home_goals > away_goals then 'C rank'
when (abs(home_goals - away_goals)) = 1 and home_goals > away_goals then  'D rank'
when (abs(home_goals - away_goals)) =0 and home_goals > away_goals then 'E rank'
end as disparity
from results),                                        -- this one checks home wins
away_A_rank_wins as (select *, case 
when (abs(home_goals - away_goals)) >= 5 and home_goals < away_goals then 'A rank'
when (abs(home_goals - away_goals)) between 3 and 4 and home_goals < away_goals then 'B rank'
when (abs(home_goals - away_goals)) = 2 and home_goals < away_goals then 'C rank'
when (abs(home_goals - away_goals)) = 1 and home_goals < away_goals then  'D rank'
when (abs(home_goals - away_goals)) =0 and home_goals < away_goals then 'E rank'
end as disparity
from results)                                            -- this checks the away wins
select *
from away_A_rank_wins;    -- finish this one

-- Which 3 teams scored the most goals in season 2006-2007?

select team, sum(goals) as total_goals
from (select home_team as team, season, home_goals as goals from results
union all
select away_team as team, season, away_goals as goals from results) combined
where season = '2006-2007'
group by team, season
order by total_goals desc
limit 3;

-- Which team scored the most goals overall, throughout all the seasons?

select team, sum(goals) as total_goals
from (select home_team as team, home_goals as goals from results
union all
select away_team as team, away_goals as goals from results) combined
group by team
order by total_goals desc
limit 1;