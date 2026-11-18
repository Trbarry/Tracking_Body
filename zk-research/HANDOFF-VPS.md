# Passation vers le VPS : chasse Airbender V2 (ZKsync OS)

- **Écrit le** 2026-11-18, depuis la session cloud « Optimism ».
- **Branche** : `ccr-f1cfed3a-k2loia` du dépôt `trbarry/Tracking_Body`. Tout se trouve dans `zk-research/`.
- **Modèle utilisé** : Opus 5.5, grâce à l'exception quota Mythos 5.2 du CLAUDE.md. Le quota se réinitialise le 2026-11-22 à 00:00 UTC ; repasser alors sur Mythos 5.2.

## 1. Point de départ

- **Le tweet** : @ZeroCool_AI, le 2026-11-17, rapporte un bug High payé 20 000 $ sur Immunefi. MEMCOPY était absent du range check 16 bits partagé dans le circuit `bigint_with_control` d'Airbender. Fiche : `airbender-memcopy-range-check.md`.
- **Dans quel composant** : le prouveur Airbender (`matter-labs/zksync-airbender`), pas le code de ZKsync OS lui-même. ZKsync OS appelle ce circuit pour l'arithmétique U256.
- **Est-ce nous qui l'avions trouvé ?** Aucune trace dans ce dépôt. Nos campagnes zkos d'octobre visaient pourtant les racines bigint (lane D1, campagne stoppée). À vérifier sur le VPS : `grep -rli memcopy /workspace/campaigns/zk*`.
- **Le correctif** est présent sur `main` (`cs/src/delegation/bigint_with_control/mod.rs:643`).

## 2. Version auditée

- `zksync-airbender` @ `0decdcd`, « feat!: Airbender V2 (#587) », du 2026-11-04. Cette réécriture découpe le CPU en circuits « unrolled » (un par famille d'opcodes), plus un circuit `unified_reduced_machine` et un circuit `inits_and_teardowns`.
- Nos campagnes d'octobre portaient sur V1. Tout le code V2 est donc neuf pour nous.
- Pour recloner : `git clone https://github.com/matter-labs/zksync-airbender && git checkout 0decdcd`, toolchain `nightly-2026-08-09`.

## 3. Trouvaille principale (candidat, non soumis)

Détails : `airbender-v2-hunt.md`. Brouillon Immunefi : `airbender-v2-padding-delegation/report.md`.

**Des lignes de padding du circuit `unified_reduced_machine` (`execute = 0`) peuvent émettre une demande de délégation Blake2s, à un timestamp choisi par le prouveur.**

- **Où** : `cs/src/machine/ops/common_impls/csr_with_delegation.rs:54-72`. La multiplicité vaut `should_delegate = is_for_delegation * exec_flag`, sans aucun lien avec `execute`.
- **Le circuit voisin `shift_binary_csr` a la garde** (`shift_binary_csr.rs:681-685`), avec ce commentaire : *« to avoid prover's possibility to set delegation to 1 when we actually do not execute on this row »*.
- **Preuve dans le code généré**, `circuit_defs/unrolled_circuits/unified_reduced_machine/generated/quotient.rs` :
  - `memory[30]` (execute) n'apparaît qu'en l.471 (booléanité), l.4028 (multiplicité du décodeur) et l.4725 (masque de la permutation d'état).
  - `memory[27]` (multiplicité de délégation) apparaît dans `w26*w79 - m27` (l.1486) et dans l'accumulateur de délégation (l.4390), sans masque.
  - Le timestamp de la demande vient de `memory[33/34]`, des colonnes que le prouveur remplit (`timestamp_setup_columns` est vide).
  - À comparer : `shift_binary_csr/generated/quotient.rs` (l.~380) contient bien `m17 - m17*m19`.
- **Attaque** :
  1. Recopier sur une ligne de padding le témoin d'une vraie ligne CSRRW vers Blake2s, en gardant `execute = 0`.
  2. Prendre comme timestamp `B`, un cycle honnête qui ne délègue pas. L'emplacement `B+3` y est libre.
  3. Ajouter une ligne dans le circuit de délégation Blake2s.
  4. Faire pointer les lectures suivantes vers les nouvelles valeurs.
  5. Toutes les contraintes et tous les arguments restent équilibrés : on obtient une compression Blake2s fantôme sur le buffer pointé par x10.
- **Où ce circuit sert** : la couche de récursion « unified ». Le programme prouvé y est le vérifieur récursif, qui utilise Blake2s pour le transcript et les preuves Merkle.
- **Introduit dans** `0decdcd` (V1 n'avait pas ce circuit).
- **Correctif** : ajouter `should_delegate*(1-execute)=0`.

## 4. Vérifié et sain

- **bigint** : 7 opérations sur 7 passent par un range check, et les retenues n'ont qu'une décomposition possible.
- **keccak_special5** : sorties bornées par tables et rotations. Une seule opération à la fois quand `execute = 1`, tout à 0 sinon. Le compilateur de délégation ne range-checke pas les écritures : chaque circuit doit le faire lui-même.
- **blake2 extended** : toutes les écritures sont bornées. Le masque de round n'est pas forcé à une seule valeur, mais l'agent n'a pas réussi à l'exploiter. `blake2_single_round` n'est pas déployé.
- **Vérifieur, agrégation et Fiat-Shamir** (terminé) :
  - Rien d'exploitable.
  - L'ordre des challenges est correct, au niveau global comme dans chaque circuit.
  - On ne peut pas omettre, dupliquer ou réordonner des instances.
  - Les compteurs sont bornés.
  - Les ensembles inits/teardowns sont ordonnés.
  - `end_params` lie le programme à la preuve.
  - FRI et DEEP sont corrects.
  - 3 points informatifs, tous écartés : les feuilles FRI finales sont lues avec `read_word` et non réduites (`verifier/src/concrete/skeleton_instance.rs:365-370`) ; les timestamps finaux ne sont pas réduits (`prover/src/definitions/mod.rs:678`) ; un commentaire trompeur dans `unrolled_proof_statement.rs:440`.
- **Liaisons entre circuits** (terminé) :
  - Rien d'exploitable.
  - Tuple mémoire, read-before-write sur 19+19 bits, timestamps d'écriture range-checkés.
  - inits/teardowns : le padding ne peut être qu'un préfixe ; pas de double init.
  - Chaîne d'état (pc, ts) correcte.
  - Le décodeur lie chaque PC à une seule famille via la table de setup.
  - Délégations : l'agent a contrôlé les garde-fous dans `shift_binary_csr` seulement. **C'est cohérent avec notre trouvaille : la même garde manque dans le circuit unifié.**
  - Rien de non masqué dans les familles executor : les arguments mémoire et état sont masqués par `execute` (`grand_product_accumulators.rs` ~l.640). **La demande de délégation, elle, n'est pas dans ce bloc de masquage.**
  - Non couvert : la range des next-PC par famille (défense en profondeur), le patch `is_register` dans load/store du circuit unifié (`ops/load.rs`, `ops/store.rs`), et l'égalité quotient généré = générateur pour toutes les familles.
- **Toutes les familles unrolled** : les écritures dans rd, les STORE (SB/SH compris) et x0 sont range-checkés ou viennent de tables. Le PC est sain (`diffs.rs`).

## 5. Ce qui tournait au moment de la passation

Les résultats arrivent dans `zk-research/` ; récupère-les avec un `git pull`. Si un fichier manque, c'est que l'agent n'avait pas fini.

| Lane | Fichier de sortie |
|---|---|
| PoC paliers 1 et 2 sur le conteneur cloud, témoin négatif avec le correctif | `airbender-v2-padding-delegation/poc.md` et `poc/` |
| Impact : variante m = −1 (annuler une vraie délégation), chemin vers une fausse preuve récursive / regrinding Fiat-Shamir, usage en production (zksync-os / zksync-os-server), doublons | `airbender-v2-padding-delegation/impact-notes.md` |
| Variantes padding dans tous les circuits (contributions non masquées par execute) | `airbender-v2-padding-variants.md` |
| Fond : liaisons mémoire entre circuits / inits-teardowns / état / délégations | **TERMINÉ, rien de trouvé** (voir §4) |
| Fond : argument de lookup / débordement des multiplicités / optimiseur de contraintes | **TERMINÉ, rien de trouvé** (voir partie F des comptes rendus) |
| Fond : vérifieur / agrégation / Fiat-Shamir / liaison du programme | **TERMINÉ, rien de trouvé** (voir §4) |

## 6. À faire sur le VPS (dans l'ordre)

1. `git pull` sur `ccr-f1cfed3a-k2loia` et lire `poc.md`, `impact-notes.md` et `airbender-v2-padding-variants.md` s'ils existent.
2. **PoC palier 3, preuve complète** : prouver le circuit unifié (`TRACE_LEN_LOG2 = 23`) avec le témoin falsifié et le faire accepter par le vrai vérifieur. Il faut beaucoup de RAM, ou un GPU (`gpu_prover`). Lancer aussi le témoin négatif avec le correctif. Repartir des commandes de `poc.md`.
3. **Impact** : construire une chaîne concrète « compression fantôme → vérifieur récursif qui accepte une preuve invalide ou une sortie fausse ». Sans elle, la sévérité reste incertaine.
4. **Périmètre** : vérifier que V2 et la couche unifiée sont dans le périmètre Immunefi ZKsync OS et en production.
5. **Doublon** : chercher une issue ou une PR amont postérieure au 2026-11-04.
6. **Triager hostile** sur `report.md` et `poc.md`. Si le rapport tient, l'utilisateur fait sa review, et **rien n'est soumis sans son accord explicite**.
7. Recherche dans les campagnes : `grep -rli memcopy /workspace/campaigns/zk*`, et retrouver le sujet de #94080.

## 7. Règles (CLAUDE.md)

- Le modèle doit être Mythos 5.2, avec l'exception Opus 5.5 jusqu'à la réinitialisation du quota. Le signaler dans chaque rapport.
- Le cadre légal verbatim n'est obligatoire que pour l'engagement OPTIMISM. Rester tout de même en lecture et en tests locaux : aucune soumission, aucun contact, aucune action on-chain.
