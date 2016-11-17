#!/bin/bash
#
. /etc/gitlab-runner/update.sh

REGISTRY=172.30.68.72:5000
URL_PROJETO="http://$(echo ${CI_BUILD_REPO} |awk -F'@' '{print $2}')"
BRANCH_PROJETO=${CI_BUILD_REF_NAME}
PROJETO=$(echo ${CI_BUILD_REPO} |awk -F'/' '{print $NF}' |awk -F'.git' '{print $1}' |sed 's/_//g; s/-//g')
IMAGEM=${REGISTRY}/${PROJETO}:${BRANCH_PROJETO}

if [[ ! $1 || ! $2 ]]; then exit 1; fi
ambiente=$1
servico=$2

echo "URL: ${URL_PROJETO} - Branch: ${BRANCH_PROJETO} - Projeto: ${PROJETO} - Imagem: ${IMAGEM}"

case $BRANCH_PROJETO in
        "master")
                echo "Fazendo build e armazenando imagem no resgistry"
                echo "Clonando o projeto " && git clone ${URL_PROJETO} && cd $(echo ${CI_BUILD_REPO} |awk -F'/' '{print $NF}' |awk -F'.git' '{print $1}')
                echo "Construindo imagem "
                IMAGEM_ID=$(sudo docker build . | tail -n 1 |awk '{print $NF}')
                sudo docker tag -f ${IMAGEM_ID} ${IMAGEM} && echo "Enviando imagem para o registry " && sudo docker push ${IMAGEM} && echo "Atualizando servicos " && upgrade $ambiente $servico && finish_upgrade $ambiente $servico

                # && sudo docker rmi ${IMAGEM} && cd .. && rm -rf $(echo ${CI_BUILD_REPO} |awk -F'/' '{print $NF}' |awk -F'.git' '{print $1}')
        ;;

        *)
                echo "Solicitando autorizacao para fazer build e armazenando imagem no resgistry"

        ;;
esac

