-- Partition: Current Year H1 (Jan-Jun)
-- Filter: DATEFROMPARTS(YEAR(GETDATE()), 1, 1) <= CreatedOn < DATEFROMPARTS(YEAR(GETDATE()), 7, 1)

WITH CTE_Activity AS (
    SELECT
        ActivitySource,
        ActivityId,
        RegardingObjectId,
        CreatedOn,
        CAST(CONVERT(VARCHAR(8), CreatedOn, 112) AS INT) AS Date_key,
        DAY(CreatedOn) AS Created_Day,
        MONTH(CreatedOn) AS Created_Month,
        YEAR(CreatedOn) AS Created_Year,
        IsBranchCaller,
        ModifiedByEmployeeNumber,
        Platform,
        Direction,
        StatusCode AS ActivityStatus,
        ModifiedByBusinessUnit,
        BranchCallerEmployeeBranchCode,
        BranchCallerEmployeeEmailAddress,
        BranchCallerEmployeeName,
        BranchCallerEmployeeNumber,
        CreatedBy,
        CreatedByEmployeeNumber,
        CreatedByBusinessUnit,
        ModifiedOn,
        ModifiedBy,
        ActivityOwner,
        OwnerEmployeeNumber
    FROM Activities_History_Tbl WITH (NOLOCK)
    -- Dynamic Partition Filter
    WHERE CreatedOn >= DATEFROMPARTS(YEAR(GETDATE()), 1, 1)
      AND CreatedOn < DATEFROMPARTS(YEAR(GETDATE()), 7, 1)
),
CTE_Lead AS (
    SELECT
        CreatedByEmployeeNumber AS LeadCreatedByEmployeeNumber,
        OwnerEmployeeNumber AS LeadOwnerEmployeeNumber,
        LeadStatusModifiedByEmployeeNumber,
        CreatedOn,
        LeadId,
        LeadIdKey,
        NccLeadsource,
        NccWrapUp,
        NccSubWrapUp
    FROM Leads_History_Tbl WITH (NOLOCK)
),
CTE_Case AS (
    SELECT
        CaseNumber,
        CaseType,
        CaseOrigin,
        CustomerCisNumber,
        CaseCreatedOn,
        CaseCreatedBy + '_' + CaseCreatedByEmployeeNumber AS CaseCreatedBy,
        CaseModifiedOn,
        CaseModifiedBy + '_' + CaseModifiedByEmployeeNumber AS CaseModifiedBy,
        CaseModifiedByEmployeeNumber,
        CaseStateCode,
        CaseCurrentQueue,
        CaseResolvedOn,
        CaseResolvedBy + '_' + CaseResolvedByEmployeeNumber AS CaseResolvedBy,
        CaseDecisionPortfolioName,
        CaseDecisionProductName,
        CaseDecisionCategoryName,
        CaseDecisionSummaryName,
        CaseDecisionSolutionResolutionType,
        CustomerType AS Client_ID_Type,
        Platform,
        CaseId,
        ActivityId,
        BranchCallerEmployeeName,
        BranchCallerEmployeeNumber,
        BranchCallerEmployeeBranchCode
    FROM Cases_History_Tbl WITH (NOLOCK)
),
CTE_JoinedData AS (
    SELECT
        Activity.*,

        -- Lead Data
        Lead_.LeadCreatedByEmployeeNumber,
        Lead_.LeadOwnerEmployeeNumber,
        Lead_.LeadStatusModifiedByEmployeeNumber,
        CAST(Lead_.LeadId AS NVARCHAR(50)) AS LeadIdStr,
        Lead_.LeadIdKey,
        Lead_.NccLeadsource,
        Lead_.NccWrapUp,
        Lead_.NccSubWrapUp,

        -- Case Data
        Case_.CaseNumber,
        Case_.CaseType,
        Case_.CaseOrigin,
        Case_.CustomerCisNumber,
        Case_.CaseCreatedOn,
        Case_.CaseCreatedBy,
        Case_.CaseModifiedOn,
        Case_.CaseModifiedBy AS CaseModifiedByFull,
        Case_.CaseModifiedByEmployeeNumber AS CaseModifiedByEmpNum,
        Case_.CaseStateCode,
        Case_.CaseCurrentQueue,
        Case_.CaseResolvedOn,
        Case_.CaseResolvedBy,
        Case_.CaseDecisionPortfolioName,
        Case_.CaseDecisionProductName,
        Case_.CaseDecisionCategoryName,
        Case_.CaseDecisionSummaryName,
        Case_.CaseDecisionSolutionResolutionType,
        Case_.Client_ID_Type,
        CAST(Case_.CaseId AS NVARCHAR(50)) AS CaseIdStr,

        -- Coalesced Logic for Branch Info
        COALESCE(Activity.BranchCallerEmployeeName, Case_.BranchCallerEmployeeName) AS FinalBranchName,
        COALESCE(Activity.BranchCallerEmployeeNumber, Case_.BranchCallerEmployeeNumber) AS FinalBranchNumber,
        COALESCE(Activity.BranchCallerEmployeeBranchCode, Case_.BranchCallerEmployeeBranchCode) AS FinalBranchCode,

        -- Optimization: Join to Staff Data (Using COALESCE instead of OR)
        COALESCE(Sp_NB.Area, Sp_CC.Area) AS Sp_Area,
        COALESCE(Sp_NB.Region, Sp_CC.Region) AS Sp_Region,
        COALESCE(Sp_NB.Title, Sp_CC.Title) AS Sp_Title,
        COALESCE(Sp_NB.Position, Sp_CC.Position) AS Sp_Position

    FROM CTE_Activity AS Activity
    LEFT JOIN CTE_Lead AS Lead_
        ON Activity.RegardingObjectId = Lead_.LeadId
    LEFT JOIN CTE_Case AS Case_
        ON Activity.RegardingObjectId = Case_.CaseId

    -- Optimized Staff Join: Two separate joins for 'NB' and 'CC' prefixes
    LEFT JOIN [NCC_WFO_Telephony].[dbo].[SAP_StaffData_General] Sp_NB WITH (NOLOCK)
        ON Activity.BranchCallerEmployeeNumber = 'NB' + CAST(Sp_NB.StaffNo AS VARCHAR(20))
    LEFT JOIN [NCC_WFO_Telephony].[dbo].[SAP_StaffData_General] Sp_CC WITH (NOLOCK)
        ON Activity.BranchCallerEmployeeNumber = 'CC' + CAST(Sp_CC.StaffNo AS VARCHAR(20))
),
CTE_DerivedLogic AS (
    SELECT
        *,
        -- Derived Owner Logic
        CASE
            WHEN ActivitySource = 'Phone Call' AND Direction = 'Incoming' THEN SUBSTRING(OwnerEmployeeNumber, 3, 6)
            WHEN ActivitySource = 'Phone Call' AND Direction = 'Outgoing' THEN SUBSTRING(CreatedByEmployeeNumber, 3, 6)
            WHEN ActivitySource = 'Email' AND Direction = 'Incoming' THEN SUBSTRING(ModifiedByEmployeeNumber, 3, 6)
            WHEN ActivitySource = 'Email' AND Direction = 'Outgoing' THEN SUBSTRING(CreatedByEmployeeNumber, 3, 6)
            WHEN ActivitySource = 'WebChat' THEN SUBSTRING(OwnerEmployeeNumber, 3, 6)
        END AS InitialDerivedOwner,

        -- Case or Lead Flag
        CASE
            WHEN LeadIdStr IS NOT NULL THEN 'Lead'
            WHEN CaseIdStr IS NOT NULL THEN 'Case'
            ELSE 'Activity Only'
        END AS CaseOrLead_Flag,

        -- Derived Branch Flag Logic (using coalesced values from CTE_JoinedData)
        CASE
            WHEN COALESCE(BranchCallerEmployeeName, FinalBranchName) IS NOT NULL THEN 'Branch Employee Captured'
            ELSE 'Assumed Client'
        END AS Derived_Branch_Flag

    FROM CTE_JoinedData
),
CTE_FinalDerivedOwner AS (
    SELECT
        *,
        -- Second Layer of Derived Owner Logic
        CASE
            WHEN (CASE
                    WHEN InitialDerivedOwner IS NULL THEN SUBSTRING(CaseModifiedByEmpNum, 3, 6)
                    ELSE InitialDerivedOwner
                  END) IS NULL
            THEN SUBSTRING(LeadOwnerEmployeeNumber, 3, 6)
            ELSE (CASE
                    WHEN InitialDerivedOwner IS NULL THEN SUBSTRING(CaseModifiedByEmpNum, 3, 6)
                    ELSE InitialDerivedOwner
                  END)
        END AS DerivedOwner1
    FROM CTE_DerivedLogic
)
SELECT
    HC.StaffNoText,
    HC.[Team Leader Name],
    HC.[Manager Name],
    FinalData.DerivedOwner1 AS InvolvedStaffNo,
    FinalData.ActivitySource,
    FinalData.Direction,
    FinalData.CaseOrLead_Flag,
    FinalData.CreatedByEmployeeNumber,
    FinalData.ModifiedByEmployeeNumber,
    FinalData.OwnerEmployeeNumber,
    FinalData.CaseModifiedByEmpNum AS CaseModifiedByEmployeeNumber,
    FinalData.LeadOwnerEmployeeNumber,
    FinalData.Derived_Branch_Flag,
    FinalData.FinalBranchName AS BranchEmployeeName,
    FinalData.FinalBranchNumber AS BranchEmployeeNumber,
    FinalData.FinalBranchCode AS BranchEmployeeBranchCode,
    FinalData.ActivityStatus,
    FinalData.LeadIdStr AS LeadId,
    FinalData.IsBranchCaller,
    CAST(FinalData.ActivityId AS NVARCHAR(50)) AS ActivityId,
    CAST(FinalData.RegardingObjectId AS NVARCHAR(50)) AS RegardingObjectId,
    FinalData.CreatedOn,
    FinalData.Date_key,
    FinalData.CaseNumber,
    FinalData.Created_Year,
    FinalData.Created_Month,
    FinalData.Created_Day,
    FinalData.CaseType,
    FinalData.CaseOrigin,
    FinalData.CustomerCisNumber,
    FinalData.CaseCreatedOn,
    FinalData.CaseModifiedOn,
    FinalData.CaseModifiedByFull AS CaseModifiedBy,
    FinalData.CaseStateCode,
    FinalData.CaseCurrentQueue,
    FinalData.CaseResolvedOn,
    FinalData.CaseResolvedBy,
    FinalData.CaseDecisionPortfolioName,
    FinalData.CaseDecisionProductName,
    FinalData.CaseDecisionCategoryName,
    FinalData.CaseDecisionSummaryName,
    FinalData.CaseDecisionSolutionResolutionType,
    FinalData.Client_ID_Type,
    FinalData.Platform,
    FinalData.CaseIdStr AS CaseId,
    FinalData.NccWrapUp,
    FinalData.NccLeadsource,
    FinalData.NccSubWrapUp,
    FinalData.LeadIdKey,
    HC.[Function Role],
    HC.[Function Area],
    HC.[Monoline / Brand],
    HC.[Desk Name],
    HC.[Role Within Division],

    -- Staff Data Columns (Optimized)
    FinalData.Sp_Area,
    FinalData.Sp_Region,
    FinalData.Sp_Title,
    FinalData.Sp_Position

FROM CTE_FinalDerivedOwner AS FinalData
LEFT JOIN NCC_WFO_HeadCount.dbo.tbl_EmTrack AS HC WITH (NOLOCK)
    ON FinalData.DerivedOwner1 = HC.StaffNoText

ORDER BY FinalData.ActivitySource, FinalData.Direction, FinalData.CaseOrLead_Flag
