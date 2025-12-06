#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' 


POSTGRES_HOST="${POSTGRES_HOST:-localhost}"
POSTGRES_PORT="${POSTGRES_PORT:-5432}"
POSTGRES_DB="${POSTGRES_DB:-athiedocs}"
POSTGRES_USER="${POSTGRES_USER:-n8nathie}"
POSTGRES_SCHEMA="${POSTGRES_SCHEMA:-n8n_athie_schema}"


echo -e "${BLUE}=============================================${NC}"
echo -e "${BLUE}  Popular Critérios de Avaliação${NC}"
echo -e "${BLUE}  N8N Document Validation System${NC}"
echo -e "${BLUE}=============================================${NC}"
echo ""


SQL_FILE="database/seed-criterios.sql"

if [ ! -f "$SQL_FILE" ]; then
    echo -e "${RED}❌ Erro: Arquivo $SQL_FILE não encontrado!${NC}"
    echo ""
    echo -e "${YELLOW}💡 Certifique-se de estar na raiz do projeto.${NC}"
    exit 1
fi

echo -e "${YELLOW}📄 Arquivo SQL encontrado: ${NC}$SQL_FILE"
echo -e "${YELLOW}🗄️  Banco de dados: ${NC}$POSTGRES_DB"
echo -e "${YELLOW}👤 Usuário: ${NC}$POSTGRES_USER"
echo -e "${YELLOW}🏠 Host: ${NC}$POSTGRES_HOST:$POSTGRES_PORT"
echo ""


read -p "$(echo -e ${YELLOW}Deseja executar o script SQL? [s/N]: ${NC})" -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Ss]$ ]]; then
    echo -e "${YELLOW}⏸️  Operação cancelada pelo usuário.${NC}"
    exit 0
fi

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}📊 Executando seed de critérios...${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""


PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f "$SQL_FILE"


if [ $? -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Critérios populados com sucesso!${NC}"
    echo ""
    
    
    echo -e "${YELLOW}📊 Resumo dos critérios inseridos:${NC}"
    echo ""
    
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "
    SELECT 
        tipo_documento, 
        COUNT(*) as total_criterios
    FROM $POSTGRES_SCHEMA.criterios_documento
    GROUP BY tipo_documento
    ORDER BY tipo_documento;
    "
    
    echo ""
    echo -e "${GREEN}✅ Total de tipos de documentos com critérios:${NC}"
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "$POSTGRES_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c "
    SELECT COUNT(DISTINCT tipo_documento) 
    FROM $POSTGRES_SCHEMA.criterios_documento;
    "
    
    echo ""
    echo -e "${YELLOW}💡 Para verificar os critérios de um tipo específico:${NC}"
    echo "   SELECT * FROM $POSTGRES_SCHEMA.criterios_documento WHERE tipo_documento = 'ASO';"
    echo ""
    
    exit 0
else
    echo ""
    echo -e "${RED}❌ Erro ao executar o script SQL!${NC}"
    echo ""
    echo -e "${YELLOW}💡 Possíveis causas:${NC}"
    echo "   - Senha incorreta (configure POSTGRES_PASSWORD no .env)"
    echo "   - Banco de dados não existe"
    echo "   - PostgreSQL não está rodando"
    echo "   - Permissões insuficientes"
    echo ""
    echo -e "${YELLOW}💡 Para testar a conexão:${NC}"
    echo "   PGPASSWORD=\"\$POSTGRES_PASSWORD\" psql -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER -d $POSTGRES_DB -c 'SELECT 1;'"
    echo ""
    
    exit 1
fi
