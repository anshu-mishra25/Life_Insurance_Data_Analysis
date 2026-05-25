

# SQL Queries -------------------------------------------------------------

# setwd("D:/STUDY/Projects/Insurance_Sector_Analysis")

library(DBI)
library(readr)
library(duckdb)

con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "duckdb")

# Verify what's in DuckDB
dbGetQuery(con, "SHOW TABLES")


# Function for exporting csv with SQL Queries

export <- function(query, filename) {
  df <- dbGetQuery(con, query)
  write_csv(df, filename)
  message("Saved: ", filename, "  (", nrow(df), " rows)")
  }



# 1. Settlement Ratio ----------------------------------------------------

#  settlement_ratio = claims paid (no.) / claims intimated * 100
#  Standard metric published by IRDAI; shows how many filed claims got paid.



dbGetQuery(con, "SELECT * FROM claims LIMIT 6") # Getting an idea of the table

SQL1 <- "
  SELECT
    c.insurer_code,
    c.insurer,
    c.year,
    c.claims_intimated,
    c.claims_paid_no,
    ROUND(
      c.claims_paid_no * 100.0 / NULLIF(c.claims_intimated, 0),
    2) AS settlement_ratio_pct
  FROM claims c
  ORDER BY c.insurer_code, c.year
  "

export(SQL1,  "export/settlement_ratio.csv")



# 2. Market Share ---------------------------------------------------------

#  Each insurer's share of total industry premium for that year.
#  SUM() OVER (PARTITION BY year) gives the industry total per year
#  without collapsing rows, so every insurer row keeps its own premium too.

dbGetQuery(con, "SELECT * FROM premium LIMIT 6") # Getting an idea of the table

SQL2 <- "
  SELECT
    p.insurer_code,
    p.insurer,
    p.year,
    p.premium_crore,
    ROUND(
      p.premium_crore * 100.0 / SUM(p.premium_crore) OVER (PARTITION BY p.year),
    2) AS market_share_pct
  FROM premium p
  ORDER BY p.year, market_share_pct DESC
  "
  
export(SQL2, "export/market_share.csv")



# 3. LIC vs Private Sector ------------------------------------------------

#  Industry-level view, not insurer-level, so no insurer_code here.
#  LIC is identified by insurer_code = 101.
#  Private share % shows the gradual shift away from LIC over the years.

dbGetQuery(con, "SELECT * FROM premium LIMIT 5")

SQL3 <- "
  SELECT
    year,
    ROUND(SUM(CASE WHEN insurer_code = 101 THEN premium_crore ELSE 0 END), 2)
      AS lic_premium_crore,
    ROUND(SUM(CASE WHEN insurer_code != 101 THEN premium_crore ELSE 0 END), 2)
      AS private_premium_crore,
    ROUND(SUM(premium_crore), 2)
      AS total_industry_premium_crore,
    ROUND(
      SUM(CASE WHEN insurer_code != 101 THEN premium_crore ELSE 0 END) * 100.0 /
      NULLIF(SUM(premium_crore), 0), 2
    ) AS private_share_pct
  FROM premium
  GROUP BY year
  ORDER BY year
  "

export(SQL3, "export/lic_vs_private.csv")



# 4. Solvency Trend -------------------------------------------------------

#  regulatory_minimum is hardcoded at 150 as per IRDAI guidelines.
#  below_minimum flags any insurer-year that breached the requirement —
#  useful for a conditional colour rule in PowerBI.

dbGetQuery(con, "SELECT * FROM solvency LIMIT 5")

SQL4 <- "
  SELECT 
    s.insurer_code,
    s.insurer,
    s.year,
    s.solvency_ratio,
    1.5 AS regulatory_minimum,
    CASE WHEN s.solvency_ratio < 1.5 THEN 'YES' ELSE 'NO' END
      AS below_minimum
  FROM solvency s
  ORDER BY s.insurer_code, s.year
  "

export(SQL4, "export/solvency_trend.csv")



# 5. AUM Growth (YoY) -----------------------------------------------------

#  LAG() looks back one row within each insurer's year sequence to get
#  the previous year's AUM, then growth % = (current - previous) / previous.
#  First year per insurer will have NULL growth, which is correct.

dbGetQuery(con, "SELECT * FROM aum LIMIT 5")

SQL5 <- "
  SELECT
    insurer_code,
    insurer,
    year,
    aum_crore,
    LAG(aum_crore) OVER (
      PARTITION BY insurer_code ORDER BY year
    ) AS prev_year_aum_crore,
    ROUND(
    (aum_crore - LAG(aum_crore) OVER (
      PARTITION BY insurer_code ORDER BY year
    )) * 100.0 / 
    NULLIF(LAG(aum_crore) OVER (
      PARTITION BY insurer_code ORDER BY year
    ), 0),
    2) AS yoy_growth_pct
  FROM aum
  ORDER BY insurer_code, year
  "

export(SQL5, "export/aum_growth.csv")



# 6. Loss Ratio Proxy -----------------------------------------------------

#  Claims paid amount / premium earned — a rough loss ratio.
#  Not actuarially precise (ignores reserves, expenses, etc.) but a valid
#  indicator of how much of premium income is going out as claims.
#  Only years where both tables have data will appear (inner join).

dbGetQuery(con, "SELECT * FROM claims LIMIT 5")
dbGetQuery(con, "SELECT * FROM premium LIMIT 5")

SQL6 <- "
  SELECT 
    c.insurer_code,
    c.insurer,
    c.year,
    c.claims_paid_amt_crore,
    p.premium_crore,
    ROUND(
      c.claims_paid_amt_crore * 100.0 / NULLIF(p.premium_crore, 0),
      2)  AS loss_ratio_proxy_pct
  FROM claims c
  INNER JOIN premium p
    ON c.insurer_code = p.insurer_code
    AND c.year = p.year
  ORDER BY c.insurer_code, c.year
  "

export(SQL6, "export/loss_ratio_proxy.csv")



# 7. AUM to Premium Ratio -------------------------------------------------

#  How much AUM has the insurer built relative to premium collected that year.
#  Higher ratio = better at retaining and compounding policyholder funds.
#  Only 3 overlapping years (2021-22 to 2023-24) since AUM stops at 2023-24.

dbGetQuery(con, "SELECT * FROM aum LIMIT 5")
dbGetQuery(con, "SELECT * FROM premium LIMIT 5")

SQL7 <- "
  SELECT
    a.insurer_code,
    a.insurer,
    a.year,
    a.aum_crore,
    p.premium_crore,
    ROUND(
     a.aum_crore / NULLIF(p.premium_crore, 0),
    2) AS aum_to_premium_ratio
  FROM aum a
  INNER JOIN premium p
    ON a.insurer_code = p.insurer_code
    AND a.year = p.year
  ORDER BY a.insurer_code, a.year
  "
export(SQL7, "export/aum_to_premium.csv")



# 8. Premium Growth (YoY) -------------------------------------------------

#  Same LAG() pattern as AUM growth but on the premium table,
#  which goes back to 2015-16 so you get a much longer trend line.

SQL8 <- "
  SELECT
   insurer_code,
   insurer,
   year,
   premium_crore,
   LAG(premium_crore) OVER (
     PARTITION BY insurer_code ORDER BY year
   ) AS prev_year_premium_crore,
   ROUND(
     (premium_crore - LAG(premium_crore) OVER (
       PARTITION BY insurer_code ORDER BY year
     )) * 100.0 /
     NULLIF(LAG(premium_crore) OVER (
       PARTITION BY insurer_code ORDER BY year
     ), 0),
   2) AS yoy_growth_pct
 FROM premium
 ORDER BY insurer_code, year"

export(SQL8, "export/premium_growth.csv")


# I ALSO NEED AN YEAR TABLE TO CONNECT WITH POWER BI

year <- c("2021-22",
          "2022-23",
          "2023-24",
          "2024-25"
          )

(year_dim <- tibble(S.No = 1:length(year), year))
write_csv(year_dim, "export/year_dim.csv")
