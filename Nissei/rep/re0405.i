/****************************************************************************
**
**     Include.: RE0405.i
**
**     Objetivo: Define temp-tables, frames e variaveis
**
****************************************************************************/

{cdp/cdcfgmat.i}/*** Pr‚-processors definitions ***/

define temp-table tt-param
    field destino   as integer
    field arquivo   as char
    field usuario   as char format "x(12)"
    field data-exec as date
    field hora-exec as integer
    field da-data-i as date format "99/99/9999"
    field da-data-f as date format "99/99/9999"
&if defined(bf_mat_selecao_estab_re) &then    
    field c-est-ini as char
    field c-est-fim as char
&endif    
    field c-destino as char format "x(40)"
    field l-imp-param as log.

def temp-table tt-raw-digita
    field raw-digita as raw.

def var da-ult-livro       like contr-livro.dt-ult-emi.
def var da-dt-of           like docum-est.dt-trans no-undo.
def var c-descricao        as character format "x(60)"  init "".
def var c-obs              as character format "x(132)" init "".
def var l-atualiza-of      as logical no-undo.
def var l-existe           as logical no-undo.
def var l-page             as logical no-undo.
def var de-tot-nota        as decimal init 0.
def var d-vl-tot-desc-item as decimal init 0.
def var i-seq-of           as integer no-undo.
def var i-x                as integer no-undo.
def var c-cd-trib-icm      as char                format "x(02)"      no-undo.
def var c-cd-trib-ipi      as char                format "x(02)"      no-undo.


/* Variaveis para Tradu‡Æo */
def var c-lb-ser    as char no-undo.
def var c-lb-docto  as char no-undo.
def var c-lb-natop  as char no-undo.
def var c-lb-emite  as char no-undo.
def var c-lb-nome   as char no-undo.
def var c-lb-esp    as char no-undo.
def var c-lb-emis   as char no-undo.
def var c-lb-entr   as char no-undo.
def var c-lb-est    as char no-undo.
def var c-lb-desc   as char no-undo.
def var c-lb-tot-nf as char no-undo.
def var c-lb-obs    as char no-undo.
def var c-lb-vl-bas as char no-undo.
def var c-lb-aliq   as char no-undo.
def var c-lb-vl-cd  as char no-undo.
def var c-lb-vl-nt  as char no-undo.
def var c-lb-vl-ou  as char no-undo.
def var c-lb-item   as char no-undo.
def var c-lb-tc     as char no-undo.
def var c-lb-natur  as char no-undo.
def var c-lb-peso   as char no-undo.
def var c-lb-qtde   as char no-undo.
def var c-lb-desp   as char no-undo.
def var c-lb-vl-tot as char no-undo.
def var c-lb-icm    as char no-undo.
def var c-lb-vl-icm as char no-undo.
def var c-lb-descr  as char no-undo.
def var c-lb-un     as char no-undo.
def var c-lb-cl-fis as char no-undo.
def var c-lb-ipi    as char no-undo.
def var c-lb-vl-ipi as char no-undo.
def var c-traco     as char no-undo.
def var c-lb-atenc  as char no-undo.
def var c-lb-sel    as char no-undo.
def var c-lb-imp    as char no-undo.
def var c-lb-usuar  as char no-undo.
def var c-lb-dest   as char no-undo.
def var c-lb-data   as char no-undo.

{utp/ut-liter.i S‚rie * r}
assign c-lb-ser = trim(return-value).
{utp/ut-liter.i Nro_Documento * r}
assign c-lb-docto = trim(return-value).
{utp/ut-liter.i Nat_Oper * r}
assign c-lb-natop = trim(return-value).
{utp/ut-liter.i Emitente * r}
assign c-lb-emite = trim(return-value).
{utp/ut-liter.i Nome_Abrev * r}
assign c-lb-nome = trim(return-value).
{utp/ut-liter.i Esp * r}
assign c-lb-esp = trim(return-value).
{utp/ut-liter.i EmissÆo * r}
assign c-lb-emis = trim(return-value).
{utp/ut-liter.i Entrada * r}
assign c-lb-entr = trim(return-value).
{utp/ut-liter.i Est * r}
assign c-lb-est = trim(return-value).
{utp/ut-liter.i Descontos * r}
assign c-lb-desc = trim(return-value).
{utp/ut-liter.i Total_da_Nota * r}
assign c-lb-tot-nf = trim(return-value).
{utp/ut-liter.i Observa‡Æo * r}
assign c-lb-obs = trim(return-value).
{utp/ut-liter.i Valor_Base * r}
assign c-lb-vl-bas = trim(return-value).
{utp/ut-liter.i Aliq * r}
assign c-lb-aliq = trim(return-value).
{utp/ut-liter.i Valor_Cred/Deb * r}
assign c-lb-vl-cd = trim(return-value).
{utp/ut-liter.i Valor_NTrib * r}
assign c-lb-vl-nt = trim(return-value).
{utp/ut-liter.i Valor_Outras * r}
assign c-lb-vl-ou = trim(return-value).
{utp/ut-liter.i Item * r}
assign c-lb-item = trim(return-value).
{utp/ut-liter.i TC * r}
assign c-lb-tc = trim(return-value).
{utp/ut-liter.i Natur * r}
assign c-lb-natur = trim(return-value).
{utp/ut-liter.i Peso * r}
assign c-lb-peso = trim(return-value).
{utp/ut-liter.i Quantidade * r}
assign c-lb-qtde = trim(return-value).
{utp/ut-liter.i Despesas * r}
assign c-lb-desp = trim(return-value).
{utp/ut-liter.i Valor_Total * r}
assign c-lb-vl-tot = trim(return-value).
{utp/ut-liter.i ICM * r}
assign c-lb-icm = trim(return-value) + ":".
{utp/ut-liter.i Valor_ICM * r}
assign c-lb-vl-icm = trim(return-value).
{utp/ut-liter.i Descri‡Æo * r}
assign c-lb-descr = trim(return-value).
{utp/ut-liter.i Un * r}
assign c-lb-un = trim(return-value).
{utp/ut-liter.i Classif_Fiscal * r}
assign c-lb-cl-fis = trim(return-value).
{utp/ut-liter.i IPI * r}
assign c-lb-ipi = trim(return-value) + ":".
{utp/ut-liter.i Valor_IPI * r}
assign c-lb-vl-ipi = trim(return-value).
{utp/ut-liter.i SELE€ÇO * r}
assign c-lb-sel = trim(return-value).
{utp/ut-liter.i IMPRESSÇO * r}
assign c-lb-imp = trim(return-value).
{utp/ut-liter.i Usu rio * r}
assign c-lb-usuar = trim(return-value).
{utp/ut-liter.i Destino * r}
assign c-lb-dest = trim(return-value).
{utp/ut-liter.i Data * r}
assign c-lb-data = trim(return-value)
       c-traco     = fill("-", 132).

form c-lb-ser            format "x(7)"
     c-lb-docto   at 8   format "x(13)"
     c-lb-natop   at 25
     c-lb-emite   at 35  format "x(6)"
     c-lb-nome    at 44  format "x(10)"
     c-lb-esp     at 57  format "x(3)"
     c-lb-emis    at 61
     c-lb-entr    at 72
     c-lb-est     at 83  format "x(5)"
     c-lb-desc    at 94  format "x(9)"
     c-lb-tot-nf  at 109 format "x(13)"
     c-lb-obs     at 123 format "x(10)" skip
     c-lb-vl-bas  at 44  format "x(10)"
     c-lb-aliq    at 57
     c-lb-vl-cd   at 66  format "x(14)"
     c-lb-vl-nt   at 88  format "x(11)"
     c-lb-vl-ou   at 110 format "x(12)" skip
     c-lb-item    at 1
     c-lb-tc      at 18  format "x(2)"
     c-lb-natur   at 21  format "x(5)"
     c-lb-peso    at 40
     c-lb-qtde    at 53  format "x(10)"
     c-lb-desp    at 72
     c-lb-vl-tot  at 88  format "x(11)"
     c-lb-icm     at 100  format "x(3)"
     c-lb-vl-icm  at 113 format "x(9)" skip
     c-lb-descr   at 1   format "x(9)"
     c-lb-un      at 62
     c-lb-cl-fis  at 74  format "x(14)"
     c-lb-ipi     at 100  format "x(3)"
     c-lb-vl-ipi  at 113 format "x(9)" skip
     c-traco             format "x(132)"
     with stream-io no-box no-label width 132 frame f-header.

form doc-fiscal.serie        at 1
     doc-fiscal.nr-doc-fis   at 8
     doc-fiscal.nat-operacao at 25
     doc-fiscal.cod-emitente at 34
     doc-fiscal.nome-ab-emi  at 44
     doc-fiscal.esp-docto    at 57
     doc-fiscal.dt-emis-doc  at 61
     doc-fiscal.dt-docto     at 72
     doc-fiscal.cod-estabel  at 83
     docum-est.tot-desconto  at 87
     docum-est.tot-valor     at 103
     docum-est.cod-obs       at 123 skip
     c-lb-icm                at 27 format "x(4)"
     doc-fiscal.vl-bicms     at 38
     doc-fiscal.aliquota-icm at 55
     doc-fiscal.vl-icms      at 64
     doc-fiscal.vl-icmsnt    at 83
     doc-fiscal.vl-icmsou    at 106 skip
     c-lb-ipi                at 27 format "x(4)"
     doc-fiscal.vl-bipi      at 38
     doc-fiscal.vl-ipi       at 64
     doc-fiscal.vl-ipint     at 83
     doc-fiscal.vl-ipiou     at 106
     with stream-io no-box no-label down width 132 frame f-documento.

form it-doc-fisc.it-codigo    at 1
     it-doc-fisc.tipo-contr   at 18
     it-doc-fisc.tipo-nat     at 21
     it-doc-fisc.peso-liq     at 27
     it-doc-fisc.quantidade   at 45 
     it-doc-fisc.vl-despes-it at 64
     it-doc-fisc.vl-tot-item  at 83
     it-doc-fisc.cd-trib-icm  at 100
     it-doc-fisc.vl-icms-it   at 106 skip
     c-descricao              at 1
     it-doc-fisc.un           at 62 
     it-doc-fisc.class-fiscal at 70 
     it-doc-fisc.cd-trib-ipi  at 100
     it-doc-fisc.vl-ipi-it    at 106
     with stream-io no-box no-label down width 132 frame f-item-nota.

form c-obs at 1
     with stream-io no-box no-label down width 132 frame f-obs.

form "-----------------------------------"    at 78 skip
     de-tot-nota  format ">>>,>>>,>>>,>>9.99" at 78
     with stream-io side-label down width 132 frame f-tot-nota.

/* Inicio -- Projeto Internacional -- ut-trfrrp.p adicionado */
RUN utp/ut-trfrrp.p (INPUT FRAME f-tot-nota:HANDLE).


{utp/ut-liter.i Valor_Total_Nota * r}
assign de-tot-nota:label in frame f-tot-nota = trim(return-value).

/* fim include */
