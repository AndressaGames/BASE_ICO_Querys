-- pendente etapa 5 - pendente de pagamento 
SELECT
    (
        CASE
            WHEN query1.vl_repasse > '20000'
                 AND query1.vl_repasse <= '100000' THEN
                'K. Acima de 20.000'
            WHEN query1.vl_repasse >= '10001'
                 AND query1.vl_repasse <= '20000' THEN
                'J. De 10.001 a 20.000'
            WHEN query1.vl_repasse >= '5001'
                 AND query1.vl_repasse <= '10000,99' THEN
                'I. De 5.001 a 10.000'
            WHEN query1.vl_repasse >= '1001'
                 AND query1.vl_repasse <= '5000,99' THEN
                'H. De 1.001 a 5.000'
            WHEN query1.vl_repasse >= '501'
                 AND query1.vl_repasse <= '1000,99' THEN
                'G. De 501 a 1.000'
            WHEN query1.vl_repasse >= '251'
                 AND query1.vl_repasse <= '500,99' THEN
                'F. De 251 a 500'
            WHEN query1.vl_repasse >= '101'
                 AND query1.vl_repasse <= '250,99' THEN
                'E. De 101 a 250'
            WHEN query1.vl_repasse >= '76'
                 AND query1.vl_repasse <= '100,99' THEN
                'D. De 76 a 100'
            WHEN query1.vl_repasse >= '51'
                 AND query1.vl_repasse <= '75,99' THEN
                'C. De 51 a 75'
            WHEN query1.vl_repasse >= '26'
                 AND query1.vl_repasse <= '50,99' THEN
                'B. De 26 a 50'
            WHEN query1.vl_repasse >= '0,01'
                 AND query1.vl_repasse <= '25,99' THEN
                'A. De 1 a 25'
            WHEN query1.vl_repasse = '0' THEN
                'L. Zeradas'
            WHEN query1.vl_repasse IS NULL THEN
                'L. Zeradas'
            WHEN query1.vl_repasse < '-20000'
                 AND query1.vl_repasse >= '-100000' THEN
                'K. Acima de 20.000'
            WHEN query1.vl_repasse <= '-10001'
                 AND query1.vl_repasse >= '-20000' THEN
                'J. De 10.001 a 20.000'
            WHEN query1.vl_repasse <= '-5001'
                 AND query1.vl_repasse >= '-10000,99' THEN
                'I. De 5.001 a 10.000'
            WHEN query1.vl_repasse <= '-1001'
                 AND query1.vl_repasse >= '-5000,99' THEN
                'H. De 1.001 a 5.000'
            WHEN query1.vl_repasse <= '-501'
                 AND query1.vl_repasse >= '-1000,99' THEN
                'G. De 501 a 1.000'
            WHEN query1.vl_repasse <= '-251'
                 AND query1.vl_repasse >= '-500,99' THEN
                'F. De 251 a 500'
            WHEN query1.vl_repasse <= '-101'
                 AND query1.vl_repasse >= '-250,99' THEN
                'E. De 101 a 250'
            WHEN query1.vl_repasse <= '-76'
                 AND query1.vl_repasse >= '-100,99' THEN
                'D. De 76 a 100'
            WHEN query1.vl_repasse <= '-51'
                 AND query1.vl_repasse >= '-75,99' THEN
                'C. De 51 a 75'
            WHEN query1.vl_repasse <= '-26'
                 AND query1.vl_repasse >= '-50,99' THEN
                'B. De 26 a 50'
            WHEN query1.vl_repasse <= '-0,01'
                 AND query1.vl_repasse >= '-25,99' THEN
                'A. De 1 a 25'
            ELSE
                'VERIFICAR'
        END
    )                                                                          escala,
    query1.pagamento,
    query1.postagem,
    query1.repasse,
    query1.nr_ficha,
    decode(upper(substr(TRIM(query1.nr_senha),
                        (length(TRIM(query1.nr_senha)) - 3),
                        4)),
           substr(query1.nr_senha, 8, 4),
           '',
           'ALFA',
           'ALFA',
           'BETA',
           'BETA',
           'GAMA',
           'GAMA',
           'ZETA',
           'ZETA',
           'Sem protocolo')                                                    "Protocolo",
    query1.id_lote,
    query1.ds_especialidade,
    admprod.fu_nm_espec(fnia_fic_calc_esp_ficha@DCMS_PROD(query1.nr_ficha))              esp_da_func,
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
    admprod.pkia_cir_cons_dentista.fnia_cir_data_ativo@DCMS_PROD(query1.cd_cir_dentista) "DATA_ATIVACAO",
    query1.NM_UNIDADE "NM_UNIDADE"
FROM
    (
        SELECT
            to_char(dtc.dt_postagem, 'dd/mm/yyyy')   postagem,
            to_char(a.dt_realiz_etapa, 'dd/mm/yyyy') repasse,
            to_char(pg.dt_pagamento, 'dd/mm/YYYY')   pagamento,
            a.nr_ficha,
            a.nr_senha,
            d.ds_especialidade,
            cd.nm_unidade,
            cd.cd_cir_dentista,
            c.id_lote,
            SUM(c.qt_realizada)                      qtde_eventos,
            COUNT(DISTINCT(a.nr_ficha))              qtde_ficha,
            round(SUM(decode(id_tipo_rev_repasse,
                             'E',
                             fu_calculo_evento_rev@DCMS_PROD(c.nr_ficha, c.cd_evento, c.cd_face, c.cd_localizacao, c.nr_perc_pagto) * - 1,
                             'P',
                             fu_calculo_evento_rev@DCMS_PROD(c.nr_ficha, c.cd_evento, c.cd_face, c.cd_localizacao, c.nr_perc_pagto) * 1,
                             ((vl_evento *(nr_perc_pagto / 100))))),
                  2)                                 vl_repasse,
            round(SUM(decode(id_tipo_rev_repasse,
                             'E',
                             fu_calculo_evento_rev_lsa@DCMS_PROD(c.nr_ficha, c.cd_evento, c.cd_face, c.cd_localizacao, c.nr_perc_pagto,
                                                       c.nr_seq_inclusao) * - 1,
                             'P',
                             fu_calculo_evento_rev_lsa@DCMS_PROD(c.nr_ficha, c.cd_evento, c.cd_face, c.cd_localizacao, c.nr_perc_pagto,
                                                       c.nr_seq_inclusao) * 1,
                             (0))),
                  2)                                 vl_revisao,
            round(SUM(decode(id_tipo_acao, 'G', vl_evento, 0)),
                  2)                                 vl_glosa,
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
                    WHEN dtc.dt_postagem >= '01-jun-2023'
                         AND dtc.dt_postagem < '01-jul-2023' THEN
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
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geografico - Nivel 1'   THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nivel 1'    THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clinico - Nivel 1'      THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clinico - Nivel 3'      THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nivel 3'    THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geografico - Nivel 3'   THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Inclusao Manual - Nivel 3'     THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Analise Estatistica - Nivel 3' THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nivel 2'    THEN
                        'E2'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geografico - Nivel 2'   THEN
                        'E2'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clinico - Nivel 2'      THEN
                        'E2'
                    ELSE
                        'Nao_estrategico'
                END
            )                                        cd_estrategico
        FROM
            tbod_ficha@DCMS_PROD               a,
            tbod_evento_ficha@DCMS_PROD        c,
            tbod_especialidade@DCMS_PROD       d,
            tbod_recepcao_ficha@DCMS_PROD      dtc,
            vwod_cir_dentista_todos@DCMS_PROD  cd,
            tbod_fich_lote_pagamento@DCMS_PROD pg,
            (
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
                    cd.cd_usuario_consultor,
                    COUNT(*)
                FROM
                    tbod_hist_sit_especial@DCMS_PROD         s,
                    vwod_cir_dentista_credenciados@DCMS_PROD cd,
                    tbod_ocorrencia@DCMS_PROD                o,
                    tbod_motivo_ocorr@DCMS_PROD              m,
                    tbod_tipo_ocorr@DCMS_PROD                p
                WHERE
                        s.dt_sit_especial = (
                            SELECT
                                MAX(s1.dt_sit_especial)
                            FROM
                                tbod_hist_sit_especial@DCMS_PROD s1
                            WHERE
                                s1.nr_cgccpf = s.nr_cgccpf
                        )
                    AND s.id_sit_especial = 'S'
                    AND s.nr_cgccpf = cd.nr_cgccpf
                    AND s.nr_ocorrencia = o.nr_ocorrencia
                    AND o.cd_tipo_ocorr = m.cd_tipo_ocorr
                    AND o.cd_motivo_ocorr = m.cd_motivo_ocorr
                    AND o.cd_tipo_ocorr = p.cd_tipo_ocorr
                    AND p.cd_tipo_ocorr = m.cd_tipo_ocorr
                   -- AND o.ds_ocorrencia = m.ds_motivo_ocorr
                GROUP BY
                    cd.cd_cir_dentista,
                    cd.nm_cir_dentista,
                    cd.sg_uf,
                    cd.nm_cidade,
                    m.ds_motivo_ocorr,
                    --o.dt_ocorrencia,
                    s.id_sit_especial,
                    s.dt_sit_especial,
                    p.ds_tipo_ocorr,
                    cd.nr_cgccpf,
                    cd.cd_usuario_consultor
                ORDER BY
                    3
            )                        cor
        WHERE
            a.cd_etapa_atual IN ( '3', '4' )
            AND a.id_ficha_reembolso = 'N'
            AND dtc.dt_postagem >= TO_DATE('01/06/2023 00:00:00', 'dd/mm/yyyy HH24:mi:ss')
            AND dtc.dt_postagem < TO_DATE('30/06/2023 23:59:59', 'dd/mm/yyyy HH24:mi:ss')
            AND a.nr_ficha = c.nr_ficha
            AND cd.nr_cgccpf = cor.nr_cgccpf (+)
            AND cd.cd_cir_dentista = cor.cd_cir_dentista (+)
            AND a.cd_cir_dentista = cd.cd_cir_dentista
            AND cd.cd_cir_dentista NOT IN ('ODPV01','MOGI01','MOGI02')
            AND cd.cd_marca NOT IN (28)
            AND a.nr_ficha = dtc.nr_ficha
            AND c.id_lote = pg.id_lote_pagamento (+)
            AND a.cd_especialidade = d.cd_especialidade
            AND c.nr_seq_evento = 1
--and a.nr_ficha not in (select nr_ficha from tbod_ficha_dtcorte )
            AND a.nr_ficha NOT IN (
                SELECT
                    nr_ficha
                FROM
                    tbod_ficha_cancelada_pre@DCMS_PROD
            )
            AND a.nr_ficha NOT IN (
                SELECT
                    nr_ficha
                FROM
                    tbod_ficha_lote@DCMS_PROD
            )
           AND A.NR_FICHA IN (188201802,157238828,156586850,157647941)
        GROUP BY
            to_char(dtc.dt_postagem, 'dd/mm/yyyy'),
            to_char(a.dt_realiz_etapa, 'dd/mm/yyyy'),
            to_char(pg.dt_pagamento, 'dd/mm/YYYY'),
            a.nr_ficha,
            a.nr_senha,
            cd.nm_unidade,
            d.ds_especialidade,
            cd.cd_cir_dentista,
            c.id_lote,
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
                    WHEN dtc.dt_postagem >= '01-jun-2023'
                         AND dtc.dt_postagem < '01-jul-2023' THEN
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
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geografico - Nivel 1'   THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nivel 1'    THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clinico - Nivel 1'      THEN
                        'E1'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clinico - Nivel 3'      THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nivel 3'    THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geografico - Nivel 3'   THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Inclusao Manual - Nivel 3'     THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Analise Estatistica - Nivel 3' THEN
                        'E3'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Comercial - Nivel 2'    THEN
                        'E2'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Geografico - Nivel 2'   THEN
                        'E2'
                    WHEN cor.ds_motivo_ocorr = 'Motivo Clinico - Nivel 2'      THEN
                        'E2'
                    ELSE
                        'Nao_estrategico'
                END
            )
    )                           query1
    LEFT JOIN (
        SELECT
            et.nr_ficha,
            to_char(et.dt_realiz_etapa, 'dd/mm/YYYY') data_liberacao
        FROM
            tbod_etapa_ficha@DCMS_PROD et
        WHERE
            et.cd_etapa = 1
    )                           query_senhas ON query1.nr_ficha = query_senhas.nr_ficha
    LEFT JOIN tbia_fic_itens_detalhamento@DCMS_PROD esp_calc ON query1.nr_ficha = esp_calc.nr_ficha