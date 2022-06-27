library(DBI)
library(odbc)
library(dplyr)
library(tidyverse)

# connect to database
con <- dbConnect(odbc(), 
                 Driver = "ODBC Driver 17 for SQL Server",
                 Server = "PNISQLBI2",
                 Database = "Tropicbird_DWH",
                 Trusted_Connection = "yes")

# formulate the SQL
query <- "select chv.chv_DWKey, years.yr, cty1.cty_Name as chartering_CCM, vsl.vsl_ID, vsl.vsl_Vessel_Name, cty2.cty_Name as flag_CCM, vty.vty_Generic_Type as vsl_type, chv_Charter_Start_Date as charter_start_date, chv_Charter_End_Date as charter_end_date, vsl.cty_Flag_DWKey
          from CHARTERED_VESSEL chv
          inner join VESSEL vsl on chv.vsl_DWKey=vsl.vsl_DWKey
          inner join VESSEL_TYPE vty on vsl.vty_DWKey = vty.vty_DWKey
          inner join COUNTRY cty1 on chv.cty_CharteringCCM_DWKey = cty1.cty_DWKey
          inner join COUNTRY cty2 on vsl.cty_SubmittedBy_DWKey = cty2.cty_DWKey
          inner join (SELECT v.yr FROM (VALUES (2011),(2012),(2013),(2014),(2015),(2016),(2017),(2018),(2019),(2020),(2021),(2022)) v(yr)) years
             on years.yr between year(chv_Charter_Start_Date) and year(chv_Charter_End_Date)
          where chv_Charter_Start_Date <= '31 Dec 2022'
          and chv_Charter_End_Date >= '1 Jan 2010'"

# fetch the data
charterers <- dplyr::tbl(con, dplyr::sql(query)) %>%
  dplyr::collect()

# the smart stuff producing crosstab on selected years :-)
out_tab<- charterers %>%
  group_by(chartering_CCM, flag_CCM, vsl_type, yr) %>%
  summarise(n=n()) %>%
  pivot_wider(names_from = 'yr', values_from =  "n" )%>%
  select(sort(colnames(.))) %>% select(chartering_CCM, flag_CCM, vsl_type,everything())

#output to CSV with NA as blanks
write.csv (out_tab, "charterTable.csv", na="")
