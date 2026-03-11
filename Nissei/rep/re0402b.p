/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0402B 2.00.00.099 } /*** "010099" ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0402b MRE}
&ENDIF

/***************************************************************************
**
**   RE0402B.P - Desatualizacao dos Modulos de Faturamento, O.F. e A.P.
**
***************************************************************************/

{utp/ut-glob.i}
{cdp/cd0666.i}
{ftp/ftapi064.i} 
{cdp/cdcfgdis.i}
/******************** Multi-Planta **********************/
def var i-tipo-movto as integer no-undo.
def var l-cria       as logical no-undo.

{cdp/cd7300.i1}
/************************* Fim **************************/

{include/i-epc200.i re0402b} /** Upc **/

def input        param r-docum          as rowid    no-undo.
def input        param l-somente-of     as logical  no-undo.
def input        param l-cancela-ft     as logical  no-undo.
def input        param l-desatualiza-ap as logical  no-undo.
def output       param l-erro           as logical  no-undo.
def input-output param table            for tt-erro.

def var l-fatur          as  logical                 no-undo.
def var l-ja-alterado    as  logical                 no-undo.
def var l-desatualizou   as  logical                 no-undo.
def var l-per-fec-of     as  logical                 no-undo.
def var l-achou          as  logical                 no-undo.
def var l-dp-cont        as  logical                 no-undo.
def var l-existe-ap      as  logical                 no-undo.
def var da-ult-livro     as  date                    no-undo.
def var c-natur          as  char                    no-undo.
def var c-texto          as  char                    no-undo.
def var i-emite          like docum-est.cod-emitente no-undo.
def var l-existe-ems50   as logical                  no-undo.
def var l-ems50          as logical                  no-undo.
def var c-nr-duplic      like dupli-apagar.nr-duplic no-undo.
def var l-despesa        as logical                  no-undo.
def var i-tipo-transacao as int                      no-undo. /* 1 - Sincrona | 2 - Assincrona */

def var i-empresa-prin  like param-global.empresa-prin no-undo. /* Utilizado para EPC "troca-empresa" */
def var i-empresa       like param-global.empresa-prin no-undo.

DEF VAR i-cod-emitente-upc LIKE docum-est.cod-emitente NO-UNDO.
/*NF-e*/
DEFINE NEW GLOBAL SHARED VARIABLE gc-NFe-docs-a-desatu-re0402 AS CHAR NO-UNDO.

/*  para n„o alterar a chamada do re0402a.p */
/*  foi criada a vari†vel global abaixo     */ 
/*  a mesma È o motivo do cancelamento      */
/*  digitado pelo usu·rio no re0402.w       */
DEFINE NEW GLOBAL SHARED VARIABLE gc-mot-canc-fat-re0402 AS CHAR NO-UNDO.

/* 
** Integracao Modulo Importacao 
*/
def var l-imp        as logical initial no no-undo.
def var l-imp-rateio as logical initial no no-undo.
{cdp/cd4300.i3}   /* include tratamento atributo livre */
{rep/re1001a.i50} /* include tratamento atributo livre docum-est.char-1 */

/* NF-e */
DEFINE VARIABLE h-axsep002           AS HANDLE      NO-UNDO.
DEFINE VARIABLE i-cont               AS INT         NO-UNDO.
DEFINE VARIABLE h-bodi515            AS HANDLE      NO-UNDO.
DEFINE VARIABLE cTpTrans             AS CHARACTER   NO-UNDO.
DEFINE VARIABLE lExecutadoPeloRE0402 AS LOGICAL     NO-UNDO.

DEFINE TEMP-TABLE tt_nfe_erro  NO-UNDO
    FIELD cStat     AS CHAR   
    FIELD chNFe     AS CHAR   
    FIELD dhRecbto  AS CHAR   
    FIELD nProt     AS CHAR.  

DEFINE TEMP-TABLE tt_log_erro NO-UNDO
     FIELD ttv_num_cod_erro  AS INTEGER   INITIAL ?
     FIELD ttv_des_msg_ajuda AS CHARACTER INITIAL ?
     FIELD ttv_des_msg_erro  AS CHARACTER INITIAL ?.


find docum-est 
    where rowid(docum-est) = r-docum exclusive-lock no-error.
find natur-oper
    where natur-oper.nat-operacao = docum-est.nat-operacao no-lock no-error.

find first param-global no-lock no-error.

find param-of
    where param-of.cod-estabel = docum-est.estab-fisc no-lock no-error.

assign i-empresa-prin = param-global.empresa-prin.

&if defined (bf_dis_consiste_conta) &then

    find estabelec where
         estabelec.cod-estabel = docum-est.cod-estabel no-lock no-error.

    run cdp/cd9970.p (input rowid(estabelec),
                      output i-empresa-prin).
&endif

/*--------- INICIO UPC ---------*/

for each tt-epc where tt-epc.cod-event = "troca-empresa":
    delete tt-epc.
end.

create tt-epc.
assign tt-epc.cod-event     = "troca-empresa" 
       tt-epc.cod-parameter = "docum-est rowid"
       tt-epc.val-parameter = string(rowid(docum-est)).

create tt-epc.
assign tt-epc.cod-event     = "troca-empresa" 
       tt-epc.cod-parameter = "i-empresa-prin"
       tt-epc.val-parameter =  string(i-empresa-prin).

{include/i-epc201.i "troca-empresa"}                

find first tt-epc
    where tt-epc.cod-event     = "troca-empresa"
      and tt-epc.cod-parameter = "i-empresa-prin" no-lock no-error.

if  avail tt-epc then 
    &IF "{&bf_dis_versao_ems}":U >= "2.071":U &THEN
    assign i-empresa-prin = tt-epc.val-parameter.
    &ELSE
    assign i-empresa-prin = integer(tt-epc.val-parameter).
    &ENDIF
/*--------- FINAL UPC ---------*/

/* Nota Fiscal de Transferencia - Faturamento */
assign l-fatur = no.
if  natur-oper.imp-nota and not l-somente-of AND l-cancela-ft then do:

    FIND FIRST nota-fiscal
         WHERE nota-fiscal.cod-estabel  = docum-est.cod-estabel
         AND   nota-fiscal.serie        = docum-est.serie-docto
         AND   nota-fiscal.nr-nota-fis  = docum-est.nro-docto
         AND   nota-fiscal.cod-emitente = docum-est.cod-emitente 
         AND   nota-fiscal.nat-operacao = docum-est.nat-operacao EXCLUSIVE-LOCK NO-ERROR.

    if not avail nota-fiscal then 
        FIND FIRST nota-fiscal
            WHERE nota-fiscal.cod-chave-aces-nf-eletro  = docum-est.cod-chave-aces-nf-eletro EXCLUSIVE-LOCK NO-ERROR.

    if avail nota-fiscal then do:

        if  nota-fiscal.ind-tip-nota <> 8 /* Recebimento */ then
            return.
        
        /* Quando a Nota Fiscal do Faturamento n∆o foi atualizada em OF,
           o documento de entrada n∆o poder† ser desatualizado */
        IF  NOT docum-est.of-atual 
        AND natur-oper.ind-gera-of THEN DO:
            run pi-erro-nota ( 32084, " ", yes ).
            return.                              
        END.
        
        /* axsep002 - Foi retirado o enviado de cancelamento para SEFAZ desse ponto e colocado no RE0402rp */
    	/* isso porque havia algumas validacoes (EMS5, por exemplo) que nao permitia a desatualizacao da nota, */
    	/* e a nota era cancelada na SEFAZ e no EMS permanecia com o "Uso autorizado". */
            
        IF  NOT AVAIL estabelec OR 
                     estabelec.cod-estabel <> docum-est.cod-estabel THEN
            FIND FIRST estabelec WHERE
                       estabelec.cod-estabel = docum-est.cod-estabel NO-LOCK NO-ERROR.
 
        /* Validar impress∆o de nota apenas quando funcao SPP-NFE n∆o estiver ativa */
        /* ou quando n∆o for serie eletronica ou n∆o for em ambiente de Producao    */
        IF  NOT CAN-FIND (FIRST funcao 
                          WHERE funcao.cd-funcao = "spp-nfe":U 
                            AND funcao.ativo) 
            OR NOT (&IF "{&bf_dis_versao_ems}":U >= "2.07":U &THEN
                       estabelec.idi-tip-emis-nf-eletro = 3 AND 
                       CAN-FIND(FIRST ser-estab WHERE
                                      ser-estab.cod-estabel = docum-est.cod-estabel AND
                                      ser-estab.serie       = docum-est.serie       AND
                                       ser-estab.log-nf-eletro)
                    &ELSE
                       SUBSTR(estabelec.char-1,168,1)  = "3" AND 
                       CAN-FIND(FIRST ser-estab WHERE
                                      ser-estab.cod-estabel = docum-est.cod-estabel AND
                                      ser-estab.serie       = docum-est.serie       AND
                                      SUBSTRING(ser-estab.char-1,1,3) = "yes")
                    &ENDIF        
                   ) THEN DO:
            if  nota-fiscal.ind-sit-nota = 1 then do:
                run pi-erro-nota ( 16744, " ", yes).
                return.
            end.
         END.

        IF nota-fiscal.cod-chave-aces-nf-eletro <> "" THEN DO:
            RUN cdp/cd0360b.p(INPUT docum-est.cod-estabel,
                              INPUT "NF-e":U,
                              OUTPUT cTpTrans).
            IF cTpTrans = "TC2":U THEN DO:
                
                ASSIGN lExecutadoPeloRE0402 = NO.
                DO  i-cont = 2 TO 15:
                    IF  PROGRAM-NAME(i-cont) MATCHES "*re0402.w*" THEN DO:
                        ASSIGN lExecutadoPeloRE0402 = YES.
                        LEAVE.
                    END.
                END.
                IF lExecutadoPeloRE0402
                AND (LENGTH(gc-mot-canc-fat-re0402) < 15 OR 
                     LENGTH(gc-mot-canc-fat-re0402) > 255) THEN DO:
                    RUN pi-erro-nota(INPUT 54357,
                                     INPUT "",
                                     INPUT YES).
                    RETURN.
                END.
            END.
        END.

        run pi-erro-nota ( 8895, " ", no ).
        
        ASSIGN nota-fiscal.dt-cancela   = today
               nota-fiscal.cd-vendedor  = docum-est.usuario.

        IF estabelec.idi-tip-emis-nf-eletro = 2
        AND TRIM(gc-mot-canc-fat-re0402) <> "" THEN
            ASSIGN nota-fiscal.desc-cancela = gc-mot-canc-fat-re0402.

        /*if nota-fiscal.ind-sit-nota = 4 then
        **   assign docum-est.log-1 = no. */
        for each it-nota-fisc
            where it-nota-fisc.cod-estabel = nota-fiscal.cod-estabel
            and   it-nota-fisc.serie       = nota-fiscal.serie
            and   it-nota-fisc.nr-nota-fis = nota-fiscal.nr-nota-fis exclusive-lock:
            assign it-nota-fisc.dt-cancela   = nota-fiscal.dt-cancela
                   it-nota-fisc.ind-sit-nota = nota-fiscal.ind-sit-nota.
        end.
        if  docum-est.tipo-docto = 1 
        OR  i-pais-impto-usuario > 1 /* internacional */ then
            assign l-fatur = yes
                   docum-est.log-1 = no.

        /* Atualiza situaá∆o do comprovante eletrìnico */
        if  i-pais-impto-usuario <> 1 then do:
            find first internac-autoriz-nfe EXCLUSIVE-LOCK
                where internac-autoriz-nfe.cod-estabel   = docum-est.cod-estabel
                  and internac-autoriz-nfe.cod-serie     = docum-est.serie-docto
                  and internac-autoriz-nfe.cod-documento = docum-est.nro-docto no-error.
            if  avail internac-autoriz-nfe THEN
                ASSIGN internac-autoriz-nfe.idi-sit-comprov = 3. /* Cancelado */
        END.

        RELEASE nota-fiscal.
        RELEASE it-nota-fisc.
    end.
    else if docum-est.tipo-docto = 1 then
            assign docum-est.log-1 = no. /* Marca como n∆o atualizada no Faturamento */
                                         /* Nota pode ter sido eliminada pelo ft0510 */

    /* Desatualizaá∆o do Remito */
    if  i-pais-impto-usuario <> 1 then do:

        find remito 
            where remito.cod-estabel = docum-est.cod-estabel 
              and remito.serie       = docum-est.serie-docto
              and remito.nr-remito   = docum-est.nro-docto no-lock no-error.
        if avail remito then do:

            for each tt-remito:
                delete tt-remito.
            end.      
    
            create tt-remito.
            assign tt-remito.cod-estabel = remito.cod-estabel
                   tt-remito.serie       = remito.serie
                   tt-remito.nr-remito   = remito.nr-remito
                   tt-remito.ind-oper    = 3
                   tt-remito.i-sequen    = 1.
        
           run ftp/ftapi064.p (input  1,                            
                               input  table tt-remito,
                               input  l-despesa,
                               output table tt-erro).

           if  can-find(first tt-erro) then do:
               assign l-erro = yes.
               return.
           end.    
        end.    
    end.
end.

IF (NOT l-cancela-ft AND natur-oper.imp-nota) AND NOT l-somente-of THEN DO:
    run pi-erro-nota ( 8896, " ", yes ).
    return.
END.
/* Eliminacao dos dados de OF */
if  docum-est.of-atual 
and docum-est.origem <> "T":U  then do: /*documentos originados pelo TMS*/
    assign l-ja-alterado  = no
           l-desatualizou = no
           l-per-fec-of   = no
           l-achou        = no.
    if  docum-est.esp-docto = 23 then do:
        find estabelec
            where estabelec.cod-estabel = docum-est.estab-de-or no-lock no-error.
        if avail estabelec then 
            assign i-emite = estabelec.cod-emitente.
    end.
    else do:
       if natur-oper.int-1 = 1
       and docum-est.cod-observa = 3 
       and docum-est.nf-emitida-est then do:      
           find estabelec where 
               estabelec.cod-estabel = docum-est.cod-estabel no-lock no-error.
           if avail estabelec then    
              assign i-emite = estabelec.cod-emitente.
       end.    
       else
              assign i-emite = docum-est.cod-emitente.

      /*    
 *        find doc-fiscal use-index ch-docto where
 *             doc-fiscal.cod-estabel  = docum-est.estab-fisc and
 *             doc-fiscal.serie        = docum-est.serie-docto and
 *             doc-fiscal.nr-doc-fis   = docum-est.nro-docto and
 *             doc-fiscal.cod-emitente = i-emite and
 *             doc-fiscal.nat-operacao = docum-est.nat-operacao
 *             no-lock no-error.
 *          if not avail doc-fiscal and
 *          natur-oper.int-1 = 1 then do:
 *          find doc-fiscal use-index ch-docto where
 *             doc-fiscal.cod-estabel  = docum-est.estab-fisc and
 *             doc-fiscal.serie        = docum-est.serie-docto and
 *             doc-fiscal.nr-doc-fis   = docum-est.nro-docto and
 *             doc-fiscal.cod-emitente = docum-est.cod-emitente and
 *             doc-fiscal.nat-operacao = docum-est.nat-operacao
 *             no-lock no-error.
 *             if avail doc-fiscal then
 *                assign i-emite = docum-est.cod-emitente.
 *       end.  */
    end.  

    if  docum-est.tipo-docto = 2 and param-global.modulo-ft then do:
        blocoItemDocEst:
        FOR EACH item-doc-est NO-LOCK {cdp/cd8900.i item-doc-est docum-est} BREAK BY item-doc-est.nat-of:
            IF  NOT FIRST-OF(item-doc-est.nat-of) THEN
                NEXT. /* S¢ faz a busca se mudar a natureza do item (um docum-est para v†rios doc-fiscal) */

            find doc-fiscal
                where doc-fiscal.cod-estabel  = docum-est.estab-fisc
                and   doc-fiscal.serie        = docum-est.serie-docto
                and   doc-fiscal.nr-doc-fis   = docum-est.nro-docto
                and   doc-fiscal.cod-emitente = i-emite
                and   doc-fiscal.nat-operacao = item-doc-est.nat-of
                no-lock no-error.
            if  avail doc-fiscal then do:
                assign l-achou = yes.
                if  natur-oper.imp-nota then do:            
                    run pi-erro-nota ( 6338, " ", no ).
                    run rep/re9995.p ( input rowid(docum-est),
                                       0, 
                                       0,
                                       6338, 
                                       no,
                                       0,
                                       2 ).                     /* Advertància */
                    leave blocoItemDocEst.
                end.
            end.
        END. /* for each item-doc-est */
    end.            

    if  l-achou = no then do:
        &if defined(bf_dis_ciap) &then    
            FOR EACH item-doc-est NO-LOCK {cdp/cd8900.i item-doc-est docum-est} BREAK BY item-doc-est.nat-of:
                IF  NOT FIRST-OF(item-doc-est.nat-of) THEN
                    NEXT. /* S¢ faz a busca se mudar a natureza do item (um docum-est para v†rios doc-fiscal) */        
         
                find doc-fiscal
                   where doc-fiscal.cod-estabel  = docum-est.estab-fisc
                   and   doc-fiscal.serie        = docum-est.serie-docto
                   and   doc-fiscal.nr-doc-fis   = docum-est.nro-docto
                   and   doc-fiscal.cod-emitente = i-emite
                   and   doc-fiscal.nat-operacao = item-doc-est.nat-of
                   no-lock no-error.
                if avail doc-fiscal then do:
                    find first contr-livros no-lock       
                        where contr-livros.cod-estabel = doc-fiscal.cod-estabel
                          and contr-livros.livro       = 6
                          and contr-livros.dt-ult-emi  >= doc-fiscal.dt-docto no-error.
    
                    if not avail contr-livros then
                        find first contr-livros no-lock       
                             where contr-livros.cod-estabel = doc-fiscal.cod-estabel
                               and contr-livros.livro       = 7        /* ciap 102 */
                               and contr-livros.dt-ult-emi  >= doc-fiscal.dt-docto no-error.
    
                    find first mov-ciap of doc-fiscal no-lock no-error.
    
                    assign l-achou = avail contr-livros
                                     and avail mov-ciap.
                    if l-achou then do:                 
                        run pi-erro-nota ( 18865, " ", yes ).
                        run rep/re9995.p ( input rowid(docum-est),
                                           0, 
                                           0,
                                           18865, 
                                           no,
                                           0,
                                           1 ).                 /* Erro */
                      
                    end.             
                    find first saida-ciap of mov-ciap no-lock no-error.             
                    if avail saida-ciap then do:
                        assign l-achou = yes.
                        run pi-erro-nota ( 18866, " ", yes ).
                       run rep/re9995.p ( input rowid(docum-est),
                                          0, 
                                          0,
                                          18866, 
                                          no,
                                          0,
                                          1 ).           /* Erro */
                      
                    end.                     
                end. 
            end. /* for each item-doc-est */
        &endif       
        for each despesa-aces {cdp/cd8900.i despesa-aces docum-est} no-lock:
            find doc-fiscal use-index ch-docto
                where doc-fiscal.cod-estabel  = docum-est.estab-fisc
                and   doc-fiscal.serie        = despesa-aces.ser-docto-ac
                and   doc-fiscal.nr-doc-fis   = despesa-aces.nro-docto-ac
                and   doc-fiscal.cod-emitente = despesa-aces.cod-forn-ac
                and   doc-fiscal.nat-operacao = despesa-aces.nat-oper-ac
                no-lock no-error.
            if  avail doc-fiscal then do:
                if  doc-fiscal.dt-ult-alt <> ? then
                    assign l-ja-alterado = yes.
                if  avail param-of    
                and doc-fiscal.dt-docto <= param-of.dt-congela then 
                    assign l-per-fec-of = yes.
            end.
        end.

        if (docum-est.tipo-docto = 1 or param-global.modulo-ft = no)
        and l-ja-alterado = no
        and l-per-fec-of  = no then do:
            for each item-doc-est {cdp/cd8900.i item-doc-est docum-est} no-lock:
                find doc-fiscal use-index ch-docto
                    where doc-fiscal.cod-estabel  = docum-est.estab-fisc
                    and   doc-fiscal.serie        = docum-est.serie-docto
                    and   doc-fiscal.nr-doc-fis   = docum-est.nro-docto
                    and   doc-fiscal.cod-emitente = i-emite
                    and   doc-fiscal.nat-operacao = item-doc-est.nat-of
                    exclusive-lock no-error.
                if  avail doc-fiscal then do:
                    if  doc-fiscal.dt-ult-alt <> ? then
                        assign l-ja-alterado = yes.
                    else
                    if  avail param-of
                    and doc-fiscal.dt-docto <= param-of.dt-congela then
                        assign l-per-fec-of = yes.
                end.
            end.
        end.

        if  /* l-ja-alterado = no and */ l-per-fec-of = no then do:
            for each item-doc-est {cdp/cd8900.i item-doc-est docum-est} no-lock:
                find doc-fiscal
                    where doc-fiscal.cod-estabel  = docum-est.estab-fisc
                    and   doc-fiscal.serie        = docum-est.serie
                    and   doc-fiscal.nr-doc-fis   = docum-est.nro-docto
                    and   doc-fiscal.cod-emitente = i-emite
                    and   doc-fiscal.nat-operacao = item-doc-est.nat-of
                    exclusive-lock no-error.
                if  avail doc-fiscal then do:
                    for each it-doc-fisc of doc-fiscal exclusive-lock:
                        if  l-ja-alterado = no then do:
                            &if defined(bf_dis_ciap) &then    
                                find mov-ciap of it-doc-fisc exclusive-lock no-error.                      
                                if  avail mov-ciap then
                                    delete mov-ciap.
                            &endif        
                            if  not l-fatur then
                                delete it-doc-fisc validate (true, "").
                        end.
                    end.
                    if  l-fatur then
                        assign doc-fiscal.ind-sit-doc = 2
                               l-desatualizou         = yes
                               l-ja-alterado          = no.
                    else
                        if  l-ja-alterado = no then do: 
                            delete doc-fiscal validate(true,"").
                            assign l-desatualizou = yes.
                        end.
                end.
            end.

            for each despesa-aces {cdp/cd8900.i docum-est despesa-aces} no-lock:
                find doc-fiscal use-index ch-docto 
                    where doc-fiscal.cod-estabel  = docum-est.estab-fisc
                    and   doc-fiscal.serie        = despesa-aces.ser-docto-ac 
                    and   doc-fiscal.nr-doc-fis   = despesa-aces.nro-docto-ac 
                    and   doc-fiscal.cod-emitente = despesa-aces.cod-forn-ac
                    and   doc-fiscal.nat-operacao = despesa-aces.nat-oper-ac
                    exclusive-lock no-error.
                if  avail doc-fiscal then do:
                    for each it-doc-fisc of doc-fiscal exclusive-lock:
                        if  l-ja-alterado = NO THEN
                            delete it-doc-fisc validate(true, "").
                    end.
                    if  l-ja-alterado = no then do: 
                        RUN dibo/bodi515.p PERSISTENT SET h-bodi515.
                        RUN openQueryStatic    IN h-bodi515 (INPUT "Main":U).
                        RUN emptyRowErrors     IN h-bodi515.
                        RUN eliminaNotaFiscAdc IN h-bodi515 (INPUT docum-est.estab-fisc, 
                                                             INPUT despesa-aces.ser-docto-ac,
                                                             INPUT despesa-aces.nro-docto-ac,
                                                             INPUT despesa-aces.cod-forn-ac,
                                                             INPUT despesa-aces.nat-oper-ac,
                                                             INPUT "", 
                                                             INPUT "",
                                                             INPUT 0,
                                                             INPUT 7). 
                        DELETE PROCEDURE h-bodi515.
                        ASSIGN h-bodi515 = ?.

                        delete doc-fiscal validate (true, "").
                        assign l-desatualizou = yes.
                    end.
                end.
            end.
        end.
    end.

    if  l-ja-alterado or l-per-fec-of then do:
        if  l-ja-alterado then do:
            run pi-erro-nota ( 6339, " ", no ).
            run rep/re9995.p ( input rowid(docum-est),
                               0, 
                               0,
                               6339, 
                               no,
                               0,
                               2 ).                     /* Advertància */
        end.
        else do:
            run pi-erro-nota ( 6340, " ", no ).
            run rep/re9995.p ( input rowid(docum-est),
                               0, 
                               0,
                               6340, 
                               no,
                               0,
                               2 ).                     /* Advertància */
        end.
    end.
    else
    if  l-desatualizou then do:
        assign da-ult-livro = if day(docum-est.dt-trans) < 11
                                 then date(month(docum-est.dt-trans),1,
                                      year(docum-est.dt-trans))
                                 else
                                 if day(docum-est.dt-trans) < 21
                                    then date(month(docum-est.dt-trans),11,
                                          year(docum-est.dt-trans))
                                    else date(month(docum-est.dt-trans),21,
                                         year(docum-est.dt-trans)).
        find first contr-livro
            where contr-livro.cod-estabel = docum-est.estab-fisc
            and   contr-livro.dt-ult-emi  = da-ult-livro
            and   contr-livro.livro       = natur-oper.tipo
            no-lock no-error.
        if  avail contr-livro then do:
            assign c-natur = {ininc/i06in245.i 04 natur-oper.tipo}
                   c-texto = c-natur + "~~" + string(da-ult-livro).
            run pi-erro-nota ( 6341, c-texto, no ).
            run rep/re9995.p ( input rowid(docum-est),
                               0, 
                               0,
                               6341, 
                               no,
                               0,
                               2 ).                     /* Advertància */
        end.
    end.
    assign docum-est.of-atual = l-ja-alterado or l-per-fec-of.
end.

/* Eliminacao dos titulos gerados em AP */
if  docum-est.ap-atual 
and not l-somente-of 
and not l-desatualiza-ap then do:

    /* 
    ** Integracao Modulo Importacao
    ** Objetivo: Verifica se o documento foi gerado pelo M¢dulo de Importaá∆o
    */
    {cdp/cd4300.i4 "yes" docum-est.char-1}
    {rep/re1001a.i51 "yes"}
    if param-global.modulo-07 THEN DO:
       FIND emitente
           WHERE emitente.cod-emitente = docum-est.cod-emitente NO-LOCK NO-ERROR.

       FIND natur-oper
           WHERE natur-oper.nat-operacao = docum-est.nat-operacao NO-LOCK NO-ERROR.
    
       FIND estabelec
           WHERE estabelec.cod-estabel = docum-est.cod-estabel NO-LOCK NO-ERROR.
    
       /*--------- INICIO UPC ---------*/

       for each tt-epc where tt-epc.cod-event = "AlteraNumTitulo":
           delete tt-epc.
       end.
       
       create tt-epc.
       assign tt-epc.cod-event     = "AlteraNumTitulo" 
              tt-epc.cod-parameter = "r-docum-est"
              tt-epc.val-parameter = string(rowid(docum-est)).
       
       {include/i-epc201.i "AlteraNumTitulo"}                
       
       find first tt-epc
           where tt-epc.cod-event     = "AlteraNumTitulo"
             and tt-epc.cod-parameter = "RetornoNumTitulo" no-lock no-error.
       
       if  avail tt-epc then 
           assign c-embarque = tt-epc.val-parameter.
           
       /*--------- FINAL UPC ---------*/             

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

       IF  AVAIL natur-oper
       AND natur-oper.nota-rateio 
       AND c-embarque <> "" THEN
           ASSIGN l-imp-rateio = YES.
    END.

    /*****************************************************************************/        

    assign l-dp-cont   = no
           l-existe-ap = no
           l-ems50     = can-find(funcao where funcao.cd-funcao = "adm-apb-ems-5.00"
                                           and funcao.ativo = yes
                                           and funcao.log-1 = yes).

    {rep/re0402b.i " " " " "dupli-apagar.nr-duplic"}     /* Verifica duplicatas */

    if  l-imp OR l-imp-rateio then do:
        run imp/im9005.p( input        rowid(docum-est),
                          input-output l-existe-ap,
                          input-output l-erro,
                          input-output l-ems50,
                          input-output l-existe-ems50,
                          input-output l-dp-cont).

        if  l-erro then
            return.
    end.         

    for each despesa-aces {cdp/cd8900.i despesa-aces docum-est} no-lock:
        if not l-ems50 then do:    
            find first lin-i-ap
                where lin-i-ap.ep-codigo    = i-empresa-prin
                and   lin-i-ap.cod-estabel  = docum-est.cod-estabel
                and   lin-i-ap.cod-esp      = despesa-aces.cod-esp
                and   lin-i-ap.serie        = despesa-aces.ser-docto-ac
                and   lin-i-ap.nr-docto     = despesa-aces.nro-docto-ac
                and   lin-i-ap.cod-fornec   = despesa-aces.cod-forn-ac
                and   lin-i-ap.ct-debito    = docum-est.ct-transit
                and   lin-i-ap.dt-desconto  = ?
                and   lin-i-ap.dt-emissao   = despesa-aces.dt-emissao
                and   lin-i-ap.dt-vencimen  = despesa-aces.dt-vencto
                and   lin-i-ap.dt-transacao = docum-est.dt-trans
                and   lin-i-ap.sc-debito    = docum-est.sc-transit
                and   lin-i-ap.vl-original  = despesa-aces.valor exclusive-lock no-error.
            if  avail lin-i-ap then do:
                find doc-i-ap
                    where doc-i-ap.ep-codigo  = lin-i-ap.ep-codigo
                    and   doc-i-ap.referencia = lin-i-ap.referencia
                    no-lock no-error.
                if  not available doc-i-ap then
                    delete lin-i-ap.
                else
                    assign l-existe-ap = yes.
            end.
            find first tit-ap use-index codigo
                where tit-ap.ep-codigo   = i-empresa-prin
                and   tit-ap.cod-fornec  = despesa-aces.cod-forn-ac
                and   tit-ap.cod-estabel = docum-est.cod-estabel
                and   tit-ap.cod-esp     = despesa-aces.cod-esp
                and   tit-ap.serie       = despesa-aces.ser-docto-ac
                and   tit-ap.nr-docto    = despesa-aces.nro-docto-ac
                and   tit-ap.vl-original = despesa-aces.valor
                no-lock no-error.
            if  avail tit-ap then do:
                assign l-existe-ap = yes.
                find first mov-ap of tit-ap
                    where mov-ap.contabilizou no-lock no-error.
                if  avail mov-ap then do:
                    assign l-dp-cont = yes.
                    leave.
                end.
            end.
        end.            
        else do:
            RUN Pi-verifica-EMS50 (input docum-est.cod-estabel,
                                   input despesa-aces.cod-forn-ac,
                                   input despesa-aces.cod-esp,
                                   input despesa-aces.ser-docto-ac,
                                   input despesa-aces.nro-docto-ac,
                                   input if despesa-aces.int-1 = 0 then ""
                                         else string(despesa-aces.int-1),
                                   output l-existe-ems50,
                                   output l-erro).
            if l-existe-ems50 then 
                assign l-existe-ap = yes.
            if l-erro then
                return.
    end.
    end.

    if  l-existe-ap then do:
        run pi-erro-nota ( 5513, " ", no ).
        run rep/re9995.p ( input rowid(docum-est),
                           0, 
                           0,
                           5513, 
                           no,
                           0,
                           2 ).                     /* Advertància */
    end.
    else do:
        run rep/re9995.p ( input rowid(docum-est),
                           0, 
                           0,
                           5513, 
                           yes,
                           0,
                           2 ).                     /* Advertància */

        /*  Multi-Planta  */
        assign c-transacao = "MAT036".
        {cdp/cd7300.i5 "001" c-transacao}

        if  param-global.modulo-mp 
        and tt-replica-msg.log-replica-msg = yes 
        and docum-est.ap-atual 
        and docum-est.cod-observa <> 3
        and docum-est.esp-docto = 20 then do:                        
            create tt-dados-env.
            assign tt-dados-env.num-sequencia  = i-seq
                   tt-dados-env.cod-tipo-reg   = 117
                   tt-dados-env.ind-tipo-movto = 7
                   tt-dados-env.identif-msg    = docum-est.serie-docto + " , "
                                               + docum-est.nro-docto   + " , "
                                               + string(docum-est.cod-emitente) + " , "
                                               + docum-est.nat-operacao.             
            raw-transfer docum-est to tt-dados-env.conteudo-msg.
            assign i-seq = i-seq + 1.
        end.          
        {cdp/cd7300.i6 "001" c-transacao}
        /*   Fim Multi-Planta   */

        assign docum-est.ap-atual = no.
    end.
end.




/******************************* PROCEDURES INTERNAS *******************************/

{rep/re0402a.i1}     /* Procedure pi-erro-nota */

{rep/re0402b.i2}     /* Procedure internas */

