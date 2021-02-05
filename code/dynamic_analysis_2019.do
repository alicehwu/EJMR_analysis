clear 
set more off
capture log close

local dir_data="../data/"
local dir_output="../results_dynamic/"

use "`dir_data'full_sample2019_stata_final.dta"

* gender neutral ("Genderless") as base
replace female=2 if female==. 


*** (1) Initial Conditions of Threads: title and the first post (assumed to be written by the same poster who started the thread)
* titles 
sort title_id1 post1
bysort title_id1: gen title_female=female[1]
bysort title_id1: gen title_acad=acad[1]
bysort title_id1: gen title_acad_dummy=acad_dummy[1]
bysort title_id1: gen title_person=person[1]
bysort title_id1: gen title_person_dummy=person_dummy[1]
gen title_p_acad_dummy=(title_acad_dummy==1 & title_person_dummy==0)

* first posts
sort title_id1 post1
bysort title_id1: gen first_female=female[2]
bysort title_id1: gen first_acad=acad[2]
bysort title_id1: gen first_acad_dummy=acad_dummy[2]
bysort title_id1: gen first_person=person[2]
bysort title_id1: gen first_person_dummy=person_dummy[2]
gen first_p_acad_dummy=(first_acad_dummy==1 & first_person_dummy==0)

* initial job rank
sort title_id1 post1
bysort title_id1: gen title_job_rank=job_rank[1]
bysort title_id1: gen first_job_rank=job_rank[2]

gen initial_rank=max(title_job_rank,first_job_rank)
tab title_job first_job if post1==1
tab initial_rank if post1==1


*** (2) Thread-level Statistics 
* no. posts in the scraped data set
bysort title_id1: gen nposts_data=_N-1
count if nposts_data==0
replace nposts_data=1 if nposts_data==0 

* no. female or male posts
gen temp_f=(female==1)
gen temp_m=(female==0)
bysort title_id1: egen nfemale=sum(temp_f)
replace nfemale=nfemale-1 if title_female==1 // do not consider title as a post 
bysort title_id1: egen nmale=sum(temp_m)
replace nmale=nmale-1 if title_female==0 

drop temp_*

gen ngender=nfemale+nmale 
tab title_female if ngender==0 // title is gendered! 
replace ngender=ngender+1 if inlist(title_female,0,1)

/*
gen gender_diff=(nfemale-nmale)/nposts_data
sum gender_diff,det
xtile gender_diff_bin=gender_diff,n(4)
tab gender_diff_bin,sum(gender_diff) // [-1,-0.25], (-0.25,-0.125],(-0.04,1]
*/

foreach var of varlist acad acad_dummy person person_dummy p_acad_*{
	bysort title_id1: egen temp_`var'=sum(`var')
	replace temp_`var'=temp_`var'-title_`var'
	gen group_`var'=temp_`var'/nposts_data
	drop temp_`var'
}


gen first_page=(post1<=21) // 88% posts on first pages; 12% from the last pages if >1 s
tab first_page
count if first_page==0 & latest_page==2 // about 70% of those from last pages directly follow first pages

count if nposts<nposts_data 
replace nposts=nposts_data if nposts<nposts_data
gen ln_nposts=log(nposts) // using total number of posts in a given thread, not just the no. posts scraped

* define post2 = no. previous posts
gen post2=post1-2 // excluding title and current post
replace post2=post2+(nposts-nposts_data) if first_page==0 // retrieve post ID in original thread (count the posts not scraped between first and last pages)
gen ln_post2=log(post2)


sort title_id1 post1 

bysort title_id1: gen post_miss_lag=post_miss[_n-1]
replace post_miss_lag=1 if post1==22 & latest_page>=3 // first post on the last page, if the latest page>=3

foreach var of varlist female job_rank acad acad_dummy person person_dummy p_acad*{
	sort title_id1 post1 
	bysort title_id1:gen `var'_lag=`var'[_n-1]

	* discontinuity between last post on 1st page and first post on last page if #pages>=3
	replace `var'_lag=. if post1==2 // bet. titles and first post
	replace `var'_lag=. if post1==22 & latest_page>=3	
}

*** (3) Define Discrete States of Topics
gen title_state=3
replace title_state=1 if title_p_acad_dummy==1
replace title_state=2 if title_person_dummy==1


gen transition=. 
replace transition=1  if p_acad_dummy==1 & p_acad_dummy_lag==1 
replace transition=2  if person_dummy==1 & p_acad_dummy_lag==1 
replace transition=3  if p_acad_dummy==0 & person_dummy==0 & p_acad_dummy_lag==1 
replace transition=4  if p_acad_dummy==1 & person_dummy_lag==1 
replace transition=5  if person_dummy==1 & person_dummy_lag==1 
replace transition=6  if p_acad_dummy==0 & person_dummy==0 & person_dummy_lag==1 
replace transition=7  if p_acad_dummy==1 & p_acad_dummy_lag==0 & person_dummy_lag==0
replace transition=8  if person_dummy==1 & p_acad_dummy_lag==0 & person_dummy_lag==0
replace transition=9  if p_acad_dummy==0 & person_dummy==0  & p_acad_dummy_lag==0 & person_dummy_lag==0



* by length 
preserve
keep if month_first>=3
log using "/accounts/grad/haowen.wu/Documents/EJR-revise/dynamic/AME-by-length.log",replace 
mlogit transition ib(2).female_lag ib(2).female_lag##ib(2).title_female ib(2).female_lag##ib(1).title_p_acad_d ///
	ib(2).female_lag##ib(0).title_person_dummy ib(2).female_lag##ib(2).first_female ib(2).female_lag##ib(1).first_p_acad ///
	ib(2).female_lag##ib(0).first_person_dummy ib(2).female_lag##c.group_p_acad_d ib(2).female_lag##c.group_person_d ///
	ib(2).female_lag##ib(9).job_rank_lag ib(2).female_lag##c.ln_post2 if p_acad_dummy_lag==1 & post_miss_lag!=1 & post_miss!=1, base(3) cluster(title_id1) robust	

_pctile ln_post2 if p_acad_dummy_lag==1 & post_miss_lag!=1 & post_miss!=1, nq(10)
return list
margins,dydx(i.female_lag) at(ln_post2=(0 `r(r1)' `r(r2)' `r(r3)' `r(r4)' `r(r5)' `r(r6)' `r(r7)' `r(r8)' `r(r9)'))
	
log close
restore


program drop _all
program define model_transition
syntax, job(int) // input 0 here 

	preserve
	if `job'>0{
		tab title_job first_job if post1==1
		tab initial_rank if post1==1
		
		keep if job_rank_lag==`job' // round0: using post-level job rank
		*keep if initial_rank==`job' // thread-level
	}
	
	disp "From Purely Professional"
	mlogit transition ib(2).female_lag ib(2).female_lag##ib(2).title_female ib(2).female_lag##ib(1).title_p_acad_d ///
	ib(2).female_lag##ib(0).title_person_dummy ib(2).female_lag##ib(2).first_female ib(2).female_lag##ib(1).first_p_acad ///
	ib(2).female_lag##ib(0).first_person_dummy ib(2).female_lag##c.group_p_acad_d ib(2).female_lag##c.group_person_d ///
	ib(2).female_lag##ib(9).job_rank_lag ib(2).female_lag##c.ln_post2 if p_acad_dummy_lag==1 & post_miss_lag!=1 & post_miss!=1, base(3) cluster(title_id1) robust	

	* Main Results (Figure 5)
	disp "average ME" 
	margins, dydx(i.female_lag)
	
	* by Length of Thread (Figure 6)
	_pctile ln_post2 if p_acad_dummy_lag==1 & post_miss_lag!=1 & post_miss!=1, nq(10)
	return list
	margins,dydx(i.female_lag) at(ln_post2=(0 `r(r1)' `r(r2)' `r(r3)' `r(r4)' `r(r5)' `r(r6)' `r(r7)' `r(r8)' `r(r9)'))
	
	
	* Heterogeneity
	* by Job Rank (Figure 7)
	disp "*** Margins along Job Ladder ***"
	disp "Students"
	margins, dydx(i.female_lag) at(job_rank_lag==1)
	disp "JMC/Postdoc"
	margins, dydx(i.female_lag) at(job_rank_lag==2)
	disp "Junior Faculty"
	margins, dydx(i.female_lag) at(job_rank_lag==3)
	disp "Senior Faculty"
	margins, dydx(i.female_lag) at(job_rank_lag==4)
	
	* by Initial Characteristics (Table 4)
	disp "*** Margins under Different Initial Conditions ***"
	margins, dydx(i.female_lag) at(title_female=2 title_p_acad_d=1) 
	margins, dydx(i.female_lag) at(title_female=1 title_p_acad_d=1) 
	margins, dydx(i.female_lag) at(title_female=0 title_p_acad_d=1) 
	margins, dydx(i.female_lag) at(title_female=2 title_person_d=1)
	margins, dydx(i.female_lag) at(title_female=1 title_person_d=1) 
	margins, dydx(i.female_lag) at(title_female=0 title_person_d=1) 
	
	
	disp "***************************************************************"

	disp "From Personal"
	mlogit transition ib(2).female_lag ib(2).female_lag##ib(2).title_female ib(2).female_lag##ib(1).title_p_acad_d ///
	ib(2).female_lag##ib(0).title_person_dummy ib(2).female_lag##ib(2).first_female ib(2).female_lag##ib(1).first_p_acad ///
	ib(2).female_lag##ib(0).first_person_dummy ib(2).female_lag##c.group_p_acad_d ib(2).female_lag##c.group_person_d ///
	ib(2).female_lag##ib(9).job_rank_lag ib(2).female_lag##c.ln_post2 if person_dummy_lag==1 & post_miss_lag!=1 & post_miss!=1, base(6) cluster(title_id1) robust	

	
	* Main Results (Figure 5)
	disp "average ME"
	margins, dydx(i.female_lag)
	
	* Heterogeneity
	* by Job Rank (Figure 7)
	disp "*** Margins along Job Ladder ***"
	disp "Students"
	margins, dydx(i.female_lag) at(job_rank_lag==1)
	disp "JMC/Postdoc"
	margins, dydx(i.female_lag) at(job_rank_lag==2)
	disp "Junior Faculty"
	margins, dydx(i.female_lag) at(job_rank_lag==3)
	disp "Senior Faculty"
	margins, dydx(i.female_lag) at(job_rank_lag==4)
	
	* by Initial Conditions (Table 4)
	disp "*** Margins under Different Initial Conditions ***"
	margins, dydx(i.female_lag) at(title_female=2 title_p_acad_d=1) 
	margins, dydx(i.female_lag) at(title_female=1 title_p_acad_d=1) 
	margins, dydx(i.female_lag) at(title_female=0 title_p_acad_d=1) 
	margins, dydx(i.female_lag) at(title_female=2 title_person_d=1)
	margins, dydx(i.female_lag) at(title_female=1 title_person_d=1) 
	margins, dydx(i.female_lag) at(title_female=0 title_person_d=1)
	
	disp "***************************************************************"
	disp "From Others"
	mlogit transition ib(2).female_lag ib(2).female_lag##ib(2).title_female ib(2).female_lag##ib(1).title_p_acad_d ///
	ib(2).female_lag##ib(0).title_person_dummy ib(2).female_lag##ib(2).first_female ib(2).female_lag##ib(1).first_p_acad ///
	ib(2).female_lag##ib(0).first_person_dummy ib(2).female_lag##c.group_p_acad_d ib(2).female_lag##c.group_person_d ///
	ib(2).female_lag##ib(9).job_rank_lag ib(2).female_lag##c.ln_post2 if p_acad_dummy_lag==0 & person_dummy_lag==0 & post_miss_lag!=1 & post_miss!=1, base(9) cluster(title_id1) robust	

	* Main Results (Figure 5)
	disp "average ME"
	margins, dydx(i.female_lag)
	
	* Heterogeneity
	* by Job Rank (Figure 7)
	disp "*** Margins along Job Ladder ***"
	disp "Students"
	margins, dydx(i.female_lag) at(job_rank_lag==1)
	disp "JMC/Postdoc"
	margins, dydx(i.female_lag) at(job_rank_lag==2)
	disp "Junior Faculty"
	margins, dydx(i.female_lag) at(job_rank_lag==3)
	disp "Senior Faculty"
	margins, dydx(i.female_lag) at(job_rank_lag==4)
	
	* by Initial Conditions (Table 4)
	disp "*** Margins under Different Initial Conditions ***"
	margins, dydx(i.female_lag) at(title_female=2 title_p_acad_d=1) 
	margins, dydx(i.female_lag) at(title_female=1 title_p_acad_d=1) 
	margins, dydx(i.female_lag) at(title_female=0 title_p_acad_d=1) 
	margins, dydx(i.female_lag) at(title_female=2 title_person_d=1)
	margins, dydx(i.female_lag) at(title_female=1 title_person_d=1) 
	margins, dydx(i.female_lag) at(title_female=0 title_person_d=1)
	
	restore
end



* if bet. August and October 2017
preserve
keep if month_first<3
log using "`dir_output'mlogit-full-after-Aug2017.log",replace
model_transition,job(0)
log close
restore

* Main results focusing on data before August 2017
keep if month_first>=3
count
log using "`dir_output'mlogit-full-before-Aug2017.log",replace
model_transition,job(0)
log close




