#!/bin/bash







GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 


N8N_HOST="${N8N_HOST:-localhost}"
N8N_PORT="${N8N_PORT:-5678}"
WEBHOOK_URL="http://${N8N_HOST}:${N8N_PORT}/webhook/decisao-sst"
API_KEY="${WEBHOOK_SST_API_KEY:-sua-api-key-sst-aqui}"
REVISOR_EMAIL="${REVISOR_EMAIL:-athiewohnrath.trajano@gmail.com}"
REVISOR_NOME="${REVISOR_NOME:-Willy Trajano - Eng. SST}"


echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Test Script - Decisão Manual SST${NC}"
echo -e "${BLUE}  N8N Document Validation System${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""


if [ -z "$1" ] || [ -z "$2" ]; then
    echo -e "${YELLOW}Uso:${NC}"
    echo "  $0 <decisao> <documento_id> [observacoes]"
    echo ""
    echo -e "${YELLOW}Parâmetros:${NC}"
    echo "  decisao      : 'aprovar' ou 'recusar'"
    echo "  documento_id : UUID do documento (36 caracteres)"
    echo "  observacoes  : Texto opcional com justificativa"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  $0 aprovar 0983a6cb-2896-4b78-96b9-a31c6e90410b"
    echo "  $0 recusar 0983a6cb-2896-4b78-96b9-a31c6e90410b 'Assinatura ilegível'"
    echo ""
    echo -e "${YELLOW}💡 Para buscar documentos pendentes de revisão:${NC}"
    echo "  SELECT id, nome_arquivo, score, data_recebimento"
    echo "  FROM n8n_athie_schema.documentos"
    echo "  WHERE status = 'pendente_revisao'"
    echo "  ORDER BY data_recebimento DESC;"
    echo ""
    exit 1
fi

DECISAO="$1"
DOCUMENTO_ID="$2"
OBSERVACOES="${3:-Decisão tomada via script de teste}"


if [ "$DECISAO" != "aprovar" ] && [ "$DECISAO" != "recusar" ]; then
    echo -e "${RED}❌ Erro: Decisão deve ser 'aprovar' ou 'recusar'${NC}"
    exit 1
fi


if [ ${#DOCUMENTO_ID} -ne 36 ]; then
    echo -e "${RED}❌ Erro: documento_id deve ter 36 caracteres (UUID)${NC}"
    echo -e "${YELLOW}   Formato esperado: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx${NC}"
    exit 1
fi

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}⚖️  Tomando Decisão Manual SST${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""


echo -e "${YELLOW}📋 Dados da decisão:${NC}"
echo "   Documento ID: $DOCUMENTO_ID"
echo "   Decisão: $(echo $DECISAO | tr '[:lower:]' '[:upper:]')"
echo "   Revisor: $REVISOR_NOME"
echo "   Email: $REVISOR_EMAIL"
echo "   Observações: $OBSERVACOES"
echo ""


JSON_PAYLOAD=$(cat <<EOF
{
  "documento_id": "$DOCUMENTO_ID",
  "decisao": "$DECISAO",
  "revisor_email": "$REVISOR_EMAIL",
  "revisor_nome": "$REVISOR_NOME",
  "observacoes": "$OBSERVACOES"
}
EOF
)


echo -e "${YELLOW}📤 Enviando para: ${NC}$WEBHOOK_URL"
echo -e "${YELLOW}🔑 API Key: ${NC}${API_KEY:0:10}...${API_KEY: -4}"
echo ""

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WEBHOOK_URL" \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD")


HTTP_BODY=$(echo "$RESPONSE" | head -n -1)
HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)

echo -e "${YELLOW}📥 Resposta (HTTP $HTTP_CODE):${NC}"
echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"
echo ""


if [ "$HTTP_CODE" -eq 200 ]; then
    STATUS_ATUAL=$(echo "$HTTP_BODY" | jq -r '.status_atual' 2>/dev/null)
    
    if [ "$DECISAO" == "aprovar" ]; then
        echo -e "${GREEN}✅ Documento APROVADO manualmente!${NC}"
        echo -e "${GREEN}   Status atual: ${NC}$STATUS_ATUAL"
    else
        echo -e "${RED}❌ Documento RECUSADO manualmente!${NC}"
        echo -e "${RED}   Status atual: ${NC}$STATUS_ATUAL"
    fi
    
    echo ""
    echo -e "${YELLOW}💡 Para verificar o documento:${NC}"
    echo "   SELECT * FROM n8n_athie_schema.documentos WHERE id = '$DOCUMENTO_ID';"
    echo ""
    echo -e "${YELLOW}💡 Para ver a decisão registrada:${NC}"
    echo "   SELECT * FROM n8n_athie_schema.decisoes_sst WHERE documento_id = '$DOCUMENTO_ID';"
    echo ""
    
    exit 0
else
    echo -e "${RED}❌ Erro HTTP $HTTP_CODE${NC}"
    
    
    if [ "$HTTP_CODE" -eq 404 ]; then
        echo -e "${YELLOW}💡 Documento não encontrado. Verifique o ID.${NC}"
    elif [ "$HTTP_CODE" -eq 400 ]; then
        echo -e "${YELLOW}💡 Verifique se o documento está com status 'pendente_revisao'.${NC}"
    elif [ "$HTTP_CODE" -eq 401 ]; then
        echo -e "${YELLOW}💡 API Key inválida. Configure WEBHOOK_SST_API_KEY no .env${NC}"
    fi
    
    echo ""
    exit 1
fi
