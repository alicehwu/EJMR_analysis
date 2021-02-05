# This file takes "EJR0_raw_text.csv" & splits the concatenated text into (1) poster ID and (2) post itself

# directory
dir_raw="/Users/alicehwu/Documents/Alice/Research/EJR_project/EJR_2018/data/raw/"

# load data
EJR0=read.csv(paste0(dir_raw,"EJR0_raw_text.csv"))
dim(EJR0) # [1] 2217046       3 
EJR0$raw_cat=as.character(EJR0$raw_cat)

# Clean up titles
sum(EJR0$post1==1)==max(EJR0$title_id1) # TRUE; 223,475 threads
EJR0[EJR0$post1==1,"raw_cat"]=gsub("<url>https://www.econjobrumors.com/topic/","",EJR0[EJR0$post1==1,"raw_cat"])
EJR0[EJR0$post1==1,"raw_cat"]=gsub("</url>","",EJR0[EJR0$post1==1,"raw_cat"])
EJR0[EJR0$post1==1,"raw_cat"]=gsub("-"," ",EJR0[EJR0$post1==1,"raw_cat"])

# Clean up posts
    # pattern: lines connected by "-YH0-" 
    # between 1st and 2nd lies in "Economist" or "Kirk"...
    # between 2nd and 3rd: poster ID
    # after the 3rd: the post itself. "-YH0-" shall be replaced by " " 
EJR0$n_YH0=sapply(EJR0$raw_cat,function(x) length(gregexpr('-YH0-',x)[[1]]))
    # all titles: n_YH0=1 b/c "-YH0-" does not exist & gregexpr returns -1 
    # if n_YH0=2: post content is missing most likely due to nested blockquotes 
EJR0$post_miss=0+(EJR0$n_YH0==2) # e.g. "Happy_Next-YH0-Economist-YH0-9593"
sum(EJR0$post_miss==1) # [1] 44917
sum(EJR0$post_miss==1)/nrow(EJR0) # [1] 0.02025984

get_name<-function(x) if (length(gregexpr('-YH0-',x)[[1]])>=2){substr(x,gregexpr('-YH0-',x)[[1]][1]+5,gregexpr('-YH0-',x)[[1]][2]-1)} else{""}
get_id<-function(x){
  if (length(gregexpr('-YH0-',x)[[1]])==2){
    substr(x,gregexpr('-YH0-',x)[[1]][2]+5,nchar(x))
  }else if (length(gregexpr('-YH0-',x)[[1]])>=3){
    substr(x,gregexpr('-YH0-',x)[[1]][2]+5,gregexpr('-YH0-',x)[[1]][3]-1)
  } else{""}
}
get_post<-function(x){
          if (length(gregexpr('-YH0-',x)[[1]])==1){x}else if ((length(gregexpr('-YH0-',x)[[1]])==2)) {""}else{
            substr(x,gregexpr('-YH0-',x)[[1]][3]+5,nchar(x))
          }
}
  
EJR0$poster_name=sapply(EJR0$raw_cat,get_name)
EJR0$poster_id=sapply(EJR0$raw_cat,get_id)
sum(EJR0$poster_name=="Economist") # [1] 1,949,804

EJR0$raw_cat=sapply(EJR0$raw_cat,get_post)
EJR0$raw_cat=gsub("Happy_Next","",EJR0$raw_cat)
EJR0$raw_cat=gsub("-YH0-"," ",EJR0$raw_cat)
EJR0$raw_cat=gsub("\n"," ",EJR0$raw_cat)
EJR0[EJR0$post_miss==1,"raw_cat"]="YH0"
sum(EJR0$raw_cat=="") # [1] 0
EJR0=subset(EJR0,select=-c(n_YH0))

write.csv(EJR0,paste0(dir_raw,"EJR0_raw_text_cleaned.csv"),row.names = FALSE)

EJR0_str=data.frame(raw_cat=EJR0$raw_cat)
write.csv(EJR0_str,paste0(dir_raw,"str_only_Nov2017.csv"),row.names=FALSE)



