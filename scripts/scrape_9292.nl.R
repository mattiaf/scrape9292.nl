# ----------------------- #
# This code reads a list of Dutch municipalities and queries the website of 9292.nl (public travel planner)
# in order to retrieve, for each Dutch city, how long it takes to get to the airport
# ----------------------- #


library(bitops)
library(RCurl)
library(XML)


scrape9292<-function(place,url1,url2){
        stringtourl<-tolower(place)
        stringtourl<- gsub(" ","-",stringtourl)
        url <- paste(url1,stringtourl, url2, sep="")
        SOURCE <-  getURL(url,encoding="UTF-8")
        PARSED <- htmlParse(SOURCE) #Format the html code 
        a<-xpathSApply(PARSED, "//dd",xmlValue)
        return(a)
}

# ----- Read table with list of municipalities ----- #
#Straight from wikipedia, it includes the following columns:
#gemeente  = municipality
#provincie = province name
#inwoners = number of inhabitants 
#landoppervlakte  = area 
#inwoners/km,gem = density
#inkomen per inw. = GDP pro capita
#hoofdplaats = capital of the municipality 
#grootste plaatsen = biggest centers in the municipality

initial<-read.csv("../data/gemeenten_fromwiki.csv", nrows=12, header=TRUE, stringsAsFactors=FALSE)
classes <-sapply(initial, class)
data <- read.csv("../data/gemeenten_fromwiki.csv", colClasses = classes,header=TRUE)


# ----- Some fixes to the table ----- #

#fix gemeente names being double! ("Rotterdam Rotterdam" -> "Rotterdam")
gemeente<-data$X.gemeente 
goodgemeente<-substr(gemeente, 2, nchar(gemeente)/2)
data$gemeente<-goodgemeente

# from column with more towns in the gemeente/municipality, gets the name of the first one (looks like it's the biggest)
data$biggest_town <- sapply(strsplit(data$grootste.plaatsen, "\\. "),function(x) x[[1]])

# new columns we will fill!
data$traveltime <- numeric(length(data$gemeente)) # data we want to get
data$nchanges <- numeric(length(data$gemeente)) # data we want to get
data$timeused <- numeric(length(data$gemeente)) # useful for debbugging 
data$provinceshort<-(as.factor(data$provincie)) # create a column with shortened version of provinces
levels(data$provinceshort) <- c('dr', 'fl', 'fr',  'gl', 'gn', 'lb' , 'nb', 'nh', 'ov', 'ut', 'zl', 'zh')
addprovince <- 0
usegemeente <- 0



# ----- Scraping 9292.nl ----- #

# Format of queries online is http://9292.nl/en/journeyadvice/ORIGIN/DESTINATION/DATEandTIME
# We'll keep destination (Schiphol) and date/time fixed, and change the origin, according to the list of gemeenten
url1 <- "http://9292.nl/reisadvies/" 
url2 <- "/station-schiphol/vertrek/2014-12-15T1801"

# Cycle on municipalities 
for (k in 1:length(data$gemeente)) {
                
        time_init<-Sys.time()
        
        #first try: using the capital city of the municapility        
       	town_to_use <- data$hoofdplaats[k]
        if (data$hoofdplaats[k]==""){town_to_use <- data$biggest_town[k]} # for some reason there might be no capital listed, then use biggest town
        
        
        a<-scrape9292(town_to_use, url1, url2)
                

        #if no data retrieved, try with name of the gemeente
        if (length(a) == 0 ) {

                a<-scrape9292(data$gemeente[k], url1, url2)
                usegemeente <- usegemeente + 1  # just an index telling me how many times the code was here
        }


        #if no data retrieved, try with biggest town eiphenated with name of the province (like baarle-nassau-nb, Baarle-Nassau in Noord Brabaant) 
        if (length(a) == 0 ) {
                a<-scrape9292(data$biggest_town[k], url1, url2)
                addprovince <- addprovince +1  # just an index telling me how many times the code was here
        }
        
        
        #this is the data we want!
        traveltime<-c(a[2],a[4],a[6],a[8]) # extract traveltime of the 4 solution that 9292.nl proposes
        changes<-c(a[1],a[3],a[5],a[7]) # extract number of changes of the 4 solution that 9292.nl proposes

        print(traveltime)
	# if we have data, add to table
        if (length(a) != 0 ) {
                data$traveltime[k] <- min(traveltime) # add minimum traveltime (optimal solution)
                data$nchanges[k] <- min(changes) # add minimum number of changes
        }

	# bummer if no data found
        if (length(a) == 0 ) {
                data$traveltime[k] <- NA
                data$nchanges[k] <- NA
        }

        
        time_end<-Sys.time()
        data$timeused[k]<-as.numeric(time_end - time_init)  
        print(k)
        
}

#save table!
save(data,url1,url2, file = "../data/data_from9292nl.RData")


# Checks
# how many times we had to...
print(addprovince) # add the province to the name of town? 27
print(usegemeente) # use the name of the municipality? 39 (39-27 = 12)

# for how many municipalities we couldn't get data from 9292.nl?
sum(is.na(data$nchanges[1:length(data$gemeente)]))
#which ones?
data$gemeente[is.na(data$nchanges)]
data$hoofdplaats[is.na(data$nchanges)]
data$biggest_town[is.na(data$nchanges)]
