# code reference: author-post-history-ID (by full) / by part in NBER folder

# directories 
dir_data="../data/"
dir_JMC="../data/JMC/"

# datasets
# (1) EJR (complete four-year sample, 2.2 million posts)
EJR=read.csv(paste0(dir_data,"raw/EJR0_raw_text_cleaned.csv"),stringsAsFactors = FALSE)
dim(EJR) # [1] 2217046       6
sum(EJR$post1==1) # 223,475 threads

EJR=EJR[EJR$post_miss==0,c("title_id1","post1","raw_cat")]
dim(EJR) # [1] 2172129       3; still 223,475 threads

# (2) Job Market Candidates
authors=read.csv(paste0(dir_JMC,"jmc_data_gender_nonmissing.csv"),stringsAsFactors = FALSE)

# set up dataframe and save into .csv file with column names 
author_history=data.frame(title_id1=0,post1=0,by_full=0,by_first=0,by_last=0,by_abbrev=0,jmc_id=0) # default "full_name" is factor
write.csv(author_history,paste0(dir_JMC,"JMC-history-ID.csv"),row.names = FALSE)


# For loop
for (i in 1:nrow(authors)){
  id=authors[i,"jmc_id"]
  first_name=tolower(authors[i,"first_name"])
  last_name=tolower(authors[i,"last_name"])
  name=paste(first_name,last_name,sep=" ")
  abbrev=toupper(paste0(substr(first_name,1,1),substr(last_name,1,1)))
  print(c(i,id,name,abbrev))
  
  EJR$by_full=sapply(EJR$raw_cat,function(x) length(grep(paste0("\\b",name,"\\b"),tolower(x)))) # 1 if matched, 0 otherwise (length(integer(0))=0)
  if (sum(EJR$by_full)!=0){
    history=EJR[EJR$by_full==1,c("title_id1","post1","by_full")] 
    
    subset=EJR[EJR$title_id1 %in% unique(history$title_id1),]
    subset$by_first=sapply(subset$raw_cat,function(x) length(grep(paste0("\\b",first_name,"\\b"),tolower(x))))
    subset$by_last=sapply(subset$raw_cat,function(x) length(grep(paste0("\\b",last_name,"\\b"),tolower(x))))
    subset$by_abbrev=sapply(subset$raw_cat,function(x) length(grep(paste0("\\b",abbrev,"\\b"),x)))
    
    subset=subset[subset$by_first==1 | subset$by_last==1 | subset$by_abbrev==1,c("title_id1","post1","by_first","by_last","by_abbrev")]
    history=merge(history,subset,by=c("title_id1","post1"),all=T)
    history$jmc_id=id
    print(dim(history))
    write.table(history,paste0(dir_JMC,"JMC-history-ID.csv"),append=TRUE,col.names = FALSE,sep=",",row.names = FALSE)
    
    rm(id,first_name,last_name,name,history,subset)
  }
}


