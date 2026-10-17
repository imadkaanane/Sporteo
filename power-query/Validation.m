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
