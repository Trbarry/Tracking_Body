# TOUT POUR LA SESSION VPS : chasse Airbender V2 / ZKsync OS (export du 2026-11-18)

> À coller tel quel dans la nouvelle session. Le dépôt `trbarry/Tracking_Body`, branche `ccr-f1cfed3a-k2loia`, contient les mêmes fichiers dans `zk-research/`.
> Ordre : 1) la passation, 2) la fiche du bug MEMCOPY d'origine, 3) les notes de chasse V2, 4) le brouillon du rapport Immunefi, 5) les comptes rendus complets des 6 agents terminés.


---

<!-- ===== FICHIER : zk-research/HANDOFF-VPS.md ===== -->

## Passation vers le VPS : chasse Airbender V2 (ZKsync OS)

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

---

<!-- ===== FICHIER : zk-research/airbender-memcopy-range-check.md ===== -->

## ZKsync Airbender : MEMCOPY hors du range check 16 bits

- **Source** : fil X de @ZeroCool_AI, posté le 2026-11-17 ; lien partagé : https://x.com/ZeroCool_AI/status/2049149819940176058
- **Capture** : [sources/2026-11-17-zerocool-airbender-memcopy.jpg](sources/2026-11-17-zerocool-airbender-memcopy.jpg)
- **Cible** : le prouveur ZKsync Airbender, et non ZKsync OS lui-même. Plus précisément le circuit de délégation
  `bigint_with_control` (`cs/src/delegation/bigint_with_control/mod.rs`, `MEMCOPY_BIT_IDX = 7`), que ZKsync OS
  appelle pour l'arithmétique EVM sur 256 bits.
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

- [ ] Retrouver le commit du correctif. Le commit `ca91999` (2025-10-08, « bigint fix ») corrige un autre bug :
      le signe de la retenue dans `sub_negate`. Dernière version lue : `0decdcd` (Airbender V2, 2026-11-04).
- [ ] Appliquer l'heuristique n° 1 aux autres zkVM qui utilisent des limbes de 16 bits.

---

<!-- ===== FICHIER : zk-research/airbender-v2-hunt.md ===== -->

## Chasse Airbender V2 : classe « valeur ou écriture non contrainte »

- **Démarrée le** 2026-11-18, à partir du bug MEMCOPY ([airbender-memcopy-range-check.md](airbender-memcopy-range-check.md)).
- **Version lue** : matter-labs/zksync-airbender `0decdcd`, « feat!: Airbender V2 (#587) », du 2026-11-04. C'est une réécriture complète : le CPU est découpé en circuits « unrolled », un par famille d'instructions.
- **Méthode** : lecture seule, sans build ni PoC pour l'instant.
- **Modèle** : Opus 5.5 pour la session et les sous-agents, grâce à l'exception quota Mythos 5.2 du CLAUDE.md, valable jusqu'au 2026-11-22.

## Candidat n° 1 : demande de délégation émise depuis une ligne de padding (`unified_reduced_machine`)

**Statut** : structure confirmée à la lecture du code source et du code généré. Ni PoC ni recherche de doublon n'ont été faits.

- **Où** :
  - `cs/src/machine/ops/common_impls/csr_with_delegation.rs:54-72` : `should_delegate = is_for_delegation * exec_flag` devient la multiplicité de la demande de délégation.
  - Appelé par `cs/src/machine/ops/unrolled/reduced_machine_ops.rs` (`PERFORM_DELEGATION`).
- **Ce qui manque** : aucune contrainte `should_delegate * (1 - execute) = 0`. Le circuit `shift_binary_csr` l'a bien (`cs/src/machine/ops/unrolled/shift_binary_csr.rs:681-685`), avec ce commentaire : *« to avoid prover's possibility to set delegation to 1 when we actually do not execute on this row »*.
- **Preuve dans le code généré** :
  - Dans `circuit_defs/unrolled_circuits/unified_reduced_machine/generated/quotient.rs`, `memory[30]` (execute) n'apparaît qu'en trois endroits : booléanité (l.471), multiplicité du lookup décodeur (l.4028) et masquage de la permutation d'état (l.4725).
  - `memory[27]` (multiplicité de délégation) apparaît dans `w26*w79 - m27` (l.1486), dans deux masquages et dans l'accumulateur de délégation (l.4390). Rien ne la masque par execute.
  - Dans `shift_binary_csr/generated/quotient.rs` (l.~380), on trouve en revanche bien `m17 - m17*m19`.
- **Pourquoi la ligne de padding est libre** :
  - Le lookup du décodeur a pour multiplicité `execute`. Quand `execute = 0`, `circuit_family_extra_mask` et donc les drapeaux, `imm` et `rs1` ne sont plus contraints.
  - Le timestamp de la demande vient des colonnes d'état `memory[33/34]` (`timestamp_setup_columns` est vide). Comme la permutation d'état est masquée par execute, ce timestamp est au choix du prouveur.
- **Scénario** :
  1. Prendre une ligne de padding et y recopier le témoin d'une vraie ligne CSRRW vers la délégation Blake2s : drapeau CSR à 1 et index CSR `BLAKE2S_DELEGATION_CSR_REGISTER`. C'est la seule délégation autorisée pour le circuit unifié (`execution_utils/src/unified_circuit.rs:91`).
  2. Mettre `execute = 0` et choisir un timestamp de départ B, où B est un cycle honnête qui ne délègue pas. L'emplacement `B+3` (in_cycle_write_index 3) y est libre.
  3. Ajouter la ligne correspondante dans le circuit de délégation Blake2s : il lit x10/x11/x12 et l'état, puis écrit l'état compressé à `B+3`.
  4. Faire pointer les lectures suivantes vers `(v', B+3)`. L'argument mémoire l'accepte.
- **Effet** : le prouveur insère une compression Blake2s, au moment de son choix, sur le buffer pointé par x10 (et modifie x12). L'exécution prouvée ne respecte plus la sémantique RISC-V.
- **Où ce circuit sert** : la couche de récursion « unified » (`execution_utils/src/unified_circuit.rs`, `full_statement_verifier/src/unified_circuit_statement.rs`). Le programme prouvé y est le vérifieur récursif, qui utilise Blake2s pour le transcript et les preuves Merkle.
- **Version concernée** : V2 seulement. Avant `0decdcd`, il n'y avait pas de circuit unifié ni de lignes de padding avec `execute`.
- **Correctif évident** : ajouter `should_delegate * (1 - execute) = 0` dans le chemin unifié.
- **Extension non tracée (PLAUSIBLE)** : sur une ligne de padding, plusieurs drapeaux peuvent valoir 1 en même temps. Les lookups fusionnés de l'opt_ctx deviennent alors des sommes. Si cela permet `m ∉ {0,1}`, par exemple `m = -1`, une vraie demande pourrait être annulée et donc une compression supprimée.

### Points ouverts avant toute soumission

- [ ] **Impact** : passer de « compression insérée au bon moment » à une fausse preuve récursive acceptée, autrement dit une contrefaçon. Sans cela, la sévérité reste incertaine.
- [ ] **Portée** : V2 / le circuit unifié sont-ils dans le périmètre du programme ZKsync OS sur Immunefi, et utilisés en production (couche unified ou unrolled) ?
- [ ] **Doublon** : chercher une issue ou une PR amont postérieure au 2026-11-04.
- [ ] **PoC** : modifier le témoin d'une preuve unifiée (trace 2^23) et vérifier que le vérifieur l'accepte. Il faut une grosse machine, soit l'Exegol, soit l'OVH.

## Vérifié et sain (V2)

- **bigint_with_control** : les 7 opérations passent par un range check (correctif MEMCOPY présent, l.643) et les retenues n'ont qu'une décomposition possible.
- **keccak_special5** :
  - Les sorties sont bornées par des tables 8 bits, et les rotations restent sous 2^16.
  - Une seule opération à la fois quand `execute = 1`, tout à 0 sinon.
  - Le compilateur de délégation ne range-checke pas les écritures : chaque circuit doit le faire lui-même.
  - Petite anomalie sans effet : la fonction de génération de la table de permutation renvoie le mauvais index.
- **blake2 (extended control)** :
  - Toutes les écritures sont bornées.
  - Le masque de round n'est pas forcé à une seule valeur, mais cela n'aboutit qu'à un écart avec le VM natif, pas à un problème de soundness.
  - `blake2_single_round` n'est pas déployé.
- **Familles unrolled** (add_sub_lui_auipc_mop, shift_binary_csr, mul_div, jump_branch_slt, load_store word et subword, unified) : les écritures dans rd, les STORE et x0 sont tous range-checkés ou viennent de tables.

---

<!-- ===== FICHIER : zk-research/airbender-v2-padding-delegation/report.md ===== -->

## [DRAFT, NOT SUBMITTED] Airbender V2: padding rows of the unified circuit can emit delegation requests

> Internal draft. The severity, the impact chain and the PoC tier are still open. See the "Open items" section at the end.
> Every claim below has to be backed by `poc.md` and `impact-notes.md` before submission.

## Summary

In Airbender V2 (`matter-labs/zksync-airbender` @ `0decdcd`, "feat!: Airbender V2 (#587)"), the
`unified_reduced_machine` circuit never ties its delegation-request multiplicity to the row's `execute`
predicate. On padding rows (`execute = 0`) the decoder lookup is not enforced and the state permutation
is masked, so the opcode bitmask, the `rs1` value and the cycle timestamp are all prover-chosen.

A malicious prover can therefore use a padding row to emit a Blake2s delegation request at a timestamp
of its choice, and serve it with an extra row of the Blake2s delegation circuit. That row reads and
overwrites RAM (the state buffer at `x10`, plus `x12`) in the middle of an otherwise honest execution. The
proven execution then no longer follows RISC-V semantics, yet every constraint and every argument still
balances.

The sibling circuit `shift_binary_csr`, which has the same delegation feature, contains the guard
explicitly, with a comment describing exactly this attack. The unified circuit lacks it.

## Affected code

- `cs/src/machine/ops/common_impls/csr_with_delegation.rs:54-72`

  ```rust
  let should_delegate = cs.add_variable_from_constraint(
      Term::from(is_for_delegation) * Term::from(exec_flag),
  );
  ...
  let delegation_request = DelegatedComputationRequest {
      execute: should_delegate,
      delegation_type: csr_index_masked,
      memory_offset_high: offset_masked,
  };
  cs.add_delegation_request(delegation_request);
  ```

  `exec_flag` is the CSR major flag that comes from the family bitmask. Nothing relates it to `inputs.execute`.

- It is reached from `cs/src/machine/ops/unrolled/reduced_machine_ops.rs` (the `PERFORM_DELEGATION == true` branch).

- For comparison, `cs/src/machine/ops/unrolled/shift_binary_csr.rs:679-685` has the guard:

  ```rust
  // And to avoid prover's possibility to set delegation to 1 when we actually do not execute on this row, check
  // that we indeed execute
  cs.add_constraint(
      Term::from(execute_delegation) * (Term::from(1u64) - Term::from(inputs.execute)),
  );
  ```

### Evidence in the committed generated verifier code

From `circuit_defs/unrolled_circuits/*/generated/`:

| | `shift_binary_csr` | `unified_reduced_machine` |
|---|---|---|
| execute column | `memory[19]` | `memory[30]` |
| delegation multiplicity column | `memory[17]` | `memory[27]` |
| constraint `m·(1−execute) = 0` | present (`m17 − m17·m19`, quotient.rs ~l.380) | **absent** |

In the `unified_reduced_machine` quotient, `memory[30]` appears in only three places:
- its booleanity (l.471);
- the decoder-lookup multiplicity (l.4028);
- the state-permutation predicate (l.4725).

`memory[27]` is defined by `w26·w79 − m27` (l.1486), where `w26` is the CSR flag and `w79` is
`is_for_delegation`. It is used unmasked as `m` in the delegation-request accumulator term (l.4390). The
timestamp in that term is read from `memory[33]`/`memory[34]`, the row's own state columns, because
`timestamp_setup_columns` is empty for this circuit. On a padding row those columns are free.

## Attack

1. Run the honest program and generate an honest witness for all circuits.
2. In the `unified_reduced_machine` trace, choose a padding row (`execute = 0`). Copy into it the witness
   columns of an honest `CSRRW` delegation row targeting `BLAKE2S_DELEGATION_CSR_REGISTER`, which is the
   only delegation allowed in the unified machine (`execution_utils/src/unified_circuit.rs:91`). Keep
   `execute = 0`.
3. Set the row's start timestamp to `B`, where `B` is the start timestamp of some honest, non-delegating
   cycle. The delegation slot `B+3` (`in_cycle_write_index = 3`) of that cycle is unused.
4. Every constraint of the row still holds:
   - the constraints that would bind the bitmask to the bytecode are lookups with multiplicity `execute = 0`;
   - the memory and state permutation terms are masked by `execute`.

   The row contributes a delegation request `(type = Blake2s, abi_offset, ts = B+3)` with multiplicity 1.
5. Add one row to the Blake2s delegation circuit that processes this request. It reads `x10`, `x11` and
   `x12` and the state/input buffers at their latest write timestamps (all `< B+3`), and writes the
   compressed state (and the updated `x12`) at `B+3`.
6. Re-point the next reads of the affected addresses to `(v', B+3)`. The RAM argument and the delegation
   set-equality both balance.

**Result:** the proof attests to an execution in which a Blake2s compression was applied to the buffer at
`x10` at a cycle where the program executed no such instruction.

## Impact

**[OPEN: to be completed from impact-notes.md]**

- The unified circuit proves the recursion verifier program, the "unified" recursion layer
  (`execution_utils/src/unified_circuit.rs`, `full_statement_verifier/src/unified_circuit_statement.rs`).
  That program relies on Blake2s for its Fiat-Shamir transcript and its Merkle-path checks.
- **What is established:** a soundness break of the unified circuit. Accepted executions are no longer
  faithful RISC-V executions of the committed program.
- **What still has to be shown or bounded:** whether this lets an invalid inner proof, or wrong public
  outputs, pass the recursion layer. A candidate route is re-sampling Fiat-Shamir state at chosen points.

## Fix

Add the same guard as in `shift_binary_csr` to the unified path, for example in `csr_with_delegation.rs`
right after `should_delegate` is allocated, or in `reduced_machine_ops.rs`:

```rust
cs.add_constraint(
    Term::from(should_delegate) * (Term::from(1u64) - Term::from(inputs.execute)),
);
```

Then regenerate the unified circuit artifacts and verifiers.

A more robust fix is for the compiler to multiply the delegation-request multiplicity by the `execute`
predicate for every unrolled circuit, as is already done for the memory and state arguments.

## Proof of concept

See `poc.md`, which also gives the tier reached and the negative control with the fix applied.

## Versions

- Introduced in `0decdcd` (2026-11-04). V1 had no unified/unrolled circuits.
- Still present on `main` as of 2026-11-18.

---
### Open items (internal, remove before submission)
- [ ] Impact chain: from inserting a compression to forging a proof or a public output (impact-notes.md)
- [ ] Whether the m = −1 variant (cancelling a real delegation) holds
- [ ] Production usage of the unified layer, and program scope
- [ ] Duplicate check upstream
- [ ] PoC tier reached (T1/T2/T3); T3 on the OVH machine if required
- [ ] Hostile triager pass

---

<!-- ===== FICHIER : zk-research/_agent-reports.md ===== -->

## Comptes rendus des agents (2026-11-18, tous en Opus 5.5 sous l'exception quota)

## A. Agent blake2 (`blake2_round_with_extended_control`, `blake2_single_round`)

Résultat : aucun bug dans les deux circuits blake2, rien de CONFIRMED ni de PLAUSIBLE.

**Périmètre.** `blake2_single_round` ne compile pas et n'est pas déployé : il appelle `create_batched_memory_accesses`, qui vaut `unimplemented!("deprecated")` (`cs/src/cs/cs_reference.rs:203`). Seule sa `g_function` est réutilisée, par le circuit extended-control. Le circuit déployé est `blake2_round_with_extended_control`, utilisé par `circuit_defs/blake2_with_compression`.

**Vérifié et sain :**

1. **Toutes les écritures RAM sont bornées, quel que soit le masque de contrôle.**
   - Mots d'état étendu 8 à 23 (écrits à chaque ligne) :
     - `a` est le résultat du dernier a-add, sous forme d'un morceau de 8 bits plus (expr−chunk)/256 ; les deux passent par le lookup Xor8 (single_round:890-906) ;
     - `c` est un morceau de 7 bits envoyé dans Xor7, et le reste/128 dans Xor9 (1018-1031) ;
     - `b` et `d` sont assemblés uniquement à partir de sorties de tables Xor (9+7 et 8+8).
   - Mots d'état 0 à 7 : la sortie vaut `perform_final_xor`·(sorties de table xor) + (1−`perform_final_xor`)·`read_value` (extended:764-776, 847-859). Les deux branches sont bornées, et les lookups tournent à chaque ligne, quel que soit le drapeau.
   - x12 : la limbe basse est forcée à 0, la limbe haute est une somme de booléens < 2^13. C'est cohérent avec `final_x12` du VM natif.

2. **Sélecteurs.**
   - Les bits de contrôle et de round viennent de `split_into_bitmask` sur x12[1]. Chaque bit est booléen et x12[1] < 2^13 est forcé.
   - Les trois sources de message (normal / compression gauche / compression droite, 371-410) sont exactement one-hot, car construites à partir des booléens `cm` et `right`.
   - Les mots 12/14 sont correctement sélectionnés (fr·cm·IV ou valeur existante). `Boolean::and`/`or`/`choose`, y compris avec une constante à gauche, produisent des valeurs contraintes.
   - Le masque de round n'est **pas** forcé à une seule valeur. Avec 0 ou 2 bits actifs ou plus, le mot de message permuté est une somme et peut dépasser 16 bits. L'agent n'a pas réussi à l'exploiter :
     - ce mot ne va jamais en RAM, il n'alimente que le a-add ;
     - le résultat du a-add est range-checké à 16 bits, donc la retenue k ∈ {0..3} est unique ; la sortie est déterministe, ou il n'existe aucun témoin valide ;
     - x12 est fixé par l'argument des registres ;
     - le VM natif panique si le masque n'est pas une puissance de 2 (`riscv_transpiler/src/vm/delegations/blake2_round_function.rs:95-100`).

     Au pire, c'est un écart entre le circuit et le VM natif pour un code invité déjà fautif, pas un problème de soundness.

3. **Additions et lookups.**
   - Le a-add à trois opérandes a 2 retenues booléennes par moitié (0..3), et le vrai maximum est (3·65535+3)/65536 = 3. Le c-add a 1 retenue booléenne, maximum 1.
   - Chaque résultat est range-checké à 16 bits, donc tous les entiers restent très en dessous de p, et la décomposition comme la retenue sont uniques.
   - Chaque entrée de lookup est soit un morceau borné par sa table, soit une expression de reste elle-même passée en lookup : d lo/hi (Xor8), le redécoupage 3/9/4 de b (Xor3/Xor9/Xor4), `chunk_16_bit_input`, et `split_top_bit` (partie basse en Xor7/Xor8, bit booléen).
   - Les tables sont de la forme (a, b, a^b) avec les deux entrées < 2^w (`cs/src/tables/binops.rs`).
   - L'ordre des morceaux de rotation est correct pour 16, 12, 8 et 7. Le réordonnancement de c dans le XOR final (od2, od3, od0, od1) et les appariements a/b/d sont corrects.

4. **Padding et code de témoin seul.**
   - Avec execute=0, `evaluate_delegation_processing_conventions` (`prover/.../every_row_except_last.rs:153+`) force à 0 toutes les lectures, toutes les écritures et les timestamps. Des entrées nulles donnent des sorties nulles, de façon déterministe.
   - Chaque `set_values` (morceaux bas, `chunk_3`/`chunk_9`, retenues, bits de poids fort) est fixé par un lookup ou une contrainte linéaire correspondante.

5. **Pointeurs et sémantique.**
   - L'alignement de x10 (128) et de x11 (64) est imposé en range-checkant ptr/2^k (`compile_layout.rs:323-343`), donc `assume_no_alignment_overflow` est sûr.
   - Le circuit correspond au VM natif : IV contre initialisation de l'état, constantes du mode compression pour les mots 12/14, condition du XOR final (round 9, ou round 6 en mode réduit), décalage du masque, limbe basse de x12 = 0.

**Non vérifié (hors périmètre).** Le cas x11 = x10+64, où le bloc d'entrée recouvre les mots d'état étendu 16 à 23 dans la même ligne. Le VM natif ne vérifie que x10 ≠ x11. L'agent s'attend à ce que ces accès à la même adresse dans une ligne soient insatisfiables, puisque read_ts < write_ts est strict. Ce serait alors un problème de complétude et non de soundness, mais cela dépend du code de l'argument mémoire partagé, que l'agent n'a pas tracé.

## B. Agent keccak (`keccak_special5`) et framework de délégation

Résultat : rien ne survit, aucun bug de soundness CONFIRMED ou PLAUSIBLE dans `cs/src/delegation/keccak_special5/` ni dans le code du framework de délégation qu'il utilise.

**Constat sur le framework (il conditionne tout le reste).** Le compilateur de délégation ne range-checke pas les valeurs écrites, en mémoire indirecte ou dans les registres. Dans `cs/src/one_row_compiler/compile_layout.rs` (l.200-560 environ), ces valeurs sont seulement placées dans le sous-arbre mémoire. Comme pour bigint, c'est donc au circuit lui-même de contraindre chaque écriture.

La contrainte de padding générée au stage 3 (`verifier_generator/src/inlining_generator/everywhere_except_last.rs`, l.1215-1650 environ) impose `(predicate-1)*v = 0`. Elle couvre l'offset ABI, le timestamp d'écriture et, pour chaque accès registre ou indirect, le timestamp de lecture, la valeur lue et la valeur écrite. Les lignes avec execute=0 forcent donc control=0, x11=0 et toutes les sorties à 0 : le padding ne peut pas porter d'écriture libre.

**Tracé et trouvé sain (avec execute=1) :**
- **Écritures des 6 emplacements de sortie u64.** Pour chacun des 7 précompilés, chaque emplacement est la sortie d'une des 5 opérations binaires, ou une copie :
  - p0 : binops 1 et 5, plus 4 copies ;
  - p1 : binops 1, 3, 5, plus 3 copies ;
  - p2 : binops 2, 4, 5, plus 3 copies ;
  - p3 et p4 : 5 binops plus 1 copie chacun ;
  - p5 : binops 1, 3, 5, plus 3 copies (dont une de l'emplacement 0 en entrée vers l'emplacement 5) ;
  - p6 : binops 2, 4, 5, plus 3 copies.
- **Les sorties des opérations binaires sont bornées, contrairement au cas MEMCOPY.**
  - Sans rotation, chaque limbe vaut `c[2i] + 256*c[2i+1]`, où c est la sortie 8 bits des tables Xor, AndN ou XorSpecialIota, donc la limbe reste < 2^16.
  - Avec rotation, chaque limbe vaut `right_j + left_{j-1}`. La table RotL donne `right = (x<<r) mod 2^16`, dont les r bits bas sont nuls, et `left = x>>(16-r)` < 2^r. La somme est < 2^16 et ne dépend que de l'entrée.
  - Les copies sont des contraintes `flag*(in-out)=0` sur des lectures RAM, déjà sur 16 bits d'après l'invariant RAM.
- **Les entrées ont une décomposition unique.** Une composition en octets d'une valeur < 2^16 est unique. En mode rotation, `a[i] = x_i + 2^16*rc`, où la constante rc est fixée par les drapeaux, et chaque entrée de RotL est une lecture RAM.
- **Registres temporaires.** Chacun est écrit par la sortie d'une opération binaire avant qu'une opération suivante ne le lise. Les registres inutilisés et les voies de travail inutilisées (a/b/c[4..8] en mode rotation) n'atteignent jamais la RAM.
- **Sélecteurs, et l'affirmation de la ligne 370 (vérifiée vraie).**
  - Les drapeaux du bitmask sont booléens.
  - Les contraintes `execute*(Σp-1)`, `execute*(Σi-1)`, `(1-execute)*Σp` et `(1-execute)*Σi` rendent les drapeaux one-hot quand execute=1, et tous nuls sinon.
  - La composition `control = Σk·p_k + 8Σj·i_j + 64Σ2^b·r_b` fixe alors les drapeaux de façon unique et impose control ≤ 2047. Le précompilé 7 et les itérations 5 à 7 sont insatisfiables, ce qui n'est qu'un problème de vivacité.
  - control_reg[1]=0 et control_reg_next[1]=0 sont contraints.
  - `rho_iterX` vient de `Boolean::and` via `add_variable_from_constraint`, ce qui est contraint.
  - L'id de table variable vient de `choose_from_orthogonal_variants`, qui est contraint : avec tous les drapeaux à zéro, il vaut 0, c'est-à-dire la table ZeroEntry.
- **Écriture de x10 (control_next).** C'est une fonction de degré 2 des drapeaux. Vérifiée sur les 7 précompilés, elle n'est jamais négative et vaut au plus environ 2086 : elle ne peut ni reboucler modulo p ni dépasser 16 bits.
- **Indices d'état.** Ils viennent de sorties de tables fixes, entre 0 et 30. x11 est aligné sur 256 par le range check de `x11_low/256`. L'offset maximal vaut 8*30+4 = 244, donc les 16 bits bas de l'adresse ne peuvent pas déborder.
- **Valeurs de contrôle hors spécification.** Les contrôles que le VM n'utilise pas, comme le round 24 pour un précompilé sans iota ou les rounds 25 à 31, aboutissent à des sorties de table marquées « junk » dans le code (indices [0..5] ou constante de round nulle). Ces sorties restent fixées par la table, donc le prouveur n'y gagne aucune liberté. Le VM n'accepte que des contrôles valides (debug_assert) : au pire une incohérence ou un problème de vivacité si l'invité se trompe, pas un problème de soundness.
- **Adresses en double dans un même appel.** Tous les accès indirects partagent le timestamp de la délégation, et le contrôle lecture-avant-écriture est strict. Accéder deux fois à la même adresse dans un appel rend donc le circuit insatisfiable, et non falsifiable. De toute façon, des contrôles valides ne produisent jamais d'indices en double.
- **Code de témoin seul.** Chaque closure `set_values` a été vérifiée : control_next, les bitmasks (y compris le masquage de p0/i0 par execute), les bits de round, les sorties, les registres temporaires et les voies de travail des binops. Chaque valeur assignée est fixée par une contrainte ou un lookup, ou n'est pas utilisée.
- **Builds de production.** Ils utilisent `DEBUG=false` (`circuit_defs/keccak_special5/src/lib.rs`), donc le chemin `peek_lookup_value_unconstrained_ext`, réservé au debug, n'est jamais compilé.

**Mineur, pas un bug.** Dans `cs/src/tables/keccak_precompile_related.rs`, la fonction de génération de la table de permutation renvoie `control` (11 bits) au lieu de `control_with_exe` comme index. Les lignes de la table sont construites à partir des clés et cet index est ignoré ; l'index rapide passe par `first_key_index_gen_fn`, qui est correct. Aucun effet sur la soundness.

## C. Agent écritures du CPU RISC-V (familles unrolled) : a trouvé le candidat principal

Aucun range check manquant n'a été trouvé sur les écritures en registre ou en RAM des circuits par famille. Un candidat a survécu, dans le chemin d'écriture CSR/délégation de l'unified reduced machine, et l'agent le classe CONFIRMED. Ce n'est pas un bug de range check, mais il permet à un prouveur malveillant de mettre une mauvaise valeur en RAM.

### CONFIRMED : `unified_reduced_machine` peut émettre une demande de délégation depuis une ligne de padding (`execute = 0`)

- **Où :**
  - `cs/src/machine/ops/common_impls/csr_with_delegation.rs:54-72` : `should_delegate = is_for_delegation * exec_flag` devient la multiplicité de la demande de délégation ;
  - appelé par `cs/src/machine/ops/unrolled/reduced_machine_ops.rs:264`.
- **Ce qui manque :** aucune contrainte ne relie `should_delegate` à `inputs.execute`.
  - `shift_binary_csr.rs:683` a exactement cette garde, `execute_delegation * (1 - execute) = 0`, avec le commentaire « to avoid prover's possibility to set delegation to 1 when we actually do not execute on this row ».
  - Dans le `circuit_defs/unrolled_circuits/unified_reduced_machine/generated/quotient.rs` généré, la colonne `execute` (memory[30]) n'apparaît qu'à trois endroits : sa booléanité (~l.471), la multiplicité du lookup décodeur (~l.4028) et le masquage de la permutation d'état (~l.4725).
  - La multiplicité de délégation (memory[27]) n'apparaît que dans `w26*w79 - m27` (~l.1486) et dans les deux produits de masquage.
  - À comparer : le quotient de `shift_binary_csr` contient `m17 - m17*m19` (~l.380).
- **Pourquoi le prouveur est libre sur les lignes de padding :**
  - la multiplicité du lookup décodeur est `execute` (quotient ~l.4028 ; `every_row_except_last.rs:861`), donc `circuit_family_extra_mask`, `imm` et `rs1` ne sont pas contraints quand execute=0 ;
  - les permutations mémoire et d'état sont masquées par `execute`, donc le timestamp de départ de la ligne et la valeur de `rs1` sont libres aussi (seuls les range checks s'appliquent) ;
  - le terme de demande de délégation (`evaluate_delegation_requests`, `every_row_except_last.rs:1744` ; côté prouveur `stage_2_shared.rs:721`) utilise la multiplicité `m` sans masque `execute`.
- **Témoin :**
  1. Prendre une ligne de padding et y recopier le témoin complet d'une vraie ligne de délégation Blake2s CSRRW : drapeau majeur CSR à 1, `imm[0]` = `BLAKE2S_DELEGATION_CSR_REGISTER`, autorisé dans la table unifiée via `ALLOWED_DELEGATION_CSRS`.
  2. Mettre `execute = 0`.
  3. Fixer le timestamp de départ à B, où B est un cycle honnête quelconque sans délégation, et ajuster l'incrément de timestamp.
  4. Toutes les contraintes non masquées restent satisfaites, et `m = 1` avec le timestamp B+3. B+3 est l'emplacement `in_cycle_write_index = 3`, que seules les délégations utilisent : il est donc libre pour ce cycle.
  5. Ajouter une ligne correspondante dans le circuit de délégation Blake2s. Elle lit x10/x11 et l'état à des timestamps antérieurs à B+3, et écrit un nouvel état compressé à B+3.
  6. Faire pointer les lectures suivantes de ces adresses vers (v', B+3). L'argument mémoire l'accepte.
- **Effet :** le prouveur insère une compression Blake2s arbitraire sur le buffer pointé par x10, au cycle de son choix. Cela modifie la RAM que le programme relit ensuite, donc l'exécution ne suit plus la sémantique RISC-V. Le circuit unifié exécute le programme de récursion (setups `unifier_reduced_machine_circuit`, `full_statement_verifier/src/unified_circuit_statement.rs`), où Blake sert au transcript et aux vérifications Merkle.
- **Tentatives de réfutation :**
  - aucune garde ajoutée par le compilateur : `bytecode_preprocessed_executor.rs:316-350` ne fait que placer la demande ;
  - aucun contrôle de timestamp ou de compte côté vérifieur : la somme d'ensembles des délégations dans `unified_circuit_statement.rs` ne fait que mettre en correspondance les demandes et les délégations traitées ;
  - la booléanité ne bloque pas : avec seulement le drapeau CSR actif, `m` vaut de toute façon 0 ou 1.
- **Extension non tracée (PLAUSIBLE seulement) :** sur les lignes de padding, plusieurs drapeaux majeurs peuvent valoir 1 en même temps, donc les lookups fusionnés de l'opt_ctx deviennent des sommes. Cela pourrait donner `m ∉ {0,1}`, par exemple −1 pour annuler une vraie demande. Pas tracé.
- **Correctif :** ajouter `should_delegate * (1 - execute) = 0` dans le chemin unifié, comme dans `shift_binary_csr`.

### Vérifié et sain
- **`add_sub_lui_auipc_mop`** : `out` et `intermediate_tmp` sont des `Register::new` (range check 16 bits). La relation add/sub fusionnée couvre les 8 drapeaux, one-hot via la table du décodeur. Pour ADDMOD/SUBMOD/MULMOD, out < p est imposé par `tmp + p = out + 2^32` avec of=1.
- **`shift_binary_csr`** :
  - les sorties de SLL/SRL/SRA sont des valeurs de table aux bits disjoints (générateurs de `shift_opcode_related.rs` vérifiés) ;
  - les octets des binops sont liés par les clés des tables 8 bits AND/OR/XOR (id de table = funct3 = 4/6/7) ;
  - le rd de CSRRW passe par des lookups `RangeCheck16WithZeroPads` ;
  - les listes de drapeaux des lookups fusionnés contiennent toutes les opérations à chaque indice utilisé, avec repli sur `ZeroEntry` quand aucun drapeau n'est actif.
- **`mul_div`** : rd = product_low/high, des `Register::new`. Les gadgets de signe sont corrects.
- **`jump_branch_slt`** : rd = pc+4 (sortie d'addition range-checkée) ou un drapeau 0/1 issu d'une table. Les branches et rd=x0 écrivent 0 via les sélecteurs `(1 - rd_is_zero)`.
- **`load_store_word_only`** : le store écrit la valeur lue de rs2. Le load écrit dans rd une lecture RAM ou une valeur de la table `RomRead`, masquée pour x0. Le lookup `RomRead` inconditionnel impose aussi l'alignement pour la RAM, car le séparateur renvoie `high % bound`.
- **`load_store_subword_only` (SB/SH)** :
  - limbe fusionnée = `ClearOriginal` + `ClearWritten`, avec des bits de table disjoints (`memory_opcode_related.rs:382-495`) ;
  - les clés sont l'ancienne limbe (16 bits venant de la RAM), l'offset et funct3, donc elles sont uniques ;
  - les traps sont imposés en découpant le bitmask en 2 bits ;
  - les sorties des lookups partagés de l'opt_ctx correspondent bien aux drapeaux orthogonaux rom/ram/store.
- **`reduced_machine_ops`, écriture finale et x0** : l'adresse et la valeur de la requête rd/store sont contraintes pour tous les formats (R/I/J/U via `update_rd`, B via zéro, S via `StoreOp<false>`, SW uniquement). Le placeholder « Also unchecked » est donc toujours lié. Tous les candidats pour rd (Add/Sub/Lui/Auipc/Binop/Conditional/Shift/Jump/Mop/Load, et l'oracle CSR avec `RangeChecked{16}`) sont sur 16 bits.
- **`diffs.rs:170/225` « No range check required »** : c'est la sélection du PC. Le PC est une combinaison de PC valides sous des drapeaux one-hot, et le lookup décodeur du cycle suivant n'accepte que de vrais pc = 4i (les entrées de padding valent p−1).
- **`bump_pc_no_range_checks_explicit`** : correct compte tenu de l'invariant pc%4 et 16 bits garanti par la table du décodeur.
- **Masques du décodeur** : `split_into_bitmask` utilise des bits booléens et donne une décomposition unique. Les masques viennent de la table prétraitée honnête.
- **Valeurs d'init paresseuse** : codées en dur à 0.
- **`machine_configurations` et `decode_and_read_operands.rs` de V1** : aucun circuit principal non unrolled sous `circuit_defs`, ce code ne semble donc pas déployé.

## D. Agent vérifieur, agrégation et Fiat-Shamir

Résultat : rien ne survit comme CONFIRMED ou PLAUSIBLE, aucune faille de soundness dans le périmètre. Il y a 3 points informatifs, dont aucun ne permet de faire vérifier un énoncé faux.

**Points informatifs (chacun vérifié et réfuté comme exploitable) :**
1. `verifier/src/concrete/skeleton_instance.rs:365-370` (identique dans chaque copie sous `circuit_defs/*/verifier`). La boucle de lecture « fri intermediate oracles » va jusqu'à `monomial_coeffs`, donc les `fri_final_step_leafs` (éléments du corps quartique) sont lus avec `read_word()` au lieu de `read_reduced_field_element`. Le commentaire en `:471` (« those are reduced when we read them ») est faux. C'était déjà le cas dans le commit parent.
   - Pourquoi ce n'est pas exploitable : les mots bruts entrent dans le transcript avant le dernier challenge de pliage et avant le tirage des requêtes. Sur RISC-V, les circuits MOP add/sub/mul traitent tout u32 comme sa valeur mod p et produisent toujours un résultat < p (`cs/src/machine/ops/unrolled/add_sub_lui_auipc_mop.rs:185-260`). La vérification aux positions requêtées (`verifier_common/src/fri_folding.rs:50`) compare le mot brut, donc une valeur non réduite échoue toujours.
   - Au final, seulement une malléabilité d'encodage ou un échec de complétude.
2. `prover/src/definitions/mod.rs:678-683` et `:740-745`. Les timestamps finaux des registres et du PC venant du ND sont emballés en `Mersenne31Field(x)`, sans réduction ni range check. Ils doivent tout de même correspondre mod p aux tuples côté circuit dans le grand produit, et ils sont absorbés avant les challenges. Malléabilité seulement.
3. `full_statement_verifier/src/unrolled_proof_statement.rs:440`. Le commentaire dit « we do have contribution from setup values into memory or delegation », mais les setups ne sont jamais absorbés dans le transcript global.
   - Vérifié dans le compilateur de layout (`cs/src/one_row_compiler/bytecode_preprocessed_executor.rs`, `layout_utils.rs:419-580`) : dans le quotient généré de add_sub_lui_auipc_mop, les termes de mémoire et de permutation d'état ne lisent que des colonnes de l'arbre mémoire et du stage 2.
   - Les setups sont aussi fixés via `end_params`. Probablement une coquille dans le commentaire (« do not »).

**Vérifié et sain :**
- **Les accumulateurs portent exactement sur les preuves vérifiées.** Les vérifieurs de famille et de délégation, les setups et les capacités sont des constantes compilées. Les const generics des types de pointeurs de fonction imposent que les nombres de délégations et de valeurs aux bords de chacun correspondent à la crate qui le fournit.
- **Omettre, dupliquer ou réordonner des instances.**
  - Une famille peut avoir zéro instance. La toute première preuve doit venir d'une famille sans délégation (assertions en `:547` et `:576`).
  - Les circuits de délégation exigent `delegation_used`.
  - Des doublons ou un réordonnancement ne peuvent pas équilibrer les arguments : les timestamps croissent strictement, la permutation d'état forme un DAG à source unique, et le produit est commutatif.
- **Ordre des challenges (global).** Les registres, le PC et les timestamps finaux, un marqueur de famille et les caps mémoire de chaque preuve sont absorbés avant `finalize_reset`. Les challenges tirés de cette graine sont comparés aux challenges mémoire, état machine et délégation de chaque preuve.
- **Ordre des challenges (par circuit).** Le transcript couvre la séquence du circuit, le type de délégation, les caps de setup, les challenges externes, les valeurs aux bords, puis les caps de témoin et de mémoire ; ensuite le stage 2 avec les deux accumulateurs ; le quotient ; les ouvertures ; chaque oracle FRI dans l'ordre, puis les dernières feuilles ; les coefficients monomiaux ; le PoW ; les bits de requête (mot 0 sauté). Chaque indice de requête est comparé par assertion à celui tiré.
- **Compteurs.**
  - Les cycles des executors sont plafonnés par `total_cycles < MAX_CYCLES`.
  - Le LogUp de délégation est plafonné par une capacité de réponse < p. Les capacités valent la longueur de trace de chaque circuit moins 1.
  - Le grand produit est multiplicatif, il n'a donc pas de problème de rebouclage.
- **Inits/teardowns.** Le contrôle d'ordre entre ensembles et entre circuits se combine avec la règle interne au circuit « si la ligne n'est pas strictement inférieure à la suivante, elle est entièrement nulle » (`verifier_generator/.../everywhere_except_last.rs:2028`). Le padding nul ne peut être qu'un préfixe, et aucune adresse ne peut être initialisée deux fois. Les contraintes aux bords sur la première ligne et l'avant-dernière sont présentes. L'équivalent dans le chemin unifié est correct.
- **Liaison de l'énoncé.**
  - x0 = 0 est vérifié par assertion ; x10..x17 sont exposés en sortie ;
  - la couche de base force x18..x25 = 0 ;
  - `end_params` = H(PC final ‖ tous les setups de famille ‖ setup init/teardown), et les setups incluent le bytecode ;
  - la chaîne de récursion utilise une préimage plus un raccourci : un programme ne peut pas imiter un maillon de la chaîne sauf si ses setups sont identiques à ceux du programme de récursion ;
  - la récursion combinée exige des chaînes identiques ;
  - le niveau de sécurité est fixé à la compilation dans `tools/verifier` ;
  - aucun circuit n'a d'entrées publiques, donc ignorer `state_variables` est sans risque.
- **Code du transcript** (`transcript/src/lib.rs`).
  - `commit_inner` gère correctement les blocs partiels et complets, la longueur et le drapeau final.
  - Le transcript avec tampon est correct.
  - Le seuil de PoW gère bien 32 bits.
  - `draw_randomness` enchaîne les graines, et deux tirages ne se suivent jamais sans mise à jour de la graine entre eux.
- **FRI et DEEP.**
  - L'indice de pliage et l'arithmétique des domaines sont corrects, et le relèvement de degré `(1 + βx)` est géré.
  - L'évaluation de Horner des monômes est correcte, avec ou sans FMA.
  - L'ordre des puissances d'alpha pour DEEP correspond à l'ordre des ouvertures.
  - z est vérifié par rapport au domaine et au polynôme d'annulation avec `batch_inverse_checked`.
  - La profondeur Merkle est fixe, donc les hachages de feuilles et de nœuds ne peuvent pas être confondus.
- **Vérifieurs générés par circuit.** `lib.rs`, `utils.rs`, `skeleton*.rs` et `size_constants.rs` sont identiques octet pour octet à `verifier/src/` pour les 12 crates de circuit. Seuls les fichiers de layout et de quotient sont générés par circuit.

**Non couvert :**
- la relecture complète du quotient généré de chaque circuit (seuls les termes de challenges externes de add_sub ont été échantillonnés ; la justesse des contraintes relève des autres agents) ;
- la correspondance entre les caps de setup et paramètres de délégation générés et les vrais circuits (complétude seulement) ;
- `proof_flattener.rs` (côté prouveur) ;
- le codegen de `verifier_generator` au-delà de la règle de padding lazy-init ;
- le niveau de sécurité concret de Blake2s en rounds réduits et de la configuration requêtes/PoW.

## E. Agent liaisons entre circuits (mémoire, état, inits/teardowns, délégation)

Résultat : aucun problème de soundness ne survit, rien de CONFIRMED ni de PLAUSIBLE.

**Vérifié et sain (chaque contrainte tracée, sauf mention contraire) :**

1. **Argument mémoire entre circuits.**
   - Le tuple est `is_reg + c0·addr_lo + c1·addr_hi + c2·ts_lo + c3·ts_hi + c4·v_lo + c5·v_hi + γ`. Les accès registre ajoutent une constante 1, les inits RAM non.
   - Les registres sont initialisés à (1, idx, 0, 0) pour idx de 0 à 31, et clôturés dans le vérifieur à partir de valeurs fournies par le prouveur (`prover/src/definitions/mod.rs:646`). Les timestamps u32 non réduits y sont congrus mod p et ne donnent aucune liberté supplémentaire.
   - Dans les familles executor, les contributions mémoire et état de chaque ligne sont masquées par `execute` (`grand_product_accumulators.rs`, bloc de masquage ~l.640). `execute` est contraint à être booléen (`cs_reference.rs` ~l.755).
   - Contrôle lecture-avant-écriture (`layout_utils.rs:846-914`) : `borrow·2^19 + r_lo − w_lo − idx` et `2^19 + r_hi − w_hi − borrow`, tous deux range-checkés sur 19 bits, donnent ensemble r < w exactement.
   - Le timestamp d'écriture vaut cycle_start + idx avec idx ≤ 2 (3 pour la délégation). cycle_end = start + 4, avec une retenue et sans retenue sortant de la limbe haute ; les deux limbes de fin sont range-checkées (`bytecode_preprocessed_executor.rs` ~l.258-280, l.453).
   - Chaque timestamp de l'ensemble des écritures est range-checké : écritures des executors, inits et registres à 0, écritures de délégation au timestamp de la demande. L'astuce de la retenue sur la limbe haute ne marche donc pas.
   - On ne peut pas accéder à une adresse non initialisée. Deux accès à la même adresse au même timestamp sont improuvables.

2. **Circuit inits_and_teardowns** (`compile_init_and_teardown_circuit.rs`, `everywhere_except_last_two.rs`, `transform_shuffle_ram_lazy_init_padding`).
   - Une ligne de padding (final_borrow = 0) force sa propre adresse et son teardown à 0, ainsi que l'adresse de la ligne suivante (vérifié à la main). Le padding ne peut donc être qu'un préfixe d'un ensemble.
   - L'ordre s'applique aux lignes 0 à N-2, et le grand produit aussi. Chaque ensemble a ses ouvertures de ligne suivante (`MEMORY_NEXT_ROW_OPENING_INDEXES`), ses contraintes aux bords sur la première ligne et l'avant-dernière, et ses range checks d'adresse sur 16 bits. Le circuit généré a 6 ensembles, tous présents dans `generated/quotient.rs`.
   - Contrôle de jonction entre ensembles et entre instances (`unrolled_proof_statement.rs:647-684`) : strictement croissant, ou bien le tuple précédent est entièrement nul. Par récurrence, seuls des ensembles entièrement nuls peuvent précéder un ensemble avec padding.
   - Au plus une ligne d'adresse 0 peut porter un teardown non nul, donc pas de double init.

3. **État machine et liaison des instructions.**
   - La permutation d'état est écrite comme (pc_fin, ts_end) et lue comme (pc_init, ts_start). Le vérifieur ajoute l'entrée INITIAL et la lecture FINAL. Comme les timestamps croissent strictement sans rebouclage, les lignes forment une seule chaîne.
   - Le décodeur est un lookup logUp de multiplicité `execute`. La clé est (pc_lo, pc_hi, rs1, rs2, rd, rd_is_zero, imm_lo, imm_hi, funct3, family_mask), comparée à une table prétraitée par famille dans le setup. Les entrées non supportées sont remplies avec p−1 et donc inatteignables. Le contrôle d'équilibre sur la dernière ligne et sur zéro est présent.
   - Les caps de setup sont dans le transcript de chaque circuit et hachées dans les paramètres de sortie. `process_binary_into_separate_tables_ext` vérifie que chaque PC appartient à exactement une famille. Le masque de famille est décomposé en bits booléens.
   - Une ligne de la famille X ne peut pas exécuter un PC de la famille Y, ni un PC hors programme.

4. **Délégation.**
   - Les demandes sont protégées : `execute_delegation = table_bit·is_csrrw`, `execute_delegation·(1−execute) = 0`, et delegation_type égale csr_index quand la demande est active (`shift_binary_csr.rs:654-684`). Le timestamp de la demande vaut start + 3 (le code généré le confirme : `+3u32`) et `abi_offset = 0`.
   - Le type de délégation est une constante du vérifieur pour chaque circuit de délégation. Les demandes sont uniques par timestamp, et l'assertion total des réponses < p est présente. Les demandes ne peuvent donc pas être perdues, dupliquées ni traitées par le mauvais type.
   - Les challenges de délégation, de mémoire et d'état sont recoupés avec le transcript global.

   **(Note de l'orchestrateur : l'agent n'a contrôlé la garde que dans `shift_binary_csr`. C'est justement celle qui manque dans `unified_reduced_machine`. Ce résultat est donc cohérent avec le candidat C.)**

**Non-problèmes, pour information :**
- `transform_bytecode_decoding_via_lookup` (`everywhere_except_last.rs:1938`) contient `todo!()`, et `compile_executor_circuit` vaut `unreachable!`. Les deux sont du code mort et doivent le rester.
- Le commentaire de `unrolled_proof_statement.rs` (~l.444) dit « we do have contribution from setup values » ; il faudrait « do not ».
- `from_aux_values_one_before_last_row` parse les valeurs de teardown avec vérification. Cela ne peut provoquer qu'un panic, donc un problème de vivacité et pas de soundness.
- Les loads depuis la ROM font une lecture RAM à l'adresse ROM et jettent la valeur. Il faut donc que ces adresses aient été initialisées paresseusement : question de complétude uniquement.

**Non couvert :**
- les range checks du next-PC de chaque famille (par exemple la limbe haute de JALR/JAL issue de la relation d'addition de l'opt_ctx) ; le lookup du décodeur et le découpage du PC final empêchent de toute façon d'exécuter un PC hors bornes, c'est donc de la défense en profondeur ;
- le patch de `is_register` dans les load/store du circuit reduced/unified (`ops/load.rs`, `ops/store.rs`) ;
- l'intérieur des circuits de délégation (exclu du périmètre) ;
- la correspondance entre les quotients générés et le générateur pour toutes les familles (seuls shift_binary_csr et inits_and_teardowns ont été contrôlés) ;
- le générateur de témoins et le prouveur GPU.

## F. Agent argument de lookup, compilateur et optimiseur

Résultat : rien ne survit. L'agent n'a trouvé aucune faille exploitable dans la couche lookup/argument/compilateur ; chaque candidat a été examiné puis réfuté. **CONFIRMED :** aucun. **PLAUSIBLE :** aucun.

**Problèmes latents (inatteignables en production aujourd'hui ; durcissement uniquement) :**
- **L1. Aucun contrôle de booléanité sur la retenue du premier accès indirect.** `verifier_generator/src/inlining_generator/everywhere_except_last.rs:1572,1612` n'ajoute `carry*(carry-1)` que si `idx > 0`. Or `compile_layout.rs:~420` attribue une colonne de retenue à tout premier accès indirect qui a `offset_constant != 0` et `!assume_no_alignment_overflow`, et `cs_reference.rs:296+` ne l'interdit pas.
  - Si un tel accès existait, le prouveur pourrait poser carry = 2^15 (2^-16 ≡ 2^15 mod p). L'adresse dérivée deviendrait (hi + 2^15, lo + off − 1), ce qui passe les deux range checks d'adresse sur 16 bits.
  - Aucun des trois layouts de délégation en production (bigint_with_control, blake2_with_compression, keccak_special5) n'a de colonne de retenue sur un accès indirect, donc ce n'est pas atteignable.
- **L2. Les chemins du vérifieur en cas de paire nulle paniqueraient.** Un nombre impair de range-check-16 rend `remainder_for_range_check_16` Some, et le générateur tombe sur `todo!()` (mod.rs:~291, first_or_last_rows.rs:~290). L'échec est bruyant, à la génération, et non silencieux ; tous les layouts générés ont `remainder: None`.

  Par ailleurs, la contrainte de somme des lookups génériques n'existe que si les polynômes de multiplicité existent. Des lookups de largeur 3 avec `total_tables_size == 0` ne seraient donc jamais sommés, mais aucun circuit n'a cette combinaison.
- **L3. Le contrôle du nombre de lookups est fait avant le padding.** `compile_layout.rs:1029` duplique la dernière expression de range-check-16 après que l'assertion `< p` sur le nombre (layout_utils.rs:~680) a déjà été évaluée. La borne est donc décalée d'une unité, avec une marge énorme dans tous les vrais circuits.

**Vérifié et sain :**
- **Rebouclage des multiplicités LogUp.** Chaque somme de lookup est vérifiée dans chaque preuve. `last_row_and_zero` exige que `Σmult_acc − Σlookup_acc` s'annule en x=0 et sur la dernière ligne, donc la somme sur les autres lignes est nulle. Il y a des sommes séparées pour range-check-16 (adresses lazy-init comprises), timestamps, lookups génériques et décodeur.
  - Le compilateur vérifie `#lookups × trace_len < p` pour range-check-16 (y compris les contrôles lazy-init supplémentaires), les timestamps et les lookups génériques (layout_utils.rs:680/790/920, decoder_compilation). Le vérifieur est généré avec un `TRACE_LEN_LOG2` fixe, donc la borne est bien appliquée en pratique ; le nombre de circuits n'y change rien. Des multiplicités à valeur dans le corps n'aident pas : une valeur hors table demanderait au moins p occurrences.
  - Côté lookup, les numérateurs valent exactement 1 (pour une paire : a+b+2γ sur (γ+a)(γ+b), avec un oracle c = a·b vérifié). Le numérateur du décodeur est `execute`, contraint à être booléen (cs_reference.rs:~757). Le prédicat du processeur de délégation est booléen dans le code des conventions RAM.
  - LogUp de délégation entre circuits : le faire reboucler demanderait p tuples (type, offset, timestamp) identiques, ce que la cohérence des timestamps et de la mémoire exclut.
- **Encodage.** L'encodage de largeur 3 est `src0 + c0·src1 + c1·src2 + c2·table_id + γ`, avec γ dans l'extension quartique : collisions et dénominateurs nuls sont négligeables. Les range checks de largeur 1 sont dans des sommes distinctes de celles de largeur 3, donc les tuples `LookupInput::empty()` ne peuvent pas entrer en collision d'un argument à l'autre.
  - Le padding du setup vaut 0 pour les tables range-check-16 et timestamp (0 est une valeur valide), (0,0,0, id 0) pour les tables génériques (c'est la table ZeroEntry), et p−1 pour la table du décodeur. La dernière ligne du setup est entièrement nulle et non contrainte, mais elle est exclue par le contrôle S(last)=0.
- **Compilation des range checks.**
  - Les contrôles sur 8 bits deviennent des lookups RangeCheckSmall `[a,b,0]` dans `finalize()`, et le contenu de la table correspond.
  - Les contrôles sur 16 bits vont dans `range_check_16_lookup_expressions` sur tous les chemins : compile_layout (délégation), bytecode_preprocessed_executor, init/teardown, et adresses lazy-init via leur chemin dédié.
  - Les 12 layouts générés de `circuit_defs/*/generated` ont été recoupés avec leurs quotients : le nombre de paires correspond exactement (décalage constant de 7), et les copies sous `verifier/src/generated` sont identiques octet pour octet.
  - La colonne de multiplicité est toujours présente là où il existe des expressions.
- **Optimiseur** (`optimize_out_linear_constraints`).
  - Il ne touche que des variables non encore placées, et il tourne après le placement des range checks, des lookups, de la mémoire, de l'état et des booléens. Il ne peut donc jamais substituer une variable range-checkée ou issue d'un lookup.
  - La substitution est exacte : x = −L/a à partir d'une contrainte linéaire de définition, réécrite partout où le degré ≤ 2 le permet, et la contrainte de définition n'est retirée qu'ensuite.
  - Un usage restant de x² ou une contrainte constante fait paniquer le générateur (`OptimizedOut` est inatteignable, le degré 0 aussi). Les placeholders et les entrées/sorties d'état sont exclus.
  - L'option `prevent_optimizations` est respectée.
- **OptimizationContext.** `enforce_all` utilise une sélection orthogonale avec repli sur 0/ZeroEntry. Un trou dans les indices provoque un panic au lieu de faire disparaître quoi que ce soit. `u16_range_check_relations` est du code mort (jamais alimenté). Les morceaux découpés sur 8 bits sont range-checkés dès leur allocation.
- **Générateur du vérifieur.** `guess_transform_squaring` vérifie exactement chaque terme quadratique. Une contrainte booléenne est émise par colonne booléenne, et le même nombre est retiré de la liste des contraintes de degré 2.
- **Bords.** Toutes les contraintes s'appliquent partout sauf sur la dernière ligne. La dernière ligne est exclue du grand produit (Z(next)=Z·Q sur les lignes 0..n−2), de toutes les sommes de lookup et de la somme de délégation. Aucune entrée publique ne se trouve sur la dernière ligne.

**Non couvert / hors périmètre :**
- le range check du PC et du décodeur par famille (par exemple shift_binop n'a aucun contrôle 16 bits et s'appuie sur des sorties de lookup ; `bump_pc_no_range_checks` utilise une retenue booléenne) : c'est du niveau circuit ;
- les contraintes d'offset `variable_dependent` de Keccak (intérieur des délégations) ;
- l'ordre lazy-init entre circuits et la sémantique du padding à l'adresse 0 ;
- l'ajustement c0==0 des oracles du stage 2 sur le corps de base dans FRI/DEEP ;
- le prouveur GPU ;
- la liaison des caps de setup (seulement survolée) : `full_statement_verifier` compare les caps.

## G. Agents encore en cours au moment de l'export
- **PoC des paliers 1 et 2** → `airbender-v2-padding-delegation/poc.md` : pas fini.
- **Impact, variante −1, usage en production, doublons** → `airbender-v2-padding-delegation/impact-notes.md` : pas fini.
- **Variantes padding dans tous les circuits** → `airbender-v2-padding-variants.md` : pas fini.
