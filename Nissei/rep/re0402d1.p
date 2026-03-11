/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0402D1 2.00.00.003}  /*** 010003 ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0402d1 MRE}
&ENDIF

/***************************************************************************
**
**   RE0402D1.P - Desatualizacao de Previsoes - Recebimento Internacional
**
***************************************************************************/

{utp/ut-glob.i}

/*
/******************** Multi-Planta **********************/
def var i-tipo-movto as integer no-undo.
def var l-cria       as logical no-undo.

{cdp/cd7300.i1}
/************************* Fim **************************/
*/

{app/apapi020.i}         /* Definicao temp-table tt-param */

/* Conforme {app/apapi018.i} existente no re0402d.p */
def temp-table tt-tit-ap 
    field ep-codigo     like tit-ap.ep-codigo
    field cod-fornec    like tit-ap.cod-fornec
    field cod-estabel   like tit-ap.cod-estabel
    field cod-esp       like tit-ap.cod-esp
    field serie         like tit-ap.serie
    field nr-docto      like tit-ap.nr-docto
    field parcela       like tit-ap.parcela
    field vl-original   like tit-ap.vl-original
    field valor-saldo   like tit-ap.valor-saldo
    field cod-maq-origem as  int format "9999"
    field num-processo   as  int format ">>>>>>>>9" initial 0
    field num-sequencia  as  int format ">>>>>9"    initial 0
    field ind-tipo-movto as  int format "99"        initial 1     
    INDEX codigo IS PRIMARY ep-codigo
                            cod-fornec
                            cod-estabel
                            cod-esp
                            serie
                            nr-docto
                            parcela.

def input  param r-dupli-apagar     as rowid    no-undo.
def output param table              for tt-tit-ap.
def output param table              for tt-retorno-erro.


def var raw-param                   as raw      no-undo.

find first param-global no-lock no-error.

find dupli-apagar
    where rowid(dupli-apagar) = r-dupli-apagar no-lock no-error.

run pi-cria-tt-param.

raw-transfer tt-param to raw-param.

run app/apapi020.p ( input  raw-param,
                     output table tt-titulo,
                     output table tt-retorno-erro ).
                     
/* O programa re0402d.p recebe como retorno a tabela tt-tit-ap ao inv‚s de tt-titulo */                     
for each tt-titulo no-lock:
    create tt-tit-ap.
    assign tt-tit-ap.ep-codigo   = tt-titulo.ep-codigo
           tt-tit-ap.cod-fornec  = tt-titulo.cod-fornec
           tt-tit-ap.cod-estabel = tt-titulo.cod-estabel
           tt-tit-ap.cod-esp     = tt-titulo.cod-esp
           tt-tit-ap.serie       = tt-titulo.serie
           tt-tit-ap.nr-docto    = tt-titulo.nr-docto
           tt-tit-ap.parcela     = tt-titulo.parcela
           tt-tit-ap.vl-original = tt-titulo.vl-original
           tt-tit-ap.valor       = tt-titulo.valor-saldo.
           
end.

return "OK".


/* ----------------------------- Procedure Interna ----------------------------*/

procedure pi-cria-tt-param:

    def var i-empresa like param-global.empresa-prin no-undo.
    {cdp/cdcfgdis.i}

    assign i-empresa = param-global.empresa-prin.
      
    &if defined (bf_dis_consiste_conta) &then
      
        find estabelec where
             estabelec.cod-estabel = dupli-apagar.cod-estabel no-lock no-error.
      
        run cdp/cd9970.p (input rowid(estabelec),
                          output i-empresa).
    &endif

    create tt-param.
    assign tt-param.cod-versao-integracao = 1
           tt-param.i-ep-codigo           = i-empresa
           tt-param.estabel               = dupli-apagar.cod-estabel
           tt-param.espec                 = dupli-apagar.cod-esp
           tt-param.serie-ini             = dupli-apagar.serie
           tt-param.docto-ini             = dupli-apagar.nr-duplic
           tt-param.parc-ini              = string(dupli-apagar.parcela)
           tt-param.forn-ini              = dupli-apagar.cod-emitente
           tt-param.emis-ini              = dupli-apagar.dt-emissao
           tt-param.verifica-movto        = yes
           tt-param.serie-fim             = ?
           tt-param.docto-fim             = ? 
           tt-param.parc-fim              = ?
           tt-param.emis-fim              = ? 
           tt-param.forn-fim              = ?
           tt-param.ref-fim               = ?.
end.

