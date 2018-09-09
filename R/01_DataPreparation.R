
# 00 Requirement: -----------------------------------------------------------------------------

rm(list = ls())

library(package = dplyr,
        warn.conflicts = FALSE)

# 01 Main Code: -------------------------------------------------------------------------------

# Create Base Date
start_date  <- "01/01/2013 00:59"
end_date    <- "31/12/2017 23:59"
format_date <- "%d/%m/%Y %H:%M"
period_date <- 1 * 3600

base_date <- seq.POSIXt(from = as.POSIXct(x = start_date, tz = "GMT", format = format_date),
                        to   = as.POSIXct(x = end_date,   tz = "GMT", format = format_date),
                        by   = period_date) %>%
    as.data.frame.POSIXct()

names(base_date) <- "date"

# Read Location of *.csv Files
name_file <- c("Air Temperature"           = "TEMP",
               "Carbon Monoxide - CO"      = "CO",
               "Global Solar Radiation"    = "SOLAR",
               "Nitric Oxide - NO"         = "NO",
               "Nitrogen Dioxide - NO2"    = "NO2",
               "Ozone - O3"                = "OZONE",
               "Particles - PM2.5"         = "PM2.5",
               "Particles - PM10"          = "PM10",
               "Rainfall"                  = "RAIN",
               "Relative Humidity"         = "HUMID",
               "Sulfur Dioxide - SO2"      = "SO2",
               "Visibility - Nepholemeter" = "NEPH",
               "Wind Direction"            = "WDR",
               "Wind Speed"                = "WSP")

csv_raw_data_location <- "./data/RawDataCSV/"
rds_raw_data_location <- "./data/RawDataRDS/"

list_folder <- list.dirs(path = csv_raw_data_location,
                         full.names = TRUE)[-1]

name_folder <- sub(pattern = paste(csv_raw_data_location, "/", sep = ""),
                   replacement = "",
                   x = list_folder)

# Extract Data from *.csv Files and Save in *.RDS Files
for (nf in name_folder)
{
    list_files <- list.files(path = paste(csv_raw_data_location, "/", nf, sep = ""), pattern = ".csv")

    result <- base_date

    for (lf in list_files)
    {
        data <- read.csv(file = paste(csv_raw_data_location, "/", nf, "/", lf, sep = ""),
                         header = TRUE,
                         skip = 2,
                         fileEncoding="latin1")

        data <- data %>% select(-c(1:2))

        data$date <- base_date$date

        result <- left_join(x  = result,
                            y  = data,
                            by = "date")
    }

    colnames(result)[-1] <- substr(x = colnames(result)[-1],
                                   start = 1,
                                   stop = regexpr(name_file[nf], colnames(result)[-1]) - 2)

    saveRDS(object = result,
            file = paste(rds_raw_data_location, "/", nf, ".RDS", sep = ""))
}

# Read List of *.RDS Files
rds_files <- list.files(path = rds_raw_data_location,
                        pattern = ".RDS",
                        full.names = TRUE)

# Create List of *.RDS Files
rds_list <- list()

for (rds in rds_files)
{
    rds_list[[substr(x = rds, start = nchar(rds_raw_data_location) + 2, stop = nchar(rds) - 4)]] <- readRDS(file = rds)
}

# Create Dataframe From List of *.RDS Files
stations_name <- colnames(rds_list[["Air Temperature"]])[-1]

data <- list()

for (st in stations_name)
{
    data[[st]] <- lapply(X = rds_list, `[[`, st)

    data[[st]]$site <- rep(x = st, length(rds_list[["Air Temperature"]]$date))

    data[[st]]$date <- rds_list[["Air Temperature"]]$date

    for (para in names(data[[st]]))
    {
        if (is.null(data[[st]][[para]]))
        {
            data[[st]][[para]] <- rep(x = NA, length(rds_list[["Air Temperature"]]$date))
        }
    }

    data[[st]] <- as.data.frame(data[[st]])
}

data_df <- do.call(what = rbind,
                   args = data)

rownames(data_df) <- NULL

data_df <- data_df %>% select(site   = site,
                              date   = date,
                              pm10   = Particles...PM10,
                              pm2.5  = Particles...PM2.5,
                              no     = Nitric.Oxide...NO,
                              no2    = Nitrogen.Dioxide...NO2,
                              so2    = Sulfur.Dioxide...SO2,
                              co     = Carbon.Monoxide...CO,
                              o3     = Ozone...O3,
                              neph   = Visibility...Nepholemeter,
                              ws     = Wind.Speed,
                              wd     = Wind.Direction,
                              tmean  = Air.Temperature,
                              rh     = Relative.Humidity,
                              solrad = Global.Solar.Radiation,
                              prec   = Rainfall)

saveRDS(object = data_df,
        file = "./data/RawDataDF.RDS")
