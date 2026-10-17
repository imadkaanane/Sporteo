// Conserver explicitement la première occurrence dans l'ordre de la source.
let
    Premiers = Table.Group(SourcesVentes, {"Ligne_ID"}, {{"Premier_index", each List.Min([Ordre_source]), Int64.Type}}),
    Jointure = Table.NestedJoin(SourcesVentes, {"Ligne_ID"}, Premiers, {"Ligne_ID"}, "Premier", JoinKind.LeftOuter),
    Index = Table.ExpandTableColumn(Jointure, "Premier", {"Premier_index"}),
    Uniques = Table.SelectRows(Index, each [Ordre_source] = [Premier_index]),
    Resultat = Table.RemoveColumns(Uniques, {"Premier_index"})
in Resultat
