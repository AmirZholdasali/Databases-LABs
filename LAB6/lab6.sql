--Task 1.1
-- Create table: employees
CREATE TABLE employees (
 emp_id INT PRIMARY KEY,
 emp_name VARCHAR(50),
 dept_id INT,
 salary DECIMAL(10, 2)
);
-- Create table: departments
CREATE TABLE departments (
 dept_id INT PRIMARY KEY,
 dept_name VARCHAR(50),
 location VARCHAR(50)
);
-- Create table: projects
CREATE TABLE projects (
 project_id INT PRIMARY KEY,
 project_name VARCHAR(50),
 dept_id INT,
 budget DECIMAL(10, 2)
);

--Task 1.2
-- Insert data into employees
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 102, 60000),
(3, 'Mike Johnson', 101, 55000),
(4, 'Sarah Williams', 103, 65000),
(5, 'Tom Brown', NULL, 45000);
-- Insert data into departments
INSERT INTO departments (dept_id, dept_name, location) VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Finance', 'Building C'),
(104, 'Marketing', 'Building D');
-- Insert data into projects
INSERT INTO projects (project_id, project_name, dept_id,
budget) VALUES
(1, 'Website Redesign', 101, 100000),
(2, 'Employee Training', 102, 50000),
(3, 'Budget Analysis', 103, 75000),
(4, 'Cloud Migration', 101, 150000),
(5, 'AI Research', NULL, 200000);

--Task 2.1
/*
N = 4, M = 5
N * M = ?
4 * 5 = 20 rows
*/

--Task 2.2
--a)
SELECT * FROM departments, employees;
--b)
SELECT * FROM employees JOIN departments ON TRUE;

--Task 2.3
 SELECT * FROM employees JOIN projects ON TRUE;

--Task 3.1
/*4 rows are returned.
The result has no person named Tom Brown, because departments table has only 4 id rows.*/

--Task 3.2
--No difference in output.

--Task 3.3
SELECT emp_name, dept_name, location
FROM employees
NATURAL INNER JOIN departments;

--Task 3.4
SELECT e.emp_name, d.dept_name, p.project_name
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id
INNER JOIN projects p ON d.dept_id = p.dept_id;

--Task 4.1
--Tom Brown has null value in each column.

--Task 4.2
SELECT e.emp_name, e.dept_id AS emp_dept, d.dept_id AS
dept_dept, d.dept_name
FROM employees e
LEFT JOIN departments d USING(dept_id);

--Task 4.3
SELECT e.emp_name, e.dept_id
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL;

--Task 4.4
SELECT d.dept_name, COUNT(e.emp_id) AS employee_count
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
ORDER BY employee_count DESC;

--Task 5.1
SELECT e.emp_name, d.dept_name
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id;

--Task 5.2
SELECT e.emp_name, d.dept_name
FROM departments d
LEFT JOIN employees e ON e.dept_id = d.dept_id;

--Task 5.3
SELECT d.dept_name, d.location
FROM employees e
RIGHT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.emp_id IS NULL;

--Task 6.1
--On the left side, on the 5th row emp_dept, on the 6th row emp_name and emp_dept.
--On the right side, on the 5th row dept_dept and dept_name.

--Task 6.2
SELECT d.dept_id, d.dept_name, p.project_name
FROM departments d FULL JOIN projects p USING(dept_id);

--Task 6.3
SELECT d.dept_id, d.dept_name, e.emp_name
FROM departments d FULL JOIN employees e ON e.dept_id = d.dept_id
WHERE d.dept_id IS NULL OR e.dept_id IS NULL;

--Task 7.1
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id AND
d.location = 'Building A';

--Task 7.2
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE d.location = 'Building A';
--WHERE clause works after ON, filtering the JOIN's result. 
--Query2 shows only employees with building A deparment.

--Task 7.3
SELECT e.emp_name, d.dept_name, e.salary
FROM employees e
INNER JOIN departments d 
  ON e.dept_id = d.dept_id 
  AND d.location = 'Building A'
UNION ALL
SELECT e.emp_name, NULL AS dept_name, e.salary
FROM employees e
WHERE e.dept_id NOT IN (
  SELECT dept_id 
  FROM departments 
  WHERE location = 'Building A'
);

--Task 8.1
SELECT
 d.dept_name,
 e.emp_name,
 e.salary,
 p.project_name,
 p.budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
ORDER BY d.dept_name, e.emp_name;

--Task 8.2
UPDATE employees SET manager_id = 3 WHERE emp_id = 1;
UPDATE employees SET manager_id = 3 WHERE emp_id = 2;
UPDATE employees SET manager_id = NULL WHERE emp_id = 3;
UPDATE employees SET manager_id = 3 WHERE emp_id = 4;
UPDATE employees SET manager_id = 3 WHERE emp_id = 5;

SELECT
 e.emp_name AS employee,
 m.emp_name AS manager
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id;

--Task 8.3
SELECT d.dept_name, AVG(e.salary) AS avg_salary
FROM departments d
INNER JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name
HAVING AVG(e.salary) > 50000;






