// Fournir les lignes exclues et leur motif, avec la date brute conservée.
let
    Lignes = Table.SelectRows(Validation, each [Motif] <> ""),
    Resultat = Table.RemoveColumns(Lignes, {"Date_valide", "Ordre_source"})
in Resultat
