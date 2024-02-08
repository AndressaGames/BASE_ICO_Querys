SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROC [JORNADA].[PRDM_BASE_ICO_PENDENTE_PAGAMENTO] AS
BEGIN

TRUNCATE TABLE [JORNADA].[BASE_ICO_PENDENTE_PAGAMENTO];

DECLARE @DATA_INICIO AS [DATE] = DATEADD(month, DATEDIFF(month, 0,DATEADD(month, -1,  GETDATE())), 0); 
DECLARE @DATA_FIM AS [DATE] =  FORMAT(DATEADD(day, -1, GETDATE()),'yyyyMMdd');

with ocorrencia as (
                SELECT
                    cd.cd_cir_dentista,
                    cd.nm_cir_dentista,
                    cd.sg_uf,
                    cd.nm_cidade,
                    cd.nr_cgccpf,
                    m.ds_motivo_ocorr,
                    s.id_sit_especial,
                    s.dt_sit_especial,
                    p.ds_tipo_ocorr,
                    cd.cd_usuario_consultor
                 --   COUNT(*)
                FROM
                    DCMS.ADMPROD_tbod_hist_sit_especial         s
                inner join DCMS.vwod_cir_dentista_credenciados cd on (s.nr_cgccpf = cd.nr_cgccpf)
                inner join DCMS.ADMPROD_tbod_ocorrencia o on (s.nr_ocorrencia = o.nr_ocorrencia)
                inner join  DCMS.ADMPROD_tbod_motivo_ocorr m on (
                    o.cd_tipo_ocorr = m.cd_tipo_ocorr and
                    o.cd_motivo_ocorr = m.cd_motivo_ocorr)
                inner join  DCMS.ADMPROD_tbod_tipo_ocorr p on (
                        o.cd_tipo_ocorr = p.cd_tipo_ocorr and 
                        p.cd_tipo_ocorr = m.cd_tipo_ocorr)
                WHERE
                        s.dt_sit_especial = (
                            SELECT
                                MAX(s1.dt_sit_especial)
                            FROM
                                dcms.admprod_tbod_hist_sit_especial s1
                            WHERE
                                s1.nr_cgccpf = s.nr_cgccpf
                        )
                    AND s.id_sit_especial = 'S'            
                GROUP BY
                    cd.cd_cir_dentista,
                    cd.nm_cir_dentista,
                    cd.sg_uf,
                    cd.nm_cidade,
                    m.ds_motivo_ocorr,
                    s.id_sit_especial,
                    s.dt_sit_especial,
                    p.ds_tipo_ocorr,
                    cd.nr_cgccpf,
                    cd.cd_usuario_consultor
                --ORDER BY
               --  3
            )                       
--select * from ocorrencia

,QUERY6  as  (SELECT
            --format(dtc.dt_postagem, 'dd/MM/yyyy')   postagem,
            --format(a.dt_realiz_etapa, 'dd/MM/yyyy') repasse,
            --format(pg.dt_pagamento, 'dd/MM/YYYY')   pagamento,
            dtc.dt_postagem   postagem,
            a.dt_realiz_etapa repasse,
            pg.dt_pagamento   pagamento,
            a.nr_ficha,
            a.nr_senha,
            d.ds_especialidade,
            cd.nm_unidade,
            cd.cd_unidade,
            cd.cd_cir_dentista,
            c.id_lote,
            SUM(c.qt_realizada)                      qtde_eventos,
            COUNT(DISTINCT(a.nr_ficha))              qtde_ficha,
            ROUND(SUM ( CASE c.ID_TIPO_REV_REPASSE
                                WHEN 'E' THEN COALESCE((AUX.VL_EVENTO * (c.NR_PERC_PAGTO / 100)), 0) * -1
                                WHEN 'P' THEN COALESCE((AUX.VL_EVENTO * (c.NR_PERC_PAGTO / 100)), 0) *  1
                                ELSE COALESCE((AUX.VL_EVENTO * (c .NR_PERC_PAGTO / 100)), 0)
                            END
                        ), 2)             AS VL_REPASSE,
            ROUND(SUM ( CASE c.ID_TIPO_REV_REPASSE
                             WHEN 'E' THEN COALESCE((c.VL_EVENTO * (c.NR_PERC_PAGTO / 100)), 0) * -1
                             WHEN 'P' THEN COALESCE((c.VL_EVENTO * (c.NR_PERC_PAGTO / 100)), 0) *  1
                        ELSE 0
                         END
                        ), 2)             AS VL_REVISAO,            
            round(SUM(CASE C.id_tipo_acao WHEN 'G'
                        THEN C.vl_evento ELSE 0 END),
                  2)                    AS          vl_glosa,
            (
                CASE
                    WHEN c.cd_evento = '00.099.999' THEN
                        'Codigo_invalido'
                    WHEN a.cd_tipo_atendimento = 7  THEN
                        'Ficha_Inicial_orto'
                    WHEN c.id_coberto = 'N'         THEN
                        'Evento_Nao_Coberto'
                    ELSE
                        'Fichas_tradicionais'
                END
            )                                        class_zeradas,
            (
                CASE
                    WHEN c.id_lote IS NOT NULL THEN
                        'Com_lote'
                    ELSE
                        'Sem_lote'
                END
            )                                        id_lote_pagto,
            (
                CASE
                    WHEN dtc.dt_postagem >= @DATA_INICIO
                         AND dtc.dt_postagem < @DATA_FIM THEN
                        'Dentro_dt_postagem'
                    ELSE
                        'Fora_dt_postagem'
                END
            )                                        id_post,
            (
                CASE
                    WHEN c.id_tipo_rev_repasse = 'P' THEN
                        'Procede'
                    WHEN c.id_tipo_rev_repasse = 'E' THEN
                        'Estorno'
                    ELSE
                        'Etapa3'
                END
            )                                        tipo_revisao,
            (
                CASE
                    WHEN cd.nm_unidade LIKE '%UNIDADE%' THEN
                        'Com_Clidec'
                    ELSE
                        'Sem_Clidec'
                END
            )                                        clidec,
            (
                CASE
                    WHEN c.id_tipo_acao = 'R' THEN
                        'Revisao'
                    ELSE
                        'GTOaS_Pendentes'
                END
            )                                        tipo_ficha,
            (
                CASE
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geográfico - Nível 1'   THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nível 1'    THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clínico - Nível 1'      THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clínico - Nível 3'      THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nível 3'    THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geográfico - Nível 3'   THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Inclusão Manual - Nível 3'     THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Análise Estatística - Nível 3' THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nível 2'    THEN
                        'E2'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geográfico - Nível 2'   THEN
                        'E2'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clínico - Nível 2'      THEN
                        'E2'
                    ELSE
                        'Nao_estratégico'
                END
            )                                        cd_estrategico 
        FROM
            DCMS.ADMPROD_tbod_ficha               a
        INNER JOIN DCMS.ADMPROD_tbod_evento_ficha c   
                    ON (a.nr_ficha = c.nr_ficha
                    AND C.NR_SEQ_EVENTO < 500)
        INNER JOIN [DCMS].[ADMPROD_TBOD_EVENTO_FICHA] AS AUX 
                    ON (AUX.NR_FICHA = a.NR_FICHA
                    AND AUX.CD_EVENTO = c.CD_EVENTO
                    AND AUX.CD_FACE = c.CD_FACE
                    AND  AUX.CD_LOCALIZACAO = c.CD_LOCALIZACAO
                    AND  AUX.NR_SEQ_INCLUSAO = c.NR_SEQ_INCLUSAO
                    AND  AUX.NR_SEQ_EVENTO = 1
        )
        INNER JOIN DCMS.ADMPROD_tbod_especialidade d
                    ON (a.cd_especialidade = d.cd_especialidade)
        INNER JOIN  DCMS.ADMPROD_tbod_recepcao_ficha      dtc 
                    ON (a.nr_ficha = dtc.nr_ficha)
        INNER JOIN DCMS.vwod_cir_dentista_todos  cd
                    ON (a.cd_cir_dentista = cd.cd_cir_dentista)
        LEFT JOIN DCMS.ADMPROD_tbod_fich_lote_pagamento pg
                 ON (c.id_lote = pg.id_lote_pagamento)
        LEFT JOIN ocorrencia cor
                on (cd.nr_cgccpf = cor.nr_cgccpf --(+)
                AND cd.cd_cir_dentista = cor.cd_cir_dentista --(+)
                )
        WHERE
            a.cd_etapa_atual IN ( '3', '4' )
            AND a.id_ficha_reembolso = 'N'
            AND dtc.dt_postagem >= @DATA_INICIO
            AND dtc.dt_postagem < @DATA_FIM
            AND cd.cd_cir_dentista NOT IN ('ODPV01','MOGI01','MOGI02')
            AND cd.cd_marca NOT IN (28)
            AND c.nr_seq_evento = 1
            AND a.nr_ficha NOT IN (
                SELECT
                    nr_ficha
                FROM
                    dcms.admprod_tbod_ficha_cancelada_pre
            )
            AND a.nr_ficha NOT IN (
                SELECT
                    nr_ficha
                FROM
                    dcms.admprod_tbod_ficha_lote
            )
           -- AND A.NR_FICHA in (156746086)
        GROUP BY
            --format(dtc.dt_postagem, 'dd/MM/yyyy') ,
            --format(a.dt_realiz_etapa, 'dd/MM/yyyy'),
            --format(pg.dt_pagamento, 'dd/MM/YYYY'),
            dtc.dt_postagem   ,
            a.dt_realiz_etapa ,
            pg.dt_pagamento   ,
            a.nr_ficha,
            a.nr_senha,
            cd.nm_unidade,
            cd.cd_unidade,
            d.ds_especialidade,
            cd.cd_cir_dentista,
            c.id_lote,
            (
                CASE
                    WHEN c.cd_evento = '00.099.999' THEN
                        'Codigo_invalido'
                    WHEN a.cd_tipo_atendimento = 7  THEN
                        'Ficha_Inicial_orto'
                    WHEN c.id_coberto = 'N'         THEN
                        'Evento_Nao_Coberto'
                    ELSE
                        'Fichas_tradicionais'
                END
            ),
            (
                CASE
                    WHEN c.id_lote IS NOT NULL THEN
                        'Com_lote'
                    ELSE
                        'Sem_lote'
                END
            ),
            (
                CASE
                    WHEN dtc.dt_postagem >= @DATA_INICIO
                    AND dtc.dt_postagem < @DATA_FIM THEN
                        'Dentro_dt_postagem'
                    ELSE
                        'Fora_dt_postagem'
                END
            ),
            (
                CASE
                    WHEN c.id_tipo_rev_repasse = 'P' THEN
                        'Procede'
                    WHEN c.id_tipo_rev_repasse = 'E' THEN
                        'Estorno'
                    ELSE
                        'Etapa3'
                END
            ),
            (
                CASE
                    WHEN cd.nm_unidade LIKE '%UNIDADE%' THEN
                        'Com_Clidec'
                    ELSE
                        'Sem_Clidec'
                END
            ),
            (
                CASE
                    WHEN c.id_tipo_acao = 'R' THEN
                        'Revisao'
                    ELSE
                        'GTOaS_Pendentes'
                END
            ),
            (
                CASE
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geográfico - Nível 1'   THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nível 1'    THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clínico - Nível 1'      THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clínico - Nível 3'      THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nível 3'    THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geográfico - Nível 3'   THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Inclusão Manual - Nível 3'     THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Análise Estatística - Nível 3' THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nível 2'    THEN
                        'E2'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geográfico - Nível 2'   THEN
                        'E2'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clínico - Nível 2'      THEN
                        'E2'
                    ELSE
                        'Nao_estratégico'
                END
            )
    )                         --  query1

  --  select top(10) * from QUERY6



INSERT INTO [JORNADA].[BASE_ICO_PENDENTE_PAGAMENTO]
 SELECT 
    CASE
        WHEN query1.vl_repasse > 20000 THEN 'K. Acima de 20.000'
        WHEN query1.vl_repasse BETWEEN 10001 AND 20000 THEN 'J. De 10.001 a 20.000'
        WHEN query1.vl_repasse BETWEEN 5001 AND 10000.99 THEN 'I. De 5.001 a 10.000'
        WHEN query1.vl_repasse BETWEEN 1001 AND 5000.99 THEN 'H. De 1.001 a 5.000'
        WHEN query1.vl_repasse BETWEEN 501 AND 1000.99 THEN 'G. De 501 a 1.000'
        WHEN query1.vl_repasse BETWEEN 251 AND 500.99 THEN 'F. De 251 a 500'
        WHEN query1.vl_repasse BETWEEN 101 AND 250.99 THEN 'E. De 101 a 250'
        WHEN query1.vl_repasse BETWEEN 76 AND 100.99 THEN 'D. De 76 a 100'
        WHEN query1.vl_repasse BETWEEN 51 AND 75.99 THEN 'C. De 51 a 75'
        WHEN query1.vl_repasse BETWEEN 26 AND 50.99 THEN 'B. De 26 a 50'
        WHEN query1.vl_repasse BETWEEN 0.01 AND 25.99 THEN 'A. De 1 a 25'
        WHEN query1.vl_repasse = 0 THEN 'L. Zeradas'
        WHEN query1.vl_repasse IS NULL THEN 'L. Zeradas'
        WHEN query1.vl_repasse < -20000 THEN 'K. Acima de 20.000'
        WHEN query1.vl_repasse BETWEEN -10001 AND -20000 THEN 'J. De 10.001 a 20.000'
        WHEN query1.vl_repasse BETWEEN -5001 AND -10000.99 THEN 'I. De 5.001 a 10.000'
        WHEN query1.vl_repasse BETWEEN -1001 AND -5000.99 THEN 'H. De 1.001 a 5.000'
        WHEN query1.vl_repasse BETWEEN -501 AND -1000.99 THEN 'G. De 501 a 1.000'
        WHEN query1.vl_repasse BETWEEN -251 AND -500.99 THEN 'F. De 251 a 500'
        WHEN query1.vl_repasse BETWEEN -101 AND -250.99 THEN 'E. De 101 a 250'
        WHEN query1.vl_repasse BETWEEN -76 AND -100.99 THEN 'D. De 76 a 100'
        WHEN query1.vl_repasse BETWEEN -51 AND -75.99 THEN 'C. De 51 a 75'
        WHEN query1.vl_repasse BETWEEN -26 AND -50.99 THEN 'B. De 26 a 50'
        WHEN query1.vl_repasse BETWEEN -0.01 AND -25.99 THEN 'A. De 1 a 25'
        ELSE 'VERIFICAR'
    END AS escala,
       query1.pagamento,
        query1.postagem,
        query1.repasse,
        query1.nr_ficha,
    CASE UPPER(SUBSTRING(TRIM(query1.NR_SENHA), (LEN(TRIM(query1.NR_SENHA)) -3), 4))
                WHEN 'ALFA' THEN 'ALFA'
                WHEN 'BETA' THEN 'BETA'
                WHEN 'GAMA' THEN 'GAMA'
                WHEN 'ZETA' THEN 'ZETA'
                ELSE 'SEM PROTOCOLO'
    END   AS PROTOCOLO,
            query1.id_lote,
        query1.ds_especialidade,
        DS_ESP.DS_ESPECIALIDADE AS esp_da_func,
        query1.qtde_ficha,
        query1.vl_repasse,
        query1.vl_revisao,
        query1.vl_glosa,
        query1.class_zeradas,
        query1.id_post,
        query1.id_lote_pagto,
        query1.tipo_revisao,
        query1.clidec,
        query1.tipo_ficha,
        query1.cd_estrategico,
        query1.cd_cir_dentista,
        query1.qtde_eventos,
        query_senhas.data_liberacao,
        DT_ATIV.V_DATA_ATIVACAO_FINAL AS  DATA_ATIVACAO,
        query1.NM_UNIDADE NM_UNIDADE
FROM QUERY6 AS query1
    LEFT JOIN (
        SELECT
            et.nr_ficha,
            et.dt_realiz_etapa data_liberacao
        FROM
            DCMS.ADMPROD_tbod_etapa_ficha et
        WHERE
            et.cd_etapa = 1
    )                           query_senhas ON query1.nr_ficha = query_senhas.nr_ficha
    OUTER APPLY [JORNADA].[FNIA_FIC_CALC_ESP_FICHA]  (query1.NR_FICHA, query1.CD_UNIDADE) AS DS_ESP
    LEFT JOIN DCMS.tbia_fic_itens_detalhamento esp_calc ON query1.nr_ficha = esp_calc.nr_ficha
    OUTER APPLY [JORNADA].[FNIA_CIR_DATA_ATIVO]  (query1.CD_CIR_DENTISTA) AS DT_ATIV


END
GO