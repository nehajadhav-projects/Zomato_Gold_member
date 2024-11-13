CREATE DATABASE zomato;

USE zomato;

CREATE TABLE goldusers_signup
(userid INT,
gold_signup_date DATE
);

INSERT INTO goldusers_signup
VALUES
(1,'2017-09-22'),
(3,'2017-04-21');

CREATE TABLE users
(userid INT,
signup_date DATE
);

INSERT INTO users
VALUES
(1,'2014-09-02'),
(2,'2015-01-15'),
(3,'2014-04-11');

CREATE TABLE sales
(userid INT,
created_date DATE,
product_id INT
);

INSERT INTO sales
VALUES
(1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);

CREATE TABLE product
(product_id INT,
product_name TEXT,
price INT
);

INSERT INTO product
VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);

SELECT * FROM sales;

SELECT * FROM product;

SELECT * FROM goldusers_signup;

SELECT * FROM users;

#1.What is the total amount each customer spent on zomato?
SELECT 
    a.userid, SUM(b.price) AS total_amount_spent
FROM
    sales AS a
        INNER JOIN
    product AS b ON a.product_id = b.product_id
GROUP BY a.userid;

#2.How many days has each customer visited zomato?
SELECT 
    userid, COUNT(DISTINCT created_date) AS times_visited
FROM
    sales
GROUP BY userid;

#3.What is the first product purchased by each customer?
SELECT * FROM(
SELECT *,RANK()OVER(PARTITION BY userid ORDER BY created_date ASC)AS rnk FROM sales)AS a 
WHERE rnk=1;

#4.what is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_id, purchase_count  FROM  (
SELECT product_id, COUNT(product_id) AS purchase_count FROM sales GROUP BY product_id )as products_counts
order by purchase_count desc
limit 1;  

-- select top 1 product_id from sales group by product_id order by count(product_id)desc;

#5.which item was the most popular for each customers?
SELECT * FROM
(SELECT *,RANK()OVER(PARTITION BY userid ORDER BY cnt DESC)AS rnk FROM
(SELECT userid,product_id,COUNT(product_id)as cnt FROM sales GROUP by userid,product_id)a)b
where rnk=1;

#6.which item was purchased 1st by the customer after they became a member?
select * from 
(Select c.*,rank()over(partition by userid order by created_date)as rnk from
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales as a inner join goldusers_signup as b 
on a.userid=b.userid
and created_date>=gold_signup_date)as c)as d
where rnk=1;

#7.Which item was purchased just before the customer became a member?
select * from 
(Select c.*,rank()over(partition by userid order by created_date desc)as rnk from
(SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales as a inner join goldusers_signup as b 
on a.userid=b.userid
and created_date<=gold_signup_date)as c)as d
where rnk=1;

#8.what is the total orders and amount spent for each member before they became a member?
SELECT 
    userid,
    COUNT(created_date) AS order_purchased,
    SUM(price) AS total_amount_spent
FROM
    (SELECT 
        c.*, d.price
    FROM
        (SELECT 
        a.userid, a.created_date, a.product_id, b.gold_signup_date
    FROM
        sales AS a
    INNER JOIN goldusers_signup AS b ON a.userid = b.userid
        AND created_date <= gold_signup_date) AS c
    INNER JOIN product AS d ON c.product_id = d.product_id) AS e
GROUP BY userid;

/*9.if buying each product generates points for eg 5rs=2 zomato point and each product has different purchasing points for eg
 for  p1 5rs=1 zomato point ,for p2 10rs= 5 zomato point and p3 5rs=1 zomato point.
 Calculate points collected by each customers and for which product most points have been given till now.
*/
SELECT 
    userid, SUM(total_points)*2.5 AS total_money_earned
FROM
    (SELECT 
        e.*, ROUND(amt / points) AS total_points
    FROM
        (SELECT 
        d.*,
            CASE
                WHEN product_id = 1 THEN 5
                WHEN product_id = 2 THEN 2
                WHEN product_id = 3 THEN 5
                ELSE 0
            END AS points
    FROM
        (SELECT 
        c.userid, c.product_id, SUM(price) AS amt
    FROM
        (SELECT 
        a.*, b.price
    FROM
        sales AS a
    INNER JOIN product AS b ON a.product_id = b.product_id) AS c
    GROUP BY userid , product_id) AS d) AS e) AS f
GROUP BY userid;




SELECT * FROM
(SELECT *,RANK()OVER(ORDER BY total_points_earned DESC)AS rnk FROM 
(SELECT 
    product_id, SUM(total_points) AS total_points_earned
FROM
    (SELECT 
        e.*, ROUND(amt / points) AS total_points
    FROM
        (SELECT 
        d.*,
            CASE
                WHEN product_id = 1 THEN 5
                WHEN product_id = 2 THEN 2
                WHEN product_id = 3 THEN 5
                ELSE 0
            END AS points
    FROM
        (SELECT 
        c.userid, c.product_id, SUM(price) AS amt
    FROM
        (SELECT 
        a.*, b.price
    FROM
        sales AS a
    INNER JOIN product AS b ON a.product_id = b.product_id) AS c
    GROUP BY userid , product_id) AS d) AS e) AS f
GROUP BY product_id)AS f)g WHERE rnk=1;

/*10. In the first 1 year after a customers joins the gold program(including their join date) irrespective of what the customer
has purched they earn 5 zomato points for every  10 rs spent who earned more 1 or 3 and what was their earnings in their
first year?
1zp=2rs
0.5 zp=1rs
*/

SELECT 
    c.*, d.price * 0.5 AS total_points_earned
FROM
    (SELECT 
        a.userid, a.created_date, a.product_id, b.gold_signup_date
    FROM
        sales AS a
    INNER JOIN goldusers_signup AS b ON a.userid = b.userid
        AND created_date >= gold_signup_date
        AND created_date <= DATE_ADD(gold_signup_date, INTERVAL 365 DAY)) AS c
        INNER JOIN
    product AS d ON c.product_id = d.product_id;

#11.rnk all the transaction of the customers.

SELECT *,RANK()OVER(PARTITION BY userid ORDER BY created_date) AS rnk FROM sales;

/*12.rank all the transactions for each member whenever they are a zomato gold member for every non gold member
 transaction mark  as na.*/
 select e.*,case when rnk=0 then 'na' else rnk end as rnkk from
 (select c.*,case when gold_signup_date is null then 0 else rank()over(partition by userid order by created_date desc) end as rnk from
 (SELECT a.userid,a.created_date,a.product_id,b.gold_signup_date
from sales as a left join goldusers_signup as b 
on a.userid=b.userid
and created_date>=gold_signup_date)as c)as e;