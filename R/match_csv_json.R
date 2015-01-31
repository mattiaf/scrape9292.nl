library("rjson")
json_file <- "../web/js/topojsonlowprecision.json"
json_data <- fromJSON(paste(readLines(json_file), collapse=""))

n<-length(json_data$objects$countries$geometries) #counts how many gemeenten 

json_data2<-json_data
json_data2$name<-sapply(json_data$objects$countries$geometries,function(x) {x$properties$GM_NAAM})


load("../data/data_from9292nl.RData")

json_data3 <- data.frame(json_data2$name)
names(json_data3)<-'gemeente'
json_data3$gemeente <- as.character(json_data3$gemeente)

library(plyr) 

#join json and data
json_data3$gemeente<- gsub(" ","",json_data3$gemeente)
data$gemeente<- gsub(" ","",data$gemeente)
json_data3$gemeente<- gsub("-","",json_data3$gemeente)
data$gemeente<- gsub("-","",data$gemeente)

json_data3$gemeente<-tolower(json_data3$gemeente)
data$gemeente<-tolower(data$gemeente)


# cities in Fryslan with Frysian/Dutch name
data$gemeente[data$gemeente == "dantumadeel"] <- 'dantumadiel'
data$gemeente[data$gemeente == "twedde"] <- 'vlagtwedde'
data$gemeente[data$gemeente == "tietjerksteradeel"] <- 'tytsjerksteradiel'
data$gemeente[data$gemeente == "littenseradeel"] <- "littenseradiel"
data$gemeente[data$gemeente == "s?dwestfrysl?n"] <- 'súdwestfryslân'
data$gemeente[data$gemeente == "menaldumadeel"] <- 'menameradiel'
data$gemeente[data$gemeente == "gantumadeel"] <- 'dantumadiel'
data$gemeente[data$gemeente == "ferwerderadeel"] <- 'ferwerderadiel'

#others different names 
data$gemeente[data$gemeente == "bergen(noord"] <- 'bergen(nh.)'
data$gemeente[data$gemeente == "bergen(lim"] <- 'bergen(l.)'
data$gemeente[data$gemeente == "halderberge"] <- 'halderberge'
data$gemeente[data$gemeente == "nuenen.gerwenenne"] <- 'nuenen,gerwenennederwetten'
data$gemeente<- gsub("\\(gem","",data$gemeente) # correct for utrecht!
data$gemeente<- gsub("denhaag","'sgravenhage",data$gemeente) # correct for denhaag == sgravenghage



mergedfactor<-join(json_data3,  data,  by="gemeente", type="left", match="all")
mergedfactor$timeinminutes <- numeric(n)

#writes inside json under properties
for (k in 1:n){
        json_data$objects$countries$geometries[[k]]$properties$nchanges <- mergedfactor$nchanges[k]        
        hoursminutes<-strsplit(mergedfactor$traveltime[k], ":")
        timeinminutes<-as.numeric(hoursminutes[[1]][1])*60+as.numeric(hoursminutes[[1]][2])
        json_data$objects$countries$geometries[[k]]$properties$timeinminutes <- timeinminutes
        mergedfactor$timeinminutes[k] <- timeinminutes
}

#exports data. we care only about name, journey time, number of changes
toexport<-data.frame(mergedfactor$gemeente, mergedfactor$timeinminutes, as.numeric(mergedfactor$nchanges))
                   
                     
names(toexport)<-c('name', 'timeinminutes', 'nchanges')
write.csv(toexport, file='../web/scrapeddata.csv',row.names=FALSE)