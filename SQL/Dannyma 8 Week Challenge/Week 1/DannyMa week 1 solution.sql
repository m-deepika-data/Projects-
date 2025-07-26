
select * from INFORMATION_SCHEMA.TABLES; -- lists tables
select * from sys.tables ;-- lists tables with detailed information

select * from sales;
select * from menu;
select * from members;

ALTER TABLE menu
ALTER COLUMN product_id int NOT NULL;

ALTER TABLE menu
ADD CONSTRAINT PK_product_id PRIMARY KEY (product_id);

ALTER TABLE members
ALTER COLUMN customer_id varchar(1) NOT NULL;

ALTER TABLE members
ADD CONSTRAINT PK_customer_id PRIMARY KEY (customer_id);


--1.	What is the total amount each customer spent at the restaurant?

SELECT 
	s.customer_id 
	, SUM(m.price) AS Total_Spent
FROM sales s
INNER JOIN menu m ON s. product_id = m.product_id
GROUP BY s.customer_id
ORDER BY Total_Spent DESC

--2.	How many days has each customer visited the restaurant?
SELECT 
	customer_id
	, COUNT(DISTINCT order_date) AS No_of_visits 
FROM SALES
GROUP BY customer_id;

--3.	What was the first item from the menu purchased by each customer?
WITH CTE AS(
SELECT s.customer_id,m.product_name, s.order_date,
DENSE_RANK()OVER(PARTITION BY s.customer_id ORDER BY s.order_date) as RN
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id)

SELECT  customer_id, product_name FROM  CTE 
WHERE RN =1
GROUP BY customer_id, product_name


--4.	What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
	TOP 1 
	m.product_id, m.product_name,
	COUNT(m.product_id) as No_of_times_ordered
FROM sales s
INNER JOIN menu m ON s.product_id = m.product_id
GROUP BY m.product_id, m.product_name
ORDER BY No_of_times_ordered DESC;

--5.Which item was the most popular for each customer?

WITH cte as(
select s.customer_id, m.product_name,
	count(m.product_name) as no_of_items,
	rank()over(partition by s.customer_id order by count(m.product_name) desc) as rnk
from sales s
inner join menu m on s.product_id = m.product_id
group by s.customer_id, m.product_name
) 

select customer_id, product_name as most_popular_product
from cte
where rnk =1

--6.	Which item was purchased first by the customer after they became a member?
	with cte as(
	select s.customer_id, m.product_name, order_date , mem.join_date,
	rank()over(partition by s.customer_id order by s.customer_id,s.order_date) as rnk
	from  sales s
	inner join members mem on s.customer_id = mem.customer_id
	inner join menu m on m.product_id = s.product_id
	where order_date>=join_date
	)
	select customer_id, product_name, order_date from cte 
	where rnk =1


--7.	Which item was purchased just before the customer became a member?


with cte as(
	select s.customer_id, m.product_name, order_date , mem.join_date,
	rank()over(partition by s.customer_id order by s.customer_id,s.order_date desc) as rnk
	from  sales s
	inner join members mem on s.customer_id = mem.customer_id
	inner join menu m on m.product_id = s.product_id
	where order_date<join_date
	)
	select customer_id, product_name, order_date from cte 
	where rnk =1
	




--8.	What is the total items and amount spent for each member before they became a member?

	select s.customer_id
	,count(m.product_name) as toral_items
	,concat('$',sum(m.price)) as total_spent
	from  sales s
	left join members mem on s.customer_id = mem.customer_id
	left join menu m on m.product_id = s.product_id
	where order_date<join_date
	group by s.customer_id;




--9.	If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
--Had the customer joined the loyalty program before making the purchases, total points that each customer would have accrued
with cte as(
select customer_id,
m.product_name, price,
case when product_name = 'sushi' then price*20 else price*10 end as points
from sales s
inner join menu m on s.product_id = m.product_id)
select customer_id, sum(points) as Total_points
from cte
group by customer_id;

--Total points that each customer has accrued after taking a membership

select s.customer_id,
sum(case when product_name = 'sushi' then price*20 else price*10 end) as points
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mem on s.customer_id = mem.customer_id
where order_date >= join_date
group by s.customer_id;

--10.	In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -
--how many points do customer A and B have at the end of January?

with normal_points as(
select s.customer_id, m.product_name, s.order_date, mem.join_date, case
when product_name = 'sushi' then price*20 else price*10 end as points
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mem on s.customer_id = mem.customer_id
where order_date<join_date)
,first_week_members as(
select s.customer_id, m.product_name, s.order_date, mem.join_date , case
when datediff(dd, order_date, join_date)<=7 then price*20 else price*10 end as points
from sales s
inner join menu m on s.product_id = m.product_id
inner join members mem on s.customer_id = mem.customer_id
where order_date>=join_date)
, cte as(
select * from normal_points 
union
select * from first_week_members)

select customer_id, product_name,sum(points) as points
from cte
group by customer_id, product_name;



--10.	In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi -
--how many points do customer A and B have at the end of January?

with members_benefit_date as(
select customer_id, join_date, dateadd(dd,6, join_date) as valid_date
from members)

select
s.customer_id,
sum(case when s.order_date between join_date and valid_date then price*20
when s.order_date not between join_date and valid_date  and product_name = 'sushi' then price*20 
when s.order_date not between join_date and valid_date  and product_name != 'sushi' then price*10 end) as points
from menu m
inner join sales s on m.product_id = s.product_id
inner join members_benefit_date m1 on m1.customer_id = s.customer_id and order_date < '2021-01-31' 
group by s.customer_id;

/*
Bonus Questions
Join All The Things
Create basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL. 
Fill Member column as 'N' if the purchase was made before becoming a member and 'Y' if the after is amde after joining the membership.
*/

select 
s.customer_id,s.order_date, m.join_date,m1.product_name,price,
case	when order_date < join_date then 'N'
		when order_date > join_date then 'Y'
	else 'N'
end
as Member_status
from sales s
left join members m 
on s.customer_id = m.customer_id
left join menu m1 
on s.product_id = m1.product_id

/*Rank All The Things
Danny also requires further information about the ranking of customer products, 
but he purposely does not need the ranking for non-member purchases 
so he expects null ranking values for the records when customers are not yet part of the loyalty program.
*/


with cte as (
select
s.customer_id
,order_date
,product_name
,price
,case
when s.order_date >= join_date  then 'Y' else 'N' end as member_status
from sales s
join menu on menu.product_id = s.product_id
left join members mem  on mem.customer_id = s.customer_id
)
select *
, case 
when member_status = 'N' then null else rank() over(partition by customer_id,member_status order by order_date)
end as 'rank'
from cte;