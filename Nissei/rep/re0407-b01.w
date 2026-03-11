&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
*/
&Scoped-define WINDOW-NAME CURRENT-WINDOW


/* Temp-Table and Buffer definitions                                    */
DEFINE TEMP-TABLE tt-rat-saldo-terc NO-UNDO LIKE rat-saldo-terc
       field r-rowid as rowid.



&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS B-table-Win 
/*********************************************************************
* Copyright (C) 2000 by Progress Software Corporation. All rights    *
* reserved. Prior versions of this work may contain portions         *
* contributed by participants of Possenet.                           *
*                                                                    *
*********************************************************************/
{include/i-prgvrs.i RE0407-B01 2.00.00.060 } /*** "010060" ***/

&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0407-b01 MUT}
&ENDIF
/*------------------------------------------------------------------------

  File:  

  Description: from BROWSER.W - Basic SmartBrowser Object Template

  Input Parameters:
      <none>

  Output Parameters:
      <none>

------------------------------------------------------------------------*/
/*          This .W file was created with the Progress UIB.             */
/*----------------------------------------------------------------------*/

/* Create an unnamed pool to store all the widgets created 
     by this procedure. This is a good default which assures
     that this procedure's triggers and internal procedures 
     will execute in this procedure's storage, and that proper
     cleanup will occur on deletion of the procedure. */

CREATE WIDGET-POOL.

/* ***************************  Definitions  ************************** */

/* Parameters Definitions ---                                           */

/* Local Variable Definitions ---                                       */
DEF VAR wh-pesquisa AS HANDLE   NO-UNDO.

DEF VAR vcod-emitente AS INT    NO-UNDO.
DEF VAR vserie-docto  AS CHAR   NO-UNDO.
DEF VAR vnro-docto    AS CHAR   NO-UNDO.
DEF VAR vnat-operacao AS CHAR   NO-UNDO.
DEF VAR vcod-refer    AS CHAR   NO-UNDO.
DEF VAR vit-codigo    AS CHAR   NO-UNDO.
DEF VAR vsequencia    AS INT    NO-UNDO.
DEF VAR vcod-estabel  AS CHAR   NO-UNDO.
DEF VAR vcod-depos    AS CHAR   NO-UNDO.
DEF VAR vcod-localiz  AS CHAR   NO-UNDO.
DEF VAR vquantidade   AS DEC    NO-UNDO.
DEF VAR i-oper        AS INT    NO-UNDO.
DEF VAR h_re0407-v02  AS HANDLE NO-UNDO.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE SmartBrowser
&Scoped-define DB-AWARE no

&Scoped-define ADM-SUPPORTED-LINKS Record-Source,Record-Target,TableIO-Target

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME F-Main
&Scoped-define BROWSE-NAME br_table

/* External Tables                                                      */
&Scoped-define EXTERNAL-TABLES saldo-terc
&Scoped-define FIRST-EXTERNAL-TABLE saldo-terc


/* Need to scope the external tables to this procedure                  */
DEFINE QUERY external_tables FOR saldo-terc.
/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-rat-saldo-terc

/* Define KEY-PHRASE in case it is used by any query. */
&Scoped-define KEY-PHRASE TRUE

/* Definitions for BROWSE br_table                                      */
&Scoped-define FIELDS-IN-QUERY-br_table tt-rat-saldo-terc.cod-depos ~
tt-rat-saldo-terc.cod-localiz tt-rat-saldo-terc.lote ~
tt-rat-saldo-terc.dt-vali-lote tt-rat-saldo-terc.quantidade ~
tt-rat-saldo-terc.it-codigo 
&Scoped-define ENABLED-FIELDS-IN-QUERY-br_table 
&Scoped-define QUERY-STRING-br_table FOR EACH tt-rat-saldo-terc WHERE ~{&KEY-PHRASE} SHARE-LOCK ~
    ~{&SORTBY-PHRASE}
&Scoped-define OPEN-QUERY-br_table OPEN QUERY br_table FOR EACH tt-rat-saldo-terc WHERE ~{&KEY-PHRASE} SHARE-LOCK ~
    ~{&SORTBY-PHRASE}.
&Scoped-define TABLES-IN-QUERY-br_table tt-rat-saldo-terc
&Scoped-define FIRST-TABLE-IN-QUERY-br_table tt-rat-saldo-terc


/* Definitions for FRAME F-Main                                         */

/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS br_table RECT-3 RECT-4 
&Scoped-Define DISPLAYED-OBJECTS c-cod-depos c-desc-dep c-cod-localiz ~
c-lote da-dt-vali-lote de-quantidade de-tot-inf de-saldo-rest 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _XFTR "Foreign Keys" B-table-Win _INLINE
/* Actions: ? adm/support/keyedit.w ? ? ? */
/* STRUCTURED-DATA
<KEY-OBJECT>
&BROWSE-NAME
</KEY-OBJECT>
<FOREIGN-KEYS>
</FOREIGN-KEYS>
<EXECUTING-CODE>
**************************
* Set attributes related to FOREIGN KEYS
*/
RUN set-attribute-list (
    'Keys-Accepted = "",
     Keys-Supplied = ""':U).
/**************************
</EXECUTING-CODE> */   

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _XFTR "Advanced Query Options" B-table-Win _INLINE
/* Actions: ? adm/support/advqedit.w ? ? ? */
/* STRUCTURED-DATA
<KEY-OBJECT>
&BROWSE-NAME
</KEY-OBJECT>
<SORTBY-OPTIONS>
</SORTBY-OPTIONS> 
<SORTBY-RUN-CODE>
************************
* Set attributes related to SORTBY-OPTIONS */
RUN set-attribute-list (
    'SortBy-Options = ""':U).
/************************
</SORTBY-RUN-CODE> 
<FILTER-ATTRIBUTES>
</FILTER-ATTRIBUTES> */   

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* ***********************  Control Definitions  ********************** */


/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-can 
     IMAGE-UP FILE "image\im-can":U
     IMAGE-INSENSITIVE FILE "image\ii-can":U
     LABEL "Ca&n" 
     SIZE 4 BY 1.25
     FONT 4.

DEFINE BUTTON bt-elimina 
     LABEL "&Elimina" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-inclui 
     LABEL "&Inclui" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-modifica 
     LABEL "&Modifica" 
     SIZE 10 BY 1
     BGCOLOR 8 .

DEFINE BUTTON bt-sav 
     IMAGE-UP FILE "image\im-sav":U
     IMAGE-INSENSITIVE FILE "image\ii-sav":U
     LABEL "&Sav" 
     SIZE 4 BY 1.25
     FONT 4.

DEFINE VARIABLE c-cod-depos AS CHARACTER FORMAT "X(3)":U 
     LABEL "" 
     VIEW-AS FILL-IN 
     SIZE 4.57 BY .88 NO-UNDO.

DEFINE VARIABLE c-cod-localiz AS CHARACTER FORMAT "X(10)":U 
     LABEL "" 
     VIEW-AS FILL-IN 
     SIZE 16 BY .88 NO-UNDO.

DEFINE VARIABLE c-desc-dep AS CHARACTER FORMAT "X(256)":U 
     VIEW-AS FILL-IN 
     SIZE 25 BY .88 NO-UNDO.

DEFINE VARIABLE c-lote AS CHARACTER FORMAT "X(40)":U 
     LABEL "" 
     VIEW-AS FILL-IN 
     SIZE 14 BY .88 NO-UNDO.

DEFINE VARIABLE da-dt-vali-lote AS DATE FORMAT "99/99/9999":U 
     LABEL "" 
     VIEW-AS FILL-IN 
     SIZE 14 BY .88 NO-UNDO.

DEFINE VARIABLE de-quantidade AS DECIMAL FORMAT "->>>,>>>,>>9.9999":U INITIAL 0 
     LABEL "" 
     VIEW-AS FILL-IN 
     SIZE 20.14 BY .88 NO-UNDO.

DEFINE VARIABLE de-saldo-rest AS DECIMAL FORMAT "->>>,>>>,>>9.9999":U INITIAL 0 
     LABEL "" 
     VIEW-AS FILL-IN 
     SIZE 19.14 BY .88 NO-UNDO.

DEFINE VARIABLE de-tot-inf AS DECIMAL FORMAT "->>>,>>>,>>9.9999":U INITIAL 0 
     LABEL "" 
     VIEW-AS FILL-IN 
     SIZE 19.14 BY .88 NO-UNDO.

DEFINE RECTANGLE RECT-3
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 44.57 BY 6.25.

DEFINE RECTANGLE RECT-4
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 44.57 BY 2.46.

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br_table FOR 
      tt-rat-saldo-terc SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br_table
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br_table B-table-Win _STRUCTURED
  QUERY br_table SHARE-LOCK NO-WAIT DISPLAY
      tt-rat-saldo-terc.cod-depos
      tt-rat-saldo-terc.cod-localiz
      tt-rat-saldo-terc.lote WIDTH 7
      tt-rat-saldo-terc.dt-vali-lote
      tt-rat-saldo-terc.quantidade
      tt-rat-saldo-terc.it-codigo
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH NO-ASSIGN SEPARATORS SIZE 39.72 BY 8.75.


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME F-Main
     br_table AT ROW 1 COL 1
     c-cod-depos AT ROW 1.63 COL 53 COLON-ALIGNED
     c-desc-dep AT ROW 1.63 COL 59.72 NO-LABEL
     c-cod-localiz AT ROW 2.63 COL 53 COLON-ALIGNED
     c-lote AT ROW 3.63 COL 53 COLON-ALIGNED
     da-dt-vali-lote AT ROW 4.63 COL 53 COLON-ALIGNED
     de-quantidade AT ROW 5.63 COL 53 COLON-ALIGNED
     de-tot-inf AT ROW 7.67 COL 53 COLON-ALIGNED
     bt-can AT ROW 8 COL 75.86
     bt-sav AT ROW 8 COL 79.86
     de-saldo-rest AT ROW 8.67 COL 53 COLON-ALIGNED
     bt-inclui AT ROW 9.92 COL 1
     bt-modifica AT ROW 9.92 COL 11.29
     bt-elimina AT ROW 9.92 COL 21.57
     RECT-3 AT ROW 1 COL 41.43
     RECT-4 AT ROW 7.38 COL 41.43
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1 SCROLLABLE 
         BGCOLOR 8 FGCOLOR 0 .


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: SmartBrowser
   External Tables: movind.saldo-terc
   Allow: Basic,Browse
   Frames: 1
   Add Fields to: EXTERNAL-TABLES
   Other Settings: PERSISTENT-ONLY
   Temp-Tables and Buffers:
      TABLE: tt-rat-saldo-terc T "?" NO-UNDO movind rat-saldo-terc
      ADDITIONAL-FIELDS:
          field r-rowid as rowid
      END-FIELDS.
   END-TABLES.
 */

/* This procedure should always be RUN PERSISTENT.  Report the error,  */
/* then cleanup and return.                                            */
IF NOT THIS-PROCEDURE:PERSISTENT THEN DO:
  MESSAGE "{&FILE-NAME} should only be RUN PERSISTENT.":U
          VIEW-AS ALERT-BOX ERROR BUTTONS OK.
  RETURN.
END.

&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
/* DESIGN Window definition (used by the UIB) 
  CREATE WINDOW B-table-Win ASSIGN
         HEIGHT             = 10
         WIDTH              = 85.29.
/* END WINDOW DEFINITION */
                                                                        */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB B-table-Win 
/* ************************* Included-Libraries *********************** */

{src/adm/method/browser.i}
{include/c-browse.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW B-table-Win
  NOT-VISIBLE,,RUN-PERSISTENT                                           */
/* SETTINGS FOR FRAME F-Main
   NOT-VISIBLE FRAME-NAME Size-to-Fit                                   */
/* BROWSE-TAB br_table 1 F-Main */
ASSIGN 
       FRAME F-Main:SCROLLABLE       = FALSE
       FRAME F-Main:HIDDEN           = TRUE.

/* SETTINGS FOR BUTTON bt-can IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-elimina IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-inclui IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-modifica IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR BUTTON bt-sav IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN c-cod-depos IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN c-cod-localiz IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN c-desc-dep IN FRAME F-Main
   NO-ENABLE ALIGN-L                                                    */
/* SETTINGS FOR FILL-IN c-lote IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN da-dt-vali-lote IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN de-quantidade IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN de-saldo-rest IN FRAME F-Main
   NO-ENABLE                                                            */
/* SETTINGS FOR FILL-IN de-tot-inf IN FRAME F-Main
   NO-ENABLE                                                            */
/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br_table
/* Query rebuild information for BROWSE br_table
     _TblList          = "Temp-Tables.tt-rat-saldo-terc"
     _Options          = "SHARE-LOCK KEY-PHRASE SORTBY-PHRASE"
     _FldNameList[1]   = Temp-Tables.tt-rat-saldo-terc.cod-depos
     _FldNameList[2]   = Temp-Tables.tt-rat-saldo-terc.cod-localiz
     _FldNameList[3]   > Temp-Tables.tt-rat-saldo-terc.lote
"Temp-Tables.tt-rat-saldo-terc.lote" ? ? "character" ? ? ? ? ? ? no ? no no "7" yes no no "U" "" "" "" "" "" "" 0 no 0 no no
     _FldNameList[4]   = Temp-Tables.tt-rat-saldo-terc.dt-vali-lote
     _FldNameList[5]   = Temp-Tables.tt-rat-saldo-terc.quantidade
     _FldNameList[6]   = Temp-Tables.tt-rat-saldo-terc.it-codigo
     _Query            is NOT OPENED
*/  /* BROWSE br_table */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME F-Main
/* Query rebuild information for FRAME F-Main
     _Options          = "NO-LOCK"
     _Query            is NOT OPENED
*/  /* FRAME F-Main */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define BROWSE-NAME br_table
&Scoped-define SELF-NAME br_table
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br_table B-table-Win
ON ROW-ENTRY OF br_table IN FRAME F-Main
DO:
  /* This code displays initial values for newly added or copied rows. */
  {src/adm/template/brsentry.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br_table B-table-Win
ON ROW-LEAVE OF br_table IN FRAME F-Main
DO:
    /* Do not disable this code or no updates will take place except
     by pressing the Save button on an Update SmartPanel. */
   {src/adm/template/brsleave.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br_table B-table-Win
ON VALUE-CHANGED OF br_table IN FRAME F-Main
DO:
  /* This ADM trigger code must be preserved in order to notify other
     objects when the browser's current row changes. */
  {src/adm/template/brschnge.i}
  RUN pi-display-fields.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-can
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-can B-table-Win
ON CHOOSE OF bt-can IN FRAME F-Main /* Can */
DO:
  RUN pi-enable-buttons(INPUT yes).  
  RUN pi-disable-fields.
  RUN pi-display-fields.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-elimina
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-elimina B-table-Win
ON CHOOSE OF bt-elimina IN FRAME F-Main /* Elimina */
DO:
    IF AVAIL tt-rat-saldo-terc THEN DO:
        DELETE tt-rat-saldo-terc.
        RUN pi-atualiza-saldo-rest.

        open query br_table for each tt-rat-saldo-terc.
        APPLY "VALUE-CHANGED":U TO br_table.
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-inclui
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-inclui B-table-Win
ON CHOOSE OF bt-inclui IN FRAME F-Main /* Inclui */
DO:
  RUN pi-enable-fields.
  
  RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT this-procedure, INPUT "cod-estabel":U).
  assign vcod-estabel = return-value.
  RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT this-procedure, INPUT "it-codigo":U).
  assign vit-codigo = return-value.
  FIND FIRST item-uni-estab WHERE item-uni-estab.cod-estabel = vcod-estabel 
                              AND item-uni-estab.it-codigo   = vit-codigo NO-LOCK NO-ERROR.
  IF AVAIL item-uni-estab THEN DO:
    assign c-cod-depos:screen-value   in frame {&frame-name} = item-uni-estab.deposito-pad
           c-cod-localiz:screen-value in frame {&frame-name} = item-uni-estab.cod-localiz.
    apply "leave" to c-cod-depos in frame {&frame-name}.
  END.
  
  assign c-lote:screen-value          in frame {&frame-name} = ""
         da-dt-vali-lote:screen-value in frame {&frame-name} = ""
         de-quantidade:screen-value   in frame {&frame-name} = STRING(de-saldo-rest)
         i-oper = 1.

  apply "entry" to c-cod-depos in frame {&frame-name}.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-modifica
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-modifica B-table-Win
ON CHOOSE OF bt-modifica IN FRAME F-Main /* Modifica */
DO:
    IF AVAIL tt-rat-saldo-terc THEN DO:
        ASSIGN i-oper = 2.
        RUN pi-enable-fields.
    END.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-sav
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-sav B-table-Win
ON CHOOSE OF bt-sav IN FRAME F-Main /* Sav */
DO:
    find deposito where
       deposito.cod-depos =  input frame {&frame-name} c-cod-depos no-lock no-error.
    if not avail deposito then do:
       {utp/ut-field.i mgind deposito cod-depos 1}
       run utp/ut-msgs.p (input "show":u, input 2, input return-value).
       apply "entry" to c-cod-depos in frame {&frame-name}.
       return no-apply.
    end.   

    find first localizacao 
         where localizacao.cod-localiz = input frame {&frame-name} c-cod-localiz 
         and   localizacao.cod-depos   = input frame {&frame-name} c-cod-depos no-lock no-error.
    if not avail localizacao then do:
        run utp/ut-msgs.p (input "show",
                           input 16687,           
                           input "").
        apply "entry" to c-cod-localiz in frame {&frame-name}.
        return no-apply.
    end.

    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT this-procedure, INPUT "cod-estabel":U).
    assign vcod-estabel = return-value.
    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT this-procedure, INPUT "it-codigo":U).
    assign vit-codigo = return-value.

    find item 
        where item.it-codigo = vit-codigo no-lock no-error.

    if  item.tipo-con-est <> 1
    and input frame {&frame-name} c-lote = " " 
    and c-lote:sensitive in frame {&frame-name} = yes then do:
        run utp/ut-msgs.p (input "show":u, input 1818, input return-value).
        apply "entry" to c-lote in frame {&frame-name}.
        return no-apply.
    end.
   
    if  item.tipo-con-est > 2 
      and (input frame {&frame-name} da-dt-vali-lote = ? or
           input frame {&frame-name} da-dt-vali-lote =  " " or
           input frame {&frame-name} da-dt-vali-lote < today) then do:
          run utp/ut-msgs.p (input "show":u, input 1247, input return-value).
          apply "entry" to da-dt-vali-lote in frame {&frame-name}.
          return no-apply.
    end.

    IF i-oper = 1 THEN DO:
        IF CAN-FIND(FIRST tt-rat-saldo-terc
                    WHERE tt-rat-saldo-terc.it-codigo = vit-codigo
                      AND tt-rat-saldo-terc.lote      = INPUT FRAME {&FRAME-NAME} c-lote) THEN DO:
            {utp/ut-liter.i "Lote/S‚rie" *}
            RUN utp/ut-msgs.p(INPUT "show":U, 
                              INPUT 7, 
                              INPUT RETURN-VALUE).
            RETURN NO-APPLY.
        END.
        ELSE
            CREATE tt-rat-saldo-terc.
    END.

    ASSIGN tt-rat-saldo-terc.it-codigo    = vit-codigo
           tt-rat-saldo-terc.cod-depos    = INPUT FRAME {&FRAME-NAME} c-cod-depos
           tt-rat-saldo-terc.cod-localiz  = INPUT FRAME {&FRAME-NAME} c-cod-localiz
           tt-rat-saldo-terc.lote         = INPUT FRAME {&FRAME-NAME} c-lote
           tt-rat-saldo-terc.dt-vali-lote = INPUT FRAME {&FRAME-NAME} da-dt-vali-lote
           tt-rat-saldo-terc.quantidade   = INPUT FRAME {&FRAME-NAME} de-quantidade.
    
    RUN pi-enable-buttons(INPUT YES).
    RUN pi-disable-fields.
    RUN pi-atualiza-saldo-rest.

    open query br_table for each tt-rat-saldo-terc.

    APPLY "VALUE-CHANGED":U TO br_table.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME c-cod-depos
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL c-cod-depos B-table-Win
ON F5 OF c-cod-depos IN FRAME F-Main
DO:
  {include/zoomvar.i &prog-zoom="inzoom/z01in084.w"
                     &campo=c-cod-depos
                     &campo2=c-desc-dep
                     &campozoom=cod-depos
                     &campozoom2=nome}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL c-cod-depos B-table-Win
ON LEAVE OF c-cod-depos IN FRAME F-Main
DO:
  {include/leave.i &tabela=deposito
                   &atributo-ref=nome
                   &variavel-ref=c-desc-dep
                   &where="deposito.cod-depos = input frame {&frame-name} 
                           c-cod-depos"}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL c-cod-depos B-table-Win
ON MOUSE-SELECT-DBLCLICK OF c-cod-depos IN FRAME F-Main
DO:
  APPLY "F5":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME c-cod-localiz
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL c-cod-localiz B-table-Win
ON F5 OF c-cod-localiz IN FRAME F-Main
DO:
  {include/zoomvar.i &prog-zoom="inzoom/z02in189.w"
                     &campo=c-cod-localiz
                     &campozoom=cod-localiz}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL c-cod-localiz B-table-Win
ON MOUSE-SELECT-DBLCLICK OF c-cod-localiz IN FRAME F-Main
DO:
  APPLY "F5":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME c-lote
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL c-lote B-table-Win
ON F5 OF c-lote IN FRAME F-Main
DO:
  {include/zoomvar.i &prog-zoom="inzoom\z02in403.w"
                     &campo = c-lote
                     &campozoom = lote}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL c-lote B-table-Win
ON MOUSE-SELECT-DBLCLICK OF c-lote IN FRAME F-Main
DO:
  APPLY "F5":U TO SELF.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK B-table-Win 


/* ***************************  Main Block  *************************** */

&IF DEFINED(UIB_IS_RUNNING) <> 0 &THEN          
RUN dispatch IN THIS-PROCEDURE ('initialize':U).        
&ENDIF

if c-cod-depos:load-mouse-pointer("image/lupa.cur")   then .
if c-cod-localiz:load-mouse-pointer("image/lupa.cur") then .
if c-lote:load-mouse-pointer("image/lupa.cur") then .

/************************ INTERNAL PROCEDURES ********************/

{utp/ut-field.i mgind deposito cod-depos 1}
assign c-cod-depos:label in frame {&frame-name}     = return-value.
{utp/ut-field.i mgind localizacao cod-localiz 1}
assign c-cod-localiz:label in frame {&frame-name}   = return-value.
{utp/ut-field.i mgind movto-estoq lote 1}
assign c-lote:label in frame {&frame-name}          = return-value.
{utp/ut-liter.i Validade * L}
assign da-dt-vali-lote:label in frame {&frame-name} = return-value.
{utp/ut-field.i mgind movto-estoq quantidade 1}
assign de-quantidade:label in frame {&frame-name}   = return-value.
{utp/ut-liter.i Total_Informado * L}
assign de-tot-inf:label in frame {&frame-name}      = return-value.
{utp/ut-liter.i Saldo_Restante * L}
assign de-saldo-rest:label in frame {&frame-name}   = return-value.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available B-table-Win  _ADM-ROW-AVAILABLE
PROCEDURE adm-row-available :
/*------------------------------------------------------------------------------
  Purpose:     Dispatched to this procedure when the Record-
               Source has a new row available.  This procedure
               tries to get the new row (or foriegn keys) from
               the Record-Source and process it.
  Parameters:  <none>
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.             */
  {src/adm/template/row-head.i}

  /* Create a list of all the tables that we need to get.            */
  {src/adm/template/row-list.i "saldo-terc"}

  /* Get the record ROWID's from the RECORD-SOURCE.                  */
  {src/adm/template/row-get.i}

  /* FIND each record specified by the RECORD-SOURCE.                */
  {src/adm/template/row-find.i "saldo-terc"}

  /* Process the newly available records (i.e. display fields,
     open queries, and/or pass records on to any RECORD-TARGETS).    */
  {src/adm/template/row-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI B-table-Win  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Hide all frames. */
  HIDE FRAME F-Main.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-display-fields B-table-Win 
PROCEDURE local-display-fields :
/*------------------------------------------------------------------------------
  Purpose:     Override standard ADM method
  Notes:       
------------------------------------------------------------------------------*/

  /* Code placed here will execute PRIOR to standard behavior. */
  FOR EACH tt-rat-saldo-terc:
      DELETE tt-rat-saldo-terc.
  END.
  
  /* Dispatch standard ADM method.                             */
  RUN dispatch IN THIS-PROCEDURE ( INPUT 'display-fields':U ) .

  /* Code placed here will execute AFTER standard behavior.    */
  
  IF AVAIL saldo-terc THEN DO:
      FOR EACH rat-saldo-terc 
         WHERE rat-saldo-terc.serie-docto  = saldo-terc.serie-docto
           AND rat-saldo-terc.nro-docto    = saldo-terc.nro-docto
           AND rat-saldo-terc.nat-operacao = saldo-terc.nat-operacao
           AND rat-saldo-terc.cod-emitente = saldo-terc.cod-emitente
           AND rat-saldo-terc.it-codigo    = saldo-terc.it-codigo
           AND rat-saldo-terc.cod-estabel  = saldo-terc.cod-estabel
           AND rat-saldo-terc.cod-refer    = saldo-terc.cod-refer 
           AND rat-saldo-terc.sequencia    = saldo-terc.sequencia no-lock:
          CREATE tt-rat-saldo-terc.
          BUFFER-COPY rat-saldo-terc TO tt-rat-saldo-terc.
      END.
  END.

  RUN pi-display-fields.
  RUN pi-atualiza-saldo-rest.

  open query br_table for each tt-rat-saldo-terc.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-add-record B-table-Win 
PROCEDURE pi-add-record :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT THIS-PROCEDURE, INPUT "cod-emitente":U).
    ASSIGN vcod-emitente = int(RETURN-VALUE).
    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT THIS-PROCEDURE, INPUT "serie-docto":U).
    ASSIGN vserie-docto = RETURN-VALUE.
    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT THIS-PROCEDURE, INPUT "nro-docto":U).
    ASSIGN vnro-docto = RETURN-VALUE.
    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT THIS-PROCEDURE, INPUT "nat-operacao":U).
    ASSIGN vnat-operacao = RETURN-VALUE.
    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT THIS-PROCEDURE, INPUT "cod-refer":U).
    ASSIGN vcod-refer = RETURN-VALUE.
    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT THIS-PROCEDURE, INPUT "cod-estabel":U).
    ASSIGN vcod-estabel = RETURN-VALUE.
    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT THIS-PROCEDURE, INPUT "it-codigo":U).
    ASSIGN vit-codigo = RETURN-VALUE.
    RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT THIS-PROCEDURE, INPUT "sequencia":U).
    ASSIGN vsequencia = int(RETURN-VALUE).


    FOR FIRST item FIELDS(tipo-con-est)
            WHERE item.it-codigo = vit-codigo NO-LOCK: END.

    IF AVAIL item AND item.tipo-con-est <> 1 THEN DO:
    
        IF AVAIL saldo-terc THEN DO:
    
                FIND FIRST tt-rat-saldo-terc NO-ERROR.
                
                IF AVAIL tt-rat-saldo-terc THEN DO:
            
                    FOR EACH tt-rat-saldo-terc:
                        CREATE rat-saldo-terc.
                        ASSIGN rat-saldo-terc.cod-emitente = vcod-emitente
                               rat-saldo-terc.serie-docto  = vserie-docto
                               rat-saldo-terc.nro-docto    = vnro-docto
                               rat-saldo-terc.nat-operacao = vnat-operacao
                               rat-saldo-terc.cod-refer    = vcod-refer
                               rat-saldo-terc.it-codigo    = vit-codigo
                               rat-saldo-terc.sequencia    = vsequencia
                               rat-saldo-terc.cod-estabel  = vcod-estabel
                               rat-saldo-terc.cod-depos    = tt-rat-saldo-terc.cod-depos
                               rat-saldo-terc.cod-localiz  = tt-rat-saldo-terc.cod-localiz
                               rat-saldo-terc.lote         = tt-rat-saldo-terc.lote
                               rat-saldo-terc.dt-vali-lote = tt-rat-saldo-terc.dt-vali-lote
                               rat-saldo-terc.quantidade   = tt-rat-saldo-terc.quantidade
                               rat-saldo-terc.qtd-origin   = tt-rat-saldo-terc.quantidade.
        
                        CREATE rat-componente.
                        ASSIGN rat-componente.cod-emitente = vcod-emitente
                               rat-componente.serie-docto  = vserie-docto
                               rat-componente.nro-docto    = vnro-docto
                               rat-componente.nat-operacao = vnat-operacao
                               rat-componente.cod-refer    = vcod-refer
                               rat-componente.sequencia    = vsequencia
                               rat-componente.it-codigo    = vit-codigo
                               rat-componente.lote         = tt-rat-saldo-terc.lote
                               rat-componente.quantidade   = tt-rat-saldo-terc.quantidade
                               rat-componente.dt-vali-lote = tt-rat-saldo-terc.dt-vali-lote
                               rat-componente.cod-localiz  = tt-rat-saldo-terc.cod-localiz
                               rat-componente.cod-depos    = tt-rat-saldo-terc.cod-depos.
                    END.
                END.
            ELSE DO:
    
                RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT THIS-PROCEDURE, INPUT "quantidade":U).
                ASSIGN vquantidade = DEC(RETURN-VALUE).
                
                RUN pi-get-depos-localiz IN h_re0407-v02 ( OUTPUT vcod-depos,
                                                           OUTPUT vcod-localiz ).
                CREATE rat-saldo-terc.
                ASSIGN rat-saldo-terc.cod-emitente = vcod-emitente
                       rat-saldo-terc.serie-docto  = vserie-docto
                       rat-saldo-terc.nro-docto    = vnro-docto
                       rat-saldo-terc.nat-operacao = vnat-operacao
                       rat-saldo-terc.cod-refer    = vcod-refer
                       rat-saldo-terc.it-codigo    = vit-codigo
                       rat-saldo-terc.sequencia    = vsequencia
                       rat-saldo-terc.cod-estabel  = vcod-estabel
                       rat-saldo-terc.cod-depos    = vcod-depos
                       rat-saldo-terc.cod-localiz  = vcod-localiz
                       rat-saldo-terc.lote         = ""
                       rat-saldo-terc.dt-vali-lote = ?
                       rat-saldo-terc.quantidade   = vquantidade
                       rat-saldo-terc.qtd-origin   = vquantidade.
                       
                CREATE rat-componente.
                ASSIGN rat-componente.cod-emitente = vcod-emitente
                       rat-componente.serie-docto  = vserie-docto
                       rat-componente.nro-docto    = vnro-docto
                       rat-componente.nat-operacao = vnat-operacao
                       rat-componente.cod-refer    = vcod-refer
                       rat-componente.sequencia    = vsequencia
                       rat-componente.it-codigo    = vit-codigo
                       rat-componente.lote         = ""
                       rat-componente.quantidade   = vquantidade
                       rat-componente.dt-vali-lote = ?
                       rat-componente.cod-localiz  = vcod-localiz
                       rat-componente.cod-depos    = vcod-depos.
            END.
        END.
    END.
    

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-atualiza-saldo-rest B-table-Win 
PROCEDURE pi-atualiza-saldo-rest :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT this-procedure, INPUT "quantidade":U).
  ASSIGN de-saldo-rest = DEC(return-value).
         de-tot-inf = 0.

  FOR EACH tt-rat-saldo-terc:
    ASSIGN de-saldo-rest = de-saldo-rest - tt-rat-saldo-terc.quantidade
           de-tot-inf = de-tot-inf + tt-rat-saldo-terc.quantidade.
  END.

  DISP de-saldo-rest
       de-tot-inf WITH FRAME {&FRAME-NAME}.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-disable-fields B-table-Win 
PROCEDURE pi-disable-fields :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  disable bt-sav 
          bt-can 
          c-cod-depos 
          c-cod-localiz
          c-lote
          da-dt-vali-lote
          de-quantidade 
          with frame {&frame-name}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-display-fields B-table-Win 
PROCEDURE pi-display-fields :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  if  avail tt-rat-saldo-terc then do:
    disp tt-rat-saldo-terc.cod-depos    @ c-cod-depos
         tt-rat-saldo-terc.cod-localiz  @ c-cod-localiz
         tt-rat-saldo-terc.lote         @ c-lote
         tt-rat-saldo-terc.dt-vali-lote @ da-dt-vali-lote
         tt-rat-saldo-terc.quantidade   @ de-quantidade
         with frame {&frame-name}.
    
    find first deposito
         where deposito.cod-depos = tt-rat-saldo-terc.cod-depos no-lock no-error.
    if avail deposito then
        disp deposito.nome @ c-desc-dep with frame {&frame-name}.
    else
        disp "" @ c-desc-dep with frame {&frame-name}.
  end.
  ELSE
    disp "" @ c-cod-depos
         "" @ c-cod-localiz
         "" @ c-lote
         "" @ da-dt-vali-lote
         "" @ de-quantidade
         "" @ c-desc-dep
         with frame {&frame-name}.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-enable-buttons B-table-Win 
PROCEDURE pi-enable-buttons :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    DEFINE INPUT  PARAMETER pEnable AS LOGICAL     NO-UNDO.

    IF pEnable THEN 
        enable bt-inclui bt-modifica bt-elimina with frame {&frame-name}.
    ELSE
        disable bt-inclui bt-modifica bt-elimina with frame {&frame-name}.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-enable-fields B-table-Win 
PROCEDURE pi-enable-fields :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

  disable bt-inclui bt-modifica bt-elimina with frame {&frame-name}.
  
  enable  bt-sav 
          bt-can 
          c-cod-depos 
          c-cod-localiz
          de-quantidade 
          with frame {&frame-name}.

      RUN Get-Field-Screen-Value IN adm-broker-hdl (INPUT this-procedure, INPUT "it-codigo":U).
      FIND FIRST ITEM WHERE item.it-codigo = RETURN-VALUE NO-LOCK NO-ERROR.
    
      IF AVAIL ITEM THEN DO:
        if item.tipo-con-est = 2
        or item.tipo-con-est = 3 
        or item.tipo-con-est = 4 then do:
       enable  c-lote
               da-dt-vali-lote with frame {&frame-name}.
    end.
    else do: 
       assign  c-lote:screen-value in frame {&frame-name} = ""
               da-dt-vali-lote:screen-value in frame {&frame-name} = ?.
       disable c-lote
               da-dt-vali-lote with frame {&frame-name}.
    end.
  END.
  ELSE
      enable  c-lote
              da-dt-vali-lote with frame {&frame-name}.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-limpa-browse B-table-Win 
PROCEDURE pi-limpa-browse :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
  
  FOR EACH tt-rat-saldo-terc:
      DELETE tt-rat-saldo-terc.
  END.

  disp "" @ c-cod-depos
       "" @ c-cod-localiz
       "" @ c-lote
       "" @ da-dt-vali-lote
       "" @ de-quantidade
       "" @ c-desc-dep
      with frame {&frame-name}.

  RUN pi-atualiza-saldo-rest.

  open query br_table for each tt-rat-saldo-terc.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-passa-handle-v02 B-table-Win 
PROCEDURE pi-passa-handle-v02 :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    def input parameter p-handle as handle.

    assign h_re0407-v02 = p-handle.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-total-informado B-table-Win 
PROCEDURE pi-total-informado :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

    DEFINE OUTPUT PARAMETER de-total-informado AS DECIMAL     NO-UNDO.

    ASSIGN de-total-informado = INPUT FRAME {&FRAME-NAME} de-tot-inf.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-validate B-table-Win 
PROCEDURE pi-validate :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
    DEFINE VARIABLE c-msg AS CHARACTER NO-UNDO.
    DEFINE VARIABLE c-msg2 AS CHARACTER NO-UNDO.
    
    {utp/ut-liter.i Total_Informado *}
    assign c-msg = RETURN-VALUE.
    
    {utp/ut-liter.i da_Quantidade_informada_para_o_Item *}
    assign c-msg2 = RETURN-VALUE.
    
    IF  CAN-FIND(FIRST tt-rat-saldo-terc)
    AND DEC(de-saldo-rest:SCREEN-VALUE IN FRAME {&FRAME-NAME}) <> 0 THEN DO:
        run utp/ut-msgs.p (input "show":U, input 33090, input c-msg + "~~":U + c-msg2
                                                     + "~~":U + c-msg + "~~" + c-msg2).
        RETURN "NOK":U.
    END.

    RETURN "OK":U.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records B-table-Win  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "saldo-terc"}
  {src/adm/template/snd-list.i "tt-rat-saldo-terc"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed B-table-Win 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE    NO-UNDO.
  DEFINE INPUT PARAMETER p-state      AS CHARACTER NO-UNDO.

  CASE p-state:
      /* Object instance CASEs can go here to replace standard behavior
         or add new cases. */
      {src/adm/template/bstates.i}
  END CASE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

