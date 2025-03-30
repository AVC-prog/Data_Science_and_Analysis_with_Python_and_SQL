-- create database pokemon;
use pokemon;

-- check the data

select *
from sql_pokemon_data;

-- count the distinct types

select count(distinct type_1)
from sql_pokemon_data;

-- Fix the mega names (notice there is one name 'mega' there that we must remove)

with fixe as (select trim(substring(name from position('mega' in name))) as fixed_name
from sql_pokemon_data
where name like '%mega%')
select fixed_name
from fixe
where fixed_name not like 'mega';

-- Define the bst column, and select those with bst above 600

with bst_data as (select (hp+ attack+defense+speed+sp_atk+sp_def) as bst, name
from sql_pokemon_data)
select *
from bst_data
where bst> 600;

-- Retrieve the dataframe with only the mega evolutions with clean names, and bst column

with mega_data as (select *
from sql_pokemon_data
where name like '%mega%' and name not like 'Yanmega')
select MyUnknownColumn, trim(substring(name from position('mega' in name))) as fixed_name,
type_1,type_2, HP, attack, defense, sp_atk, sp_def, speed, generation , legendary,
(attack+defense+sp_atk+sp_def+speed+hp) as bst
from mega_data 
where name like '%mega%';

-- Get all the megas and their base forms (Venusaur and Mega Venusaur, etc.)

-- Add Zygarde (Complete Form) and Zygarde (10%) with the correct values 
-- (research in Pokemon Database website) and in the correct index position in the dataframe 
-- (10% form should come before the 50% form, and the complete form should go after the 50% form)

insert into sql_pokemon_data( name, type_1, type_2, HP, Attack,Defense,Sp_Atk,Sp_Def,Speed,Generation,Legendary)
values ("Zygarde (Complete Form)", "Dragon", "Ground", 216,100,121,91,95,85, 6,True),
("Zygarde (10% Form)", "Dragon", "Ground", 54,100,71,61,85,115, 6,True);



-- Only show rows that don't have repeated names in the next one
-- (Don't see duplicate rows and keep the ones that have the highest BST if there are many with the same name but different BSTs)

create view essential_data as
with extra_names as (select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST, lag(name) over (order by name asc) as prev_name
from sql_pokemon_data)
select * from extra_names where prev_name is not null and position(prev_name in name) > 0;      -- these are all the things you don't want

select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST
from sql_pokemon_data
where name not in (select name from essential_data) and name not like "%Mega%";    -- removes all forms and megas

-- Best team per type using BST as the metric. (Teams can only have 6 Pokemon, no Legendaries)

delimiter $$

create procedure best_team_per_type(in ty_1 int)
begin
select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST
from sql_pokemon_data
where name like "%mega%" and (type_1 = ty_1 or type_2 = ty_1) and legendary = "False"
order by BST desc, name desc
limit 1;                                                                      -- best mega for that type
select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST
from sql_pokemon_data
where name not like "%mega%" and legendary = "False" and (type_1 = ty_1 or type_2 = ty_1)
order by BST desc
limit 5;                                                                       -- other top 5 for that type
end$$

delimiter ;

-- Best team accross generations  (create a stored procedure to get the best mega per generation, and add he next five)
-- No legendaries allowed

delimiter $$

create procedure best_team_per_gen(in gen int)
begin
select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST
from sql_pokemon_data
where name like "%mega%" and generation = gen and legendary = "False"
order by BST desc, name desc
limit 1;                                                                      -- best mega in that gen
select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST
from sql_pokemon_data
where name not like "%mega%" and legendary = "False" and generation = gen
order by BST desc
limit 5;                                                                       -- other top 5 in that gen
end$$

delimiter ;

-- Best mono type team (we choose the type)

delimiter $$

create procedure best_team_per_type(in ty_1 int)
begin
select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST
from sql_pokemon_data
where name like "%mega%" and type_1 = ty_1 and type_2 = "" and legendary = "False"
order by BST desc, name desc
limit 1;                                                                      -- best mega for mono type
select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST
from sql_pokemon_data
where name not like "%mega%" and legendary = "False" and type_1 = ty_1 and type_2 = ""
order by BST desc
limit 5;                                                                       -- other top 5 for mono type
end$$

delimiter ;

-- Best dual type team (we choose the type)

delimiter $$

create procedure best_team_per_type(in ty_1 int)
begin
select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST
from sql_pokemon_data
where name like "%mega%" and type_1 = ty_1 and (type_2 != "" and type_2 != ty_1) and legendary = "False"
order by BST desc, name desc
limit 1;                                                                      -- best mega for dual type
select *, (HP + Attack + Defense + Sp_Atk + Sp_Def + Speed) as BST
from sql_pokemon_data
where name not like "%mega%" and legendary = "False" and type_1 = ty_1 and (type_2 != "" and type_2 != ty_1) 
order by BST desc
limit 5;                                                                       -- other top 5 for dual type
end$$

delimiter ;


-- Change names in Type 1 (Fire->Lava) and Type 2 (Psychic->Light) columns

update sql_pokemon_data
set type_1 = case when type_1 = 'fire' then 'lava' else type_1 end,
    type_2 = case when type_2 = 'psychic' then 'light' else type_2 end;


