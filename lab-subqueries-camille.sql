# LAB: SUBQUERIES

# 1. How many copies of the film Hunchback Impossible exist in the inventory system?
SELECT
	COUNT(inventory_id) AS number_of_copies_of_Hunchback_Impossible
FROM
	inventory
WHERE
	film_id IN (
		SELECT
			film_id
		FROM 
			film
		WHERE
			title = "Hunchback Impossible")
;

# 2. List all films whose length is longer than the average of all the films.
SELECT
	title
FROM
	film
WHERE
	length > (SELECT AVG(length)
			  FROM film)
;

# 3. Use subqueries to display all actors who appear in the film Alone Trip.
# GETTING THE FILM ID
SELECT 
	film_id
FROM
	film
WHERE 
	title = "Alone Trip";
# GETTING THE ACTOR ID
SELECT
	actor_id
FROM
	film_actor
WHERE
	film_id IN (SELECT 
					film_id
				FROM
					film
				WHERE title = "Alone Trip")
;
# FINALLY GETTING THE ACTOR NAME:
SELECT
	CONCAT(last_name, " ", first_name) AS actor_name
FROM
	actor
WHERE
	actor_id IN (SELECT
					actor_id
				FROM
					film_actor
				WHERE
					film_id IN (SELECT 
									film_id
								FROM
									film
								WHERE 
									title = "Alone Trip")
					)
;

# 4. Sales have been lagging among young families, and you wish to target all family movies for a promotion. 
	# Identify all movies categorized as family films.
# GETTING THE CATEGORY ID
SELECT
	category_id
FROM
	category
WHERE
	name = "Family";
# GETTING THE FILM IDs
SELECT
	film_id
FROM
	film_category
WHERE
	category_id IN (SELECT
					category_id
				FROM
					category
				WHERE
					name = "Family"
    )
;
# GETTING THE TITLE LIST
SELECT
	title
FROM
	film
WHERE
	film_id IN (SELECT
					film_id
				FROM
					film_category
				WHERE
					category_id IN (SELECT
										category_id
									FROM
										category
									WHERE
										name = "Family"
				)
    )
;
   
# 5. Get name and email from customers from Canada using subqueries. 
	# Do the same with joins. 
    # Note that to create a join, you will have to identify the correct tables with their primary keys and foreign keys, that will help you get the relevant information.
# GETTING THE COUNTRY ID
SELECT
	country_id
FROM
	country
WHERE
	country = "Canada";
    
# GETTING THE CITY IDs
SELECT
	city_id
FROM
	city
WHERE
	country_id IN (SELECT
						country_id
					FROM
						country
					WHERE
						country = "Canada"
					)
;
# GETTING THE ADDRESS IDs
SELECT
	address_id
FROM
	address
WHERE
	city_id IN (SELECT
					city_id
				FROM
					city
				WHERE
					country_id IN (SELECT
										country_id
									FROM
										country
									WHERE
										country = "Canada"
									)
				)
;
# GETTING THE LIST OF CUSTOMER BASED IN CANADA
SELECT
	CONCAT(last_name, " ", first_name) AS customer
FROM
	customer
WHERE
	address_id IN (SELECT
						address_id
					FROM
						address
					WHERE
						city_id IN (SELECT
										city_id
									FROM
										city
									WHERE
										country_id IN (SELECT
															country_id
														FROM
															country
														WHERE
															country = "Canada"
														)
									)
					)
;
# As a side note, address_id 1 and 3 that are in the second to last subquery are the ones of the store and staff respectively, which is why they don't appear in the final query.

# 6. Which are films starred by the most prolific actor? Most prolific actor is defined as the actor that has acted in the most number of films. 
	# First you will have to find the most prolific actor and then use that actor_id to find the different films that he/she starred.
# CREATING A TEMP TABLE TO HAVE THE COUNT OF FILM PER ACTOR
CREATE TEMPORARY TABLE count
SELECT
	actor_id,
	COUNT(film_id) AS num_films
FROM
	film_actor
GROUP BY
	actor_id
ORDER BY
	num_films DESC;
# CHECKING TABLE
SELECT 
	* 
FROM 
	count;

# MAX FILM PER ACTOR
SELECT
	MAX(num_films)
FROM
	count;

# MOST PROLIFIC ACTOR WITH JOIN (NO NEED FOR THE NAME REALLY BUT I JUST LIKE TO KNOW)
SELECT
	CONCAT(A.last_name, " ", A.first_name) AS actor_name,
	FA.actor_id,
	COUNT(FA.film_id) AS num_films
FROM
	film_actor FA
    INNER JOIN
		actor A
	ON
		A.actor_id = FA.actor_id
GROUP BY
	actor_id
HAVING
	num_films = (SELECT
					MAX(num_films)
				FROM
					count
				)
;

# MOST PROLIFIC ACTOR NAME WITH SUBEQUERIES ONLY (NO NEED FOR THE NAME REALLY BUT I JUST LIKE TO KNOW)
SELECT
	CONCAT(last_name, " ", first_name) AS actor_name
FROM
	actor
WHERE
	actor_id IN (SELECT
					actor_id
				FROM
					film_actor
				GROUP BY
					actor_id
				HAVING
					COUNT(film_id) = (SELECT
										MAX(num_films)
									FROM
										count
									)
				)
;

# CREATE TEMP TABLE WITH JUST THE ACTOR ID
CREATE TEMPORARY TABLE best_thesp
SELECT
	actor_id
FROM
	film_actor
GROUP BY
	actor_id
HAVING
	COUNT(film_id) = (SELECT
					MAX(num_films)
				FROM
					count
				)
;
SELECT
	*
FROM
	best_thesp;

# GETTING THE FILMS STARRED BY THE MOST PROLIFIC ACTOR
SELECT
	title, film_id
FROM
	film
WHERE
	film_id IN (SELECT
					film_id
				FROM
					film_actor
				WHERE
					actor_id = (SELECT
									*
								FROM
									best_thesp
								)
				)
ORDER BY
	title ASC;
    
# 7. Films rented by most profitable customer. 
	# You can use the customer table and payment table to find the most profitable customer ie the customer that has made the largest sum of payments
# GETTING LARGEST SUM OF PAYMENT
CREATE TEMPORARY TABLE money_money
SELECT
	customer_id,
    SUM(amount) AS payment_sum
FROM
	payment
GROUP BY
	customer_id
ORDER BY
	payment_sum DESC;
# CHECKING
SELECT
	*
FROM
	money_money;

# GETTING THE MAX PAYMENT SUM
SELECT
	MAX(payment_sum)
FROM
	money_money;
    
# GETTING THE MOST PROFITABLE CUSTOMER (USING A JOIN)
SELECT
	CONCAT(C.last_name, " ", C.first_name) AS customer_name,
	P.customer_id
FROM
	payment P
	INNER JOIN
		customer C
	ON
		C.customer_id = P.customer_id
GROUP BY
	customer_id
HAVING
	SUM(P.amount) = (SELECT
						MAX(payment_sum)
					FROM
						money_money
					)
;

# GETTING THE MOST PROFITABLE CUSTOMER (USING SUBQUERIES ONLY) -> FASTER
SELECT
	CONCAT(last_name, " ", first_name) AS customer_name
FROM
	customer
WHERE
	customer_id IN (SELECT
						customer_id
					FROM
						payment
					GROUP BY
						customer_id
					HAVING
						SUM(amount) = (SELECT
											MAX(payment_sum)
										FROM
											money_money
										)
					)
;

# 8. Get the client_id and the total_amount_spent of those clients who spent more than the average of the total_amount spent by each client.
SELECT
	customer_id,
    SUM(amount) AS total_paid
FROM
	payment
GROUP BY
	customer_id
ORDER BY
	total_paid DESC;

SELECT
	ROUND(AVG(total_paid))
FROM
	(SELECT
		customer_id,
		SUM(amount) AS total_paid
	FROM
		payment
	GROUP BY
		customer_id) AS totals
;

SELECT
	customer_id,
    SUM(amount) AS total_paid
FROM
	payment
GROUP BY
	customer_id
HAVING
	total_paid > (SELECT
					ROUND(AVG(total_paid))
				FROM
					(SELECT
						customer_id,
						SUM(amount) AS total_paid
					FROM
						payment
					GROUP BY
						customer_id) AS totals
				)
ORDER BY
	total_paid ASC;



