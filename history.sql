--Create bank-full Table
COPY "bank-marketing".public."bank-full" FROM 's3://bank-marketing-dwh/data_typefixed/full-additional.csv' IAM_ROLE 'arn:aws:iam::051328325616:role/RedshiftServerless1' FORMAT AS CSV DELIMITER ',' QUOTE '"' IGNOREHEADER 1 REGION AS 'us-east-1'

-- Create term_deposit from bank-full
CREATE TABLE public."term_deposit" as (
    select
    "bank-full".customer_id as customer_id,
    "bank-full".y as success
    FROM public."bank-full");

ALTER TABLE public."term_deposit"
ADD PRIMARY KEY (customer_id);

-- Create dimJobType Table and polulate it
CREATE TABLE dimJobType (
    jobID INT PRIMARY KEY,
    jobType VARCHAR(30)
);

INSERT INTO dimJobType (jobID, jobType)
SELECT 
    ROW_NUMBER() OVER (ORDER BY job) AS jobID,
    job AS jobType
FROM "bank-full"
GROUP BY job;

--Create Table dimEduType and populate it
CREATE TABLE dimEduType (
    eduID INT PRIMARY KEY,
    eduType VARCHAR(30) 
);

INSERT INTO dimEduType (eduID, eduType)
SELECT 
    ROW_NUMBER() OVER (ORDER BY education) AS eduID,
    education AS eduType
FROM "bank-full"
GROUP BY education;


-- Create table dimBasicInfo

CREATE TABLE dimbasicinfo (
    customer_id INT,
    age INT,
    marital VARCHAR(255),
    job_id INT,
    edu_id INT,
    PRIMARY KEY (customer_id)
);

-- Add Foreign Key constraints

ALTER TABLE dimbasicinfo
ADD FOREIGN KEY (customer_id) REFERENCES term_deposit(customer_id),
ADD FOREIGN KEY (job_id) REFERENCES dimJobType(job_id),
ADD FOREIGN KEY (edu_id) REFERENCES dimEduType(edu_id);

--  Populate the table

INSERT INTO dimbasicinfo (customer_id, age, marital, job_id, edu_id)
SELECT
    "term_deposit".customer_id as customer_id,
    "bank-full".age as age,
    "bank-full".marital as marital,
    "dimjobtype".job_id as job_id,
    "dimedutype".edu_id as edu_id
FROM "term_deposit"
JOIN "bank-full" ON "term_deposit".customer_id = "bank-full".customer_id
JOIN "dimjobtype" ON "bank-full".job = "dimjobtype".jobType
JOIN "dimedutype" ON "bank-full".education = "dimedutype".eduType;

-- dimfinances

CREATE TABLE dimfinances(
    customer_id INT,
    housing VARCHAR,
    loan VARCHAR,
    def VARCHAR
)

ALTER TABLE dimfinances
    ADD FOREIGN KEY (customer_id) REFERENCES termdeposit(customer_id)

INSERT INTO dimfinances(housing, loan,def,customer_id)
SELECT
    "bank-full".housing as housing,
    "bank-full".loan as loan,
    "bank-full"."default" as def,
    "bank-full".customer_id as customer_id
FROM "bank-full";

-- Rest of the Tables..
CREATE TABLE dimlastcontact(
    customer_id INT,
    month VARCHAR,
    dayofweek VARCHAR,
    duration INT
);

ALTER TABLE dimlastcontact
    ADD FOREIGN KEY (customer_id) REFERENCES termdeposit(customer_id);


CREATE TABLE dimprevcontact(
    customer_id INT,
    campaign INT,
    pdays INT,
    previous INT,
    poutcome VARCHAR,
    contact VARCHAR
);

ALTER TABLE dimprevcontact
    ADD FOREIGN KEY (customer_id) REFERENCES termdeposit(customer_id);

CREATE TABLE dimsocioecon(
    customer_id INT,
    emp_var_rate REAL,
    cons_price_idx REAL,
    cons_conf_idx VARCHAR,
    euribor3 REAL,
    nr_employed REAL
);

ALTER TABLE dimsocioecon
    ADD FOREIGN KEY (customer_id) REFERENCES termdeposit(customer_id);

INSERT INTO dimlastcontact(contact, month,dayofweek,duration,customer_id)
SELECT
    "bank-full".contact as contact,
    "bank-full".month as month,
    "bank-full".day_of_week as dayofweek,
    "bank-full".duration as duration,
    "bank-full".customer_id as customer_id
FROM "bank-full";

INSERT INTO dimsocioecon(emp_var_rate,cons_price_idx,cons_conf_idx,euribor3,nr_employed,customer_id)
SELECT
    "bank-full".emp_var_rate as emp_var_rate,
    "bank-full".cons_price_idx as cons_price_idx,
    "bank-full".cons_conf_idx as cons_conf_idx,
    "bank-full".euribor3m as euribor3m,
    "bank-full".nr_employed as nr_employed,
    "bank-full".customer_id as customer_id
FROM "bank-full";

-- Rest of the table are appended in the same way.

-- Connecting with Google Looker

CREATE USER looker_user WITH PASSWORD 'looker1Password';
GRANT USAGE ON SCHEMA public TO looker_user;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO looker_user;

GRANT SELECT ON TABLE information_schema.tables TO looker_user;
GRANT SELECT ON TABLE information_schema.columns TO looker_user;
ALTER USER looker_user SET search_path TO '$user',public;