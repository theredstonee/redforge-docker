#!/bin/sh
# RedForge: startet Gitea wie gewohnt und legt beim ersten Start einen internen Verwaltungs-Zugang an,
# mit dem die RedForge-App Gitea steuert (Nutzer anlegen, OAuth-App, Import). Der Token liegt nur im
# internen Volume /rf-intern, das allein Gitea und die App sehen.
# Fehler beim Zugang dürfen Gitea nie beenden: dann fehlt nur der Zugang, und die App meldet das.
set -u

INTERN=/rf-intern
SYSTEM=rf-system

/usr/local/bin/docker-entrypoint.sh "$@" &
pid=$!
trap 'kill -TERM "$pid" 2>/dev/null; wait "$pid"; exit $?' TERM INT

bereit() { curl -fs -o /dev/null http://127.0.0.1:3000/api/healthz 2>/dev/null; }

i=0
until bereit; do
	if ! kill -0 "$pid" 2>/dev/null; then
		wait "$pid"
		exit $?
	fi
	i=$((i + 1))
	if [ "$i" -gt 600 ]; then
		echo "[redforge] Gitea antwortet nach 10 Minuten nicht, Zugang wird beim nächsten Start angelegt." >&2
		break
	fi
	sleep 1
done

token_gueltig() {
	[ -s "$INTERN/token" ] || return 1
	curl -fs -o /dev/null -H "Authorization: token $(cat "$INTERN/token")" http://127.0.0.1:3000/api/v1/user 2>/dev/null
}

zugang_einrichten() {
	if ! gitea admin user list --admin 2>/dev/null | awk 'NR > 1 { print $2 }' | grep -qx "$SYSTEM"; then
		gitea admin user create --admin --username "$SYSTEM" --email "$SYSTEM@redforge.invalid" \
			--random-password --random-password-length 48 --must-change-password=false >/dev/null || return 1
	fi
	t=$(gitea admin user generate-access-token --username "$SYSTEM" --token-name "redforge-$(date +%s)" --scopes all --raw) || return 1
	[ -n "$t" ] || return 1
	(umask 077 && printf '%s' "$t" > "$INTERN/token.neu") || return 1
	mv -f "$INTERN/token.neu" "$INTERN/token" || return 1
}

if bereit && ! token_gueltig; then
	if zugang_einrichten; then
		echo "[redforge] Interner Zugang eingerichtet."
	else
		echo "[redforge] FEHLER: Interner Zugang konnte nicht eingerichtet werden (Rechte von $INTERN?)." >&2
	fi
fi

wait "$pid"
