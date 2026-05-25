
library(duckdb)
library(dplyr)
library(dbplyr)
library(DBI)

# setwd("D:/STUDY/Projects/Insurance_Sector_Analysis")

aum <- read.csv("data/aum.csv")
claims <- read.csv("data/claims.csv")
premium <- read.csv("data/premium.csv")
solvency <- read.csv("data/solvency.csv")

# CONNECTING WITH OUR DUCKDB DATABASE
con <- DBI::dbConnect(duckdb::duckdb(), dbdir = "duckdb")

DBI::dbWriteTable(con, "aum", aum)
DBI::dbWriteTable(con, "claims", claims)
DBI::dbWriteTable(con, "premium", premium)
DBI::dbWriteTable(con, "solvency", solvency)

dbListTables(con)

claims$sector <- ifelse(claims$insurer == "LIC ",
                        "Public Sector", "Private Sector")

glimpse(aum)
glimpse(claims)
glimpse(premium)
glimpse(solvency)

unique(aum$insurer)
unique(claims$insurer)
unique(premium$insurer)
unique(solvency$insurer)

# THERE ARE 22 UNIQUE INSURERS CONTAINED IN ALL TABLES, 
# SO WE'LL ONLY BE TAKING THOSE

# ASSIGNING A CODE FOR EACH INSURER SO IT HELPS IN SQL QUERIES
insurer_dim <- tibble(
  insurer_code = 101:122,
  insurer_name = c(
    "LIC",
    "Aditya Birla Sun Life",
    "Ageas Federal",
    "Aviva",
    "Axis Max Life",
    "Bajaj Allianz",
    "Bandhan",
    "Bharti AXA",
    "Canara HSBC",
    "Edelweiss Tokio",
    "Future Generali",
    "HDFC Life",
    "ICICI Prudential",
    "India First",
    "Kotak Mahindra",
    "PNB MetLife",
    "Pramerica Life",
    "Sahara",
    "SBI Life",
    "Shriram",
    "Star Union Dai-ichi",
    "Tata AIA"
    )
  )


# Named vectors for name replacement
#
# Format:  c("raw name in file" = "canonical name")
# trimws() handles the trailing-space problem before matching.
# Any name not in the vector → NA → filtered out (the 4 extras).

map_claims <- c(
  "LIC"                  = "LIC",
  "Aditya Birla Sun Life"= "Aditya Birla Sun Life",
  "Ageas Federal"        = "Ageas Federal",
  "Aviva"                = "Aviva",
  "Axis Max Life"        = "Axis Max Life",
  "Bajaj Allianz"        = "Bajaj Allianz",
  "Bandhan"              = "Bandhan",
  "Bharti Axa"           = "Bharti AXA",
  "Canara HSBC"          = "Canara HSBC",
  "Edelweiss Life"       = "Edelweiss Tokio",
  "Future Generali"      = "Future Generali",
  "HDFC Life"            = "HDFC Life",
  "ICICI Prudential"     = "ICICI Prudential",
  "India First"          = "India First",
  "Kotak Mahindra"       = "Kotak Mahindra",
  "PNB Met Life"         = "PNB MetLife",
  "Pramerica Life"       = "Pramerica Life",
  "Sahara"               = "Sahara",
  "SBI Life"             = "SBI Life",
  "Shriram"              = "Shriram",
  "Star Union"           = "Star Union Dai-ichi",
  "Tata AIA"             = "Tata AIA"
)

map_aum <- c(
  "LIC"                    = "LIC",
  "Aditya Birla Sun Life"  = "Aditya Birla Sun Life",
  "Ageas Federal Life"     = "Ageas Federal",
  "Aviva Life"             = "Aviva",
  "Max Life"               = "Axis Max Life",
  "Bajaj Allianz Life"     = "Bajaj Allianz",
  "Bandhan Life"           = "Bandhan",
  "Bharti AXA Life"        = "Bharti AXA",
  "Canara HSBC OBC Life"   = "Canara HSBC",
  "Edelweiss Tokio Life"   = "Edelweiss Tokio",
  "Future Generali Life"   = "Future Generali",
  "HDFC Life"              = "HDFC Life",
  "ICICI Prudential Life"  = "ICICI Prudential",
  "IndiaFirst Life"        = "India First",
  "Kotak Mahindra Life"    = "Kotak Mahindra",
  "PNB Metlife"            = "PNB MetLife",
  "Pramerica Life"         = "Pramerica Life",
  "Sahara India Life"      = "Sahara",
  "SBI Life"               = "SBI Life",
  "Shriram Life"           = "Shriram",
  "Star Union Dai-ichi Life" = "Star Union Dai-ichi",
  "Tata AIA Life"          = "Tata AIA"
  # Acko Life, Credit Access Life, Exide Life, Go Digit Life → dropped
)

map_premium <- c(
  "Life Insurance Corporation of India"              = "LIC",
  "Aditya Birla Sunlife Insurance Company Ltd."      = "Aditya Birla Sun Life",
  "Ageas Federal Life Insurance Company Ltd."        = "Ageas Federal",
  "Aviva Life Insurance Company India Ltd."          = "Aviva",
  "Axis MaxLife  Insurance Company Ltd."             = "Axis Max Life",
  "Bajaj Allianz Life Insurance Company Ltd."        = "Bajaj Allianz",
  "Bandhan Life Insurance Company Ltd."              = "Bandhan",
  "Bharti AXA Life Insurance Company Ltd."           = "Bharti AXA",
  "Canara HSBC Life Insurance Company Ltd."          = "Canara HSBC",
  "Edelweiss Tokio Life Insurance Company Ltd."      = "Edelweiss Tokio",
  "Future Generali India Life Insurance Company Ltd."= "Future Generali",
  "HDFC Life Insurance Company Ltd."                 = "HDFC Life",
  "ICICI Prudential Life Insurance Company Ltd."     = "ICICI Prudential",
  "IndiaFirst Life Insurance Company Ltd."           = "India First",
  "Kotak Mahindra Life Insurance Ltd."               = "Kotak Mahindra",
  "PNB Metlife India Insurance Company Ltd."         = "PNB MetLife",
  "Pramerica Life Insurance Company Ltd."            = "Pramerica Life",
  "Sahara  India Life Insurance Company Ltd."        = "Sahara",
  "SBI Life Insurance Company Ltd."                  = "SBI Life",
  "Shriram Life Insurance Company Ltd."              = "Shriram",
  "Star Union Dai-ichi Life Insurance Company Ltd."  = "Star Union Dai-ichi",
  "TATA AIA Life Insurance Company Ltd."             = "Tata AIA"
  # Acko, CreditAccess, Exide, Go Digit → not mapped → dropped
)

map_solvency <- c(
  "LIC of India"                                       = "LIC",
  "Aditya Birla Sun Life Insurance Company Ltd."       = "Aditya Birla Sun Life",
  "Aegas Federal Life Insurance Company Limited"       = "Ageas Federal",  # note: typo in IRDAI source
  "Aviva Life Insurance Company India Ltd."            = "Aviva",
  "Axis Max Life Insurance Company Ltd"                = "Axis Max Life",
  "Bajaj Allianz Life Insurance Co Ltd"                = "Bajaj Allianz",
  "Bandhan Life Insurance Company Limited"             = "Bandhan",
  "Bharti-AXA Life Insurance Co Ltd"                  = "Bharti AXA",
  "Canara HSBC Life Insurance Company Ltd."            = "Canara HSBC",
  "Edelweiss Tokio Life Insurance Co. Ltd."            = "Edelweiss Tokio",
  "Future Generali India Life Insurance Company Limited"= "Future Generali",
  "HDFC Life Insurance Company Ltd."                  = "HDFC Life",
  "ICICI Prudential Life Insurance Company Ltd."      = "ICICI Prudential",
  "IndiaFirst Life Insurance Company Limited"         = "India First",
  "Kotak Mahindra OM Life Insurance Co. Ltd."         = "Kotak Mahindra",
  "PNB MetLife India Insurance Co. Ltd."              = "PNB MetLife",
  "Pramerica Life Insurance Company Limited"          = "Pramerica Life",
  "Sahara  India Life Insurance Company Ltd."         = "Sahara",
  "SBI Life Insurance Company Limited"                = "SBI Life",
  "Shriram Life Insurance Co. Ltd."                   = "Shriram",
  "Star Union Dai-ichi Life Insurance Company"        = "Star Union Dai-ichi",
  "TATA AIA LIFE INSURANCE CO. LTD"                   = "Tata AIA"
  # Acko, Credit Access, Exide, Go Digit → not mapped → dropped
  )

#  Applying the map
#
#  Helper: trims whitespace, looks up canonical name, joins code from dim table,
#          and drops any row whose name wasn't in the map (the 4 extras).

standardise <- function(df, map) {
  df |>
    mutate(
      insurer = trimws(insurer),
      insurer = map[insurer]        # named-vector lookup; unmatched → NA
    ) |>
    filter(!is.na(insurer)) |>     # drop the 4 excluded insurers
    left_join(insurer_dim, by = c("insurer" = "insurer_name")) |>
    relocate(insurer_code, .before = insurer)
  }

claims_clean   <- standardise(claims,   map_claims)
aum_clean      <- standardise(aum,      map_aum)
premium_clean  <- standardise(premium,  map_premium)
solvency_clean <- standardise(solvency, map_solvency)


# Quick sanity check

check_count <- function(df, label) {
  n <- n_distinct(df$insurer_code)
  message(label, ": ", n, " insurers — ", if (n == 22) "OK" else "PROBLEM")
}

check_count(claims_clean,  "claims")
check_count(aum_clean,     "aum")
check_count(premium_clean, "premium")
check_count(solvency_clean,"solvency")


#  Load into DuckDB 
#
#  dbWriteTable() creates persistent tables inside DuckDB.

dbWriteTable(con, "insurer_dim",    insurer_dim,    overwrite = TRUE)
dbWriteTable(con, "claims",         claims_clean,   overwrite = TRUE)
dbWriteTable(con, "aum",            aum_clean,      overwrite = TRUE)
dbWriteTable(con, "premium",        premium_clean,  overwrite = TRUE)
dbWriteTable(con, "solvency",       solvency_clean, overwrite = TRUE)

# Verify what's in DuckDB
dbGetQuery(con, "SHOW TABLES")

# DISCONNECTING WITH DUCKDB
dbDisconnect(con)


