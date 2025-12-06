#!/bin/bash







GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 


N8N_HOST="${N8N_HOST:-localhost}"
N8N_PORT="${N8N_PORT:-5678}"
WEBHOOK_URL="http://${N8N_HOST}:${N8N_PORT}/webhook/receber-documento"
API_KEY="${WEBHOOK_API_KEY:-sua-api-key-aqui}"
EMAIL_TESTE="${EMAIL_TESTE:-athiewohnrath.trajano@gmail.com}"


echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Test Script - Webhook Principal${NC}"
echo -e "${BLUE}  N8N Document Validation System${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""


if [ -z "$1" ]; then
    echo -e "${YELLOW}Uso:${NC}"
    echo "  $0 aminho-do-arquivo>"
    echo ""
    echo -e "${YELLOW}Exemplos:${NC}"
    echo "  $0 samples/Documentos\ Aprovados/ASO_valido.pdf"
    echo "  $0 samples/Documentos\ Reprovados/ASO_invalido.pdf"
    echo ""
    echo -e "${YELLOW}Ou teste todos os arquivos de uma pasta:${NC}"
    echo "  $0 samples/Documentos\ Aprovados/*.pdf"
    echo ""
    exit 1
fi


test_file() {
    local FILE="$1"
    
    
    if [ ! -f "$FILE" ]; then
        echo -e "${RED}❌ Erro: Arquivo não encontrado: $FILE${NC}"
        return 1
    fi
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📄 Testando:${NC} $(basename "$FILE")"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    
    echo -e "${YELLOW}📊 Informações do arquivo:${NC}"
    echo "   Nome: $(basename "$FILE")"
    echo "   Tamanho: $(du -h "$FILE" | cut -f1)"
    echo "   Tipo: $(file -b --mime-type "$FILE")"
    echo ""
    
    
    echo -e "${YELLOW}📤 Enviando para: ${NC}$WEBHOOK_URL"
    echo -e "${YELLOW}🔑 API Key: ${NC}${API_KEY:0:10}...${API_KEY: -4}"
    echo -e "${YELLOW}📧 Email: ${NC}$EMAIL_TESTE"
    echo ""
    
    RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$WEBHOOK_URL" \
        -H "X-API-Key: $API_KEY" \
        -F "arquivo=@$FILE" \
        -F "email_fornecedor=$EMAIL_TESTE")
    
    
    HTTP_BODY=$(echo "$RESPONSE" | head -n -1)
    HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
    
    echo -e "${YELLOW}📥 Resposta (HTTP $HTTP_CODE):${NC}"
    echo "$HTTP_BODY" | jq '.' 2>/dev/null || echo "$HTTP_BODY"
    echo ""
    
    
    if [ "$HTTP_CODE" -eq 200 ]; then
        DOCUMENTO_ID=$(echo "$HTTP_BODY" | jq -r '.documento_id' 2>/dev/null)
        STATUS=$(echo "$HTTP_BODY" | jq -r '.status' 2>/dev/null)
        
        echo -e "${GREEN}✅ Sucesso!${NC}"
        echo -e "${GREEN}   Documento ID: ${NC}$DOCUMENTO_ID"
        echo -e "${GREEN}   Status: ${NC}$STATUS"
        echo ""
        echo -e "${YELLOW}💡 Para acompanhar o processamento:${NC}"
        echo "   SELECT * FROM n8n_athie_schema.documentos WHERE id = '$DOCUMENTO_ID';"
        echo ""
        echo -e "${YELLOW}💡 Para ver os logs:${NC}"
        echo "   SELECT * FROM n8n_athie_schema.logs_processamento WHERE documento_id = '$DOCUMENTO_ID' ORDER BY timestamp;"
        echo ""
        
        return 0
    else
        echo -e "${RED}❌ Erro HTTP $HTTP_CODE${NC}"
        return 1
    fi
}


SUCCESS_COUNT=0
FAIL_COUNT=0
TOTAL_COUNT=0

for FILE in "$@"; do
    ((TOTAL_COUNT++))
    
    if test_file "$FILE"; then
        ((SUCCESS_COUNT++))
    else
        ((FAIL_COUNT++))
    fi
    
    
    if [ $TOTAL_COUNT -lt $# ]; then
        echo -e "${YELLOW}⏳ Aguardando 2 segundos antes do próximo teste...${NC}"
        echo ""
        sleep 2
    fi
done


echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  RESUMO DOS TESTES${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}Total testados:${NC} $TOTAL_COUNT"
echo -e "${GREEN}Sucessos:${NC} $SUCCESS_COUNT"
echo -e "${RED}Falhas:${NC} $FAIL_COUNT"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""


if [ $FAIL_COUNT -eq 0 ]; then
    exit 0
else
    exit 1
fi
