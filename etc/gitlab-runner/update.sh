#!/bin/sh

JQ="/etc/gitlab-runner/jq"

function upgrade() {
        local ambiente=$1
        local service=$2

        if [[ ! $ambiente || ! $service ]]; then
                exit 1
        fi

        CATTLE_ACCESS_KEY="B2E3AC790938892B70C1"
        CATTLE_SECRET_KEY="7kaoi7gV7odGwXCADZqQfBon3o4gc1k5B9xxBHUu"
        RANCHER_API_URL="http://dese.paas.sefaz.ce.gov.br:8080/v1"

        local inServiceStrategy=$(curl -s -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" \
                -X GET \
                -H 'Accept: application/json' \
                -H 'Content-Type: application/json' \
                "${RANCHER_API_URL}/projects/${ambiente}/services/${service}/" | $JQ '.upgrade.inServiceStrategy')

        local updatedServiceStrategy=${inServiceStrategy}

        curl -s -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" \
                -X POST \
                -H 'Accept: application/json' \
                -H 'Content-Type: application/json' \
                -d "{
                        \"inServiceStrategy\": ${updatedServiceStrategy}
                        }
                }" \
                "${RANCHER_API_URL}/projects/${ambiente}/services/${service}/?action=upgrade" > /dev/null
}

function finish_upgrade() {
        local ambiente=$1
        local service=$2

        while true; do
                local serviceState=`curl -s -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" \
                -X GET \
                -H 'Accept: application/json' \
                -H 'Content-Type: application/json' \
                "${RANCHER_API_URL}/projects/${ambiente}/services/${service}/" | $JQ '.state'`

                case $serviceState in
                        "\"upgraded\"" )
                        echo " Servico atualizado !"
                        curl -s -u "${CATTLE_ACCESS_KEY}:${CATTLE_SECRET_KEY}" \
                                -X POST \
                                -H 'Accept: application/json' \
                                -H 'Content-Type: application/json' \
                                -d '{}' \
                                "${RANCHER_API_URL}/projects/${ambiente}/services/${service}/?action=finishupgrade" > /dev/null
                        break ;;

                        "\"upgrading\"" )
                        echo -n "."
                        sleep 3
                        continue ;;

                        *)
                        echo "unexpected upgrade state: $serviceState"
                        break ;;
                esac
        done
}

