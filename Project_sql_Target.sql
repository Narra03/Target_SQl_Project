--1. Initial exploratory questions:-- 
  
---1.a. DATA type OF COLUMNS IN a TABLE
SELECT
  column_name,
  data_type
FROM
  target-sql-project-450923.Target_Data.INFORMATION_SCHEMA.COLUMNS
WHERE
  table_name = 'customers' 
  
---1.b. Get the time period FOR which the DATA IS given
select
  MIN(order_purchase_timestamp) AS first_order,
  MAX(order_purchase_timestamp) AS last_order
FROM
  `Target_Data.orders` 
/* The datset consist data from 2016 to 2018 */ 
  
---1.c. Check whether the DATA IS avaialble FOR every month 

---2016
SELECT
    EXTRACT(YEAR
    FROM
        order_purchase_timestamp) AS year,
    EXTRACT(MONTH
    FROM
        order_purchase_timestamp) AS month,
    COUNT(*) AS record_count
FROM
    `Target_Data.orders`
WHERE
    EXTRACT(YEAR
    FROM
        order_purchase_timestamp) = 2016 -- Specify the year you want TO check
GROUP BY
    year,
    month
ORDER BY
    month; 
/* For 2016 the data is available only for 3 months, i.e 9, 10, 12.*/ 
  
--2017
SELECT
  EXTRACT(YEAR
  FROM
    order_purchase_timestamp) AS year,
  EXTRACT(MONTH
  FROM
    order_purchase_timestamp) AS month,
  COUNT(*) AS record_count
FROM
  `Target_Data.orders`
WHERE
  EXTRACT(YEAR
  FROM
    order_purchase_timestamp) = 2017 -- Specify the year you want TO check
GROUP BY
  year,
  month
ORDER BY
  month; 
/* The data is available for all 12 months*/ 

---2018
SELECT
  EXTRACT(YEAR
  FROM
    order_purchase_timestamp) AS year,
  EXTRACT(MONTH
  FROM
    order_purchase_timestamp) AS month,
  COUNT(*) AS record_count
FROM
  `Target_Data.orders`
WHERE
  EXTRACT(YEAR
  FROM
    order_purchase_timestamp) = 2018 -- Specify the year you want TO check
GROUP BY
  year,
  month
ORDER BY
  month; 
/* The data is avilable only for the first 10 months*/ 
  
---1.d. Number OF cities AND states IN our dataset
SELECT
  COUNT(DISTINCT(geolocation_city)) AS city_count,
  COUNT(DISTINCT(geolocation_state)) AS state_count
FROM
  `Target_Data.geolocation`;

/* The dataset contains information for 8011 cities across 27 states in Brazil.*/


---2.a. Is there a growing trend in e-commerce in Brazil? How can we describe a complete scenario?

SELECT Extract( year from order_purchase_timestamp) as year,
Extract( month from order_purchase_timestamp) as month,
COUNT(1) as num_orders
FROM `Target_Data.orders`
GROUP BY year, month
ORDER BY year, month

##Observations:
##January 2021 vs. January 2022: Orders increased from 150 to 170, indicating growth.
##Monthly Trend in 2021: Orders increased from January to March, suggesting a positive trend in the first quarter.
##Comparing February and March: Both years show an increase from February to March, indicating a possible seasonal trend.


---Lets check only for months which are present in the data for all three years
WITH monthly_data AS (
    SELECT 
        EXTRACT(YEAR FROM order_purchase_timestamp) AS year,
        EXTRACT(MONTH FROM order_purchase_timestamp) AS month,
        COUNT(order_id) AS num_orders
    FROM 
        `Target_Data.orders`
    GROUP BY 
        year, month
),
common_months AS (
    SELECT 
        month
    FROM 
        monthly_data
    GROUP BY 
        month
    HAVING 
        COUNT(DISTINCT year) = 3 -- Only include months present in all 3 years
)
SELECT 
    md.year,
    md.month,
    md.num_orders
FROM 
    monthly_data md
JOIN 
    common_months cm ON md.month = cm.month
ORDER BY 
    md.year, md.month;

##Observations
#Order volume spiked dramatically in 2017 for September and October, then plummeted in 2018 for the same months.
#Only September and October have consistent data across 2016, 2017, and 2018, allowing for direct year-to-year comparisons.
#There is high volatility in the order numbers, showing large fluctuations from year to year.

---b. Question: Can we see some seasonality with peaks at specic months?
SELECT Extract( month from order_purchase_timestamp) as month, COUNT(1) as
num_orders
FROM `Target_Data.orders`
GROUP BY 1
ORDER BY 1

##Observations:
#Peak Months: The highest order volumes occur in months 5 (May), 7 (July), 8 (August), and 11 (November). This suggests increased customer activity or demand during these periods.
#Potential Seasonality: The peaks in May, July, and August could indicate a summer seasonality effect, while the peak in November might be related to holiday shopping or specific promotions.
#Lower Activity: Months 1 (January), 2 (February), and 12 (December) show relatively lower order volumes, suggesting a potential slowdown in activity during these months.


---c. What time do Brazilian customers tend to buy (Dawn, Morning, Afternoon or Night)?
select
case
when extract (hour from order_purchase_timestamp) between 0 and 6 then 'dawn'
when extract (hour from order_purchase_timestamp) between 7 and 12 then 'morning'
when extract (hour from order_purchase_timestamp) between 13 and 18 then 'afternoon'
when extract (hour from order_purchase_timestamp) between 19 and 23 then 'night'
end as time_of_day, count(distinct order_id) as count
from `Target_Data.orders`
group by 1
order by 2 desc

##Observations:
#Afternoon: 38135 orders (most popular)
#Night: 28331 orders
#Morning: 27733 orders
#Dawn: 5242 orders (least popular)

---3. Evolution of E-commerce orders in Brazil region
---3.a. Get month on month orders by states.
select Extract( month from order_purchase_timestamp) as month,
c.customer_state, COUNT(1) as num_orders
from `Target_Data.orders` o
inner join `Target_Data.customers` c
on o.customer_id = c.customer_id
group by c.customer_state, month
order by num_orders desc
limit 10

##Observations:
#SP (Sao Paulo) sees peak orders in August and May, with a significant drop in December.
#Monthly order volume fluctuates, suggesting potential seasonality or trends within the state.


---3.b. Distribution of customers across the states in Brazil
select customer_state, COUNT(distinct(customer_unique_id)) as
num_customers
from `Target_Data.customers`
group by customer_state
order by num_customers desc;
#Observations:
#Dominant State: São Paulo (SP) has by far the largest customer base, significantly exceeding all other states.
#Varied Distribution: Customer numbers vary greatly across states, with a few major states having a large portion of the customers and many states having relatively small customer numbers.



--4. Impact on Economy
---4.a.Get % increase in cost of orders from 2017 to 2018 (include months between Jan to Aug only) - You can use “payment_value” column in payments table
with base as
(
select * from `Target_Data.orders` a
inner join
`Target_Data.payments` b
on a.order_id = b.order_id
where
extract(year from a.order_purchase_timestamp) between 2017 and 2018
and
extract(month from a.order_purchase_timestamp) between 1 and 8
),
base_2 as
(
select extract(year from order_purchase_timestamp) as year, sum(payment_value) as cost
from base
group by 1
order by 1 asc
),
base_3 as
(
select *, lead(cost, 1) over (order by year) as next_year_cost from base_2
)
select *, (next_year_cost - cost)/ cost *100 as percent_increase from base_3

#Observations:
#Significant Increase: The cost of orders increased by approximately 136.98% from 2017 to 2018 (specifically, from the period of Jan to Aug).
#Data Limitation: The data only shows the increase from 2017 to 2018. It does not contain further year information. It also does not show the monthly data that was requested.


---Create CTE Table and new columns:
---○ price_per_order = sum(price)/count(order_id)
---○ freight_per_order= sum(freight_value)/count(order_id)
---○ Group the data on yearly and monthly level

with cte_table as (
select Extract( month from o.order_purchase_timestamp) as month,
Extract( year from o.order_purchase_timestamp) as year,
(sum(price)/count(o.order_id)) as price_per_order,
(sum(freight_value)/count(o.order_id)) as freight_per_order
from `Target_Data.orders` o
inner join `Target_Data.order_items` i
on o.order_id= i.order_id
group by year,month
)
select (price_per_order), (freight_per_order), month , year
from cte_table

---4.a. Total amount sold in 2017 between Jan to august (Jan to Aug because data is available starting 2017 01 to 2018 08) and we can only compare cycles with cycles
with cte_table as (
select
Extract( month from order_purchase_timestamp) as month,
Extract( year from order_purchase_timestamp) as year,
sum(price) as total_price,
sum(freight_value) as total_freight
from `Target_Data.orders` o
inner join `Target_Data.order_items` i
on o.order_id= i.order_id
group by year, month
)
select sum(total_price) as total_transaction_amt
from cte_table
where year =2017 and month between 1 and 8

##Observations:
#Total amount sold in 2017 between Jan to August is  3113000.319999903.

----. % increase from 2017 to 2018
select *, (orders-coalesce(lagger_orders,0))/coalesce(orders,1)*100 as difference from (
select *, lag (orders,1) over (order by year asc) as lagger_orders from (
select extract(year from a.order_purchase_timestamp) as year,
count(distinct a.order_id) as orders,
count(distinct b.customer_unique_id) as customers
from `Target_Data.orders` a
left join `Target_Data.customers` b
on a.customer_id=b.customer_id
group by 1
)base) base_2
order by year asc

##Observations:
#Orders increased by approximately 100% from 2016 to 2017 and then by another 16.5% from 2017 to 2018.
#The data shows a consistent upward trend in order volume across the three years.


---Sum and mean price by customer state
with cte_table as (
select
c.customer_state as state,
sum(price) as total_price,
count(distinct(o.order_id)) as num_orders
from `Target_Data.orders` o
inner join `Target_Data.order_items` i
on o.order_id= i.order_id
inner join `Target_Data.customers` c
on o.customer_id=c.customer_id
group by state
)
select state, total_price, num_orders,(total_price/num_orders) as avg_price
from cte_table
order by total_price desc

##Observations:
#Sao Paulo (SP) leads in total order value but has a lower average order value than some other states.
#States with fewer orders, like BA and GO, tend to have higher average order values.
#This suggests a difference in buying behavior across states, with some prioritizing volume and others higher individual purchases.

---. Sum and mean freight by customer state
with cte_table as (
select
c.customer_state as state,
sum(freight_value) as total_freight,count(distinct(o.order_id)) as num_orders
from `Target_Data.orders` o
inner join `Target_Data.order_items` i
on o.order_id= i.order_id
inner join `Target_Data.customers` c
on o.customer_id=c.customer_id
group by state
)
select state, total_freight, num_orders,(total_freight/num_orders) as avg_price
from cte_table
order by total_freight desc
##Observations:
#São Paulo (SP) has the highest total freight cost but the lowest average freight cost per order.
#States with fewer orders tend to have higher average freight costs, likely due to distance or logistics.
#This highlights a potential trade-off between order volume and freight cost efficiency across states.

---Total amount sold in 2018 between Jan to august
with cte_table as (
select
Extract( month from order_purchase_timestamp) as month,
Extract( year from order_purchase_timestamp) as year,
sum(price) as total_price,
sum(freight_value) as total_freight
from `Target_Data.orders` o
inner join `Target_Data.order_items` i
on o.order_id= i.order_id
group by year, month
)
select sum(total_price)
from cte_table
where year =2018 and month between 1 and 8
##Observations:
#Total amount sold in 2018 between Jan to August is  7385905.800000433.


-----5. Analysis on sales, freight and delivery time
---create new columns for time to delivery and difference in estimated vs actual delivery
select order_id,TIMESTAMP_DIFF(
order_delivered_customer_date,order_purchase_timestamp, DAY) as time_to_dil,
TIMESTAMP_DIFF( order_delivered_customer_date,order_estimated_delivery_date ,
DAY) as diff_estimated_dil
from `Target_Data.orders`
where order_status='delivered'

---Top 5 states with highest/lowest average time to delivery

select state, avg_time_to_delivery from
(select c.customer_state as state, avg(timestamp_diff(o.order_delivered_customer_date, o.order_purchase_timestamp , DAY)) as avg_time_to_delivery
from `Target_Data.customers` c join `Target_Data.orders` o on 
c.customer_id = o.customer_id
group by state) 
order by  avg_time_to_delivery
limit 5
##Observations:
#SP has the fastest average delivery time at 8.3 days, while SC is the slowest at 14.5 days.
#Delivery times vary across states, likely due to factors like distance, infrastructure, and logistics.

---Top 5 states with highest frieght value
with ft as (
  select c.customer_state as state, 
  Avg(i.freight_value) as Avg_ft
  from `Target_Data.customers` c join 
  `Target_Data.orders` o 
  on c.customer_id = o.customer_id
  join `Target_Data.order_items` i on o.order_id = i.order_id
  group by state
)
select state, Avg_ft from ft
order by Avg_ft desc
limit 5
##Observations:
#RR and PB have the highest average freight values, indicating expensive shipping.
#These states likely face higher transportation costs due to distance, infrastructure limitations, or lower order volumes.

---Top 5 states where delivery is really fast/ not so fast compared to estimated date

select c.customer_state as state ,
Avg(timestamp_diff(o.order_delivered_customer_date,o.order_purchase_timestamp,DAY)) as Avg_cust_delivery,
Avg(timestamp_diff(o.order_estimated_delivery_date,o.order_purchase_timestamp,DAY)) as Avg_est_delivery
from `Target_Data.customers` c join `Target_Data.orders`  o
on c.customer_id = o.customer_id
group by state 
order by Avg_cust_delivery desc
limit 5
##Observations:
#Deliveries to RR, AP, and AM experience significant delays compared to estimated times.
#AL and PA have smaller delivery delays, but still exceed estimated times.
#This suggests potential logistical challenges in certain regions.


----Payment type Analysis
----Count of orders for different payment types
select count(distinct(order_id)) as order_count, payment_type 
from `Target_Data.payments`
group by payment_type
order by order_count desc
limit 10

---Count of orders based on the no. of payment installments
select distinct(payment_installments) as installments, count(order_id) as Num_orders,
FROM `Target_Data.payments`
where payment_installments>1
GROUP BY payment_installments
order by Num_orders desc;
##Observations:
#Most orders are made with 2 installments.
##Fewer orders are made with higher installment counts, indicating a preference for lower installment payments.

---Rank payment_value partitioned by payment_type
select payment_type, payment_value, order_id,
rank() over(partition by payment_type order by payment_value desc ) as rank
from `Target_Data.payments`

---For each seller rank the items by price
select order_id,product_id, seller_id, price,
rank() over(partition by seller_id order by price desc ) as rank
from `Target_Data.order_items`


---What percentage of orders were canceled or unavailable
select counter/total*100 as percentage from (
select sum(case when order_status in ('canceled','unavailable') then 1 else 0 end) as counter,
count (1) as total from `Target_Data.orders`
)

---Find customers with more than one order
select customer_unique_id, count(1) as ordercount FROM
`Target_Data.customers` c
JOIN `Target_Data.orders` o ON c.customer_id = o.customer_id
GROUP BY customer_unique_id
HAVING COUNT(order_purchase_timestamp) >1
ORDER BY COUNT(order_purchase_timestamp) desc

---Avg time for delivery
SELECT SUM(TIMESTAMP_DIFF(order_delivered_customer_date, order_purchase_timestamp, DAY)) / COUNT(order_id) AS average_time_for_del
FROM `Target_Data.orders`
WHERE order_status = 'delivered';
##Observations:
#The average time for delivery is approximately 12.092601422085863 days for delivered orders.



















