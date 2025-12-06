# 📦 Como usar:


### 1. Dar permissão de execução:
```bash
chmod +x scripts/*.sh
```

### 2. Testar um documento específico:
```bash
./scripts/test-webhook.sh "samples/Documentos Aprovados/ASO_valido.pdf"
```

### 3. Testar múltiplos documentos:
```bash
./scripts/test-webhook.sh samples/Documentos\ Aprovados/*.pdf
```

### 4. Testar TODOS os samples:
```bash
./scripts/test-all-samples.sh
```

### 5. Tomar decisão SST:
```bash
# Aprovar
./scripts/test-sst.sh aprovar 0983a6cb-2896-4b78-96b9-a31c6e90410b

# Recusar
./scripts/test-sst.sh recusar 0983a6cb-2896-4b78-96b9-a31c6e90410b "Assinatura ilegível"
```

### 6. Popular critérios no banco:
```bash
./scripts/populate-criterios.sh
``` 