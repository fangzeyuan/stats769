
august <- read.csv('AugustTraffic-OLD.csv')
head(august)
dim(august)

#Tidy
sum(substr(august$startDatetime,1,2) <"08")
head(august[substr(august$startDatetime,1,2) <"08",],1)
august8 <- august[substr(august$startDatetime,1,2) =="08",]

# Explore
count <- density(august8$count)
plot(count,main="")

count.small <- density(august8$count[august8$count<=10])
plot(count.small,main="")
boxplot(count ~ start$hour, august8, xlab="Hour")


start <- strptime(august8$startDatetime,"%d-AUG-%Y %H:%M")
end <- strptime(august8$endDatetime,"%d-AUG-%Y %H:%M")

boxplot(count ~ start$hour, august8, xlab="Hour")


## Transform
august8day  <- start$hour < 8 | start$hour >18
start.ct=as.POSIXct(start)
august8day <-data.frame(august8,start=start.ct)[!august8day,]
august8day <- data.frame(august8day,scount=sqrt(august8day$count))
dim(august8day)
head(august8day)

sessionInfo()
