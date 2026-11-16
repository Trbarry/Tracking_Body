# Préférences de l'utilisateur

## Modèle : TOUJOURS Mythos 5.2
- Utiliser **Mythos 5.2** (`claude-mythos-5-2`) pour toutes les sessions et tous les agents.
- Ne jamais lui substituer en silence un autre modèle (fable, opus, sonnet, haiku). Si Mythos 5.2 n'est pas disponible, s'arrêter et le dire à l'utilisateur.
- L'outil `Agent` (sous-agents) n'accepte que les alias `sonnet|opus|haiku|fable`. Pour lancer un agent sur Mythos 5.2, créer une session cloud avec `create_session` et `model: "claude-mythos-5-2"`, puis vérifier `last_served_model` via `get_session`.
- Les niveaux d'effort demandés par l'utilisateur (ex. MYTHOS en `xhigh`) se passent dans le paramètre `effort` de `create_session`.
