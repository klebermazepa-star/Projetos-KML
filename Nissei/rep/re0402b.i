/************************************************************************
**
**      RE0402b.i - Verificacao dos titulos no Contas ¹ Pagar
**
************************************************************************/

assign i-cod-emitente-upc = docum-est.cod-emitente.

if  "{1}" = " " then do:

    if  c-nom-prog-upc-mg97  <> "" THEN DO:
    
        for each tt-epc:
            delete tt-epc.
        end.

        create tt-epc.
        assign tt-epc.cod-event = "before_validate_duplic"
               tt-epc.cod-parameter = "ROWID(docum-est)"
               tt-epc.val-parameter = STRING(ROWID(docum-est)).
               
        create tt-epc.
        assign tt-epc.cod-event = "before_validate_duplic"
               tt-epc.cod-parameter = "i-cod-emitente-upc"
               tt-epc.val-parameter = STRING(i-cod-emitente-upc).
               
         {include/i-epc201.i "before_validate_duplic"} 

        find tt-epc
             where tt-epc.cod-parameter = "i-cod-emitente-upc" no-error.
        if  avail tt-epc then
            assign i-cod-emitente-upc = int(tt-epc.val-parameter).             
        
    end.                                                   
end.

for each dupli-apagar{1} use-index documento 
    where dupli-apagar{1}.serie-docto  = docum-est.serie-docto 
      and dupli-apagar{1}.nro-docto    = docum-est.nro-docto 
      and dupli-apagar{1}.cod-emitente = docum-est.cod-emitente
      and dupli-apagar{1}.nat-operacao = docum-est.nat-operacao no-lock:

    IF  "{1}" <> " " THEN
        ASSIGN i-cod-emitente-upc = dupli-apagar{1}.cod-emitente{2}.

    assign c-nr-duplic = {3}.
    if l-imp then
        assign c-nr-duplic = c-embarque.        

    if  not l-ems50 then do:
        run pi-verifica-ap ( input  i-cod-emitente-upc,
                             input  dupli-apagar{1}.cod-esp,
                             input  c-nr-duplic,  
                             input  dupli-apagar{1}.parcela).
        if  l-dp-cont then
            leave.
    end.
    else do:
        RUN Pi-verifica-EMS50 (input docum-est.cod-estabel,
                               input i-cod-emitente-upc,
                               input dupli-apagar{1}.cod-esp,
                               input dupli-apagar{1}.serie-docto,
                               input c-nr-duplic,
                               input dupli-apagar{1}.parcela,
                               output l-existe-ems50,
                               output l-erro).

        if l-existe-ems50 then 
            assign l-existe-ap = yes.
        if l-erro then
            return.
    end.                

    for each dupli-imp no-lock
        where dupli-imp.cod-esp      = dupli-apagar{1}.cod-esp
        and   dupli-imp.serie        = dupli-apagar{1}.serie-docto
        and   dupli-imp.nro-docto    = dupli-apagar{1}.nro-docto
        and   dupli-imp.parcela      = dupli-apagar{1}.parcela 
        and   dupli-imp.cod-forn-imp = dupli-apagar{1}.cod-emitente:

        if not l-ems50 then do:
            run pi-verifica-ap ( input dupli-imp.cod-forn-imp,
                                 input dupli-imp.cod-esp,
                                 input dupli-imp.nro-docto-imp,
                                 input dupli-imp.parcela-imp).

            if  l-dp-cont then 
                leave.
        end.
        else do:
            RUN Pi-verifica-EMS5 (input docum-est.cod-estabel,
                                  input dupli-apagar{1}.cod-emitente,
                                  input dupli-imp.cod-esp,
                                  input dupli-apagar{1}.serie-docto,
                                  input dupli-imp.nro-docto-imp,
                                  input dupli-imp.parcela-imp,
                                  output l-existe-ems50,
                                  output l-erro).
            if l-existe-ems50 then 
                assign l-existe-ap = yes.
            if l-erro then
                return.
        end.
    end.                
end.

/* re0402b.i */
