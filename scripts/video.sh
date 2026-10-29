#!/usr/bin/env bash
# Exploitation de video.manga-pics.com sur work : social-media (sm) et MoneyPrinterTurbo (mpt).
# Alias (ajouté au ~/.bashrc par l'installation) : video <commande> [sm|mpt|all] [service]
#   video status            état des conteneurs + santé HTTP publique
#   video logs sm ui-service  logs suivis (Ctrl-C pour sortir) ; sans service = toute la pile
#   video restart mpt       redémarre une pile (ou un service)
#   video up|down|build|pull-src|config [sm|mpt|all]
set -euo pipefail

ROOT="${VIDEO_ROOT:-$HOME/workspace/social-media-org}"
DC="$ROOT/docker-compose"

compose() {  # compose <sm|mpt> <args...>
  local app="$1"; shift
  case "$app" in
    sm)  docker compose --project-directory "$DC" -f "$DC/docker-compose.yml" -f "$DC/docker-compose.work.yml" --env-file "$DC/.env" "$@" ;;
    mpt) docker compose --project-directory "$DC/moneyprinter" -f "$DC/moneyprinter/docker-compose.yml" --env-file "$DC/.env" "$@" ;;
    *)   echo "pile inconnue : $app (sm|mpt)" >&2; return 2 ;;
  esac
}

targets() { [ "${1:-all}" = all ] && echo "sm mpt" || echo "$1"; }

health() {
  local host; host="$(grep -E '^PUBLIC_HOST=' "$DC/.env" | cut -d= -f2)"
  local auth; auth="$(cat "$DC/.basic_auth_plain" 2>/dev/null || true)"
  # origine = Traefik local (contourne Cloudflare) ; public = via Cloudflare
  printf '  %-30s %-8s %s\n' chemin origine public
  for path in /socialmedia/ /socialmedia/api/health /socialmedia/youtube/health /moneyprinter/; do
    printf '  %-30s %-8s %s\n' "$path" \
      "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 --resolve "$host:443:127.0.0.1" ${auth:+-u "$auth"} "https://$host$path")" \
      "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 ${auth:+-u "$auth"} "https://$host$path")"
  done
}

cmd="${1:-status}"; app="${2:-all}"; svc="${3:-}"
case "$cmd" in
  status|ps)
    for a in $(targets "$app"); do echo "== $a"; compose "$a" ps --format 'table {{.Service}}\t{{.Status}}'; done
    echo "== santé HTTP (attendu 200)"; health
    echo "== mémoire"; docker stats --no-stream --format '{{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' | grep -E 'ui-|service|generator|moneyprinter' || true ;;
  logs)
    [ "$app" = all ] && { echo "précisez sm ou mpt" >&2; exit 2; }
    compose "$app" logs -f --tail=100 ${svc:+"$svc"} ;;
  restart) for a in $(targets "$app"); do compose "$a" restart ${svc:+"$svc"}; done ;;
  up)      for a in $(targets "$app"); do compose "$a" up -d ${svc:+"$svc"}; done ;;
  down)    for a in $(targets "$app"); do compose "$a" down; done ;;
  build)   for a in $(targets "$app"); do compose "$a" up -d --build ${svc:+"$svc"}; done ;;
  config)  for a in $(targets "$app"); do compose "$a" config --quiet && echo "$a : compose valide"; done ;;
  health)  health ;;
  pull-src) git -C "$ROOT/MoneyPrinterTurbo" pull --ff-only ;;  # MPT est public ; les dépôts social-media arrivent par scp
  *) sed -n '2,8p' "$0"; exit 2 ;;
esac
