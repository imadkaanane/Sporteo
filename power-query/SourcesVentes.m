// Lire la table source embarquée, sans chemin propre à un ordinateur.
let
    Source = Excel.CurrentWorkbook(){[Name="Source_Ventes"]}[Content],
    Types = Table.TransformColumnTypes(Source, {{"Ligne_ID", type text}, {"Commande_ID", type text}, {"Date", type text}, {"Magasin_ID", type text}, {"Produit_ID", type text}, {"Client_ID", type text}, {"Canal", type text}, {"Quantite", Int64.Type}, {"Prix_unitaire", type number}, {"Remise_taux", type number}, {"Quantite_retournee", Int64.Type}, {"Cout_unitaire", type number}}, "en-US"),
    Ordre = Table.AddIndexColumn(Types, "Ordre_source", 0, 1, Int64.Type)
in
    Ordre
