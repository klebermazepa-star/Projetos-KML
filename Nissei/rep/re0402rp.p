/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0402RP 2.00.01.042 } /*** "010142" ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0402rp MRE}
&ENDIF

{include/i_fnctrad.i}
/******************************************************************************
**
**       Programa: RE0402
**
**       Objetivo: Desatualizacao de Notas Fiscais
**
**       Versao..: 1.00.000
**
******************************************************************************/

  DEF NEW GLOBAL SHARED VAR i-ep-codigo-usuario AS CHARACTER FORMAT "x(3)":U LABEL "Empresa" COLUMN-LABEL "Empresa" NO-UNDO.
  DEF NEW GLOBAL SHARED VAR v_cod_empres_usuar AS CHARACTER FORMAT "x(3)":U LABEL "Empresa" COLUMN-LABEL "Empresa" NO-UNDO.




{utp/ut-glob.i}
{cdp/cdcfgmat.i}
{cdp/cdcfgcex.i}
{cdp/cd0666.i}
{cdp/cd0031.i "MRE"} /* Seguranáa por Estabelecimento */


DEF TEMP-TABLE tt-raw-digita 
    FIELD raw-digita AS RAW.

{include/tt-edit.i}
/*{rep/re0402.i1}*/

{include/i-epc200.i "RE0402RP"} /* Definiá∆o TT-EPC */

/* Definiá∆o Temp-Table */
{rep/re0402.i3}
{btb/btb009za.i}

DEF INPUT PARAM raw-param AS RAW NO-UNDO.
DEF INPUT PARAM table FOR tt-raw-digita.

DEF TEMP-TABLE tt-rowid-movto-estoq    NO-UNDO FIELD r-rowid AS ROWID
    INDEX ch-id IS PRIMARY r-rowid.

FOR EACH tt-raw-digita:
    CREATE tt-digita.
    RAW-TRANSFER tt-raw-digita.raw-digita TO tt-digita.
END.

DEFINE BUFFER b-tt-digita FOR tt-digita.

DEF BUFFER b-item-doc-est  FOR item-doc-est.
DEF BUFFER b-docum-est     FOR docum-est.
DEF BUFFER b2-item-doc-est FOR item-doc-est.
DEF TEMP-TABLE tt-item-doc-est-fat NO-UNDO LIKE item-doc-est.
DEFINE NEW GLOBAL SHARED VARIABLE v_log_eai_habilit AS LOG  NO-UNDO.
DEF VAR l-integra-eai       AS LOGICAL      NO-UNDO.
DEF VAR l-integra-ems-his   AS LOGICAL      NO-UNDO.
DEF VAR l-enviar            AS LOGICAL      NO-UNDO.

DEF VAR i-cont-progs AS INTEGER NO-UNDO.
DEF VAR l-executado-ft0911 AS LOGICAL NO-UNDO.

DEF VAR h-acomp            AS HANDLE  NO-UNDO.
DEF VAR h-re0402a          AS HANDLE  NO-UNDO.
DEF VAR h-btb009za         AS HANDLE  NO-UNDO.

&IF '{&bf_mat_versao_ems}' >= '2.08' AND '{&bf_mat_integra_eai2}' = 'YES' &THEN
    /* Integraá∆o EMS EAI2.0 Mensagem unica */
    DEFINE NEW GLOBAL SHARED VARIABLE v_log_eai2_ativado AS LOGICAL NO-UNDO INITIAL NO.    
    DEFINE VARIABLE h-ceapi311 AS HANDLE NO-UNDO.
    DEFINE VARIABLE h-ceapi310 AS HANDLE NO-UNDO.
&ENDIF

&if "{1}" = "" &then
DEF VAR i-cont             AS INTEGER NO-UNDO.
&endif

DEF VAR l-ja-conectado  AS LOGICAL                    NO-UNDO.
DEF VAR l-erro       AS LOG  NO-UNDO.
DEF VAR l-ems50      AS LOG  NO-UNDO.     
DEF VAR l-ems50-cr   AS LOG  NO-UNDO.
DEF VAR c-upc-parameters AS CHAR NO-UNDO.
{rep/re0402d.i1}
DEF VAR l-gerou-nc AS LOG NO-UNDO.
DEF VAR l-estornou AS LOG NO-UNDO.
/* Funcao define se havera integracao entre o ERP e o HIS - Sistema Hospitalar */
ASSIGN l-integra-ems-his =  CAN-FIND (FIRST funcao
                                      WHERE funcao.cd-funcao = "spp-integra-ems-his":U
                                      AND   funcao.ativo     = YES).

IF v_log_eai_habilit THEN
    ASSIGN l-integra-eai = YES.

DEF VAR l-saldo-neg AS LOGICAL NO-UNDO.
DEF VAR v-sequencia-1       AS INTEGER NO-UNDO.
DEF VAR v-sequencia-2       AS INTEGER NO-UNDO.

/* Variˇveis p/ p†gina de parÉmetros */
DEF VAR c-mensagem   AS CHAR FORMAT "x(90)" LABEL "Observaá‰es".
DEF VAR l-param      LIKE param-global.exp-cep NO-UNDO.
DEF VAR c-lb-data    AS CHAR NO-UNDO.
DEF VAR c-lb-espec   AS CHAR NO-UNDO.
DEF VAR c-lb-serie   AS CHAR NO-UNDO.
DEF VAR c-lb-docto   AS CHAR NO-UNDO.
DEF VAR c-lb-emite   AS CHAR NO-UNDO.
DEF VAR c-lb-natur   AS CHAR NO-UNDO.
DEF VAR c-lb-estab   AS CHAR NO-UNDO.
DEF VAR c-lb-atual   AS CHAR NO-UNDO.
DEF VAR c-lb-usuario AS CHAR NO-UNDO.
DEF VAR c-lb-of      AS CHAR NO-UNDO.
DEF VAR c-lb-saldo   AS CHAR NO-UNDO.
DEF VAR c-lb-fatur   AS CHAR NO-UNDO.
DEF VAR c-lb-custo   AS CHAR NO-UNDO.
DEF VAR c-lb-ap      AS CHAR NO-UNDO.
DEF VAR c-lb-preco   AS CHAR NO-UNDO.
DEF VAR c-lb-dest    AS CHAR NO-UNDO.
DEF VAR c-lb-usuar   AS CHAR NO-UNDO.
DEF VAR c-lb-param   AS CHAR NO-UNDO.
DEF VAR c-lb-selec   AS CHAR NO-UNDO.
DEF VAR c-lb-digit   AS CHAR NO-UNDO.
DEF VAR c-lb-impr    AS CHAR NO-UNDO.
DEF VAR c-lb-draw    AS CHAR NO-UNDO.
DEF VAR c-lb-acr     AS CHAR NO-UNDO.
DEF VAR c-titulo-lit AS CHAR NO-UNDO.
DEF VAR c-cancel-lit AS CHAR NO-UNDO.
DEF VAR c-total-lit  AS CHAR NO-UNDO.    
DEF VAR c-destino    AS CHAR NO-UNDO.
DEF VAR c-msg        AS CHAR FORMAT "x(25)" NO-UNDO.
DEF VAR h-cdapi050   AS HANDLE NO-UNDO.

DEF VAR i-empresa LIKE param-global.empresa-prin NO-UNDO.

/*NF-e*/
DEFINE NEW GLOBAL SHARED VARIABLE gc-NFe-docs-a-desatu-re0402 AS CHAR NO-UNDO.
ASSIGN gc-NFe-docs-a-desatu-re0402 = "".
DEF VAR h-axsep002       AS HANDLE    NO-UNDO.
DEF VAR i-tipo-transacao AS INTEGER   NO-UNDO. /* 1 - Sincrona | 2 - Assincrona */
DEF VAR tp-integ         AS CHARACTER NO-UNDO.

DEFINE TEMP-TABLE tt_nfe_erro NO-UNDO
    FIELD cStat     AS CHAR   
    FIELD chNFe     AS CHAR   
    FIELD dhRecbto  AS CHAR   
    FIELD nProt     AS CHAR.  

DEFINE TEMP-TABLE tt_log_erro NO-UNDO
    FIELD ttv_num_cod_erro  AS INTEGER   INITIAL ?
    FIELD ttv_des_msg_ajuda AS CHARACTER INITIAL ?
    FIELD ttv_des_msg_erro  AS CHARACTER INITIAL ?.

DEFINE TEMP-TABLE RowErrors NO-UNDO
    FIELD ErrorSequence    AS INTEGER
    FIELD ErrorNumber      AS INTEGER
    FIELD ErrorDescription AS CHARACTER
    FIELD ErrorParameters  AS CHARACTER
    FIELD ErrorType        AS CHARACTER
    FIELD ErrorHelp        AS CHARACTER
    FIELD ErrorSubType     AS CHARACTER.

DEFINE TEMP-TABLE tt-erro-nfe NO-UNDO LIKE tt-erro.
/*fim NF-e*/

/*  para n„o alterar a chamada do re0402a.p */
/*  foi criada a vari†vel global abaixo     */ 
/*  a mesma È usada no re0402b.p            */
DEFINE NEW GLOBAL SHARED VARIABLE gc-mot-canc-fat-re0402 AS CHAR NO-UNDO.


/* TOTVS COLABORAÄ«O 2.0 */
def temp-table tt-dados-evento no-undo
  field cod-estab               like nota-fiscal.cod-estabel
  field cod-serie               like nota-fiscal.serie
  field cod-nota-fis            like nota-fiscal.nr-nota-fis
  field desc-evento             as char format "x(100)"
  field num-seq                 like carta-correc-eletro.num-seq
  field cod-versao              like carta-correc-eletro.cod-versao
  field dsl-evento              like carta-correc-eletro.dsl-carta-correc-eletro
  field des-dat-hora-event      like carta-correc-eletro.des-dat-hora-event
  field r-rowid                 as rowid
  index ch-nota is primary
        cod-estab   
        cod-serie   
        cod-nota-fis.

{cdp/cdcfgdis.i}

{include/i-rpvar.i}
RUN utp/ut-acomp.p PERSISTENT SET h-acomp.
{utp/ut-liter.i Desatualizaá∆o_de_Documentos *}
RUN pi-inicializar IN h-acomp ( RETURN-VALUE ).
{utp/ut-liter.i "Titulo"}
ASSIGN c-titulo-lit = RETURN-VALUE.

{utp/ut-liter.i "Cancelamento"}
ASSIGN c-cancel-lit = RETURN-VALUE.

{utp/ut-liter.i "Total"}
ASSIGN c-total-lit = RETURN-VALUE.

FIND FIRST param-global NO-LOCK NO-ERROR.
FIND FIRST param-estoq  NO-LOCK NO-ERROR.

FIND param-re WHERE param-re.usuario = c-seg-usuario NO-LOCK NO-ERROR.

&IF '{&mgdis_version}' = '2.06f' &THEN
    ASSIGN i-empresa           = param-global.empresa-prin
           i-ep-codigo-usuario = STRING(param-global.empresa-prin). /* este assign Ç necessario para que n∆o ocorram 
                                                                     erros na integraá∆o com o EMS 5. */
&ELSE
    ASSIGN i-empresa = param-global.empresa-prin.
&ENDIF

&if defined (bf_dis_consiste_conta) &then

    FIND estabelec WHERE
         estabelec.cod-estabel = param-estoq.estabel-pad NO-LOCK NO-ERROR.

    RUN cdp/cd9970.p (INPUT ROWID(estabelec),
                      OUTPUT i-empresa).
&endif

FIND empresa WHERE
     empresa.ep-codigo = i-ep-codigo-usuario NO-LOCK NO-ERROR.

CREATE tt-param.
RAW-TRANSFER raw-param TO tt-param.

ASSIGN l-saldo-neg = tt-param.l-saldo.
ASSIGN c-empresa  = (IF AVAILABLE empresa THEN empresa.razao-social ELSE "")
       c-programa = "RE/0402"
       c-versao   = "1.00"
       c-revisao  = "000".

DEF FRAME f-docto
    docum-est.nro-docto
    docum-est.serie-docto
    docum-est.cod-emitente
    docum-est.nat-operacao
    tt-erro.cd-erro                  COLUMN-LABEL "Erro"
    tt-erro.mensagem FORMAT "x(77)"  COLUMN-LABEL "Mensagem"
    WITH STREAM-IO WIDTH 132 DOWN FRAME f-docto.

{utp/ut-liter.i Desatualizaá∆o_de_Notas_Fiscais * r}
ASSIGN c-titulo-relat = TRIM(RETURN-VALUE).
{utp/ut-liter.i RECEBIMENTO * r}
ASSIGN c-sistema = TRIM(RETURN-VALUE).

RUN utp/ut-trfrrp.p (INPUT FRAME f-docto:handle).
{include/i-rpcab.i}

{include/i-rpout.i}

ASSIGN l-ems50    = CAN-FIND(FIRST funcao WHERE funcao.cd-funcao = "adm-apb-ems-5.00"
                                       AND funcao.ativo
                                       AND funcao.log-1 )
       l-ems50-cr = CAN-FIND(FIRST funcao WHERE funcao.cd-funcao = "adm-acr-ems-5.00"
                                       AND funcao.ativo
                                       AND funcao.log-1 ).
VIEW FRAME f-cabec.
VIEW FRAME f-rodape.

IF  l-ems50 
OR  l-ems50-cr THEN DO:
    IF  SEARCH("prgint/dcf/dcf900za.r")  = ? 
    AND SEARCH("prgint/dcf/dcf900za.py") = ? THEN DO:
        RUN pi-erro-nota ( 6246, "prgint/dcf/dcf900za.py", YES ).
        RUN pi-finalizar IN h-acomp.
        RUN pi-lista-erros.

        RETURN.        
    END.

    RUN pi-conecta-ems50 ( 1 ). /* 1 = conecta */
    IF l-erro THEN DO:
       {include/i-rpclo.i}
       RUN pi-finalizar IN h-acomp.
       UNDO, RETURN "NOK".
    END.  
END.    

&IF '{&bf_mat_versao_ems}' >= '2.08' AND '{&bf_mat_integra_eai2}' = 'YES' &THEN
    /* Carrega a vari·vel global v_log_eai2_ativado */
    RUN cdp/cd0101i.p.

    IF NOT VALID-HANDLE(h-ceapi310) OR
          h-ceapi310:TYPE <> "PROCEDURE":U OR
          h-ceapi310:FILE-NAME <> "cep/ceapi310.p":U THEN DO:
          RUN cep/ceapi310.p PERSISTENT SET h-ceapi310.
    END.

    /* Integraá∆o EMS EAI2.0 Mensagem unica */
    IF v_log_eai2_ativado THEN 
       IF NOT VALID-HANDLE(h-ceapi311) OR
          h-ceapi311:TYPE <> "PROCEDURE":U OR
          h-ceapi311:FILE-NAME <> "cep/ceapi311.p":U THEN DO:
          RUN cep/ceapi311.p PERSISTENT SET h-ceapi311.
    END. 
&ENDIF   
      
VIEW FRAME f-cabec.
VIEW FRAME f-rodape.


IF NOT VALID-HANDLE(h-cdapi050) THEN
    RUN cdp/cdapi050.p PERSISTENT SET h-cdapi050.

/* Leitura dos documentos */
/* Se for utilizado a digitaá∆o de documentos, a seleá∆o ser† ignorada */
DO WITH FRAME f-docto:
    FIND FIRST tt-digita NO-ERROR.
    IF AVAILABLE tt-digita THEN DO:
        bloco:
        FOR EACH tt-digita TRANSACTION:

            FIND docum-est WHERE
                 docum-est.serie-docto  = tt-digita.serie-docto  AND
                 docum-est.nro-docto    = tt-digita.nro-docto    AND
                 docum-est.cod-emitente = tt-digita.cod-emitente AND
                 docum-est.nat-operacao = tt-digita.nat-operacao NO-LOCK NO-ERROR.
                 

            IF NOT AVAIL docum-est THEN 
                NEXT.

            IF  NOT docum-est.ce-atual  THEN
                NEXT.
             
            /* Seguranáa por estabelecimento */ 
            {cdp/cd0031a.i docum-est.cod-estabel}     

            IF  tt-param.l-of <> YES THEN
            DO:
                RUN pi-valida-medio.

                IF l-erro THEN  DO:
                    RUN pi-lista-erros.

                    ASSIGN l-erro = NO.
                    NEXT bloco.
                END.    
            END.

            IF AVAIL param-re AND 
                docum-est.origem = "G":U AND
               (SUBSTRING(param-re.char-1,26,1) <> "S":U AND
                SUBSTRING(param-re.char-1,26,1) <> "":U) THEN DO:
                
                RUN pi-erro-nota ( 6825, " ", YES).
                RUN pi-lista-erros.
                ASSIGN l-erro = NO.
                NEXT bloco.

            END.

            ASSIGN l-erro = NO.

            RUN pi-efetiva.

            IF  l-erro THEN
                UNDO bloco, NEXT bloco.
        END.
    END.
    ELSE DO:
        /* Passou a ler os documentos utilizando o °ndice 'emitente' quando for 
           selecionado apenas um emitente(alteraá∆o feita por solicitaá∆o da Grendene) */
        IF  tt-param.i-emit-ini = tt-param.i-emit-fim THEN DO:
            {rep/re0402.i5 "use-index emitente"}
        END.
        ELSE DO:
            {rep/re0402.i5 "use-index documento"}
        END.
    END.
END.

IF  l-ems50 
OR  l-ems50-cr THEN
    RUN pi-conecta-ems50 ( 2 ). /* Disconecta bancos do EMS 5.0 */

IF  VALID-HANDLE (h-btb009za) AND
h-btb009za:TYPE = "PROCEDURE":U AND
h-btb009za:FILE-NAME = "btb/btb009za.p":U THEN DO:
    DELETE PROCEDURE h-btb009za.
    ASSIGN h-btb009za = ?.
END.

&IF '{&bf_mat_versao_ems}' >= '2.08' AND '{&bf_mat_integra_eai2}' = 'YES' &THEN

    /* Integraá∆o EMS EAI2.0 Mensagem unica */ 
    IF VALID-HANDLE(h-ceapi310) AND
       h-ceapi310:TYPE = "PROCEDURE":U AND
       h-ceapi310:FILE-NAME = "cep/ceapi310.p":U THEN DO:
       DELETE PROCEDURE h-ceapi310 NO-ERROR.
       ASSIGN h-ceapi310 = ?.
    END. 

    /* Integraá∆o EMS EAI2.0 Mensagem unica */    
    IF VALID-HANDLE(h-ceapi311) AND
       h-ceapi311:TYPE = "PROCEDURE":U AND
       h-ceapi311:FILE-NAME = "cep/ceapi311.p":U THEN DO:
       DELETE PROCEDURE h-ceapi311 NO-ERROR.
       ASSIGN h-ceapi311 = ?.
    END.  
&ENDIF    

/*--- NF-e ---*/
IF  CAN-FIND (FIRST funcao 
              WHERE funcao.cd-funcao = "spp-nfe":U 
                AND funcao.ativo) THEN
    RUN pi-Trata-Cancel-NFe.
/*--- fim NF-e ---*/
/*** Siscoserv ***/
IF VALID-HANDLE(h-cdapi050) THEN DO:
    DELETE PROCEDURE h-cdapi050.
    ASSIGN h-cdapi050 = ?.
END.
/*** Siscoserv ***/


{utp/ut-liter.i Desatualiza_apenas_OF * r}
ASSIGN c-lb-of = TRIM(RETURN-VALUE).
{utp/ut-liter.i Desatualiza_Itens_com_Saldo_Negativo * r}
ASSIGN c-lb-saldo = TRIM(RETURN-VALUE).
{utp/ut-liter.i Desatualiza_Nota_Fiscal_do_Faturamento * r}
ASSIGN c-lb-fatur = TRIM(RETURN-VALUE).
{utp/ut-liter.i Desatualiza_Nota_Fiscal_com_data_inferior_custo_padrao * r}
ASSIGN c-lb-custo = TRIM(RETURN-VALUE).
{utp/ut-liter.i Desatualiza_Contas_a_Pagar * r}
ASSIGN c-lb-ap = TRIM(RETURN-VALUE).
{utp/ut-liter.i Desatualiza_Contas_a_Receber * r}
ASSIGN c-lb-acr = TRIM(RETURN-VALUE).
{utp/ut-liter.i Desatualiza_Drawback * r}
ASSIGN c-lb-draw = TRIM(RETURN-VALUE).
{utp/ut-liter.i Data_Transaá∆o * r}
ASSIGN c-lb-data = TRIM(RETURN-VALUE).
{utp/ut-liter.i EspÇcie * r}
ASSIGN c-lb-espec = TRIM(RETURN-VALUE).
{utp/ut-liter.i SÇrie * r}
ASSIGN c-lb-serie = TRIM(RETURN-VALUE).
{utp/ut-liter.i Documento * r}
ASSIGN c-lb-docto = TRIM(RETURN-VALUE).
{utp/ut-liter.i Emitente * r}
ASSIGN c-lb-emite = TRIM(RETURN-VALUE).
{utp/ut-liter.i Natureza * r}
ASSIGN c-lb-natur = TRIM(RETURN-VALUE).
{utp/ut-liter.i Estabelecimento * r}
ASSIGN c-lb-estab = TRIM(RETURN-VALUE).
{utp/ut-liter.i Data_Atualizaá∆o * r}
ASSIGN c-lb-atual = TRIM(RETURN-VALUE).
{utp/ut-liter.i Usu†rio * r}
ASSIGN c-lb-usuario = TRIM(RETURN-VALUE).
{utp/ut-liter.i Destino * r}
ASSIGN c-lb-dest = TRIM(RETURN-VALUE).
{utp/ut-liter.i Usu†rio * r}
ASSIGN c-lb-usuar = TRIM(RETURN-VALUE).
{utp/ut-liter.i PAR∂METROS * r}
ASSIGN c-lb-param = TRIM(RETURN-VALUE).
{utp/ut-liter.i SELEÄ«O * r}
ASSIGN c-lb-selec = TRIM(RETURN-VALUE).
{utp/ut-liter.i DIGITAÄ«O * r}
ASSIGN c-lb-digit = TRIM(RETURN-VALUE).
{utp/ut-liter.i IMPRESS«O * r}
ASSIGN c-lb-impr = TRIM(RETURN-VALUE).
{utp/ut-liter.i Preáo_de_Custo * r}
ASSIGN c-lb-preco = TRIM(RETURN-VALUE).

/* Imprime parÉmetros */
IF tt-param.l-imp-param THEN DO:
    PAGE.
    PUT UNFORMATTED
        c-lb-param
        c-lb-preco AT 5 ": " tt-param.c-custo SKIP(1).
    
    ASSIGN l-param = tt-param.l-of.
    PUT c-lb-of    AT 5 FORMAT "x(21)" ": " l-param.
    
    ASSIGN l-param = tt-param.l-saldo.
    PUT c-lb-saldo AT 5 FORMAT "x(36)" ": " l-param.
    
    ASSIGN l-param = tt-param.l-desatual.
    PUT c-lb-fatur    AT 5 FORMAT "x(38)" ": " l-param.
    
    ASSIGN l-param = tt-param.l-custo-padrao.
    PUT c-lb-custo    AT 5 FORMAT "x(54)" ": " l-param.
    
    ASSIGN l-param = tt-param.l-desatualiza-ap.
    PUT c-lb-ap    AT 5 FORMAT "x(26)" ": " l-param.
    
    IF  NOT CAN-FIND (funcao WHERE funcao.cd-funcao = "spp-drb-sld-terc":U AND funcao.ativo)
    AND param-global.modulo-ex
    AND param-global.modulo-07 THEN DO:
        ASSIGN l-param = tt-param.l-desatualiza-draw.
        PUT c-lb-draw  AT 5 FORMAT "x(20)" ": " l-param. 
    END.
    
    ASSIGN l-param = tt-param.l-desatualiza-cr.
    PUT c-lb-acr AT 5 FORMAT "x(28)" ": " l-param.
    
    PUT SKIP(1).
    
    PUT UNFORMATTED
        c-lb-selec           SKIP(1)
        c-lb-data            AT 5  ":"
        tt-param.da-data-ini FORMAT "99/99/9999" AT 22 "|<  >| " AT 39 tt-param.da-data-fim FORMAT "99/99/9999"
        c-lb-espec           AT 5  ":"
        tt-param.c-esp-ini   AT 22 "|<  >| " AT 39 tt-param.c-esp-fim
        c-lb-serie           AT 5  ":"
        tt-param.c-ser-ini   AT 22 "|<  >| " AT 39 tt-param.c-ser-fim
        c-lb-docto           AT 5  ":"
        tt-param.c-num-ini   AT 22 "|<  >| " AT 39 tt-param.c-num-fim
        c-lb-emite           AT 5  ":"
        tt-param.i-emit-ini  AT 22 "|<  >| " AT 39 tt-param.i-emit-fim
        c-lb-natur           AT 5  ":"
        tt-param.c-nat-ini   AT 22 "|<  >| " AT 39 tt-param.c-nat-fim
        c-lb-estab           AT 5  ":"
        tt-param.c-estab-ini AT 22 "|<  >| " AT 39 tt-param.c-estab-fim 
        c-lb-atual           AT 5  ":"
        tt-param.da-atual-ini  FORMAT "99/99/9999" AT 22 "|<  >| " AT 39 tt-param.da-atual-fim  FORMAT "99/99/9999"
        c-lb-usuario         AT 5  ":"
        tt-param.c-usuario-ini AT 22 "|<  >| " AT 39 tt-param.c-usuario-fim SKIP(1).
    
        /* Se existir documentos digitados, ser∆o listados no final do relatΩrio */
        FIND FIRST tt-digita NO-ERROR.
        IF AVAILABLE tt-digita THEN DO:
            PUT UNFORMATTED
                c-lb-digit       SKIP(1)
                c-lb-serie       AT 5
                c-lb-docto       AT 11
                c-lb-emite       AT 28
                c-lb-natur       AT 38 SKIP(0)
                "    ----- ---------------- --------- --------" SKIP(0). 
                FOR EACH tt-digita:
                    PUT UNFORMATTED
                    tt-digita.serie-docto  AT 5
                    tt-digita.nro-docto    AT 11
                    tt-digita.cod-emitente AT 28.
                    PUT tt-digita.nat-operacao AT 38 SKIP(0).
                END.
            PUT UNFORMATTED SKIP(1).
        END.
    
    ASSIGN tt-param.c-destino = c-destino.
    PUT UNFORMATTED
        c-lb-impr            SKIP(1)
        c-lb-dest            AT 5  ": " tt-param.c-destino " - " tt-param.arquivo
        c-lb-usuar           AT 5  ": " tt-param.usuario.
END.
RUN pi-finalizar IN h-acomp.

{include/i-rpclo.i}

{include/pi-edit.i}

RETURN "OK".

/* --------------------------  Procedure Interna ----------------------------- */

{rep/re0402a.i1}     /* Procedure pi-erro-nota */

PROCEDURE pi-valida-medio:

    FIND FIRST param-estoq NO-LOCK NO-ERROR.

    /*doc GFE ignora perÌodo do mÈdio*/
    {inbo/boin01019.i1 "D"} /* verificaCtbzGFE */ /* D - Desatualizaá∆o */

    IF param-estoq.log-1 AND NOT l-ctbz-gfe THEN
    DO:      /* Usa Medio Mensal */
       IF  param-estoq.tp-fech = 2 THEN 
       DO:
           FIND estab-mat
                WHERE estab-mat.cod-estabel = docum-est.cod-estabel NO-LOCK NO-ERROR.

           IF  AVAIL estab-mat 
           AND docum-est.dt-trans <= estab-mat.mensal-ate THEN DO:
               RUN pi-erro-nota ( 1586, " ", YES).
           END.
       END.
       ELSE 
          IF param-estoq.log-1 AND docum-est.dt-trans <= param-estoq.mensal-ate THEN  DO:
               RUN pi-erro-nota ( 1586, " ", YES).
          END.
    END.

END.

PROCEDURE pi-efetiva:

    RUN pi-acompanhar IN h-acomp (INPUT docum-est.nro-docto).
    /*******************  Chamada EPC Grendene ********************/        
    FOR EACH tt-epc
        WHERE tt-epc.cod-event = "NAO-DESATUALIZA".
        DELETE tt-epc.
    END.

    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "NAO-DESATUALIZA"
           tt-epc.cod-parameter = "ROWID-DOCUM-EST"
           tt-epc.val-parameter = STRING(ROWID(docum-est)).

    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "NAO-DESATUALIZA"
           tt-epc.cod-parameter = "tt-param"
           tt-epc.val-parameter = STRING(raw-param).

    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "NAO-DESATUALIZA"
           tt-epc.cod-parameter = "tt-param-handle"
           tt-epc.val-parameter = STRING(TEMP-TABLE tt-param:HANDLE).
    
    {include/i-epc201.i "NAO-DESATUALIZA"}
    FIND FIRST tt-param NO-ERROR.

    IF RETURN-VALUE = "NOK":U THEN NEXT.
    /**************************************************************/  
    Assign gc-mot-canc-fat-re0402 = tt-param.mot-canc.
    IF CAN-FIND(funcao WHERE funcao.cd-funcao = "spp-integracao-eai" AND funcao.ativo) THEN DO:
        RUN rep/re0402a.p PERSISTENT SET h-re0402a ( INPUT  ROWID(docum-est),
                                                    INPUT  tt-param.l-of,
                                                    INPUT  tt-param.l-saldo,
                                                    INPUT  tt-param.l-desatual,
                                                    INPUT  tt-param.l-custo-padrao,
                                                    INPUT  tt-param.l-desatualiza-ap,
                                                    INPUT  tt-param.i-prc-custo,
                                                    INPUT  tt-param.l-desatualiza-aca,
                                                    INPUT  tt-param.l-desatualiza-wms,
                                                    INPUT  tt-param.l-desatualiza-draw,
                                                    INPUT  tt-param.l-desatualiza-cr,
                                                    OUTPUT l-erro,
                                                    OUTPUT table tt-erro ).

        RUN pi-rowid IN h-re0402a (OUTPUT TABLE tt-rowid-movto-estoq).

        DELETE OBJECT h-re0402a.
    END. ELSE DO:
        RUN rep/re0402a.p ( INPUT  ROWID(docum-est),
                            INPUT  tt-param.l-of,
                            INPUT  tt-param.l-saldo,
                            INPUT  tt-param.l-desatual,
                            INPUT  tt-param.l-custo-padrao,
                            INPUT  tt-param.l-desatualiza-ap,
                            INPUT  tt-param.i-prc-custo,
                            INPUT  tt-param.l-desatualiza-aca,
                            INPUT  tt-param.l-desatualiza-wms,
                            INPUT  tt-param.l-desatualiza-draw,
                            INPUT  tt-param.l-desatualiza-cr,
                            OUTPUT l-erro,
                            OUTPUT table tt-erro ).
    END.    
	
    /*Duane*/
    FOR EACH tt-epc
       WHERE tt-epc.cod-event     = "desatualiz-cr":U:
        DELETE tt-epc.		
    END.
    
    CREATE tt-epc. 
    ASSIGN tt-epc.cod-event     = "desatualiz-cr":U 
           tt-epc.cod-parameter = "parametros":U
           tt-epc.val-parameter = STRING(ROWID(docum-est)).
    
    CREATE tt-epc. 
    ASSIGN tt-epc.cod-event     = "desatualiz-cr":U 
           tt-epc.cod-parameter = "tt-erro":u
           tt-epc.val-parameter = STRING(TEMP-TABLE tt-erro:DEFAULT-BUFFER-HANDLE).
    
    {include/i-epc201.i "desatualiz-cr"}
    
    FIND FIRST tt-epc NO-LOCK
         WHERE tt-epc.cod-event     = "desatualiz-cr":U 
           AND tt-epc.cod-parameter = "tt-erro-return":u  NO-ERROR.
    IF AVAIL tt-epc THEN DO:
        IF tt-epc.val-parameter	= "N∆o" THEN
            ASSIGN l-erro = NO.
        ELSE IF tt-epc.val-parameter = "Sim" THEN
            ASSIGN l-erro = YES.
    END.

    /*Desatualiza Nota de Credito*/
    IF  NOT l-erro THEN DO:

        FOR EACH item-doc-est NO-LOCK
            OF docum-est:
            /* eSocial  */
            FOR EACH docum-est-esoc EXCLUSIVE-LOCK  
                WHERE docum-est-esoc.serie-docto  = item-doc-est.serie-docto  AND
                      docum-est-esoc.nro-docto    = item-doc-est.nro-docto    AND
                      docum-est-esoc.cod-emitente = item-doc-est.cod-emitente AND
                      docum-est-esoc.nat-operacao = item-doc-est.nat-of:
               DELETE docum-est-esoc.
            END. 
        END.

        IF  docum-est.esp-docto = 20 THEN DO: /*Devolucao*/

            EMPTY TEMP-TABLE tt_cancelamento_estorno_apb_1.
            EMPTY TEMP-TABLE tt_estornar_agrupados.
            EMPTY TEMP-TABLE tt_log_erros_atualiz.
            EMPTY TEMP-TABLE tt_log_erros_estorn_cancel_apb.
            EMPTY TEMP-TABLE tt_estorna_tit_imptos.

            FOR FIRST natur-oper NO-LOCK
                WHERE natur-oper.nat-operacao = docum-est.nat-operacao
                  AND natur-oper.tipo         = 2: /*Saida*/

                /*Item Devolucao*/
                FOR EACH item-doc-est EXCLUSIVE-LOCK {cdp/cd8900.i item-doc-est docum-est}:

                    /*Item Fatura ou Item Remito*/
                    FOR EACH b-item-doc-est NO-LOCK
                       WHERE b-item-doc-est.cod-emitente = item-doc-est.cod-emitente
                         AND b-item-doc-est.serie-docto  = item-doc-est.serie-comp
                         AND b-item-doc-est.nro-docto    = item-doc-est.nro-comp
                         AND b-item-doc-est.nat-operacao = item-doc-est.nat-comp
                         AND b-item-doc-est.it-codigo    = item-doc-est.it-codigo
                         AND b-item-doc-est.sequencia    = item-doc-est.seq-comp,
                       FIRST b-docum-est OF b-item-doc-est NO-LOCK:

                        IF  NOT b-docum-est.nff THEN DO:

                            /*Item Fatura*/
                            FOR FIRST b2-item-doc-est NO-LOCK
                                WHERE b2-item-doc-est.cod-emitente = b-item-doc-est.cod-emitente
                                  AND b2-item-doc-est.serie-comp   = b-item-doc-est.serie-docto
                                  AND b2-item-doc-est.nro-comp     = b-item-doc-est.nro-docto
                                  AND b2-item-doc-est.nat-comp     = b-item-doc-est.nat-operacao
                                  AND b2-item-doc-est.it-codigo    = b-item-doc-est.it-codigo
                                  AND b2-item-doc-est.seq-comp     = b-item-doc-est.sequencia:
                        
                                CREATE tt-item-doc-est-fat.
                                BUFFER-COPY b2-item-doc-est TO tt-item-doc-est-fat.
                            END.
                        END.
                        ELSE DO:
                            CREATE tt-item-doc-est-fat.
                            BUFFER-COPY b-item-doc-est TO tt-item-doc-est-fat.
                        END.
                    END.

                    /*Itens da Fatura*/
                    FOR EACH tt-item-doc-est-fat:
                    FIND FIRST b-docum-est OF tt-item-doc-est-fat NO-LOCK NO-ERROR.
                        /*Se gerou nota de credito*/
                        IF  &IF "{&bf_mat_versao_ems}":U >= "2.071":U &THEN
                                item-doc-est.log-gerou-ncredito
                            &ELSE
                                SUBSTRING(item-doc-est.char-2,449,1) = "1"
                            &ENDIF THEN DO:
                            
                            
                            /*Cria tt estorno*/
                            IF  NOT CAN-FIND(FIRST tt_cancelamento_estorno_apb_1
                                             WHERE tt_cancelamento_estorno_apb_1.tta_cod_estab_ext      = b-docum-est.cod-estabel
                                               AND tt_cancelamento_estorno_apb_1.tta_cod_espec_docto    = natur-oper.cod-esp
                                               AND tt_cancelamento_estorno_apb_1.tta_cod_ser_docto      = tt-item-doc-est-fat.serie-docto
                                               AND tt_cancelamento_estorno_apb_1.tta_cod_tit_ap         = tt-item-doc-est-fat.nro-docto
                                               AND tt_cancelamento_estorno_apb_1.tta_cdn_fornecedor     = tt-item-doc-est-fat.cod-emitente
                                               AND tt_cancelamento_estorno_apb_1.tta_cod_parcela        = &IF "{&bf_mat_versao_ems}":U >= "2.071":U &THEN
                                                                                                              item-doc-est.cod-parc-devol
                                                                                                          &ELSE
                                                                                                              SUBSTRING(item-doc-est.char-2,450,2)
                                                                                                          &ENDIF) THEN DO:
                                
                                CREATE tt_cancelamento_estorno_apb_1.
                                ASSIGN tt_cancelamento_estorno_apb_1.tta_cod_estab_ext      = b-docum-est.cod-estabel
                                       tt_cancelamento_estorno_apb_1.tta_cod_espec_docto    = natur-oper.cod-esp
                                       tt_cancelamento_estorno_apb_1.tta_cod_ser_docto      = tt-item-doc-est-fat.serie-docto
                                       tt_cancelamento_estorno_apb_1.tta_cod_tit_ap         = tt-item-doc-est-fat.nro-docto
                                       tt_cancelamento_estorno_apb_1.tta_cdn_fornecedor     = tt-item-doc-est-fat.cod-emitente
                                       tt_cancelamento_estorno_apb_1.ttv_ind_niv_operac_apb = c-titulo-lit 
                                       tt_cancelamento_estorno_apb_1.ttv_ind_tip_operac_apb = c-cancel-lit 
                                       tt_cancelamento_estorno_apb_1.ttv_ind_tip_estorn     = c-total-lit  
                                       tt_cancelamento_estorno_apb_1.ttv_log_reaber_item    = NO
                                       tt_cancelamento_estorno_apb_1.ttv_log_reembol        = NO
                                       tt_cancelamento_estorno_apb_1.ttv_rec_tit_ap         = 0
                                       tt_cancelamento_estorno_apb_1.tta_cod_parcela        = &IF "{&bf_mat_versao_ems}":U >= "2.071":U &THEN
                                                                                                  item-doc-est.cod-parc-devol.
                                                                                              &ELSE
                                                                                                  SUBSTRING(item-doc-est.char-2,450,2).
                                                                                              &ENDIF
                            END.
                        END.
                    END.
                END.

                /*Integraá∆o com o EMS 5*/
                IF  CAN-FIND(FIRST tt_cancelamento_estorno_apb_1) THEN DO:

                    RUN prgfin/apb/apb768zd.py (INPUT 1,
                                                INPUT "REP",
                                                INPUT "",
                                                INPUT TABLE tt_cancelamento_estorno_apb_1,
                                                INPUT TABLE tt_estornar_agrupados,
                                                OUTPUT TABLE tt_log_erros_atualiz,
                                                OUTPUT TABLE tt_log_erros_estorn_cancel_apb,
                                                OUTPUT TABLE tt_estorna_tit_imptos,
                                                OUTPUT l-estornou).

                    /*Tratamento de erro*/
                    FIND FIRST tt_log_erros_atualiz           NO-ERROR.
                    FIND FIRST tt_log_erros_estorn_cancel_apb NO-ERROR.
                    
                    IF  AVAIL tt_log_erros_atualiz OR
                        AVAIL tt_log_erros_estorn_cancel_apb THEN DO:
                        
                        /* Criacao dos erros do documento */
                        FOR EACH tt_log_erros_atualiz:
                            CREATE tt-erro.
                            ASSIGN tt-erro.cd-erro  = tt_log_erros_atualiz.ttv_num_mensagem
                                   tt-erro.mensagem = tt_log_erros_atualiz.ttv_des_msg_erro.
                        END.
                        
                        FOR EACH tt_log_erros_estorn_cancel_apb:
                            CREATE tt-erro.
                            ASSIGN tt-erro.cd-erro  = tt_log_erros_estorn_cancel_apb.tta_num_mensagem
                                   tt-erro.mensagem = tt_log_erros_estorn_cancel_apb.ttv_des_msg_erro.
                        END.
                    END.
                END.
            END.
        END.
    END.


        /*--------- INICIO UPC ---------*/   
     
    IF NOT CAN-FIND(FIRST tt-erro) THEN DO:
       /* DCR Projeto Gradiente - Favor n∆o apagar o coment†rio.
       &IF "{&bf_mat_versao_ems}" >= "2.05" &THEN
           if param-global.log-modul-zfm and  /* MΩdulo Zone Franca de Manaus */
             (connected("mgfis") or
              connected("shmgfis"))      then do:

               def var h-bofi034 as handle no-undo.

               if not valid-handle(h-bofi034) then
                   run fibo/bofi034.p persistent set h-bofi034.

               for each item-doc-est no-lock where
                        item-doc-est.serie-docto  = docum-est.serie-docto  and
                        item-doc-est.nro-docto    = docum-est.nro-docto    and
                        item-doc-est.cod-emitente = docum-est.cod-emitente and
                        item-doc-est.nat-operacao = docum-est.nat-operacao:

                   run pi-delete-zfm-ult-entr-dcr in h-bofi034 (input item-doc-est.it-codigo,
                                                                input docum-est.dt-trans,
                                                                input docum-est.nro-doct,
                                                                input docum-est.serie-docto,
                                                                input docum-est.cod-emitente).
               end.
               if valid-handle(h-bofi034) then do:
                   delete procedure h-bofi034.
                   assign h-bofi034 = ?.
               end.
           end.
       &ENDIF
       Fim - DCR */

       
       FOR EACH tt-epc WHERE tt-epc.cod-event = "Apos-Atualizacao":
           DELETE tt-epc.
       END.

       ASSIGN c-upc-parameters = STRING(ROWID(docum-est))           + "," +
                                 string(tt-param.l-of)              + "," +
                                 string(tt-param.l-saldo)           + "," +
                                 string(tt-param.l-desatual)        + "," +
                                 string(tt-param.l-custo-padrao)    + "," +
                                 string(tt-param.l-desatualiza-ap)  + "," +
                                 string(tt-param.l-desatualiza-aca) + "," +                                 
                                 string(tt-param.i-prc-custo)       .

       CREATE tt-epc.
       ASSIGN tt-epc.cod-event     = "Apos-Atualizacao" 
              tt-epc.cod-parameter = "parametros"
              tt-epc.val-parameter = c-upc-parameters.

       {include/i-epc201.i "Apos-Atualizacao"}

       /*--------- FINAL UPC ---------*/
    END.

    /*** Siscoserv ***/    
    RUN pi-siscoserv-ativo IN h-cdapi050.
    IF RETURN-VALUE = "OK":U THEN DO:
        RUN pi-apaga-nota-import-sis IN h-cdapi050 (INPUT docum-est.serie-docto,
                                                    INPUT docum-est.nro-docto,
                                                    INPUT docum-est.nat-operacao,
                                                    INPUT docum-est.cod-estabel,
                                                    INPUT STRING(docum-est.cod-emitente),
                                                    INPUT 1).
    END.
    /*** Siscoserv ***/
       
    FOR EACH tt-epc WHERE tt-epc.cod-event = "final-atualiz" :
        DELETE tt-epc.
    END.

    CREATE tt-epc. 
    ASSIGN tt-epc.cod-event     = "final-atualiz":U 
           tt-epc.cod-parameter = "parametros":U
           tt-epc.val-parameter = STRING(ROWID(docum-est)).

    CREATE tt-epc. 
    ASSIGN tt-epc.cod-event     = "final-atualiz":U 
           tt-epc.cod-parameter = "destino":U
           tt-epc.val-parameter = STRING(tt-param.destino).
    
    CREATE tt-epc. 
    ASSIGN tt-epc.cod-event     = "final-atualiz":U 
           tt-epc.cod-parameter = "motivo":u
           tt-epc.val-parameter = tt-param.c-destino.

    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "final-atualiz":U 
           tt-epc.cod-parameter = "usuario"
           tt-epc.val-parameter = tt-param.usuario.

    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "final-atualiz":U 
           tt-epc.cod-parameter = "tt-erro-handle"
           tt-epc.val-parameter = STRING(TEMP-TABLE tt-erro:HANDLE).

    {include/i-epc201.i "final-atualiz"}

    ASSIGN c-destino = tt-param.c-destino.

    FIND FIRST tt-epc NO-LOCK
         WHERE tt-epc.cod-event     = "final-atualiz":U
           AND tt-epc.cod-parameter = "c-destino":U  NO-ERROR.
    IF AVAIL tt-epc THEN
        ASSIGN c-destino = tt-epc.val-parameter .

    /*--- NF-e ---*/
    IF  CAN-FIND (FIRST funcao 
                  WHERE funcao.cd-funcao = "spp-nfe":U 
                  AND funcao.ativo) THEN DO: 
        IF (tt-param.l-desatual AND CAN-FIND(FIRST natur-oper 
                                             WHERE natur-oper.nat-operacao = docum-est.nat-operacao
                                               AND natur-oper.imp-nota))
            AND NOT l-erro AND NOT tt-param.l-of THEN DO:

            FIND FIRST nota-fiscal 
                 WHERE nota-fiscal.cod-estabel  = docum-est.cod-estabel
                   AND nota-fiscal.serie        = docum-est.serie-docto
                   AND nota-fiscal.nr-nota-fis  = docum-est.nro-docto
                   AND nota-fiscal.cod-emitente = docum-est.cod-emitente 
                   AND nota-fiscal.nat-operacao = docum-est.nat-operacao EXCLUSIVE-LOCK NO-ERROR.

            IF NOT AVAIL nota-fiscal THEN 
                FIND FIRST nota-fiscal
                    WHERE nota-fiscal.cod-chave-aces-nf-eletro  = docum-est.cod-chave-aces-nf-eletro EXCLUSIVE-LOCK NO-ERROR.
    
            IF  AVAIL nota-fiscal AND nota-fiscal.ind-tip-nota = 8 THEN DO: /* Nota fiscal do recebimento */
                IF &IF "{&bf_dis_versao_ems}":U >= "2.07":U &THEN
                   (nota-fiscal.idi-sit-nf-eletro  > 1 AND
                    nota-fiscal.idi-sit-nf-eletro <> 12) /*12 - NF-e em Processo de Cancelamento*/
                 &ELSE
                   CAN-FIND(FIRST sit-nf-eletro  
                            WHERE sit-nf-eletro.cod-estabel   = nota-fiscal.cod-estabel 
                              AND sit-nf-eletro.cod-serie     = nota-fiscal.serie       
                              AND sit-nf-eletro.cod-nota-fisc = nota-fiscal.nr-nota-fis
                              AND (sit-nf-eletro.idi-sit-nf-eletro  > 1
                              AND  sit-nf-eletro.idi-sit-nf-eletro <> 12)) /*12 - NF-e em Processo de Cancelamento*/
                &ENDIF THEN DO:
                   IF NOT AVAIL estabelec OR 
                                estabelec.cod-estabel <> docum-est.cod-estabel THEN
                        FIND FIRST estabelec WHERE
                                   estabelec.cod-estabel = docum-est.cod-estabel NO-LOCK NO-ERROR.
            
                   /* somente envia XML para series eletronicas, em ambiente de Producao */
                   IF estabelec.idi-tip-emis-nf-eletro = 3 AND 
                      CAN-FIND(FIRST ser-estab WHERE
                                     ser-estab.cod-estabel = docum-est.cod-estabel AND
                                     ser-estab.serie       = docum-est.serie       AND
                                      ser-estab.log-nf-eletro)                    THEN DO:
                       /* 1 - Aplicativo de Transmissao (XML) */
                       
                       RUN cdp/cd0360b (INPUT docum-est.cod-estabel,
                                        INPUT "NF-e",
                                        OUTPUT tp-integ).

                       IF  tp-integ <> "Manual":U THEN DO:

                           IF  LOOKUP (tp-integ, "TSS,TC,TC2":U) > 0 THEN DO:

                               ASSIGN i-tipo-transacao = 2.
                           
                               RUN pi-erro-nota (17006, 
                                                 "NF-e em processo de Cancelamento!":U + " [NF ":U + nota-fiscal.nr-nota-fis + "]":U, 
                                                 YES ).
                            
                           END.
                           ELSE DO:
                            
                               IF NOT VALID-HANDLE(h-axsep002)  OR 
                               h-axsep002:TYPE <> "PROCEDURE":U OR 
                               h-axsep002:FILE-NAME <> "adapters/xml/ep2/axsep002.p":U THEN 
                               RUN adapters/xml/ep2/axsep002.p PERSISTENT SET h-axsep002(OUTPUT table tt_log_erro).
                            
                               RUN PITransUpsert IN h-axsep002 (INPUT "upd":U,
                                                                INPUT tt-param.mot-canc,
                                                                INPUT ROWID(nota-fiscal),
                                                                OUTPUT i-tipo-transacao, /* 1 - Sincrona | 2 - Assincrona */
                                                                OUTPUT TABLE tt_log_erro,
                                                                OUTPUT TABLE tt_nfe_erro).
                            
                               IF CAN-FIND(FIRST tt_log_erro) THEN
                                  FOR EACH tt_log_erro:                          
                                      IF tt_log_erro.ttv_num_cod_erro = 27979 THEN
                                         RUN pi-erro-nota ( tt_log_erro.ttv_num_cod_erro , tt_log_erro.ttv_des_msg_erro, NO ).
                                      ELSE
                                         RUN pi-erro-nota ( tt_log_erro.ttv_num_cod_erro , tt_log_erro.ttv_des_msg_erro, YES ).
                                  END.
                            
                               IF  i-tipo-transacao = ? OR i-tipo-transacao = 0 THEN
                                   RETURN.
                           END.
                            
                             /*---- ASS÷NCRONA ---*/
                           IF  i-tipo-transacao = 2 THEN DO:
                               /*Gravar as notas que necessitam ser enviadas o xml de solicitaá∆o de cancelamento*/
                               IF  INDEX(gc-NFe-docs-a-desatu-re0402,STRING(ROWID(docum-est))) = 0 /*verifica se o rowid em quest∆o ainda n∆o est† na vari†vel, para n∆o repetir documentos*/ 
                               THEN 
                                   ASSIGN gc-NFe-docs-a-desatu-re0402 = ( IF gc-NFe-docs-a-desatu-re0402 = ""
                                                                                THEN STRING(ROWID(docum-est))
                                                                                ELSE gc-NFe-docs-a-desatu-re0402 + "#" + STRING(ROWID(docum-est)) ).
                           END.
                           ELSE DO:
                               IF nota-fiscal.idi-sit-nf-eletro = 3 THEN
                                  FOR FIRST tt_nfe_erro:
                                        CREATE ret-nf-eletro.
                                        ASSIGN ret-nf-eletro.cod-estabel      = nota-fiscal.cod-estabel
                                               ret-nf-eletro.cod-serie        = nota-fiscal.serie 
                                               ret-nf-eletro.nr-nota-fis      = nota-fiscal.nr-nota-fis 
                                               ret-nf-eletro.cod-msg          = tt_nfe_erro.cStat
                                               ret-nf-eletro.dat-ret          = TODAY
                                               ret-nf-eletro.hra-ret          = REPLACE(STRING(TIME, "HH:MM:SS"),":","")
                                               ret-nf-eletro.idi-orig-solicit = 2 /* Cancelamento */ 
                                               ret-nf-eletro.log-ativo        = YES
                                               ret-nf-eletro.cod-livre-1      = tt_nfe_erro.nProt.
                                  END.
                           
                               IF VALID-HANDLE(h-axsep002) THEN DO:
                                  DELETE PROCEDURE h-axsep002 NO-ERROR.
                                  ASSIGN h-axsep002 = ?.
                               END.
                           
                               IF (CAN-FIND(FIRST tt_nfe_erro WHERE tt_nfe_erro.cStat = '101')    /*101 Cancelamento de NF-e homologado*/                                                
                               OR  CAN-FIND(FIRST tt_nfe_erro WHERE tt_nfe_erro.cStat = '151')    /*151 Cancelamento de NF-e homologado fora de prazo*/                                  
                               OR  CAN-FIND(FIRST tt_nfe_erro WHERE tt_nfe_erro.cStat = '155'))   /*155 Cancelamento homologado fora de prazo (para Evento de Cancelamento [NT2011.006]*/
                               THEN DO:
                                   IF AVAIL docum-est THEN ASSIGN docum-est.idi-sit-nf-eletro = 6. 
                                      ASSIGN nota-fiscal.idi-sit-nf-eletro = 6.
                           
                                   RUN pi-atualizaNotaFiscAdc. /* Atualiza nota-fisc-adc (CD4035) */
                               END.
                               ELSE DO:
                                  RUN pi-lista-erros.
                                  RETURN. 
                               END.
                           
                           END. /* IF  i-tipo-transacao = 2 THEN DO: */
                       END.
                       ELSE 
                       IF  tp-integ = "Manual":U THEN DO: /* Transmissao Manual */
                            IF AVAIL docum-est THEN ASSIGN docum-est.idi-sit-nf-eletro = 6. 
                               ASSIGN nota-fiscal.idi-sit-nf-eletro = 6.
                            
                            RUN pi-atualizaNotaFiscAdc.  /* Atualiza nota-fisc-adc (CD4035) */
                       END.
                   END.
                END. 
                ELSE DO:
                    DO  i-cont-progs = 2 TO 10:
                        IF  PROGRAM-NAME(i-cont-progs) MATCHES "*ft0911*" THEN DO:
                            ASSIGN l-executado-ft0911 = YES.
                            LEAVE.
                        END.
                    END.
                    IF  l-executado-ft0911 = NO THEN DO:
                        FOR FIRST sit-nf-eletro EXCLUSIVE-LOCK
                            WHERE sit-nf-eletro.cod-estabel  = nota-fiscal.cod-estabel
                              AND sit-nf-eletro.cod-serie    = nota-fiscal.serie
                              AND sit-nf-eletro.cod-nota-fis = nota-fiscal.nr-nota-fis:
                        IF  NOT AVAIL tt-param THEN
                            FIND FIRST tt-param NO-LOCK NO-ERROR.
                        ASSIGN sit-nf-eletro.cod-livre-1 = ("N" + "#" +
                                                            (IF tt-param.l-saldo            THEN "S" ELSE "N") + "#" +
                                                            "S" + "#" +
                                                            (IF tt-param.l-custo-padrao     THEN "S" ELSE "N") + "#" +
                                                            (IF tt-param.l-desatualiza-ap   THEN "S" ELSE "N") + "#" +
                                                            (IF tt-param.l-desatualiza-aca  THEN "S" ELSE "N") + "#" +
                                                            (IF tt-param.l-desatualiza-wms  THEN "S" ELSE "N") + "#" +
                                                            (IF tt-param.l-desatualiza-draw THEN "S" ELSE "N") + "#" +
                                                            (IF tt-param.l-desatualiza-cr   THEN "S" ELSE "N") + "#" +
                                                            STRING(tt-param.i-prc-custo)).
                        RUN pi-erro-nota (17006, 
                                          "NF-e em processo de Cancelamento!":U + " [NF ":U + nota-fiscal.nr-nota-fis + "]":U, 
                                          YES ).
                        END.
                    END.

                END.

            END.
            FIND CURRENT nota-fiscal   NO-LOCK NO-ERROR.
            FIND CURRENT docum-est     NO-LOCK NO-ERROR.
            FIND CURRENT sit-nf-eletro NO-LOCK NO-ERROR.
        END. 
        RUN pi-grava-erros-para-NFe.
    END. 
    /*--- fim NF-e ---*/
	
	/*********************  Chamada EPC AACD **********************/
    FOR EACH tt-epc
       WHERE tt-epc.cod-event = "Antes-lista-erros":
        DELETE tt-epc.
    END.

    FOR EACH tt-epc
       WHERE tt-epc.cod-event = "tt-erro":
        DELETE tt-epc.
    END.

    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "Antes-lista-erros"
           tt-epc.cod-parameter = "lista-erros"
           tt-epc.val-parameter = STRING(ROWID(docum-est)).

    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "Antes-lista-erros"
           tt-epc.cod-parameter = "l-erro"
           tt-epc.val-parameter = STRING(l-erro).

    {include/i-epc201.i "Antes-lista-erros"}
    
    FOR FIRST tt-epc
        WHERE tt-epc.cod-event = "tt-erro":
        RUN pi-erro-nota(INPUT INT(tt-epc.cod-parameter),
                         INPUT tt-epc.val-parameter, 
                         INPUT YES).
    END.

    IF CAN-FIND(FIRST funcao 
                WHERE funcao.cd-funcao = "spp-integracao-eai" 
                  AND funcao.ativo)
    AND NOT l-erro THEN DO:
        FIND FIRST natur-oper 
             WHERE natur-oper.nat-operacao = docum-est.nat-operacao NO-LOCK NO-ERROR.
        IF AVAIL natur-oper AND natur-oper.tp-oper-terc <> 4  THEN DO:
           RUN pi-eai.
        END.
        ELSE DO:
            FOR EACH tt-rowid-movto-estoq:
                FIND movto-estoq WHERE ROWID(movto-estoq) = tt-rowid-movto-estoq.r-rowid EXCLUSIVE-LOCK NO-ERROR.
                IF AVAIL movto-estoq THEN
                   DELETE movto-estoq.
            
            END.
        END.
    END.
    /**************************************************************/

    RUN pi-lista-erros.

    /*******************  Chamada EPC Vicunha ********************/        

    FOR EACH tt-epc
        WHERE tt-epc.cod-event = "Apos-lista-erros".
        DELETE tt-epc.
    END.

    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "Apos-lista-erros"
           tt-epc.cod-parameter = "lista-erros"
           tt-epc.val-parameter = STRING(ROWID(docum-est)).

    {include/i-epc201.i "Apos-lista-erros"}

    /**************************************************************/        

    RETURN "OK":U.

END.

PROCEDURE pi-eai:
    IF  v_log_eai_habilit
    AND l-integra-eai THEN DO: 

        &if '{&bf_dis_versao_ems}' >= '2.06' &then
        /** Validacao para que nao seja enviado ao HIS o movimento de estoque do recebimento fiscal, caso o mesmo tenha sido
            gerado pelo Recebimento Fisico**/
        IF  l-integra-ems-his THEN DO:
            IF  AVAIL docum-est THEN DO:
                IF  param-estoq.rec-fisico THEN
                    FIND FIRST doc-fisico
                         WHERE doc-fisico.nro-docto    = docum-est.nro-docto
                         AND   doc-fisico.serie-docto  = docum-est.serie-docto
                         AND   doc-fisico.cod-emitente = docum-est.cod-emitente NO-LOCK NO-ERROR.
            END.
        END.

        /*Comentado devido ‡ lÛgica que foi considerada indevida para o HIS */
        /*if  not avail doc-fisico then do:*/
        &endif
        
        RUN adapters/xml/ar2/axsar011.p (INPUT "RE0402A":U,
                                         INPUT c-prg-vrs,
                                         INPUT "DEL":U,
                                         INPUT table tt-rowid-movto-estoq,
                                         OUTPUT table RowErrors).
        IF RETURN-VALUE = "NOK" OR CAN-FIND(FIRST RowErrors) THEN DO:
             
             FOR EACH RowErrors:
                RUN pi-erro-nota (RowErrors.ErrorNumber, RowErrors.ErrorParameters, INPUT (RowErrors.ErrorSubType = "ERROR":U)).
             END.
             RUN pi-lista-erros.
             UNDO, NEXT.

        END.       
    END.    
    &IF '{&bf_mat_versao_ems}' >= '2.08' AND '{&bf_mat_integra_eai2}' = 'YES' &THEN
        IF v_log_eai2_ativado THEN 
        DO:        
            /* Integraá∆o EMS EAI2.0 Mensagem unica */
            RUN pi-sendDeleteList IN h-ceapi311 (INPUT TABLE tt-rowid-movto-estoq, OUTPUT TABLE RowErrors).      
               
            IF CAN-FIND(FIRST RowErrors) THEN DO:            
                FOR EACH RowErrors:
                    RUN pi-erro-nota (RowErrors.ErrorNumber, RowErrors.ErrorParameters, INPUT (RowErrors.ErrorSubType = "ERROR":U)).
                END.
                RUN pi-lista-erros.
                UNDO, NEXT.
            END.

            FOR FIRST tt-rowid-movto-estoq:
            END.

            {cep/ceapi310.i}

            IF l-enviar THEN DO:
            
                /* Integraá∆o EMS EAI2.0 AppointmentCost */  
                RUN pi-sendDeleteList IN h-ceapi310 (INPUT TABLE tt-rowid-movto-estoq, OUTPUT TABLE RowErrors).      
                
                IF CAN-FIND(FIRST RowErrors) THEN DO:            
                    FOR EACH RowErrors:
                        RUN pi-erro-nota (RowErrors.ErrorNumber, RowErrors.ErrorDescription, INPUT (RowErrors.ErrorSubType = "ERROR":U)).
                    END.
                    RUN pi-lista-erros.
                    UNDO, NEXT.
                END.

            END.

        END.
    &ENDIF    
           
    FOR EACH tt-rowid-movto-estoq:
        FIND movto-estoq WHERE ROWID(movto-estoq) = tt-rowid-movto-estoq.r-rowid EXCLUSIVE-LOCK NO-ERROR.
        IF AVAIL movto-estoq THEN
           DELETE movto-estoq.
    END.    
    
    IF l-erro THEN RETURN "NOK":U.                
    
    RETURN "OK":U.
END PROCEDURE.

PROCEDURE pi-lista-erros:

    IF AVAIL docum-est THEN
        DISP docum-est.nro-docto
             docum-est.serie-docto
             docum-est.cod-emitente
             docum-est.nat-operacao
             WITH FRAME f-docto.

    IF i-pais-impto-usuario <> 1 AND NOT CAN-FIND(FIRST tt-erro) THEN DO:
        {utp/ut-liter.i "Documento_Desatualizado_com_“xito" *}
        ASSIGN c-msg = TRIM(RETURN-VALUE).
        DISP c-msg @ tt-erro.mensagem AT 54
                WITH FRAME f-docto.
            DOWN WITH FRAME f-docto.
    END.

    FOR EACH tt-erro:

        DISP tt-erro.cd-erro
            WITH FRAME f-docto.

        RUN pi-print-editor (INPUT tt-erro.mensagem, INPUT 77).
        FOR EACH tt-editor:
            DISP tt-editor.conteudo @ tt-erro.mensagem AT 54
                WITH FRAME f-docto.
            DOWN WITH FRAME f-docto.
        END.
        DELETE tt-erro.
    END.

    DOWN WITH FRAME f-docto.
    PUT " " SKIP.

END.

PROCEDURE pi-conecta-ems50:

    DEF INPUT PARAM i-conect AS INTEGER NO-UNDO.

    RUN btb/btb009za.p PERSISTENT SET h-btb009za.

    IF i-conect = 1 THEN 
    DO:
        IF NOT CONNECTED("emsbas") OR 
           NOT CONNECTED("emsfin") OR 
           NOT CONNECTED("emsuni") THEN DO:          

            IF  VALID-HANDLE (h-btb009za) AND
               h-btb009za:TYPE = "PROCEDURE":U AND
               h-btb009za:FILE-NAME = "btb/btb009za.p":U THEN DO:


               RUN pi-conecta-bco IN h-btb009za (INPUT 1,                         /*contem a vers„o de integraå„o da Api*/
                                                 INPUT i-conect,                  /*contem a opå„o desejada (1-Conex„o, 2-Desconex„o)*/
                                                 INPUT param-global.empresa-prin, /*contem o c©digo da empresa*/
                                                 INPUT "all",                     /*contem o c©digo do banco externo*/ 
                                                 OUTPUT Table tt_erros_conexao).  /*retorna erros caso existam*/
               FOR EACH tt_erros_conexao:
                     IF RETURN-VALUE <> "OK":U THEN DO:
                         IF LINE-COUNTER > 62 THEN
                            PAGE.
                         PUT STRING(tt_erros_conexao.cd-erro,">>>>>9") AT 44.
                         PUT tt_erros_conexao.mensagem AT 53 FORMAT "X(78)" SKIP.
                         IF  tt_erros_conexao.param-1 <> " " AND 
                             tt_erros_conexao.cd-erro <> 6003 OR tt_erros_conexao.cd-erro <> 2 THEN
                             PUT tt_erros_conexao.param-1 AT 01 FORMAT "X(132)" SKIP.
                         ASSIGN l-erro = YES.
                         UNDO, RETURN "NOK".                                              
                     END.
               END.
            END.
        END.
        ELSE
            ASSIGN l-ja-conectado = YES.
    END.
    ELSE DO:
        IF l-ja-conectado = NO THEN 
        DO:
            IF CONNECTED("emsbas") OR 
               connected("emsfin") OR 
               connected("emsuni") THEN DO:

                IF  VALID-HANDLE (h-btb009za) AND
                   h-btb009za:TYPE = "PROCEDURE":U AND
                   h-btb009za:FILE-NAME = "btb/btb009za.p":U THEN DO:

                   RUN pi-conecta-bco IN h-btb009za (INPUT 1,                         /*contem a vers„o de integraå„o da Api*/
                                                     INPUT i-conect,                  /*contem a opå„o desejada (1-Conex„o, 2-Desconex„o)*/
                                                     INPUT param-global.empresa-prin, /*contem o c©digo da empresa*/
                                                     INPUT "all",                     /*contem o c©digo do banco externo*/ 
                                                     OUTPUT Table tt_erros_conexao).  /*retorna erros caso existam*/
                   FOR EACH tt_erros_conexao:
                       IF RETURN-VALUE <> "OK":U THEN DO:
                           IF LINE-COUNTER > 62 THEN
                               PAGE.
                           PUT STRING(tt_erros_conexao.cd-erro,">>>>>9") AT 44.
                           PUT tt_erros_conexao.mensagem AT 53 FORMAT "X(78)" SKIP.
                           IF  tt_erros_conexao.param-1 <> " " AND 
                               tt_erros_conexao.cd-erro <> 6003 OR tt_erros_conexao.cd-erro <> 2 THEN
                               PUT tt_erros_conexao.param-1 AT 01 FORMAT "X(132)" SKIP.
                           ASSIGN l-erro = YES.
                           UNDO, RETURN "NOK".                                              
                       END.
                   END.
                END.
            END.    
        END.    
    END.
    RETURN "OK":U.
END.





PROCEDURE pi-Trata-Cancel-NFe:

    DEFINE VARIABLE i-cont-progs         AS INTEGER     NO-UNDO.
    DEFINE VARIABLE i-cont-seg           AS INTEGER     NO-UNDO.
    DEFINE VARIABLE lExecutadoPeloFT0911 AS LOGICAL     NO-UNDO.
    DEFINE VARIABLE h-axsep002           AS HANDLE      NO-UNDO.
    DEFINE VARIABLE i-tipo-transacao     AS INTEGER     NO-UNDO.
    DEFINE VARIABLE cMotivoCancelamento  AS CHARACTER   NO-UNDO.
    
    /*Totvs Colaboraá∆o 2.0*/
    DEFINE VARIABLE cTpTrans AS CHARACTER NO-UNDO.
    DEFINE VARIABLE h-axsep018           AS HANDLE      NO-UNDO.

    /*---
    ENVIAR XML DE SOLICITAÄ«O DE CANCELAMENTO
    ---*/
    IF  CAN-FIND (FIRST tt-erro-nfe NO-LOCK
                  WHERE tt-erro-nfe.cd-erro = 17006
                    AND (INDEX(tt-erro-nfe.mensagem , "NF-e em processo de Cancelamento") > 0
                     OR  INDEX(tt-erro-nfe.mensagem , "NF-e em processo de Inutilizaá∆o") > 0) ) THEN DO: /*Mensagens 17006, geradas no axsep002 para cancel Assincrono*/

        IF  gc-NFe-docs-a-desatu-re0402 <> ""
        AND gc-NFe-docs-a-desatu-re0402 <> ? THEN DO:

            DO  i-cont = 1 TO NUM-ENTRIES(gc-NFe-docs-a-desatu-re0402,"#") :

                FOR FIRST docum-est NO-LOCK
                    WHERE ROWID(docum-est) = TO-ROWID( ENTRY(i-cont,gc-NFe-docs-a-desatu-re0402,"#") ):
                END.
                IF  NOT AVAIL docum-est THEN RETURN "OK":U.
                    
                FOR FIRST nota-fiscal NO-LOCK
                    WHERE nota-fiscal.cod-estabel = docum-est.cod-estabel
                      AND nota-fiscal.serie       = docum-est.serie-docto
                      AND nota-fiscal.nr-nota-fis = docum-est.nro-docto:
                END.
                IF  NOT AVAIL nota-fiscal THEN RETURN "OK":U.

                ASSIGN cMotivoCancelamento = tt-param.mot-canc.
                
                RUN cdp/cd0360b.p (INPUT docum-est.cod-estabel,
                                   INPUT "NF-e":U,
                                   OUTPUT cTpTrans).
        
                IF  cTpTrans = "TC2":U THEN DO:
        
                    EMPTY TEMP-TABLE tt-dados-evento.
                    CREATE tt-dados-evento.                         
                    ASSIGN tt-dados-evento.cod-estab             = nota-fiscal.cod-estabel         
                           tt-dados-evento.cod-serie             = nota-fiscal.serie         
                           tt-dados-evento.cod-nota-fis          = nota-fiscal.nr-nota-fis 
                           tt-dados-evento.desc-evento           = "Cancelamento"               
                           tt-dados-evento.num-seq               = 1        
                           tt-dados-evento.cod-versao            = "1.00"        
                           tt-dados-evento.dsl-evento            = cMotivoCancelamento
                           tt-dados-evento.des-dat-hora-event    = STRING(TODAY,"99/99/9999") + " " + STRING(TIME,"HH:MM:SS").   
                           tt-dados-evento.r-rowid               = ROWID(nota-fiscal) .
        
                   IF  NOT VALID-HANDLE(h-axsep018) THEN
                       RUN adapters/xml/ep2/axsep018.p PERSISTENT SET h-axsep018.
        
                    RUN PITransUpsert IN h-axsep018 (INPUT "upd", INPUT "CancelamentoEnv", INPUT "110111", INPUT TABLE tt-dados-evento, OUTPUT TABLE tt_log_erro).
        
                    ASSIGN i-tipo-transacao = 2.
        
                    IF  VALID-HANDLE(h-axsep018) THEN DO:
                        DELETE PROCEDURE h-axsep018.
                        ASSIGN h-axsep018 = ?.
                    END.
        
                END.
                ELSE
                    IF  lookup(cTpTrans,"TSS,TC":U) > 0 THEN DO:
    
                           RUN ftp/ftapi512.p (INPUT "Cancelamento",
                                               INPUT ROWID(nota-fiscal),
                                               INPUT cMotivoCancelamento,
                                               OUTPUT i-tipo-transacao).
    
                    END.
                    ELSE DO:
                    
                        IF  NOT VALID-HANDLE(h-axsep002)
                        OR  h-axsep002:TYPE <> "PROCEDURE":U
                        OR  h-axsep002:FILE-NAME <> "adapters/xml/ep2/axsep002.p":U THEN
                            RUN adapters/xml/ep2/axsep002.p PERSISTENT SET h-axsep002 (OUTPUT TABLE tt_log_erro).
                                   
                        
        
                        RUN PITransUpsert IN h-axsep002 (INPUT "upd":U,
                                                         INPUT cMotivoCancelamento,
                                                         INPUT ROWID(nota-fiscal),
                                                         OUTPUT i-tipo-transacao, /* 1 - Sincrona | 2 - Assincrona */
                                                         OUTPUT TABLE tt_log_erro,
                                                         OUTPUT TABLE tt_nfe_erro).
                    
                    END.

                IF  i-tipo-transacao = ? OR i-tipo-transacao = 0 THEN
                    RETURN "NOK":U.
        
                /*---- ASS÷NCRONA ---*/
                IF  i-tipo-transacao = 2 THEN DO:

                    /*RE - Atualizaá∆o Situaá∆o*/   /*12 - NF-e em processo de Cancelamento*/
                    FIND CURRENT docum-est EXCLUSIVE-LOCK NO-ERROR.

                    &if "{&bf_dis_versao_ems}":U >= "2.071":U &then
                        ASSIGN docum-est.idi-sit-nf-eletro     = 12. 
                    &else
                        ASSIGN OVERLAY(docum-est.char-1,154,2) = "12". 
                    &endif
                    
                    FIND CURRENT docum-est NO-LOCK        NO-ERROR.

                    /*FT - Atualizaá∆o Situaá∆o*/   /*12 - NF-e em processo de Cancelamento*/
                    &if "{&bf_dis_versao_ems}" >= "2.07" &then
                    
                        FIND CURRENT nota-fiscal EXCLUSIVE-LOCK NO-ERROR.
        
                        ASSIGN nota-fiscal.idi-sit-nf-eletro = 12 /*12 - NF-e em processo de Cancelamento*/
                               nota-fiscal.desc-cancela = tt-param.mot-canc.

                        FIND CURRENT nota-fiscal NO-LOCK        NO-ERROR.

                    &else
                        FOR FIRST sit-nf-eletro  
                            WHERE sit-nf-eletro.cod-estabel   = nota-fiscal.cod-estabel 
                              AND sit-nf-eletro.cod-serie     = nota-fiscal.serie       
                              AND sit-nf-eletro.cod-nota-fisc = nota-fiscal.nr-nota-fis EXCLUSIVE-LOCK:

                            ASSIGN sit-nf-eletro.idi-sit-nf-eletro = 12.  /*12 - NF-e em processo de Cancelamento*/

                        END.
                        RELEASE sit-nf-eletro.
                    &endif
                
                    /*
                    Grava na sit-nf-eletro toda a parametrizaá∆o feita em tela, para que, quando o receiver executar a rotina de cancelamento, possa cancelar conforme os parametros selecionados pelo usuario
                    */
            
                    FOR FIRST sit-nf-eletro EXCLUSIVE-LOCK
                        WHERE sit-nf-eletro.cod-estabel  = nota-fiscal.cod-estabel
                          AND sit-nf-eletro.cod-serie    = nota-fiscal.serie
                          AND sit-nf-eletro.cod-nota-fis = nota-fiscal.nr-nota-fis:
                    END.
                    IF  NOT AVAIL sit-nf-eletro THEN DO:
                        CREATE sit-nf-eletro.
                        ASSIGN sit-nf-eletro.cod-estabel  = nota-fiscal.cod-estabel
                               sit-nf-eletro.cod-serie    = nota-fiscal.serie
                               sit-nf-eletro.cod-nota-fis = nota-fiscal.nr-nota-fis.
                    END.

                    IF  NOT AVAIL tt-param THEN
                        FIND FIRST tt-param NO-LOCK NO-ERROR.

                    ASSIGN sit-nf-eletro.cod-livre-1 = ((IF tt-param.l-of               THEN "S" ELSE "N") + "#" +
                                                        (IF tt-param.l-saldo            THEN "S" ELSE "N") + "#" +
                                                        (IF tt-param.l-desatual         THEN "S" ELSE "N") + "#" +
                                                        (IF tt-param.l-custo-padrao     THEN "S" ELSE "N") + "#" +
                                                        (IF tt-param.l-desatualiza-ap   THEN "S" ELSE "N") + "#" +
                                                        (IF tt-param.l-desatualiza-aca  THEN "S" ELSE "N") + "#" +
                                                        (IF tt-param.l-desatualiza-wms  THEN "S" ELSE "N") + "#" +
                                                        (IF tt-param.l-desatualiza-draw THEN "S" ELSE "N") + "#" +
                                                        (IF tt-param.l-desatualiza-cr   THEN "S" ELSE "N") + "#" +
                                                        STRING(tt-param.i-prc-custo)).

                    RELEASE sit-nf-eletro.

                END. /*fim IF  i-tipo-transacao = 2*/

            END. /*fim DO  i-cont*/

        END. /*fim IF  gc-NFe-docs-a-desatu-re0402 <> ""*/
    
    END. /*fim IF  CAN-FIND (FIRST tt-erro-nfe*/


    /*---
    Quando a Situaá∆o da NF-e estiver 12 ou 13, em processo de cancel/inut, e no retorno (ft0911) n∆o foi poss°vel cancelar a nota, 
    gravar na ret-nf-eletro, para mostrar os erros salvos no arquivo re0402.lst (ret-nf-eleltro Ç mostrada no FT0909)
    ---*/

    ASSIGN lExecutadoPeloFT0911 = NO.

    DO  i-cont-progs = 2 TO 20:
        IF  PROGRAM-NAME(i-cont-progs) MATCHES "*ft0911*" THEN DO:
            ASSIGN lExecutadoPeloFT0911 = YES.
            LEAVE.
        END.
    END.

    IF  lExecutadoPeloFT0911 THEN DO: /*Executado pela Rotina de Cancelamento - ft0911*/

        FIND FIRST tt-digita NO-LOCK NO-ERROR. /*criada somente 1 tt-digita por documento no ft0911.p*/

        FOR FIRST docum-est NO-LOCK
            WHERE docum-est.serie-docto  = tt-digita.serie-docto
              AND docum-est.nro-docto    = tt-digita.nro-docto
              AND docum-est.cod-emitente = tt-digita.cod-emitente
              AND docum-est.nat-operacao = tt-digita.nat-operacao:
        END.
        IF  NOT AVAIL docum-est THEN RETURN "OK":U.
            
        FOR FIRST nota-fiscal NO-LOCK
            WHERE nota-fiscal.cod-estabel = docum-est.cod-estabel
              AND nota-fiscal.serie       = docum-est.serie-docto
              AND nota-fiscal.nr-nota-fis = docum-est.nro-docto:
        END.
        IF  NOT AVAIL nota-fiscal THEN RETURN "OK":U.

        
        /* (sit-nf-eletro 12 [NF-e em Processo de Cancelamento] ou 13 [NF-e em Processo de Inutilizaá∆o], quando Ç modo ass°ncrono) */
        IF  &if "{&bf_dis_versao_ems}":U >= "2.07":U &then
              (nota-fiscal.idi-sit-nf-eletro   = 12 OR nota-fiscal.idi-sit-nf-eletro   = 13)
            &else
              CAN-FIND (FIRST sit-nf-eletro NO-LOCK
                        WHERE sit-nf-eletro.cod-estabel  = nota-fiscal.cod-estabel
                          AND sit-nf-eletro.cod-serie    = nota-fiscal.serie
                          AND sit-nf-eletro.cod-nota-fis = nota-fiscal.nr-nota-fis
                          AND (sit-nf-eletro.idi-sit-nf-eletro = 12
                          OR   sit-nf-eletro.idi-sit-nf-eletro = 13))
            &endif
        THEN DO:

            IF  l-erro THEN /*Erros que impediram a desatualizaá∆o*/
            FOR EACH tt-erro-nfe NO-LOCK:

                /*Gravar na ret-nf-eletro*/
                CREATE ret-nf-eletro.
                ASSIGN ret-nf-eletro.cod-estabel = nota-fiscal.cod-estabel
                       ret-nf-eletro.cod-serie   = nota-fiscal.serie
                       ret-nf-eletro.nr-nota-fis = nota-fiscal.nr-nota-fis
                       ret-nf-eletro.cod-msg     = "0"
                       ret-nf-eletro.dat-ret     = TODAY
                       ret-nf-eletro.hra-ret     = REPLACE(STRING(TIME + i-cont-seg, "HH:MM:SS"),":","")
                       ret-nf-eletro.log-ativo   = YES
                       ret-nf-eletro.cod-livre-2 = "[Msg RE0402] " + TRIM(tt-erro-nfe.mensagem).

                ASSIGN i-cont-seg = i-cont-seg + 5. /*Incrementar 5 segundos para n∆o dar problema de chave duplicada*/
            END.
        END.
    END.
    /*---*/

    ASSIGN gc-NFe-docs-a-desatu-re0402 = "".

    EMPTY TEMP-TABLE tt-erro-nfe.

    RELEASE docum-est.
    RELEASE nota-fiscal.

END PROCEDURE.

PROCEDURE pi-grava-erros-para-NFe:

    /*Gravar erros em tabela tempor†ria auxiliar, pois os erros s∆o eliminados na pi-lista-erros*/

    EMPTY TEMP-TABLE tt-erro-nfe.

    FOR EACH tt-erro NO-LOCK:

        CREATE tt-erro-nfe.
        BUFFER-COPY tt-erro TO tt-erro-nfe.
    END.

END PROCEDURE.

PROCEDURE pi-atualizaNotaFiscAdc :
    DEFINE VARIABLE h-bodi515 AS HANDLE     NO-UNDO.
    
    IF  NOT AVAIL nota-fiscal THEN
        RETURN "NOK".

    /* Atualiza nota-fisc-adc (CD4035) */
    IF  NOT VALID-HANDLE(h-bodi515) THEN
        RUN dibo/bodi515.p PERSISTENT SET h-bodi515.

    IF  VALID-HANDLE(h-bodi515) THEN DO:
        RUN cancelaNotaFiscAdc IN h-bodi515 (INPUT nota-fiscal.cod-estabel,
                                             INPUT nota-fiscal.serie,
                                             INPUT nota-fiscal.nr-nota-fis,
                                             INPUT nota-fiscal.cod-emitente,
                                             INPUT nota-fiscal.nat-operacao,
                                             INPUT &IF "{&bf_dis_versao_ems}":U >= "2.07":U &THEN
                                                        nota-fiscal.idi-sit-nf-eletro
                                                   &ELSE
                                                        sit-nf-eletro.idi-sit-nf-eletro
                                                   &ENDIF).
        DELETE PROCEDURE h-bodi515.
    END.

    ASSIGN h-bodi515 = ?.
    /* Fim - Atualiza nota-fisc-adc (CD4035) */

    RETURN "OK".
END PROCEDURE.


