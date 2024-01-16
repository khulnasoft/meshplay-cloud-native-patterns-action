#!/usr/bin/env bash

SCRIPT_DIR=$(dirname -- "$(readlink -f "${BASH_SOURCE[0]}" || realpath "${BASH_SOURCE[0]}")")

declare -A adapters
adapters["istio"]=meshplay-istio:10000
adapters["linkerd"]=meshplay-linkerd:10001
adapters["consul"]=meshplay-consul:10002
adapters["network_service_mesh"]=meshplay-nsm:10004
adapters["kuma"]=meshplay-kuma:10007
adapters["cpx"]=meshplay-cpx:10008
adapters["open_service_mesh"]=meshplay-osm:10009

main() {

	local pattern_file=
	local pattern_url=

	parse_command_line "$@"

	docker network connect bridge meshplay_meshplay_1
	docker network connect minikube meshplay_meshplay_1

	for mesh in "${!adapters[@]}"
		do
			shortName=$(echo ${adapters["$mesh"]} | cut -d '-' -f2 | cut -d ':' -f1)
			docker network connect bridge meshplay_meshplay-"$shortName"_1
			docker network connect minikube meshplay_meshplay-"$shortName"_1
		done

	meshplayctl system config minikube -t ~/auth.json

	if [ -z "$pattern_file" ]
	then
		meshplayctl pattern apply --file $pattern_url -t ~/auth.json
	else
		meshplayctl pattern apply --file $pattern_file -t ~/auth.json
	fi

	sleep 30s
	kubectl get all --all-namespaces
}

parse_command_line() {
	while :
	do
		case "${1:-}" in
			--pattern-file)
				if [[ -n "${2:-}" ]]; then
					pattern_file=$2
					shift
				else
					echo "ERROR: '--pattern-file' cannot be empty." >&2
					exit 1
				fi
				;;
			--pattern-url)
				if [[ -n "${2:-}" ]]; then
					pattern_url=$2
					shift
				else
					echo "ERROR: '--pattern-url' cannot be empty." >&2
					exit 1
				fi
				;;
			*)
				break
				;;
		esac
		shift
	done
}

main "$@"
