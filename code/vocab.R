# this file reads the 10,000 most frequent words, 
# tabulate by category, female (gender classifiers)
# for each category, it outputs a .txt file with list of indices of words under this category

dir_data="../data/vocab/"

vocab10K=read.csv(paste0(dir_data,"cleaned_vocab.csv"),stringsAsFactors = FALSE)

# Categories (Appendix Table B4)
table(vocab10K$category)
# 0     1    1.5    2  2.5    3    4  4.4  4.5  4.6    5    6  6.5    7    8 
# 6960  140  254 1295  180  121  112  124   32  105  121   72   62  356   66 
sum(table(vocab10K$category)) # 10,000
# 0: common words, counted under Others in Tab B4
# 1 & 1.5: Economics
# 2: Academic General 
# 2.5: Professional 
# 3: emotions 
# 4: Physical Attributes
# 4.4: intellectual negative
# 4.5: intellectual neutral
# 4.6: intellectual positive 
# 5: Personal Info/Family
# 6: gender pronouns & identities
# 6.5: gender-related, but not used as gender classifiers (e.g.,"sexual"); counted under Others in Tab B4
# 7: words related to people, counted under Others in Tab B4
# 8: swear words 

# Gender classifiers (Appendix Table B1)
table(vocab10K$female)
# 0   1 
# 204  53 


# Generate lists by category: brought this back to Python to count the number of words under each category in each post
n=matrix(NA,nrow=1,ncol=nlevels(as.factor(vocab10K$category))) # [1]  1 15
for (i in 1:dim(n)[2]){
  l=levels(as.factor(vocab10K$category))[i]
  print(l)
  n[i]=length(which(vocab10K$category==l))
  cat_indices=which(vocab10K$category==l)
  write.csv(cat_indices,paste0(dir_data,"category/",l,".txt"),row.names=FALSE)
}
sum(n) # [1] 10000

