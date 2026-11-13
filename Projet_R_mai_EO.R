library(pls)
library(car)
library(plsVarSel)
library(knitr)

# Partie 1: Présentation et analyse exploratoire

## Prétraitement : De la donnée brute au jeu de données d'apprentissage

training <- read.table("~/Documents/training_EO.csv", 
                       header = TRUE, 
                       sep = ",", 
                       fill = TRUE, 
                       quote = "\"", 
                       dec = ".")

X <- training[, grep("^m", colnames(training))]

Y <- training$SOC

indices_ok <- !is.na(Y)
X <- X[indices_ok, ]
Y <- Y[indices_ok]

df_final <- training[, c(grep("^m", colnames(training)), which(colnames(training) == "SOC"))]

## Caractéristiques du tableau de données

n <- nrow(df_final)
p_total <- ncol(df_final)
p_x <- length(X)

## Statistiques descriptives de Y (SOC)

summary_y <- summary(Y)
summary_y

## Traitement du problème de distribution

Y_log <- log(Y + 1)

par(mfrow=c(1,2))
hist(Y, main="Distribution Originale (SOC)", 
     col="orange", xlab="Taux de Carbone", breaks=30)
hist(Y_log, main="Distribution après Log", 
     col="lightgreen", xlab="log(SOC + 1)", breaks=30)

summary_ylog <- summary(Y_log)
summary_ylog

## Visualisation des corrélations (matrice de corrélation et spectres)

X_sample <- df_final[, 500:505]
cor_matrix <- cor(X_sample)
print(round(cor_matrix, 3))

par(mfrow=c(1,1))
matplot(t(X[1:50, ]), type="l", lty=1, col=rgb(0.1, 0.1, 0.9, 0.3),
        main="Visualisation des Spectres Infrarouges (X)",
        xlab="Indices des longueurs d'onde (3578 variables)", 
        ylab="Absorbance")

legend("topright", legend="50 premiers spectres", col="blue", lty=1, cex=0.8)

# Partie 2: Régression linéaire (MCO)

## Implémentation du modèle MCO et régression

X_sub <- X[, 1:100]

data_mco <- as.data.frame(cbind(SOC_log = Y_log, X_sub)) 

model_mco <- lm(SOC_log ~ ., data = data_mco)

## Détection de la multicolinéarité via le VIF

vif_values <- vif(lm(SOC_log ~ ., data = data_mco)) 
summary(vif_values)

## Evaluation des performances 

residus <- residuals(model_mco)
rmse_mco <- sqrt(mean(residus^2))
r2_mco <- summary(model_mco)$r.squared

## Validation croisée

k <- 10 

set.seed(123)
groupes <- sample(rep(1:k, length.out = n))

erreurs_carrees <- c()

for (i in 1:k) {
  train_set <- data_mco[groupes != i, ]
  test_set  <- data_mco[groupes == i, ]
  
  modele_temp <- lm(SOC_log ~ ., data = train_set)
  
  predictions <- predict(modele_temp, newdata = test_set)
  
  err <- test_set$SOC_log - predictions
  erreurs_carrees <- c(erreurs_carrees, err^2)
}

rmse_cv_lm <- sqrt(mean(erreurs_carrees))

## Discussion sur les limitations et les points à surveiller

plot(model_mco, which = 1, 
     main = "Graphique des Résidus (MCO)\nPreuve de l'instabilité du modèle classique")


# Partie 3: Régression PLS

## Préparation des données et lancement du modèle

X_mat <- as.matrix(X)
pls_data <- data.frame(Y_log = Y_log)
pls_data$X <- I(X_mat)

model_pls <- plsr(Y_log ~ X, 
                  data = pls_data, 
                  ncomp = 49, 
                  validation = "CV", 
                  scale = TRUE)

## L'instabilité du minimum mathématique

ncomp_opt <- which.min(RMSEP(model_pls)$val[estimate="CV", , ]) - 1 

plot(model_pls, "validation", estimate = "CV", 
     main = "Évolution de l'erreur (RMSEP) selon les composantes",
     xlab = "Nombre de composantes", ylab = "RMSEP (Validation Croisée)")

var_expl <- cumsum(explvar(model_pls))
print(round(var_expl, 2))


## Perfomances

h <- 12
r2_final <- R2(model_pls, estimate="train")$val[,,h + 1]
rmse_final <- RMSEP(model_pls, estimate="CV")$val[,,h + 1]

## Visualisation des scores et loadings

par(mfrow=c(1,2))

plot(model_pls, plottype = "scores", comps = 1:2, 
     main = "Graphique des Scores",
     col = "firebrick", pch = 16)
abline(h = 0, v = 0, lty = 2)

plot(model_pls, plottype = "loadings", comps = 1:2, 
     main = "Graphique des Loadings ",
     xlab = "Indices des longueurs d'onde",
     legendpos = "topright")
abline(h = 0, lty = 2)

# Partie 4: Analyse des VIP

## Calcul des Variable Importance in Projection (VIP)

all_vips <- VIP(model_pls, opt.comp = 12)
vips_final <- all_vips

plot(vips_final, type = "l", col = "darkblue", 
     main = "Importance des Variables (VIP) - Modèle à 12 composantes",
     xlab = "Indices des longueurs d'onde", ylab = "Score VIP")
abline(h = 1, col = "red", lty = 2)

# Partie 5: Comparaison régression linéaire et PLS

## Tableau comparatif des performances

comparatif_reg <- data.frame(
  "Indicateur" = c("Nombre de Variables", "R-squared (R²)", "RMSE", "Type de Validation"),
  "MCO (Partie 2)" = c("100 (manuelles)", "0.5500", "0.6200", "Simple"),
  "PLS (Partie 3)" = c("3578 (12 comp.)", "0.9426", "0.2099", "Croisée (10-fold)")
)

kable(comparatif_reg, 
      caption = "Comparaison des performances : MCO vs PLS",
      align = "lcc")

## Comparaison des Coefficients : MCO vs PLS

par(mfrow=c(1,2))
# Coefficients MCO
plot(coef(model_mco), type="l", col="red", main="Coefficients MCO ")
# Coefficients PLS
plot(coef(model_pls, ncomp=12), type="l", col="blue", main="Coefficients PLS")

## Analyse de l'espace latent : Scores et Loadings

par(mfrow=c(1,2))

plot(model_pls, plottype = "scores", comps = 1:2, 
     col = "darkgreen", pch = 20,
     main = "Graphique des Scores (Comp 1 vs 2)")
abline(h = 0, v = 0, lty = 2, col = "grey")

plot(model_pls, plottype = "loadings", comps = 1:2, 
     lty = 1, col = c("blue", "red"),
     main = "Graphique des Loadings (Comp 1 & 2)")
abline(h = 0, lty = 2, col = "grey")
legend("topright", legend = c("Comp 1", "Comp 2"), 
       col = c("blue", "red"), lty = 1, bty = "n", cex = 0.8)

