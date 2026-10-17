// Calculer les montants en centimes entiers puis enrichir avec les référentiels.
let
    Lignes = Table.SelectRows(Validation, each [Motif] = ""),
    Colonnes = Table.RemoveColumns(Lignes, {"Date", "Ordre_source", "Motif"}),
    Dates = Table.RenameColumns(Colonnes, {{"Date_valide", "Date"}}),
    Prix = Table.AddColumn(Dates, "Prix_centimes", each Number.Round([Prix_unitaire] * 100, 0, RoundingMode.AwayFromZero), Int64.Type),
    Cout = Table.AddColumn(Prix, "Cout_centimes", each Number.Round([Cout_unitaire] * 100, 0, RoundingMode.AwayFromZero), Int64.Type),
    Remise = Table.AddColumn(Cout, "Remise_pct", each Number.Round([Remise_taux] * 100, 0, RoundingMode.AwayFromZero), Int64.Type),
    Facture = Table.AddColumn(Remise, "CA_facture", each Number.IntegerDivide([Quantite] * [Prix_centimes] * (100 - [Remise_pct]) + 50, 100) / 100, Currency.Type),
    Retour = Table.AddColumn(Facture, "Remboursements", each Number.IntegerDivide([Quantite_retournee] * [Prix_centimes] * (100 - [Remise_pct]) + 50, 100) / 100, Currency.Type),
    Net = Table.AddColumn(Retour, "CA_net", each [CA_facture] - [Remboursements], Currency.Type),
    CoutNet = Table.AddColumn(Net, "Cout_net", each ([Quantite] - [Quantite_retournee]) * [Cout_centimes] / 100, Currency.Type),
    Marge = Table.AddColumn(CoutNet, "Marge_nette", each [CA_net] - [Cout_net], Currency.Type),
    RefProduits = if Table.RowCount(SourcesProduits) = List.Count(List.Distinct(SourcesProduits[Produit_ID])) then SourcesProduits else error "Cle Produit_ID non unique",
    RefMagasins = if Table.RowCount(SourcesMagasins) = List.Count(List.Distinct(SourcesMagasins[Magasin_ID])) then SourcesMagasins else error "Cle Magasin_ID non unique",
    Produit = Table.NestedJoin(Marge, {"Produit_ID"}, RefProduits, {"Produit_ID"}, "Produit", JoinKind.LeftOuter),
    Categorie = Table.ExpandTableColumn(Produit, "Produit", {"Categorie"}),
    Magasin = Table.NestedJoin(Categorie, {"Magasin_ID"}, RefMagasins, {"Magasin_ID"}, "RefMagasin", JoinKind.LeftOuter),
    Nom = Table.ExpandTableColumn(Magasin, "RefMagasin", {"Magasin"}),
    Annee = Table.AddColumn(Nom, "Annee", each Date.Year([Date]), Int64.Type),
    Mois = Table.AddColumn(Annee, "Mois", each Date.ToText([Date], "yyyy-MM", "en-US"), type text),
    Resultat = Table.SelectColumns(Mois, {"Ligne_ID", "Commande_ID", "Date", "Magasin_ID", "Produit_ID", "Client_ID", "Canal", "Quantite", "Prix_unitaire", "Remise_taux", "Quantite_retournee", "Cout_unitaire", "CA_facture", "Remboursements", "CA_net", "Cout_net", "Marge_nette", "Categorie", "Magasin", "Annee", "Mois"})
in Resultat
