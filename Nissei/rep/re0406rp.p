/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0406RP 2.00.00.038 } /*** "010038" ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0406rp MRE}
&ENDIF

{include/i_fnctrad.i}
/*******************************************************************************
**
**   Programa: RE0406
**
**   Data....: Junho de 1997
**
**   Objetivo: Eliminar Documentos e Saldos Terceiros Zerados.
**
**   Versao..: I.00.005 - Marciana - 18/12/96 - DATASUL-MTI - FO 66
**                    Estava utilizando chave errada p/ busca dos componentes,
**                    O campo  componente.codigo-rejei  foi  substituido  pelo
**                    componente.seq-comp.
******************************************************************************/
define temp-table tt-param
    field destino          as integer
    field arquivo          as char
    field usuario          as char format "x(12)"
    field data-exec        as date
    field hora-exec        as integer
    field l-doctos         like item.loc-unica
    field l-terc           like item.loc-unica
    field c-per            as c format "9999/99"
    field i-emitente-ini   like emitente.cod-emitente
    field i-emitente-fim   like emitente.cod-emitente
    field c-serie-ini      like docum-est.serie-docto
    field c-serie-fim      like docum-est.serie-docto
    field c-nro-ini        like docum-est.nro-docto
    field c-nro-fim        like docum-est.nro-docto
    field c-nat-codigo-ini like natur-oper.nat-operacao
    field c-nat-codigo-fim like natur-oper.nat-operacao
    field c-estabel-ini    like estabelec.cod-estabel
    field c-estabel-fim    like estabelec.cod-estabel
    field c-item-ini       like item.it-codigo
    field c-item-fim       like item.it-codigo
    field l-imp-param      as log.

disable triggers for load of docum-est .   
disable triggers for load of doc-fisico.   

def temp-table tt-raw-digita
    field raw-digita as raw.

def input parameter raw-param as raw no-undo.
def input parameter table for tt-raw-digita.

create tt-param.
raw-transfer raw-param to tt-param. 

def buffer b-saldo for saldo-estoq.

/* Empresa do Usuario */
DEFINE NEW GLOBAL SHARED VARIABLE i-ep-codigo-usuario AS CHARACTER NO-UNDO.

def var c-titulo        as c    format "x(38)".
def var c-lb1           as c    format "x(1)".
def var c-sel           as char format "x(20)".
def var c-par           as char format "x(20)".
def var c-imp           as char format "x(20)".
def var c-labels-4      as char format "x(10)".
def var c-labels-5      as char format "x(11)".
def var da-data-ate              as date form "99/99/9999"   no-undo.
def var c-mensagem        as c.
def var i-cont1         as int.
def var i-cont2         as int.
def var da-ult-fech-dia as date format "99/99/9999" no-undo.

{cdp/cdcfgdis.i}            /* Vari†veis Release 2.02 - Materiais */
{cdp/cdcfgmat.i}
{method/dbotterr.i} /* Definiá∆o da RowErrors */

{include/i-epc200.i RE0406RP} /** Upc **/

/* Variaveis Integracao Modulo Importacao */
def var l-imp as logical init no no-undo.

/* Seguranáa por estabelecimento - Def. temp-table tt_estab_ems2 e verif. se seguranáa ativa no m¢dulo) */
{cdp/cd0031.i "MRE"}

/* Estas variaveis nao podem ser no-undo */

def var i-doctos                 as integer label "Documentos".
def var i-terc                   as integer label "Saldos Terceiros Zerados".
def var c-arquivo                as character format "x(20)".
def var l-erro-x                 as logical.
def var l-ce9998-x               as logical.
def var l-x                      as logical.
def var i-mes-x                  as integer.
def var i-ano-x                  as integer.
def var da-data-ini-x            as date.
def var r-registro               as rowid.

form c-titulo      no-label at 1  skip
     "-----------------------------" at 7 skip(1)
     i-doctos      colon 40
     i-terc        colon 40
     with frame f-totais side-labels overlay row 17 attr-space stream-io.

{utp/ut-liter.i Total_de_registros_eliminados * L}
assign c-titulo = return-value.
{utp/ut-liter.i Documentos * L}
assign i-doctos:label in frame f-totais = return-value.
{utp/ut-liter.i Saldos_em_Terceiros_Zerados * L}
assign i-terc:label in frame f-totais = return-value.

{utp/ut-liter.i Ö * L}
assign c-lb1 = return-value.

form  skip(2)
      c-sel no-labels at 5  skip(01)       
      tt-param.i-emitente-ini   to 44   c-lb1 no-label at 68 tt-param.i-emitente-fim   no-labels  at 83 skip
      tt-param.c-serie-ini      to 40   c-lb1 no-label at 68 tt-param.c-serie-fim      no-labels  at 83 skip
      tt-param.c-nro-ini        to 51   c-lb1 no-label at 68 tt-param.c-nro-fim        no-labels  at 83 skip
      tt-param.c-item-ini       to 51   c-lb1 no-label at 68 tt-param.c-item-fim       no-labels  at 83 skip      
      tt-param.c-nat-codigo-ini to 41   c-lb1 no-label at 68 tt-param.c-nat-codigo-fim no-labels  at 83 skip
      tt-param.c-estabel-ini    to 40   c-lb1 no-label at 68 tt-param.c-estabel-fim    no-labels  at 83 skip
      with no-box side-labels stream-io width 132 frame f-selecao.                 

{utp/ut-liter.i SELEÄ«O * L}
assign c-sel = return-value.  
{utp/ut-field.i mgind movto-estoq cod-emitente 1}
assign tt-param.i-emitente-ini:label in frame f-selecao = return-value.     
{utp/ut-field.i mgind movto-estoq serie-docto 1}
assign tt-param.c-serie-ini:label in frame f-selecao = return-value.     
{utp/ut-field.i mgind movto-estoq nro-docto 1}
assign tt-param.c-nro-ini:label in frame f-selecao = return-value.     
{utp/ut-field.i mgind item it-codigo 1}
assign tt-param.c-item-ini:label in frame f-selecao = return-value.
{utp/ut-field.i mgind natur-oper nat-operacao 1}
assign tt-param.c-nat-codigo-ini:label in frame f-selecao = return-value.
{utp/ut-field.i mgind movto-estoq cod-estabel 1}
assign tt-param.c-estabel-ini:label in frame f-selecao = return-value.


form skip(2)
     c-par no-labels at 6   skip(01)
     tt-param.l-doctos     at 13 skip
     tt-param.c-per        at 29 skip 
     tt-param.l-terc       at 13 skip
     with no-box side-labels stream-io width 132 frame f-parametro. 

{utp/ut-liter.i PAR∂METROS * L}
assign c-par = return-value.                           
{utp/ut-liter.i Documentos * L}
assign tt-param.l-doctos:label in frame f-parametro = return-value.
{utp/ut-liter.i Eliminar_Documentos_atÇ * L}
assign tt-param.c-per:label in frame f-parametro = return-value.
{utp/ut-liter.i Saldos_Terceiros_Zerados * L}
assign tt-param.l-terc:label in frame f-parametro = return-value.

form skip(2)
     c-imp no-labels at 4  skip (01)
     c-labels-4  at 25 tt-param.destino at 35 "-"  tt-param.arquivo skip
     c-labels-5  at 25 tt-param.usuario at 35
     with no-box no-labels stream-io width 132 frame f-impressao. 

{include/i-rpvar.i}

FIND empresa NO-LOCK WHERE empresa.ep-codigo = i-ep-codigo-usuario NO-ERROR.
IF AVAILABLE empresa THEN ASSIGN c-empresa  = empresa.razao-social.

assign c-programa    = "RE/0406"
       c-versao      = "I.00"
       c-revisao     = "005".

{utp/ut-liter.i Eliminaá∆o_de_Dados_do_Recebimento * L}
assign c-titulo-relat = return-value.       

find first param-global no-lock no-error.
find first param-estoq no-lock no-error.

/*--- Bancos Historicos ---
{bhp/bh9810.i}
-------------------------*/
run utp/ut-trfrrp.p (input frame f-impressao:handle).
run utp/ut-trfrrp.p (input frame f-parametro:handle).
run utp/ut-trfrrp.p (input frame f-selecao:handle).
run utp/ut-trfrrp.p (input frame f-totais:handle).
{include/i-rpcab.i}

           
if  integer(substring(tt-param.c-per,5,2)) = 12 then
    assign da-data-ate = date(12,31,integer(substring(tt-param.c-per,1,4))).
else
    assign da-data-ate = date(integer(substring(tt-param.c-per,5,2)) + 1,01,
                              integer(substring(tt-param.c-per,1,4))) - 1.
assign i-doctos      = 0
       i-terc        = 0.

{include/i-rpout.i}    
def var h-acomp as handle no-undo.
run utp/ut-acomp.p persistent set h-acomp.

{utp/ut-liter.i Eliminaá∆o_de_Dados_do_Recebimento * R}
run pi-inicializar in h-acomp (input return-value).


view frame f-cabec.
view frame f-rodape.
if tt-param.l-doctos then do:

    for each  docum-est use-index atual exclusive-lock
        where docum-est.cod-estabel  >= tt-param.c-estabel-ini
          and docum-est.cod-estabel  <= tt-param.c-estabel-fim
          and docum-est.cod-emitente >= tt-param.i-emitente-ini
          and docum-est.cod-emitente <= tt-param.i-emitente-fim
          and docum-est.serie-docto  >= tt-param.c-serie-ini
          and docum-est.serie-docto  <= tt-param.c-serie-fim
          and docum-est.nro-docto    >= tt-param.c-nro-ini
          and docum-est.nro-docto    <= tt-param.c-nro-fim
          and docum-est.nat-operacao >= tt-param.c-nat-codigo-ini
          and docum-est.nat-operacao <= tt-param.c-nat-codigo-fim
          and docum-est.dt-trans     <= da-data-ate
          and ce-atual = yes transaction:

          /* Seguranáa estabelecimento - Se estiver ativa e o usu†rio n∆o tem permiss∆o no estab, executa o NEXT */
          {cdp/cd0031a.i docum-est.cod-estabel}

          /************************************************************/
          /* Chama a PI e passa o codigo do estabelecimento corrente, */
          /* retornando a data do ultimo periodo fechado.             */
          /* (Mais detalhes ver coment†rio na PI)                     */
          /************************************************************/
          run pi-verifica-ult-fech-dia (input docum-est.cod-estabel,
                                        output da-ult-fech-dia). 

          if docum-est.dt-trans <= da-ult-fech-dia then do: /*Validaá∆o que evita a eliminaá∆o de documentos ligados a periodos reabertos.*/

                {utp/ut-liter.i Eliminando_Documentos_atÇ * R}
                assign c-mensagem = return-value + substr(tt-param.c-per,1,4) 
                                    + "/" + substr(tt-param.c-per,5,2) + ":" + 
                                    string(i-doctos).         
                run pi-acompanhar in h-acomp (input c-mensagem).


                /* Integracao Modulo Importacao */        
                find emitente where emitente.cod-emitente = docum-est.cod-emitente no-lock no-error.        
                find estabelec where estabelec.cod-estabel = docum-est.cod-estabel no-lock no-error.                 
                if  param-global.modulo-07
                and emitente.pais <> estabelec.pais then
                    assign l-imp = yes.            
                if  l-imp then
                    run imp/im9002.p(input  rowid(docum-est)).            

                assign r-registro = rowid (docum-est).

                 assign i-cont1 = 0               
                        i-cont2 = 0.

                for each item-doc-est {cdp/cd8900.i item-doc-est docum-est} exclusive-lock:
                    assign i-cont1 = i-cont1 + 1.                   
                    if  item-doc-est.it-codigo   >= c-item-ini
                    and item-doc-est.it-codigo   <= c-item-fim then do:


                        /* Verifica se existem devolucoes que ainda nao foram
                        atualizadas nas estatisticas de faturamento. Em caso
                        positivo, nao elimina o documento em questao. */
                        if  param-global.modulo-ft                        
                        and docum-est.cod-observa = 3 then do:

                            find natur-oper
                               where natur-oper.nat-operacao = item-doc-est.nat-comp
                               no-lock no-error.
                            if  avail natur-oper
                            and natur-oper.atual-estat then do:

                                find first devol-cli use-index ch-nfe             
                                     where devol-cli.serie-docto  = docum-est.serie-docto
                                       and devol-cli.nro-docto    = docum-est.nro-docto
                                       and devol-cli.cod-emitente = docum-est.cod-emitente
                                       and devol-cli.nat-operacao = docum-est.nat-operacao
                                       and devol-cli.ind-atu-est  = no
                                      no-lock no-error.
                                if avail devol-cli then next.
                            end.
                        end.
                    end.

                    FOR EACH item-doc-est-troca USE-INDEX codigo
                       where item-doc-est-troca.cod-serie        = item-doc-est.serie-docto  and
                             item-doc-est-troca.nro-docto        = item-doc-est.nro-docto    and
                             item-doc-est-troca.cdn-emitente     = item-doc-est.cod-emitente and
                             item-doc-est-troca.cod-nat-operacao = item-doc-est.nat-operacao and
                             item-doc-est-troca.num-sequencia    = item-doc-est.sequencia  EXCLUSIVE-LOCK:
                       DELETE item-doc-est-troca.     
                    END.

                    /*esocial*/
                    for each docum-est-esoc 
                        WHERE docum-est-esoc.serie-docto  = item-doc-est.serie-docto  
                          AND docum-est-esoc.nro-docto    = item-doc-est.nro-docto    
                          AND docum-est-esoc.cod-emitente = item-doc-est.cod-emitente 
                          AND docum-est-esoc.nat-operacao = item-doc-est.nat-of exclusive-lock:
                        delete docum-est-esoc.
                    end.

                    assign i-cont2 = i-cont2 + 1.  
                    delete item-doc-est.
                end.

                if i-cont1 <> i-cont2 then undo, next.

                for each devol-cli use-index ch-nfe
                   where devol-cli.serie-docto  = docum-est.serie-docto
                     and devol-cli.nro-docto    = docum-est.nro-docto
                     and devol-cli.cod-emitente = docum-est.cod-emitente
                     and devol-cli.nat-operacao = docum-est.nat-operacao exclusive-lock:
                     delete devol-cli validate(true, "").
                end.
                for each rat-lote {cdp/cd8900.i rat-lote docum-est} exclusive-lock:
                    delete rat-lote.
                end.
                for each rat-ordem {cdp/cd8900.i rat-ordem docum-est} exclusive-lock:
                    delete rat-ordem.
                end.
                for each rat-docum {cdp/cd8900.i rat-docum docum-est} exclusive-lock:
                    delete rat-docum.
                end.
                for each movto-pend {cdp/cd8900.i movto-pend docum-est} exclusive-lock:
                    delete movto-pend.
                end.
                for each despesa-aces {cdp/cd8900.i despesa-aces docum-est} exclusive-lock:
                    delete despesa-aces.
                end.

                for each dupli-imp 
                   where dupli-imp.serie-docto  = docum-est.serie-docto  and
                         dupli-imp.nro-docto    = docum-est.nro-docto    and
                         dupli-imp.cod-emitente = docum-est.cod-emitente and
                         dupli-imp.nat-operacao = docum-est.nat-operacao exclusive-lock:
                    delete dupli-imp.
                end.

                for each dupli-apagar {cdp/cd8900.i dupli-apagar docum-est} exclusive-lock:
                    delete dupli-apagar.
                end.

                &if  defined(bf_dis_devol_forn) &then
                     for each devol-forn 
                        where devol-forn.cod-emitente = docum-est.cod-emitente
                          and devol-forn.serie-docto  = docum-est.serie-docto
                          and devol-forn.nro-docto    = docum-est.nro-docto
                          and devol-forn.nat-operacao = docum-est.nat-operacao exclusive-lock:
                        delete devol-forn.
                     end.
                &endif                

                for each consist-nota {cdp/cd8900.i consist-nota docum-est} exclusive-lock:
                    delete consist-nota.
                end.

                /*Unidade de Neg¢cio*/
                for each unid-neg-nota
                   where unid-neg-nota.cod-emitente = docum-est.cod-emitente
                     and unid-neg-nota.serie-docto  = docum-est.serie-docto 
                     and unid-neg-nota.nro-docto    = docum-est.nro-docto 
                     and unid-neg-nota.nat-operacao = docum-est.nat-operacao exclusive-lock:
                    DELETE unid-neg-nota.
                END.
               
                FOR EACH ext-docum-est
                    WHERE ext-docum-est.serie-docto  = docum-est.serie-docto 
                      AND ext-docum-est.nro-docto    = docum-est.nro-docto   
                      AND ext-docum-est.cod-emitente = docum-est.cod-emitente
                      AND ext-docum-est.nat-operacao = docum-est.nat-operacao exclusive-lock:
                    DELETE ext-docum-est.
                END.

                FOR EACH ext-item-doc-est 
                    WHERE ext-item-doc-est.serie-docto  = docum-est.serie-docto  
                      AND ext-item-doc-est.nro-docto    = docum-est.nro-docto    
                      AND ext-item-doc-est.cod-emitente = docum-est.cod-emitente 
                      AND ext-item-doc-est.nat-operacao = docum-est.nat-operacao exclusive-lock:                     
                    DELETE ext-item-doc-est.
                END.

                /* Configurador de Tributos */
                FOR EACH ct-trib-item-doc-est EXCLUSIVE-LOCK
                   WHERE ct-trib-item-doc-est.cdn-emitente     = docum-est.cod-emitente 
                     AND ct-trib-item-doc-est.cod-ser-docto    = docum-est.serie-docto  
                     AND ct-trib-item-doc-est.cod-docto        = docum-est.nro-docto
                     AND ct-trib-item-doc-est.cod-natur-operac = docum-est.nat-operacao: 
                      DELETE ct-trib-item-doc-est.
                END.

                /*Dados de Importaá∆o - RE1001A3*/
                FOR EACH docto-estoq-nfe-imp 
                    WHERE docto-estoq-nfe-imp.cdn-emitente     = docum-est.cod-emitente
                      AND docto-estoq-nfe-imp.cod-ser-docto    = docum-est.serie-docto   
                      AND docto-estoq-nfe-imp.cod-docto        = docum-est.nro-docto       
                      AND docto-estoq-nfe-imp.cod-natur-operac = docum-est.nat-operacao exclusive-lock: 
                    
                    FOR EACH item-docto-estoq-nfe-imp 
                       WHERE item-docto-estoq-nfe-imp.cdn-emitente     = docto-estoq-nfe-imp.cdn-emitente
                         AND item-docto-estoq-nfe-imp.cod-ser-docto    = docto-estoq-nfe-imp.cod-ser-docto   
                         AND item-docto-estoq-nfe-imp.cod-docto        = docto-estoq-nfe-imp.cod-docto       
                         AND item-docto-estoq-nfe-imp.cod-natur-operac = docto-estoq-nfe-imp.cod-natur-operac exclusive-lock:
                        DELETE item-docto-estoq-nfe-imp.                           
                    END.
                    DELETE docto-estoq-nfe-imp.
                END.

                /*Dados de Embalagem - RE1001a2*/
                FOR EACH docto-estoq-embal 
                    WHERE docto-estoq-embal.cod-ser-docto    = docum-est.serie-docto  
                      AND docto-estoq-embal.cod-docto        = docum-est.nro-docto    
                      AND docto-estoq-embal.cdn-emitente     = docum-est.cod-emitente 
                      AND docto-estoq-embal.cod-natur-operac = docum-est.nat-operacao exclusive-lock:
                    DELETE docto-estoq-embal.
                END.

                FOR EACH item-doc-est-tribut 
                     WHERE item-doc-est-tribut.cod-serie-docto  = docum-est.serie-docto
                       AND item-doc-est-tribut.cod-num-docto    = docum-est.nro-docto       
                       AND item-doc-est-tribut.cdn-emitente     = docum-est.cod-emitente
                       AND item-doc-est-tribut.cod-natur-operac = docum-est.nat-operacao  exclusive-lock:                
                    DELETE item-doc-est-tribut.
                END.

                /*--------- INICIO UPC ---------*/

                for each tt-epc where tt-epc.cod-event = "delete-docto":
                    delete tt-epc.
                end.

                create tt-epc.
                assign tt-epc.cod-event     = "delete-docto" 
                       tt-epc.cod-parameter = "docum-est rowid"
                       tt-epc.val-parameter = string(rowid(docum-est)).

                 {include/i-epc201.i "delete-docto"}                
                 /*--------- FINAL UPC ---------*/

                for each  fat-despesa
                    where fat-despesa.serie-docto = docum-est.serie-docto
                      and fat-despesa.nro-docto = docum-est.nro-docto
                      and fat-despesa.cod-emitente = docum-est.cod-emitente
                      and fat-despesa.nat-operacao = docum-est.nat-operacao
                      exclusive-lock:
                    delete fat-despesa.
                end.

                for each  extra-fornec
                    where extra-fornec.cod-emitente = docum-est.cod-emitente
                      and extra-fornec.nro-docto    = docum-est.nro-docto
                      and extra-fornec.serie-docto  = docum-est.serie-docto
                      and extra-fornec.nat-operacao = docum-est.nat-operacao
                      exclusive-lock:
                    delete extra-fornec.
                end.

                for each  desp-item-doc-est
                    where desp-item-doc-est.serie-docto = docum-est.serie-docto
                      and desp-item-doc-est.nro-docto = docum-est.nro-docto
                      and desp-item-doc-est.cod-emitente = docum-est.cod-emitente
                      and desp-item-doc-est.nat-operacao = docum-est.nat-operacao
                      exclusive-lock:
                    delete desp-item-doc-est.
                end.  

                /** Elimina dados Recebimento Fisico**/
                if  param-estoq.rec-fisico then do:
                    find first doc-fisico
                        where  doc-fisico.nro-docto    = docum-est.nro-docto
                        and    doc-fisico.serie-docto  = docum-est.serie-docto
                        and    doc-fisico.cod-emitente = docum-est.cod-emitente exclusive-lock no-error.
                    if  avail doc-fisico then do:

                        for each  it-doc-fisico
                            where it-doc-fisico.serie-docto  = doc-fisico.serie-doc
                            and   it-doc-fisico.nro-docto    = doc-fisico.nro-docto
                            and   it-doc-fisico.cod-emitente = doc-fisico.cod-emitente
                            and   it-doc-fisico.tipo-nota    = doc-fisico.tipo-nota exclusive-lock:
                            delete it-doc-fisico validate(true, "").
                        end.

                        delete doc-fisico.
                    end.
                end.

                /* Eliminar documento WMS */
                IF CONNECTED('mgscm') THEN DO:
    
                    FIND FIRST param-estoq NO-LOCK NO-ERROR.
                    IF AVAIL param-estoq AND (substring(param-estoq.char-2,6,1) = "1") THEN DO:
    
                        RUN wmp/wm9085.p (INPUT docum-est.cod-estabel,
                                          INPUT STRING(docum-est.nro-docto),
                                          INPUT 3,
                                          OUTPUT TABLE RowErrors).
    
                    END.
                END.
                delete docum-est validate(true," ").

                /*----- Bancos Historicos - elimina arquivo de extensao ------*/
                find first his-docum-est
                     where his-docum-est.serie-docto  = docum-est.serie-docto
                      and  his-docum-est.nro-docto    = docum-est.nro-docto
                      and  his-docum-est.cod-emitente = docum-est.cod-emitente
                      and  his-docum-est.nat-operacao = docum-est.nat-operacao
                      exclusive-lock no-error.
                if  avail his-docum-est then
                    delete his-docum-est validate(true,"").
                /*------------------------------------------------------------*/

                assign i-doctos = i-doctos + 1.
          end.
          else
              next.
    end.
end.

if tt-param.l-terc then do: 
    /*message "Eliminando movimentacao com Terceiros...".*/
    for each saldo-terc
       where saldo-terc.serie-docto  >= tt-param.c-serie-ini
         and saldo-terc.serie-docto  <= tt-param.c-serie-fim
         and saldo-terc.nro-docto    >= tt-param.c-nro-ini
         and saldo-terc.nro-docto    <= tt-param.c-nro-fim         
         and saldo-terc.cod-emitente >= tt-param.i-emitente-ini
         and saldo-terc.cod-emitente <= tt-param.i-emitente-fim
         and saldo-terc.nat-operacao >= tt-param.c-nat-codigo-ini
         and saldo-terc.nat-operacao <= tt-param.c-nat-codigo-fim        
         and saldo-terc.it-codigo    >= tt-param.c-item-ini
         and saldo-terc.it-codigo    <= tt-param.c-item-fim
         and saldo-terc.cod-estabel  >= tt-param.c-estabel-ini
         and saldo-terc.cod-estabel  <= tt-param.c-estabel-fim
         and saldo-terc.quantidade    = 0   
         and saldo-terc.dt-retorno   <= da-data-ate exclusive-lock transaction:         
         
         /* Seguranáa estabelecimento - Se estiver ativa e o usu†rio n∆o tem permiss∆o no estab, executa o NEXT */
         {cdp/cd0031a.i saldo-terc.cod-estabel}

         /************************************************************/
         /* Chama a PI e passa o codigo do estabelecimento corrente, */
         /* retornando a data do ultimo periodo fechado.             */
         /* (Mais detalhes ver coment†rio na PI)                     */
         /************************************************************/
         run pi-verifica-ult-fech-dia (input saldo-terc.cod-estabel,
                                       output da-ult-fech-dia). 

         if saldo-terc.dt-retorno <= da-ult-fech-dia then do: /*Validaá∆o que evita a eliminaá∆o de movimentaá∆o com Terceiros, ligadas a periodos reabertos.*/

           assign r-registro = rowid (saldo-terc).        
           {utp/ut-liter.i Eliminando_Saldos_em_Terceiros_Zerados * R}
           assign c-mensagem = return-value + ":" + string(i-doctos).         
           run pi-acompanhar in h-acomp (input c-mensagem). 

           find first componente
                where componente.cod-emitente = saldo-terc.cod-emitente
                  and componente.serie-comp   = saldo-terc.serie-docto
                  and componente.nro-comp     = saldo-terc.nro-docto
                  and componente.nat-comp     = saldo-terc.nat-oper
                  and componente.it-codigo    = saldo-terc.it-codigo
                  and componente.cod-refer    = saldo-terc.cod-refer
                  and componente.seq-comp     = saldo-terc.sequencia
                  and componente.dt-retorno   > da-data-ate
                  no-lock no-error.
           if avail componente then
               next. /* Existem retorno em per°odo aberto. Documentos n∆o ser† eliminado - Magnus I00 */
           for each  componente
               where componente.cod-emitente = saldo-terc.cod-emitente
                 and componente.serie-docto  = saldo-terc.serie-docto
                 and componente.nro-docto    = saldo-terc.nro-docto
                 and componente.nat-oper     = saldo-terc.nat-oper
                 and componente.it-codigo    = saldo-terc.it-codigo
                 and componente.cod-refer    = saldo-terc.cod-refer
                 and componente.sequencia    = saldo-terc.sequencia exclusive-lock:

                 FOR EACH rat-componente
                    WHERE rat-componente.serie-docto   = componente.serie-docto 
                      AND rat-componente.nro-docto     = componente.nro-docto   
                      AND rat-componente.cod-emitente  = componente.cod-emitente
                      AND rat-componente.nat-operacao  = componente.nat-operacao
                      AND rat-componente.it-codigo     = componente.it-codigo
                      AND rat-componente.cod-refer     = componente.cod-refer
                      AND rat-componente.sequencia     = componente.sequencia EXCLUSIVE-LOCK:  

                     DELETE rat-componente.                          
                 END.
                 DELETE componente.
           end.
           for each  componente
               where componente.cod-emitente = saldo-terc.cod-emitente
                 and componente.serie-comp   = saldo-terc.serie-docto
                 and componente.nro-comp     = saldo-terc.nro-docto
                 and componente.nat-comp     = saldo-terc.nat-oper
                 and componente.it-codigo    = saldo-terc.it-codigo
                 and componente.cod-refer    = saldo-terc.cod-refer
                 and componente.seq-comp     = saldo-terc.sequencia exclusive-lock: 

               FOR EACH rat-componente
                    WHERE rat-componente.serie-docto  = componente.serie-docto 
                     AND rat-componente.nro-docto     = componente.nro-docto   
                     AND rat-componente.cod-emitente  = componente.cod-emitente
                     AND rat-componente.nat-operacao  = componente.nat-operacao
                     AND rat-componente.it-codigo     = componente.it-codigo
                     AND rat-componente.cod-refer     = componente.cod-refer
                     AND rat-componente.sequencia     = componente.sequencia EXCLUSIVE-LOCK:  

                    DELETE rat-componente.
               END.
               DELETE componente.
           end.

           FOR EACH rat-saldo-terc 
              WHERE rat-saldo-terc.serie-docto  = saldo-terc.serie-docto 
                AND rat-saldo-terc.nro-docto    = saldo-terc.nro-docto   
                AND rat-saldo-terc.cod-emitente = saldo-terc.cod-emitente
                AND rat-saldo-terc.nat-operacao = saldo-terc.nat-operacao
                AND rat-saldo-terc.it-codigo    = saldo-terc.it-codigo
                AND rat-saldo-terc.cod-refer    = saldo-terc.cod-refer
                AND rat-saldo-terc.sequencia    = saldo-terc.sequencia EXCLUSIVE-LOCK:

               DELETE rat-saldo-terc.
           END.

           delete saldo-terc.
           i-terc = i-terc + 1.
         end.
         else
             next.
    end.
end.

disp c-titulo
     i-doctos      
     i-terc        
     with frame f-totais.

IF tt-param.l-imp-param THEN DO:

    disp  c-sel                               
          c-lb1
          tt-param.i-emitente-ini   
          tt-param.i-emitente-fim   
          tt-param.c-serie-ini      
          tt-param.c-serie-fim      
          tt-param.c-nro-ini        
          tt-param.c-nro-fim        
          tt-param.c-item-ini       
          tt-param.c-item-fim       
          tt-param.c-nat-codigo-ini 
          tt-param.c-nat-codigo-fim 
          tt-param.c-estabel-ini    
          tt-param.c-estabel-fim    
          with frame f-selecao.                 
    
    disp c-par 
         tt-param.l-doctos     
         tt-param.c-per        
         tt-param.l-terc       
         with frame f-parametro.
    
    {utp/ut-liter.i IMPRESS«O_:}
    assign c-imp = return-value.
    display c-imp with frame f-impressao.
    
    {utp/ut-liter.i Destino:}
    assign c-labels-4 = return-value.
    display c-labels-4 tt-param.destino tt-param.arquivo with frame f-impressao.
    
    {utp/ut-liter.i Usu†rio:}
    assign c-labels-5 = return-value.
    display c-labels-5  tt-param.usuario with frame f-impressao.          

END.    

/************************************************/
/*  Procedure que valida o fechamento, ou seja, */
/*  se Ç por estabelecimento ou Ç unico...      */
/*  Retorna a data do ultimo dia fechado.       */
/************************************************/
procedure pi-verifica-ult-fech-dia:

    def input  param c-cod-estabel like saldo-terc.cod-estabel no-undo.
    def output param da-ult-fech-dia like param-estoq.ult-fech-dia no-undo.

    &if defined (bf_mat_fech_estab) &then
        if  avail param-estoq and param-estoq.tp-fech = 2 then do:
            if not avail estab-mat then 
                find estab-mat
                     where estab-mat.cod-estabel = c-cod-estabel no-lock no-error.
            else
               if estab-mat.cod-estabel <> c-cod-estabel then
                    find estab-mat where estab-mat.cod-estabel = c-cod-estabel no-lock no-error.

            assign da-ult-fech-dia = estab-mat.ult-fech-dia.
        end.
        else
            if avail param-estoq and param-estoq.tp-fech = 1 then
               assign da-ult-fech-dia = param-estoq.ult-fech-dia.
    &else
        if  avail param-estoq then
            assign da-ult-fech-dia = param-estoq.ult-fech-dia.
    &endif

end procedure.

{include/i-rpclo.i}
run pi-finalizar in h-acomp.

return "OK".
