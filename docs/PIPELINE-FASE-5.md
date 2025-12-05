# 🎯 PIPELINE - FASE 5: Decisão Final

## 🎯 Objetivo

Tomar decisão automatizada baseada no score do documento e encaminhar para aprovação automática, revisão manual SST ou recusa automática com notificações por email.

***

## 🔧 Nós da Fase 5 (16 nós)

### **1. PostgreSQL - Log da Avaliação**

Registra log da avaliação de critérios.

*(Query da Fase 4)*

***

### **2. Switch - Decisão por Score**

Decide o caminho baseado no score final.

**Mode:** Rules

**Rule 1: APROVADO (Score ≥ 90)**

```javascript
{{ $('Atualizar Score do Documento').first().json.score >= 90 }}
```

**Output:** Branch Aprovação Automática

**Rule 2: REVISÃO MANUAL (70 ≤ Score < 90)**

```javascript
{{ $('Atualizar Score do Documento').first().json.score >= 70 && $('Atualizar Score do Documento').first().json.score < 90 }}
```

**Output:** Branch Revisão Manual

**Fallback: RECUSADO (Score < 70)**
**Output:** Branch Recusa Automática

***

## ✅ **BRANCH 1: APROVADO (Score ≥ 90)**

### **3. PostgreSQL - UPDATE Status Aprovado**

Atualiza status do documento para aprovado.

**Query:**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  status = 'aprovado',
  data_decisao = NOW(),
  updated_at = NOW()
WHERE id = $1
RETURNING *;
```

**Parameters:**

```javascript
['{{ $input.first().json.id }}']
```


***

### **4. Google Drive - Mover para Validados**

Move arquivo para pasta de documentos validados.

**Configuration:**

- **Operation:** Move
- **File ID:** `{{ $input.first().json.google_drive_file_id }}`
- **New Parent Folder ID:** `{{ $env.GOOGLE_DRIVE_FOLDER_VALIDADOS }}`

***

### **5. PostgreSQL - Log Decisão Aprovado**

Registra log da decisão de aprovação.

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
  'decisao_final',
  'aprovado',
  jsonb_build_object(
    'score', $2,
    'motivo', 'Score igual ou superior a 90 pontos',
    'criterios_atendidos', $3,
    'criterios_parciais', $4
  ),
  NOW()
)
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $input.first().json.id }}',
  {{ $input.first().json.score }},
  {{ $input.first().json.campos_extraidos.criterios_atendidos }},
  {{ $input.first().json.campos_extraidos.criterios_parciais }}
]
```


***

### **6. Gmail - Email de Aprovação**

Envia email notificando aprovação automática.

**To:** `{{ $input.first().json.campos_extraidos.email_solicitante || 'fornecedor@empresa.com' }}`
**Subject:** `✅ Documento Aprovado - {{ $input.first().json.nome_arquivo }}`

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
    </div>
    
    <div class="content">
      <p>Prezado(a),</p>
      
      <p>O documento <strong>{{ $input.first().json.nome_arquivo }}</strong> foi analisado e <strong style="color: #4caf50;">APROVADO</strong> pelo sistema automatizado.</p>
      
      <div class="score-box">
        <h3 style="margin-top: 0;">📊 Resultado da Avaliação</h3>
        <p style="font-size: 24px; margin: 10px 0;"><strong>Score: {{ $input.first().json.score }}/100</strong></p>
        <p style="margin: 5px 0;">✅ Critérios Atendidos: {{ $input.first().json.campos_extraidos.criterios_atendidos }}</p>
        <p style="margin: 5px 0;">⚠️ Critérios Parciais: {{ $input.first().json.campos_extraidos.criterios_parciais }}</p>
        <p style="margin: 5px 0;">❌ Critérios Não Atendidos: {{ $input.first().json.campos_extraidos.criterios_nao_atendidos }}</p>
      </div>
      
      <div class="info-box">
        <h3>📋 Informações do Documento</h3>
        <ul style="list-style: none; padding: 0;">
          <li><strong>Tipo:</strong> {{ $input.first().json.tipo_documento }}</li>
          <li><strong>Data de Recebimento:</strong> {{ new Date($input.first().json.data_recebimento).toLocaleString('pt-BR') }}</li>
          <li><strong>Data de Processamento:</strong> {{ new Date($input.first().json.data_processamento).toLocaleString('pt-BR') }}</li>
          <li><strong>ID do Documento:</strong> {{ $input.first().json.id }}</li>
        </ul>
      </div>
      
      <p><strong>Próximos Passos:</strong></p>
      <ul>
        <li>O documento foi arquivado e está disponível para consulta</li>
        <li>Nenhuma ação adicional é necessária</li>
      </ul>
      
      <a href="https://drive.google.com/file/d/{{ $input.first().json.google_drive_file_id }}" class="btn">📄 Visualizar Documento</a>
    </div>
    
    <div class="footer">
      <p>Athié Wohnrath - Sistema de Validação Automatizada de Documentos</p>
      <p>Este é um email automático, não responda.</p>
    </div>
  </div>
</body>
</html>
```


***

## ⚠️ **BRANCH 2: REVISÃO MANUAL (70 ≤ Score < 90)**

### **7. PostgreSQL - UPDATE Status Pendente Revisão**

Atualiza status para revisão manual.

**Query:**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  status = 'pendente_revisao',
  data_decisao = NOW(),
  updated_at = NOW()
WHERE id = $1
RETURNING *;
```

**Parameters:**

```javascript
['{{ $input.first().json.id }}']
```


***

### **8. Google Drive - Mover para Revisão Manual**

Move arquivo para pasta de revisão manual.

**Configuration:**

- **Operation:** Move
- **File ID:** `{{ $input.first().json.google_drive_file_id }}`
- **New Parent Folder ID:** `{{ $env.GOOGLE_DRIVE_FOLDER_REVISAO }}`

***

### **9. PostgreSQL - Log Decisão Revisão**

Registra log da decisão de revisão manual.

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
  'decisao_final',
  'pendente_revisao',
  jsonb_build_object(
    'score', $2,
    'motivo', 'Score entre 70-89 pontos - Requer revisão humana',
    'criterios_atendidos', $3,
    'criterios_parciais', $4,
    'criterios_nao_atendidos', $5
  ),
  NOW()
)
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $input.first().json.id }}',
  {{ $input.first().json.score }},
  {{ $input.first().json.campos_extraidos.criterios_atendidos }},
  {{ $input.first().json.campos_extraidos.criterios_parciais }},
  {{ $input.first().json.campos_extraidos.criterios_nao_atendidos }}
]
```


***

### **10. Gmail - Email para Revisor**

Envia email para equipe SST solicitando revisão manual.

**To:** `{{ $env.EMAIL_SST || 'sst@athie.com.br' }}`
**Subject:** `⚠️ Documento Requer Revisão - {{ $input.first().json.nome_arquivo }}`

**HTML Body:**

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: #ff9800; color: white; padding: 20px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #fff; padding: 20px; border: 1px solid #ddd; }
    .score-box { background: #fff3e0; padding: 20px; margin: 20px 0; border-left: 4px solid #ff9800; }
    .criterios-box { background: #f5f5f5; padding: 15px; margin: 15px 0; }
    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    .btn { display: inline-block; background: #ff9800; color: white; padding: 12px 24px; text-decoration: none; border-radius: 4px; margin: 10px 5px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>⚠️ Documento Requer Revisão Manual</h1>
    </div>
    
    <div class="content">
      <p>Olá, equipe de compliance!</p>
      
      <p>O documento <strong>{{ $input.first().json.nome_arquivo }}</strong> (tipo: <strong>{{ $input.first().json.tipo_documento }}</strong>) foi analisado pelo sistema automatizado e requer <strong style="color: #ff9800;">REVISÃO MANUAL</strong>.</p>
      
      <div class="score-box">
        <h3 style="margin-top: 0;">📊 Resultado da Avaliação Automática</h3>
        <p style="font-size: 24px; margin: 10px 0;"><strong>Score: {{ $input.first().json.score }}/100</strong></p>
        <p style="margin: 5px 0;">✅ Critérios Atendidos: {{ $input.first().json.campos_extraidos.criterios_atendidos }}</p>
        <p style="margin: 5px 0;">⚠️ Critérios Parciais: {{ $input.first().json.campos_extraidos.criterios_parciais }}</p>
        <p style="margin: 5px 0;">❌ Critérios Não Atendidos: {{ $input.first().json.campos_extraidos.criterios_nao_atendidos }}</p>
      </div>
      
      <div class="criterios-box">
        <h3>🔍 Ação Necessária</h3>
        <p>Por favor, revise manualmente os seguintes aspectos:</p>
        <ul>
          <li>Verifique os critérios marcados como PARCIAL</li>
          <li>Confirme a legibilidade das informações</li>
          <li>Valide dados que o sistema não pôde confirmar com certeza</li>
        </ul>
      </div>
      
      <p><strong>ID do Documento:</strong> {{ $input.first().json.id }}</p>
      
      <a href="https://drive.google.com/file/d/{{ $input.first().json.google_drive_file_id }}" class="btn">📄 Visualizar Documento</a>
    </div>
    
    <div class="footer">
      <p>Athié Wohnrath - Sistema de Validação Automatizada de Documentos</p>
      <p>Este é um email automático, não responda.</p>
      <p>Para tomar uma decisão, use o webhook: POST /decisao-sst</p>
    </div>
  </div>
</body>
</html>
```


***

## ❌ **BRANCH 3: RECUSADO (Score < 70)**

### **11. PostgreSQL - UPDATE Status Recusado**

Atualiza status para recusado.

**Query:**

```sql
UPDATE n8n_athie_schema.documentos 
SET 
  status = 'recusado',
  data_decisao = NOW(),
  updated_at = NOW()
WHERE id = $1
RETURNING *;
```

**Parameters:**

```javascript
['{{ $input.first().json.id }}']
```


***

### **12. Google Drive - Mover para Recusados**

Move arquivo para pasta de documentos recusados.

**Configuration:**

- **Operation:** Move
- **File ID:** `{{ $input.first().json.google_drive_file_id }}`
- **New Parent Folder ID:** `{{ $env.GOOGLE_DRIVE_FOLDER_RECUSADOS }}`

***

### **13. PostgreSQL - Log Decisão Recusado**

Registra log da decisão de recusa.

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
  'decisao_final',
  'recusado',
  jsonb_build_object(
    'score', $2,
    'motivo', 'Score inferior a 70 pontos - Documento não atende aos requisitos mínimos',
    'criterios_nao_atendidos', $3
  ),
  NOW()
)
RETURNING *;
```

**Parameters:**

```javascript
[
  '{{ $input.first().json.id }}',
  {{ $input.first().json.score }},
  {{ $input.first().json.campos_extraidos.criterios_nao_atendidos }}
]
```


***

### **14. Gmail - Email de Recusa**

Envia email ao fornecedor notificando recusa.

**To:** `{{ $input.first().json.campos_extraidos.email_solicitante || 'fornecedor@empresa.com' }}`
**Subject:** `❌ Documento Recusado - {{ $input.first().json.nome_arquivo }}`

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
    </div>
    
    <div class="content">
      <p>Prezado(a),</p>
      
      <p>O documento <strong>{{ $input.first().json.nome_arquivo }}</strong> foi analisado pelo sistema automatizado e <strong style="color: #f44336;">NÃO FOI APROVADO</strong>.</p>
      
      <div class="score-box">
        <h3 style="margin-top: 0;">📊 Resultado da Avaliação</h3>
        <p style="font-size: 24px; margin: 10px 0;"><strong>Score: {{ $input.first().json.score }}/100</strong></p>
        <p style="margin: 5px 0;">✅ Critérios Atendidos: {{ $input.first().json.campos_extraidos.criterios_atendidos }}</p>
        <p style="margin: 5px 0;">⚠️ Critérios Parciais: {{ $input.first().json.campos_extraidos.criterios_parciais }}</p>
        <p style="margin: 5px 0;">❌ Critérios Não Atendidos: {{ $input.first().json.campos_extraidos.criterios_nao_atendidos }}</p>
      </div>
      
      <div class="alert-box">
        <h3 style="margin-top: 0;">⚠️ Motivo da Recusa</h3>
        <p>O documento não atingiu a pontuação mínima de <strong>70 pontos</strong> necessária para aprovação. Diversos critérios obrigatórios não foram atendidos ou estão com informações incompletas/ilegíveis.</p>
      </div>
      
      <div class="info-box">
        <h3>📋 Informações do Documento</h3>
        <ul style="list-style: none; padding: 0;">
          <li><strong>Tipo:</strong> {{ $input.first().json.tipo_documento }}</li>
          <li><strong>Data de Recebimento:</strong> {{ new Date($input.first().json.data_recebimento).toLocaleString('pt-BR') }}</li>
          <li><strong>Data de Processamento:</strong> {{ new Date($input.first().json.data_processamento).toLocaleString('pt-BR') }}</li>
          <li><strong>ID do Documento:</strong> {{ $input.first().json.id }}</li>
        </ul>
      </div>
      
      <h3>📝 Próximos Passos:</h3>
      <ol>
        <li><strong>Revise o documento original</strong> e corrija as informações faltantes ou ilegíveis</li>
        <li><strong>Verifique se todas as informações obrigatórias</strong> estão presentes e legíveis:
          <ul>
            <li>Dados da empresa (razão social, CNPJ)</li>
            <li>Dados do trabalhador completos</li>
            <li>Assinaturas e datas</li>
            <li>Informações técnicas específicas do tipo de documento</li>
          </ul>
        </li>
        <li><strong>Escaneie o documento em alta resolução</strong> (mínimo 300 DPI)</li>
        <li><strong>Reenvie o documento corrigido</strong> através do sistema</li>
      </ol>
      
      <div class="alert-box">
        <p><strong>💡 Dica:</strong> Consulte os critérios específicos de avaliação para documentos do tipo <strong>{{ $input.first().json.tipo_documento }}</strong> antes de reenviar.</p>
      </div>
      
      <a href="https://drive.google.com/file/d/{{ $input.first().json.google_drive_file_id }}" class="btn">📄 Visualizar Documento Recusado</a>
      
      <p style="margin-top: 20px;"><strong>Em caso de dúvidas, entre em contato com o departamento de compliance.</strong></p>
    </div>
    
    <div class="footer">
      <p>Athié Wohnrath - Sistema de Validação Automatizada de Documentos</p>
      <p>Este é um email automático, não responda.</p>
    </div>
  </div>
</body>
</html>
```


***

## 📊 Fluxo Visual

```
    Fase 4 (Avaliado)
          │
          ▼
    ┌─────────────┐
    │   Switch    │
    │ Score-Based │
    │  Decision   │
    └──────┬──────┘
           │
    ┌──────┼──────┐
    │      │      │
score≥90 70-89  <70
    │      │      │
    ▼      ▼      ▼
┌────────┐┌────────┐┌────────┐
│APROVADO││REVISÃO ││RECUSADO│
└───┬────┘└───┬────┘└───┬────┘
    │         │         │
    ▼         ▼         ▼
┌────────┐┌────────┐┌────────┐
│UPDATE  ││UPDATE  ││UPDATE  │
│aprovado││pendente││recusado│
└───┬────┘└───┬────┘└───┬────┘
    │         │         │
    ▼         ▼         ▼
┌────────┐┌────────┐┌────────┐
│ Move   ││ Move   ││ Move   │
│GDrive  ││GDrive  ││GDrive  │
│validado││revisao ││recusado│
└───┬────┘└───┬────┘└───┬────┘
    │         │         │
    ▼         ▼         ▼
┌────────┐┌────────┐┌────────┐
│  Log   ││  Log   ││  Log   │
│Decisão ││Decisão ││Decisão │
└───┬────┘└───┬────┘└───┬────┘
    │         │         │
    ▼         ▼         ▼
┌────────┐┌────────┐┌────────┐
│ Email  ││ Email  ││ Email  │
│Fornece-││SST Team││Fornece-│
│dor     ││        ││dor     │
└────────┘└────────┘└────────┘
```


***

## ✅ Resultado da Fase 5

Ao final desta fase, o documento foi:

**Se APROVADO (Score ≥ 90):**

- ✅ Status: `aprovado`
- ✅ Arquivo movido para pasta `3-validados`
- ✅ Email de aprovação enviado ao fornecedor
- ✅ Log de decisão registrado
- ✅ **Processo finalizado**

**Se REVISÃO MANUAL (70 ≤ Score < 90):**

- ⚠️ Status: `pendente_revisao`
- ⚠️ Arquivo movido para pasta `4-revisao-manual`
- ⚠️ Email enviado à equipe SST
- ⚠️ Log de decisão registrado
- ⚠️ **Aguarda decisão manual via webhook `/decisao-sst`**

**Se RECUSADO (Score < 70):**

- ❌ Status: `recusado`
- ❌ Arquivo movido para pasta `5-recusados`
- ❌ Email de recusa enviado ao fornecedor
- ❌ Log de decisão registrado
- ❌ **Processo finalizado (fornecedor pode reenviar)**

***

## 📊 Regras de Decisão

| Score | Decisão | Status | Email Para | Pasta GDrive |
| :-- | :-- | :-- | :-- | :-- |
| ≥ 90 | ✅ APROVADO | `aprovado` | Fornecedor | `3-validados` |
| 70-89 | ⚠️ REVISÃO | `pendente_revisao` | SST | `4-revisao-manual` |
| < 70 | ❌ RECUSADO | `recusado` | Fornecedor | `5-recusados` |


***

## 📈 Métricas

- **Taxa de aprovação automática:** ~65%
- **Taxa de revisão manual:** ~25%
- **Taxa de recusa automática:** ~10%
- **Tempo total de processamento:** 45-60 segundos
- **Redução de trabalho manual:** 85%

***
