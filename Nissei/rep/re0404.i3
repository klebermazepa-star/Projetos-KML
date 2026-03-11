/****************************************************************************
**
**  Include.: re0404.i3
**
**  Objetivo: ImpressÆo do log de exporta‡Æo e Exporta‡Æo (tt-impto-tit-pend)
**
****************************************************************************/
{include/i_dbvers.i}

 put stream arq-export  
    "600"
    tt-impto-tit-pend-ap.ep-codigo                 &IF "{&mguni_version}" >= "2.071" &THEN 
                                                     format "x(5)"                         
                                                   &ELSE                                   
                                                     format "999"                          
                                                   &ENDIF           space (0)              
    tt-impto-tit-pend-ap.cod-estabel               &IF "{&mguni_version}" >= "2.071" &THEN
                                                     format "x(5)"
                                                   &ELSE
                                                     format "x(3)"  
                                                   &ENDIF           space (0)     
    tt-impto-tit-pend-ap.Serie                       format "x(5)" space(0)            
    tt-impto-tit-pend-ap.Cod-esp                     format "x(2)" space(0)         
    tt-impto-tit-pend-ap.Nr-docto                    format "x(16)" space(0)         
    tt-impto-tit-pend-ap.Parcela                     format "x(2)" space(0)       
    "      "                                         format "x(6)" space(0) 
   (tt-impto-tit-pend-ap.Vl-imposto * 100)           format "99999999999999" space(0) 
    tt-impto-tit-pend-ap.Ct-imposto                  format "x(8)"  space(0)        
    tt-impto-tit-pend-ap.Sc-imposto                  format "x(8)"  space(0)        
    tt-impto-tit-pend-ap.Conta-imposto               format "x(17)" space(0)   
    "   "

    /*tt-impto-tit-pend-ap.Cod-imposto                 format "999" space(0) */
    
    tt-impto-tit-pend-ap.Tipo                        format "99" space(0)             
    tt-impto-tit-pend-ap.Contabilizou                format "S/N" space(0)           
    (tt-impto-tit-pend-ap.Perc-imposto * 100)        format "999999" space(0) 
    day(tt-impto-tit-pend-ap.Dt-transacao)           format "99" space(0) 
    month(tt-impto-tit-pend-ap.Dt-transacao)         format "99" space(0)
    year(tt-impto-tit-pend-ap.Dt-transacao)          format "9999" space(0)
    (tt-impto-tit-pend-ap.Vl-base  * 100)            format "99999999999999" space(0)   
    day(tt-impto-tit-pend-ap.Dt-emissao)             format "99" space(0) 
    month(tt-impto-tit-pend-ap.Dt-emissao)           format "99" space(0)
    year(tt-impto-tit-pend-ap.Dt-emissao)            format "9999" space(0)
    tt-impto-tit-pend-ap.Ind-data-base               format "999999999" space(0) 
    (tt-impto-tit-pend-ap.Vl-saldo-imposto  * 100)   format "99999999999999" space(0) 
    tt-impto-tit-pend-ap.Lancamento                  format "99" space(0)      
    tt-impto-tit-pend-ap.Ct-percepcao                format "x(8)"  space(0)    
    tt-impto-tit-pend-ap.Sc-percepcao                format "x(8)"  space(0)     
    tt-impto-tit-pend-ap.conta-percepcao             format "x(17)" space(0)
    (tt-impto-tit-pend-ap.Vl-percepcao * 100)        format "99999999999999" space(0)      
    tt-impto-tit-pend-ap.Ct-retencao                 format "x(8)" space(0)     
    tt-impto-tit-pend-ap.Sc-retencao                 format "x(8)" space(0)       
    tt-impto-tit-pend-ap.Conta-retencao              format "x(17)" space(0)   
    (tt-impto-tit-pend-ap.Perc-retencao  * 100)      format "999999" space(0) 
    (tt-impto-tit-pend-ap.Vl-retencao * 100)         format "99999999999999" space(0)     
    (tt-impto-tit-pend-ap.Perc-percepcao * 100)      format "999999" space(0) 
    (tt-impto-tit-pend-ap.Vl-base-me  * 100)         format "99999999999999" space(0)             
    (tt-impto-tit-pend-ap.Vl-imposto-me  * 100)      format "99999999999999" space(0)     
    (tt-impto-tit-pend-ap.Vl-percepcao-me  * 100)    format "99999999999999" space(0) 
    (tt-impto-tit-pend-ap.Vl-retencao-me * 100)      format "99999999999999" space(0)    
    (tt-impto-tit-pend-ap.Vl-saldo-imposto-me * 100) format "99999999999999" space(0)    
    tt-impto-tit-pend-ap.Mo-codigo                   format "99" space(0)          
    tt-impto-tit-pend-ap.Hp-codigo                   format "999" space(0)          
    tt-impto-tit-pend-ap.Historico                   format "x(80)" space(0)    
    tt-impto-tit-pend-ap.Cod-retencao                format "99999" space(0) 
    day(tt-impto-tit-pend-ap.dt-vencimen)            format "99" space(0) 
    month(tt-impto-tit-pend-ap.dt-vencimen)          format "99" space(0)
    year(tt-impto-tit-pend-ap.dt-vencimen)           format "9999" space(0)
    tt-impto-tit-pend-ap.Tp-codigo                   format "999" space(0)      
    tt-impto-tit-pend-ap.num-seq-impto                format "9999999999" space(0)  
    (tt-impto-tit-pend-ap.Cotacao-dia  * 100000000)  format "9999999999999" space(0) 
    (tt-impto-tit-pend-ap.Vl-var-monet  * 100)       format "9999999999999" space(0) 
    tt-impto-tit-pend-ap.Origem-impto                format "99" space(0)    
    tt-impto-tit-pend-ap.Num-id-pef-pend             format "9999999" space(0)    
    tt-impto-tit-pend-ap.Cod-portador                format "99999" space(0)     
    tt-impto-tit-pend-ap.Trans-impto-ap              format "99" space(0)    
    (tt-impto-tit-pend-ap.vl-iva-liberado    * 100)  format "99999999999999" space(0)
    (tt-impto-tit-pend-ap.Vl-iva-liberado-me * 100)  format "99999999999999" space(0)  
    (tt-impto-tit-pend-ap.Perc-iva-liberado * 100)   format "999999" space(0)   
    tt-impto-tit-pend-ap.Ct-iva-liberado             format "x(8)"  space(0)  
    tt-impto-tit-pend-ap.Sc-iva-liberado             format "x(8)" space(0) 
    tt-impto-tit-pend-ap.Conta-iva-liberado          format "x(17)"   space(0)  
    tt-impto-tit-pend-ap.Conta-saldo-credito         format "x(17)"  space(0)  
    tt-impto-tit-pend-ap.Sc-saldo-credito            format "x(8)"  space(0) 
    tt-impto-tit-pend-ap.Ct-saldo-credito            format "x(8)"  space(0) 
    tt-impto-tit-pend-ap.Cod-classificacao           format "9999" space(0) 
    tt-impto-tit-pend-ap.Cod-fornec                  format "999999999" space(0) 
    substring(tt-impto-tit-pend-ap.char-1,1,2)       format "x(2)"      space(0)
    substring(tt-impto-tit-pend-ap.char-1,3,5)       format "x(5)"      space(0)   
    substring(tt-impto-tit-pend-ap.char-1,8,16)      format "x(16)"     space(0)
    substring(tt-impto-tit-pend-ap.char-1,24,2)      format "x(2)"      space(0) 
    tt-impto-tit-pend-ap.Cod-imposto                 format "9999"      space(0) skip.


    /*****************************************************************************/    
    /** Chamada EPC para exportar informa‡äes adicionais da localiza‡Æo         **/
    /*****************************************************************************/
    
    for each tt-epc where tt-epc.cod-event = "Exporta-impto-tit-pend-ap":
       delete tt-epc.
    end.

    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "ep-codigo"
           tt-epc.val-parameter = string(tt-impto-tit-pend-ap.ep-codigo).
    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "cod-estabel"
           tt-epc.val-parameter = tt-impto-tit-pend-ap.cod-estabel.
    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "cod-esp"
           tt-epc.val-parameter = tt-impto-tit-pend-ap.cod-esp.
    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "serie"
           tt-epc.val-parameter = tt-impto-tit-pend-ap.serie.
    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "nr-docto"
           tt-epc.val-parameter = tt-impto-tit-pend-ap.nr-docto.
    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "parcela"
           tt-epc.val-parameter = tt-impto-tit-pend-ap.parcela.
    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "cod-fornec"
           tt-epc.val-parameter = string(tt-impto-tit-pend-ap.cod-fornec).
    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "cod-imposto"
           tt-epc.val-parameter = string(tt-impto-tit-pend-ap.cod-imposto).
    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "num-seq-impto"
           tt-epc.val-parameter = string(tt-impto-tit-pend-ap.num-seq-impto).
    create tt-epc.
    assign tt-epc.cod-event     = "Exporta-impto-tit-pend-ap"
           tt-epc.cod-parameter = "nat-operac"
           tt-epc.val-parameter = tt-impto-tit-pend-ap.nat-operac.
           
           
    {include/i-epc201.i "Exporta-impto-tit-pend-ap"}
    
    /*****************************************************************************/
    
        
        
 
                    


