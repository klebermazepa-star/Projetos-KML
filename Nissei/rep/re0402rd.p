/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0402RD 2.00.00.008}  /*** 010008 ***/

&IF "{&EMSFND_VERSION}" >= "1.00"
&THEN
{include/i-license-manager.i RE0402RD MRE}
&ENDIF

/*****************************************************************************
**
**       Programa: RE0402D
**
**       Objetivo: Criar o Arquivo de Erros do Documento
**
*****************************************************************************/

def input param de-calculado       as decimal no-undo.
def input param de-informado       as decimal no-undo.
def input param i-mensagem         as integer no-undo.
def input param i-tipo             as integer no-undo.
def input param r-RE0301-documento as rowid   no-undo.

find docum-est where rowid(docum-est) = r-RE0301-documento no-lock no-error.
find first consist-nota
    {cdp/cd8900.i consist-nota docum-est}
    and consist-nota.tipo     = i-tipo
    and consist-nota.mensagem = i-mensagem no-error.
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
           consist-nota.mensagem     = i-mensagem
           consist-nota.tipo         = i-tipo.
end.

/* Fim do Programa */
