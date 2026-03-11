/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0404A 2.00.00.068 } /*** "010068" ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0404a MRE}
&ENDIF

/****************************************************************************
**
**       PROGRAMA: RE0404A.P
**
**       DATA....: JUNHO DE 1997
**
**       OBJETVO.: INTEGRAÄ«O COM CONTAS A PAGAR
**
**       VERS«O..: 1.00.000 - Sandra Stadelhofer
**
****************************************************************************/

{utp/ut-glob.i}
{cdp/cd0666.i} /**** Definiá∆o da temp-table tt-erro ****/
{rep/re0404.i1} /* Define temp-tables, frames e varivaeis e preprocessadores comuns */
{cdp/cd4300.i3}

{app/apapi001b.i} /*Definiá∆o de tem-tables */
{cdp/cd0031.i "MRE"} /*Seguranca por Estabelecimento*/

def input param raw-param as raw no-undo.
def input param table for tt-raw-digita.

def new global shared var c-RE0301-origem as char    no-undo.
DEF var l-erro-ap as logical no-undo.

def shared stream arq-export.

def shared var i-param as integer no-undo.

def var de-val-tot       as   decimal no-undo.
def var c-ref            like lin-i-ap.referencia no-undo.
def var c-ref2           like lin-i-ap.referencia no-undo.
def var i-ep-codigo      like lin-i-ap.ep-codigo  no-undo.
def var i-aux            as integer no-undo.
def var i-seq-exp        as integer no-undo.
def var l-erro-at        as logical no-undo.
def var l-erro-mp        as logical no-undo.
def var l-usa-mp         as logical no-undo.
def var l-exporta        as logical no-undo.
def var l-primer         as logical initial yes.
def var i-empresa like param-global.empresa-prin no-undo.
{cdp/cdcfgdis.i}

def buffer b-natur-oper  for natur-oper.
def buffer b-docum-est   for docum-est.

def var l-erro           as logical no-undo.
def var l-ems50         as logical                    no-undo.
def var l-conecta-ems50 as logical                    no-undo.
def var h-boin090       as handle                     no-undo.
def var h-bocx255       as handle                     no-undo.

def var l-ja-conectado  as logical                    no-undo.

DEF VAR l-dupli-apagar-cex AS LOGICAL INITIAL NO      NO-UNDO.

{btb/btb009za.i}

DEF VAR h-btb009za AS HANDLE.

if  can-find(funcao where funcao.cd-funcao = "adm-apb-ems-5.00" and
    funcao.ativo = yes and
    funcao.log-1 = yes) then
    assign l-ems50 = yes.

{include/tt-edit.i}
{include/pi-edit.i}

FOR EACH tt-lin-i-ap:             
    DELETE tt-lin-i-ap.           
END.                              
FOR EACH tt-lin-conta-ap:         
    DELETE tt-lin-conta-ap.       
END.                              
FOR EACH tt-impto-tit-pend-ap.    
    DELETE tt-impto-tit-pend-ap.  
END.                              

form 
    tt-erro.i-sequen 
    tt-erro.cd-erro 
    tt-editor.conteudo format "x(50)" 
    skip(01)
    with stream-io width 132 frame f-erro.

/* Inicio -- Projeto Internacional -- ut-trfrrp.p adicionado */
RUN utp/ut-trfrrp.p (INPUT FRAME f-erro:HANDLE).


{include/i-epc200.i re0404a} /** Upc **/

{utp/ut-liter.i Sequància * r}
assign tt-erro.i-sequen:label in frame f-erro = return-value.

{utp/ut-liter.i C¢digo * r}
assign tt-erro.cd-erro:label in frame f-erro = return-value.

{utp/ut-liter.i Mensagem * r}
assign tt-editor.conteudo:label in frame f-erro = return-value.

run utp/ut-acomp.p persistent set h-acomp.
{utp/ut-liter.i Integraá∆o_com_Contas_a_Pagar *}

run pi-inicializar in h-acomp (input  Return-value ).


create tt-param.
raw-transfer raw-param to tt-param.

for each tt-raw-digita:
    create tt-digita.
    raw-transfer tt-raw-digita.raw-digita to tt-digita.
end.

{rep/re9340.i1 "new"} /* Frame F-CORPO */

RUN utp/ut-liter.p (INPUT docum-est.nro-docto:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN docum-est.nro-docto:LABEL IN FRAME f-corpo = RETURN-VALUE.

RUN utp/ut-liter.p (INPUT docum-est.serie-docto:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN docum-est.serie-docto:LABEL IN FRAME f-corpo = RETURN-VALUE.

RUN utp/ut-liter.p (INPUT docum-est.nat-operacao:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN docum-est.nat-operacao:LABEL IN FRAME f-corpo = RETURN-VALUE.

RUN utp/ut-liter.p (INPUT docum-est.cod-emitente:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN docum-est.cod-emitente:LABEL IN FRAME f-corpo = RETURN-VALUE.

RUN utp/ut-liter.p (INPUT emitente.nome-abrev:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN emitente.nome-abrev:LABEL IN FRAME f-corpo = RETURN-VALUE.

RUN utp/ut-liter.p (INPUT docum-est.cod-estabel:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN docum-est.cod-estabel:LABEL IN FRAME f-corpo = RETURN-VALUE.

RUN utp/ut-liter.p (INPUT dupli-apagar.dt-emissao:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN dupli-apagar.dt-emissao:LABEL IN FRAME f-corpo = RETURN-VALUE.

RUN utp/ut-liter.p (INPUT  dupli-apagar.dt-trans:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN  dupli-apagar.dt-trans:LABEL IN FRAME f-corpo = RETURN-VALUE.

RUN utp/ut-liter.p (INPUT dupli-apagar.dt-vencim:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN dupli-apagar.dt-vencim:LABEL IN FRAME f-corpo = RETURN-VALUE.

RUN utp/ut-liter.p (INPUT replace(dupli-apagar.vl-a-pagar:LABEL IN FRAME f-corpo, ' ', '_'), INPUT '', INPUT '').
ASSIGN dupli-apagar.vl-a-pagar:LABEL IN FRAME f-corpo = RETURN-VALUE.

{utp/ut-liter.i Vcto_Desc}
ASSIGN dupli-apagar.dt-venc-desc:LABEL IN FRAME f-corpo = RETURN-VALUE.                                              

RUN utp/ut-liter.p (INPUT dupli-apagar.desconto:LABEL IN FRAME f-corpo, INPUT '', INPUT '').
ASSIGN dupli-apagar.desconto:LABEL IN FRAME f-corpo = RETURN-VALUE.

{utp/ut-liter.i Desconto}
ASSIGN dupli-apagar.vl-desconto:LABEL IN FRAME f-corpo = RETURN-VALUE.

find first param-global no-lock no-error.
find first param-estoq  no-lock no-error.

assign c-RE0301-origem = "RE0404".

/**********************************************************************
**      EMS - 5.0 Integraá∆o "On-line" Datasul-EMS 2.0
**********************************************************************/

if  l-ems50 then do:
    if  search("prgint/dcf/dcf900za.r")  = ?
    and search("prgint/dcf/dcf900za.py") = ? then do:
        run utp/ut-msgs.p ( input "msg", input 6246, input "prgint/dcf/dcf900za.py" ).
        create tt-erro.
        assign tt-erro.cd-erro  = 6246
               tt-erro.mensagem = return-value.
        run pi-finalizar in h-acomp.
        return.        
    end.

    run pi-conecta-ems5 ( 1 ). /* 1 = conecta */

    if l-erro then do:
      run pi-finalizar in h-acomp.
       undo, return "NOK".
    end.  
end.  

do  on endkey undo, return
    on error  undo, retry:

    assign de-val-tot = 0
           i-aux      = 0.
    nota-fisc:
    for each b-docum-est use-index dt-tp-estab
        where b-docum-est.dt-trans >= tt-param.da-data-i
        and   b-docum-est.dt-trans <= tt-param.da-data-f
    &if defined(bf_mat_selecao_estab_re) &then
        and   b-docum-est.cod-estabel >= tt-param.c-est-ini
        and   b-docum-est.cod-estabel <= tt-param.c-est-fim
    &endif
        and   b-docum-est.ce-atual  = yes
        and   b-docum-est.ap-atual  = no no-lock transaction:
            
        {cdp/cd0031a.i b-docum-est.cod-estabel}     

        ASSIGN l-dupli-apagar-cex = NO
               l-erro-ap          = NO.

        {rep/re1001a.i50}
        {cdp/cd4300.i4 "yes" b-docum-est.char-1}
        {rep/re1001a.i51 "yes"}
        IF param-global.modulo-07 THEN DO:
            IF c-embarque <> "":U THEN DO:
                RUN cxbo/bocx255.p PERSISTENT SET h-bocx255.

                RUN findDupliApagarCex IN h-bocx255 (INPUT b-docum-est.serie-docto,
                                                     INPUT b-docum-est.nro-docto,
                                                     INPUT b-docum-est.cod-emitente,
                                                     INPUT b-docum-est.nat-operacao,
                                                     OUTPUT l-dupli-apagar-cex).

                IF VALID-HANDLE(h-bocx255) THEN DO:
                    DELETE PROCEDURE h-bocx255.
                    ASSIGN h-bocx255 = ?.
                END.
            END.
        END.

       /***********************************************************************
        * Consistància para somente chamar o re9340 para os documentos que o  *
        * estabelecimento estiver dentro de alguma faixa do tt-digita         *
        **********************************************************************/
       if param-estoq.gera-ap = 2 then do:
            assign l-exporta = no.
            for each tt-digita:
               if  b-docum-est.cod-estabel >= tt-digita.estab-i
               and b-docum-est.cod-estabel <= tt-digita.estab-f then do:
                    assign l-exporta = yes.
                    leave.
               end.
            end.
            if l-exporta = no then 
                next.
       end.

       run pi-acompanhar in h-acomp (input b-docum-est.nro-docto).

       find docum-est
           where rowid(docum-est) = rowid(b-docum-est)
           exclusive-lock no-error.

       assign i-empresa = param-global.empresa-prin.

       &if defined (bf_dis_consiste_conta) &then

           find estabelec where
                estabelec.cod-estabel = docum-est.cod-estabel no-lock no-error.

           run cdp/cd9970.p (input rowid(estabelec),
                             output i-empresa).
       &endif

       find param-re where param-re.usuario = docum-est.usuario no-lock no-error.

       find natur-oper where natur-oper.nat-operacao = docum-est.nat-operacao no-lock no-error.

       find emitente
          where emitente.cod-emitente = docum-est.cod-emitente
          no-lock no-error.

       IF CAN-FIND(FIRST dupli-apagar {cdp/cd8900.i dupli-apagar docum-est}) OR
          CAN-FIND(FIRST despesa-aces {cdp/cd8900.i despesa-aces docum-est}) OR 
          l-dupli-apagar-cex OR
          (i-pais-impto-usuario <> 1 AND
           natur-oper.tipo = 2       AND
           param-global.modulo-ap    AND
           docum-est.esp-docto = 20) THEN DO:
       
        IF natur-oper.tipo = 1 THEN DO:

             run rep/re9340.p (input  rowid(docum-est),
                               input  l-usa-mp,
                               output l-erro-at,
                               input-output table tt-lin-i-ap,          
                               input-output table tt-lin-conta-ap,
                               input-output table tt-impto-tit-pend-ap,
                               input-output de-val-tot,
                               input-output table tt-erro).

        END.         
        ELSE DO:
          if  natur-oper.tipo = 2          /* SAIDA                                */
          and i-pais-impto-usuario <> 1    /* Somente Internacional                */
          and param-global.modulo-ap       /* AP implantado                        */
          and docum-est.esp-docto = 20     /* Devoluá∆o a fornecedor               */
          then do:  

            &IF "{&bf_dis_versao_ems}" = "2.042" &THEN /* Documento gera nota de crÇdito no AP */
             if not can-find(first item-doc-est of docum-est 
                             where item-doc-est.log-geracao-nrc-ap) then next.
            &ELSEIF "{&bf_dis_versao_ems}" >= "2.05" &THEN /* Nesta release, nome do campo foi corrigido.*/
             if not can-find(first item-doc-est of docum-est 
                             where item-doc-est.log-geracao-ncr-ap) then next.
            &ELSE    
             if not can-find(first item-doc-est of docum-est 
                             where item-doc-est.log-geracao-nrc-ap) then next.
            &ENDIF

            run rep/reapi005.p (input rowid(docum-est),
                                output l-erro-ap,
                                INPUT-OUTPUT TABLE tt-doc-i-ap,
                                input-output table tt-lin-i-ap,
                                input-output table tt-lin-conta-ap,
                                input-output table tt-impto-tit-pend-ap,
                                INPUT-OUTPUT de-val-tot,
                                input-output table tt-erro ).

          END. /*** Termino atualizaá∆o Nota CrÇdito ***/
        END.
        
        IF  param-estoq.gera-ap = 1 THEN
            disp docum-est.nro-docto
                 docum-est.serie-docto
                 docum-est.nat-operacao
                 docum-est.cod-emitente
                 emitente.nome-abrev
                 docum-est.cod-estabel                 
                 with frame f-corpo stream-io.
        
        for each dupli-apagar {cdp/cd8900.i dupli-apagar docum-est} no-lock:
            if param-estoq.gera-ap = 1 then do:  
               disp dupli-apagar.parcela
                    dupli-apagar.cod-esp
                    dupli-apagar.dt-emissao
                    dupli-apagar.dt-trans 
                    dupli-apagar.dt-vencim
                    dupli-apagar.vl-a-pagar
                    dupli-apagar.dt-venc-desc
                    dupli-apagar.desconto                                  
                    dupli-apagar.vl-desconto
                    with frame f-corpo stream-io.
               down with frame f-corpo.
            end.   
        end.                                     

        for each despesa-aces {cdp/cd8900.i despesa-aces docum-est} no-lock:

            find emitente 
               where emitente.cod-emitente = despesa-aces.cod-forn-ac
               no-lock no-error.
           find natur-oper
              where natur-oper.nat-operacao = despesa-aces.nat-oper-ac 
              no-lock no-error.

           if  natur-oper.emite-dupli then do:

              if param-estoq.gera-ap = 1 then do:         
                 disp despesa-aces.nro-docto-ac  @ docum-est.nro-docto            
                      despesa-aces.ser-docto-ac  @ docum-est.serie-docto
                      despesa-aces.nat-oper-ac   @ docum-est.nat-operacao
                      despesa-aces.cod-forn-ac   @ docum-est.cod-emitente
                      emitente.nome-abrev        
                      string(despesa-aces.int-1) @ dupli-apagar.parcela                      
                      despesa-aces.cod-esp       @ dupli-apagar.cod-esp
                      despesa-aces.dt-emissao    @ dupli-apagar.dt-emissao                    
                      docum-est.dt-trans         @ dupli-apagar.dt-trans
                      despesa-aces.dt-vencto     @ dupli-apagar.dt-vencim
                      despesa-aces.valor         @ dupli-apagar.vl-a-pagar    
                      with frame f-corpo stream-io.
                 down with frame f-corpo.
              end.
           end.          
        end.

        find first tt-erro no-lock no-error.
        if avail tt-erro then do:
            if param-estoq.gera-ap = 2 then do: /*exporta*/
                find emitente
                    where emitente.cod-emitente = docum-est.cod-emitente
                    no-lock no-error.

                 disp /*param-global.ep-codigo   @ lin-i-ap.ep-codigo   */
                     docum-est.cod-estabel    @ lin-i-ap.cod-estabel 
/*                     tt-lin-i-ap.cod-esp      when first-of(tt-lin-i-ap.cod-esp)   @ lin-i-ap.cod-esp   */
                     docum-est.cod-emitente   @ lin-i-ap.cod-fornec  
                     emitente.nome-abrev            
                     docum-est.nro-docto      @ lin-i-ap.nr-docto
                     docum-est.serie-docto    @ lin-i-ap.serie
/*                     tt-lin-i-ap.parcela    @ lin-i-ap.parcela  */
                     docum-est.dt-emissao     @ lin-i-ap.dt-emissao  
                     docum-est.dt-trans       @ lin-i-ap.dt-transacao  
/*                     tt-lin-i-ap.dt-vencimen  @ lin-i-ap.dt-vencimen
                     tt-lin-i-ap.vl-original  @ lin-i-ap.vl-original*/
                     with frame f-corpo2 stream-io.
                down with frame f-corpo2.
            end.
            for each tt-erro EXCLUSIVE-LOCK:
               put string(tt-erro.cd-erro,">>>>>9") at 44.
               run pi-print-editor (input tt-erro.mensagem, input 80).
               for each tt-editor:
                   put tt-editor.conteudo at 50 format "X(80)" skip.
               end.
               delete tt-erro.
            end.
            put skip(1).
        end.            

        if l-erro-at = YES
        OR l-erro-ap = yes then do:
            undo nota-fisc, next nota-fisc.
        end.
      END.
    end.

    put skip(01).
    /* Projeto Internacional -- Traducao de DISPLAY. Validar e verificar possibilidade de colocar em FRAME */
    DEFINE VARIABLE c-lbl-liter-total AS CHARACTER FORMAT "X(12)" NO-UNDO.
    {utp/ut-liter.i "TOTAL" *}
    ASSIGN c-lbl-liter-total = TRIM(RETURN-VALUE).
    DISPLAY "" @ docum-est.nro-docto
            "" @ docum-est.serie-docto
            "" @ docum-est.nat-operacao
            "" @ docum-est.cod-emitente
            "" @ emitente.nome-abrev
            "" @ docum-est.cod-estabel
            STRING("     " + c-lbl-liter-total) @ dupli-apagar.dt-vencim
            de-val-tot @ dupli-apagar.vl-a-pagar
            with frame f-corpo stream-io.
    down with frame f-corpo.


    assign i-param = 0.
    if param-estoq.gera-ap = 2 then do:

       for each tt-digita:
          assign i-aux  = 1 + i-aux * int(i-aux <> 9)
               c-ref  = string(day(today),"99")
                      + if month(today) < 10 then string(month(today),"9")
                                             else entry(month(today) - 9,"A,B,C")
               c-ref2 = substr(string(time,"hh:mm"), 1, 2)
                      + substr(string(time,"hh:mm"), 4, 2)
                      + substr(string(time,"hh:mm:ss"), 7, 2)
                      + string(i-aux,"9").
         output stream arq-export to value(tt-digita.arquivo) append.
         find last tt-lin-i-ap use-index codigo
            where tt-lin-i-ap.ep-codigo   = tt-digita.ep-codigo
            and   tt-lin-i-ap.referencia <> ""
            and   tt-lin-i-ap.seq-import  > 0 no-lock no-error.
         assign i-seq-exp = if avail tt-lin-i-ap
                               then tt-lin-i-ap.seq-import + 10 else 10.

         for each tt-lin-i-ap
            where tt-lin-i-ap.cod-estabel  >= tt-digita.estab-i
            and   tt-lin-i-ap.cod-estabel  <= tt-digita.estab-f
            and   tt-lin-i-ap.dt-transacao >= tt-param.da-data-i
            and   tt-lin-i-ap.dt-transacao <= tt-param.da-data-f
            and   tt-lin-i-ap.referencia    = ""
            break by tt-lin-i-ap.cod-estabel
                  by tt-lin-i-ap.dt-transacao
                  by tt-lin-i-ap.cod-esp
                  by tt-lin-i-ap.sequencia transaction:

            if first-of(tt-lin-i-ap.dt-transacao) or
               first-of(tt-lin-i-ap.cod-estabel)  or
               first-of(tt-lin-i-ap.cod-esp)      then
                 run pi-exporta-doc-i-ap.

            assign i-ep-codigo            = i-empresa
                   tt-lin-i-ap.referencia = c-ref + c-ref2
                   tt-lin-i-ap.seq-import = i-seq-exp
                   tt-lin-i-ap.ep-codigo  = tt-digita.ep-codigo.

           {rep/re0404.i2}

            find emitente
                where emitente.cod-emitente = tt-lin-i-ap.cod-fornec
                no-lock no-error.

            disp tt-lin-i-ap.ep-codigo    when first-of(tt-lin-i-ap.cod-esp)   @ lin-i-ap.ep-codigo   
                 tt-lin-i-ap.cod-estabel  when first-of(tt-lin-i-ap.cod-esp)   @ lin-i-ap.cod-estabel 
                 tt-lin-i-ap.cod-esp      when first-of(tt-lin-i-ap.cod-esp)   @ lin-i-ap.cod-esp   
                 tt-lin-i-ap.cod-fornec   @ lin-i-ap.cod-fornec  
                 emitente.nome-abrev            
                 tt-lin-i-ap.nr-docto     @ lin-i-ap.nr-docto
                 tt-lin-i-ap.serie        @ lin-i-ap.serie
                 tt-lin-i-ap.parcela      @ lin-i-ap.parcela  
                 tt-lin-i-ap.dt-emissao   @ lin-i-ap.dt-emissao  
                 tt-lin-i-ap.dt-transacao @ lin-i-ap.dt-transacao  
                 tt-lin-i-ap.dt-vencimen  @ lin-i-ap.dt-vencimen
                 tt-lin-i-ap.vl-orig-me   @ lin-i-ap.vl-original
                 with frame f-corpo2 stream-io.
            down with frame f-corpo2.

            for each tt-lin-conta-ap
                where tt-lin-conta-ap.ep-codigo   = i-ep-codigo
                and   tt-lin-conta-ap.cod-estabel = tt-lin-i-ap.cod-estabel
                and   tt-lin-conta-ap.cod-esp     = tt-lin-i-ap.cod-esp
                and   tt-lin-conta-ap.serie       = tt-lin-i-ap.serie
                and   tt-lin-conta-ap.nr-docto    = tt-lin-i-ap.nr-docto
                and   tt-lin-conta-ap.parcela     = tt-lin-i-ap.parcela
                and   tt-lin-conta-ap.cod-fornec  = tt-lin-i-ap.cod-fornec:
                assign tt-lin-conta-ap.ep-codigo  = tt-lin-i-ap.ep-codigo.
                {rep/re0404.i4}
            end.

            for each tt-impto-tit-pend-ap 
                where tt-impto-tit-pend-ap.ep-codigo  = i-ep-codigo
                and   tt-impto-tit-pend-ap.cod-est    = tt-lin-i-ap.cod-est
                and   tt-impto-tit-pend-ap.cod-esp    = tt-lin-i-ap.cod-esp                       
                and   tt-impto-tit-pend-ap.serie      = tt-lin-i-ap.serie
                and   tt-impto-tit-pend-ap.cod-fornec = tt-lin-i-ap.cod-fornec
                and   tt-impto-tit-pend-ap.nr-docto   = tt-lin-i-ap.nr-docto
                and   tt-impto-tit-pend-ap.parcela    = tt-lin-i-ap.parcela:
                assign tt-impto-tit-pend-ap.ep-codigo = i-ep-codigo.
                {rep/re0404.i3}
            end.

            if last-of(tt-lin-i-ap.dt-transacao) or
               last-of(tt-lin-i-ap.cod-estabel)  or 
               last-of(tt-lin-i-ap.cod-esp)      then 
            do:
                /* Projeto Internacional -- Traducao de DISPLAY. Validar e verificar possibilidade de colocar em FRAME */
                DEFINE VARIABLE c-lbl-liter-total-2 AS CHARACTER FORMAT "X(12)" NO-UNDO.
                {utp/ut-liter.i "Total" *}
                ASSIGN c-lbl-liter-total-2 = TRIM(RETURN-VALUE).
                display STRING("     " + c-lbl-liter-total-2) @ lin-i-ap.dt-vencimen
                      de-total-movto @ lin-i-ap.vl-original
                      with frame f-corpo2 stream-io.
                 down with frame f-corpo2.
                assign i-aux  = 1 + i-aux * int(i-aux <> 9)
                      c-ref2 = substr(string(time,"hh:mm"), 1, 2)
                             + substr(string(time,"hh:mm"), 4, 2)
                             + substr(string(time,"hh:mm:ss"), 7, 2)
                             + string(i-aux,"9")
                      de-total-movto = 0.

            end.   
         end.
         output stream arq-export close.
      end.
    end.
end.

if l-ems50 then 
    run pi-conecta-ems5 ( 2 ). /* 2 = disconecta */

if  valid-handle (h-btb009za) AND
    h-btb009za:TYPE = "PROCEDURE":U AND
    h-btb009za:FILE-NAME = "btb/btb009za.p":U then do:
    DELETE PROCEDURE h-btb009za.
    assign h-btb009za = ?.
end.    

run pi-finalizar in h-acomp.

/*****************************************************************************************************/

Procedure pi-exporta-doc-i-ap:
    def buffer b-tt-lin-i-ap for tt-lin-i-ap.

    assign de-total-movto = 0.
    for each b-tt-lin-i-ap
       where b-tt-lin-i-ap.cod-estabel  = tt-lin-i-ap.cod-estabel
       and   b-tt-lin-i-ap.cod-esp      = tt-lin-i-ap.cod-esp
       and   b-tt-lin-i-ap.dt-transacao = tt-lin-i-ap.dt-transacao
       and   b-tt-lin-i-ap.referencia   = "" no-lock:

/*       
        if  lin-i-ap.mo-codigo = 0 then
            assign de-total-movto = de-total-movto
                                  + b-tt-lin-i-ap.vl-original.
        else*/

            assign de-total-movto = de-total-movto
                                  + b-tt-lin-i-ap.vl-orig-me.
    end.

    create tt-doc-i-ap.
    assign tt-doc-i-ap.cod-esp    = if param-global.modulo-ap = no 
                                    then "CT" /* Atualizaá∆o via Multiplanta             */ 
                                              /* Indica contabilizaá∆o na planta destino */
                                    else "" 
          tt-doc-i-ap.cod-estabel = tt-lin-i-ap.cod-estabel
          tt-doc-i-ap.data-movto  = tt-lin-i-ap.dt-transacao
          tt-doc-i-ap.ep-codigo   = tt-digita.ep-codigo
          tt-doc-i-ap.referencia  = c-ref + c-ref2
          tt-doc-i-ap.total-movto = de-total-movto
          tt-doc-i-ap.cod-versao-integ = 002
          tt-doc-i-ap.ind-elimina-lote = if avail param-re and 
                                                  param-re.erro-dupli then 2 /* n∆o elimina o tt-doc-i-ap em caso de erro na api*/
                                                                       else 1. /* elimina o tt-doc-i-ap em caso de erro na api*/
    {rep/re0404.i5}

End Procedure.

/* Conecta as bases do EMS5 */

procedure pi-conecta-ems5:

    def input param i-conect as integer no-undo.

    RUN btb/btb009za.p PERSISTENT SET h-btb009za.

    if i-conect = 1 then do:
        if not connected("emsbas") or 
           not connected("emsfin") or 
           not connected("emsuni") then do:          

            if  valid-handle (h-btb009za) AND
               h-btb009za:TYPE = "PROCEDURE":U AND
               h-btb009za:FILE-NAME = "btb/btb009za.p":U then do:

               run pi-conecta-bco IN h-btb009za (Input 1,                         /*contem a vers“o de integraÓ“o da Api*/
                                                 Input i-conect,                  /*contem a opÓ“o desejada (1-Conex“o, 2-Desconex“o)*/
                                                 Input param-global.empresa-prin, /*contem o cÆdigo da empresa*/
                                                 Input "all",                     /*contem o cÆdigo do banco externo*/ 
                                                 Output Table tt_erros_conexao).  /*retorna erros caso existam*/
            end.
        end.
        else
            assign l-ja-conectado = yes.
    end.
    else do:
        if l-ja-conectado = no then do:
            if connected("emsbas") or 
               connected("emsfin") or 
               connected("emsuni") then do:

                if  valid-handle (h-btb009za) AND
                   h-btb009za:TYPE = "PROCEDURE":U AND
                   h-btb009za:FILE-NAME = "btb/btb009za.p":U then do:

                   run pi-conecta-bco IN h-btb009za (Input 2,                         /*contem a vers“o de integraÓ“o da Api*/
                                                     Input i-conect,                  /*contem a opÓ“o desejada (1-Conex“o, 2-Desconex“o)*/
                                                     Input param-global.empresa-prin, /*contem o cÆdigo da empresa*/
                                                     Input "all",                     /*contem o cÆdigo do banco externo*/ 
                                                     Output Table tt_erros_conexao).  /*retorna erros caso existam*/
                end.
            end.    
        end.    
    end.

end.

