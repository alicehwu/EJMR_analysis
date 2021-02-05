# This file aims to identify posts in the four-yr sample that discuss each author by full name
# Output: a panel dataset with EJMR "history" of each NBER author

# directories 
dir_data="../data/"


# datasets
# (1) EJR (complete four-year sample, 2.2 million posts)
EJR=read.csv(paste0(dir_data,"raw/EJR0_raw_text_cleaned.csv"),stringsAsFactors = FALSE)
EJR=EJR[EJR$post_miss==0,c("title_id1","post1","raw_cat")]
dim(EJR) # [1] 2172129       3; still 223,475 threads

# (2) authors
authors=read.csv(paste0(dir_data,"NBER/nber-author-info.csv"),stringsAsFactors = FALSE)
authors=authors[,c("full_name","first_name","last_name")]
sum(duplicated(authors$full_name)) # 0 

# special characters ("//*" in 2 names) 
authors[authors$full_name=="FRANCESCO DAC**TO",c("full_name","last_name")]=c("FRANCESCO DACUNTO","DACUNTO")
authors[authors$full_name=="IS**TA RAJANI",c("full_name","first_name")]=c("ISHITA RAJANI","ISHITA")


# set up dataframe and save into .csv file with column names 
#author_history=data.frame(title_id1=0,post1=0,full_name="",check_middle=0) # default "full_name" is factor
#author_history$full_name=as.character(author_history$full_name)
#write.csv(author_history,paste0(dir_data,"NBER/author-history-ID-by-full.csv"),row.names = FALSE)

### Matching 
for (i in 1:nrow(authors)){
  name=tolower(paste(authors[i,"first_name"],authors[i,"last_name"],sep=" "))
  
  print(c(i,name))
  EJR$by_full=sapply(EJR$raw_cat,function(x) length(grep(name,tolower(x)))) # 1 if matched, 0 otherwise (length(integer(0))=0)
  if (sum(EJR$by_full)!=0){
    history=EJR[EJR$by_full==1,c("title_id1","post1")]  
    history$full_name=name
    history$check_middle=0+(name!=tolower(authors[i,"full_name"]))
    print(dim(history))
    write.table(history,paste0(dir_data,"NBER/author-history-ID-by-full.csv"),append=TRUE,col.names = FALSE,sep=",",row.names = FALSE)
    
    #author_history=rbind(author_history,history)
    rm(name,history)
  }
}



