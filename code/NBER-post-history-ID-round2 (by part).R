# This file aims to identify posts in the four-yr sample that discuss each author by first/last names
# Output: a panel dataset with EJMR "history" of each NBER author

# directories 
dir_data="..data/"


# datasets
# (1) EJR (complete four-year sample, 2.2 million posts)
EJR=read.csv(paste0(dir_data,"raw/EJR0_raw_text_cleaned.csv"),stringsAsFactors = FALSE)
dim(EJR) # [1] 2217046       6
sum(EJR$post1==1) # 223,475 threads
max(EJR$title_id1) # [1] 223475

EJR=EJR[EJR$post_miss==0,c("title_id1","post1","raw_cat")]
dim(EJR) # [1] 2172129       3; still 223,475 threads


# (2) authors
authors=read.csv(paste0(dir_data,"NBER/nber-ejr-author-info.csv"),stringsAsFactors = FALSE)
authors=authors[,c("full_name","first_name","last_name")]
sum(duplicated(authors$full_name)) # 0 

# special characters ("//*" in 2 names) 
authors[authors$full_name=="FRANCESCO DAC**TO",c("full_name","last_name")]=c("FRANCESCO DACUNTO","DACUNTO")
authors[authors$full_name=="IS**TA RAJANI",c("full_name","first_name")]=c("ISHITA RAJANI","ISHITA")


# (3) by_full results
author_history0=read.csv(paste0(dir_data,"NBER/author-history-ID-by-full.csv"),stringsAsFactors = FALSE)
# only search within threads with matched full names! 
EJR=EJR[EJR$title_id1 %in% unique(author_history0$title_id1),]
print(dim(EJR))

# set up dataframe and save into .csv file with column names 
author_history=data.frame(title_id1=0,post1=0,by_first=0,by_last=0,full_name="") # default "full_name" is factor
author_history$full_name=as.character(author_history$full_name)
write.csv(author_history,paste0(dir_data,"NBER/author-history-ID-by-part.csv"),row.names = FALSE)

### Matching 
for (i in 1:nrow(authors)){
  first_name=tolower(authors[i,"first_name"])
  last_name=tolower(authors[i,"last_name"])
  name=paste(first_name,last_name,sep=" ")
  
  print(c(i,name))
  #EJR$by_full=sapply(EJR$raw_cat,function(x) length(grep(name,tolower(x)))) # 1 if matched, 0 otherwise (length(integer(0))=0)
  EJR$by_first=sapply(EJR$raw_cat,function(x) length(grep(first_name,tolower(x))))
  EJR$by_last=sapply(EJR$raw_cat,function(x) length(grep(last_name,tolower(x))))
  
  if (sum(EJR$by_first)!=0 | sum(EJR$by_last)!=0){
    history=EJR[EJR$by_first==1 | EJR$by_last==1,c("title_id1","post1","by_first","by_last")]  
    history$full_name=name
    print(dim(history))
    write.table(history,paste0(dir_data,"NBER/author-history-ID-by-part.csv"),append=TRUE,col.names = FALSE,sep=",",row.names = FALSE)
    
    rm(first_name,last_name,name,history)
  }
}



