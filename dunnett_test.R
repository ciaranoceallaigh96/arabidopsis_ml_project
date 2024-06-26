#Performs Dunnett test and Non-parametric Dunnett Tests (M-robust and MLT-Dunnett)
#From Hothorn 2019 - Robust multiple comparisons against a control group with application in toxicology

#R-3.6.3/bin/R in venv
#library import order matters
args = commandArgs(trailingOnly=TRUE)
library("broom")
library("reshape2")
library("robustbase")
library("mvtnorm")
library("TH.data")
library("multcomp")
library("nparcomp")
library("variables")
library("basefun")
library("mlt")
library("ggplot2")

#e.g  grep 'is \[' cv_grid_all_ml_312_mlma_1k_ft16.txt  | grep -v 'Variance' | grep -v 'AUC' | cut -f '2' -d '['   | cut -d ']' -f 1 #remove baseline and add gblup
sprintf(args[1])
results_table <- scan(args[1], sep=',') #just the scores separated by commas, each model on a different line with no rownames!
results_table <- matrix(results_table, ncol=4, byrow=TRUE)
rownames(results_table) <- c("gBLUP", "SVM", "RBF", "LASSO", "Ridge", "RF", "FNN", "CNN")
results_table[results_table < 0] <- 0 # convert negatiive values to 0
results_table <- melt(results_table)

#value is the results values e.g r2
#Var1 is the model names



yvar <- numeric_var("value", support=quantile(results_table$value,prob=c(.01,.99))) #MLT
bstorder <- 5 #order of Bernstein polynomical # recommednded between 5 and 10
yb <- Bernstein_basis(yvar,ui="increasing",order=bstorder) # Bernstein polynominal
ma <-ctm(yb, shifting = ~ Var1, todistr="Normal", data=results_table) # condit transf mod
m_mlt <- mlt(ma, data=results_table) # most likely transformation
K <- diag(length(coef(m_mlt))) # contrast matrix
rownames(K) <- names(coef(m_mlt))
matr <- bstorder+1
K <- K[-(1:matr),] #for order 5 Bernstein

print("SMALL SAMPLE MLT-DUNNETT")
tC <- glht(m_mlt, linfct= K, df=model_r2$.df.residual) # MLT for small sample size (t-distribution)
summary(tC)
tCMLT <- fortify(summary(tC))

num_models <- nrow(K)-1
tCMLT[,num_models]
