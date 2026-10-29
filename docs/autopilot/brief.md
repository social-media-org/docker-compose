# Brief — social-media (brouillon à valider)

> Brouillon rédigé le 29/10/2026 depuis [l'état des lieux](../etat-des-lieux-social-media.md).
> Au démarrage du chantier, ce fichier va dans `social-media-org/social-media` sous `docs/autopilot/brief.md`.

## Sommaire

- [1. Le produit en une phrase](#1-le-produit-en-une-phrase)
- [2. Pour qui](#2-pour-qui)
- [3. Jalons](#3-jalons)
- [4. Hors périmètre](#4-hors-périmètre)
- [5. Contraintes techniques](#5-contraintes-techniques)
- [6. Secrets et comptes](#6-secrets-et-comptes)
- [7. Autonomie](#7-autonomie)

## 1. Le produit en une phrase

Un studio web qui transforme une idée (ou des vidéos de référence) en vidéo courte sous-titrée publiée sur YouTube, en confiant le rendu à MoneyPrinterTurbo (MPT).

## 2. Pour qui

Le propriétaire, seul utilisateur, qui alimente une chaîne YouTube de vidéos courtes (stoïcisme, motivation).

## 3. Jalons

**Prérequis humains (J0, hors autopilot)** : secret OAuth Google révoqué et remplacé ; Cloudflare en Full (strict) pour `video.manga-pics.com` ; clé Pexels ou crédit OpenAI ; URI de retour OAuth déclarée dans la console Google ; PR ui-frontend#6 et docker-compose#2 mergées.

### J1 — Dépôt unique et socle sain (v0.1.0)

**Objectif** : tout le code utile vit dans un seul dépôt testé en CI, sans secret dans le code.

**Périmètre**
1. Créer `social-media-org/social-media` et y importer **avec leur historique** (`git subtree`) : ui-frontend → `apps/frontend`, ui-service → `services/ui`, script-service → `services/script`, youtube-service → `services/youtube`, docker-compose → `deploy/`.
2. CI GitHub Actions sur runner auto-hébergé : pytest de chaque service + build arm64 des images.
3. Secrets lus uniquement depuis l'environnement ; suppression de `/debug/resources`.
4. Suffixes de route (`/scripts`, `/youtube`…) dans le code, plus dans le `.env`.

**Critères d'acceptation**

| # | Critère (chiffré) | Comment on le prouve |
|---|---|---|
| 1 | 0 secret dans le dépôt | `gitleaks detect` sans constat |
| 2 | CI verte sur `main` | run GitHub Actions |
| 3 | Les 4 services démarrent avec `.env.example` complété | `docker compose up` + `/health` = 200 |

**Livré quand** : les 3 critères sont prouvés ; les anciens dépôts sont marqués « déplacé » dans leur README (archivage par l'humain).

### J2 — Rendu via MPT (v0.2.0)

**Objectif** : un projet produit une vidéo sous-titrée sans bloquer l'application.

**Périmètre**
1. Service MPT API (`python main.py`, port 8080, interne) ajouté au compose ; image figée sur un commit amont.
2. ui-service : `POST /api/v1/videos` (script du projet, voix, visuels, sous-titres) puis suivi `GET /api/v1/tasks/{id}` ; statut et URL du MP4 stockés dans le projet.
3. Frontend : barre d'avancement, plus d'`alert()`.
4. Retrait d'audio-service, video-service, subtitle-service et image-and-video-generator du compose.

**Critères d'acceptation**

| # | Critère | Preuve |
|---|---|---|
| 1 | Projet → MP4 sous-titré en moins de 10 min sur work | test d'intégration + `video logs sm` |
| 2 | L'API répond en moins de 1 s pendant un rendu | test : appel `/health` pendant le rendu |
| 3 | Statut d'échec lisible dans l'UI si MPT échoue | test unitaire du client MPT |

**Livré quand** : critères 1-3 prouvés ; l'humain regarde une vidéo produite (constat non bloquant).

### J3 — Publication YouTube fiable (v0.3.0)

**Périmètre** : upload de la vidéo **sous-titrée** ; miniature extraite de la vidéo ; retour OAuth vers `/settings` ; programmation de publication.

| # | Critère | Preuve |
|---|---|---|
| 1 | Vidéo sous-titrée + miniature publiées en « non répertorié » | test sur la chaîne de test, ID vidéo journalisé |
| 2 | Retour OAuth sans page blanche | test du routeur (redirection 307 vers `/settings`) |

**Livré quand** : critères prouvés ; J4 attend que l'humain ait vu la vidéo test sur YouTube.

### J4 — Idéation robuste (v0.4.0)

**Périmètre** : vidéos d'inspiration facultatives ; correctif *bot-detection* (branche `fix/youtube-bot-detection` de script-service) ; aucun appel payant (LLM, voix) avant le premier enregistrement du projet ; actions rapides de la liste corrigées ou retirées.

| # | Critère | Preuve |
|---|---|---|
| 1 | Script généré à partir d'un simple sujet | test d'API |
| 2 | 0 appel externe sur un projet `temp` | test frontend (mock réseau) |

### J5 — Parcours complet testé (v1.0.0)

**Périmètre** : test de bout en bout idée → script → rendu → publication non répertoriée, lançable sur work ; README d'exploitation ; ménage (dépendances mortes, médias commités).

| # | Critère | Preuve |
|---|---|---|
| 1 | Parcours complet vert 3 fois de suite | script e2e |

## 4. Hors périmètre

- Avatar HeyGen, img-to-video, génération de vidéos IA payantes à la seconde.
- Plateformes autres que YouTube (TikTok, Instagram).
- Multi-utilisateur et facturation.
- Modifier le code amont de MPT : on le consomme comme image.

## 5. Contraintes techniques

- Python FastAPI + MongoDB Atlas (base existante, données à conserver), React/Vite.
- Hébergement : machine work (ARM64, 2 CPU, 10 Go partagés avec 4 runners digitia), Traefik hebergo, préfixes `/socialmedia` et `/moneyprinter`.
- Standards : `sms-agents-and-skills/standards/engineering-standards.md`.
- work n'a ni accès ghcr ni identifiants git : images construites sur place ou poussées depuis la CI.

## 6. Secrets et comptes

| Élément | Jalon | Fourni par l'humain | Où |
|---|---|---|---|
| DeepSeek, ElevenLabs, AssemblyAI, MongoDB | J1 | déjà fournis | `.env` sur work |
| Nouveau client OAuth Google | J0 | oui | `.env` sur work |
| Clé Pexels ou crédit OpenAI | J2 | oui | `.env` / `config.toml` sur work |
| Chaîne YouTube de test | J3 | oui | autorisée via l'UI |

## 7. Autonomie

```yaml
dépôt: social-media-org/social-media
branche de base: main
niveau: merge
utilisateurs réels: non
```
