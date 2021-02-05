# this file merges (1) EJR four-yr gender sample, (2) posts about NBER authors, (3) posts about PhD graduates/JMCs
# output: full_sample2019.csv


dir_data="../data/" # please update the directory accordingly

#------------------------------------------------------------------------------------------#
### (1) EJR gender sample (1.7 million postings)
# female0_pred defined through gender classifiers (=1 if a post includes female classifiers only, 0  if it includes male classifiers only)
# when a post includes both female and male classifiers, I used Lasso-Logit model based on other words to re-classify the gender. 
# Please see replications files at https://www.aeaweb.org/articles?id=10.1257/pandp.20181101 for details on the Lasso-logit regression 

raw_source1=read.csv(paste0(dir_data,"gender_sample_by_classifiers/EJR_gender_dataset_Jan2018.csv"),stringsAsFactors = FALSE)
nrow(raw_source1) # [1] 1734998    
raw_source1=raw_source1[order(raw_source1$title_id1,raw_source1$post1),] # sorted by title_id1+post1
rownames(raw_source1)<-1:nrow(raw_source1) # re-index

raw_source1=raw_source1[,c("title_id1","post1","female0_pred")]
sum(duplicated(raw_source1[,c("title_id1","post1")])) # 0 

uniq_thread_source1=unique(raw_source1$title_id1) # 138,357 threads

#------------------------------------------------------------------------------------------#
### (2) Threads that mention NBER authors (matched by names)
history=read.csv(paste0(dir_data,"NBER/author-history-merged.csv"),stringsAsFactors = FALSE) 
dim(history) # [1] 288671     17 (note: the entire thread is preserved when it contains at least one post that mentions an NBER author)
sum(!duplicated(history[,c("title_id1","post1")])) # [1] 163591 (duplicate posts if discuss multiple authors)

raw_source2=history[!duplicated(history[,c("title_id1","post1")]),c("title_id1","post1")] # [1] 163591      2

uniq_thread_source2=unique(raw_source2$title_id1) # 12,138 unique threads (8,757 unique non-NBER threads)
sum(uniq_thread_source2 %in% uniq_thread_source1) # 10,587 in gender sample (8,169 non-abstract in gender_sample)
new_source2=setdiff(uniq_thread_source2,uniq_thread_source1) # 588 new threads
sum(raw_source2$title_id1 %in% new_source2) # [1] 7659 new postings from source 2

# combine source1 and source2 
raw_source1$source1=1
raw_source2$source2=1
full_sample=merge(raw_source1,raw_source2,by=c("title_id1","post1"),all=T) # [1] 1742657       5

full_sample[is.na(full_sample$source1),"source1"]=0
full_sample[is.na(full_sample$source2),"source2"]=0
sum(full_sample$source1) # [1] 1734998 as in the gender_sample as always:)
sum(full_sample$source2) # [1] 163591 that mention names of NBER authors


#------------------------------------------------------------------------------------------#
### (3) Threads that mention JMCs (matched by names)
JMC_ID_merged=read.csv("JMC/JMC-history-ID-merged.csv",stringsAsFactors = FALSE)
# note the data above only includes posts that mention at least part of a person's name
uniq_thread_JMC=unique(JMC_ID_merged$title_id1) # 3,117 unique threads that contain posts about JMCs

# merge with 2.2 million complete dataset to preserve an entire thread 
EJR_raw=read.csv(paste0(dir_data,"raw/EJR0_raw_text_cleaned.csv"),stringsAsFactors = FALSE)

raw_JMC=EJR_raw[EJR_raw$title_id1 %in% uniq_thread_JMC,c("title_id1","post1")] # [1] 49810     2
raw_JMC$source_JMC=1
sum(!duplicated(raw_JMC$title_id1)) # [1] 3117 threads that contain >=1 post about JMC

full_sample=merge(full_sample,raw_JMC,by=c("title_id1","post1"),all=T)
full_sample$source_JMC=0+(full_sample$title_id1 %in% unique(raw_JMC$title_id1))
full_sample[is.na(full_sample$source1),"source1"]=0
full_sample[is.na(full_sample$source2),"source2"]=0

nrow(full_sample) # [1] 1743220 rows

sum(full_sample$source1) # source 1: gender sample based on gender classifers (pronouns etc) - 1,734,998 posts
sum(full_sample$source2) # source 2: NBER fellows and authors - 163,591 posts
sum(full_sample$source_JMC) # source 3: job market candidates - 49,810 posts 


############################################################################################################################
### Full Sample ### 
# (1) merge with EJR_raw to get "raw_cat" - content of posts
# (2) merge with main_stats to get thread-level statistics, scraped from main pages of EJMR
# (3) merge with counts of gender classifiers, generated in prep_for_analysis.py
############################################################################################################################

### (1) Merge with EJR_raw
full_sample=merge(full_sample,EJR_raw[,c("title_id1","post1","raw_cat","poster_name","poster_id")],by=c("title_id1","post1"),all.x=T)

#------------------------------------------------------------------------------------------#
### (2) Merge in month_first, month_latest, job rank at the thread level 
# Load main stats 
main_stats=read.csv(paste0(dir_data,"raw/main_stats_cleaned.csv"),stringsAsFactors = FALSE)
dim(main_stats) # [1] 306253     10
main_stats=main_stats[1:which(main_stats$time_str=="4 years")[1]-1,] # [1] 224361     10 # restrict to data after 10/28/2013 --> most recent 4 years
main_stats$topic=gsub("-"," ",main_stats$topic)
main_stats=subset(main_stats,select=-c(url,votes,latest_post_id))
names(main_stats)[7]="time_latest_str"

# duplicate "titles" in main_stats: keep the latest ones (occuring FIRST in this data as it started from Page 1)
main_stats$dup_title=0+duplicated(main_stats$topic)
sum(main_stats$dup_title) # 721 
main_stats=main_stats[main_stats$dup_title==0,]  
main_stats=subset(main_stats,select=-c(dup_title)) # 223640 rows

thread_info=full_sample[full_sample$post1==1,c("title_id1","raw_cat")]
thread_info=thread_info[!is.na(thread_info$title_id1),]
names(thread_info)[2]="topic"
thread_info=merge(thread_info,main_stats,by="topic",all.x=T)
full_sample=merge(full_sample,thread_info,by="title_id1",all.x=T)

# Merge thread_info with the INITIAL time stamp (from first post)
initial_time=read.csv(paste0(dir_data,"raw/raw_time_stamp.csv"),
                      stringsAsFactors = FALSE)
dim(initial_time) # [1] 223475      2
initial_time$time_first_str=sapply(initial_time$raw,
                                   function(x) substr(x,gregexpr("Posted on:",x)[[1]]+10,nchar(x)))
initial_time=initial_time[,c("title_id1","time_first_str")]

full_sample=merge(full_sample,initial_time,by="title_id1",all.x=T)

# recode time (strings) to #years rel. to Oct 2017 (0 means Oct 2016 to Oct 2017)
get_yr<-function(x) if (length(grep("year",x))==0){0}else{as.numeric(substr(x,1,2))}
full_sample$yr_latest=sapply(full_sample$time_latest_str,function(x) if(!is.na(x)){get_yr(x)}else{NA})
full_sample$yr_first=sapply(full_sample$time_first_str,function(x) if(!is.na(x)){get_yr(x)}else{NA})

# assign month codes: Oct 2017 as 0, Sept 2017 as 1, ... 
get_month<-function(x) if (length(grep("month",x))==0){NA}else{as.numeric(substr(x,1,gregexpr("month",x)[[1]]-1))}
full_sample$month_first=sapply(full_sample$time_first_str,get_month)
full_sample[is.na(full_sample$month_first),"month_first"]=sapply(full_sample[is.na(full_sample$month_first),"time_first_str"],
                                                                 function(x) if(gregexpr("year",x)==-1 & !is.na(x)){0}else{NA}) # within 1 month: days, weeks 
full_sample[full_sample$month_first==12 & !is.na(full_sample$month_first),"month_first"]=11

full_sample$month_latest=sapply(full_sample$time_latest_str,get_month)
full_sample[is.na(full_sample$month_latest),"month_latest"]=sapply(full_sample[is.na(full_sample$month_latest),"time_latest_str"],
                                                                   function(x) if(gregexpr("year",x)==-1 & !is.na(x)){0}else{NA})
full_sample[full_sample$month_latest==12 & !is.na(full_sample$month_latest),"month_latest"]=11


#------------------------------------------------------------------------------------------#
### (3) Merge with counts of gender classifiers 
# Notes: although I have used "female0_pred" based on gender classifiers & Lasso-logit (see https://www.aeaweb.org/articles?id=10.1257/pandp.20181101),
# I count the number of gender classifiers in each post again. This step would be necessary if you reconsider the selection of gender classifiers,
# and to resolve posts that include both female and male classifiers, you can re-run the Lasso-logit model to predict gender through
# words other than gender classifiers. 
all_classifiers=read.csv(paste0(dir_data,"raw/EJR_ALL_gender_classifiers_2019.csv"))
full_sample=merge(full_sample,all_classifiers,by=c("title_id1","post1"),all.x=T)



#------------------------------------------------------------------------------------------#
# Output "full_sample2019.csv"
full_sample=full_sample[order(full_sample$title_id1,full_sample$post1),]
write.csv(full_sample,paste0(dir_data,"full_sample2019.csv"),
          row.names = FALSE)

