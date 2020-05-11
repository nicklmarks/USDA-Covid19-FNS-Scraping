# USDA COVID-19 SNAP Scraping Tool
# Cite as: Tettamanti, N. (2020). USDA COVID-19 FNS Scraping Tool. www.covidsnap.org. 

# This script will scrape tables from the Food and Nutrition COVID-19 response website, and 
# output an excel file with the columns: date, request name, status, and jurisdiction .
# The script is set to scrape the SNAP datatable. It can be easily modified
# to scrape data from the WIC, USDA Food Programs, and Child Nutrition programs by
# changing one number on line 29.

#Install packages, and then load them 
packages <- c("rvest","dplyr","xml2","xlsx")
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}

library(rvest)
library(dplyr)
library(xml2)
library(xlsx)

# Scraping function for each state
scrapeFNS <- function(state_num) {

  # Go to the state's webpage
  webpage_url <- paste("https://www.fns.usda.gov/disaster/pandemic/covid-19/", state.name[state_num], sep="")
  webpage <- xml2::read_html(webpage_url)
  
  # Save the SNAP table. Change [1] to: [2] for Child Nutrition, [3] for USDA Food Programs, and [4] for WIC. 
  snapTable <- rvest::html_table(webpage, header=TRUE)[[1]]
  rows <- nrow(snapTable)
  snapTable$Jurisdiction = rep(state.name[state_num],rows)
  
  return(snapTable)
}

# Create empty dataframe for full dataset
full_data <- data.frame(
  DateApproved=character(), 
  Request=character(),
  Status=character(),
  Jurisdiction=character()
)

# Loop through each state
for(i in 1:51){
  
  if(!(state.name[i] %in% full_data$Jurisdiction)){
  # Output state to console 
  cat(paste("\nScraping:", state.name[i], "\n"))
  
  # Setup timer to not block the tracker
  ok <- FALSE 
  counter <- 0
  
  while (ok == FALSE & counter <= 5) {
    counter <- counter + 1 
    out <- tryCatch({
          # Scrape the state
          new_state <- scrapeFNS(i)
        }, 
       error = function(e) {
          Sys.sleep(2)
         e
       }
     )
    
    if("error" %in% class(out)) {
      cat(".")
    } else { 
      ok <- TRUE
      cat(state.name[i], "Done.\n")}
  }
  
    # add results to main table 
    full_data <- rbind(full_data, new_state)
  } 
}

# Outputs excel file. 
write.xlsx(full_data, file="FNS_Web_Scrape.xlsx")
