# Identify job rank through keywords at the post level

dir_data="..data/"

# final data set
full_sample=read.csv(paste0(dir_data,"full_sample2019.csv"),stringsAsFactors = FALSE)
print(dim(full_sample)) 
# ignore additional threads of NBER abstracts
full_sample=full_sample[!is.na(full_sample$title_id1),] 

# Keywords at each level
level1=c("research assistant","ra","graduate student","grad student","phd","ta",
         "cohort","classmate","colleague","coauthor","co author","office mate","officemate")
level2=c("candidate","job market","jmc","jmp","placement","flyout","post-doc","post doc","postdoc")
level3=c("assistant professor","assistant prof","ap","untenured","junior faculty",
         "tenure track","junior professor","junior economist","midterm review")
level4=c("tenure","tenured","associate professor","associate prof")
level5=c("full professor","full prof","chaired","endowed prof","endowed chair","senior faculty",
         "senior professor","senior economist","department chair",
         "nobel","bates clark","clark bates","clark prize","clark medal","fischer black prize")

list_levels=list(level1,level2,level3,level4,level5)

full_sample=full_sample[,c("title_id1","post1","raw_cat")]
full_sample$raw_cat=tolower(full_sample$raw_cat) # use lower case for all 

full_sample$level1=0
full_sample$level2=0
full_sample$level3=0
full_sample$level4=0
full_sample$level5=0

for (l in 1:length(list_levels)){
  print(c("level",l))
  for (w in 1:length(list_levels[[l]])){
    word=list_levels[[l]][w]
    print(c("level",l,word))
    full_sample[,paste0("level",l)]=full_sample[,paste0("level",l)]+sapply(full_sample$raw_cat,function(x) length(grep(paste0("\\b",word,"\\b"),x))
            +length(grep(paste0("\\b",word,"s\\b"),x)))
    print(summary(full_sample[,paste0("level",l)]))
  }
}


full_sample=subset(full_sample,select=-c(raw_cat))
write.csv(full_sample,paste0(dir_data,"full_sample_job_rank.csv"),row.names = FALSE)






