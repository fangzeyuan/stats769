
## Example
## Bootstrap distribution of regression slope parameter
plot(mpg ~ disp, mtcars)
N <- 20
betas <- numeric(N)
nrow <- nrow(mtcars)
for (i in 1:N) {
    resample <- sample(1:nrow, nrow, replace=TRUE)
    fit <- lm(mpg ~ disp, mtcars[resample, ])
    coef <- coef(fit)
    abline(coef, col=rgb(0,0,0,.02))
    betas[i] <- coef[2]
}
betas
plot(density(betas))

## Larger example (without the plotting)
N <- 2000
betas <- numeric(N)
nrow <- nrow(mtcars)
for (i in 1:N) {
    resample <- sample(1:nrow, nrow, replace=TRUE)
    fit <- lm(mpg ~ disp, mtcars[resample, ])
    coef <- coef(fit)
    betas[i] <- coef[2]
}
length(betas)
head(betas)

# Same code as function
myboot <- function(N=2000) {
    betas <- numeric(N)
    nrow <- nrow(mtcars)
    for (i in 1:N) {
        resample <- sample(1:nrow, nrow, replace=TRUE)
        betas[i] <- lm(mpg ~ disp, mtcars[resample, ])$coef[2]
    }
    betas
}
betas <- myboot()
length(betas)
head(betas)

## Same code in .R file
source("boot.R")
length(betas)
head(betas)

## Same code with separate worker
# - how do I get 'betas' back from the worker ?
system("Rscript boot.R", ignore.stdout=TRUE)

# Why doesn't this work ?
# ... because the worker R session does not know about myboot()
# - how do I get information to the worker ?
system("Rscript -e 'betas <- myboot()'")


###########
## Timings
system.time(source("boot.R"))

## Repeat 3 times (in series)
system.time({
    source("boot.R")
    source("boot.R")
    source("boot.R")
})

## Repeat 3 times with 3 workers (in series)
system.time({
    system("Rscript boot.R", ignore.stdout=TRUE)
    system("Rscript boot.R", ignore.stdout=TRUE)
    system("Rscript boot.R", ignore.stdout=TRUE)
})

# Manual parallel processing (3 worker R sessions)
# Three times the work done in the same amount of time
# (because each R session gets run by the OS on different CPU core)
# - how do I know when they have all finished ?
system.time({
    system("Rscript boot.R", ignore.stdout=TRUE, wait=FALSE)
    system("Rscript boot.R", ignore.stdout=TRUE, wait=FALSE)
    system("Rscript boot.R", ignore.stdout=TRUE, wait=FALSE)
})


# Use multiple cores via mclapply() 
library(parallel)
# How many cores do I have ?
numCores <- detectCores()
numCores
timer <- function(x) Sys.sleep(.5)
# Serial
system.time(
    lapply(1:10, timer)
    )
# Parallel (on Linux)
# NOTE the effect of num calls versus num cores
system.time(
    mclapply(1:10, timer, mc.cores=4)
    )
system.time(
    mclapply(1:5, timer, mc.cores=4)
    )

# Back to the bootstrap example
system.time({
    threeBoots <- mclapply(1:3, function(i) { source("boot.R"); betas },
                           mc.cores=3)
})
# The result is a list 
class(threeBoots)
length(threeBoots)
head(threeBoots[[1]])
# Using the function ALSO works because we pass the function object
# as an argument to mclapply()
threeBoots <- mclapply(rep(2000, 3), myboot, mc.cores=3)
head(threeBoots[[1]])
# AND the following also works ...
threeBoots <- mclapply(1:3, function(i) myboot(), mc.cores=3)
head(threeBoots[[1]])
# ... because the worker R sessions are FORKs of the current R session,
# so they can see the function myboot()

# Use multiple cores via makeCluster()
# NOTE the startup time for makeCluster() getting 'numCores' R sessions started
cl <- makeCluster(4)
system.time(
    parLapply(cl, 1:10, timer)
    )
system.time(
    parLapply(cl, 1:5, timer)
    )
stopCluster(cl)

# Back to the bootstrap example
system.time({
    ## NOTE the overhead of starting up several new R sessions
    cl <- makeCluster(3)
    threeBoots <- parLapply(cl, 1:3, function(i) { source("boot.R"); betas })
    ## (almost) NONE of the work is done in THIS R session
})
head(threeBoots[[1]])
# Using the function works because we pass the function object
# as an argument to parLapply()
# NOTE that we can reuse the cluster
threeBoots <- parLapply(cl, rep(2000, 3), myboot)
head(threeBoots[[1]])
# BUT the following does NOT work ...
# ... because the worker R sessions are independent and communicating via
# sockets, so they do not know about myboot()
threeBoots <- parLapply(cl, 1:3, function(i) myboot())
# BUT we can make it work by sending the myboot() function to the worker
# R sessions.
clusterExport(cl, "myboot")
threeBoots <- parLapply(cl, 1:3, function(i) myboot())
head(threeBoots[[1]])
# Clean up
stopCluster(cl)

# Demonstration of parallel code running SLOWER
# Run on my PC
# Serial
system.time(oneBoot <- myboot(6000))
# Good parallel
system.time({
    cl <- makeCluster(3)
    threeBoots <- parLapply(cl, rep(2000, 3), myboot)
    stopCluster(cl)
})
# Bad parallel
system.time({
    cl <- makeCluster(100)
    hundredBoots <- parLapply(cl, rep(30, 100), myboot)
    stopCluster(cl)
})

# Use multiple machines via makeCluster()
# NOTE that not only are the worker R sessions independent and
# communicating via sockets, BUT they no longer share
# the same file system either!
# This means there is even more set up required.
# R must be installed, R packages must be installed, files must copied ...

## RUN FROM DO droplets !!!
## (based on ubuntu-769-parallel-... image, which already has R and boot.R)
##   143.198.73.203
##   137.184.3.5

## ssh root@143.198.73.203

library(parallel)
cl <- makeCluster(c(rep("localhost", 2),
                    rep("137.184.3.5", 2)),                  
                  master="143.198.73.203",
                  user="root",
                  homogeneous=FALSE,
                  Rscript="/usr/bin/Rscript")
threeBoots <- parLapply(cl, 1:3, function(i) source("boot.R"))
head(threeBoots[[1]]$value)
stopCluster(cl)

## BACK TO VMs

## NOTE jobs are "chunked" to workers differently
mclapply(1:8, function(i) paste(Sys.getpid(), ":", i), mc.cores=4)
cl <- makeCluster(4)
parLapply(cl, 1:8, function(i) paste(Sys.getpid(), ":", i))
stopCluster(cl)

# Load balancing/chunking
# NOTE order of chunks matters (do big jobs first)
variableTimer <- function(x) Sys.sleep(x/2)

system.time(
    mclapply(1:8, variableTimer, mc.cores=4)
    )
system.time(
    mclapply(1:8, variableTimer, mc.cores=4, mc.preschedule=FALSE)
    )
system.time(
    mclapply(8:1, variableTimer, mc.cores=4)
    )
system.time(
    mclapply(8:1, variableTimer, mc.cores=4, mc.preschedule=FALSE)
    )

cl <- makeCluster(4)
system.time(
    parLapply(cl, 1:8, variableTimer)
    )
system.time(
    parLapplyLB(cl, 8:1, variableTimer)
    )
stopCluster(cl)

# Implicit parallelism
library(boot) 
betafun <- function(data, b) {  
    d <- data[b, ] 
    lm(d$mpg ~ d$disp)$coef[2]
}
system.time(bootBeta <- boot(data=mtcars, statistic=betafun, R=6000))
system.time(bootBetaParallel <- boot(data=mtcars, statistic=betafun, R=6000,
                                     parallel="multicore", ncpus=3))
str(bootBeta)
str(bootBetaParallel)

## SHELL CODE BELOW

## backgrounding and niceing processes
Rscript -e 'for (i in 1:3) { Sys.sleep(1); print(i) }'
echo done

Rscript -e 'for (i in 1:3) { Sys.sleep(1); print(i) }' &
echo done

time -p taskset -c 0 Rscript -e 'invisible(rnorm(100000000))' &
time -p taskset -c 0 Rscript -e 'invisible(rnorm(100000000))' &

    
time -p taskset -c 0 Rscript -e 'invisible(rnorm(100000000))' &
time -p taskset -c 0 nice -n19 Rscript -e 'invisible(rnorm(100000000))' &

time -p Rscript -e 'invisible(rnorm(100000000))' &
time -p Rscript -e 'invisible(rnorm(100000000))' &

