-- =====================================================
-- SEED: Critérios de Avaliação de Documentos
-- Sistema: N8N-system - Athié Wohnrath - Trajano
-- =====================================================

-- Limpar dados existentes (opcional, comentar se não quiser)
-- TRUNCATE TABLE n8n_athie_schema.criterios_documento CASCADE;

-- =====================================================
-- ASO - Atestado de Saúde Ocupacional
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('ASO', 'ASO-01', 'Documento legível, sem rasuras em formato PDF', 5, 'Formato'),
('ASO', 'ASO-02', 'Dados da empresa (razão social, CNPJ)', 10, 'Dados da Empresa'),
('ASO', 'ASO-03', 'Dados do trabalhador (nome completo, CPF, cargo)', 10, 'Dados do Trabalhador'),
('ASO', 'ASO-04', 'Tipo de exame identificado (admissional, periódico, mudança de função, retorno ao trabalho, demissional)', 10, 'Tipo de Exame'),
('ASO', 'ASO-05', 'Data de realização do exame médico', 10, 'Datas'),
('ASO', 'ASO-06', 'Riscos ocupacionais identificados', 15, 'Riscos'),
('ASO', 'ASO-07', 'Exames clínicos e complementares realizados', 15, 'Exames'),
('ASO', 'ASO-08', 'Conclusão médica: Apto ou Inapto', 10, 'Conclusão'),
('ASO', 'ASO-09', 'Assinatura e CRM do médico examinador', 15, 'Assinatura');

-- =====================================================
-- ASO_DEMISSIONAL
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('ASO_DEMISSIONAL', 'ASOD-01', 'Documento legível, sem rasuras', 5, 'Formato'),
('ASO_DEMISSIONAL', 'ASOD-02', 'Dados da empresa (razão social, CNPJ)', 10, 'Dados da Empresa'),
('ASO_DEMISSIONAL', 'ASOD-03', 'Dados do trabalhador (nome completo, CPF)', 10, 'Dados do Trabalhador'),
('ASO_DEMISSIONAL', 'ASOD-04', 'Data de demissão', 15, 'Datas'),
('ASO_DEMISSIONAL', 'ASOD-05', 'Data de realização do exame demissional', 10, 'Datas'),
('ASO_DEMISSIONAL', 'ASOD-06', 'Exames realizados', 15, 'Exames'),
('ASO_DEMISSIONAL', 'ASOD-07', 'Conclusão: Apto para demissão', 15, 'Conclusão'),
('ASO_DEMISSIONAL', 'ASOD-08', 'Assinatura e CRM do médico', 20, 'Assinatura');

-- =====================================================
-- PGR - Programa de Gerenciamento de Riscos
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('PGR', 'PGR-01', 'Documento legível e completo', 5, 'Formato'),
('PGR', 'PGR-02', 'Dados da empresa (razão social, CNPJ, CNAE)', 10, 'Dados da Empresa'),
('PGR', 'PGR-03', 'Grau de risco da atividade (1 a 4)', 10, 'Classificação'),
('PGR', 'PGR-04', 'Identificação de perigos e riscos ocupacionais', 20, 'Riscos'),
('PGR', 'PGR-05', 'Medidas de controle implementadas', 20, 'Medidas de Controle'),
('PGR', 'PGR-06', 'Cronograma de ações preventivas', 15, 'Cronograma'),
('PGR', 'PGR-07', 'Data de elaboração e vigência', 10, 'Datas'),
('PGR', 'PGR-08', 'Responsável técnico e registro profissional (CREA, CRM)', 10, 'Responsável Técnico');

-- =====================================================
-- PCMSO - Programa de Controle Médico de Saúde Ocupacional
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('PCMSO', 'PCMSO-01', 'Documento legível e completo', 5, 'Formato'),
('PCMSO', 'PCMSO-02', 'Dados da empresa (razão social, CNPJ)', 10, 'Dados da Empresa'),
('PCMSO', 'PCMSO-03', 'Médico coordenador identificado (nome e CRM)', 15, 'Médico Coordenador'),
('PCMSO', 'PCMSO-04', 'Data de elaboração', 10, 'Datas'),
('PCMSO', 'PCMSO-05', 'Vigência do programa (início e fim)', 10, 'Vigência'),
('PCMSO', 'PCMSO-06', 'Riscos ocupacionais identificados', 20, 'Riscos'),
('PCMSO', 'PCMSO-07', 'Exames médicos previstos por cargo/função', 20, 'Exames'),
('PCMSO', 'PCMSO-08', 'Cronograma de exames periódicos', 10, 'Cronograma');

-- =====================================================
-- CONTRATO_TRABALHO
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('CONTRATO_TRABALHO', 'CT-01', 'Documento legível', 5, 'Formato'),
('CONTRATO_TRABALHO', 'CT-02', 'Dados da empresa (razão social, CNPJ)', 10, 'Dados da Empresa'),
('CONTRATO_TRABALHO', 'CT-03', 'Dados do empregado (nome completo, CPF, RG)', 15, 'Dados do Empregado'),
('CONTRATO_TRABALHO', 'CT-04', 'Cargo/função', 10, 'Cargo'),
('CONTRATO_TRABALHO', 'CT-05', 'Salário e forma de pagamento', 15, 'Remuneração'),
('CONTRATO_TRABALHO', 'CT-06', 'Jornada de trabalho', 10, 'Jornada'),
('CONTRATO_TRABALHO', 'CT-07', 'Data de admissão', 10, 'Datas'),
('CONTRATO_TRABALHO', 'CT-08', 'Local de trabalho', 5, 'Localização'),
('CONTRATO_TRABALHO', 'CT-09', 'Assinaturas (empregado e empregador)', 20, 'Assinaturas');

-- =====================================================
-- CTPS - Carteira de Trabalho
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('CTPS', 'CTPS-01', 'Documento legível', 10, 'Formato'),
('CTPS', 'CTPS-02', 'Foto visível', 10, 'Identificação'),
('CTPS', 'CTPS-03', 'Dados do trabalhador (nome, CPF, RG)', 20, 'Dados Pessoais'),
('CTPS', 'CTPS-04', 'Número da CTPS', 15, 'Número CTPS'),
('CTPS', 'CTPS-05', 'Data de emissão', 10, 'Datas'),
('CTPS', 'CTPS-06', 'Registro de admissão (se aplicável)', 15, 'Admissão'),
('CTPS', 'CTPS-07', 'Assinatura do trabalhador', 20, 'Assinatura');

-- =====================================================
-- FICHA_REGISTRO
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('FICHA_REGISTRO', 'FR-01', 'Documento legível', 5, 'Formato'),
('FICHA_REGISTRO', 'FR-02', 'Dados da empresa', 10, 'Dados da Empresa'),
('FICHA_REGISTRO', 'FR-03', 'Dados completos do empregado (nome, CPF, RG, endereço)', 20, 'Dados do Empregado'),
('FICHA_REGISTRO', 'FR-04', 'Cargo e função', 10, 'Cargo'),
('FICHA_REGISTRO', 'FR-05', 'Data de admissão', 10, 'Datas'),
('FICHA_REGISTRO', 'FR-06', 'Salário', 10, 'Remuneração'),
('FICHA_REGISTRO', 'FR-07', 'Jornada de trabalho', 10, 'Jornada'),
('FICHA_REGISTRO', 'FR-08', 'Número CTPS', 10, 'CTPS'),
('FICHA_REGISTRO', 'FR-09', 'Assinatura do empregado', 15, 'Assinatura');

-- =====================================================
-- ORDEM_SERVICO
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('ORDEM_SERVICO', 'OS-01', 'Documento legível', 5, 'Formato'),
('ORDEM_SERVICO', 'OS-02', 'Dados da empresa', 10, 'Dados da Empresa'),
('ORDEM_SERVICO', 'OS-03', 'Identificação do trabalhador', 10, 'Trabalhador'),
('ORDEM_SERVICO', 'OS-04', 'Descrição das atividades e riscos', 20, 'Atividades'),
('ORDEM_SERVICO', 'OS-05', 'Medidas de proteção coletivas e individuais', 20, 'EPIs/EPCs'),
('ORDEM_SERVICO', 'OS-06', 'Procedimentos de segurança', 15, 'Procedimentos'),
('ORDEM_SERVICO', 'OS-07', 'Data de emissão', 10, 'Datas'),
('ORDEM_SERVICO', 'OS-08', 'Assinatura do trabalhador (ciência)', 10, 'Assinatura');

-- =====================================================
-- FICHA_EPI
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('FICHA_EPI', 'EPI-01', 'Documento legível', 5, 'Formato'),
('FICHA_EPI', 'EPI-02', 'Dados da empresa', 10, 'Dados da Empresa'),
('FICHA_EPI', 'EPI-03', 'Identificação do trabalhador', 15, 'Trabalhador'),
('FICHA_EPI', 'EPI-04', 'Lista de EPIs entregues', 25, 'EPIs'),
('FICHA_EPI', 'EPI-05', 'Número do CA (Certificado de Aprovação) de cada EPI', 15, 'Certificação'),
('FICHA_EPI', 'EPI-06', 'Data de entrega', 10, 'Datas'),
('FICHA_EPI', 'EPI-07', 'Assinatura do trabalhador', 20, 'Assinatura');

-- =====================================================
-- NR06 - Treinamento EPI
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('NR06', 'NR06-01', 'Documento legível', 5, 'Formato'),
('NR06', 'NR06-02', 'Dados da empresa', 10, 'Dados da Empresa'),
('NR06', 'NR06-03', 'Nome do participante', 15, 'Participante'),
('NR06', 'NR06-04', 'Conteúdo programático do treinamento', 20, 'Conteúdo'),
('NR06', 'NR06-05', 'Carga horária (mínimo exigido pela NR)', 15, 'Carga Horária'),
('NR06', 'NR06-06', 'Data de realização', 10, 'Datas'),
('NR06', 'NR06-07', 'Instrutor responsável', 10, 'Instrutor'),
('NR06', 'NR06-08', 'Assinatura do participante', 15, 'Assinatura');

-- =====================================================
-- NR10 - Treinamento Eletricidade
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('NR10', 'NR10-01', 'Documento legível', 5, 'Formato'),
('NR10', 'NR10-02', 'Dados da empresa', 10, 'Dados da Empresa'),
('NR10', 'NR10-03', 'Nome do participante', 10, 'Participante'),
('NR10', 'NR10-04', 'Tipo de treinamento (básico ou complementar)', 10, 'Tipo'),
('NR10', 'NR10-05', 'Conteúdo programático conforme NR-10', 20, 'Conteúdo'),
('NR10', 'NR10-06', 'Carga horária (40h básico ou 40h complementar)', 15, 'Carga Horária'),
('NR10', 'NR10-07', 'Data de realização e validade (2 anos)', 10, 'Datas'),
('NR10', 'NR10-08', 'Instrutor habilitado', 10, 'Instrutor'),
('NR10', 'NR10-09', 'Assinatura do participante', 10, 'Assinatura');

-- =====================================================
-- NR12 - Treinamento Máquinas e Equipamentos
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('NR12', 'NR12-01', 'Documento legível', 5, 'Formato'),
('NR12', 'NR12-02', 'Dados da empresa', 10, 'Dados da Empresa'),
('NR12', 'NR12-03', 'Nome do participante', 10, 'Participante'),
('NR12', 'NR12-04', 'Tipo de máquina/equipamento', 15, 'Equipamento'),
('NR12', 'NR12-05', 'Conteúdo programático conforme NR-12', 20, 'Conteúdo'),
('NR12', 'NR12-06', 'Carga horária adequada', 10, 'Carga Horária'),
('NR12', 'NR12-07', 'Data de realização', 10, 'Datas'),
('NR12', 'NR12-08', 'Instrutor qualificado', 10, 'Instrutor'),
('NR12', 'NR12-09', 'Assinatura do participante', 10, 'Assinatura');

-- =====================================================
-- NR18 - Treinamento Segurança na Construção
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('NR18', 'NR18-01', 'Documento legível', 5, 'Formato'),
('NR18', 'NR18-02', 'Dados da empresa', 10, 'Dados da Empresa'),
('NR18', 'NR18-03', 'Nome do participante', 10, 'Participante'),
('NR18', 'NR18-04', 'Conteúdo: riscos na construção civil', 20, 'Conteúdo'),
('NR18', 'NR18-05', 'Carga horária (mínimo 6h admissional)', 15, 'Carga Horária'),
('NR18', 'NR18-06', 'Data de realização', 10, 'Datas'),
('NR18', 'NR18-07', 'Instrutor habilitado', 10, 'Instrutor'),
('NR18', 'NR18-08', 'Assinatura do participante', 20, 'Assinatura');

-- =====================================================
-- NR35 - Treinamento Trabalho em Altura
-- =====================================================
INSERT INTO n8n_athie_schema.criterios_documento 
(tipo_documento, criterio_id, descricao, peso, categoria)
VALUES
('NR35', 'NR35-01', 'Documento legível', 5, 'Formato'),
('NR35', 'NR35-02', 'Dados da empresa', 10, 'Dados da Empresa'),
('NR35', 'NR35-03', 'Nome do participante', 10, 'Participante'),
('NR35', 'NR35-04', 'Conteúdo programático conforme NR-35', 20, 'Conteúdo'),
('NR35', 'NR35-05', 'Carga horária (mínimo 8h)', 15, 'Carga Horária'),
('NR35', 'NR35-06', 'Data de realização e validade (2 anos)', 10, 'Datas'),
('NR35', 'NR35-07', 'Instrutor habilitado', 10, 'Instrutor'),
('NR35', 'NR35-08', 'Avaliação prática e teórica', 10, 'Avaliação'),
('NR35', 'NR35-09', 'Assinatura do participante', 10, 'Assinatura');

-- =====================================================
-- Verificar inserções
-- =====================================================
SELECT tipo_documento, COUNT(*) as total_criterios
FROM n8n_athie_schema.criterios_documento
GROUP BY tipo_documento
ORDER BY tipo_documento;
