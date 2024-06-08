select *, cast(transaction_date as date) as transact_date
from dbo.credit_card_transcations

select * from dbo.credit_card_transcations


-- top 5 cities with highest spends and their percentage contribution of total credit card spends 


with top_5_cities as(select top 5 city, sum(amount) as spend
from dbo.credit_card_transcations 
group by city
order by spend desc)

,total as(select sum(cast (amount as float)) as total_spend
from dbo.credit_card_transcations)

select city, round(spend*100.0/total_spend,2)
from top_5_cities
cross join total


-- highest spend month and amount spent in that month for each card type

with Transaction_by_month as(select card_type, datepart(year,transaction_date) as Transaction_year, datepart(month,transaction_date) as Transaction_month , sum(amount) as total_amt
from dbo.credit_card_transcations
group by card_type,datepart(year,transaction_date), datepart(month,transaction_date))
--order by total_amt desc

select *
from(
 select *, rank() over(partition by card_type order by total_amt desc) rnk
 from Transaction_by_month) s
 where rnk = 1

-- the transaction details(all columns from the table) for each card type when it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)
with cte as(
select  *, sum(amount) over(partition by card_type order by transaction_date,transaction_id) running_sum
from dbo.credit_card_transcations)

select *
from(
select *, rank() over(partition by card_type order by running_sum asc) rnk
from cte 
where running_sum > 1000000 
) s
where rnk = 1


-- city which had lowest percentage spend for gold card type

with cte as(select city, card_type, sum(amount) amt,
sum(case when card_type = 'Gold' then amount end) as gold_amount
from dbo.credit_card_transcations
group by city,card_type)

select
city, sum(gold_amount)*1.0/sum(amt) as gold_ratio
from cte
group by city
having sum(gold_amount) is not null
order by gold_ratio


-- print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with expense as(select city, exp_type, sum(amount) amt
from dbo.credit_card_transcations
group by city, exp_type)

, expense_order as(select city, exp_type, amt,
rank() over(partition by city order by amt desc) rnk_desc,
rank() over(partition by city order by amt asc) rnk_asc
from expense)

select city, 
min(case when rnk_desc = 1 then exp_type end) as highest_expense_type, 
max(case when rnk_asc = 1 then exp_type end) as lowest_expense_type
from expense_order
group by city


-- percentage contribution of spends by females for each expense type

select exp_type, 
sum(case when gender = 'F' then amount else 0 end)*1.0/sum(amount) as percentage_female_contribution
from dbo.credit_card_transcations
group by exp_type


-- which card and expense type combination saw highest month over month growth in Jan-2014

with cte1 as(select card_type, exp_type, left(transaction_date,7)  as year_month, sum(amount) as amt
from dbo.credit_card_transcations
group by card_type, exp_type, left(transaction_date,7))

, cte2 as(select card_type, exp_type, year_month, 
(amt- lag(amt) over(partition by card_type,exp_type order by year_month) ) as diff
from cte1
)


, cte3 as(select card_type, exp_type, year_month,max(diff) as max_diff 
from cte2
where year_month = '2014-01'
group by card_type, exp_type, year_month)

select top 1 * from cte3
order by max_diff desc

-- during weekends which city has highest total spend to total no of transcations ratio 

with cte as(select *, datepart(weekday,transaction_date) as daynum
from dbo.credit_card_transcations)

select city, sum(amount)/count(*) as ratio
from cte
where daynum in (7,1)
group by city
order by ratio desc

-- city took least number of days to reach its 500th transaction after the first transaction in that city

with cte as(select *, count(*) over(partition by city order by transaction_date,transaction_id) cnt
from dbo.credit_card_transcations)

, cte1 as(select city, 
case when cnt = 500 then transaction_date end as lastday
from cte
where case when cnt = 500 then transaction_date end is not null)

, cte2 as(select city, 
case when cnt = 1 then transaction_date end as firstday
from cte
where case when cnt = 1 then transaction_date end is not null)

, cte3 as
(
select c1.city, DATEDIFF(day, firstday, lastday) as days_diff
from cte1 c1
join cte2 c2
on c1.city = c2.city
) 
select city, days_diff
from cte3
where days_diff = (select min(days_diff) from cte3)