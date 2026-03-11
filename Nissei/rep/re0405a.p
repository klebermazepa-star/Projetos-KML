/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0405A 2.00.00.002}  /*** 010002 ***/

&IF "{&EMSFND_VERSION}" >= "1.00"
&THEN
{include/i-license-manager.i RE0405A MRE}
&ENDIF

/****************************************************************************
**
**       Programa: RE0405A.P
**
**       Data....: Junho de 1997
**
**       Objetivo: Criar o Arquivo de Erros do Documento
**
**       Vers∆o..: 1.00.000 - Sandra Stadelhofer
**
****************************************************************************/

def input param de-calculado       as decimal no-undo.
def input param de-informado       as decimal no-undo.
def input param i-tipo             as integer no-undo.
def input param r-RE0301-documento as rowid   no-undo.

find docum-est
    where rowid(docum-est) = r-RE0301-documento no-lock no-error.
find first consist-nota
    {cdp/cd8900.i consist-nota docum-est}
    and consist-nota.tipo     = i-tipo
    and consist-nota.mensagem = 5523 exclusive-lock no-error. /*juliano*/
if  avail consist-nota then
    assign consist-nota.calculado = de-calculado
           consist-nota.informado = de-informado.
else do:
    create consist-nota.
    assign consist-nota.serie-docto  = docum-est.serie-docto
           consist-nota.nro-docto    = docum-est.nro-docto
           consist-nota.nat-operacao = docum-est.nat-operacao
           consist-nota.cod-emit     = docum-est.cod-emit
           consist-nota.calculado    = de-calculado
           consist-nota.informado    = de-informado
           consist-nota.mensagem     = 5523
           consist-nota.tipo         = i-tipo.
end.

/* Fim do Programa */
