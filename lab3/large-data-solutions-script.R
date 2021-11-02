

path <- "/course/ASADataExpo2009/Data"

library(profmem)

## Solution 1 ...
## Use a bigger machine
## ssh fosstatsprd02.its.auckland.ac.nz
runiflotsoftime <- function() {
    system(paste("ls -lh", file.path(path, "bigmemory/airline.csv")))
    p <- profmem({
        airline <- read.csv(file.path(path, "bigmemory/airline.csv"))
        object.size(airline)
        ## 14330060808 bytes
        mean(airline$DepDelay, na.rm=TRUE)
        ## [1] 8.170708
    })
    total(p)
}
system(paste("ls -lh", file.path(path, "2008.csv")))
## Slow
p <- profmem({
    f2008 <- read.csv(file.path(path, "2008.csv"))
    mean(f2008$DepDelay, na.rm=TRUE)
})
total(p)

## Solution 2 ...
## Store data in database and just extract the bits we want
system(paste("ls -lh", file.path(path, "sqlite/ontime.sqlite3")))
library(RSQLite)
con <- dbConnect(SQLite(), file.path(path, "sqlite/ontime.sqlite3"))
runiflotsoftime <- function() {
    delays <- dbGetQuery(con, "SELECT DepDelay FROM ontime")
    ## 494140616 bytes
    mean(delays$DepDelay)
    ## [1] 8.018443
}
p <- profmem({
    delays <- dbGetQuery(con, "SELECT DepDelay FROM ontime WHERE Year == 2008")
    mean(delays$DepDelay)
})
total(p)
dbDisconnect(con)
## Of course, the database system still uses memory to perform the query,
## but this should typically be less than R requires to work with the
## full data set
system(paste0('/usr/bin/time -f "%M" ',
              'sqlite3 /course/ASADataExpo2009/Data/sqlite/ontime.sqlite3 ',
              '"SELECT DepDelay FROM ontime WHERE Year == 2008" ',
              "> /dev/null"))

## Sample the data
fullMeans <- aggregate(DepDelay ~ Month, f2008, mean)
sampleMeans <- aggregate(DepDelay ~ Month,
                         f2008[sample(1:nrow(f2008), 700000), ],
                         mean)
merge(fullMeans, sampleMeans, by="Month")

## 'data.table'
library(data.table)
p <- profmem({
    f2008DT <- fread(file.path(path, "2008.csv"), sep=",")
    f2008DT[, monthDelay := mean(DepDelay, na.rm=TRUE), by=Month]
})
total(p)
head(f2008DT)

## Streaming data
## Naive reading in of data file
## NEW R SESSION
## Watch Vcells used AND Vcells max used
gc(reset=TRUE)
x <- scan("numbers.csv", sep=",")
object.size(x)
mean(as.matrix(x))
gc()
## Stream reading
## AND use a streaming algorithm to calculate the mean
gc(reset=TRUE)
con <- file("numbers.csv", "r")
sum <- 0
for (i in 1:10) {
    y <- scan(con, sep=",", nlines=1000)
    sum <- sum + sum(y)
    gc()
}
sum/1000000
close(con)
gc()
## 'biglm' package
## Linear regression
x <- read.table("numbers.csv", sep=",")
naiveFit <- lm(V1 ~ V2, x[,1:2])
coef(naiveFit)
library(biglm)
con <- file("numbers.csv", "r")
y <- read.table(con, sep=",", nrows=1000)
streamFit <- biglm(V1 ~ V2, y[,1:2])
for (i in 2:10) {
    y <- read.table(con, sep=",", nrows=1000)
    streamFit <- update(streamFit, y[,1:2])
}
close(con)
coef(streamFit)

## Solution 3 ...
## Do the analysis in the database
library(RSQLite)
con <- dbConnect(SQLite(), file.path(path, "sqlite/ontime.sqlite3"))
dbGetQuery(con, "SELECT AVG(DepDelay) FROM ontime WHERE Year = 2008")
dbDisconnect(con)
## Do the analysis in the shell
## Mean of the 16th column (DepDelay)
runinshell <- function() {
    /usr/bin/time -f "%M" \
    awk -F, -e 'BEGIN { sum = 0; n = 0 }; NR > 1 { if ($16 != "NA") { sum += $16; n += 1 } }; END { print(sum/n) }' /course/ASADataExpo2009/Data/2008.csv
}
