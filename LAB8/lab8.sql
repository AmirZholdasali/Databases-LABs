--Task 2.1:
CREATE INDEX emp_salary_idx ON employees(salary);
--I see 2 indexes. 1 

--Task 2.2:
CREATE INDEX emp_dept_idx ON employees(dept_id);
--Because queries will become faster

--Task 2.3:
--I see: departments_pkey, dept_summary_mv_idx, emp_dept_idx, emp_salary_idx, employees_pkey, projects_pkey
--projects_pkey, employees_pkey, departments_pkey are created automatically

--Task 3.1:
--In this case, PostgreSQL can't use this index effectively.

--Task 3.2:
--It does matter. For example, index (dept_id, salary); speed up queries such as: WHERE dept_id= or WHERE dept_id=... AND salary=... But it does not speed up queries such as: WHERE salary=... or ORDER BY salary.

--Task 4.1:
--ERROR: Duplicate key value violates uniqueness constraint "employees_pkey"
--Details: Key "(emp_id)=(6)" already exists.

--Task 4.2:
--Postgre automatically created unique index.

--Task 5.1:
--It stores the values in DESC order, so the queries with ORDER BY DESC works faster.

--Task 5.2:
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

--Task 6.1:
--Postgre would use LOWER() function for every single row.

--Task 6.2:
CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

--Task 7.1:
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

--Task 7.2:
DROP INDEX emp_salary_dept_idx;
--We drop indexes because it may slow down insert and index is not used.

--Task 7.3:
REINDEX INDEX employees_salary_index;

--Task 8.1:
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

--Task 8.2:
CREATE INDEX proj_high_budget_idx ON projects(budget) WHERE budget > 80000;
--With partial index we store less -> faster.

--Task 8.3:
--Sequental scan. I think Postgre chose seq scan because my salary column is not big enough to use index.

--Task 9.1:
--Hash index is faster when we compare for identity.

--Task 9.2:
CREATE INDEX proj_name_btree_idx ON projects(project_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (project_name);
SELECT * FROM projects WHERE project_name = 'Website Redesign';
SELECT * FROM projects WHERE project_name > 'Database';

--Task 10.1:
--dept_name_hash_idx is largest because it is a hash index. Hash indexes stores additional hash values ​​of each key.

--Task 10.2:
DROP INDEX IF EXISTS proj_name_hash_idx;

--Task 10.3:
CREATE VIEW index_documentation AS
SELECT
 tablename,
 indexname,
 indexdef,
 'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
 AND indexname LIKE '%salary%';
SELECT * FROM index_documentation;