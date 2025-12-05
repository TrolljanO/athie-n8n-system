# 📡 API Documentation - Webhooks

Sistema de validação de documentos via N8N com webhooks REST.

---

## 🔐 Autenticação

Todas as requisições devem incluir o header de autenticação:

```

X-API-Key: sua-api-key-aqui

```

**Headers obrigatórios:**
- `X-API-Key`: Token de autenticação
- `Content-Type`: `multipart/form-data` (para upload de arquivos)

---

## 📥 **Webhook 1: Receber Documento**

### **Endpoint**
```

POST /webhook/receber-documento

```

### **Descrição**
Envia um documento para validação automatizada. O sistema retorna imediatamente um ID de documento e processa assincronamente.

### **Headers**
```

X-API-Key: sua-api-key-principal
Content-Type: multipart/form-data

```

### **Body (form-data)**

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `arquivo` | File | ✅ Sim | Arquivo PDF, JPG ou PNG (máx 10MB) |
| `email_fornecedor` | String | ❌ Opcional | Email do fornecedor para notificações |
| `metadata` | JSON | ❌ Opcional | Metadados adicionais |

### **Exemplo de Requisição (cURL)**

```

curl -X POST http://localhost:5678/webhook/receber-documento \
-H "X-API-Key: sua-api-key-principal" \
-F "arquivo=@/path/to/ASO_exemplo.pdf" \
-F "email_fornecedor=fornecedor@empresa.com.br" \
-F 'metadata={"fonte":"sistema_rh","prioridade":"normal"}'

```

### **Exemplo de Requisição (JavaScript)**

```

const formData = new FormData();
formData.append('arquivo', fileInput.files);
formData.append('email_fornecedor', 'fornecedor@empresa.com.br');
formData.append('metadata', JSON.stringify({
fonte: 'sistema_rh',
prioridade: 'normal'
}));

fetch('http://localhost:5678/webhook/receber-documento', {
method: 'POST',
headers: {
'X-API-Key': 'sua-api-key-principal'
},
body: formData
})
.then(response => response.json())
.then(data => console.log(data));

```

### **Respostas**

#### ✅ **200 OK - Documento Novo**
```

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

#### ✅ **200 OK - Documento Duplicado**
```

{
"sucesso": true,
"documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
"status": "aprovado",
"mensagem": "Documento já processado anteriormente",
"tipo_documento": "ASO",
"score": 90,
"data_recebimento": "2025-12-05T22:00:00.000Z",
"timestamp": "2025-12-05T23:00:00.000Z"
}

```

#### ❌ **400 Bad Request - Arquivo Inválido**
```

{
"sucesso": false,
"erro": "Campo arquivo ausente ou inválido",
"codigo": "ARQUIVO_INVALIDO"
}

```

#### ❌ **400 Bad Request - Formato Não Suportado**
```

{
"sucesso": false,
"erro": "Formato não suportado. Use PDF, JPG ou PNG.",
"codigo": "FORMATO_INVALIDO"
}

```

#### ❌ **400 Bad Request - Arquivo Muito Grande**
```

{
"sucesso": false,
"erro": "Arquivo muito grande. Máximo: 10MB",
"codigo": "TAMANHO_EXCEDIDO"
}

```

#### ❌ **401 Unauthorized**
```

{
"sucesso": false,
"erro": "API Key inválida ou ausente",
"codigo": "AUTENTICACAO_FALHOU"
}

```

---

## ⚖️ **Webhook 2: Decisão Manual SST**

### **Endpoint**
```

POST /webhook/decisao-sst

```

### **Descrição**
Permite que a equipe SST tome decisões manuais sobre documentos com status `pendente_revisao` (score entre 70-89).

### **Headers**
```

X-API-Key: sua-api-key-sst
Content-Type: application/json

```

### **Body (JSON)**

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `documento_id` | UUID | ✅ Sim | ID do documento (recebido no webhook anterior) |
| `decisao` | String | ✅ Sim | `"aprovar"` ou `"recusar"` |
| `revisor_email` | String | ✅ Sim | Email do revisor SST |
| `revisor_nome` | String | ❌ Opcional | Nome completo do revisor |
| `observacoes` | String | ❌ Opcional | Observações sobre a decisão |

### **Exemplo de Requisição (cURL) - Aprovar**

```

curl -X POST http://localhost:5678/webhook/decisao-sst \
-H "X-API-Key: sua-api-key-sst" \
-H "Content-Type: application/json" \
-d '{
"documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
"decisao": "aprovar",
"revisor_email": "joao.silva@athie.com.br",
"revisor_nome": "João Silva - Engenheiro SST",
"observacoes": "Documento aprovado após revisão manual."
}'

```

### **Exemplo de Requisição (cURL) - Recusar**

```

curl -X POST http://localhost:5678/webhook/decisao-sst \
-H "X-API-Key: sua-api-key-sst" \
-H "Content-Type: application/json" \
-d '{
"documento_id": "0983a6cb-2896-4b78-96b9-a31c6e90410b",
"decisao": "recusar",
"revisor_email": "maria.santos@athie.com.br",
"revisor_nome": "Maria Santos - Médica do Trabalho",
"observacoes": "Documento recusado devido a assinatura ilegível."
}'

```

### **Exemplo de Requisição (JavaScript)**

```

const decisao = {
documento_id: '0983a6cb-2896-4b78-96b9-a31c6e90410b',
decisao: 'aprovar',
revisor_email: 'joao.silva@athie.com.br',
revisor_nome: 'João Silva - Eng. SST',
observacoes: 'Documento aprovado após revisão.'
};

fetch('http://localhost:5678/webhook/decisao-sst', {
method: 'POST',
headers: {
'X-API-Key': 'sua-api-key-sst',
'Content-Type': 'application/json'
},
body: JSON.stringify(decisao)
})
.then(response => response.json())
.then(data => console.log(data));

```

### **Respostas**

#### ✅ **200 OK - Aprovação Manual**
```

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

#### ✅ **200 OK - Recusa Manual**
```

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

#### ❌ **400 Bad Request - Campo Obrigatório Ausente**
```

{
"sucesso": false,
"erro": "Campo documento_id é obrigatório",
"codigo": "CAMPO_OBRIGATORIO"
}

```

#### ❌ **400 Bad Request - Decisão Inválida**
```

{
"sucesso": false,
"erro": "Campo decisao deve ser 'aprovar' ou 'recusar'",
"codigo": "DECISAO_INVALIDA"
}

```

#### ❌ **400 Bad Request - Email Inválido**
```

{
"sucesso": false,
"erro": "Email do revisor inválido",
"codigo": "EMAIL_INVALIDO"
}

```

#### ❌ **404 Not Found - Documento Não Encontrado**
```

{
"sucesso": false,
"erro": "Documento não encontrado",
"codigo": "DOCUMENTO_NAO_ENCONTRADO"
}

```

#### ❌ **400 Bad Request - Status Inválido**
```

{
"sucesso": false,
"erro": "Documento não pode receber decisão manual. Status atual: aprovado",
"codigo": "STATUS_INVALIDO"
}

```

#### ❌ **401 Unauthorized**
```

{
"sucesso": false,
"erro": "API Key SST inválida ou ausente",
"codigo": "AUTENTICACAO_FALHOU"
}

```

---

## 📊 **Estados do Documento**

| Status | Descrição |
|--------|-----------|
| `recebido` | Documento recebido, aguardando processamento |
| `processando` | Classificação em andamento |
| `ocr_em_andamento` | Extração de texto em andamento |
| `ocr_completo` | OCR concluído com sucesso |
| `ocr_falhou` | Documento ilegível |
| `avaliado` | Critérios avaliados, aguardando decisão |
| `aprovado` | Aprovado automaticamente (score ≥ 90) |
| `pendente_revisao` | Aguardando revisão manual SST (70 ≤ score < 90) |
| `recusado` | Recusado automaticamente (score < 70) |
| `aprovado_manual` | Aprovado pela equipe SST |
| `recusado_manual` | Recusado pela equipe SST |
| `tipo_desconhecido` | Tipo não identificado (confidence < 0.70) |

---

## 🔄 **Fluxo de Estados**

```

recebido
↓
processando → tipo_desconhecido (STOP)
↓
ocr_em_andamento → ocr_falhou (STOP)
↓
ocr_completo
↓
avaliado
↓
├─→ aprovado (score ≥ 90)
├─→ pendente_revisao (70-89) → aprovado_manual / recusado_manual
└─→ recusado (score < 70)

```

---

## 🧪 **Testando a API**

### **Collection Postman**

Importe a collection disponível em `docs/POSTMAN-COLLECTION.json`.

### **Teste Rápido (Bash)**

```


# Testar webhook principal

./scripts/test-webhook.sh /path/to/documento.pdf

# Testar decisão SST (aprovar)

./scripts/test-sst.sh aprovar 0983a6cb-2896-4b78-96b9-a31c6e90410b

# Testar decisão SST (recusar)

./scripts/test-sst.sh recusar 0983a6cb-2896-4b78-96b9-a31c6e90410b

```

---

## 🛡️ **Segurança**

- ✅ **Autenticação via API Key** (header `X-API-Key`)
- ✅ **Validação de formato** (apenas PDF, JPG, PNG)
- ✅ **Validação de tamanho** (máximo 10MB)
- ✅ **Hash SHA-256** para integridade
- ✅ **Detecção de duplicatas** automática
- ✅ **Rate limiting** (configurável no N8N)

---

## 📞 **Suporte**

Para dúvidas ou problemas com a API:
- 📧 Email: athiewohnrath.trajano@gmail.com
- 📱 WhatsApp: +55 (XX) XXXXX-XXXX
