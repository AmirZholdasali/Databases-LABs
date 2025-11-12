--Task 2.1:
CREATE VIEW emp_view
AS
SELECT e.emp_name, e.salary, d.dept_name, d.location
FROM employees e JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NOT NULL;
--4 rows are returned, Tom Brown is not included because he has no department

--Task 2.2:
CREATE VIEW dept_statistics
AS
SELECT d.dept_name, count(e.emp_name) AS employee_cnt, avg(e.salary), max(e.salary), min(e.salary)
FROM departments d LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY emp_id, dept_name
ORDER BY employee_cnt DESC;

--Task 2.3:
CREATE VIEW project_overview
AS
SELECT p.project_name, p.budget, d.dept_name, d.location, count(e.emp_id) AS team_size
FROM projects p JOIN departments d ON p.dept_id = d.dept_id
JOIN employees e ON d.dept_id = e.dept_id
GROUP BY project_name, budget, dept_name, location;

--Task 2.4:
CREATE VIEW high_earners
AS
SELECT e.emp_name, e.salary, d.dept_name
FROM employees e JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;
--I see Jane Doe and Sarrah Williams.


--Task 3.1
CREATE OR REPLACE VIEW employee_details AS
SELECT e.emp_name, e.salary, d.dept_name, d.location,
CASE
    WHEN e.salary > 60000 THEN 'High'
    WHEN e.salary > 50000 THEN 'Medium'
    ELSE 'Standard'
END AS salary_grade
FROM employees e JOIN departments d ON e.dept_id = d.dept_id
WHERE d.dept_id IS NOT NULL;

--Task 3.2
ALTER VIEW high_earners RENAME TO top_performers;

--Task 3.3:
CREATE TEMP VIEW temp_view
AS
SELECT e.emp_name, e.salary
FROM employees e
WHERE e.salary < 50000;

DROP VIEW temp_view;


--Task 4.1:
CREATE VIEW employee_salaries AS
SELECT e.emp_id, e.emp_name, e.dept_id, e.salary
FROM employees e;

--Task 4.2:
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

--Task 4.3:
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary) VALUES(6, 'Alice Johnson', 102, 58000);
--The insert was successful.

--Task 4.4:
CREATE VIEW it_employees
AS
SELECT e.emp_name
FROM employees e
WHERE e.dept_id = 101
WITH LOCAL CHECK OPTION;


--Task 5.1:
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT d.dept_id, d.dept_name, count(e.emp_id) AS employee_cnt, coalesce(sum(e.salary), 0) AS salary_total, count(p.project_id) AS project_cnt, coalesce(sum(p.budget), 0) AS budget_total
FROM departments d LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON e.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;

--Task 5.2:
INSERT INTO employees (emp_name, emp_id, dept_id, salary)
VALUES ('Charlie Brown', 8, 101, 54000);

REFRESH MATERIALIZED VIEW dept_summary_mv;

--Task 5.3:
CREATE UNIQUE INDEX dept_summary_mv_idx ON dept_summary_mv(dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;
--CONCURRENTLY allows us to read (SELECT) the view while refreshing.

--Task 5.4:
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT p.project_name, p.budget, d.dept_name, count(e.emp_id)
FROM projects p LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY project_name, budget, dept_name
WITH NO DATA;
--ERROR: Materialized view "project_stats_mv" was not populated

--Task 6.1:
CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer LOGIN PASSWORD 'viewer123';
CREATE USER report_user PASSWORD 'report 456';

--Task 6.2:
CREATE ROLE db_creator LOGIN CREATEDB PASSWORD 'creator789';
CREATE ROLE user_manager LOGIN CREATEROLE PASSWORD 'manager101';
CREATE ROLE admin_user LOGIN SUPERUSER PASSWORD 'admin999';

--Task 6.3:
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

--Task 6.4:
CREATE ROLE hr_team;
CREATE ROLE finance_team;
CREATE ROLE it_team;

CREATE USER hr_user1 PASSWORD 'hr001';
CREATE USER hr_user2 PASSWORD 'hr002';
CREATE USER finance_user1 PASSWORD 'fin001';

GRANT hr_team TO hr_user1;
GRANT hr_team TO hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

--Task 6.5:
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

--Task 6.6:
ALTER ROLE analyst LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager SUPERUSER;
ALTER ROLE analyst PASSWORD NULL;
ALTER ROLE data_viewer CONNECTION LIMIT 5;

--Task 7.1:
CREATE ROLE read_only NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;
CREATE ROLE junior_analyst LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst LOGIN PASSWORD 'senior123';
GRANT read_only TO junior_analyst;
GRANT read_only TO senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;

--Task 7.2:
CREATE ROLE project_manager LOGIN PASSWORD 'pm123';
ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

--Task 7.3:
CREATE ROLE temp_owner LOGIN;
CREATE TABLE temp_table(
    id INT
);
ALTER TABLE temp_table OWNER TO temp_owner;
REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

--Task 7.4:
CREATE VIEW hr_employee_view AS
SELECT e.emp_id, e.emp_name, e.salary
FROM employees e
WHERE e.dept_id = 102;

GRANT SELECT ON hr_employee_view TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT e.emp_id, e.emp_name, e.salary
FROM employees e;

GRANT SELECT ON finance_employee_view TO finance_team;


--Task 8.1:
CREATE VIEW dept_dashboard AS
SELECT d.dept_name,
       d.location,
       count(e.emp_id),
       round(avg(e.salary)::numeric, 2) AS avg_salary,
       count(p.project_id) AS projects_num,
       sum(p.budget) AS project_budget,
       ROUND(COALESCE(SUM(p.budget) / NULLIF(COUNT(e.emp_id), 0), 0), 2) AS budget_per_employee
FROM departments d LEFT JOIN projects p ON d.dept_id = p.dept_id
LEFT JOIN employees e ON p.dept_id = e.dept_id
GROUP BY dept_name, location;

--Task 8.2:
ALTER TABLE projects
ADD COLUMN created_date DATE DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT p.project_id, p.project_name, p.budget
FROM projects p
WHERE p.budget > 75000;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT p.project_id, p.project_name, p.budget, d.dept_name, p.created_date
FROM projects p LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

CREATE OR REPLACE VIEW high_budget_projects AS
SELECT p.project_id, p.project_name, p.budget, d.dept_name, p.created_date,
       CASE
           WHEN p.budget > 150000 THEN 'Critical Review Required'
           WHEN p.budget > 10000 THEN 'Managment Approval Needed'
           ELSE 'Standard Process'
       END AS approval_status

FROM projects p LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

--Task 8.3:
CREATE ROLE viewer_role NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO viewer_role;

CREATE ROLE entry_role NOLOGIN;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

CREATE ROLE analyst_role NOLOGIN;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

CREATE ROLE manager_role NOLOGIN;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

CREATE ROLE alice LOGIN PASSWORD 'alice123';
CREATE ROLE bob LOGIN PASSWORD 'bob123';
CREATE ROLE charlie LOGIN PASSWORD 'charlie123';

GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;

