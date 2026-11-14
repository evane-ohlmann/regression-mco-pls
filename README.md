# Régression MCO vs régression PLS : prédire le carbone organique des sols

Comparaison de deux méthodes de régression sur des données de **très grande dimension** : plus de variables que d'observations, et des variables très corrélées entre elles.

> Projet réalisé en binôme par **Evane Ohlmann** et **Aissatou Ndiaye**, en R (R Markdown).

---

## La question

Peut-on prédire le carbone organique d'un sol à partir de son spectre infrarouge ? Et quelle méthode de régression convient quand les variables sont plus nombreuses que les observations ?

## Les données

- **Source** : projet AfSIS (*Africa Soil Information Service*), compétition Kaggle *Africa Soil Property Prediction Challenge*.
- **Observations** : 1 157 échantillons de sol.
- **Variables explicatives** : 3 578 mesures d'absorbance infrarouge, une par nombre d'onde (colonnes dont le nom commence par `m`).
- **Cible** : le carbone organique du sol (`SOC`). Dans ce jeu de données, la cible est fournie **standardisée**, d'où des valeurs négatives.

Les données ne sont pas incluses dans ce dépôt. Pour reproduire l'analyse, télécharger le fichier `training.csv` depuis la page de la compétition sur Kaggle et le placer à la racine du projet.

## La démarche

| Étape | Contenu |
|---|---|
| 1. Analyse exploratoire | Transformation `log(SOC + 1)` pour corriger l'asymétrie, mise en évidence de la multicolinéarité |
| 2. Régression MCO | Modèle sur 100 variables, diagnostic par le VIF, validation croisée à 10 blocs codée à la main |
| 3. Régression PLS | Modèle sur les 3 578 variables, choix du nombre de composantes, scores et loadings |
| 4. Scores VIP | Identification des zones du spectre les plus utiles à la prédiction |
| 5. Comparaison | Performances, stabilité des coefficients, choix de la méthode |

## Principaux résultats

| Indicateur | MCO (100 variables) | PLS (12 composantes) |
|---|---|---|
| R² (données d'apprentissage) | 0,55 | 0,94 |
| RMSE (validation croisée) | 0,62 | 0,21 |
| VIF | de 1,6 million à 11 milliards | sans objet |

- **La régression MCO est instable** : avec des VIF de plusieurs millions, ses coefficients prennent des valeurs extrêmes et oscillantes.
- **La régression PLS divise l'erreur de prédiction par trois**, en résumant les 3 578 variables en 12 composantes construites pour être liées à la cible.
- **Les scores VIP** montrent que l'essentiel de l'information se situe dans la seconde moitié du spectre (au-delà de l'indice 1 800).

## Recul critique

En reprenant ce projet, plusieurs points méritent d'être nuancés :

- **La comparaison est un peu défavorable aux MCO** : les 100 variables retenues sont les 100 premières du spectre, qui font partie des moins informatives d'après les scores VIP.
- **Le nombre de composantes a été choisi sur la variance des variables explicatives**, alors qu'un critère fondé sur l'erreur de prédiction en validation croisée serait plus adapté (par exemple `selectNcomp(..., method = "onesigma")`).
- **Les R² sont calculés sur les données d'apprentissage** : un R² en validation croisée serait plus représentatif de la performance sur de nouvelles données.

## Compétences mises en œuvre

- Régression linéaire et diagnostic de la multicolinéarité (VIF)
- Réduction de dimension supervisée (régression PLS)
- Validation croisée, codée à la main et avec le package `pls`
- Importance des variables (scores VIP)
- Rapport reproductible en R Markdown

## Reproduire l'analyse

```r
install.packages(c("pls", "plsVarSel", "rmarkdown"))
```

1. Placer `training.csv` à la racine du projet.
2. Ouvrir le projet dans RStudio (*File > Open Project*).
3. Compiler le fichier R Markdown avec le bouton *Knit*.

## Structure du dépôt

```
├── README.md
├── regression_mco_pls.Rmd    # code et analyse
└── regression_mco_pls.pdf    # rapport compilé
```
