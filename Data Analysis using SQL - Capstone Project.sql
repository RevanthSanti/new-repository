USE nft_project;

-- How many sales occurred during this time period? 

SELECT COUNT(token_id) AS "Number of Sales Occured"
FROM pricedata;

-- Return the top 5 most expensive transactions (by USD price) for this data set. Return the name, ETH price, and USD price, as well as the date.

SELECT name,eth_price,usd_price,event_date
FROM pricedata
ORDER BY usd_price DESC
LIMIT 5;

-- Return a table with a row for each transaction with an event column, a USD price column, and a moving average of USD price that averages the last 50 transactions.

SELECT event_date,usd_price,
AVG(usd_price) OVER (ORDER BY event_date ROWS BETWEEN 49 PRECEDING AND CURRENT ROW) AS last_50_moving_average
FROM pricedata;

-- Return all the NFT names and their average sale price in USD. Sort descending. Name the average column as average_price.

SELECT name,AVG(usd_price) AS average_price 
FROM pricedata
GROUP BY name
ORDER BY AVG(usd_price) DESC;

-- Return each day of the week and the number of sales that occurred on that day of the week, as well as the average price in ETH. Order by the count of transactions in ascending order.

SELECT DAYNAME(event_date) AS Day_of_Week,COUNT(token_id) AS Number_of_Sales,AVG(eth_price) 
FROM pricedata
GROUP BY Day_of_Week
ORDER BY Number_of_Sales;

-- Construct a column that describes each sale and is called summary. The sentence should include who sold the NFT name, who bought the NFT, who sold the NFT, the date, and what price it was sold for in USD rounded to the nearest thousandth.
 #Here’s an example summary:
 #“CryptoPunk #1139 was sold for $194000 to 0x91338ccfb8c0adb7756034a82008531d7713009d from 0x1593110441ab4c5f2c133f21b0743b2b43e297cb on 2022-01-14”
 
 SELECT CONCAT(name," ","was sold for $","to",buyer_address," ","from"," ",seller_address," ","on"," ",event_date) AS summary 
 FROM pricedata;
 
 -- Create a view called “1919_purchases” and contains any sales where “0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685” was the buyer.

CREATE VIEW 1919_purchases AS SELECT * FROM pricedata
WHERE buyer_address="0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685";

SELECT *FROM 1919_purchases;

-- Create a histogram of ETH price ranges. Round to the nearest hundred value.

SELECT ROUND(eth_price, -2)    AS eth_price_rounded, COUNT(*) AS count,
RPAD('', COUNT(*), '-') AS bar 
FROM pricedata
GROUP BY eth_price_rounded
ORDER BY eth_price_rounded;

-- Return a unioned query that contains the highest price each NFT was bought for and a new column called status saying “highest” with a query that has the lowest price each NFT was bought for and the status column saying “lowest”.
# The table should have a name column, a price column called price, and a status column.
# Order the result set by the name of the NFT, and the status, in ascending order. 

SELECT name,MAX(usd_price) AS price,"Highest" AS status FROM pricedata
GROUP BY name,status
UNION
SELECT name,MIN(usd_price) AS price, "Lowest" AS status FROM pricedata
GROUP BY name,status
ORDER BY name ASC,status ASC;


-- What NFT sold the most each month / year combination? Also, what was the name and the price in USD? Order in chronological format.

SELECT CONCAT(MONTHNAME(event_date),"/",YEAR(event_date)) AS month_year,name,MAX(usd_price) 
FROM pricedata
GROUP BY month_year,name
ORDER BY month_year;


-- Return the total volume (sum of all sales), round to the nearest hundred on a monthly basis (month/year).

SELECT CONCAT(MONTHNAME(event_date),"/",YEAR(event_date)) AS month_year,ROUND(SUM(usd_price),-2) AS total_volume 
FROM pricedata
GROUP BY month_year
ORDER BY month_year;


-- Count how many transactions the wallet "0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685"had over this time period.

SELECT COUNT(*) AS "count of transactions for 0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685" 
FROM pricedata
WHERE buyer_address='0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685'
OR seller_address='0x1919db36ca2fa2e15f9000fd9cdc2edcf863e685';

-- Create an “estimated average value calculator” that has a representative price of the collection every day based off of these criteria:
 #- Exclude all daily outlier sales where the purchase price is below 10% of the daily average price
 #- Take the daily average of remaining transactions
 #a) First create a query that will be used as a subquery. Select the event date, the USD price, and the average USD price for each day using a window function. Save it as a temporary table.
 #b) Use the table you created in Part A to filter out rows where the USD prices is below 10% of the daily average and return a new estimated value which is just the daily average of the filtered data
 
 CREATE TEMPORARY TABLE Avg_price_table;
 
 SELECT event_date,usd_price,AVG(usd_price) OVER(ORDER BY event_date) AS price_average FROM pricedata;
 
 SELECT event_date,AVG(usd_price) AS new_average FROM Avg_price_table
 WHERE usd_price>0.1*price_average
 GROUP BY event_date;
 
 -- Give a complete list ordered by wallet profitability (whether people have made or lost money)
 
SELECT
    wallet_address,
    SUM(CASE WHEN is_buyer THEN -usd_price ELSE usd_price END) AS total_profit_loss
FROM (SELECT
        buyer_address AS wallet_address,
        usd_price,
        true AS is_buyer
    FROM pricedata
    UNION ALL
    SELECT
        seller_address AS wallet_address,
        usd_price,
        false AS is_buyer
    FROM pricedata) AS transactions
GROUP BY
    wallet_address
ORDER BY
    total_profit_loss DESC;
    
    
    