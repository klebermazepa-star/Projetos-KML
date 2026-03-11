/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i REAPI190 2.00.04.007 } /*** 010407 ***/
/*******************************************************************************
* Programa..:  REAPI190.P
* Data......:  Outubro de 1998
* Objetivo .:  Valida e Gera documentos
* Cria��o ..:  Zucco
*******************************************************************************/


// Teste Kleber

{rep/reapi190.i}

/* alteração teste */
message "REAPI190 - Geracao de Documentos de Estorno" VIEW-AS ALERT-BOX INFO BUTTONS OK.


/* Definicao de Parametros */
DEFINE INPUT  PARAMETER TABLE FOR tt-versao-integr.
DEFINE INPUT  PARAMETER TABLE FOR tt-docum-est.
DEFINE INPUT  PARAMETER TABLE FOR tt-item-doc-est.
DEFINE INPUT  PARAMETER TABLE FOR tt-dupli-apagar.
DEFINE INPUT  PARAMETER TABLE FOR tt-dupli-imp.
DEFINE INPUT  PARAMETER TABLE FOR tt-unid-neg-nota.
DEFINE OUTPUT PARAMETER TABLE FOR tt-erro.
IF NOT CAN-FIND (FIRST funcao
                     WHERE funcao.cd-funcao = "spp-nao-elimina-ordem"
                       AND funcao.ativo     = YES) THEN DO:
    FOR FIRST ordem-compra
        WHERE ordem-compra.numero-ordem = 0 EXCLUSIVE-LOCK:
        FOR FIRST prazo-compra OF ordem-compra EXCLUSIVE-LOCK:
            DELETE prazo-compra.
        END.
        DELETE ordem-compra.
    END.        
END.

FOR EACH tt-docum-est:
    CREATE tt-docum-est-aux.
    BUFFER-COPY tt-docum-est TO tt-docum-est-aux.
    ASSIGN tt-docum-est-aux.nome-transp    = ""
           tt-docum-est-aux.cod-placa-1    = ""
           tt-docum-est-aux.cod-placa-2    = ""
           tt-docum-est-aux.cod-placa-3    = ""
           tt-docum-est-aux.cod-uf-placa-1 = ""
           tt-docum-est-aux.cod-uf-placa-2 = ""
           tt-docum-est-aux.cod-uf-placa-3 = "".
END.

RUN rep/reapi190a.p (INPUT  TABLE tt-versao-integr,
                     INPUT  TABLE tt-docum-est-aux,
                     INPUT  TABLE tt-item-doc-est,
                     INPUT  TABLE tt-dupli-apagar,
                     INPUT  TABLE tt-dupli-imp,
                     INPUT  TABLE tt-unid-neg-nota,
                     OUTPUT TABLE tt-erro).

IF  RETURN-VALUE <> "OK":U THEN
    RETURN "NOK":U.
ELSE
    RETURN "OK":U.
