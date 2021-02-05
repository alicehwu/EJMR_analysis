# this R file generates Figure 2

dir_static="../static/"
dir_plot="../figures/"

library(ggplot2)

############################################################################################
# Trend Plots (Figure 2)
## import sample Means and SEs by month_first (Start month of a thread)
topic_by_month=read.csv(paste0(dir_static,"topic-diff-by-month.csv"),stringsAsFactors = FALSE)
topic_by_month=topic_by_month[!is.na(topic_by_month$female),]

# sort and add dates
topic_by_month=topic_by_month[order(topic_by_month$female,topic_by_month$month_first),]
topic_by_month$date=rep(seq(as.Date("2017-10-01"),as.Date("2016-11-01"),by="-1 month"),2)

# (a) Academic/Professional Topic
p_acad=ggplot(topic_by_month,aes(x=date))+
  geom_point(aes(y=mean_acad,color=as.factor(female),shape=as.factor(female)),size=1.5)+
  geom_errorbar(aes(ymin=mean_acad-1.96*se_acad, ymax=mean_acad+1.96*se_acad,color=as.factor(female)),width=5,size=0.3,alpha=0.6)+
  geom_line(aes(y=mean_acad,color=as.factor(female),linetype=as.factor(female)),alpha=0.6)+
  geom_vline(xintercept = as.numeric(as.Date("2017-08-01")), linetype="dashed",color="grey", size=0.5)+
  scale_color_manual(values=c("gray26","gray26"),labels=c("Male","Female"))+
  scale_linetype_manual(values=c("longdash","solid"),labels=c("Male","Female"))+
  scale_shape_discrete(labels=c("Male","Female"))+
  scale_x_date(date_breaks="1 month",date_labels =  "%b %Y")+ # change to 1 month label 
  scale_y_continuous(breaks=seq(0,5,by=0.5),limits=c(0,5))+
  xlab("Start Month of a Thread")+ylab("Mean No. Academic/Professional terms")+
  theme(legend.position="bottom",legend.title=element_blank(),legend.key=element_blank(), 
        panel.background = element_blank(),
        axis.line = element_line(colour = "gray"),axis.title=element_text(size=10),
        axis.text.x=element_text(angle = 90,vjust=-0.005,size=8)) 

ggsave(paste0(dir_plot,"figure2_acad_by_month_first_1yr.pdf"),p_acad,width=6,height=4.5)

# (b) Personal/Physical Topic
p_person=ggplot(topic_by_month,aes(x=date))+
  geom_point(aes(y=mean_person,color=as.factor(female),shape=as.factor(female)),size=1.5)+
  geom_errorbar(aes(ymin=mean_person-1.96*se_person, ymax=mean_person+1.96*se_person,color=as.factor(female)),width=5,size=0.3,alpha=0.6) +
  geom_line(aes(y=mean_person,color=as.factor(female),linetype=as.factor(female)),alpha=0.6)+
  geom_vline(xintercept = as.numeric(as.Date("2017-08-01")), linetype="dashed",color="grey", size=0.5)+
  scale_color_manual(values=c("gray26","gray26"),labels=c("Male","Female"))+
  scale_linetype_manual(values=c("longdash","solid"),labels=c("Male","Female"))+
  scale_shape_discrete(labels=c("Male","Female"))+
  scale_x_date(date_breaks="1 month",date_labels =  "%b %Y")+ # changed to 1 month
  scale_y_continuous(breaks=seq(0,1.5,by=0.25),limits=c(0,1.5))+
  xlab("Start Month of a Thread")+ylab("Mean No. Personal/Physical terms")+
  theme(legend.position="bottom",legend.title=element_blank(),legend.key=element_blank(), 
        panel.background = element_blank(),
        axis.line = element_line(colour = "gray"),axis.title=element_text(size=10),
        axis.text.x=element_text(angle = 90,vjust=-0.005,size=8))


ggsave(paste0(dir_plot,"figure2_person_by_month_first_1yr.pdf"),p_person,width=6,height=4.5) # need to remove "alpha=0.5" in errorbar



