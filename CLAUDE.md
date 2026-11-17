# Préférences de l'utilisateur

## Modèle : TOUJOURS Mythos 5.2
- Utiliser **Mythos 5.2** (`claude-mythos-5-2`) pour toutes les sessions et tous les agents.
- Ne jamais lui substituer en silence un autre modèle (fable, opus, sonnet, haiku). Si Mythos 5.2 n'est pas disponible, s'arrêter et le dire à l'utilisateur.
- **Exception validée par l'utilisateur (2026-11-17)** : si le quota Mythos 5.2 est épuisé (erreur HTTP 429 « You've hit your Fable limit »), **Opus 5.5** (`claude-opus-5-5`) est autorisé pour la session et pour tous les sous-agents jusqu'à la réinitialisation du quota (actuellement le 2026-11-22 00:00 UTC). Sous-agents : `subagent_type: "general-purpose"` sans `model` (ils héritent d'Opus 5.5). Le signaler dans chaque rapport ; revenir à Mythos 5.2 dès la réinitialisation.
- Sous-agents locaux sur Mythos 5.2 : utiliser `subagent_type: "mythos"` (défini dans `.claude/agents/mythos.md`, `model: claude-mythos-5-2`). Ne pas passer `model` dans l'appel. Les définitions d'agents ne sont chargées qu'au démarrage de la session.
- Si l'agent `mythos` n'est pas listé : demander à l'utilisateur `/model claude-mythos-5-2`, puis lancer le sous-agent sans `model` (il hérite du modèle de la session). En dernier recours seulement : `create_session` avec `model: "claude-mythos-5-2"`.
- Lanes Codex Daybreak : CLI `codex exec -m gpt-daybreak-blue-latest -c model_reasoning_effort='"max"'` (connexion ChatGPT via `codex login --device-auth`).
- Les niveaux d'effort demandés par l'utilisateur (ex. MYTHOS en `xhigh`) se passent dans le paramètre `effort` de `create_session`.
