&ANALYZE-SUSPEND _VERSION-NUMBER UIB_v8r12 GUI ADM1
&ANALYZE-RESUME
/* Connected Databases 
          mgadm            PROGRESS
          movind           PROGRESS
*/
&Scoped-define WINDOW-NAME C-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _DEFINITIONS C-Win 
/********************************************************************************
** Copyright DATASUL S.A. (1997)
** Todos os Direitos Reservados.
**
** Este fonte e de propriedade exclusiva da DATASUL, sua reproducao
** parcial ou total por qualquer meio, so podera ser feita mediante
** autorizacao expressa.
*******************************************************************************/
{include/i-prgvrs.i RE0404 2.00.00.018 } /*** 010018 ***/


&IF "{&EMSFND_VERSION}" >= "1.00" &THEN
    {include/i-license-manager.i re0404 MRE}
&ENDIF

/*------------------------------------------------------------------------

  File: 

  Description: 

  Input Parameters:
      <none>

  Output Parameters:
      <none>

  Author: 

  Created: 

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

/* Preprocessadores do Template de Relat¢rio                            */
/* Obs: Retirar o valor do preprocessador para as p ginas que nÆo existirem  */

&GLOBAL-DEFINE PGSEL f-pg-sel
&GLOBAL-DEFINE PGCLA
&GLOBAL-DEFINE PGPAR
&GLOBAL-DEFINE PGDIG f-pg-dig
&GLOBAL-DEFINE PGIMP f-pg-imp

/*** Pr‚-processors definitions ***/
{cdp/cdcfgmat.i}
{cdp/cd0031.i "MRE"} /*Seguranca por Estabelecimento*/
/**********************************/

/* Parameters Definitions ---                                           */

/* Temporary Table Definitions ---                                      */

define temp-table tt-param
    field destino     as integer
    field arquivo     as char
    field usuario     as char format "x(12)"
    field data-exec   as date
    field hora-exec   as integer
    field da-data-i   as date format "99/99/9999"
    field da-data-f   as date format "99/99/9999"
&if defined(bf_mat_selecao_estab_re) &then    
    field c-est-ini   like lin-i-ap.cod-estabel
    field c-est-fim   like lin-i-ap.cod-estabel
&endif
    field i-opcao     as integer
    field c-opcao     as char format "x(20)"
    field c-destino   as char format "x(40)"
    field l-imp-param as log.

define temp-table tt-digita
    field flag       as logical format "*/"
    field Data       as char    format "x(5)"
    field Hora       as char    format "x(5)"
    field Arquivo    as char    format "x(30)"
    field ep-codigo  like lin-i-ap.ep-codigo
    field estab-i    like lin-i-ap.cod-estabel format "x(7)"
    field estab-f    like lin-i-ap.cod-estabel format "x(7)"
    field cod-esp    like doc-i-ap.cod-esp
    field referencia like doc-i-ap.referencia
    index id-digita is primary data.

define buffer b-tt-digita    for tt-digita.

/* Transfer Definitions */

def var raw-param        as raw no-undo.

def temp-table tt-raw-digita
   field raw-digita      as raw.

/* Local Variable Definitions ---                                       */

def var l-ok               as logical no-undo.
def var c-arq-digita       as char    no-undo.
def var c-terminal         as char    no-undo.
&IF "{&mguni_version}" >= "2.071" &THEN
    def var i-empresa      like empresa.ep-codigo.
&ELSE
    def var i-empresa      as integer no-undo.
&ENDIF

def var l-deleta           as logical no-undo.

def var r-digita           as rowid   no-undo.
def var i-ref              as integer no-undo.

def var c-lit-marca        as char    no-undo.
def var c-lit-desmarca     as char    no-undo.
def var c-arqexporta       as char    no-undo.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-PREPROCESSOR-BLOCK 

/* ********************  Preprocessor Definitions  ******************** */

&Scoped-define PROCEDURE-TYPE w-relat
&Scoped-define DB-AWARE no

/* Name of designated FRAME-NAME and/or first browse and/or first query */
&Scoped-define FRAME-NAME f-pg-dig
&Scoped-define BROWSE-NAME br-digita

/* Internal Tables (found by Frame, Query & Browse Queries)             */
&Scoped-define INTERNAL-TABLES tt-digita docum-est

/* Definitions for BROWSE br-digita                                     */
&Scoped-define FIELDS-IN-QUERY-br-digita tt-digita.estab-i tt-digita.estab-f tt-digita.ep-codigo tt-digita.arquivo   
&Scoped-define ENABLED-FIELDS-IN-QUERY-br-digita tt-digita.estab-i ~
tt-digita.estab-f ~
tt-digita.ep-codigo ~
tt-digita.arquivo   
&Scoped-define ENABLED-TABLES-IN-QUERY-br-digita tt-digita
&Scoped-define FIRST-ENABLED-TABLE-IN-QUERY-br-digita tt-digita
&Scoped-define SELF-NAME br-digita
&Scoped-define QUERY-STRING-br-digita FOR EACH tt-digita
&Scoped-define OPEN-QUERY-br-digita OPEN QUERY br-digita FOR EACH tt-digita.
&Scoped-define TABLES-IN-QUERY-br-digita tt-digita
&Scoped-define FIRST-TABLE-IN-QUERY-br-digita tt-digita


/* Definitions for FRAME f-pg-dig                                       */
&Scoped-define OPEN-BROWSERS-IN-QUERY-f-pg-dig ~
    ~{&OPEN-QUERY-br-digita}

/* Definitions for FRAME f-pg-sel                                       */
&Scoped-define QUERY-STRING-f-pg-sel FOR EACH docum-est SHARE-LOCK
&Scoped-define OPEN-QUERY-f-pg-sel OPEN QUERY f-pg-sel FOR EACH docum-est SHARE-LOCK.
&Scoped-define TABLES-IN-QUERY-f-pg-sel docum-est
&Scoped-define FIRST-TABLE-IN-QUERY-f-pg-sel docum-est


/* Standard List Definitions                                            */
&Scoped-Define ENABLED-OBJECTS br-digita bt-inserir bt-alterar bt-retirar ~
bt-salvar bt-recuperar 

/* Custom List Definitions                                              */
/* List-1,List-2,List-3,List-4,List-5,List-6                            */

/* _UIB-PREPROCESSOR-BLOCK-END */
&ANALYZE-RESUME



/* ***********************  Control Definitions  ********************** */

/* Define the widget handle for the window                              */
DEFINE VAR C-Win AS WIDGET-HANDLE NO-UNDO.

/* Definitions of the field level widgets                               */
DEFINE BUTTON bt-alterar 
     LABEL "Alterar" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-inserir 
     LABEL "Inserir" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-recuperar 
     LABEL "Recuperar" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-retirar 
     LABEL "Retirar" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-salvar 
     LABEL "Salvar" 
     SIZE 15 BY 1.

DEFINE BUTTON bt-arquivo 
     IMAGE-UP FILE "image\im-sea":U
     IMAGE-INSENSITIVE FILE "image\ii-sea":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE BUTTON bt-config-impr 
     IMAGE-UP FILE "image\im-cfprt":U
     LABEL "" 
     SIZE 4 BY 1.

DEFINE VARIABLE c-arquivo AS CHARACTER 
     VIEW-AS EDITOR MAX-CHARS 256
     SIZE 40 BY .88
     BGCOLOR 15  NO-UNDO.

DEFINE VARIABLE text-destino AS CHARACTER FORMAT "X(256)":U INITIAL " Destino" 
      VIEW-AS TEXT 
     SIZE 8.57 BY .63 NO-UNDO.

DEFINE VARIABLE text-modo AS CHARACTER FORMAT "X(256)":U INITIAL "Execu‡Æo" 
      VIEW-AS TEXT 
     SIZE 10.86 BY .63 NO-UNDO.

DEFINE VARIABLE text-parametro AS CHARACTER FORMAT "X(256)":U INITIAL "Parƒmetros de ImpressÆo" 
      VIEW-AS TEXT 
     SIZE 19.72 BY .63 NO-UNDO.

DEFINE VARIABLE rs-destino AS INTEGER INITIAL 2 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "Impressora", 1,
"Arquivo", 2,
"Terminal", 3
     SIZE 44 BY 1.08 NO-UNDO.

DEFINE VARIABLE rs-execucao AS INTEGER INITIAL 1 
     VIEW-AS RADIO-SET HORIZONTAL
     RADIO-BUTTONS 
          "On-Line", 1,
"Batch", 2
     SIZE 27.72 BY .92 NO-UNDO.

DEFINE RECTANGLE RECT-11
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 46.29 BY 2.13.

DEFINE RECTANGLE RECT-7
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 46.29 BY 2.92.

DEFINE RECTANGLE RECT-9
     EDGE-PIXELS 2 GRAPHIC-EDGE  NO-FILL   
     SIZE 46.29 BY 1.71.

DEFINE VARIABLE tb-imprimir-parametro AS LOGICAL INITIAL yes 
     LABEL "Imprimir parƒmetros" 
     VIEW-AS TOGGLE-BOX
     SIZE 17 BY .83 NO-UNDO.

DEFINE VARIABLE c-estab-fim LIKE estabelec.cod-estabel
     VIEW-AS FILL-IN 
     SIZE 7.14 BY 1 NO-UNDO.

DEFINE VARIABLE c-estab-ini LIKE estabelec.cod-estabel
     LABEL "Estabelecimento":R7 
     VIEW-AS FILL-IN 
     SIZE 7.14 BY 1 NO-UNDO.

DEFINE VARIABLE da-data-f AS DATE FORMAT "99/99/9999" INITIAL 12/31/9999 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88.

DEFINE VARIABLE da-data-i AS DATE FORMAT "99/99/9999" INITIAL 01/01/001 
     LABEL "Data Transa‡Æo":R17 
     VIEW-AS FILL-IN 
     SIZE 13 BY .88.

DEFINE IMAGE IMAGE-1
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-2
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-3
     FILENAME "image\im-fir":U
     SIZE 3 BY .88.

DEFINE IMAGE IMAGE-4
     FILENAME "image\im-las":U
     SIZE 3 BY .88.

DEFINE BUTTON bt-ajuda 
     LABEL "Ajuda" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-cancelar AUTO-END-KEY 
     LABEL "Cancelar" 
     SIZE 10 BY 1.

DEFINE BUTTON bt-executar 
     LABEL "Executar" 
     SIZE 10 BY 1.

DEFINE IMAGE im-pg-dig
     FILENAME "image\im-fldup":U
     SIZE 15.72 BY 1.21.

DEFINE IMAGE im-pg-imp
     FILENAME "image\im-fldup":U
     SIZE 15.72 BY 1.21.

DEFINE IMAGE im-pg-sel
     FILENAME "image\im-fldup":U
     SIZE 15.72 BY 1.21.

DEFINE RECTANGLE RECT-1
     EDGE-PIXELS 2 GRAPHIC-EDGE    
     SIZE 79 BY 1.42
     BGCOLOR 7 .

DEFINE RECTANGLE RECT-6
     EDGE-PIXELS 0    
     SIZE 78.72 BY .13
     BGCOLOR 7 .

DEFINE RECTANGLE rt-folder
     EDGE-PIXELS 1 GRAPHIC-EDGE  NO-FILL   
     SIZE 79 BY 11.38
     FGCOLOR 0 .

DEFINE RECTANGLE rt-folder-left
     EDGE-PIXELS 0    
     SIZE .43 BY 11.21
     BGCOLOR 15 .

DEFINE RECTANGLE rt-folder-right
     EDGE-PIXELS 0    
     SIZE .43 BY 11.17
     BGCOLOR 7 .

DEFINE RECTANGLE rt-folder-top
     EDGE-PIXELS 0    
     SIZE 78.72 BY .13
     BGCOLOR 15 .

/* Query definitions                                                    */
&ANALYZE-SUSPEND
DEFINE QUERY br-digita FOR 
      tt-digita SCROLLING.

DEFINE QUERY f-pg-sel FOR 
      docum-est SCROLLING.
&ANALYZE-RESUME

/* Browse definitions                                                   */
DEFINE BROWSE br-digita
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _DISPLAY-FIELDS br-digita C-Win _FREEFORM
  QUERY br-digita DISPLAY
      tt-digita.estab-i
      tt-digita.estab-f
      tt-digita.ep-codigo
      tt-digita.arquivo
ENABLE
      tt-digita.estab-i
      tt-digita.estab-f
      tt-digita.ep-codigo
      tt-digita.arquivo
/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME
    WITH SEPARATORS SIZE 75 BY 9.38
         BGCOLOR 15 .


/* ************************  Frame Definitions  *********************** */

DEFINE FRAME f-relat
     bt-executar AT ROW 14.54 COL 3 HELP
          "Dispara a execu‡Æo do relat¢rio"
     bt-cancelar AT ROW 14.54 COL 14 HELP
          "Cancelar"
     bt-ajuda AT ROW 14.54 COL 70 HELP
          "Ajuda"
     RECT-1 AT ROW 14.29 COL 2
     RECT-6 AT ROW 13.75 COL 2.14
     rt-folder-right AT ROW 2.67 COL 80.43
     rt-folder AT ROW 2.5 COL 2
     rt-folder-top AT ROW 2.54 COL 2.14
     rt-folder-left AT ROW 2.54 COL 2.14
     im-pg-dig AT ROW 1.5 COL 17.86
     im-pg-imp AT ROW 1.5 COL 33.57
     im-pg-sel AT ROW 1.5 COL 2.14
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 1 ROW 1
         SIZE 81 BY 15
         DEFAULT-BUTTON bt-executar.

DEFINE FRAME f-pg-dig
     br-digita AT ROW 1 COL 2
     bt-inserir AT ROW 10.42 COL 2
     bt-alterar AT ROW 10.42 COL 17
     bt-retirar AT ROW 10.42 COL 32
     bt-salvar AT ROW 10.42 COL 47
     bt-recuperar AT ROW 10.42 COL 62
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 3
         SIZE 76.5 BY 10.5.

DEFINE FRAME f-pg-sel
     da-data-i AT ROW 2 COL 19.86 COLON-ALIGNED
     da-data-f AT ROW 2 COL 45 COLON-ALIGNED NO-LABEL
     c-estab-ini AT ROW 3.46 COL 19.86 COLON-ALIGNED HELP
          ""
          LABEL "Estabelecimento":R7
     c-estab-fim AT ROW 3.46 COL 45 COLON-ALIGNED HELP
          "" NO-LABEL
     IMAGE-1 AT ROW 2.08 COL 35
     IMAGE-2 AT ROW 2.08 COL 44
     IMAGE-3 AT ROW 3.46 COL 35
     IMAGE-4 AT ROW 3.46 COL 44
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 3
         SIZE 76.5 BY 10.5.

DEFINE FRAME f-pg-imp
     rs-destino AT ROW 2.38 COL 3.29 HELP
          "Destino de ImpressÆo do Relat¢rio" NO-LABEL
     bt-arquivo AT ROW 3.58 COL 43.29 HELP
          "Escolha do nome do arquivo"
     bt-config-impr AT ROW 3.58 COL 43.29 HELP
          "Configura‡Æo da impressora"
     c-arquivo AT ROW 3.63 COL 3.29 HELP
          "Nome do arquivo de destino do relat¢rio" NO-LABEL
     rs-execucao AT ROW 5.75 COL 3 HELP
          "Modo de Execu‡Æo" NO-LABEL
     tb-imprimir-parametro AT ROW 8.5 COL 3 WIDGET-ID 4
     text-destino AT ROW 1.63 COL 3.86 NO-LABEL
     text-modo AT ROW 5 COL 1.29 COLON-ALIGNED NO-LABEL
     text-parametro AT ROW 7.58 COL 1.29 COLON-ALIGNED NO-LABEL WIDGET-ID 6
     RECT-7 AT ROW 1.92 COL 2.14
     RECT-9 AT ROW 5.29 COL 2.14
     RECT-11 AT ROW 7.88 COL 2.14 WIDGET-ID 2
    WITH 1 DOWN NO-BOX KEEP-TAB-ORDER OVERLAY 
         SIDE-LABELS NO-UNDERLINE THREE-D 
         AT COL 3 ROW 3
         SIZE 76.5 BY 10.5.


/* *********************** Procedure Settings ************************ */

&ANALYZE-SUSPEND _PROCEDURE-SETTINGS
/* Settings for THIS-PROCEDURE
   Type: w-relat
   Allow: Basic,Browse,DB-Fields,Window,Query
 */
&ANALYZE-RESUME _END-PROCEDURE-SETTINGS

/* *************************  Create Window  ************************** */

&ANALYZE-SUSPEND _CREATE-WINDOW
IF SESSION:DISPLAY-TYPE = "GUI":U THEN
  CREATE WINDOW C-Win ASSIGN
         HIDDEN             = YES
         TITLE              = "Integra‡Æo com Contas a Pagar"
         HEIGHT             = 15
         WIDTH              = 81.14
         MAX-HEIGHT         = 22.33
         MAX-WIDTH          = 114.29
         VIRTUAL-HEIGHT     = 22.33
         VIRTUAL-WIDTH      = 114.29
         RESIZE             = yes
         SCROLL-BARS        = no
         STATUS-AREA        = yes
         BGCOLOR            = ?
         FGCOLOR            = ?
         KEEP-FRAME-Z-ORDER = yes
         THREE-D            = yes
         MESSAGE-AREA       = no
         SENSITIVE          = yes.
ELSE {&WINDOW-NAME} = CURRENT-WINDOW.
/* END WINDOW DEFINITION                                                */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _INCLUDED-LIB C-Win 
/* ************************* Included-Libraries *********************** */

{src/adm/method/containr.i}
{include/w-relat.i}
{utp/ut-glob.i}

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME




/* ***********  Runtime Attributes and AppBuilder Settings  *********** */

&ANALYZE-SUSPEND _RUN-TIME-ATTRIBUTES
/* SETTINGS FOR WINDOW C-Win
  VISIBLE,,RUN-PERSISTENT                                               */
/* SETTINGS FOR FRAME f-pg-dig
   FRAME-NAME                                                           */
/* BROWSE-TAB br-digita 1 f-pg-dig */
/* SETTINGS FOR FRAME f-pg-imp
                                                                        */
/* SETTINGS FOR FILL-IN text-destino IN FRAME f-pg-imp
   NO-DISPLAY NO-ENABLE ALIGN-L                                         */
ASSIGN 
       text-destino:PRIVATE-DATA IN FRAME f-pg-imp     = 
                "Destino".

/* SETTINGS FOR FILL-IN text-modo IN FRAME f-pg-imp
   NO-DISPLAY NO-ENABLE                                                 */
ASSIGN 
       text-modo:PRIVATE-DATA IN FRAME f-pg-imp     = 
                "Execu‡Æo".

/* SETTINGS FOR FILL-IN text-parametro IN FRAME f-pg-imp
   NO-DISPLAY NO-ENABLE                                                 */
ASSIGN 
       text-parametro:PRIVATE-DATA IN FRAME f-pg-imp     = 
                "Parƒmetros de ImpressÆo".

/* SETTINGS FOR FRAME f-pg-sel
                                                                        */
/* SETTINGS FOR FILL-IN c-estab-fim IN FRAME f-pg-sel
   LIKE = mgadm.estabelec.cod-estabel EXP-SIZE                          */
ASSIGN 
       c-estab-fim:HIDDEN IN FRAME f-pg-sel           = TRUE.

/* SETTINGS FOR FILL-IN c-estab-ini IN FRAME f-pg-sel
   LIKE = mgadm.estabelec.cod-estabel EXP-LABEL EXP-SIZE                */
ASSIGN 
       c-estab-ini:HIDDEN IN FRAME f-pg-sel           = TRUE.

ASSIGN 
       IMAGE-3:HIDDEN IN FRAME f-pg-sel           = TRUE.

ASSIGN 
       IMAGE-4:HIDDEN IN FRAME f-pg-sel           = TRUE.

/* SETTINGS FOR FRAME f-relat
                                                                        */
/* SETTINGS FOR RECTANGLE RECT-1 IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE RECT-6 IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder-left IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder-right IN FRAME f-relat
   NO-ENABLE                                                            */
/* SETTINGS FOR RECTANGLE rt-folder-top IN FRAME f-relat
   NO-ENABLE                                                            */
IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(C-Win)
THEN C-Win:HIDDEN = no.

/* _RUN-TIME-ATTRIBUTES-END */
&ANALYZE-RESUME


/* Setting information for Queries and Browse Widgets fields            */

&ANALYZE-SUSPEND _QUERY-BLOCK BROWSE br-digita
/* Query rebuild information for BROWSE br-digita
     _START_FREEFORM
OPEN QUERY br-digita FOR EACH tt-digita.
     _END_FREEFORM
     _Query            is OPENED
*/  /* BROWSE br-digita */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME f-pg-imp
/* Query rebuild information for FRAME f-pg-imp
     _Query            is NOT OPENED
*/  /* FRAME f-pg-imp */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _QUERY-BLOCK FRAME f-pg-sel
/* Query rebuild information for FRAME f-pg-sel
     _TblList          = "movind.docum-est"
     _Query            is NOT OPENED
*/  /* FRAME f-pg-sel */
&ANALYZE-RESUME

 



/* ************************  Control Triggers  ************************ */

&Scoped-define SELF-NAME C-Win
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON END-ERROR OF C-Win /* Integra‡Æo com Contas a Pagar */
OR ENDKEY OF {&WINDOW-NAME} ANYWHERE DO:
  /* This case occurs when the user presses the "Esc" key.
     In a persistently run window, just ignore this.  If we did not, the
     application would exit. */
   RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL C-Win C-Win
ON WINDOW-CLOSE OF C-Win /* Integra‡Æo com Contas a Pagar */
DO:
  /* This event will close the window and terminate the procedure.  */
  APPLY "CLOSE":U TO THIS-PROCEDURE.
  RETURN NO-APPLY.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define BROWSE-NAME br-digita
&Scoped-define SELF-NAME br-digita
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita C-Win
ON DEL OF br-digita IN FRAME f-pg-dig
DO:
   apply 'choose' to bt-retirar in frame f-pg-dig.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita C-Win
ON END-ERROR OF br-digita IN FRAME f-pg-dig
ANYWHERE 
DO:
    if  br-digita:new-row in frame f-pg-dig then do:
        if  avail tt-digita then
            delete tt-digita.
        if  br-digita:delete-current-row() in frame f-pg-dig then. 
    end.                                                               
    else do:
        get current br-digita.
        display tt-digita.estab-i
                tt-digita.estab-f
                tt-digita.ep-codigo
                tt-digita.arquivo with browse br-digita.
    end.
    return no-apply.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita C-Win
ON ENTER OF br-digita IN FRAME f-pg-dig
ANYWHERE
DO:
  apply 'tab' to self.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita C-Win
ON INS OF br-digita IN FRAME f-pg-dig
DO:
   apply 'choose' to bt-inserir in frame f-pg-dig.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita C-Win
ON OFF-END OF br-digita IN FRAME f-pg-dig
DO:
   apply 'entry' to bt-inserir in frame f-pg-dig.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita C-Win
ON OFF-HOME OF br-digita IN FRAME f-pg-dig
DO:
  apply 'entry' to bt-recuperar in frame f-pg-dig.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita C-Win
ON ROW-ENTRY OF br-digita IN FRAME f-pg-dig
DO:
   /* trigger para inicializar campos da temp table de digita‡Æo */
   if  br-digita:new-row in frame f-pg-dig then do:
       assign tt-digita.estab-i:screen-value   in browse br-digita = ""
              tt-digita.estab-f:screen-value   in browse br-digita = ""
              tt-digita.ep-codigo:screen-value in browse br-digita = ""
              tt-digita.arquivo:screen-value   in browse br-digita = "".
   end.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL br-digita C-Win
ON ROW-LEAVE OF br-digita IN FRAME f-pg-dig
DO:
    /* aqui que a grava‡Æo da linha da temp-table ‚ efetivada. EntÆo
       neste gatilho devem ser implementadas as valida‡äes necess rias */

    if  br-digita:new-row in frame f-pg-dig then do transaction on error undo, return no-apply:
	
		/* outras valida‡äes */
        IF  INPUT BROWSE br-digita tt-digita.estab-i <> "":U THEN DO:
            FOR FIRST estabelec FIELDS()
                WHERE estabelec.cod-estabel = INPUT BROWSE br-digita tt-digita.estab-i NO-LOCK: END.            
            IF NOT AVAIL estabelec THEN DO:
                RUN utp/ut-msgs.p ("show", 13, INPUT BROWSE br-digita tt-digita.estab-i).
                APPLY 'mouse-select-click' TO im-pg-dig IN FRAME f-relat.
                APPLY 'entry' TO tt-digita.estab-i IN BROWSE br-digita.
                RETURN NO-APPLY.
            END.    
        END.
        
        IF  INPUT BROWSE br-digita tt-digita.estab-f <> "":U THEN DO:
            FOR FIRST estabelec FIELDS()
                WHERE estabelec.cod-estabel = INPUT BROWSE br-digita tt-digita.estab-f NO-LOCK: END.            
            IF NOT AVAIL estabelec THEN DO:
                RUN utp/ut-msgs.p ("show", 13, INPUT BROWSE br-digita tt-digita.estab-f).
                APPLY 'mouse-select-click' TO im-pg-dig IN FRAME f-relat.
                APPLY 'entry' TO tt-digita.estab-f IN BROWSE br-digita.
                RETURN NO-APPLY.
            END.    
        END.
        
        CREATE tt-digita.
        ASSIGN INPUT BROWSE br-digita tt-digita.estab-i
               INPUT BROWSE br-digita tt-digita.estab-f
               INPUT BROWSE br-digita tt-digita.ep-codigo
               INPUT BROWSE br-digita tt-digita.arquivo.
	end.
    else do transaction:
        IF  tt-digita.estab-i:screen-value IN BROWSE br-digita <> "" THEN DO:
            FOR FIRST estabelec FIELDS()
                WHERE estabelec.cod-estabel = tt-digita.estab-i:screen-value IN BROWSE br-digita NO-LOCK: END.                
            IF NOT AVAIL estabelec then do:
                RUN utp/ut-msgs.p ("show", 13, tt-digita.estab-i:screen-value IN BROWSE br-digita).
                APPLY 'mouse-select-click' TO im-pg-dig IN FRAME f-relat.
                APPLY 'entry' TO tt-digita.estab-i IN BROWSE br-digita.
                RETURN NO-APPLY.
            END.    
        END.
        
        IF  tt-digita.estab-f:screen-value IN BROWSE br-digita <> ""THEN DO:
            FOR FIRST estabelec FIELDS()
                WHERE estabelec.cod-estabel = tt-digita.estab-f:screen-value IN BROWSE br-digita NO-LOCK: END.                
            IF NOT AVAIL estabelec then do:
                RUN utp/ut-msgs.p ("show", 13, tt-digita.estab-f:screen-value IN BROWSE br-digita).
                APPLY 'mouse-select-click' TO im-pg-dig IN FRAME f-relat.
                APPLY 'entry' TO tt-digita.estab-f IN BROWSE br-digita.
                RETURN NO-APPLY.
            END.    
        END.
    end.
    if br-digita:new-row then br-digita:create-result-list-entry() in frame f-pg-dig.   
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-relat
&Scoped-define SELF-NAME bt-ajuda
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-ajuda C-Win
ON CHOOSE OF bt-ajuda IN FRAME f-relat /* Ajuda */
DO:
   {include/ajuda.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-dig
&Scoped-define SELF-NAME bt-alterar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-alterar C-Win
ON CHOOSE OF bt-alterar IN FRAME f-pg-dig /* Alterar */
DO:
    apply 'entry' to tt-digita.estab-i in browse br-digita.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-imp
&Scoped-define SELF-NAME bt-arquivo
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-arquivo C-Win
ON CHOOSE OF bt-arquivo IN FRAME f-pg-imp
DO:
    {include/i-rparq.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-relat
&Scoped-define SELF-NAME bt-cancelar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-cancelar C-Win
ON CHOOSE OF bt-cancelar IN FRAME f-relat /* Cancelar */
DO:
   apply "close" to this-procedure.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-imp
&Scoped-define SELF-NAME bt-config-impr
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-config-impr C-Win
ON CHOOSE OF bt-config-impr IN FRAME f-pg-imp
DO:
   {include/i-rpimp.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-relat
&Scoped-define SELF-NAME bt-executar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-executar C-Win
ON CHOOSE OF bt-executar IN FRAME f-relat /* Executar */
DO:
   do  on error undo, return no-apply:
       run pi-executar.
   end.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-dig
&Scoped-define SELF-NAME bt-inserir
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-inserir C-Win
ON CHOOSE OF bt-inserir IN FRAME f-pg-dig /* Inserir */
DO:
    if  num-results('br-digita') > 0 then do:
        if  br-digita:insert-row('after') in frame f-pg-dig then.
    end.
    else do transaction:
        create tt-digita.
        open query br-digita for each tt-digita.
        apply 'entry' to tt-digita.estab-i in browse br-digita.
    end.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-recuperar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-recuperar C-Win
ON CHOOSE OF bt-recuperar IN FRAME f-pg-dig /* Recuperar */
DO:
    {include/i-rprcd.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-retirar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-retirar C-Win
ON CHOOSE OF bt-retirar IN FRAME f-pg-dig /* Retirar */
DO:
    if  br-digita:num-selected-rows > 0 then do on error undo, return no-apply:
        get current br-digita.
        delete tt-digita.
        if  br-digita:delete-current-row() in frame f-pg-dig then.
    end.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME bt-salvar
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL bt-salvar C-Win
ON CHOOSE OF bt-salvar IN FRAME f-pg-dig /* Salvar */
DO:
   {include/i-rpsvd.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-relat
&Scoped-define SELF-NAME im-pg-dig
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-dig C-Win
ON MOUSE-SELECT-CLICK OF im-pg-dig IN FRAME f-relat
DO:
    find first param-estoq no-lock no-error.
    if param-estoq.gera-ap = 2 then
       run pi-troca-pagina.
/*
    if  input frame f-pg-dig rs-opcao = 1 then do:
        assign l-deleta = no.
        apply "value-changed" to rs-opcao in frame f-pg-dig.
    end.
    if  avail tt-digita then do:
        if  input frame f-pg-dig rs-opcao = 2 then
            apply "value-changed" to br-reexporta in frame f-pg-dig.
        if  input frame f-pg-dig rs-opcao = 3 then
            apply "value-changed" to br-elimina in frame f-pg-dig.
    end.
*/    
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME im-pg-imp
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-imp C-Win
ON MOUSE-SELECT-CLICK OF im-pg-imp IN FRAME f-relat
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME im-pg-sel
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL im-pg-sel C-Win
ON MOUSE-SELECT-CLICK OF im-pg-sel IN FRAME f-relat
DO:
    run pi-troca-pagina.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-imp
&Scoped-define SELF-NAME rs-destino
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-destino C-Win
ON VALUE-CHANGED OF rs-destino IN FRAME f-pg-imp
DO:
do  with frame f-pg-imp:
    case self:screen-value:
        when "1" then do:
            assign c-arquivo:sensitive    = no
                   bt-arquivo:visible     = no
                   bt-config-impr:visible = yes.
        end.
        when "2" then do:
            assign c-arquivo:sensitive     = yes
                   bt-arquivo:visible      = yes
                   bt-config-impr:visible  = no.
        end.
        when "3" then do:
            assign c-arquivo:sensitive     = no
                   bt-arquivo:visible      = no
                   bt-config-impr:visible  = no.
        end.
    end case.
end.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define SELF-NAME rs-execucao
&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CONTROL rs-execucao C-Win
ON VALUE-CHANGED OF rs-execucao IN FRAME f-pg-imp
DO:
   {include/i-rprse.i}
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


&Scoped-define FRAME-NAME f-pg-dig
&UNDEFINE SELF-NAME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _CUSTOM _MAIN-BLOCK C-Win 


/* ***************************  Main Block  *************************** */

on  "F5", mouse-select-dblclick of tt-digita.estab-i in browse br-digita do:
    {include/zoomvar.i &prog-zoom="adzoom/z01ad107.w"
                       &campo=tt-digita.estab-i
                       &campozoom=cod-estabel
                       &browse=br-digita}
end.
on  "F5", mouse-select-dblclick of tt-digita.estab-f in browse br-digita do:
    {include/zoomvar.i &prog-zoom="adzoom/z01ad107.w"
                       &campo=tt-digita.estab-f
                       &campozoom=cod-estabel
                       &browse=br-digita}
end.
on  "entry" of tt-digita.arquivo in browse br-digita do:
    if  tt-digita.arquivo:screen-value in browse br-digita = "" then do:
        assign i-empresa    = input browse br-digita tt-digita.ep-codigo
               c-arqexporta = string(day(today), "99")
                            + string(month(today), "99") + "-"
                            + string(i-empresa, "999")   + ".EXP".
        assign tt-digita.arquivo:screen-value in browse br-digita = c-arqexporta.
    end.
end.

/* Set CURRENT-WINDOW: this will parent dialog-boxes and frames.        */
ASSIGN CURRENT-WINDOW                = {&WINDOW-NAME} 
       THIS-PROCEDURE:CURRENT-WINDOW = {&WINDOW-NAME}.

{utp/ut9000.i "RE0404" "2.00.00.015"}

/* inicializa‡äes do template de relat¢rio */
{include/i-rpini.i}

/* The CLOSE event can be used from inside or outside the procedure to  */
/* terminate it.                                                        */
ON CLOSE OF THIS-PROCEDURE 
   RUN disable_UI.

{include/i-rplbl.i}

/* Best default for GUI applications is...                              */
PAUSE 0 BEFORE-HIDE.

/* Now enable the interface and wait for the exit condition.            */
/* (NOTE: handle ERROR and END-KEY so cleanup code will always fire.    */
MAIN-BLOCK:
DO  ON ERROR   UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK
    ON END-KEY UNDO MAIN-BLOCK, LEAVE MAIN-BLOCK:

    RUN enable_UI.

    &if defined(bf_mat_selecao_estab_re) &then
        assign c-estab-ini:visible in frame f-pg-sel = yes
               image-3:visible     in frame f-pg-sel = yes
               image-4:visible     in frame f-pg-sel = yes
               c-estab-fim:visible in frame f-pg-sel = yes.
    &else
        assign c-estab-ini:visible in frame f-pg-sel = no
               image-3:visible     in frame f-pg-sel = no
               image-4:visible     in frame f-pg-sel = no
               c-estab-fim:visible in frame f-pg-sel = no.
    &endif   

    {include/i-rpmbl.i}

    find first param-global no-lock no-error.
    find first param-estoq  no-lock no-error.
    if not avail param-estoq then do:
       run utp/ut-msgs.p (input "show",
                          input 1059,
                          input ""). 
       apply "close" to this-procedure.
    end.
    if param-estoq.gera-ap <> 2 then 
        assign im-pg-dig:sensitive in frame f-relat = no
               wh-label-dig:fgcolor = 7
               frame f-pg-dig:sensitive = no.


    {utp/ut-liter.i Estab_I * r}
    assign tt-digita.estab-i:label in browse br-digita = trim(return-value).
    {utp/ut-liter.i Estab_F * r}
    assign tt-digita.estab-f:label in browse br-digita = trim(return-value)
           da-data-i:screen-value in frame f-pg-sel    = string(today).

    {utp/ut-liter.i Estabelecimento * r}
    assign c-estab-ini:label in frame f-pg-sel = trim(return-value).

    &IF "{&mguni_version}" >= "2.071" &THEN
        ASSIGN c-estab-fim:SCREEN-VALUE IN FRAME f-pg-sel = "ZZZZZ".
    &ELSE
        ASSIGN c-estab-fim:SCREEN-VALUE IN FRAME f-pg-sel = "ZZZ".
    &ENDIF

    IF  NOT THIS-PROCEDURE:PERSISTENT THEN
        WAIT-FOR CLOSE OF THIS-PROCEDURE.
END.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME


/* **********************  Internal Procedures  *********************** */

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-create-objects C-Win  _ADM-CREATE-OBJECTS
PROCEDURE adm-create-objects :
/*------------------------------------------------------------------------------
  Purpose:     Create handles for all SmartObjects used in this procedure.
               After SmartObjects are initialized, then SmartLinks are added.
  Parameters:  <none>
------------------------------------------------------------------------------*/

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE adm-row-available C-Win  _ADM-ROW-AVAILABLE
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

  /* Process the newly available records (i.e. display fields,
     open queries, and/or pass records on to any RECORD-TARGETS).    */
  {src/adm/template/row-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE disable_UI C-Win  _DEFAULT-DISABLE
PROCEDURE disable_UI :
/*------------------------------------------------------------------------------
  Purpose:     DISABLE the User Interface
  Parameters:  <none>
  Notes:       Here we clean-up the user-interface by deleting
               dynamic widgets we have created and/or hide 
               frames.  This procedure is usually called when
               we are ready to "clean-up" after running.
------------------------------------------------------------------------------*/
  /* Delete the WINDOW we created */
  IF SESSION:DISPLAY-TYPE = "GUI":U AND VALID-HANDLE(C-Win)
  THEN DELETE WIDGET C-Win.
  IF THIS-PROCEDURE:PERSISTENT THEN DELETE PROCEDURE THIS-PROCEDURE.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE enable_UI C-Win  _DEFAULT-ENABLE
PROCEDURE enable_UI :
/*------------------------------------------------------------------------------
  Purpose:     ENABLE the User Interface
  Parameters:  <none>
  Notes:       Here we display/view/enable the widgets in the
               user-interface.  In addition, OPEN all queries
               associated with each FRAME and BROWSE.
               These statements here are based on the "Other 
               Settings" section of the widget Property Sheets.
------------------------------------------------------------------------------*/
  ENABLE im-pg-dig im-pg-imp im-pg-sel bt-executar bt-cancelar bt-ajuda 
      WITH FRAME f-relat IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-f-relat}
  ENABLE br-digita bt-inserir bt-alterar bt-retirar bt-salvar bt-recuperar 
      WITH FRAME f-pg-dig IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-dig}
  DISPLAY rs-destino c-arquivo rs-execucao tb-imprimir-parametro 
      WITH FRAME f-pg-imp IN WINDOW C-Win.
  ENABLE RECT-7 RECT-9 RECT-11 rs-destino bt-arquivo bt-config-impr c-arquivo 
         rs-execucao tb-imprimir-parametro 
      WITH FRAME f-pg-imp IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-imp}
  DISPLAY da-data-i da-data-f c-estab-ini c-estab-fim 
      WITH FRAME f-pg-sel IN WINDOW C-Win.
  ENABLE IMAGE-1 IMAGE-2 IMAGE-3 IMAGE-4 da-data-i da-data-f c-estab-ini 
         c-estab-fim 
      WITH FRAME f-pg-sel IN WINDOW C-Win.
  {&OPEN-BROWSERS-IN-QUERY-f-pg-sel}
  VIEW C-Win.
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE local-exit C-Win 
PROCEDURE local-exit :
/* -----------------------------------------------------------
  Purpose:  Starts an "exit" by APPLYing CLOSE event, which starts "destroy".
  Parameters:  <none>
  Notes:    If activated, should APPLY CLOSE, *not* dispatch adm-exit.   
-------------------------------------------------------------*/
   APPLY "CLOSE":U TO THIS-PROCEDURE.

   RETURN.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-executar C-Win 
PROCEDURE pi-executar :
/*------------------------------------------------------------------------------
  Purpose:
  Parameters:  <none>
  Notes:
------------------------------------------------------------------------------*/

do  on error undo, return error
    on stop  undo, return error:

    {include/i-rpexa.i}

    if  input frame f-pg-imp rs-destino = 2 then do:
        run utp/ut-vlarq.p (input input frame f-pg-imp c-arquivo).
        if  return-value = "nok" then do:
            run utp/ut-msgs.p (input "show", input 73, input "").
            apply 'mouse-select-click' to im-pg-imp in frame f-relat.
            apply 'entry' to c-arquivo in frame f-pg-imp.
            return error.
        end.
    end.

    /* Coloque aqui as valida‡äes das outras p ginas, lembrando que elas
       devem apresentar uma mensagem de erro cadastrada, posicionar na p gina 
       com problemas e colocar o focus no campo com problemas */
    find first param-estoq no-lock no-error.
    if param-estoq.gera-ap = 2 then do:
        find first tt-digita no-error.
        if  not avail tt-digita then do:
            run utp/ut-msgs.p (input "show", input 16024, input "").
            return error.
        end.
    end.

    create tt-param.
    assign tt-param.usuario   = c-seg-usuario
           tt-param.destino   = input frame f-pg-imp rs-destino
           tt-param.data-exec = today
           tt-param.hora-exec = time
           tt-param.da-data-i = input frame f-pg-sel da-data-i
           tt-param.da-data-f = input frame f-pg-sel da-data-f
    &if defined(bf_mat_selecao_estab_re) &then
           tt-param.c-est-ini = input frame f-pg-sel c-estab-ini
           tt-param.c-est-fim = input frame f-pg-sel c-estab-fim
    &endif
           tt-param.i-opcao   = 1
           tt-param.c-destino = entry((tt-param.destino - 1) * 2 + 1, 
                                       rs-destino:radio-buttons in frame f-pg-imp)
           tt-param.l-imp-param = input frame f-pg-imp tb-imprimir-parametro.

    if  tt-param.destino = 1 then
        assign tt-param.arquivo = "".
    else
    if  tt-param.destino = 2 then 
        assign tt-param.arquivo = input frame f-pg-imp c-arquivo.
    else
        assign tt-param.arquivo = session:temp-directory + c-programa-mg97 + ".tmp".

    /* Coloque aqui a l¢gica de grava‡Æo dos parƒmtros e sele‡Æo na temp-table
       tt-param */ 

    {include/i-rpexb.i}

    if  session:set-wait-state("general") then.

    {include/i-rprun.i rep/re0404rp.p} 

    {include/i-rpexc.i}

    if  session:set-wait-state("") then.

    {include/i-rptrm.i}

end.

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-reexportar C-Win 
PROCEDURE pi-reexportar :
/*------------------------------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/
/**************** 
    assign i-ref = 0.
    reexporta:
    for each doc-i-ap where doc-i-ap.referencia <> "" break by doc-i-ap.referencia no-lock:
        if  first-of(doc-i-ap.referencia) then do:
            do  i-ref = 1 to 10:
                if  substr(doc-i-ap.referencia, i-ref, i-ref) = ""
                or (substr(doc-i-ap.referencia, i-ref, i-ref) < "0"
                and substr(doc-i-ap.referencia, i-ref, i-ref) > "9") then
                    next reexporta.
            end.
            create tt-digita.
            assign tt-digita.data = substr(doc-i-ap.referencia, 1, 2) + "/"
                                  + string(index("123456789ABC",
                                           substr(doc-i-ap.referencia, 3, 1)),"99")
                   tt-digita.hora = substr(doc-i-ap.referencia, 4, 2) + ":"
                                  + substr(doc-i-ap.referencia, 6, 2)
                   tt-digita.ep-codigo  = doc-i-ap.ep-codigo
                   tt-digita.cod-esp    = doc-i-ap.cod-esp
                   tt-digita.referencia = doc-i-ap.referencia
                   tt-digita.arquivo    = ""
                   tt-digita.flag       = no.
        end.
    end.
    open query br-reexporta for each tt-digita.
**************/    
END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE pi-troca-pagina C-Win 
PROCEDURE pi-troca-pagina :
/*------------------------------------------------------------------------------
  Purpose: Gerencia a Troca de P gina (folder)   
  Parameters:  <none>
  Notes:       
------------------------------------------------------------------------------*/

{include/i-rptrp.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE send-records C-Win  _ADM-SEND-RECORDS
PROCEDURE send-records :
/*------------------------------------------------------------------------------
  Purpose:     Send record ROWID's for all tables used by
               this file.
  Parameters:  see template/snd-head.i
------------------------------------------------------------------------------*/

  /* Define variables needed by this internal procedure.               */
  {src/adm/template/snd-head.i}

  /* For each requested table, put it's ROWID in the output list.      */
  {src/adm/template/snd-list.i "tt-digita"}
  {src/adm/template/snd-list.i "docum-est"}

  /* Deal with any unexpected table requests before closing.           */
  {src/adm/template/snd-end.i}

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

&ANALYZE-SUSPEND _UIB-CODE-BLOCK _PROCEDURE state-changed C-Win 
PROCEDURE state-changed :
/* -----------------------------------------------------------
  Purpose:     
  Parameters:  <none>
  Notes:       
-------------------------------------------------------------*/
  DEFINE INPUT PARAMETER p-issuer-hdl AS HANDLE NO-UNDO.
  DEFINE INPUT PARAMETER p-state AS CHARACTER NO-UNDO.

  run pi-trata-state (p-issuer-hdl, p-state).

END PROCEDURE.

/* _UIB-CODE-BLOCK-END */
&ANALYZE-RESUME

