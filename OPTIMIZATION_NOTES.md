# Optimization Strategy: NCC Activities Query

This document outlines the planned optimizations for the `NCC_Activities_Enhanced.sql` query to improve execution speed.

## 1. Identified Performance Bottlenecks

### 1.1. Non-SARGable Joins (The Primary Culprit)
The most significant performance issue is the `LEFT JOIN` condition:
```sql
LEFT OUTER JOIN [NCC_WFO_Telephony].[dbo].[SAP_StaffData_General] Sp
    ON Activity.BranchCallerEmployeeNumber = CONCAT('NB', Sp.StaffNo)
    OR Activity.BranchCallerEmployeeNumber = CONCAT('CC', Sp.StaffNo)
```
- **Issue**: The `OR` condition forces the SQL Server optimizer to scan the `SAP_StaffData_General` table repeatedly or perform a nested loop join without effective index usage.
- **Why**: Standard indexes on `StaffNo` cannot be used efficiently because the join predicate involves function calls (`CONCAT`) and an `OR` logic on the join side.

### 1.2. Deeply Nested Subqueries
The query uses multiple layers of nested `FROM (SELECT ... FROM (SELECT ...))` subqueries.
- **Issue**: While SQL Server *can* optimize nested views/subqueries, deep nesting makes it harder for the optimizer to push predicates (like the date filter) down to the base tables effectively. It also makes the query extremely difficult to read and maintain.

### 1.3. Repeated Complex Logic
Calculations like `DerivedOwner`, `Derived_Branch_Flag`, and `Date_key` are repeated or calculated late in the query execution pipeline, potentially processing more rows than necessary.

## 2. Proposed Optimizations

### 2.1. Refactor Join Logic (Remove `OR`)
Instead of a single join with `OR`, we will use two separate `LEFT JOIN`s (one for 'NB' prefix, one for 'CC' prefix) and combine the results using `COALESCE`.

**New Logic:**
```sql
LEFT JOIN [NCC_WFO_Telephony].[dbo].[SAP_StaffData_General] Sp_NB
    ON Activity.BranchCallerEmployeeNumber = 'NB' + CAST(Sp_NB.StaffNo AS VARCHAR)
LEFT JOIN [NCC_WFO_Telephony].[dbo].[SAP_StaffData_General] Sp_CC
    ON Activity.BranchCallerEmployeeNumber = 'CC' + CAST(Sp_CC.StaffNo AS VARCHAR)

-- Select:
COALESCE(Sp_NB.Area, Sp_CC.Area) AS Sp_Area, ...
```
*Note: Assuming `StaffNo` is numeric or string, casting ensures compatibility.*

### 2.2. Use Common Table Expressions (CTEs)
We will restructure the query using CTEs (`WITH ... AS ...`) to break down the logic into logical steps:
1.  `CTE_Activity`: Base selection from `Activities_History_Tbl` with the date filter applied immediately.
2.  `CTE_Lead`: Base selection from `Leads_History_Tbl`.
3.  `CTE_Case`: Base selection from `Cases_History_Tbl`.
4.  `CTE_JoinedData`: Perform the joins between Activity, Lead, Case, and Staff Data.
5.  `CTE_FinalProjection`: Apply the complex `CASE` statements (`DerivedOwner`, etc.) on the result of the join.

This improves readability and allows the optimizer to better understand the data flow.

### 2.3. Materialize Intermediate Logic (Optional but Good)
If specific calculations (like `Date_key`) are used in joins or grouping later (not the case here, but good practice), calculating them early in the CTE helps.

## 3. Expected Outcome
- **Faster Execution**: By removing the `OR` join, we enable the use of indexes on `StaffNo` (if they exist) and avoid table scans.
- **Better Plan**: The optimizer can choose more efficient join algorithms (Hash Join or Merge Join) instead of forced Nested Loops.
- **Maintainability**: The CTE structure will be much easier to read and modify in the future.
