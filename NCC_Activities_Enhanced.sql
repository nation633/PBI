declare @Startdate as datetime
declare @EndDate as datetime

Set @Startdate = CONVERT(DATETIME, '2025-01-01 00:00:00', 102)
set @EndDate =CONVERT(DATETIME, '2026-12-31 23:59:59', 102)


SELECT        HC.StaffNoText, HC.[Team Leader Name], HC.[Manager Name], ActivityCaseLead.DerivedOwner1 AS InvolvedStaffNo, ActivityCaseLead.ActivitySource, ActivityCaseLead.Direction,
                         ActivityCaseLead.CaseOrLead_Flag, ActivityCaseLead.CreatedByEmployeeNumber, ActivityCaseLead.ModifiedByEmployeeNumber, ActivityCaseLead.OwnerEmployeeNumber,
                         ActivityCaseLead.CaseModifiedByEmployeeNumber, ActivityCaseLead.LeadOwnerEmployeeNumber, ActivityCaseLead.Derived_Branch_Flag, ActivityCaseLead.BranchEmployeeName,
                         ActivityCaseLead.BranchEmployeeNumber, ActivityCaseLead.BranchEmployeeBranchCode, ActivityCaseLead.ActivityStatus, ActivityCaseLead.LeadId, ActivityCaseLead.IsBranchCaller,
                         ActivityCaseLead.ActivityId, ActivityCaseLead.RegardingObjectId, ActivityCaseLead.CreatedOn,cast(Convert(varchar,ActivityCaseLead.CreatedOn,112) as int) as Date_key,ActivityCaseLead.CaseNumber, ActivityCaseLead.Created_Year, ActivityCaseLead.Created_Month,
                         ActivityCaseLead.Created_Day, ActivityCaseLead.CaseType, ActivityCaseLead.CaseOrigin, ActivityCaseLead.CustomerCisNumber, ActivityCaseLead.CaseCreatedOn, ActivityCaseLead.CaseModifiedOn,
                         ActivityCaseLead.CaseModifiedBy, ActivityCaseLead.CaseStateCode, ActivityCaseLead.CaseCurrentQueue, ActivityCaseLead.CaseResolvedOn, ActivityCaseLead.CaseResolvedBy,
                         ActivityCaseLead.CaseDecisionPortfolioName, ActivityCaseLead.CaseDecisionProductName, ActivityCaseLead.CaseDecisionCategoryName, ActivityCaseLead.CaseDecisionSummaryName,
                         ActivityCaseLead.CaseDecisionSolutionResolutionType, ActivityCaseLead.Client_ID_Type, ActivityCaseLead.Platform, ActivityCaseLead.CaseId, ActivityCaseLead.NccWrapUp, ActivityCaseLead.NccLeadsource, ActivityCaseLead.NccSubWrapUp,
                         ActivityCaseLead.LeadIdKey, HC.[Function Role], HC.[Function Area], HC.[Monoline / Brand], HC.[Desk Name], HC.[Role Within Division],

                         -- New Columns from D365 Activities
                         ActivityCaseLead.Sp_Area,
                         ActivityCaseLead.Sp_Region,
                         ActivityCaseLead.Sp_Title,
                         ActivityCaseLead.Sp_Position

FROM            (SELECT        CASE WHEN (CASE WHEN DerivedOwner IS NULL THEN substring(CaseModifiedByEmployeeNumber, 3, 6) ELSE DerivedOwner END) IS NULL THEN substring(LeadOwnerEmployeeNumber, 3, 6)
                                                    ELSE (CASE WHEN DerivedOwner IS NULL THEN substring(CaseModifiedByEmployeeNumber, 3, 6) ELSE DerivedOwner END) END AS DerivedOwner1, DerivedOwner, ActivitySource, Direction,
                                                    CaseOrLead_Flag, CreatedByEmployeeNumber, ModifiedByEmployeeNumber, OwnerEmployeeNumber, CaseModifiedByEmployeeNumber, LeadOwnerEmployeeNumber, Derived_Branch_Flag,
                                                    BranchEmployeeName, BranchEmployeeNumber, BranchEmployeeBranchCode, ActivityStatus, LeadId, IsBranchCaller, ActivityId, RegardingObjectId, CreatedOn, CaseNumber, Created_Year,
                                                    Created_Month, Created_Day, CaseType, CaseOrigin, CustomerCisNumber, CaseCreatedOn, CaseModifiedOn, CaseModifiedBy, CaseStateCode, CaseCurrentQueue, CaseResolvedOn,
                                                    CaseResolvedBy, CaseDecisionPortfolioName, CaseDecisionProductName, CaseDecisionCategoryName, CaseDecisionSummaryName, CaseDecisionSolutionResolutionType, Client_ID_Type,
                                                    Platform, CaseId, NccWrapUp, NccLeadsource, NccSubWrapUp, LeadIdKey, ModifiedByBusinessUnit,

                                                    -- Carry Sp columns up
                                                    derivedtbl_1.Sp_Area,
                                                    derivedtbl_1.Sp_Region,
                                                    derivedtbl_1.Sp_Title,
                                                    derivedtbl_1.Sp_Position

                          FROM            (SELECT        Lead_.LeadCreatedByEmployeeNumber, Lead_.LeadOwnerEmployeeNumber, Lead_.LeadStatusModifiedByEmployeeNumber, CASE WHEN Activitysource = 'Phone Call' AND
                                                                              Direction = 'Incoming' THEN substring(Activity.OwnerEmployeeNumber, 3, 6) ELSE CASE WHEN Activitysource = 'Phone Call' AND
                                                                              Direction = 'Outgoing' THEN substring(Activity.CreatedByEmployeeNumber, 3, 6) ELSE CASE WHEN Activitysource = 'Email' AND
                                                                              Direction = 'Incoming' THEN substring(Activity.ModifiedByEmployeeNumber, 3, 6) ELSE CASE WHEN Activitysource = 'Email' AND
                                                                              Direction = 'Outgoing' THEN substring(Activity.CreatedByEmployeeNumber, 3, 6) ELSE CASE WHEN Activitysource = 'WebChat' THEN substring(Activity.OwnerEmployeeNumber, 3, 6)
                                                                              END END END END END AS DerivedOwner, Case_.CaseModifiedByEmployeeNumber, Activity.ActivitySource, Activity.Direction, CASE WHEN Lead_.LeadId IS NOT NULL
                                                                              THEN 'Lead' ELSE CASE WHEN Case_.CaseId IS NOT NULL THEN 'Case' ELSE 'Activity Only' END END AS CaseOrLead_Flag, Activity.CreatedByEmployeeNumber,
                                                                              Activity.ModifiedByEmployeeNumber, Activity.OwnerEmployeeNumber, CASE WHEN CASE WHEN Activity.BranchCallerEmployeeName IS NULL
                                                                              THEN Case_.BranchCallerEmployeeName ELSE (CASE WHEN Case_.BranchCallerEmployeeName IS NULL THEN Activity.BranchCallerEmployeeName ELSE NULL END) END IS NOT NULL
                                                                               THEN 'Branch Employee Captured' ELSE 'Assumed Client' END AS Derived_Branch_Flag, CASE WHEN Activity.BranchCallerEmployeeName IS NULL
                                                                              THEN Case_.BranchCallerEmployeeName ELSE (CASE WHEN Case_.BranchCallerEmployeeName IS NULL THEN Activity.BranchCallerEmployeeName ELSE NULL END)
                                                                              END AS BranchEmployeeName, CASE WHEN Activity.BranchCallerEmployeeNumber IS NULL
                                                                              THEN Case_.BranchCallerEmployeeNumber ELSE (CASE WHEN Case_.BranchCallerEmployeeNumber IS NULL THEN Activity.BranchCallerEmployeeNumber ELSE NULL END)
                                                                              END AS BranchEmployeeNumber, CASE WHEN Activity.BranchCallerEmployeeBranchCode IS NULL
                                                                              THEN Case_.BranchCallerEmployeeBranchCode ELSE (CASE WHEN Case_.BranchCallerEmployeeBranchCode IS NULL THEN Activity.BranchCallerEmployeeBranchCode ELSE NULL
                                                                              END) END AS BranchEmployeeBranchCode, Activity.StatusCode AS ActivityStatus, CAST(Lead_.LeadId AS nvarchar(50)) AS LeadId, Activity.IsBranchCaller,
                                                                              CAST(Activity.ActivityId AS nvarchar(50)) AS ActivityId, CAST(Activity.RegardingObjectId AS nvarchar(50)) AS RegardingObjectId, Activity.CreatedOn, Case_.CaseNumber,
                                                                              Activity.Created_Year, Activity.Created_Month, Activity.Created_Day, Case_.CaseType, Case_.CaseOrigin, Case_.CustomerCisNumber, Case_.CaseCreatedOn, Case_.CaseModifiedOn,
                                                                              Case_.CaseModifiedBy, Case_.CaseStateCode, Case_.CaseCurrentQueue, Case_.CaseResolvedOn, Case_.CaseResolvedBy, Case_.CaseDecisionPortfolioName,
                                                                              Case_.CaseDecisionProductName, Case_.CaseDecisionCategoryName, Case_.CaseDecisionSummaryName, Case_.CaseDecisionSolutionResolutionType, Case_.Client_ID_Type,
                                                                              Activity.Platform, CAST(Case_.CaseId AS nvarchar(50)) AS CaseId, Lead_.NccWrapUp, Lead_.NccLeadsource, Lead_.NccSubWrapUp, Lead_.LeadIdKey, Activity.ModifiedByBusinessUnit,

                                                                              -- Sp Columns propagated
                                                                              Sp.Area       AS Sp_Area,
                                                                              Sp.Region     AS Sp_Region,
                                                                              Sp.Title      AS Sp_Title,
                                                                              Sp.Position   AS Sp_Position

                                                    FROM            (SELECT        ActivitySource, ActivityId, RegardingObjectId, CreatedOn, cast(Convert(varchar,CreatedOn,112) as int) as Date_key,DAY(CreatedOn) AS Created_Day, MONTH(CreatedOn) AS Created_Month, YEAR(CreatedOn) AS Created_Year,
                                                                                                        IsBranchCaller, ModifiedByEmployeeNumber, Platform, Direction, StatusCode, ModifiedByBusinessUnit, BranchCallerEmployeeBranchCode,
                                                                                                        BranchCallerEmployeeEmailAddress, BranchCallerEmployeeName, BranchCallerEmployeeNumber, CreatedBy, CreatedByEmployeeNumber, CreatedByBusinessUnit,
                                                                                                        ModifiedOn, ModifiedBy, ActivityOwner, OwnerEmployeeNumber
                                                                              FROM            Activities_History_Tbl
                                                                              WHERE        (CreatedOn BETWEEN @Startdate AND @EndDate)) AS Activity

                                                                              LEFT OUTER JOIN [NCC_WFO_Telephony].[dbo].[SAP_StaffData_General] Sp
                                                                                ON Activity.BranchCallerEmployeeNumber = CONCAT('NB',Sp.StaffNo)
                                                                                OR Activity.BranchCallerEmployeeNumber = CONCAT('CC',Sp.StaffNo)

                                                                              LEFT OUTER JOIN
                                                                                  (SELECT        CreatedByEmployeeNumber AS LeadCreatedByEmployeeNumber, OwnerEmployeeNumber AS LeadOwnerEmployeeNumber, LeadStatusModifiedByEmployeeNumber,
                                                                                                              CreatedOn, LeadId, LeadIdKey, NccLeadsource, NccWrapUp, NccSubWrapUp
                                                                                    FROM            Leads_History_Tbl) AS Lead_ ON Activity.RegardingObjectId = Lead_.LeadId LEFT OUTER JOIN
                                                                                  (SELECT        CaseNumber, CaseType, CaseOrigin, CustomerCisNumber, CaseCreatedOn, CaseCreatedBy + '_' + CaseCreatedByEmployeeNumber AS CaseCreatedBy, CaseModifiedOn,
                                                                                                              CaseModifiedBy + '_' + CaseModifiedByEmployeeNumber AS CaseModifiedBy, CaseModifiedByEmployeeNumber, CaseStateCode, CaseCurrentQueue, CaseResolvedOn,
                                                                                                              CaseResolvedBy + '_' + CaseResolvedByEmployeeNumber AS CaseResolvedBy, CaseDecisionPortfolioName, CaseDecisionProductName, CaseDecisionCategoryName,
                                                                                                              CaseDecisionSummaryName, CaseDecisionSolutionResolutionType, CustomerType AS Client_ID_Type, Platform, CaseId, ActivityId, BranchCallerEmployeeName,
                                                                                                              BranchCallerEmployeeNumber, BranchCallerEmployeeBranchCode
                                                                                    FROM            Cases_History_Tbl) AS Case_ ON Activity.RegardingObjectId = Case_.CaseId) AS derivedtbl_1) AS ActivityCaseLead LEFT OUTER JOIN
                             (SELECT        StaffNoText, [Nedbank Staff Number], [Team Leader Name], [Manager Name], [Function Role], [Function Area], [Monoline / Brand], [Desk Name], [Role Within Division]
                               FROM            NCC_WFO_HeadCount.dbo.tbl_EmTrack) AS HC ON ActivityCaseLead.DerivedOwner1 = HC.StaffNoText
ORDER BY ActivityCaseLead.ActivitySource, ActivityCaseLead.Direction, ActivityCaseLead.CaseOrLead_Flag
