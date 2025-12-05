# ⚖️ PIPELINE - FASE 4: Avaliação de Critérios

## 🎯 Objetivo

Buscar critérios de avaliação específicos do tipo de documento, aplicar cada critério usando IA, calcular score ponderado e armazenar resultados detalhados.

***

## 🔧 Nós da Fase 4 (10 nós)

### **1. PostgreSQL - Documento OCR - Sucesso**

Atualiza status após OCR bem-sucedido.

**Query:**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  texto_extraido = $1,
  campos_extraidos = $2::jsonb,
  status = 'avaliando_criterios',
  updated_at = NOW()
WHERE id = $3
RETURNING *;
```


***

### **2. PostgreSQL - Inserir Log - Documento Ilegível**

Registra log do OCR.

*(Query da Fase 3)*

***

### **3. PostgreSQL - Buscar Critérios do Tipo**

Busca critérios de avaliação específicos do tipo de documento.

**Query:**

```sql
SELECT 
  id,
  tipo_documento,
  criterio_id,
  descricao,
  peso,
  categoria
FROM n8n_athie_schema.criterios_documento
WHERE tipo_documento = $1
ORDER BY criterio_id ASC;
```

**Parameters:**

```javascript
['{{ $('Validar Qualidade OCR').first().json.tipo_documento }}']
```

**Output (Exemplo para ASO):**

```json
[
  {
    "id": 1,
    "tipo_documento": "ASO",
    "criterio_id": "ASO-01",
    "descricao": "Documento legível, sem rasuras em formato PDF",
    "peso": 5,
    "categoria": "Formato"
  },
  {
    "id": 2,
    "tipo_documento": "ASO",
    "criterio_id": "ASO-02",
    "descricao": "Dados da empresa (razão social, CNPJ)",
    "peso": 10,
    "categoria": "Dados da Empresa"
  },
  ...
]
```


***

### **4. Function - Preparar Prompt**

Prepara o prompt para avaliação de critérios.

**Código:**

```javascript
const documento = $('Documento OCR - Sucesso').first().json;
const criterios = $input.all();

const textoExtraido = documento.texto_extraido;
const camposExtraidos = documento.campos_extraidos;
const tipoDocumento = documento.tipo_documento;

// Formata critérios para o prompt
const criteriosFormatados = criterios.map(c => ({
  criterio_id: c.json.criterio_id,
  descricao: c.json.descricao,
  peso: c.json.peso,
  categoria: c.json.categoria
}));

const prompt = `Você é um auditor especializado em documentos trabalhistas brasileiros conforme legislação (CLT, NRs, Portarias MTE).

**DOCUMENTO ANALISADO:**
Tipo: ${tipoDocumento}

**TEXTO EXTRAÍDO DO DOCUMENTO:**
${textoExtraido}

**CAMPOS ESTRUTURADOS EXTRAÍDOS:**
${JSON.stringify(camposExtraidos, null, 2)}

**CRITÉRIOS DE AVALIAÇÃO:**
${JSON.stringify(criteriosFormatados, null, 2)}

**TAREFA:**
Avalie se o documento atende a CADA critério listado. Para cada critério, determine:

1. **atende**: "SIM", "PARCIAL", "NAO" ou "NAO_APLICAVEL"
2. **pontos_obtidos**: Pontuação de 0 até o valor máximo do peso
3. **pontos_possiveis**: Valor do peso do critério
4. **justificativa**: Explicação clara e objetiva (máximo 200 caracteres)

**REGRAS DE AVALIAÇÃO:**

- **SIM**: Critério totalmente atendido → pontos_obtidos = pontos_possiveis
- **PARCIAL**: Critério parcialmente atendido → pontos_obtidos = 50% do peso
- **NAO**: Critério não atendido → pontos_obtidos = 0
- **NAO_APLICAVEL**: Critério não se aplica a este documento → pontos_obtidos = pontos_possiveis (não penalizar)

**FORMATO DE RESPOSTA (JSON):**
{
  "avaliacoes": [
    {
      "criterio_id": "ASO-01",
      "atende": "SIM",
      "pontos_obtidos": 5,
      "pontos_possiveis": 5,
      "justificativa": "Documento legível, sem rasuras aparentes.",
      "descricao": "Documento legível, sem rasuras em formato PDF",
      "categoria": "Formato",
      "peso": 5
    },
    {
      "criterio_id": "ASO-02",
      "atende": "PARCIAL",
      "pontos_obtidos": 5,
      "pontos_possiveis": 10,
      "justificativa": "Razão social presente, CNPJ ilegível.",
      "descricao": "Dados da empresa (razão social, CNPJ)",
      "categoria": "Dados da Empresa",
      "peso": 10
    }
  ]
}

**IMPORTANTE:**
- Seja rigoroso mas justo na avaliação
- Justificativas devem ser específicas e baseadas no conteúdo
- Não invente informações que não estão no documento
- Considere apenas o que está visível e legível`;

return {
  json: {
    prompt: prompt,
    documento_id: documento.id,
    tipo_documento: tipoDocumento,
    total_criterios: criterios.length
  }
};
```

**Output:**

```json
{
  "prompt": "Você é um auditor especializado...",
  "documento_id": "0983a6cb...",
  "tipo_documento": "ASO",
  "total_criterios": 9
}
```


***

### **5. HTTP Request - Gemini Avalia Critérios**

Envia requisição para avaliação de critérios.

**Configuration:**

- **Method:** POST
- **URL:** `https://openrouter.ai/api/v1/chat/completions`

**Headers:**

```json
{
  "Authorization": "Bearer {{ $env.OPENROUTER_API_KEY }}",
  "Content-Type": "application/json",
  "HTTP-Referer": "https://athie-wohnrath.com.br",
  "X-Title": "Athie Document Validation - Criteria"
}
```

**Body:**

```json
{
  "model": "google/gemini-2.0-flash-thinking-exp:free",
  "messages": [
    {
      "role": "user",
      "content": "{{ $json.prompt }}"
    }
  ],
  "temperature": 0.2,
  "max_tokens": 4000,
  "response_format": {
    "type": "json_object"
  }
}
```

**Output (Exemplo):**

```json
{
  "id": "gen-345678",
  "choices": [
    {
      "message": {
        "role": "assistant",
        "content": "{\"avaliacoes\":[{\"criterio_id\":\"ASO-01\",\"atende\":\"SIM\",\"pontos_obtidos\":5,\"pontos_possiveis\":5,\"justificativa\":\"Documento legível, sem rasuras aparentes.\",\"descricao\":\"Documento legível, sem rasuras em formato PDF\",\"categoria\":\"Formato\",\"peso\":5},...}"
      }
    }
  ],
  "usage": {
    "prompt_tokens": 2500,
    "completion_tokens": 450,
    "total_tokens": 2950
  }
}
```


***

### **6. Function - Processar Avaliação e Calcular Score**

Calcula o score final e prepara dados.

**Código:**

```javascript
const response = $input.first().json;
const documento = $('Preparar Prompt').first().json;

// Parse da resposta
const content = JSON.parse(response.choices[0].message.content);
const avaliacoes = content.avaliacoes;

// Calcular score
let pontos_obtidos = 0;
let pontos_maximos = 0;
let total_atendidos = 0;
let total_parciais = 0;
let total_nao_atendidos = 0;
let total_nao_aplicaveis = 0;

avaliacoes.forEach(av => {
  pontos_obtidos += parseFloat(av.pontos_obtidos);
  pontos_maximos += parseFloat(av.pontos_possiveis);
  
  if (av.atende === 'SIM') total_atendidos++;
  else if (av.atende === 'PARCIAL') total_parciais++;
  else if (av.atende === 'NAO') total_nao_atendidos++;
  else if (av.atende === 'NAO_APLICAVEL') total_nao_aplicaveis++;
});

const score_final = pontos_maximos > 0 
  ? ((pontos_obtidos / pontos_maximos) * 100).toFixed(2)
  : 0;

return {
  json: {
    avaliacoes: avaliacoes,
    score_final: parseFloat(score_final),
    pontos_obtidos: pontos_obtidos,
    pontos_maximos: pontos_maximos,
    total_criterios: avaliacoes.length,
    total_criterios_avaliados: avaliacoes.length,
    total_atendidos: total_atendidos,
    total_parciais: total_parciais,
    total_nao_atendidos: total_nao_atendidos,
    total_nao_aplicaveis: total_nao_aplicaveis,
    documento_id: documento.documento_id,
    tipo_documento: documento.tipo_documento,
    api_tokens_avaliacao: response.usage.total_tokens,
    api_cost_avaliacao: (response.usage.total_tokens * 0.000000176).toFixed(9),
    api_model_avaliacao: 'google/gemini-2.0-flash-thinking-exp:free'
  }
};
```

**Output:**

```json
{
  "avaliacoes": [ {...}, {...}, ... ],
  "score_final": 90.00,
  "pontos_obtidos": 90,
  "pontos_maximos": 100,
  "total_criterios": 9,
  "total_criterios_avaliados": 9,
  "total_atendidos": 7,
  "total_parciais": 2,
  "total_nao_atendidos": 0,
  "total_nao_aplicaveis": 0,
  "documento_id": "0983a6cb...",
  "tipo_documento": "ASO",
  "api_tokens_avaliacao": 2950,
  "api_cost_avaliacao": "0.000000519",
  "api_model_avaliacao": "google/gemini-2.0-flash-thinking-exp:free"
}
```


***

### **7. Split Out - Preparar Loop**

Divide o array de avaliações para inserção individual.

**Configuration:**

- **Field to Split Out:** `avaliacoes`

**Output:** 9 items (1 para cada critério)

***

### **8. PostgreSQL - INSERT Critério Avaliado**

Insere cada critério avaliado no banco (executa 9x em loop).

**Query:**

```sql
INSERT INTO n8n_athie_schema.criterios_avaliacao (
  documento_id,
  criterio_id,
  criterio_descricao,
  pontuacao_obtida,
  pontuacao_maxima,
  observacao,
  categoria,
  peso,
  atende
) VALUES (
  $1, $2, $3, $4, $5, $6, $7, $8, $9
)
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $('Processar Avaliação e Calcular Score').first().json.documento_id }}',
  '{{ $json.criterio_id }}',
  '{{ $json.descricao }}',
  {{ $json.pontos_obtidos }},
  {{ $json.pontos_possiveis }},
  '{{ $json.justificativa }}',
  '{{ $json.categoria }}',
  {{ $json.peso }},
  '{{ $json.atende }}'
]
```


***

### **9. Aggregate - Juntar Resultados do Loop**

Aguarda todos os inserts terminarem e junta os resultados.

**Configuration:**

- **Mode:** Aggregate All Items
- **Field to Aggregate:** All fields

**Output:** Array com todos os 9 critérios inseridos

***

### **10. PostgreSQL - Atualizar Score do Documento**

Atualiza o documento com score final e estatísticas.

**Query:**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  score = $1,
  status = 'avaliado',
  campos_extraidos = COALESCE(campos_extraidos, '{}'::jsonb) || jsonb_build_object(
    'pontos_obtidos', $2,
    'pontos_maximos', $3,
    'percentual_score', $1,
    'total_criterios', $4,
    'criterios_atendidos', $5,
    'criterios_parciais', $6,
    'criterios_nao_atendidos', $7,
    'criterios_nao_aplicaveis', $8,
    'api_tokens_avaliacao', $9,
    'api_cost_avaliacao', $10
  ),
  data_processamento = NOW(),
  updated_at = NOW()
WHERE id = $11
RETURNING *;
```

**Parameters:**

```javascript
[
  {{ $('Processar Avaliação e Calcular Score').first().json.score_final }},
  {{ $('Processar Avaliação e Calcular Score').first().json.pontos_obtidos }},
  {{ $('Processar Avaliação e Calcular Score').first().json.pontos_maximos }},
  {{ $('Processar Avaliação e Calcular Score').first().json.total_criterios }},
  {{ $('Processar Avaliação e Calcular Score').first().json.total_atendidos }},
  {{ $('Processar Avaliação e Calcular Score').first().json.total_parciais }},
  {{ $('Processar Avaliação e Calcular Score').first().json.total_nao_atendidos }},
  {{ $('Processar Avaliação e Calcular Score').first().json.total_nao_aplicaveis }},
  {{ $('Processar Avaliação e Calcular Score').first().json.api_tokens_avaliacao }},
  '{{ $('Processar Avaliação e Calcular Score').first().json.api_cost_avaliacao }}',
  '{{ $('Processar Avaliação e Calcular Score').first().json.documento_id }}'
]
```


***

### **11. PostgreSQL - Log da Avaliação**

Registra log da avaliação de critérios.

**Query:**

```sql
INSERT INTO n8n_athie_schema.logs_processamento (
  documento_id,
  etapa,
  status,
  detalhes,
  timestamp
) VALUES (
  $1,
  'avaliacao_criterios',
  'sucesso',
  jsonb_build_object(
    'score_final', $2,
    'pontos_obtidos', $3,
    'pontos_maximos', $4,
    'total_criterios_avaliados', $5,
    'criterios_atendidos', $6,
    'criterios_parciais', $7,
    'criterios_nao_atendidos', $8,
    'api_tokens', $9,
    'api_cost', $10,
    'api_model', $11
  ),
  NOW()
)
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $('Processar Avaliação e Calcular Score').first().json.documento_id }}',
  {{ $('Processar Avaliação e Calcular Score').first().json.score_final }},
  {{ $('Processar Avaliação e Calcular Score').first().json.pontos_obtidos }},
  {{ $('Processar Avaliação e Calcular Score').first().json.pontos_maximos }},
  {{ $('Processar Avaliação e Calcular Score').first().json.total_criterios_avaliados }},
  {{ $('Processar Avaliação e Calcular Score').first().json.total_atendidos }},
  {{ $('Processar Avaliação e Calcular Score').first().json.total_parciais }},
  {{ $('Processar Avaliação e Calcular Score').first().json.total_nao_atendidos }},
  {{ $('Processar Avaliação e Calcular Score').first().json.api_tokens_avaliacao }},
  '{{ $('Processar Avaliação e Calcular Score').first().json.api_cost_avaliacao }}',
  '{{ $('Processar Avaliação e Calcular Score').first().json.api_model_avaliacao }}'
]
```


***

## 📊 Fluxo Visual

```
    Fase 3 (OCR Completo)
              │
              ▼
    ┌─────────────────────┐
    │ UPDATE status       │
    │ avaliando_criterios │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │ SELECT Critérios    │
    │ WHERE tipo_doc      │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │ Preparar Prompt     │
    │ • Texto extraído    │
    │ • Campos extraídos  │
    │ • Lista critérios   │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  HTTP Request       │
    │  Gemini Avalia      │
    │  Todos Critérios    │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │ Calcular Score      │
    │ • Pontos / Total    │
    │ • % Score (0-100)   │
    │ • Estatísticas      │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │  Split Out (Loop)   │
    │  9 critérios        │
    └──────────┬──────────┘
               │
        ┌──────┴──────┐
        │  Loop 9x    │
        ▼             ▼
    ┌─────────────────────┐
    │ INSERT Critério     │
    │ (cada um)           │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │ Aggregate (Juntar)  │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │ UPDATE Documento    │
    │ • score = 90        │
    │ • status=avaliado   │
    └──────────┬──────────┘
               │
               ▼
    ┌─────────────────────┐
    │ Log Avaliação       │
    └──────────┬──────────┘
               │
               ▼
          FASE 5
    (Decisão Final)
```


***

## ✅ Resultado da Fase 4

Ao final desta fase:

- ✅ Todos os critérios avaliados individualmente
- ✅ Score calculado (0-100)
- ✅ Cada critério inserido em `criterios_avaliacao`
- ✅ Estatísticas completas:
    - Total de critérios atendidos (SIM)
    - Total de critérios parciais (PARCIAL)
    - Total de critérios não atendidos (NAO)
    - Total não aplicáveis (NAO_APLICAVEL)
- ✅ Status atualizado para `avaliado`
- ✅ Log detalhado com tokens e custo

**Próxima Fase:** Decisão Final por Score (Fase 5)

***

## 📋 Exemplo de Critérios Avaliados (ASO)

```json
[
  {
    "criterio_id": "ASO-01",
    "atende": "SIM",
    "pontos_obtidos": 5,
    "pontos_possiveis": 5,
    "justificativa": "Documento legível, sem rasuras aparentes.",
    "categoria": "Formato"
  },
  {
    "criterio_id": "ASO-02",
    "atende": "SIM",
    "pontos_obtidos": 10,
    "pontos_possiveis": 10,
    "justificativa": "Razão social e CNPJ da empresa presentes.",
    "categoria": "Dados da Empresa"
  },
  {
    "criterio_id": "ASO-08",
    "atende": "PARCIAL",
    "pontos_obtidos": 5,
    "pontos_possiveis": 10,
    "justificativa": "Nome do médico presente, CRM incompleto.",
    "categoria": "Médico Examinador"
  }
]
```


***

## 📈 Cálculo do Score

**Fórmula:**

```
Score = (Pontos Obtidos / Pontos Máximos) × 100
```

**Exemplo:**

```
Pontos Obtidos: 90
Pontos Máximos: 100
Score = (90 / 100) × 100 = 90%
```

**Classificação:**

- ✅ **90-100:** APROVADO
- ⚠️ **70-89:** REVISÃO MANUAL
- ❌ **0-69:** RECUSADO

***

## 🗂️ Estrutura da Tabela `criterios_avaliacao`

```sql
CREATE TABLE criterios_avaliacao (
  id SERIAL PRIMARY KEY,
  documento_id UUID NOT NULL REFERENCES documentos(id),
  criterio_id VARCHAR(50) NOT NULL,
  criterio_descricao TEXT NOT NULL,
  pontuacao_obtida DECIMAL(5,2) NOT NULL,
  pontuacao_maxima DECIMAL(5,2) NOT NULL,
  observacao TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  categoria VARCHAR(100),
  peso INTEGER,
  atende VARCHAR(20) CHECK (atende IN ('SIM', 'PARCIAL', 'NAO', 'NAO_APLICAVEL'))
);
```


***

## 📊 Métricas

- **Tempo médio:** ~15 segundos
- **Critérios avaliados por documento:** 9-15
- **Taxa de avaliação completa:** 98%
- **Custo por avaliação:** ~\$0.000519 USD
- **Score médio (ASO):** 87%

