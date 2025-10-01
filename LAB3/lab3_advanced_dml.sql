-- Part A: Database and Table Setup
CREATE DATABASE advanced_lab;

CREATE TABLE employees (
    emp_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    department VARCHAR(100) DEFAULT NULL,
    salary INTEGER DEFAULT 0,
    hire_date DATE,
    status VARCHAR(50) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id SERIAL PRIMARY KEY,
    dept_name VARCHAR(100),
    budget INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    dept_id INTEGER,
    start_date DATE,
    end_date DATE,
    budget INTEGER
);

-- Part B: Advanced INSERT Operations
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'John', 'Doe', 'IT');

INSERT INTO employees (first_name, last_name, department)
VALUES ('Jane', 'Smith', 'HR');

INSERT INTO employees (first_name, last_name, department, salary)
VALUES ('Bob', 'Miller', 'Finance', DEFAULT);

INSERT INTO employees (first_name, last_name)
VALUES ('Alice', 'Brown');

INSERT INTO departments (dept_name, budget, manager_id)
VALUES 
('HR', 80000, 1),
('Finance', 120000, 2),
('IT', 150000, 3);

INSERT INTO employees (first_name, last_name, department, hire_date, salary)
VALUES ('Chris', 'Evans', 'Engineering', CURRENT_DATE, 50000 * 1.1);

CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

-- Part C: Complex UPDATE Operations
UPDATE employees
SET salary = salary * 1.1;

UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

UPDATE departments
SET budget = (SELECT AVG(salary) * 1.2
              FROM employees e
              WHERE e.department = departments.dept_name);

UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

-- Part D: Advanced DELETE Operations
DELETE FROM employees
WHERE status = 'Terminated';

DELETE FROM employees
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

DELETE FROM departments
WHERE dept_id NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- Part E: Operations with NULL Values
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('Null', 'Case', NULL, NULL);

UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

-- Part F: RETURNING Clause Operations
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Tom', 'Hanks', 'PR', 60000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- Part G: Advanced DML Patterns
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Mark', 'Twain', 'Literature', 45000, CURRENT_DATE
WHERE NOT EXISTS (
    SELECT 1 FROM employees WHERE first_name = 'Mark' AND last_name = 'Twain'
);

UPDATE employees
SET salary = salary * (
    CASE WHEN (SELECT budget FROM departments d WHERE d.dept_name = employees.department) > 100000
         THEN 1.1 ELSE 1.05 END
);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
('A1', 'B1', 'IT', 40000, CURRENT_DATE),
('A2', 'B2', 'HR', 42000, CURRENT_DATE),
('A3', 'B3', 'Finance', 45000, CURRENT_DATE),
('A4', 'B4', 'Sales', 46000, CURRENT_DATE),
('A5', 'B5', 'IT', 47000, CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.1
WHERE first_name IN ('A1','A2','A3','A4','A5');

CREATE TABLE employee_archive AS
TABLE employees WITH NO DATA;

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees
WHERE status = 'Inactive';

UPDATE projects
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
  AND dept_id IN (
      SELECT dept_id FROM departments d
      WHERE (SELECT COUNT(*) FROM employees e WHERE e.department = d.dept_name) > 3
  );
