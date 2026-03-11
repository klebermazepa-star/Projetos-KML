/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0405RP 2.00.00.052 } /*** 010052 ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0405rp MRE}
&ENDIF

{include/i_fnctrad.i}
/****************************************************************************
**
**     Programa: RE0405RP.P
**
**     Data....: Junho de 1997
**
**     Objetivo: Integracao com Obrigaá‰es Fiscais
**
**     Versao..: 1.00.000 - Sandra Stadelhofer
**
****************************************************************************/

{cdp/cdcfgmat.i}
{utp/ut-glob.i}    
/* Define temp-tables, frames e variaveis */
{rep/re0405.i}
{rep/re1005.i05}                    /* Definicao TT-RATEIO              */
{cdp/cd9120.i1}                     /* Definicao tt-docto e tt-item     */

/* Seguranáa por estabelecimento - Def. temp-table tt_estab_ems2 e verif. se seguranáa ativa no m¢dulo) */
{cdp/cd0031.i "MRE"}	

/* Empresa do Usuario */
DEFINE NEW GLOBAL SHARED VARIABLE i-ep-codigo-usuario AS CHARACTER NO-UNDO.

def input param raw-param as raw no-undo.
def input param table for tt-raw-digita.

def var c-RE0301-usuario   like param-re.usuario no-undo. 
def var r-RE0301-documento as rowid   no-undo.
def var c-RE0301-origem    as char    no-undo.
def var i-tipo             as integer no-undo.
def var h-acomp            as handle  no-undo.
def var c-lb-estab         as char    no-undo.
def var l-ja-existe-of     as logical no-undo.

def var l-spp-nfe             as log     no-undo.
DEF VAR l-valida-chave        AS LOG     NO-UNDO.
DEF VAR l-valida-chave-emit     AS LOG   NO-UNDO.
DEF VAR i-meio-validacao        AS INT   NO-UNDO.

def temp-table tt_log_erro  no-undo
    field ttv_num_cod_erro  as integer   initial ?
    field ttv_des_msg_ajuda as character initial ?
    field ttv_des_msg_erro  as character initial ?.

def new global shared var c-dir-spool-servid-exec as char no-undo.

def buffer b-emite for emitente.

DEF BUFFER b-item-doc FOR item-doc-est.


def temp-table tt-erro no-undo
    field cd-erro      as int
    field mensagem     as char format "x(255)"
    FIELD serie        LIKE docum-est.serie-docto
    FIELD nro-docto    LIKE docum-est.nro-docto
    FIELD nat-operacao LIKE docum-est.nat-operacao
    FIELD cod-emitente LIKE docum-est.cod-emitente.

{include/i-rpvar.i}

assign c-programa = "RE/0405"
       c-versao   = "1.00"
       c-revisao  = "000".

{utp/ut-liter.i Integraá∆o_com_Obrigaá‰es_Fiscais * r}
assign c-titulo-relat = trim(return-value).
{utp/ut-liter.i Recebimento * r}
assign c-sistema = trim(return-value).

&if defined(bf_mat_selecao_estab_re) &then 
    {utp/ut-liter.i Estabelecimento * r }
    assign c-lb-estab = trim(return-value).
&endif

run utp/ut-acomp.p persistent set h-acomp.

{utp/ut-liter.i Integraá∆o_com_Obrigaá‰es_Fiscais * r }
run pi-inicializar in h-acomp (input trim(return-value)).

create tt-param.
raw-transfer raw-param to tt-param.

find first param-global no-lock no-error.

FIND  empresa NO-LOCK WHERE empresa.ep-codigo = i-ep-codigo-usuario NO-ERROR.
IF AVAIL empresa THEN 
    ASSIGN c-empresa  = empresa.razao-social. 

assign c-re0301-origem = "RE0405"
       l-atualiza-of   = yes.

{include/i-rpcab.i}

{include/i-rpout.i}

FOR EACH tt-erro.
    DELETE tt-erro.
END.

/* Nota Fiscal Eletronica */
assign l-spp-nfe = can-find(first funcao where 
                                  funcao.cd-funcao = "SPP-NFE":U and funcao.ativo = yes).

do  on endkey undo,leave:

    assign l-page = yes.
    view frame f-cabec.
    view frame f-rodape.

    for each docum-est NO-LOCK use-index dt-tp-estab
        where docum-est.dt-trans >= tt-param.da-data-i
        and   docum-est.dt-trans <= tt-param.da-data-f
    &if defined(bf_mat_selecao_estab_re) &then        
        and   docum-est.cod-estabel >= tt-param.c-est-ini
        and   docum-est.cod-estabel <= tt-param.c-est-fim
    &endif
        and   docum-est.ce-atual
        AND   docum-est.origem <> "T":U
        and   not docum-est.of-atual
        and   not(docum-est.tipo-docto = 2
        and   param-global.modulo-ft = yes) :		
		
		{cdp/cd0031a.i docum-est.cod-estabel} /* Seguranáa por estabelecimento */

        run pi-acompanhar in h-acomp (input docum-est.nro-docto).
        /* Erro 6046 = Data do documento impede atualizacao em Obrigacoes Fiscais */

        /* Garantindo conte£do na natureza de obrigaá‰es fiscais (item-doc-est.nat-of) */
        FOR EACH item-doc-est {cdp/cd8900.i item-doc-est docum-est}
            AND (item-doc-est.nat-of = "" OR item-doc-est.nat-of = ?) NO-LOCK :

            DO WHILE TRUE :
                FIND FIRST b-item-doc OF item-doc-est EXCLUSIVE-LOCK NO-WAIT NO-ERROR.

                IF NOT LOCKED(b-item-doc) THEN DO:
                    ASSIGN b-item-doc.nat-of = item-doc-est.nat-operacao.
                    RELEASE b-item-doc.
                    LEAVE.
                END.
                    
                PAUSE 1.
            END.


        END.

        /* Verifica se existem documentos OF com a natureza fiscal */
        ASSIGN l-ja-existe-of = NO. /* Se usa m£ltiplas naturezas ir† verificar todas as naturezas dos itens sen∆o somente a natureza da nota */
        FOR EACH item-doc-est NO-LOCK {cdp/cd8900.i item-doc-est docum-est} BREAK BY item-doc-est.nat-of:
            IF  NOT FIRST-OF(item-doc-est.nat-of) THEN
                NEXT. /* S¢ faz a busca se mudar a natureza do item (um docum-est para v†rios doc-fiscal) */
            
            FIND doc-fiscal
             WHERE doc-fiscal.cod-estabel  = docum-est.estab-fisc
               AND doc-fiscal.serie        = docum-est.serie-docto
               AND doc-fiscal.nr-doc-fis   = docum-est.nro-docto
               AND doc-fiscal.cod-emitente = docum-est.cod-emitente
               AND doc-fiscal.nat-operacao = item-doc-est.nat-of NO-LOCK NO-ERROR.
            
            IF  AVAIL doc-fiscal THEN DO:
                /* Erro 6497 Documento ja Cadastrado em O.F. */
                RUN pi-erro-nota (item-doc-est.serie-docto, item-doc-est.nro-docto, item-doc-est.cod-emitente, item-doc-est.nat-of, 6497, "").
                ASSIGN l-ja-existe-of = YES.
            END.
        END.
        IF  l-ja-existe-of THEN
            NEXT.

        FIND FIRST natur-oper
             WHERE natur-oper.nat-operacao = docum-est.nat-operacao NO-LOCK NO-ERROR.
        IF NOT AVAIL natur-oper THEN NEXT.   

        FIND FIRST emitente
             WHERE emitente.cod-emitente = docum-est.cod-emitente NO-LOCK NO-ERROR.
        IF NOT AVAIL emitente THEN NEXT.   
        
        FIND FIRST estabelec WHERE estabelec.cod-estabel = docum-est.cod-estabel NO-LOCK NO-ERROR.
        /* valida chave NF-e -> SEFAZ */
        IF NOT docum-est.log-1 
           AND l-spp-nfe 
           AND docum-est.cdn-sit-nfe = 1 THEN DO:
            
            if can-find(first param-re where
                              param-re.usuario = c-seg-usuario and
                              param-re.log-atualiza-nfe-of) then
			      
               RUN pi-atualiza-sit-doc (BUFFER docum-est, 2). /* autenticada usuario */

            /* Verifica se deve validar a chave de acesso e o meio de validaá∆o */
            RUN rep/reapi331a.p (INPUT ROWID(docum-est),
                                 OUTPUT l-valida-chave,
                                 OUTPUT l-valida-chave-emit,
                                 OUTPUT i-meio-validacao). /* 0-Nenhum; 1-EAI; 2-TSS; 3-Colaboraá∆o Ass°ncrono */

            IF RETURN-VALUE = "NOK" THEN 
                ASSIGN l-valida-chave = NO.

            IF l-valida-chave THEN DO:
                IF i-meio-validacao = 3 THEN DO: /* TOTVS COLABORAÄ«O 2.0 - Ass°ncrono - Envio da mensagem consSitNFe ou consSitCTe */
                    RUN rep/reapi331.p (INPUT TRIM(docum-est.cod-chave-aces-nf-eletro),
                                        INPUT docum-est.cod-estabel,
                                        INPUT i-meio-validacao,                /* 0-Nenhum; 1-EAI; 2-TSS; 3-Colaboraá∆o Ass°ncrono */
                                        INPUT 1,                               /* Etapa s¢ Ç utilizado quando o i-meio-validacao = 3 (Ass°ncrono) */
                                        INPUT TRIM(estabelec.des-vers-layout), /* S¢ Ç usado na integraá∆o via EAI - Neogrid */
                                        OUTPUT TABLE tt_log_erro).

                    IF RETURN-VALUE = "NOK":U THEN DO:
                        FOR EACH tt_log_erro NO-LOCK:
                            /* N∆o gerou arquivo de consulta, ent∆o n∆o ir† validar a chave de acesso */
                            run pi-erro-nota (docum-est.serie-docto, docum-est.nro-docto, docum-est.cod-emitente, docum-est.nat-operacao, tt_log_erro.ttv_num_cod_erro, tt_log_erro.ttv_des_msg_erro).
                            FIND CURRENT tt-erro EXCLUSIVE-LOCK NO-ERROR.
                            ASSIGN tt-erro.mensagem = tt_log_erro.ttv_des_msg_erro.
                            ASSIGN i-meio-validacao = 0. /* N∆o deve validar pois ocorreu erro na geraá∆o do arquivo XML de consulta */
                        END.
                    END.
                END.

                RUN rep/reapi331.p (INPUT TRIM(docum-est.cod-chave-aces-nf-eletro),
                                    INPUT docum-est.cod-estabel,
                                    INPUT i-meio-validacao,                /* 0-Nenhum; 1-EAI; 2-TSS; 3-Colaboraá∆o Ass°ncrono */
                                    INPUT 2,                               /* Etapa s¢ Ç utilizado quando o i-meio-validacao = 3 (Ass°ncrono) */
                                    INPUT TRIM(estabelec.des-vers-layout), /* S¢ Ç usado na integraá∆o via EAI - Neogrid */
                                    OUTPUT TABLE tt_log_erro).

                if return-value = "OK":U AND i-meio-validacao <> 0 then do:
                   IF CAN-FIND(FIRST tt_log_erro WHERE
                                     tt_log_erro.ttv_num_cod_erro = 52844) THEN DO: /* Autorizada */
				     
                      RUN pi-atualiza-sit-doc (BUFFER docum-est, 3). /* autenticada sistema */
                      run pi_elimina_consist_nota_validacao_nfe.
                   END.					   
                   else do:
                        FOR EACH tt_log_erro NO-LOCK:
                            run pi-erro-nota (  docum-est.serie-docto, docum-est.nro-docto, docum-est.cod-emitente, docum-est.nat-operacao, tt_log_erro.ttv_num_cod_erro, tt_log_erro.ttv_des_msg_erro).
                            run pi_cria_consist_nota (tt_log_erro.ttv_num_cod_erro, 1).
                        END.
                        if docum-est.cdn-sit-nfe = 1 then
                           next.
                    end.
                end.
                else do:
                     run pi-erro-nota (  docum-est.serie-docto, docum-est.nro-docto, docum-est.cod-emitente, docum-est.nat-operacao, 33187, "").
                     run pi_cria_consist_nota (33187, 1).
                     if docum-est.cdn-sit-nfe = 1 then
                        next.
                end.
                
                if docum-est.cdn-sit-nfe = 3 then DO:
                   for first consist-nota {cdp/cd8900.i consist-nota docum-est}
                         AND consist-nota.tipo     = 1
                         and consist-nota.mensagem = 33187 exclusive-lock:
                       delete consist-nota.
                   end.
                END.
            END.
            ELSE IF l-valida-chave-emit THEN DO: /* Faz o mesmo tratamento que era feito anteriormente */
                IF CAN-FIND(FIRST emitente                                                                          
                            WHERE emitente.cod-emitente = docum-est.cod-emitente                                    
                              AND emitente.log-possui-nf-eletro) THEN /* chave nf-e nao autenticada */               

                    RUN pi-atualiza-sit-doc (BUFFER docum-est, 2).
            END.

        /* Fim Valida chave NF-e -> SEFAZ */
        END.

        assign c-re0301-usuario = docum-est.usuario.
        
        find param-of
            where param-of.cod-estabel = docum-est.estab-fisc
            no-lock no-error.

        assign da-dt-of = if avail param-of and param-of.dt-congela <> ?
                             then param-of.dt-congela else ?.
        
        if  da-dt-of <> ?
        and da-dt-of >= docum-est.dt-trans then do:
            run utp/ut-msgs.p (input "type":U, input 5523, input "").
            assign i-tipo = {uninc/i01un001.i 06 return-value}
                   r-RE0301-documento = rowid(docum-est).
            run rep/re0405a.p (?, ?, i-tipo, r-RE0301-documento).
            
            if  l-page
            or  line-counter > 60 then do:
                if line-counter > 60 then page.
                disp c-lb-ser     c-lb-docto   c-lb-natop
                     c-lb-emite   c-lb-nome    c-lb-esp
                     c-lb-emis    c-lb-entr    c-lb-est
                     c-lb-desc    c-lb-tot-nf  c-lb-obs
                     c-lb-vl-bas  c-lb-aliq    c-lb-vl-cd
                     c-lb-vl-nt   c-lb-vl-ou   c-lb-item
                     c-lb-tc      c-lb-natur   c-lb-peso
                     c-lb-qtde    c-lb-desp    c-lb-vl-tot
                     c-lb-icm     c-lb-vl-icm  c-lb-descr
                     c-lb-un      c-lb-cl-fis  c-lb-ipi
                     c-lb-vl-ipi  c-traco      with frame f-header.
                assign l-page = no.
            end.

            disp c-lb-ipi
                 c-lb-icm
                 docum-est.serie-docto  @ doc-fiscal.serie
                 docum-est.nro-docto    @ doc-fiscal.nr-doc-fis
                 docum-est.nat-operacao @ doc-fiscal.nat-operacao
                 docum-est.cod-emitente @ doc-fiscal.cod-emitente
                 docum-est.esp-docto    @ doc-fiscal.esp-docto
                 docum-est.dt-emissao   @ doc-fiscal.dt-emis-doc
                 docum-est.dt-trans     @ doc-fiscal.dt-docto
                 docum-est.cod-estabel  @ doc-fiscal.cod-estabel
                 docum-est.tot-desconto 
                 docum-est.tot-valor    
                 with frame f-documento.
            down with frame f-documento.

            if  l-page                 
            or  line-counter > 60 then do:
                page.
                disp c-lb-ser     c-lb-docto   c-lb-natop
                     c-lb-emite   c-lb-nome    c-lb-esp
                     c-lb-emis    c-lb-entr    c-lb-est
                     c-lb-desc    c-lb-tot-nf  c-lb-obs
                     c-lb-vl-bas  c-lb-aliq    c-lb-vl-cd
                     c-lb-vl-nt   c-lb-vl-ou   c-lb-item
                     c-lb-tc      c-lb-natur   c-lb-peso
                     c-lb-qtde    c-lb-desp    c-lb-vl-tot
                     c-lb-icm     c-lb-vl-icm  c-lb-descr
                     c-lb-un      c-lb-cl-fis  c-lb-ipi
                     c-lb-vl-ipi  c-traco      with frame f-header.
                assign l-page = no.
            end.

            {utp/ut-liter.i Atená∆o * r}
            assign c-lb-atenc = trim(return-value) + "!!! ".
            run utp/ut-msgs.p ("msg", 5523, "").
            put c-lb-atenc  at 25  format "x(11)" skip
                trim(return-value) format "x(80)" skip(1).
            next.
        end.
        else do:
            find first consist-nota
                {cdp/cd8900.i consist-nota docum-est}
                and consist-nota.tipo     = 2
                and consist-nota.mensagem = 5523 exclusive-lock no-error.
            if  avail consist-nota then
                delete consist-nota.
        end.

        assign i-seq-of    = 10
               de-tot-nota = 0.

        /* ATUALIZACAO DE DESPESAS ACESSORIAS E DOCUMENTO FISCAL DE OF */
        if  docum-est.pais-origem = "RE1001" then do:
            if  docum-est.of-atual = no 
            and param-global.modulo-of 
            and (avail natur-oper and natur-oper.tipo = 1) then do:           
                run cdp/cd4395.p ( rowid(docum-est),
                                   yes, 
                                   input table tt-rateio ).
                if return-value = "NOK" then do: /*Erro Integraáa‰ MRI x OF*/
                    run pi-erro-nota (docum-est.serie-docto, docum-est.nro-docto, docum-est.cod-emitente, docum-est.nat-operacao, 33689, "").
                    next.
                end.
		
                RUN pi-atualiza-sit-of (BUFFER docum-est, natur-oper.ind-gera-of). 

                /* Marca documento como atualizado em OF quando somente a despesa acess¢ria atualiza OF.*/
                if not docum-est.of-atual then do:
                   for each despesa-aces {cdp/cd8900.i despesa-aces docum-est} no-lock:

                       find natur-oper
                      where natur-oper.nat-operacao = despesa-aces.nat-oper-ac
                       no-lock no-error.

                         if  avail natur-oper
                         and docum-est.of-atual = no then 
			 
                             RUN pi-atualiza-sit-of (BUFFER docum-est, natur-oper.ind-gera-of). 

                   end.                  
                end.       

            end.
        end.
        else if avail natur-oper then do:
            run rep/re9350.p (rowid(docum-est),
                              c-RE0301-origem,
                              r-RE0301-documento,
                              c-RE0301-usuario).

            if  natur-oper.atualiza-of = no 
            and natur-oper.terceiros   = yes
            and natur-oper.oper-terc   = 1
            and natur-oper.tipo        = 1 then  do:
                run rep/re9351.p (rowid(docum-est),
                                  r-RE0301-documento,
                                  c-RE0301-origem,
                                  c-RE0301-usuario).
            end.
        end.

        /*if  docum-est.cod-observa <> 3 then do:*/

            find param-re
                where param-re.usuario = docum-est.usuario
                no-lock no-error.

            find natur-oper
                where natur-oper.nat-operacao = docum-est.nat-operacao
                no-lock no-error.
            if not avail natur-oper then next.

            if  docum-est.esp-docto  = 23
            and docum-est.tipo-docto = 1 then do:
                find estabelec
                    where estabelec.cod-estabel = docum-est.estab-de-or
                    no-lock no-error.
                if  avail estabelec then
                    find b-emite
                        where b-emite.cod-emitente = estabelec.cod-emitente
                        no-lock no-error.
            end.
            else
                if  natur-oper.int-1 = 1 
                and docum-est.cod-observa = 3 
                and docum-est.nf-emitida-est then do:
                    find estabelec 
                       where estabelec.cod-estabel = docum-est.cod-estabel no-lock no-error.
                    if  avail estabelec then
                        find b-emite where 
                             b-emite.cod-emitente = estabelec.cod-emitente no-lock no-error.
                end.             
                else
                    find b-emite
                        where b-emite.cod-emitente = docum-est.cod-emitente
                        no-lock no-error.

            find estabelec
                where estabelec.cod-estabel = docum-est.estab-fisc
                no-lock no-error.

            if not avail estabelec then next.
             
            ASSIGN d-vl-tot-desc-item = 0. /* Zerando totalizador de desconto */
            FOR EACH item-doc-est no-lock {cdp/cd8900.i item-doc-est docum-est} BREAK BY item-doc-est.nat-of:
                /* totaliza os descontos de cada documento fiscal */
                ASSIGN d-vl-tot-desc-item = d-vl-tot-desc-item + item-doc-est.desconto[1].
                IF  NOT LAST-OF(item-doc-est.nat-of) THEN
                    NEXT. /* S¢ faz a busca se mudar a nat. do item (um docum-est para v†rios doc-fiscal) */

                FIND doc-fiscal
                    WHERE doc-fiscal.cod-estabel  = docum-est.estab-fisc
                    AND   doc-fiscal.cod-emitente = b-emite.cod-emitente
                    AND   doc-fiscal.nat-operacao = item-doc-est.nat-of
                    AND   doc-fiscal.nr-doc-fis   = docum-est.nro-docto
                    AND   doc-fiscal.serie        = docum-est.serie
                    NO-LOCK NO-ERROR.
                IF  AVAIL doc-fiscal THEN DO:
    
                    if  l-page 
                    or  line-counter > 60 then do:
                        page.
                        disp c-lb-ser     c-lb-docto   c-lb-natop
                             c-lb-emite   c-lb-nome    c-lb-esp
                             c-lb-emis    c-lb-entr    c-lb-est
                             c-lb-desc    c-lb-tot-nf  c-lb-obs
                             c-lb-vl-bas  c-lb-aliq    c-lb-vl-cd
                             c-lb-vl-nt   c-lb-vl-ou   c-lb-item
                             c-lb-tc      c-lb-natur   c-lb-peso
                             c-lb-qtde    c-lb-desp    c-lb-vl-tot
                             c-lb-icm     c-lb-vl-icm  c-lb-descr
                             c-lb-un      c-lb-cl-fis  c-lb-ipi
                             c-lb-vl-ipi  c-traco      with frame f-header.
                        assign l-page = no.
                    end.
                    
                    disp c-lb-ipi
                         c-lb-icm
                         doc-fiscal.serie
                         doc-fiscal.nr-doc-fis
                         doc-fiscal.nat-operacao
                         doc-fiscal.cod-emitente
                         doc-fiscal.nome-ab-emi
                         doc-fiscal.esp-docto
                         doc-fiscal.dt-emis-doc
                         doc-fiscal.dt-docto
                         doc-fiscal.cod-estabel
                         d-vl-tot-desc-item @ docum-est.tot-desconto
                         doc-fiscal.vl-cont-doc @ docum-est.tot-valor 
                         docum-est.cod-obs
                         doc-fiscal.vl-bicms
                         doc-fiscal.aliquota-icm
                         doc-fiscal.vl-icms
                         doc-fiscal.vl-icmsnt
                         doc-fiscal.vl-icmsou skip
                         doc-fiscal.vl-bipi
                         doc-fiscal.vl-ipi
                         doc-fiscal.vl-ipint
                         doc-fiscal.vl-ipiou
                         with frame f-documento.
                    down with frame f-documento.
                    assign d-vl-tot-desc-item = 0. /* Zerando totalizador de desconto */
    
                    if  l-page 
                    or  line-counter > 60 then do:
                        page.
                        disp c-lb-ser     c-lb-docto   c-lb-natop
                             c-lb-emite   c-lb-nome    c-lb-esp
                             c-lb-emis    c-lb-entr    c-lb-est
                             c-lb-desc    c-lb-tot-nf  c-lb-obs
                             c-lb-vl-bas  c-lb-aliq    c-lb-vl-cd
                             c-lb-vl-nt   c-lb-vl-ou   c-lb-item
                             c-lb-tc      c-lb-natur   c-lb-peso
                             c-lb-qtde    c-lb-desp    c-lb-vl-tot
                             c-lb-icm     c-lb-vl-icm  c-lb-descr
                             c-lb-un      c-lb-cl-fis  c-lb-ipi
                             c-lb-vl-ipi  c-traco      with frame f-header.
                        assign l-page = no.
                    end.
    
                    run rep/re0405b.p (input rowid(doc-fiscal)).
                    put skip(1).
                end.
                assign de-tot-nota = de-tot-nota + docum-est.tot-valor.
                                
            end.
        /*end.*/

        for each despesa-aces {cdp/cd8900.i despesa-aces docum-est} no-lock:
            find doc-fiscal
                where doc-fiscal.cod-estabel  = docum-est.estab-fisc
                and   doc-fiscal.nat-operac   = despesa-aces.nat-oper-ac
                and   doc-fiscal.serie        = despesa-aces.ser-docto-ac
                and   doc-fiscal.nr-doc-fis   = despesa-aces.nro-docto-ac
                and   doc-fiscal.cod-emitente = despesa-aces.cod-forn-ac
                no-lock no-error.
            if  avail doc-fisc then do:
                disp c-lb-ipi
                     c-lb-icm
                     doc-fiscal.serie
                     doc-fiscal.nr-doc-fis
                     doc-fiscal.nat-operacao
                     doc-fiscal.cod-emitente
                     doc-fiscal.nome-ab-emi
                     doc-fiscal.esp-docto
                     doc-fiscal.dt-emis-doc
                     doc-fiscal.dt-docto
                     doc-fiscal.cod-estabel
                     despesa-aces.valor @ docum-est.tot-valor 
                     doc-fiscal.vl-bicms
                     doc-fiscal.aliquota-icm
                     doc-fiscal.vl-icms
                     doc-fiscal.vl-icmsnt
                     doc-fiscal.vl-icmsou skip
                     doc-fiscal.vl-bipi
                     doc-fiscal.vl-ipi
                     doc-fiscal.vl-ipint
                     doc-fiscal.vl-ipiou
                     with frame f-documento.
                down with frame f-documento.
                assign de-tot-nota = de-tot-nota
                                   + despesa-aces.valor.

                if  l-page 
                or  line-counter > 60 then do:
                    page.
                    disp c-lb-ser     c-lb-docto   c-lb-natop
                         c-lb-emite   c-lb-nome    c-lb-esp
                         c-lb-emis    c-lb-entr    c-lb-est
                         c-lb-desc    c-lb-tot-nf  c-lb-obs
                         c-lb-vl-bas  c-lb-aliq    c-lb-vl-cd
                         c-lb-vl-nt   c-lb-vl-ou   c-lb-item
                         c-lb-tc      c-lb-natur   c-lb-peso
                         c-lb-qtde    c-lb-desp    c-lb-vl-tot
                         c-lb-icm     c-lb-vl-icm  c-lb-descr
                         c-lb-un      c-lb-cl-fis  c-lb-ipi
                         c-lb-vl-ipi  c-traco      with frame f-header.
                    assign l-page = no.
                end.                    

                for each it-doc-fisc
                    where it-doc-fisc.cod-estabel  = doc-fiscal.cod-estabel
                    and   it-doc-fisc.nat-oper     = doc-fiscal.nat-operac
                    and   it-doc-fisc.serie        = doc-fiscal.serie
                    and   it-doc-fisc.nr-doc-fis   = doc-fiscal.nr-doc-fis
                    and   it-doc-fisc.cod-emitente = doc-fiscal.cod-emitente
                    no-lock:
                    find item
                        where item.it-codigo = it-doc-fisc.it-codigo
                        no-lock no-error.

                    if  it-doc-fisc.cd-trib-icm >= 1
                    and it-doc-fisc.cd-trib-icm <= 4 then
                       assign c-cd-trib-icm = 
                              substr({ininc/i01in245.i 04 it-doc-fisc.cd-trib-icm},1,1).                     

                   if  it-doc-fisc.cd-trib-ipi >= 1 
                   and it-doc-fisc.cd-trib-ipi <= 4 then
                      assign c-cd-trib-ipi = 
                             substr({ininc/i07in122.i 04 it-doc-fisc.cd-trib-ipi},1,1).                     

                    if  avail item then
                        assign c-descricao = item.desc-item.   /*string(item.descricao-1,"x(18)")
 *                                            + item.descricao-2.*/
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

                    if  l-page 
                    or  line-counter > 60 then do:
                        page.
                        disp c-lb-ser     c-lb-docto   c-lb-natop
                             c-lb-emite   c-lb-nome    c-lb-esp
                             c-lb-emis    c-lb-entr    c-lb-est
                             c-lb-desc    c-lb-tot-nf  c-lb-obs
                             c-lb-vl-bas  c-lb-aliq    c-lb-vl-cd
                             c-lb-vl-nt   c-lb-vl-ou   c-lb-item
                             c-lb-tc      c-lb-natur   c-lb-peso
                             c-lb-qtde    c-lb-desp    c-lb-vl-tot
                             c-lb-icm     c-lb-vl-icm  c-lb-descr
                             c-lb-un      c-lb-cl-fis  c-lb-ipi
                             c-lb-vl-ipi  c-traco      with frame f-header.
                        assign l-page = no.
                    end.

                    do  i-x = 1 to 15:
                        if  can-do("1,2,3,4,5,6,7,8,9",
                                  (substr(it-doc-fisc.ct-codigo,i-x,1))) then
                            leave.
                    end.

                    if  i-x = 16 then do:
                        run utp/ut-msgs.p ("msg", 5512, "").
                        put trim(return-value) format "x(80)".
                        down with frame f-item-nota.
                    end.

                    if  l-existe = yes then do:
                        run utp/ut-msgs.p ("msg", 6451, "").
                        assign c-obs = "** " + trim(return-value) + " **".
                        disp c-obs with frame f-obs.
                        down with frame f-obs.
                    end.
                    put skip(1).
                end.
            end.
        end.
        assign da-ult-livro = if day(docum-est.dt-trans) < 16
                                 then date(month(docum-est.dt-trans),1,
                                            year(docum-est.dt-trans))
                                 else date(month(docum-est.dt-trans),16,
                                            year(docum-est.dt-trans)).
        find contr-livro
            where contr-livro.cod-estabel = docum-est.cod-estabel
            and   contr-livro.dt-ult-emi  = da-ult-livro
            and   contr-livro.livro       = 2
            no-lock no-error.
        if  avail contr-livro
        and de-tot-nota > 0 then
            disp de-tot-nota with frame f-tot-nota.
    end.

end.

page.

if can-find(first tt-erro) then do:
    /* Inicio -- Projeto Internacional */
    DEFINE VARIABLE c-lbl-liter-notas-fiscais-que-nao-foram-at AS CHARACTER FORMAT "X(41)" NO-UNDO.
    {utp/ut-liter.i "Notas_fiscais_que_nao_foram_atualizadas" *}
    ASSIGN c-lbl-liter-notas-fiscais-que-nao-foram-at = TRIM(RETURN-VALUE).
    PUT skip(3) c-lbl-liter-notas-fiscais-que-nao-foram-at SKIP.
    PUT "---------------------------------------" SKIP.
end.

FOR EACH tt-erro:
    put tt-erro.serie at 1.
    put tt-erro.nro-docto   at 7.
    put string(tt-erro.cod-emitente) at 24 format "x(9)".
    put tt-erro.nat-operacao at 35.
    put string(tt-erro.cd-erro,">>>>>9") at 43.
    put tt-erro.mensagem at 53 format "X(78)" skip.
END.

IF tt-param.l-imp-param THEN DO:
	page.
	disp c-lb-sel             at 1
		 c-lb-data            at 8  format "x(4)"      
		 ":"                  at 14
		 tt-param.da-data-i   at 25  
		 " |<  >|"            at 38
		 tt-param.da-data-f   at 52 
	&if defined(bf_mat_selecao_estab_re) &then 
		 skip
		 c-lb-estab           at 8 format "x(15)"
		 ":"                  at 23
		 tt-param.c-est-ini   at 25 format "x(5)"
		 " |<  >|"            at 38 
		 tt-param.c-est-fim   at 52 format "x(5)"
	&endif
		 skip(1)
		 c-lb-imp             at 1  format "x(9)"       skip
		 c-lb-dest            at 5  format "x(7)" 
		 ":"                  at 14
		 tt-param.c-destino   at 19 format "x(10)" 
		 " - "                at 32
		 tt-param.arquivo     at 46 format "x(40)"
		 c-lb-usuar           at 5  format "x(7)" 
		 ":"                  at 14
		 tt-param.usuario     at 19  
		 with stream-io no-labels no-attr-space no-box width 132 .
end.
 {include/i-rpclo.i}

run pi-finalizar in h-acomp.

return "OK".

procedure pi-erro-nota:
    DEF INPUT PARAMETER p-serie        LIKE docum-est.serie NO-UNDO.
    DEF INPUT PARAMETER p-nro-docto    LIKE docum-est.nro-docto NO-UNDO.
    DEF INPUT PARAMETER p-cod-emitente LIKE docum-est.cod-emitente NO-UNDO.
    DEF INPUT PARAMETER p-nat-operacao LIKE docum-est.nat-operacao NO-UNDO.
    def input parameter cod-mensag  as integer                      no-undo.
    def input parameter c-complem   as char                         no-undo.

    run utp/ut-msgs.p ( input "msg",
                        input cod-mensag,
                        input c-complem  ).  

    create tt-erro.
    assign tt-erro.cd-erro      = cod-mensag
           tt-erro.mensagem     = return-value
           tt-erro.serie        = p-serie
           tt-erro.nro-docto    = p-nro-docto
           tt-erro.cod-emitente = p-cod-emitente
           tt-erro.nat-operacao = p-nat-operacao.

end.

PROCEDURE pi_elimina_consist_nota_validacao_nfe:
	FOR EACH consist-nota {cdp/cd8900.i consist-nota docum-est} EXCLUSIVE-LOCK:
		IF consist-nota.mensagem = 33187 OR consist-nota.mensagem = 33140 OR consist-nota.mensagem = 52843 OR consist-nota.mensagem = 17006 THEN
			DELETE consist-nota.
	END.
END.

PROCEDURE pi_cria_consist_nota:
    def input parameter cod-mensag      as integer  no-undo.
    def input parameter i-tipo-msg      as integer  no-undo. 

	if not can-find( first consist-nota {cdp/cd8900.i consist-nota docum-est}
					   and consist-nota.tipo     = i-tipo-msg
					   and consist-nota.mensagem = cod-mensag) then do:
	   create consist-nota.
	   assign consist-nota.serie-docto  = docum-est.serie-docto
			  consist-nota.nro-docto    = docum-est.nro-docto
			  consist-nota.nat-operacao = docum-est.nat-operacao
			  consist-nota.cod-emit     = docum-est.cod-emit
			  consist-nota.mensagem     = cod-mensag
			  consist-nota.tipo         = i-tipo-msg.	  
	end.
END.

PROCEDURE pi-atualiza-sit-doc :

    DEF PARAM BUFFER p-docum-est FOR docum-est.
    DEF INPUT PARAM p-sit-nfe LIKE docum-est.cdn-sit-nfe NO-UNDO.

    DEF BUFFER b-altera-doc FOR docum-est.

    DO WHILE TRUE :

        FIND FIRST b-altera-doc OF p-docum-est EXCLUSIVE-LOCK NO-WAIT NO-ERROR.

        IF NOT LOCKED(b-altera-doc) THEN DO:
            ASSIGN b-altera-doc.cdn-sit-nfe = p-sit-nfe.

            RELEASE b-altera-doc.

            LEAVE.
        END.

        PAUSE 1.

    END.

END PROCEDURE.

PROCEDURE pi-atualiza-sit-of :

    DEF PARAM BUFFER p-docum-est FOR docum-est.
    DEF INPUT PARAM p-sit-of LIKE docum-est.of-atual NO-UNDO.

    DEF BUFFER b-altera-doc FOR docum-est.

    DO WHILE TRUE :

        FIND FIRST b-altera-doc OF p-docum-est EXCLUSIVE-LOCK NO-WAIT NO-ERROR.

        IF NOT LOCKED(b-altera-doc) THEN DO:
            ASSIGN b-altera-doc.of-atual = p-sit-of.

            RELEASE b-altera-doc.

            LEAVE.
        END.

        PAUSE 1.

    END.

END PROCEDURE.
