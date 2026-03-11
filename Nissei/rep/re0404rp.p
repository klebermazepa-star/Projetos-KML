/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0404RP 2.00.00.037 } /*** 010037 ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0404rp MRE}
&ENDIF

/****************************************************************************
**
**       PROGRAMA: RE0404RP.P
**
**       DATA....: JUNHO DE 1997
**
**       OBJRTIVO: INTEGRA€ÇO COM CONTAS A PAGAR
**
**       VERSÇO..: 1.00.000 - Sandra Stadelhofer
**
****************************************************************************/

def new shared frame f-total.
def new shared frame f-referencia.
def new shared frame f-linha.
def new shared frame f-lis-tot.

def var l-ja-conectado  as logical      no-undo.

{btb/btb009za.i}

DEF VAR h-btb009za AS HANDLE.

RUN btb/btb009za.p PERSISTENT SET h-btb009za.


{rep/re0404.i1} /* Define temp-tables, frames, variaveis e preprocessadores comuns */
{rep/re1005.i01}
{cdp/cd0666.i}
{cdp/cd0031.i "MRE"} /*Seguranca por Estabelecimento*/

def input param raw-param as raw no-undo.
def input param table for tt-raw-digita.

def new global shared var c-RE0301-origem as char no-undo.

/* Empresa do Usuario */
DEFINE NEW GLOBAL SHARED VARIABLE i-ep-codigo-usuario AS CHARACTER NO-UNDO.

def new shared stream arq-export.
def new shared var i-param as integer no-undo.
def var l-ems50         as logical                    no-undo.
def var l-conec-bas     as logical                    no-undo.
def var l-conec-fin     as logical                    no-undo.
def var l-conec-uni     as logical                    no-undo.
def var l-erro          as logical                    no-undo.

run utp/ut-acomp.p persistent set h-acomp.

create tt-param.
raw-transfer raw-param to tt-param.

for each tt-raw-digita:
    create tt-digita.
    raw-transfer tt-raw-digita.raw-digita to tt-digita.
end.


{include/i-rpvar.i} 
{include/i-rpcab.i}
find first tt-param no-error.

find first param-cp     no-lock no-error.
find first param-global no-lock no-error.
find first param-estoq  no-lock no-error.

find empresa where empresa.ep-codigo = i-ep-codigo-usuario no-lock no-error.

assign c-empresa  = empresa.razao-social when available empresa
       c-programa = "RE/0404"
       c-versao   = "1.00"
       c-revisao  = "000"
       c-RE0301-origem = "RE0404".       

{include/i-rpout.i}

view frame f-cabec.
view frame f-rodape.


if line-counter <= 5 then do:
   put c-cabec1 at 0 skip.
   put c-cabec2 at 0 skip.
end.

{utp/ut-liter.i Integra‡Æo_com_Contas_a_Pagar}
assign c-titulo-relat = trim(return-value).
{utp/ut-liter.i ESTOQUE}
assign c-sistema = trim(return-value).
{utp/ut-liter.i Estabelecimento * r }
assign c-lb-estab = trim(return-value).

{app/apapi001b.i}

{utp/ut-liter.i Integra‡Æo_com_Contas_a_Pagar * r }
run pi-inicializar in h-acomp (input trim(return-value)).


assign  l-ems50         =     can-find(funcao where funcao.cd-funcao = "adm-apb-ems-5.00"
                                                    and funcao.ativo = yes
                                                    and funcao.log-1 = yes).

if  l-ems50 then do:
    run pi-conecta-ems50 ( 1 ). /* 1 = conecta */
    if l-erro then do:
       {include/i-rpclo.i}
       run pi-finalizar in h-acomp.
       undo, return "NOK".
    end.    
end.    

if  tt-param.i-opcao = 1 then do:
    {utp/ut-liter.i Em_processamento,_aguarde * r}
    assign c-lb-msg = trim(return-value) + "...".
    run pi-acompanhar in h-acomp (input c-lb-msg).

    view frame f-cabec.
    view frame f-rodape.
   
    run rep/re0404a.p (raw-param, table tt-raw-digita).
   
end.

/************* ESTA OPCAO NAO ESTA DISPONIVEL NO EMS*********************
 * AS OPCOES REEXPORTA E ELIMINA NAO PODERAO  SER IMPLEMENTADAS NO EMS  *
 * POIS O EMS NAO GERA AS TABELAS DOC-I-AP  E  LIN -I-AP NA EXPORTACAO  *
 * DOS DOCUMENTOS. DESTA FORMA, NESTA VERSAO, FOI RETIRADO DO RE0404.W  *
 * O  RADIO-SET  QUE  SELECIONA  REEXPORTA  E  ELIMINA. O PROGRAMA FOI  *
 * ALTERADO PARA SEMPRE UTILIZAR A OPCAO GERACAO.                       *
 ************************************************************************
 * if  tt-param.i-opcao = 2 then do:
 *     find first tt-digita where tt-digita.flag no-error.
 *     if  avail tt-digita then do:
 *         {utp/ut-liter.i ReExportando * r}
 *         assign c-lb-msg = trim(return-value) + "...".
 *         run pi-acompanhar in h-acomp (input c-lb-msg).
 *     end.
 * 
 *     view frame f-cabec.
 *     view frame f-rodape.
 *     assign i-param = 0.
 *     for each tt-digita transaction:
 *          if  tt-digita.flag then do:
 *                 run pi-acompanhar in h-acomp (input tt-digita.referencia).
 *                     output stream arq-export to value(tt-digita.arquivo) append.
 *             for each tt-lin-i-ap
 *                 where tt-lin-i-ap.ep-codigo  = tt-digita.ep-codigo
 *                 and   tt-lin-i-ap.referencia = tt-digita.referencia no-lock
 *                 break by tt-lin-i-ap.cod-esp:
 *                 assign i-param = 1.
 *                 {rep/re0404.i2} 
 *                 assign de-total-movto = de-total-movto + tt-lin-i-ap.vl-original.
 *                 find emitente
 *                     where emitente.cod-emitente = tt-lin-i-ap.cod-fornec
 *                     no-lock no-error.
 *                 disp tt-lin-i-ap.ep-codigo    when first-of(tt-lin-i-ap.cod-esp)   @ lin-i-ap.ep-codigo   
 *                      tt-lin-i-ap.cod-estabel  when first-of(tt-lin-i-ap.cod-esp)   @ lin-i-ap.cod-estabel 
 *                      tt-lin-i-ap.cod-esp      when first-of(tt-lin-i-ap.cod-esp)   @ lin-i-ap.cod-esp   
 *                      tt-lin-i-ap.cod-fornec   @ lin-i-ap.cod-fornec  
 *                      emitente.nome-abrev            
 *                      tt-lin-i-ap.nr-docto     @ lin-i-ap.nr-docto
 *                      tt-lin-i-ap.serie        @ lin-i-ap.serie
 *                      tt-lin-i-ap.parcela      @ lin-i-ap.parcela  
 *                      tt-lin-i-ap.dt-emissao   @ lin-i-ap.dt-emissao  
 *                      tt-lin-i-ap.dt-transacao @ lin-i-ap.dt-transacao  
 *                      tt-lin-i-ap.dt-vencimen  @ lin-i-ap.dt-vencimen
 *                      tt-lin-i-ap.vl-original  @ lin-i-ap.vl-original
 *                      with frame f-corpo2 stream-io.
 *                 down with frame f-corpo2.
 * 
 *                 for each tt-lin-conta-ap
 *                     where tt-lin-conta-ap.ep-codigo   = tt-lin-i-ap.ep-codigo
 *                     and   tt-lin-conta-ap.cod-estabel = tt-lin-i-ap.cod-estabel
 *                     and   tt-lin-conta-ap.cod-esp     = tt-lin-i-ap.cod-esp
 *                     and   tt-lin-conta-ap.serie       = tt-lin-i-ap.serie
 *                     and   tt-lin-conta-ap.nr-docto    = tt-lin-i-ap.nr-docto
 *                     and   tt-lin-conta-ap.parcela     = tt-lin-i-ap.parcela
 *                     and   tt-lin-conta-ap.cod-fornec  = tt-lin-i-ap.cod-fornec:
 *                    {rep/re0404.i4}
 *                 end.
 *                 
 *                 for each tt-impto-tit-pend-ap 
 *                     where tt-impto-tit-pend-ap.ep-codigo  = tt-lin-i-ap.ep-codigo
 *                     and   tt-impto-tit-pend-ap.cod-est    = tt-lin-i-ap.cod-est
 *                     and   tt-impto-tit-pend-ap.cod-esp    = tt-lin-i-ap.cod-esp                       
 *                     and   tt-impto-tit-pend-ap.serie      = tt-lin-i-ap.serie
 *                     and   tt-impto-tit-pend-ap.cod-fornec = tt-lin-i-ap.cod-fornec
 *                     and   tt-impto-tit-pend-ap.nr-docto   = tt-lin-i-ap.nr-docto
 *                     and   tt-impto-tit-pend-ap.parcela    = tt-lin-i-ap.parcela:
 *                     {rep/re0404.i3}
 *                  end.
 *             end.
 *             {utp/ut-liter.i Total * r}
 *             assign c-lb-total = "     " + trim(return-value).
 *             disp c-lb-total     format "x(10)"
 *                                 @ lin-i-ap.dt-vencimen
 *                  de-total-movto @ lin-i-ap.vl-original with frame f-corpo2 stream-io.
 *             down with frame f-corpo2.
 *             assign de-total-movto = 0.
 *             find first tt-doc-i-ap
 *                 where tt-doc-i-ap.ep-codigo  = tt-digita.ep-codigo
 *                 and   tt-doc-i-ap.cod-esp    = tt-digita.cod-esp
 *                 and   tt-doc-i-ap.referencia = tt-digita.referencia no-error.    
 *                {rep/re0404.i5}
 *              output stream arq-export close.
 *         end.
 *     end.
 * end.
 * 
 * if  tt-param.i-opcao = 3 then do:
 *     {utp/ut-liter.i Eliminando * r}
 *     assign c-lb-msg = trim(return-value) + "...".
 *     run pi-acompanhar in h-acomp (input c-lb-msg).
 * 
 *     for each tt-digita transaction:
 *         if  tt-digita.flag then do:
 *             run pi-acompanhar in h-acomp (input tt-digita.referencia).
 *             find doc-i-ap
 *                 where doc-i-ap.ep-codigo  = tt-digita.ep-codigo
 *                 and   doc-i-ap.referencia = tt-digita.referencia.
 *             for each tt-lin-i-ap
 *                 where tt-lin-i-ap.ep-codigo = doc-i-ap.ep-codigo
 *                 and   tt-lin-i-ap.referencia = doc-i-ap.referencia:
 *                 for each tt-lin-conta-ap
 *                     where tt-lin-conta-ap.ep-codigo   = tt-lin-i-ap.ep-codigo
 *                     and   tt-lin-conta-ap.cod-estabel = tt-lin-i-ap.cod-estabel
 *                     and   tt-lin-conta-ap.cod-esp     = tt-lin-i-ap.cod-esp
 *                     and   tt-lin-conta-ap.serie       = tt-lin-i-ap.serie
 *                     and   tt-lin-conta-ap.nr-docto    = tt-lin-i-ap.nr-docto
 *                     and   tt-lin-conta-ap.parcela     = tt-lin-i-ap.parcela
 *                     and   tt-lin-conta-ap.cod-fornec  = tt-lin-i-ap.cod-fornec:
 *                     delete tt-lin-conta-ap.
 *                 end.
 *                 delete tt-lin-i-ap.
 *             end.
 *             delete doc-i-ap.
 *         end.
 *     end.
 * end.
 * **************************************************************************/

if l-ems50 then
    run pi-conecta-ems50 ( 2 ). /* 2 = disconecta */

if valid-handle (h-btb009za) then
   DELETE PROCEDURE h-btb009za.

if tt-param.l-imp-param then do:

    page.
    put c-lb-sel            skip
        c-lb-ini            at 25 c-lb-fim at 45
        "-------"           at 25 "-----"  at 45      skip
        c-lb-trans          at 5  format "x(14)" ": "
        tt-param.da-data-i  at 25 format "99/99/9999"
        tt-param.da-data-f  at 45 format "99/99/9999" 
    &if defined(bf_mat_selecao_estab_re) &then
        skip
        c-lb-estab          at 5  format "x(15)" ": "     
        tt-param.c-est-ini  at 25 format "x(5)"
        tt-param.c-est-fim  at 45 format "x(5)"
    &endif
        skip(1)
        c-lb-imp                  format "x(9)"       skip(1)
        c-lb-des            at 5  ": " trim(tt-param.c-destino)  " - "
        tt-param.arquivo          format "x(30)"
        c-lb-usu            at 5 ": "  tt-param.usuario skip(1).
    
    if  avail tt-digita then
        put c-lb-dig format "x(9)" skip(1).
    
    if  tt-param.i-opcao = 1 then
        for each tt-digita:
            disp tt-digita.estab-i
                 tt-digita.estab-f
                 tt-digita.ep-codigo
                 tt-digita.arquivo
                 with stream-io no-box width 132 down frame f-digita1.
            down with frame f-digita1.
        end.
    /*
     * if  tt-param.i-opcao = 2 then
     *     for each tt-digita:
     *         disp tt-digita.flag no-label
     *              tt-digita.data
     *              tt-digita.hora
     *              tt-digita.ep-codigo
     *              tt-digita.cod-esp
     *              tt-digita.arquivo
     *              tt-digita.referencia
     *              with stream-io no-box width 132 down frame f-digita2.
     *         down with frame f-digita2.
     *     end.
     * if  tt-param.i-opcao = 3 then
     *     for each tt-digita:
     *         disp tt-digita.flag no-label
     *              tt-digita.data
     *              tt-digita.hora
     *              tt-digita.ep-codigo
     *              tt-digita.cod-esp
     *              with stream-io no-box width 132 down frame f-digita3.
     *         down with frame f-digita3.
     *     end.
     * */
end.     


for each tt-digita:
    delete tt-digita.
end.


{include/i-rpclo.i}
run pi-finalizar in h-acomp.

if  valid-handle(h-acomp) then do:
    delete procedure h-acomp.
end.
    
RETURN "OK":U.


/*{include/i-rpclo.i}
 * 
 * run pi-finalizar in h-acomp.
 * 
 * RETURN "OK".*/

{rep/re1005.i14} /*Integracao EMS50*/





