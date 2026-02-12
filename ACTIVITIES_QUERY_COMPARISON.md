# Activities Query Comparison: NCC Models vs. D365 Activities

This document outlines the changes made to the **NCC Models** query (Activities) to incorporate columns and logic from the **D365 Activities** query, ensuring unity between the two data models.

## 1. Goal
Update the **NCC Models** query (Activities version) to include the `Sp` (Staff Data) columns (`Area`, `Region`, `Title`, `Position`) by joining to `[NCC_WFO_Telephony].[dbo].[SAP_StaffData_General]`.

## 2. Changes Applied

### 2.1. New Columns Added
The following columns were identified in the D365 query and added to the NCC Models query:
- `Sp.Area`
- `Sp.Region`
- `Sp.Title`
- `Sp.Position`

These columns are propagated from the inner subquery `derivedtbl_1` up to the main `SELECT` statement.

### 2.2. New Join Logic
A `LEFT JOIN` was added to the inner query to bring in the staff data:

```sql
LEFT JOIN [NCC_WFO_Telephony].[dbo].[SAP_StaffData_General] Sp
    ON Activity.BranchCallerEmployeeNumber = CONCAT('NB', Sp.StaffNo)
    OR Activity.BranchCallerEmployeeNumber = CONCAT('CC', Sp.StaffNo)
```

This join logic matches the D365 query pattern.

### 2.3. Filtering Logic
The D365 query includes a `WHERE` clause filtering by `CaseDecisionPortfolioName`.
> **Note:** Consistent with the previous task, this filter was **NOT** applied to the main NCC Models query to avoid restricting the existing report's data scope. The focus was on adding missing columns and joins.

## 3. Structure Preservation
- The original date logic (`@Startdate` = '2025-01-01', `@EndDate` = '2026-12-31') was preserved.
- The complex nested subquery structure (`ActivityCaseLead` -> `derivedtbl_1`) was maintained.
- Existing `CASE` statements and derived columns in the NCC Models query were kept intact.
