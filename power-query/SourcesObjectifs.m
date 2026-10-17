// Un objectif par mois et magasin, jamais un objectif par vente.
let
    Source = Excel.CurrentWorkbook(){[Name="Source_Objectifs"]}[Content],
    Types = Table.TransformColumnTypes(Source, {{"Date", type date}, {"Magasin_ID", type text}, {"Objectif_CA", Currency.Type}, {"Objectif_taux_marque", type number}}, "en-US")
in Types
