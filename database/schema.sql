create table documentos
(
    id                   uuid        default gen_random_uuid()             not null
        primary key,
    nome_arquivo         varchar(255)                                      not null,
    hash_sha256          varchar(64)                                       not null
        unique,
    tipo_documento       varchar(50),
    status               varchar(50) default 'recebido'::character varying not null,
    score                numeric(5, 2),
    confidence_tipo      numeric(3, 2),
    texto_extraido       text,
    campos_extraidos     jsonb,
    google_drive_file_id varchar(255),
    google_drive_folder  varchar(100),
    data_recebimento     timestamp   default now()                         not null,
    data_processamento   timestamp,
    data_decisao         timestamp,
    created_at           timestamp   default now()                         not null,
    updated_at           timestamp   default now()                         not null
);

alter table documentos
    owner to n8nathie;

create index idx_documentos_status
    on documentos (status);

create index idx_documentos_tipo
    on documentos (tipo_documento);

create index idx_documentos_hash
    on documentos (hash_sha256);

create index idx_documentos_data_recebimento
    on documentos (data_recebimento desc);

create table criterios_avaliacao
(
    id                 serial
        primary key,
    documento_id       uuid                    not null
        references documentos
            on delete cascade,
    criterio_id        varchar(50)             not null,
    criterio_descricao text                    not null,
    pontuacao_obtida   numeric(5, 2)           not null,
    pontuacao_maxima   numeric(5, 2)           not null,
    observacao         text,
    created_at         timestamp default now() not null,
    categoria          varchar(100),
    peso               integer,
    atende             varchar(20)
        constraint criterios_avaliacao_atende_check
            check ((atende)::text = ANY
                   ((ARRAY ['SIM'::character varying, 'PARCIAL'::character varying, 'NAO'::character varying, 'NAO_APLICAVEL'::character varying])::text[]))
);

alter table criterios_avaliacao
    owner to n8nathie;

create index idx_criterios_documento
    on criterios_avaliacao (documento_id);

create table logs_processamento
(
    id           serial
        primary key,
    documento_id uuid
                                         references documentos
                                             on delete set null,
    etapa        varchar(50)             not null,
    status       varchar(20)             not null,
    detalhes     jsonb                   not null,
    duracao_ms   integer,
    timestamp    timestamp default now() not null
);

alter table logs_processamento
    owner to n8nathie;

create index idx_logs_documento
    on logs_processamento (documento_id);

create index idx_logs_etapa
    on logs_processamento (etapa);

create index idx_logs_status
    on logs_processamento (status);

create index idx_logs_timestamp
    on logs_processamento (timestamp desc);

create table decisoes_sst
(
    id            serial
        primary key,
    documento_id  uuid                    not null
        unique
        references documentos
            on delete cascade,
    usuario_sst   varchar(255)            not null,
    decisao       varchar(20)             not null,
    justificativa text                    not null,
    data_decisao  timestamp default now() not null
);

alter table decisoes_sst
    owner to n8nathie;

create index idx_decisoes_documento
    on decisoes_sst (documento_id);

create index idx_decisoes_usuario
    on decisoes_sst (usuario_sst);

create table criterios_documentos
(
    id               serial
        primary key,
    tipo_documento   varchar(50)                                  not null,
    nome_completo    varchar(255)                                 not null,
    versao_criterios varchar(10) default '1.0'::character varying not null,
    pontuacao_total  integer     default 100                      not null,
    criterios        jsonb                                        not null,
    ativo            boolean     default true,
    created_at       timestamp   default now()                    not null,
    updated_at       timestamp   default now()                    not null
);

alter table criterios_documentos
    owner to n8nathie;

create unique index idx_criterios_documentos_tipo
    on criterios_documentos (tipo_documento)
    where (ativo = true);

create view dashboard_documentos
            (tipo_documento, status, total_documentos, score_medio, confidence_media, primeiro_documento,
             ultimo_documento) as
SELECT tipo_documento,
       status,
       count(*)              AS total_documentos,
       avg(score)            AS score_medio,
       avg(confidence_tipo)  AS confidence_media,
       min(data_recebimento) AS primeiro_documento,
       max(data_recebimento) AS ultimo_documento
FROM n8n_athie_schema.documentos d
GROUP BY tipo_documento, status
ORDER BY tipo_documento, status;

alter table dashboard_documentos
    owner to n8nathie;

create function update_updated_at_column() returns trigger
    language plpgsql
as
$$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$;

alter function update_updated_at_column() owner to n8nathie;

