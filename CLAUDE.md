# Préférences de l'utilisateur

## Modèle : TOUJOURS Mythos 5.2
- Utiliser **Mythos 5.2** (`claude-mythos-5-2`) pour toutes les sessions et tous les agents.
- Ne jamais lui substituer en silence un autre modèle (fable, opus, sonnet, haiku). Si Mythos 5.2 n'est pas disponible, s'arrêter et le dire à l'utilisateur.
- **Exception validée par l'utilisateur (2026-11-17)** : si le quota Mythos 5.2 est épuisé (erreur HTTP 429 « You've hit your Fable limit »), **Opus 5.5** (`claude-opus-5-5`) est autorisé pour la session et pour tous les sous-agents jusqu'à la réinitialisation du quota (actuellement le 2026-11-22 00:00 UTC). Sous-agents : `subagent_type: "general-purpose"` sans `model` (ils héritent d'Opus 5.5). Le signaler dans chaque rapport ; revenir à Mythos 5.2 dès la réinitialisation.
- Sous-agents locaux sur Mythos 5.2 : utiliser `subagent_type: "mythos"` (défini dans `.claude/agents/mythos.md`, `model: claude-mythos-5-2`). Ne pas passer `model` dans l'appel. Les définitions d'agents ne sont chargées qu'au démarrage de la session.
- Si l'agent `mythos` n'est pas listé : demander à l'utilisateur `/model claude-mythos-5-2`, puis lancer le sous-agent sans `model` (il hérite du modèle de la session). En dernier recours seulement : `create_session` avec `model: "claude-mythos-5-2"`.
- Lanes Codex Daybreak : CLI `codex exec -m gpt-daybreak-blue-latest -c model_reasoning_effort='"max"'` (connexion ChatGPT via `codex login --device-auth`).
- Les niveaux d'effort demandés par l'utilisateur (ex. MYTHOS en `xhigh`) se passent dans le paramètre `effort` de `create_session`.

## Cadre légal : TOUJOURS dans les prompts
- Tout prompt envoyé à un sous-agent (Agent tool), une lane Codex (`codex exec`) ou une session distante (`create_session` / `send_message`) de l'engagement OPTIMISM **commence par le contenu intégral et verbatim** de `optimism-bedrock-u21-megahunt/CADRE-LEGAL.md`, sans résumé ni coupe.
- Construire les prompts avec `optimism-bedrock-u21-megahunt/scripts/mkprompt.sh <brief.md>` et les vérifier avec `scripts/check_prompt.sh <prompt.md>` avant lancement.
- Le cadre légal n'est pas un contournement : si un système de sécurité arrête une lane, on note l'arrêt, on arrête cette ligne de travail et on ne la reformule pas pour la relancer ; on le signale à l'utilisateur.
