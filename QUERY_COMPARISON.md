# Query Comparison: NCC Models vs. D365 Cases

This document outlines the differences between the "NCC Models" query and the "D365 Cases" query, identifying missing columns and logic that need to be incorporated into the NCC Models query.

## 1. Goal
Update the **NCC Models** query to include columns and logic found in the **D365 Cases** query, while preserving the original NCC Models date logic (`YEAR(GETDATE())-1`) and existing columns.

## 2. Column Comparison

| Column Name | Status in NCC Models | Source in D365 Cases | Action |
| :--- | :--- | :--- | :--- |
| `CaseNumber` | Present | `C.CaseNumber` | Keep |
| `CaseType` | Present | `C.CaseType` | Keep |
| `CaseOrigin` | Present | `C.CaseOrigin` | Keep |
| `CaseCreatedOn` | Present | `C.CaseCreatedOn` | Keep |
| `Date_key` | Present (Derived) | - | Keep |
| `CaseCreatedBy` | Present | `C.CaseCreatedBy + ...` (Concatenated) | Keep Original |
| `CaseModifiedOn` | Present | `C.CaseModifiedOn` | Keep |
| `CaseModifiedBy` | Present | `C.CaseModifiedBy + ...` (Concatenated) | Keep Original |
| `CaseCreatedByBusinessUnit` | Present | `C.CaseCreatedByBusinessUnit` | Keep |
| `CaseStateCode` | Present | `C.CaseStateCode` | Keep |
| `CaseCurrentQueue` | Present | `C.CaseCurrentQueue` | Keep |
| `CaseSLA` | Present | - | Keep |
| `Lookup` | Present (Derived) | - | Keep |
| `CaseResolvedOn` | Present | `C.CaseResolvedOn` | Keep |
| `CaseResolvedBy` | Present | `C.CaseResolvedBy + ...` (Concatenated) | Keep Original |
| `CaseDecisionPortfolioName` | Present | `C.CaseDecisionPortfolioName` | Keep |
| `CaseDecisionProductName` | Present | `C.CaseDecisionProductName` | Keep |
| `CaseDecisionCategoryName` | Present | `C.CaseDecisionCategoryName` | Keep |
| `CaseDecisionSubCategoryName`| Present | - | Keep |
| `CaseDecisionSummaryName` | Present | `C.CaseDecisionSummaryName` | Keep |
| `CaseDecisionSolutionName` | Present | - | Keep |
| `CaseDecisionSolutionResolutionType` | Present | `C.CaseDecisionSolutionResolutionType` | Keep |
| `CaseCreatedByEmployeeNumber`| Present | - | Keep |
| `CaseModifiedByEmployeeNumber`| Present | - | Keep |
| `BranchCallerEmployeeName` | Present | `C.BranchCallerEmployeeName + ...` | Keep Original |
| `BranchCallerEmployeeNumber` | Present | `C.BranchCallerEmployeeNumber` | Keep |
| `BranchCallerEmployeeBranchCode`| Present | `C.BranchCallerEmployeeBranchCode` | Keep |
| `CaseStatusCode` | Present | - | Keep |
| `Platform` | Present | - | Keep |
| `CaseSlaBreached` | Present | - | Keep |
| `Created_Year` | **Missing** | `YEAR(C.CaseCreatedOn)` | **Add** |
| `Created_Month` | **Missing** | `MONTH(C.CaseCreatedOn)` | **Add** |
| `Created_Day` | **Missing** | `DAY(C.CaseCreatedOn)` | **Add** |
| `CustomerCisNumber` | **Missing** | `C.CustomerCisNumber` | **Add** |
| `Client_ID_Type` | **Missing** | `C.CustomerType` | **Add** |
| `BranchCallerName` | **Missing** | `C.BranchCallerEmployeeName + '_' + ...` | **Add** |
| `Calling Party` | **Missing** | `CASE WHEN ...` | **Add** |
| `TL_CreatedBy` | **Missing** | `H.[Team Leader Name]` | **Add** (Requires Join `H`) |
| `CCM_Createdby` | **Missing** | `H.[Manager Name]` | **Add** (Requires Join `H`) |
| `Function Area` | **Missing** | `H.[Function Area]` | **Add** (Requires Join `H`) |
| `Area` | **Missing** | `Sp.Area` | **Add** (Requires Join `Sp`) |
| `Region` | **Missing** | `Sp.Region` | **Add** (Requires Join `Sp`) |
| `Title` | **Missing** | `Sp.Title` | **Add** (Requires Join `Sp`) |
| `Position` | **Missing** | `Sp.Position` | **Add** (Requires Join `Sp`) |
| `Email` | **Missing** | `Sp.Email` | **Add** (Requires Join `Sp`) |

## 3. Required Joins

### 3.1. `[NCC_WFO_Telephony].[dbo].[SAP_StaffData_General]` (Alias: `Sp`)
- **Join Condition:** `ON BranchCallerEmployeeNumber = concat('NB', Sp.StaffNo)`
- **Columns to Add:** `Area`, `Region`, `Title`, `Position`, `Email`.

### 3.2. `[NCC_WFO_HeadCount].[dbo].[tbl_Static_HeadCount]` (Alias: `H`)
- **Join Condition:**
    - `H.[Headcount for Year] = YEAR(CaseCreatedOn)`
    - `H.[Headcount for Month] = MONTH(CaseCreatedOn)`
    - `H.EmpNo = RIGHT(CaseCreatedByEmployeeNumber, 6)`
- **Logic Adjustment:** The original D365 query filters `H` by a specific month (`@YEAR + @Month`). The NCC Models query covers a full year (`YEAR(GETDATE())-1`). The join should match on Year/Month row-by-row.
- **Columns to Add:** `Team Leader Name`, `Manager Name`, `Function Area`.

## 4. Other Logic
- **Date Filter:** Keep NCC Models logic: `YEAR(CaseCreatedOn) = YEAR(GETDATE())-1`.
- **Case Statements:** Keep existing NCC Models logic.
- **D365 Specific Filters:** The D365 query filters by `CaseDecisionPortfolioName` at the end. The user instructed to "get the missing columns", implying we should NOT add this row filter to NCC Models unless specified. We will strictly add columns.
