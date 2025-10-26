Problem Statement: Identifying Top Earners in Each Department

As an HR Analyst, the goal is to generate a comprehensive report identifying "high earners" across the entire organization. 
A high earner is defined as any employee whose salary ranks among the top three salary tiers within their specific department.

This report requires careful handling of duplicate salaries and precise sorting to meet the manager's presentation requirements.


employee: Contains employee_id, name, salary, department_id.
department: Contains department_id, department_name.

Requirements:

Grouping: The ranking must be calculated independently for each department.
Ranking Criteria: Identify all employees whose salary falls into the top three salary tiers (<= 3).
Tie Handling (Crucial): If multiple employees share a salary that falls into the top three tiers, all employees must be included in the result set. (This is the strong hint to use DENSE_RANK).
Output Fields: Display the employee's name, department_name, and salary.
Final Sorting: The result must be sorted for presentation:
Primary Sort: department_name (Ascending).
Secondary Sort: salary (Descending).
Tertiary Sort: name (Alphabetical/Ascending).

--Assume the table containing employee data is named 'employees'

-- Step 2: Filter the results to include only the top 2 high earners.

WITH RankSalaries AS (
  SELECT 
    em.name,
    em.salary,
    em.department_id,
    DENSE_RANK() OVER (
      PARTITION BY em.department_id ORDER BY em.salary DESC) AS ranking
  FROM employee AS em
)

SELECT 
  dep.department_name,
  rs.name,
  rs.salary
FROM RankSalaries AS rs
INNER JOIN department AS dep
  ON rs.department_id = dep.department_id
WHERE rs.ranking <= 3
ORDER BY dep.department_name ASC, rs.salary DESC, rs.name ASC;






