# Indian Life Insurance Sector Analysis

An end-to-end data project analysing the Indian life insurance industry using publicly available data from the **Insurance Regulatory and Development Authority of India (IRDAI)**.

## Project Overview

This project takes raw IRDAI data across four separate datasets, cleans and standardises it using R, analyses it using SQL queries in DuckDB, and presents the findings through an interactive PowerBI dashboard.

## Tools Used

- **R** — data cleaning, name standardisation, and loading data into DuckDB
- **SQL (DuckDB)** — analytical queries to calculate key insurance metrics
- **PowerBI** — interactive dashboard with insurer and year slicers

## Data Source

*Handbook on Indian Insurance Statistics 2024-25*, published by IRDAI.  
All four datasets were extracted directly from the official IRDAI publication.

| Dataset | Coverage |
|---------|----------|
| Claims | 2021-22 to 2024-25 |
| Premium | 2015-16 to 2024-25 |
| Solvency Ratio | 2015-16 to 2024-25 |
| AUM | 2021-22 to 2023-24 |

## The Data Problem

Each dataset used different naming conventions for the same 22 insurers — ranging from full legal names like *"ICICI Prudential Life Insurance Company Ltd."* to short forms like *"ICICI Prudential"*, with inconsistent spacing, capitalisation and spelling across files. Four insurers present in some datasets but absent from claims data were excluded to maintain consistency.

The cleaning process involved building named vector maps in R to standardise all insurer names to a single canonical form, assigning each insurer a numeric code (101–122) used as a foreign key to connect all tables.

## Metrics Calculated

| Metric | Description |
|--------|-------------|
| Settlement Ratio | Claims paid ÷ claims intimated × 100 |
| Market Share | Insurer premium ÷ total industry premium × 100 |
| LIC vs Private Sector | Year-wise split of industry premium between LIC and private insurers |
| Solvency Ratio Trend | Solvency ratio over time against the 1.5x IRDAI regulatory minimum |
| Loss Ratio Proxy | Claims paid amount ÷ premium earned × 100 |
| Premium Growth | Year-on-year premium growth per insurer |

## Repository Structure

```
irdai-insurance-analysis/
│
├── data/
│   └── raw/                  ← original CSVs from IRDAI handbook
│
├── R/
│   ├── irdai_clean.R         ← data cleaning and DuckDB setup
│   └── irdai_queries.R       ← SQL queries via dbGetQuery()
│
├── exports/                  ← cleaned CSVs exported for PowerBI
│
├── dashboard/
│   └── insurance_analysis.pbix
│
└── README.md
```

## Dashboard Features

- **Insurer slicer** — compare any combination of the 22 life insurers
- **Year slicer** — filter by financial year across all compatible visuals
- Settlement ratio and loss ratio respond to both slicers
- LIC vs Private Sector and Premium Growth show full historical trend regardless of year selection
