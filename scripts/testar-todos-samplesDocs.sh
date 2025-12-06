#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 


echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Test All Samples${NC}"
echo -e "${BLUE}  N8N Document Validation System${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""


SAMPLES_DIR="samples"
APROVADOS_DIR="$SAMPLES_DIR/Documentos Aprovados"
REPROVADOS_DIR="$SAMPLES_DIR/Documentos Reprovados"


if [ ! -d "$SAMPLES_DIR" ]; then
    echo -e "${RED}❌ Erro: Pasta $SAMPLES_DIR não encontrada!${NC}"
    echo -e "${YELLOW}💡 Certifique-se de estar na raiz do projeto.${NC}"
    exit 1
fi

echo -e "${YELLOW}📁 Testando documentos das pastas:${NC}"
echo "   - $APROVADOS_DIR"
echo "   - $REPROVADOS_DIR"
echo ""


read -p "$(echo -e ${YELLOW}Deseja testar todos os documentos? [s/N]: ${NC})" -n 1 -r
echo ""
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}⏸️  Operação cancelada pelo usuário.${NC}"
    exit 0
fi


if [ -d "$APROVADOS_DIR" ]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  TESTANDO: DOCUMENTOS APROVADOS${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    find "$APROVADOS_DIR" -type f -name "*.pdf" | while read file; do
        ./scripts/test-webhook.sh "$file"
        echo ""
        echo -e "${YELLOW}⏳ Aguardando 3 segundos antes do próximo teste...${NC}"
        sleep 3
    done
fi


if [ -d "$REPROVADOS_DIR" ]; then
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}  TESTANDO: DOCUMENTOS REPROVADOS${NC}"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    find "$REPROVADOS_DIR" -type f -name "*.pdf" | while read file; do
        ./scripts/test-webhook.sh "$file"
        echo ""
        echo -e "${YELLOW}⏳ Aguardando 3 segundos antes do próximo teste...${NC}"
        sleep 3
    done
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}  TESTES CONCLUÍDOS!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}💡 Para ver todos os documentos processados:${NC}"
echo "   SELECT id, nome_arquivo, tipo_documento, status, score"
echo "   FROM n8n_athie_schema.documentos"
echo "   ORDER BY data_recebimento DESC LIMIT 20;"
echo ""
