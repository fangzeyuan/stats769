
## Getting into Linux
# FlexIT to Ubuntu 18.04
# ssh to VM (or desktop)

### Basic file system operations
# Where are we ?
pwd
# Make a directory (folder) for my project
mkdir Flights
# List current files and directories
ls
# List parent directories
ls ..
ls ../..
# List absolute paths
ls /
ls /course
# There are places we cannot go!
ls /root
# Change to new directory
cd Flights
# Where are we ?
pwd
# Copy a file into this directory
cp /course/ASADataExpo2009/Data/airports.csv .
ls
# Notice that overwriting happens without warning
cp /course/ASADataExpo2009/Data/airports.csv .
# Remove a file (then copy it again)
# Notice that removal happens without confirmation!
rm airports.csv 
ls
cp /course/ASADataExpo2009/Data/airports.csv .
# List more about current files
ls -lh
# What else can 'ls' do ?
man ls
# View the contents of a file
cat airports.csv
# View just the first few lines
head airports.csv
# View the last few lines
tail airports.csv
# View the file one "page" at a time
# (space bar for next page, 'q' to quit)
more airports.csv
# (space bar for next page, 'b' for previous page, 'q' to quit,
#  '/pattern' to search, 'n' for next match, 'N' for previous match)
less airports.csv

### Multi-user, shared-resource environment
who
top
df -h

### Running R
R
# see ./linux-shell-script.R
# source("line-shell-script.R")

### Processing R Markdown
cp ../airports.Rmd .
cat airports.Rmd
# Generate HTML
Rscript -e 'library(rmarkdown); render("airports.Rmd")'

