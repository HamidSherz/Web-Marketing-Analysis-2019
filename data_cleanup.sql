-- Create the database
CREATE DATABASE Web_Marketing_Data;

-- Use the newly created database
USE Web_Marketing_Data;

-- Create User Sessions table
CREATE TABLE User_Sessions (
    Session_ID INT PRIMARY KEY,
    Country VARCHAR(50),
    Date DATE,
    Device_Category VARCHAR(50),
    Channel_Grouping VARCHAR(50),
    Source_Medium VARCHAR(50),
    Bounces INT,
    Exits INT,
    Page_Load_Time FLOAT,
    Pageviews INT,
    Sessions INT,
    Time_on_Page FLOAT,
    Unique_Pageviews INT
);

-- Create Pageviews table
CREATE TABLE Pageviews (
    Pageview_ID INT PRIMARY KEY,
    Session_ID INT,
    Page_Title VARCHAR(100),
    Page_URL VARCHAR(255),
    Bounces INT,
    Exits INT,
    FOREIGN KEY (Session_ID) REFERENCES User_Sessions(Session_ID) -- Connecting to User Sessions
);

-- Create Traffic Sources table
CREATE TABLE Traffic_Sources (
    Source_ID INT PRIMARY KEY,
    Pageview_ID INT,  -- Change to connect to Pageviews table
    Source_Type VARCHAR(50),
    Campaign_Name VARCHAR(100),
    FOREIGN KEY (Pageview_ID) REFERENCES Pageviews(Pageview_ID) -- Connecting to Pageviews
);

-- Create Engagement Metrics table
CREATE TABLE Engagement_Metrics (
    Engagement_ID INT PRIMARY KEY,
    Source_ID INT,  -- Change to connect to Traffic Sources table
    Average_Bounce_Rate FLOAT,
    Average_Exit_Rate FLOAT,
    Average_Time_on_Page FLOAT,
    Average_Page_Load_Time FLOAT,
    FOREIGN KEY (Source_ID) REFERENCES Traffic_Sources(Source_ID) -- Connecting to Traffic Sources
);

-- Create Marketing Campaigns table
CREATE TABLE Marketing_Campaigns (
    Campaign_ID INT PRIMARY KEY,
    Campaign_Name VARCHAR(100),
    Start_Date DATE,
    End_Date DATE,
    Budget FLOAT,
    Target_Audience VARCHAR(100)
);

-- Assuming the following tables: User_Sessions, Pageviews, Traffic_Sources, Engagement_Metrics, Marketing_Campaigns

-- 1. Cleaning up User Sessions: Remove any sessions with null values in critical fields.
DELETE FROM User_Sessions 
WHERE Session_ID IS NULL OR Country IS NULL OR Date IS NULL OR Device_Category IS NULL;

-- 2. Standardizing Date Format: Ensure all date entries in the Page Views table are in 'YYYY-MM-DD' format.
UPDATE Pageviews 
SET Date = STR_TO_DATE(Date, '%m/%d/%y') 
WHERE STR_TO_DATE(Date, '%Y-%m-%d') IS NULL;

-- Issue 1: Duplicate Entries in Traffic Sources
-- Removing duplicates based on Source Name and Medium.
DELETE t1 
FROM Traffic_Sources t1
INNER JOIN Traffic_Sources t2 
WHERE 
    t1.Source_ID > t2.Source_ID AND 
    t1.Source_Type = t2.Source_Type AND 
    t1.Campaign_Name = t2.Campaign_Name;

-- 3. Cleaning Engagement Metrics: Update null values for Average Time on Page.
UPDATE Engagement_Metrics 
SET Average_Time_on_Page = 0 
WHERE Average_Time_on_Page IS NULL;

-- Issue 2 : Inconsistent Device Category Names
-- Standardizing device categories to ensure consistency.
UPDATE User_Sessions 
SET Device_Category = 'Mobile' 
WHERE Device_Category IN ('Smartphone', 'Phone');

-- 4. Validating Marketing Campaign Data: Ensuring no campaigns have null values in the Start_Date and End_Date fields.
DELETE FROM Marketing_Campaigns 
WHERE Start_Date IS NULL OR End_Date IS NULL;

-- 5. Aggregate Performance Metrics by Channel Grouping
SELECT Channel_Grouping, 
       SUM(Pageviews) AS Total_Pageviews, 
       AVG(Bounces) AS Average_Bounce_Rate 
FROM User_Sessions 
GROUP BY Channel_Grouping;

-- 6. Analyze User Engagement by Device Category
SELECT Device_Category, 
       AVG(Average_Time_on_Page) AS Average_Time_On_Page 
FROM Engagement_Metrics 
GROUP BY Device_Category;

-- 7. Join all tables into the comprehensive dataset for analysis
CREATE TABLE Web_Marketing_Data AS 
SELECT 
    us.Channel_Grouping,
    us.Country,
    us.Date,
    us.Device_Category,
    p.Page_Title,
    us.Source_Medium,
    us.Bounces,
    us.Exits,
    us.Page_Load_Time,
    us.Pageviews,
    us.Sessions,
    us.Time_on_Page,
    us.Unique_Pageviews
FROM User_Sessions us
JOIN Pageviews p ON us.Session_ID = p.Session_ID
JOIN Traffic_Sources ts ON p.Pageview_ID = ts.Pageview_ID
JOIN Engagement_Metrics em ON ts.Source_ID = em.Source_ID;