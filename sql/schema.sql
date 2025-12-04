-- Criar schema
CREATE SCHEMA IF NOT EXISTS n8n_athie_schema;

-- Definir o schema como padrão para esta sessão
SET search_path TO n8n_athie_schema, public;

-- Criar extensões necessárias (no schema correto)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp" SCHEMA n8n_athie_schema;

-- Criar tabela documentos
CREATE TABLE IF NOT EXISTS n8n_athie_schema.documentos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nome_arquivo VARCHAR(255) NOT NULL,
  hash_sha256 VARCHAR(64) UNIQUE NOT NULL,
  tipo_documento VARCHAR(50),
  status VARCHAR(50) NOT NULL DEFAULT 'recebido',
  score DECIMAL(5,2),
  confidence_tipo DECIMAL(3,2),
  texto_extraido TEXT,
  campos_extraidos JSONB,
  google_drive_file_id VARCHAR(255),
  google_drive_folder VARCHAR(100),
  data_recebimento TIMESTAMP NOT NULL DEFAULT NOW(),
  data_processamento TIMESTAMP,
  data_decisao TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_documentos_status ON n8n_athie_schema.documentos(status);
CREATE INDEX IF NOT EXISTS idx_documentos_tipo ON n8n_athie_schema.documentos(tipo_documento);
CREATE INDEX IF NOT EXISTS idx_documentos_hash ON n8n_athie_schema.documentos(hash_sha256);
CREATE INDEX IF NOT EXISTS idx_documentos_data_recebimento ON n8n_athie_schema.documentos(data_recebimento DESC);

-- Criar tabela criterios_avaliacao
CREATE TABLE IF NOT EXISTS n8n_athie_schema.criterios_avaliacao (
  id SERIAL PRIMARY KEY,
  documento_id UUID NOT NULL REFERENCES n8n_athie_schema.documentos(id) ON DELETE CASCADE,
  criterio_id VARCHAR(50) NOT NULL,
  criterio_descricao TEXT NOT NULL,
  atendido BOOLEAN NOT NULL,
  pontuacao_obtida DECIMAL(5,2) NOT NULL,
  pontuacao_maxima DECIMAL(5,2) NOT NULL,
  observacao TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_criterios_documento ON n8n_athie_schema.criterios_avaliacao(documento_id);
CREATE INDEX IF NOT EXISTS idx_criterios_atendido ON n8n_athie_schema.criterios_avaliacao(atendido);

-- Criar tabela logs_processamento
CREATE TABLE IF NOT EXISTS n8n_athie_schema.logs_processamento (
  id SERIAL PRIMARY KEY,
  documento_id UUID REFERENCES n8n_athie_schema.documentos(id) ON DELETE SET NULL,
  etapa VARCHAR(50) NOT NULL,
  status VARCHAR(20) NOT NULL,
  detalhes JSONB NOT NULL,
  duracao_ms INTEGER,
  timestamp TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_logs_documento ON n8n_athie_schema.logs_processamento(documento_id);
CREATE INDEX IF NOT EXISTS idx_logs_etapa ON n8n_athie_schema.logs_processamento(etapa);
CREATE INDEX IF NOT EXISTS idx_logs_status ON n8n_athie_schema.logs_processamento(status);
CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON n8n_athie_schema.logs_processamento(timestamp DESC);

-- Criar tabela decisoes_sst
CREATE TABLE IF NOT EXISTS n8n_athie_schema.decisoes_sst (
  id SERIAL PRIMARY KEY,
  documento_id UUID NOT NULL UNIQUE REFERENCES n8n_athie_schema.documentos(id) ON DELETE CASCADE,
  usuario_sst VARCHAR(255) NOT NULL,
  decisao VARCHAR(20) NOT NULL,
  justificativa TEXT NOT NULL,
  data_decisao TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_decisoes_documento ON n8n_athie_schema.decisoes_sst(documento_id);
CREATE INDEX IF NOT EXISTS idx_decisoes_usuario ON n8n_athie_schema.decisoes_sst(usuario_sst);

-- View para Dashboard
CREATE OR REPLACE VIEW n8n_athie_schema.dashboard_documentos AS
SELECT
  d.tipo_documento,
  d.status,
  COUNT(*) as total_documentos,
  AVG(d.score) as score_medio,
  AVG(d.confidence_tipo) as confidence_media,
  MIN(d.data_recebimento) as primeiro_documento,
  MAX(d.data_recebimento) as ultimo_documento
FROM n8n_athie_schema.documentos d
GROUP BY d.tipo_documento, d.status
ORDER BY d.tipo_documento, d.status;

-- Trigger para updated_at
CREATE OR REPLACE FUNCTION n8n_athie_schema.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE TRIGGER update_documentos_updated_at
BEFORE UPDATE ON n8n_athie_schema.documentos
FOR EACH ROW
EXECUTE FUNCTION n8n_athie_schema.update_updated_at_column();
