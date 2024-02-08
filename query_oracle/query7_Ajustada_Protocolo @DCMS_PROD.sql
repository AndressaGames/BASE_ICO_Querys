--etapa de revisao
SELECT
    (
        CASE
            WHEN query1.vl_revisao > '20000'
                 AND query1.vl_revisao <= '100000' THEN
                'K. Acima de 20.000'
            WHEN query1.vl_revisao >= '10001'
                 AND query1.vl_revisao <= '20000' THEN
                'J. De 10.001 a 20.000'
            WHEN query1.vl_revisao >= '5001'
                 AND query1.vl_revisao <= '10000,99' THEN
                'I. De 5.001 a 10.000'
            WHEN query1.vl_revisao >= '1001'
                 AND query1.vl_revisao <= '5000,99' THEN
                'H. De 1.001 a 5.000'
            WHEN query1.vl_revisao >= '501'
                 AND query1.vl_revisao <= '1000,99' THEN
                'G. De 501 a 1.000'
            WHEN query1.vl_revisao >= '251'
                 AND query1.vl_revisao <= '500,99' THEN
                'F. De 251 a 500'
            WHEN query1.vl_revisao >= '101'
                 AND query1.vl_revisao <= '250,99' THEN
                'E. De 101 a 250'
            WHEN query1.vl_revisao >= '76'
                 AND query1.vl_revisao <= '100,99' THEN
                'D. De 76 a 100'
            WHEN query1.vl_revisao >= '51'
                 AND query1.vl_revisao <= '75,99' THEN
                'C. De 51 a 75'
            WHEN query1.vl_revisao >= '26'
                 AND query1.vl_revisao <= '50,99' THEN
                'B. De 26 a 50'
            WHEN query1.vl_revisao >= '0,01'
                 AND query1.vl_revisao <= '25,99' THEN
                'A. De 1 a 25'
            WHEN query1.vl_revisao = '0' THEN
                'L. Zeradas'
            WHEN query1.vl_revisao IS NULL THEN
                'L. Zeradas'
            WHEN query1.vl_revisao < '-20000'
                 AND query1.vl_revisao >= '-100000' THEN
                'K. Acima de 20.000'
            WHEN query1.vl_revisao <= '-10001'
                 AND query1.vl_revisao >= '-20000' THEN
                'J. De 10.001 a 20.000'
            WHEN query1.vl_revisao <= '-5001'
                 AND query1.vl_revisao >= '-10000,99' THEN
                'I. De 5.001 a 10.000'
            WHEN query1.vl_revisao <= '-1001'
                 AND query1.vl_revisao >= '-5000,99' THEN
                'H. De 1.001 a 5.000'
            WHEN query1.vl_revisao <= '-501'
                 AND query1.vl_revisao >= '-1000,99' THEN
                'G. De 501 a 1.000'
            WHEN query1.vl_revisao <= '-251'
                 AND query1.vl_revisao >= '-500,99' THEN
                'F. De 251 a 500'
            WHEN query1.vl_revisao <= '-101'
                 AND query1.vl_revisao >= '-250,99' THEN
                'E. De 101 a 250'
            WHEN query1.vl_revisao <= '-76'
                 AND query1.vl_revisao >= '-100,99' THEN
                'D. De 76 a 100'
            WHEN query1.vl_revisao <= '-51'
                 AND query1.vl_revisao >= '-75,99' THEN
                'C. De 51 a 75'
            WHEN query1.vl_revisao <= '-26'
                 AND query1.vl_revisao >= '-50,99' THEN
                'B. De 26 a 50'
            WHEN query1.vl_revisao <= '-0,01'
                 AND query1.vl_revisao >= '-25,99' THEN
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
           'Sem protocolo')   
    query1.id_lote,                                                 "Protocolo",
    query1.ds_especialidade,
    admprod.fu_nm_espec(fnia_fic_calc_esp_ficha@DCMS_PROD(query1.nr_ficha))              esp_da_func,
    query1.qtde_ficha,
    query1.vl_repasse,
    query1.vl_revisao,
    query1.vl_glosa,
    query1.class_zeradas,
    query1.id_post,

    query1.tipo_revisao,
    query1.clidec,
    query1.id_repasse,
    query1.cd_estrategico,
    query1.cd_cir_dentista,
    query1.qtde_eventos,
    query_senhas.data_liberacao,
    admprod.pkia_cir_cons_dentista.fnia_cir_data_ativo@DCMS_PROD(query1.cd_cir_dentista) "DATA_ATIVACAO",
    query1.nm_unidade "NM_UNIDADE"
FROM
    (
        SELECT
            to_char(evf.dt_acao, 'dd/mm/YYYY')    repasse,
            to_char(rf.dt_postagem, 'dd/mm/YYYY') postagem,
            to_char(p.dt_pagamento, 'dd/mm/YYYY') pagamento,
            cd.cd_cir_dentista,
            cd.nm_cir_dentista,
            cd.nm_cidade,
            cd.sg_uf,
            cd.nr_cgccpf,
            cd.nm_unidade,
            f.nr_ficha,
            f.nr_senha,
            evf.id_lote_pagamento,
            d.ds_especialidade,
            f.cd_etapa_atual,
            f.cd_associado,
            f.cd_empresa,
            SUM(evf.qt_realizada)                 qtde_eventos,
            COUNT(DISTINCT(f.nr_ficha))           qtde_ficha,
            round(SUM(decode(id_tipo_acao, '', vl_evento, 0)),
                  2)                              vl_repasse,
            round(SUM(decode(id_tipo_rev_repasse,
                             'E',
                             fu_calculo_evento_rev_lsa@DCMS_PROD(evf.nr_ficha, evf.cd_evento, evf.cd_face, evf.cd_localizacao, evf.nr_perc_pagto
                             ,
                                                       evf.nr_seq_inclusao) * - 1,
                             'P',
                             fu_calculo_evento_rev_lsa@DCMS_PROD(evf.nr_ficha, evf.cd_evento, evf.cd_face, evf.cd_localizacao, evf.nr_perc_pagto
                             ,
                                                       evf.nr_seq_inclusao) * 1,
                             (0))),
                  2)                              vl_revisao,
            round(SUM(decode(id_tipo_acao, 'G', vl_evento, 0)),
                  2)                              vl_glosa,
            (
                CASE
                    WHEN evf.cd_evento = '00.099.999' THEN
                        'Codigo_invalido'
                    WHEN f.cd_tipo_atendimento = 7    THEN
                        'Ficha_Inicial_orto'
                    WHEN evf.id_coberto = 'N'         THEN
                        'Evento_Nao_Coberto'
                    ELSE
                        'Fichas_tradicionais'
                END
            )                                     class_zeradas,
            (
                CASE
                    WHEN evf.id_lote_pagamento IS NOT NULL THEN
                        'Com_lote'
                    ELSE
                        'Sem_lote'
                END
            )                                     id_lote,
            (
                CASE
                    WHEN rf.dt_postagem >= '11-jun-2023'
                         AND rf.dt_postagem < '10-jul-2023' THEN
                        'Dentro_dt_postagem'
                    ELSE
                        'Fora_dt_postagem'
                END
            )                                     id_post,
            (
                CASE
                    WHEN evf.id_tipo_rev_repasse = 'P' THEN
                        'Revisao_Procede'
                    WHEN evf.id_tipo_rev_repasse = 'E' THEN
                        'Revisao_Estorno'
                    ELSE
                        'Revisao_Nao_procede'
                END
            )                                     tipo_revisao,
            (
                CASE
                    WHEN cd.nm_unidade LIKE '%UNIDADE%' THEN
                        'Com_Clidec'
                    ELSE
                        'Sem_Clidec'
                END
            )                                     clidec,
            (
                CASE
                    WHEN evf.id_tipo_acao = 'R' THEN
                        'Revisoes'
                    ELSE
                        'Consolidacao'
                END
            )                                     id_repasse,
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
            )                                     cd_estrategico
        FROM
            tbod_ficha@DCMS_PROD               f,
            tbod_evento_ficha@DCMS_PROD        evf,
            tbod_fich_lote_pagamento@DCMS_PROD p,
            vwod_cir_dentista_todos@DCMS_PROD  cd,
            tbod_especialidade@DCMS_PROD       d,
            tbod_recepcao_ficha@DCMS_PROD      rf,
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
                  --  AND o.ds_ocorrencia = m.ds_motivo_ocorr
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
                f.nr_ficha = evf.nr_ficha (+)
            AND evf.id_lote_pagamento = p.id_lote_pagamento (+)
            AND cd.nr_cgccpf = cor.nr_cgccpf (+)
            AND cd.cd_cir_dentista = cor.cd_cir_dentista (+)
            AND cd.cd_cir_dentista = f.cd_cir_dentista
            AND cd.cd_cir_dentista NOT IN ('ODPV01','MOGI01','MOGI02')
            AND cd.cd_marca NOT IN (28)
            AND f.nr_ficha = rf.nr_ficha (+)
            AND evf.dt_acao >= TO_DATE('28/06/2023 16:00:00', 'DD/MM/YYYY HH24:MI:SS')
            AND evf.dt_acao < TO_DATE('31/07/2023 23:59:59', 'DD/MM/YYYY HH24:MI:SS')
            AND evf.id_tipo_acao = 'R'
           AND f.NR_FICHA IN (188201802,157238828,156586850,157647941)
            AND f.cd_especialidade = d.cd_especialidade
        GROUP BY
            to_char(evf.dt_acao, 'dd/mm/YYYY'),
            to_char(rf.dt_postagem, 'dd/mm/YYYY'),
            to_char(p.dt_pagamento, 'dd/mm/YYYY'),
            cd.cd_cir_dentista,
            cd.nm_cir_dentista,
            cd.nm_cidade,
            cd.sg_uf,
            cd.nr_cgccpf,
            cd.nm_unidade,
            f.nr_ficha,
            f.nr_senha,
            evf.id_lote_pagamento,
            d.ds_especialidade,
            f.cd_etapa_atual,
            f.cd_associado,
            f.cd_empresa,
            (
                CASE
                    WHEN evf.cd_evento = '00.099.999' THEN
                        'Codigo_invalido'
                    WHEN f.cd_tipo_atendimento = 7    THEN
                        'Ficha_Inicial_orto'
                    WHEN evf.id_coberto = 'N'         THEN
                        'Evento_Nao_Coberto'
                    ELSE
                        'Fichas_tradicionais'
                END
            ),
            (
                CASE
                    WHEN evf.id_lote_pagamento IS NOT NULL THEN
                        'Com_lote'
                    ELSE
                        'Sem_lote'
                END
            ),
            (
                CASE
                    WHEN rf.dt_postagem >= '11-jun-2023'
                         AND rf.dt_postagem < '10-jul-2023' THEN
                        'Dentro_dt_postagem'
                    ELSE
                        'Fora_dt_postagem'
                END
            ),
            (
                CASE
                    WHEN evf.id_tipo_rev_repasse = 'P' THEN
                        'Revisao_Procede'
                    WHEN evf.id_tipo_rev_repasse = 'E' THEN
                        'Revisao_Estorno'
                    ELSE
                        'Revisao_Nao_procede'
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
                    WHEN evf.id_tipo_acao = 'R' THEN
                        'Revisoes'
                    ELSE
                        'Consolidacao'
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