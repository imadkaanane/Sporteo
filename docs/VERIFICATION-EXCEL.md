# Vérification du classeur Sportéo

- 60 240 lignes sources, 240 doublons, 120 rejets, 59 880 ventes valides.
- Les cinq montants financiers de chaque vente correspondent au centime aux CSV de référence.
- 30 000 commandes distinctes ; 192 objectifs mois-magasin.
- CA net : 10 636 885,21 EUR ; marge commerciale : 4 356 347,70 EUR.
- 92 formules Excel avec valeurs initiales conservées.
- Trois graphiques natifs, deux filtres et six tables de sortie reliées à Power Query.
- Douze requêtes M : syntaxe contrôlée par l’analyseur Microsoft.
- 65 parties XML contrôlées et toutes les cibles de relations présentes.
- Structure DataMashup vérifiée selon MS-QDEFF ; section M identique aux fichiers fournis.

L’ouverture, le recalcul et l’exécution Power Query dans Excel Desktop restent à vérifier sur cette application. Les valeurs chargées dans les tables sont des résultats précalculés et rapprochés ; elles ne sont pas présentées comme une actualisation Power Query exécutée ici.

Contrôle complémentaire : lecture des 91 valeurs numériques du tableau de bord sur une copie LibreOffice, puis recalcul forcé sans caches sur les deux cas filtrés décrits ci-dessous. Le classeur livré conserve ses composants Power Query et n’est pas remplacé par la copie LibreOffice.

Filtres contrôlés après recalcul LibreOffice : 2024/Lyon et 2025/Montpellier ; les huit indicateurs de chaque cas correspondent aux agrégations indépendantes des CSV.
