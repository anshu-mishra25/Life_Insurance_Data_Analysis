# Indian Life Insurance Sector Analysis

An end-to-end data project analysing the Indian life insurance industry using publicly available data **Handbook on Indian Insurance Statistics 2024-25** from the **Insurance Regulatory and Development Authority of India (IRDAI)**.

## Project Overview

This project takes raw IRDAI data across four separate datasets, cleans and standardises it using R, analyses it using SQL queries in DuckDB, and presents the findings through an interactive PowerBI dashboard.

## Tools Used

- **R** — data cleaning, name standardisation, and loading data into DuckDB
- **SQL (DuckDB)** — analytical queries to calculate key insurance metrics
- **PowerBI** — interactive dashboard with insurer and year slicers

## Data Source

*[Handbook on Indian Insurance Statistics 2024-25](https://irdai.gov.in/handbook-of-indian-insurance?p_p_id=com_irdai_document_media_IRDAIDocumentMediaPortlet&p_p_lifecycle=0&p_p_state=normal&p_p_mode=view&_com_irdai_document_media_IRDAIDocumentMediaPortlet_cur=2&_com_irdai_document_media_IRDAIDocumentMediaPortlet_delta=8&_com_irdai_document_media_IRDAIDocumentMediaPortlet_orderByCol=title&_com_irdai_document_media_IRDAIDocumentMediaPortlet_orderByType=asc)*, published by IRDAI.  
All four datasets were extracted directly from the official IRDAI publication.

| Dataset | Coverage |
|---------|----------|
| Claims | 2021-22 to 2024-25 |
| Premium | 2015-16 to 2024-25 |
| Solvency Ratio | 2015-16 to 2024-25 |
| AUM | 2021-22 to 2023-24 |

## The Data Problem
There were in total 27 Life Insurers but some some insurers like Reliance Nippon - which is fairly new; Max Life Insurance - which got merged with Axis, etc., I picked 22 fully defined with all avaiable data sets insureres, and only then I was able to make dashboard without any kind of hassle.

Each dataset used different naming conventions for the same 22 insurers — ranging from full legal names like *"ICICI Prudential Life Insurance Company Ltd."* to short forms like *"ICICI Prudential"*, with inconsistent spacing, capitalisation and spelling across files. 

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
Life_Insurance_Data_Analysis/
│
├── data/
│   └── raw/                  ← original CSVs from IRDAI handbook
│
├── insurance_data_analysis.R         ← data cleaning and DuckDB setup
├── SQL_Queries_for_Dashboard.R       ← SQL queries via dbGetQuery()
│
├── exports/                  ← cleaned CSVs exported for PowerBI
│
├── insurance_analysis.pbix
│
└── README.md
```

## Dashboard Features

- **Insurer slicer** — compare any combination of the 22 life insurers
- **Year slicer** — filter by financial year across all compatible visuals
- Settlement ratio and loss ratio respond to both slicers
- LIC vs Private Sector and Premium Growth show full historical trend regardless of year selection
