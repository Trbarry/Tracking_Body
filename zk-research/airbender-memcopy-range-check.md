# ZKsync Airbender : MEMCOPY hors du range check 16 bits

- **Source** : fil X de @ZeroCool_AI, posté le 2026-11-17 ; lien partagé : https://x.com/ZeroCool_AI/status/2049149819940176058
- **Capture** : [sources/2026-11-17-zerocool-airbender-memcopy.jpg](sources/2026-11-17-zerocool-airbender-memcopy.jpg)
- **Cible** : circuits ZKsync Airbender
- **Sévérité** : High, payée 20 000 $ via Immunefi
- **Statut** : corrigé (d'après le fil)
- **Fiabilité** : résumé d'un tweet ; ni le rapport ni le commit du correctif n'ont été lus.

## Le bug (d'après le fil)

Une valeur de 256 bits est découpée en seize limbes de 16 bits. Cette représentation n'est valable que si
le circuit force chaque limbe dans `[0, 2^16)`.

L'opération MEMCOPY n'était pas branchée sur le range check 16 bits partagé. Avec une limbe à `0xFFFF`
plus une retenue de 1, le circuit acceptait `65536` (`0x10000`) comme limbe valide. Résultat : une
représentation non canonique, que le prouveur peut choisir à sa guise. C'est un bug de soundness.

**Correctif** : MEMCOPY passe désormais par le même range check que les autres opérations.

## Heuristiques d'audit à en tirer

1. **Inventaire des producteurs de limbes** : lister chaque opcode ou sous-circuit qui écrit une limbe
   (calculs arithmétiques, mais aussi copies, chargements et déplacements mémoire). Vérifier que
   *chacun* alimente la lookup ou l'argument de range check. Les chemins de « simple copie » sont souvent
   supposés conserver la plage et en sont oubliés.
2. **Retenues aux bords** : tester `0xFFFF + 1` sur chaque limbe, la propagation de la retenue jusqu'à la
   limbe la plus haute et le débordement final de 256 bits.
3. **Range check « partagé »** : quand un argument de lookup est mutualisé entre opcodes, comparer la liste
   des colonnes ou variables qui y sont réellement envoyées à la liste de celles qui *devraient* l'être.
   Diff entre les deux = surface d'attaque.
4. **Unicité de la décomposition** : pour toute recomposition `Σ limb_i · 2^(16i)`, se demander si deux
   jeux de limbes différents peuvent donner la même valeur dans le corps. Si c'est possible, une contrainte
   de plage manque.
5. **Test différentiel** : produire un témoin avec une limbe à `2^16`. Si le vérificateur l'accepte, le bug
   est confirmé.

## À faire

- [ ] Retrouver le rapport Immunefi ou le commit du correctif dans le dépôt Airbender (matter-labs) pour la
      localisation exacte.
- [ ] Appliquer l'heuristique n° 1 aux autres zkVM qui utilisent des limbes de 16 bits.
