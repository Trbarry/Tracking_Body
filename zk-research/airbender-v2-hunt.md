# Chasse Airbender V2 : classe « valeur ou écriture non contrainte »

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
