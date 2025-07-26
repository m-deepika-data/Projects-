SELECT * FROM [dbo].[credit_card_transcations]

-- Type of cards and their spending
SELECT
	card_type
	,SUM(amount) AS TotalSpending
	FROM credit_card_transcations
GROUP BY card_type

-- Total City wise Creditcard usage in Amount
SELECT TOP 10
	city
	,SUM(amount) AS Total
FROM credit_card_transcations
GROUP BY city
ORDER BY Total DESC

-- Total Genderwise Creditcard usage in Amount 
SELECT
	gender
	,exp_type
	,SUM(amount) AS Total
FROM credit_card_transcations
GROUP BY gender, exp_type
ORDER BY gender 

-- Total Expense type wise Creditcard usage in Amount 
SELECT
	exp_type
	,SUM(amount) AS Total
FROM credit_card_transcations
GROUP BY exp_type


--GenderWise Spending Comparison
SELECT 
	* 
	,CASE WHEN FemaleSpending-MaleSpending>0 THEN 'FemaleSpendsMore' ELSE 'MaleSpendsMore' END AS SpendAnalysis
FROM (SELECT
	exp_type
	,SUM(CASE WHEN gender = 'F' THEN amount ELSE 0 END) AS FemaleSpending
	,SUM(CASE WHEN gender = 'M' THEN amount ELSE 0 END) AS MaleSpending
FROM credit_card_transcations
GROUP BY exp_type) A

--Yearwise Spending
SELECT 
	YEAR(transaction_date) AS TxnYear
	,SUM(amount) AS TotalSpending
FROM credit_card_transcations
GROUP BY YEAR(transaction_date)

-- Most Expensive month and Year
SELECT TOP 3
	TransactionMonth
	,TransactionYear
	,SUM(amount) AS TotalSpending
FROM
(SELECT 
	*
	,YEAR(transaction_date) AS TransactionYear
	,MONTH(transaction_date) AS TransactionMonth
	,DAY(transaction_date) AS TransactionDay
FROM credit_card_transcations) A
GROUP BY TransactionMonth, TransactionYear
ORDER BY TotalSpending

--1- write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends

SELECT TOP 5
	city
	,SUM(amount) AS TotalSpending
	,SUM(amount)/(SELECT SUM(amount) AS TotalCreditCardSpend FROM credit_card_transcations)*100 AS percentageContribution
FROM credit_card_transcations
GROUP BY city
ORDER BY TotalSpending DESC

--2- write a query to print highest spend month and amount spent in that month for each card type
WITH cte AS(
SELECT 
	card_type
	,DATENAME(MONTH,transaction_date) AS TransactionMonth
	,SUM(amount) AS TotalSpending
FROM credit_card_transcations
GROUP BY card_type,DATENAME(MONTH,transaction_date))
,A AS (
SELECT
	card_type
	,TransactionMonth
	,SUM(TotalSpending) OVER(PARTITION BY card_type ORDER BY TotalSpending DESC) AS Total
	,DENSE_RANK()OVER(PARTITION BY card_type ORDER BY TotalSpending DESC) AS RNK
FROM cte)

SELECT 
	card_type
	,TransactionMonth
	,Total
FROM A WHERE RNK=1
ORDER BY Total DESC;

--3- write a query to print the transaction details(all columns from the table) for each card type when
--it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type)

WITH cumsum_cte AS(
SELECT
	*
	,SUM(amount) OVER (PARTITION BY card_type ORDER BY transaction_date,transaction_id) AS CumulativeSum
FROM credit_card_transcations) 
SELECT * FROM (SELECT
	*
	,RANK() OVER (PARTITION BY card_type ORDER BY CumulativeSum) AS RNK
FROM cumsum_cte
WHERE CumulativeSum>=1000000) A
WHERE RNK =1;

--4- write a query to find city which had lowest percentage spend for gold card type
WITH cte AS(
SELECT
	city
	,card_type
	,SUM(amount) AS TotalSpend
	,SUM(CASE WHEN card_type = 'Gold' THEN amount END) AS GoldSum
FROM credit_card_transcations
GROUP BY city,card_type)
SELECT TOP 1
	city
	,SUM(GoldSum)*1.0/SUM(TotalSpend) AS GoldRatio
FROM cte
GROUP BY city
HAVING COUNT(GoldSum)>0 AND SUM(GoldSum)>0
ORDER BY GoldRatio;

--5- write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)
WITH citywiseExpense AS(
SELECT	
	city
	,exp_type
	,SUM(amount) AS Total
FROM credit_card_transcations
GROUP BY city,exp_type)
SELECT 
	city
	,MAX(case when RN_ASC=1 then exp_type end) as Lowest_Exp_type
	,MIN(case when RN_DESC=1 then exp_type end) as Highest_Exp_type
FROM (SELECT
	*
	,RANK() OVER (PARTITION BY city ORDER BY Total DESC) AS RN_DESC
	,RANK() OVER (PARTITION BY city ORDER BY Total ASC) AS RN_ASC
FROM citywiseExpense)A
GROUP BY city;

--6- write a query to find percentage contribution of spends by females for each expense type

SELECT
	exp_type
	,SUM(amount) AS TotalSpend
	,SUM(CASE WHEN gender = 'F' THEN amount END) AS FemaleSpend
	,SUM(CASE WHEN gender = 'F' THEN amount END)/SUM(amount) AS PercentageContribution
FROM credit_card_transcations
GROUP BY exp_type 
Order BY PercentageContribution DESC

--7- which card and expense type combination saw highest month over month growth in Jan-2014

SELECT * FROM credit_card_transcations;
WITH A AS (
SELECT 
	card_type
	,exp_type
	,MONTH(transaction_date) AS TxnMonth
	,YEAR(transaction_date) AS TxnYear
	,SUM(amount) AS TotalSpend
FROM credit_card_transcations
GROUP BY card_type,exp_type,MONTH(transaction_date),YEAR(transaction_date))
SELECT TOP 1 * FROM (
SELECT
	*
	,LAG(TotalSpend,1) OVER(PARTITION BY card_type,exp_type ORDER BY TxnYear,TxnMonth) AS PrevMonthSpending
FROM A) AS B
WHERE TxnYear = '2014' AND TxnMonth = '1'

--8- during weekends which city has highest total spend to total no of transcations ratio 
SELECT * FROM credit_card_transcations;

SELECT TOP 1
	city
	--,DATEPART(WEEKDAY,transaction_date) AS WeekdayTxn
	,SUM(amount)/COUNT(transaction_id) AS Ratio
FROM credit_card_transcations
WHERE DATEPART(WEEKDAY,transaction_date) IN (1,7)
GROUP BY city--,DATEPART(WEEKDAY,transaction_date)
ORDER BY RATIO DESC

--9- which city took least number of days to reach its 500th transaction after the first transaction in that city
WITH A AS(
SELECT 
	*
	,ROW_NUMBER() OVER(PARTITION BY city ORDER BY transaction_date,transaction_id) AS RN
FROM credit_card_transcations)

SELECT 
	city,
	DATEDIFF(DAY,MIN(transaction_date),max(transaction_date)) AS DiffInDaYS
FROM A
WHERE RN = 1 OR RN = 500
GROUP BY city
HAVING COUNT(1)=2
ORDER BY DiffInDaYS 
