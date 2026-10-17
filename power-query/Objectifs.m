// Agréger les faits avant la jointure pour ne pas multiplier les objectifs.
let
    ObjectifsUniques = if Table.RowCount(SourcesObjectifs) = Table.RowCount(Table.Distinct(SourcesObjectifs, {"Date", "Magasin_ID"})) then SourcesObjectifs else error "Objectif mois-magasin duplique",
    Mois = Table.AddColumn(ObjectifsUniques, "Mois", each Date.ToText([Date], "yyyy-MM", "en-US"), type text),
    Totaux = Table.Group(Ventes, {"Magasin_ID", "Mois"}, {{"CA_net", each List.Sum([CA_net]), Currency.Type}}),
    VentesGroupees = Table.NestedJoin(Mois, {"Magasin_ID", "Mois"}, Totaux, {"Magasin_ID", "Mois"}, "VentesMois", JoinKind.LeftOuter),
    Montant = Table.ExpandTableColumn(VentesGroupees, "VentesMois", {"CA_net"}),
    Zero = Table.ReplaceValue(Montant, null, 0, Replacer.ReplaceValue, {"CA_net"}),
    Magasin = Table.NestedJoin(Zero, {"Magasin_ID"}, SourcesMagasins, {"Magasin_ID"}, "RefMagasin", JoinKind.LeftOuter),
    Nom = Table.ExpandTableColumn(Magasin, "RefMagasin", {"Magasin"}),
    Annee = Table.AddColumn(Nom, "Annee", each Date.Year([Date]), Int64.Type),
    Atteinte = Table.AddColumn(Annee, "Atteinte_CA", each if [Objectif_CA] = 0 then null else [CA_net] / [Objectif_CA], type number),
    Ecart = Table.AddColumn(Atteinte, "Ecart_CA", each [CA_net] - [Objectif_CA], Currency.Type)
in Ecart
