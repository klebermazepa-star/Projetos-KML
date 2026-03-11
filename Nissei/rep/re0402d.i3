if  l-integracao-ems50 then do:

    /* API Cancelamento de Titulos - EMS 5.0 */
    run prgfin/apb/apb768zd.py ( input  1,
                                 input  "REP",
                                 input  " ",
                                 input  table tt_cancelamento_estorno_apb_1,
                                 input  table tt_estornar_agrupados,
                                 output table tt_log_erros_atualiz,
                                 output table tt_log_erros_estorn_cancel_apb,
                                 output table tt_estorna_tit_imptos, 
                                 output v_log_livre_1 ).

    find first tt_log_erros_atualiz no-error.
    find first tt_log_erros_estorn_cancel_apb no-error.
    
    if  avail tt_log_erros_atualiz
    or  avail tt_log_erros_estorn_cancel_apb then do:
        
        /* Criacao dos erros do documento */
        for each tt_log_erros_atualiz:
            create tt-erro.
            assign tt-erro.cd-erro  = tt_log_erros_atualiz.ttv_num_mensagem
                   tt-erro.mensagem = tt_log_erros_atualiz.ttv_des_msg_erro.
        end.                                  
         
        for each tt_log_erros_estorn_cancel_apb:
            create tt-erro.
            assign tt-erro.cd-erro  = tt_log_erros_estorn_cancel_apb.tta_num_mensagem
                   tt-erro.mensagem = tt_log_erros_estorn_cancel_apb.ttv_des_msg_erro.
        end.
        
        assign l-erro = yes.
    end.
    
    if  l-erro then return.
    
end.  

assign docum-est.ap-atual = no.

/* eSocial */
FOR FIRST docum-est-esoc EXCLUSIVE-LOCK  
    WHERE docum-est-esoc.serie-docto  = docum-est.serie-docto  AND
          docum-est-esoc.nro-docto    = docum-est.nro-docto    AND
          docum-est-esoc.cod-emitente = docum-est.cod-emitente AND
          docum-est-esoc.nat-operacao = docum-est.nat-operacao :
                      
   ASSIGN docum-est-esoc.log-livre-1 = docum-est.ap-atual.
END. 

if c-nom-prog-upc-mg97  <> "":U
or c-nom-prog-dpc-mg97  <> "":U
or c-nom-prog-appc-mg97 <> "":U then do:
    /* UPC Banrisul */
    FOR EACH tt-epc WHERE tt-epc.cod-event = "GERACAO-AVA-MAIOR":U:
        DELETE tt-epc.
    END.
   
    CREATE tt-epc.
    ASSIGN tt-epc.cod-event     = "GERACAO-AVA-MAIOR":U
           tt-epc.cod-parameter = "r-docum-est":U
           tt-epc.val-parameter = STRING(ROWID(docum-est)).
   
    {include/i-epc201.i "GERACAO-AVA-MAIOR"} 
        
end.

return "OK".

/* -------------------------- Procedures Internas ---------------------------- */

{rep/re0402a.i1}     /* Procedure pi-erro-nota */

procedure pi-cria-temp-table:
    
    def input param c-nro-docto      like docum-est.nro-docto     no-undo.
    def input param c-serie-docto    like docum-est.serie-docto   no-undo.
    def input param i-cod-emitente   like docum-est.cod-emitente  no-undo.
    def input param c-cod-esp        like dupli-apagar.cod-esp    no-undo.
    def input param i-parcela        like dupli-apagar.parcela    no-undo.
    def input param da-emissao       like dupli-apagar.dt-emissao no-undo.
    def input param l-elimina-impto  as   log                     no-undo.

    assign i-empresa = param-global.empresa-prin.

    &if defined (bf_dis_consiste_conta) &then

        find estabelec where
             estabelec.cod-estabel = docum-est.cod-estabel no-lock no-error.

        run cdp/cd9970.p (input rowid(estabelec),
                          output i-empresa).
    &endif

    if  not l-integracao-ems50 then do:
        create tt-param.
        assign tt-param.cod-versao-integracao = 1
               tt-param.i-ep-codigo     = i-empresa
               tt-param.estabel         = docum-est.cod-estabel
               tt-param.espec           = c-cod-esp
               tt-param.serie-ini       = c-serie-docto
               tt-param.docto-ini       = c-nro-docto
               tt-param.parc-ini        = string(i-parcela)
               tt-param.forn-ini        = i-cod-emitente
               tt-param.emis-ini        = da-emissao
               tt-param.elimina-ir      = l-elimina-impto
               tt-param.elimina-iss     = l-elimina-impto
               tt-param.elimina-estoque = yes
               tt-param.elimina-movto   = no
               tt-param.serie-fim       = ?
               tt-param.docto-fim       = ? 
               tt-param.parc-fim        = ?
               tt-param.emis-fim        = ? 
               tt-param.forn-fim        = ?
               tt-param.ref-fim         = ?.
    end.
    else do:           
    
         if  i-pais-impto-usuario = 2 and not l-credito-debito then do:
             if  not valid-handle(h-boar2011) then
                 run local/arg/boar2011.p persistent set h-boar2011.             
                                                         
             RUN BuscaSerieAPB IN h-boar2011 (INPUT i-empresa,
                                              INPUT i-cod-emitente,
                                              INPUT c-serie-docto,                                             
                                              INPUT c-cod-esp,
                                              INPUT rowid(docum-est),
                                              OUTPUT c-serie-docto-ems5).
                                                                      
             if  c-serie-docto-ems5 <> "" then
                 assign c-serie-docto = c-serie-docto-ems5.
                 
             if  valid-handle(h-boar2011) then
                 run destroy in h-boar2011.
         end.

         /* Integracao com EMS 5.0 */
         create tt_cancelamento_estorno_apb_1.
         assign tt_cancelamento_estorno_apb_1.tta_cod_estab_ext      = docum-est.cod-estabel
                tt_cancelamento_estorno_apb_1.tta_cod_espec_docto    = c-cod-esp
                tt_cancelamento_estorno_apb_1.tta_cod_ser_docto      = c-serie-docto
                tt_cancelamento_estorno_apb_1.tta_cod_tit_ap         = c-nro-docto
                tt_cancelamento_estorno_apb_1.tta_cod_parcela        = string(i-parcela)
                tt_cancelamento_estorno_apb_1.tta_cdn_fornecedor     = i-cod-emitente
                tt_cancelamento_estorno_apb_1.ttv_log_reaber_item    = no                
                tt_cancelamento_estorno_apb_1.ttv_log_reembol        = no
                tt_cancelamento_estorno_apb_1.ttv_rec_tit_ap         = 0.
         
         assign tt_cancelamento_estorno_apb_1.ttv_ind_niv_operac_apb = "T¡tulo"
                tt_cancelamento_estorno_apb_1.ttv_ind_tip_operac_apb = "Cancelamento"
                tt_cancelamento_estorno_apb_1.ttv_ind_tip_estorn     = "Total".
    end.
           
end.

procedure pi-verifica-erro:

    def output param l-erro    as log       no-undo.
    
    find first tt-param no-error.
    find first tt-tit-ap no-error.
    find first tt-retorno-erro no-error.
    
    if  avail tt-retorno-erro then do:
        create tt-erro.
        assign tt-erro.cd-erro  = tt-retorno-erro.cod-erro
               tt-erro.mensagem = tt-retorno-erro.desc-erro.
    end.

    if  avail tt-param then
        delete tt-param.                  
        
    assign l-erro =  avail tt-retorno-erro
                  or not avail tt-tit-ap.        

end.


