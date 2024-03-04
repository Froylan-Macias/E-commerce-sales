select *
from dbo.E_comerce_sales_data

--view the table with all the columns that will be used for the analysis.
select Order_ID, Customer_ID, Order_Date, Ship_Date, Ship_Mode, Segment, Country, City, State, Region, Product_ID, Category, Sub_Category, Product_Name, Sales, Quantity, Discount, Profit
from dbo.E_comerce_sales_data
order by Order_ID

--calculated the profit margin for each sale
--Calculated each item sold, the profit for each sold item, discount per item
select Order_ID, Customer_ID, Order_Date, Ship_Date, Ship_Mode, Segment, Country, City, State, Region, Product_ID, Category, Sub_Category, Product_Name, Sales, (Sales/Quantity) as Sale_Per_Item, Quantity, Discount as Percentage_Discount, Discount * (Sales / Quantity) as Discount_Per_Item, abs(Profit) as Profit, abs((Profit/Quantity)) as Pofit_Per_Item
from dbo.E_comerce_sales_data
order by Order_ID

-- select the sales, sale_per_item, quantity, percentage_discount, discount_per_itme, profit, profit_per_
-- group by Order_id
select 
Order_ID, 
Customer_ID,
State,
Sales, 
(Sales/Quantity) as Sale_Per_Item, 
Quantity, 
category,
Discount as Percentage_Discount, 
Discount * (Sales / Quantity) as Discount_Per_Item,
Discount * Sales as Discount_Sale ,
abs(Profit) as Profit,
abs((Profit/Quantity)) as Pofit_Per_Item
 -- avg(Profit) over(partition by Profit) as avg_Profit i need to perform the 
 -- avg profit for the total Order_id
from dbo.E_comerce_sales_data


--total orders
select
 count(distinct Order_id) as Total_Orders
from dbo.E_comerce_sales_data

--global numbers
select
sum(quantity) as Total_items,
COUNT(distinct Order_id) as Total_orders,
sum(Sales) as Total_sales, 
sum(Discount * Sales) as Total_Discount,
sum(abs(Profit)) as Total_Profit
from dbo.E_comerce_sales_data



--Table with the sum sales per date per state.
select 
State, 
Sales,
sum(sales) over(partition by state order by order_date) as Sales_by_state,
Order_Date
from dbo.E_comerce_sales_data
order by State

--Table with the total sum sales per state
select
distinct state,
sum(sales) over(partition by state) as total_sales_by_state
from dbo.E_comerce_sales_data
order by total_sales_by_state desc

--Table with the total sum sales, total sum category, and total sum per category and state
select
distinct state,
category,
sum(sales) over(partition by category, state) as total_sales_category_state,
sum(sales) over(partition by state) as total_sales_by_state,
sum(sales) over(partition by category) as total_sales_by_category
from dbo.E_comerce_sales_data
order by state 



--Use CTE to perform aggregate function in aggregate functions to calculate percentages
-- by state and category
with Percentage_category_state as
(
select
distinct state,
category,
discount * sales as Total_Discount,
sum(sales) over(partition by category, state) as total_sales_category_state,
sum(sales) over(partition by state) as total_sales_by_state,
sum(sales) over(partition by category) as total_sales_by_category
from dbo.E_comerce_sales_data
)
select
distinct state,
category,
sum(Total_Discount) over(partition by  state) as Total_discount_per_State,
total_sales_category_state,
total_sales_by_state,
total_sales_by_category,
(total_sales_category_state / total_sales_by_state )*100 as category_percentage_by_state,
(total_sales_category_state / total_sales_by_category)*100 as category_percentage_by_category
from Percentage_category_state
order by State



-- Work with the Order_Id to calculate the profit, total sale and the profit percentage
with Profit_table as
(
select
distinct Order_ID,
abs(profit) as Profit,
sum(sales) over(partition by Order_ID) as total_sale_Order_Id
from dbo.E_comerce_sales_data
),
profit_order as 
(
select
distinct Order_ID,
sum(profit) over(partition by Order_ID) as Profit_Order_Id,
total_sale_Order_Id
from Profit_table
)
select
distinct order_id,
Profit_Order_Id,
total_sale_Order_Id,
(Profit_Order_Id / total_sale_Order_Id) * 100  as profit_percentage_by_total_sale
from profit_order
--The are a total of 5,009 different orders


-- Calculated the total orders per state
Select
Count(distinct(Order_id)) as Total_Orders_State ,
state
from dbo.E_comerce_sales_data
group by State
Order by Count(distinct(Order_id)) desc


-- Calculated the total orders per state by category, by ship mode
Select
Count(distinct(Order_id)) as Total_Orders_State ,
state,
Category,
Ship_Mode
from dbo.E_comerce_sales_data
group by State, Category, Ship_Mode
Order by State 

-- calculate the avg ETD (estimated time delivery) per state
with ETD_table as 
(
select
distinct Order_ID,
Order_Date,
Ship_Date,
DATEDIFF(day, Order_Date, Ship_Date) as ETD,
State
from dbo.E_comerce_sales_data
)
select
distinct state,
avg(ETD) over(partition by state order by state) as avg_ETD
from ETD_table


-- Total orders by segment and state
Select
Count(distinct(Order_id)) as Total_Orders_State ,
state,
Segment
from dbo.E_comerce_sales_data
group by State, Segment
Order by State 

-- Total orders by segment
Select
Count(distinct(Order_id)) as Total_Orders_State ,
Segment
from dbo.E_comerce_sales_data
group by  Segment

-- Total orders by segment, total profit and avg profit
Select
Count(distinct(Order_id)) as Total_Orders_State ,
Segment,
sum(abs(profit)) as Total_profit,
avg(abs(profit)) as Avg_profit
from dbo.E_comerce_sales_data
group by  Segment

--Total orders by segment, total profit, avg profit, by state
Select
Count(distinct(Order_id)) as Total_Orders_State ,
Segment,
State,
sum(abs(profit)) as Total_profit,
avg(abs(profit)) as Avg_profit
from dbo.E_comerce_sales_data
group by  Segment, State

--Create a table with Total sales, avg by customer_id, there is a total of 793 different customers
select 
distinct Customer_ID,
sum(Sales) over(partition by customer_id)  as total_sales_per_customer,
avg(sales) over(partition by customer_id) as avg_sales_per_customer,
sum(abs(profit)) over(partition by customer_id) as total_profit_per_customer,
avg(abs(profit)) over(partition by customer_id) as avg_profit_per_customer,
into Customers_sales_profit
from dbo.E_comerce_sales_data


-- Create a table with Total orders by customer
Select 
distinct customer_id,
count(distinct(order_id)) as Total_orders_per_customer
into Total_orders_by_customer
from dbo.E_comerce_sales_data
group by Customer_ID

-- Change the column name from the table Total_orders_by_customer
exec sp_rename 'Total_orders_by_customer.customer_id', 'Customer_ID'


--Join the two created tables to get the analysis in one table
select*
from Customers_sales_profit csp
right join
Total_orders_by_customer toc
on csp.Customer_ID = toc.Customer_ID


--Total orders by Region, segment, category
select
distinct Region,
segment,
category,
count(distinct(Order_ID)) as Total_orders_reg_cat_seg
from dbo.E_comerce_sales_data
group by Region, segment, Category

-- total sales by region
select
region,
sum(sales) as total_sales_region
from dbo.E_comerce_sales_data
group by Region





select 
distinct Customer_ID,
sum(Sales) over(partition by customer_id)  as total_sales_per_customer,
avg(sales) over(partition by customer_id) as avg_sales_per_customer,
sum(abs(profit)) over(partition by customer_id) as total_profit_per_customer,
avg(abs(profit)) over(partition by customer_id) as avg_profit_per_customer,
sum(Discount * Sales) over(partition by customer_id) as Discount_Sale
from dbo.E_comerce_sales_data