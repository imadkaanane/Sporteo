# Transformations Power Query

Les douze requêtes sont intégrées au classeur Excel. Les fichiers .m permettent de consulter et de réutiliser chaque transformation. Section1.m contient la section complète ; les autres fichiers contiennent une formule de requête individuelle.

Dans Excel Desktop : Données > Requêtes et connexions, puis clic droit > Modifier. Les quatre tables Source_ sont embarquées dans le classeur ; aucun chemin externe ni serveur n’est utilisé. Après remplacement des sources, lancer Actualiser tout et attendre la fin de l’actualisation avant de lire le tableau de bord.

Les premières occurrences sont déterminées par un index source, les dates impossibles sont rejetées, les montants utilisent des centimes entiers et les objectifs sont joints au grain mois-magasin.

Référence : https://learn.microsoft.com/en-us/openspecs/office_file_formats/ms-qdeff/22557f6d-7c29-4554-8fe4-7b7a54ac7a2b
