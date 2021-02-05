# Preparation for Analysis using the full gender sample

# Outline #
# starting from "full_sample2019.csv", merge in info about JMCs, NBER authors, words counts by categories, job ranks
# finalize definitions of female (1 if a Female post), academic vs. personal topics, and job ranks
# Output: "full_sample2019_stata.csv", which is then brought into Stata for static and dynamic analyses (see .do files)

# directories (please change accordingly)
dir_data="../data/"
dir_nber="../data/NBER/"
dir_JMC="../data/JMC/"


library(plyr)

# Load full sample dataset
full_sample=read.csv(paste0(dir_data,"full_sample2019.csv"),stringsAsFactors = FALSE)
dim(full_sample) # [1] 1743220      31

sum(full_sample$source1) # source 1: gender sample based on gender classifers (pronouns etc) - 1,734,998 posts
sum(full_sample$source2) # source 2: NBER fellows and authors - 163,591 posts
sum(full_sample$source_JMC) # source 3: job market candidates - 49,810 posts 

############################################################################
# Section 1: Merge with JMC sample and NBER sample # 
############################################################################
# (1) Merge with JMC info (source_JMC==1)
JMC=read.csv(paste0(dir_JMC,"JMC-history-ID-merged.csv"),stringsAsFactors = FALSE)
# unique at title_id1+post1 
JMC$dup=0+(duplicated(JMC[,c("title_id1","post1")]))
JMC[is.na(JMC$by_full),"by_full"]=0 # NA to 0, consistent with other by_*
full_sample=merge(full_sample,JMC[JMC$dup==0,c("title_id1","post1","jmc_id","female","nJMCs",
                                               "full_name","by_full","by_first","by_last","by_abbrev",
                                               "yr_phd","school")],by=c("title_id1","post1"),all.x=T)

# (2) Merge in gender of NBER authors (source 2==1)
NBER=read.csv(paste0(dir_nber,"author-history-merged.csv"),stringsAsFactors = FALSE)
names(NBER)[19]="by_abbrev"
# note: NBER contains entire threads in which one's full name is mentioned in at least one post
NBER=NBER[NBER$by_full==1|NBER$by_first==1| NBER$by_last==1 |NBER$by_abbrev==1,]
dim(NBER) # [1] 36410    19

author_merged=read.csv(paste0(dir_nber,"complete-nber-author-info.csv"),stringsAsFactors = FALSE) # unique at full_name
author_merged$full_name=tolower(author_merged$full_name)
NBER=merge(NBER[,c("full_name","title_id1","post1","by_full","by_first","by_last","by_abbrev")],
           author_merged[,c("full_name","female","level2016")],
           by="full_name",all.x=T)
temp=ddply(NBER,~title_id1+post1,summarize,nAuthors=length(unique(full_name)),mean_level=mean(level2016,na.rm=T))
NBER=merge(NBER,temp,by=c("title_id1","post1"))

NBER[NBER$nAuthors>1,c("female","level2016","by_full","by_first","by_last","by_abbrev")]=NA
NBER[NBER$nAuthors>1,"full_name"]=NA

NBER$dup=0+(duplicated(NBER[,c("title_id1","post1")])) # 27,138 unique posts

full_sample=merge(full_sample,NBER[NBER$dup==0,],by=c("title_id1","post1"),all.x=T)
full_sample=subset(full_sample,select=-c(dup))
dim(full_sample) # [1] 1743220      50


############################################################################################
# Section 2: Define Topics 
############################################################################################
all_cat=read.csv(paste0(dir_data,"raw/EJR_ALL_categories_2019.csv"),stringsAsFactors=FALSE)
full_sample=merge(full_sample,all_cat,by=c("title_id1","post1"),all.x=T)
dim(full_sample) # [1] 1743220      66

# Academic or Professional
full_sample$acad=full_sample$X1+full_sample$X2+full_sample$X2.5+full_sample$X1.5
full_sample$acad_dummy=0+(full_sample$acad>0)

# Personal or Physical
full_sample$person=full_sample$X4+full_sample$X5+full_sample$X6.5
full_sample$person_dummy=0+(full_sample$person>0)

# 1 if Purely Academic/Professional
full_sample$p_acad_dummy=0+(full_sample$acad_dummy==1 & full_sample$person_dummy==0) # 41% are purely Academic/Professional 



############################################################################################
# Section 3: Define Female 
############################################################################################

table(full_sample$female0_pred) # by gender classifiers
# 0      1 
# 341226 102998 
table(full_sample$female.x) # by names of PhD graduates
# 4563  818  
table(full_sample$female.y) # by names of NBER authors
# 18339  2671 

# (1) Use gender of a JMC or NBER author, if a post includes at least part of one's name (first/last/abbrev)
full_sample$female=NA
full_sample[!is.na(full_sample$female.x),"female"]=full_sample[!is.na(full_sample$female.x),"female.x"]
full_sample[!is.na(full_sample$female.y),"female"]=full_sample[!is.na(full_sample$female.y),"female.y"]
# check if conflict between female.x (JMC) and female.y (NBER) --> NA
full_sample[!is.na(full_sample$female.x) & !is.na(full_sample$female.y) & full_sample$female.x!=full_sample$female.y,"female"]=NA
table(full_sample$female)
# 0     1 
# 22040  3235

# (2) if still missing, use pronouns & gender classifiers (source1==1)
full_sample[is.na(full_sample$female),"female"]=full_sample[is.na(full_sample$female),"female0_pred"]
table(full_sample$female)
# 0      1 
# 347751 105044 

# (3) exclude names as of 02/03/2019 -- remove names that are not gendered / of historical figures, e.g., Marx
full_sample$fem_nonname=0+(full_sample$fem_1>0 | full_sample$fem_2>0 | full_sample$fem_3>0) # gender classifiers that are not names
full_sample[full_sample$fem_nonname==0 & full_sample$exclude_names>0 & is.na(full_sample$female.x) & is.na(full_sample$female.y),"female"]=NA

table(full_sample$female) 
# 0      1 
# 334721 104476 

table(full_sample[full_sample$source1==1,"female"]) # gender classifiers
# 0      1 
# 333560 104200 
table(full_sample[full_sample$source2==1,"female"]) # NBER
# 0     1 
# 50311  7505 
table(full_sample[full_sample$source_JMC==1,"female"]) # JMC
# 0     1 
# 14367  2372 
table(full_sample[full_sample$source2==1 | full_sample$source_JMC==1,"female"]) # economists
# 0     1 
# 56883  8344 (65,227 in total)


# revision: remove threads that do not include any F/M posts so far
# this step is needed due to the 36 names excluded above 
ngender=ddply(full_sample,~title_id1,summarise,ngender=sum(!is.na(female)))
full_sample=merge(full_sample,ngender,by="title_id1")
sum(full_sample$ngender>0) # [1] 1725646


############################################################################################
# Section 4: Define job ranks
# 1-Students, 2-JMC/post-docs, 3-Junior Faculty, 4-Senior Faculty
############################################################################################

# Merge with keywords (post-level; see job-rank.R, and keywords listed in Appendix Table B5)
keywords=read.csv(paste0(dir_data,"full_sample_job_rank.csv"),stringsAsFactors = FALSE)
full_sample=merge(full_sample,keywords,by=c("title_id1","post1"),all.x=T)
dim(full_sample) # [1] 1743220      74


# define job rank
full_sample$job_rank=NA

# (1) JMC threads - created <= yr_phd
full_sample$since_phd=((2017-full_sample$yr_first)-full_sample$yr_phd)
table(full_sample$since_phd) # range from -6 to 6 
full_sample[!is.na(full_sample$yr_phd) & full_sample$since_phd %in% c(-6:-2),"job_rank"]=1 # student
full_sample[!is.na(full_sample$yr_phd) & full_sample$since_phd %in% c(-1:1),"job_rank"]=2 # JMC
full_sample[!is.na(full_sample$yr_phd) & full_sample$since_phd>1,"job_rank"]=3 # Junior Faculty
table(full_sample$job_rank)
# 1    2    3 
# 473 1999 2909 
#full_sample[!is.na(full_sample$yr_phd) & full_sample$yr_phd>=(2017-full_sample$yr_first),"job_rank"]=1 # 2,077 posts

# (2) NBER threads
table(full_sample[is.na(full_sample$job_rank),"level2016"])
# 0     1     2     3    # 2=junior, 3=senior; need to convert to four levels!
# 514   349  1029 17618

# students to students (level 1)
full_sample[is.na(full_sample$job_rank) & !is.na(full_sample$level2016) & full_sample$level2016==1,"job_rank"]=full_sample[is.na(full_sample$job_rank) & !is.na(full_sample$level2016) & full_sample$level2016==1,"level2016"]
# add 1 to faculty
full_sample[is.na(full_sample$job_rank) & !is.na(full_sample$level2016) & full_sample$level2016>=2,"job_rank"]=1+full_sample[is.na(full_sample$job_rank) & !is.na(full_sample$level2016) & full_sample$level2016>=2,"level2016"]
table(full_sample$job_rank)
# 1     2     3     4 
# 822  1999  3938 17618 


# (3) Keywords
full_sample$level_max=0
for (l in 1:5){
  full_sample$level_max[full_sample[,paste0("level",l)]>0]=l 
}
table(full_sample$level_max)
# 0         1       2       3       4       5 
# 1614165   48457   40762   11016   18978   9842
full_sample[is.na(full_sample$job_rank) & (full_sample$level_max==1),"job_rank"]=1
full_sample[is.na(full_sample$job_rank) & (full_sample$level_max==2),"job_rank"]=2
full_sample[is.na(full_sample$job_rank) & (full_sample$level_max %in% c(3:4)),"job_rank"]=3
full_sample[is.na(full_sample$job_rank) & full_sample$level_max==5,"job_rank"]=4

full_sample[is.na(full_sample$job_rank),"job_rank"]=9

table(full_sample[full_sample$ngender>0,"job_rank"]) 
# 1       2       3       4       9 
# 48117   41868   33115   26707 1575839 




############################################################################################
# missing posts (denoted by "YH0" during scraping)
sum(full_sample$raw_cat=="YH0") # [1] 38753
full_sample$post_miss=0+(full_sample$raw_cat=="YH0") 
mean(full_sample$post_miss) # 2.2%
#write.csv(full_sample[,c("title_id1","post1","post_miss")],paste0(dir_data,"full_sample2019_stata_postmiss.csv"),row.names = FALSE)

# save a .csv file to be imported into Stata
full_sample=full_sample[full_sample$ngender>0,]
names(full_sample)[35]="full_name_JMC"
names(full_sample)[42]="full_name_NBER"
select_col=c("title_id1","post1","topic","nposts","nviews","n_pos","n_neg","latest_page","time_latest_str",
             "time_first_str","yr_latest","yr_first","month_first","month_latest","post_miss","source1","source2","source_JMC",
             "jmc_id","full_name_JMC","yr_phd","school","full_name_NBER","female","acad","acad_dummy","person","person_dummy",
             "p_acad_dummy","job_rank","since_phd")
full_sample=full_sample[,select_col]
full_sample=full_sample[order(full_sample$title_id1,full_sample$post1),] # [1] 1725646      31


write.csv(full_sample,paste0(dir_data,"full_sample2019_stata.csv"),row.names = FALSE)

