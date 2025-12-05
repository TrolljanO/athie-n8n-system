# 👨‍⚕️ SUB-WORKFLOW: Decisão Manual SST

## 🎯 Objetivo

Permitir que a equipe de Segurança e Saúde do Trabalho (SST) tome decisões manuais sobre documentos que ficaram pendentes de revisão (score entre 70-89).

***

## 🔧 Nós do Sub-Workflow SST (3 nós principais)

### **1. Webhook - Decisão SST**

Recebe decisão manual da equipe SST.

**Configuration:**

- **Tipo:** Webhook Trigger
- **Método:** POST
- **Path:** `/webhook/decisao-sst`
- **Authentication:** Header Auth (`X-API-Key`)
- **Response Mode:** When Last Node Finishes

**Payload Esperado:**

```json
{
  "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
  "decisao": "aprovar",
  "revisor_email": "revisor@athie.com.br",
  "revisor_nome": "João Silva",
  "observacoes": "Documento revisado manualmente. Critérios parciais verificados e aprovados."
}
```

**Campos:**

- `documento_id` (obrigatório): UUID do documento
- `decisao` (obrigatório): `"aprovar"` ou `"recusar"`
- `revisor_email` (obrigatório): Email do revisor SST
- `revisor_nome` (opcional): Nome do revisor
- `observacoes` (opcional): Observações sobre a decisão

**Exemplo cURL:**

```bash
curl -X POST http://localhost:5678/webhook/decisao-sst \
  -H "X-API-Key: sua-api-key-sst" \
  -H "Content-Type: application/json" \
  -d '{
    "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
    "decisao": "aprovar",
    "revisor_email": "joao.silva@athie.com.br",
    "revisor_nome": "João Silva",
    "observacoes": "Após revisão manual, todos os critérios foram validados. Documento aprovado."
  }'
```


***

### **2. Function - Validar Decisão SST**

Valida o payload recebido.

**Código:**

```javascript
const body = $input.first().json.body;

// Validações
if (!body.documento_id) {
  throw new Error('Campo documento_id é obrigatório');
}

if (!body.decisao) {
  throw new Error('Campo decisao é obrigatório');
}

if (!['aprovar', 'recusar'].includes(body.decisao.toLowerCase())) {
  throw new Error('Campo decisao deve ser "aprovar" ou "recusar"');
}

if (!body.revisor_email) {
  throw new Error('Campo revisor_email é obrigatório');
}

// Validar formato de email
const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
if (!emailRegex.test(body.revisor_email)) {
  throw new Error('Email do revisor inválido');
}

return {
  json: {
    documento_id: body.documento_id.trim(),
    decisao: body.decisao.toLowerCase(),
    revisor_email: body.revisor_email.trim(),
    revisor_nome: body.revisor_nome || 'Revisor SST',
    observacoes: body.observacoes || 'Decisão manual sem observações adicionais',
    data_decisao_manual: new Date().toISOString()
  }
};
```

**Output:**

```json
{
  "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
  "decisao": "aprovar",
  "revisor_email": "joao.silva@athie.com.br",
  "revisor_nome": "João Silva",
  "observacoes": "Após revisão manual, todos os critérios foram validados.",
  "data_decisao_manual": "2025-12-05T22:00:00.000Z"
}
```


***

### **3. PostgreSQL - Buscar Documento**

Busca o documento para validar status.

**Query:**

```sql
SELECT 
  d.*,
  COALESCE(
    (SELECT email_solicitante FROM jsonb_to_record(d.campos_extraidos) AS x(email_solicitante text)),
    'fornecedor@empresa.com'
  ) as email_destinatario
FROM n8n_athie_schema.documentos d
WHERE d.id = $1::uuid;
```

**Parameters:**

```javascript
['{{ $json.documento_id }}']
```

**Validações:**

- Verifica se documento existe
- Verifica se status atual é `pendente_revisao`
- Se não for `pendente_revisao`, retorna erro

**Output:**

```json
{
  "id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
  "nome_arquivo": "ASO_2025.pdf",
  "tipo_documento": "ASO",
  "status": "pendente_revisao",
  "score": 85,
  "google_drive_file_id": "1Abc...XYZ",
  "email_destinatario": "fornecedor@empresa.com",
  ...
}
```


***

### **4. Function - Validar Status do Documento**

Valida se o documento pode receber decisão manual.

**Código:**

```javascript
const documento = $input.first().json;
const decisao = $('Validar Decisão SST').first().json;

// Validar se documento existe
if (!documento.id) {
  throw new Error(`Documento ${decisao.documento_id} não encontrado`);
}

// Validar se documento está pendente de revisão
if (documento.status !== 'pendente_revisao') {
  throw new Error(
    `Documento não pode receber decisão manual. Status atual: ${documento.status}. ` +
    `Apenas documentos com status 'pendente_revisao' podem ser aprovados/recusados manualmente.`
  );
}

return {
  json: {
    ...documento,
    decisao_sst: decisao.decisao,
    revisor_email: decisao.revisor_email,
    revisor_nome: decisao.revisor_nome,
    observacoes_sst: decisao.observacoes,
    data_decisao_manual: decisao.data_decisao_manual
  }
};
```


***

### **5. Switch - Decisão: Aprovar ou Recusar?**

Direciona o fluxo baseado na decisão.

**Mode:** Rules

**Rule 1: APROVAR**

```javascript
{{ $json.decisao_sst === 'aprovar' }}
```

**Output:** Branch Aprovação Manual

**Fallback: RECUSAR**
**Output:** Branch Recusa Manual

***

## ✅ **BRANCH: APROVAR**

### **6. PostgreSQL - UPDATE Status Aprovado (Manual)**

Atualiza documento para aprovado.

**Query:**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  status = 'aprovado_manual',
  data_decisao = NOW(),
  campos_extraidos = COALESCE(campos_extraidos, '{}'::jsonb) || jsonb_build_object(
    'decisao_manual', true,
    'revisor_email', $2,
    'revisor_nome', $3,
    'observacoes_sst', $4,
    'data_decisao_manual', $5
  ),
  updated_at = NOW()
WHERE id = $1
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $json.id }}',
  '{{ $json.revisor_email }}',
  '{{ $json.revisor_nome }}',
  '{{ $json.observacoes_sst }}',
  '{{ $json.data_decisao_manual }}'
]
```


***

### **7. Google Drive - Mover para Validados (Manual)**

Move arquivo para pasta de validados.

**Configuration:**

- **Operation:** Move
- **File ID:** `{{ $json.google_drive_file_id }}`
- **New Parent Folder ID:** `{{ $env.GOOGLE_DRIVE_FOLDER_VALIDADOS }}`

***

### **8. PostgreSQL - Log Aprovação Manual**

Registra log da aprovação manual.

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
  'decisao_manual_sst',
  'aprovado_manual',
  jsonb_build_object(
    'score_original', $2,
    'decisao', 'aprovado',
    'revisor_email', $3,
    'revisor_nome', $4,
    'observacoes', $5
  ),
  NOW()
)
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $json.id }}',
  {{ $json.score }},
  '{{ $json.revisor_email }}',
  '{{ $json.revisor_nome }}',
  '{{ $json.observacoes_sst }}'
]
```


***

### **9. Gmail - Email Aprovação Manual**

Envia email de aprovação ao fornecedor.

**To:** `{{ $json.email_destinatario }}`
**Subject:** `✅ Documento Aprovado (Revisão Manual) - {{ $json.nome_arquivo }}`

**HTML Body:**

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #4caf50; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #fff; padding: 20px; border: 1px solid #ddd; }
    .score-box { background: #e8f5e9; padding: 20px; margin: 20px 0; border-left: 4px solid #4caf50; }
    .info-box { background: #f5f5f5; padding: 15px; margin: 15px 0; border-radius: 4px; }
    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    .btn { display: inline-block; background: #4caf50; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin: 10px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✅ Documento Aprovado!</h1>
      <p style="margin: 5px 0; font-size: 14px;">(Após Revisão Manual SST)</p>
    </div>
    
    <div class="content">
      <p>Prezado(a),</p>
      
      <p>O documento <strong>{{ $json.nome_arquivo }}</strong> foi <strong style="color: #4caf50;">APROVADO</strong> pela equipe de Segurança e Saúde do Trabalho após revisão manual detalhada.</p>
      
      <div class="score-box">
        <h3 style="margin-top: 0;">📊 Resultado da Avaliação</h3>
        <p style="font-size: 20px; margin: 10px 0;"><strong>Score Automático: {{ $json.score }}/100</strong></p>
        <p style="margin: 5px 0;">✅ Status: <strong>APROVADO MANUALMENTE</strong></p>
        <p style="margin: 5px 0;">👤 Revisor: <strong>{{ $json.revisor_nome }}</strong></p>
      </div>
      
      <div class="info-box">
        <h3>💬 Observações do Revisor</h3>
        <p style="font-style: italic;">"{{ $json.observacoes_sst }}"</p>
      </div>
      
      <div class="info-box">
        <h3>📋 Informações do Documento</h3>
        <ul style="list-style: none; padding: 0;">
          <li><strong>Tipo:</strong> {{ $json.tipo_documento }}</li>
          <li><strong>ID:</strong> {{ $json.id }}</li>
          <li><strong>Data de Revisão:</strong> {{ new Date($json.data_decisao_manual).toLocaleString('pt-BR') }}</li>
        </ul>
      </div>
      
      <p><strong>Próximos Passos:</strong></p>
      <ul>
        <li>✅ O documento foi arquivado e está disponível para consulta</li>
        <li>✅ Nenhuma ação adicional é necessária</li>
      </ul>
      
      <a href="https://drive.google.com/file/d/{{ $json.google_drive_file_id }}" class="btn">📄 Visualizar Documento</a>
    </div>
    
    <div class="footer">
      <p>Athié Wohnrath - Sistema de Validação de Documentos</p>
      <p>Decisão tomada por: {{ $json.revisor_email }}</p>
    </div>
  </div>
</body>
</html>
```


***

### **10. Response - Aprovação Confirmada**

Responde ao webhook confirmando aprovação.

**Status Code:** `200`

**Response Body:**

```json
{
  "sucesso": true,
  "mensagem": "Documento aprovado manualmente com sucesso",
  "documento_id": "{{ $json.id }}",
  "nome_arquivo": "{{ $json.nome_arquivo }}",
  "status_anterior": "pendente_revisao",
  "status_atual": "aprovado_manual",
  "score_original": {{ $json.score }},
  "revisor": "{{ $json.revisor_nome }}",
  "email_revisor": "{{ $json.revisor_email }}",
  "data_decisao": "{{ $json.data_decisao_manual }}",
  "timestamp": "{{ new Date().toISOString() }}"
}
```


***

## ❌ **BRANCH: RECUSAR**

### **11. PostgreSQL - UPDATE Status Recusado (Manual)**

Atualiza documento para recusado.

**Query:**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  status = 'recusado_manual',
  data_decisao = NOW(),
  campos_extraidos = COALESCE(campos_extraidos, '{}'::jsonb) || jsonb_build_object(
    'decisao_manual', true,
    'revisor_email', $2,
    'revisor_nome', $3,
    'observacoes_sst', $4,
    'data_decisao_manual', $5
  ),
  updated_at = NOW()
WHERE id = $1
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $json.id }}',
  '{{ $json.revisor_email }}',
  '{{ $json.revisor_nome }}',
  '{{ $json.observacoes_sst }}',
  '{{ $json.data_decisao_manual }}'
]
```


***

### **12. Google Drive - Mover para Recusados (Manual)**

Move arquivo para pasta de recusados.

**Configuration:**

- **Operation:** Move
- **File ID:** `{{ $json.google_drive_file_id }}`
- **New Parent Folder ID:** `{{ $env.GOOGLE_DRIVE_FOLDER_RECUSADOS }}`

***

### **13. PostgreSQL - Log Recusa Manual**

Registra log da recusa manual.

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
  'decisao_manual_sst',
  'recusado_manual',
  jsonb_build_object(
    'score_original', $2,
    'decisao', 'recusado',
    'revisor_email', $3,
    'revisor_nome', $4,
    'observacoes', $5
  ),
  NOW()
)
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $json.id }}',
  {{ $json.score }},
  '{{ $json.revisor_email }}',
  '{{ $json.revisor_nome }}',
  '{{ $json.observacoes_sst }}'
]
```


***

### **14. Gmail - Email Recusa Manual**

Envia email de recusa ao fornecedor.

**To:** `{{ $json.email_destinatario }}`
**Subject:** `❌ Documento Recusado (Revisão Manual) - {{ $json.nome_arquivo }}`

**HTML Body:**

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #f44336; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #fff; padding: 20px; border: 1px solid #ddd; }
    .score-box { background: #ffebee; padding: 20px; margin: 20px 0; border-left: 4px solid #f44336; }
    .info-box { background: #f5f5f5; padding: 15px; margin: 15px 0; border-radius: 4px; }
    .alert-box { background: #fff3cd; padding: 15px; margin: 15px 0; border-left: 4px solid #ffc107; }
    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    .btn { display: inline-block; background: #f44336; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin: 10px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>❌ Documento Recusado</h1>
      <p style="margin: 5px 0; font-size: 14px;">(Após Revisão Manual SST)</p>
    </div>
    
    <div class="content">
      <p>Prezado(a),</p>
      
      <p>O documento <strong>{{ $json.nome_arquivo }}</strong> foi analisado pela equipe de Segurança e Saúde do Trabalho e <strong style="color: #f44336;">NÃO FOI APROVADO</strong>.</p>
      
      <div class="score-box">
        <h3 style="margin-top: 0;">📊 Resultado da Avaliação</h3>
        <p style="font-size: 20px; margin: 10px 0;"><strong>Score Automático: {{ $json.score }}/100</strong></p>
        <p style="margin: 5px 0;">❌ Status: <strong>RECUSADO MANUALMENTE</strong></p>
        <p style="margin: 5px 0;">👤 Revisor: <strong>{{ $json.revisor_nome }}</strong></p>
      </div>
      
      <div class="alert-box">
        <h3 style="margin-top: 0;">⚠️ Motivo da Recusa</h3>
        <p style="font-style: italic;">"{{ $json.observacoes_sst }}"</p>
      </div>
      
      <div class="info-box">
        <h3>📋 Informações do Documento</h3>
        <ul style="list-style: none; padding: 0;">
          <li><strong>Tipo:</strong> {{ $json.tipo_documento }}</li>
          <li><strong>ID:</strong> {{ $json.id }}</li>
          <li><strong>Data de Revisão:</strong> {{ new Date($json.data_decisao_manual).toLocaleString('pt-BR') }}</li>
        </ul>
      </div>
      
      <h3>📝 Próximos Passos:</h3>
      <ol>
        <li><strong>Leia atentamente as observações do revisor</strong> acima</li>
        <li><strong>Corrija os problemas identificados</strong> no documento</li>
        <li><strong>Certifique-se de que todas as informações obrigatórias</strong> estão completas e legíveis</li>
        <li><strong>Reenvie o documento corrigido</strong> através do sistema</li>
      </ol>
      
      <a href="https://drive.google.com/file/d/{{ $json.google_drive_file_id }}" class="btn">📄 Visualizar Documento Recusado</a>
      
      <p style="margin-top: 20px;"><strong>Em caso de dúvidas sobre a recusa, entre em contato com: {{ $json.revisor_email }}</strong></p>
    </div>
    
    <div class="footer">
      <p>Athié Wohnrath - Sistema de Validação de Documentos</p>
      <p>Decisão tomada por: {{ $json.revisor_email }}</p>
    </div>
  </div>
</body>
</html>
```


***

### **15. Response - Recusa Confirmada**

Responde ao webhook confirmando recusa.

**Status Code:** `200`

**Response Body:**

```json
{
  "sucesso": true,
  "mensagem": "Documento recusado manualmente com sucesso",
  "documento_id": "{{ $json.id }}",
  "nome_arquivo": "{{ $json.nome_arquivo }}",
  "status_anterior": "pendente_revisao",
  "status_atual": "recusado_manual",
  "score_original": {{ $json.score }},
  "revisor": "{{ $json.revisor_nome }}",
  "email_revisor": "{{ $json.revisor_email }}",
  "data_decisao": "{{ $json.data_decisao_manual }}",
  "timestamp": "{{ new Date().toISOString() }}"
}
```


***

## 📊 Fluxo Visual

```
┌─────────────────────┐
│   Webhook POST      │
│  /decisao-sst       │
│ {documento_id,      │
│  decisao: aprovar/  │
│  recusar}           │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Validar Payload     │
│ • documento_id OK?  │
│ • decisao válida?   │
│ • email válido?     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ SELECT Documento    │
│ WHERE id = $1       │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Validar Status      │
│ pendente_revisao?   │
└──────────┬──────────┘
           │
     ┌─────┴─────┐
     │           │
  aprovar     recusar
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│ UPDATE  │ │ UPDATE  │
│aprovado_│ │recusado_│
│manual   │ │manual   │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│  Move   │ │  Move   │
│ GDrive  │ │ GDrive  │
│validados│ │recusados│
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│   Log   │ │   Log   │
│Aprovação│ │ Recusa  │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────┐ ┌─────────┐
│  Email  │ │  Email  │
│Fornece- │ │Fornece- │
│dor      │ │dor      │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌─────────────────────┐
│   Response 200      │
│ sucesso: true       │
└─────────────────────┘
```


***

## ✅ Resultado do Sub-Workflow SST

**Entrada:**

- Documento com status `pendente_revisao` (score 70-89)
- Decisão manual do revisor SST

**Saída (Aprovar):**

- ✅ Status: `aprovado_manual`
- ✅ Arquivo movido para `3-validados`
- ✅ Email enviado ao fornecedor
- ✅ Log com dados do revisor
- ✅ Resposta 200 confirmando aprovação

**Saída (Recusar):**

- ❌ Status: `recusado_manual`
- ❌ Arquivo movido para `5-recusados`
- ❌ Email enviado ao fornecedor
- ❌ Log com dados do revisor
- ❌ Resposta 200 confirmando recusa

***

## 🧪 Exemplos de Uso

### **Aprovar Documento:**

```bash
curl -X POST http://localhost:5678/webhook/decisao-sst \
  -H "X-API-Key: sua-api-key-sst" \
  -H "Content-Type: application/json" \
  -d '{
    "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
    "decisao": "aprovar",
    "revisor_email": "joao.silva@athie.com.br",
    "revisor_nome": "João Silva - Engenheiro SST",
    "observacoes": "Revisão manual completa. Critérios de assinatura e data validados presencialmente. Documento aprovado para arquivo."
  }'
```

**Resposta:**

```json
{
  "sucesso": true,
  "mensagem": "Documento aprovado manualmente com sucesso",
  "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
  "nome_arquivo": "ASO_2025.pdf",
  "status_anterior": "pendente_revisao",
  "status_atual": "aprovado_manual",
  "score_original": 85,
  "revisor": "João Silva - Engenheiro SST",
  "email_revisor": "joao.silva@athie.com.br",
  "data_decisao": "2025-12-05T22:00:00.000Z",
  "timestamp": "2025-12-05T22:00:05.123Z"
}
```


***

### **Recusar Documento:**

```bash
curl -X POST http://localhost:5678/webhook/decisao-sst \
  -H "X-API-Key: sua-api-key-sst" \
  -H "Content-Type: application/json" \
  -d '{
    "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
    "decisao": "recusar",
    "revisor_email": "maria.santos@athie.com.br",
    "revisor_nome": "Maria Santos - Médica do Trabalho",
    "observacoes": "Documento recusado devido a assinatura médica ilegível e ausência de carimbo com CRM. Solicitar reenvio com documentação completa e legível."
  }'
```

**Resposta:**

```json
{
  "sucesso": true,
  "mensagem": "Documento recusado manualmente com sucesso",
  "documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
  "nome_arquivo": "ASO_2025.pdf",
  "status_anterior": "pendente_revisao",
  "status_atual": "recusado_manual",
  "score_original": 75,
  "revisor": "Maria Santos - Médica do Trabalho",
  "email_revisor": "maria.santos@athie.com.br",
  "data_decisao": "2025-12-05T22:05:00.000Z",
  "timestamp": "2025-12-05T22:05:03.456Z"
}
```


***

## 🔒 Segurança

- ✅ Autenticação via `X-API-Key` específica para SST
- ✅ Validação de status do documento (apenas `pendente_revisao`)
- ✅ Validação de formato de email
- ✅ Registro completo do revisor e timestamp
- ✅ Todas as ações auditadas em logs

***

## 📈 Métricas

- **Tempo médio de processamento:** ~5 segundos
- **Taxa de aprovação manual:** ~80%
- **Taxa de recusa manual:** ~20%
- **SLA para decisão SST:** 24-48 horas

***

## 🎯 Estados Finais do Documento

| Status Original | Decisão SST | Status Final | Pasta GDrive |
| :-- | :-- | :-- | :-- |
| `pendente_revisao` | `aprovar` | `aprovado_manual` | `3-validados` |
| `pendente_revisao` | `recusar` | `recusado_manual` | `5-recusados` |


***
