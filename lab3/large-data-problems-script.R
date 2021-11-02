

# Determining the size of the problem ...

# On CeR VMs ...
path <- "/course/ASADataExpo2009/Data/"
filename <- paste0(path, "2008.csv")

system(paste0("ls -lh ", filename))
system(paste0("du -sh ", path))
system(paste0("wc -l ", filename))
system(paste0("head ", filename))

system("free -h")
system("df -h")

# Reasoning about object sizes in R 
# Size of numeric vectors
object.size(integer(1000))
object.size(numeric(1000))
object.size(numeric(10000))
object.size(numeric(100000))
object.size(numeric(1000000))
# Character vectors are interesting because they are actually
# pointers (8-bytes) to the CHARSXP cache!
object.size(letters)
object.size(rep("a", 26))
object.size(rep("a", 1000))
object.size(rep("a", 10000))
# Data frame is (roughly) sum of columns
object.size(data.frame(x=numeric(100000), y=rep("a", 10000)))

# R's memory usage
# Baseline (watch the Vcells used)
gc()
# Allocate memory for 'x'
x <- numeric(1e6)
object.size(x)
gc()
# Release memory from 'x'
rm(x)
gc()

# Estimating the memory required for large CSV
f2008sample <- read.csv(filename, nrow=2)
table(sapply(f2008sample, class))
system(paste("wc -l", filename))
7009729*(25*4 + 4*8)

# Should use up a lot of RAM
gc()
# Slow
f2008 <- read.csv(filename)
object.size(f2008)
gc()
rm(f2008)

## Exploring object allocations within functions
## Memory profiling
## https://cran.r-project.org/web/packages/profmem/vignettes/profmem.html
object.size(integer(10000000))
object.size(matrix(rnorm(n = 10000000), nrow = 100))
f <- function() {
    x <- integer(10000000)
    Y <- matrix(rnorm(n = 10000000), nrow = 100)
    NULL
}
library("profmem")
## NOTE that the result from profmem() is a data frame
## (so we can subset() it, etc)
p <- profmem(f())
p
## profmem() is an overestimate
f2 <- function() {
    Y <- matrix(rnorm(n = 10000000), nrow = 100)
    rm(Y)
    gc()
    x <- integer(10000000)
    NULL
}
p <- profmem(f2())
total(p)
gc(reset=TRUE)
f()
gc()

# A LOT can be going on ...
# Slow
p <- profmem(f2008 <- read.csv(filename))
p
total(p)
object.size(f2008)

## Model matrices
x1 <- runif(1000000)
x2 <- runif(1000000)
gnum <- rep(1:5, each=200000)
g <- factor(gnum)
y <- x1 + x2 + gnum + rnorm(1000000)

## Single continuous variable
p <- profmem(lm(y ~ x1))
subset(p, bytes > 10000000 & !is.na(bytes))
head(model.matrix(y ~ x1))

## Two continuous variables
p <- profmem(lm(y ~ x1 + x2))
subset(p, bytes > 10000000 & !is.na(bytes))
head(model.matrix(y ~ x1 + x2))

## Add a categorical variable (5 levels)
p <- profmem(lm(y ~ x1 + x2 + g))
subset(p, bytes > 10000000 & !is.na(bytes))
head(model.matrix(y ~ x1 + x2 + g), 30)

## An example of a large model matrix
# f2008 <- read.csv(filename)
lm(DepDelay ~ Origin, f2008, subset=1:10000)
nrow(f2008)
length(unique(f2008$Origin))
## (be careful where you run the next line !)
# mm <- model.matrix(DepDelay ~ Origin, f2008)

## Measuring memory usage in the shell
## time --format="%M" (gives resident memory usage in KB)
## Use /usr/bin/time (else get bash built-in 'time' command)
## Baseline R memory use 
runinshell <- function() {
    /usr/bin/time -f "%M" Rscript -e 'invisible(NULL)'
    ## Generate an 8MB R structure
    /usr/bin/time -f "%M" Rscript -e 'invisible(rnorm(1000000))'
    ## Generate an 80MB R structure
    /usr/bin/time -f "%M" Rscript -e 'invisible(rnorm(10000000))'

    ## R vs wc
    ## Slow
    /usr/bin/time -f "%M" Rscript -e 'length(readLines("/course/ASADataExpo2009/Data/2008.csv"))'
    /usr/bin/time -f "%M" wc -l /course/ASADataExpo2009/Data/2008.csv
})
