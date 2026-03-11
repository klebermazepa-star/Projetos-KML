/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0402C 2.00.00.001}  /*** 010001 ***/

&IF "{&EMSFND_VERSION}" >= "1.00"
&THEN
{include/i-license-manager.i RE0402C MRE}
&ENDIF


/*****************************************************************************
**
**       Programa: RE0402C
**
**       Objetivo: Desatualizacao de Notas Fiscais - Recebimento F�sico
**
*****************************************************************************/

def input param rw-docum-est  as rowid no-undo.


find docum-est 
    where rowid(docum-est) = rw-docum-est no-lock no-error.
    

find doc-fisico
    where doc-fisico.cod-emitente = docum-est.cod-emitente
    and   doc-fisico.serie-docto  = docum-est.serie-docto
    and   doc-fisico.nro-docto    = docum-est.nro-docto 
    and   doc-fisico.tipo-nota    = docum-est.tipo-nota exclusive-lock no-error.
    
if  avail doc-fisico then     
    assign doc-fisico.situacao = 3.


    alterado para o projeto 2
    

