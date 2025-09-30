-- Part A
-- Task 1
CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary INT DEFAULT 40000,
    hire_date DATE,
    status VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(50),
    budget INT,
    manager_id INT
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INT,
    start_date DATE,
    end_date DATE,
    budget INT
);

-- Part B
-- Task 2
INSERT INTO employees (first_name, last_name, department)
VALUES ('Almas', 'Nagimov', 'IT');

-- Task 3
INSERT INTO employees (first_name, last_name, department)
VALUES ('Arman', 'Seifullin', 'Building');

-- Task 4
INSERT INTO departments (dept_name, budget, manager_id)
VALUES
('IT', 100000, 1),
('Building', 80000, 2),
('Manager', 120000, 3);

-- Task 5
INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Asylbek', 'Shoytasov', 'Manager', CURRENT_DATE, 50000 * 1.1);

-- Task 6
CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- Part C
-- Task 7
UPDATE employees
SET salary = salary * 1.10;

-- Task 8
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- Task 9
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

-- Task 10
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- Task 11
UPDATE departments d
SET budget = (SELECT AVG(e.salary) * 1.20
              FROM employees e
              WHERE e.department = d.dept_name);

-- Task 12
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'HR';

-- Part D
-- Task 13
DELETE FROM employees
WHERE status = 'Terminated';

-- Task 14
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- Task 15
DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

-- Task 16
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- Part E
-- Task 17
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Sayat', 'Zhaksybai', NULL, NULL);

-- Task 18
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- Task 19
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- Part F
-- Task 20
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Arai', 'Nusip', 'IT', 55000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- Task 21
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, (salary - 5000) AS old_salary, salary AS new_salary;

-- Task 22
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- Part G
-- Task 23
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Aru', 'Bekmakhan', 'IT', 60000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM employees
    WHERE first_name = 'Aru' AND last_name = 'Bekmakhan'
);

-- Task 24
UPDATE employees e
SET salary = CASE
    WHEN (SELECT budget FROM departments d WHERE d.dept_name = e.department) > 100000
         THEN salary * 1.10
    ELSE salary * 1.05
END;

-- Task 25
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
('name1', 'surname1', 'HR', 45000, CURRENT_DATE),
('name2', 'surname2', 'HR', 47000, CURRENT_DATE),
('name3', 'surname3', 'HR', 48000, CURRENT_DATE),
('name4', 'surname4', 'HR', 46000, CURRENT_DATE),
('name5', 'surname5', 'HR', 50000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.10
WHERE department = 'HR';

-- Task 26
CREATE TABLE employee_archive AS
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

-- Task 27
INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('smartnation', 1, CURRENT_DATE, CURRENT_DATE + INTERVAL '90 days', 60000);

UPDATE projects p
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND (SELECT COUNT(*) FROM employees e WHERE e.department = p.dept_id) > 3;
