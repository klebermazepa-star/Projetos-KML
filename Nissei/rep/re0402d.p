/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
********************************************************************************/
{include/i-prgvrs.i RE0402D 2.00.00.030 } /*** "010030" ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0402d MRE}
&ENDIF

/***************************************************************************
**
**   RE0402D.P - Desatualizacao do Contas a Pagar
**
***************************************************************************/

{utp/ut-glob.i}
{cdp/cd0666.i} 

/*
/******************** Multi-Planta **********************/
def var i-tipo-movto as integer no-undo.
def var l-cria       as logical no-undo.

{cdp/cd7300.i1}
/************************* Fim **************************/
*/

def input        param r-docum          as rowid    no-undo.
def output       param l-erro           as logical  no-undo.
def input-output param table            for tt-erro.

{cdp/cdcfgren.i}    
{app/apapi018.i}         /* Definicao temp-table tt-param    */
{rep/re0402d.i1}         /* Definicao temp-tables do EMS 5.0 */
{include/i-epc200.i "RE0402D"} /* Defini‡Æo TT-EPC */

def buffer b-docum-est           for docum-est.
def buffer b-dupli-apagar        for dupli-apagar.
def buffer b-item-doc-est        for item-doc-est.

def var l-rec-brasil             as log                     no-undo.
def var l-integracao-ems50       as log                     no-undo.
def var de-vl-previsao           as dec                     no-undo.
def var de-vl-item-fatura        as dec                     no-undo.
def var v_log_livre_1            as log  format "Sim/Nao"   no-undo.
def var c-nr-duplic              like dupli-apagar.nr-duplic no-undo.

DEF VAR i-cod-emitente-upc LIKE docum-est.cod-emitente    NO-UNDO.
def var i-empresa          like param-global.empresa-prin no-undo.
DEF VAR h-boar2011         AS HANDLE NO-UNDO.
DEF VAR c-serie-docto-ems5 AS CHAR   NO-UNDO.
DEF VAR c-parcela          AS CHAR   NO-UNDO.
DEF VAR l-existe           AS LOG    NO-UNDO.
DEF VAR l-erro-ems50       AS LOG    NO-UNDO.
DEF VAR i-cont             AS INT    NO-UNDO.
DEF VAR l-credito-debito   AS LOG    NO-UNDO.

DEF TEMP-TABLE tt_msg_erros NO-UNDO
    FIELD ttv_num_seq      AS INT  FORMAT ">>>,>>9"
    FIELD ttv_num_msg_erro AS INT  FORMAT ">>>>>>9"
    FIELD ttv_dsl_msg_erro AS CHAR FORMAT "x(255)".


/*
** Integra‡Æo M¢dulo de Importa‡Æo
*/
{cdp/cd4300.i3}   /* include tratamento atributo livre */
{rep/re1001a.i50} /* include tratamento atributo livre docum-est.char-1 */
def var l-imp        as logical INIT NO no-undo.
def var l-imp-rateio as logical INIT NO no-undo.

{cdp/cdcfgmat.i}        /* Release 2.02 e 2.03- Materiais */
{cdp/cdcfgdis.i}

find first param-global no-lock no-error.

find docum-est
    where rowid(docum-est) = r-docum exclusive-lock no-error.

{cdp/cd4300.i4 "yes" docum-est.char-1}
{rep/re1001a.i51 "yes"}

FIND FIRST natur-oper WHERE natur-oper.nat-operacao = docum-est.nat-operacao NO-LOCK NO-ERROR.

IF param-global.modulo-07 THEN DO:
   FIND emitente
       WHERE emitente.cod-emitente   = docum-est.cod-emitente NO-LOCK NO-ERROR.   

   FIND estabelec
       WHERE estabelec.cod-estabel   = docum-est.cod-estabel NO-LOCK NO-ERROR.

   IF  AVAIL natur-oper 
   AND NOT natur-oper.nota-rateio AND
       c-embarque <> "":U THEN DO:
       IF  AVAIL emitente
       AND (emitente.natureza = 3 OR 
            emitente.natureza = 4) THEN
           IF AVAIL estabelec 
           AND  estabelec.pais <> emitente.pais THEN
             assign l-imp = yes.
   END.
   
   IF AVAIL natur-oper
   AND natur-oper.nota-rateio
   AND c-embarque <> "" THEN
       ASSIGN l-imp-rateio = YES.
END.

find funcao
    where funcao.cd-funcao = "adm-apb-ems-5.00"
      and funcao.ativo
      and funcao.log-1 
    no-lock no-error. 

assign l-integracao-ems50 = avail funcao
       l-rec-brasil       = i-pais-impto-usuario = 1.   /* Brasil */


/* Documento de Cr‚dito/D‚bito nÆo possui duplicatas */
IF i-pais-impto-usuario <> 1 AND AVAIL natur-oper AND
   (natur-oper.log-gera-ncredito OR SUBSTRING(natur-oper.char-2,134,1) = "1":U) AND
   NOT CAN-FIND(FIRST dupli-apagar {cdp/cd8900.i dupli-apagar docum-est}) THEN DO:

        IF i-pais-impto-usuario = 2 /* Argentina */ THEN DO:
            IF NOT VALID-HANDLE(h-boar2011) THEN
                RUN local/arg/boar2011.p PERSISTENT SET h-boar2011.
    
            RUN BuscaSerieAPB IN h-boar2011 (INPUT i-ep-codigo-usuario,
                                             INPUT docum-est.cod-emitente,
                                             INPUT docum-est.serie-docto,
                                             INPUT natur-oper.cod-esp,
                                             INPUT ROWID(docum-est),
                                             OUTPUT c-serie-docto-ems5).
    
            IF VALID-HANDLE(h-boar2011) THEN DO:
                RUN destroy IN h-boar2011.
                ASSIGN h-boar2011 = ?.
            END.
        END.
        ELSE
            ASSIGN c-serie-docto-ems5 = docum-est.serie-docto.

        EMPTY TEMP-TABLE tt_msg_erros.
        ASSIGN c-parcela        = ""
               l-existe         = NO
               l-erro-ems50     = NO
               l-credito-debito = YES.
        
        RUN prgint/dcf/dcf900za.py (INPUT "001", /*Versao API*/
                                    INPUT "1",   /*Modulo para pesquisa: APB*/
                                    INPUT (STRING(docum-est.cod-estabel)   + "," +
                                           STRING(docum-est.cod-emitente)  + "," +
                                           STRING(natur-oper.cod-esp)      + "," +
                                           STRING(c-serie-docto-ems5)      + "," +
                                           STRING(docum-est.nro-docto)     + ","), /*Chave titulo*/
                                    INPUT YES,                                     /*indica se quer procurar pela ultima parcela*/
                                    OUTPUT l-existe,                               /*titulo encontrado ou nao*/
                                    OUTPUT c-parcela,                              /*retorna a ultima parcela do documento*/
                                    INPUT-OUTPUT TABLE tt_msg_erros,               /*temp-table de erros*/
                                    OUTPUT l-erro-ems50).                          /*indica se foram incluidos novos erros na temp-table*/        

        DO i-cont = 1 TO INT(c-parcela):            
            run pi-cria-temp-table (docum-est.nro-docto,
                                    c-serie-docto-ems5,
                                    docum-est.cod-emitente,
                                    natur-oper.cod-esp,
                                    STRING(i-cont,"99"),
                                    docum-est.dt-emissao,
                                    yes /* Elimina IR e ISS */ ).
            
        END.

END.




/*
** Duplicatas de Material (dupli-apagar)
*/ 
{rep/re0402d.i2}

/*
** Integra‡Æo M¢dulo Importa‡Æo - Duplicatas de Despesas do Material
*/
if l-imp OR l-imp-rateio then do:
    run imp/im9039.p (input r-docum,
                      output l-erro,
                      input-output table tt-erro).
    if l-erro then
        return.
end.

/* Duplicata da Despesa Acessoria - Brasil */
for each despesa-aces {cdp/cd8900.i despesa-aces docum-est} no-lock:

    find natur-oper 
        where natur-oper.nat-operacao = despesa-aces.nat-oper-ac no-lock no-error.

    if  not natur-oper.emite-dupli then 
        next.

    run pi-cria-temp-table ( despesa-aces.nro-docto-ac,
                             despesa-aces.ser-docto-ac,
                             despesa-aces.cod-forn-ac,
                             despesa-aces.cod-esp,
                             despesa-aces.int-1,
                             despesa-aces.dt-emissao,
                             no /* Nao tem imposto */ ). 

    
end.

/* Atualiza Saldo da Previsao e Situcao Remito/Fatura - Internacional */
if  not l-rec-brasil
and docum-est.nff  
and docum-est.nat-operacao = " " /* Fatura */ then
    run pi-atualiza-previsao.

{rep/re0402d.i3}    

procedure pi-atualiza-previsao:
    {rep/re1001b.i50}

    for each item-doc-est {cdp/cd8900.i item-doc-est docum-est} 
         and item-doc-est.sit-item <> 2 exclusive-lock  /* Itens da Fatura que possuem Remito */
        break by item-doc-est.sequencia:

        {cdp/cd4300.i4  "yes" item-doc-est.char-1} 
        {rep/re1001b.i51 "yes"}

        find b-item-doc-est 
            where b-item-doc-est.cod-emitente = item-doc-est.cod-emitente 
              and b-item-doc-est.serie-docto  = item-doc-est.serie-comp
              and b-item-doc-est.nro-docto    = item-doc-est.nro-comp     
              and b-item-doc-est.nat-operacao = item-doc-est.nat-comp    
              and b-item-doc-est.sequencia    = item-doc-est.seq-comp     
            exclusive-lock no-error.

        find b-docum-est          {cdp/cd8900.i b-docum-est    b-item-doc-est} exclusive-lock no-error.
        find first b-dupli-apagar {cdp/cd8900.i b-dupli-apagar b-item-doc-est} no-lock no-error.

        /* Atualiza situacao dos itens da Fatura e do Remito */        
        assign item-doc-est.sit-item   = 1  /* Ok */
               b-item-doc-est.sit-item = 2  /* Aguardando Fatura */

               /* Atualiza Saldo do Remito */
               b-item-doc-est.qt-saldo = b-item-doc-est.qt-saldo 
                                       + item-doc-est.quantidade.

        /* Atualiza situacao da Fatura e do Remito */        
        if  last-of(item-doc-est.sequencia) then
            assign docum-est.sit-docum   = item-doc-est.sit-item
                   b-docum-est.sit-docum = b-item-doc-est.sit-item.
    end.    
end.


