# 🖨️ N8N Document Validation System - Athié Wohnrath

**Sistema Automatizado de Validação de Documentos Trabalhistas**

[![N8N](https://img.shields.io/badge/N8N-Workflow-EA4B71?logo=n8n)](https://n8n.io)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791?logo=postgresql)](https://www.postgresql.org/)
[![Google Drive](https://img.shields.io/badge/Google_Drive-Storage-4285F4?logo=google-drive)](https://drive.google.com)
[![OpenRouter](https://img.shields.io/badge/OpenRouter-API-411B7B)](https://openrouter.ai/)
[![Gemini AI](https://img.shields.io/badge/Gemini-2.0_Flash-8E75B2?logo=google)](https://ai.google.dev/)
[![Gmail](https://img.shields.io/badge/Gmail-Notifications-EA4335?logo=gmail)](https://gmail.com)

***

## 📋 Índice

- [Visão Geral](#-vis%C3%A3o-geral)
- [Arquitetura do Sistema](#-arquitetura-do-sistema)
- [Fluxo Completo](#-fluxo-completo-end-to-end)
- [Fases do Pipeline](#-fases-do-pipeline)
- [Instalação](#-instala%C3%A7%C3%A3o)
- [Configuração](#-configura%C3%A7%C3%A3o)
- [Como Usar](#-como-usar)
- [Estrutura de Arquivos](#-estrutura-de-arquivos)
- [Troubleshooting](#-troubleshooting)
- [Métricas e KPIs](#-m%C3%A9tricas-e-kpis)
- [Tecnologias Utilizadas](#-tecnologias-utilizadas)

***

## 🎯 Visão Geral

Sistema desenvolvido em **N8N** para automatizar a validação de documentos trabalhistas conforme legislação brasileira (CLT, NRs, Portarias MTE). O sistema processa documentos em **5 fases sequenciais** e toma decisões automatizadas baseadas em **IA multimodal (Gemini 2.0 Flash Thinking)**.

### **Principais Funcionalidades**

✅ **Recebimento via Webhook** - API REST para upload de documentos

✅ **Classificação Automática** - Identifica o tipo de documento usando IA

✅ **OCR e Extração** - Extrai texto e campos estruturados

✅ **Avaliação por Critérios** - Valida conformidade com critérios específicos

✅ **Decisão Automatizada** - Aprova, recusa ou encaminha para revisão manual

✅ **Sub-Workflow SST** - Permite decisões manuais da equipe de compliance

✅ **Notificações Automáticas** - Emails formatados para todas as decisões

✅ **Armazenamento em Nuvem** - Google Drive com organização por status

✅ **Auditoria Completa** - Logs detalhados de todas as etapas

---
### **Tipos de Documentos Suportados (14)**

| ID | Tipo | Descrição |
| :-- | :-- | :-- |
| 1 | `PGR` | Programa de Gerenciamento de Riscos |
| 2 | `PCMSO` | Programa de Controle Médico de Saúde Ocupacional |
| 3 | `ASO` | Atestado de Saúde Ocupacional |
| 4 | `ASO_DEMISSIONAL` | ASO Demissional |
| 5 | `CONTRATO_TRABALHO` | Contrato de Trabalho |
| 6 | `CTPS` | Carteira de Trabalho |
| 7 | `FICHA_REGISTRO` | Ficha de Registro de Empregado |
| 8 | `ORDEM_SERVICO` | Ordem de Serviço |
| 9 | `FICHA_EPI` | Ficha de Controle de EPI |
| 10 | `NR06` | Treinamento EPI |
| 11 | `NR10` | Treinamento Eletricidade |
| 12 | `NR12` | Treinamento Máquinas Rotativas |
| 13 | `NR18` | Treinamento Segurança do Trabalho |
| 14 | `NR35` | Treinamento Trabalho em Altura |


***

## 🏗️ Arquitetura do Sistema

```
┌─────────────────────────────────────────────────────────────────┐
│                    SISTEMA DE VALIDAÇÃO                          │
│                   N8N Document Validation                        │
└─────────────────────────────────────────────────────────────────┘

                              ▼
                    
┌─────────────────────────────────────────────────────────────────┐
│                      WEBHOOK ENTRADA                             │
│  POST /webhook/receber-documento                                 │
│  • Upload de arquivo (PDF/JPG/PNG)                               │
│  • Autenticação via X-API-Key                                    │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FASE 1: RECEBIMENTO                           │
│  ✅ Validar formato e tamanho                                    │
│  ✅ Calcular hash SHA-256                                        │
│  ✅ Detectar duplicatas                                          │
│  ✅ INSERT no PostgreSQL                                         │
│  ✅ Upload para Google Drive                                     │
│  ✅ Response 200 com documento_id                                │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────┐
│                 FASE 2: CLASSIFICAÇÃO                            │
│  🤖 Gemini 2.0 Flash Thinking                                    │
│  • Identifica tipo de documento (14 categorias)                  │
│  • Calcula confidence (0.0 - 1.0)                                │
│  • Se confidence < 0.70 → TIPO_DESCONHECIDO                      │
└──────────────────────┬──────────────────────────────────────────┘
                       │
                ┌──────┴──────┐
                │             │
         confidence      confidence
           < 0.70          ≥ 0.70
                │             │
                ▼             ▼
        ┌──────────┐   ┌─────────────────────────────────────────┐
        │  Email   │   │      FASE 3: OCR E EXTRAÇÃO              │
        │   SST    │   │  🤖 Gemini 2.0 Flash                     │
        │  STOP    │   │  • Extrai texto completo                 │
        └──────────┘   │  • Extrai campos estruturados (JSON)     │
                       │  • Valida qualidade OCR (≥ 0.5)          │
                       └──────────────┬───────────────────────────┘
                                      │
                               ┌──────┴──────┐
                               │             │
                          Qualidade      Qualidade
                            Baixa          Boa
                               │             │
                               ▼             ▼
                       ┌──────────┐   ┌─────────────────────────────────────────┐
                       │  Email   │   │   FASE 4: AVALIAÇÃO DE CRITÉRIOS        │
                       │Fornecedor│   │  🤖 Gemini 2.0 Flash                    │
                       │  STOP    │   │  • Busca critérios do tipo              │
                       └──────────┘   │  • Avalia cada critério (SIM/PARCIAL/   │
                                      │    NAO/NAO_APLICAVEL)                    │
                                      │  • Calcula score ponderado (0-100)       │
                                      └──────────────┬───────────────────────────┘
                                                     │
                                              ┌──────┴──────┬──────────┐
                                              │             │          │
                                          Score≥90      70≤Score<90  Score<70
                                              │             │          │
                                              ▼             ▼          ▼
                              ┌────────────────────┐ ┌────────────┐ ┌────────────┐
                              │   FASE 5: DECISÃO  │ │   REVISÃO  │ │  RECUSADO  │
                              │     APROVADO       │ │   MANUAL   │ │            │
                              │  ✅ aprovado       │ │⚠️ pendente │ │❌ recusado │
                              │  📁 validados      │ │ _revisao   │ │📁 recusados│
                              │  📧 Fornecedor     │ │📁 revisao  │ │📧Fornecedor│
                              └────────────────────┘ │📧 SST Team │ └────────────┘
                                                     └──────┬─────┘
                                                            │
                              ┌─────────────────────────────┘
                              │
                              ▼
                    ┌──────────────────────────────────────┐
                    │   SUB-WORKFLOW: DECISÃO SST          │
                    │  POST /webhook/decisao-sst           │
                    │  • Revisor toma decisão manual       │
                    │  • aprovar → aprovado_manual         │
                    │  • recusar → recusado_manual         │
                    └──────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    INTEGRAÇÕES EXTERNAS                          │
│  • PostgreSQL (Dados e Logs)                                     │
│  • Google Drive (Armazenamento)                                  │
│  • Gemini 2.0 Flash (IA Multimodal via OpenRouter)              │
│  • Gmail/SMTP (Notificações)                                     │
└─────────────────────────────────────────────────────────────────┘
```


***

## 🔄 Fluxo Completo End-to-End

### **Timeline de Processamento**

```
T=0s    ┌──────────────────┐
        │ Upload Documento │  POST /webhook/receber-documento
        └────────┬─────────┘
                 │
T=5s             ▼
        ┌──────────────────┐
        │ Validação + Hash │  FASE 1
        │ INSERT + GDrive  │
        └────────┬─────────┘  ✅ Response 200 (documento_id)
                 │
                 │ [Processamento Assíncrono]
                 │
T=15s            ▼
        ┌──────────────────┐
        │  Classificação   │  FASE 2 (Gemini)
        │   tipo + conf.   │
        └────────┬─────────┘
                 │
T=27s            ▼
        ┌──────────────────┐
        │  OCR + Extração  │  FASE 3 (Gemini)
        │  texto + campos  │
        └────────┬─────────┘
                 │
T=42s            ▼
        ┌──────────────────┐
        │ Avalia Critérios │  FASE 4 (Gemini)
        │ Calcula Score    │
        └────────┬─────────┘
                 │
T=47s            ▼
        ┌──────────────────┐
        │ Decisão Final    │  FASE 5
        │ Email + GDrive   │
        └──────────────────┘

⏱️ Tempo Total: ~45-60 segundos
💰 Custo Total: ~$0.0012 USD por documento
```


***

## 📂 Fases do Pipeline

### **FASE 1: Recebimento e Validação**

[📖 Ver README Detalhado](./docs/PIPELINE-FASE-1.md)

**Objetivo:** Receber, validar e armazenar documentos.

**Principais Ações:**

- Validação de formato (PDF/JPG/PNG) e tamanho (< 10MB)
- Cálculo de hash SHA-256 para detecção de duplicatas
- INSERT no PostgreSQL com status `recebido`
- Upload para Google Drive (pasta `1-recebidos`)
- Response 200 com `documento_id`

**Métricas:**

- Tempo médio: ~5s
- Taxa de sucesso: 98%

***

### **FASE 2: Classificação de Tipo**

[📖 Ver README Detalhado](./docs/PIPELINE-FASE-2.md)

**Objetivo:** Identificar automaticamente o tipo de documento.

**Principais Ações:**

- Análise multimodal com Gemini 2.0 Flash Thinking
- Classificação entre 14 tipos possíveis
- Cálculo de confidence (0.70 mínimo para prosseguir)
- Se confidence < 0.70 → Email SST + STOP

**Métricas:**

- Tempo médio: ~10s
- Acurácia: 92%
- Custo: ~\$0.000235 USD

***

### **FASE 3: OCR e Extração**

[📖 Ver README Detalhado](./docs/PIPELINE-FASE-3.md)

**Objetivo:** Extrair texto e campos estruturados.

**Principais Ações:**

- OCR completo do documento
- Extração de campos específicos por tipo (CNPJ, CPF, datas, etc)
- Validação de qualidade OCR (≥ 0.5)
- Se qualidade < 0.5 → Email fornecedor + STOP

**Métricas:**

- Tempo médio: ~12s
- Taxa de sucesso OCR: 95%
- Custo: ~\$0.000382 USD

***

### **FASE 4: Avaliação de Critérios**

[📖 Ver README Detalhado](./docs/PIPELINE-FASE-4.md)

**Objetivo:** Validar conformidade com critérios específicos.

**Principais Ações:**

- SELECT critérios do tipo de documento
- Avaliação individual de cada critério (SIM/PARCIAL/NAO/NAO_APLICAVEL)
- Cálculo de score ponderado (0-100)
- INSERT de cada critério avaliado na tabela `criterios_avaliacao`

**Métricas:**

- Tempo médio: ~15s
- Critérios avaliados: 9-15 por documento
- Custo: ~\$0.000519 USD

***

### **FASE 5: Decisão Final**

[📖 Ver README Detalhado](./docs/PIPELINE-FASE-5.md)

**Objetivo:** Tomar decisão automatizada baseada no score.

**Regras de Decisão:**


| Score | Decisão | Status | Email Para | Pasta GDrive |
| :-- | :-- | :-- | :-- | :-- |
| ≥ 90 | ✅ APROVADO | `aprovado` | Fornecedor | `3-validados` |
| 70-89 | ⚠️ REVISÃO | `pendente_revisao` | SST | `4-revisao-manual` |
| < 70 | ❌ RECUSADO | `recusado` | Fornecedor | `5-recusados` |

**Métricas:**

- Taxa de aprovação automática: ~65%
- Taxa de revisão manual: ~25%
- Taxa de recusa automática: ~10%

***

### **SUB-WORKFLOW: Decisão Manual SST**

[📖 Ver README Detalhado](./docs/SUB-WORKFLOW-SST.md)

**Objetivo:** Permitir decisões manuais da equipe SST.

**Webhook:** `POST /webhook/decisao-sst`

**Payload:**

```json
{
  "documento_id": "uuid",
  "decisao": "aprovar", // ou "recusar"
  "revisor_email": "revisor@athie.com.br",
  "revisor_nome": "João Silva",
  "observacoes": "Documento revisado e aprovado."
}
```

**Ações:**

- Valida status `pendente_revisao`
- UPDATE para `aprovado_manual` ou `recusado_manual`
- Move arquivo no Google Drive
- Envia email ao fornecedor
- Response 200 com confirmação

***

## 🚀 Instalação

### **Pré-requisitos**

- [N8N](https://n8n.io/) v1.0+ (self-hosted ou cloud)
- [PostgreSQL](https://www.postgresql.org/) 15+
- [Google Drive API](https://developers.google.com/drive) configurada
- [OpenRouter API Key](https://openrouter.ai/) (para Gemini)
- Gmail ou SMTP para envio de emails


### **Passo 1: Clone o Repositório**

```bash
git clone https://github.com/athie-wohnrath/n8n-document-validation.git
cd n8n-document-validation
```


### **Passo 2: Configure o Banco de Dados**

```bash
# Execute o script SQL
psql -U seu_usuario -d seu_banco -f database/schema.sql

# Popular critérios (exemplo para ASO)
psql -U seu_usuario -d seu_banco -f database/seed-criterios.sql
```


### **Passo 3: Configure Variáveis de Ambiente**

```bash
# Copie o template
cp .env.example .env

# Edite com suas credenciais
nano .env
```

Ver seção [Configuração](#-configura%C3%A7%C3%A3o) para detalhes.

### **Passo 4: Importe os Workflows no N8N**

1. Acesse N8N: `http://localhost:5678`
2. Vá em **Workflows** → **Import from File**
3. Importe os arquivos:
    - `workflows/n8n-workflow-principal.json` (Fases 1-5)
    - `workflows/n8n-workflow-sst.json` (Sub-workflow SST)

### **Passo 5: Configure Credenciais no N8N**

Configure as credenciais para:

- ✅ PostgreSQL
- ✅ Google Drive (OAuth2)
- ✅ Gmail (App Password)
- ✅ HTTP Request Headers (OpenRouter API Key)


### **Passo 6: Ative os Workflows**

1. **Workflow Principal**: Ative o webhook `/receber-documento`
2. **Workflow SST**: Ative o webhook `/decisao-sst`

***

## ⚙️ Configuração

### **Arquivo `.env`**

```bash
# PostgreSQL
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=n8n_athie
POSTGRES_USER=n8nathie
POSTGRES_PASSWORD=sua_senha_segura
POSTGRES_SCHEMA=n8n_athie_schema

# Google Drive - IDs das Pastas
GOOGLE_DRIVE_FOLDER_RECEBIDOS=1Abc...XYZ
GOOGLE_DRIVE_FOLDER_VALIDADOS=1Def...ABC
GOOGLE_DRIVE_FOLDER_REVISAO=1Ghi...DEF
GOOGLE_DRIVE_FOLDER_RECUSADOS=1Jkl...GHI

# OpenRouter (Gemini)
OPENROUTER_API_KEY=sk-or-v1-...

# Email
EMAIL_SST=sst@athie.com.br
GMAIL_USER=noreply@athie.com.br
GMAIL_APP_PASSWORD=xxxx xxxx xxxx xxxx

# N8N
N8N_WEBHOOK_URL=http://localhost:5678/webhook
N8N_API_KEY=n8n_api_key_principal
N8N_API_KEY_SST=n8n_api_key_sst_team

# Configurações Opcionais
N8N_LOG_LEVEL=info
N8N_TIMEZONE=America/Sao_Paulo
```


### **Obter IDs de Pastas do Google Drive**

1. Acesse [Google Drive](https://drive.google.com)
2. Crie as pastas:
    - `1-recebidos`
    - `2-processando`
    - `3-validados`
    - `4-revisao-manual`
    - `5-recusados`
3. Abra cada pasta e copie o ID da URL:

```
https://drive.google.com/drive/folders/1Abc...XYZ
                                         ^^^^^^^^^^^
                                         Este é o ID
```


***

## 📖 Como Usar

### **1. Enviar Documento para Validação**

```bash
curl -X POST http://localhost:5678/webhook/receber-documento \
  -H "X-API-Key: n8n_api_key_principal" \
  -F "arquivo=@/path/to/ASO_exemplo.pdf" \
  -F "email_fornecedor=fornecedor@empresa.com.br"
```

**Resposta (200 OK):**

```json
{
  "sucesso": true,
  "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
  "status": "recebido",
  "mensagem": "Documento recebido com sucesso e será processado em breve",
  "nome_arquivo": "ASO_exemplo.pdf",
  "google_drive_file_id": "1Abc...XYZ",
  "timestamp": "2025-12-05T23:00:00.000Z"
}
```


### **2. Tomar Decisão Manual (SST)**

```bash
curl -X POST http://localhost:5678/webhook/decisao-sst \
  -H "X-API-Key: n8n_api_key_sst_team" \
  -H "Content-Type: application/json" \
  -d '{
    "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
    "decisao": "aprovar",
    "revisor_email": "joao.silva@athie.com.br",
    "revisor_nome": "João Silva - Eng. SST",
    "observacoes": "Documento aprovado após revisão manual."
  }'
```

**Resposta (200 OK):**

```json
{
  "sucesso": true,
  "mensagem": "Documento aprovado manualmente com sucesso",
  "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
  "status_atual": "aprovado_manual",
  "revisor": "João Silva - Eng. SST"
}
```


### **3. Consultar Status de Documento**

```sql
-- Via PostgreSQL
SELECT 
  id,
  nome_arquivo,
  tipo_documento,
  status,
  score,
  data_recebimento,
  data_processamento
FROM n8n_athie_schema.documentos
WHERE id = '0983a6cb-2896-4b78-96b9-a31c6e90410b';
```


### **4. Ver Logs de Processamento**

```sql
SELECT 
  etapa,
  status,
  detalhes,
  timestamp
FROM n8n_athie_schema.logs_processamento
WHERE documento_id = '0983a6cb-2896-4b78-96b9-a31c6e90410b'
ORDER BY timestamp ASC;
```


***

## 📁 Estrutura de Arquivos

```
n8n-document-validation/
│
├── README.md                          # Este arquivo
│
├── docs/                              # Documentação detalhada
│   ├── PIPELINE-FASE-1.md
│   ├── PIPELINE-FASE-2.md
│   ├── PIPELINE-FASE-3.md
│   ├── PIPELINE-FASE-4.md
│   ├── PIPELINE-FASE-5.md
│   └── SUB-WORKFLOW-SST.md
│
├── workflows/                         # Workflows N8N (JSON)
│   ├── n8n-workflow-principal.json   # Fases 1-5
│   └── n8n-workflow-sst.json         # Sub-workflow SST
│
├── database/                          # Scripts SQL
│   ├── schema.sql                    # Schema completo
│   ├── seed-criterios.sql            # Critérios de avaliação
│   └── migrations/                   # Migrations (futuro)
│
├── templates/                         # Templates de Email
│   ├── email-aprovacao.html
│   ├── email-recusa.html
│   ├── email-revisao-sst.html
│   ├── email-documento-ilegivel.html
│   ├── email-tipo-desconhecido.html
│   ├── email-aprovacao-manual.html
│   └── email-recusa-manual.html
│
├── data/                              # Dados de exemplo
│   ├── criterios/                    # Critérios em JSON
│   │   ├── ASO.json
│   │   ├── PGR.json
│   │   └── PCMSO.json
│   └── test-documents/               # Documentos de teste
│       ├── ASO-valido-90pts.pdf
│       ├── ASO-medio-75pts.pdf
│       ├── ASO-invalido-60pts.pdf
│       └── documento-ilegivel.pdf
│
├── scripts/                           # Scripts utilitários
│   ├── test-webhook.sh               # Testa webhook principal
│   ├── test-sst.sh                   # Testa webhook SST
│   └── populate-criterios.sh         # Popula critérios no BD
│
├── .env.example                       # Template de variáveis
├── .gitignore
└── LICENSE
```


***

## 🔧 Troubleshooting

### **Problema: Documento não é processado**

**Sintomas:**

- Recebe 200 OK mas documento fica em `recebido`

**Soluções:**

1. Verifique se o workflow principal está **ATIVO**
2. Verifique logs no N8N (execuções)
3. Verifique se PostgreSQL está acessível
4. Verifique credenciais do Google Drive
```bash
# Testar conexão PostgreSQL
psql -U n8nathie -d n8n_athie -c "SELECT 1;"

# Ver logs do N8N
docker logs n8n
```


***

### **Problema: Erro ao classificar tipo**

**Sintomas:**

- Documento fica em `processando`
- Log mostra erro na Fase 2

**Soluções:**

1. Verifique saldo da API OpenRouter
2. Verifique se `OPENROUTER_API_KEY` está correta
3. Teste manualmente a API:
```bash
curl https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY"
```


***

### **Problema: Email não é enviado**

**Sintomas:**

- Decisão tomada mas fornecedor não recebe email

**Soluções:**

1. Verifique credenciais Gmail no N8N
2. Verifique se "App Password" foi gerado corretamente
3. Teste envio manual:
```bash
# Via N8N: Execute manualmente o node "Gmail"
```


***

### **Problema: Arquivo não aparece no Google Drive**

**Sintomas:**

- Upload falha na Fase 1

**Soluções:**

1. Reautentique OAuth2 do Google Drive no N8N
2. Verifique permissões das pastas
3. Verifique IDs das pastas no `.env`

***

## 📊 Métricas e KPIs

### **Dashboard SQL (View Disponível)**

```sql
SELECT * FROM n8n_athie_schema.dashboard_documentos;
```

**Colunas:**

- `tipo_documento`
- `status`
- `total_documentos`
- `score_medio`
- `confidence_media`
- `primeiro_documento`
- `ultimo_documento`


### **Métricas de Performance**

| Métrica | Valor Esperado |
| :-- | :-- |
| Tempo total de processamento | 45-60 segundos |
| Taxa de aprovação automática | ~65% |
| Taxa de revisão manual | ~25% |
| Taxa de recusa automática | ~10% |
| Acurácia de classificação | 92% |
| Taxa de sucesso OCR | 95% |
| Redução de trabalho manual | 85% |

### **Custo por Documento**

| Fase | Custo (USD) |
| :-- | :-- |
| Fase 2 (Classificação) | \$0.000235 |
| Fase 3 (OCR) | \$0.000382 |
| Fase 4 (Avaliação) | \$0.000519 |
| **TOTAL** | **~\$0.0012** |

**Estimativa mensal (1000 docs):** ~\$1.20 USD

***

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Versão | Uso |
| :-- | :-- | :-- |
| [N8N](https://n8n.io/) | 1.0+ | Orquestração de workflows |
| [PostgreSQL](https://www.postgresql.org/) | 15+ | Banco de dados relacional |
| [Google Drive API](https://developers.google.com/drive) | v3 | Armazenamento em nuvem |
| [Gemini 2.0 Flash Thinking](https://ai.google.dev/) | via OpenRouter | IA multimodal (OCR + classificação) |
| [Gmail API](https://developers.google.com/gmail) | - | Envio de emails |


***

## 📄 Licença

Este projeto é de uma avaliação de codificação da empresa **Athie Wohnrath Associados Projetos Construcao e Gerenciamento Ltda**

***

## 👥 Autores

- **Guilherme Trajano** (`TrolljanO`) - Desenvolvedor Fullstack

***

## 🎯 Próximos Passos

- [ ] Implementar dashboard web (Metabase/Grafana)
- [ ] Adicionar mais tipos de documentos
- [ ] Implementar versionamento de critérios
- [ ] Adicionar suporte a múltiplos idiomas
- [ ] Implementar API REST completa
- [ ] Criar testes automatizados (E2E)

***

**☕ Um amigo que compartilha um café com você é um amigo para a vida toda.**
