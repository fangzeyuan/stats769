## The working directory is the directory we started in
getwd()
airports <- read.csv("airports.csv")
head(airports)
unique(airports$country)
table(airports$country)
airportsUS <- airports[airports$country == "USA",]
table(airportsUS$state)
sort(table(airportsUS$state))

barplot(sort(table(airportsUS$state)))

pdf("airport-count.pdf")
barplot(sort(table(airportsUS$state)))
dev.off()
write.csv(airportsUS, "airportsUS.csv")
q()
