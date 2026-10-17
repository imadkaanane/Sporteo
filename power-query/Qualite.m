// Réconcilier la totalité des lignes brutes avec leurs destinations.
let
    Brut = Table.RowCount(SourcesVentes),
    DoublonsN = Table.RowCount(Doublons),
    RejetsN = Table.RowCount(Rejets),
    Propres = Table.RowCount(Ventes),
    Resultat = #table(type table [Controle=text, Valeur=Int64.Type], {{"Lignes brutes", Brut}, {"Doublons", DoublonsN}, {"Rejets", RejetsN}, {"Lignes propres", Propres}, {"Ecart reconciliation", Brut-DoublonsN-RejetsN-Propres}})
in Resultat
