/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
********************************************************************************/
{include/i-prgvrs.i RE0402A 2.00.00.103 } /*** "010003" ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0402a MRE}
&ENDIF
 
/******************************************************************************
**
**       Programa: RE0402A
**
**       Objetivo: Desatualizacao de Notas Fiscais 
**
******************************************************************************/
{utp/ut-glob.i}
{cdp/cd0666.i}
{include/i_dbvers.i}
{include/i_dbtype.i}
{method/dbotterr.i} /*** RowErrors ***/
{wmp/wm9033.i}
{cdp/cd1234.i}/* Defini‡Æo da fun‡Æo fn_ajust_dec conforme engenharia "Ajustes de Casas Decimais"*/

/*Integra‡Æo EAI*/
define new global shared variable v_log_eai_habilit as log  no-undo.
DEFINE VARIABLE h-axssu001 AS HANDLE     NO-UNDO.
DEFINE TEMP-TABLE tt_log_erro NO-UNDO
     FIELD ttv_num_cod_erro AS integer INITIAL ?
     FIELD ttv_des_msg_ajuda AS character INITIAL ?
     FIELD ttv_des_msg_erro AS character INITIAL ?.

def input  param rw-docum           as rowid      no-undo.
def input  param l-somente-of       as logical    no-undo.
def input  param l-saldo-neg        as logical    no-undo.
def input  param l-cancela-ft       as logical    no-undo.
def input  param l-custo-padrao     as logical    no-undo.
def input  param l-desatualiza-ap   as logical    no-undo.
def input  param i-prc-custo        as integer    no-undo.
def input  param l-desatualiza-aca  as logical    no-undo.
def input  param l-desatualiza-wms  as logical    no-undo.
def input  param l-desatualiza-draw as logical    no-undo.
def input  param l-desatualiza-cr   as logical    no-undo.
def output param l-erro             as logical    no-undo.
def output param table              for tt-erro.

/*--- EXECUCAO ORCAMENTARIA - Datasul FINANCAS ---*/
&if "{&mgadm_version}" >= "2.04" &then
    {cdp/cd1001.i}  /*--- cria tabelas temporarias tt_xml_input_1 - tt_log_erros ---*/
    {cdp/cd1002.i}  /*--- funcao execucao orcamentaria ---*/

    define var l-erro-conect          as logical            no-undo.
    define var l-banco-conectado-bas  as logical initial NO no-undo.
    define var l-banco-conectado-fin  as logical initial NO no-undo.
    define var l-banco-conectado-uni  as logical initial NO no-undo.
&endif
{include/i-epc200.i "re0402rp"}
{cdp/cdcfgdis.i}
{cdp/cdcfgman.i}
{cdp/cdcfgmat.i}
{cdp/cdcfgcex.i}
{ftp/ft0605.i3}
{ftp/ft2011.i1} /* Defini‡Æo da temp-table tt-ped-item */
{cpp/cpapi009.i} /* Temp-tables com os dados do reporte */
{cnp/cnapi020.i3} /*Temp-Tables e Variaveis BGC*/
DEF TEMP-TABLE tt-erro-aux NO-UNDO LIKE tt-erro .
DEF TEMP-TABLE tt-erro-aux2 NO-UNDO LIKE tt-erro. /*TDMNZ7*/

def temp-table tt-rowid-movto-estoq    no-undo field r-rowid as rowid
    index ch-id is primary r-rowid.

def workfile w-fat-repre
    field nome-ab-rep like fat-repre.nome-ab-rep
    field posicao     as integer.

/* Definicao dos preprocessadores utilizados na include ft0605.i5 ------------*/
&IF DEFINED (bf_dis_versao_ems) &THEN
  &IF '{&bf_dis_versao_ems}' >= '2.06' &THEN
    &GLOBAL-DEFINE ind-calc-pis           it-nota-fisc.idi-forma-calc-pis
    &GLOBAL-DEFINE val-pis-por-unidade    it-nota-fisc.val-unit-pis
    &GLOBAL-DEFINE ind-calc-cofins        it-nota-fisc.idi-forma-calc-cofins
    &GLOBAL-DEFINE val-cofins-por-unidade it-nota-fisc.val-unit-cofins
  &ELSE
    &GLOBAL-DEFINE ind-calc-pis           TRIM(SUBSTRING(it-nota-fisc.char-2,140,1))
    &GLOBAL-DEFINE val-pis-por-unidade    TRIM(SUBSTRING(it-nota-fisc.char-2,141,10))
    &GLOBAL-DEFINE ind-calc-cofins        TRIM(SUBSTRING(it-nota-fisc.char-2,151,1))
    &GLOBAL-DEFINE val-cofins-por-unidade TRIM(SUBSTRING(it-nota-fisc.char-2,152,10))
  &ENDIF  
&else
    &GLOBAL-DEFINE ind-calc-pis           TRIM(SUBSTRING(it-nota-fisc.char-2,140,1))
    &GLOBAL-DEFINE val-pis-por-unidade    TRIM(SUBSTRING(it-nota-fisc.char-2,141,10))
    &GLOBAL-DEFINE ind-calc-cofins        TRIM(SUBSTRING(it-nota-fisc.char-2,151,1))
    &GLOBAL-DEFINE val-cofins-por-unidade TRIM(SUBSTRING(it-nota-fisc.char-2,152,10))
&ENDIF

/*Vari veis utilizadas na include ft0605.i5 */
def NEW shared var i-emitente-cod-gr-cli like emitente.cod-gr-cli.
def NEW shared var i-cod-rep             like repres.cod-rep.
def NEW shared var i-cod-princ           like repres.cod-rep.
def NEW shared var de-tot-aux            like it-nota-fisc.vl-tot-item.
def NEW shared var de-tot-it             like it-nota-fisc.vl-tot-item.
def NEW shared var de-comis              as   decimal  format ">>9.99999999".
def NEW shared var de-comis-emis         as   decimal  format ">>9.99999999".
def NEW shared var de-comis-ind          as   decimal  format ">>9.99999999".
def NEW shared var l-ft0603x             as   logical initial no.
def NEW shared var l-erro-x              as   logical.
def NEW shared var l-principal           as   logical.

/* Definicao dos preprocessadores com as especies de movimentos --------------*/
{cep/ceapi001.i10}
def new global shared var v_log_eai_habilit as log no-undo.
/* procedure pi-desatualiza-custo */
{rep/re0402a.i3}

/*Defini‡äes utilizadas na fun‡Æo lote avan‡ado*/
&if '{&bf_lote_avancado_liberado}' = 'yes' &then
    {cep/ceapi030.i} 
    {cep/ceapi028.i}
    DEFINE VARIABLE h-ceapi028 AS HANDLE NO-UNDO.
    DEFINE VARIABLE h-ceapi030 AS HANDLE NO-UNDO.
    DEFINE VARIABLE p-retorno AS LOGICAL NO-UNDO.
&ENDIF
def buffer b-movto-estoq    for movto-estoq.
def buffer b-docum          for docum-est.
def buffer b-item-doc-est   for item-doc-est.
def buffer b-ped-item       for ped-item.
def buffer b-item-ref       for item.
DEF BUFFER b1-natur-oper    FOR natur-oper.
def buffer bf-nota-fiscal   for nota-fiscal.
def buffer bf-it-nota-fisc  for it-nota-fisc.
def buffer bf-componente    for componente.
DEF BUFFER b-estabelec      FOR estabelec.

/* DEV.FAT.ENT.FUT*/
DEF BUFFER b-natur-dev-fat-ent-fut FOR natur-oper.


def var c-referencia        like item-doc-est.cod-refer no-undo.
def var c-cod-refer         like item-doc-est.cod-refer no-undo.
def var l-erro-cr           as logical      no-undo.
def var l-erro-cp           as logical      no-undo.
def var l-ord-prod          as logical      no-undo.
def var l-modulo-ge         as logical      no-undo.
def var i-retorno           as integer      no-undo.
def var i-gerencial         as integer      no-undo.
def var i-per-cons          as integer      no-undo.
def var i-periodos          as integer      no-undo.
def var c-per-cons          as char         no-undo.
def var c-texto             as char         no-undo.
def var de-qtd-tot          as decimal      no-undo.
def var r-gerencial         as rowid        no-undo.
def var l-rec-Brasil        as logical      no-undo.
DEF VAR l-impto-retido      AS LOGICAL      NO-UNDO.
DEFINE VARIABLE i-num-lote  AS INTEGER    NO-UNDO.
def var i-empresa like param-global.empresa-prin no-undo.
def var i-seq-erro          as integer      no-undo.
def var l-erro-wms          as logical      no-undo.
DEF VAR hDBOSC047           AS HANDLE       NO-UNDO.
DEF VAR hDBOSC048           AS HANDLE       NO-UNDO.
DEF VAR hDBOSC138           AS HANDLE       NO-UNDO.
DEF VAR hDBOSC038           AS HANDLE       NO-UNDO.
DEF VAR c-cod-local-wms     AS CHAR         NO-UNDO.
def var i-seq-aux           as integer      no-undo.
DEF VAR l-integra-ems-his   AS LOGICAL      NO-UNDO.
DEF VAR l-integra-estab-his AS LOGICAL      NO-UNDO.
DEF VAR i-ind-sit-docto     AS INTEGER      NO-UNDO.
DEF VAR l-atualiza-estoque   AS LOGICAL      NO-UNDO.

/* Variaveis utilizadas pelo faturamento */
def var de-tot-frete        as decimal      no-undo.
def var de-frete            as decimal      no-undo.
def var de-vl-merc          as decimal      no-undo.
def var de-vl-desp          as decimal      no-undo.
def var de-vl-ori           as decimal      no-undo.
def var de-taxa-pis         as decimal      no-undo.
def var de-taxa-cofins      as decimal      no-undo.
def var i-custo             as integer      no-undo.
def var i-time              as integer      no-undo.
def var i-tipo-sal-terc     as integer      no-undo.
def var h-bodi261           as handle       no-undo.
def var h-boin735           as handle       no-undo.
def var h-bocx332           as handle       no-undo.
DEF VAR h-bocx00451         AS HANDLE       NO-UNDO.
DEF VAR h-ex3051            AS HANDLE       NO-UNDO.
DEF VAR h-exapi             AS HANDLE       NO-UNDO.
def var l-comissao-epc      as logical      no-undo.
def var l-comissao          as logical      no-undo.
def var r-registro          as rowid        no-undo.
def var l-integra-eai       as logical      no-undo.
def var i-nr-fatura         like nota-fiscal.nr-fatura             no-undo.

def var l-vinc-rot-pend     AS LOGICAL      NO-UNDO.
def var lOrigGraosAtivo     AS LOGICAL      NO-UNDO.
def var lUtilizaCaractLote  AS LOGICAL      NO-UNDO.
def var lValidarCaractLote  AS LOGICAL      NO-UNDO.
def var h-ggapi140          AS HANDLE       NO-UNDO.

/* Fretes */
DEF VAR h-bosc003           AS HANDLE       NO-UNDO.
DEF BUFFER bnatur-oper FOR natur-oper.

DEFINE VARIABLE h-boin01019 AS HANDLE  NO-UNDO.

/* Gredene */
define variable l-valida-saldo-neg-eac-ref as logical no-undo initial yes.
find first funcao
     where funcao.cd-funcao = "spp-permite-saldo-neg-eac-ref":u
       and funcao.ativo     = yes no-lock no-error.
if  avail funcao THEN
    assign l-valida-saldo-neg-eac-ref = no.
/* Faz a desatualiza‡Æo das notas de cr‚dito com o EMS 5.
   V lido somente para integra‡Æo com EMS 5.00, EMS 2.06B, ou se for EMS 2.04, com a fun‡Æo SPP-INTEGRA-RE-CR ativa. */
DEF VAR h-acr924za      AS HANDLE NO-UNDO.

{rep/re1005.i22} /* Fun‡Æo EMS 5 integra‡Æo RE */

{cdp/cd9700.i}
DEF BUFFER bf-natur-oper-fut          FOR natur-oper.
DEF BUFFER bf-docum-est-fut           FOR docum-est.
DEF BUFFER bf-item-doc-est-fut        FOR item-doc-est.
DEF BUFFER bf-movto-fatur-antecip-fut FOR movto-fatur-antecip.
DEF VAR c-texto-ent-fut               AS CHAR NO-UNDO.

/*** TT para integra‡Æo da desatualiza‡Æo do CR ***/
def temp-table tt_nota_devol NO-UNDO
    field tta_cod_ser_nota_devol     as character format "x(5)"  label "S‚rie Nota Devol" column-label "S‚rei Dev"
    field tta_cod_nota_devol         as character format "x(16)" label "Nr. Nota Devolu‡Æo" column-label "Nota Dev"
    field tta_cod_natur_operac_devol as character format "x(6)"  label "Natureza Opera‡Æo" column-label "Nat Opera‡Æo"
    field tta_cdn_cliente            as Integer format ">>>,>>>,>>9" initial 0 label "Cliente" column-label "Cliente"
    index tt_nota_devol              is primary unique
          tta_cod_ser_nota_devol     ascending
          tta_cod_nota_devol         ascending
          tta_cod_natur_operac_devol ascending
          tta_cdn_cliente            ascending.

/* Var. empresa do usuario, utilizada no ems 5 */
&IF '{&mgdis_version}' = '2.06f' &THEN
    def new global shared var i-ep-codigo-usuario as CHARACTER format "x(3)":U label "Empresa" column-label "Empresa" no-undo.
&ELSE
    def new global shared var v_cod_empres_usuar  as CHARACTER format "x(3)":U label "Empresa" column-label "Empresa" no-undo.
&ENDIF

/*internacional*/
DEFINE VARIABLE h-boar202155 AS HANDLE NO-UNDO.
DEFINE VARIABLE h-boin01067  AS HANDLE NO-UNDO.

/* Variaveis utilizadas pela Execucao Orcamentaria */
DEF VAR v-sequencia-1       AS INTEGER NO-UNDO.
DEF VAR v-sequencia-2       AS INTEGER NO-UNDO.
def var c-nro-docto-origem  as char    no-undo.

/***************** Multi-Planta **********************/
def var i-tipo-movto as integer no-undo.
def var l-cria       as logical no-undo.

/************************ *************************/
DEFINE VARIABLE i-estab-emit AS INTEGER     NO-UNDO.

{cdp/cd7300.i1}
/*********************** Fim *************************/
/* Conversor */
DEF VAR h-boin847 AS HANDLE NO-UNDO. /*NFe - Nota Fiscal de Compra */
DEF VAR h-boin871 AS HANDLE NO-UNDO. /*CTe - Conhecimento de Transporte*/
DEF VAR h-boin874 AS HANDLE NO-UNDO. /*NFSe - Nota Fiscal de Servico*/
/*************** Unificacao de conceitos *************/
def var h_api_cta_ctbl   as handle no-undo. 
/** ----------------------------------------------- **/

DEF VAR h-bodi390 AS HANDLE NO-UNDO.

&IF '{&bf_mat_versao_ems}' >= '2.08' AND '{&bf_mat_integra_eai2}' = 'YES' &THEN
    /* Integra‡Æo EMS EAI2.0*/     
    DEFINE NEW GLOBAL SHARED VARIABLE v_log_eai2_ativado AS LOGICAL NO-UNDO INITIAL NO.

    /* Carrega a variável global v_log_eai2_ativado */
    RUN cdp/cd0101i.p.

&ENDIF

find first param-global no-lock no-error.
find first param-estoq  no-lock no-error.
find first para-fat     no-lock no-error.

find docum-est
    where rowid(docum-est) = rw-docum exclusive-lock no-error.
if  docum-est.ce-atual = no then
    return.

find b1-natur-oper
    where b1-natur-oper.nat-operacao = docum-est.nat-operacao no-lock no-error.
if  not avail b1-natur-oper then return.

find empresa where empresa.ep-codigo = i-empresa no-lock no-error.
find estabelec
    where estabelec.cod-estabel = docum-est.cod-estabel no-lock no-error.
find estab-mat where
     estab-mat.cod-estabel = docum-est.cod-estabel no-lock no-error.

find emitente
    where emitente.cod-emitente = docum-est.cod-emitente no-lock no-error.

/* Funcao define se havera integracao entre o ERP e o HIS - Sistema Hospitalar */
ASSIGN l-integra-ems-his =  CAN-FIND (FIRST funcao
                                      WHERE funcao.cd-funcao = "spp-integra-ems-his":U
                                      AND   funcao.ativo     = yes).

IF v_log_eai_habilit THEN
    ASSIGN l-integra-eai = YES.

/* Emitente parceiro EAI*/
&IF '{&bf_mat_versao_ems}':U >= '2.05':U &THEN
    find first dist-emitente no-lock
        where dist-emitente.cod-emitente = emitente.cod-emitente no-error.
    if  avail dist-emitente
    and dist-emitente.parceiro-b2b then
        assign l-integra-eai = yes.
&else 
    if substr(emitente.char-1,11,1) = "1" then
        assign l-integra-eai = yes.
&ENDIF


/* buscar empresa do estabelecimento */
{cdp/cd9970.i estabelec.cod-estabel}
find first param-ge
    where param-ge.ep-codigo = i-empresa no-lock no-error.
assign l-rec-Brasil  = (i-pais-impto-usuario  = 1).   /* 1 indica pais Brasil */
if  avail param-ge then do:
    if  param-ge.informa-data = yes then do:
        assign l-modulo-ge = yes.
        if  search("gep/ge0102a.p") <> ?
        or  search("gep/ge0102a.r") <> ? then
            assign l-modulo-ge = yes.
        else
            assign l-modulo-ge = no.
    end.
    else
        assign l-modulo-ge = no.
end.
else
    assign l-modulo-ge = no.

/* Consistˆncias da Nota Fiscal */
if  not l-somente-of then do:
    assign l-erro = no.
    {rep/re0402a.i2}

    if  l-erro THEN
        return.
end.

/******** Chamada EPC para consistencias da nota *******/
for each tt-epc
    where tt-epc.cod-event = "Inicio-Atualizacao".
    delete tt-epc.
end.

create tt-epc.
assign tt-epc.cod-event     = "Inicio-Atualizacao"
       tt-epc.cod-parameter = "docum-est-rowid"
       tt-epc.val-parameter = string(rowid(docum-est)).

{include/i-epc201.i "Inicio-Atualizacao"}

if return-value = 'NOK' then do:
   FIND FIRST tt-epc 
        WHERE tt-epc.cod-event = "tt-erro" NO-LOCK NO-ERROR.
   IF AVAIL tt-epc THEN DO:
        CREATE tt-erro.
        ASSIGN tt-erro.cd-erro  = INT(tt-epc.cod-parameter)
               tt-erro.mensagem = tt-epc.val-parameter.
   END.
   assign l-erro = yes.
   return.
end.

/************* MODULO RECUPERADOR IMPOSTOS ************/
/*Definic‡Æo da temp-table tt-erro-mri */
DEFINE TEMP-TABLE tt-erro-mri NO-UNDO
        FIELD ErrorSequence    AS INTEGER
        FIELD ErrorNumber      AS INTEGER
        FIELD ErrorDescription AS CHARACTER
        FIELD ErrorParameters  AS CHARACTER
        FIELD ErrorType        AS CHARACTER
        FIELD ErrorHelp        AS CHARACTER
        FIELD ErrorSubType     AS CHARACTER.

RUN pi-pre-valida-mri.

/******************************************************/
run pi-leitura.

if  i-periodos > 12 then
    assign i-periodos = i-periodos - 12.

if  not l-somente-of then do on error undo, return:

    assign l-erro-cr    = no.
           l-erro-cp = no.

    if  docum-est.esp-docto = 20
    and b1-natur-oper.tipo  = 1
    and param-global.modulo-cr
    and docum-est.cr-atual
    AND (l-acr-ems50 AND l-acr-ems2 AND NOT l-desatualiza-cr) /* Somente valida se nÆo foi parametrizado para desatualizar o CR */
    THEN do:
        run pi-erro-nota ( 8642, " ", no ).

        run rep/re9995.p ( input rowid(docum-est),
                           0,
                           0,
                           8642,
                           no,
                           0,
                           2 ).  /* Advertˆncia */
    end.
    else
        assign l-flag-com = 1. /* assume valor liquido p/ calc comissao */

    /* Estorno do Acabado */
    RUN pi-estorno-acabado.
    IF RETURN-VALUE = "NOK":U THEN
        RETURN.

    for each item-doc-est {cdp/cd8900.i item-doc-est docum-est} exclusive-lock:

        find item where item.it-codigo = item-doc-est.it-codigo no-lock no-error.

        /* Desatualiza Reservas e Ordem de Produ‡Æo */
        if  item-doc-est.nr-ord-prod <> 0
        and param-global.modulo-cp
        and item-doc-est.baixa-ce
        and item-doc-est.quantidade <> 0 
        /*and item.tipo-requis = 1 */ /*Alterado devido a FO 1814.495 - SOPRANO*/
        then 
            run pi-desatualiza-cp.

        /*Verifica se item possui Roteiro de Inspe»’o Antecipado*/
        for first item-uni-estab no-lock
            where item-uni-estab.it-codigo   = item-doc-est.it-codigo
              and item-uni-estab.cod-estabel = docum-est.cod-estabel:
            ASSIGN l-vinc-rot-pend = item-uni-estab.log-rotei-pend.
        end.
        
        /* Desatualiza Controle de Qualidade */
        RUN pi-desatualiza-lote.
        IF l-vinc-rot-pend THEN
          RUN pi-desatualiza-cq-antecipado.
        ELSE DO:
            if  not docum-est.rec-fisico THEN
                run pi-desatualiza-cq.
        end.

        /* Data de Ultima Entrada do Item */
        if  item.data-ult-ent    = docum-est.dt-trans
        and docum-est.tipo-docto = 1 then
            run rep/re9995.p ( input rowid(docum-est),
                               0,
                               0,
                               6337,
                               no,
                               item-doc-est.sequencia,
                               2 ).                     /* Advertˆncia */

        /* Desatualiza M¢dulo de Compras */
        if  docum-est.mod-atual = 1 then /* Material Agregado */
            for each recebimento use-index fornecedor
                where recebimento.data-movto   = docum-est.dt-trans
                and   recebimento.numero-nota  = TRIM(docum-est.nro-docto)
                and   recebimento.serie-nota   = TRIM(docum-est.serie-docto)
                and   recebimento.cod-movto    = b1-natur-oper.tipo
                and   recebimento.cod-emitente = docum-est.cod-emitente exclusive-lock:

                IF recebimento.nat-operacao = docum-est.nat-operacao THEN
                   RUN pi-desatualiza-cc.
                ELSE IF TRIM(SUBSTRING(recebimento.char-1,1,6)) = docum-est.nat-operacao THEN
                        run pi-desatualiza-cc.
            end.
        else
             for each recebimento use-index fornecedor
                where recebimento.data-movto   = docum-est.dt-trans
                and   recebimento.it-codigo    = TRIM(item-doc-est.it-codigo)
                and   recebimento.numero-nota  = TRIM(docum-est.nro-docto)
                and   recebimento.serie-nota   = TRIM(docum-est.serie-docto)
                and   recebimento.cod-movto    = b1-natur-oper.tipo
                and   recebimento.cod-emitente = docum-est.cod-emitente exclusive-lock:

                IF recebimento.nat-operacao = docum-est.nat-operacao THEN
                   RUN pi-desatualiza-cc.
                ELSE IF TRIM(SUBSTRING(recebimento.char-1,1,6)) = docum-est.nat-operacao THEN
                        run pi-desatualiza-cc.
            end.

        /* Desatualiza Terceiros */
        if b1-natur-oper.nota-rateio = no then
           run pi-desatualiza-terceiros.

        RUN pi-desatualiza-draw.

        /* Desatualiza Mod. Memorando Exporta‡Æo */
        run pi-desatualiza-memorando.

        IF l-erro THEN 
           RETURN.

        /* Desatualiza Pedidos e Faturamento */
        if  docum-est.esp-docto = 20
        and b1-natur-oper.tipo     = 1 then do:
            find devol-cli use-index ch-nfe
                where devol-cli.cod-emitente = docum-est.cod-emitente
                and   devol-cli.cod-estabel  = docum-est.cod-estabel
                and   devol-cli.serie-docto  = docum-est.serie-docto
                and   devol-cli.nat-operacao = docum-est.nat-operacao
                and   devol-cli.nro-docto    = docum-est.nro-docto
                and   devol-cli.sequencia    = item-doc-est.sequencia
                and   devol-cli.serie        = item-doc-est.serie-comp
                and   devol-cli.nr-nota-fis  = item-doc-est.nro-comp
                and   devol-cli.nr-sequencia = item-doc-est.seq-comp
                and   devol-cli.it-codigo    = item-doc-est.it-codigo  exclusive-lock no-error.
            if  avail devol-cli then do:
                find nota-fiscal
                    where nota-fiscal.cod-estabel = devol-cli.cod-estabel
                    and   nota-fiscal.serie       = devol-cli.serie
                    and   nota-fiscal.nr-nota-fis = devol-cli.nr-nota-fis
                    no-lock no-error.
                if  avail nota-fiscal then do:
                    if  devol-cli.ind-atu-est = yes THEN do:
                        assign i-custo = i-prc-custo.
                        {ftp/ft0605.i5 "-"}
                    end.
                end.

                /* ATUALIZA€ÇO DE COTAS */
                IF param-global.modulo-08 THEN DO:
                   IF  NOT VALID-HANDLE(h-bodi261) OR
                       h-bodi261:TYPE      <> "PROCEDURE":U OR
                       h-bodi261:FILE-NAME <> "dibo/bodi261.p":U THEN
                       RUN dibo/bodi261.p PERSISTENT SET h-bodi261 NO-ERROR.

                   RUN atualizarCotasRecebimento in h-bodi261(INPUT ROWID(devol-cli),
                                                              INPUT 5). /*devolucao*/

                   IF VALID-HANDLE(h-bodi261) THEN DO:
                      DELETE PROCEDURE h-bodi261.
                      ASSIGN h-bodi261 = ?.
                   END.
                END.
                
                &IF defined(bf_devolucao_exportacao) &THEN
                    {rep/re0402a.i6}
                &else
                    delete devol-cli validate(yes," ").
                &endif
                
            end.
            ELSE
                if item-doc-est.nro-comp <> ""             /* tem nota origem mas nao tem devol-cli */
                and docum-est.cod-observa <> 4 then do:   /* Servi‡o */
                    {utp/ut-table.i mgdis devol-cli 1}

                    run pi-erro-nota ( 7016, input return-value , no). /* emite aviso */
                    run rep/re9995.p ( input rowid(docum-est),
                                       0,
                                       0,
                                       7016,
                                       no,
                                       item-doc-est.sequencia,
                                       2 ).                  /* Advertˆncia */
                end.

            run pi-desatualiza-ft.

            if return-value = "ADM-ERROR" then /* ocorreu erro na pi-desatualiza-ft */
            do:
                run pi-erro-nota ( 19248, input " ", yes ).
                return.
            end.
            /* DESATUALIZA QUANTIDADE DEVOLVIDA NO REMITO */
            if  not l-rec-Brasil THEN
                RUN pi-desatualiza-remito.
        end.

        /** Torna indisponiveis os seriais dos itens do documentos **/
        &if "{&bf_mat_versao_ems}":U >= "2.05":U &then
            if  can-find (funcao
                           where funcao.cd-funcao = "spp-seriais-nf":U
                           and   funcao.ativo)
            and docum-est.cod-observa = 3 then do:

                for first item-dist fields (log-1)
                    where item-dist.it-codigo = item-doc-est.it-codigo no-lock: end.
                if  avail item-dist
                and item-dist.log-1 then  do:

                    if  not valid-handle (h-boin735) then
                        run inbo/boin735.p persistent set h-boin735.

                    run atualizaItemRecFiscal in h-boin735 (input ?,
                                                            input 2, /** Desatualiza **/
                                                            input item-doc-est.serie-docto,
                                                            input item-doc-est.nro-docto,
                                                            input item-doc-est.cod-emitente,
                                                            input item-doc-est.nat-operacao,
                                                            input item-doc-est.sequencia).

                    if  return-value = "NOK":U then do:
                        run getRowErrors in h-boin735 (output table rowErrors).

                        for each rowErrors:
                            find last tt-erro no-error.
                            if  avail tt-erro then
                                assign i-sequencia = tt-erro.i-sequen + 1.
                            ELSE
                                assign i-sequencia = 1.

                            create tt-erro.
                            assign tt-erro.i-sequen = i-sequencia
                                   tt-erro.cd-erro  = RowErrors.ErrorNumber
                                   tt-erro.mensagem = RowErrors.ErrorDescription
                                   l-erro           = yes.
                        end.
                    end.

                    if  valid-handle (h-boin735) then do:
                        delete procedure h-boin735.
                        assign h-boin735 = ?.
                    end.

                    if  l-erro then
                        return.
                end.
            end.
        &endif

        /* DESATUALIZA QUANTIDADE DEVOLVIDA PARA NOTAS DE DEVOLU€ÇO A FORNECEDOR */
        if  b1-natur-oper.tipo = 2
        and docum-est.esp-docto = 20 then do:

            find b-item-doc-est
                where b-item-doc-est.cod-emitente = item-doc-est.cod-emitente
                  and b-item-doc-est.serie-docto  = item-doc-est.serie-comp
                  and b-item-doc-est.nro-docto    = item-doc-est.nro-comp
                  and b-item-doc-est.nat-operacao = item-doc-est.nat-comp
                  and b-item-doc-est.it-codigo    = item-doc-est.it-codigo
                  and b-item-doc-est.sequencia    = item-doc-est.seq-comp
                exclusive-lock no-error.
            if  avail b-item-doc-est then do:
                assign b-item-doc-est.qt-real = b-item-doc-est.qt-real - item-doc-est.quantidade.
                if  b-item-doc-est.qt-real < 0 THEN
                    assign b-item-doc-est.qt-real = 0.
            end.
        end.


        /*--- quando a nota eh fatura entrega futura ou faturamento antecipado, a quantidade recebida 
             fica armazenada somente no campo ordem-compra.qtd-recbda-fut. A baixa da ordem de compra (tabela recebimento)
             eh gerada somente ao receber a respectiva nota de remessa ---*/

        FIND bf-natur-oper-fut WHERE
             bf-natur-oper-fut.nat-operacao = item-doc-est.nat-operacao NO-LOCK NO-ERROR.

        /*--- verifica se docum-est eh de nota de fatura faturamento ou fatura entrega futura ---*/
        {cdp/cd9700.i1 bf-natur-oper-fut}

        IF  l-fatura-fat-antecip
        OR  l-fatura-ent-futura THEN DO:

            IF  item-doc-est.numero-ordem > 0 THEN DO:
                FIND ordem-compra EXCLUSIVE-LOCK
                     WHERE ordem-compra.numero-ordem = item-doc-est.numero-ordem NO-ERROR.
                IF  AVAIL ordem-compra THEN DO:
                    FIND FIRST prazo-compra EXCLUSIVE-LOCK
                         WHERE prazo-compra.numero-ordem = item-doc-est.numero-ordem
                           AND prazo-compra.parcela      = item-doc-est.parcela NO-ERROR.
                    IF AVAIL prazo-compra THEN DO:
                        ASSIGN prazo-compra.qtd-recbda-fut = prazo-compra.qtd-recbda-fut - item-doc-est.quantidade.
                        IF  prazo-compra.qtd-recbda-fut < 0 THEN
                            ASSIGN prazo-compra.qtd-recbda-fut = 0.
                    END.

                    ASSIGN ordem-compra.qtd-recbda-fut = ordem-compra.qtd-recbda-fut - item-doc-est.quantidade.
                    IF  ordem-compra.qtd-recbda-fut < 0 THEN
                        ASSIGN ordem-compra.qtd-recbda-fut = 0.

                    IF l-fatura-ent-futura THEN
                        run pi-aloca-ordem-cc ( yes, item-doc-est.quantidade, rowid(prazo-compra)).
                END.
            END.
            ELSE DO:
                FOR EACH  rat-ordem 
                    WHERE rat-ordem.nro-docto    = docum-est.nro-docto
                      AND rat-ordem.serie-docto  = docum-est.serie-docto
                      AND rat-ordem.nat-operacao = docum-est.nat-operacao
                      AND rat-ordem.cod-emitente = docum-est.cod-emitente
                      AND rat-ordem.sequencia    = item-doc-est.sequencia NO-LOCK:
                    FIND ordem-compra EXCLUSIVE-LOCK
                         WHERE ordem-compra.numero-ordem = rat-ordem.numero-ordem NO-ERROR.
                    IF  AVAIL ordem-compra THEN DO:
                        FIND FIRST prazo-compra EXCLUSIVE-LOCK
                             WHERE prazo-compra.numero-ordem = rat-ordem.numero-ordem
                               AND prazo-compra.parcela      = rat-ordem.parcela NO-ERROR.
                        IF AVAIL prazo-compra THEN DO:
                            ASSIGN prazo-compra.qtd-recbda-fut = prazo-compra.qtd-recbda-fut - rat-ordem.quantidade.
                            IF  prazo-compra.qtd-recbda-fut < 0 THEN
                                ASSIGN prazo-compra.qtd-recbda-fut = 0.
                        END.

                        ASSIGN ordem-compra.qtd-recbda-fut = ordem-compra.qtd-recbda-fut - rat-ordem.quantidade.
                        IF  ordem-compra.qtd-recbda-fut < 0 THEN
                            ASSIGN ordem-compra.qtd-recbda-fut = 0.                    

                        IF l-fatura-ent-futura THEN
                            run pi-aloca-ordem-cc ( yes, rat-ordem.quantidade, rowid(prazo-compra)).
                    END.
                END.
            END.        
        END.

    end. /* for each item-doc-est */

    /*REINF*/
    FOR EACH ext-docum-est 
       WHERE ext-docum-est.serie-docto  = docum-est.serie-docto
         AND ext-docum-est.nro-docto    = docum-est.nro-docto
         AND ext-docum-est.cod-emitente = docum-est.cod-emitente
         AND ext-docum-est.nat-operacao = docum-est.nat-operacao 
         AND ext-docum-est.cod-param    = "reinf":U EXCLUSIVE-LOCK:
       DELETE ext-docum-est.
    END.

    IF CAN-FIND(FIRST funcao
                WHERE funcao.cd-funcao = "spp-ifric22":U
                  AND funcao.ativo) THEN
        RUN pi-desatualiza-antecip-import.

    if  l-erro THEN
        return.

    if  connected("MGINV") THEN
        run rep/re0402rf.p (input rowid(docum-est),
                            OUTPUT TABLE tt-erro APPEND).

    /* desaloca saldo do wms para nÆo exigir que o item permita saldo negativo */
    IF  l-desatualiza-wms = YES
    AND docum-est.log-2   = YES THEN DO:        
         RUN pi-desfaz-qtd-aloc-prod-wms.
    END.

    /*desatualização notas de frete GFE*/
    
    /*desatualização diferenciada para doc GFE*/
    {inbo/boin01019.i1 "D"} /* verificaCtbzGFE */ /* D - Desatualiza‡Æo */
    IF l-ctbz-gfe THEN DO:

        IF NOT VALID-HANDLE(h-boin01019) THEN 
            RUN inbo/boin01019.p PERSISTENT SET h-boin01019.

        RUN emptyRowErrors IN h-boin01019.

        RUN descontabilizacaoGFE IN h-boin01019 (INPUT rowid(docum-est)).

        RUN getRowErrors IN h-boin01019(OUTPUT TABLE RowErrors).
                    IF CAN-FIND(FIRST RowErrors
                                 WHERE RowErrors.ErrorType <> "INTERNAL":U) THEN DO:

                        FOR EACH RowErrors
                            WHERE RowErrors.ErrorType <> "INTERNAL":U:
                
                            FIND LAST tt-erro NO-ERROR.
                            IF  avail tt-erro THEN
                                ASSIGN i-sequencia = tt-erro.i-sequen + 1.
                            ELSE
                            ASSIGN i-sequencia = 1.
                
                            CREATE tt-erro.
                            ASSIGN tt-erro.i-sequen = i-sequencia
                                   tt-erro.cd-erro  = RowErrors.ErrorNumber
                                   tt-erro.mensagem = RowErrors.ErrorDescription
                                   l-erro           = yes.

                        END.

                        IF VALID-HANDLE(h-boin01019) THEN DO:
                            DELETE PROCEDURE h-boin01019.
                            ASSIGN h-boin01019 = ?.
                        END.

                        RETURN.

                    END.

        IF VALID-HANDLE(h-boin01019) THEN DO:
            DELETE PROCEDURE h-boin01019.
            ASSIGN h-boin01019 = ?.
        END.

    END.
     
     IF i-pais-impto-usuario <> 1  AND 
        docum-est.esp-docto  = 20  AND
        docum-est.log-2      = YES AND  
        l-desatualiza-wms    = YES THEN DO:
         IF NOT VALID-HANDLE(hDBOSC038) THEN
            RUN scbo/bosc038.p PERSISTENT SET hDBOSC038.         
     END.

    ASSIGN lOrigGraosAtivo = param-global.log-modul-gg
           h-ggapi140      = ?.

    /* Desatualiza Estoque */
    for each movto-estoq exclusive-lock
         where movto-estoq.serie-docto  = docum-est.serie-docto
         and movto-estoq.nro-docto      = docum-est.nro-docto
         and movto-estoq.cod-emitente   = docum-est.cod-emitente
         and ( movto-estoq.nat-operacao = docum-est.nat-operacao
            or movto-estoq.nat-operacao = " " )
        by movto-estoq.tipo-trans descending:       

        if  movto-estoq.origem-valor = "FT" then next.

        if  movto-estoq.esp-docto = 1 OR  movto-estoq.esp-docto = 8 then next.

        /* Somente elimina movto-estoq de entrada originado no Recebimento F¡sico */
        if  movto-estoq.nat-operacao = " "
        and (    not docum-est.rec-fisico
            or trim(substr(movto-estoq.referencia,1,4)) <> ( "RF":U + string(docum-est.int-1) )
            or movto-estoq.tipo-trans <> 2 ) THEN next.

        IF NOT CAN-FIND(funcao WHERE funcao.cd-funcao = "spp-integracao-eai" AND funcao.ativo) THEN DO:
            run pi-eai.
        END.

        if  return-value = "NOK":U then
            return. 

        find ITEM
            where item.it-codigo = movto-estoq.it-codigo no-lock no-error.
        FIND   item-uni-estab 
         WHERE ITEM-uni-estab.it-codigo   = ITEM.it-codigo 
           AND item-uni-estab.cod-estabel = movto-estoq.cod-estabel 
                                                   NO-LOCK NO-ERROR.       


         IF i-pais-impto-usuario <> 1  AND 
            docum-est.esp-docto  = 20  AND
            docum-est.log-2      = YES AND  
            l-desatualiza-wms    = YES THEN DO:                                
                
             IF CAN-FIND (FIRST deposito 
                          WHERE deposito.cod-depos    = movto-estoq.cod-depos 
                            AND deposito.log-gera-wms = YES) THEN DO:           
                                

                assign c-nro-docto-origem = string(docum-est.serie-docto,"x(5)")
                                          + string(docum-est.nro-docto,"x(16)")
                                          + string(docum-est.cod-emitente,">>>>>>>>9")
                                          + string(docum-est.nat-operacao).

                RUN retornaDoctoAtualizaEstoque IN hDBOSC038 (INPUT docum-est.cod-estabel,
                                                              INPUT movto-estoq.cod-depos,
                                                              INPUT 22,
                                                              INPUT c-nro-docto-origem,
                                                              INPUT docum-est.nro-docto,
                                                              INPUT 2,
                                                              OUTPUT l-atualiza-estoque).
                        
                IF NOT l-atualiza-estoque THEN NEXT. /*movto-estoq*/ 
                                           
             END.
         END.

        /* Desatualiza saldos em estoque */
        if  item.tipo-contr <> 4
        and movto-estoq.quantidade <> 0 then do:

            FOR EACH saldo-estoq
                where saldo-estoq.it-codigo   = movto-estoq.it-codigo
                and   saldo-estoq.cod-estabel = movto-estoq.cod-estabel
                and   saldo-estoq.cod-depos   = movto-estoq.cod-depos
                and   saldo-estoq.cod-localiz = movto-estoq.cod-localiz
                and   saldo-estoq.lote        = movto-estoq.lote
                and   saldo-estoq.cod-refer   = movto-estoq.cod-refer exclusive-lock:
            
                find item-estab
                    where item-estab.cod-estabel = movto-estoq.cod-estabel
                      and item-estab.it-codigo   = movto-estoq.it-codigo EXCLUSIVE-LOCK NO-ERROR.
                
               
    
                if  movto-estoq.tipo-trans = 1 THEN DO:
                    assign saldo-estoq.qtidade-atu = saldo-estoq.qtidade-atu
                                                   - movto-estoq.quantidade
                           item-estab.qtidade-atu  = item-estab.qtidade-atu
                                                   - movto-estoq.quantidade.
    
                    IF  i-pais-impto-usuario = 2 /* Argentina */
                    AND CAN-FIND(FIRST funcao WHERE funcao.cd-funcao = "spp-cod-despacho-plaza":U AND funcao.ativo) THEN DO:
    
                        IF  NOT VALID-HANDLE(h-boar202155) THEN
                            RUN local/arg/boar202155.p PERSISTENT SET h-boar202155.
    
                        RUN desatualiza-argext-sdo IN h-boar202155 (INPUT ROWID(saldo-estoq),
                                                                    INPUT ROWID(docum-est),
                                                                    INPUT movto-estoq.quantidade).
                    END.
    
                END.
                else
                    assign saldo-estoq.qtidade-atu = saldo-estoq.qtidade-atu
                                                   + movto-estoq.quantidade
                           item-estab.qtidade-atu  = item-estab.qtidade-atu
                                                   + movto-estoq.quantidade.                
                
                if  (saldo-estoq.qtidade-atu  -
                     saldo-estoq.qt-alocada   -
                     saldo-estoq.qt-aloc-prod -
                     saldo-estoq.qt-aloc-ped   ) < 0 then do:
                    if  l-valida-saldo-neg-eac-ref = yes   /* funcao especifica da grendene para permitir desatualizar a nota com saldo negativo*/
                    or  l-saldo-neg = no  then do:
                       IF AVAIL item-uni-estab THEN DO:
                           if  item-uni-estab.perm-saldo-neg = 1 then do:
                               run pi-erro-nota ( 8715, input saldo-estoq.it-codigo, yes ).
                               /*return.*/
                           end.
                           else if item-uni-estab.perm-saldo-neg = 2 then do:
                                if l-saldo-neg = no then do:
                                    run pi-erro-nota ( 8715, input saldo-estoq.it-codigo, yes ).
                                    /*return.*/
                                end.
                           end.
                       END.
                       ELSE DO:
                           if  item.perm-saldo-neg = 1 then do:
                               run pi-erro-nota ( 8715, input saldo-estoq.it-codigo, yes ).
                               /*return.*/
                           end.
                           else if item.perm-saldo-neg = 2 then do:
                                if l-saldo-neg = no then do:
                                    run pi-erro-nota ( 8715, input saldo-estoq.it-codigo, yes ).
                                    /*return.*/
                                end.
                           end.
                       END.
                    END.
                END.

                IF i-pais-impto-usuario <> 1 /* Brasil */ AND
                   CAN-FIND(FIRST funcao WHERE funcao.cd-funcao = "spp-controle-aduana-internac":U AND funcao.ativo) THEN DO:
                     IF NOT VALID-HANDLE(h-boin01067) THEN
                         RUN inbo/boin01067.p PERSISTENT SET h-boin01067.

                     RUN DesatualizaDocto IN h-boin01067 (INPUT ROWID(movto-estoq)).

                     IF RETURN-VALUE = "NOK":U THEN DO:

                        IF i-pais-impto-usuario = 4 THEN
                            {utp/ut-liter.i "Pedimento" *}
                        ELSE
                            {utp/ut-liter.i "Controle_de_Aduana" *}                        

                        run pi-erro-nota ( 56238, input (saldo-estoq.it-codigo + "~~" + TRIM(RETURN-VALUE)), yes ).
                     END.
                     
                END.

            END. /* end for each saldo-estoq*/
        END.

        /* Elimina movimento de material */
        find first movto-mat use-index num-seq
            where movto-mat.nr-ord-prod = movto-estoq.nr-ord-produ
            and   movto-mat.num-sequen = movto-estoq.num-sequen exclusive-lock no-error.
        if  avail movto-mat then do:
            delete movto-mat.
        end.

        /* Desatualiza situa‡Æo do Aviso de Recolhimento */ 
        IF SUBSTRING(docum-est.char-1,192,16) <> "" THEN DO:
            FIND FIRST aviso-recolhto WHERE aviso-recolhto.cdn-emit    = docum-est.cod-emitente                      
                                        AND aviso-recolhto.nr-docto    = SUBSTRING(docum-est.char-1,192,16)                         
                                        AND aviso-recolhto.cod-estabel = docum-est.cod-estabel EXCLUSIVE-LOCK NO-ERROR.
            IF AVAIL aviso-recolhto THEN
                ASSIGN aviso-recolhto.cod-situacao = 2.
        END.                                                      
                                                                     
        /*************************************************/          

        /*-----------------------------------------------------------------------------------------*/
        /* Verifica se sistema de manuten‡Æo de frota (M¢dulo Manuten‡Æo Mecƒnica) est  implantado */
        /*-----------------------------------------------------------------------------------------*/
        /* Rotina para excluir os movimentos de materiais do sistema de manuten‡Æo de frota        */ 
        /*-----------------------------------------------------------------------------------------*/
         run pi-verifica-ordem-frota in this-procedure.


        /* Desatualiza Consumo  */
        run pi-desatualiza-consumo.

        /* Desatualiza Custo On-line - RE0402 */
        if  avail estab-mat
        and estab-mat.usa-on-line THEN
            run pi-desatualiza-custo.

        if  param-global.modulo-pl then do:
            run cdp/cd7000.p (input 1,
                              input ITEM.it-codigo,
                              input docum-est.cod-estabel).
        end.
        /*************************************************
        * Chamada EPC para Controle de Vasilhames - Super *
        *************************************************/
        if  avail movto-estoq then do:
            for each tt-epc
               where tt-epc.cod-event = "Controle-Vasilhames2".
    	           delete tt-epc.
            end.

            create tt-epc.
            assign tt-epc.cod-event     = "Controle-Vasilhames2"
                   tt-epc.cod-parameter = "movto-estoq-rowid"
   	         tt-epc.val-parameter = string(rowid(movto-estoq)).
            {include/i-epc201.i "Controle-Vasilhames2"}
            if  return-value = 'NOK' then do:
                assign l-erro = yes.
                return.
            end.
        end.
        /*-- Execucao Orcamentaria EMS 5 - Datasul FINANCAS --*/
        &if "{&mgadm_version}" >= "2.04" &then
            IF (docum-est.ct-transit + docum-est.sc-transit) <> (movto-estoq.ct-codigo + movto-estoq.sc-codigo) THEN DO:
                run cdp/cd1005o.p (input 1,
                                   input i-empresa,
                                   input movto-estoq.nr-ord-produ,
                                   input movto-estoq.ct-codigo,
                                   input movto-estoq.sc-codigo,
                                   input movto-estoq.cod-estabel,
                                   input movto-estoq.dt-trans,
                                   input (movto-estoq.nr-trans),
                                  &IF "{&bf_mat_versao_ems}" >= "2.062" &THEN
                                   INPUT movto-estoq.cod-unid-negoc,
                                  &ENDIF
                                   input-output v-sequencia-1,
                                   input-output table tt_xml_input_1,
                                   output table tt_log_erros).
            END.
        &endif
        
        &IF "{&bf_mat_versao_ems}" >= "2.062" &THEN
        FOR EACH rat-movto-estoq-un EXCLUSIVE-LOCK
           WHERE rat-movto-estoq-un.num-trans = movto-estoq.nr-trans:
            DELETE rat-movto-estoq-un.
        END.
        &ENDIF

        /* *** Origina‡Æo de GRÇOS *** */
        IF  l-erro = NO AND lOrigGraosAtivo THEN DO:
		    IF  lValidarCaractLote = NO THEN DO:
				RUN ggp/ggapi007.p(movto-estoq.it-codigo, OUTPUT lUtilizaCaractLote).
				IF  lUtilizaCaractLote THEN DO:
					ASSIGN lValidarCaractLote = YES.

					RUN ggp/ggapi140.p PERSISTENT SET h-ggapi140.
					IF  VALID-HANDLE(h-ggapi140) THEN DO: /* NFE - nota fiscal de entrada */
						RUN piExecutar IN h-ggapi140 (BUFFER movto-estoq, 
													 "delete":U,
													  OUTPUT l-erro,
													  OUTPUT TABLE tt-erro APPEND).
						IF  l-erro THEN
							RETURN.
					END.
				END.
			END.
        END.

        /*Cria‡Æo da tabela hist¢rico para os movimentos (mvto-estoq) eliminados - Fun‡Æo Lote Avan‡ado*/
        &if '{&bf_lote_avancado_liberado}' = 'yes' &then
           IF CAN-FIND(FIRST funcao 
                       WHERE funcao.cd-funcao = "LOTE-AVANCADO":U 
                       AND   funcao.ativo     = YES) and
               ITEM.tipo-con-est > 2 THEN DO:
               RUN cep/ceapi030.p PERSISTENT SET h-ceapi030(INPUT  TABLE tt-dados-fda,
                                                            OUTPUT TABLE tt-valores,  
                                                            OUTPUT TABLE tt-erro APPEND).
               RUN cep/ceapi028.p PERSISTENT SET h-ceapi028(INPUT TABLE tt-fda-lote-avancad, 
                                                            INPUT TABLE tt-fda-lote-histor,  
                                                            INPUT 4, /*Faturamento*/
                                                            INPUT "Desatualiza‡Æo Documento Fiscal",
                                                            OUTPUT TABLE tt-erro APPEND).
               RUN pi-identifica-saldo IN h-ceapi030(INPUT 0,
                                                     INPUT movto-estoq.it-codigo,
                                                     INPUT movto-estoq.cod-estabel,
                                                     INPUT movto-estoq.lote,
                                                     INPUT 0,
                                                     OUTPUT p-retorno,
                                                     OUTPUT TABLE tt-valores2,
                                                     OUTPUT TABLE tt-erro APPEND).
               FOR FIRST tt-valores2:
                   EMPTY TEMP-TABLE tt-fda-lote-histor.
                   create tt-fda-lote-histor.
                   assign tt-fda-lote-histor.dat-alter         = today
                          /*tt-fda-lote-histor.des-alter[1]      = "Desatualiza‡Æo Documento Fiscal " + "N§" + string(movto-estoq.nro-docto) + " Programa RE0402A" */
                          tt-fda-lote-histor.hra-alter         = string(time, "hh:mm:ss")
                          tt-fda-lote-histor.nr-trans          = movto-estoq.nr-trans
                          tt-fda-lote-histor.i-seq             = 0.
                   RUN pi-cria-historico IN h-ceapi028(INPUT 0,
                                                       INPUT tt-valores2.r-rowid,
                                                       INPUT TABLE tt-fda-lote-histor,
                                                       INPUT 4, /*faturamento*/
                                                       INPUT "Desatualiza‡Æo Documento Fiscal " + "N§" + string(movto-estoq.nro-docto) + " Programa RE0402A").
               END.
           END.
        &ENDIF 
        
        /* Verifica se o estabelecimento esta integrado com o HIS */
        IF l-integra-ems-his THEN DO:
            FOR FIRST b-estabelec FIELD() NO-LOCK
                WHERE b-estabelec.cod-estabel = movto-estoq.cod-estabel
                  AND SUBSTRING(b-estabelec.char-2,214,1) = "S":
                ASSIGN l-integra-estab-his = YES.
            END.
        END.
        
        IF CAN-FIND(funcao WHERE funcao.cd-funcao = "spp-integracao-eai" AND funcao.ativo) THEN DO:
            IF ((l-integra-ems-his AND l-integra-estab-his) OR NOT l-integra-ems-his) OR v_log_eai2_ativado THEN DO:
               CREATE tt-rowid-movto-estoq.
               ASSIGN tt-rowid-movto-estoq.r-rowid = rowid(movto-estoq).
            END.
            ELSE DO:
               delete movto-estoq.
            END.
        END. 
        ELSE DO:
           delete movto-estoq.
        END.

	/*VERIFICA SE EXSITE MOVIMENTO NA TABELA ITEM-ENTR-ST*/
        RUN pi-verif-movto-item-entr-st. 
            
    END.

    IF  VALID-HANDLE(h-ggapi140) THEN DO:
        DELETE PROCEDURE h-ggapi140.
        ASSIGN h-ggapi140 = ?.
    END.

    IF i-pais-impto-usuario <> 1  AND 
        docum-est.esp-docto  = 20  AND
        docum-est.log-2      = YES AND  
        l-desatualiza-wms    = YES THEN DO:
         IF VALID-HANDLE(hDBOSC038) THEN DO:
            run destroy IN hDBOSC038.
            DELETE OBJECT hDBOSC038 NO-ERROR.
         END.
     END.

    /* *** ISSUE MAGRO-419 (208514)       *** */
    /* *** Tratamento Origina‡Æo de GrÆos *** */
    IF  l-erro = NO THEN DO:
        IF  lOrigGraosAtivo THEN DO:
            RUN ggp/ggre0402a.p (INPUT ROWID(docum-est),
                                 OUTPUT l-erro,
                                 OUTPUT TABLE tt-erro APPEND).
        END.
    END.

    for each movto-pend {cdp/cd8900.i movto-pend docum-est} no-lock:
        for each recebimento use-index data
            where recebimento.data-movto   = docum-est.dt-trans
            and   recebimento.num-pedido   = movto-pend.num-pedido
            and   recebimento.numero-ordem = movto-pend.numero-ordem
            and   recebimento.parcela      = movto-pend.parcela
            and   recebimento.numero-nota  = docum-est.nro-docto
            and   recebimento.serie-nota   = docum-est.serie-docto
            and   recebimento.cod-movto    = 1 exclusive-lock:

            IF recebimento.nat-operacao = docum-est.nat-operacao THEN
               RUN pi-desatualiza-cc.
            ELSE IF TRIM(SUBSTRING(recebimento.char-1,1,6)) = docum-est.nat-operacao THEN
                RUN pi-desatualiza-cc.
        end.
    end.
    /* Altera Situa‡Æo do Documento no Recebimento F¡sico */
    if  docum-est.rec-fisico then
        run rep/re0402c.p ( input rowid(docum-est) ).
    if  l-erro then return.
    assign docum-est.ce-atual = no.
    
end.

/** Integracao Modulo de Recupera¯Êo de Impostos **/
RUN pi-recuperacao-impostos.
run rep/re0402b.p ( rowid(docum-est),
                    l-somente-of,
                    l-cancela-ft,
                    l-desatualiza-ap,
                    output l-erro,
                    input-output table tt-erro ).

if  l-erro then return.
/* Desatualiza Titulo no Contas a Pagar */
if  l-desatualiza-ap and docum-est.ap-atual
and not l-somente-of then
    run rep/re0402d.p ( rowid(docum-est),
                        output l-erro,
                        input-output table tt-erro ).
if  l-erro then return.
/* Executa desatualiza‡Æo CR qdo tiver integra‡Æo com EMS 5, for EMS 2.04 com fun‡Æo espec¡fica, ou EMS 2.06B */
IF   docum-est.cr-atual = YES
AND  l-somente-of = NO
AND (l-acr-ems50 AND l-acr-ems2  AND l-desatualiza-cr) THEN DO:

    RUN pi-desatualiza-cr (OUTPUT l-erro).
    IF  l-erro THEN
        RETURN.
END.
/*********** Desatualizacao do WMS ************/
if l-desatualiza-wms THEN
   run pi-desatualiza-wms.
else do:
   if docum-est.log-2 = yes then do:

        find last tt-erro no-lock no-error.
        assign i-seq-erro = if avail tt-erro
                            then tt-erro.i-sequen + 1
                            else 1.

        create tt-erro.
        assign tt-erro.i-sequen = 1
               tt-erro.cd-erro  = 27401.

        run utp/ut-msgs.p (input 'msg', input 27401, input '').
        assign tt-erro.mensagem = return-value.
    end.
end.

run pi-desatualiza-fretes.
{rep/re0402a.m12}

FIND FIRST param-convrsr-nfe NO-LOCK NO-ERROR.

/* NFe *************************************************************/
IF  CAN-FIND(FIRST funcao WHERE funcao.cd-funcao = "spp-conv-nfe-entrada":U AND funcao.ativo NO-LOCK) THEN DO:
    /* Conversor NFe Entrada */

    IF NOT VALID-HANDLE(h-boin847) 
    OR h-boin847:TYPE      <> "PROCEDURE":U 
    OR h-boin847:FILE-NAME <> "inbo/boin847.p":U THEN
        RUN inbo/boin847.p PERSISTENT SET h-boin847.
    
    DEFINE VARIABLE c-chave-acesso AS CHARACTER   NO-UNDO.

    ASSIGN c-chave-acesso = &if "{&bf_mat_versao_ems}" < "2.07" &then
                                TRIM(substring(docum-est.char-1,93,60))
                            &else
                                docum-est.cod-chave-aces-nf-eletro
                            &endif
                            .

    RUN atualizaSituacao IN h-boin847 (INPUT c-chave-acesso,
                                       INPUT docum-est.cod-emitente,
                                       INPUT docum-est.cod-estabel,
                                       INPUT docum-est.serie-docto,
                                       INPUT docum-est.nro-docto,
                                       INPUT docum-est.nat-operacao,
                                       INPUT 1). /* Situa‡Æo 1: Digitada Receb. Fiscal */
    
    IF  VALID-HANDLE(h-boin847)        AND
        h-boin847:TYPE = "PROCEDURE":U AND
        h-boin847:FILE-NAME = "inbo/boin847.p":U THEN DO:
        DELETE PROCEDURE h-boin847.
        ASSIGN h-boin847 = ?.
    END.                    

    /* Fim conversor NFe Entrada */
END.
/*************************************************************************/


/*NFSe ******************************************************************/

IF AVAIL(param-convrsr-nfe) AND param-convrsr-nfe.log-livre-2 THEN DO:
    IF NOT VALID-HANDLE(h-boin874)
    OR h-boin874:TYPE      <> "PROCEDURE":U
    OR h-boin874:FILE-NAME <> "inbo/boin874.p":U THEN
        RUN inbo/boin874.p PERSISTENT SET h-boin874.

    IF  VALID-HANDLE(h-boin874)        AND
        h-boin874:TYPE = "PROCEDURE":U AND
        h-boin874:FILE-NAME = "inbo/boin874.p":U THEN DO:
    
        RUN atualizaSituacaoPeloDocumento IN h-boin874 (INPUT docum-est.cod-emitente,                                         
                                                        INPUT docum-est.nro-docto,
                                                        INPUT docum-est.serie-docto,
                                                        INPUT docum-est.dt-emissao,
                                                        INPUT 1). /* Situa‡Æo 1: Digitada Receb. Fiscal */
                    
        DELETE PROCEDURE h-boin874.
        ASSIGN h-boin874 = ?.
    END.
END.

/************************************************************************/


/* verifica se o CT-e est  habilitado ***********************************/
IF AVAIL(param-convrsr-nfe) AND param-convrsr-nfe.log-livre-1 THEN DO:

    IF NOT VALID-HANDLE(h-boin871)
    OR h-boin871:TYPE      <> "PROCEDURE":U
    OR h-boin871:FILE-NAME <> "inbo/boin871.p":U THEN
        RUN inbo/boin871.p PERSISTENT SET h-boin871.

    IF  VALID-HANDLE(h-boin871)        AND
        h-boin871:TYPE = "PROCEDURE":U AND
        h-boin871:FILE-NAME = "inbo/boin871.p":U THEN DO:
    
        RUN atualizaSituacao IN h-boin871 (INPUT docum-est.cod-emitente,
                                           INPUT docum-est.cod-estabel,
                                           INPUT docum-est.serie-docto,
                                           INPUT docum-est.nro-docto,
                                           INPUT 1). /* Situa‡Æo 1: Digitada Receb. Fiscal */
    
        DELETE PROCEDURE h-boin871.
        ASSIGN h-boin871 = ?.
    END.
END.
/************************************************************************/

/*** Grava advertencia no documento ***/
if docum-est.log-2 = yes then
    run rep/re9995.p ( input rowid(docum-est),
                       0,
                       0,
                       27401,
                       no,
                       0,
                       2 ).

/******** Chamada EPC no final da atualiza‡Æo *******/
RUN pi-epc-fim-atualizacao.

if return-value = 'NOK' then do:
   assign l-erro = yes.
   return.
end.

/*--- Execucao Orcamentaria EMS 5 - Datasul Financas ---*/
RUN pi-execucao-orcamentaria.

/* Integra‡ao EAI */
&if ('{&ProVers}':U + proversion) >= '009.1D':U &then 
    if  v_log_eai_habilit 
    and l-integra-eai then do: 
        if not valid-handle(h-axssu001) then
            run adapters/xml/su2/axssu001.p persistent set h-axssu001 (output table tt_log_erro).
    
        run PITransUpsert in h-axssu001 ( input  "Undone",
                                          input  "upd":U,
                                          input  rowid(docum-est),
                                          output table tt_log_erro).
       
        for each tt_log_erro:
            run pi-erro-nota (input tt_log_erro.ttv_num_cod_erro,
                              input tt_log_erro.ttv_des_msg_ajuda,
                              input yes).
        end.
    
        if valid-handle(h-axssu001) then do:
            delete procedure h-axssu001.
            assign h-axssu001 = ?.
        end.
    end.
&endif.

IF  VALID-HANDLE(h-acr924za) THEN DO:
    DELETE PROCEDURE h-acr924za.
    ASSIGN h-acr924za = ?.
END.

/******************************************** PROCEDURES INTERNAS ************************************/
{rep/re0402a.i1}     /* Procedure pi-erro-nota */
{cdp/cd4329.i2}      /* Procedure pi-aloca-ordem-cc */
{rep/re0402a.m13}    /* Procedure pi-desatualiza-memorando */
         

IF  VALID-HANDLE(h-ceapi028) THEN DO:
    DELETE PROCEDURE h-ceapi028.
    ASSIGN h-ceapi028 = ?.
END.

IF  VALID-HANDLE(h-ceapi030) THEN DO:
    DELETE PROCEDURE h-ceapi030.
    ASSIGN h-ceapi030 = ?.
END.

if valid-handle(h-boar202155) then do:
    delete procedure h-boar202155.
    assign h-boar202155 = ?.
end.

IF VALID-HANDLE(h-boin01067) THEN DO:
    RUN destroy IN h-boin01067.
    ASSIGN h-boin01067 = ?.
END.

 
PROCEDURE pi-desatualiza-draw:
    if  l-desatualiza-draw AND
     (((not can-find(funcao where funcao.cd-funcao = "spp-drb-sld-terc":U and funcao.ativo))
        and item-doc-est.nr-ato-concessorio <> ""
        and param-global.modulo-07
        and param-global.modulo-ex
        &if "{&bf_dis_versao_ems}":U >= "2.06":U &then
           and b1-natur-oper.log-natur-operac-draw
        &else
           and substring(b1-natur-oper.char-1,94,1) = "1"
        &endif
        and connected ("mgcex":U)) OR
       (i-pais-impto-usuario = 2      /* Argentina */ AND          
        param-global.log-modul-draw    /* Drawback */ AND            
        CAN-FIND(FIRST natur-operac-internac 
                 WHERE natur-operac-internac.cod-natur-operac = docum-est.nat-operacao 
                   AND natur-operac-internac.log-transf-draw) AND
        CAN-FIND (FIRST embarq-import-docto
                  WHERE embarq-import-docto.cod-estab        = docum-est.cod-estabel
                    and embarq-import-docto.cod-embarq       = SUBSTRING(docum-est.char-1,1,20)
                    and embarq-import-docto.cod-ser-docto    = docum-est.serie-docto
                    and embarq-import-docto.cod-docto        = docum-est.nro-docto
                    and embarq-import-docto.cdn-emitente     = docum-est.cod-emitente
                    and embarq-import-docto.cod-natur-operac = docum-est.nat-operacao
                    and embarq-import-docto.log-transf-draw))) /* Transferˆncia Drawback */ then do:

        if  not valid-handle (h-bocx332) then
            run cxbo/bocx332.p persistent set h-bocx332.
        run eliminaMovtos in h-bocx332 (input  rowid(item-doc-est),
                                        input  yes,  /** Elimina Movtos**/
                                        input  yes,  /** Desatualizacao Documentos **/
                                        output table RowErrors).
        if  can-find (first RowErrors) then do:
            for each RowErrors:
                find last tt-erro no-error.
                if  avail tt-erro then
                    assign i-seq-erro = tt-erro.i-sequen + 1.
                ELSE
                    assign i-seq-erro = 1.

                create tt-erro.
                assign tt-erro.i-sequen = i-seq-erro
                       tt-erro.cd-erro  = RowErrors.errorNumber
                       tt-erro.mensagem = RowErrors.errorDescription.
            end.
            assign l-erro = yes.
        end.
        if  valid-handle (h-bocx332) then do:
            delete procedure h-bocx332.
            assign h-bocx332 = ?.
        end.
    end.
END PROCEDURE.

procedure pi-desatualiza-cp:
    find ord-prod
        where ord-prod.nr-ord-prod = item-doc-est.nr-ord-prod no-lock no-error.
    if  avail ord-prod then do:

/*         COMENTADO CONFORME FO 1814.495 - SOPRANO                             */
/*         &IF DEFINED (bf_man_linha_estab) &THEN                               */
/*         find lin-prod                                                        */
/*             where lin-prod.cod-estabel = ord-prod.cod-estabel                */
/*               and lin-prod.nr-linha    = ord-prod.nr-linha no-lock no-error. */
/*         &ELSE                                                                */
/*         find lin-prod                                                        */
/*             where lin-prod.nr-linha = ord-prod.nr-linha no-lock no-error.    */
/*         &ENDIF                                                               */
/*                                                                              */
/*         IF AVAIL lin-prod THEN DO:                                           */
/*             if  lin-prod.sum-requis = 2 then do:                             */

        {cdp/cd9010.i5 item-doc-est.nr-ord-prod
                       item-doc-est.item-pai
                       item-doc-est.cod-roteiro
                       item-doc-est.op-codigo
                       item-doc-est.it-codigo
                       item-doc-est.quantidade}

        if  not l-erro-cp then do:
            run pi-erro-nota ( 6301, " ", no ).
            assign l-erro-cp = yes.

            run rep/re9995.p ( input rowid(docum-est),
                               0,
                               0,
                               6301,
                               no,
                               item-doc-est.sequencia,
                               2 ).                     /* Advertˆncia */
        end.
    end.
end.

procedure pi-desatualiza-cc:
    {rep/re0402.i}
    delete recebimento.
end.

procedure pi-desatualiza-cq:
    for each rat-lote {cdp/cd8900.i rat-lote item-doc-est}
         and rat-lote.sequencia = item-doc-est.sequencia exclusive-lock:

        ASSIGN i-num-lote =  i-num-lote + 1.

        for each lote-compr use-index nr-nota
           where lote-compr.cod-emitente = rat-lote.cod-emitente
             and lote-compr.serie-nf     = rat-lote.serie-docto
             and lote-compr.nr-nota-fis  = rat-lote.nro-docto
             and lote-compr.it-codigo    = rat-lote.it-codigo
             and lote-compr.lote         = rat-lote.lote exclusive-lock:

            if lote-compr.qtd-recebida >= rat-lote.quantidade
            then assign lote-compr.qtd-recebida = lote-compr.qtd-recebida
                                                  - rat-lote.quantidade.
            else assign lote-compr.qtd-recebida = 0.

           if  lote-compr.qtd-recebida = 0
           and lote-compr.qtd-devolvida = 0 then
               delete lote-compr.
        end.

        /*******   Atualiza‡Æo do RMA.  *******/
        RUN pi-atualiza-rma.

        find ficha-cq
            where ficha-cq.nr-ficha = rat-lote.nr-ficha exclusive-lock no-error.
        if  avail ficha-cq then do:

            /* valida se ha alguma ficha do documento fisico com item no wms com saldo cq-armazenado
               e nao permitir  a desatualizacao */

            /* Integracao WMS */
            if avail param-estoq and substring(param-estoq.char-2,6,1) = "1" then do:
                /*Valida se deposito est  integrado com o WMS ou vinculado a um deposito wms*/
                run scbo/bosc047.p persistent set hDBOSC047.
                run validaDepositoIntegraWMS in hDBOSC047 (input docum-est.cod-estabel, /*Estabelecimento*/   
                                                           input rat-lote.cod-depos).    /*Deposito*/          
                if return-value = "OK" then do:
                    /*valida se ha alguma ficha do documento fisico com item no WMS com saldo cq-armazenado
                      e nao permitir  a desatualizacao*/
                    run scbo/bosc138.p persistent set hDBOSC138.
                    run validaRoteiroPendenteMovtoConcluido in hDBOSC138 (input docum-est.cod-estabel,  /*Estabelecimento*/
                                                                          input rat-lote.cod-depos,     /*Deposito*/
                                                                          input ficha-cq.nr-ficha).     /*Ficha*/
                    if return-value = "NOK" then do:
                        /*Nao pode prosseguir*/    
                        create tt-erro.
                        /* Inicio -- Projeto Internacional */
                        DEFINE VARIABLE c-lbl-liter-roteiro AS CHARACTER NO-UNDO.
                        {utp/ut-liter.i "Roteiro" *}
                        ASSIGN c-lbl-liter-roteiro = TRIM(RETURN-VALUE).
                        DEFINE VARIABLE c-lbl-liter-possui-documento-wms-com-pende AS CHARACTER NO-UNDO.
                        {utp/ut-liter.i "possui_documento_WMS_com_pendˆncia_CQ-Armazenado,_necess rio_realizar_a_inspe‡Æo" *}
                        ASSIGN c-lbl-liter-possui-documento-wms-com-pende = TRIM(RETURN-VALUE).
                        assign tt-erro.i-sequen = 1
                               tt-erro.cd-erro  = 17006
                               tt-erro.mensagem = c-lbl-liter-roteiro + " " + string(ficha-cq.nr-ficha) + " " + c-lbl-liter-possui-documento-wms-com-pende + "!".
                        run rep/re9995.p ( input rowid(docum-est),
                                           0,
                                           0,
                                           17006,
                                           no,
                                           item-doc-est.sequencia,
                                           1 ).                     /* Erro */
    
                        assign l-erro = yes.
                    end.
                end.
                IF VALID-HANDLE(hDBOSC047) THEN
                    run destroy in hDBOSC047.
                IF VALID-HANDLE(hDBOSC138) THEN
                    run destroy in hDBOSC138.
            end.

            if  ficha-cq.qt-aprovada  + ficha-cq.qt-consumida
              + ficha-cq.qt-rejeitada + ficha-cq.qt-apr-cond > 0 then
                assign item-doc-est.nr-ficha = rat-lote.nr-ficha.
            else do:
                /* Integra‡Æo WMS */
                IF AVAIL param-estoq AND SUBSTRING(param-estoq.char-2,6,1) = "1" THEN
                    RUN wmp/wm9003.p (INPUT docum-est.cod-estabel,
                                      INPUT ROWID(rat-lote)).
                assign rat-lote.nr-ficha = 0.
                for each exam-ficha
                    where exam-ficha.nr-ficha = ficha-cq.nr-ficha exclusive-lock:
                    delete exam-ficha.
                end.
                delete ficha-cq.
            end.
        end.
    end.

    find ficha-cq
        where ficha-cq.nr-ficha = item-doc-est.nr-ficha exclusive-lock no-error.
    if  avail ficha-cq then do:
        if  ficha-cq.qt-aprovada  + ficha-cq.qt-consumida
          + ficha-cq.qt-rejeitada + ficha-cq.qt-apr-cond > 0 then do:
            run pi-erro-nota ( 6336, " ", no ).
            run rep/re9995.p ( input rowid(docum-est),
                               0,
                               0,
                               6336,
                               no,
                               item-doc-est.sequencia,
                               2 ).                     /* Advertˆncia */
        end.
        else do:
            for each exam-ficha
                where exam-ficha.nr-ficha = ficha-cq.nr-ficha exclusive-lock:
                delete exam-ficha.
            end.
            delete ficha-cq.
            assign item-doc-est.nr-ficha = 0.
        end.
    end.
    else
        assign item-doc-est.nr-ficha = 0.
end.

procedure pi-desatualiza-cq-antecipado:
    for each rat-lote {cdp/cd8900.i rat-lote item-doc-est}
         and rat-lote.sequencia = item-doc-est.sequencia exclusive-lock:

        FIND FIRST ficha-cq EXCLUSIVE-LOCK
             WHERE ficha-cq.idi-orig-restdo = 2
               AND ficha-cq.nr-ficha = rat-lote.nr-ficha NO-ERROR.
        IF AVAIL ficha-cq AND NOT ficha-cq.log-com-nota THEN DO:

            ASSIGN ficha-cq.serie-docto  = "" 
                   ficha-cq.nro-docto    = ""
                   ficha-cq.cod-emitente = 0
                   ficha-cq.nat-operacao = ""
                   ficha-cq.dat-emis-nf  = ?.
        END.
    end.
end.

procedure pi-desatualiza-terceiros:

    DEF VAR lDevSimbConsig   AS LOGICAL NO-UNDO.
    DEF VAR lNfDevSimbConsig AS LOGICAL NO-UNDO.
    DEF VAR h-boin404        AS HANDLE  NO-UNDO.

    FIND bf-natur-oper-fut WHERE
         bf-natur-oper-fut.nat-operacao = item-doc-est.nat-operacao NO-LOCK NO-ERROR.

    {cdp/cd9700.i1 bf-natur-oper-fut}
    /*--- quando for desatualizacao de fatura de entrega futura, primeiro tem que desatualizar
          as remessas dessa fatura ---*/

    IF  l-fatura-ent-futura THEN DO:
        FOR EACH  saldo-terc
            WHERE saldo-terc.nro-docto    = item-doc-est.nro-docto
              AND saldo-terc.nat-operacao = item-doc-est.nat-comp
              AND saldo-terc.cod-emitente = item-doc-est.cod-emitente
              AND saldo-terc.serie-docto  = item-doc-est.serie-docto
              AND saldo-terc.sequencia    = item-doc-est.sequencia NO-LOCK:
    
            FOR EACH  componente 
                WHERE componente.nro-comp     = saldo-terc.nro-docto
                  AND componente.nat-comp     = saldo-terc.nat-operacao 
                  AND componente.serie-comp   = saldo-terc.serie-docto 
                  AND componente.cod-emitente = saldo-terc.cod-emitente
                  AND componente.seq-comp     = saldo-terc.sequencia NO-LOCK:
                
                FIND bf-natur-oper-fut WHERE
                     bf-natur-oper-fut.nat-operacao = componente.nat-operacao NO-LOCK NO-ERROR.

                IF  AVAIL bf-natur-oper-fut THEN DO:

                    /*--- verifica se docum-est eh de nota de fatura faturamento ou fatura entrega futura ---*/
                    {cdp/cd9700.i1 bf-natur-oper-fut}
                
                    IF  l-remessa-ent-futura THEN DO:
                        FIND bf-docum-est-fut WHERE
                             bf-docum-est-fut.nro-docto = componente.nro-docto AND
                             bf-docum-est-fut.nat-operacao = componente.nat-operacao AND
                             bf-docum-est-fut.cod-emitente = componente.cod-emitente AND
                             bf-docum-est-fut.serie-docto  = componente.serie-docto NO-LOCK NO-ERROR.

                        IF  AVAIL bf-docum-est-fut
                        AND bf-docum-est-fut.ce-atual = YES THEN DO:
                            FIND LAST tt-erro NO-LOCK NO-ERROR.
                            ASSIGN i-seq-erro = IF AVAIL tt-erro
                                                THEN tt-erro.i-sequen + 1
                                                ELSE 1.

                            /*--- nao permite desatualizar a NF de fatura se houver 
                                  NF de remessa atualizada ---*/
                            CREATE tt-erro.
                            ASSIGN tt-erro.i-sequen = i-seq-erro
                                   tt-erro.cd-erro  = 17006.
            
                            /* Inicio -- Projeto Internacional */
                            DEFINE VARIABLE c-lbl-liter-antes-deve-ser-desatualizada-a AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "Antes_deve_ser_desatualizada_a_NF_de_Remessa" *}
                            ASSIGN c-lbl-liter-antes-deve-ser-desatualizada-a = TRIM(RETURN-VALUE).
                            DEFINE VARIABLE c-lbl-liter-nr AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "Nr" *}
                            ASSIGN c-lbl-liter-nr = TRIM(RETURN-VALUE).
                            DEFINE VARIABLE c-lbl-liter-emit AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "/_Emit" *}
                            ASSIGN c-lbl-liter-emit = TRIM(RETURN-VALUE).
                            DEFINE VARIABLE c-lbl-liter-serie AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "/_S‚rie" *}
                            ASSIGN c-lbl-liter-serie = TRIM(RETURN-VALUE).
                            DEFINE VARIABLE c-lbl-liter-nat-oper AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "/_Nat_Oper" *}
                            ASSIGN c-lbl-liter-nat-oper = TRIM(RETURN-VALUE).
                            RUN utp/ut-msgs.p (INPUT "msg", INPUT 17006, INPUT c-lbl-liter-antes-deve-ser-desatualizada-a + ": " +
                                                                               chr(13) + 
                                                                               " " + c-lbl-liter-nr + ": "       + bf-docum-est-fut.nro-docto +
                                                                               " " + c-lbl-liter-emit + ": "     + STRING(bf-docum-est-fut.cod-emitente) +
                                                                               " " + c-lbl-liter-serie + ": "    + bf-docum-est-fut.serie-docto +
                                                                               " " + c-lbl-liter-nat-oper + ": " + bf-docum-est-fut.nat-operacao ).
                            ASSIGN tt-erro.mensagem = RETURN-VALUE.

                            ASSIGN l-erro = YES.
                        END.
                    END.
                END.    
            END. /* FOR EACH componente... */


            FOR EACH bf-item-doc-est-fut
                WHERE bf-item-doc-est-fut.nro-comp     = saldo-terc.nro-docto
                  AND bf-item-doc-est-fut.nat-comp     = saldo-terc.nat-operacao
                  AND bf-item-doc-est-fut.serie-comp   = saldo-terc.serie-docto
                  AND bf-item-doc-est-fut.cod-emitente = saldo-terc.cod-emitente
                  AND bf-item-doc-est-fut.seq-comp     = saldo-terc.sequencia NO-LOCK:
        
                FIND bf-natur-oper-fut WHERE
                     bf-natur-oper-fut.nat-operacao = bf-item-doc-est-fut.nat-operacao NO-LOCK NO-ERROR.

                IF  AVAIL bf-natur-oper-fut THEN DO:

                    /*--- verifica se docum-est eh de nota de fatura faturamento ou fatura entrega futura ---*/
                    {cdp/cd9700.i1 bf-natur-oper-fut}
                
                    IF  l-remessa-ent-futura THEN DO:

                        FIND bf-docum-est-fut WHERE
                             bf-docum-est-fut.nro-docto    = bf-item-doc-est-fut.nro-docto AND
                             bf-docum-est-fut.nat-operacao = bf-item-doc-est-fut.nat-operacao AND
                             bf-docum-est-fut.cod-emitente = bf-item-doc-est-fut.cod-emitente AND
                             bf-docum-est-fut.serie-docto  = bf-item-doc-est-fut.serie-docto AND 
                             bf-docum-est-fut.ce-atual     = NO NO-LOCK NO-ERROR.

                        IF  AVAIL bf-docum-est-fut THEN DO:
                            FIND LAST tt-erro NO-LOCK NO-ERROR.
                            ASSIGN i-seq-erro = IF AVAIL tt-erro
                                                THEN tt-erro.i-sequen + 1
                                                ELSE 1.
                            /*--- nao permite desatualiza a NF de fatura se houver NF de remessa
                                  digitada, tem que eliminar a remessa porque senao corre-se o 
                                  risco do usuario atualizar a remessa antes da fatura ---*/
                            CREATE tt-erro.
                            ASSIGN tt-erro.i-sequen = i-seq-erro
                                   tt-erro.cd-erro  = 17006.
            
                            /* Inicio -- Projeto Internacional */
                            DEFINE VARIABLE c-lbl-liter-a-nf-de-remessa-deve-ser-elimi AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "A_NF_de_Remessa_deve_ser_eliminada" *}
                            ASSIGN c-lbl-liter-a-nf-de-remessa-deve-ser-elimi = TRIM(RETURN-VALUE).
                            DEFINE VARIABLE c-lbl-liter-nr-2 AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "Nr" *}
                            ASSIGN c-lbl-liter-nr-2 = TRIM(RETURN-VALUE).
                            DEFINE VARIABLE c-lbl-liter-emit-2 AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "/_Emit" *}
                            ASSIGN c-lbl-liter-emit-2 = TRIM(RETURN-VALUE).
                            DEFINE VARIABLE c-lbl-liter-serie-2 AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "/_S‚rie" *}
                            ASSIGN c-lbl-liter-serie-2 = TRIM(RETURN-VALUE).
                            DEFINE VARIABLE c-lbl-liter-nat-oper-2 AS CHARACTER NO-UNDO.
                            {utp/ut-liter.i "/_Nat_Oper" *}
                            ASSIGN c-lbl-liter-nat-oper-2 = TRIM(RETURN-VALUE).
                            RUN utp/ut-msgs.p (INPUT "msg", INPUT 17006, INPUT c-lbl-liter-a-nf-de-remessa-deve-ser-elimi + ": " +
                                                                               chr(13) + 
                                                                               " " + c-lbl-liter-nr-2 + ": "       + bf-docum-est-fut.nro-docto +
                                                                               " " + c-lbl-liter-emit-2 + ": "     + STRING(bf-docum-est-fut.cod-emitente) +
                                                                               " " + c-lbl-liter-serie-2 + ": "    + bf-docum-est-fut.serie-docto +
                                                                               " " + c-lbl-liter-nat-oper-2 + ": " + bf-docum-est-fut.nat-operacao ).
                            ASSIGN tt-erro.mensagem = RETURN-VALUE.
                            ASSIGN l-erro = YES.
                        END.
                    END.
                END.    
            END. /* FOR EACH bf-item-doc-est-fut */
        END. /* FOR EACH saldo-terc */
        
        IF l-erro THEN RETURN "NOK":U.
    END. /* IF l-fatura-ent-futura */ 
    ELSE IF  l-fatura-fat-antecip THEN DO:

        /*--- somente permite desatualizar a nota de fatura se 
              as outras notas tambem estao desatualizadas ---*/
        FOR FIRST sdo-fatur-antecip FIELDS(num-id-sdo nr-nota-fis serie cod-emitente num-id-sdo)
            WHERE sdo-fatur-antecip.cod-emitente = item-doc-est.cod-emitente
              AND sdo-fatur-antecip.cod-estabel  = docum-est.cod-estabel
              AND sdo-fatur-antecip.nr-nota-fis  = item-doc-est.nro-docto
              AND sdo-fatur-antecip.serie        = item-doc-est.serie-docto
              AND sdo-fatur-antecip.it-codigo    = item-doc-est.it-codigo
              AND sdo-fatur-antecip.cod-refer    = item-doc-est.cod-refer
              AND sdo-fatur-antecip.num-seq      = item-doc-est.sequencia NO-LOCK: END.

        IF  AVAIL sdo-fatur-antecip THEN DO:

            FOR EACH movto-fatur-antecip FIELDS (nr-nota-fis nat-operacao
                                                 cod-emitente serie idi-det-trans)
                WHERE movto-fatur-antecip.num-id-sdo = sdo-fatur-antecip.num-id-sdo
                  AND (   movto-fatur-antecip.idi-det-trans = 8 /* recebimento de remessa */
                       OR movto-fatur-antecip.idi-det-trans = 9 /* devolucao de fatura */
                       OR movto-fatur-antecip.idi-det-trans = 10 /* devolucao de remessa */ ) NO-LOCK: 
                
                FOR FIRST bf-docum-est-fut FIELDS(nro-docto   nat-operacao
                                                  cod-emitente serie-docto ce-atual)  
                    WHERE bf-docum-est-fut.nro-docto    = movto-fatur-antecip.nr-nota-fis 
                      AND bf-docum-est-fut.nat-operacao = movto-fatur-antecip.nat-operacao 
                      AND bf-docum-est-fut.cod-emitente = movto-fatur-antecip.cod-emitente 
                      AND bf-docum-est-fut.serie-docto  = movto-fatur-antecip.serie NO-LOCK: END.

                IF  AVAIL bf-docum-est-fut THEN DO:
                    FIND LAST tt-erro NO-LOCK NO-ERROR.
                    ASSIGN i-seq-erro = IF AVAIL tt-erro
                                        THEN tt-erro.i-sequen + 1
                                        ELSE 1.

                    /*--- nao permite desatualizar a NF de fatura se houver 
                          NF de remessa atualizada ---*/
                    CREATE tt-erro.
                    ASSIGN tt-erro.i-sequen = i-seq-erro
                           tt-erro.cd-erro  = 17006.

                    IF  bf-docum-est-fut.ce-atual THEN DO:
                        IF  movto-fatur-antecip.idi-det-trans = 8 /* recebimento de remessa */ THEN
                            ASSIGN c-texto-ent-fut = "Antes deve ser desatualizada a NF de Remessa: ".
                        ELSE
                            ASSIGN c-texto-ent-fut = "Antes deve ser desatualizada a NF de Devolucao de remessa: ".
                    END.
                    ELSE DO:
                        IF  movto-fatur-antecip.idi-det-trans = 8 /* recebimento de remessa */ THEN
                            ASSIGN c-texto-ent-fut = "Antes deve ser eliminada a NF de Remessa: ".
                        ELSE
                            ASSIGN c-texto-ent-fut = "Antes deve ser eliminada a NF de Devolucao de remessa: ".
                    END.

                    /* Inicio -- Projeto Internacional */
                    DEFINE VARIABLE c-lbl-liter-nr-3 AS CHARACTER NO-UNDO.
                    {utp/ut-liter.i "Nr" *}
                    ASSIGN c-lbl-liter-nr-3 = TRIM(RETURN-VALUE).
                    DEFINE VARIABLE c-lbl-liter-emit-3 AS CHARACTER NO-UNDO.
                    {utp/ut-liter.i "/_Emit" *}
                    ASSIGN c-lbl-liter-emit-3 = TRIM(RETURN-VALUE).
                    DEFINE VARIABLE c-lbl-liter-serie-3 AS CHARACTER NO-UNDO.
                    {utp/ut-liter.i "/_S‚rie" *}
                    ASSIGN c-lbl-liter-serie-3 = TRIM(RETURN-VALUE).
                    DEFINE VARIABLE c-lbl-liter-nat-oper-3 AS CHARACTER NO-UNDO.
                    {utp/ut-liter.i "/_Nat_Oper" *}
                    ASSIGN c-lbl-liter-nat-oper-3 = TRIM(RETURN-VALUE).
                    RUN utp/ut-msgs.p (INPUT "msg", INPUT 17006, INPUT c-texto-ent-fut + 
                                                                       " " + c-lbl-liter-nr-3 + ": "         + bf-docum-est-fut.nro-docto +
                                                                       " " + c-lbl-liter-emit-3 + ": "     + STRING(bf-docum-est-fut.cod-emitente) +
                                                                       " " + c-lbl-liter-serie-3 + ": "    + bf-docum-est-fut.serie-docto +
                                                                       " " + c-lbl-liter-nat-oper-3 + ": " + bf-docum-est-fut.nat-operacao ).
                    ASSIGN tt-erro.mensagem = RETURN-VALUE.

                    ASSIGN l-erro = YES.
                END.

            END. /* FOR EACH movto-fatur-antecip */
            
            FOR EACH bf-item-doc-est-fut
               WHERE bf-item-doc-est-fut.nro-comp     = sdo-fatur-antecip.nr-nota-fis
                 AND bf-item-doc-est-fut.nat-comp     = ""
                 AND bf-item-doc-est-fut.serie-comp   = sdo-fatur-antecip.serie
                 AND bf-item-doc-est-fut.cod-emitente = sdo-fatur-antecip.cod-emitente
                 AND bf-item-doc-est-fut.seq-comp     = sdo-fatur-antecip.num-id-sdo NO-LOCK: 

               FIND bf-docum-est-fut WHERE
                    bf-docum-est-fut.nro-docto    = bf-item-doc-est-fut.nro-docto AND
                    bf-docum-est-fut.nat-operacao = bf-item-doc-est-fut.nat-operacao AND
                    bf-docum-est-fut.cod-emitente = bf-item-doc-est-fut.cod-emitente AND
                    bf-docum-est-fut.serie-docto  = bf-item-doc-est-fut.serie-docto AND 
                    bf-docum-est-fut.ce-atual     = NO NO-LOCK NO-ERROR.

               IF  AVAIL bf-docum-est-fut THEN DO:
                   FIND LAST tt-erro NO-LOCK NO-ERROR.
                   ASSIGN i-seq-erro = IF AVAIL tt-erro
                                       THEN tt-erro.i-sequen + 1
                                       ELSE 1.
                   /*--- nao permite desatualiza a NF de fatura se houver NF de remessa
                         digitada, tem que eliminar a remessa porque senao corre-se o 
                         risco do usuario atualizar a remessa antes da fatura ---*/
                   CREATE tt-erro.
                   ASSIGN tt-erro.i-sequen = i-seq-erro
                          tt-erro.cd-erro  = 17006.
                          
                   /* Inicio -- Projeto Internacional */
                   DEFINE VARIABLE c-lbl-liter-a-nf-de-remessa-deve-ser-elimi-2 AS CHARACTER NO-UNDO.
                   {utp/ut-liter.i "A_NF_de_Remessa_deve_ser_eliminada" *}
                   ASSIGN c-lbl-liter-a-nf-de-remessa-deve-ser-elimi-2 = TRIM(RETURN-VALUE).
                   DEFINE VARIABLE c-lbl-liter-nr-4 AS CHARACTER NO-UNDO.
                   {utp/ut-liter.i "Nr" *}
                   ASSIGN c-lbl-liter-nr-4 = TRIM(RETURN-VALUE).
                   DEFINE VARIABLE c-lbl-liter-emit-4 AS CHARACTER NO-UNDO.
                   {utp/ut-liter.i "/_Emit" *}
                   ASSIGN c-lbl-liter-emit-4 = TRIM(RETURN-VALUE).
                   DEFINE VARIABLE c-lbl-liter-serie-4 AS CHARACTER NO-UNDO.
                   {utp/ut-liter.i "/_S‚rie" *}
                   ASSIGN c-lbl-liter-serie-4 = TRIM(RETURN-VALUE).
                   DEFINE VARIABLE c-lbl-liter-nat-oper-4 AS CHARACTER NO-UNDO.
                   {utp/ut-liter.i "/_Nat_Oper" *}
                   ASSIGN c-lbl-liter-nat-oper-4 = TRIM(RETURN-VALUE).
                   RUN utp/ut-msgs.p (INPUT "msg", INPUT 17006, INPUT c-lbl-liter-a-nf-de-remessa-deve-ser-elimi-2 + ": " + chr(13) + 
                                                                      " " + c-lbl-liter-nr-4 + ": "         + bf-docum-est-fut.nro-docto +
                                                                      " " + c-lbl-liter-emit-4 + ": "     + STRING(bf-docum-est-fut.cod-emitente) +
                                                                      " " + c-lbl-liter-serie-4 + ": "    + bf-docum-est-fut.serie-docto +
                                                                      " " + c-lbl-liter-nat-oper-4 + ": " + bf-docum-est-fut.nat-operacao ).
                   ASSIGN tt-erro.mensagem = RETURN-VALUE.
                   ASSIGN l-erro = YES.
               END. 
            END.       
        END. /* IF  AVAIL sdo-fatur-antecip */
        IF l-erro THEN RETURN "NOK".
    END. /* ELSE IF  l-fatura-fat-antecip THEN DO */
    ELSE IF l-remessa-fat-antecip THEN DO:

        /*--- nao permite desatualizar a remessa se houver devolucao de remesa atualizada ---*/
        FOR EACH  bf-movto-fatur-antecip-fut FIELDS(num-id-sdo)
            WHERE bf-movto-fatur-antecip-fut.nr-nota-fis   = item-doc-est.nro-docto
              AND bf-movto-fatur-antecip-fut.cod-emitente  = item-doc-est.cod-emitente
              AND bf-movto-fatur-antecip-fut.serie         = item-doc-est.serie-docto
              AND bf-movto-fatur-antecip-fut.nat-operacao  = item-doc-est.nat-operacao
              AND bf-movto-fatur-antecip-fut.idi-det-trans = 8 /* recebimento de remessa */ NO-LOCK:

            FOR EACH movto-fatur-antecip FIELDS (nr-nota-fis nat-operacao
                                                 cod-emitente serie idi-det-trans)
                WHERE movto-fatur-antecip.num-id-sdo    = bf-movto-fatur-antecip-fut.num-id-sdo
                  AND movto-fatur-antecip.idi-det-trans = 10 /* devolucao de remessa */ NO-LOCK: 
                
                FOR FIRST bf-docum-est-fut FIELDS(nro-docto   nat-operacao
                                                  cod-emitente serie-docto ce-atual)  
                    WHERE bf-docum-est-fut.nro-docto    = movto-fatur-antecip.nr-nota-fis 
                      AND bf-docum-est-fut.nat-operacao = movto-fatur-antecip.nat-operacao 
                      AND bf-docum-est-fut.cod-emitente = movto-fatur-antecip.cod-emitente 
                      AND bf-docum-est-fut.serie-docto  = movto-fatur-antecip.serie 
                      AND bf-docum-est-fut.ce-atual     = YES NO-LOCK: END.

                IF  AVAIL bf-docum-est-fut THEN DO:
                    FIND LAST tt-erro NO-LOCK NO-ERROR.
                    ASSIGN i-seq-erro = IF AVAIL tt-erro
                                        THEN tt-erro.i-sequen + 1
                                        ELSE 1.

                    /*--- nao permite desatualizar a NF de fatura se houver 
                          NF de remessa atualizada ---*/
                    CREATE tt-erro.
                    ASSIGN tt-erro.i-sequen = i-seq-erro
                           tt-erro.cd-erro  = 17006.
    
                    /* Inicio -- Projeto Internacional */
                    DEFINE VARIABLE c-lbl-liter-antes-deve-ser-desatualizada-a-2 AS CHARACTER NO-UNDO.
                    {utp/ut-liter.i "Antes_deve_ser_desatualizada_a_NF_de_Devolucao_de_remessa" *}
                    ASSIGN c-lbl-liter-antes-deve-ser-desatualizada-a-2 = TRIM(RETURN-VALUE).
                    DEFINE VARIABLE c-lbl-liter-nr-5 AS CHARACTER NO-UNDO.
                    {utp/ut-liter.i "Nr" *}
                    ASSIGN c-lbl-liter-nr-5 = TRIM(RETURN-VALUE).
                    DEFINE VARIABLE c-lbl-liter-emit-5 AS CHARACTER NO-UNDO.
                    {utp/ut-liter.i "/_Emit" *}
                    ASSIGN c-lbl-liter-emit-5 = TRIM(RETURN-VALUE).
                    DEFINE VARIABLE c-lbl-liter-serie-5 AS CHARACTER NO-UNDO.
                    {utp/ut-liter.i "/_S‚rie" *}
                    ASSIGN c-lbl-liter-serie-5 = TRIM(RETURN-VALUE).
                    DEFINE VARIABLE c-lbl-liter-nat-oper-5 AS CHARACTER NO-UNDO.
                    {utp/ut-liter.i "/_Nat_Oper" *}
                    ASSIGN c-lbl-liter-nat-oper-5 = TRIM(RETURN-VALUE).
                    RUN utp/ut-msgs.p (INPUT "msg", INPUT 17006, INPUT c-lbl-liter-antes-deve-ser-desatualizada-a-2 + ": "
                                                                       + chr(13) + 
                                                                       " " + c-lbl-liter-nr-5 + ": "         + bf-docum-est-fut.nro-docto +
                                                                       " " + c-lbl-liter-emit-5 + ": "     + STRING(bf-docum-est-fut.cod-emitente) +
                                                                       " " + c-lbl-liter-serie-5 + ": "    + bf-docum-est-fut.serie-docto +
                                                                       " " + c-lbl-liter-nat-oper-5 + ": " + bf-docum-est-fut.nat-operacao ).
                    ASSIGN tt-erro.mensagem = RETURN-VALUE.

                    ASSIGN l-erro = YES.
                END.

            END. /* FOR EACH movto-fatur-antecip */

        END. /* FOR EACH  bf-movto-fatur-antecip-fut */
        
        IF l-erro THEN RETURN "NOK".
        
    END. 

	IF  l-fatura-ent-futura THEN DO:		        
        FIND FIRST bf-natur-oper-fut 
             WHERE bf-natur-oper-fut.nat-operacao = docum-est.nat-operacao NO-LOCK NO-ERROR.
         
        IF AVAIL bf-natur-oper-fut AND bf-natur-oper-fut.tipo-compra = 3 THEN DO: /* Devolução */   
    		FOR FIRST nota-fiscal
    			WHERE nota-fiscal.nr-nota-fis = item-doc-est.nro-comp
    			  AND nota-fiscal.serie       = item-doc-est.serie-comp 
    			  AND nota-fiscal.cod-estabel = docum-est.cod-estabel NO-LOCK:			      
    			FOR FIRST bf-natur-oper-fut 
    				WHERE bf-natur-oper-fut.nat-operacao = nota-fiscal.nat-operacao NO-LOCK:				    
    				/*** localiza o componente da nota de fatura para encontrar a saldo-terc ***/			
    				FOR EACH bf-componente 
    					WHERE bf-componente.nro-docto     = item-doc-est.nro-comp
    					  AND bf-componente.nat-operacao  = bf-natur-oper-fut.nat-comp
    					  AND bf-componente.cod-emitente  = item-doc-est.cod-emitente
    					  AND bf-componente.serie-docto   = item-doc-est.serie-comp
    					  AND bf-componente.sequencia     = item-doc-est.seq-comp    NO-LOCK:					      
    					/*** Localiza a saldo-terc para atualizacao do saldo ***/
    					FOR FIRST saldo-terc
    						WHERE saldo-terc.nro-docto    = bf-componente.nro-docto   				  
    						  AND saldo-terc.cod-emitente = bf-componente.cod-emitente
    						  AND saldo-terc.serie-docto  = bf-componente.serie-docto 
    						  AND saldo-terc.sequencia    = bf-componente.sequencia   EXCLUSIVE-LOCK:					                            
                             /*** Localiza o componente criado pela nota de devolucao da fatura 
                                 e atualiza o saldo-ter com base na quantidade deste componente ***/   
                            /*Busca naturaeza para encontrar a nat. complementar da nota de devolução*/  
                            FIND FIRST b-natur-dev-fat-ent-fut    
                                 WHERE b-natur-dev-fat-ent-fut.nat-operacao = item-doc-est.nat-operacao NO-LOCK NO-ERROR.    
                                  
    						FOR EACH  componente 
    							WHERE componente.nro-docto     =  item-doc-est.nro-docto              
    							  AND componente.nat-operacao  =  b-natur-dev-fat-ent-fut.nat-comp  
    							  AND componente.cod-emitente  =  item-doc-est.cod-emitente 
    							  AND componente.serie-docto   =  item-doc-est.serie-docto 
    							  AND componente.sequencia     =  item-doc-est.sequencia     EXCLUSIVE-LOCK:		
    							      
    							ASSIGN saldo-terc.quantidade = saldo-terc.quantidade + componente.quantidade
    								   saldo-terc.dec-1      = saldo-terc.dec-1      + item-doc-est.quantidade.						
    							DELETE componente.
    						END.	
    						
    						FOR EACH rat-componente 
                               WHERE rat-componente.serie-docto  = item-doc-est.serie-docto
                                 AND rat-componente.nro-docto    = item-doc-est.nro-docto
                                 AND rat-componente.cod-emitente = item-doc-est.cod-emitente     
                                 AND rat-componente.nat-operacao = b-natur-dev-fat-ent-fut.nat-comp EXCLUSIVE-LOCK:                            
                                  FOR FIRST rat-saldo-terc 
                                      WHERE rat-saldo-terc.serie-docto  = bf-componente.serie-docto
                                        AND rat-saldo-terc.nro-docto    = bf-componente.nro-docto
                                        AND rat-saldo-terc.cod-emitente = bf-componente.cod-emitente
                                        AND rat-saldo-terc.nat-operacao = bf-componente.nat-operacao  
                                        AND rat-saldo-terc.it-codigo    = rat-componente.it-codigo
                                        AND rat-saldo-terc.cod-refer    = rat-componente.cod-refer
                                        AND rat-saldo-terc.sequencia    = rat-componente.seq-comp
                                        AND rat-saldo-terc.lote         = rat-componente.lote EXCLUSIVE-LOCK:
                                        ASSIGN rat-saldo-terc.quantidade     = rat-saldo-terc.quantidade + rat-componente.quantidade
                                               rat-saldo-terc.qtd-aloc-trans = rat-saldo-terc.qtd-aloc-trans  + rat-componente.quantidade.
                                  END.         
                          
                                  DELETE rat-componente.
                            END.					
    				    END.						
    			    END.					
    	        END.			
    	    END.		
	    end. 
	    else do:
           FIND FIRST bf-natur-oper-fut 
                WHERE bf-natur-oper-fut.nat-operacao = docum-est.nat-operacao NO-LOCK NO-ERROR.
                    
                IF AVAIL bf-natur-oper-fut THEN DO:                   
                    FOR FIRST bf-natur-oper-fut 
                        WHERE bf-natur-oper-fut.nat-operacao = docum-est.nat-operacao NO-LOCK:
                        /*** localiza o componente para encontrar a saldo-terc ***/            
                        FOR EACH componente 
                           WHERE componente.nro-docto     = item-doc-est.nro-docto
                             AND componente.nat-operacao  = bf-natur-oper-fut.nat-comp
                             AND componente.cod-emitente  = item-doc-est.cod-emitente
                             AND componente.serie-docto   = item-doc-est.serie-docto
                             AND componente.sequencia     = item-doc-est.sequencia EXCLUSIVE-LOCK:  
                                 
                            FOR FIRST saldo-terc
                                WHERE saldo-terc.nro-docto  = componente.nro-docto                   
                                AND saldo-terc.cod-emitente = componente.cod-emitente
                                AND saldo-terc.serie-docto  = componente.serie-docto 
                                AND saldo-terc.sequencia    = componente.sequencia   EXCLUSIVE-LOCK:
                                    
                                FOR EACH rat-componente 
                                    WHERE rat-componente.serie-docto  = componente.serie-docto
                                    AND rat-componente.nro-docto      = componente.nro-docto
                                    AND rat-componente.cod-emitente   = componente.cod-emitente
                                    AND rat-componente.nat-operacao   = componente.nat-operacao EXCLUSIVE-LOCK:
                                    DELETE rat-componente.                      
                    
                                END.
                                
                                FOR EACH rat-saldo-terc 
                                    WHERE rat-saldo-terc.cod-emitente = saldo-terc.cod-emitente
                                    AND rat-saldo-terc.serie          = saldo-terc.serie-docto  
                                    AND rat-saldo-terc.nro-docto      = saldo-terc.nro-docto  
                                    AND rat-saldo-terc.nat-operacao   = saldo-terc.nat-operacao 
                                    AND rat-saldo-terc.it-codigo      = saldo-terc.it-codigo   
                                    AND rat-saldo-terc.cod-refer      = saldo-terc.cod-refer   
                                    AND rat-saldo-terc.sequencia      = saldo-terc.sequencia EXCLUSIVE-LOCK:
                                        
                                    DELETE rat-saldo-terc.
                                    
                                END.
                                
                                DELETE saldo-terc.
                                DELETE componente.                 
                                           
                            END.                        
                        END.                    
                    END.            
                END.   
            END.		   					
        END. 
	else if l-remessa-ent-futura then do: 	
		FOR FIRST bf-nota-fiscal
			WHERE bf-nota-fiscal.nr-nota-fis = item-doc-est.nro-comp
			  AND bf-nota-fiscal.serie       = item-doc-est.serie-comp 
			  AND bf-nota-fiscal.cod-estabel = docum-est.cod-estabel NO-LOCK:
			FOR FIRST bf-it-nota-fisc 
				WHERE bf-it-nota-fisc.cod-estabel = bf-nota-fiscal.cod-estabel
				  AND bf-it-nota-fisc.serie       = bf-nota-fiscal.serie
				  AND bf-it-nota-fisc.nr-nota-fis = bf-nota-fiscal.nr-nota-fis
				  AND bf-it-nota-fisc.nr-seq-fat  = item-doc-est.seq-comp
				  AND bf-it-nota-fisc.it-codigo   = item-doc-est.it-codigo NO-LOCK: 						  
				FOR FIRST nota-fiscal
					WHERE nota-fiscal.nr-nota-fis = bf-it-nota-fisc.nr-nota-ant
					  AND nota-fiscal.serie       = bf-it-nota-fisc.serie-ant
					  AND nota-fiscal.cod-estabel = bf-it-nota-fisc.cod-estabel NO-LOCK:
					FOR EACH  it-nota-fisc 
						WHERE it-nota-fisc.cod-estabel = nota-fiscal.cod-estabel
						  AND it-nota-fisc.serie       = nota-fiscal.serie
						  AND it-nota-fisc.nr-nota-fis = nota-fiscal.nr-nota-fis
						  AND it-nota-fisc.nr-seq-fat  = item-doc-est.seq-comp
						  AND it-nota-fisc.it-codigo   = item-doc-est.it-codigo NO-LOCK: 	
						FOR FIRST bf-natur-oper-fut 
							WHERE bf-natur-oper-fut.nat-operacao = it-nota-fisc.nat-operacao NO-LOCK: 
							/*** localiza o componente da nota de fatura para encontrar a saldo-terc ***/
							FOR EACH bf-componente 
								WHERE bf-componente.nro-docto     = it-nota-fisc.nr-nota-fis
								  AND bf-componente.nat-operacao  = bf-natur-oper-fut.nat-comp
								  AND bf-componente.cod-emitente  = item-doc-est.cod-emitente
								  AND bf-componente.serie-docto   = it-nota-fisc.serie
								  AND bf-componente.sequencia     = it-nota-fisc.nr-seq-fat    NO-LOCK:
								/*** Localiza a saldo-terc para atualizacao do saldo ***/
								FOR FIRST saldo-terc
									WHERE saldo-terc.nro-docto    = bf-componente.nro-docto   				  
									  AND saldo-terc.cod-emitente = bf-componente.cod-emitente
									  AND saldo-terc.serie-docto  = bf-componente.serie-docto 
									  AND saldo-terc.sequencia    = bf-componente.sequencia   EXCLUSIVE-LOCK:
									/*** Localiza o componente criado pela nota de devolucao da fatura 
										 e atualiza o saldo-ter com base na quantidade deste componente ***/
									FOR EACH  componente 
										WHERE componente.nro-docto     = item-doc-est.nro-docto
										  AND componente.nat-operacao  = bf-natur-oper-fut.nat-comp
										  AND componente.cod-emitente  = item-doc-est.cod-emitente 
										  AND componente.serie-docto   = item-doc-est.serie-docto
										  AND componente.sequencia     = item-doc-est.sequencia    EXCLUSIVE-LOCK:
										ASSIGN saldo-terc.quantidade = saldo-terc.quantidade - componente.quantidade.
										DELETE componente.
									END.
									
									FOR EACH rat-componente 
                                       WHERE rat-componente.serie-docto  = item-doc-est.serie-docto
                                         AND rat-componente.nro-docto    = item-doc-est.nro-docto
                                         AND rat-componente.cod-emitente = item-doc-est.cod-emitente     
                                         AND rat-componente.nat-operacao = bf-natur-oper-fut.nat-comp EXCLUSIVE-LOCK:  
                                          FOR EACH rat-saldo-terc 
                                              WHERE rat-saldo-terc.serie-docto  = bf-componente.serie-docto
                                                AND rat-saldo-terc.nro-docto    = bf-componente.nro-docto
                                                AND rat-saldo-terc.cod-emitente = bf-componente.cod-emitente
                                                AND rat-saldo-terc.nat-operacao = bf-componente.nat-operacao
                                                AND rat-saldo-terc.it-codigo    = rat-componente.it-codigo
                                                AND rat-saldo-terc.cod-refer    = rat-componente.cod-refer
                                                AND rat-saldo-terc.sequencia    = rat-componente.seq-comp 
                                                AND rat-saldo-terc.lote         = rat-componente.lote EXCLUSIVE-LOCK:                                                                                   
                                                ASSIGN rat-saldo-terc.quantidade = rat-saldo-terc.quantidade - rat-componente.quantidade.                                                                                                 
                                          END. 
                                          DELETE rat-componente.
                                    END.					
								END.						
							END.					
						END.						 
					END.
				END.
			END.
		END.
	end.	
    ELSE IF  l-fatura-fat-antecip 
         OR  l-remessa-fat-antecip THEN DO:

        /*--- desatualiza saldo de faturamento antecipado ---*/
        FOR EACH  movto-fatur-antecip
            WHERE movto-fatur-antecip.nr-nota-fis  = item-doc-est.nro-docto
              AND movto-fatur-antecip.serie        = item-doc-est.serie-docto
              AND movto-fatur-antecip.cod-emitente = item-doc-est.cod-emitente
              AND movto-fatur-antecip.nat-operacao = item-doc-est.nat-operacao
              AND movto-fatur-antecip.num-seq      = IF l-fatura-fat-antecip THEN item-doc-est.sequencia ELSE item-doc-est.seq-comp EXCLUSIVE-LOCK:

            FIND FIRST sdo-fatur-antecip
                 WHERE sdo-fatur-antecip.num-id-sdo = movto-fatur-antecip.num-id-sdo EXCLUSIVE-LOCK NO-ERROR.

            IF  AVAIL sdo-fatur-antecip THEN DO:
				/*--- quando estiver desatualizando a Devolução Faturamento Antecipado volta o 
				      saldo de fatura antecipada que havia sido diminuido na devolução     ---*/
				IF movto-fatur-antecip.idi-det-trans = 5 THEN DO:					
					ASSIGN sdo-fatur-antecip.qtd-recebe-fisic = sdo-fatur-antecip.qtd-recebe-fisic + movto-fatur-antecip.qtd-movto
						   sdo-fatur-antecip.qtd-saldo        = sdo-fatur-antecip.qtd-saldo + movto-fatur-antecip.qtd-movto
						   sdo-fatur-antecip.dt-atualiza = TODAY.
					DELETE movto-fatur-antecip.					
					NEXT.					
				END.		
				
				/*--- quando estiver desatualizando a fatura, elimina o saldo fatur antecip 
                      e seu respectivo movimento ---*/
                IF  movto-fatur-antecip.idi-det-trans = 7 /* recebimento fatura */ THEN DO:
                    DELETE sdo-fatur-antecip NO-ERROR.
                    DELETE movto-fatur-antecip NO-ERROR.
                    NEXT.
                END.

                IF  NOT AVAIL sdo-fatur-antecip THEN
                    NEXT.

                /*--- volta o saldo de fatura antecip quando estiver desatualizando a nota de 
                      remessa que havia diminuido o saldo ---*/
                IF  movto-fatur-antecip.idi-det-trans = 8 /* recebimento de remessa */ 
                OR  movto-fatur-antecip.idi-det-trans = 9 /* devolucao de fatura */ THEN DO:
                    ASSIGN sdo-fatur-antecip.qtd-saldo        = sdo-fatur-antecip.qtd-saldo + movto-fatur-antecip.qtd-movto
                           sdo-fatur-antecip.dt-atualiza = TODAY.
                    IF  movto-fatur-antecip.idi-det-trans = 8 THEN DO:
                        ASSIGN sdo-fatur-antecip.qtd-recebe-fisic = sdo-fatur-antecip.qtd-recebe-fisic + movto-fatur-antecip.qtd-movto.
                        DELETE movto-fatur-antecip NO-ERROR.
                        NEXT.
                    END.
                END.
                
                /*--- diminui o saldo da fatura antecip quando estiver desatualizando a nota de devolucao da
                      remessa, pois essa nota havia somado o saldo ---*/
                IF  movto-fatur-antecip.idi-det-trans = 10 /* devolucao de remessa */ THEN DO:
					ASSIGN sdo-fatur-antecip.qtd-saldo   = sdo-fatur-antecip.qtd-saldo - movto-fatur-antecip.qtd-movto
						   sdo-fatur-antecip.dt-atualiza = TODAY.
					DELETE movto-fatur-antecip.
					NEXT.
				END.                

                IF  sdo-fatur-antecip.qtd-saldo < 0 THEN
                    ASSIGN sdo-fatur-antecip.qtd-saldo = 0.
            END.
        END.
        
        /*Recebimento da Devolução Remessa Faturamento Antecipado*/
        IF  l-remessa-fat-antecip and
            docum-est.cod-observa = 3 THEN DO:
            /*Posicionando na nota de Remessa*/
            FOR FIRST bf-nota-fiscal FIELDS(nr-nota-fis serie cod-estabel nat-operacao cod-emitente)
                WHERE bf-nota-fiscal.nr-nota-fis = item-doc-est.nro-comp
                  AND bf-nota-fiscal.serie       = item-doc-est.serie-comp 
                  AND bf-nota-fiscal.cod-estabel = docum-est.cod-estabel NO-LOCK:
                FOR FIRST bf-it-nota-fisc FIELDS(cod-estabel serie nr-nota-fis nr-seq-fat it-codigo nr-nota-ant serie-ant nr-seq-ped int-1) 
                    WHERE bf-it-nota-fisc.cod-estabel = bf-nota-fiscal.cod-estabel
                      AND bf-it-nota-fisc.serie       = bf-nota-fiscal.serie
                      AND bf-it-nota-fisc.nr-nota-fis = bf-nota-fiscal.nr-nota-fis
                      AND bf-it-nota-fisc.nr-seq-fat  = item-doc-est.seq-comp
                      AND bf-it-nota-fisc.it-codigo   = item-doc-est.it-codigo NO-LOCK:
                    /*Posicionando na nota de Fatura*/
                    FOR FIRST nota-fiscal FIELDS(nr-nota-fis serie cod-estabel nat-operacao cod-emitente dt-emis-nota)
                        WHERE nota-fiscal.nr-nota-fis = bf-it-nota-fisc.nr-nota-ant
                          AND nota-fiscal.serie       = bf-it-nota-fisc.serie-ant
                          AND nota-fiscal.cod-estabel = bf-it-nota-fisc.cod-estabel NO-LOCK:
                        FOR FIRST it-nota-fisc FIELDS(cod-estabel serie nr-nota-fis nr-seq-fat it-codigo nat-operacao) 
                            WHERE it-nota-fisc.cod-estabel = nota-fiscal.cod-estabel
                              AND it-nota-fisc.serie       = nota-fiscal.serie
                              AND it-nota-fisc.nr-nota-fis = nota-fiscal.nr-nota-fis
                              AND it-nota-fisc.nr-seq-fat  = bf-it-nota-fisc.int-1 /*Seq da nota de fatura*/
                              AND it-nota-fisc.it-codigo   = item-doc-est.it-codigo NO-LOCK:
                            FOR FIRST movto-fatur-antecip
                                WHERE movto-fatur-antecip.cod-estabel   = nota-fiscal.cod-estabel
                                  AND movto-fatur-antecip.serie-docto   = it-nota-fisc.serie 
                                  AND movto-fatur-antecip.nr-nota-fis   = it-nota-fisc.nr-nota-fis
                                  AND movto-fatur-antecip.cod-emitente  = docum-est.cod-emitente
                                  AND movto-fatur-antecip.nat-operacao  = it-nota-fisc.nat-operacao
                                  AND movto-fatur-antecip.it-codigo     = item-doc-est.it-codigo
                                  AND movto-fatur-antecip.cod-refer     = item-doc-est.cod-refer  
                                  AND movto-fatur-antecip.num-seq       = it-nota-fisc.nr-seq-fat 
                                  AND movto-fatur-antecip.idi-det-trans = 6 /* devolucao de remessa */ EXCLUSIVE-LOCK:

                                FIND FIRST sdo-fatur-antecip
                                     WHERE sdo-fatur-antecip.num-id-sdo = movto-fatur-antecip.num-id-sdo EXCLUSIVE-LOCK NO-ERROR.
                                IF AVAIL sdo-fatur-antecip THEN
                                    ASSIGN sdo-fatur-antecip.qtd-saldo        = sdo-fatur-antecip.qtd-saldo - movto-fatur-antecip.qtd-movto
                                           sdo-fatur-antecip.qtd-recebe-fisic = sdo-fatur-antecip.qtd-recebe-fisic + movto-fatur-antecip.qtd-movto. 
                                           sdo-fatur-antecip.dt-atualiza      = TODAY.

                                DELETE movto-fatur-antecip.
                                NEXT.
                            END.
                        END.
                    END.
                END.
            END.
        END. /*IF  l-remessa-fat-antecip*/
    END.

    IF CAN-FIND(FIRST rat-lote 
                WHERE rat-lote.cod-emitente = item-doc-est.cod-emitente
                  AND rat-lote.serie        = item-doc-est.serie-docto  
                  AND rat-lote.nro-docto    = item-doc-est.nro-docto  
                  AND rat-lote.nat-operacao = item-doc-est.nat-operacao  
                  AND rat-lote.it-codigo    = item-doc-est.it-codigo   
                  AND rat-lote.cod-refer    = item-doc-est.cod-refer   
                  AND rat-lote.sequencia    = item-doc-est.sequencia) THEN
        for each rat-lote 
           where rat-lote.cod-emitente = item-doc-est.cod-emitente
             and rat-lote.serie        = item-doc-est.serie-docto  
             and rat-lote.nro-docto    = item-doc-est.nro-docto  
             and rat-lote.nat-operacao = item-doc-est.nat-operacao  
             and rat-lote.it-codigo    = item-doc-est.it-codigo   
             and rat-lote.cod-refer    = item-doc-est.cod-refer   
             and rat-lote.sequencia    = item-doc-est.sequencia no-lock:
            FOR first rat-saldo-terc 
                where rat-saldo-terc.cod-emitente = item-doc-est.cod-emitente
                  and rat-saldo-terc.serie        = item-doc-est.serie-comp  
                  and rat-saldo-terc.nro-docto    = item-doc-est.nro-comp  
                  and rat-saldo-terc.nat-operacao = item-doc-est.nat-comp  
                  and rat-saldo-terc.it-codigo    = item-doc-est.it-codigo   
                  and rat-saldo-terc.cod-refer    = item-doc-est.cod-refer   
                  and rat-saldo-terc.sequencia    = item-doc-est.seq-comp 
                  and rat-saldo-terc.lote         = rat-lote.lote EXCLUSIVE-LOCK:
                IF  docum-est.rec-fisico
                AND item-doc-est.dec-1 > 0
                AND SUBSTRING(param-estoq.char-1,23,1) = "1" THEN /* Contabiliza Diferenca Contagem */
                    ASSIGN rat-saldo-terc.quantidade     = rat-saldo-terc.quantidade     + rat-lote.qtd-origin
                           rat-saldo-terc.qtd-aloc-trans = rat-saldo-terc.qtd-aloc-trans + rat-lote.qtd-origin WHEN NOT b1-natur-oper.transf. 
                ELSE
                    ASSIGN rat-saldo-terc.quantidade     = rat-saldo-terc.quantidade     + rat-lote.quantidade
                           rat-saldo-terc.qtd-aloc-trans = rat-saldo-terc.qtd-aloc-trans + rat-lote.quantidade WHEN NOT b1-natur-oper.transf.
            END.
        END.
    ELSE DO:
      FOR EACH rat-componente 
         WHERE rat-componente.cod-emitente = item-doc-est.cod-emitente
           AND rat-componente.it-codigo    = item-doc-est.it-codigo   
           AND rat-componente.cod-refer    = item-doc-est.cod-refer   
           AND rat-componente.sequencia    = item-doc-est.sequencia
           AND rat-componente.nro-docto    = item-doc-est.nro-docto
           AND rat-componente.nat-operacao = item-doc-est.nat-operacao
           AND rat-componente.serie-docto  = item-doc-est.serie-docto NO-LOCK:
           FOR EACH rat-saldo-terc 
              WHERE rat-saldo-terc.cod-emitente = item-doc-est.cod-emitente
                AND rat-saldo-terc.serie        = item-doc-est.serie-comp  
                AND rat-saldo-terc.nro-docto    = item-doc-est.nro-comp  
                AND rat-saldo-terc.nat-operacao = item-doc-est.nat-comp  
                AND rat-saldo-terc.it-codigo    = item-doc-est.it-codigo   
                AND rat-saldo-terc.cod-refer    = item-doc-est.cod-refer   
                AND rat-saldo-terc.sequencia    = item-doc-est.seq-comp 
                AND rat-saldo-terc.lote         = rat-componente.lote EXCLUSIVE-LOCK:
                ASSIGN rat-saldo-terc.quantidade     = rat-saldo-terc.quantidade + rat-componente.quantidade
                       rat-saldo-terc.qtd-aloc-trans = rat-saldo-terc.qtd-aloc-trans  + rat-componente.quantidade.
           END.
      END.
    END.
    
    FOR EACH rat-saldo-terc 
         where rat-saldo-terc.cod-emitente = item-doc-est.cod-emitente
           and rat-saldo-terc.serie        = item-doc-est.serie-docto  
           and rat-saldo-terc.nro-docto    = item-doc-est.nro-docto  
           and rat-saldo-terc.nat-operacao = item-doc-est.nat-operacao 
           and rat-saldo-terc.it-codigo    = item-doc-est.it-codigo   
           and rat-saldo-terc.cod-refer    = item-doc-est.cod-refer   
           and rat-saldo-terc.sequencia    = item-doc-est.sequencia exclusive-lock:
        delete rat-saldo-terc.
    END. 
	
    /* Opera‡ao Triangular */
    &if defined(bf_mat_oper_triangular) &then
        if  b1-natur-oper.log-oper-triang THEN
            run pi-desatualiza-oper-triang.
    &endif

    ASSIGN lDevSimbConsig = {cdp/cd0066.i docum-est.cod-estabel b1-natur-oper}
    
    IF  l-rec-Brasil AND lDevSimbConsig THEN DO:
        ASSIGN lNfDevSimbConsig = NO.
        FIND FIRST componente NO-LOCK
             WHERE componente.cod-emitente = item-doc-est.cod-emitente
               AND componente.serie-docto  = item-doc-est.serie-docto
               AND componente.nro-docto    = item-doc-est.nro-docto
               AND componente.nat-operacao = item-doc-est.nat-operacao
               AND componente.it-codigo    = item-doc-est.it-codigo
               AND componente.cod-refer    = item-doc-est.cod-refer 
               AND componente.sequencia    = item-doc-est.sequencia NO-ERROR.
        IF  AVAIL componente THEN
            ASSIGN lNfDevSimbConsig = {cdp/cd0066.i1 b1-natur-oper componente}

        IF  lNfDevSimbConsig THEN DO:
            IF &IF "{&mguni_version}" >= "2.08" &THEN
                componente.qtd-afatur-consig > 0 OR
                componente.qtd-fatur-consig > 0
               &ELSE
                DEC(SUBSTR(componente.char-1,54,14)) > 0 or
                DEC(SUBSTR(componente.char-1,68,14)) > 0
               &ENDIF THEN DO:

                FIND LAST tt-erro NO-LOCK NO-ERROR.
                ASSIGN i-seq-erro = IF AVAIL tt-erro
                                    THEN tt-erro.i-sequen + 1
                                    ELSE 1.

                CREATE tt-erro.
                ASSIGN tt-erro.i-sequen = 1
                       tt-erro.cd-erro  = 34858.

                RUN utp/ut-msgs.p (INPUT 'help', INPUT 34858, INPUT '').
                ASSIGN tt-erro.mensagem = RETURN-VALUE.

                assign l-erro = yes.

                RETURN "NOK":U.
            END.
        END.
    END.

    IF AVAIL b1-natur-oper
        AND b1-natur-oper.transf 
        AND b1-natur-oper.tipo = 2 /* Saida - RE4001 */ THEN DO:

        ASSIGN i-estab-emit   = IF AVAIL estabelec THEN estabelec.cod-emitente ELSE 0.

        FIND FIRST saldo-terc USE-INDEX documento 
             WHERE saldo-terc.serie-docto  = item-doc-est.serie-docto 
               AND saldo-terc.nro-docto    = item-doc-est.nro-docto 
               AND saldo-terc.cod-emitente = i-estab-emit
               AND saldo-terc.nat-operacao = item-doc-est.nat-operacao
               AND saldo-terc.it-codigo    = item-doc-est.it-codigo
               AND saldo-terc.cod-refer    = item-doc-est.cod-refer
               AND saldo-terc.sequencia    = item-doc-est.sequencia EXCLUSIVE-LOCK NO-ERROR.
        
        IF AVAIL saldo-terc THEN DO:
    
            FIND FIRST componente USE-INDEX documento 
                 WHERE componente.serie-docto  = item-doc-est.serie-docto 
                   AND componente.nro-docto    = item-doc-est.nro-docto
                   AND componente.nat-operacao = item-doc-est.nat-operacao
                   and componente.it-codigo    = item-doc-est.it-codigo
                   and componente.cod-refer    = item-doc-est.cod-refer
                   and componente.sequencia    = item-doc-est.sequencia 
                   AND componente.cod-emitente = saldo-terc.cod-emitente EXCLUSIVE-LOCK NO-ERROR.
        
            IF AVAIL componente THEN                 
              DELETE componente.
              
            FOR EACH rat-componente 
                WHERE  rat-componente.serie-docto  = item-doc-est.serie-docto
                  AND  rat-componente.nro-docto    = item-doc-est.nro-docto
                  AND  rat-componente.cod-emitente = saldo-terc.cod-emitente
                  AND  rat-componente.nat-operacao = item-doc-est.nat-operacao EXCLUSIVE-LOCK:
                      
                DELETE rat-componente.
                
            END.
            FOR EACH rat-saldo-terc 
              WHERE rat-saldo-terc.serie-docto  = item-doc-est.serie-docto
                AND rat-saldo-terc.nro-docto    = item-doc-est.nro-docto
                AND rat-saldo-terc.cod-emitente = saldo-terc.cod-emitente
                AND rat-saldo-terc.nat-operacao = item-doc-est.nat-operacao EXCLUSIVE-LOCK:

                DELETE rat-saldo-terc.

            END.
        END.
    
    END.
    ELSE DO:

        FIND FIRST componente {cdp/cd8900.i item-doc-est componente}
            and componente.it-codigo = item-doc-est.it-codigo
            and componente.cod-refer = item-doc-est.cod-refer
            and componente.sequencia = item-doc-est.sequencia exclusive-lock no-error.
        if avail componente then              
            delete componente.       
       
         FOR EACH rat-componente 
            WHERE rat-componente.serie-docto  = item-doc-est.serie-docto
              AND rat-componente.nro-docto    = item-doc-est.nro-docto
              AND rat-componente.cod-emitente = item-doc-est.cod-emitente
              AND rat-componente.nat-operacao = item-doc-est.nat-operacao EXCLUSIVE-LOCK:  
        
            IF b1-natur-oper.tp-oper-terc <> 4 AND lDevSimbConsig = NO THEN 
               DELETE rat-componente.
         END. 
         
    
        FIND FIRST saldo-terc {cdp/cd8900.i saldo-terc item-doc-est}
            and saldo-terc.it-codigo = item-doc-est.it-codigo
            and saldo-terc.cod-refer = item-doc-est.cod-refer
            and saldo-terc.sequencia = item-doc-est.sequencia exclusive-lock no-error.
    END.

    if  avail saldo-terc then do:
        /*************************************************
        * Chamada EPC para Contole de Vasilhames - Super *
        *************************************************/
        if avail saldo-terc then do:
            for each tt-epc
               where tt-epc.cod-event = "Controle-Vasilhames":
    	           delete tt-epc.
            end.

            create tt-epc.
            assign tt-epc.cod-event     = "Controle-Vasilhames"
                   tt-epc.cod-parameter = "saldo-terc-rowid"
       	         tt-epc.val-parameter = string(rowid(saldo-terc)).

            {include/i-epc201.i "Controle-Vasilhames"}
            if  return-value = 'NOK' then do:
                assign l-erro = yes.
                return.
            end.
        end.
        /*************************************************/
        delete saldo-terc validate(true, "").
    end.

    find saldo-terc
        where saldo-terc.cod-emitente = item-doc-est.cod-emitente
        and   saldo-terc.serie-docto  = item-doc-est.serie-comp
        and   saldo-terc.nro-docto    = item-doc-est.nro-comp
        and   saldo-terc.nat-operacao = item-doc-est.nat-comp
        and   saldo-terc.it-codigo    = item-doc-est.it-codigo
        and   saldo-terc.cod-refer    = item-doc-est.cod-refer
        and   saldo-terc.sequencia    = item-doc-est.seq-comp  exclusive-lock no-error.
    if  avail saldo-terc then do:
        run pi-valida-tipo-retorno.

        /* Estorno do Faturamento */
        IF  {cdp/cd0066.i2 saldo-terc.cod-estabel}
            AND b1-natur-oper.tp-oper-terc = 4 THEN DO: /* Faturamento Consignacao  */

            RUN inbo/boin404.p PERSISTENT SET h-boin404.
            RUN updateFifoDevolucaoSimbolica
                         IN h-boin404 (NO,
                                       NO,
                                       ROWID(saldo-terc),
                                       item-doc-est.quantidade).
             DELETE PROCEDURE h-boin404.
        END.

        IF  l-rec-Brasil AND lDevSimbConsig THEN
            RETURN "OK":U.

        if  (docum-est.rec-fisico 
	         &if '{&bf_mat_versao_ems}':U >= '2.062':U &then
		       or l-rec-brasil = no
		     &endif)
        and item-doc-est.dec-1 <> 0
        and docum-est.esp-docto <> 23 /* Transferencia */
        AND SUBSTRING(param-estoq.char-1,23,1) = "0" then   /* Nao Contabiliza Diferenca Contagem */
            assign saldo-terc.quantidade = saldo-terc.quantidade + item-doc-est.dec-1
                   saldo-terc.dec-1      = saldo-terc.dec-1      + item-doc-est.dec-1.
        ELSE
            assign saldo-terc.quantidade = saldo-terc.quantidade + item-doc-est.quantidade
                   saldo-terc.dec-1      = saldo-terc.dec-1      + item-doc-est.quantidade WHEN NOT b1-natur-oper.transf.
    end.
    
end.

procedure pi-epc:
    /* Chamada espec¡fica para Itatiaia - Favor nao retirar.
       A UPC (espec005.p) ira indicar se devera ser desatualizado o 
       sado-terc mesmo com a natureza nao marcada como 'terceiros' */
    FOR EACH  tt-epc
        WHERE tt-epc.cod-event = "Saldo-Terc Check-Sum":
        DELETE tt-epc.
    END.

    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "Saldo-Terc Check-sum"
           tt-epc.cod-parameter = "rowid item-doc-est"
           tt-epc.val-parameter = STRING(ROWID(item-doc-est)).

    {include/i-epc201.i "Saldo-Terc Check-sum"}
    FIND FIRST tt-epc WHERE
         tt-epc.cod-event = "Saldo-Terc Check-sum" NO-ERROR.
    IF  AVAIL tt-epc
    AND tt-epc.val-parameter = "1" THEN
        /* Se o valor retornado for = "1" atribui valor para a
          variavel e nao ocorre o erro  26782 */
        ASSIGN i-tipo-sal-terc = saldo-terc.tipo-sal-terc.
end procedure.


procedure pi-verifica-ordem-frota:
    run cdp/cd9902.p(3).  /* M¢dulo de Manuten‡Æo Mecƒnica */
    if return-value = "OK":U       and 
       movto-estoq.nr-ord-prod > 0 then do:
       run abp/ab0803.p(buffer movto-estoq,
                         2).  /* 1 = InclusÆo Registro. 2 = Exclusao Registro */
    end.
    return "OK":U.
end procedure.

procedure pi-valida-tipo-retorno:
/* Objetivo: qdo o usuario altera o tipo da operacao terceiros da natureza de retorno o saldo em quantidade fica errado e com isso aparece no RE0508 os asteriscos *** */
    /*  Retorno Beneficiamento */
    if  b1-natur-oper.tp-oper-terc = 2 then
        assign i-tipo-sal-terc = if  b1-natur-oper.tipo = 1 then 1
                                 else 2.
    else
    /*  Faturamento de Consignacao  e  Reajuste de Preco */
    if  b1-natur-oper.tp-oper-terc = 4
    or  b1-natur-oper.tp-oper-terc = 6 then
        assign i-tipo-sal-terc = if  b1-natur-oper.tipo = 1 then 5
                                 else 4.
    else
    /*  Devolucao de Consignacao */
    if  b1-natur-oper.tp-oper-terc = 5 then
        assign i-tipo-sal-terc = if  b1-natur-oper.tipo = 1 then 4
                                 else 5.
    else
    /*  Retorno Dep Fechado */
    if  b1-natur-oper.tp-oper-terc = 9 then 
        assign i-tipo-sal-terc = if  b1-natur-oper.tipo = 1 then 7
                                 else 8.
    else
    /*  Retorno Armaz Geral */
    if  b1-natur-oper.tp-oper-terc = 11 then 
        assign i-tipo-sal-terc = if  b1-natur-oper.tipo = 1 then 9
                                 else 10.
    
    run pi-epc.
    
    if not b1-natur-oper.transf
    and i-tipo-sal-terc <> saldo-terc.tipo-sal-terc then
        run pi-erro-nota ( 26782, " ", yes ).
        /* Tipo Operacao com terceiros da natureza foi alterado ap¢s a inclusÆo desta nota fiscal.
           Verifique o tipo de opera‡Æo do saldo terceiros original */
end.

procedure pi-desatualiza-consumo:

    def var v_ind_finalid_cta    as char   no-undo.
    DEF VAR h_api_cta_ctbl       AS HANDLE NO-UNDO.
    
    find item WHERE
         item.it-codigo = movto-estoq.it-codigo
         no-lock no-error.
    if  item.tipo-contr   <> 4 AND
        param-estoq.dec-2 <> 1 /* Atualiza consumo AAD ? */ then do:

        run prgint/utb/utb743za.py persistent set h_api_cta_ctbl.
        /* Busca finalidade da conta na api de financas */
        run pi_busca_dados_cta_ctbl_integr in h_api_cta_ctbl (input  i-empresa,             /* EMPRESA EMS2 */
                                                              input  "CEP",                 /* MODULO */
                                                              input  "",                    /* PLANO DE CONTAS */
                                                              input  movto-estoq.ct-codigo, /* CONTA */
                                                              input  movto-estoq.dt-trans,  /* DATA TRANSACAO */   
                                                              output v_ind_finalid_cta,     /* FINALIDADES DA CONTA */
                                                              output table tt_log_erro).    /* ERROS */                                                            
        if return-value = "OK" then do:
            if v_ind_finalid_cta = {adinc/i05ad049.i 4 1} or
               v_ind_finalid_cta = {adinc/i05ad049.i 4 3} or
               v_ind_finalid_cta = {adinc/i05ad049.i 4 6} then do:
                   
                find item WHERE item.it-codigo = movto-estoq.it-codigo
                     exclusive-lock no-error.
    
                find item-estab
                    where item-estab.it-codigo = movto-estoq.it-codigo
                    and   item-estab.cod-estabel = movto-estoq.cod-estabel exclusive-lock no-error.
    
                if  movto-estoq.tipo-trans = 1 then
                    assign item.consumo-aad       = item.consumo-aad
                                                  + movto-estoq.quantidade
                           item-estab.consumo-aad = item-estab.consumo-aad
                                                  + movto-estoq.quantidade.
                else
                    assign item.consumo-aad       = item.consumo-aad
                                                  - movto-estoq.quantidade
                           item-estab.consumo-aad = item-estab.consumo-aad
                                                  - movto-estoq.quantidade.
                                                  
            end.
        end.
        delete object h_api_cta_ctbl.
    end.

    /* Desatualiza consumo */
    if  i-periodos > 0 and i-periodos < 13 then do:
        find consumo use-index conta-item
            where consumo.ct-codigo = movto-estoq.ct-codigo
            and   consumo.sc-codigo = movto-estoq.sc-codigo
            and   consumo.it-codigo = movto-estoq.it-codigo
            and   consumo.periodo   = c-per-cons  exclusive-lock no-error.
        if  avail consumo then
            if  movto-estoq.tipo-trans = 1 then
                assign consumo.qt-entrada = consumo.qt-entrada
                                          - movto-estoq.quantidade.
            else
                assign consumo.qt-saida = consumo.qt-saida
                                        - movto-estoq.quantidade.
    end.
end.

procedure pi-desatualiza-ft:
def var l-pd0001        as logical  no-undo.

do on error undo, return "ADM-ERROR" :

    if item-doc-est.nro-comp <> "" then
    do:
        find it-nota-fisc use-index ch-nota-item
            where it-nota-fisc.cod-estabel = docum-est.cod-estabel
            and   it-nota-fisc.serie       = item-doc-est.serie-comp
            and   it-nota-fisc.nr-nota-fis = item-doc-est.nro-comp
            and   it-nota-fisc.nr-seq-fat  = item-doc-est.seq-comp
            and   it-nota-fisc.it-codigo   = item-doc-est.it-codigo
                no-lock no-error.
        find first ped-item
            where ped-item.nome-abrev   = emitente.nome-abrev
            and   ped-item.nr-pedcli    = it-nota-fisc.nr-pedcli
            and   ped-item.nr-sequencia = it-nota-fisc.nr-seq-ped
            and   ped-item.it-codigo    = it-nota-fisc.it-codigo
            and   ped-item.cod-refer    = item-doc-est.cod-refer no-lock no-error.
    end.
    else 
        find first ped-item
            where ped-item.nome-abrev   = emitente.nome-abrev
            and   ped-item.nr-pedcli    = item-doc-est.nr-pedcli
            and   ped-item.nr-sequencia = item-doc-est.nr-pd-seq
            and   ped-item.it-codigo    = item-doc-est.it-codigo
            and   ped-item.cod-refer    = item-doc-est.cod-refer no-lock no-error.

    /* Baixa do Modulo de Pedidos */
    if  param-global.modulo-pd
    and avail ped-item
    and ped-item.esp-ped = 1 then do:

        for each rat-lote {cdp/cd8900.i "rat-lote" "item-doc-est"}
            and rat-lote.sequencia = item-doc-est.sequencia no-lock
            break by rat-lote.sequencia:

            find tt-ped-item where tt-ped-item.rw-ped-item = rowid(ped-item) no-lock no-error.
            if  not avail tt-ped-item then do:
                create tt-ped-item.
                assign tt-ped-item.rw-ped-item = rowid(ped-item).
            end.

            if  can-find (first b-item-ref
                       where b-item-ref.it-codigo    = rat-lote.it-codigo
                       and   b-item-ref.tipo-con-est = 4) then do:

                 for first b-ped-item
                     fields (b-ped-item.cod-refer
                             b-ped-item.nome-abrev
                             b-ped-item.nr-pedcli
                             b-ped-item.nr-sequencia
                             b-ped-item.it-codigo)
                     where b-ped-item.nome-abrev   = emitente.nome-abrev
                       and b-ped-item.nr-pedcli    = item-doc-est.nr-pedcli
                       and b-ped-item.nr-sequencia = item-doc-est.seq-comp
                       and b-ped-item.it-codigo    = rat-lote.it-codigo no-lock:
                        assign c-referencia = b-ped-item.cod-refer.
                 end.
            end.
            else assign c-referencia = "".

            run pdp/pd9701.p (input rowid(ped-item),
                              input rat-lote.it-codigo,
                              input c-referencia,
                              input rat-lote.quantidade,
                              input yes,
                              input no,
                              input item-doc-est.reabre-pd,
                              input no,
                              ( if  avail it-nota-fisc then it-nota-fisc.nr-entrega
                                else 0 ),
                              input table tt-ped-item,
                              input 1).

            if  last-of(rat-lote.sequencia) then do:
                find tt-ped-item where tt-ped-item.rw-ped-item = rowid(ped-item) no-lock no-error.
                if  not avail tt-ped-item then do:
                    create tt-ped-item.
                    assign tt-ped-item.rw-ped-item = rowid(ped-item).
                end.
                run pdp/pd9701.p (input rowid(ped-item),
                                  input item-doc-est.it-codigo,
                                  input item-doc-est.cod-refer,
                                  ( if (item.politica = 5 or item.politica = 6) and not item-doc-est.baixa-ce
                                        then item-doc-est.quantidade
                                        else 0 ),
                                  input yes,
                                  input yes,
                                  input item-doc-est.reabre-pd,
                                  input no,
                                  ( if  avail it-nota-fisc then it-nota-fisc.nr-entrega
                                    else 0 ),
                                  input table tt-ped-item,
                                  input 1).
            end.
            assign l-pd0001 = yes.
        end.
        if  l-pd0001 = no then do:
            find tt-ped-item where tt-ped-item.rw-ped-item = rowid(ped-item) no-lock no-error.
            if  not avail tt-ped-item then do:
                create tt-ped-item.
                assign tt-ped-item.rw-ped-item = rowid(ped-item).
            end.
            run pdp/pd9701.p (input rowid(ped-item),
                              input item-doc-est.it-codigo,
                              input item-doc-est.cod-refer,
                              input item-doc-est.quantidade,
                              input yes,
                              input yes,
                              input item-doc-est.reabre-pd,
                              input no,
                              ( if  avail it-nota-fisc then it-nota-fisc.nr-entrega
                                else 0 ),
                              input table tt-ped-item,
                              input 1).
        end.
    end.
		
    IF  AVAIL it-nota-fisc     AND
        param-global.modulo-ex AND
        CONNECTED("MGCEX") THEN DO:
			
		if can-find ( FIRST nota-fiscal 
		              WHERE nota-fiscal.cod-estabel = it-nota-fisc.cod-estabel
					    AND nota-fiscal.serie       = it-nota-fisc.serie
						AND nota-fiscal.nr-nota-fis = it-nota-fisc.nr-nota-fis
						AND nota-fiscal.nr-proc-exp <> "":U ) then do:
		
            RUN exp/ex3051.p PERSISTENT SET h-ex3051.
            
            RUN criaProcPedEntDesatualiz IN h-ex3051 (INPUT ROWID(it-nota-fisc),
                                                      OUTPUT TABLE RowErrors APPEND).
            for each RowErrors:
                run pi-erro-nota ( input RowErrors.ErrorNumber,
                                   input RowErrors.ErrorParameters,
                                   input (RowErrors.ErrorSubType = "ERROR":U) ).
            end.
            
            
            RUN ModificaSituacao IN h-ex3051 (INPUT 2,
                                              INPUT ROWID(it-nota-fisc)).
            DELETE PROCEDURE h-ex3051.
            ASSIGN h-ex3051 = ?.
        end.
        
        if  l-erro then
            return "NOK":U.
        
    END.
end.
end procedure.

procedure pi-desatualiza-oper-triang:
    &if defined(bf_mat_oper_triangular) &then
        /* Verifica a existencia de retornos do beneficiador */
        if  can-find(first componente use-index comp where
                     componente.cod-emitente = item-doc-est.cod-emit-terc  and
                     componente.serie-comp   = item-doc-est.serie-terc     and
                     componente.nro-comp     = item-doc-est.nro-docto-terc and
                     componente.nat-comp     = item-doc-est.nat-terc       AND
                     componente.it-codigo    = item-doc-est.it-codigo      AND
                     componente.cod-refer    = item-doc-est.cod-refer      AND
                     componente.sequencia    = item-doc-est.seq-terc) then do:
            run pi-erro-nota ( 19219, " ", no ).
            assign l-erro = yes.
            return.
        end.

        find componente
            where componente.cod-emitente = item-doc-est.cod-emit-terc
              and componente.serie-docto  = item-doc-est.serie-terc
              and componente.nro-docto    = item-doc-est.nro-docto-terc
              and componente.nat-operacao = item-doc-est.nat-terc
              and componente.it-codigo    = item-doc-est.it-codigo
              and componente.cod-refer    = item-doc-est.cod-refer
              and componente.sequencia    = item-doc-est.seq-terc exclusive-lock no-error.
        if  avail componente THEN
            delete componente.
            
        FOR EACH rat-componente 
           WHERE rat-componente.serie-docto  = item-doc-est.serie-terc
             AND rat-componente.nro-docto    = item-doc-est.nro-docto-terc
             AND rat-componente.cod-emitente = item-doc-est.cod-emit-terc
             AND rat-componente.nat-operacao = item-doc-est.nat-terc
             and rat-componente.it-codigo    = item-doc-est.it-codigo
             and rat-componente.cod-refer    = item-doc-est.cod-refer
             and rat-componente.sequencia    = item-doc-est.seq-terc EXCLUSIVE-LOCK:    
             
            DELETE rat-componente.                
        END.                
            
       
        find saldo-terc
            where saldo-terc.cod-emitente = item-doc-est.cod-emit-terc
              and saldo-terc.serie-docto  = item-doc-est.serie-terc
              and saldo-terc.nro-docto    = item-doc-est.nro-docto-terc
              and saldo-terc.nat-operacao = item-doc-est.nat-terc
              and saldo-terc.it-codigo    = item-doc-est.it-codigo
              and saldo-terc.cod-refer    = item-doc-est.cod-refer
              and saldo-terc.sequencia    = item-doc-est.seq-terc exclusive-lock no-error.
        if  avail saldo-terc THEN
            delete saldo-terc validate(true, "").       
            
        for each  rat-saldo-terc
            where rat-saldo-terc.cod-emitente = item-doc-est.cod-emit-terc
              and rat-saldo-terc.serie-docto  = item-doc-est.serie-terc
              and rat-saldo-terc.nro-docto    = item-doc-est.nro-docto-terc
              and rat-saldo-terc.nat-operacao = item-doc-est.nat-terc
              and rat-saldo-terc.it-codigo    = item-doc-est.it-codigo
              and rat-saldo-terc.cod-refer    = item-doc-est.cod-refer
              and rat-saldo-terc.sequencia    = item-doc-est.seq-terc exclusive-lock:
                 
            delete rat-saldo-terc validate(true, "").
                        
        end.

        /* Elimina Saldo-Terc da Oper. Triang. na nota de Material Agregado com Acabado */
        for first movto-pend
            fields (cod-emitente serie-docto nro-docto
                    nat-operacao it-codigo   cod-refer )
            where movto-pend.cod-emitente = item-doc-est.cod-emitente
              and movto-pend.serie-docto  = item-doc-est.serie-docto
              and movto-pend.nro-docto    = item-doc-est.nro-docto
              and movto-pend.nat-operacao = item-doc-est.nat-operacao
              and movto-pend.it-codigo    = item-doc-est.it-codigo
              and movto-pend.nr-ord-prod  = item-doc-est.nr-ord-prod
              and movto-pend.tipo         = 1 no-lock: end. /* Acabado */

        if  not avail movto-pend THEN
            for first movto-pend
                fields (cod-emitente serie-docto nro-docto
                        nat-operacao it-codigo   cod-refer )
                where movto-pend.cod-emitente = item-doc-est.cod-emitente
                  and movto-pend.serie-docto  = item-doc-est.serie-docto
                  and movto-pend.nro-docto    = item-doc-est.nro-docto
                  and movto-pend.nat-operacao = item-doc-est.nat-operacao
                  and movto-pend.nr-ord-prod  = item-doc-est.nr-ord-prod
                  and movto-pend.tipo         = 1 no-lock: end. /* Acabado */

        if  avail movto-pend then do:
            find componente
                where componente.cod-emitente = item-doc-est.cod-emit-terc
                  and componente.serie-docto  = item-doc-est.serie-terc
                  and componente.nro-docto    = item-doc-est.nro-docto-terc
                  and componente.nat-operacao = item-doc-est.nat-terc
                  and componente.it-codigo    = movto-pend.it-codigo
                  and componente.cod-refer    = movto-pend.cod-refer
                  and componente.sequencia    = item-doc-est.sequencia exclusive-lock no-error.
            if  avail componente THEN
                delete componente.
                
            FOR EACH rat-componente 
               WHERE rat-componente.serie-docto  = item-doc-est.serie-terc
                 AND rat-componente.nro-docto    = item-doc-est.nro-docto-terc
                 AND rat-componente.cod-emitente = item-doc-est.cod-emit-terc
                 AND rat-componente.nat-operacao = item-doc-est.nat-terc
                 and rat-componente.it-codigo    = movto-pend.it-codigo
                 and rat-componente.cod-refer    = movto-pend.cod-refer
                 and rat-componente.sequencia    = item-doc-est.sequencia EXCLUSIVE-LOCK:                          

                DELETE rat-componente.                
            END.         
            
           
            find saldo-terc
                where saldo-terc.cod-emitente = item-doc-est.cod-emit-terc
                  and saldo-terc.serie-docto  = item-doc-est.serie-terc
                  and saldo-terc.nro-docto    = item-doc-est.nro-docto-terc
                  and saldo-terc.nat-operacao = item-doc-est.nat-terc
                  and saldo-terc.it-codigo    = movto-pend.it-codigo
                  and saldo-terc.cod-refer    = movto-pend.cod-refer
                  and saldo-terc.sequencia    = item-doc-est.sequencia exclusive-lock no-error.
            if  avail saldo-terc THEN
                delete saldo-terc validate(true, "").
              
            for each rat-saldo-terc exclusive
                where rat-saldo-terc.cod-emitente = item-doc-est.cod-emit-terc
                  and rat-saldo-terc.serie-docto  = item-doc-est.serie-terc
                  and rat-saldo-terc.nro-docto    = item-doc-est.nro-docto-terc
                  and rat-saldo-terc.nat-operacao = item-doc-est.nat-terc
                  and rat-saldo-terc.it-codigo    = movto-pend.it-codigo
                  and rat-saldo-terc.cod-refer    = movto-pend.cod-refer
                  and rat-saldo-terc.sequencia    = item-doc-est.sequencia :
          
                delete rat-saldo-terc validate(true, "").
              
            end.                    
        end.
    &endif
end.
    
PROCEDURE pi-atualiza-rma:
if  rat-lote.nr-ficha            = 0
and rat-lote.num-seq-rma-dep     > 0
and rat-lote.num-seq-rma-dep-mov > 0 then do:

    find first rma-it-dep-mov
      where rma-it-dep-mov.num-seq-dep-mov = rat-lote.num-seq-rma-dep-mov
      and   rma-it-dep-mov.cod-estabel     = docum-est.cod-estabel
      and   rma-it-dep-mov.cod-rma         = docum-est.cod-rma
      and   rma-it-dep-mov.num-sequencia   = item-doc-est.num-seq-rma exclusive-lock no-error.

    find rma
      where rma.cod-estabel = rma-it-dep-mov.cod-estabel
      and   rma.cod-rma     = rma-it-dep-mov.cod-rma no-lock no-error.
    if  avail rma
    and rma.cdn-situacao < 6 then do:
        assign rma-it-dep-mov.qtd-estocada = 0.
        {cdp/cd1203.i docum-est.cod-rma docum-est.cod-estabel}
    end.
end.
END PROCEDURE.

procedure pi-cn-bgc-conteudo-inicial:
    /*Integracao CN x BGC*/
    if  avail ordem-compra
    and ordem-compra.nr-contrato <> 0 then do:

        /* Integracao Contratos - limpa registros temp-table integra‡Æo */
        {cnp/cnapi020.i4}

        /* Integracao Contratos - criar registro para altera‡Æo */
        {cnp/cnapi020.i1 1 2 RE0402 " " prazo-compra prazo-compra}
    end.
end procedure.

procedure pi-cn-bgc-conteudo-final:
    /*Integracao CN x BGC*/
    if  avail ordem-compra
    and ordem-compra.nr-contrato <> 0 then do:

        /* Integracao Contratos - criar registro para altera‡Æo */
        {cnp/cnapi020.i1 2 2 RE0402 " " prazo-compra prazo-compra}
        
        /* Integracao Contratos - executa API integra‡Æo e valida erros */
        {cnp/cnapi020.i2 " " no}
        {cnp/cnapi020.i5 " "}
        if  l-erro-integra-cn then do:
            assign l-erro = yes.
            return "NOK":U.
        end.
    end.
    return "OK":U.
end procedure.

procedure pi-leitura:
    bloco-leitura:
    for each  ano-fiscal
        where ano-fiscal.ep-codigo  = i-empresa no-lock:
        do  i-per-cons = 1 to ano-fiscal.num-periodos:
            if  docum-est.dt-trans >= ano-fiscal.ini-periodo[i-per-cons]
            and docum-est.dt-trans <= ano-fiscal.fim-periodo[i-per-cons] then do:
               assign c-per-cons = string(year(docum-est.dt-trans),"9999")
                                 + string(month(docum-est.dt-trans),"99")
                      i-periodos = i-per-cons.
               leave bloco-leitura.
            end.
        end.
    end.
end procedure.

procedure pi-eai:
    IF  v_log_eai_habilit
    AND l-integra-eai THEN DO: 


        &if '{&bf_dis_versao_ems}' >= '2.06' &then
        /** Validacao para que nao seja enviado ao HIS o movimento de estoque do recebimento fiscal, caso o mesmo tenha sido
            gerado pelo Recebimento Fisico**/
        if  l-integra-ems-his then do:
            if  avail docum-est then do:
                if  param-estoq.rec-fisico then
                    find first doc-fisico
                         where doc-fisico.nro-docto    = docum-est.nro-docto
                         and   doc-fisico.serie-docto  = docum-est.serie-docto
                         and   doc-fisico.cod-emitente = docum-est.cod-emitente no-lock no-error.
            end.
        end.
        
        if  not avail doc-fisico then do:
        &endif
        
            run adapters/xml/ar2/axsar001.p (input "RE0402A":U,
                                             input c-prg-vrs,
                                             input "DEL":U,
                                             input rowid(movto-estoq),
                                             output table RowErrors).

        &if '{&bf_dis_versao_ems}' >= '2.06' &then
        end.
        &endif

        for each RowErrors:
            run pi-erro-nota ( input RowErrors.ErrorNumber,
                               input RowErrors.ErrorParameters,
                               input (RowErrors.ErrorSubType = "ERROR":U) ).
            RUN pi-lista-erros.
        end.
        if  l-erro THEN 
            return "NOK":U.
    end.
    return "OK":U.
end procedure.

procedure pi-desatualiza-wms:
    /*** fiscal soh desatualiza se nao houve fisico ***/
    /***   e se docum-est estah atualizado no wms   ***/
    if  docum-est.rec-fisico = no
    and docum-est.log-2 = yes then do:

        assign c-nro-docto-origem = string(docum-est.serie-docto,"x(5)")
                                  + string(docum-est.nro-docto,"x(16)")
                                  + string(docum-est.cod-emitente,">>>>>>>>9")
                                  + string(docum-est.nat-operacao).
        desalocacao:
        do on error undo desalocacao, leave desalocacao:
           FOR EACH rat-lote no-lock where
               rat-lote.nro-docto    = docum-est.nro-docto and
               rat-lote.serie-docto  = docum-est.serie-docto and
               rat-lote.cod-emitente = docum-est.cod-emitente and
               rat-lote.nat-operacao = docum-est.nat-operacao,
               FIRST deposito no-lock where
                     deposito.cod-depos = rat-lote.cod-depos,
               FIRST item no-lock where
                     item.it-codigo  = rat-lote.it-codigo and
                     item.tipo-contr <> 4:

               IF deposito.log-gera-wms = NO AND
                  deposito.ind-dep-cq = YES THEN DO:                   

                   RUN scbo/bosc048.p PERSISTENT SET hDBOSC048.
                   RUN getLocalDeposito IN hDBOSC048 (INPUT docum-est.cod-estabel,
                                                      INPUT rat-lote.cod-depos,
                                                      OUTPUT c-cod-local-wms).
                   IF c-cod-local-wms <> ? AND
                      not can-find(first tt-docto-receb where
                                         tt-docto-receb.cod-estabel = docum-est.cod-estabel and
                                         tt-docto-receb.cod-depos   = rat-lote.cod-depos    and
                                         tt-docto-receb.num-docto   = docum-est.nro-docto) then do:

                       IF i-pais-impto-usuario <> 1 AND docum-est.esp-docto = 20 THEN DO:
                           create tt-docto-receb.
                           assign tt-docto-receb.cod-estabel      = docum-est.cod-estabel
                                  tt-docto-receb.cod-depos        = rat-lote.cod-depos
                                  tt-docto-receb.num-docto        = docum-est.nro-docto
                                  tt-docto-receb.num-docto-origem = c-nro-docto-origem
                                  tt-docto-receb.ind-tipo-trans   = 2    /* saida */ 
                                  tt-docto-receb.ind-origem-docto = 22.  /* devolu‡Æo a fornecedor */
                       END.
                       ELSE DO:
                           create tt-docto-receb.
                           assign tt-docto-receb.cod-estabel      = docum-est.cod-estabel
                                  tt-docto-receb.cod-depos        = rat-lote.cod-depos
                                  tt-docto-receb.num-docto        = docum-est.nro-docto
                                  tt-docto-receb.num-docto-origem = c-nro-docto-origem
                                  tt-docto-receb.ind-tipo-trans   = 1   /* entrada */
                                  tt-docto-receb.ind-origem-docto = 3.  /* recebimento */
                       END.
                   END.
                   run destroy IN hDBOSC048.
                   DELETE OBJECT hDBOSC048 NO-ERROR.
               END.
               ELSE DO:
                    IF deposito.log-gera-wms = YES THEN DO:
                        if not can-find(first tt-docto-receb where
                            tt-docto-receb.cod-estabel = docum-est.cod-estabel and
                            tt-docto-receb.cod-depos   = rat-lote.cod-depos    and
                            tt-docto-receb.num-docto   = docum-est.nro-docto no-lock) then do:
    
                            IF i-pais-impto-usuario <> 1 AND docum-est.esp-docto = 20 THEN DO:
                                create tt-docto-receb.
                                assign tt-docto-receb.cod-estabel      = docum-est.cod-estabel
                                       tt-docto-receb.cod-depos        = rat-lote.cod-depos
                                       tt-docto-receb.num-docto        = docum-est.nro-docto
                                       tt-docto-receb.num-docto-origem = c-nro-docto-origem
                                       tt-docto-receb.ind-tipo-trans   = 2    /* saida */ 
                                       tt-docto-receb.ind-origem-docto = 22.  /* devolu‡Æo a fornecedor */
                            END.
                            ELSE DO:
                                create tt-docto-receb.
                                assign tt-docto-receb.cod-estabel      = docum-est.cod-estabel
                                       tt-docto-receb.cod-depos        = rat-lote.cod-depos
                                       tt-docto-receb.num-docto        = docum-est.nro-docto
                                       tt-docto-receb.num-docto-origem = c-nro-docto-origem
                                       tt-docto-receb.ind-tipo-trans   = 1   /* entrada */ 
                                       tt-docto-receb.ind-origem-docto = 3.  /* recebimento */
                            END.
                        END.
                    
                   /***********************Retirado para não desalocar 2 vezes
                        IF deposito.log-aloca-qtd-wms = YES THEN DO:
                            if item.tipo-con-est = 4 then do: /* referencia */
                                find b-item-doc-est
                               where b-item-doc-est.cod-emitente = rat-lote.cod-emitente
                                 and b-item-doc-est.serie-docto  = rat-lote.serie-docto
                                 and b-item-doc-est.nro-docto    = rat-lote.nro-docto
                                 and b-item-doc-est.nat-operacao = rat-lote.nat-operacao
                                 and b-item-doc-est.it-codigo    = rat-lote.it-codigo
                                 and b-item-doc-est.sequencia    = rat-lote.sequencia
                                 exclusive-lock no-error.
                            if avail b-item-doc-est THEN
                                assign c-cod-refer = b-item-doc-est.cod-refer.
                        end.
                       else assign c-cod-refer = rat-lote.cod-refer.
                       run cep/ceapi012.p (input docum-est.cod-estabel,
                                           input rat-lote.cod-depos,
                                           input rat-lote.it-codigo,
                                           input rat-lote.lote,
                                           input rat-lote.cod-localiz,
                                           input c-cod-refer,
                                           input rat-lote.quantidade).
                   end.
                   ************/
                    END.
               END.
               
                /*Elimina relacionamento cq x wms quando o documento serÿ desatualizado*/
                IF AVAIL param-estoq AND SUBSTRING(param-estoq.char-2,6,1) = "1" THEN
                    RUN wmp/wm9003.p (INPUT docum-est.cod-estabel,
                                      INPUT ROWID(rat-lote)).
           end.
           if can-find(first tt-docto-receb no-lock) then do:
               run wmp/wm9033.p (input  table tt-docto-receb,
                                 output l-erro-wms,
                                 output table RowErrors).

               if l-erro-wms = yes then do:
                   for each RowErrors:
                       create tt-erro.
                       assign tt-erro.i-sequen = RowErrors.errorSequence
                              tt-erro.cd-erro  = RowErrors.errorNumber
                              tt-erro.mensagem = RowErrors.errorDescription.
                   end.
               end.
               ELSE DO:
                   assign docum-est.log-2 = no.  /* indica que documento nao estÿ atualizado no WMS */

                   IF i-pais-impto-usuario <> 1 AND docum-est.esp-docto = 20 THEN DO:
                       for each b-item-doc-est {cdp/cd8900.i b-item-doc-est docum-est} exclusive-lock:
                           IF SUBSTRING(b-item-doc-est.char-2,939,1) = "3" /* Enviado  WMS */ THEN
                               ASSIGN OVERLAY(b-item-doc-est.char-2,939,1) = "2" /*NÆo Enviado para o WMS*/ .
                       END.
                   END.
               END.
           end.
           if l-erro-wms = yes then do:
              undo desalocacao, leave.
           end.
        end. /* undo */ 
    end.

end procedure.

procedure pi-desfaz-qtd-aloc-prod-wms:

    assign c-nro-docto-origem = string(docum-est.serie-docto,"x(5)")
                              + string(docum-est.nro-docto,"x(16)")
                              + string(docum-est.cod-emitente,">>>>>>>>9")
                              + string(docum-est.nat-operacao).

   FOR EACH rat-lote no-lock where
       rat-lote.nro-docto    = docum-est.nro-docto and
       rat-lote.serie-docto  = docum-est.serie-docto and
       rat-lote.cod-emitente = docum-est.cod-emitente and
       rat-lote.nat-operacao = docum-est.nat-operacao,
       FIRST deposito no-lock where
             deposito.cod-depos = rat-lote.cod-depos,
       FIRST item no-lock where
             item.it-codigo  = rat-lote.it-codigo and
             item.tipo-contr <> 4:

       IF deposito.log-gera-wms = NO AND
          deposito.ind-dep-cq = YES THEN DO:
           RUN scbo/bosc048.p PERSISTENT SET hDBOSC048.
           RUN getLocalDeposito IN hDBOSC048 (INPUT docum-est.cod-estabel,
                                              INPUT rat-lote.cod-depos,
                                              OUTPUT c-cod-local-wms).
           IF c-cod-local-wms <> ? AND
              not can-find(first tt-docto-receb where
                                 tt-docto-receb.cod-estabel = docum-est.cod-estabel and
                                 tt-docto-receb.cod-depos   = rat-lote.cod-depos    and
                                 tt-docto-receb.num-docto   = docum-est.nro-docto) then do:

                   IF i-pais-impto-usuario <> 1 AND docum-est.esp-docto = 20 THEN DO:

                           create tt-docto-receb.
                           assign tt-docto-receb.cod-estabel      = docum-est.cod-estabel
                                  tt-docto-receb.cod-depos        = rat-lote.cod-depos
                                  tt-docto-receb.num-docto        = docum-est.nro-docto
                                  tt-docto-receb.num-docto-origem = c-nro-docto-origem
                                  tt-docto-receb.ind-tipo-trans   = 2    /* saida */ 
                                  tt-docto-receb.ind-origem-docto = 22.  /* devolu‡Æo a fornecedor */
                   END.
                   ELSE DO:

                       create tt-docto-receb.
                       assign tt-docto-receb.cod-estabel      = docum-est.cod-estabel
                              tt-docto-receb.cod-depos        = rat-lote.cod-depos
                              tt-docto-receb.num-docto        = docum-est.nro-docto
                              tt-docto-receb.num-docto-origem = c-nro-docto-origem
                              tt-docto-receb.ind-tipo-trans   = 1   /* entrada */
                              tt-docto-receb.ind-origem-docto = 3.  /* recebimento */
                   END.
           END.
           run destroy IN hDBOSC048.
           DELETE OBJECT hDBOSC048 NO-ERROR.
           END.
       ELSE
            IF deposito.log-gera-wms = YES THEN DO:
                if not can-find(first tt-docto-receb where
                    tt-docto-receb.cod-estabel = docum-est.cod-estabel and
                    tt-docto-receb.cod-depos   = rat-lote.cod-depos    and
                    tt-docto-receb.num-docto   = docum-est.nro-docto no-lock) then do:

                    IF i-pais-impto-usuario <> 1 AND docum-est.esp-docto = 20 THEN DO:

                           create tt-docto-receb.
                           assign tt-docto-receb.cod-estabel      = docum-est.cod-estabel
                                  tt-docto-receb.cod-depos        = rat-lote.cod-depos
                                  tt-docto-receb.num-docto        = docum-est.nro-docto
                                  tt-docto-receb.num-docto-origem = c-nro-docto-origem
                                  tt-docto-receb.ind-tipo-trans   = 2    /* saida */ 
                                  tt-docto-receb.ind-origem-docto = 22.  /* devolu‡Æo a fornecedor */
                    END.
                    ELSE DO:

                        create tt-docto-receb.
                        assign tt-docto-receb.cod-estabel      = docum-est.cod-estabel
                               tt-docto-receb.cod-depos        = rat-lote.cod-depos
                               tt-docto-receb.num-docto        = docum-est.nro-docto
                               tt-docto-receb.num-docto-origem = c-nro-docto-origem
                               tt-docto-receb.ind-tipo-trans   = 1   /* entrada */ 
                               tt-docto-receb.ind-origem-docto = 3.  /* recebimento */
                    END.
                END.
       END.
   end.
   if can-find(first tt-docto-receb no-lock) then do:
       run wmp/wm9037.p (input  table tt-docto-receb).
   end.

end procedure.

/*--- Execucao Orcamentaria EMS 5 - Datasul Financas ---*/
PROCEDURE pi-execucao-orcamentaria:
    &if "{&mgadm_version}" >= "2.04" &then
    run cdp/cd1005o.p (input 2,
                       input i-empresa,
                       input 0,
                       input "",
                       input "",
                       input "",
                       input "",
                       input 0,
                      &IF "{&bf_mat_versao_ems}" >= "2.062" &THEN
                       input "",
                      &ENDIF
                       input-output v-sequencia-1,
                       input-output table tt_xml_input_1,
                       output table tt_log_erros).
    if return-value = "NOK":U then do:
        for each tt_log_erros:
            run pi-erro-nota (input 25997,
                              input tt_log_erros.ttv_des_erro + tt_log_erros.ttv_des_ajuda,
                              input yes).
        end.
        return.
    end.
&endif
END PROCEDURE.

PROCEDURE pi-pre-valida-mri:
    /*Faz validacao da bem-invest*/
    &IF  "{&bf_dis_versao_ems}":U >= "2.04":U &THEN
        IF  {cdp/cd9870.i1 docum-est.cod-estabel "MRE"} THEN DO:
            RUN rip/ri0402a.p (INPUT ROWID(docum-est),
                               OUTPUT TABLE tt-erro-mri).
        END.
    &ENDIF
END.

PROCEDURE pi-recuperacao-impostos:
    /** Integracao Modulo de Recupera¯Êo de Impostos **/
    IF INT(SUBSTR(docum-est.char-1,92,1)) = 1 THEN DO:
        IF  {cdp/cd9870.i1 docum-est.estab-fisc "MRE"} THEN DO:
            /*Caso nÆo retorne erro na verifica‡Æo da bem-invest ele executa ri1005*/
            IF NOT CAN-FIND(FIRST tt-erro-mri NO-LOCK) THEN DO:
                EMPTY TEMP-TABLE tt-erro-aux.
                RUN rip/ri1005.p (INPUT "desatualizacao":U,
                                  INPUT ROWID(docum-est),
                                  INPUT ?,
                                  INPUT-OUTPUT TABLE tt-erro-aux).
                FOR EACH tt-erro-aux:
                    CREATE tt-erro.
                    BUFFER-COPY tt-erro-aux TO tt-erro.
                END.
            END.
        END.
    END.
END PROCEDURE.

PROCEDURE pi-epc-fim-atualizacao:
    for each tt-epc
        where tt-epc.cod-event = "Fim-Atualizacao".
        delete tt-epc.
    end.
    
    create tt-epc.
    assign tt-epc.cod-event     = "Fim-Atualizacao"
           tt-epc.cod-parameter = "docum-est-rowid"
           tt-epc.val-parameter = string(rowid(docum-est)).
    
    {include/i-epc201.i "Fim-Atualizacao"}
END PROCEDURE.
    
PROCEDURE pi-desatualiza-cr:
    DEF OUTPUT PARAM p-erro AS LOG INIT NO NO-UNDO.

    FOR EACH tt_nota_devol: DELETE tt_nota_devol. END.
    FOR EACH tt_log_erros:  DELETE tt_log_erros.  END.

    &IF defined(bf_devolucao_exportacao) &THEN
        {rep/re0402a.i7}
    &ENDIF
    

    CREATE tt_nota_devol.
    ASSIGN tt_nota_devol.tta_cod_ser_nota_devol     = docum-est.serie-docto
           tt_nota_devol.tta_cod_natur_operac_devol = docum-est.nat-operacao
           tt_nota_devol.tta_cdn_cliente            = docum-est.cod-emitente.

    IF  docum-est.nat-operacao BEGINS "3" AND
        emitente.natureza = 3  THEN DO:
        FIND FIRST item-doc-est 
                WHERE item-doc-est.nro-docto    = docum-est.nro-docto 
                  AND item-doc-est.serie-docto  = docum-est.serie-docto 
                  AND item-doc-est.cod-emitente = docum-est.cod-emitente
                  AND item-doc-est.nat-operacao = docum-est.nat-operacao NO-LOCK NO-ERROR.
    
        find nota-fiscal 
           where nota-fiscal.cod-estabel = docum-est.cod-estabel 
           and nota-fiscal.serie         = item-doc-est.serie-comp 
           and nota-fiscal.nr-nota-fis   = item-doc-est.nro-comp no-lock no-error.
    
        IF AVAIL nota-fiscal THEN
            i-nr-fatura  = if ( nota-fiscal.ind-tip-nota = 1       /* Sistema */
                           or   nota-fiscal.ind-tip-nota = 3       /* Diferenca Preco */
                           or   nota-fiscal.ind-tip-nota = 4 )     /* Complementar */
                           and  emitente.natureza = 3               /* Estrangeiro */
                           and  nota-fiscal.nr-proc-exp > " "
                           and  para-fat.ind-docum-fatura = 2 then
                                nota-fiscal.nr-proc-exp
                           else 
                                nota-fiscal.nr-fatura.
    
        ASSIGN tt_nota_devol.tta_cod_nota_devol         = i-nr-fatura.
    END.

    ELSE 
        ASSIGN tt_nota_devol.tta_cod_nota_devol = docum-est.nro-docto.
  
    &IF defined(bf_devolucao_exportacao) &THEN
        {rep/re0402a.i8}
    &ENDIF

    IF  NOT valid-handle(h-acr924za)
    OR  h-acr924za:TYPE      <> "procedure":U
    OR  h-acr924za:FILE-NAME <> "prgfin/acr/acr924za.py":U THEN
        RUN prgfin/acr/acr924za.py PERSISTENT SET h-acr924za (INPUT 1).
    RUN pi_desatualiza_devolucao IN h-acr924za (INPUT TABLE tt_nota_devol,
                                                INPUT "", /* p_cod_refer_tit */
                                                INPUT param-global.empresa-prin,
                                                OUTPUT TABLE tt_log_erros).
    IF  CAN-FIND(FIRST tt_log_erros) THEN DO:
        FIND LAST tt-erro NO-ERROR.
        ASSIGN i-seq-erro = IF  AVAIL tt-erro THEN tt-erro.i-sequen + 1 ELSE 1.
        for each tt_log_erros:
            create tt-erro.
            assign tt-erro.i-sequen = i-seq-erro
                   tt-erro.cd-erro  = tt_log_erros.ttv_num_cod_erro
                   tt-erro.mensagem = tt_log_erros.ttv_des_erro + CHR(10) + tt_log_erros.ttv_des_ajuda
                   p-erro = YES.
        end.
    END.
    ELSE /* Se nÆo encontrou erro, atualiza documento com CR nÆo atualizado */
        ASSIGN docum-est.cr-atual = NO.
    RETURN "OK":U.
END PROCEDURE.

PROCEDURE pi-desatualiza-remito:
    find  it-remito
        where it-remito.cod-estabel = docum-est.cod-estabel
          and it-remito.serie       = item-doc-est.serie-comp
          and it-remito.nr-remito   = item-doc-est.nro-comp
          and it-remito.nr-seq-item = item-doc-est.seq-comp
          and it-remito.it-codigo   = item-doc-est.it-codigo
        exclusive-lock no-error.
    if  avail it-remito then do:
        assign it-remito.dec-1 = it-remito.dec-1 - item-doc-est.quantidade.
        if  it-remito.dec-1 < 0 THEN
            assign it-remito.dec-1 = 0.
        assign it-remito.dec-2 = it-remito.qt-pedida - it-remito.qt-faturada - it-remito.dec-1.
    end.
END.

PROCEDURE pi-desatualiza-lote:
    for each rat-lote {cdp/cd8900.i rat-lote item-doc-est}
             and rat-lote.sequencia = item-doc-est.sequencia exclusive-lock:
        for each lote-compr use-index nr-nota                 
           where lote-compr.cod-emitente = rat-lote.cod-emitente
            and lote-compr.serie-nf     = rat-lote.serie-docto
            and lote-compr.nr-nota-fis  = rat-lote.nro-docto
            and lote-compr.it-codigo    = rat-lote.it-codigo
            and lote-compr.lote         = rat-lote.lote
            exclusive-lock:
            if lote-compr.qtd-recebida >= rat-lote.quantidade
            then assign lote-compr.qtd-recebida = lote-compr.qtd-recebida
                                                  - rat-lote.quantidade.
            else assign lote-compr.qtd-recebida = 0.
           if  lote-compr.qtd-recebida = 0
           and lote-compr.qtd-devolvida = 0 then
               delete lote-compr.
        end.

        if  (   docum-est.esp-docto = 20 
             and can-find(first natur-oper
                          where natur-oper.nat-operacao = docum-est.nat-operacao
                          and   natur-oper.tipo = 1))
        OR  can-find(first natur-oper
                     where natur-oper.nat-operacao = docum-est.nat-operacao
                     and   natur-oper.terceiros  
                     and   natur-oper.tp-oper-terc = 5) THEN DO: /* devolução de consignacao */
             find lote-vend use-index nr-nota 
                  where lote-vend.serie      = item-doc-est.serie-comp  
                  and lote-vend.nr-nota-fis  = item-doc-est.nro-comp    
                  and lote-vend.cod-emitente = rat-lote.cod-emitente
                  and lote-vend.it-codigo    = rat-lote.it-codigo
                  and lote-vend.lote         = rat-lote.lote  exclusive-lock no-error.
            if  not  avail lote-vend then 
                 find first lote-vend
                      where lote-vend.cod-emitente = rat-lote.cod-emitente
                      and lote-vend.it-codigo      = rat-lote.it-codigo
                      and lote-vend.lote           = rat-lote.lote
                      and lote-vend.cod-refer      = item-doc-est.cod-refer exclusive-lock no-error.
             if  avail lote-vend then 
                 assign lote-vend.qtd-devolvida = lote-vend.qtd-devolvida - rat-lote.quantidade.
        end.
    END.
END PROCEDURE.    

PROCEDURE pi-estorno-acabado:
    if  l-desatualiza-aca THEN do:
        for each movto-pend fields ( cod-emitente   serie-docto nro-docto
                                     nat-operacao   tipo        nr-reporte)
           where movto-pend.cod-emitente = docum-est.cod-emitente
             and movto-pend.serie-docto  = docum-est.serie-docto
             and movto-pend.nro-docto    = docum-est.nro-docto
             and movto-pend.nat-operacao = docum-est.nat-operacao
             and movto-pend.tipo         = 1 no-lock:  /* Acabado */
            
            create tt-rep-prod.
            assign tt-rep-prod.cod-versao-integracao = 001
                   tt-rep-prod.nr-reporte            = movto-pend.nr-reporte
                   tt-rep-prod.data                  = docum-est.dt-trans.
        end.

        IF CAN-FIND(FIRST tt-rep-prod) THEN DO:
            run cpp/cpapi011.p ( input        table tt-rep-prod,
                                 input-output table tt-erro,
                                 input        table tt-relatorio,
                                 input        no ).

        /** Tratamento inclu¡do para nÆo permitir desatualizar o documento quando
                este possui mais que uma ordem de produ‡Æo e nÆo foi gerado moc=vimento EAC **/
            &if defined (CUSTOM_GRENDENE) &then
                if can-find(first tt-erro) then do:
                     assign l-erro = yes.
                     return.
                end.
            &endif                            
    
            if  return-value <> "OK" then do:
                assign l-erro = yes.
                RETURN "NOK":U.
            end.
        END.
             
        assign docum-est.cp-atual = no.
    end.

    RETURN "OK":U.

END PROCEDURE.

PROCEDURE pi-verif-movto-item-entr-st:
   
    FOR FIRST item-entr-st EXCLUSIVE-LOCK
        WHERE item-entr-st.cod-estab           = docum-est.cod-estabel
        AND   item-entr-st.cod-serie           = docum-est.serie-docto  
        AND   item-entr-st.cod-docto           = docum-est.nro-docto      
        AND   item-entr-st.cod-natur-operac    = docum-est.nat-operacao 
        AND   item-entr-st.cod-emitente        = string(docum-est.cod-emitente):
        
        IF item-entr-st.qtd-sdo-final <> item-entr-st.val-livre-1 THEN DO:
            
           find last tt-erro no-error.
           if  avail tt-erro then
               assign i-seq-erro = tt-erro.i-sequen + 1.
           ELSE
               assign i-seq-erro = 1.
        
           create tt-erro.
           assign tt-erro.i-sequen = i-seq-erro
                  tt-erro.cd-erro  = 35879.


            run utp/ut-msgs.p (input 'msg', input 35879, input '').
            assign tt-erro.mensagem = return-value.
        
        END.
        ELSE DO:
            DELETE item-entr-st.
        END.
    END.
END PROCEDURE.

PROCEDURE pi-desatualiza-antecip-import:
    /*
    ** Procedure respons vel por retirar as informa‡äes do documento
    ** na tabela antecip-import: serie-docto nro-docto cdn-emitente 
    ** nat-operacao dat-cotac-nacionaliz e val-cotac-nacionaliz
    */ 

    IF NOT VALID-HANDLE(h-bocx00451) THEN
        RUN cxbo/bocx00451.p PERSISTENT SET h-bocx00451.

    RUN deleteRelacDocum-est IN h-bocx00451 (INPUT docum-est.serie-docto,  
                                             INPUT docum-est.nro-docto,    
                                             INPUT docum-est.cod-emitente, 
                                             INPUT docum-est.nat-operacao). 
    IF VALID-HANDLE(h-bocx00451) THEN DO:
        DELETE PROCEDURE h-bocx00451.
        ASSIGN h-bocx00451 = ?.
    END.


    RETURN "OK":U.
END PROCEDURE.

return "OK":U.
/* Fim do Programa */

PROCEDURE pi-rowid:
    DEFINE OUTPUT PARAM TABLE FOR tt-rowid-movto-estoq.
END.


