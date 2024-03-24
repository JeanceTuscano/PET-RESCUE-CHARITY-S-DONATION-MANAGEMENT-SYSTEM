-- Create a new database
CREATE DATABASE BI;

-- Use the new database
USE BI;

-- Create the Central_Donations_Repository table
CREATE TABLE Central_Donations_Repository (
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    group_leader VARCHAR(50),
    unit_num VARCHAR(50),
    street_number VARCHAR(50),
    street_name VARCHAR(50),
    street_type VARCHAR(50),
    street_direction VARCHAR(50),
    postal_code VARCHAR(50),
    city VARCHAR(50),
    province VARCHAR(50),
	donor_first_name VARCHAR(50), 
	donor_last_name VARCHAR(50), 
	donation_date date, 
	donation_amount int, 
	payment_method VARCHAR(50),
);



alter table Central_Donations_Repository
alter column donation_date date;




-- BULK INSERT data into Central_Donations_Repository table
BULK INSERT Central_Donations_Repository
FROM "C:\Users\tusca\Desktop\Projects\Central Donations\Database (1).csv"
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n'
);

Select * from Central_Donations_Repository;


CREATE PROCEDURE GetDonationStatsByDate
AS
BEGIN
    SELECT
        DAY(donation_date) AS day,
        MONTH(donation_date) AS month,
        YEAR(donation_date) AS year,
        AVG(donation_amount) AS avg_amount,
        SUM(donation_amount) AS total_amount
    FROM
        Central_Donations_Repository
    GROUP BY
        DAY(donation_date), MONTH(donation_date), YEAR(donation_date);
END;

--Executing stored procedure
EXEC GetDonationStatsByDate


-- Drop the existing stored procedure if it exists
IF OBJECT_ID('GetDonationStatsByLocationAndMonth', 'P') IS NOT NULL
    DROP PROCEDURE GetDonationStatsByLocationAndMonth;
GO

-- Create the new stored procedure
CREATE PROCEDURE GetDonationStatsByLocationAndMonth
    @target_city VARCHAR(50),
    @target_month INT
AS
BEGIN
    -- Check if the provided month is valid (between 1 and 12)
    IF @target_month < 1 OR @target_month > 12
    BEGIN
        PRINT 'Invalid month. Please provide a month between 1 and 12.';
        RETURN;
    END

    SELECT
        postal_code,
        city,
        AVG(donation_amount) AS avg_amount,
        SUM(donation_amount) AS total_amount
    FROM
        Central_Donations_Repository
    WHERE
        MONTH(donation_date) = @target_month AND city = @target_city
    GROUP BY
        postal_code, city;
END;



DECLARE @city VARCHAR(50) = 'Toronto'; -- Replace with the desired city
DECLARE @month INT = 7; -- Replace with the desired month

EXEC GetDonationStatsByLocationAndMonth @target_city = @city, @target_month = @month;

CREATE PROCEDURE GetPaymentStatsInCityWithHighestDonations
    @target_payment_method VARCHAR(50) OUTPUT
AS
BEGIN
    -- Declare a table variable to store the city with the highest donations
    DECLARE @CityWithHighestDonations TABLE (
        city VARCHAR(50)
    );

    -- Find the city with the highest total donations and insert into the table variable
    INSERT INTO @CityWithHighestDonations (city)
    SELECT TOP 1 city
    FROM Central_Donations_Repository
    GROUP BY city
    ORDER BY SUM(donation_amount) DESC;

    -- Get payment stats in the city with the highest donations
    SELECT TOP 1
        @target_payment_method = payment_method
    FROM
        Central_Donations_Repository cdr
    WHERE
        city IN (SELECT city FROM @CityWithHighestDonations)
    GROUP BY
        payment_method
    ORDER BY
        SUM(donation_amount) DESC;

END;

DECLARE @target_payment_method_output VARCHAR(50);

-- Execute the stored procedure
EXEC GetPaymentStatsInCityWithHighestDonations @target_payment_method = @target_payment_method_output OUTPUT;

-- Print or select the output parameter value
SELECT @target_payment_method_output AS TargetPaymentMethod;