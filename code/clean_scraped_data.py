# Clean raw text data & Generate complete dataset 

import numpy as np 
import pandas as pd 
import os 
os.chdir('../data/raw')

EJR0=pd.read_csv('scraped_posts.txt',sep="\r", header=None) # loadtxt('econ.txt')

# EJR0=pd.read_csv('try.csv',sep="\r", header=None)
EJR0.shape # (3634707, 1)
EJR0.head() 
#                                                   0
#0  <url>https://www.econjobrumors.com/topic/reque...
#1  Downloaded on: Sun Oct 29 19:43:51 2017 Posted...
#2                                         Happy_Next
#3                                               Kirk
#4                                          Rep: 1450

EJR0.columns=['raw']
(EJR0['raw'].str.slice(0,11,1)=="<url>https:").sum() # no. threads
(EJR0['raw'].str.slice(0,15,1)=="Downloaded on: ").sum() # no. threads
(EJR0['raw'].str.slice(0,10,1)=="Happy_Next").sum() # no. posts

# Identify titles & generate "title_id1"
EJR0['title_id0']=EJR0['raw'].str.slice(0,11,1)=="<url>https:"
EJR0['title_id0']=EJR0['title_id0'].astype(int)
EJR0['title_id0'].sum() # should be no. threads

EJR0['title_id1']=EJR0['title_id0'].cumsum()
EJR0['title_id1'].min() # 1
EJR0['title_id1'].max() # should be no. threads

EJR0.loc[EJR0['title_id1']==6,]


# Extract time stamps "Downloaded on: ... Posted on: ..."
EJR0_time=EJR0.loc[EJR0['raw'].str.slice(0,15,1)=="Downloaded on: ",]
EJR0_time.shape
EJR0_time.to_csv("raw_time_stamp.csv")


# Identify posts: generate "post_id1" (titles would have "post_id1=1" here) 
EJR0=EJR0.loc[EJR0['raw'].str.slice(0,15,1)!="Downloaded on: "] # ok as long as consistent with line 21-22!
EJR0=EJR0.reset_index(drop=False) # reset index 
EJR0=EJR0.drop(['index'],axis=1) # drop old "index" column

EJR0['post0']=(EJR0['raw'].str.slice(0,10,1)=="Happy_Next")|(EJR0['title_id0']==1) 
EJR0['post0']=EJR0['post0'].astype(int)
EJR0['post1']=EJR0.groupby(['title_id1'])['post0'].cumsum() 
(EJR0['post1']==1).sum() # should be no. threads/titles


# Merge into one post led by "Happy_Next" & poster ID (linked by "-YH0")
raw_cat=EJR0.groupby(['title_id1','post1'])['raw'].apply(lambda x: x.str.cat(sep='-YH0-')) 
len(raw_cat) # number of Titles+Posts
type(raw_cat) # pandas.core.series.Series

raw_cat_df=pd.DataFrame(raw_cat) 
raw_cat_df.columns=['raw_cat']
raw_cat_df=raw_cat_df.reset_index(drop=False)
raw_cat_df.shape
raw_cat_df.duplicated(['title_id1','post1']).sum() # 0 ~ no duplicate title-post combination! 

raw_cat_df.to_csv("EJR0_raw_text.csv",index=False)

# Next step: clean the file above in "clean_raw_text.R"









