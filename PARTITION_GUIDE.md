# SSAS Partition Guide for NCC Activities

This guide explains how to use the generated SQL partition files in SSAS or Tabular Editor.

## Partition Strategy
The queries are designed to split the data into 4 logical partitions covering the last 3 years:

1.  **Partition 1 (2 Years Ago)**: `Partition_2_Years_Back.sql`
    -   Covers the full calendar year of 2 years ago (e.g., if today is 2025, this covers 2023).
    -   Logic: `YEAR(GETDATE())-2`
2.  **Partition 2 (Last Year)**: `Partition_Last_Year.sql`
    -   Covers the full calendar year of last year (e.g., if today is 2025, this covers 2024).
    -   Logic: `YEAR(GETDATE())-1`
3.  **Partition 3 (Current Year H1)**: `Partition_Current_Year_H1.sql`
    -   Covers Jan 1st to June 30th of the current year.
    -   Logic: `YEAR(GETDATE())`
4.  **Partition 4 (Current Year H2)**: `Partition_Current_Year_H2.sql`
    -   Covers July 1st to Dec 31st of the current year.
    -   Logic: `YEAR(GETDATE())`

## How to Apply in Tabular Editor

1.  **Open your Model** in Tabular Editor.
2.  Navigate to the **NCC Activities** table.
3.  Right-click on **Partitions** and select **New Partition** (or duplicate an existing one).
4.  Create 4 partitions named:
    -   `Activities_2_Years_Ago`
    -   `Activities_Last_Year`
    -   `Activities_Current_Year_H1`
    -   `Activities_Current_Year_H2`
5.  For each partition:
    -   Select the partition.
    -   In the **Expression** (for M partitions) or **Query** (for Legacy/SQL partitions) window, paste the content of the corresponding `.sql` file.
    -   **Important**: If you are using Power Query (M), you will need to wrap the SQL in `Value.NativeQuery`.
        ```powerquery
        let
            Source = Sql.Database("YourServerName", "YourDatabaseName"),
            Query = Value.NativeQuery(Source, "PASTE_SQL_CONTENT_HERE")
        in
            Query
        ```
    -   If you are using Legacy SQL partitions, simply paste the SQL content directly.

## Dynamic Date Logic
The queries use `DATEFROMPARTS(YEAR(GETDATE())...)` to dynamically calculate the date ranges. This means you do **not** need to update the queries annually.
-   When the year rolls over (e.g., 2025 to 2026), the "Current Year" partition will automatically start looking at 2026 data, and the "Last Year" partition will shift to 2025 data.
-   **Note**: You will need to process the partitions to pick up the new data ranges.
