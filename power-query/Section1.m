section Section1;

shared SourcesVentes =
// Lire la table source embarquée, sans chemin propre à un ordinateur.
let
    Source = Excel.CurrentWorkbook(){[Name="Source_Ventes"]}[Content],
    Types = Table.TransformColumnTypes(Source, {{"Ligne_ID", type text}, {"Commande_ID", type text}, {"Date", type text}, {"Magasin_ID", type text}, {"Produit_ID", type text}, {"Client_ID", type text}, {"Canal", type text}, {"Quantite", Int64.Type}, {"Prix_unitaire", type number}, {"Remise_taux", type number}, {"Quantite_retournee", Int64.Type}, {"Cout_unitaire", type number}}, "en-US"),
    Ordre = Table.AddIndexColumn(Types, "Ordre_source", 0, 1, Int64.Type)
in
    Ordre
;

shared SourcesMagasins =
// Une ligne par magasin ; cette clé doit rester unique.
Excel.CurrentWorkbook(){[Name="Source_Magasins"]}[Content]
;

shared SourcesProduits =
// Une ligne par produit ; cette clé doit rester unique.
Excel.CurrentWorkbook(){[Name="Source_Produits"]}[Content]
;

shared SourcesObjectifs =
// Un objectif par mois et magasin, jamais un objectif par vente.
let
    Source = Excel.CurrentWorkbook(){[Name="Source_Objectifs"]}[Content],
    Types = Table.TransformColumnTypes(Source, {{"Date", type date}, {"Magasin_ID", type text}, {"Objectif_CA", Currency.Type}, {"Objectif_taux_marque", type number}}, "en-US")
in Types
;

shared PremieresLignes =
// Conserver explicitement la première occurrence dans l'ordre de la source.
let
    Premiers = Table.Group(SourcesVentes, {"Ligne_ID"}, {{"Premier_index", each List.Min([Ordre_source]), Int64.Type}}),
    Jointure = Table.NestedJoin(SourcesVentes, {"Ligne_ID"}, Premiers, {"Ligne_ID"}, "Premier", JoinKind.LeftOuter),
    Index = Table.ExpandTableColumn(Jointure, "Premier", {"Premier_index"}),
    Uniques = Table.SelectRows(Index, each [Ordre_source] = [Premier_index]),
    Resultat = Table.RemoveColumns(Uniques, {"Premier_index"})
in Resultat
;

shared Doublons =
// Isoler les occurrences répétées pour conserver une piste d'audit.
let
    Premiers = Table.Group(SourcesVentes, {"Ligne_ID"}, {{"Premier_index", each List.Min([Ordre_source]), Int64.Type}}),
    Jointure = Table.NestedJoin(SourcesVentes, {"Ligne_ID"}, Premiers, {"Ligne_ID"}, "Premier", JoinKind.LeftOuter),
    Index = Table.ExpandTableColumn(Jointure, "Premier", {"Premier_index"}),
    Doublons = Table.SelectRows(Index, each [Ordre_source] <> [Premier_index]),
    Resultat = Table.RemoveColumns(Doublons, {"Ordre_source", "Premier_index"})
in Resultat
;

shared Validation =
// Une date impossible ou une valeur invalide est rejetée, sans réparation arbitraire.
let
    Magasins = List.Buffer(SourcesMagasins[Magasin_ID]),
    Produits = List.Buffer(SourcesProduits[Produit_ID]),
    DateControlee = Table.AddColumn(PremieresLignes, "Date_valide", each try Date.FromText([Date], [Format="yyyy-MM-dd", Culture="en-US"]) otherwise null, type nullable date),
    Motifs = Table.AddColumn(DateControlee, "Motif", each Text.Combine(List.RemoveNulls({
        if [Date_valide] = null then "Date invalide" else null,
        if [Quantite] <= 0 then "Quantite non positive" else null,
        if not List.Contains(Produits, [Produit_ID]) then "Produit inconnu" else null,
        if not List.Contains(Magasins, [Magasin_ID]) then "Magasin inconnu" else null,
        if [Remise_taux] < 0 or [Remise_taux] > 1 then "Remise hors intervalle" else null,
        if [Quantite_retournee] < 0 or [Quantite_retournee] > [Quantite] then "Retour incoherent" else null
    }), ", "), type text)
in Motifs
;

shared Rejets =
// Fournir les lignes exclues et leur motif, avec la date brute conservée.
let
    Lignes = Table.SelectRows(Validation, each [Motif] <> ""),
    Resultat = Table.RemoveColumns(Lignes, {"Date_valide", "Ordre_source"})
in Resultat
;

shared Ventes =
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
;

shared Commandes =
// Une commande n'appartient qu'à une année et un magasin dans ce scénario.
let
    Groupes = Table.Group(Ventes, {"Commande_ID"}, {{"Annee", each List.First([Annee]), Int64.Type}, {"Magasin", each List.First([Magasin]), type text}, {"CA_net", each List.Sum([CA_net]), Currency.Type}}),
    Nombre = Table.AddColumn(Groupes, "Nombre", each 1, Int64.Type)
in Nombre
;

shared Objectifs =
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
;

shared Qualite =
// Réconcilier la totalité des lignes brutes avec leurs destinations.
let
    Brut = Table.RowCount(SourcesVentes),
    DoublonsN = Table.RowCount(Doublons),
    RejetsN = Table.RowCount(Rejets),
    Propres = Table.RowCount(Ventes),
    Resultat = #table(type table [Controle=text, Valeur=Int64.Type], {{"Lignes brutes", Brut}, {"Doublons", DoublonsN}, {"Rejets", RejetsN}, {"Lignes propres", Propres}, {"Ecart reconciliation", Brut-DoublonsN-RejetsN-Propres}})
in Resultat
;