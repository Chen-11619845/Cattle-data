## Cattle data analysis
# The investigators are interested in evaluating the effect of treatment on cattle weight over time.
#library(jmcm)
#
# 加载cattle数据集
#data(cattle)


# 在RStudio中以表格形式查看
#View(cattle)


#citation("jmcm")
# =============================
# Variable Descriptions (cattle)
# =============================

# subject     : Cattle identifier (repeated measures within each animal, 1–60)
# weight      : Response variable — body weight (in kg or grams, depending on unit)
#               Measured at 11 time points for each cow
# treatment   : Group assignment (Treatment A or B)
#               Factor variable: "A" = Treatment A group (last 330 rows),
#                                 "B" = Treatment B group (first 330 rows)
# days        : Time variable — measurement day
#               Repeated values: 0, 14, 28, 42, 56, ..., 133 (11 time points)


# Load data
cattle <- read.table("cattle.txt",header=FALSE)
head(cattle)


#transforme the original cattle dataset into a long format 
# Define variables
Y <- cattle[,2:12]


#Transpose Y and convert it into a 660 × 1 column vector 
weight <- as.vector(matrix(t(Y),660,1))


#Create a vector of length 660 indicating the subject ID for each observation
subject <- kronecker(diag(rep(1,60)),rep(1,11))%*%seq(1:60)


#Assign treatment groups: the first 330 records are for Treatment B
treatment <- factor(c(rep("B",330),rep("A",330)))
treatment <- relevel(treatment,ref="B")


#Generate the time variable for each cow ，11 repeated time points from day 0 to day 133
days <- rep(c(0,14,28,42,56,70,84,98,112,126,133),60)

cattledata<-data.frame(subject,weight,treatment,days)
id <- cattledata$subject
uid <- unique(id)

# Visual summaries
plot(days,weight,pch=19,cex=0.25)

for (i in 1:60) {
  take=(id==uid[i])
  lines(days[take],weight[take],col=i,lwd=2)
}








library(ggplot2)

png("C:/Users/Lenovo/Desktop/cattle_weight_plot.png", width = 800, height = 600)

ggplot(cattledata, aes(x = days, y = weight, group = subject, color = treatment)) +
  geom_line(alpha = 0.4) +
  labs(title = "Weight Change Over Time by Treatment Group",
       x = "Days", y = "Weight") +
  theme_minimal()


dev.off()






library(geepack)
# Fit GEE model assuming weight increases linearly over time, without accounting for treatment effect

names(cattledata)

fit_indep <- geeglm(weight ~ days+treatment, id = subject, data = cattledata,
                    family = gaussian(), corstr = "independence")

summary(fit_indep)






fit_exch <- geeglm(weight ~ days+treatment, id = subject, data = cattledata,
                   family = gaussian(), corstr = "exchangeable")

 
summary(fit_exch)





fit_ar1 <- geeglm(weight ~ days+treatment, id = subject, data = cattledata,
                  family = gaussian(), corstr = "ar1")

summary(fit_ar1)



fit_unstr <- geeglm(weight ~ days+treatment, id = subject, data = cattledata,
                    family = gaussian(), corstr = "unstructured")


summary(fit_unstr)






# QIC comparison）
qic_values <- data.frame(
  Model = c("Independent", "Exchangeable", "AR(1)", "Unstructured"),
  QIC = c(QIC(fit_indep)["QIC"],
          QIC(fit_exch)["QIC"],
          QIC(fit_ar1)["QIC"],
          QIC(fit_unstr)["QIC"])
)

print(qic_values[order(qic_values$QIC), ])




coef_comparison <- data.frame(
  Model = c("Independent", "Exchangeable", "AR(1)", "Unstructured"),
  Estimate = c(summary(fit_indep)$coefficients["days", "Estimate"],
               summary(fit_exch)$coefficients["days", "Estimate"],
               summary(fit_ar1)$coefficients["days", "Estimate"],
               summary(fit_unstr)$coefficients["days", "Estimate"]),
  Std.err = c(summary(fit_indep)$coefficients["days", "Std.err"],
              summary(fit_exch)$coefficients["days", "Std.err"],
              summary(fit_ar1)$coefficients["days", "Std.err"],
              summary(fit_unstr)$coefficients["days", "Std.err"])
)

print(coef_comparison[order(coef_comparison$Std.err), ])







#Model Estimate Std.err
#1  Independent    0.812  0.0174
#2 Exchangeable    0.812  0.0174
#3        AR(1)    0.759  0.0186
#4 Unstructured    0.713  0.0250











# weight_ij = β0 + β1 * days_ij + β2 * treatment_i + β3 * (days_ij × treatment_i) + ε_ij

# 1. Independence correlation structure
fit_interaction_indep <- geeglm(weight ~ days * treatment,
                                id = subject,
                                data = cattledata,
                                family = gaussian(),
                                corstr = "independence")
summary(fit_interaction_indep)

#Coefficients:
#  Estimate  Std.err     Wald Pr(>|W|)
#(Intercept)     225.2897   1.9684 13100.19   <2e-16
#days              0.8268   0.0226  1335.08   <2e-16
#treatmentA        3.7591   2.8523     1.74     0.19
#days:treatmentA  -0.0303   0.0347     0.76     0.38

#(Intercept)     ***
#  days            ***
# treatmentA         
#days:treatmentA    
#---
# Signif. codes:  
#  0 ‘***’ 0.001 ‘**’ 0.01 ‘*’ 0.05 ‘.’ 0.1 ‘ ’ 1

#Correlation structure = independence 
#Estimated Scale Parameters:
  
# Estimate Std.err
#(Intercept)      308    35.4
#Number of clusters:   60  Maximum cluster size: 11 

QIC(fit_interaction_indep)


# β0 (Intercept) = 225.29: Represents the average baseline weight (at day 0) for the control group.
# β1 (days effect) = 0.827:Indicates that for the control group, the average body weight increases by approximately 0.83 kg for each additional day.

#conclusion
# The p-values for the coefficient of days are all smaller than 0.05 across all models.
# a. The average body weight of cattle increases significantly over the study period (day 0 to 133).
# b. The interaction term between treatment and days is not statistically significant (p = 0.38), 
#    suggesting that the rate of weight gain over time does not differ significantly between treatment groups.
# c. The main effect of treatment is also not statistically significant (p = 0.19), 
#    indicating no strong evidence that average weight differs between treatment A and B.





coefs <- summary(fit_interaction_indep)$coefficients
estimates <- coefs[, "Estimate"]
std_errs <- coefs[, "Std.err"]

# 95% confidence interval
conf_int <- data.frame(
  Term = rownames(coefs),
  Estimate = estimates,
  CI_lower = estimates - 1.96 * std_errs,
  CI_upper = estimates + 1.96 * std_errs,
  p_value = coefs[, "Pr(>|W|)"]
)

print(conf_int)

#Term  Estimate CI_lower  CI_upper
#1     (Intercept) 225.28969 221.4317 229.14766
#2            days   0.82684   0.7825   0.87119















# 2. Exchangeable correlation structure
fit_interaction_exch <- geeglm(weight ~ days * treatment,
                               id = subject,
                               data = cattledata,
                               family = gaussian(),
                               corstr = "exchangeable")
summary(fit_interaction_exch)







#是否加入交互项
fit_treatment <- geeglm(weight ~ days + treatment, 
                        id = subject, 
                        data = cattledata,
                        family = gaussian(), 
                        corstr = "exchangeable")  

fit_full <- geeglm(weight ~ days * treatment, 
                   id = subject, 
                   data = cattledata,
                   family = gaussian(), 
     
                                 corstr = "exchangeable")
#model comparison
anova(fit_treatment, fit_full)  


#Analysis of 'Wald statistic' Table

#Model 1 weight ~ days * treatment 
#Model 2 weight ~ days + treatment
#Df    X2 P(>|Chi|)
#1  1 0.762      0.38


#A Wald test was performed to evaluate whether including an interaction term between time and treatment group significantly improved model fit. The resulting p-value ($p = 0.38$) indicated that the interaction term was not statistically significant. Therefore, the simpler additive model was retained for analysis.



#导师给的画图部分：需要更改为类似形式
#ggplot(Data, aes(x = week, y = cd4, group = patid, color = factor(trtarm))) +
#geom_line(size = 1) +
#  geom_point(size = 1) +
#  facet_wrap(~ trtarm, ncol = 3, labeller = label_both) +
#  labs(
#    title = "Longitudinal CD4 Trajectories by Patient",
#    x = "Week",
#    y = "CD4 Count"
#  ) +
#  theme_minimal() +
#  theme(legend.position = "none")  # <-- Removes legend





# 创建绘图对象并存为变量
p <- ggplot(cattledata, aes(x = days, y = weight, group = subject, color = treatment)) +
  geom_line(alpha = 0.6) +   # 每个牛的体重变化曲线
  geom_point(alpha = 0.6) +  # 每次测量点
  facet_wrap(~ treatment, ncol = 2) + 
  labs(
    title = "Longitudinal Cattle Weight trace by Treatment Group",
    x = "Days Since Start of Trial",
    y = "Weight"
  ) +
  theme_minimal() +
  theme(legend.position = "none")   # 去掉图例，分面标题即可说明组别


ggsave(
  filename = "C:/Users/Lenovo/Desktop/cattle_weight_plot_faceted.pdf",
  plot = p,
  width = 8,
  height = 5
)


