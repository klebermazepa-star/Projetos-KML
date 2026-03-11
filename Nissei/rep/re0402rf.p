/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0402RF 2.00.00.016 } /*** 010016 ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
{include/i-license-manager.i re0402rf MRE}
&ENDIF


/**************************************************************************
**
**  RE0402F.P - Desatualizacao dos Modulos de Investimento e Patrimonio
**
**************************************************************************/
{rep/re1005.i05}
{cdp/cd4300.i3} /*Vari†veis que ser∆o utilizadas no cd4300.i4*/
{rep/re1001a.i50} /*Vari†veis do embarque*/
{cdp/cd0666.i}

def input  param r-docum-est as rowid.
def output param table for tt-erro.

{include/i-epc200.i re0402rf}

find first param-global no-lock no-error.
find docum-est where rowid(docum-est) = r-docum-est no-lock no-error.

/*Grava o valor do embarque na c-embarque*/
{cdp/cd4300.i4 "yes" docum-est.char-1}
{rep/re1001a.i51 "yes"}
/*Grava o valor do embarque na c-embarque*/

DEF VAR h-cd9111 AS HANDLE NO-UNDO.

IF NOT VALID-HANDLE (h-cd9111) THEN
    RUN cdp/cd9111rp.p PERSISTENT SET h-cd9111 (INPUT ROWID(item-doc-est),
                                                INPUT NO,
                                                INPUT TABLE tt-rateio).

for each item-doc-est {cdp/cd8900.i item-doc-est docum-est} no-lock:

    IF  (c-nom-prog-dpc-mg97  <> "" AND c-nom-prog-dpc-mg97  <> ?)
    OR  (c-nom-prog-appc-mg97 <> "" AND c-nom-prog-appc-mg97 <> ?)
    OR  (c-nom-prog-upc-mg97  <> "" AND c-nom-prog-upc-mg97  <> ?) THEN DO:
        IF  param-global.modulo-in THEN DO:
            
            /*nota Ç de importaá∆o:
               - m¢dulo implantado
               - docum-est.char-1,1,12 <> ""
               - natureza de operacao = rateio (cd0606)*/
    
            FIND FIRST natur-oper NO-LOCK
                     WHERE natur-oper.nat-operacao = docum-est.nat-operacao NO-ERROR.
            IF  AVAIL natur-oper THEN DO:
                IF  natur-oper.nota-rateio
                AND trim(c-embarque) <> "" THEN DO:
                    
                    /* ******************** Ponto UPC - YAMANA ******************** */
                    FOR EACH tt-epc
                        WHERE tt-epc.cod-event = "antes-desatualizacao-investimentos".
                        DELETE tt-epc.
                    END.
                    
                    CREATE tt-epc.
                    ASSIGN tt-epc.cod-event     = "antes-desatualizacao-investimentos"
                           tt-epc.cod-parameter = "docum-est-rowid"
                           tt-epc.val-parameter = STRING(ROWID(docum-est)).
                    
                    {include/i-epc201.i "antes-desatualizacao-investimentos" }
                    
                    IF  RETURN-VALUE = 'NOK' THEN DO:
                        FIND FIRST tt-epc 
                             WHERE tt-epc.cod-event = "tt-erro" NO-LOCK NO-ERROR.
                        IF AVAIL tt-epc THEN DO:
                            CREATE tt-erro.
                            ASSIGN tt-erro.cd-erro  = INT(tt-epc.cod-parameter)
                                   tt-erro.mensagem = tt-epc.val-parameter.
                            
                        END.
                        RETURN.
                    END.
                    /* ******************** Ponto UPC - YAMANA ******************** */
                END.
            END.
        END.
    END.

    /* Modulo Investimentos */
    if  param-global.modulo-in        and
        item-doc-est.num-ord-inv <> 0 then
        run inp/in2107.p (input rowid(item-doc-est)).

    /* Elimina BEM-INVEST */
    /* Verificar com o desenvolvimento do patrimonio */

    if  param-global.modulo-pt THEN DO:
        RUN pi-execute IN h-cd9111 (INPUT ROWID(item-doc-est),
                                    INPUT NO,
                                    INPUT TABLE tt-rateio).

        RUN pi-retorna-tt-erro IN h-cd9111 (OUTPUT TABLE tt-erro).
    END.
end.
DELETE PROCEDURE h-cd9111.
/* Fim do Programa */
