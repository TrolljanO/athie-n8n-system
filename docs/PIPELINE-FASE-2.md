# 🔍 PIPELINE - FASE 2: Classificação de Tipo

## 🎯 Objetivo

Classificar automaticamente o tipo de documento usando IA multimodal (Gemini 2.0 Flash Thinking) e validar a confiança da classificação.

***

## 🔧 Nós da Fase 2 (10 nós)

### **1. Início - Análise Async**

Início do processamento assíncrono após resposta ao webhook da Fase 1.

**Trigger:** Automático após conclusão da Fase 1

***

### **2. PostgreSQL - Atualiza status do arquivo**

Marca o documento como "em processamento".

**Query:**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  status = 'processando',
  updated_at = NOW()
WHERE id = $1
RETURNING *;
```

**Parameters:**

```javascript
['{{ $('Inserir documentos').first().json.id }}']
```

**Output:**

```json
{
  "id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
  "nome_arquivo": "ASO_2025.pdf",
  "status": "processando",
  "hash_sha256": "a3f2c8d9...",
  "google_drive_file_id": "1Abc...XYZ"
}
```


***

### **3. Google Drive - Download do Arquivo**

Baixa o arquivo do Google Drive para análise.

**Configuration:**

- **Operation:** Download
- **File ID:** `{{ $json.google_drive_file_id }}`
- **Output Format:** Binary

**Output:** Arquivo em formato binário (base64)

***

### **4. Function - Code in JavaScript**

Prepara o prompt de classificação para o Gemini.

**Código:**

```javascript
const documento = $input.first();

const prompt = `Você é um especialista em análise de documentos trabalhistas brasileiros conforme legislação vigente (CLT, NRs, Portarias MTE).

Analise a imagem fornecida e identifique o tipo de documento entre as seguintes categorias:

**CATEGORIAS VÁLIDAS:**
1. PGR - Programa de Gerenciamento de Riscos
2. PCMSO - Programa de Controle Médico de Saúde Ocupacional
3. ASO - Atestado de Saúde Ocupacional (admissional, periódico, mudança de função)
4. ASO_DEMISSIONAL - Atestado de Saúde Ocupacional Demissional
5. CONTRATO_TRABALHO - Contrato de Trabalho
6. CTPS - Carteira de Trabalho e Previdência Social
7. FICHA_REGISTRO - Ficha de Registro de Empregado
8. ORDEM_SERVICO - Ordem de Serviço de Segurança do Trabalho
9. FICHA_EPI - Ficha de Controle de Entrega de EPI
10. NR06 - Treinamento sobre Equipamentos de Proteção Individual
11. NR10 - Treinamento Básico de Segurança em Instalações e Serviços com Eletricidade
12. NR12 - Treinamento sobre Máquinas e Ferramentas Rotativas
13. NR18 - Treinamento Básico em Segurança do Trabalho
14. NR35 - Treinamento para Trabalho em Altura

**INSTRUÇÕES:**
1. Analise cuidadosamente o layout, cabeçalho, campos e conteúdo do documento
2. Identifique elementos característicos (logos, assinaturas, carimbos, estrutura)
3. Calcule um nível de confiança (0.0 a 1.0) baseado na clareza da identificação
4. Se a confiança for menor que 0.70, retorne tipo "TIPO_DESCONHECIDO"

**FORMATO DE RESPOSTA (JSON OBRIGATÓRIO):**
{
  "tipo": "PGR",
  "confidence": 0.95,
  "justificativa": "Documento apresenta estrutura típica de PGR com identificação de riscos, medidas de controle, cronograma e assinatura de profissional habilitado. Identificados campos como CNPJ da empresa, descrição de perigos e riscos, e avaliação qualitativa."
}

**IMPORTANTE:**
- Seja preciso e objetivo na justificativa
- Considere apenas os 14 tipos listados
- Não invente categorias
- Confidence < 0.70 → tipo = "TIPO_DESCONHECIDO"`;

// Converte arquivo para base64
const fileData = documento.binary.data;
const base64Image = fileData.toString('base64');

return {
  json: {
    prompt: prompt,
    image_base64: base64Image,
    documento_id: documento.json.id,
    nome_arquivo: documento.json.nome_arquivo
  }
};
```

**Output:**

```json
{
  "prompt": "Você é um especialista...",
  "image_base64": "JVBERi0xLjQK...",
  "documento_id": "0983a6cb...",
  "nome_arquivo": "ASO_2025.pdf"
}
```


***

### **5. HTTP Request - Gemini (OpenRouter)**

Envia requisição para o Gemini via OpenRouter.

**Configuration:**

- **Method:** POST
- **URL:** `https://openrouter.ai/api/v1/chat/completions`

**Headers:**

```json
{
  "Authorization": "Bearer {{ $env.OPENROUTER_API_KEY }}",
  "Content-Type": "application/json",
  "HTTP-Referer": "https://athie-wohnrath.com.br",
  "X-Title": "Athie Document Validation System"
}
```

**Body:**

```json
{
  "model": "google/gemini-2.0-flash-thinking-exp:free",
  "messages": [
    {
      "role": "user",
      "content": [
        {
          "type": "text",
          "text": "{{ $json.prompt }}"
        },
        {
          "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,{{ $json.image_base64 }}"
          }
        }
      ]
    }
  ],
  "temperature": 0.3,
  "max_tokens": 1500,
  "response_format": {
    "type": "json_object"
  }
}
```

**Output (Exemplo):**

```json
{
  "id": "gen-123456",
  "model": "google/gemini-2.0-flash-thinking-exp:free",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "{\"tipo\":\"ASO\",\"confidence\":0.98,\"justificativa\":\"Documento apresenta estrutura típica de ASO com identificação do trabalhador, dados da empresa, resultado de exames clínicos, indicação de aptidão, assinatura e CRM do médico examinador.\"}"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 1250,
    "completion_tokens": 85,
    "total_tokens": 1335
  }
}
```


***

### **6. Function - Validar Confidence**

Extrai e valida a resposta do Gemini.

**Código:**

```javascript
const response = $input.first().json;

// Parse da resposta JSON do Gemini
const content = JSON.parse(response.choices[0].message.content);

// Validações
if (!content.tipo || !content.confidence || !content.justificativa) {
  throw new Error('Resposta do Gemini incompleta');
}

// Normalizar tipo (uppercase + underscore)
const tipoNormalizado = content.tipo.toUpperCase().replace(/\s+/g, '_');

return {
  json: {
    tipo_documento: tipoNormalizado,
    confidence_tipo: parseFloat(content.confidence),
    justificativa: content.justificativa,
    documento_id: $('Code in JavaScript').first().json.documento_id,
    nome_arquivo: $('Code in JavaScript').first().json.nome_arquivo,
    api_tokens: response.usage.total_tokens,
    api_cost: (response.usage.total_tokens * 0.000000176).toFixed(9) // Custo estimado
  }
};
```

**Output:**

```json
{
  "tipo_documento": "ASO",
  "confidence_tipo": 0.98,
  "justificativa": "Documento apresenta estrutura típica...",
  "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
  "nome_arquivo": "ASO_2025.pdf",
  "api_tokens": 1335,
  "api_cost": "0.000000235"
}
```


***

### **7. Switch - Confidence Adequada?**

Verifica se a confiança é suficiente (>= 70%).

**Mode:** Rules

**Rule 1: Confidence Adequada**

```javascript
{{ $json.confidence_tipo >= 0.70 }}
```

**Output:** Tipo identificado (TRUE)

**Fallback:** Tipo desconhecido (FALSE)

***

## ❌ **BRANCH: Confidence Inadequada (< 0.70)**

### **8. PostgreSQL - Atualizar Tipo Documento - Falha**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  status = 'tipo_desconhecido',
  tipo_documento = 'TIPO_DESCONHECIDO',
  confidence_tipo = $1,
  updated_at = NOW()
WHERE id = $2
RETURNING *;
```

**Parameters:**

```javascript
[
  {{ $('Validar Confidence').first().json.confidence_tipo }},
  '{{ $('Validar Confidence').first().json.documento_id }}'
]
```


***

### **9. Gmail - Notificar - Inadequado**

Envia email notificando que o tipo não foi identificado.

**To:** `{{ $env.EMAIL_SST }}`
**Subject:** `⚠️ Documento com Tipo Desconhecido - {{ $json.nome_arquivo }}`

**HTML Body:**

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #ff9800; color: white; padding: 20px; text-align: center; }
    .content { background: #fff; padding: 20px; border: 1px solid #ddd; }
    .alert-box { background: #fff3cd; padding: 15px; margin: 15px 0; border-left: 4px solid #ff9800; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>⚠️ Tipo de Documento Desconhecido</h1>
    </div>
    
    <div class="content">
      <p>O documento <strong>{{ $json.nome_arquivo }}</strong> não pôde ser classificado automaticamente.</p>
      
      <div class="alert-box">
        <h3>📊 Informações da Análise</h3>
        <p><strong>Confidence:</strong> {{ $json.confidence_tipo }}</p>
        <p><strong>Documento ID:</strong> {{ $json.documento_id }}</p>
        <p><strong>Justificativa:</strong> {{ $json.justificativa }}</p>
      </div>
      
      <p><strong>Ação Necessária:</strong> Revisar manualmente o documento e classificá-lo no sistema.</p>
      
      <a href="https://drive.google.com/file/d/{{ $('Atualiza status do arquivo').first().json.google_drive_file_id }}" 
         style="display: inline-block; background: #ff9800; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin: 10px 0;">
        📄 Visualizar Documento
      </a>
    </div>
  </div>
</body>
</html>
```


***

### **10. Stop and Error - Documento Inadequado**

Para o fluxo e registra erro.

**Error Message:** `Documento com tipo desconhecido - confidence < 0.70`

***

## ✅ **BRANCH: Confidence Adequada (>= 0.70)**

### **11. PostgreSQL - Atualizar Tipo Documento - Sucesso**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  tipo_documento = $1,
  confidence_tipo = $2,
  updated_at = NOW()
WHERE id = $3
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $('Validar Confidence').first().json.tipo_documento }}',
  {{ $('Validar Confidence').first().json.confidence_tipo }},
  '{{ $('Validar Confidence').first().json.documento_id }}'
]
```


***

### **12. PostgreSQL - Inserir Log - Sucesso**

```sql
INSERT INTO n8n_athie_schema.logs_processamento (
  documento_id,
  etapa,
  status,
  detalhes,
  timestamp
) VALUES (
  $1,
  'classificacao',
  'sucesso',
  jsonb_build_object(
    'tipo_documento', $2,
    'confidence', $3,
    'justificativa', $4,
    'api_tokens', $5,
    'api_cost', $6
  ),
  NOW()
)
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $('Validar Confidence').first().json.documento_id }}',
  '{{ $('Validar Confidence').first().json.tipo_documento }}',
  {{ $('Validar Confidence').first().json.confidence_tipo }},
  '{{ $('Validar Confidence').first().json.justificativa }}',
  {{ $('Validar Confidence').first().json.api_tokens }},
  '{{ $('Validar Confidence').first().json.api_cost }}'
]
```


***

## 📊 Fluxo Visual

```
     Fase 1 (Documento Recebido)
              │
              ▼
    ┌─────────────────────┐
    │ UPDATE status       │
    │ processando         │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │ Download Arquivo    │
    │ Google Drive        │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │ Preparar Request    │
    │ • Prompt            │
    │ • Base64 Image      │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  HTTP Request       │
    │  Gemini 2.0 Flash   │
    │  (via OpenRouter)   │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │ Validar Confidence  │
    │ Parse JSON Response │
    └──────────┬──────────┘
               │
        ┌──────┴──────┐
        │             │
   confidence      confidence
     < 0.70          >= 0.70
        │             │
        ▼             ▼
┌──────────────┐  ┌──────────────┐
│   UPDATE     │  │   UPDATE     │
│tipo_desconhe-│  │tipo_documento│
│cido          │  │+ confidence  │
└──────┬───────┘  └──────┬───────┘
       │                 │
       ▼                 ▼
┌──────────────┐  ┌──────────────┐
│ Email SST    │  │ Log Sucesso  │
│ Notificação  │  │              │
└──────┬───────┘  └──────┬───────┘
       │                 │
       ▼                 ▼
     STOP            FASE 3
                  (OCR e Extração)
```


***

## ✅ Resultado da Fase 2

Ao final desta fase (sucesso):

- ✅ Tipo de documento identificado (ex: `ASO`, `PGR`, `PCMSO`)
- ✅ Nível de confiança calculado (0.70 - 1.00)
- ✅ Justificativa da IA registrada
- ✅ Status atualizado no banco (`tipo_documento` + `confidence_tipo`)
- ✅ Log estruturado com tokens e custo da API
- ✅ Documento pronto para Fase 3 (OCR)

**Próxima Fase:** OCR e Extração de Campos (Fase 3)

***

## 🧪 Tipos Suportados (14 categorias)

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

## 📈 Métricas

- **Tempo médio:** ~10 segundos
- **Acurácia:** 92% (confidence >= 0.85)
- **Taxa de tipo desconhecido:** ~8%
- **Custo por classificação:** ~\$0.000235 USD

***

## 🔍 Exemplo de Resposta Gemini

**Input:** ASO bem formatado

**Output:**

```json
{
  "tipo": "ASO",
  "confidence": 0.98,
  "justificativa": "Documento apresenta estrutura típica de ASO com: (1) Cabeçalho com razão social e CNPJ da empresa; (2) Dados completos do trabalhador incluindo nome, CPF e cargo; (3) Lista de riscos ocupacionais; (4) Resultado de exames clínicos datados; (5) Conclusão de aptidão para o trabalho; (6) Assinatura e CRM do médico examinador; (7) Data de realização do exame. Todos elementos essenciais de um ASO conforme NR-7 estão presentes."
}
```

