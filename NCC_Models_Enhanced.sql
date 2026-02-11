DECLARE @YEAR INT;
SET @YEAR = YEAR(GETDATE())-1;

SELECT
    C.[CaseNumber],
    C.[CaseType],
    C.[CaseOrigin],
    C.[CaseCreatedOn],
    TRY_CAST(CONVERT(VARCHAR(8), C.CaseCreatedOn, 112) AS INT) AS Date_key,
    C.[CaseCreatedBy],
    C.[CaseModifiedOn],
    C.[CaseModifiedBy],
    C.[CaseCreatedByBusinessUnit],
    C.[CaseStateCode],
    C.[CaseCurrentQueue],
    C.[CaseSLA],
    CONCAT(YEAR(C.CaseCreatedOn),'_',MONTH(C.CaseCreatedOn),'_',RIGHT(C.[CaseCreatedByEmployeeNumber],LEN(C.[CaseCreatedByEmployeeNumber]) - 2)) AS [Lookup],
    C.[CaseResolvedOn],
    C.[CaseResolvedBy],
    C.[CaseDecisionPortfolioName],
    C.[CaseDecisionProductName],
    C.[CaseDecisionCategoryName],
    C.[CaseDecisionSubCategoryName],
    C.[CaseDecisionSummaryName],
    C.[CaseDecisionSolutionName],
    C.[CaseDecisionSolutionResolutionType],

    C.[CaseCreatedByEmployeeNumber],
    C.[CaseModifiedByEmployeeNumber],

    C.[BranchCallerEmployeeName],
    C.[BranchCallerEmployeeNumber],
    C.[BranchCallerEmployeeBranchCode],
    C.[CaseStatusCode],
    C.[Platform],
    C.[CaseSlaBreached],

    -- New Columns from D365 Cases Query
    YEAR(C.[CaseCreatedOn]) AS [Created_Year],
    MONTH(C.[CaseCreatedOn]) AS [Created_Month],
    DAY(C.[CaseCreatedOn]) AS [Created_Day],
    C.[CustomerCisNumber],
    C.[CustomerType] AS "Client_ID_Type",
    C.[BranchCallerEmployeeName] +'_'+ C.[BranchCallerEmployeeNumber] AS "BranchCallerName",
    CASE
        WHEN C.[BranchCallerEmployeeNumber] IS NULL THEN 'Client'
        ELSE 'Branch'
    END AS [Calling Party],

    H.[Team Leader Name] AS "TL_CreatedBy",
    H.[Manager Name] AS "CCM_Createdby",
    H.[Function Area],

    Sp.Area,
    Sp.Region,
    Sp.Title,
    Sp.Position,
    Sp.Email

FROM [CRM].[dbo].[Cases_History_Tbl] C WITH (NOLOCK)
LEFT JOIN [NCC_WFO_Telephony].[dbo].[SAP_StaffData_General] Sp
    ON C.BranchCallerEmployeeNumber = CONCAT('NB', Sp.StaffNo)
LEFT JOIN [NCC_WFO_HeadCount].[dbo].[tbl_Static_HeadCount] H
    ON H.[Headcount for Year] = YEAR(C.[CaseCreatedOn])
    AND H.[Headcount for Month] = MONTH(C.[CaseCreatedOn])
    AND RIGHT('000000' + CAST(H.[Nedbank Staff Number] AS NVARCHAR), 6) = RIGHT(C.[CaseCreatedByEmployeeNumber], 6)

WHERE YEAR(C.CaseCreatedOn) = @YEAR
