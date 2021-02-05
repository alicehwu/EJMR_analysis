### Prepare for Analysis
## Count occurrences of words under each category in each post (Section II)
## Count occurrences of female/male classifiers in each post (Section III)

import numpy as np 
import pandas as pd 
from scipy.sparse import hstack

import os # set working directory
os.chdir('../data/') # please change accordingly
 
# Prep: Useful Functions 
# F1: save scipy compressed matrix: http://stackoverflow.com/questions/24691755/how-to-format-in-numpy-savetxt-such-that-zeros-are-saved-only-as-0/24699373#24699373
def savetxt_sparse_compact(fname, x, fmt="%.6g", delimiter=','):
    with open(fname, 'w') as fh:
        for row in x:
            line = delimiter.join("0" if value == 0 else fmt % value for value in row.A[0])
            fh.write(line + '\n')
 
# F2: given indices of VOCAB in gender/categories, output sum of word frequencies in each row (i.e., a post)
def subset_by_index(indices,npz): 
    print(type(indices)) # pandas Series or list 
    for i in range(len(indices)): 
        print(i,indices[i])
        if i==0:
            out_sum=npz.getcol(indices[i]-1) # indices starting from 1 rather than 0! 
        else:
            out_sum=out_sum+npz.getcol(indices[i]-1) # important: start from 0 
    return(out_sum)

%paste # or %cpaste 

##############################################################################################
                                    # Section I: Data # 
##############################################################################################

# (1) Load Cleaned dataset with posts and IDs
EJR_raw=pd.read_csv("raw/EJR0_raw_text_cleaned.csv") 
EJR_raw.shape # (2217046, 6)
EJR_raw.head()
list(EJR_raw) # ['title_id1', 'post1', 'raw_cat', 'post_miss', 'poster_name', 'poster_id']
EJR_raw=EJR_raw[['title_id1','post1']]

# (2) Load word count matrix (10,000 columns for the most frequent 10,000 words)
word_counts=np.load('raw/counts_Nov2017.npz',encoding='latin1')
X=word_counts['X'][()] 
type(X) # scipy.sparse.csc.csc_matrix
X.shape  # (2217046, 10000)


##############################################################################################
                 # Section II: Count by category (Prep for Topic Analysis) # 

# Vocab Categories, 11/03/2017 
# "0" "1" "1.5" "2" "2.5" "3" "4" "4.4" "4.5" "5" "6" "6.5" "7" "8" 

# 0: Irrelevant / neutral
# 1: Economics directly 
# 1.5: Econ topics related (news/research projects...)
# 2: General Academic  
# 2.5: Professional 
# 3: Emotion/Feelings/Personality
# 4: Body / Physical Appearance 
# 4.4: intellectual negative
# 4.5: intellectual neutral
# 4.6: intellectual positive
# 5: Personal (family, children, relationship etc)
# 6: Gender classifiers (rest = 1,2,3)
# 6.5: sexual
# 7: Names (gendered first names & the last names of economists are also used as gender classifiers - rest=0) & related to groups of people 
# 8: Swear words 
# exclude_names (as of 02/03/2019): remove names of famous historical figures like "Marx", and a few names that are not gendered


# Outputs:
# (i) "all_cat_2019.csv" is an intermediary file that saves words counts under each category, 
#                   in the same title-post order, but it doesn't include title and post IDs yet

# (ii) "EJR_ALL_categories_2019.csv" is the final output of this file, with word counts under each category 
#               for each post, and title_id1 + post1, through which it can be merged with the final dataset in R
##############################################################################################

cat0=pd.read_csv('vocab/category/'+"0.txt") 
indices=cat0['x'] # starting from 1 

cat_outputs=subset_by_index(indices,X) # type csc matrix; 

Cats=["1","1.5","2","2.5","3","4","4.4","4.5","4.6","5","6","6.5","7","8","exclude_names"]

from scipy.sparse import hstack

def category_sum(Cats,cat_outputs,npz):
    n=len(Cats) 
    # print(n)
    for i in range(n): 
        filename='vocab/category/'+Cats[i]+".txt"
        # print(i,filename)
        cat=pd.read_csv(filename)
        indices=cat['x'] # indices for vocab 
        outputs=subset_by_index(indices,npz) # function from earlier
        cat_outputs=hstack((cat_outputs,outputs))
    return(cat_outputs) # important indent! 

Final_cat_outputs=category_sum(Cats,cat_outputs,X) 

savetxt_sparse_compact('raw/all_cat_2019.csv', Final_cat_outputs, fmt='%.4f')

all_cats=pd.read_csv('raw/all_cat_2019.csv',header=None) 
# rename columns
all_cats.columns=all_cats.columns.astype(str) # column names from integer to string
cat_names=['X0']
for j in range(len(Cats)):
    cat_names=cat_names+['X'+Cats[j]]

all_cats.columns=cat_names[0:15]+["exclude_names"]

all_cats_for_R=pd.concat([EJR_raw,all_cats],axis=1) 

all_cats_for_R.to_csv("raw/EJR_ALL_categories_2019.csv",index=False) 



##############################################################################################
                         # Section III: Count Gender Classifiers #           

# Purpose: merge the counts of gender classifiers with full_sample in "merge_sources.R"    
# Notes: the same code was used for identifying Female/Male posts through gender classifiers,
# please see https://www.aeaweb.org/articles?id=10.1257/pandp.20181101 for replication files that 
# generate the "female0_pred" variable in "../data/gender_sample_by_classifiers/EJR_gender_dataset_Jan2018.csv"

##############################################################################################

# Call Gender Classifiers

gender=pd.read_csv("vocab/gender_classifiers.csv") 
#    index  cleaned  female  rest
#       58      he      0    1
#       87     his      0    1
#      123     her      1    1
#      128     she      1    1
#      171     him      0    1

# Get indices
female_all=gender.loc[gender["female"]==1]
female_all_index=female_all["index"]
female_all_index.index=range(len(female_all_index))

female_0=gender.loc[(gender["female"]==1) & (gender['rest']==0)]
female_0_index=female_0["index"]
female_0_index.index=range(len(female_0_index))

female_1=gender.loc[(gender["female"]==1) & (gender['rest']==1)]
female_1_index=female_1["index"]
female_1_index.index=range(len(female_1_index))

female_2=gender.loc[(gender["female"]==1) & (gender['rest']==2)]
female_2_index=female_2["index"]
female_2_index.index=range(len(female_2_index))

female_3=gender.loc[(gender["female"]==1) & (gender['rest']==3)]
female_3_index=female_3["index"]
female_3_index.index=range(len(female_3_index))

male_all=gender.loc[gender["female"]==0]
male_all_index=male_all["index"]
male_all_index.index=range(len(male_all_index))

male_0=gender.loc[(gender["female"]==0) & (gender['rest']==0)]
male_0_index=male_0["index"]
male_0_index.index=range(len(male_0_index))

male_1=gender.loc[(gender["female"]==0) & (gender['rest']==1)]
male_1_index=male_1["index"]
male_1_index.index=range(len(male_1_index))

male_2=gender.loc[(gender["female"]==0) & (gender['rest']==2)]
male_2_index=male_2["index"]
male_2_index.index=range(len(male_2_index))

male_3=gender.loc[(gender["female"]==0) & (gender['rest']==3)]
male_3_index=male_3["index"]
male_3_index.index=range(len(male_3_index))


# calling F2
fem_all_count=subset_by_index(female_all_index,X)
fem_0_count=subset_by_index(female_0_index,X)
fem_1_count=subset_by_index(female_1_index,X)
fem_2_count=subset_by_index(female_2_index,X)
fem_3_count=subset_by_index(female_3_index,X)

male_all_count=subset_by_index(male_all_index,X)
male_0_count=subset_by_index(male_0_index,X)
male_1_count=subset_by_index(male_1_index,X)
male_2_count=subset_by_index(male_2_index,X)
male_3_count=subset_by_index(male_3_index,X)


all_classifiers=hstack((fem_all_count,fem_0_count,fem_1_count,fem_2_count,fem_3_count,
    male_all_count,male_0_count,male_1_count,male_2_count,male_3_count)) # scipy.sparse.csc.csc_matrix; shape (2217046, 10)

savetxt_sparse_compact('raw/all_classifiers_2019.csv', all_classifiers, fmt='%.4f')

count_classifiers=pd.read_csv('raw/all_classifiers_2019.csv',header=None) 
# rename columns
count_classifiers.columns=count_classifiers.columns.astype(str) # column names from integer to string
count_classifiers.columns=["fem_all","fem_0","fem_1","fem_2","fem_3","male_all","male_0","male_1","male_2","male_3"]

count_classifiers=pd.concat([EJR_raw,count_classifiers],axis=1) 

count_classifiers.to_csv("raw/EJR_ALL_gender_classifiers_2019.csv",index=False)



# as of Jan 2018: a post is classified to be Female if fem_all>0 & male_all==0,
# Male if fem_all==0 & male_all>0. 
# if fem_all>0 & male_all>0, I ran a Lasso-Logistic regression with 5-fold cross validation
# to determine re-classify gender based on words other than gender classifiers. 
# The details (R & Python programs) can be found at https://www.aeaweb.org/articles?id=10.1257/pandp.20181101 



