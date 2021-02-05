* Static Analysis of the EJMR gender data 
* Alice Wu 
* Edited in May 2019

clear
set more off
capture log close

local dir_data="../data/" // please change directories of data and output accordingly
local dir_output="../results_static/"



/*
** Import the .csv file (cleaned up in R) into stata and save as .dta
import delimited "`dir_data'full_sample2019_stata.csv",case(preserve)

foreach var of varlist female month_first month_latest jmc_id yr_phd since_phd{
	destring `var',ignore("NA") replace
}
sort title_id1 post1
save "`dir_data'full_sample2019_stata.dta",replace
*/



* codebook
log using "`dir_output'codebook_dta.log",replace
use "`dir_data'full_sample2019_stata_final.dta"
count 
desc, full
tab female 
tab job_rank 
tab1 source*
log close


********************************************************************************
* Static Analysis * 

/* 
(1) the program "summary_stats" generates a log file that breaks down the sample by gender, 
and analyzes topic differences between Female and Male posts. The results for the full gender sample, 
and for each job rank, corresponds to results in Table 1-2, Figures 3-4 

(2) 
*/
********************************************************************************

*** (1) Summary Statistics & Topic Differences
program drop _all
program define summary_stats 
syntax,job(integer) // 0 if full gender sample; otherwise, specify a job rank from 1 to 4 

	preserve
	
	keep if post_miss!=1 // nonmissing posts only (vacuous assumption b/c gendered posts here)
	
	if `job'!=0{
		keep if job_rank==`job'
	}

	log using "`dir_output'/summary_stats_`job'.log",replace
	count 
	disp "Before August 2017"
	tab female if month_first>=3 // including month_first==. (>=1 year)
	gen temp_f=(female==1 & month_first>=3)
	gen temp_m=(female==0 & month_first>=3)
	bysort title_id1: egen nfemale=sum(temp_f) // restrict to a given job level
	bysort title_id1: egen nmale=sum(temp_m) 
	bysort title_id1: gen uniq_thread=_n
	count if uniq_thread==1 & month_first>=3 & (nfemale>0|nmale>0)
	count if uniq_thread==1 & nfemale>0 & month_first>=3 
	count if uniq_thread==1 & nmale>0 & month_first>=3
	drop uniq_thread
	
	* topic differences (clustered at the thread level)
	foreach var of varlist acad person acad_dummy person person_dummy p_acad_dummy{
		reg `var' female if month_first>=3,robust cluster(title_id1) 
		lincom female+_cons
	}

	disp "*************************************************************************"
	disp "After August 2017"
	tab female if month_first<3 
	drop nfemale nmale temp_f temp_m
	gen temp_f=(female==1 & month_first<3)
	gen temp_m=(female==0 & month_first<3)
	bysort title_id1: egen nfemale=sum(temp_f) // restrict to a given job level
	bysort title_id1: egen nmale=sum(temp_m) 
	bysort title_id1: gen uniq_thread=_n
	count if uniq_thread==1 & month_first<3
	count if uniq_thread==1 & nfemale>0 & month_first<3 
	count if uniq_thread==1 & nmale>0 & month_first<3
	drop uniq_thread

	* topic differences (clustered at the thread level)
	foreach var of varlist acad person acad_dummy person person_dummy p_acad_dummy{
		disp "Dependent Variable: `var'"
		reg `var' female if month_first<3,robust cluster(title_id1) 
		lincom female+_cons
	}
	log close

	restore
end

summary_stats,job(0) // all Female and Male posts (full gender sample)
summary_stats,job(1) // Female and Male posts at Grad Students level
summary_stats,job(2) // Female and Male posts at JMCs/Post-docs level
summary_stats,job(3) // Female and Male posts at Junior Faculty level
summary_stats,job(4) // Female and Male posts at Senior Faculty level


*** (2) Topic Differences by Month 
* prepare for trend plots (sample means and SEs) -- Figure 2 
preserve
collapse (mean) acad person (semean) se_acad=acad se_person=person, by(female month_first)
rename acad mean_acad
rename person mean_person
drop if month_first==. 
export delimited "`dir_output'topic-diff-by-month.csv",replace
restore

* I read this file in R and generated Figure 2 (see "figures/figure2_topic_diff.R")



