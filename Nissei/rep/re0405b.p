/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0405B 2.00.00.004}  /*** 010004 ***/

&IF "{&EMSFND_VERSION}" >= "1.00"
&THEN
{include/i-license-manager.i RE0405B MRE}
&ENDIF

/****************************************************************************
**
**       Programa: RE0405B.P
**
**       Data....: Junho de 1997
**
**       Objetivo: Impressao dos Itens
**
**       VersÆo..: 1.00.000 - Sandra Stadelhofer
**
****************************************************************************/

def input param r-reg as rowid.

/*/*def var c-descricao like item.desc-item. /*char format "x(36)" init "".*/*/
 * def var i-x         as integer no-undo.*/
{rep/re0405.i}
   
form it-doc-fisc.it-codigo    at 1
     it-doc-fisc.tipo-contr
     it-doc-fisc.tipo-nat
     it-doc-fisc.peso-liq
     it-doc-fisc.quantidade
     it-doc-fisc.vl-despes-it
     it-doc-fisc.vl-tot-item
     it-doc-fisc.cd-trib-icm  space(3)
     it-doc-fisc.vl-icms-it   skip
     c-descricao
     it-doc-fisc.un
     it-doc-fisc.class-fiscal at 78
     it-doc-fisc.cd-trib-ipi  space(3)
     it-doc-fisc.vl-ipi-it
     with stream-io no-box no-label down width 132 frame f-item-nota.

 
find doc-fiscal where rowid(doc-fiscal) = r-reg no-lock no-error.  
for each it-doc-fisc of doc-fiscal no-lock:

if  it-doc-fisc.cd-trib-icm >= 1
and it-doc-fisc.cd-trib-icm <= 4 then
    assign c-cd-trib-icm = substr({ininc/i01in245.i 04 it-doc-fisc.cd-trib-icm},1,1).                     
                                                    
if  it-doc-fisc.cd-trib-ipi >= 1 
and it-doc-fisc.cd-trib-ipi <= 4 then
    assign c-cd-trib-ipi = substr({ininc/i07in122.i 04 it-doc-fisc.cd-trib-ipi},1,1).        

    find item
        where item.it-codigo = it-doc-fisc.it-codigo no-lock no-error.
    if  avail item then
        assign c-descricao = item.desc-item.   /*item.descricao-1 +  item.descricao-2.*/
    disp it-doc-fisc.it-codigo
         it-doc-fisc.tipo-contr
         it-doc-fisc.tipo-nat
         it-doc-fisc.peso-liq
         it-doc-fisc.quantidade
         it-doc-fisc.vl-despes-it
         it-doc-fisc.vl-tot-item
         c-cd-trib-icm @ it-doc-fisc.cd-trib-icm
         it-doc-fisc.vl-icms-it
         c-descricao
         it-doc-fisc.un
         it-doc-fisc.class-fiscal
         c-cd-trib-ipi @ it-doc-fisc.cd-trib-ipi
         it-doc-fisc.vl-ipi-it
         with frame f-item-nota.
    down with frame f-item-nota.

    do  i-x = 1 to 15:
        if  can-do("1,2,3,4,5,6,7,8,9",
                  (substr(it-doc-fisc.ct-codigo,i-x,1))) then
            leave.
    end.

    if  i-x = 16 then do:
        run utp/ut-msgs.p (input "msg", input 5512, "").
        put trim(return-value) format "x(80)" skip(1).
        down with frame f-item-nota.
    end.
end.

