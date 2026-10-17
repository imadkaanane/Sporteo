// Une commande n'appartient qu'à une année et un magasin dans ce scénario.
let
    Groupes = Table.Group(Ventes, {"Commande_ID"}, {{"Annee", each List.First([Annee]), Int64.Type}, {"Magasin", each List.First([Magasin]), type text}, {"CA_net", each List.Sum([CA_net]), Currency.Type}}),
    Nombre = Table.AddColumn(Groupes, "Nombre", each 1, Int64.Type)
in Nombre
