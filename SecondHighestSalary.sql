/*SQL Interview Problem: Finding the Nth Highest Value
Problem Statement: Second Highest Salary

As an HR Analyst, the goal is to conduct a simple, high-level analysis of the pay distribution across the company. The manager requires a query that efficiently determines the second highest salary paid to any employee in the company.
Requirements:
Input Table: employee (salary, employee_id, etc.).
Logic: Identify the salary value that ranks second overall.
Handling Duplicates (Crucial): If multiple employees share the second highest salary value, that salary should only be listed once in the final output. If only one unique salary exists, the output should be NULL.
Output: A single column named second_highest_salary containing the numeric value.*/


WITH highest_salary_cte AS (
  SELECT MAX(salary) AS highest_salary
  FROM employee
)

SELECT
MAX(salary) as second_highest_salary
FROM employee
WHERE salary
< ( SELECT * FROM highest_salary_cte

)
