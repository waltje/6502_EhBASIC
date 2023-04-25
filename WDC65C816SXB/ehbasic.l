ca65 V2.17 - Git d52d986a
Main file   : ehbasic.asm
Current file: ehbasic.asm

000000r 1               .include "ca65-816sxb.inc"
000000r 2               .feature labels_without_colons
000000r 2               
000000r 2               SXB       = 1
000000r 2               
000000r 2               WDCBASE   = $8080
000000r 2               SRESET    = WDCBASE+2             ; this is a reset routine
000000r 2               TREADY    = SRESET+2              ; TIDE FIFO receive ready (0 = no char, 1 = char)
000000r 2               TRECV     = TREADY+2              ; TIDE FIFO receive
000000r 2               TSEND     = TRECV+2               ; TIDE FIFO send
000000r 2               SYSCODE   = TSEND+2               ; holds address of SYSCODE variable, set to 0 to use our vectors
000000r 2               VERSTR    = SYSCODE+2             ; holds address of version string
000000r 2               S_NMI     = $7E72                 ; Shadow NMI vector
000000r 2               S_NNMI    = $7E76
000000r 2               S_IRQBRK  = $7E70
000000r 2               S_NBRK    = $7E74
000000r 2               S_BRK     = $7EFE                 ; Shadow BRK vector
000000r 2               
000000r 1               .pc02
000000r 1               
000000r 1               ; Enhanced BASIC to assemble under 6502 simulator, $ver 2.22p3
000000r 1               
000000r 1               ; $E7E1 $E7CF $E7C6 $E7D3 $E7D1 $E7D5 $E7CF $E81E $E825
000000r 1               
000000r 1               ; 2.00      new revision numbers start here
000000r 1               ; 2.01      fixed LCASE$() and UCASE$()
000000r 1               ; 2.02      new get value routine done
000000r 1               ; 2.03      changed RND() to galoise method
000000r 1               ; 2.04      fixed SPC()
000000r 1               ; 2.05      new get value routine fixed
000000r 1               ; 2.06      changed USR() code
000000r 1               ; 2.07      fixed STR$()
000000r 1               ; 2.08      changed INPUT and READ to remove need for $00 start to input buffer
000000r 1               ; 2.09      fixed RND()
000000r 1               ; 2.10      integrated missed changes from an earlier version
000000r 1               ; 2.20      added ELSE to IF .. THEN and fixed IF .. GOTO <statement> to cause error
000000r 1               ; 2.21      fixed IF .. THEN RETURN to not cause error
000000r 1               ; 2.22      fixed RND() breaking the get byte routine
000000r 1               ; 2.22p     patched to disable use of decimal mode and fix Ibuff issues
000000r 1               ;              (bugsnquirks.txt notes 2, 4 and 5)
000000r 1               ;              tabs converted to spaces, tabwidth=6
000000r 1               ; 2.22p2    fixed can't continue error on 1st statement after direct mode
000000r 1               ;              changed INPUT to throw "break in line ##" on empty line input
000000r 1               ; 2.22p3    fixed RAM above code / Ibuff above EhBASIC patch breaks STR$()
000000r 1               ;              fix provided by github user mgcaret
000000r 1               
000000r 1               ; zero page use ..
000000r 1               
000000r 1               LAB_WARM          = $00       ; BASIC warm start entry point
000000r 1               Wrmjpl            = LAB_WARM+1; BASIC warm start vector jump low byte
000000r 1               Wrmjph            = LAB_WARM+2; BASIC warm start vector jump high byte
000000r 1               
000000r 1               Usrjmp            = $0A       ; USR function JMP address
000000r 1               Usrjpl            = Usrjmp+1  ; USR function JMP vector low byte
000000r 1               Usrjph            = Usrjmp+2  ; USR function JMP vector high byte
000000r 1               Nullct            = $0D       ; nulls output after each line
000000r 1               TPos              = $0E       ; BASIC terminal position byte
000000r 1               TWidth            = $0F       ; BASIC terminal width byte
000000r 1               Iclim             = $10       ; input column limit
000000r 1               Itempl            = $11       ; temporary integer low byte
000000r 1               Itemph            = Itempl+1  ; temporary integer high byte
000000r 1               
000000r 1               nums_1            = Itempl    ; number to bin/hex string convert MSB
000000r 1               nums_2            = nums_1+1  ; number to bin/hex string convert
000000r 1               nums_3            = nums_1+2  ; number to bin/hex string convert LSB
000000r 1               
000000r 1               Srchc             = $5B       ; search character
000000r 1               Temp3             = Srchc     ; temp byte used in number routines
000000r 1               Scnquo            = $5C       ; scan-between-quotes flag
000000r 1               Asrch             = Scnquo    ; alt search character
000000r 1               
000000r 1               XOAw_l            = Srchc     ; eXclusive OR, OR and AND word low byte
000000r 1               XOAw_h            = Scnquo    ; eXclusive OR, OR and AND word high byte
000000r 1               
000000r 1               Ibptr             = $5D       ; input buffer pointer
000000r 1               Dimcnt            = Ibptr     ; # of dimensions
000000r 1               Tindx             = Ibptr     ; token index
000000r 1               
000000r 1               Defdim            = $5E       ; default DIM flag
000000r 1               Dtypef            = $5F       ; data type flag, $FF=string, $00=numeric
000000r 1               Oquote            = $60       ; open quote flag (b7) (Flag: DATA scan; LIST quote; memory)
000000r 1               Gclctd            = $60       ; garbage collected flag
000000r 1               Sufnxf            = $61       ; subscript/FNX flag, 1xxx xxx = FN(0xxx xxx)
000000r 1               Imode             = $62       ; input mode flag, $00=INPUT, $80=READ
000000r 1               
000000r 1               Cflag             = $63       ; comparison evaluation flag
000000r 1               
000000r 1               TabSiz            = $64       ; TAB step size (was input flag)
000000r 1               
000000r 1               next_s            = $65       ; next descriptor stack address
000000r 1               
000000r 1                                             ; these two bytes form a word pointer to the item
000000r 1                                             ; currently on top of the descriptor stack
000000r 1               last_sl           = $66       ; last descriptor stack address low byte
000000r 1               last_sh           = $67       ; last descriptor stack address high byte (always $00)
000000r 1               
000000r 1               des_sk            = $68       ; descriptor stack start address (temp strings)
000000r 1               
000000r 1               ;                 = $70       ; End of descriptor stack
000000r 1               
000000r 1               ut1_pl            = $71       ; utility pointer 1 low byte
000000r 1               ut1_ph            = ut1_pl+1  ; utility pointer 1 high byte
000000r 1               ut2_pl            = $73       ; utility pointer 2 low byte
000000r 1               ut2_ph            = ut2_pl+1  ; utility pointer 2 high byte
000000r 1               
000000r 1               Temp_2            = ut1_pl    ; temp byte for block move
000000r 1               
000000r 1               FACt_1            = $75       ; FAC temp mantissa1
000000r 1               FACt_2            = FACt_1+1  ; FAC temp mantissa2
000000r 1               FACt_3            = FACt_2+1  ; FAC temp mantissa3
000000r 1               
000000r 1               dims_l            = FACt_2    ; array dimension size low byte
000000r 1               dims_h            = FACt_3    ; array dimension size high byte
000000r 1               
000000r 1               TempB             = $78       ; temp page 0 byte
000000r 1               
000000r 1               Smeml             = $79       ; start of mem low byte       (Start-of-Basic)
000000r 1               Smemh             = Smeml+1   ; start of mem high byte      (Start-of-Basic)
000000r 1               Svarl             = $7B       ; start of vars low byte      (Start-of-Variables)
000000r 1               Svarh             = Svarl+1   ; start of vars high byte     (Start-of-Variables)
000000r 1               Sarryl            = $7D       ; var mem end low byte        (Start-of-Arrays)
000000r 1               Sarryh            = Sarryl+1  ; var mem end high byte       (Start-of-Arrays)
000000r 1               Earryl            = $7F       ; array mem end low byte      (End-of-Arrays)
000000r 1               Earryh            = Earryl+1  ; array mem end high byte     (End-of-Arrays)
000000r 1               Sstorl            = $81       ; string storage low byte     (String storage (moving down))
000000r 1               Sstorh            = Sstorl+1  ; string storage high byte    (String storage (moving down))
000000r 1               Sutill            = $83       ; string utility ptr low byte
000000r 1               Sutilh            = Sutill+1  ; string utility ptr high byte
000000r 1               Ememl             = $85       ; end of mem low byte         (Limit-of-memory)
000000r 1               Ememh             = Ememl+1   ; end of mem high byte        (Limit-of-memory)
000000r 1               Clinel            = $87       ; current line low byte       (Basic line number)
000000r 1               Clineh            = Clinel+1  ; current line high byte      (Basic line number)
000000r 1               Blinel            = $89       ; break line low byte         (Previous Basic line number)
000000r 1               Blineh            = Blinel+1  ; break line high byte        (Previous Basic line number)
000000r 1               
000000r 1               Cpntrl            = $8B       ; continue pointer low byte
000000r 1               Cpntrh            = Cpntrl+1  ; continue pointer high byte
000000r 1               
000000r 1               Dlinel            = $8D       ; current DATA line low byte
000000r 1               Dlineh            = Dlinel+1  ; current DATA line high byte
000000r 1               
000000r 1               Dptrl             = $8F       ; DATA pointer low byte
000000r 1               Dptrh             = Dptrl+1   ; DATA pointer high byte
000000r 1               
000000r 1               Rdptrl            = $91       ; read pointer low byte
000000r 1               Rdptrh            = Rdptrl+1  ; read pointer high byte
000000r 1               
000000r 1               Varnm1            = $93       ; current var name 1st byte
000000r 1               Varnm2            = Varnm1+1  ; current var name 2nd byte
000000r 1               
000000r 1               Cvaral            = $95       ; current var address low byte
000000r 1               Cvarah            = Cvaral+1  ; current var address high byte
000000r 1               
000000r 1               Frnxtl            = $97       ; var pointer for FOR/NEXT low byte
000000r 1               Frnxth            = Frnxtl+1  ; var pointer for FOR/NEXT high byte
000000r 1               
000000r 1               Tidx1             = Frnxtl    ; temp line index
000000r 1               
000000r 1               Lvarpl            = Frnxtl    ; let var pointer low byte
000000r 1               Lvarph            = Frnxth    ; let var pointer high byte
000000r 1               
000000r 1               prstk             = $99       ; precedence stacked flag
000000r 1               
000000r 1               comp_f            = $9B       ; compare function flag, bits 0,1 and 2 used
000000r 1                                             ; bit 2 set if >
000000r 1                                             ; bit 1 set if =
000000r 1                                             ; bit 0 set if <
000000r 1               
000000r 1               func_l            = $9C       ; function pointer low byte
000000r 1               func_h            = func_l+1  ; function pointer high byte
000000r 1               
000000r 1               garb_l            = func_l    ; garbage collection working pointer low byte
000000r 1               garb_h            = func_h    ; garbage collection working pointer high byte
000000r 1               
000000r 1               des_2l            = $9E       ; string descriptor_2 pointer low byte
000000r 1               des_2h            = des_2l+1  ; string descriptor_2 pointer high byte
000000r 1               
000000r 1               g_step            = $A0       ; garbage collect step size
000000r 1               
000000r 1               Fnxjmp            = $A1       ; jump vector for functions
000000r 1               Fnxjpl            = Fnxjmp+1  ; functions jump vector low byte
000000r 1               Fnxjph            = Fnxjmp+2  ; functions jump vector high byte
000000r 1               
000000r 1               g_indx            = Fnxjpl    ; garbage collect temp index
000000r 1               
000000r 1               FAC2_r            = $A3       ; FAC2 rounding byte
000000r 1               
000000r 1               Adatal            = $A4       ; array data pointer low byte
000000r 1               Adatah            = Adatal+1  ; array data pointer high  byte
000000r 1               
000000r 1               Nbendl            = Adatal    ; new block end pointer low byte
000000r 1               Nbendh            = Adatah    ; new block end pointer high  byte
000000r 1               
000000r 1               Obendl            = $A6       ; old block end pointer low byte
000000r 1               Obendh            = Obendl+1  ; old block end pointer high  byte
000000r 1               
000000r 1               numexp            = $A8       ; string to float number exponent count
000000r 1               expcnt            = $A9       ; string to float exponent count
000000r 1               
000000r 1               numbit            = numexp    ; bit count for array element calculations
000000r 1               
000000r 1               numdpf            = $AA       ; string to float decimal point flag
000000r 1               expneg            = $AB       ; string to float eval exponent -ve flag
000000r 1               
000000r 1               Astrtl            = numdpf    ; array start pointer low byte
000000r 1               Astrth            = expneg    ; array start pointer high  byte
000000r 1               
000000r 1               Histrl            = numdpf    ; highest string low byte
000000r 1               Histrh            = expneg    ; highest string high  byte
000000r 1               
000000r 1               Baslnl            = numdpf    ; BASIC search line pointer low byte
000000r 1               Baslnh            = expneg    ; BASIC search line pointer high  byte
000000r 1               
000000r 1               Fvar_l            = numdpf    ; find/found variable pointer low byte
000000r 1               Fvar_h            = expneg    ; find/found variable pointer high  byte
000000r 1               
000000r 1               Ostrtl            = numdpf    ; old block start pointer low byte
000000r 1               Ostrth            = expneg    ; old block start pointer high  byte
000000r 1               
000000r 1               Vrschl            = numdpf    ; variable search pointer low byte
000000r 1               Vrschh            = expneg    ; variable search pointer high  byte
000000r 1               
000000r 1               FAC1_e            = $AC       ; FAC1 exponent
000000r 1               FAC1_1            = FAC1_e+1  ; FAC1 mantissa1
000000r 1               FAC1_2            = FAC1_e+2  ; FAC1 mantissa2
000000r 1               FAC1_3            = FAC1_e+3  ; FAC1 mantissa3
000000r 1               FAC1_s            = FAC1_e+4  ; FAC1 sign (b7)
000000r 1               
000000r 1               str_ln            = FAC1_e    ; string length
000000r 1               str_pl            = FAC1_1    ; string pointer low byte
000000r 1               str_ph            = FAC1_2    ; string pointer high byte
000000r 1               
000000r 1               des_pl            = FAC1_2    ; string descriptor pointer low byte
000000r 1               des_ph            = FAC1_3    ; string descriptor pointer high byte
000000r 1               
000000r 1               mids_l            = FAC1_3    ; MID$ string temp length byte
000000r 1               
000000r 1               negnum            = $B1       ; string to float eval -ve flag
000000r 1               numcon            = $B1       ; series evaluation constant count
000000r 1               
000000r 1               FAC1_o            = $B2       ; FAC1 overflow byte
000000r 1               
000000r 1               FAC2_e            = $B3       ; FAC2 exponent
000000r 1               FAC2_1            = FAC2_e+1  ; FAC2 mantissa1
000000r 1               FAC2_2            = FAC2_e+2  ; FAC2 mantissa2
000000r 1               FAC2_3            = FAC2_e+3  ; FAC2 mantissa3
000000r 1               FAC2_s            = FAC2_e+4  ; FAC2 sign (b7)
000000r 1               
000000r 1               FAC_sc            = $B8       ; FAC sign comparison, Acc#1 vs #2
000000r 1               FAC1_r            = $B9       ; FAC1 rounding byte
000000r 1               
000000r 1               ssptr_l           = FAC_sc    ; string start pointer low byte
000000r 1               ssptr_h           = FAC1_r    ; string start pointer high byte
000000r 1               
000000r 1               sdescr            = FAC_sc    ; string descriptor pointer
000000r 1               
000000r 1               csidx             = $BA       ; line crunch save index
000000r 1               Asptl             = csidx     ; array size/pointer low byte
000000r 1               Aspth             = $BB       ; array size/pointer high byte
000000r 1               
000000r 1               Btmpl             = Asptl     ; BASIC pointer temp low byte
000000r 1               Btmph             = Aspth     ; BASIC pointer temp low byte
000000r 1               
000000r 1               Cptrl             = Asptl     ; BASIC pointer temp low byte
000000r 1               Cptrh             = Aspth     ; BASIC pointer temp low byte
000000r 1               
000000r 1               Sendl             = Asptl     ; BASIC pointer temp low byte
000000r 1               Sendh             = Aspth     ; BASIC pointer temp low byte
000000r 1               
000000r 1               LAB_IGBY          = $BC       ; get next BASIC byte subroutine
000000r 1               
000000r 1               LAB_GBYT          = $C2       ; get current BASIC byte subroutine
000000r 1               Bpntrl            = $C3       ; BASIC execute (get byte) pointer low byte
000000r 1               Bpntrh            = Bpntrl+1  ; BASIC execute (get byte) pointer high byte
000000r 1               
000000r 1               ;                 = $D7       ; end of get BASIC char subroutine
000000r 1               
000000r 1               Rbyte4            = $D8       ; extra PRNG byte
000000r 1               Rbyte1            = Rbyte4+1  ; most significant PRNG byte
000000r 1               Rbyte2            = Rbyte4+2  ; middle PRNG byte
000000r 1               Rbyte3            = Rbyte4+3  ; least significant PRNG byte
000000r 1               
000000r 1               NmiBase           = $DC       ; NMI handler enabled/setup/triggered flags
000000r 1                                             ; bit function
000000r 1                                             ; === ========
000000r 1                                             ; 7   interrupt enabled
000000r 1                                             ; 6   interrupt setup
000000r 1                                             ; 5   interrupt happened
000000r 1               ;                 = $DD       ; NMI handler addr low byte
000000r 1               ;                 = $DE       ; NMI handler addr high byte
000000r 1               IrqBase           = $DF       ; IRQ handler enabled/setup/triggered flags
000000r 1               ;                 = $E0       ; IRQ handler addr low byte
000000r 1               ;                 = $E1       ; IRQ handler addr high byte
000000r 1               
000000r 1               ;                 = $DE       ; unused
000000r 1               ;                 = $DF       ; unused
000000r 1               ;                 = $E0       ; unused
000000r 1               ;                 = $E1       ; unused
000000r 1               ;                 = $E2       ; unused
000000r 1               ;                 = $E3       ; unused
000000r 1               ;                 = $E4       ; unused
000000r 1               ;                 = $E5       ; unused
000000r 1               ;                 = $E6       ; unused
000000r 1               ;                 = $E7       ; unused
000000r 1               ;                 = $E8       ; unused
000000r 1               ;                 = $E9       ; unused
000000r 1               ;                 = $EA       ; unused
000000r 1               ;                 = $EB       ; unused
000000r 1               ;                 = $EC       ; unused
000000r 1               ;                 = $ED       ; unused
000000r 1               ;                 = $EE       ; unused
000000r 1               
000000r 1               Decss             = $EF       ; number to decimal string start
000000r 1               Decssp1           = Decss+1   ; number to decimal string start
000000r 1               
000000r 1               ;                 = $FF       ; decimal string end
000000r 1               
000000r 1               ; token values needed for BASIC
000000r 1               
000000r 1               ; primary command tokens (can start a statement)
000000r 1               
000000r 1               TK_END            = $80             ; END token
000000r 1               TK_FOR            = TK_END+1        ; FOR token
000000r 1               TK_NEXT           = TK_FOR+1        ; NEXT token
000000r 1               TK_DATA           = TK_NEXT+1       ; DATA token
000000r 1               TK_INPUT          = TK_DATA+1       ; INPUT token
000000r 1               TK_DIM            = TK_INPUT+1      ; DIM token
000000r 1               TK_READ           = TK_DIM+1        ; READ token
000000r 1               TK_LET            = TK_READ+1       ; LET token
000000r 1               TK_DEC            = TK_LET+1        ; DEC token
000000r 1               TK_GOTO           = TK_DEC+1        ; GOTO token
000000r 1               TK_RUN            = TK_GOTO+1       ; RUN token
000000r 1               TK_IF             = TK_RUN+1        ; IF token
000000r 1               TK_RESTORE        = TK_IF+1         ; RESTORE token
000000r 1               TK_GOSUB          = TK_RESTORE+1    ; GOSUB token
000000r 1               TK_RETIRQ         = TK_GOSUB+1      ; RETIRQ token
000000r 1               TK_RETNMI         = TK_RETIRQ+1     ; RETNMI token
000000r 1               TK_RETURN         = TK_RETNMI+1     ; RETURN token
000000r 1               TK_REM            = TK_RETURN+1     ; REM token
000000r 1               TK_STOP           = TK_REM+1        ; STOP token
000000r 1               TK_ON             = TK_STOP+1       ; ON token
000000r 1               TK_NULL           = TK_ON+1         ; NULL token
000000r 1               TK_INC            = TK_NULL+1       ; INC token
000000r 1               TK_WAIT           = TK_INC+1        ; WAIT token
000000r 1               TK_LOAD           = TK_WAIT+1       ; LOAD token
000000r 1               TK_SAVE           = TK_LOAD+1       ; SAVE token
000000r 1               TK_DEF            = TK_SAVE+1       ; DEF token
000000r 1               TK_POKE           = TK_DEF+1        ; POKE token
000000r 1               TK_DOKE           = TK_POKE+1       ; DOKE token
000000r 1               TK_CALL           = TK_DOKE+1       ; CALL token
000000r 1               TK_DO             = TK_CALL+1       ; DO token
000000r 1               TK_LOOP           = TK_DO+1         ; LOOP token
000000r 1               TK_PRINT          = TK_LOOP+1       ; PRINT token
000000r 1               TK_CONT           = TK_PRINT+1      ; CONT token
000000r 1               TK_LIST           = TK_CONT+1       ; LIST token
000000r 1               TK_CLEAR          = TK_LIST+1       ; CLEAR token
000000r 1               TK_NEW            = TK_CLEAR+1      ; NEW token
000000r 1               TK_WIDTH          = TK_NEW+1        ; WIDTH token
000000r 1               TK_GET            = TK_WIDTH+1      ; GET token
000000r 1               TK_SWAP           = TK_GET+1        ; SWAP token
000000r 1               TK_BITSET         = TK_SWAP+1       ; BITSET token
000000r 1               TK_BITCLR         = TK_BITSET+1     ; BITCLR token
000000r 1               TK_IRQ            = TK_BITCLR+1     ; IRQ token
000000r 1               TK_NMI            = TK_IRQ+1        ; NMI token
000000r 1               
000000r 1               ; secondary command tokens, can't start a statement
000000r 1               
000000r 1               TK_TAB            = TK_NMI+1        ; TAB token
000000r 1               TK_ELSE           = TK_TAB+1        ; ELSE token
000000r 1               TK_TO             = TK_ELSE+1       ; TO token
000000r 1               TK_FN             = TK_TO+1         ; FN token
000000r 1               TK_SPC            = TK_FN+1         ; SPC token
000000r 1               TK_THEN           = TK_SPC+1        ; THEN token
000000r 1               TK_NOT            = TK_THEN+1       ; NOT token
000000r 1               TK_STEP           = TK_NOT+1        ; STEP token
000000r 1               TK_UNTIL          = TK_STEP+1       ; UNTIL token
000000r 1               TK_WHILE          = TK_UNTIL+1      ; WHILE token
000000r 1               TK_OFF            = TK_WHILE+1      ; OFF token
000000r 1               
000000r 1               ; opperator tokens
000000r 1               
000000r 1               TK_PLUS           = TK_OFF+1        ; + token
000000r 1               TK_MINUS          = TK_PLUS+1       ; - token
000000r 1               TK_MUL            = TK_MINUS+1      ; * token
000000r 1               TK_DIV            = TK_MUL+1        ; / token
000000r 1               TK_POWER          = TK_DIV+1        ; ^ token
000000r 1               TK_AND            = TK_POWER+1      ; AND token
000000r 1               TK_EOR            = TK_AND+1        ; EOR token
000000r 1               TK_OR             = TK_EOR+1        ; OR token
000000r 1               TK_RSHIFT         = TK_OR+1         ; RSHIFT token
000000r 1               TK_LSHIFT         = TK_RSHIFT+1     ; LSHIFT token
000000r 1               TK_GT             = TK_LSHIFT+1     ; > token
000000r 1               TK_EQUAL          = TK_GT+1         ; = token
000000r 1               TK_LT             = TK_EQUAL+1      ; < token
000000r 1               
000000r 1               ; functions tokens
000000r 1               
000000r 1               TK_SGN            = TK_LT+1         ; SGN token
000000r 1               TK_INT            = TK_SGN+1        ; INT token
000000r 1               TK_ABS            = TK_INT+1        ; ABS token
000000r 1               TK_USR            = TK_ABS+1        ; USR token
000000r 1               TK_FRE            = TK_USR+1        ; FRE token
000000r 1               TK_POS            = TK_FRE+1        ; POS token
000000r 1               TK_SQR            = TK_POS+1        ; SQR token
000000r 1               TK_RND            = TK_SQR+1        ; RND token
000000r 1               TK_LOG            = TK_RND+1        ; LOG token
000000r 1               TK_EXP            = TK_LOG+1        ; EXP token
000000r 1               TK_COS            = TK_EXP+1        ; COS token
000000r 1               TK_SIN            = TK_COS+1        ; SIN token
000000r 1               TK_TAN            = TK_SIN+1        ; TAN token
000000r 1               TK_ATN            = TK_TAN+1        ; ATN token
000000r 1               TK_PEEK           = TK_ATN+1        ; PEEK token
000000r 1               TK_DEEK           = TK_PEEK+1       ; DEEK token
000000r 1               TK_SADD           = TK_DEEK+1       ; SADD token
000000r 1               TK_LEN            = TK_SADD+1       ; LEN token
000000r 1               TK_STRS           = TK_LEN+1        ; STR$ token
000000r 1               TK_VAL            = TK_STRS+1       ; VAL token
000000r 1               TK_ASC            = TK_VAL+1        ; ASC token
000000r 1               TK_UCASES         = TK_ASC+1        ; UCASE$ token
000000r 1               TK_LCASES         = TK_UCASES+1     ; LCASE$ token
000000r 1               TK_CHRS           = TK_LCASES+1     ; CHR$ token
000000r 1               TK_HEXS           = TK_CHRS+1       ; HEX$ token
000000r 1               TK_BINS           = TK_HEXS+1       ; BIN$ token
000000r 1               TK_BITTST         = TK_BINS+1       ; BITTST token
000000r 1               TK_MAX            = TK_BITTST+1     ; MAX token
000000r 1               TK_MIN            = TK_MAX+1        ; MIN token
000000r 1               TK_PI             = TK_MIN+1        ; PI token
000000r 1               TK_TWOPI          = TK_PI+1         ; TWOPI token
000000r 1               TK_VPTR           = TK_TWOPI+1      ; VARPTR token
000000r 1               TK_LEFTS          = TK_VPTR+1       ; LEFT$ token
000000r 1               TK_RIGHTS         = TK_LEFTS+1      ; RIGHT$ token
000000r 1               TK_MIDS           = TK_RIGHTS+1     ; MID$ token
000000r 1               
000000r 1               ; offsets from a base of X or Y
000000r 1               
000000r 1               PLUS_0            = $00       ; X or Y plus 0
000000r 1               PLUS_1            = $01       ; X or Y plus 1
000000r 1               PLUS_2            = $02       ; X or Y plus 2
000000r 1               PLUS_3            = $03       ; X or Y plus 3
000000r 1               
000000r 1               LAB_STAK          = $0100     ; stack bottom, no offset
000000r 1               
000000r 1               LAB_SKFE          = LAB_STAK+$FE
000000r 1                                             ; flushed stack address
000000r 1               LAB_SKFF          = LAB_STAK+$FF
000000r 1                                             ; flushed stack address
000000r 1               
000000r 1               ccflag            = $0200     ; BASIC CTRL-C flag, 00 = enabled, 01 = dis
000000r 1               ccbyte            = ccflag+1  ; BASIC CTRL-C byte
000000r 1               ccnull            = ccbyte+1  ; BASIC CTRL-C byte timeout
000000r 1               
000000r 1               VEC_CC            = ccnull+1  ; ctrl c check vector
000000r 1               
000000r 1               .ifndef SXB ; we'll hard-code thess
000000r 1               VEC_IN            = VEC_CC+2  ; input vector
000000r 1               VEC_OUT           = VEC_IN+2  ; output vector
000000r 1               VEC_LD            = VEC_OUT+2 ; load vector
000000r 1               VEC_SV            = VEC_LD+2  ; save vector
000000r 1               .endif
000000r 1               
000000r 1               ; Ibuffs can now be anywhere in RAM, ensure that the max length is < $80,
000000r 1               ; the input buffer must not cross a page boundary and must not overlap with
000000r 1               ; program RAM pages!
000000r 1               
000000r 1               ;Ibuffs            = IRQ_vec+$14
000000r 1               .ifdef SXB
000000r 1               Ibuffs = $0280
000000r 1               Ibuffe = $02FF
000000r 1               .else
000000r 1               Ibuffs            = VEC_SV+$16
000000r 1                                             ; start of input buffer after IRQ/NMI code
000000r 1               Ibuffe            = Ibuffs+$47; end of input buffer
000000r 1               .endif
000000r 1               
000000r 1               Ram_base          = $0400     ; start of user RAM (set as needed, should be page aligned)
000000r 1               Ram_top           = $7D00     ; end of user RAM+1 (set as needed, should be page aligned)
000000r 1               
000000r 1               ; This start can be changed to suit your system
000000r 1               
000000r 1               .if SXB
000000r 1               .org    $C000
00C000  1               .else
00C000  1                    *=    $C000
00C000  1               .endif
00C000  1               
00C000  1               ; BASIC cold start entry point
00C000  1               
00C000  1               ; new page 2 initialisation, copy block to ccflag on
00C000  1               
00C000  1               LAB_COLD
00C000  1  A0 04              LDY   #PG2_TABE-PG2_TABS-1
00C002  1                                             ; byte count-1
00C002  1               LAB_2D13
00C002  1  B9 DD E0           LDA   PG2_TABS,Y        ; get byte
00C005  1  99 00 02           STA   ccflag,Y          ; store in page 2
00C008  1  88                 DEY                     ; decrement count
00C009  1  10 F7              BPL   LAB_2D13          ; loop if not done
00C00B  1               
00C00B  1  A2 FF              LDX   #$FF              ; set byte
00C00D  1  86 88              STX   Clineh            ; set current line high byte (set immediate mode)
00C00F  1  9A                 TXS                     ; reset stack pointer
00C010  1               
00C010  1  A9 4C              LDA   #$4C              ; code for JMP
00C012  1  85 A1              STA   Fnxjmp            ; save for jump vector for functions
00C014  1               
00C014  1               ; copy block from LAB_2CEE to $00BC - $00D3
00C014  1               
00C014  1  A2 1C              LDX   #StrTab-LAB_2CEE  ; set byte count
00C016  1               LAB_2D4E
00C016  1  BD E1 E0           LDA   LAB_2CEE-1,X      ; get byte from table
00C019  1  95 BB              STA   LAB_IGBY-1,X      ; save byte in page zero
00C01B  1  CA                 DEX                     ; decrement count
00C01C  1  D0 F8              BNE   LAB_2D4E          ; loop if not all done
00C01E  1               
00C01E  1               ; copy block from StrTab to $0000 - $0012
00C01E  1               
00C01E  1               LAB_GMEM
00C01E  1  A2 12              LDX   #EndTab-StrTab-1  ; set byte count-1
00C020  1               TabLoop
00C020  1  BD FE E0           LDA   StrTab,X          ; get byte from table
00C023  1  95 00              STA   PLUS_0,X          ; save byte in page zero
00C025  1  CA                 DEX                     ; decrement count
00C026  1  10 F8              BPL   TabLoop           ; loop if not all done
00C028  1               
00C028  1               ; set-up start values
00C028  1               
00C028  1               .ifdef SXB
00C028  1  A9 00              LDA   #<Ram_base
00C02A  1  85 11              STA   Itempl
00C02C  1  A0 04              LDY   #>Ram_base
00C02E  1  84 12              STY   Itemph
00C030  1               .endif
00C030  1               
00C030  1  A9 00              LDA   #$00              ; clear A
00C032  1  85 DC              STA   NmiBase           ; clear NMI handler enabled flag
00C034  1  85 DF              STA   IrqBase           ; clear IRQ handler enabled flag
00C036  1  85 B2              STA   FAC1_o            ; clear FAC1 overflow byte
00C038  1  85 67              STA   last_sh           ; clear descriptor stack top item pointer high byte
00C03A  1               
00C03A  1  A9 0E              LDA   #$0E              ; set default tab size
00C03C  1  85 64              STA   TabSiz            ; save it
00C03E  1  A9 03              LDA   #$03              ; set garbage collect step size for descriptor stack
00C040  1  85 A0              STA   g_step            ; save it
00C042  1  A2 68              LDX   #des_sk           ; descriptor stack start
00C044  1  86 65              STX   next_s            ; set descriptor stack pointer
00C046  1  20 62 C8           JSR   LAB_CRLF          ; print CR/LF
00C049  1               .ifdef SXB
00C049  1  A9 00              lda   #<Ram_top
00C04B  1  A0 7D              ldy   #>Ram_top
00C04D  1               .else
00C04D  1                     LDA   #<LAB_MSZM        ; point to memory size message (low addr)
00C04D  1                     LDY   #>LAB_MSZM        ; point to memory size message (high addr)
00C04D  1                     JSR   LAB_18C3          ; print null terminated string from memory
00C04D  1                     JSR   LAB_INLN          ; print "? " and get BASIC input
00C04D  1                     STX   Bpntrl            ; set BASIC execute pointer low byte
00C04D  1                     STY   Bpntrh            ; set BASIC execute pointer high byte
00C04D  1                     JSR   LAB_GBYT          ; get last byte back
00C04D  1               
00C04D  1                     BNE   LAB_2DAA          ; branch if not null (user typed something)
00C04D  1               
00C04D  1                     LDY   #$00              ; else clear Y
00C04D  1                                             ; character was null so get memory size the hard way
00C04D  1                                             ; we get here with Y=0 and Itempl/h = Ram_base
00C04D  1               LAB_2D93
00C04D  1                     INC   Itempl            ; increment temporary integer low byte
00C04D  1                     BNE   LAB_2D99          ; branch if no overflow
00C04D  1               
00C04D  1                     INC   Itemph            ; increment temporary integer high byte
00C04D  1                     LDA   Itemph            ; get high byte
00C04D  1                     CMP   #>Ram_top         ; compare with top of RAM+1
00C04D  1                     BEQ   LAB_2DB6          ; branch if match (end of user RAM)
00C04D  1               
00C04D  1               LAB_2D99
00C04D  1                     LDA   #$55              ; set test byte
00C04D  1                     STA   (Itempl),Y        ; save via temporary integer
00C04D  1                     CMP   (Itempl),Y        ; compare via temporary integer
00C04D  1                     BNE   LAB_2DB6          ; branch if fail
00C04D  1               
00C04D  1                     ASL                     ; shift test byte left (now $AA)
00C04D  1                     STA   (Itempl),Y        ; save via temporary integer
00C04D  1                     CMP   (Itempl),Y        ; compare via temporary integer
00C04D  1                     BEQ   LAB_2D93          ; if ok go do next byte
00C04D  1               
00C04D  1                     BNE   LAB_2DB6          ; branch if fail
00C04D  1               
00C04D  1               LAB_2DAA
00C04D  1                     JSR   LAB_2887          ; get FAC1 from string
00C04D  1                     LDA   FAC1_e            ; get FAC1 exponent
00C04D  1                     CMP   #$98              ; compare with exponent = 2^24
00C04D  1                     BCS   LAB_GMEM          ; if too large go try again
00C04D  1               
00C04D  1                     JSR   LAB_F2FU          ; save integer part of FAC1 in temporary integer
00C04D  1                                             ; (no range check)
00C04D  1               
00C04D  1               LAB_2DB6
00C04D  1                     LDA   Itempl            ; get temporary integer low byte
00C04D  1                     LDY   Itemph            ; get temporary integer high byte
00C04D  1                     CPY   #<Ram_base+1      ; compare with start of RAM+$100 high byte
00C04D  1                     BCC   LAB_GMEM          ; if too small go try again
00C04D  1               
00C04D  1               
00C04D  1               ; uncomment these lines if you want to check on the high limit of memory. Note if
00C04D  1               ; Ram_top is set too low then this will fail. default is ignore it and assume the
00C04D  1               ; users know what they're doing!
00C04D  1               
00C04D  1               ;     CPY   #>Ram_top         ; compare with top of RAM high byte
00C04D  1               ;     BCC   MEM_OK            ; branch if < RAM top
00C04D  1               
00C04D  1               ;     BNE   LAB_GMEM          ; if too large go try again
00C04D  1                                             ; else was = so compare low bytes
00C04D  1               ;     CMP   #<Ram_top         ; compare with top of RAM low byte
00C04D  1               ;     BEQ   MEM_OK            ; branch if = RAM top
00C04D  1               
00C04D  1               ;     BCS   LAB_GMEM          ; if too large go try again
00C04D  1               
00C04D  1               ;MEM_OK
00C04D  1               
00C04D  1               .endif
00C04D  1  85 85              STA   Ememl             ; set end of mem low byte
00C04F  1  84 86              STY   Ememh             ; set end of mem high byte
00C051  1  85 81              STA   Sstorl            ; set bottom of string space low byte
00C053  1  84 82              STY   Sstorh            ; set bottom of string space high byte
00C055  1               
00C055  1  A0 00              LDY   #<Ram_base        ; set start addr low byte
00C057  1  A2 04              LDX   #>Ram_base        ; set start addr high byte
00C059  1  84 79              STY   Smeml             ; save start of mem low byte
00C05B  1  86 7A              STX   Smemh             ; save start of mem high byte
00C05D  1               
00C05D  1               ; this line is only needed if Ram_base is not $xx00
00C05D  1                     .IF   Ram_base&$FF>0
00C05D  1                     LDY   #$00              ; clear Y
00C05D  1                     .ENDIF
00C05D  1               
00C05D  1  98                 TYA                     ; clear A
00C05E  1  91 79              STA   (Smeml),Y         ; clear first byte
00C060  1  E6 79              INC   Smeml             ; increment start of mem low byte
00C062  1               
00C062  1               ; these two lines are only needed if Ram_base is $xxFF
00C062  1                     .IF   Ram_base & $FF = $FF
00C062  1                     BNE   LAB_2E05          ; branch if no rollover
00C062  1                     INC   Smemh             ; increment start of mem high byte
00C062  1               LAB_2E05
00C062  1                     .ENDIF
00C062  1               
00C062  1  20 62 C8           JSR   LAB_CRLF          ; print CR/LF
00C065  1  20 28 C3           JSR   LAB_1463          ; do "NEW" and "CLEAR"
00C068  1  A5 85              LDA   Ememl             ; get end of mem low byte
00C06A  1  38                 SEC                     ; set carry for subtract
00C06B  1  E5 79              SBC   Smeml             ; subtract start of mem low byte
00C06D  1  AA                 TAX                     ; copy to X
00C06E  1  A5 86              LDA   Ememh             ; get end of mem high byte
00C070  1  E5 7A              SBC   Smemh             ; subtract start of mem high byte
00C072  1  20 53 DA           JSR   LAB_295E          ; print XA as unsigned integer (bytes free)
00C075  1  A9 20              LDA   #<LAB_SMSG        ; point to sign-on message (low addr)
00C077  1  A0 E1              LDY   #>LAB_SMSG        ; point to sign-on message (high addr)
00C079  1  20 A3 C8           JSR   LAB_18C3          ; print null terminated string from memory
00C07C  1  A9 20              LDA   #<LAB_1274        ; warm start vector low byte
00C07E  1  A0 C1              LDY   #>LAB_1274        ; warm start vector high byte
00C080  1  85 01              STA   Wrmjpl            ; save warm start vector low byte
00C082  1  84 02              STY   Wrmjph            ; save warm start vector high byte
00C084  1  6C 01 00           JMP   (Wrmjpl)          ; go do warm start
00C087  1               
00C087  1               ; open up space in memory
00C087  1               ; move (Ostrtl)-(Obendl) to new block ending at (Nbendl)
00C087  1               
00C087  1               ; Nbendl,Nbendh - new block end address (A/Y)
00C087  1               ; Obendl,Obendh - old block end address
00C087  1               ; Ostrtl,Ostrth - old block start address
00C087  1               
00C087  1               ; returns with ..
00C087  1               
00C087  1               ; Nbendl,Nbendh - new block start address (high byte - $100)
00C087  1               ; Obendl,Obendh - old block start address (high byte - $100)
00C087  1               ; Ostrtl,Ostrth - old block start address (unchanged)
00C087  1               
00C087  1               LAB_11CF
00C087  1  20 D1 C0           JSR   LAB_121F          ; check available memory, "Out of memory" error if no room
00C08A  1                                             ; addr to check is in AY (low/high)
00C08A  1  85 7F              STA   Earryl            ; save new array mem end low byte
00C08C  1  84 80              STY   Earryh            ; save new array mem end high byte
00C08E  1               
00C08E  1               ; open up space in memory
00C08E  1               ; move (Ostrtl)-(Obendl) to new block ending at (Nbendl)
00C08E  1               ; don't set array end
00C08E  1               
00C08E  1               LAB_11D6
00C08E  1  38                 SEC                     ; set carry for subtract
00C08F  1  A5 A6              LDA   Obendl            ; get block end low byte
00C091  1  E5 AA              SBC   Ostrtl            ; subtract block start low byte
00C093  1  A8                 TAY                     ; copy MOD(block length/$100) byte to Y
00C094  1  A5 A7              LDA   Obendh            ; get block end high byte
00C096  1  E5 AB              SBC   Ostrth            ; subtract block start high byte
00C098  1  AA                 TAX                     ; copy block length high byte to X
00C099  1  E8                 INX                     ; +1 to allow for count=0 exit
00C09A  1  98                 TYA                     ; copy block length low byte to A
00C09B  1  F0 24              BEQ   LAB_120A          ; branch if length low byte=0
00C09D  1               
00C09D  1                                             ; block is (X-1)*256+Y bytes, do the Y bytes first
00C09D  1               
00C09D  1  38                 SEC                     ; set carry for add + 1, two's complement
00C09E  1  49 FF              EOR   #$FF              ; invert low byte for subtract
00C0A0  1  65 A6              ADC   Obendl            ; add block end low byte
00C0A2  1               
00C0A2  1  85 A6              STA   Obendl            ; save corrected old block end low byte
00C0A4  1  B0 03              BCS   LAB_11F3          ; branch if no underflow
00C0A6  1               
00C0A6  1  C6 A7              DEC   Obendh            ; else decrement block end high byte
00C0A8  1  38                 SEC                     ; set carry for add + 1, two's complement
00C0A9  1               LAB_11F3
00C0A9  1  98                 TYA                     ; get MOD(block length/$100) byte
00C0AA  1  49 FF              EOR   #$FF              ; invert low byte for subtract
00C0AC  1  65 A4              ADC   Nbendl            ; add destination end low byte
00C0AE  1  85 A4              STA   Nbendl            ; save modified new block end low byte
00C0B0  1  B0 08              BCS   LAB_1203          ; branch if no underflow
00C0B2  1               
00C0B2  1  C6 A5              DEC   Nbendh            ; else decrement block end high byte
00C0B4  1  90 04              BCC   LAB_1203          ; branch always
00C0B6  1               
00C0B6  1               LAB_11FF
00C0B6  1  B1 A6              LDA   (Obendl),Y        ; get byte from source
00C0B8  1  91 A4              STA   (Nbendl),Y        ; copy byte to destination
00C0BA  1               LAB_1203
00C0BA  1  88                 DEY                     ; decrement index
00C0BB  1  D0 F9              BNE   LAB_11FF          ; loop until Y=0
00C0BD  1               
00C0BD  1                                             ; now do Y=0 indexed byte
00C0BD  1  B1 A6              LDA   (Obendl),Y        ; get byte from source
00C0BF  1  91 A4              STA   (Nbendl),Y        ; save byte to destination
00C0C1  1               LAB_120A
00C0C1  1  C6 A7              DEC   Obendh            ; decrement source pointer high byte
00C0C3  1  C6 A5              DEC   Nbendh            ; decrement destination pointer high byte
00C0C5  1  CA                 DEX                     ; decrement block count
00C0C6  1  D0 F2              BNE   LAB_1203          ; loop until count = $0
00C0C8  1               
00C0C8  1  60                 RTS
00C0C9  1               
00C0C9  1               ; check room on stack for A bytes
00C0C9  1               ; stack too deep? do OM error
00C0C9  1               
00C0C9  1               LAB_1212
00C0C9  1  85 78              STA   TempB             ; save result in temp byte
00C0CB  1  BA                 TSX                     ; copy stack
00C0CC  1  E4 78              CPX   TempB             ; compare new "limit" with stack
00C0CE  1  90 30              BCC   LAB_OMER          ; if stack < limit do "Out of memory" error then warm start
00C0D0  1               
00C0D0  1  60                 RTS
00C0D1  1               
00C0D1  1               ; check available memory, "Out of memory" error if no room
00C0D1  1               ; addr to check is in AY (low/high)
00C0D1  1               
00C0D1  1               LAB_121F
00C0D1  1  C4 82              CPY   Sstorh            ; compare bottom of string mem high byte
00C0D3  1  90 2A              BCC   LAB_124B          ; if less then exit (is ok)
00C0D5  1               
00C0D5  1  D0 04              BNE   LAB_1229          ; skip next test if greater (tested <)
00C0D7  1               
00C0D7  1                                             ; high byte was =, now do low byte
00C0D7  1  C5 81              CMP   Sstorl            ; compare with bottom of string mem low byte
00C0D9  1  90 24              BCC   LAB_124B          ; if less then exit (is ok)
00C0DB  1               
00C0DB  1                                             ; addr is > string storage ptr (oops!)
00C0DB  1               LAB_1229
00C0DB  1  48                 PHA                     ; push addr low byte
00C0DC  1  A2 08              LDX   #$08              ; set index to save Adatal to expneg inclusive
00C0DE  1  98                 TYA                     ; copy addr high byte (to push on stack)
00C0DF  1               
00C0DF  1                                             ; save misc numeric work area
00C0DF  1               LAB_122D
00C0DF  1  48                 PHA                     ; push byte
00C0E0  1  B5 A3              LDA   Adatal-1,X        ; get byte from Adatal to expneg ( ,$00 not pushed)
00C0E2  1  CA                 DEX                     ; decrement index
00C0E3  1  10 FA              BPL   LAB_122D          ; loop until all done
00C0E5  1               
00C0E5  1  20 B0 D1           JSR   LAB_GARB          ; garbage collection routine
00C0E8  1               
00C0E8  1                                             ; restore misc numeric work area
00C0E8  1  A2 00              LDX   #$00              ; clear the index to restore bytes
00C0EA  1               LAB_1238
00C0EA  1  68                 PLA                     ; pop byte
00C0EB  1  95 A4              STA   Adatal,X          ; save byte to Adatal to expneg
00C0ED  1  E8                 INX                     ; increment index
00C0EE  1  E0 08              CPX   #$08              ; compare with end + 1
00C0F0  1  30 F8              BMI   LAB_1238          ; loop if more to do
00C0F2  1               
00C0F2  1  68                 PLA                     ; pop addr high byte
00C0F3  1  A8                 TAY                     ; copy back to Y
00C0F4  1  68                 PLA                     ; pop addr low byte
00C0F5  1  C4 82              CPY   Sstorh            ; compare bottom of string mem high byte
00C0F7  1  90 06              BCC   LAB_124B          ; if less then exit (is ok)
00C0F9  1               
00C0F9  1  D0 05              BNE   LAB_OMER          ; if greater do "Out of memory" error then warm start
00C0FB  1               
00C0FB  1                                             ; high byte was =, now do low byte
00C0FB  1  C5 81              CMP   Sstorl            ; compare with bottom of string mem low byte
00C0FD  1  B0 01              BCS   LAB_OMER          ; if >= do "Out of memory" error then warm start
00C0FF  1               
00C0FF  1                                             ; ok exit, carry clear
00C0FF  1               LAB_124B
00C0FF  1  60                 RTS
00C100  1               
00C100  1               ; do "Out of memory" error then warm start
00C100  1               
00C100  1               LAB_OMER
00C100  1  A2 0C              LDX   #$0C              ; error code $0C ("Out of memory" error)
00C102  1               
00C102  1               ; do error #X, then warm start
00C102  1               
00C102  1               LAB_XERR
00C102  1  20 62 C8           JSR   LAB_CRLF          ; print CR/LF
00C105  1               
00C105  1  BD 92 E6           LDA   LAB_BAER,X        ; get error message pointer low byte
00C108  1  BC 93 E6           LDY   LAB_BAER+1,X      ; get error message pointer high byte
00C10B  1  20 A3 C8           JSR   LAB_18C3          ; print null terminated string from memory
00C10E  1               
00C10E  1  20 61 C3           JSR   LAB_1491          ; flush stack and clear continue flag
00C111  1  A9 CF              LDA   #<LAB_EMSG        ; point to " Error" low addr
00C113  1  A0 E7              LDY   #>LAB_EMSG        ; point to " Error" high addr
00C115  1               LAB_1269
00C115  1  20 A3 C8           JSR   LAB_18C3          ; print null terminated string from memory
00C118  1  A4 88              LDY   Clineh            ; get current line high byte
00C11A  1  C8                 INY                     ; increment it
00C11B  1  F0 03              BEQ   LAB_1274          ; go do warm start (was immediate mode)
00C11D  1               
00C11D  1                                             ; else print line number
00C11D  1  20 48 DA           JSR   LAB_2953          ; print " in line [LINE #]"
00C120  1               
00C120  1               ; BASIC warm start entry point
00C120  1               ; wait for Basic command
00C120  1               
00C120  1               LAB_1274
00C120  1                                             ; clear ON IRQ/NMI bytes
00C120  1  A9 00              LDA   #$00              ; clear A
00C122  1  85 DF              STA   IrqBase           ; clear enabled byte
00C124  1  85 DC              STA   NmiBase           ; clear enabled byte
00C126  1  A9 E0              LDA   #<LAB_RMSG        ; point to "Ready" message low byte
00C128  1  A0 E7              LDY   #>LAB_RMSG        ; point to "Ready" message high byte
00C12A  1               
00C12A  1  20 A3 C8           JSR   LAB_18C3          ; go do print string
00C12D  1               
00C12D  1               ; wait for Basic command (no "Ready")
00C12D  1               
00C12D  1               LAB_127D
00C12D  1  20 13 C2           JSR   LAB_1357          ; call for BASIC input
00C130  1               LAB_1280
00C130  1  86 C3              STX   Bpntrl            ; set BASIC execute pointer low byte
00C132  1  84 C4              STY   Bpntrh            ; set BASIC execute pointer high byte
00C134  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C137  1  F0 F4              BEQ   LAB_127D          ; loop while null
00C139  1               
00C139  1               ; got to interpret input line now ..
00C139  1               
00C139  1  A2 FF              LDX   #$FF              ; current line to null value
00C13B  1  86 88              STX   Clineh            ; set current line high byte
00C13D  1  90 06              BCC   LAB_1295          ; branch if numeric character (handle new BASIC line)
00C13F  1               
00C13F  1                                             ; no line number .. immediate mode
00C13F  1  20 4A C2           JSR   LAB_13A6          ; crunch keywords into Basic tokens
00C142  1  4C C7 C4           JMP   LAB_15F6          ; go scan and interpret code
00C145  1               
00C145  1               ; handle new BASIC line
00C145  1               
00C145  1               LAB_1295
00C145  1  20 25 C7           JSR   LAB_GFPN          ; get fixed-point number into temp integer
00C148  1  20 4A C2           JSR   LAB_13A6          ; crunch keywords into Basic tokens
00C14B  1  84 5D              STY   Ibptr             ; save index pointer to end of crunched line
00C14D  1  20 FC C2           JSR   LAB_SSLN          ; search BASIC for temp integer line number
00C150  1  90 44              BCC   LAB_12E6          ; branch if not found
00C152  1               
00C152  1                                             ; aroooogah! line # already exists! delete it
00C152  1  A0 01              LDY   #$01              ; set index to next line pointer high byte
00C154  1  B1 AA              LDA   (Baslnl),Y        ; get next line pointer high byte
00C156  1  85 72              STA   ut1_ph            ; save it
00C158  1  A5 7B              LDA   Svarl             ; get start of vars low byte
00C15A  1  85 71              STA   ut1_pl            ; save it
00C15C  1  A5 AB              LDA   Baslnh            ; get found line pointer high byte
00C15E  1  85 74              STA   ut2_ph            ; save it
00C160  1  A5 AA              LDA   Baslnl            ; get found line pointer low byte
00C162  1  88                 DEY                     ; decrement index
00C163  1  F1 AA              SBC   (Baslnl),Y        ; subtract next line pointer low byte
00C165  1  18                 CLC                     ; clear carry for add
00C166  1  65 7B              ADC   Svarl             ; add start of vars low byte
00C168  1  85 7B              STA   Svarl             ; save new start of vars low byte
00C16A  1  85 73              STA   ut2_pl            ; save destination pointer low byte
00C16C  1  A5 7C              LDA   Svarh             ; get start of vars high byte
00C16E  1  69 FF              ADC   #$FF              ; -1 + carry
00C170  1  85 7C              STA   Svarh             ; save start of vars high byte
00C172  1  E5 AB              SBC   Baslnh            ; subtract found line pointer high byte
00C174  1  AA                 TAX                     ; copy to block count
00C175  1  38                 SEC                     ; set carry for subtract
00C176  1  A5 AA              LDA   Baslnl            ; get found line pointer low byte
00C178  1  E5 7B              SBC   Svarl             ; subtract start of vars low byte
00C17A  1  A8                 TAY                     ; copy to bytes in first block count
00C17B  1  B0 03              BCS   LAB_12D0          ; branch if overflow
00C17D  1               
00C17D  1  E8                 INX                     ; increment block count (correct for =0 loop exit)
00C17E  1  C6 74              DEC   ut2_ph            ; decrement destination high byte
00C180  1               LAB_12D0
00C180  1  18                 CLC                     ; clear carry for add
00C181  1  65 71              ADC   ut1_pl            ; add source pointer low byte
00C183  1  90 03              BCC   LAB_12D8          ; branch if no overflow
00C185  1               
00C185  1  C6 72              DEC   ut1_ph            ; else decrement source pointer high byte
00C187  1  18                 CLC                     ; clear carry
00C188  1               
00C188  1                                             ; close up memory to delete old line
00C188  1               LAB_12D8
00C188  1  B1 71              LDA   (ut1_pl),Y        ; get byte from source
00C18A  1  91 73              STA   (ut2_pl),Y        ; copy to destination
00C18C  1  C8                 INY                     ; increment index
00C18D  1  D0 F9              BNE   LAB_12D8          ; while <> 0 do this block
00C18F  1               
00C18F  1  E6 72              INC   ut1_ph            ; increment source pointer high byte
00C191  1  E6 74              INC   ut2_ph            ; increment destination pointer high byte
00C193  1  CA                 DEX                     ; decrement block count
00C194  1  D0 F2              BNE   LAB_12D8          ; loop until all done
00C196  1               
00C196  1                                             ; got new line in buffer and no existing same #
00C196  1               LAB_12E6
00C196  1  AD 80 02           LDA   Ibuffs            ; get byte from start of input buffer
00C199  1  F0 3F              BEQ   LAB_1319          ; if null line just go flush stack/vars and exit
00C19B  1               
00C19B  1                                             ; got new line and it isn't empty line
00C19B  1  A5 85              LDA   Ememl             ; get end of mem low byte
00C19D  1  A4 86              LDY   Ememh             ; get end of mem high byte
00C19F  1  85 81              STA   Sstorl            ; set bottom of string space low byte
00C1A1  1  84 82              STY   Sstorh            ; set bottom of string space high byte
00C1A3  1  A5 7B              LDA   Svarl             ; get start of vars low byte  (end of BASIC)
00C1A5  1  85 A6              STA   Obendl            ; save old block end low byte
00C1A7  1  A4 7C              LDY   Svarh             ; get start of vars high byte (end of BASIC)
00C1A9  1  84 A7              STY   Obendh            ; save old block end high byte
00C1AB  1  65 5D              ADC   Ibptr             ; add input buffer pointer    (also buffer length)
00C1AD  1  90 01              BCC   LAB_1301          ; branch if no overflow from add
00C1AF  1               
00C1AF  1  C8                 INY                     ; else increment high byte
00C1B0  1               LAB_1301
00C1B0  1  85 A4              STA   Nbendl            ; save new block end low byte (move to, low byte)
00C1B2  1  84 A5              STY   Nbendh            ; save new block end high byte
00C1B4  1  20 87 C0           JSR   LAB_11CF          ; open up space in memory
00C1B7  1                                             ; old start pointer Ostrtl,Ostrth set by the find line call
00C1B7  1  A5 7F              LDA   Earryl            ; get array mem end low byte
00C1B9  1  A4 80              LDY   Earryh            ; get array mem end high byte
00C1BB  1  85 7B              STA   Svarl             ; save start of vars low byte
00C1BD  1  84 7C              STY   Svarh             ; save start of vars high byte
00C1BF  1  A4 5D              LDY   Ibptr             ; get input buffer pointer    (also buffer length)
00C1C1  1  88                 DEY                     ; adjust for loop type
00C1C2  1               LAB_1311
00C1C2  1  B9 7C 02           LDA   Ibuffs-4,Y        ; get byte from crunched line
00C1C5  1  91 AA              STA   (Baslnl),Y        ; save it to program memory
00C1C7  1  88                 DEY                     ; decrement count
00C1C8  1  C0 03              CPY   #$03              ; compare with first byte-1
00C1CA  1  D0 F6              BNE   LAB_1311          ; continue while count <> 3
00C1CC  1               
00C1CC  1  A5 12              LDA   Itemph            ; get line # high byte
00C1CE  1  91 AA              STA   (Baslnl),Y        ; save it to program memory
00C1D0  1  88                 DEY                     ; decrement count
00C1D1  1  A5 11              LDA   Itempl            ; get line # low byte
00C1D3  1  91 AA              STA   (Baslnl),Y        ; save it to program memory
00C1D5  1  88                 DEY                     ; decrement count
00C1D6  1  A9 FF              LDA   #$FF              ; set byte to allow chain rebuild. if you didn't set this
00C1D8  1                                             ; byte then a zero already here would stop the chain rebuild
00C1D8  1                                             ; as it would think it was the [EOT] marker.
00C1D8  1  91 AA              STA   (Baslnl),Y        ; save it to program memory
00C1DA  1               
00C1DA  1               LAB_1319
00C1DA  1  20 3D C3           JSR   LAB_1477          ; reset execution to start, clear vars and flush stack
00C1DD  1  A6 79              LDX   Smeml             ; get start of mem low byte
00C1DF  1  A5 7A              LDA   Smemh             ; get start of mem high byte
00C1E1  1  A0 01              LDY   #$01              ; index to high byte of next line pointer
00C1E3  1               LAB_1325
00C1E3  1  86 71              STX   ut1_pl            ; set line start pointer low byte
00C1E5  1  85 72              STA   ut1_ph            ; set line start pointer high byte
00C1E7  1  B1 71              LDA   (ut1_pl),Y        ; get it
00C1E9  1  F0 18              BEQ   LAB_133E          ; exit if end of program
00C1EB  1               
00C1EB  1               ; rebuild chaining of Basic lines
00C1EB  1               
00C1EB  1  A0 04              LDY   #$04              ; point to first code byte of line
00C1ED  1                                             ; there is always 1 byte + [EOL] as null entries are deleted
00C1ED  1               LAB_1330
00C1ED  1  C8                 INY                     ; next code byte
00C1EE  1  B1 71              LDA   (ut1_pl),Y        ; get byte
00C1F0  1  D0 FB              BNE   LAB_1330          ; loop if not [EOL]
00C1F2  1               
00C1F2  1  38                 SEC                     ; set carry for add + 1
00C1F3  1  98                 TYA                     ; copy end index
00C1F4  1  65 71              ADC   ut1_pl            ; add to line start pointer low byte
00C1F6  1  AA                 TAX                     ; copy to X
00C1F7  1  A0 00              LDY   #$00              ; clear index, point to this line's next line pointer
00C1F9  1  91 71              STA   (ut1_pl),Y        ; set next line pointer low byte
00C1FB  1  98                 TYA                     ; clear A
00C1FC  1  65 72              ADC   ut1_ph            ; add line start pointer high byte + carry
00C1FE  1  C8                 INY                     ; increment index to high byte
00C1FF  1  91 71              STA   (ut1_pl),Y        ; save next line pointer low byte
00C201  1  90 E0              BCC   LAB_1325          ; go do next line, branch always, carry clear
00C203  1               
00C203  1               
00C203  1               LAB_133E
00C203  1  4C 2D C1           JMP   LAB_127D          ; else we just wait for Basic command, no "Ready"
00C206  1               
00C206  1               ; print "? " and get BASIC input
00C206  1               
00C206  1               LAB_INLN
00C206  1  20 BB C8           JSR   LAB_18E3          ; print "?" character
00C209  1  20 B8 C8           JSR   LAB_18E0          ; print " "
00C20C  1  D0 05              BNE   LAB_1357          ; call for BASIC input and return
00C20E  1               
00C20E  1               ; receive line from keyboard
00C20E  1               
00C20E  1                                             ; $08 as delete key (BACKSPACE on standard keyboard)
00C20E  1               LAB_134B
00C20E  1  20 BD C8           JSR   LAB_PRNA          ; go print the character
00C211  1  CA                 DEX                     ; decrement the buffer counter (delete)
00C212  1  2C                 .byte $2C               ; make LDX into BIT abs
00C213  1               
00C213  1               ; call for BASIC input (main entry point)
00C213  1               
00C213  1               LAB_1357
00C213  1  A2 00              LDX   #$00              ; clear BASIC line buffer pointer
00C215  1               LAB_1359
00C215  1  20 BD E0           JSR   V_INPT            ; call scan input device
00C218  1               
00C218  1  90 FB              BCC   LAB_1359          ; loop if no byte
00C21A  1               
00C21A  1  F0 F9              BEQ   LAB_1359          ; loop until valid input (ignore NULLs)
00C21C  1               
00C21C  1  C9 07              CMP   #$07              ; compare with [BELL]
00C21E  1  F0 16              BEQ   LAB_1378          ; branch if [BELL]
00C220  1               
00C220  1  C9 0D              CMP   #$0D              ; compare with [CR]
00C222  1  F0 1F              BEQ   LAB_1384          ; do CR/LF exit if [CR]
00C224  1               
00C224  1               .ifdef SXB
00C224  1  C9 7F              CMP   #$7F              ; [DELETE]
00C226  1  D0 02              BNE   :+
00C228  1  A9 08              LDA   #$08
00C22A  1               :
00C22A  1               .endif
00C22A  1               
00C22A  1  E0 00              CPX   #$00              ; compare pointer with $00
00C22C  1  D0 04              BNE   LAB_1374          ; branch if not empty
00C22E  1               
00C22E  1               ; next two lines ignore any non print character and [SPACE] if input buffer empty
00C22E  1               
00C22E  1  C9 21              CMP   #$21              ; compare with [SP]+1
00C230  1  90 E3              BCC   LAB_1359          ; if < ignore character
00C232  1               
00C232  1               LAB_1374
00C232  1  C9 08              CMP   #$08              ; compare with [BACKSPACE] (delete last character)
00C234  1  F0 D8              BEQ   LAB_134B          ; go delete last character
00C236  1               
00C236  1               LAB_1378
00C236  1  E0 7F              CPX   #Ibuffe-Ibuffs    ; compare character count with max
00C238  1  B0 0C              BCS   LAB_138E          ; skip store and do [BELL] if buffer full
00C23A  1               
00C23A  1  9D 80 02           STA   Ibuffs,X          ; else store in buffer
00C23D  1  E8                 INX                     ; increment pointer
00C23E  1               LAB_137F
00C23E  1  20 BD C8           JSR   LAB_PRNA          ; go print the character
00C241  1  D0 D2              BNE   LAB_1359          ; always loop for next character
00C243  1               
00C243  1               LAB_1384
00C243  1  4C 59 C8           JMP   LAB_1866          ; do CR/LF exit to BASIC
00C246  1               
00C246  1               ; announce buffer full
00C246  1               
00C246  1               LAB_138E
00C246  1  A9 07              LDA   #$07              ; [BELL] character into A
00C248  1  D0 F4              BNE   LAB_137F          ; go print the [BELL] but ignore input character
00C24A  1                                             ; branch always
00C24A  1               
00C24A  1               ; crunch keywords into Basic tokens
00C24A  1               ; position independent buffer version ..
00C24A  1               ; faster, dictionary search version ....
00C24A  1               
00C24A  1               LAB_13A6
00C24A  1  A0 FF              LDY   #$FF              ; set save index (makes for easy math later)
00C24C  1               
00C24C  1  38                 SEC                     ; set carry for subtract
00C24D  1  A5 C3              LDA   Bpntrl            ; get basic execute pointer low byte
00C24F  1  E9 80              SBC   #<Ibuffs          ; subtract input buffer start pointer
00C251  1  AA                 TAX                     ; copy result to X (index past line # if any)
00C252  1               
00C252  1  86 60              STX   Oquote            ; clear open quote/DATA flag
00C254  1               LAB_13AC
00C254  1  BD 80 02           LDA   Ibuffs,X          ; get byte from input buffer
00C257  1  F0 5D              BEQ   LAB_13EC          ; if null save byte then exit
00C259  1               
00C259  1               .ifdef SXB
00C259  1  C9 7B              CMP   #'{'              ; convert lower to upper case
00C25B  1  B0 59              BCS   LAB_13EC          ; is above lower case
00C25D  1  C9 61              CMP   #'a'
00C25F  1  90 02              BCC   PATCH_LC          ; is below lower case
00C261  1  29 DF              AND   #$DF              ; mask lower case bit
00C263  1               
00C263  1               PATCH_LC
00C263  1               .endif
00C263  1               
00C263  1  C9 5F              CMP   #'_'              ; compare with "_"
00C265  1  B0 4F              BCS   LAB_13EC          ; if >= go save byte then continue crunching
00C267  1               
00C267  1  C9 3C              CMP   #'<'              ; compare with "<"
00C269  1  B0 0E              BCS   LAB_13CC          ; if >= go crunch now
00C26B  1               
00C26B  1  C9 30              CMP   #'0'              ; compare with "0"
00C26D  1  B0 47              BCS   LAB_13EC          ; if >= go save byte then continue crunching
00C26F  1               
00C26F  1  85 5C              STA   Scnquo            ; save buffer byte as search character
00C271  1  C9 22              CMP   #$22              ; is it quote character?
00C273  1  F0 63              BEQ   LAB_1410          ; branch if so (copy quoted string)
00C275  1               
00C275  1  C9 2A              CMP   #'*'              ; compare with "*"
00C277  1  90 3D              BCC   LAB_13EC          ; if < go save byte then continue crunching
00C279  1               
00C279  1                                             ; else crunch now
00C279  1               LAB_13CC
00C279  1  24 60              BIT   Oquote            ; get open quote/DATA token flag
00C27B  1  70 39              BVS   LAB_13EC          ; branch if b6 of Oquote set (was DATA)
00C27D  1                                             ; go save byte then continue crunching
00C27D  1               
00C27D  1  86 78              STX   TempB             ; save buffer read index
00C27F  1  84 BA              STY   csidx             ; copy buffer save index
00C281  1  A0 F9              LDY   #<TAB_1STC        ; get keyword first character table low address
00C283  1  84 73              STY   ut2_pl            ; save pointer low byte
00C285  1  A0 E2              LDY   #>TAB_1STC        ; get keyword first character table high address
00C287  1  84 74              STY   ut2_ph            ; save pointer high byte
00C289  1  A0 00              LDY   #$00              ; clear table pointer
00C28B  1               
00C28B  1               LAB_13D0
00C28B  1  D1 73              CMP   (ut2_pl),Y        ; compare with keyword first character table byte
00C28D  1  F0 05              BEQ   LAB_13D1          ; go do word_table_chr if match
00C28F  1               .ifdef SXB
00C28F  1  90 5B              BCC   PATCH_LC2         ; if < keyword first character table byte go restore
00C291  1               .else
00C291  1                     BCC   LAB_13EA          ; if < keyword first character table byte go restore
00C291  1                                             ; Y and save to crunched
00C291  1               .endif
00C291  1  C8                 INY                     ; else increment pointer
00C292  1  D0 F7              BNE   LAB_13D0          ; and loop (branch always)
00C294  1               
00C294  1               ; have matched first character of some keyword
00C294  1               
00C294  1               LAB_13D1
00C294  1  98                 TYA                     ; copy matching index
00C295  1  0A                 ASL                     ; *2 (bytes per pointer)
00C296  1  AA                 TAX                     ; copy to new index
00C297  1  BD 17 E3           LDA   TAB_CHRT,X        ; get keyword table pointer low byte
00C29A  1  85 73              STA   ut2_pl            ; save pointer low byte
00C29C  1  BD 18 E3           LDA   TAB_CHRT+1,X      ; get keyword table pointer high byte
00C29F  1  85 74              STA   ut2_ph            ; save pointer high byte
00C2A1  1               
00C2A1  1  A0 FF              LDY   #$FF              ; clear table pointer (make -1 for start)
00C2A3  1               
00C2A3  1  A6 78              LDX   TempB             ; restore buffer read index
00C2A5  1               
00C2A5  1               LAB_13D6
00C2A5  1  C8                 INY                     ; next table byte
00C2A6  1  B1 73              LDA   (ut2_pl),Y        ; get byte from table
00C2A8  1               LAB_13D8
00C2A8  1  30 0A              BMI   LAB_13EA          ; all bytes matched so go save token
00C2AA  1               
00C2AA  1  E8                 INX                     ; next buffer byte
00C2AB  1               .ifdef SXB
00C2AB  1  5D 80 02           EOR     Ibuffs,x        ; check bits against table
00C2AE  1  29 DF              AND     #$DF            ; DF masks the upper/lower case bit
00C2B0  1               .else
00C2B0  1                     CMP   Ibuffs,X          ; compare with byte from input buffer
00C2B0  1               .endif
00C2B0  1  F0 F3              BEQ   LAB_13D6          ; go compare next if match
00C2B2  1               
00C2B2  1  D0 2B              BNE   LAB_1417          ; branch if >< (not found keyword)
00C2B4  1               
00C2B4  1               LAB_13EA
00C2B4  1  A4 BA              LDY   csidx             ; restore save index
00C2B6  1               
00C2B6  1                                             ; save crunched to output
00C2B6  1               LAB_13EC
00C2B6  1  E8                 INX                     ; increment buffer index (to next input byte)
00C2B7  1  C8                 INY                     ; increment save index (to next output byte)
00C2B8  1  99 80 02           STA   Ibuffs,Y          ; save byte to output
00C2BB  1  C9 00              CMP   #$00              ; set the flags, set carry
00C2BD  1  F0 32              BEQ   LAB_142A          ; do exit if was null [EOL]
00C2BF  1               
00C2BF  1                                             ; A holds token or byte here
00C2BF  1  E9 3A              SBC   #':'              ; subtract ":" (carry set by CMP #00)
00C2C1  1  F0 04              BEQ   LAB_13FF          ; branch if it was ":" (is now $00)
00C2C3  1               
00C2C3  1                                             ; A now holds token-$3A
00C2C3  1  C9 49              CMP   #TK_DATA-$3A      ; compare with DATA token - $3A
00C2C5  1  D0 02              BNE   LAB_1401          ; branch if not DATA
00C2C7  1               
00C2C7  1                                             ; token was : or DATA
00C2C7  1               LAB_13FF
00C2C7  1  85 60              STA   Oquote            ; save token-$3A (clear for ":", TK_DATA-$3A for DATA)
00C2C9  1               LAB_1401
00C2C9  1  49 57              EOR   #TK_REM-$3A       ; effectively subtract REM token offset
00C2CB  1  D0 87              BNE   LAB_13AC          ; If wasn't REM then go crunch rest of line
00C2CD  1               
00C2CD  1  85 5C              STA   Asrch             ; else was REM so set search for [EOL]
00C2CF  1               
00C2CF  1                                             ; loop for REM, "..." etc.
00C2CF  1               LAB_1408
00C2CF  1  BD 80 02           LDA   Ibuffs,X          ; get byte from input buffer
00C2D2  1  F0 E2              BEQ   LAB_13EC          ; branch if null [EOL]
00C2D4  1               
00C2D4  1  C5 5C              CMP   Asrch             ; compare with stored character
00C2D6  1  F0 DE              BEQ   LAB_13EC          ; branch if match (end quote)
00C2D8  1               
00C2D8  1                                             ; entry for copy string in quotes, don't crunch
00C2D8  1               LAB_1410
00C2D8  1  C8                 INY                     ; increment buffer save index
00C2D9  1  99 80 02           STA   Ibuffs,Y          ; save byte to output
00C2DC  1  E8                 INX                     ; increment buffer read index
00C2DD  1  D0 F0              BNE   LAB_1408          ; loop while <> 0 (should never be 0!)
00C2DF  1               
00C2DF  1                                             ; not found keyword this go
00C2DF  1               LAB_1417
00C2DF  1  A6 78              LDX   TempB             ; compare has failed, restore buffer index (start byte!)
00C2E1  1               
00C2E1  1                                             ; now find the end of this word in the table
00C2E1  1               LAB_141B
00C2E1  1  B1 73              LDA   (ut2_pl),Y        ; get table byte
00C2E3  1  08                 PHP                     ; save status
00C2E4  1  C8                 INY                     ; increment table index
00C2E5  1  28                 PLP                     ; restore byte status
00C2E6  1  10 F9              BPL   LAB_141B          ; if not end of keyword go do next
00C2E8  1               
00C2E8  1  B1 73              LDA   (ut2_pl),Y        ; get byte from keyword table
00C2EA  1  D0 BC              BNE   LAB_13D8          ; go test next word if not zero byte (end of table)
00C2EC  1               
00C2EC  1                                             ; reached end of table with no match
00C2EC  1               .ifdef SXB
00C2EC  1               PATCH_LC2
00C2EC  1               .endif
00C2EC  1  BD 80 02           LDA   Ibuffs,X          ; restore byte from input buffer
00C2EF  1  10 C3              BPL   LAB_13EA          ; branch always (all bytes in buffer are $00-$7F)
00C2F1  1                                             ; go save byte in output and continue crunching
00C2F1  1               
00C2F1  1                                             ; reached [EOL]
00C2F1  1               LAB_142A
00C2F1  1  C8                 INY                     ; increment pointer
00C2F2  1  C8                 INY                     ; increment pointer (makes it next line pointer high byte)
00C2F3  1  99 80 02           STA   Ibuffs,Y          ; save [EOL] (marks [EOT] in immediate mode)
00C2F6  1  C8                 INY                     ; adjust for line copy
00C2F7  1  C8                 INY                     ; adjust for line copy
00C2F8  1  C8                 INY                     ; adjust for line copy
00C2F9  1               ; *** begin patch for when Ibuffs is $xx00 - Daryl Rictor ***
00C2F9  1               ; *** insert
00C2F9  1                     .IF   Ibuffs & $FF = 0
00C2F9  1                     LDA   Bpntrl            ; test for $00
00C2F9  1                     BNE   LAB_142P          ; not $00
00C2F9  1                     DEC   Bpntrh            ; allow for increment when $xx00
00C2F9  1               LAB_142P
00C2F9  1                     .ENDIF
00C2F9  1               ; *** end   patch for when Ibuffs is $xx00 - Daryl Rictor ***
00C2F9  1               ; end of patch
00C2F9  1  C6 C3              DEC   Bpntrl            ; allow for increment
00C2FB  1  60                 RTS
00C2FC  1               
00C2FC  1               ; search Basic for temp integer line number from start of mem
00C2FC  1               
00C2FC  1               LAB_SSLN
00C2FC  1  A5 79              LDA   Smeml             ; get start of mem low byte
00C2FE  1  A6 7A              LDX   Smemh             ; get start of mem high byte
00C300  1               
00C300  1               ; search Basic for temp integer line number from AX
00C300  1               ; returns carry set if found
00C300  1               ; returns Baslnl/Baslnh pointer to found or next higher (not found) line
00C300  1               
00C300  1               ; old 541 new 507
00C300  1               
00C300  1               LAB_SHLN
00C300  1  A0 01              LDY   #$01              ; set index
00C302  1  85 AA              STA   Baslnl            ; save low byte as current
00C304  1  86 AB              STX   Baslnh            ; save high byte as current
00C306  1  B1 AA              LDA   (Baslnl),Y        ; get pointer high byte from addr
00C308  1  F0 1A              BEQ   LAB_145F          ; pointer was zero so we're done, do 'not found' exit
00C30A  1               
00C30A  1  A0 03              LDY   #$03              ; set index to line # high byte
00C30C  1  B1 AA              LDA   (Baslnl),Y        ; get line # high byte
00C30E  1  88                 DEY                     ; decrement index (point to low byte)
00C30F  1  C5 12              CMP   Itemph            ; compare with temporary integer high byte
00C311  1  D0 04              BNE   LAB_1455          ; if <> skip low byte check
00C313  1               
00C313  1  B1 AA              LDA   (Baslnl),Y        ; get line # low byte
00C315  1  C5 11              CMP   Itempl            ; compare with temporary integer low byte
00C317  1               LAB_1455
00C317  1  B0 09              BCS   LAB_145E          ; else if temp < this line, exit (passed line#)
00C319  1               
00C319  1               LAB_1456
00C319  1  88                 DEY                     ; decrement index to next line ptr high byte
00C31A  1  B1 AA              LDA   (Baslnl),Y        ; get next line pointer high byte
00C31C  1  AA                 TAX                     ; copy to X
00C31D  1  88                 DEY                     ; decrement index to next line ptr low byte
00C31E  1  B1 AA              LDA   (Baslnl),Y        ; get next line pointer low byte
00C320  1  90 DE              BCC   LAB_SHLN          ; go search for line # in temp (Itempl/Itemph) from AX
00C322  1                                             ; (carry always clear)
00C322  1               
00C322  1               LAB_145E
00C322  1  F0 01              BEQ   LAB_1460          ; exit if temp = found line #, carry is set
00C324  1               
00C324  1               LAB_145F
00C324  1  18                 CLC                     ; clear found flag
00C325  1               LAB_1460
00C325  1  60                 RTS
00C326  1               
00C326  1               ; perform NEW
00C326  1               
00C326  1               LAB_NEW
00C326  1  D0 FD              BNE   LAB_1460          ; exit if not end of statement (to do syntax error)
00C328  1               
00C328  1               LAB_1463
00C328  1  A9 00              LDA   #$00              ; clear A
00C32A  1  A8                 TAY                     ; clear Y
00C32B  1  91 79              STA   (Smeml),Y         ; clear first line, next line pointer, low byte
00C32D  1  C8                 INY                     ; increment index
00C32E  1  91 79              STA   (Smeml),Y         ; clear first line, next line pointer, high byte
00C330  1  18                 CLC                     ; clear carry
00C331  1  A5 79              LDA   Smeml             ; get start of mem low byte
00C333  1  69 02              ADC   #$02              ; calculate end of BASIC low byte
00C335  1  85 7B              STA   Svarl             ; save start of vars low byte
00C337  1  A5 7A              LDA   Smemh             ; get start of mem high byte
00C339  1  69 00              ADC   #$00              ; add any carry
00C33B  1  85 7C              STA   Svarh             ; save start of vars high byte
00C33D  1               
00C33D  1               ; reset execution to start, clear vars and flush stack
00C33D  1               
00C33D  1               LAB_1477
00C33D  1  18                 CLC                     ; clear carry
00C33E  1  A5 79              LDA   Smeml             ; get start of mem low byte
00C340  1  69 FF              ADC   #$FF              ; -1
00C342  1  85 C3              STA   Bpntrl            ; save BASIC execute pointer low byte
00C344  1  A5 7A              LDA   Smemh             ; get start of mem high byte
00C346  1  69 FF              ADC   #$FF              ; -1+carry
00C348  1  85 C4              STA   Bpntrh            ; save BASIC execute pointer high byte
00C34A  1               
00C34A  1               ; "CLEAR" command gets here
00C34A  1               
00C34A  1               LAB_147A
00C34A  1  A5 85              LDA   Ememl             ; get end of mem low byte
00C34C  1  A4 86              LDY   Ememh             ; get end of mem high byte
00C34E  1  85 81              STA   Sstorl            ; set bottom of string space low byte
00C350  1  84 82              STY   Sstorh            ; set bottom of string space high byte
00C352  1  A5 7B              LDA   Svarl             ; get start of vars low byte
00C354  1  A4 7C              LDY   Svarh             ; get start of vars high byte
00C356  1  85 7D              STA   Sarryl            ; save var mem end low byte
00C358  1  84 7E              STY   Sarryh            ; save var mem end high byte
00C35A  1  85 7F              STA   Earryl            ; save array mem end low byte
00C35C  1  84 80              STY   Earryh            ; save array mem end high byte
00C35E  1  20 12 C5           JSR   LAB_161A          ; perform RESTORE command
00C361  1               
00C361  1               ; flush stack and clear continue flag
00C361  1               
00C361  1               LAB_1491
00C361  1  A2 68              LDX   #des_sk           ; set descriptor stack pointer
00C363  1  86 65              STX   next_s            ; save descriptor stack pointer
00C365  1  68                 PLA                     ; pull return address low byte
00C366  1  AA                 TAX                     ; copy return address low byte
00C367  1  68                 PLA                     ; pull return address high byte
00C368  1  8E FE 01           STX   LAB_SKFE          ; save to cleared stack
00C36B  1  8D FF 01           STA   LAB_SKFF          ; save to cleared stack
00C36E  1  A2 FD              LDX   #$FD              ; new stack pointer
00C370  1  9A                 TXS                     ; reset stack
00C371  1  A9 00              LDA   #$00              ; clear byte
00C373  1               ;*** fix p2: no longer necessary as the continue pointer is saved anyway
00C373  1               ;      STA   Cpntrh            ; clear continue pointer high byte
00C373  1  85 61              STA   Sufnxf            ; clear subscript/FNX flag
00C375  1               LAB_14A6
00C375  1  60                 RTS
00C376  1               
00C376  1               ; perform CLEAR
00C376  1               
00C376  1               LAB_CLEAR
00C376  1  F0 D2              BEQ   LAB_147A          ; if no following token go do "CLEAR"
00C378  1               
00C378  1                                             ; else there was a following token (go do syntax error)
00C378  1  60                 RTS
00C379  1               
00C379  1               ; perform LIST [n][-m]
00C379  1               ; bigger, faster version (a _lot_ faster)
00C379  1               
00C379  1               LAB_LIST
00C379  1  90 06              BCC   LAB_14BD          ; branch if next character numeric (LIST n..)
00C37B  1               
00C37B  1  F0 04              BEQ   LAB_14BD          ; branch if next character [NULL] (LIST)
00C37D  1               
00C37D  1  C9 B7              CMP   #TK_MINUS         ; compare with token for -
00C37F  1  D0 F4              BNE   LAB_14A6          ; exit if not - (LIST -m)
00C381  1               
00C381  1                                             ; LIST [[n][-m]]
00C381  1                                             ; this bit sets the n , if present, as the start and end
00C381  1               LAB_14BD
00C381  1  20 25 C7           JSR   LAB_GFPN          ; get fixed-point number into temp integer
00C384  1  20 FC C2           JSR   LAB_SSLN          ; search BASIC for temp integer line number
00C387  1                                             ; (pointer in Baslnl/Baslnh)
00C387  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C38A  1  F0 0C              BEQ   LAB_14D4          ; branch if no more characters
00C38C  1               
00C38C  1                                             ; this bit checks the - is present
00C38C  1  C9 B7              CMP   #TK_MINUS         ; compare with token for -
00C38E  1  D0 95              BNE   LAB_1460          ; return if not "-" (will be Syntax error)
00C390  1               
00C390  1                                             ; LIST [n]-m
00C390  1                                             ; the - was there so set m as the end value
00C390  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C393  1  20 25 C7           JSR   LAB_GFPN          ; get fixed-point number into temp integer
00C396  1  D0 8D              BNE   LAB_1460          ; exit if not ok
00C398  1               
00C398  1               LAB_14D4
00C398  1  A5 11              LDA   Itempl            ; get temporary integer low byte
00C39A  1  05 12              ORA   Itemph            ; OR temporary integer high byte
00C39C  1  D0 06              BNE   LAB_14E2          ; branch if start set
00C39E  1               
00C39E  1  A9 FF              LDA   #$FF              ; set for -1
00C3A0  1  85 11              STA   Itempl            ; set temporary integer low byte
00C3A2  1  85 12              STA   Itemph            ; set temporary integer high byte
00C3A4  1               LAB_14E2
00C3A4  1  A0 01              LDY   #$01              ; set index for line
00C3A6  1  84 60              STY   Oquote            ; clear open quote flag
00C3A8  1  20 62 C8           JSR   LAB_CRLF          ; print CR/LF
00C3AB  1  B1 AA              LDA   (Baslnl),Y        ; get next line pointer high byte
00C3AD  1                                             ; pointer initially set by search at LAB_14BD
00C3AD  1  F0 3E              BEQ   LAB_152B          ; if null all done so exit
00C3AF  1  20 E8 C4           JSR   LAB_1629          ; do CRTL-C check vector
00C3B2  1               
00C3B2  1  C8                 INY                     ; increment index for line
00C3B3  1  B1 AA              LDA   (Baslnl),Y        ; get line # low byte
00C3B5  1  AA                 TAX                     ; copy to X
00C3B6  1  C8                 INY                     ; increment index
00C3B7  1  B1 AA              LDA   (Baslnl),Y        ; get line # high byte
00C3B9  1  C5 12              CMP   Itemph            ; compare with temporary integer high byte
00C3BB  1  D0 04              BNE   LAB_14FF          ; branch if no high byte match
00C3BD  1               
00C3BD  1  E4 11              CPX   Itempl            ; compare with temporary integer low byte
00C3BF  1  F0 02              BEQ   LAB_1501          ; branch if = last line to do (< will pass next branch)
00C3C1  1               
00C3C1  1               LAB_14FF                      ; else ..
00C3C1  1  B0 2A              BCS   LAB_152B          ; if greater all done so exit
00C3C3  1               
00C3C3  1               LAB_1501
00C3C3  1  84 97              STY   Tidx1             ; save index for line
00C3C5  1  20 53 DA           JSR   LAB_295E          ; print XA as unsigned integer
00C3C8  1  A9 20              LDA   #$20              ; space is the next character
00C3CA  1               LAB_1508
00C3CA  1  A4 97              LDY   Tidx1             ; get index for line
00C3CC  1  29 7F              AND   #$7F              ; mask top out bit of character
00C3CE  1               LAB_150C
00C3CE  1  20 BD C8           JSR   LAB_PRNA          ; go print the character
00C3D1  1  C9 22              CMP   #$22              ; was it " character
00C3D3  1  D0 06              BNE   LAB_1519          ; branch if not
00C3D5  1               
00C3D5  1                                             ; we are either entering or leaving a pair of quotes
00C3D5  1  A5 60              LDA   Oquote            ; get open quote flag
00C3D7  1  49 FF              EOR   #$FF              ; toggle it
00C3D9  1  85 60              STA   Oquote            ; save it back
00C3DB  1               LAB_1519
00C3DB  1  C8                 INY                     ; increment index
00C3DC  1  B1 AA              LDA   (Baslnl),Y        ; get next byte
00C3DE  1  D0 0E              BNE   LAB_152E          ; branch if not [EOL] (go print character)
00C3E0  1  A8                 TAY                     ; else clear index
00C3E1  1  B1 AA              LDA   (Baslnl),Y        ; get next line pointer low byte
00C3E3  1  AA                 TAX                     ; copy to X
00C3E4  1  C8                 INY                     ; increment index
00C3E5  1  B1 AA              LDA   (Baslnl),Y        ; get next line pointer high byte
00C3E7  1  86 AA              STX   Baslnl            ; set pointer to line low byte
00C3E9  1  85 AB              STA   Baslnh            ; set pointer to line high byte
00C3EB  1  D0 B7              BNE   LAB_14E2          ; go do next line if not [EOT]
00C3ED  1                                             ; else ..
00C3ED  1               LAB_152B
00C3ED  1  60                 RTS
00C3EE  1               
00C3EE  1               LAB_152E
00C3EE  1  10 DE              BPL   LAB_150C          ; just go print it if not token byte
00C3F0  1               
00C3F0  1                                             ; else was token byte so uncrunch it (maybe)
00C3F0  1  24 60              BIT   Oquote            ; test the open quote flag
00C3F2  1  30 DA              BMI   LAB_150C          ; just go print character if open quote set
00C3F4  1               
00C3F4  1  A2 E4              LDX   #>LAB_KEYT        ; get table address high byte
00C3F6  1  0A                 ASL                     ; *2
00C3F7  1  0A                 ASL                     ; *4
00C3F8  1  90 02              BCC   LAB_152F          ; branch if no carry
00C3FA  1               
00C3FA  1  E8                 INX                     ; else increment high byte
00C3FB  1  18                 CLC                     ; clear carry for add
00C3FC  1               LAB_152F
00C3FC  1  69 FA              ADC   #<LAB_KEYT        ; add low byte
00C3FE  1  90 01              BCC   LAB_1530          ; branch if no carry
00C400  1               
00C400  1  E8                 INX                     ; else increment high byte
00C401  1               LAB_1530
00C401  1  85 73              STA   ut2_pl            ; save table pointer low byte
00C403  1  86 74              STX   ut2_ph            ; save table pointer high byte
00C405  1  84 97              STY   Tidx1             ; save index for line
00C407  1  A0 00              LDY   #$00              ; clear index
00C409  1  B1 73              LDA   (ut2_pl),Y        ; get length
00C40B  1  AA                 TAX                     ; copy length
00C40C  1  C8                 INY                     ; increment index
00C40D  1  B1 73              LDA   (ut2_pl),Y        ; get 1st character
00C40F  1  CA                 DEX                     ; decrement length
00C410  1  F0 B8              BEQ   LAB_1508          ; if no more characters exit and print
00C412  1               
00C412  1  20 BD C8           JSR   LAB_PRNA          ; go print the character
00C415  1  C8                 INY                     ; increment index
00C416  1  B1 73              LDA   (ut2_pl),Y        ; get keyword address low byte
00C418  1  48                 PHA                     ; save it for now
00C419  1  C8                 INY                     ; increment index
00C41A  1  B1 73              LDA   (ut2_pl),Y        ; get keyword address high byte
00C41C  1  A0 00              LDY   #$00
00C41E  1  85 74              STA   ut2_ph            ; save keyword pointer high byte
00C420  1  68                 PLA                     ; pull low byte
00C421  1  85 73              STA   ut2_pl            ; save keyword pointer low byte
00C423  1               LAB_1540
00C423  1  B1 73              LDA   (ut2_pl),Y        ; get character
00C425  1  CA                 DEX                     ; decrement character count
00C426  1  F0 A2              BEQ   LAB_1508          ; if last character exit and print
00C428  1               
00C428  1  20 BD C8           JSR   LAB_PRNA          ; go print the character
00C42B  1  C8                 INY                     ; increment index
00C42C  1  D0 F5              BNE   LAB_1540          ; loop for next character
00C42E  1               
00C42E  1               ; perform FOR
00C42E  1               
00C42E  1               LAB_FOR
00C42E  1  A9 80              LDA   #$80              ; set FNX
00C430  1  85 61              STA   Sufnxf            ; set subscript/FNX flag
00C432  1  20 84 C7           JSR   LAB_LET           ; go do LET
00C435  1  68                 PLA                     ; pull return address
00C436  1  68                 PLA                     ; pull return address
00C437  1  A9 10              LDA   #$10              ; we need 16d bytes !
00C439  1  20 C9 C0           JSR   LAB_1212          ; check room on stack for A bytes
00C43C  1  20 6D C6           JSR   LAB_SNBS          ; scan for next BASIC statement ([:] or [EOL])
00C43F  1  18                 CLC                     ; clear carry for add
00C440  1  98                 TYA                     ; copy index to A
00C441  1  65 C3              ADC   Bpntrl            ; add BASIC execute pointer low byte
00C443  1  48                 PHA                     ; push onto stack
00C444  1  A5 C4              LDA   Bpntrh            ; get BASIC execute pointer high byte
00C446  1  69 00              ADC   #$00              ; add carry
00C448  1  48                 PHA                     ; push onto stack
00C449  1  A5 88              LDA   Clineh            ; get current line high byte
00C44B  1  48                 PHA                     ; push onto stack
00C44C  1  A5 87              LDA   Clinel            ; get current line low byte
00C44E  1  48                 PHA                     ; push onto stack
00C44F  1  A9 AD              LDA   #TK_TO            ; get "TO" token
00C451  1  20 C0 CB           JSR   LAB_SCCA          ; scan for CHR$(A) , else do syntax error then warm start
00C454  1  20 9F CA           JSR   LAB_CTNM          ; check if source is numeric, else do type mismatch
00C457  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00C45A  1                                             ; else do type mismatch
00C45A  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00C45C  1  09 7F              ORA   #$7F              ; set all non sign bits
00C45E  1  25 AD              AND   FAC1_1            ; and FAC1 mantissa1
00C460  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00C462  1  A9 6D              LDA   #<LAB_159F        ; set return address low byte
00C464  1  A0 C4              LDY   #>LAB_159F        ; set return address high byte
00C466  1  85 71              STA   ut1_pl            ; save return address low byte
00C468  1  84 72              STY   ut1_ph            ; save return address high byte
00C46A  1  4C 53 CB           JMP   LAB_1B66          ; round FAC1 and put on stack (returns to next instruction)
00C46D  1               
00C46D  1               LAB_159F
00C46D  1  A9 C9              LDA   #<LAB_259C        ; set 1 pointer low addr (default step size)
00C46F  1  A0 E1              LDY   #>LAB_259C        ; set 1 pointer high addr
00C471  1  20 4E D8           JSR   LAB_UFAC          ; unpack memory (AY) into FAC1
00C474  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C477  1  C9 B2              CMP   #TK_STEP          ; compare with STEP token
00C479  1  D0 06              BNE   LAB_15B3          ; jump if not "STEP"
00C47B  1               
00C47B  1                                             ;.was step so ..
00C47B  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C47E  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00C481  1                                             ; else do type mismatch
00C481  1               LAB_15B3
00C481  1  20 BA D8           JSR   LAB_27CA          ; return A=FF,C=1/-ve A=01,C=0/+ve
00C484  1  85 B0              STA   FAC1_s            ; set FAC1 sign (b7)
00C486  1                                             ; this is +1 for +ve step and -1 for -ve step, in NEXT we
00C486  1                                             ; compare the FOR value and the TO value and return +1 if
00C486  1                                             ; FOR > TO, 0 if FOR = TO and -1 if FOR < TO. the value
00C486  1                                             ; here (+/-1) is then compared to that result and if they
00C486  1                                             ; are the same (+ve and FOR > TO or -ve and FOR < TO) then
00C486  1                                             ; the loop is done
00C486  1  20 48 CB           JSR   LAB_1B5B          ; push sign, round FAC1 and put on stack
00C489  1  A5 98              LDA   Frnxth            ; get var pointer for FOR/NEXT high byte
00C48B  1  48                 PHA                     ; push on stack
00C48C  1  A5 97              LDA   Frnxtl            ; get var pointer for FOR/NEXT low byte
00C48E  1  48                 PHA                     ; push on stack
00C48F  1  A9 81              LDA   #TK_FOR           ; get FOR token
00C491  1  48                 PHA                     ; push on stack
00C492  1               
00C492  1               ; interpreter inner loop
00C492  1               
00C492  1               LAB_15C2
00C492  1  20 E8 C4           JSR   LAB_1629          ; do CRTL-C check vector
00C495  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte
00C497  1  A4 C4              LDY   Bpntrh            ; get BASIC execute pointer high byte
00C499  1               
00C499  1  A6 88              LDX   Clineh            ; continue line is $FFxx for immediate mode
00C49B  1                                             ; ($00xx for RUN from immediate mode)
00C49B  1  E8                 INX                     ; increment it (now $00 if immediate mode)
00C49C  1               ;*** fix p2: skip no longer necessary as the continue pointer is saved anyway
00C49C  1               ;      BEQ   LAB_15D1          ; branch if null (immediate mode)
00C49C  1               
00C49C  1  85 8B              STA   Cpntrl            ; save continue pointer low byte
00C49E  1  84 8C              STY   Cpntrh            ; save continue pointer high byte
00C4A0  1               LAB_15D1
00C4A0  1  A0 00              LDY   #$00              ; clear index
00C4A2  1  B1 C3              LDA   (Bpntrl),Y        ; get next byte
00C4A4  1  F0 07              BEQ   LAB_15DC          ; branch if null [EOL]
00C4A6  1               
00C4A6  1  C9 3A              CMP   #':'              ; compare with ":"
00C4A8  1  F0 1D              BEQ   LAB_15F6          ; branch if = (statement separator)
00C4AA  1               
00C4AA  1               LAB_15D9
00C4AA  1  4C D1 CB           JMP   LAB_SNER          ; else syntax error then warm start
00C4AD  1               
00C4AD  1                                             ; have reached [EOL]
00C4AD  1               LAB_15DC
00C4AD  1  A0 02              LDY   #$02              ; set index
00C4AF  1  B1 C3              LDA   (Bpntrl),Y        ; get next line pointer high byte
00C4B1  1  18                 CLC                     ; clear carry for no "BREAK" message
00C4B2  1  F0 50              BEQ   LAB_1651          ; if null go to immediate mode (was immediate or [EOT]
00C4B4  1                                             ; marker)
00C4B4  1               
00C4B4  1  C8                 INY                     ; increment index
00C4B5  1  B1 C3              LDA   (Bpntrl),Y        ; get line # low byte
00C4B7  1  85 87              STA   Clinel            ; save current line low byte
00C4B9  1  C8                 INY                     ; increment index
00C4BA  1  B1 C3              LDA   (Bpntrl),Y        ; get line # high byte
00C4BC  1  85 88              STA   Clineh            ; save current line high byte
00C4BE  1  98                 TYA                     ; A now = 4
00C4BF  1  65 C3              ADC   Bpntrl            ; add BASIC execute pointer low byte
00C4C1  1  85 C3              STA   Bpntrl            ; save BASIC execute pointer low byte
00C4C3  1  90 02              BCC   LAB_15F6          ; branch if no overflow
00C4C5  1               
00C4C5  1  E6 C4              INC   Bpntrh            ; else increment BASIC execute pointer high byte
00C4C7  1               LAB_15F6
00C4C7  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C4CA  1               
00C4CA  1               LAB_15F9
00C4CA  1  20 D0 C4           JSR   LAB_15FF          ; go interpret BASIC code from (Bpntrl)
00C4CD  1               
00C4CD  1               LAB_15FC
00C4CD  1  4C 92 C4           JMP   LAB_15C2          ; loop
00C4D0  1               
00C4D0  1               ; interpret BASIC code from (Bpntrl)
00C4D0  1               
00C4D0  1               LAB_15FF
00C4D0  1  F0 4E              BEQ   LAB_1628          ; exit if zero [EOL]
00C4D2  1               
00C4D2  1               LAB_1602
00C4D2  1  0A                 ASL                     ; *2 bytes per vector and normalise token
00C4D3  1  B0 03              BCS   LAB_1609          ; branch if was token
00C4D5  1               
00C4D5  1  4C 84 C7           JMP   LAB_LET           ; else go do implied LET
00C4D8  1               
00C4D8  1               LAB_1609
00C4D8  1  C9 56              CMP   #(TK_TAB-$80)*2   ; compare normalised token * 2 with TAB
00C4DA  1  B0 CE              BCS   LAB_15D9          ; branch if A>=TAB (do syntax error then warm start)
00C4DC  1                                             ; only tokens before TAB can start a line
00C4DC  1  A8                 TAY                     ; copy to index
00C4DD  1  B9 F1 E1           LDA   LAB_CTBL+1,Y      ; get vector high byte
00C4E0  1  48                 PHA                     ; onto stack
00C4E1  1  B9 F0 E1           LDA   LAB_CTBL,Y        ; get vector low byte
00C4E4  1  48                 PHA                     ; onto stack
00C4E5  1  4C BC 00           JMP   LAB_IGBY          ; jump to increment and scan memory
00C4E8  1                                             ; then "return" to vector
00C4E8  1               
00C4E8  1               ; CTRL-C check jump. this is called as a subroutine but exits back via a jump if a
00C4E8  1               ; key press is detected.
00C4E8  1               
00C4E8  1               LAB_1629
00C4E8  1  6C 03 02           JMP   (VEC_CC)          ; ctrl c check vector
00C4EB  1               
00C4EB  1               ; if there was a key press it gets back here ..
00C4EB  1               
00C4EB  1               LAB_1636
00C4EB  1  C9 03              CMP   #$03              ; compare with CTRL-C
00C4ED  1               
00C4ED  1               ; perform STOP
00C4ED  1               
00C4ED  1               LAB_STOP
00C4ED  1  B0 01              BCS   LAB_163B          ; branch if token follows STOP
00C4EF  1                                             ; else just END
00C4EF  1               ; END
00C4EF  1               
00C4EF  1               LAB_END
00C4EF  1  18                 CLC                     ; clear the carry, indicate a normal program end
00C4F0  1               LAB_163B
00C4F0  1  D0 61              BNE   LAB_167A          ; if wasn't CTRL-C or there is a following byte return
00C4F2  1               
00C4F2  1  A5 C4              LDA   Bpntrh            ; get the BASIC execute pointer high byte
00C4F4  1               ;*** fix p2: skip no longer necessary as the continue pointer is saved anyway
00C4F4  1               ;      EOR   #>Ibuffs          ; compare with buffer address high byte (Cb unchanged)
00C4F4  1               ;      BEQ   LAB_164F          ; branch if the BASIC pointer is in the input buffer
00C4F4  1               ;                              ; (can't continue in immediate mode)
00C4F4  1               ;                              ; else ..
00C4F4  1               ;      EOR   #>Ibuffs          ; correct the bits
00C4F4  1  A4 C3              LDY   Bpntrl            ; get BASIC execute pointer low byte
00C4F6  1  84 8B              STY   Cpntrl            ; save continue pointer low byte
00C4F8  1  85 8C              STA   Cpntrh            ; save continue pointer high byte
00C4FA  1               LAB_1647
00C4FA  1  A5 87              LDA   Clinel            ; get current line low byte
00C4FC  1  A4 88              LDY   Clineh            ; get current line high byte
00C4FE  1  85 89              STA   Blinel            ; save break line low byte
00C500  1  84 8A              STY   Blineh            ; save break line high byte
00C502  1               LAB_164F
00C502  1  68                 PLA                     ; pull return address low
00C503  1  68                 PLA                     ; pull return address high
00C504  1               LAB_1651
00C504  1  90 07              BCC   LAB_165E          ; if was program end just do warm start
00C506  1               
00C506  1                                             ; else ..
00C506  1  A9 C7              LDA   #<LAB_BMSG        ; point to "Break" low byte
00C508  1  A0 E7              LDY   #>LAB_BMSG        ; point to "Break" high byte
00C50A  1  4C 15 C1           JMP   LAB_1269          ; print "Break" and do warm start
00C50D  1               
00C50D  1               LAB_165E
00C50D  1  4C 20 C1           JMP   LAB_1274          ; go do warm start
00C510  1               
00C510  1               ; perform RESTORE
00C510  1               
00C510  1               LAB_RESTORE
00C510  1  D0 0F              BNE   LAB_RESTOREn      ; branch if next character not null (RESTORE n)
00C512  1               
00C512  1               LAB_161A
00C512  1  38                 SEC                     ; set carry for subtract
00C513  1  A5 79              LDA   Smeml             ; get start of mem low byte
00C515  1  E9 01              SBC   #$01              ; -1
00C517  1  A4 7A              LDY   Smemh             ; get start of mem high byte
00C519  1  B0 01              BCS   LAB_1624          ; branch if no underflow
00C51B  1               
00C51B  1               LAB_uflow
00C51B  1  88                 DEY                     ; else decrement high byte
00C51C  1               LAB_1624
00C51C  1  85 8F              STA   Dptrl             ; save DATA pointer low byte
00C51E  1  84 90              STY   Dptrh             ; save DATA pointer high byte
00C520  1               LAB_1628
00C520  1  60                 RTS
00C521  1               
00C521  1                                             ; is RESTORE n
00C521  1               LAB_RESTOREn
00C521  1  20 25 C7           JSR   LAB_GFPN          ; get fixed-point number into temp integer
00C524  1  20 70 C6           JSR   LAB_SNBL          ; scan for next BASIC line
00C527  1  A5 88              LDA   Clineh            ; get current line high byte
00C529  1  C5 12              CMP   Itemph            ; compare with temporary integer high byte
00C52B  1  B0 0B              BCS   LAB_reset_search  ; branch if >= (start search from beginning)
00C52D  1               
00C52D  1  98                 TYA                     ; else copy line index to A
00C52E  1  38                 SEC                     ; set carry (+1)
00C52F  1  65 C3              ADC   Bpntrl            ; add BASIC execute pointer low byte
00C531  1  A6 C4              LDX   Bpntrh            ; get BASIC execute pointer high byte
00C533  1  90 07              BCC   LAB_go_search     ; branch if no overflow to high byte
00C535  1               
00C535  1  E8                 INX                     ; increment high byte
00C536  1  B0 04              BCS   LAB_go_search     ; branch always (can never be carry clear)
00C538  1               
00C538  1               ; search for line # in temp (Itempl/Itemph) from start of mem pointer (Smeml)
00C538  1               
00C538  1               LAB_reset_search
00C538  1  A5 79              LDA   Smeml             ; get start of mem low byte
00C53A  1  A6 7A              LDX   Smemh             ; get start of mem high byte
00C53C  1               
00C53C  1               ; search for line # in temp (Itempl/Itemph) from (AX)
00C53C  1               
00C53C  1               LAB_go_search
00C53C  1               
00C53C  1  20 00 C3           JSR   LAB_SHLN          ; search Basic for temp integer line number from AX
00C53F  1  B0 03              BCS   LAB_line_found    ; if carry set go set pointer
00C541  1               
00C541  1  4C 42 C6           JMP   LAB_16F7          ; else go do "Undefined statement" error
00C544  1               
00C544  1               LAB_line_found
00C544  1                                             ; carry already set for subtract
00C544  1  A5 AA              LDA   Baslnl            ; get pointer low byte
00C546  1  E9 01              SBC   #$01              ; -1
00C548  1  A4 AB              LDY   Baslnh            ; get pointer high byte
00C54A  1  B0 D0              BCS   LAB_1624          ; branch if no underflow (save DATA pointer and return)
00C54C  1               
00C54C  1  90 CD              BCC   LAB_uflow         ; else decrement high byte then save DATA pointer and
00C54E  1                                             ; return (branch always)
00C54E  1               
00C54E  1               ; perform NULL
00C54E  1               
00C54E  1               LAB_NULL
00C54E  1  20 5D D4           JSR   LAB_GTBY          ; get byte parameter
00C551  1  86 0D              STX   Nullct            ; save new NULL count
00C553  1               LAB_167A
00C553  1  60                 RTS
00C554  1               
00C554  1               ; perform CONT
00C554  1               
00C554  1               LAB_CONT
00C554  1  D0 FD              BNE   LAB_167A          ; if following byte exit to do syntax error
00C556  1               
00C556  1  A4 8C              LDY   Cpntrh            ; get continue pointer high byte
00C558  1  C0 02              CPY   #>Ibuffs          ; *** fix p2: test direct mode
00C55A  1  D0 05              BNE   LAB_166C          ; go do continue if we can
00C55C  1               
00C55C  1  A2 1E              LDX   #$1E              ; error code $1E ("Can't continue" error)
00C55E  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00C561  1               
00C561  1                                             ; we can continue so ..
00C561  1               LAB_166C
00C561  1  A9 93              LDA   #TK_ON            ; set token for ON
00C563  1  20 E7 DE           JSR   LAB_IRQ           ; set IRQ flags
00C566  1  A9 93              LDA   #TK_ON            ; set token for ON
00C568  1  20 EA DE           JSR   LAB_NMI           ; set NMI flags
00C56B  1               
00C56B  1  84 C4              STY   Bpntrh            ; save BASIC execute pointer high byte
00C56D  1  A5 8B              LDA   Cpntrl            ; get continue pointer low byte
00C56F  1  85 C3              STA   Bpntrl            ; save BASIC execute pointer low byte
00C571  1  A5 89              LDA   Blinel            ; get break line low byte
00C573  1  A4 8A              LDY   Blineh            ; get break line high byte
00C575  1  85 87              STA   Clinel            ; set current line low byte
00C577  1  84 88              STY   Clineh            ; set current line high byte
00C579  1  60                 RTS
00C57A  1               
00C57A  1               ; perform RUN
00C57A  1               
00C57A  1               LAB_RUN
00C57A  1  D0 03              BNE   LAB_1696          ; branch if RUN n
00C57C  1  4C 3D C3           JMP   LAB_1477          ; reset execution to start, clear variables, flush stack and
00C57F  1                                             ; return
00C57F  1               
00C57F  1               ; does RUN n
00C57F  1               
00C57F  1               LAB_1696
00C57F  1  20 4A C3           JSR   LAB_147A          ; go do "CLEAR"
00C582  1  F0 2E              BEQ   LAB_16B0          ; get n and do GOTO n (branch always as CLEAR sets Z=1)
00C584  1               
00C584  1               ; perform DO
00C584  1               
00C584  1               LAB_DO
00C584  1  A9 05              LDA   #$05              ; need 5 bytes for DO
00C586  1  20 C9 C0           JSR   LAB_1212          ; check room on stack for A bytes
00C589  1  A5 C4              LDA   Bpntrh            ; get BASIC execute pointer high byte
00C58B  1  48                 PHA                     ; push on stack
00C58C  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte
00C58E  1  48                 PHA                     ; push on stack
00C58F  1  A5 88              LDA   Clineh            ; get current line high byte
00C591  1  48                 PHA                     ; push on stack
00C592  1  A5 87              LDA   Clinel            ; get current line low byte
00C594  1  48                 PHA                     ; push on stack
00C595  1  A9 9D              LDA   #TK_DO            ; token for DO
00C597  1  48                 PHA                     ; push on stack
00C598  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C59B  1  4C 92 C4           JMP   LAB_15C2          ; go do interpreter inner loop
00C59E  1               
00C59E  1               ; perform GOSUB
00C59E  1               
00C59E  1               LAB_GOSUB
00C59E  1  A9 05              LDA   #$05              ; need 5 bytes for GOSUB
00C5A0  1  20 C9 C0           JSR   LAB_1212          ; check room on stack for A bytes
00C5A3  1  A5 C4              LDA   Bpntrh            ; get BASIC execute pointer high byte
00C5A5  1  48                 PHA                     ; push on stack
00C5A6  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte
00C5A8  1  48                 PHA                     ; push on stack
00C5A9  1  A5 88              LDA   Clineh            ; get current line high byte
00C5AB  1  48                 PHA                     ; push on stack
00C5AC  1  A5 87              LDA   Clinel            ; get current line low byte
00C5AE  1  48                 PHA                     ; push on stack
00C5AF  1  A9 8D              LDA   #TK_GOSUB         ; token for GOSUB
00C5B1  1  48                 PHA                     ; push on stack
00C5B2  1               LAB_16B0
00C5B2  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C5B5  1  20 BB C5           JSR   LAB_GOTO          ; perform GOTO n
00C5B8  1  4C 92 C4           JMP   LAB_15C2          ; go do interpreter inner loop
00C5BB  1                                             ; (can't RTS, we used the stack!)
00C5BB  1               
00C5BB  1               ; perform GOTO
00C5BB  1               
00C5BB  1               LAB_GOTO
00C5BB  1  20 25 C7           JSR   LAB_GFPN          ; get fixed-point number into temp integer
00C5BE  1  20 70 C6           JSR   LAB_SNBL          ; scan for next BASIC line
00C5C1  1  A5 88              LDA   Clineh            ; get current line high byte
00C5C3  1  C5 12              CMP   Itemph            ; compare with temporary integer high byte
00C5C5  1  B0 0B              BCS   LAB_16D0          ; branch if >= (start search from beginning)
00C5C7  1               
00C5C7  1  98                 TYA                     ; else copy line index to A
00C5C8  1  38                 SEC                     ; set carry (+1)
00C5C9  1  65 C3              ADC   Bpntrl            ; add BASIC execute pointer low byte
00C5CB  1  A6 C4              LDX   Bpntrh            ; get BASIC execute pointer high byte
00C5CD  1  90 07              BCC   LAB_16D4          ; branch if no overflow to high byte
00C5CF  1               
00C5CF  1  E8                 INX                     ; increment high byte
00C5D0  1  B0 04              BCS   LAB_16D4          ; branch always (can never be carry)
00C5D2  1               
00C5D2  1               ; search for line # in temp (Itempl/Itemph) from start of mem pointer (Smeml)
00C5D2  1               
00C5D2  1               LAB_16D0
00C5D2  1  A5 79              LDA   Smeml             ; get start of mem low byte
00C5D4  1  A6 7A              LDX   Smemh             ; get start of mem high byte
00C5D6  1               
00C5D6  1               ; search for line # in temp (Itempl/Itemph) from (AX)
00C5D6  1               
00C5D6  1               LAB_16D4
00C5D6  1  20 00 C3           JSR   LAB_SHLN          ; search Basic for temp integer line number from AX
00C5D9  1  90 67              BCC   LAB_16F7          ; if carry clear go do "Undefined statement" error
00C5DB  1                                             ; (unspecified statement)
00C5DB  1               
00C5DB  1                                             ; carry already set for subtract
00C5DB  1  A5 AA              LDA   Baslnl            ; get pointer low byte
00C5DD  1  E9 01              SBC   #$01              ; -1
00C5DF  1  85 C3              STA   Bpntrl            ; save BASIC execute pointer low byte
00C5E1  1  A5 AB              LDA   Baslnh            ; get pointer high byte
00C5E3  1  E9 00              SBC   #$00              ; subtract carry
00C5E5  1  85 C4              STA   Bpntrh            ; save BASIC execute pointer high byte
00C5E7  1               LAB_16E5
00C5E7  1  60                 RTS
00C5E8  1               
00C5E8  1               LAB_DONOK
00C5E8  1  A2 22              LDX   #$22              ; error code $22 ("LOOP without DO" error)
00C5EA  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00C5ED  1               
00C5ED  1               ; perform LOOP
00C5ED  1               
00C5ED  1               LAB_LOOP
00C5ED  1  A8                 TAY                     ; save following token
00C5EE  1  BA                 TSX                     ; copy stack pointer
00C5EF  1  BD 03 01           LDA   LAB_STAK+3,X      ; get token byte from stack
00C5F2  1  C9 9D              CMP   #TK_DO            ; compare with DO token
00C5F4  1  D0 F2              BNE   LAB_DONOK         ; branch if no matching DO
00C5F6  1               
00C5F6  1  E8                 INX                     ; dump calling routine return address
00C5F7  1  E8                 INX                     ; dump calling routine return address
00C5F8  1  9A                 TXS                     ; correct stack
00C5F9  1  98                 TYA                     ; get saved following token back
00C5FA  1  F0 20              BEQ   LoopAlways        ; if no following token loop forever
00C5FC  1                                             ; (stack pointer in X)
00C5FC  1               
00C5FC  1  C9 3A              CMP   #':'              ; could be ':'
00C5FE  1  F0 1C              BEQ   LoopAlways        ; if :... loop forever
00C600  1               
00C600  1  E9 B3              SBC   #TK_UNTIL         ; subtract token for UNTIL, we know carry is set here
00C602  1  AA                 TAX                     ; copy to X (if it was UNTIL then Y will be correct)
00C603  1  F0 04              BEQ   DoRest            ; branch if was UNTIL
00C605  1               
00C605  1  CA                 DEX                     ; decrement result
00C606  1  D0 62              BNE   LAB_16FC          ; if not WHILE go do syntax error and warm start
00C608  1                                             ; only if the token was WHILE will this fail
00C608  1               
00C608  1  CA                 DEX                     ; set invert result byte
00C609  1               DoRest
00C609  1  86 98              STX   Frnxth            ; save invert result byte
00C60B  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C60E  1  20 B0 CA           JSR   LAB_EVEX          ; evaluate expression
00C611  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00C613  1  F0 02              BEQ   DoCmp             ; if =0 go do straight compare
00C615  1               
00C615  1  A9 FF              LDA   #$FF              ; else set all bits
00C617  1               DoCmp
00C617  1  BA                 TSX                     ; copy stack pointer
00C618  1  45 98              EOR   Frnxth            ; EOR with invert byte
00C61A  1  D0 1A              BNE   LoopDone          ; if <> 0 clear stack and back to interpreter loop
00C61C  1               
00C61C  1                                             ; loop condition wasn't met so do it again
00C61C  1               LoopAlways
00C61C  1  BD 02 01           LDA   LAB_STAK+2,X      ; get current line low byte
00C61F  1  85 87              STA   Clinel            ; save current line low byte
00C621  1  BD 03 01           LDA   LAB_STAK+3,X      ; get current line high byte
00C624  1  85 88              STA   Clineh            ; save current line high byte
00C626  1  BD 04 01           LDA   LAB_STAK+4,X      ; get BASIC execute pointer low byte
00C629  1  85 C3              STA   Bpntrl            ; save BASIC execute pointer low byte
00C62B  1  BD 05 01           LDA   LAB_STAK+5,X      ; get BASIC execute pointer high byte
00C62E  1  85 C4              STA   Bpntrh            ; save BASIC execute pointer high byte
00C630  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C633  1  4C 92 C4           JMP   LAB_15C2          ; go do interpreter inner loop
00C636  1               
00C636  1                                             ; clear stack and back to interpreter loop
00C636  1               LoopDone
00C636  1  E8                 INX                     ; dump DO token
00C637  1  E8                 INX                     ; dump current line low byte
00C638  1  E8                 INX                     ; dump current line high byte
00C639  1  E8                 INX                     ; dump BASIC execute pointer low byte
00C63A  1  E8                 INX                     ; dump BASIC execute pointer high byte
00C63B  1  9A                 TXS                     ; correct stack
00C63C  1  4C 5C C6           JMP   LAB_DATA          ; go perform DATA (find : or [EOL])
00C63F  1               
00C63F  1               ; do the return without gosub error
00C63F  1               
00C63F  1               LAB_16F4
00C63F  1  A2 04              LDX   #$04              ; error code $04 ("RETURN without GOSUB" error)
00C641  1  2C                 .byte $2C               ; makes next line BIT LAB_0EA2
00C642  1               
00C642  1               LAB_16F7                      ; do undefined statement error
00C642  1  A2 0E              LDX   #$0E              ; error code $0E ("Undefined statement" error)
00C644  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00C647  1               
00C647  1               ; perform RETURN
00C647  1               
00C647  1               LAB_RETURN
00C647  1  D0 9E              BNE   LAB_16E5          ; exit if following token (to allow syntax error)
00C649  1               
00C649  1               LAB_16E8
00C649  1  68                 PLA                     ; dump calling routine return address
00C64A  1  68                 PLA                     ; dump calling routine return address
00C64B  1  68                 PLA                     ; pull token
00C64C  1  C9 8D              CMP   #TK_GOSUB         ; compare with GOSUB token
00C64E  1  D0 EF              BNE   LAB_16F4          ; branch if no matching GOSUB
00C650  1               
00C650  1               LAB_16FF
00C650  1  68                 PLA                     ; pull current line low byte
00C651  1  85 87              STA   Clinel            ; save current line low byte
00C653  1  68                 PLA                     ; pull current line high byte
00C654  1  85 88              STA   Clineh            ; save current line high byte
00C656  1  68                 PLA                     ; pull BASIC execute pointer low byte
00C657  1  85 C3              STA   Bpntrl            ; save BASIC execute pointer low byte
00C659  1  68                 PLA                     ; pull BASIC execute pointer high byte
00C65A  1  85 C4              STA   Bpntrh            ; save BASIC execute pointer high byte
00C65C  1               
00C65C  1                                             ; now do the DATA statement as we could be returning into
00C65C  1                                             ; the middle of an ON <var> GOSUB n,m,p,q line
00C65C  1                                             ; (the return address used by the DATA statement is the one
00C65C  1                                             ; pushed before the GOSUB was executed!)
00C65C  1               
00C65C  1               ; perform DATA
00C65C  1               
00C65C  1               LAB_DATA
00C65C  1  20 6D C6           JSR   LAB_SNBS          ; scan for next BASIC statement ([:] or [EOL])
00C65F  1               
00C65F  1                                             ; set BASIC execute pointer
00C65F  1               LAB_170F
00C65F  1  98                 TYA                     ; copy index to A
00C660  1  18                 CLC                     ; clear carry for add
00C661  1  65 C3              ADC   Bpntrl            ; add BASIC execute pointer low byte
00C663  1  85 C3              STA   Bpntrl            ; save BASIC execute pointer low byte
00C665  1  90 02              BCC   LAB_1719          ; skip next if no carry
00C667  1               
00C667  1  E6 C4              INC   Bpntrh            ; else increment BASIC execute pointer high byte
00C669  1               LAB_1719
00C669  1  60                 RTS
00C66A  1               
00C66A  1               LAB_16FC
00C66A  1  4C D1 CB           JMP   LAB_SNER          ; do syntax error then warm start
00C66D  1               
00C66D  1               ; scan for next BASIC statement ([:] or [EOL])
00C66D  1               ; returns Y as index to [:] or [EOL]
00C66D  1               
00C66D  1               LAB_SNBS
00C66D  1  A2 3A              LDX   #':'              ; set look for character = ":"
00C66F  1  2C                 .byte $2C               ; makes next line BIT $00A2
00C670  1               
00C670  1               ; scan for next BASIC line
00C670  1               ; returns Y as index to [EOL]
00C670  1               
00C670  1               LAB_SNBL
00C670  1  A2 00              LDX   #$00              ; set alt search character = [EOL]
00C672  1  A0 00              LDY   #$00              ; set search character = [EOL]
00C674  1  84 5C              STY   Asrch             ; store search character
00C676  1               LAB_1725
00C676  1  8A                 TXA                     ; get alt search character
00C677  1  45 5C              EOR   Asrch             ; toggle search character, effectively swap with $00
00C679  1  85 5C              STA   Asrch             ; save swapped search character
00C67B  1               LAB_172D
00C67B  1  B1 C3              LDA   (Bpntrl),Y        ; get next byte
00C67D  1  F0 EA              BEQ   LAB_1719          ; exit if null [EOL]
00C67F  1               
00C67F  1  C5 5C              CMP   Asrch             ; compare with search character
00C681  1  F0 E6              BEQ   LAB_1719          ; exit if found
00C683  1               
00C683  1  C8                 INY                     ; increment index
00C684  1  C9 22              CMP   #$22              ; compare current character with open quote
00C686  1  D0 F3              BNE   LAB_172D          ; if not open quote go get next character
00C688  1               
00C688  1  F0 EC              BEQ   LAB_1725          ; if found go swap search character for alt search character
00C68A  1               
00C68A  1               ; perform IF
00C68A  1               
00C68A  1               LAB_IF
00C68A  1  20 B0 CA           JSR   LAB_EVEX          ; evaluate the expression
00C68D  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C690  1  C9 B0              CMP   #TK_THEN          ; compare with THEN token
00C692  1  F0 11              BEQ   LAB_174B          ; if it was THEN go do IF
00C694  1               
00C694  1                                             ; wasn't IF .. THEN so must be IF .. GOTO
00C694  1  C9 89              CMP   #TK_GOTO          ; compare with GOTO token
00C696  1  D0 D2              BNE   LAB_16FC          ; if it wasn't GOTO go do syntax error
00C698  1               
00C698  1  A6 C3              LDX   Bpntrl            ; save the basic pointer low byte
00C69A  1  A4 C4              LDY   Bpntrh            ; save the basic pointer high byte
00C69C  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C69F  1  B0 C9              BCS   LAB_16FC          ; if not numeric go do syntax error
00C6A1  1               
00C6A1  1  86 C3              STX   Bpntrl            ; restore the basic pointer low byte
00C6A3  1  84 C4              STY   Bpntrh            ; restore the basic pointer high byte
00C6A5  1               LAB_174B
00C6A5  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00C6A7  1  F0 1B              BEQ   LAB_174E          ; if the result was zero go look for an ELSE
00C6A9  1               
00C6A9  1  20 BC 00           JSR   LAB_IGBY          ; else increment and scan memory
00C6AC  1  B0 03              BCS   LAB_174D          ; if not numeric go do var or keyword
00C6AE  1               
00C6AE  1               LAB_174C
00C6AE  1  4C BB C5           JMP   LAB_GOTO          ; else was numeric so do GOTO n
00C6B1  1               
00C6B1  1                                             ; is var or keyword
00C6B1  1               LAB_174D
00C6B1  1  C9 90              CMP   #TK_RETURN        ; compare the byte with the token for RETURN
00C6B3  1  D0 03              BNE   LAB_174G          ; if it wasn't RETURN go interpret BASIC code from (Bpntrl)
00C6B5  1                                             ; and return to this code to process any following code
00C6B5  1               
00C6B5  1  4C D2 C4           JMP   LAB_1602          ; else it was RETURN so interpret BASIC code from (Bpntrl)
00C6B8  1                                             ; but don't return here
00C6B8  1               
00C6B8  1               LAB_174G
00C6B8  1  20 D0 C4           JSR   LAB_15FF          ; interpret BASIC code from (Bpntrl)
00C6BB  1               
00C6BB  1               ; the IF was executed and there may be a following ELSE so the code needs to return
00C6BB  1               ; here to check and ignore the ELSE if present
00C6BB  1               
00C6BB  1  A0 00              LDY   #$00              ; clear the index
00C6BD  1  B1 C3              LDA   (Bpntrl),Y        ; get the next BASIC byte
00C6BF  1  C9 AC              CMP   #TK_ELSE          ; compare it with the token for ELSE
00C6C1  1  F0 99              BEQ   LAB_DATA          ; if ELSE ignore the following statement
00C6C3  1               
00C6C3  1               ; there was no ELSE so continue execution of IF <expr> THEN <stat> [: <stat>]. any
00C6C3  1               ; following ELSE will, correctly, cause a syntax error
00C6C3  1               
00C6C3  1  60                 RTS                     ; else return to the interpreter inner loop
00C6C4  1               
00C6C4  1               ; perform ELSE after IF
00C6C4  1               
00C6C4  1               LAB_174E
00C6C4  1  A0 00              LDY   #$00              ; clear the BASIC byte index
00C6C6  1  A2 01              LDX   #$01              ; clear the nesting depth
00C6C8  1               LAB_1750
00C6C8  1  C8                 INY                     ; increment the BASIC byte index
00C6C9  1  B1 C3              LDA   (Bpntrl),Y        ; get the next BASIC byte
00C6CB  1  F0 0F              BEQ   LAB_1753          ; if EOL go add the pointer and return
00C6CD  1               
00C6CD  1  C9 8B              CMP   #TK_IF            ; compare the byte with the token for IF
00C6CF  1  D0 03              BNE   LAB_1752          ; if not IF token skip the depth increment
00C6D1  1               
00C6D1  1  E8                 INX                     ; else increment the nesting depth ..
00C6D2  1  D0 F4              BNE   LAB_1750          ; .. and continue looking
00C6D4  1               
00C6D4  1               LAB_1752
00C6D4  1  C9 AC              CMP   #TK_ELSE          ; compare the byte with the token for ELSE
00C6D6  1  D0 F0              BNE   LAB_1750          ; if not ELSE token continue looking
00C6D8  1               
00C6D8  1  CA                 DEX                     ; was ELSE so decrement the nesting depth
00C6D9  1  D0 ED              BNE   LAB_1750          ; loop if still nested
00C6DB  1               
00C6DB  1  C8                 INY                     ; increment the BASIC byte index past the ELSE
00C6DC  1               
00C6DC  1               ; found the matching ELSE, now do <{n|statement}>
00C6DC  1               
00C6DC  1               LAB_1753
00C6DC  1  98                 TYA                     ; else copy line index to A
00C6DD  1  18                 CLC                     ; clear carry for add
00C6DE  1  65 C3              ADC   Bpntrl            ; add the BASIC execute pointer low byte
00C6E0  1  85 C3              STA   Bpntrl            ; save the BASIC execute pointer low byte
00C6E2  1  90 02              BCC   LAB_1754          ; branch if no overflow to high byte
00C6E4  1               
00C6E4  1  E6 C4              INC   Bpntrh            ; else increment the BASIC execute pointer high byte
00C6E6  1               LAB_1754
00C6E6  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C6E9  1  90 C3              BCC   LAB_174C          ; if numeric do GOTO n
00C6EB  1                                             ; the code will return to the interpreter loop at the
00C6EB  1                                             ; tail end of the GOTO <n>
00C6EB  1               
00C6EB  1  4C D0 C4           JMP   LAB_15FF          ; interpret BASIC code from (Bpntrl)
00C6EE  1                                             ; the code will return to the interpreter loop at the
00C6EE  1                                             ; tail end of the <statement>
00C6EE  1               
00C6EE  1               ; perform REM, skip (rest of) line
00C6EE  1               
00C6EE  1               LAB_REM
00C6EE  1  20 70 C6           JSR   LAB_SNBL          ; scan for next BASIC line
00C6F1  1  4C 5F C6           JMP   LAB_170F          ; go set BASIC execute pointer and return, branch always
00C6F4  1               
00C6F4  1               LAB_16FD
00C6F4  1  4C D1 CB           JMP   LAB_SNER          ; do syntax error then warm start
00C6F7  1               
00C6F7  1               ; perform ON
00C6F7  1               
00C6F7  1               LAB_ON
00C6F7  1  C9 A9              CMP   #TK_IRQ           ; was it IRQ token ?
00C6F9  1  D0 03              BNE   LAB_NOIN          ; if not go check NMI
00C6FB  1               
00C6FB  1  4C 0B DF           JMP   LAB_SIRQ          ; else go set-up IRQ
00C6FE  1               
00C6FE  1               LAB_NOIN
00C6FE  1  C9 AA              CMP   #TK_NMI           ; was it NMI token ?
00C700  1  D0 03              BNE   LAB_NONM          ; if not go do normal ON command
00C702  1               
00C702  1  4C 0F DF           JMP   LAB_SNMI          ; else go set-up NMI
00C705  1               
00C705  1               LAB_NONM
00C705  1  20 5D D4           JSR   LAB_GTBY          ; get byte parameter
00C708  1  48                 PHA                     ; push GOTO/GOSUB token
00C709  1  C9 8D              CMP   #TK_GOSUB         ; compare with GOSUB token
00C70B  1  F0 04              BEQ   LAB_176B          ; branch if GOSUB
00C70D  1               
00C70D  1  C9 89              CMP   #TK_GOTO          ; compare with GOTO token
00C70F  1               LAB_1767
00C70F  1  D0 E3              BNE   LAB_16FD          ; if not GOTO do syntax error then warm start
00C711  1               
00C711  1               
00C711  1               ; next character was GOTO or GOSUB
00C711  1               
00C711  1               LAB_176B
00C711  1  C6 AF              DEC   FAC1_3            ; decrement index (byte value)
00C713  1  D0 04              BNE   LAB_1773          ; branch if not zero
00C715  1               
00C715  1  68                 PLA                     ; pull GOTO/GOSUB token
00C716  1  4C D2 C4           JMP   LAB_1602          ; go execute it
00C719  1               
00C719  1               LAB_1773
00C719  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C71C  1  20 25 C7           JSR   LAB_GFPN          ; get fixed-point number into temp integer (skip this n)
00C71F  1                                             ; (we could LDX #',' and JSR LAB_SNBL+2, then we
00C71F  1                                             ; just BNE LAB_176B for the loop. should be quicker ..
00C71F  1                                             ; no we can't, what if we meet a colon or [EOL]?)
00C71F  1  C9 2C              CMP   #$2C              ; compare next character with ","
00C721  1  F0 EE              BEQ   LAB_176B          ; loop if ","
00C723  1               
00C723  1               LAB_177E
00C723  1  68                 PLA                     ; else pull keyword token (run out of options)
00C724  1                                             ; also dump +/-1 pointer low byte and exit
00C724  1               LAB_177F
00C724  1  60                 RTS
00C725  1               
00C725  1               ; takes n * 106 + 11 cycles where n is the number of digits
00C725  1               
00C725  1               ; get fixed-point number into temp integer
00C725  1               
00C725  1               LAB_GFPN
00C725  1  A2 00              LDX   #$00              ; clear reg
00C727  1  86 11              STX   Itempl            ; clear temporary integer low byte
00C729  1               LAB_1785
00C729  1  86 12              STX   Itemph            ; save temporary integer high byte
00C72B  1  B0 F7              BCS   LAB_177F          ; return if carry set, end of scan, character was
00C72D  1                                             ; not 0-9
00C72D  1               
00C72D  1  E0 19              CPX   #$19              ; compare high byte with $19
00C72F  1  A8                 TAY                     ; ensure Zb = 0 if the branch is taken
00C730  1  B0 DD              BCS   LAB_1767          ; branch if >=, makes max line # 63999 because next
00C732  1                                             ; bit does *$0A, = 64000, compare at target will fail
00C732  1                                             ; and do syntax error
00C732  1               
00C732  1  E9 2F              SBC   #'0'-1            ; subtract "0", $2F + carry, from byte
00C734  1  A8                 TAY                     ; copy binary digit
00C735  1  A5 11              LDA   Itempl            ; get temporary integer low byte
00C737  1  0A                 ASL                     ; *2 low byte
00C738  1  26 12              ROL   Itemph            ; *2 high byte
00C73A  1  0A                 ASL                     ; *2 low byte
00C73B  1  26 12              ROL   Itemph            ; *2 high byte, *4
00C73D  1  65 11              ADC   Itempl            ; + low byte, *5
00C73F  1  85 11              STA   Itempl            ; save it
00C741  1  8A                 TXA                     ; get high byte copy to A
00C742  1  65 12              ADC   Itemph            ; + high byte, *5
00C744  1  06 11              ASL   Itempl            ; *2 low byte, *10d
00C746  1  2A                 ROL                     ; *2 high byte, *10d
00C747  1  AA                 TAX                     ; copy high byte back to X
00C748  1  98                 TYA                     ; get binary digit back
00C749  1  65 11              ADC   Itempl            ; add number low byte
00C74B  1  85 11              STA   Itempl            ; save number low byte
00C74D  1  90 01              BCC   LAB_17B3          ; if no overflow to high byte get next character
00C74F  1               
00C74F  1  E8                 INX                     ; else increment high byte
00C750  1               LAB_17B3
00C750  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C753  1  4C 29 C7           JMP   LAB_1785          ; loop for next character
00C756  1               
00C756  1               ; perform DEC
00C756  1               
00C756  1               LAB_DEC
00C756  1  A9 CD              LDA   #<LAB_2AFD        ; set -1 pointer low byte
00C758  1  2C                 .byte $2C               ; BIT abs to skip the LDA below
00C759  1               
00C759  1               ; perform INC
00C759  1               
00C759  1               LAB_INC
00C759  1  A9 C9              LDA   #<LAB_259C        ; set 1 pointer low byte
00C75B  1               LAB_17B5
00C75B  1  48                 PHA                     ; save +/-1 pointer low byte
00C75C  1               LAB_17B7
00C75C  1  20 79 CD           JSR   LAB_GVAR          ; get var address
00C75F  1  A6 5F              LDX   Dtypef            ; get data type flag, $FF=string, $00=numeric
00C761  1  30 1E              BMI   IncrErr           ; exit if string
00C763  1               
00C763  1  85 97              STA   Lvarpl            ; save var address low byte
00C765  1  84 98              STY   Lvarph            ; save var address high byte
00C767  1  20 4E D8           JSR   LAB_UFAC          ; unpack memory (AY) into FAC1
00C76A  1  68                 PLA                     ; get +/-1 pointer low byte
00C76B  1  48                 PHA                     ; save +/-1 pointer low byte
00C76C  1  A0 E1              LDY   #>LAB_259C        ; set +/-1 pointer high byte (both the same)
00C76E  1  20 8F D5           JSR   LAB_246C          ; add (AY) to FAC1
00C771  1  20 74 D8           JSR   LAB_PFAC          ; pack FAC1 into variable (Lvarpl)
00C774  1               
00C774  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C777  1  C9 2C              CMP   #','              ; compare with ","
00C779  1  D0 A8              BNE   LAB_177E          ; exit if not "," (either end or error)
00C77B  1               
00C77B  1                                             ; was "," so another INCR variable to do
00C77B  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C77E  1  4C 5C C7           JMP   LAB_17B7          ; go do next var
00C781  1               
00C781  1               IncrErr
00C781  1  4C AB CA           JMP   LAB_1ABC          ; do "Type mismatch" error then warm start
00C784  1               
00C784  1               ; perform LET
00C784  1               
00C784  1               LAB_LET
00C784  1  20 79 CD           JSR   LAB_GVAR          ; get var address
00C787  1  85 97              STA   Lvarpl            ; save var address low byte
00C789  1  84 98              STY   Lvarph            ; save var address high byte
00C78B  1  A9 C1              LDA   #TK_EQUAL         ; get = token
00C78D  1  20 C0 CB           JSR   LAB_SCCA          ; scan for CHR$(A), else do syntax error then warm start
00C790  1  A5 5F              LDA   Dtypef            ; get data type flag, $FF=string, $00=numeric
00C792  1  48                 PHA                     ; push data type flag
00C793  1  20 B0 CA           JSR   LAB_EVEX          ; evaluate expression
00C796  1  68                 PLA                     ; pop data type flag
00C797  1  2A                 ROL                     ; set carry if type = string
00C798  1  20 A2 CA           JSR   LAB_CKTM          ; type match check, set C for string
00C79B  1  D0 03              BNE   LAB_17D5          ; branch if string
00C79D  1               
00C79D  1  4C 74 D8           JMP   LAB_PFAC          ; pack FAC1 into variable (Lvarpl) and return
00C7A0  1               
00C7A0  1               ; string LET
00C7A0  1               
00C7A0  1               LAB_17D5
00C7A0  1  A0 02              LDY   #$02              ; set index to pointer high byte
00C7A2  1  B1 AE              LDA   (des_pl),Y        ; get string pointer high byte
00C7A4  1  C5 82              CMP   Sstorh            ; compare bottom of string space high byte
00C7A6  1  90 17              BCC   LAB_17F4          ; if less assign value and exit (was in program memory)
00C7A8  1               
00C7A8  1  D0 07              BNE   LAB_17E6          ; branch if >
00C7AA  1                                             ; else was equal so compare low bytes
00C7AA  1  88                 DEY                     ; decrement index
00C7AB  1  B1 AE              LDA   (des_pl),Y        ; get pointer low byte
00C7AD  1  C5 81              CMP   Sstorl            ; compare bottom of string space low byte
00C7AF  1  90 0E              BCC   LAB_17F4          ; if less assign value and exit (was in program memory)
00C7B1  1               
00C7B1  1                                             ; pointer was >= to bottom of string space pointer
00C7B1  1               LAB_17E6
00C7B1  1  A4 AF              LDY   des_ph            ; get descriptor pointer high byte
00C7B3  1  C4 7C              CPY   Svarh             ; compare start of vars high byte
00C7B5  1  90 08              BCC   LAB_17F4          ; branch if less (descriptor is on stack)
00C7B7  1               
00C7B7  1  D0 0D              BNE   LAB_17FB          ; branch if greater (descriptor is not on stack)
00C7B9  1               
00C7B9  1                                             ; else high bytes were equal so ..
00C7B9  1  A5 AE              LDA   des_pl            ; get descriptor pointer low byte
00C7BB  1  C5 7B              CMP   Svarl             ; compare start of vars low byte
00C7BD  1  B0 07              BCS   LAB_17FB          ; branch if >= (descriptor is not on stack)
00C7BF  1               
00C7BF  1               LAB_17F4
00C7BF  1  A5 AE              LDA   des_pl            ; get descriptor pointer low byte
00C7C1  1  A4 AF              LDY   des_ph            ; get descriptor pointer high byte
00C7C3  1  4C DC C7           JMP   LAB_1811          ; clean stack, copy descriptor to variable and return
00C7C6  1               
00C7C6  1                                             ; make space and copy string
00C7C6  1               LAB_17FB
00C7C6  1  A0 00              LDY   #$00              ; index to length
00C7C8  1  B1 AE              LDA   (des_pl),Y        ; get string length
00C7CA  1  20 01 D1           JSR   LAB_209C          ; copy string
00C7CD  1  A5 9E              LDA   des_2l            ; get descriptor pointer low byte
00C7CF  1  A4 9F              LDY   des_2h            ; get descriptor pointer high byte
00C7D1  1  85 B8              STA   ssptr_l           ; save descriptor pointer low byte
00C7D3  1  84 B9              STY   ssptr_h           ; save descriptor pointer high byte
00C7D5  1  20 E2 D2           JSR   LAB_228A          ; copy string from descriptor (sdescr) to (Sutill)
00C7D8  1  A9 AC              LDA   #<FAC1_e          ; set descriptor pointer low byte
00C7DA  1  A0 00              LDY   #>FAC1_e          ; get descriptor pointer high byte
00C7DC  1               
00C7DC  1                                             ; clean stack and assign value to string variable
00C7DC  1               LAB_1811
00C7DC  1  85 9E              STA   des_2l            ; save descriptor_2 pointer low byte
00C7DE  1  84 9F              STY   des_2h            ; save descriptor_2 pointer high byte
00C7E0  1  20 44 D3           JSR   LAB_22EB          ; clean descriptor stack, YA = pointer
00C7E3  1  A0 00              LDY   #$00              ; index to length
00C7E5  1  B1 9E              LDA   (des_2l),Y        ; get string length
00C7E7  1  91 97              STA   (Lvarpl),Y        ; copy to let string variable
00C7E9  1  C8                 INY                     ; index to string pointer low byte
00C7EA  1  B1 9E              LDA   (des_2l),Y        ; get string pointer low byte
00C7EC  1  91 97              STA   (Lvarpl),Y        ; copy to let string variable
00C7EE  1  C8                 INY                     ; index to string pointer high byte
00C7EF  1  B1 9E              LDA   (des_2l),Y        ; get string pointer high byte
00C7F1  1  91 97              STA   (Lvarpl),Y        ; copy to let string variable
00C7F3  1  60                 RTS
00C7F4  1               
00C7F4  1               ; perform GET
00C7F4  1               
00C7F4  1               LAB_GET
00C7F4  1  20 79 CD           JSR   LAB_GVAR          ; get var address
00C7F7  1  85 97              STA   Lvarpl            ; save var address low byte
00C7F9  1  84 98              STY   Lvarph            ; save var address high byte
00C7FB  1  20 D3 DE           JSR   INGET             ; get input byte
00C7FE  1  A6 5F              LDX   Dtypef            ; get data type flag, $FF=string, $00=numeric
00C800  1  30 07              BMI   LAB_GETS          ; go get string character
00C802  1               
00C802  1                                             ; was numeric get
00C802  1  A8                 TAY                     ; copy character to Y
00C803  1  20 35 D0           JSR   LAB_1FD0          ; convert Y to byte in FAC1
00C806  1  4C 74 D8           JMP   LAB_PFAC          ; pack FAC1 into variable (Lvarpl) and return
00C809  1               
00C809  1               LAB_GETS
00C809  1  48                 PHA                     ; save character
00C80A  1  A9 01              LDA   #$01              ; string is single byte
00C80C  1  B0 01              BCS   LAB_IsByte        ; branch if byte received
00C80E  1               
00C80E  1  68                 PLA                     ; string is null
00C80F  1               LAB_IsByte
00C80F  1  20 09 D1           JSR   LAB_MSSP          ; make string space A bytes long A=$AC=length,
00C812  1                                             ; X=$AD=Sutill=ptr low byte, Y=$AE=Sutilh=ptr high byte
00C812  1  F0 05              BEQ   LAB_NoSt          ; skip store if null string
00C814  1               
00C814  1  68                 PLA                     ; get character back
00C815  1  A0 00              LDY   #$00              ; clear index
00C817  1  91 AD              STA   (str_pl),Y        ; save byte in string (byte IS string!)
00C819  1               LAB_NoSt
00C819  1  20 56 D1           JSR   LAB_RTST          ; check for space on descriptor stack then put address
00C81C  1                                             ; and length on descriptor stack and update stack pointers
00C81C  1               
00C81C  1  4C A0 C7           JMP   LAB_17D5          ; do string LET and return
00C81F  1               
00C81F  1               ; perform PRINT
00C81F  1               
00C81F  1               LAB_1829
00C81F  1  20 A6 C8           JSR   LAB_18C6          ; print string from Sutill/Sutilh
00C822  1               LAB_182C
00C822  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C825  1               
00C825  1               ; PRINT
00C825  1               
00C825  1               LAB_PRINT
00C825  1  F0 3B              BEQ   LAB_CRLF          ; if nothing following just print CR/LF
00C827  1               
00C827  1               LAB_1831
00C827  1  C9 AB              CMP   #TK_TAB           ; compare with TAB( token
00C829  1  F0 56              BEQ   LAB_18A2          ; go do TAB/SPC
00C82B  1               
00C82B  1  C9 AF              CMP   #TK_SPC           ; compare with SPC( token
00C82D  1  F0 52              BEQ   LAB_18A2          ; go do TAB/SPC
00C82F  1               
00C82F  1  C9 2C              CMP   #','              ; compare with ","
00C831  1  F0 38              BEQ   LAB_188B          ; go do move to next TAB mark
00C833  1               
00C833  1  C9 3B              CMP   #';'              ; compare with ";"
00C835  1  F0 66              BEQ   LAB_18BD          ; if ";" continue with PRINT processing
00C837  1               
00C837  1  20 B0 CA           JSR   LAB_EVEX          ; evaluate expression
00C83A  1  24 5F              BIT   Dtypef            ; test data type flag, $FF=string, $00=numeric
00C83C  1  30 E1              BMI   LAB_1829          ; branch if string
00C83E  1               
00C83E  1  20 66 DA           JSR   LAB_296E          ; convert FAC1 to string
00C841  1  20 13 D1           JSR   LAB_20AE          ; print " terminated string to Sutill/Sutilh
00C844  1  A0 00              LDY   #$00              ; clear index
00C846  1               
00C846  1               ; don't check fit if terminal width byte is zero
00C846  1               
00C846  1  A5 0F              LDA   TWidth            ; get terminal width byte
00C848  1  F0 0A              BEQ   LAB_185E          ; skip check if zero
00C84A  1               
00C84A  1  38                 SEC                     ; set carry for subtract
00C84B  1  E5 0E              SBC   TPos              ; subtract terminal position
00C84D  1  F1 AE              SBC   (des_pl),Y        ; subtract string length
00C84F  1  B0 03              BCS   LAB_185E          ; branch if less than terminal width
00C851  1               
00C851  1  20 62 C8           JSR   LAB_CRLF          ; else print CR/LF
00C854  1               LAB_185E
00C854  1  20 A6 C8           JSR   LAB_18C6          ; print string from Sutill/Sutilh
00C857  1  F0 C9              BEQ   LAB_182C          ; always go continue processing line
00C859  1               
00C859  1               ; CR/LF return to BASIC from BASIC input handler
00C859  1               
00C859  1               LAB_1866
00C859  1  A9 00              LDA   #$00              ; clear byte
00C85B  1  9D 80 02           STA   Ibuffs,X          ; null terminate input
00C85E  1  A2 80              LDX   #<Ibuffs          ; set X to buffer start-1 low byte
00C860  1  A0 02              LDY   #>Ibuffs          ; set Y to buffer start-1 high byte
00C862  1               
00C862  1               ; print CR/LF
00C862  1               
00C862  1               LAB_CRLF
00C862  1  A9 0D              LDA   #$0D              ; load [CR]
00C864  1  20 BD C8           JSR   LAB_PRNA          ; go print the character
00C867  1  A9 0A              LDA   #$0A              ; load [LF]
00C869  1  D0 52              BNE   LAB_PRNA          ; go print the character and return, branch always
00C86B  1               
00C86B  1               LAB_188B
00C86B  1  A5 0E              LDA   TPos              ; get terminal position
00C86D  1  C5 10              CMP   Iclim             ; compare with input column limit
00C86F  1  90 05              BCC   LAB_1897          ; branch if less
00C871  1               
00C871  1  20 62 C8           JSR   LAB_CRLF          ; else print CR/LF (next line)
00C874  1  D0 27              BNE   LAB_18BD          ; continue with PRINT processing (branch always)
00C876  1               
00C876  1               LAB_1897
00C876  1  38                 SEC                     ; set carry for subtract
00C877  1               LAB_1898
00C877  1  E5 64              SBC   TabSiz            ; subtract TAB size
00C879  1  B0 FC              BCS   LAB_1898          ; loop if result was +ve
00C87B  1               
00C87B  1  49 FF              EOR   #$FF              ; complement it
00C87D  1  69 01              ADC   #$01              ; +1 (twos complement)
00C87F  1  D0 12              BNE   LAB_18B6          ; always print A spaces (result is never $00)
00C881  1               
00C881  1                                             ; do TAB/SPC
00C881  1               LAB_18A2
00C881  1  48                 PHA                     ; save token
00C882  1  20 5A D4           JSR   LAB_SGBY          ; scan and get byte parameter
00C885  1  C9 29              CMP   #$29              ; is next character )
00C887  1  D0 7B              BNE   LAB_1910          ; if not do syntax error then warm start
00C889  1               
00C889  1  68                 PLA                     ; get token back
00C88A  1  C9 AB              CMP   #TK_TAB           ; was it TAB ?
00C88C  1  D0 06              BNE   LAB_18B7          ; if not go do SPC
00C88E  1               
00C88E  1                                             ; calculate TAB offset
00C88E  1  8A                 TXA                     ; copy integer value to A
00C88F  1  E5 0E              SBC   TPos              ; subtract terminal position
00C891  1  90 0A              BCC   LAB_18BD          ; branch if result was < 0 (can't TAB backwards)
00C893  1               
00C893  1                                             ; print A spaces
00C893  1               LAB_18B6
00C893  1  AA                 TAX                     ; copy result to X
00C894  1               LAB_18B7
00C894  1  8A                 TXA                     ; set flags on size for SPC
00C895  1  F0 06              BEQ   LAB_18BD          ; branch if result was = $0, already here
00C897  1               
00C897  1                                             ; print X spaces
00C897  1               LAB_18BA
00C897  1  20 B8 C8           JSR   LAB_18E0          ; print " "
00C89A  1  CA                 DEX                     ; decrement count
00C89B  1  D0 FA              BNE   LAB_18BA          ; loop if not all done
00C89D  1               
00C89D  1                                             ; continue with PRINT processing
00C89D  1               LAB_18BD
00C89D  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C8A0  1  D0 85              BNE   LAB_1831          ; if more to print go do it
00C8A2  1               
00C8A2  1  60                 RTS
00C8A3  1               
00C8A3  1               ; print null terminated string from memory
00C8A3  1               
00C8A3  1               LAB_18C3
00C8A3  1  20 13 D1           JSR   LAB_20AE          ; print " terminated string to Sutill/Sutilh
00C8A6  1               
00C8A6  1               ; print string from Sutill/Sutilh
00C8A6  1               
00C8A6  1               LAB_18C6
00C8A6  1  20 0F D3           JSR   LAB_22B6          ; pop string off descriptor stack, or from top of string
00C8A9  1                                             ; space returns with A = length, X=$71=pointer low byte,
00C8A9  1                                             ; Y=$72=pointer high byte
00C8A9  1  A0 00              LDY   #$00              ; reset index
00C8AB  1  AA                 TAX                     ; copy length to X
00C8AC  1  F0 49              BEQ   LAB_188C          ; exit (RTS) if null string
00C8AE  1               
00C8AE  1               LAB_18CD
00C8AE  1               
00C8AE  1  B1 71              LDA   (ut1_pl),Y        ; get next byte
00C8B0  1  20 BD C8           JSR   LAB_PRNA          ; go print the character
00C8B3  1  C8                 INY                     ; increment index
00C8B4  1  CA                 DEX                     ; decrement count
00C8B5  1  D0 F7              BNE   LAB_18CD          ; loop if not done yet
00C8B7  1               
00C8B7  1  60                 RTS
00C8B8  1               
00C8B8  1                                             ; Print single format character
00C8B8  1               ; print " "
00C8B8  1               
00C8B8  1               LAB_18E0
00C8B8  1  A9 20              LDA   #$20              ; load " "
00C8BA  1  2C                 .byte $2C               ; change next line to BIT LAB_3FA9
00C8BB  1               
00C8BB  1               ; print "?" character
00C8BB  1               
00C8BB  1               LAB_18E3
00C8BB  1  A9 3F              LDA   #$3F              ; load "?" character
00C8BD  1               
00C8BD  1               ; print character in A
00C8BD  1               ; now includes the null handler
00C8BD  1               ; also includes infinite line length code
00C8BD  1               ; note! some routines expect this one to exit with Zb=0
00C8BD  1               
00C8BD  1               LAB_PRNA
00C8BD  1  C9 20              CMP   #' '              ; compare with " "
00C8BF  1  90 19              BCC   LAB_18F9          ; branch if less (non printing)
00C8C1  1               
00C8C1  1                                             ; else printable character
00C8C1  1  48                 PHA                     ; save the character
00C8C2  1               
00C8C2  1               ; don't check fit if terminal width byte is zero
00C8C2  1               
00C8C2  1  A5 0F              LDA   TWidth            ; get terminal width
00C8C4  1  D0 0A              BNE   LAB_18F0          ; branch if not zero (not infinite length)
00C8C6  1               
00C8C6  1               ; is "infinite line" so check TAB position
00C8C6  1               
00C8C6  1  A5 0E              LDA   TPos              ; get position
00C8C8  1  E5 64              SBC   TabSiz            ; subtract TAB size, carry set by CMP #$20 above
00C8CA  1  D0 0B              BNE   LAB_18F7          ; skip reset if different
00C8CC  1               
00C8CC  1  85 0E              STA   TPos              ; else reset position
00C8CE  1  F0 07              BEQ   LAB_18F7          ; go print character
00C8D0  1               
00C8D0  1               LAB_18F0
00C8D0  1  C5 0E              CMP   TPos              ; compare with terminal character position
00C8D2  1  D0 03              BNE   LAB_18F7          ; branch if not at end of line
00C8D4  1               
00C8D4  1  20 62 C8           JSR   LAB_CRLF          ; else print CR/LF
00C8D7  1               LAB_18F7
00C8D7  1  E6 0E              INC   TPos              ; increment terminal position
00C8D9  1  68                 PLA                     ; get character back
00C8DA  1               LAB_18F9
00C8DA  1  20 D0 E0           JSR   V_OUTP            ; output byte via output vector
00C8DD  1  C9 0D              CMP   #$0D              ; compare with [CR]
00C8DF  1  D0 14              BNE   LAB_188A          ; branch if not [CR]
00C8E1  1               
00C8E1  1                                             ; else print nullct nulls after the [CR]
00C8E1  1  86 78              STX   TempB             ; save buffer index
00C8E3  1  A6 0D              LDX   Nullct            ; get null count
00C8E5  1  F0 0A              BEQ   LAB_1886          ; branch if no nulls
00C8E7  1               
00C8E7  1  A9 00              LDA   #$00              ; load [NULL]
00C8E9  1               LAB_1880
00C8E9  1  20 BD C8           JSR   LAB_PRNA          ; go print the character
00C8EC  1  CA                 DEX                     ; decrement count
00C8ED  1  D0 FA              BNE   LAB_1880          ; loop if not all done
00C8EF  1               
00C8EF  1  A9 0D              LDA   #$0D              ; restore the character (and set the flags)
00C8F1  1               LAB_1886
00C8F1  1  86 0E              STX   TPos              ; clear terminal position (X always = zero when we get here)
00C8F3  1  A6 78              LDX   TempB             ; restore buffer index
00C8F5  1               LAB_188A
00C8F5  1  29 FF              AND   #$FF              ; set the flags
00C8F7  1               LAB_188C
00C8F7  1  60                 RTS
00C8F8  1               
00C8F8  1               ; handle bad input data
00C8F8  1               
00C8F8  1               LAB_1904
00C8F8  1  A5 62              LDA   Imode             ; get input mode flag, $00=INPUT, $00=READ
00C8FA  1  10 0B              BPL   LAB_1913          ; branch if INPUT (go do redo)
00C8FC  1               
00C8FC  1  A5 8D              LDA   Dlinel            ; get current DATA line low byte
00C8FE  1  A4 8E              LDY   Dlineh            ; get current DATA line high byte
00C900  1  85 87              STA   Clinel            ; save current line low byte
00C902  1  84 88              STY   Clineh            ; save current line high byte
00C904  1               LAB_1910
00C904  1  4C D1 CB           JMP   LAB_SNER          ; do syntax error then warm start
00C907  1               
00C907  1                                             ; mode was INPUT
00C907  1               LAB_1913
00C907  1  A9 FB              LDA   #<LAB_REDO        ; point to redo message (low addr)
00C909  1  A0 E7              LDY   #>LAB_REDO        ; point to redo message (high addr)
00C90B  1  20 A3 C8           JSR   LAB_18C3          ; print null terminated string from memory
00C90E  1  A5 8B              LDA   Cpntrl            ; get continue pointer low byte
00C910  1  A4 8C              LDY   Cpntrh            ; get continue pointer high byte
00C912  1  85 C3              STA   Bpntrl            ; save BASIC execute pointer low byte
00C914  1  84 C4              STY   Bpntrh            ; save BASIC execute pointer high byte
00C916  1  60                 RTS
00C917  1               
00C917  1               ; perform INPUT
00C917  1               
00C917  1               LAB_INPUT
00C917  1  C9 22              CMP   #$22              ; compare next byte with open quote
00C919  1  D0 0B              BNE   LAB_1934          ; branch if no prompt string
00C91B  1               
00C91B  1  20 8D CB           JSR   LAB_1BC1          ; print "..." string
00C91E  1  A9 3B              LDA   #$3B              ; load A with ";"
00C920  1  20 C0 CB           JSR   LAB_SCCA          ; scan for CHR$(A), else do syntax error then warm start
00C923  1  20 A6 C8           JSR   LAB_18C6          ; print string from Sutill/Sutilh
00C926  1               
00C926  1                                             ; done with prompt, now get data
00C926  1               LAB_1934
00C926  1  20 39 D0           JSR   LAB_CKRN          ; check not Direct, back here if ok
00C929  1  20 06 C2           JSR   LAB_INLN          ; print "? " and get BASIC input
00C92C  1  A9 00              LDA   #$00              ; set mode = INPUT
00C92E  1  CD 80 02           CMP   Ibuffs            ; test first byte in buffer
00C931  1  D0 09              BNE   LAB_1953          ; branch if not null input
00C933  1               
00C933  1               ; *** change p2: keep carry set to throw break message
00C933  1               ;      CLC                     ; was null input so clear carry to exit program
00C933  1  4C FA C4           JMP   LAB_1647          ; go do BREAK exit
00C936  1               
00C936  1               ; perform READ
00C936  1               
00C936  1               LAB_READ
00C936  1  A6 8F              LDX   Dptrl             ; get DATA pointer low byte
00C938  1  A4 90              LDY   Dptrh             ; get DATA pointer high byte
00C93A  1  A9 80              LDA   #$80              ; set mode = READ
00C93C  1               
00C93C  1               LAB_1953
00C93C  1  85 62              STA   Imode             ; set input mode flag, $00=INPUT, $80=READ
00C93E  1  86 91              STX   Rdptrl            ; save READ pointer low byte
00C940  1  84 92              STY   Rdptrh            ; save READ pointer high byte
00C942  1               
00C942  1                                             ; READ or INPUT next variable from list
00C942  1               LAB_195B
00C942  1  20 79 CD           JSR   LAB_GVAR          ; get (var) address
00C945  1  85 97              STA   Lvarpl            ; save address low byte
00C947  1  84 98              STY   Lvarph            ; save address high byte
00C949  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte
00C94B  1  A4 C4              LDY   Bpntrh            ; get BASIC execute pointer high byte
00C94D  1  85 11              STA   Itempl            ; save as temporary integer low byte
00C94F  1  84 12              STY   Itemph            ; save as temporary integer high byte
00C951  1  A6 91              LDX   Rdptrl            ; get READ pointer low byte
00C953  1  A4 92              LDY   Rdptrh            ; get READ pointer high byte
00C955  1  86 C3              STX   Bpntrl            ; set BASIC execute pointer low byte
00C957  1  84 C4              STY   Bpntrh            ; set BASIC execute pointer high byte
00C959  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C95C  1  D0 11              BNE   LAB_1988          ; branch if not null
00C95E  1               
00C95E  1                                             ; pointer was to null entry
00C95E  1  24 62              BIT   Imode             ; test input mode flag, $00=INPUT, $80=READ
00C960  1  30 65              BMI   LAB_19DD          ; branch if READ
00C962  1               
00C962  1                                             ; mode was INPUT
00C962  1  20 BB C8           JSR   LAB_18E3          ; print "?" character (double ? for extended input)
00C965  1  20 06 C2           JSR   LAB_INLN          ; print "? " and get BASIC input
00C968  1  86 C3              STX   Bpntrl            ; set BASIC execute pointer low byte
00C96A  1  84 C4              STY   Bpntrh            ; set BASIC execute pointer high byte
00C96C  1               LAB_1985
00C96C  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C96F  1               LAB_1988
00C96F  1  24 5F              BIT   Dtypef            ; test data type flag, $FF=string, $00=numeric
00C971  1  10 24              BPL   LAB_19B0          ; branch if numeric
00C973  1               
00C973  1                                             ; else get string
00C973  1  85 5B              STA   Srchc             ; save search character
00C975  1  C9 22              CMP   #$22              ; was it " ?
00C977  1  F0 07              BEQ   LAB_1999          ; branch if so
00C979  1               
00C979  1  A9 3A              LDA   #':'              ; else search character is ":"
00C97B  1  85 5B              STA   Srchc             ; set new search character
00C97D  1  A9 2C              LDA   #','              ; other search character is ","
00C97F  1  18                 CLC                     ; clear carry for add
00C980  1               LAB_1999
00C980  1  85 5C              STA   Asrch             ; set second search character
00C982  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte
00C984  1  A4 C4              LDY   Bpntrh            ; get BASIC execute pointer high byte
00C986  1               
00C986  1  69 00              ADC   #$00              ; c is =1 if we came via the BEQ LAB_1999, else =0
00C988  1  90 01              BCC   LAB_19A4          ; branch if no execute pointer low byte rollover
00C98A  1               
00C98A  1  C8                 INY                     ; else increment high byte
00C98B  1               LAB_19A4
00C98B  1  20 19 D1           JSR   LAB_20B4          ; print Srchc or Asrch terminated string to Sutill/Sutilh
00C98E  1  20 A0 D4           JSR   LAB_23F3          ; restore BASIC execute pointer from temp (Btmpl/Btmph)
00C991  1  20 A0 C7           JSR   LAB_17D5          ; go do string LET
00C994  1  4C 9D C9           JMP   LAB_19B6          ; go check string terminator
00C997  1               
00C997  1                                             ; get numeric INPUT
00C997  1               LAB_19B0
00C997  1  20 77 D9           JSR   LAB_2887          ; get FAC1 from string
00C99A  1  20 74 D8           JSR   LAB_PFAC          ; pack FAC1 into (Lvarpl)
00C99D  1               LAB_19B6
00C99D  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C9A0  1  F0 0A              BEQ   LAB_19C5          ; branch if null (last entry)
00C9A2  1               
00C9A2  1  C9 2C              CMP   #','              ; else compare with ","
00C9A4  1  F0 03              BEQ   LAB_19C2          ; branch if ","
00C9A6  1               
00C9A6  1  4C F8 C8           JMP   LAB_1904          ; else go handle bad input data
00C9A9  1               
00C9A9  1                                             ; got good input data
00C9A9  1               LAB_19C2
00C9A9  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00C9AC  1               LAB_19C5
00C9AC  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte (temp READ/INPUT ptr)
00C9AE  1  A4 C4              LDY   Bpntrh            ; get BASIC execute pointer high byte (temp READ/INPUT ptr)
00C9B0  1  85 91              STA   Rdptrl            ; save for now
00C9B2  1  84 92              STY   Rdptrh            ; save for now
00C9B4  1  A5 11              LDA   Itempl            ; get temporary integer low byte (temp BASIC execute ptr)
00C9B6  1  A4 12              LDY   Itemph            ; get temporary integer high byte (temp BASIC execute ptr)
00C9B8  1  85 C3              STA   Bpntrl            ; set BASIC execute pointer low byte
00C9BA  1  84 C4              STY   Bpntrh            ; set BASIC execute pointer high byte
00C9BC  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00C9BF  1  F0 2C              BEQ   LAB_1A03          ; if null go do extra ignored message
00C9C1  1               
00C9C1  1  20 CD CB           JSR   LAB_1C01          ; else scan for "," , else do syntax error then warm start
00C9C4  1  4C 42 C9           JMP   LAB_195B          ; go INPUT next variable from list
00C9C7  1               
00C9C7  1                                             ; find next DATA statement or do "Out of DATA" error
00C9C7  1               LAB_19DD
00C9C7  1  20 6D C6           JSR   LAB_SNBS          ; scan for next BASIC statement ([:] or [EOL])
00C9CA  1  C8                 INY                     ; increment index
00C9CB  1  AA                 TAX                     ; copy character ([:] or [EOL])
00C9CC  1  D0 12              BNE   LAB_19F6          ; branch if [:]
00C9CE  1               
00C9CE  1  A2 06              LDX   #$06              ; set for "Out of DATA" error
00C9D0  1  C8                 INY                     ; increment index, now points to next line pointer high byte
00C9D1  1  B1 C3              LDA   (Bpntrl),Y        ; get next line pointer high byte
00C9D3  1  F0 73              BEQ   LAB_1A54          ; branch if end (eventually does error X)
00C9D5  1               
00C9D5  1  C8                 INY                     ; increment index
00C9D6  1  B1 C3              LDA   (Bpntrl),Y        ; get next line # low byte
00C9D8  1  85 8D              STA   Dlinel            ; save current DATA line low byte
00C9DA  1  C8                 INY                     ; increment index
00C9DB  1  B1 C3              LDA   (Bpntrl),Y        ; get next line # high byte
00C9DD  1  C8                 INY                     ; increment index
00C9DE  1  85 8E              STA   Dlineh            ; save current DATA line high byte
00C9E0  1               LAB_19F6
00C9E0  1  B1 C3              LDA   (Bpntrl),Y        ; get byte
00C9E2  1  C8                 INY                     ; increment index
00C9E3  1  AA                 TAX                     ; copy to X
00C9E4  1  20 5F C6           JSR   LAB_170F          ; set BASIC execute pointer
00C9E7  1  E0 83              CPX   #TK_DATA          ; compare with "DATA" token
00C9E9  1  F0 81              BEQ   LAB_1985          ; was "DATA" so go do next READ
00C9EB  1               
00C9EB  1  D0 DA              BNE   LAB_19DD          ; go find next statement if not "DATA"
00C9ED  1               
00C9ED  1               ; end of INPUT/READ routine
00C9ED  1               
00C9ED  1               LAB_1A03
00C9ED  1  A5 91              LDA   Rdptrl            ; get temp READ pointer low byte
00C9EF  1  A4 92              LDY   Rdptrh            ; get temp READ pointer high byte
00C9F1  1  A6 62              LDX   Imode             ; get input mode flag, $00=INPUT, $80=READ
00C9F3  1  10 03              BPL   LAB_1A0E          ; branch if INPUT
00C9F5  1               
00C9F5  1  4C 1C C5           JMP   LAB_1624          ; save AY as DATA pointer and return
00C9F8  1               
00C9F8  1                                             ; we were getting INPUT
00C9F8  1               LAB_1A0E
00C9F8  1  A0 00              LDY   #$00              ; clear index
00C9FA  1  B1 91              LDA   (Rdptrl),Y        ; get next byte
00C9FC  1  D0 01              BNE   LAB_1A1B          ; error if not end of INPUT
00C9FE  1               
00C9FE  1  60                 RTS
00C9FF  1               
00C9FF  1                                             ; user typed too much
00C9FF  1               LAB_1A1B
00C9FF  1  A9 EA              LDA   #<LAB_IMSG        ; point to extra ignored message (low addr)
00CA01  1  A0 E7              LDY   #>LAB_IMSG        ; point to extra ignored message (high addr)
00CA03  1  4C A3 C8           JMP   LAB_18C3          ; print null terminated string from memory and return
00CA06  1               
00CA06  1               ; search the stack for FOR activity
00CA06  1               ; exit with z=1 if FOR else exit with z=0
00CA06  1               
00CA06  1               LAB_11A1
00CA06  1  BA                 TSX                     ; copy stack pointer
00CA07  1  E8                 INX                     ; +1 pass return address
00CA08  1  E8                 INX                     ; +2 pass return address
00CA09  1  E8                 INX                     ; +3 pass calling routine return address
00CA0A  1  E8                 INX                     ; +4 pass calling routine return address
00CA0B  1               LAB_11A6
00CA0B  1  BD 01 01           LDA   LAB_STAK+1,X      ; get token byte from stack
00CA0E  1  C9 81              CMP   #TK_FOR           ; is it FOR token
00CA10  1  D0 21              BNE   LAB_11CE          ; exit if not FOR token
00CA12  1               
00CA12  1                                             ; was FOR token
00CA12  1  A5 98              LDA   Frnxth            ; get var pointer for FOR/NEXT high byte
00CA14  1  D0 0A              BNE   LAB_11BB          ; branch if not null
00CA16  1               
00CA16  1  BD 02 01           LDA   LAB_STAK+2,X      ; get FOR variable pointer low byte
00CA19  1  85 97              STA   Frnxtl            ; save var pointer for FOR/NEXT low byte
00CA1B  1  BD 03 01           LDA   LAB_STAK+3,X      ; get FOR variable pointer high byte
00CA1E  1  85 98              STA   Frnxth            ; save var pointer for FOR/NEXT high byte
00CA20  1               LAB_11BB
00CA20  1  DD 03 01           CMP   LAB_STAK+3,X      ; compare var pointer with stacked var pointer (high byte)
00CA23  1  D0 07              BNE   LAB_11C7          ; branch if no match
00CA25  1               
00CA25  1  A5 97              LDA   Frnxtl            ; get var pointer for FOR/NEXT low byte
00CA27  1  DD 02 01           CMP   LAB_STAK+2,X      ; compare var pointer with stacked var pointer (low byte)
00CA2A  1  F0 07              BEQ   LAB_11CE          ; exit if match found
00CA2C  1               
00CA2C  1               LAB_11C7
00CA2C  1  8A                 TXA                     ; copy index
00CA2D  1  18                 CLC                     ; clear carry for add
00CA2E  1  69 10              ADC   #$10              ; add FOR stack use size
00CA30  1  AA                 TAX                     ; copy back to index
00CA31  1  D0 D8              BNE   LAB_11A6          ; loop if not at start of stack
00CA33  1               
00CA33  1               LAB_11CE
00CA33  1  60                 RTS
00CA34  1               
00CA34  1               ; perform NEXT
00CA34  1               
00CA34  1               LAB_NEXT
00CA34  1  D0 04              BNE   LAB_1A46          ; branch if NEXT var
00CA36  1               
00CA36  1  A0 00              LDY   #$00              ; else clear Y
00CA38  1  F0 03              BEQ   LAB_1A49          ; branch always (no variable to search for)
00CA3A  1               
00CA3A  1               ; NEXT var
00CA3A  1               
00CA3A  1               LAB_1A46
00CA3A  1  20 79 CD           JSR   LAB_GVAR          ; get variable address
00CA3D  1               LAB_1A49
00CA3D  1  85 97              STA   Frnxtl            ; store variable pointer low byte
00CA3F  1  84 98              STY   Frnxth            ; store variable pointer high byte
00CA41  1                                             ; (both cleared if no variable defined)
00CA41  1  20 06 CA           JSR   LAB_11A1          ; search the stack for FOR activity
00CA44  1  F0 04              BEQ   LAB_1A56          ; branch if found
00CA46  1               
00CA46  1  A2 00              LDX   #$00              ; else set error $00 ("NEXT without FOR" error)
00CA48  1               LAB_1A54
00CA48  1  F0 63              BEQ   LAB_1ABE          ; do error #X, then warm start
00CA4A  1               
00CA4A  1               LAB_1A56
00CA4A  1  9A                 TXS                     ; set stack pointer, X set by search, dumps return addresses
00CA4B  1               
00CA4B  1  8A                 TXA                     ; copy stack pointer
00CA4C  1  38                 SEC                     ; set carry for subtract
00CA4D  1  E9 F7              SBC   #$F7              ; point to TO var
00CA4F  1  85 73              STA   ut2_pl            ; save pointer to TO var for compare
00CA51  1  69 FB              ADC   #$FB              ; point to STEP var
00CA53  1               
00CA53  1  A0 01              LDY   #>LAB_STAK        ; point to stack page high byte
00CA55  1  20 4E D8           JSR   LAB_UFAC          ; unpack memory (STEP value) into FAC1
00CA58  1  BA                 TSX                     ; get stack pointer back
00CA59  1  BD 08 01           LDA   LAB_STAK+8,X      ; get step sign
00CA5C  1  85 B0              STA   FAC1_s            ; save FAC1 sign (b7)
00CA5E  1  A5 97              LDA   Frnxtl            ; get FOR variable pointer low byte
00CA60  1  A4 98              LDY   Frnxth            ; get FOR variable pointer high byte
00CA62  1  20 8F D5           JSR   LAB_246C          ; add (FOR variable) to FAC1
00CA65  1  20 74 D8           JSR   LAB_PFAC          ; pack FAC1 into (FOR variable)
00CA68  1  A0 01              LDY   #>LAB_STAK        ; point to stack page high byte
00CA6A  1  20 EA D8           JSR   LAB_27FA          ; compare FAC1 with (Y,ut2_pl) (TO value)
00CA6D  1  BA                 TSX                     ; get stack pointer back
00CA6E  1  DD 08 01           CMP   LAB_STAK+8,X      ; compare step sign
00CA71  1  F0 17              BEQ   LAB_1A9B          ; branch if = (loop complete)
00CA73  1               
00CA73  1                                             ; loop back and do it all again
00CA73  1  BD 0D 01           LDA   LAB_STAK+$0D,X    ; get FOR line low byte
00CA76  1  85 87              STA   Clinel            ; save current line low byte
00CA78  1  BD 0E 01           LDA   LAB_STAK+$0E,X    ; get FOR line high byte
00CA7B  1  85 88              STA   Clineh            ; save current line high byte
00CA7D  1  BD 10 01           LDA   LAB_STAK+$10,X    ; get BASIC execute pointer low byte
00CA80  1  85 C3              STA   Bpntrl            ; save BASIC execute pointer low byte
00CA82  1  BD 0F 01           LDA   LAB_STAK+$0F,X    ; get BASIC execute pointer high byte
00CA85  1  85 C4              STA   Bpntrh            ; save BASIC execute pointer high byte
00CA87  1               LAB_1A98
00CA87  1  4C 92 C4           JMP   LAB_15C2          ; go do interpreter inner loop
00CA8A  1               
00CA8A  1                                             ; loop complete so carry on
00CA8A  1               LAB_1A9B
00CA8A  1  8A                 TXA                     ; stack copy to A
00CA8B  1  69 0F              ADC   #$0F              ; add $10 ($0F+carry) to dump FOR structure
00CA8D  1  AA                 TAX                     ; copy back to index
00CA8E  1  9A                 TXS                     ; copy to stack pointer
00CA8F  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00CA92  1  C9 2C              CMP   #','              ; compare with ","
00CA94  1  D0 F1              BNE   LAB_1A98          ; branch if not "," (go do interpreter inner loop)
00CA96  1               
00CA96  1                                             ; was "," so another NEXT variable to do
00CA96  1  20 BC 00           JSR   LAB_IGBY          ; else increment and scan memory
00CA99  1  20 3A CA           JSR   LAB_1A46          ; do NEXT (var)
00CA9C  1               
00CA9C  1               ; evaluate expression and check is numeric, else do type mismatch
00CA9C  1               
00CA9C  1               LAB_EVNM
00CA9C  1  20 B0 CA           JSR   LAB_EVEX          ; evaluate expression
00CA9F  1               
00CA9F  1               ; check if source is numeric, else do type mismatch
00CA9F  1               
00CA9F  1               LAB_CTNM
00CA9F  1  18                 CLC                     ; destination is numeric
00CAA0  1  24                 .byte $24               ; makes next line BIT $38
00CAA1  1               
00CAA1  1               ; check if source is string, else do type mismatch
00CAA1  1               
00CAA1  1               LAB_CTST
00CAA1  1  38                 SEC                     ; required type is string
00CAA2  1               
00CAA2  1               ; type match check, set C for string, clear C for numeric
00CAA2  1               
00CAA2  1               LAB_CKTM
00CAA2  1  24 5F              BIT   Dtypef            ; test data type flag, $FF=string, $00=numeric
00CAA4  1  30 03              BMI   LAB_1ABA          ; branch if data type is string
00CAA6  1               
00CAA6  1                                             ; else data type was numeric
00CAA6  1  B0 03              BCS   LAB_1ABC          ; if required type is string do type mismatch error
00CAA8  1               LAB_1AB9
00CAA8  1  60                 RTS
00CAA9  1               
00CAA9  1                                             ; data type was string, now check required type
00CAA9  1               LAB_1ABA
00CAA9  1  B0 FD              BCS   LAB_1AB9          ; exit if required type is string
00CAAB  1               
00CAAB  1                                             ; else do type mismatch error
00CAAB  1               LAB_1ABC
00CAAB  1  A2 18              LDX   #$18              ; error code $18 ("Type mismatch" error)
00CAAD  1               LAB_1ABE
00CAAD  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00CAB0  1               
00CAB0  1               ; evaluate expression
00CAB0  1               
00CAB0  1               LAB_EVEX
00CAB0  1  A6 C3              LDX   Bpntrl            ; get BASIC execute pointer low byte
00CAB2  1  D0 02              BNE   LAB_1AC7          ; skip next if not zero
00CAB4  1               
00CAB4  1  C6 C4              DEC   Bpntrh            ; else decrement BASIC execute pointer high byte
00CAB6  1               LAB_1AC7
00CAB6  1  C6 C3              DEC   Bpntrl            ; decrement BASIC execute pointer low byte
00CAB8  1               
00CAB8  1               LAB_EVEZ
00CAB8  1  A9 00              LDA   #$00              ; set null precedence (flag done)
00CABA  1               LAB_1ACC
00CABA  1  48                 PHA                     ; push precedence byte
00CABB  1  A9 02              LDA   #$02              ; 2 bytes
00CABD  1  20 C9 C0           JSR   LAB_1212          ; check room on stack for A bytes
00CAC0  1  20 9C CB           JSR   LAB_GVAL          ; get value from line
00CAC3  1  A9 00              LDA   #$00              ; clear A
00CAC5  1  85 9B              STA   comp_f            ; clear compare function flag
00CAC7  1               LAB_1ADB
00CAC7  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00CACA  1               LAB_1ADE
00CACA  1  38                 SEC                     ; set carry for subtract
00CACB  1  E9 C0              SBC   #TK_GT            ; subtract token for > (lowest comparison function)
00CACD  1  90 17              BCC   LAB_1AFA          ; branch if < TK_GT
00CACF  1               
00CACF  1  C9 03              CMP   #$03              ; compare with ">" to "<" tokens
00CAD1  1  B0 13              BCS   LAB_1AFA          ; branch if >= TK_SGN (highest evaluation function +1)
00CAD3  1               
00CAD3  1                                             ; was token for > = or < (A = 0, 1 or 2)
00CAD3  1  C9 01              CMP   #$01              ; compare with token for =
00CAD5  1  2A                 ROL                     ; *2, b0 = carry (=1 if token was = or <)
00CAD6  1                                             ; (A = 0, 3 or 5)
00CAD6  1  49 01              EOR   #$01              ; toggle b0
00CAD8  1                                             ; (A = 1, 2 or 4. 1 if >, 2 if =, 4 if <)
00CAD8  1  45 9B              EOR   comp_f            ; EOR with compare function flag bits
00CADA  1  C5 9B              CMP   comp_f            ; compare with compare function flag
00CADC  1  90 67              BCC   LAB_1B53          ; if <(comp_f) do syntax error then warm start
00CADE  1                                             ; was more than one <, = or >)
00CADE  1               
00CADE  1  85 9B              STA   comp_f            ; save new compare function flag
00CAE0  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00CAE3  1  4C CA CA           JMP   LAB_1ADE          ; go do next character
00CAE6  1               
00CAE6  1                                             ; token is < ">" or > "<" tokens
00CAE6  1               LAB_1AFA
00CAE6  1  A6 9B              LDX   comp_f            ; get compare function flag
00CAE8  1  D0 2C              BNE   LAB_1B2A          ; branch if compare function
00CAEA  1               
00CAEA  1  B0 79              BCS   LAB_1B78          ; go do functions
00CAEC  1               
00CAEC  1                                             ; else was <  TK_GT so is operator or lower
00CAEC  1  69 0A              ADC   #TK_GT-TK_PLUS    ; add # of operators (+, -, *, /, ^, AND, OR or EOR)
00CAEE  1  90 75              BCC   LAB_1B78          ; branch if < + operator
00CAF0  1               
00CAF0  1                                             ; carry was set so token was +, -, *, /, ^, AND, OR or EOR
00CAF0  1  D0 07              BNE   LAB_1B0B          ; branch if not + token
00CAF2  1               
00CAF2  1  24 5F              BIT   Dtypef            ; test data type flag, $FF=string, $00=numeric
00CAF4  1  10 03              BPL   LAB_1B0B          ; branch if not string
00CAF6  1               
00CAF6  1                                             ; will only be $00 if type is string and token was +
00CAF6  1  4C A5 D2           JMP   LAB_224D          ; add strings, string 1 is in descriptor des_pl, string 2
00CAF9  1                                             ; is in line, and return
00CAF9  1               
00CAF9  1               LAB_1B0B
00CAF9  1  85 71              STA   ut1_pl            ; save it
00CAFB  1  0A                 ASL                     ; *2
00CAFC  1  65 71              ADC   ut1_pl            ; *3
00CAFE  1  A8                 TAY                     ; copy to index
00CAFF  1               LAB_1B13
00CAFF  1  68                 PLA                     ; pull previous precedence
00CB00  1  D9 D2 E2           CMP   LAB_OPPT,Y        ; compare with precedence byte
00CB03  1  B0 65              BCS   LAB_1B7D          ; branch if A >=
00CB05  1               
00CB05  1  20 9F CA           JSR   LAB_CTNM          ; check if source is numeric, else do type mismatch
00CB08  1               LAB_1B1C
00CB08  1  48                 PHA                     ; save precedence
00CB09  1               LAB_1B1D
00CB09  1  20 31 CB           JSR   LAB_1B43          ; get vector, execute function then continue evaluation
00CB0C  1  68                 PLA                     ; restore precedence
00CB0D  1  A4 99              LDY   prstk             ; get precedence stacked flag
00CB0F  1  10 19              BPL   LAB_1B3C          ; branch if stacked values
00CB11  1               
00CB11  1  AA                 TAX                     ; copy precedence (set flags)
00CB12  1  F0 76              BEQ   LAB_1B9D          ; exit if done
00CB14  1               
00CB14  1  D0 5D              BNE   LAB_1B86          ; else pop FAC2 and return, branch always
00CB16  1               
00CB16  1               LAB_1B2A
00CB16  1  26 5F              ROL   Dtypef            ; shift data type flag into Cb
00CB18  1  8A                 TXA                     ; copy compare function flag
00CB19  1  85 5F              STA   Dtypef            ; clear data type flag, X is 0xxx xxxx
00CB1B  1  2A                 ROL                     ; shift data type into compare function byte b0
00CB1C  1  A6 C3              LDX   Bpntrl            ; get BASIC execute pointer low byte
00CB1E  1  D0 02              BNE   LAB_1B34          ; branch if no underflow
00CB20  1               
00CB20  1  C6 C4              DEC   Bpntrh            ; else decrement BASIC execute pointer high byte
00CB22  1               LAB_1B34
00CB22  1  C6 C3              DEC   Bpntrl            ; decrement BASIC execute pointer low byte
00CB24  1               TK_LT_PLUS  = TK_LT-TK_PLUS
00CB24  1  A0 24              LDY   #TK_LT_PLUS*3     ; set offset to last operator entry
00CB26  1  85 9B              STA   comp_f            ; save new compare function flag
00CB28  1  D0 D5              BNE   LAB_1B13          ; branch always
00CB2A  1               
00CB2A  1               LAB_1B3C
00CB2A  1  D9 D2 E2           CMP   LAB_OPPT,Y        ;.compare with stacked function precedence
00CB2D  1  B0 44              BCS   LAB_1B86          ; branch if A >=, pop FAC2 and return
00CB2F  1               
00CB2F  1  90 D7              BCC   LAB_1B1C          ; branch always
00CB31  1               
00CB31  1               ;.get vector, execute function then continue evaluation
00CB31  1               
00CB31  1               LAB_1B43
00CB31  1  B9 D4 E2           LDA   LAB_OPPT+2,Y      ; get function vector high byte
00CB34  1  48                 PHA                     ; onto stack
00CB35  1  B9 D3 E2           LDA   LAB_OPPT+1,Y      ; get function vector low byte
00CB38  1  48                 PHA                     ; onto stack
00CB39  1                                             ; now push sign, round FAC1 and put on stack
00CB39  1  20 48 CB           JSR   LAB_1B5B          ; function will return here, then the next RTS will call
00CB3C  1                                             ; the function
00CB3C  1  A5 9B              LDA   comp_f            ; get compare function flag
00CB3E  1  48                 PHA                     ; push compare evaluation byte
00CB3F  1  B9 D2 E2           LDA   LAB_OPPT,Y        ; get precedence byte
00CB42  1  4C BA CA           JMP   LAB_1ACC          ; continue evaluating expression
00CB45  1               
00CB45  1               LAB_1B53
00CB45  1  4C D1 CB           JMP   LAB_SNER          ; do syntax error then warm start
00CB48  1               
00CB48  1               ; push sign, round FAC1 and put on stack
00CB48  1               
00CB48  1               LAB_1B5B
00CB48  1  68                 PLA                     ; get return addr low byte
00CB49  1  85 71              STA   ut1_pl            ; save it
00CB4B  1  E6 71              INC   ut1_pl            ; increment it (was ret-1 pushed? yes!)
00CB4D  1                                             ; note! no check is made on the high byte! if the calling
00CB4D  1                                             ; routine assembles to a page edge then this all goes
00CB4D  1                                             ; horribly wrong !!!
00CB4D  1  68                 PLA                     ; get return addr high byte
00CB4E  1  85 72              STA   ut1_ph            ; save it
00CB50  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00CB52  1  48                 PHA                     ; push sign
00CB53  1               
00CB53  1               ; round FAC1 and put on stack
00CB53  1               
00CB53  1               LAB_1B66
00CB53  1  20 AA D8           JSR   LAB_27BA          ; round FAC1
00CB56  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00CB58  1  48                 PHA                     ; push on stack
00CB59  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00CB5B  1  48                 PHA                     ; push on stack
00CB5C  1  A5 AD              LDA   FAC1_1            ; get FAC1 mantissa1
00CB5E  1  48                 PHA                     ; push on stack
00CB5F  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00CB61  1  48                 PHA                     ; push on stack
00CB62  1  6C 71 00           JMP   (ut1_pl)          ; return, sort of
00CB65  1               
00CB65  1               ; do functions
00CB65  1               
00CB65  1               LAB_1B78
00CB65  1  A0 FF              LDY   #$FF              ; flag function
00CB67  1  68                 PLA                     ; pull precedence byte
00CB68  1               LAB_1B7B
00CB68  1  F0 20              BEQ   LAB_1B9D          ; exit if done
00CB6A  1               
00CB6A  1               LAB_1B7D
00CB6A  1  C9 64              CMP   #$64              ; compare previous precedence with $64
00CB6C  1  F0 03              BEQ   LAB_1B84          ; branch if was $64 (< function)
00CB6E  1               
00CB6E  1  20 9F CA           JSR   LAB_CTNM          ; check if source is numeric, else do type mismatch
00CB71  1               LAB_1B84
00CB71  1  84 99              STY   prstk             ; save precedence stacked flag
00CB73  1               
00CB73  1                                             ; pop FAC2 and return
00CB73  1               LAB_1B86
00CB73  1  68                 PLA                     ; pop byte
00CB74  1  4A                 LSR                     ; shift out comparison evaluation lowest bit
00CB75  1  85 63              STA   Cflag             ; save comparison evaluation flag
00CB77  1  68                 PLA                     ; pop exponent
00CB78  1  85 B3              STA   FAC2_e            ; save FAC2 exponent
00CB7A  1  68                 PLA                     ; pop mantissa1
00CB7B  1  85 B4              STA   FAC2_1            ; save FAC2 mantissa1
00CB7D  1  68                 PLA                     ; pop mantissa2
00CB7E  1  85 B5              STA   FAC2_2            ; save FAC2 mantissa2
00CB80  1  68                 PLA                     ; pop mantissa3
00CB81  1  85 B6              STA   FAC2_3            ; save FAC2 mantissa3
00CB83  1  68                 PLA                     ; pop sign
00CB84  1  85 B7              STA   FAC2_s            ; save FAC2 sign (b7)
00CB86  1  45 B0              EOR   FAC1_s            ; EOR FAC1 sign (b7)
00CB88  1  85 B8              STA   FAC_sc            ; save sign compare (FAC1 EOR FAC2)
00CB8A  1               LAB_1B9D
00CB8A  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00CB8C  1  60                 RTS
00CB8D  1               
00CB8D  1               ; print "..." string to string util area
00CB8D  1               
00CB8D  1               LAB_1BC1
00CB8D  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte
00CB8F  1  A4 C4              LDY   Bpntrh            ; get BASIC execute pointer high byte
00CB91  1  69 00              ADC   #$00              ; add carry to low byte
00CB93  1  90 01              BCC   LAB_1BCA          ; branch if no overflow
00CB95  1               
00CB95  1  C8                 INY                     ; increment high byte
00CB96  1               LAB_1BCA
00CB96  1  20 13 D1           JSR   LAB_20AE          ; print " terminated string to Sutill/Sutilh
00CB99  1  4C A0 D4           JMP   LAB_23F3          ; restore BASIC execute pointer from temp and return
00CB9C  1               
00CB9C  1               ; get value from line
00CB9C  1               
00CB9C  1               LAB_GVAL
00CB9C  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00CB9F  1  B0 03              BCS   LAB_1BAC          ; branch if not numeric character
00CBA1  1               
00CBA1  1                                             ; else numeric string found (e.g. 123)
00CBA1  1               LAB_1BA9
00CBA1  1  4C 77 D9           JMP   LAB_2887          ; get FAC1 from string and return
00CBA4  1               
00CBA4  1               ; get value from line .. continued
00CBA4  1               
00CBA4  1                                             ; wasn't a number so ..
00CBA4  1               LAB_1BAC
00CBA4  1  AA                 TAX                     ; set the flags
00CBA5  1  30 2F              BMI   LAB_1BD0          ; if -ve go test token values
00CBA7  1               
00CBA7  1                                             ; else it is either a string, number, variable or (<expr>)
00CBA7  1  C9 24              CMP   #'$'              ; compare with "$"
00CBA9  1  F0 F6              BEQ   LAB_1BA9          ; branch if "$", hex number
00CBAB  1               
00CBAB  1  C9 25              CMP   #'%'              ; else compare with "%"
00CBAD  1  F0 F2              BEQ   LAB_1BA9          ; branch if "%", binary number
00CBAF  1               
00CBAF  1  C9 2E              CMP   #'.'              ; compare with "."
00CBB1  1  F0 EE              BEQ   LAB_1BA9          ; if so get FAC1 from string and return (e.g. was .123)
00CBB3  1               
00CBB3  1                                             ; it wasn't any sort of number so ..
00CBB3  1  C9 22              CMP   #$22              ; compare with "
00CBB5  1  F0 D6              BEQ   LAB_1BC1          ; branch if open quote
00CBB7  1               
00CBB7  1                                             ; wasn't any sort of number so ..
00CBB7  1               
00CBB7  1               ; evaluate expression within parentheses
00CBB7  1               
00CBB7  1  C9 28              CMP   #'('              ; compare with "("
00CBB9  1  D0 4F              BNE   LAB_1C18          ; if not "(" get (var), return value in FAC1 and $ flag
00CBBB  1               
00CBBB  1               LAB_1BF7
00CBBB  1  20 B8 CA           JSR   LAB_EVEZ          ; evaluate expression, no decrement
00CBBE  1               
00CBBE  1               ; all the 'scan for' routines return the character after the sought character
00CBBE  1               
00CBBE  1               ; scan for ")" , else do syntax error then warm start
00CBBE  1               
00CBBE  1               LAB_1BFB
00CBBE  1  A9 29              LDA   #$29              ; load A with ")"
00CBC0  1               
00CBC0  1               ; scan for CHR$(A) , else do syntax error then warm start
00CBC0  1               
00CBC0  1               LAB_SCCA
00CBC0  1  A0 00              LDY   #$00              ; clear index
00CBC2  1  D1 C3              CMP   (Bpntrl),Y        ; check next byte is = A
00CBC4  1  D0 0B              BNE   LAB_SNER          ; if not do syntax error then warm start
00CBC6  1               
00CBC6  1  4C BC 00           JMP   LAB_IGBY          ; increment and scan memory then return
00CBC9  1               
00CBC9  1               ; scan for "(" , else do syntax error then warm start
00CBC9  1               
00CBC9  1               LAB_1BFE
00CBC9  1  A9 28              LDA   #$28              ; load A with "("
00CBCB  1  D0 F3              BNE   LAB_SCCA          ; scan for CHR$(A), else do syntax error then warm start
00CBCD  1                                             ; (branch always)
00CBCD  1               
00CBCD  1               ; scan for "," , else do syntax error then warm start
00CBCD  1               
00CBCD  1               LAB_1C01
00CBCD  1  A9 2C              LDA   #$2C              ; load A with ","
00CBCF  1  D0 EF              BNE   LAB_SCCA          ; scan for CHR$(A), else do syntax error then warm start
00CBD1  1                                             ; (branch always)
00CBD1  1               
00CBD1  1               ; syntax error then warm start
00CBD1  1               
00CBD1  1               LAB_SNER
00CBD1  1  A2 02              LDX   #$02              ; error code $02 ("Syntax" error)
00CBD3  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00CBD6  1               
00CBD6  1               ; get value from line .. continued
00CBD6  1               ; do tokens
00CBD6  1               
00CBD6  1               LAB_1BD0
00CBD6  1  C9 B7              CMP   #TK_MINUS         ; compare with token for -
00CBD8  1  F0 29              BEQ   LAB_1C11          ; branch if - token (do set-up for functions)
00CBDA  1               
00CBDA  1                                             ; wasn't -n so ..
00CBDA  1  C9 B6              CMP   #TK_PLUS          ; compare with token for +
00CBDC  1  F0 BE              BEQ   LAB_GVAL          ; branch if + token (+n = n so ignore leading +)
00CBDE  1               
00CBDE  1  C9 B1              CMP   #TK_NOT           ; compare with token for NOT
00CBE0  1  D0 13              BNE   LAB_1BE7          ; branch if not token for NOT
00CBE2  1               
00CBE2  1                                             ; was NOT token
00CBE2  1               TK_EQUAL_PLUS     = TK_EQUAL-TK_PLUS
00CBE2  1  A0 21              LDY   #TK_EQUAL_PLUS*3  ; offset to NOT function
00CBE4  1  D0 1F              BNE   LAB_1C13          ; do set-up for function then execute (branch always)
00CBE6  1               
00CBE6  1               ; do = compare
00CBE6  1               
00CBE6  1               LAB_EQUAL
00CBE6  1  20 75 CE           JSR   LAB_EVIR          ; evaluate integer expression (no sign check)
00CBE9  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00CBEB  1  49 FF              EOR   #$FF              ; invert it
00CBED  1  A8                 TAY                     ; copy it
00CBEE  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00CBF0  1  49 FF              EOR   #$FF              ; invert it
00CBF2  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00CBF5  1               
00CBF5  1               ; get value from line .. continued
00CBF5  1               
00CBF5  1                                             ; wasn't +, -, or NOT so ..
00CBF5  1               LAB_1BE7
00CBF5  1  C9 AE              CMP   #TK_FN            ; compare with token for FN
00CBF7  1  D0 03              BNE   LAB_1BEE          ; branch if not token for FN
00CBF9  1               
00CBF9  1  4C 83 D0           JMP   LAB_201E          ; go evaluate FNx
00CBFC  1               
00CBFC  1               ; get value from line .. continued
00CBFC  1               
00CBFC  1                                             ; wasn't +, -, NOT or FN so ..
00CBFC  1               LAB_1BEE
00CBFC  1  E9 C3              SBC   #TK_SGN           ; subtract with token for SGN
00CBFE  1  B0 19              BCS   LAB_1C27          ; if a function token go do it
00CC00  1               
00CC00  1  4C D1 CB           JMP   LAB_SNER          ; else do syntax error
00CC03  1               
00CC03  1               ; set-up for functions
00CC03  1               
00CC03  1               LAB_1C11
00CC03  1               TK_GT_PLUS  = TK_GT-TK_PLUS
00CC03  1  A0 1E              LDY   #TK_GT_PLUS*3     ; set offset from base to > operator
00CC05  1               LAB_1C13
00CC05  1  68                 PLA                     ; dump return address low byte
00CC06  1  68                 PLA                     ; dump return address high byte
00CC07  1  4C 09 CB           JMP   LAB_1B1D          ; execute function then continue evaluation
00CC0A  1               
00CC0A  1               ; variable name set-up
00CC0A  1               ; get (var), return value in FAC_1 and $ flag
00CC0A  1               
00CC0A  1               LAB_1C18
00CC0A  1  20 79 CD           JSR   LAB_GVAR          ; get (var) address
00CC0D  1  85 AE              STA   FAC1_2            ; save address low byte in FAC1 mantissa2
00CC0F  1  84 AF              STY   FAC1_3            ; save address high byte in FAC1 mantissa3
00CC11  1  A6 5F              LDX   Dtypef            ; get data type flag, $FF=string, $00=numeric
00CC13  1  30 03              BMI   LAB_1C25          ; if string then return (does RTS)
00CC15  1               
00CC15  1               LAB_1C24
00CC15  1  4C 4E D8           JMP   LAB_UFAC          ; unpack memory (AY) into FAC1
00CC18  1               
00CC18  1               LAB_1C25
00CC18  1  60                 RTS
00CC19  1               
00CC19  1               ; get value from line .. continued
00CC19  1               ; only functions left so ..
00CC19  1               
00CC19  1               ; set up function references
00CC19  1               
00CC19  1               ; new for V2.0+ this replaces a lot of IF .. THEN .. ELSEIF .. THEN .. that was needed
00CC19  1               ; to process function calls. now the function vector is computed and pushed on the stack
00CC19  1               ; and the preprocess offset is read. if the preprocess offset is non zero then the vector
00CC19  1               ; is calculated and the routine called, if not this routine just does RTS. whichever
00CC19  1               ; happens the RTS at the end of this routine, or the end of the preprocess routine, calls
00CC19  1               ; the function code
00CC19  1               
00CC19  1               ; this also removes some less than elegant code that was used to bypass type checking
00CC19  1               ; for functions that returned strings
00CC19  1               
00CC19  1               LAB_1C27
00CC19  1  0A                 ASL                     ; *2 (2 bytes per function address)
00CC1A  1  A8                 TAY                     ; copy to index
00CC1B  1               
00CC1B  1  B9 8D E2           LDA   LAB_FTBM,Y        ; get function jump vector high byte
00CC1E  1  48                 PHA                     ; push functions jump vector high byte
00CC1F  1  B9 8C E2           LDA   LAB_FTBL,Y        ; get function jump vector low byte
00CC22  1  48                 PHA                     ; push functions jump vector low byte
00CC23  1               
00CC23  1  B9 47 E2           LDA   LAB_FTPM,Y        ; get function pre process vector high byte
00CC26  1  F0 05              BEQ   LAB_1C56          ; skip pre process if null vector
00CC28  1               
00CC28  1  48                 PHA                     ; push functions pre process vector high byte
00CC29  1  B9 46 E2           LDA   LAB_FTPL,Y        ; get function pre process vector low byte
00CC2C  1  48                 PHA                     ; push functions pre process vector low byte
00CC2D  1               
00CC2D  1               LAB_1C56
00CC2D  1  60                 RTS                     ; do function, or pre process, call
00CC2E  1               
00CC2E  1               ; process string expression in parenthesis
00CC2E  1               
00CC2E  1               LAB_PPFS
00CC2E  1  20 BB CB           JSR   LAB_1BF7          ; process expression in parenthesis
00CC31  1  4C A1 CA           JMP   LAB_CTST          ; check if source is string then do function,
00CC34  1                                             ; else do type mismatch
00CC34  1               
00CC34  1               ; process numeric expression in parenthesis
00CC34  1               
00CC34  1               LAB_PPFN
00CC34  1  20 BB CB           JSR   LAB_1BF7          ; process expression in parenthesis
00CC37  1  4C 9F CA           JMP   LAB_CTNM          ; check if source is numeric then do function,
00CC3A  1                                             ; else do type mismatch
00CC3A  1               
00CC3A  1               ; set numeric data type and increment BASIC execute pointer
00CC3A  1               
00CC3A  1               LAB_PPBI
00CC3A  1  46 5F              LSR   Dtypef            ; clear data type flag, $FF=string, $00=numeric
00CC3C  1  4C BC 00           JMP   LAB_IGBY          ; increment and scan memory then do function
00CC3F  1               
00CC3F  1               ; process string for LEFT$, RIGHT$ or MID$
00CC3F  1               
00CC3F  1               LAB_LRMS
00CC3F  1  20 B8 CA           JSR   LAB_EVEZ          ; evaluate (should be string) expression
00CC42  1  20 CD CB           JSR   LAB_1C01          ; scan for ",", else do syntax error then warm start
00CC45  1  20 A1 CA           JSR   LAB_CTST          ; check if source is string, else do type mismatch
00CC48  1               
00CC48  1  68                 PLA                     ; get function jump vector low byte
00CC49  1  AA                 TAX                     ; save functions jump vector low byte
00CC4A  1  68                 PLA                     ; get function jump vector high byte
00CC4B  1  A8                 TAY                     ; save functions jump vector high byte
00CC4C  1  A5 AF              LDA   des_ph            ; get descriptor pointer high byte
00CC4E  1  48                 PHA                     ; push string pointer high byte
00CC4F  1  A5 AE              LDA   des_pl            ; get descriptor pointer low byte
00CC51  1  48                 PHA                     ; push string pointer low byte
00CC52  1  98                 TYA                     ; get function jump vector high byte back
00CC53  1  48                 PHA                     ; save functions jump vector high byte
00CC54  1  8A                 TXA                     ; get function jump vector low byte back
00CC55  1  48                 PHA                     ; save functions jump vector low byte
00CC56  1  20 5D D4           JSR   LAB_GTBY          ; get byte parameter
00CC59  1  8A                 TXA                     ; copy byte parameter to A
00CC5A  1  60                 RTS                     ; go do function
00CC5B  1               
00CC5B  1               ; process numeric expression(s) for BIN$ or HEX$
00CC5B  1               
00CC5B  1               LAB_BHSS
00CC5B  1  20 B8 CA           JSR   LAB_EVEZ          ; process expression
00CC5E  1  20 9F CA           JSR   LAB_CTNM          ; check if source is numeric, else do type mismatch
00CC61  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00CC63  1  C9 98              CMP   #$98              ; compare with exponent = 2^24
00CC65  1  B0 20              BCS   LAB_BHER          ; branch if n>=2^24 (is too big)
00CC67  1               
00CC67  1  20 21 D9           JSR   LAB_2831          ; convert FAC1 floating-to-fixed
00CC6A  1  A2 02              LDX   #$02              ; 3 bytes to do
00CC6C  1               LAB_CFAC
00CC6C  1  B5 AD              LDA   FAC1_1,X          ; get byte from FAC1
00CC6E  1  95 11              STA   nums_1,X          ; save byte to temp
00CC70  1  CA                 DEX                     ; decrement index
00CC71  1  10 F9              BPL   LAB_CFAC          ; copy FAC1 mantissa to temp
00CC73  1               
00CC73  1  20 C2 00           JSR   LAB_GBYT          ; get next BASIC byte
00CC76  1  A2 00              LDX   #$00              ; set default to no leading "0"s
00CC78  1  C9 29              CMP   #')'              ; compare with close bracket
00CC7A  1  F0 0A              BEQ   LAB_1C54          ; if ")" go do rest of function
00CC7C  1               
00CC7C  1  20 AF D4           JSR   LAB_SCGB          ; scan for "," and get byte
00CC7F  1  20 C2 00           JSR   LAB_GBYT          ; get last byte back
00CC82  1  C9 29              CMP   #')'              ; is next character )
00CC84  1  D0 01              BNE   LAB_BHER          ; if not ")" go do error
00CC86  1               
00CC86  1               LAB_1C54
00CC86  1  60                 RTS                     ; else do function
00CC87  1               
00CC87  1               LAB_BHER
00CC87  1  4C F8 CE           JMP   LAB_FCER          ; do function call error then warm start
00CC8A  1               
00CC8A  1               ; perform EOR
00CC8A  1               
00CC8A  1               ; added operator format is the same as AND or OR, precedence is the same as OR
00CC8A  1               
00CC8A  1               ; this bit worked first time but it took a while to sort out the operator table
00CC8A  1               ; pointers and offsets afterwards!
00CC8A  1               
00CC8A  1               LAB_EOR
00CC8A  1  20 B1 CC           JSR   GetFirst          ; get first integer expression (no sign check)
00CC8D  1  45 5B              EOR   XOAw_l            ; EOR with expression 1 low byte
00CC8F  1  A8                 TAY                     ; save in Y
00CC90  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00CC92  1  45 5C              EOR   XOAw_h            ; EOR with expression 1 high byte
00CC94  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00CC97  1               
00CC97  1               ; perform OR
00CC97  1               
00CC97  1               LAB_OR
00CC97  1  20 B1 CC           JSR   GetFirst          ; get first integer expression (no sign check)
00CC9A  1  05 5B              ORA   XOAw_l            ; OR with expression 1 low byte
00CC9C  1  A8                 TAY                     ; save in Y
00CC9D  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00CC9F  1  05 5C              ORA   XOAw_h            ; OR with expression 1 high byte
00CCA1  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00CCA4  1               
00CCA4  1               ; perform AND
00CCA4  1               
00CCA4  1               LAB_AND
00CCA4  1  20 B1 CC           JSR   GetFirst          ; get first integer expression (no sign check)
00CCA7  1  25 5B              AND   XOAw_l            ; AND with expression 1 low byte
00CCA9  1  A8                 TAY                     ; save in Y
00CCAA  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00CCAC  1  25 5C              AND   XOAw_h            ; AND with expression 1 high byte
00CCAE  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00CCB1  1               
00CCB1  1               ; get first value for OR, AND or EOR
00CCB1  1               
00CCB1  1               GetFirst
00CCB1  1  20 75 CE           JSR   LAB_EVIR          ; evaluate integer expression (no sign check)
00CCB4  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00CCB6  1  85 5C              STA   XOAw_h            ; save it
00CCB8  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00CCBA  1  85 5B              STA   XOAw_l            ; save it
00CCBC  1  20 94 D5           JSR   LAB_279B          ; copy FAC2 to FAC1 (get 2nd value in expression)
00CCBF  1  20 75 CE           JSR   LAB_EVIR          ; evaluate integer expression (no sign check)
00CCC2  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00CCC4  1               LAB_1C95
00CCC4  1  60                 RTS
00CCC5  1               
00CCC5  1               ; perform comparisons
00CCC5  1               
00CCC5  1               ; do < compare
00CCC5  1               
00CCC5  1               LAB_LTHAN
00CCC5  1  20 A2 CA           JSR   LAB_CKTM          ; type match check, set C for string
00CCC8  1  B0 13              BCS   LAB_1CAE          ; branch if string
00CCCA  1               
00CCCA  1                                             ; do numeric < compare
00CCCA  1  A5 B7              LDA   FAC2_s            ; get FAC2 sign (b7)
00CCCC  1  09 7F              ORA   #$7F              ; set all non sign bits
00CCCE  1  25 B4              AND   FAC2_1            ; and FAC2 mantissa1 (AND in sign bit)
00CCD0  1  85 B4              STA   FAC2_1            ; save FAC2 mantissa1
00CCD2  1  A9 B3              LDA   #<FAC2_e          ; set pointer low byte to FAC2
00CCD4  1  A0 00              LDY   #>FAC2_e          ; set pointer high byte to FAC2
00CCD6  1  20 E8 D8           JSR   LAB_27F8          ; compare FAC1 with FAC2 (AY)
00CCD9  1  AA                 TAX                     ; copy result
00CCDA  1  4C 0E CD           JMP   LAB_1CE1          ; go evaluate result
00CCDD  1               
00CCDD  1                                             ; do string < compare
00CCDD  1               LAB_1CAE
00CCDD  1  46 5F              LSR   Dtypef            ; clear data type flag, $FF=string, $00=numeric
00CCDF  1  C6 9B              DEC   comp_f            ; clear < bit in compare function flag
00CCE1  1  20 0F D3           JSR   LAB_22B6          ; pop string off descriptor stack, or from top of string
00CCE4  1                                             ; space returns with A = length, X=pointer low byte,
00CCE4  1                                             ; Y=pointer high byte
00CCE4  1  85 AC              STA   str_ln            ; save length
00CCE6  1  86 AD              STX   str_pl            ; save string pointer low byte
00CCE8  1  84 AE              STY   str_ph            ; save string pointer high byte
00CCEA  1  A5 B5              LDA   FAC2_2            ; get descriptor pointer low byte
00CCEC  1  A4 B6              LDY   FAC2_3            ; get descriptor pointer high byte
00CCEE  1  20 13 D3           JSR   LAB_22BA          ; pop (YA) descriptor off stack or from top of string space
00CCF1  1                                             ; returns with A = length, X=pointer low byte,
00CCF1  1                                             ; Y=pointer high byte
00CCF1  1  86 B5              STX   FAC2_2            ; save string pointer low byte
00CCF3  1  84 B6              STY   FAC2_3            ; save string pointer high byte
00CCF5  1  AA                 TAX                     ; copy length
00CCF6  1  38                 SEC                     ; set carry for subtract
00CCF7  1  E5 AC              SBC   str_ln            ; subtract string 1 length
00CCF9  1  F0 08              BEQ   LAB_1CD6          ; branch if str 1 length = string 2 length
00CCFB  1               
00CCFB  1  A9 01              LDA   #$01              ; set str 1 length > string 2 length
00CCFD  1  90 04              BCC   LAB_1CD6          ; branch if so
00CCFF  1               
00CCFF  1  A6 AC              LDX   str_ln            ; get string 1 length
00CD01  1  A9 FF              LDA   #$FF              ; set str 1 length < string 2 length
00CD03  1               LAB_1CD6
00CD03  1  85 B0              STA   FAC1_s            ; save length compare
00CD05  1  A0 FF              LDY   #$FF              ; set index
00CD07  1  E8                 INX                     ; adjust for loop
00CD08  1               LAB_1CDB
00CD08  1  C8                 INY                     ; increment index
00CD09  1  CA                 DEX                     ; decrement count
00CD0A  1  D0 07              BNE   LAB_1CE6          ; branch if still bytes to do
00CD0C  1               
00CD0C  1  A6 B0              LDX   FAC1_s            ; get length compare back
00CD0E  1               LAB_1CE1
00CD0E  1  30 0F              BMI   LAB_1CF2          ; branch if str 1 < str 2
00CD10  1               
00CD10  1  18                 CLC                     ; flag str 1 <= str 2
00CD11  1  90 0C              BCC   LAB_1CF2          ; go evaluate result
00CD13  1               
00CD13  1               LAB_1CE6
00CD13  1  B1 B5              LDA   (FAC2_2),Y        ; get string 2 byte
00CD15  1  D1 AD              CMP   (FAC1_1),Y        ; compare with string 1 byte
00CD17  1  F0 EF              BEQ   LAB_1CDB          ; loop if bytes =
00CD19  1               
00CD19  1  A2 FF              LDX   #$FF              ; set str 1 < string 2
00CD1B  1  B0 02              BCS   LAB_1CF2          ; branch if so
00CD1D  1               
00CD1D  1  A2 01              LDX   #$01              ;  set str 1 > string 2
00CD1F  1               LAB_1CF2
00CD1F  1  E8                 INX                     ; x = 0, 1 or 2
00CD20  1  8A                 TXA                     ; copy to A
00CD21  1  2A                 ROL                     ; *2 (1, 2 or 4)
00CD22  1  25 63              AND   Cflag             ; AND with comparison evaluation flag
00CD24  1  F0 02              BEQ   LAB_1CFB          ; branch if 0 (compare is false)
00CD26  1               
00CD26  1  A9 FF              LDA   #$FF              ; else set result true
00CD28  1               LAB_1CFB
00CD28  1  4C CB D8           JMP   LAB_27DB          ; save A as integer byte and return
00CD2B  1               
00CD2B  1               LAB_1CFE
00CD2B  1  20 CD CB           JSR   LAB_1C01          ; scan for ",", else do syntax error then warm start
00CD2E  1               
00CD2E  1               ; perform DIM
00CD2E  1               
00CD2E  1               LAB_DIM
00CD2E  1  AA                 TAX                     ; copy "DIM" flag to X
00CD2F  1  20 7E CD           JSR   LAB_1D10          ; search for variable
00CD32  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00CD35  1  D0 F4              BNE   LAB_1CFE          ; scan for "," and loop if not null
00CD37  1               
00CD37  1  60                 RTS
00CD38  1               
00CD38  1               ; perform << (left shift)
00CD38  1               
00CD38  1               LAB_LSHIFT
00CD38  1  20 6E CD           JSR   GetPair           ; get integer expression and byte (no sign check)
00CD3B  1  A5 AE              LDA   FAC1_2            ; get expression high byte
00CD3D  1  A6 78              LDX   TempB             ; get shift count
00CD3F  1  F0 22              BEQ   NoShift           ; branch if zero
00CD41  1               
00CD41  1  E0 10              CPX   #$10              ; compare bit count with 16d
00CD43  1  B0 23              BCS   TooBig            ; branch if >=
00CD45  1               
00CD45  1               Ls_loop
00CD45  1  06 AF              ASL   FAC1_3            ; shift low byte
00CD47  1  2A                 ROL                     ; shift high byte
00CD48  1  CA                 DEX                     ; decrement bit count
00CD49  1  D0 FA              BNE   Ls_loop           ; loop if shift not complete
00CD4B  1               
00CD4B  1  A4 AF              LDY   FAC1_3            ; get expression low byte
00CD4D  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00CD50  1               
00CD50  1               ; perform >> (right shift)
00CD50  1               
00CD50  1               LAB_RSHIFT
00CD50  1  20 6E CD           JSR   GetPair           ; get integer expression and byte (no sign check)
00CD53  1  A5 AE              LDA   FAC1_2            ; get expression high byte
00CD55  1  A6 78              LDX   TempB             ; get shift count
00CD57  1  F0 0A              BEQ   NoShift           ; branch if zero
00CD59  1               
00CD59  1  E0 10              CPX   #$10              ; compare bit count with 16d
00CD5B  1  B0 0B              BCS   TooBig            ; branch if >=
00CD5D  1               
00CD5D  1               Rs_loop
00CD5D  1  4A                 LSR                     ; shift high byte
00CD5E  1  66 AF              ROR   FAC1_3            ; shift low byte
00CD60  1  CA                 DEX                     ; decrement bit count
00CD61  1  D0 FA              BNE   Rs_loop           ; loop if shift not complete
00CD63  1               
00CD63  1               NoShift
00CD63  1  A4 AF              LDY   FAC1_3            ; get expression low byte
00CD65  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00CD68  1               
00CD68  1               TooBig
00CD68  1  A9 00              LDA   #$00              ; clear high byte
00CD6A  1  A8                 TAY                     ; copy to low byte
00CD6B  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00CD6E  1               
00CD6E  1               GetPair
00CD6E  1  20 60 D4           JSR   LAB_EVBY          ; evaluate byte expression, result in X
00CD71  1  86 78              STX   TempB             ; save it
00CD73  1  20 94 D5           JSR   LAB_279B          ; copy FAC2 to FAC1 (get 2nd value in expression)
00CD76  1  4C 75 CE           JMP   LAB_EVIR          ; evaluate integer expression (no sign check)
00CD79  1               
00CD79  1               ; search for variable
00CD79  1               
00CD79  1               ; return pointer to variable in Cvaral/Cvarah
00CD79  1               
00CD79  1               LAB_GVAR
00CD79  1  A2 00              LDX   #$00              ; set DIM flag = $00
00CD7B  1  20 C2 00           JSR   LAB_GBYT          ; scan memory (1st character)
00CD7E  1               LAB_1D10
00CD7E  1  86 5E              STX   Defdim            ; save DIM flag
00CD80  1               LAB_1D12
00CD80  1  85 93              STA   Varnm1            ; save 1st character
00CD82  1  29 7F              AND   #$7F              ; clear FN flag bit
00CD84  1  20 ED CD           JSR   LAB_CASC          ; check byte, return C=0 if<"A" or >"Z"
00CD87  1  B0 03              BCS   LAB_1D1F          ; branch if ok
00CD89  1               
00CD89  1  4C D1 CB           JMP   LAB_SNER          ; else syntax error then warm start
00CD8C  1               
00CD8C  1                                             ; was variable name so ..
00CD8C  1               LAB_1D1F
00CD8C  1  A2 00              LDX   #$00              ; clear 2nd character temp
00CD8E  1  86 5F              STX   Dtypef            ; clear data type flag, $FF=string, $00=numeric
00CD90  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory (2nd character)
00CD93  1  90 05              BCC   LAB_1D2D          ; branch if character = "0"-"9" (ok)
00CD95  1               
00CD95  1                                             ; 2nd character wasn't "0" to "9" so ..
00CD95  1  20 ED CD           JSR   LAB_CASC          ; check byte, return C=0 if<"A" or >"Z"
00CD98  1  90 0B              BCC   LAB_1D38          ; branch if <"A" or >"Z" (go check if string)
00CD9A  1               
00CD9A  1               LAB_1D2D
00CD9A  1  AA                 TAX                     ; copy 2nd character
00CD9B  1               
00CD9B  1                                             ; ignore further (valid) characters in the variable name
00CD9B  1               LAB_1D2E
00CD9B  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory (3rd character)
00CD9E  1  90 FB              BCC   LAB_1D2E          ; loop if character = "0"-"9" (ignore)
00CDA0  1               
00CDA0  1  20 ED CD           JSR   LAB_CASC          ; check byte, return C=0 if<"A" or >"Z"
00CDA3  1  B0 F6              BCS   LAB_1D2E          ; loop if character = "A"-"Z" (ignore)
00CDA5  1               
00CDA5  1                                             ; check if string variable
00CDA5  1               LAB_1D38
00CDA5  1  C9 24              CMP   #'$'              ; compare with "$"
00CDA7  1  D0 0B              BNE   LAB_1D47          ; branch if not string
00CDA9  1               
00CDA9  1               ; to introduce a new variable type (% suffix for integers say) then this branch
00CDA9  1               ; will need to go to that check and then that branch, if it fails, go to LAB_1D47
00CDA9  1               
00CDA9  1                                             ; type is string
00CDA9  1  A9 FF              LDA   #$FF              ; set data type = string
00CDAB  1  85 5F              STA   Dtypef            ; set data type flag, $FF=string, $00=numeric
00CDAD  1  8A                 TXA                     ; get 2nd character back
00CDAE  1  09 80              ORA   #$80              ; set top bit (indicate string var)
00CDB0  1  AA                 TAX                     ; copy back to 2nd character temp
00CDB1  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00CDB4  1               
00CDB4  1               ; after we have determined the variable type we need to come back here to determine
00CDB4  1               ; if it's an array of type. this would plug in a%(b[,c[,d]])) integer arrays nicely
00CDB4  1               
00CDB4  1               
00CDB4  1               LAB_1D47                      ; gets here with character after var name in A
00CDB4  1  86 94              STX   Varnm2            ; save 2nd character
00CDB6  1  05 61              ORA   Sufnxf            ; or with subscript/FNX flag (or FN name)
00CDB8  1  C9 28              CMP   #'('              ; compare with "("
00CDBA  1  D0 03              BNE   LAB_1D53          ; branch if not "("
00CDBC  1               
00CDBC  1  4C 87 CE           JMP   LAB_1E17          ; go find, or make, array
00CDBF  1               
00CDBF  1               ; either find or create var
00CDBF  1               ; var name (1st two characters only!) is in Varnm1,Varnm2
00CDBF  1               
00CDBF  1                                             ; variable name wasn't var(... so look for plain var
00CDBF  1               LAB_1D53
00CDBF  1  A9 00              LDA   #$00              ; clear A
00CDC1  1  85 61              STA   Sufnxf            ; clear subscript/FNX flag
00CDC3  1  A5 7B              LDA   Svarl             ; get start of vars low byte
00CDC5  1  A6 7C              LDX   Svarh             ; get start of vars high byte
00CDC7  1  A0 00              LDY   #$00              ; clear index
00CDC9  1               LAB_1D5D
00CDC9  1  86 AB              STX   Vrschh            ; save search address high byte
00CDCB  1               LAB_1D5F
00CDCB  1  85 AA              STA   Vrschl            ; save search address low byte
00CDCD  1  E4 7E              CPX   Sarryh            ; compare high address with var space end
00CDCF  1  D0 04              BNE   LAB_1D69          ; skip next compare if <>
00CDD1  1               
00CDD1  1                                             ; high addresses were = so compare low addresses
00CDD1  1  C5 7D              CMP   Sarryl            ; compare low address with var space end
00CDD3  1  F0 2C              BEQ   LAB_1D8B          ; if not found go make new var
00CDD5  1               
00CDD5  1               LAB_1D69
00CDD5  1  A5 93              LDA   Varnm1            ; get 1st character of var to find
00CDD7  1  D1 AA              CMP   (Vrschl),Y        ; compare with variable name 1st character
00CDD9  1  D0 08              BNE   LAB_1D77          ; branch if no match
00CDDB  1               
00CDDB  1                                             ; 1st characters match so compare 2nd characters
00CDDB  1  A5 94              LDA   Varnm2            ; get 2nd character of var to find
00CDDD  1  C8                 INY                     ; index to point to variable name 2nd character
00CDDE  1  D1 AA              CMP   (Vrschl),Y        ; compare with variable name 2nd character
00CDE0  1  F0 69              BEQ   LAB_1DD7          ; branch if match (found var)
00CDE2  1               
00CDE2  1  88                 DEY                     ; else decrement index (now = $00)
00CDE3  1               LAB_1D77
00CDE3  1  18                 CLC                     ; clear carry for add
00CDE4  1  A5 AA              LDA   Vrschl            ; get search address low byte
00CDE6  1  69 06              ADC   #$06              ; +6 (offset to next var name)
00CDE8  1  90 E1              BCC   LAB_1D5F          ; loop if no overflow to high byte
00CDEA  1               
00CDEA  1  E8                 INX                     ; else increment high byte
00CDEB  1  D0 DC              BNE   LAB_1D5D          ; loop always (RAM doesn't extend to $FFFF !)
00CDED  1               
00CDED  1               ; check byte, return C=0 if<"A" or >"Z" or "a" to "z"
00CDED  1               
00CDED  1               LAB_CASC
00CDED  1  C9 61              CMP   #'a'              ; compare with "a"
00CDEF  1  B0 0A              BCS   LAB_1D83          ; go check <"z"+1
00CDF1  1               
00CDF1  1               ; check byte, return C=0 if<"A" or >"Z"
00CDF1  1               
00CDF1  1               LAB_1D82
00CDF1  1  C9 41              CMP   #'A'              ; compare with "A"
00CDF3  1  90 05              BCC   LAB_1D8A          ; exit if less
00CDF5  1               
00CDF5  1                                             ; carry is set
00CDF5  1  E9 5B              SBC   #$5B              ; subtract "Z"+1
00CDF7  1  38                 SEC                     ; set carry
00CDF8  1  E9 A5              SBC   #$A5              ; subtract $A5 (restore byte)
00CDFA  1                                             ; carry clear if byte>$5A
00CDFA  1               LAB_1D8A
00CDFA  1  60                 RTS
00CDFB  1               
00CDFB  1               LAB_1D83
00CDFB  1  E9 7B              SBC   #$7B              ; subtract "z"+1
00CDFD  1  38                 SEC                     ; set carry
00CDFE  1  E9 85              SBC   #$85              ; subtract $85 (restore byte)
00CE00  1                                             ; carry clear if byte>$7A
00CE00  1  60                 RTS
00CE01  1               
00CE01  1                                             ; reached end of variable mem without match
00CE01  1                                             ; .. so create new variable
00CE01  1               LAB_1D8B
00CE01  1  68                 PLA                     ; pop return address low byte
00CE02  1  48                 PHA                     ; push return address low byte
00CE03  1               LAB_1C18p2  = LAB_1C18+2
00CE03  1  C9 0C              CMP   #<LAB_1C18p2      ; compare with expected calling routine return low byte
00CE05  1  D0 05              BNE   LAB_1D98          ; if not get (var) go create new var
00CE07  1               
00CE07  1               ; This will only drop through if the call was from LAB_1C18 and is only called
00CE07  1               ; from there if it is searching for a variable from the RHS of a LET a=b statement
00CE07  1               ; it prevents the creation of variables not assigned a value.
00CE07  1               
00CE07  1               ; value returned by this is either numeric zero (exponent byte is $00) or null string
00CE07  1               ; (descriptor length byte is $00). in fact a pointer to any $00 byte would have done.
00CE07  1               
00CE07  1               ; doing this saves 6 bytes of variable memory and 168 machine cycles of time
00CE07  1               
00CE07  1               ; this is where you would put the undefined variable error call e.g.
00CE07  1               
00CE07  1               ;                             ; variable doesn't exist so flag error
00CE07  1               ;     LDX   #$24              ; error code $24 ("undefined variable" error)
00CE07  1               ;     JMP   LAB_XERR          ; do error #X then warm start
00CE07  1               
00CE07  1               ; the above code has been tested and works a treat! (it replaces the three code lines
00CE07  1               ; below)
00CE07  1               
00CE07  1                                             ; else return dummy null value
00CE07  1  A9 CA              LDA   #<LAB_1D96        ; low byte point to $00,$00
00CE09  1                                             ; (uses part of misc constants table)
00CE09  1  A0 E1              LDY   #>LAB_1D96        ; high byte point to $00,$00
00CE0B  1  60                 RTS
00CE0C  1               
00CE0C  1                                             ; create new numeric variable
00CE0C  1               LAB_1D98
00CE0C  1  A5 7D              LDA   Sarryl            ; get var mem end low byte
00CE0E  1  A4 7E              LDY   Sarryh            ; get var mem end high byte
00CE10  1  85 AA              STA   Ostrtl            ; save old block start low byte
00CE12  1  84 AB              STY   Ostrth            ; save old block start high byte
00CE14  1  A5 7F              LDA   Earryl            ; get array mem end low byte
00CE16  1  A4 80              LDY   Earryh            ; get array mem end high byte
00CE18  1  85 A6              STA   Obendl            ; save old block end low byte
00CE1A  1  84 A7              STY   Obendh            ; save old block end high byte
00CE1C  1  18                 CLC                     ; clear carry for add
00CE1D  1  69 06              ADC   #$06              ; +6 (space for one var)
00CE1F  1  90 01              BCC   LAB_1DAE          ; branch if no overflow to high byte
00CE21  1               
00CE21  1  C8                 INY                     ; else increment high byte
00CE22  1               LAB_1DAE
00CE22  1  85 A4              STA   Nbendl            ; set new block end low byte
00CE24  1  84 A5              STY   Nbendh            ; set new block end high byte
00CE26  1  20 87 C0           JSR   LAB_11CF          ; open up space in memory
00CE29  1  A5 A4              LDA   Nbendl            ; get new start low byte
00CE2B  1  A4 A5              LDY   Nbendh            ; get new start high byte (-$100)
00CE2D  1  C8                 INY                     ; correct high byte
00CE2E  1  85 7D              STA   Sarryl            ; save new var mem end low byte
00CE30  1  84 7E              STY   Sarryh            ; save new var mem end high byte
00CE32  1  A0 00              LDY   #$00              ; clear index
00CE34  1  A5 93              LDA   Varnm1            ; get var name 1st character
00CE36  1  91 AA              STA   (Vrschl),Y        ; save var name 1st character
00CE38  1  C8                 INY                     ; increment index
00CE39  1  A5 94              LDA   Varnm2            ; get var name 2nd character
00CE3B  1  91 AA              STA   (Vrschl),Y        ; save var name 2nd character
00CE3D  1  A9 00              LDA   #$00              ; clear A
00CE3F  1  C8                 INY                     ; increment index
00CE40  1  91 AA              STA   (Vrschl),Y        ; initialise var byte
00CE42  1  C8                 INY                     ; increment index
00CE43  1  91 AA              STA   (Vrschl),Y        ; initialise var byte
00CE45  1  C8                 INY                     ; increment index
00CE46  1  91 AA              STA   (Vrschl),Y        ; initialise var byte
00CE48  1  C8                 INY                     ; increment index
00CE49  1  91 AA              STA   (Vrschl),Y        ; initialise var byte
00CE4B  1               
00CE4B  1                                             ; found a match for var ((Vrschl) = ptr)
00CE4B  1               LAB_1DD7
00CE4B  1  A5 AA              LDA   Vrschl            ; get var address low byte
00CE4D  1  18                 CLC                     ; clear carry for add
00CE4E  1  69 02              ADC   #$02              ; +2 (offset past var name bytes)
00CE50  1  A4 AB              LDY   Vrschh            ; get var address high byte
00CE52  1  90 01              BCC   LAB_1DE1          ; branch if no overflow from add
00CE54  1               
00CE54  1  C8                 INY                     ; else increment high byte
00CE55  1               LAB_1DE1
00CE55  1  85 95              STA   Cvaral            ; save current var address low byte
00CE57  1  84 96              STY   Cvarah            ; save current var address high byte
00CE59  1  60                 RTS
00CE5A  1               
00CE5A  1               ; set-up array pointer (Adatal/h) to first element in array
00CE5A  1               ; set Adatal,Adatah to Astrtl,Astrth+2*Dimcnt+#$05
00CE5A  1               
00CE5A  1               LAB_1DE6
00CE5A  1  A5 5D              LDA   Dimcnt            ; get # of dimensions (1, 2 or 3)
00CE5C  1  0A                 ASL                     ; *2 (also clears the carry !)
00CE5D  1  69 05              ADC   #$05              ; +5 (result is 7, 9 or 11 here)
00CE5F  1  65 AA              ADC   Astrtl            ; add array start pointer low byte
00CE61  1  A4 AB              LDY   Astrth            ; get array pointer high byte
00CE63  1  90 01              BCC   LAB_1DF2          ; branch if no overflow
00CE65  1               
00CE65  1  C8                 INY                     ; else increment high byte
00CE66  1               LAB_1DF2
00CE66  1  85 A4              STA   Adatal            ; save array data pointer low byte
00CE68  1  84 A5              STY   Adatah            ; save array data pointer high byte
00CE6A  1  60                 RTS
00CE6B  1               
00CE6B  1               ; evaluate integer expression
00CE6B  1               
00CE6B  1               LAB_EVIN
00CE6B  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00CE6E  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00CE71  1                                             ; else do type mismatch
00CE71  1               
00CE71  1               ; evaluate integer expression (no check)
00CE71  1               
00CE71  1               LAB_EVPI
00CE71  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00CE73  1  30 0D              BMI   LAB_1E12          ; do function call error if -ve
00CE75  1               
00CE75  1               ; evaluate integer expression (no sign check)
00CE75  1               
00CE75  1               LAB_EVIR
00CE75  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00CE77  1  C9 90              CMP   #$90              ; compare with exponent = 2^16 (n>2^15)
00CE79  1  90 09              BCC   LAB_1E14          ; branch if n<2^16 (is ok)
00CE7B  1               
00CE7B  1  A9 D1              LDA   #<LAB_1DF7        ; set pointer low byte to -32768
00CE7D  1  A0 E1              LDY   #>LAB_1DF7        ; set pointer high byte to -32768
00CE7F  1  20 E8 D8           JSR   LAB_27F8          ; compare FAC1 with (AY)
00CE82  1               LAB_1E12
00CE82  1  D0 74              BNE   LAB_FCER          ; if <> do function call error then warm start
00CE84  1               
00CE84  1               LAB_1E14
00CE84  1  4C 21 D9           JMP   LAB_2831          ; convert FAC1 floating-to-fixed and return
00CE87  1               
00CE87  1               ; find or make array
00CE87  1               
00CE87  1               LAB_1E17
00CE87  1  A5 5E              LDA   Defdim            ; get DIM flag
00CE89  1  48                 PHA                     ; push it
00CE8A  1  A5 5F              LDA   Dtypef            ; get data type flag, $FF=string, $00=numeric
00CE8C  1  48                 PHA                     ; push it
00CE8D  1  A0 00              LDY   #$00              ; clear dimensions count
00CE8F  1               
00CE8F  1               ; now get the array dimension(s) and stack it (them) before the data type and DIM flag
00CE8F  1               
00CE8F  1               LAB_1E1F
00CE8F  1  98                 TYA                     ; copy dimensions count
00CE90  1  48                 PHA                     ; save it
00CE91  1  A5 94              LDA   Varnm2            ; get array name 2nd byte
00CE93  1  48                 PHA                     ; save it
00CE94  1  A5 93              LDA   Varnm1            ; get array name 1st byte
00CE96  1  48                 PHA                     ; save it
00CE97  1  20 6B CE           JSR   LAB_EVIN          ; evaluate integer expression
00CE9A  1  68                 PLA                     ; pull array name 1st byte
00CE9B  1  85 93              STA   Varnm1            ; restore array name 1st byte
00CE9D  1  68                 PLA                     ; pull array name 2nd byte
00CE9E  1  85 94              STA   Varnm2            ; restore array name 2nd byte
00CEA0  1  68                 PLA                     ; pull dimensions count
00CEA1  1  A8                 TAY                     ; restore it
00CEA2  1  BA                 TSX                     ; copy stack pointer
00CEA3  1  BD 02 01           LDA   LAB_STAK+2,X      ; get DIM flag
00CEA6  1  48                 PHA                     ; push it
00CEA7  1  BD 01 01           LDA   LAB_STAK+1,X      ; get data type flag
00CEAA  1  48                 PHA                     ; push it
00CEAB  1  A5 AE              LDA   FAC1_2            ; get this dimension size high byte
00CEAD  1  9D 02 01           STA   LAB_STAK+2,X      ; stack before flag bytes
00CEB0  1  A5 AF              LDA   FAC1_3            ; get this dimension size low byte
00CEB2  1  9D 01 01           STA   LAB_STAK+1,X      ; stack before flag bytes
00CEB5  1  C8                 INY                     ; increment dimensions count
00CEB6  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00CEB9  1  C9 2C              CMP   #','              ; compare with ","
00CEBB  1  F0 D2              BEQ   LAB_1E1F          ; if found go do next dimension
00CEBD  1               
00CEBD  1  84 5D              STY   Dimcnt            ; store dimensions count
00CEBF  1  20 BE CB           JSR   LAB_1BFB          ; scan for ")" , else do syntax error then warm start
00CEC2  1  68                 PLA                     ; pull data type flag
00CEC3  1  85 5F              STA   Dtypef            ; restore data type flag, $FF=string, $00=numeric
00CEC5  1  68                 PLA                     ; pull DIM flag
00CEC6  1  85 5E              STA   Defdim            ; restore DIM flag
00CEC8  1  A6 7D              LDX   Sarryl            ; get array mem start low byte
00CECA  1  A5 7E              LDA   Sarryh            ; get array mem start high byte
00CECC  1               
00CECC  1               ; now check to see if we are at the end of array memory (we would be if there were
00CECC  1               ; no arrays).
00CECC  1               
00CECC  1               LAB_1E5C
00CECC  1  86 AA              STX   Astrtl            ; save as array start pointer low byte
00CECE  1  85 AB              STA   Astrth            ; save as array start pointer high byte
00CED0  1  C5 80              CMP   Earryh            ; compare with array mem end high byte
00CED2  1  D0 04              BNE   LAB_1E68          ; branch if not reached array mem end
00CED4  1               
00CED4  1  E4 7F              CPX   Earryl            ; else compare with array mem end low byte
00CED6  1  F0 39              BEQ   LAB_1EA1          ; go build array if not found
00CED8  1               
00CED8  1                                             ; search for array
00CED8  1               LAB_1E68
00CED8  1  A0 00              LDY   #$00              ; clear index
00CEDA  1  B1 AA              LDA   (Astrtl),Y        ; get array name first byte
00CEDC  1  C8                 INY                     ; increment index to second name byte
00CEDD  1  C5 93              CMP   Varnm1            ; compare with this array name first byte
00CEDF  1  D0 06              BNE   LAB_1E77          ; branch if no match
00CEE1  1               
00CEE1  1  A5 94              LDA   Varnm2            ; else get this array name second byte
00CEE3  1  D1 AA              CMP   (Astrtl),Y        ; compare with array name second byte
00CEE5  1  F0 16              BEQ   LAB_1E8D          ; array found so branch
00CEE7  1               
00CEE7  1                                             ; no match
00CEE7  1               LAB_1E77
00CEE7  1  C8                 INY                     ; increment index
00CEE8  1  B1 AA              LDA   (Astrtl),Y        ; get array size low byte
00CEEA  1  18                 CLC                     ; clear carry for add
00CEEB  1  65 AA              ADC   Astrtl            ; add array start pointer low byte
00CEED  1  AA                 TAX                     ; copy low byte to X
00CEEE  1  C8                 INY                     ; increment index
00CEEF  1  B1 AA              LDA   (Astrtl),Y        ; get array size high byte
00CEF1  1  65 AB              ADC   Astrth            ; add array mem pointer high byte
00CEF3  1  90 D7              BCC   LAB_1E5C          ; if no overflow go check next array
00CEF5  1               
00CEF5  1               ; do array bounds error
00CEF5  1               
00CEF5  1               LAB_1E85
00CEF5  1  A2 10              LDX   #$10              ; error code $10 ("Array bounds" error)
00CEF7  1  2C                 .byte $2C               ; makes next bit BIT LAB_08A2
00CEF8  1               
00CEF8  1               ; do function call error
00CEF8  1               
00CEF8  1               LAB_FCER
00CEF8  1  A2 08              LDX   #$08              ; error code $08 ("Function call" error)
00CEFA  1               LAB_1E8A
00CEFA  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00CEFD  1               
00CEFD  1                                             ; found array, are we trying to dimension it?
00CEFD  1               LAB_1E8D
00CEFD  1  A2 12              LDX   #$12              ; set error $12 ("Double dimension" error)
00CEFF  1  A5 5E              LDA   Defdim            ; get DIM flag
00CF01  1  D0 F7              BNE   LAB_1E8A          ; if we are trying to dimension it do error #X, then warm
00CF03  1                                             ; start
00CF03  1               
00CF03  1               ; found the array and we're not dimensioning it so we must find an element in it
00CF03  1               
00CF03  1  20 5A CE           JSR   LAB_1DE6          ; set-up array pointer (Adatal/h) to first element in array
00CF06  1                                             ; (Astrtl,Astrth points to start of array)
00CF06  1  A5 5D              LDA   Dimcnt            ; get dimensions count
00CF08  1  A0 04              LDY   #$04              ; set index to array's # of dimensions
00CF0A  1  D1 AA              CMP   (Astrtl),Y        ; compare with no of dimensions
00CF0C  1  D0 E7              BNE   LAB_1E85          ; if wrong do array bounds error, could do "Wrong
00CF0E  1                                             ; dimensions" error here .. if we want a different
00CF0E  1                                             ; error message
00CF0E  1               
00CF0E  1  4C 94 CF           JMP   LAB_1F28          ; found array so go get element
00CF11  1                                             ; (could jump to LAB_1F28 as all LAB_1F24 does is take
00CF11  1                                             ; Dimcnt and save it at (Astrtl),Y which is already the
00CF11  1                                             ; same or we would have taken the BNE)
00CF11  1               
00CF11  1                                             ; array not found, so build it
00CF11  1               LAB_1EA1
00CF11  1  20 5A CE           JSR   LAB_1DE6          ; set-up array pointer (Adatal/h) to first element in array
00CF14  1                                             ; (Astrtl,Astrth points to start of array)
00CF14  1  20 D1 C0           JSR   LAB_121F          ; check available memory, "Out of memory" error if no room
00CF17  1                                             ; addr to check is in AY (low/high)
00CF17  1  A0 00              LDY   #$00              ; clear Y (don't need to clear A)
00CF19  1  84 BB              STY   Aspth             ; clear array data size high byte
00CF1B  1  A5 93              LDA   Varnm1            ; get variable name 1st byte
00CF1D  1  91 AA              STA   (Astrtl),Y        ; save array name 1st byte
00CF1F  1  C8                 INY                     ; increment index
00CF20  1  A5 94              LDA   Varnm2            ; get variable name 2nd byte
00CF22  1  91 AA              STA   (Astrtl),Y        ; save array name 2nd byte
00CF24  1  A5 5D              LDA   Dimcnt            ; get dimensions count
00CF26  1  A0 04              LDY   #$04              ; index to dimension count
00CF28  1  84 BA              STY   Asptl             ; set array data size low byte (four bytes per element)
00CF2A  1  91 AA              STA   (Astrtl),Y        ; set array's dimensions count
00CF2C  1               
00CF2C  1                                             ; now calculate the size of the data space for the array
00CF2C  1  18                 CLC                     ; clear carry for add (clear on subsequent loops)
00CF2D  1               LAB_1EC0
00CF2D  1  A2 0B              LDX   #$0B              ; set default dimension value low byte
00CF2F  1  A9 00              LDA   #$00              ; set default dimension value high byte
00CF31  1  24 5E              BIT   Defdim            ; test default DIM flag
00CF33  1  50 07              BVC   LAB_1ED0          ; branch if b6 of Defdim is clear
00CF35  1               
00CF35  1  68                 PLA                     ; else pull dimension value low byte
00CF36  1  69 01              ADC   #$01              ; +1 (allow for zeroeth element)
00CF38  1  AA                 TAX                     ; copy low byte to X
00CF39  1  68                 PLA                     ; pull dimension value high byte
00CF3A  1  69 00              ADC   #$00              ; add carry from low byte
00CF3C  1               
00CF3C  1               LAB_1ED0
00CF3C  1  C8                 INY                     ; index to dimension value high byte
00CF3D  1  91 AA              STA   (Astrtl),Y        ; save dimension value high byte
00CF3F  1  C8                 INY                     ; index to dimension value high byte
00CF40  1  8A                 TXA                     ; get dimension value low byte
00CF41  1  91 AA              STA   (Astrtl),Y        ; save dimension value low byte
00CF43  1  20 E3 CF           JSR   LAB_1F7C          ; does XY = (Astrtl),Y * (Asptl)
00CF46  1  86 BA              STX   Asptl             ; save array data size low byte
00CF48  1  85 BB              STA   Aspth             ; save array data size high byte
00CF4A  1  A4 71              LDY   ut1_pl            ; restore index (saved by subroutine)
00CF4C  1  C6 5D              DEC   Dimcnt            ; decrement dimensions count
00CF4E  1  D0 DD              BNE   LAB_1EC0          ; loop while not = 0
00CF50  1               
00CF50  1  65 A5              ADC   Adatah            ; add size high byte to first element high byte
00CF52  1                                             ; (carry is always clear here)
00CF52  1  B0 5D              BCS   LAB_1F45          ; if overflow go do "Out of memory" error
00CF54  1               
00CF54  1  85 A5              STA   Adatah            ; save end of array high byte
00CF56  1  A8                 TAY                     ; copy end high byte to Y
00CF57  1  8A                 TXA                     ; get array size low byte
00CF58  1  65 A4              ADC   Adatal            ; add array start low byte
00CF5A  1  90 03              BCC   LAB_1EF3          ; branch if no carry
00CF5C  1               
00CF5C  1  C8                 INY                     ; else increment end of array high byte
00CF5D  1  F0 52              BEQ   LAB_1F45          ; if overflow go do "Out of memory" error
00CF5F  1               
00CF5F  1                                             ; set-up mostly complete, now zero the array
00CF5F  1               LAB_1EF3
00CF5F  1  20 D1 C0           JSR   LAB_121F          ; check available memory, "Out of memory" error if no room
00CF62  1                                             ; addr to check is in AY (low/high)
00CF62  1  85 7F              STA   Earryl            ; save array mem end low byte
00CF64  1  84 80              STY   Earryh            ; save array mem end high byte
00CF66  1  A9 00              LDA   #$00              ; clear byte for array clear
00CF68  1  E6 BB              INC   Aspth             ; increment array size high byte (now block count)
00CF6A  1  A4 BA              LDY   Asptl             ; get array size low byte (now index to block)
00CF6C  1  F0 05              BEQ   LAB_1F07          ; branch if low byte = $00
00CF6E  1               
00CF6E  1               LAB_1F02
00CF6E  1  88                 DEY                     ; decrement index (do 0 to n-1)
00CF6F  1  91 A4              STA   (Adatal),Y        ; zero byte
00CF71  1  D0 FB              BNE   LAB_1F02          ; loop until this block done
00CF73  1               
00CF73  1               LAB_1F07
00CF73  1  C6 A5              DEC   Adatah            ; decrement array pointer high byte
00CF75  1  C6 BB              DEC   Aspth             ; decrement block count high byte
00CF77  1  D0 F5              BNE   LAB_1F02          ; loop until all blocks done
00CF79  1               
00CF79  1  E6 A5              INC   Adatah            ; correct for last loop
00CF7B  1  38                 SEC                     ; set carry for subtract
00CF7C  1  A0 02              LDY   #$02              ; index to array size low byte
00CF7E  1  A5 7F              LDA   Earryl            ; get array mem end low byte
00CF80  1  E5 AA              SBC   Astrtl            ; subtract array start low byte
00CF82  1  91 AA              STA   (Astrtl),Y        ; save array size low byte
00CF84  1  C8                 INY                     ; index to array size high byte
00CF85  1  A5 80              LDA   Earryh            ; get array mem end high byte
00CF87  1  E5 AB              SBC   Astrth            ; subtract array start high byte
00CF89  1  91 AA              STA   (Astrtl),Y        ; save array size high byte
00CF8B  1  A5 5E              LDA   Defdim            ; get default DIM flag
00CF8D  1  D0 53              BNE   LAB_1F7B          ; exit (RET) if this was a DIM command
00CF8F  1               
00CF8F  1                                             ; else, find element
00CF8F  1  C8                 INY                     ; index to # of dimensions
00CF90  1               
00CF90  1               LAB_1F24
00CF90  1  B1 AA              LDA   (Astrtl),Y        ; get array's dimension count
00CF92  1  85 5D              STA   Dimcnt            ; save it
00CF94  1               
00CF94  1               ; we have found, or built, the array. now we need to find the element
00CF94  1               
00CF94  1               LAB_1F28
00CF94  1  A9 00              LDA   #$00              ; clear byte
00CF96  1  85 BA              STA   Asptl             ; clear array data pointer low byte
00CF98  1               LAB_1F2C
00CF98  1  85 BB              STA   Aspth             ; save array data pointer high byte
00CF9A  1  C8                 INY                     ; increment index (point to array bound high byte)
00CF9B  1  68                 PLA                     ; pull array index low byte
00CF9C  1  AA                 TAX                     ; copy to X
00CF9D  1  85 AE              STA   FAC1_2            ; save index low byte to FAC1 mantissa2
00CF9F  1  68                 PLA                     ; pull array index high byte
00CFA0  1  85 AF              STA   FAC1_3            ; save index high byte to FAC1 mantissa3
00CFA2  1  D1 AA              CMP   (Astrtl),Y        ; compare with array bound high byte
00CFA4  1  90 0E              BCC   LAB_1F48          ; branch if within bounds
00CFA6  1               
00CFA6  1  D0 06              BNE   LAB_1F42          ; if outside bounds do array bounds error
00CFA8  1               
00CFA8  1                                             ; else high byte was = so test low bytes
00CFA8  1  C8                 INY                     ; index to array bound low byte
00CFA9  1  8A                 TXA                     ; get array index low byte
00CFAA  1  D1 AA              CMP   (Astrtl),Y        ; compare with array bound low byte
00CFAC  1  90 07              BCC   LAB_1F49          ; branch if within bounds
00CFAE  1               
00CFAE  1               LAB_1F42
00CFAE  1  4C F5 CE           JMP   LAB_1E85          ; else do array bounds error
00CFB1  1               
00CFB1  1               LAB_1F45
00CFB1  1  4C 00 C1           JMP   LAB_OMER          ; do "Out of memory" error then warm start
00CFB4  1               
00CFB4  1               LAB_1F48
00CFB4  1  C8                 INY                     ; index to array bound low byte
00CFB5  1               LAB_1F49
00CFB5  1  A5 BB              LDA   Aspth             ; get array data pointer high byte
00CFB7  1  05 BA              ORA   Asptl             ; OR with array data pointer low byte
00CFB9  1  F0 0A              BEQ   LAB_1F5A          ; branch if array data pointer = null (skip multiply)
00CFBB  1               
00CFBB  1  20 E3 CF           JSR   LAB_1F7C          ; does XY = (Astrtl),Y * (Asptl)
00CFBE  1  8A                 TXA                     ; get result low byte
00CFBF  1  65 AE              ADC   FAC1_2            ; add index low byte from FAC1 mantissa2
00CFC1  1  AA                 TAX                     ; save result low byte
00CFC2  1  98                 TYA                     ; get result high byte
00CFC3  1  A4 71              LDY   ut1_pl            ; restore index
00CFC5  1               LAB_1F5A
00CFC5  1  65 AF              ADC   FAC1_3            ; add index high byte from FAC1 mantissa3
00CFC7  1  86 BA              STX   Asptl             ; save array data pointer low byte
00CFC9  1  C6 5D              DEC   Dimcnt            ; decrement dimensions count
00CFCB  1  D0 CB              BNE   LAB_1F2C          ; loop if dimensions still to do
00CFCD  1               
00CFCD  1  06 BA              ASL   Asptl             ; array data pointer low byte * 2
00CFCF  1  2A                 ROL                     ; array data pointer high byte * 2
00CFD0  1  06 BA              ASL   Asptl             ; array data pointer low byte * 4
00CFD2  1  2A                 ROL                     ; array data pointer high byte * 4
00CFD3  1  A8                 TAY                     ; copy high byte
00CFD4  1  A5 BA              LDA   Asptl             ; get low byte
00CFD6  1  65 A4              ADC   Adatal            ; add array data start pointer low byte
00CFD8  1  85 95              STA   Cvaral            ; save as current var address low byte
00CFDA  1  98                 TYA                     ; get high byte back
00CFDB  1  65 A5              ADC   Adatah            ; add array data start pointer high byte
00CFDD  1  85 96              STA   Cvarah            ; save as current var address high byte
00CFDF  1  A8                 TAY                     ; copy high byte to Y
00CFE0  1  A5 95              LDA   Cvaral            ; get current var address low byte
00CFE2  1               LAB_1F7B
00CFE2  1  60                 RTS
00CFE3  1               
00CFE3  1               ; does XY = (Astrtl),Y * (Asptl)
00CFE3  1               
00CFE3  1               LAB_1F7C
00CFE3  1  84 71              STY   ut1_pl            ; save index
00CFE5  1  B1 AA              LDA   (Astrtl),Y        ; get dimension size low byte
00CFE7  1  85 76              STA   dims_l            ; save dimension size low byte
00CFE9  1  88                 DEY                     ; decrement index
00CFEA  1  B1 AA              LDA   (Astrtl),Y        ; get dimension size high byte
00CFEC  1  85 77              STA   dims_h            ; save dimension size high byte
00CFEE  1               
00CFEE  1  A9 10              LDA   #$10              ; count = $10 (16 bit multiply)
00CFF0  1  85 A8              STA   numbit            ; save bit count
00CFF2  1  A2 00              LDX   #$00              ; clear result low byte
00CFF4  1  A0 00              LDY   #$00              ; clear result high byte
00CFF6  1               LAB_1F8F
00CFF6  1  8A                 TXA                     ; get result low byte
00CFF7  1  0A                 ASL                     ; *2
00CFF8  1  AA                 TAX                     ; save result low byte
00CFF9  1  98                 TYA                     ; get result high byte
00CFFA  1  2A                 ROL                     ; *2
00CFFB  1  A8                 TAY                     ; save result high byte
00CFFC  1  B0 B3              BCS   LAB_1F45          ; if overflow go do "Out of memory" error
00CFFE  1               
00CFFE  1  06 BA              ASL   Asptl             ; shift multiplier low byte
00D000  1  26 BB              ROL   Aspth             ; shift multiplier high byte
00D002  1  90 0B              BCC   LAB_1FA8          ; skip add if no carry
00D004  1               
00D004  1  18                 CLC                     ; else clear carry for add
00D005  1  8A                 TXA                     ; get result low byte
00D006  1  65 76              ADC   dims_l            ; add dimension size low byte
00D008  1  AA                 TAX                     ; save result low byte
00D009  1  98                 TYA                     ; get result high byte
00D00A  1  65 77              ADC   dims_h            ; add dimension size high byte
00D00C  1  A8                 TAY                     ; save result high byte
00D00D  1  B0 A2              BCS   LAB_1F45          ; if overflow go do "Out of memory" error
00D00F  1               
00D00F  1               LAB_1FA8
00D00F  1  C6 A8              DEC   numbit            ; decrement bit count
00D011  1  D0 E3              BNE   LAB_1F8F          ; loop until all done
00D013  1               
00D013  1  60                 RTS
00D014  1               
00D014  1               ; perform FRE()
00D014  1               
00D014  1               LAB_FRE
00D014  1  A5 5F              LDA   Dtypef            ; get data type flag, $FF=string, $00=numeric
00D016  1  10 03              BPL   LAB_1FB4          ; branch if numeric
00D018  1               
00D018  1  20 0F D3           JSR   LAB_22B6          ; pop string off descriptor stack, or from top of string
00D01B  1                                             ; space returns with A = length, X=$71=pointer low byte,
00D01B  1                                             ; Y=$72=pointer high byte
00D01B  1               
00D01B  1                                             ; FRE(n) was numeric so do this
00D01B  1               LAB_1FB4
00D01B  1  20 B0 D1           JSR   LAB_GARB          ; go do garbage collection
00D01E  1  38                 SEC                     ; set carry for subtract
00D01F  1  A5 81              LDA   Sstorl            ; get bottom of string space low byte
00D021  1  E5 7F              SBC   Earryl            ; subtract array mem end low byte
00D023  1  A8                 TAY                     ; copy result to Y
00D024  1  A5 82              LDA   Sstorh            ; get bottom of string space high byte
00D026  1  E5 80              SBC   Earryh            ; subtract array mem end high byte
00D028  1               
00D028  1               ; save and convert integer AY to FAC1
00D028  1               
00D028  1               LAB_AYFC
00D028  1  46 5F              LSR   Dtypef            ; clear data type flag, $FF=string, $00=numeric
00D02A  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00D02C  1  84 AE              STY   FAC1_2            ; save FAC1 mantissa2
00D02E  1  A2 90              LDX   #$90              ; set exponent=2^16 (integer)
00D030  1  4C D3 D8           JMP   LAB_27E3          ; set exp=X, clear FAC1_3, normalise and return
00D033  1               
00D033  1               ; perform POS()
00D033  1               
00D033  1               LAB_POS
00D033  1  A4 0E              LDY   TPos              ; get terminal position
00D035  1               
00D035  1               ; convert Y to byte in FAC1
00D035  1               
00D035  1               LAB_1FD0
00D035  1  A9 00              LDA   #$00              ; clear high byte
00D037  1  F0 EF              BEQ   LAB_AYFC          ; always save and convert integer AY to FAC1 and return
00D039  1               
00D039  1               ; check not Direct (used by DEF and INPUT)
00D039  1               
00D039  1               LAB_CKRN
00D039  1  A6 88              LDX   Clineh            ; get current line high byte
00D03B  1  E8                 INX                     ; increment it
00D03C  1  D0 A4              BNE   LAB_1F7B          ; return if can continue not direct mode
00D03E  1               
00D03E  1                                             ; else do illegal direct error
00D03E  1               LAB_1FD9
00D03E  1  A2 16              LDX   #$16              ; error code $16 ("Illegal direct" error)
00D040  1               LAB_1FDB
00D040  1  4C 02 C1           JMP   LAB_XERR          ; go do error #X, then warm start
00D043  1               
00D043  1               ; perform DEF
00D043  1               
00D043  1               LAB_DEF
00D043  1  20 74 D0           JSR   LAB_200B          ; check FNx syntax
00D046  1  85 9C              STA   func_l            ; save function pointer low byte
00D048  1  84 9D              STY   func_h            ; save function pointer high byte
00D04A  1  20 39 D0           JSR   LAB_CKRN          ; check not Direct (back here if ok)
00D04D  1  20 C9 CB           JSR   LAB_1BFE          ; scan for "(" , else do syntax error then warm start
00D050  1  A9 80              LDA   #$80              ; set flag for FNx
00D052  1  85 61              STA   Sufnxf            ; save subscript/FNx flag
00D054  1  20 79 CD           JSR   LAB_GVAR          ; get (var) address
00D057  1  20 9F CA           JSR   LAB_CTNM          ; check if source is numeric, else do type mismatch
00D05A  1  20 BE CB           JSR   LAB_1BFB          ; scan for ")" , else do syntax error then warm start
00D05D  1  A9 C1              LDA   #TK_EQUAL         ; get = token
00D05F  1  20 C0 CB           JSR   LAB_SCCA          ; scan for CHR$(A), else do syntax error then warm start
00D062  1  A5 96              LDA   Cvarah            ; get current var address high byte
00D064  1  48                 PHA                     ; push it
00D065  1  A5 95              LDA   Cvaral            ; get current var address low byte
00D067  1  48                 PHA                     ; push it
00D068  1  A5 C4              LDA   Bpntrh            ; get BASIC execute pointer high byte
00D06A  1  48                 PHA                     ; push it
00D06B  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte
00D06D  1  48                 PHA                     ; push it
00D06E  1  20 5C C6           JSR   LAB_DATA          ; go perform DATA
00D071  1  4C E3 D0           JMP   LAB_207A          ; put execute pointer and variable pointer into function
00D074  1                                             ; and return
00D074  1               
00D074  1               ; check FNx syntax
00D074  1               
00D074  1               LAB_200B
00D074  1  A9 AE              LDA   #TK_FN            ; get FN" token
00D076  1  20 C0 CB           JSR   LAB_SCCA          ; scan for CHR$(A) , else do syntax error then warm start
00D079  1                                             ; return character after A
00D079  1  09 80              ORA   #$80              ; set FN flag bit
00D07B  1  85 61              STA   Sufnxf            ; save FN flag so array variable test fails
00D07D  1  20 80 CD           JSR   LAB_1D12          ; search for FN variable
00D080  1  4C 9F CA           JMP   LAB_CTNM          ; check if source is numeric and return, else do type
00D083  1                                             ; mismatch
00D083  1               
00D083  1                                             ; Evaluate FNx
00D083  1               LAB_201E
00D083  1  20 74 D0           JSR   LAB_200B          ; check FNx syntax
00D086  1  48                 PHA                     ; push function pointer low byte
00D087  1  98                 TYA                     ; copy function pointer high byte
00D088  1  48                 PHA                     ; push function pointer high byte
00D089  1  20 C9 CB           JSR   LAB_1BFE          ; scan for "(", else do syntax error then warm start
00D08C  1  20 B0 CA           JSR   LAB_EVEX          ; evaluate expression
00D08F  1  20 BE CB           JSR   LAB_1BFB          ; scan for ")", else do syntax error then warm start
00D092  1  20 9F CA           JSR   LAB_CTNM          ; check if source is numeric, else do type mismatch
00D095  1  68                 PLA                     ; pop function pointer high byte
00D096  1  85 9D              STA   func_h            ; restore it
00D098  1  68                 PLA                     ; pop function pointer low byte
00D099  1  85 9C              STA   func_l            ; restore it
00D09B  1  A2 20              LDX   #$20              ; error code $20 ("Undefined function" error)
00D09D  1  A0 03              LDY   #$03              ; index to variable pointer high byte
00D09F  1  B1 9C              LDA   (func_l),Y        ; get variable pointer high byte
00D0A1  1  F0 9D              BEQ   LAB_1FDB          ; if zero go do undefined function error
00D0A3  1               
00D0A3  1  85 96              STA   Cvarah            ; save variable address high byte
00D0A5  1  88                 DEY                     ; index to variable address low byte
00D0A6  1  B1 9C              LDA   (func_l),Y        ; get variable address low byte
00D0A8  1  85 95              STA   Cvaral            ; save variable address low byte
00D0AA  1  AA                 TAX                     ; copy address low byte
00D0AB  1               
00D0AB  1                                             ; now stack the function variable value before use
00D0AB  1  C8                 INY                     ; index to mantissa_3
00D0AC  1               LAB_2043
00D0AC  1  B1 95              LDA   (Cvaral),Y        ; get byte from variable
00D0AE  1  48                 PHA                     ; stack it
00D0AF  1  88                 DEY                     ; decrement index
00D0B0  1  10 FA              BPL   LAB_2043          ; loop until variable stacked
00D0B2  1               
00D0B2  1  A4 96              LDY   Cvarah            ; get variable address high byte
00D0B4  1  20 78 D8           JSR   LAB_2778          ; pack FAC1 (function expression value) into (XY)
00D0B7  1                                             ; (function variable), return Y=0, always
00D0B7  1  A5 C4              LDA   Bpntrh            ; get BASIC execute pointer high byte
00D0B9  1  48                 PHA                     ; push it
00D0BA  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte
00D0BC  1  48                 PHA                     ; push it
00D0BD  1  B1 9C              LDA   (func_l),Y        ; get function execute pointer low byte
00D0BF  1  85 C3              STA   Bpntrl            ; save as BASIC execute pointer low byte
00D0C1  1  C8                 INY                     ; index to high byte
00D0C2  1  B1 9C              LDA   (func_l),Y        ; get function execute pointer high byte
00D0C4  1  85 C4              STA   Bpntrh            ; save as BASIC execute pointer high byte
00D0C6  1  A5 96              LDA   Cvarah            ; get variable address high byte
00D0C8  1  48                 PHA                     ; push it
00D0C9  1  A5 95              LDA   Cvaral            ; get variable address low byte
00D0CB  1  48                 PHA                     ; push it
00D0CC  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00D0CF  1                                             ; else do type mismatch
00D0CF  1  68                 PLA                     ; pull variable address low byte
00D0D0  1  85 9C              STA   func_l            ; save variable address low byte
00D0D2  1  68                 PLA                     ; pull variable address high byte
00D0D3  1  85 9D              STA   func_h            ; save variable address high byte
00D0D5  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00D0D8  1  F0 03              BEQ   LAB_2074          ; branch if null (should be [EOL] marker)
00D0DA  1               
00D0DA  1  4C D1 CB           JMP   LAB_SNER          ; else syntax error then warm start
00D0DD  1               
00D0DD  1               ; restore Bpntrl,Bpntrh and function variable from stack
00D0DD  1               
00D0DD  1               LAB_2074
00D0DD  1  68                 PLA                     ; pull BASIC execute pointer low byte
00D0DE  1  85 C3              STA   Bpntrl            ; restore BASIC execute pointer low byte
00D0E0  1  68                 PLA                     ; pull BASIC execute pointer high byte
00D0E1  1  85 C4              STA   Bpntrh            ; restore BASIC execute pointer high byte
00D0E3  1               
00D0E3  1               ; put execute pointer and variable pointer into function
00D0E3  1               
00D0E3  1               LAB_207A
00D0E3  1  A0 00              LDY   #$00              ; clear index
00D0E5  1  68                 PLA                     ; pull BASIC execute pointer low byte
00D0E6  1  91 9C              STA   (func_l),Y        ; save to function
00D0E8  1  C8                 INY                     ; increment index
00D0E9  1  68                 PLA                     ; pull BASIC execute pointer high byte
00D0EA  1  91 9C              STA   (func_l),Y        ; save to function
00D0EC  1  C8                 INY                     ; increment index
00D0ED  1  68                 PLA                     ; pull current var address low byte
00D0EE  1  91 9C              STA   (func_l),Y        ; save to function
00D0F0  1  C8                 INY                     ; increment index
00D0F1  1  68                 PLA                     ; pull current var address high byte
00D0F2  1  91 9C              STA   (func_l),Y        ; save to function
00D0F4  1  60                 RTS
00D0F5  1               
00D0F5  1               ; perform STR$()
00D0F5  1               
00D0F5  1               LAB_STRS
00D0F5  1  20 9F CA           JSR   LAB_CTNM          ; check if source is numeric, else do type mismatch
00D0F8  1  20 66 DA           JSR   LAB_296E          ; convert FAC1 to string
00D0FB  1  A9 F0              LDA   #<Decssp1         ; set result string low pointer
00D0FD  1  A0 00              LDY   #>Decssp1         ; set result string high pointer
00D0FF  1  F0 12              BEQ   LAB_20AE          ; print null terminated string to Sutill/Sutilh
00D101  1               
00D101  1               ; Do string vector
00D101  1               ; copy des_pl/h to des_2l/h and make string space A bytes long
00D101  1               
00D101  1               LAB_209C
00D101  1  A6 AE              LDX   des_pl            ; get descriptor pointer low byte
00D103  1  A4 AF              LDY   des_ph            ; get descriptor pointer high byte
00D105  1  86 9E              STX   des_2l            ; save descriptor pointer low byte
00D107  1  84 9F              STY   des_2h            ; save descriptor pointer high byte
00D109  1               
00D109  1               ; make string space A bytes long
00D109  1               ; A=length, X=Sutill=ptr low byte, Y=Sutilh=ptr high byte
00D109  1               
00D109  1               LAB_MSSP
00D109  1  20 7E D1           JSR   LAB_2115          ; make space in string memory for string A long
00D10C  1                                             ; return X=Sutill=ptr low byte, Y=Sutilh=ptr high byte
00D10C  1  86 AD              STX   str_pl            ; save string pointer low byte
00D10E  1  84 AE              STY   str_ph            ; save string pointer high byte
00D110  1  85 AC              STA   str_ln            ; save length
00D112  1  60                 RTS
00D113  1               
00D113  1               ; Scan, set up string
00D113  1               ; print " terminated string to Sutill/Sutilh
00D113  1               
00D113  1               LAB_20AE
00D113  1  A2 22              LDX   #$22              ; set terminator to "
00D115  1  86 5B              STX   Srchc             ; set search character (terminator 1)
00D117  1  86 5C              STX   Asrch             ; set terminator 2
00D119  1               
00D119  1               ; print [Srchc] or [Asrch] terminated string to Sutill/Sutilh
00D119  1               ; source is AY
00D119  1               
00D119  1               LAB_20B4
00D119  1  85 B8              STA   ssptr_l           ; store string start low byte
00D11B  1  84 B9              STY   ssptr_h           ; store string start high byte
00D11D  1  85 AD              STA   str_pl            ; save string pointer low byte
00D11F  1  84 AE              STY   str_ph            ; save string pointer high byte
00D121  1  A0 FF              LDY   #$FF              ; set length to -1
00D123  1               LAB_20BE
00D123  1  C8                 INY                     ; increment length
00D124  1  B1 B8              LDA   (ssptr_l),Y       ; get byte from string
00D126  1  F0 0C              BEQ   LAB_20CF          ; exit loop if null byte [EOS]
00D128  1               
00D128  1  C5 5B              CMP   Srchc             ; compare with search character (terminator 1)
00D12A  1  F0 04              BEQ   LAB_20CB          ; branch if terminator
00D12C  1               
00D12C  1  C5 5C              CMP   Asrch             ; compare with terminator 2
00D12E  1  D0 F3              BNE   LAB_20BE          ; loop if not terminator 2
00D130  1               
00D130  1               LAB_20CB
00D130  1  C9 22              CMP   #$22              ; compare with "
00D132  1  F0 01              BEQ   LAB_20D0          ; branch if " (carry set if = !)
00D134  1               
00D134  1               LAB_20CF
00D134  1  18                 CLC                     ; clear carry for add (only if [EOL] terminated string)
00D135  1               LAB_20D0
00D135  1  84 AC              STY   str_ln            ; save length in FAC1 exponent
00D137  1  98                 TYA                     ; copy length to A
00D138  1  65 B8              ADC   ssptr_l           ; add string start low byte
00D13A  1  85 BA              STA   Sendl             ; save string end low byte
00D13C  1  A6 B9              LDX   ssptr_h           ; get string start high byte
00D13E  1  90 01              BCC   LAB_20DC          ; branch if no low byte overflow
00D140  1               
00D140  1  E8                 INX                     ; else increment high byte
00D141  1               LAB_20DC
00D141  1  86 BB              STX   Sendh             ; save string end high byte
00D143  1  A5 B9              LDA   ssptr_h           ; get string start high byte
00D145  1               ; *** begin RAM above code / Ibuff above EhBASIC patch V2 ***
00D145  1               ; *** replace
00D145  1               ;      CMP   #>Ram_base        ; compare with start of program memory
00D145  1               ;      BCS   LAB_RTST          ; branch if not in utility area
00D145  1               ; *** with
00D145  1  F0 04              BEQ   LAB_MVST          ; fix STR$() using page zero via LAB_296E
00D147  1  C9 02              CMP   #>Ibuffs          ; compare with location of input buffer page
00D149  1  D0 0B              BNE   LAB_RTST          ; branch if not in utility area
00D14B  1               LAB_MVST
00D14B  1               ; *** end   RAM above code / Ibuff above EhBASIC patch V2 ***
00D14B  1               
00D14B  1                                             ; string in utility area, move to string memory
00D14B  1  98                 TYA                     ; copy length to A
00D14C  1  20 01 D1           JSR   LAB_209C          ; copy des_pl/h to des_2l/h and make string space A bytes
00D14F  1                                             ; long
00D14F  1  A6 B8              LDX   ssptr_l           ; get string start low byte
00D151  1  A4 B9              LDY   ssptr_h           ; get string start high byte
00D153  1  20 F0 D2           JSR   LAB_2298          ; store string A bytes long from XY to (Sutill)
00D156  1               
00D156  1               ; check for space on descriptor stack then ..
00D156  1               ; put string address and length on descriptor stack and update stack pointers
00D156  1               
00D156  1               LAB_RTST
00D156  1  A6 65              LDX   next_s            ; get string stack pointer
00D158  1  E0 71              CPX   #des_sk+$09       ; compare with max+1
00D15A  1  D0 05              BNE   LAB_20F8          ; branch if space on string stack
00D15C  1               
00D15C  1                                             ; else do string too complex error
00D15C  1  A2 1C              LDX   #$1C              ; error code $1C ("String too complex" error)
00D15E  1               LAB_20F5
00D15E  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00D161  1               
00D161  1               ; put string address and length on descriptor stack and update stack pointers
00D161  1               
00D161  1               LAB_20F8
00D161  1  A5 AC              LDA   str_ln            ; get string length
00D163  1  95 00              STA   PLUS_0,X          ; put on string stack
00D165  1  A5 AD              LDA   str_pl            ; get string pointer low byte
00D167  1  95 01              STA   PLUS_1,X          ; put on string stack
00D169  1  A5 AE              LDA   str_ph            ; get string pointer high byte
00D16B  1  95 02              STA   PLUS_2,X          ; put on string stack
00D16D  1  A0 00              LDY   #$00              ; clear Y
00D16F  1  86 AE              STX   des_pl            ; save string descriptor pointer low byte
00D171  1  84 AF              STY   des_ph            ; save string descriptor pointer high byte (always $00)
00D173  1  88                 DEY                     ; Y = $FF
00D174  1  84 5F              STY   Dtypef            ; save data type flag, $FF=string
00D176  1  86 66              STX   last_sl           ; save old stack pointer (current top item)
00D178  1  E8                 INX                     ; update stack pointer
00D179  1  E8                 INX                     ; update stack pointer
00D17A  1  E8                 INX                     ; update stack pointer
00D17B  1  86 65              STX   next_s            ; save new top item value
00D17D  1  60                 RTS
00D17E  1               
00D17E  1               ; Build descriptor
00D17E  1               ; make space in string memory for string A long
00D17E  1               ; return X=Sutill=ptr low byte, Y=Sutill=ptr high byte
00D17E  1               
00D17E  1               LAB_2115
00D17E  1  46 60              LSR   Gclctd            ; clear garbage collected flag (b7)
00D180  1               
00D180  1                                             ; make space for string A long
00D180  1               LAB_2117
00D180  1  48                 PHA                     ; save string length
00D181  1  49 FF              EOR   #$FF              ; complement it
00D183  1  38                 SEC                     ; set carry for subtract (twos comp add)
00D184  1  65 81              ADC   Sstorl            ; add bottom of string space low byte (subtract length)
00D186  1  A4 82              LDY   Sstorh            ; get bottom of string space high byte
00D188  1  B0 01              BCS   LAB_2122          ; skip decrement if no underflow
00D18A  1               
00D18A  1  88                 DEY                     ; decrement bottom of string space high byte
00D18B  1               LAB_2122
00D18B  1  C4 80              CPY   Earryh            ; compare with array mem end high byte
00D18D  1  90 11              BCC   LAB_2137          ; do out of memory error if less
00D18F  1               
00D18F  1  D0 04              BNE   LAB_212C          ; if not = skip next test
00D191  1               
00D191  1  C5 7F              CMP   Earryl            ; compare with array mem end low byte
00D193  1  90 0B              BCC   LAB_2137          ; do out of memory error if less
00D195  1               
00D195  1               LAB_212C
00D195  1  85 81              STA   Sstorl            ; save bottom of string space low byte
00D197  1  84 82              STY   Sstorh            ; save bottom of string space high byte
00D199  1  85 83              STA   Sutill            ; save string utility ptr low byte
00D19B  1  84 84              STY   Sutilh            ; save string utility ptr high byte
00D19D  1  AA                 TAX                     ; copy low byte to X
00D19E  1  68                 PLA                     ; get string length back
00D19F  1  60                 RTS
00D1A0  1               
00D1A0  1               LAB_2137
00D1A0  1  A2 0C              LDX   #$0C              ; error code $0C ("Out of memory" error)
00D1A2  1  A5 60              LDA   Gclctd            ; get garbage collected flag
00D1A4  1  30 B8              BMI   LAB_20F5          ; if set then do error code X
00D1A6  1               
00D1A6  1  20 B0 D1           JSR   LAB_GARB          ; else go do garbage collection
00D1A9  1  A9 80              LDA   #$80              ; flag for garbage collected
00D1AB  1  85 60              STA   Gclctd            ; set garbage collected flag
00D1AD  1  68                 PLA                     ; pull length
00D1AE  1  D0 D0              BNE   LAB_2117          ; go try again (loop always, length should never be = $00)
00D1B0  1               
00D1B0  1               ; garbage collection routine
00D1B0  1               
00D1B0  1               LAB_GARB
00D1B0  1  A6 85              LDX   Ememl             ; get end of mem low byte
00D1B2  1  A5 86              LDA   Ememh             ; get end of mem high byte
00D1B4  1               
00D1B4  1               ; re-run routine from last ending
00D1B4  1               
00D1B4  1               LAB_214B
00D1B4  1  86 81              STX   Sstorl            ; set string storage low byte
00D1B6  1  85 82              STA   Sstorh            ; set string storage high byte
00D1B8  1  A0 00              LDY   #$00              ; clear index
00D1BA  1  84 9D              STY   garb_h            ; clear working pointer high byte (flag no strings to move)
00D1BC  1  A5 7F              LDA   Earryl            ; get array mem end low byte
00D1BE  1  A6 80              LDX   Earryh            ; get array mem end high byte
00D1C0  1  85 AA              STA   Histrl            ; save as highest string low byte
00D1C2  1  86 AB              STX   Histrh            ; save as highest string high byte
00D1C4  1  A9 68              LDA   #des_sk           ; set descriptor stack pointer
00D1C6  1  85 71              STA   ut1_pl            ; save descriptor stack pointer low byte
00D1C8  1  84 72              STY   ut1_ph            ; save descriptor stack pointer high byte ($00)
00D1CA  1               LAB_2161
00D1CA  1  C5 65              CMP   next_s            ; compare with descriptor stack pointer
00D1CC  1  F0 05              BEQ   LAB_216A          ; branch if =
00D1CE  1               
00D1CE  1  20 34 D2           JSR   LAB_21D7          ; go garbage collect descriptor stack
00D1D1  1  F0 F7              BEQ   LAB_2161          ; loop always
00D1D3  1               
00D1D3  1                                             ; done stacked strings, now do string vars
00D1D3  1               LAB_216A
00D1D3  1  06 A0              ASL   g_step            ; set step size = $06
00D1D5  1  A5 7B              LDA   Svarl             ; get start of vars low byte
00D1D7  1  A6 7C              LDX   Svarh             ; get start of vars high byte
00D1D9  1  85 71              STA   ut1_pl            ; save as pointer low byte
00D1DB  1  86 72              STX   ut1_ph            ; save as pointer high byte
00D1DD  1               LAB_2176
00D1DD  1  E4 7E              CPX   Sarryh            ; compare start of arrays high byte
00D1DF  1  D0 04              BNE   LAB_217E          ; branch if no high byte match
00D1E1  1               
00D1E1  1  C5 7D              CMP   Sarryl            ; else compare start of arrays low byte
00D1E3  1  F0 05              BEQ   LAB_2183          ; branch if = var mem end
00D1E5  1               
00D1E5  1               LAB_217E
00D1E5  1  20 2E D2           JSR   LAB_21D1          ; go garbage collect strings
00D1E8  1  F0 F3              BEQ   LAB_2176          ; loop always
00D1EA  1               
00D1EA  1                                             ; done string vars, now do string arrays
00D1EA  1               LAB_2183
00D1EA  1  85 A4              STA   Nbendl            ; save start of arrays low byte as working pointer
00D1EC  1  86 A5              STX   Nbendh            ; save start of arrays high byte as working pointer
00D1EE  1  A9 04              LDA   #$04              ; set step size
00D1F0  1  85 A0              STA   g_step            ; save step size
00D1F2  1               LAB_218B
00D1F2  1  A5 A4              LDA   Nbendl            ; get pointer low byte
00D1F4  1  A6 A5              LDX   Nbendh            ; get pointer high byte
00D1F6  1               LAB_218F
00D1F6  1  E4 80              CPX   Earryh            ; compare with array mem end high byte
00D1F8  1  D0 04              BNE   LAB_219A          ; branch if not at end
00D1FA  1               
00D1FA  1  C5 7F              CMP   Earryl            ; else compare with array mem end low byte
00D1FC  1  F0 75              BEQ   LAB_2216          ; tidy up and exit if at end
00D1FE  1               
00D1FE  1               LAB_219A
00D1FE  1  85 71              STA   ut1_pl            ; save pointer low byte
00D200  1  86 72              STX   ut1_ph            ; save pointer high byte
00D202  1  A0 02              LDY   #$02              ; set index
00D204  1  B1 71              LDA   (ut1_pl),Y        ; get array size low byte
00D206  1  65 A4              ADC   Nbendl            ; add start of this array low byte
00D208  1  85 A4              STA   Nbendl            ; save start of next array low byte
00D20A  1  C8                 INY                     ; increment index
00D20B  1  B1 71              LDA   (ut1_pl),Y        ; get array size high byte
00D20D  1  65 A5              ADC   Nbendh            ; add start of this array high byte
00D20F  1  85 A5              STA   Nbendh            ; save start of next array high byte
00D211  1  A0 01              LDY   #$01              ; set index
00D213  1  B1 71              LDA   (ut1_pl),Y        ; get name second byte
00D215  1  10 DB              BPL   LAB_218B          ; skip if not string array
00D217  1               
00D217  1               ; was string array so ..
00D217  1               
00D217  1  A0 04              LDY   #$04              ; set index
00D219  1  B1 71              LDA   (ut1_pl),Y        ; get # of dimensions
00D21B  1  0A                 ASL                     ; *2
00D21C  1  69 05              ADC   #$05              ; +5 (array header size)
00D21E  1  20 66 D2           JSR   LAB_2208          ; go set up for first element
00D221  1               LAB_21C4
00D221  1  E4 A5              CPX   Nbendh            ; compare with start of next array high byte
00D223  1  D0 04              BNE   LAB_21CC          ; branch if <> (go do this array)
00D225  1               
00D225  1  C5 A4              CMP   Nbendl            ; else compare element pointer low byte with next array
00D227  1                                             ; low byte
00D227  1  F0 CD              BEQ   LAB_218F          ; if equal then go do next array
00D229  1               
00D229  1               LAB_21CC
00D229  1  20 34 D2           JSR   LAB_21D7          ; go defrag array strings
00D22C  1  F0 F3              BEQ   LAB_21C4          ; go do next array string (loop always)
00D22E  1               
00D22E  1               ; defrag string variables
00D22E  1               ; enter with XA = variable pointer
00D22E  1               ; return with XA = next variable pointer
00D22E  1               
00D22E  1               LAB_21D1
00D22E  1  C8                 INY                     ; increment index (Y was $00)
00D22F  1  B1 71              LDA   (ut1_pl),Y        ; get var name byte 2
00D231  1  10 30              BPL   LAB_2206          ; if not string, step pointer to next var and return
00D233  1               
00D233  1  C8                 INY                     ; else increment index
00D234  1               LAB_21D7
00D234  1  B1 71              LDA   (ut1_pl),Y        ; get string length
00D236  1  F0 2B              BEQ   LAB_2206          ; if null, step pointer to next string and return
00D238  1               
00D238  1  C8                 INY                     ; else increment index
00D239  1  B1 71              LDA   (ut1_pl),Y        ; get string pointer low byte
00D23B  1  AA                 TAX                     ; copy to X
00D23C  1  C8                 INY                     ; increment index
00D23D  1  B1 71              LDA   (ut1_pl),Y        ; get string pointer high byte
00D23F  1  C5 82              CMP   Sstorh            ; compare bottom of string space high byte
00D241  1  90 06              BCC   LAB_21EC          ; branch if less
00D243  1               
00D243  1  D0 1E              BNE   LAB_2206          ; if greater, step pointer to next string and return
00D245  1               
00D245  1                                             ; high bytes were = so compare low bytes
00D245  1  E4 81              CPX   Sstorl            ; compare bottom of string space low byte
00D247  1  B0 1A              BCS   LAB_2206          ; if >=, step pointer to next string and return
00D249  1               
00D249  1                                             ; string pointer is < string storage pointer (pos in mem)
00D249  1               LAB_21EC
00D249  1  C5 AB              CMP   Histrh            ; compare to highest string high byte
00D24B  1  90 17              BCC   LAB_2207          ; if <, step pointer to next string and return
00D24D  1               
00D24D  1  D0 04              BNE   LAB_21F6          ; if > update pointers, step to next and return
00D24F  1               
00D24F  1                                             ; high bytes were = so compare low bytes
00D24F  1  E4 AA              CPX   Histrl            ; compare to highest string low byte
00D251  1  90 11              BCC   LAB_2207          ; if <, step pointer to next string and return
00D253  1               
00D253  1                                             ; string is in string memory space
00D253  1               LAB_21F6
00D253  1  86 AA              STX   Histrl            ; save as new highest string low byte
00D255  1  85 AB              STA   Histrh            ; save as new highest string high byte
00D257  1  A5 71              LDA   ut1_pl            ; get start of vars(descriptors) low byte
00D259  1  A6 72              LDX   ut1_ph            ; get start of vars(descriptors) high byte
00D25B  1  85 9C              STA   garb_l            ; save as working pointer low byte
00D25D  1  86 9D              STX   garb_h            ; save as working pointer high byte
00D25F  1  88                 DEY                     ; decrement index DIFFERS
00D260  1  88                 DEY                     ; decrement index (should point to descriptor start)
00D261  1  84 A2              STY   g_indx            ; save index pointer
00D263  1               
00D263  1                                             ; step pointer to next string
00D263  1               LAB_2206
00D263  1  18                 CLC                     ; clear carry for add
00D264  1               LAB_2207
00D264  1  A5 A0              LDA   g_step            ; get step size
00D266  1               LAB_2208
00D266  1  65 71              ADC   ut1_pl            ; add pointer low byte
00D268  1  85 71              STA   ut1_pl            ; save pointer low byte
00D26A  1  90 02              BCC   LAB_2211          ; branch if no overflow
00D26C  1               
00D26C  1  E6 72              INC   ut1_ph            ; else increment high byte
00D26E  1               LAB_2211
00D26E  1  A6 72              LDX   ut1_ph            ; get pointer high byte
00D270  1  A0 00              LDY   #$00              ; clear Y
00D272  1  60                 RTS
00D273  1               
00D273  1               ; search complete, now either exit or set-up and move string
00D273  1               
00D273  1               LAB_2216
00D273  1  C6 A0              DEC   g_step            ; decrement step size (now $03 for descriptor stack)
00D275  1  A6 9D              LDX   garb_h            ; get string to move high byte
00D277  1  F0 F5              BEQ   LAB_2211          ; exit if nothing to move
00D279  1               
00D279  1  A4 A2              LDY   g_indx            ; get index byte back (points to descriptor)
00D27B  1  18                 CLC                     ; clear carry for add
00D27C  1  B1 9C              LDA   (garb_l),Y        ; get string length
00D27E  1  65 AA              ADC   Histrl            ; add highest string low byte
00D280  1  85 A6              STA   Obendl            ; save old block end low pointer
00D282  1  A5 AB              LDA   Histrh            ; get highest string high byte
00D284  1  69 00              ADC   #$00              ; add any carry
00D286  1  85 A7              STA   Obendh            ; save old block end high byte
00D288  1  A5 81              LDA   Sstorl            ; get bottom of string space low byte
00D28A  1  A6 82              LDX   Sstorh            ; get bottom of string space high byte
00D28C  1  85 A4              STA   Nbendl            ; save new block end low byte
00D28E  1  86 A5              STX   Nbendh            ; save new block end high byte
00D290  1  20 8E C0           JSR   LAB_11D6          ; open up space in memory, don't set array end
00D293  1  A4 A2              LDY   g_indx            ; get index byte
00D295  1  C8                 INY                     ; point to descriptor low byte
00D296  1  A5 A4              LDA   Nbendl            ; get string pointer low byte
00D298  1  91 9C              STA   (garb_l),Y        ; save new string pointer low byte
00D29A  1  AA                 TAX                     ; copy string pointer low byte
00D29B  1  E6 A5              INC   Nbendh            ; correct high byte (move sets high byte -1)
00D29D  1  A5 A5              LDA   Nbendh            ; get new string pointer high byte
00D29F  1  C8                 INY                     ; point to descriptor high byte
00D2A0  1  91 9C              STA   (garb_l),Y        ; save new string pointer high byte
00D2A2  1  4C B4 D1           JMP   LAB_214B          ; re-run routine from last ending
00D2A5  1                                             ; (but don't collect this string)
00D2A5  1               
00D2A5  1               ; concatenate
00D2A5  1               ; add strings, string 1 is in descriptor des_pl, string 2 is in line
00D2A5  1               
00D2A5  1               LAB_224D
00D2A5  1  A5 AF              LDA   des_ph            ; get descriptor pointer high byte
00D2A7  1  48                 PHA                     ; put on stack
00D2A8  1  A5 AE              LDA   des_pl            ; get descriptor pointer low byte
00D2AA  1  48                 PHA                     ; put on stack
00D2AB  1  20 9C CB           JSR   LAB_GVAL          ; get value from line
00D2AE  1  20 A1 CA           JSR   LAB_CTST          ; check if source is string, else do type mismatch
00D2B1  1  68                 PLA                     ; get descriptor pointer low byte back
00D2B2  1  85 B8              STA   ssptr_l           ; set pointer low byte
00D2B4  1  68                 PLA                     ; get descriptor pointer high byte back
00D2B5  1  85 B9              STA   ssptr_h           ; set pointer high byte
00D2B7  1  A0 00              LDY   #$00              ; clear index
00D2B9  1  B1 B8              LDA   (ssptr_l),Y       ; get length_1 from descriptor
00D2BB  1  18                 CLC                     ; clear carry for add
00D2BC  1  71 AE              ADC   (des_pl),Y        ; add length_2
00D2BE  1  90 05              BCC   LAB_226D          ; branch if no overflow
00D2C0  1               
00D2C0  1  A2 1A              LDX   #$1A              ; else set error code $1A ("String too long" error)
00D2C2  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00D2C5  1               
00D2C5  1               LAB_226D
00D2C5  1  20 01 D1           JSR   LAB_209C          ; copy des_pl/h to des_2l/h and make string space A bytes
00D2C8  1                                             ; long
00D2C8  1  20 E2 D2           JSR   LAB_228A          ; copy string from descriptor (sdescr) to (Sutill)
00D2CB  1  A5 9E              LDA   des_2l            ; get descriptor pointer low byte
00D2CD  1  A4 9F              LDY   des_2h            ; get descriptor pointer high byte
00D2CF  1  20 13 D3           JSR   LAB_22BA          ; pop (YA) descriptor off stack or from top of string space
00D2D2  1                                             ; returns with A = length, ut1_pl = pointer low byte,
00D2D2  1                                             ; ut1_ph = pointer high byte
00D2D2  1  20 F4 D2           JSR   LAB_229C          ; store string A bytes long from (ut1_pl) to (Sutill)
00D2D5  1  A5 B8              LDA   ssptr_l           ;.set descriptor pointer low byte
00D2D7  1  A4 B9              LDY   ssptr_h           ;.set descriptor pointer high byte
00D2D9  1  20 13 D3           JSR   LAB_22BA          ; pop (YA) descriptor off stack or from top of string space
00D2DC  1                                             ; returns with A = length, X=ut1_pl=pointer low byte,
00D2DC  1                                             ; Y=ut1_ph=pointer high byte
00D2DC  1  20 56 D1           JSR   LAB_RTST          ; check for space on descriptor stack then put string
00D2DF  1                                             ; address and length on descriptor stack and update stack
00D2DF  1                                             ; pointers
00D2DF  1  4C C7 CA           JMP   LAB_1ADB          ;.continue evaluation
00D2E2  1               
00D2E2  1               ; copy string from descriptor (sdescr) to (Sutill)
00D2E2  1               
00D2E2  1               LAB_228A
00D2E2  1  A0 00              LDY   #$00              ; clear index
00D2E4  1  B1 B8              LDA   (sdescr),Y        ; get string length
00D2E6  1  48                 PHA                     ; save on stack
00D2E7  1  C8                 INY                     ; increment index
00D2E8  1  B1 B8              LDA   (sdescr),Y        ; get source string pointer low byte
00D2EA  1  AA                 TAX                     ; copy to X
00D2EB  1  C8                 INY                     ; increment index
00D2EC  1  B1 B8              LDA   (sdescr),Y        ; get source string pointer high byte
00D2EE  1  A8                 TAY                     ; copy to Y
00D2EF  1  68                 PLA                     ; get length back
00D2F0  1               
00D2F0  1               ; store string A bytes long from YX to (Sutill)
00D2F0  1               
00D2F0  1               LAB_2298
00D2F0  1  86 71              STX   ut1_pl            ; save source string pointer low byte
00D2F2  1  84 72              STY   ut1_ph            ; save source string pointer high byte
00D2F4  1               
00D2F4  1               ; store string A bytes long from (ut1_pl) to (Sutill)
00D2F4  1               
00D2F4  1               LAB_229C
00D2F4  1  AA                 TAX                     ; copy length to index (don't count with Y)
00D2F5  1  F0 14              BEQ   LAB_22B2          ; branch if = $0 (null string) no need to add zero length
00D2F7  1               
00D2F7  1  A0 00              LDY   #$00              ; zero pointer (copy forward)
00D2F9  1               LAB_22A0
00D2F9  1  B1 71              LDA   (ut1_pl),Y        ; get source byte
00D2FB  1  91 83              STA   (Sutill),Y        ; save destination byte
00D2FD  1               
00D2FD  1  C8                 INY                     ; increment index
00D2FE  1  CA                 DEX                     ; decrement counter
00D2FF  1  D0 F8              BNE   LAB_22A0          ; loop while <> 0
00D301  1               
00D301  1  98                 TYA                     ; restore length from Y
00D302  1               LAB_22A9
00D302  1  18                 CLC                     ; clear carry for add
00D303  1  65 83              ADC   Sutill            ; add string utility ptr low byte
00D305  1  85 83              STA   Sutill            ; save string utility ptr low byte
00D307  1  90 02              BCC   LAB_22B2          ; branch if no carry
00D309  1               
00D309  1  E6 84              INC   Sutilh            ; else increment string utility ptr high byte
00D30B  1               LAB_22B2
00D30B  1  60                 RTS
00D30C  1               
00D30C  1               ; evaluate string
00D30C  1               
00D30C  1               LAB_EVST
00D30C  1  20 A1 CA           JSR   LAB_CTST          ; check if source is string, else do type mismatch
00D30F  1               
00D30F  1               ; pop string off descriptor stack, or from top of string space
00D30F  1               ; returns with A = length, X=pointer low byte, Y=pointer high byte
00D30F  1               
00D30F  1               LAB_22B6
00D30F  1  A5 AE              LDA   des_pl            ; get descriptor pointer low byte
00D311  1  A4 AF              LDY   des_ph            ; get descriptor pointer high byte
00D313  1               
00D313  1               ; pop (YA) descriptor off stack or from top of string space
00D313  1               ; returns with A = length, X=ut1_pl=pointer low byte, Y=ut1_ph=pointer high byte
00D313  1               
00D313  1               LAB_22BA
00D313  1  85 71              STA   ut1_pl            ; save descriptor pointer low byte
00D315  1  84 72              STY   ut1_ph            ; save descriptor pointer high byte
00D317  1  20 44 D3           JSR   LAB_22EB          ; clean descriptor stack, YA = pointer
00D31A  1  08                 PHP                     ; save status flags
00D31B  1  A0 00              LDY   #$00              ; clear index
00D31D  1  B1 71              LDA   (ut1_pl),Y        ; get length from string descriptor
00D31F  1  48                 PHA                     ; put on stack
00D320  1  C8                 INY                     ; increment index
00D321  1  B1 71              LDA   (ut1_pl),Y        ; get string pointer low byte from descriptor
00D323  1  AA                 TAX                     ; copy to X
00D324  1  C8                 INY                     ; increment index
00D325  1  B1 71              LDA   (ut1_pl),Y        ; get string pointer high byte from descriptor
00D327  1  A8                 TAY                     ; copy to Y
00D328  1  68                 PLA                     ; get string length back
00D329  1  28                 PLP                     ; restore status
00D32A  1  D0 13              BNE   LAB_22E6          ; branch if pointer <> last_sl,last_sh
00D32C  1               
00D32C  1  C4 82              CPY   Sstorh            ; compare bottom of string space high byte
00D32E  1  D0 0F              BNE   LAB_22E6          ; branch if <>
00D330  1               
00D330  1  E4 81              CPX   Sstorl            ; else compare bottom of string space low byte
00D332  1  D0 0B              BNE   LAB_22E6          ; branch if <>
00D334  1               
00D334  1  48                 PHA                     ; save string length
00D335  1  18                 CLC                     ; clear carry for add
00D336  1  65 81              ADC   Sstorl            ; add bottom of string space low byte
00D338  1  85 81              STA   Sstorl            ; save bottom of string space low byte
00D33A  1  90 02              BCC   LAB_22E5          ; skip increment if no overflow
00D33C  1               
00D33C  1  E6 82              INC   Sstorh            ; increment bottom of string space high byte
00D33E  1               LAB_22E5
00D33E  1  68                 PLA                     ; restore string length
00D33F  1               LAB_22E6
00D33F  1  86 71              STX   ut1_pl            ; save string pointer low byte
00D341  1  84 72              STY   ut1_ph            ; save string pointer high byte
00D343  1  60                 RTS
00D344  1               
00D344  1               ; clean descriptor stack, YA = pointer
00D344  1               ; checks if AY is on the descriptor stack, if so does a stack discard
00D344  1               
00D344  1               LAB_22EB
00D344  1  C4 67              CPY   last_sh           ; compare pointer high byte
00D346  1  D0 0C              BNE   LAB_22FB          ; exit if <>
00D348  1               
00D348  1  C5 66              CMP   last_sl           ; compare pointer low byte
00D34A  1  D0 08              BNE   LAB_22FB          ; exit if <>
00D34C  1               
00D34C  1  85 65              STA   next_s            ; save descriptor stack pointer
00D34E  1  E9 03              SBC   #$03              ; -3
00D350  1  85 66              STA   last_sl           ; save low byte -3
00D352  1  A0 00              LDY   #$00              ; clear high byte
00D354  1               LAB_22FB
00D354  1  60                 RTS
00D355  1               
00D355  1               ; perform CHR$()
00D355  1               
00D355  1               LAB_CHRS
00D355  1  20 60 D4           JSR   LAB_EVBY          ; evaluate byte expression, result in X
00D358  1  8A                 TXA                     ; copy to A
00D359  1  48                 PHA                     ; save character
00D35A  1  A9 01              LDA   #$01              ; string is single byte
00D35C  1  20 09 D1           JSR   LAB_MSSP          ; make string space A bytes long A=$AC=length,
00D35F  1                                             ; X=$AD=Sutill=ptr low byte, Y=$AE=Sutilh=ptr high byte
00D35F  1  68                 PLA                     ; get character back
00D360  1  A0 00              LDY   #$00              ; clear index
00D362  1  91 AD              STA   (str_pl),Y        ; save byte in string (byte IS string!)
00D364  1  4C 56 D1           JMP   LAB_RTST          ; check for space on descriptor stack then put string
00D367  1                                             ; address and length on descriptor stack and update stack
00D367  1                                             ; pointers
00D367  1               
00D367  1               ; perform LEFT$()
00D367  1               
00D367  1               LAB_LEFT
00D367  1  48                 PHA                     ; push byte parameter
00D368  1  20 C8 D3           JSR   LAB_236F          ; pull string data and byte parameter from stack
00D36B  1                                             ; return pointer in des_2l/h, byte in A (and X), Y=0
00D36B  1  D1 9E              CMP   (des_2l),Y        ; compare byte parameter with string length
00D36D  1  98                 TYA                     ; clear A
00D36E  1  F0 09              BEQ   LAB_2316          ; go do string copy (branch always)
00D370  1               
00D370  1               ; perform RIGHT$()
00D370  1               
00D370  1               LAB_RIGHT
00D370  1  48                 PHA                     ; push byte parameter
00D371  1  20 C8 D3           JSR   LAB_236F          ; pull string data and byte parameter from stack
00D374  1                                             ; return pointer in des_2l/h, byte in A (and X), Y=0
00D374  1  18                 CLC                     ; clear carry for add-1
00D375  1  F1 9E              SBC   (des_2l),Y        ; subtract string length
00D377  1  49 FF              EOR   #$FF              ; invert it (A=LEN(expression$)-l)
00D379  1               
00D379  1               LAB_2316
00D379  1  90 04              BCC   LAB_231C          ; branch if string length > byte parameter
00D37B  1               
00D37B  1  B1 9E              LDA   (des_2l),Y        ; else make parameter = length
00D37D  1  AA                 TAX                     ; copy to byte parameter copy
00D37E  1  98                 TYA                     ; clear string start offset
00D37F  1               LAB_231C
00D37F  1  48                 PHA                     ; save string start offset
00D380  1               LAB_231D
00D380  1  8A                 TXA                     ; copy byte parameter (or string length if <)
00D381  1               LAB_231E
00D381  1  48                 PHA                     ; save string length
00D382  1  20 09 D1           JSR   LAB_MSSP          ; make string space A bytes long A=$AC=length,
00D385  1                                             ; X=$AD=Sutill=ptr low byte, Y=$AE=Sutilh=ptr high byte
00D385  1  A5 9E              LDA   des_2l            ; get descriptor pointer low byte
00D387  1  A4 9F              LDY   des_2h            ; get descriptor pointer high byte
00D389  1  20 13 D3           JSR   LAB_22BA          ; pop (YA) descriptor off stack or from top of string space
00D38C  1                                             ; returns with A = length, X=ut1_pl=pointer low byte,
00D38C  1                                             ; Y=ut1_ph=pointer high byte
00D38C  1  68                 PLA                     ; get string length back
00D38D  1  A8                 TAY                     ; copy length to Y
00D38E  1  68                 PLA                     ; get string start offset back
00D38F  1  18                 CLC                     ; clear carry for add
00D390  1  65 71              ADC   ut1_pl            ; add start offset to string start pointer low byte
00D392  1  85 71              STA   ut1_pl            ; save string start pointer low byte
00D394  1  90 02              BCC   LAB_2335          ; branch if no overflow
00D396  1               
00D396  1  E6 72              INC   ut1_ph            ; else increment string start pointer high byte
00D398  1               LAB_2335
00D398  1  98                 TYA                     ; copy length to A
00D399  1  20 F4 D2           JSR   LAB_229C          ; store string A bytes long from (ut1_pl) to (Sutill)
00D39C  1  4C 56 D1           JMP   LAB_RTST          ; check for space on descriptor stack then put string
00D39F  1                                             ; address and length on descriptor stack and update stack
00D39F  1                                             ; pointers
00D39F  1               
00D39F  1               ; perform MID$()
00D39F  1               
00D39F  1               LAB_MIDS
00D39F  1  48                 PHA                     ; push byte parameter
00D3A0  1  A9 FF              LDA   #$FF              ; set default length = 255
00D3A2  1  85 AF              STA   mids_l            ; save default length
00D3A4  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00D3A7  1  C9 29              CMP   #')'              ; compare with ")"
00D3A9  1  F0 06              BEQ   LAB_2358          ; branch if = ")" (skip second byte get)
00D3AB  1               
00D3AB  1  20 CD CB           JSR   LAB_1C01          ; scan for "," , else do syntax error then warm start
00D3AE  1  20 5D D4           JSR   LAB_GTBY          ; get byte parameter (use copy in mids_l)
00D3B1  1               LAB_2358
00D3B1  1  20 C8 D3           JSR   LAB_236F          ; pull string data and byte parameter from stack
00D3B4  1                                             ; return pointer in des_2l/h, byte in A (and X), Y=0
00D3B4  1  CA                 DEX                     ; decrement start index
00D3B5  1  8A                 TXA                     ; copy to A
00D3B6  1  48                 PHA                     ; save string start offset
00D3B7  1  18                 CLC                     ; clear carry for sub-1
00D3B8  1  A2 00              LDX   #$00              ; clear output string length
00D3BA  1  F1 9E              SBC   (des_2l),Y        ; subtract string length
00D3BC  1  B0 C2              BCS   LAB_231D          ; if start>string length go do null string
00D3BE  1               
00D3BE  1  49 FF              EOR   #$FF              ; complement -length
00D3C0  1  C5 AF              CMP   mids_l            ; compare byte parameter
00D3C2  1  90 BD              BCC   LAB_231E          ; if length>remaining string go do RIGHT$
00D3C4  1               
00D3C4  1  A5 AF              LDA   mids_l            ; get length byte
00D3C6  1  B0 B9              BCS   LAB_231E          ; go do string copy (branch always)
00D3C8  1               
00D3C8  1               ; pull string data and byte parameter from stack
00D3C8  1               ; return pointer in des_2l/h, byte in A (and X), Y=0
00D3C8  1               
00D3C8  1               LAB_236F
00D3C8  1  20 BE CB           JSR   LAB_1BFB          ; scan for ")" , else do syntax error then warm start
00D3CB  1  68                 PLA                     ; pull return address low byte (return address)
00D3CC  1  85 A2              STA   Fnxjpl            ; save functions jump vector low byte
00D3CE  1  68                 PLA                     ; pull return address high byte (return address)
00D3CF  1  85 A3              STA   Fnxjph            ; save functions jump vector high byte
00D3D1  1  68                 PLA                     ; pull byte parameter
00D3D2  1  AA                 TAX                     ; copy byte parameter to X
00D3D3  1  68                 PLA                     ; pull string pointer low byte
00D3D4  1  85 9E              STA   des_2l            ; save it
00D3D6  1  68                 PLA                     ; pull string pointer high byte
00D3D7  1  85 9F              STA   des_2h            ; save it
00D3D9  1  A0 00              LDY   #$00              ; clear index
00D3DB  1  8A                 TXA                     ; copy byte parameter
00D3DC  1  F0 79              BEQ   LAB_23A8          ; if null do function call error then warm start
00D3DE  1               
00D3DE  1  E6 A2              INC   Fnxjpl            ; increment function jump vector low byte
00D3E0  1                                             ; (JSR pushes return addr-1. this is all very nice
00D3E0  1                                             ; but will go tits up if either call is on a page
00D3E0  1                                             ; boundary!)
00D3E0  1  6C A2 00           JMP   (Fnxjpl)          ; in effect, RTS
00D3E3  1               
00D3E3  1               ; perform LCASE$()
00D3E3  1               
00D3E3  1               LAB_LCASE
00D3E3  1  20 0C D3           JSR   LAB_EVST          ; evaluate string
00D3E6  1  85 AC              STA   str_ln            ; set string length
00D3E8  1  A8                 TAY                     ; copy length to Y
00D3E9  1  F0 38              BEQ   NoString          ; branch if null string
00D3EB  1               
00D3EB  1  20 09 D1           JSR   LAB_MSSP          ; make string space A bytes long A=length,
00D3EE  1                                             ; X=Sutill=ptr low byte, Y=Sutilh=ptr high byte
00D3EE  1  86 AD              STX   str_pl            ; save string pointer low byte
00D3F0  1  84 AE              STY   str_ph            ; save string pointer high byte
00D3F2  1  A8                 TAY                     ; get string length back
00D3F3  1               
00D3F3  1               LC_loop
00D3F3  1  88                 DEY                     ; decrement index
00D3F4  1  B1 71              LDA   (ut1_pl),Y        ; get byte from string
00D3F6  1  20 F1 CD           JSR   LAB_1D82          ; is character "A" to "Z"
00D3F9  1  90 02              BCC   NoUcase           ; branch if not upper case alpha
00D3FB  1               
00D3FB  1  09 20              ORA   #$20              ; convert upper to lower case
00D3FD  1               NoUcase
00D3FD  1  91 83              STA   (Sutill),Y        ; save byte back to string
00D3FF  1  98                 TYA                     ; test index
00D400  1  D0 F1              BNE   LC_loop           ; loop if not all done
00D402  1               
00D402  1  F0 1F              BEQ   NoString          ; tidy up and exit, branch always
00D404  1               
00D404  1               ; perform UCASE$()
00D404  1               
00D404  1               LAB_UCASE
00D404  1  20 0C D3           JSR   LAB_EVST          ; evaluate string
00D407  1  85 AC              STA   str_ln            ; set string length
00D409  1  A8                 TAY                     ; copy length to Y
00D40A  1  F0 17              BEQ   NoString          ; branch if null string
00D40C  1               
00D40C  1  20 09 D1           JSR   LAB_MSSP          ; make string space A bytes long A=length,
00D40F  1                                             ; X=Sutill=ptr low byte, Y=Sutilh=ptr high byte
00D40F  1  86 AD              STX   str_pl            ; save string pointer low byte
00D411  1  84 AE              STY   str_ph            ; save string pointer high byte
00D413  1  A8                 TAY                     ; get string length back
00D414  1               
00D414  1               UC_loop
00D414  1  88                 DEY                     ; decrement index
00D415  1  B1 71              LDA   (ut1_pl),Y        ; get byte from string
00D417  1  20 ED CD           JSR   LAB_CASC          ; is character "a" to "z" (or "A" to "Z")
00D41A  1  90 02              BCC   NoLcase           ; branch if not alpha
00D41C  1               
00D41C  1  29 DF              AND   #$DF              ; convert lower to upper case
00D41E  1               NoLcase
00D41E  1  91 83              STA   (Sutill),Y        ; save byte back to string
00D420  1  98                 TYA                     ; test index
00D421  1  D0 F1              BNE   UC_loop           ; loop if not all done
00D423  1               
00D423  1               NoString
00D423  1  4C 56 D1           JMP   LAB_RTST          ; check for space on descriptor stack then put string
00D426  1                                             ; address and length on descriptor stack and update stack
00D426  1                                             ; pointers
00D426  1               
00D426  1               ; perform SADD()
00D426  1               
00D426  1               LAB_SADD
00D426  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00D429  1  20 79 CD           JSR   LAB_GVAR          ; get var address
00D42C  1               
00D42C  1  20 BE CB           JSR   LAB_1BFB          ; scan for ")", else do syntax error then warm start
00D42F  1  20 A1 CA           JSR   LAB_CTST          ; check if source is string, else do type mismatch
00D432  1               
00D432  1  A0 02              LDY   #$02              ; index to string pointer high byte
00D434  1  B1 95              LDA   (Cvaral),Y        ; get string pointer high byte
00D436  1  AA                 TAX                     ; copy string pointer high byte to X
00D437  1  88                 DEY                     ; index to string pointer low byte
00D438  1  B1 95              LDA   (Cvaral),Y        ; get string pointer low byte
00D43A  1  A8                 TAY                     ; copy string pointer low byte to Y
00D43B  1  8A                 TXA                     ; copy string pointer high byte to A
00D43C  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00D43F  1               
00D43F  1               ; perform LEN()
00D43F  1               
00D43F  1               LAB_LENS
00D43F  1  20 45 D4           JSR   LAB_ESGL          ; evaluate string, get length in A (and Y)
00D442  1  4C 35 D0           JMP   LAB_1FD0          ; convert Y to byte in FAC1 and return
00D445  1               
00D445  1               ; evaluate string, get length in Y
00D445  1               
00D445  1               LAB_ESGL
00D445  1  20 0C D3           JSR   LAB_EVST          ; evaluate string
00D448  1  A8                 TAY                     ; copy length to Y
00D449  1  60                 RTS
00D44A  1               
00D44A  1               ; perform ASC()
00D44A  1               
00D44A  1               LAB_ASC
00D44A  1  20 45 D4           JSR   LAB_ESGL          ; evaluate string, get length in A (and Y)
00D44D  1  F0 08              BEQ   LAB_23A8          ; if null do function call error then warm start
00D44F  1               
00D44F  1  A0 00              LDY   #$00              ; set index to first character
00D451  1  B1 71              LDA   (ut1_pl),Y        ; get byte
00D453  1  A8                 TAY                     ; copy to Y
00D454  1  4C 35 D0           JMP   LAB_1FD0          ; convert Y to byte in FAC1 and return
00D457  1               
00D457  1               ; do function call error then warm start
00D457  1               
00D457  1               LAB_23A8
00D457  1  4C F8 CE           JMP   LAB_FCER          ; do function call error then warm start
00D45A  1               
00D45A  1               ; scan and get byte parameter
00D45A  1               
00D45A  1               LAB_SGBY
00D45A  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00D45D  1               
00D45D  1               ; get byte parameter
00D45D  1               
00D45D  1               LAB_GTBY
00D45D  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00D460  1                                             ; else do type mismatch
00D460  1               
00D460  1               ; evaluate byte expression, result in X
00D460  1               
00D460  1               LAB_EVBY
00D460  1  20 71 CE           JSR   LAB_EVPI          ; evaluate integer expression (no check)
00D463  1               
00D463  1  A4 AE              LDY   FAC1_2            ; get FAC1 mantissa2
00D465  1  D0 F0              BNE   LAB_23A8          ; if top byte <> 0 do function call error then warm start
00D467  1               
00D467  1  A6 AF              LDX   FAC1_3            ; get FAC1 mantissa3
00D469  1  4C C2 00           JMP   LAB_GBYT          ; scan memory and return
00D46C  1               
00D46C  1               ; perform VAL()
00D46C  1               
00D46C  1               LAB_VAL
00D46C  1  20 45 D4           JSR   LAB_ESGL          ; evaluate string, get length in A (and Y)
00D46F  1  D0 03              BNE   LAB_23C5          ; branch if not null string
00D471  1               
00D471  1                                             ; string was null so set result = $00
00D471  1  4C 21 D6           JMP   LAB_24F1          ; clear FAC1 exponent and sign and return
00D474  1               
00D474  1               LAB_23C5
00D474  1  A6 C3              LDX   Bpntrl            ; get BASIC execute pointer low byte
00D476  1  A4 C4              LDY   Bpntrh            ; get BASIC execute pointer high byte
00D478  1  86 BA              STX   Btmpl             ; save BASIC execute pointer low byte
00D47A  1  84 BB              STY   Btmph             ; save BASIC execute pointer high byte
00D47C  1  A6 71              LDX   ut1_pl            ; get string pointer low byte
00D47E  1  86 C3              STX   Bpntrl            ; save as BASIC execute pointer low byte
00D480  1  18                 CLC                     ; clear carry
00D481  1  65 71              ADC   ut1_pl            ; add string length
00D483  1  85 73              STA   ut2_pl            ; save string end low byte
00D485  1  A5 72              LDA   ut1_ph            ; get string pointer high byte
00D487  1  85 C4              STA   Bpntrh            ; save as BASIC execute pointer high byte
00D489  1  69 00              ADC   #$00              ; add carry to high byte
00D48B  1  85 74              STA   ut2_ph            ; save string end high byte
00D48D  1  A0 00              LDY   #$00              ; set index to $00
00D48F  1  B1 73              LDA   (ut2_pl),Y        ; get string end +1 byte
00D491  1  48                 PHA                     ; push it
00D492  1  98                 TYA                     ; clear A
00D493  1  91 73              STA   (ut2_pl),Y        ; terminate string with $00
00D495  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00D498  1  20 77 D9           JSR   LAB_2887          ; get FAC1 from string
00D49B  1  68                 PLA                     ; restore string end +1 byte
00D49C  1  A0 00              LDY   #$00              ; set index to zero
00D49E  1  91 73              STA   (ut2_pl),Y        ; put string end byte back
00D4A0  1               
00D4A0  1               ; restore BASIC execute pointer from temp (Btmpl/Btmph)
00D4A0  1               
00D4A0  1               LAB_23F3
00D4A0  1  A6 BA              LDX   Btmpl             ; get BASIC execute pointer low byte back
00D4A2  1  A4 BB              LDY   Btmph             ; get BASIC execute pointer high byte back
00D4A4  1  86 C3              STX   Bpntrl            ; save BASIC execute pointer low byte
00D4A6  1  84 C4              STY   Bpntrh            ; save BASIC execute pointer high byte
00D4A8  1  60                 RTS
00D4A9  1               
00D4A9  1               ; get two parameters for POKE or WAIT
00D4A9  1               
00D4A9  1               LAB_GADB
00D4A9  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00D4AC  1                                             ; else do type mismatch
00D4AC  1  20 C2 D4           JSR   LAB_F2FX          ; save integer part of FAC1 in temporary integer
00D4AF  1               
00D4AF  1               ; scan for "," and get byte, else do Syntax error then warm start
00D4AF  1               
00D4AF  1               LAB_SCGB
00D4AF  1  20 CD CB           JSR   LAB_1C01          ; scan for "," , else do syntax error then warm start
00D4B2  1  A5 12              LDA   Itemph            ; save temporary integer high byte
00D4B4  1  48                 PHA                     ; on stack
00D4B5  1  A5 11              LDA   Itempl            ; save temporary integer low byte
00D4B7  1  48                 PHA                     ; on stack
00D4B8  1  20 5D D4           JSR   LAB_GTBY          ; get byte parameter
00D4BB  1  68                 PLA                     ; pull low byte
00D4BC  1  85 11              STA   Itempl            ; restore temporary integer low byte
00D4BE  1  68                 PLA                     ; pull high byte
00D4BF  1  85 12              STA   Itemph            ; restore temporary integer high byte
00D4C1  1  60                 RTS
00D4C2  1               
00D4C2  1               ; convert float to fixed routine. accepts any value that fits in 24 bits, +ve or
00D4C2  1               ; -ve and converts it into a right truncated integer in Itempl and Itemph
00D4C2  1               
00D4C2  1               ; save unsigned 16 bit integer part of FAC1 in temporary integer
00D4C2  1               
00D4C2  1               LAB_F2FX
00D4C2  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00D4C4  1  C9 98              CMP   #$98              ; compare with exponent = 2^24
00D4C6  1  B0 8F              BCS   LAB_23A8          ; if >= do function call error then warm start
00D4C8  1               
00D4C8  1               LAB_F2FU
00D4C8  1  20 21 D9           JSR   LAB_2831          ; convert FAC1 floating-to-fixed
00D4CB  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00D4CD  1  A4 AF              LDY   FAC1_3            ; get FAC1 mantissa3
00D4CF  1  84 11              STY   Itempl            ; save temporary integer low byte
00D4D1  1  85 12              STA   Itemph            ; save temporary integer high byte
00D4D3  1  60                 RTS
00D4D4  1               
00D4D4  1               ; perform PEEK()
00D4D4  1               
00D4D4  1               LAB_PEEK
00D4D4  1  20 C2 D4           JSR   LAB_F2FX          ; save integer part of FAC1 in temporary integer
00D4D7  1  A2 00              LDX   #$00              ; clear index
00D4D9  1  A1 11              LDA   (Itempl,X)        ; get byte via temporary integer (addr)
00D4DB  1  A8                 TAY                     ; copy byte to Y
00D4DC  1  4C 35 D0           JMP   LAB_1FD0          ; convert Y to byte in FAC1 and return
00D4DF  1               
00D4DF  1               ; perform POKE
00D4DF  1               
00D4DF  1               LAB_POKE
00D4DF  1  20 A9 D4           JSR   LAB_GADB          ; get two parameters for POKE or WAIT
00D4E2  1  8A                 TXA                     ; copy byte argument to A
00D4E3  1  A2 00              LDX   #$00              ; clear index
00D4E5  1  81 11              STA   (Itempl,X)        ; save byte via temporary integer (addr)
00D4E7  1  60                 RTS
00D4E8  1               
00D4E8  1               ; perform DEEK()
00D4E8  1               
00D4E8  1               LAB_DEEK
00D4E8  1  20 C2 D4           JSR   LAB_F2FX          ; save integer part of FAC1 in temporary integer
00D4EB  1  A2 00              LDX   #$00              ; clear index
00D4ED  1  A1 11              LDA   (Itempl,X)        ; PEEK low byte
00D4EF  1  A8                 TAY                     ; copy to Y
00D4F0  1  E6 11              INC   Itempl            ; increment pointer low byte
00D4F2  1  D0 02              BNE   Deekh             ; skip high increment if no rollover
00D4F4  1               
00D4F4  1  E6 12              INC   Itemph            ; increment pointer high byte
00D4F6  1               Deekh
00D4F6  1  A1 11              LDA   (Itempl,X)        ; PEEK high byte
00D4F8  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00D4FB  1               
00D4FB  1               ; perform DOKE
00D4FB  1               
00D4FB  1               LAB_DOKE
00D4FB  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00D4FE  1                                             ; else do type mismatch
00D4FE  1  20 C2 D4           JSR   LAB_F2FX          ; convert floating-to-fixed
00D501  1               
00D501  1  84 97              STY   Frnxtl            ; save pointer low byte (float to fixed returns word in AY)
00D503  1  85 98              STA   Frnxth            ; save pointer high byte
00D505  1               
00D505  1  20 CD CB           JSR   LAB_1C01          ; scan for "," , else do syntax error then warm start
00D508  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00D50B  1                                             ; else do type mismatch
00D50B  1  20 C2 D4           JSR   LAB_F2FX          ; convert floating-to-fixed
00D50E  1               
00D50E  1  98                 TYA                     ; copy value low byte (float to fixed returns word in AY)
00D50F  1  A2 00              LDX   #$00              ; clear index
00D511  1  81 97              STA   (Frnxtl,X)        ; POKE low byte
00D513  1  E6 97              INC   Frnxtl            ; increment pointer low byte
00D515  1  D0 02              BNE   Dokeh             ; skip high increment if no rollover
00D517  1               
00D517  1  E6 98              INC   Frnxth            ; increment pointer high byte
00D519  1               Dokeh
00D519  1  A5 12              LDA   Itemph            ; get value high byte
00D51B  1  81 97              STA   (Frnxtl,X)        ; POKE high byte
00D51D  1  4C C2 00           JMP   LAB_GBYT          ; scan memory and return
00D520  1               
00D520  1               ; perform SWAP
00D520  1               
00D520  1               LAB_SWAP
00D520  1  20 79 CD           JSR   LAB_GVAR          ; get var1 address
00D523  1  85 97              STA   Lvarpl            ; save var1 address low byte
00D525  1  84 98              STY   Lvarph            ; save var1 address high byte
00D527  1  A5 5F              LDA   Dtypef            ; get data type flag, $FF=string, $00=numeric
00D529  1  48                 PHA                     ; save data type flag
00D52A  1               
00D52A  1  20 CD CB           JSR   LAB_1C01          ; scan for "," , else do syntax error then warm start
00D52D  1  20 79 CD           JSR   LAB_GVAR          ; get var2 address (pointer in Cvaral/h)
00D530  1  68                 PLA                     ; pull var1 data type flag
00D531  1  45 5F              EOR   Dtypef            ; compare with var2 data type
00D533  1  10 10              BPL   SwapErr           ; exit if not both the same type
00D535  1               
00D535  1  A0 03              LDY   #$03              ; four bytes to swap (either value or descriptor+1)
00D537  1               SwapLp
00D537  1  B1 97              LDA   (Lvarpl),Y        ; get byte from var1
00D539  1  AA                 TAX                     ; save var1 byte
00D53A  1  B1 95              LDA   (Cvaral),Y        ; get byte from var2
00D53C  1  91 97              STA   (Lvarpl),Y        ; save byte to var1
00D53E  1  8A                 TXA                     ; restore var1 byte
00D53F  1  91 95              STA   (Cvaral),Y        ; save byte to var2
00D541  1  88                 DEY                     ; decrement index
00D542  1  10 F3              BPL   SwapLp            ; loop until done
00D544  1               
00D544  1  60                 RTS
00D545  1               
00D545  1               SwapErr
00D545  1  4C AB CA           JMP   LAB_1ABC          ; do "Type mismatch" error then warm start
00D548  1               
00D548  1               ; perform CALL
00D548  1               
00D548  1               LAB_CALL
00D548  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00D54B  1                                             ; else do type mismatch
00D54B  1  20 C2 D4           JSR   LAB_F2FX          ; convert floating-to-fixed
00D54E  1  A9 D5              LDA   #>CallExit        ; set return address high byte
00D550  1  48                 PHA                     ; put on stack
00D551  1  A9 56              LDA   #<CallExit-1      ; set return address low byte
00D553  1  48                 PHA                     ; put on stack
00D554  1  6C 11 00           JMP   (Itempl)          ; do indirect jump to user routine
00D557  1               
00D557  1               ; if the called routine exits correctly then it will return to here. this will then get
00D557  1               ; the next byte for the interpreter and return
00D557  1               
00D557  1               CallExit
00D557  1  4C C2 00           JMP   LAB_GBYT          ; scan memory and return
00D55A  1               
00D55A  1               ; perform WAIT
00D55A  1               
00D55A  1               LAB_WAIT
00D55A  1  20 A9 D4           JSR   LAB_GADB          ; get two parameters for POKE or WAIT
00D55D  1  86 97              STX   Frnxtl            ; save byte
00D55F  1  A2 00              LDX   #$00              ; clear mask
00D561  1  20 C2 00           JSR   LAB_GBYT          ; scan memory
00D564  1  F0 03              BEQ   LAB_2441          ; skip if no third argument
00D566  1               
00D566  1  20 AF D4           JSR   LAB_SCGB          ; scan for "," and get byte, else SN error then warm start
00D569  1               LAB_2441
00D569  1  86 98              STX   Frnxth            ; save EOR argument
00D56B  1               LAB_2445
00D56B  1  B1 11              LDA   (Itempl),Y        ; get byte via temporary integer (addr)
00D56D  1  45 98              EOR   Frnxth            ; EOR with second argument (mask)
00D56F  1  25 97              AND   Frnxtl            ; AND with first argument (byte)
00D571  1  F0 F8              BEQ   LAB_2445          ; loop if result is zero
00D573  1               
00D573  1               LAB_244D
00D573  1  60                 RTS
00D574  1               
00D574  1               ; perform subtraction, FAC1 from (AY)
00D574  1               
00D574  1               LAB_2455
00D574  1  20 5C D7           JSR   LAB_264D          ; unpack memory (AY) into FAC2
00D577  1               
00D577  1               ; perform subtraction, FAC1 from FAC2
00D577  1               
00D577  1               LAB_SUBTRACT
00D577  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00D579  1  49 FF              EOR   #$FF              ; complement it
00D57B  1  85 B0              STA   FAC1_s            ; save FAC1 sign (b7)
00D57D  1  45 B7              EOR   FAC2_s            ; EOR with FAC2 sign (b7)
00D57F  1  85 B8              STA   FAC_sc            ; save sign compare (FAC1 EOR FAC2)
00D581  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00D583  1  4C 92 D5           JMP   LAB_ADD           ; go add FAC2 to FAC1
00D586  1               
00D586  1               ; perform addition
00D586  1               
00D586  1               LAB_2467
00D586  1  20 AB D6           JSR   LAB_257B          ; shift FACX A times right (>8 shifts)
00D589  1  90 4D              BCC   LAB_24A8          ;.go subtract mantissas
00D58B  1               
00D58B  1               ; add 0.5 to FAC1
00D58B  1               
00D58B  1               LAB_244E
00D58B  1  A9 D2              LDA   #<LAB_2A96        ; set 0.5 pointer low byte
00D58D  1  A0 E1              LDY   #>LAB_2A96        ; set 0.5 pointer high byte
00D58F  1               
00D58F  1               ; add (AY) to FAC1
00D58F  1               
00D58F  1               LAB_246C
00D58F  1  20 5C D7           JSR   LAB_264D          ; unpack memory (AY) into FAC2
00D592  1               
00D592  1               ; add FAC2 to FAC1
00D592  1               
00D592  1               LAB_ADD
00D592  1  D0 10              BNE   LAB_2474          ; branch if FAC1 was not zero
00D594  1               
00D594  1               ; copy FAC2 to FAC1
00D594  1               
00D594  1               LAB_279B
00D594  1  A5 B7              LDA   FAC2_s            ; get FAC2 sign (b7)
00D596  1               
00D596  1               ; save FAC1 sign and copy ABS(FAC2) to FAC1
00D596  1               
00D596  1               LAB_279D
00D596  1  85 B0              STA   FAC1_s            ; save FAC1 sign (b7)
00D598  1  A2 04              LDX   #$04              ; 4 bytes to copy
00D59A  1               LAB_27A1
00D59A  1  B5 B2              LDA   FAC1_o,X          ; get byte from FAC2,X
00D59C  1  95 AB              STA   FAC1_e-1,X        ; save byte at FAC1,X
00D59E  1  CA                 DEX                     ; decrement count
00D59F  1  D0 F9              BNE   LAB_27A1          ; loop if not all done
00D5A1  1               
00D5A1  1  86 B9              STX   FAC1_r            ; clear FAC1 rounding byte
00D5A3  1  60                 RTS
00D5A4  1               
00D5A4  1                                             ; FAC1 is non zero
00D5A4  1               LAB_2474
00D5A4  1  A6 B9              LDX   FAC1_r            ; get FAC1 rounding byte
00D5A6  1  86 A3              STX   FAC2_r            ; save as FAC2 rounding byte
00D5A8  1  A2 B3              LDX   #FAC2_e           ; set index to FAC2 exponent addr
00D5AA  1  A5 B3              LDA   FAC2_e            ; get FAC2 exponent
00D5AC  1               LAB_247C
00D5AC  1  A8                 TAY                     ; copy exponent
00D5AD  1  F0 C4              BEQ   LAB_244D          ; exit if zero
00D5AF  1               
00D5AF  1  38                 SEC                     ; set carry for subtract
00D5B0  1  E5 AC              SBC   FAC1_e            ; subtract FAC1 exponent
00D5B2  1  F0 24              BEQ   LAB_24A8          ; branch if = (go add mantissa)
00D5B4  1               
00D5B4  1  90 12              BCC   LAB_2498          ; branch if <
00D5B6  1               
00D5B6  1                                             ; FAC2>FAC1
00D5B6  1  84 AC              STY   FAC1_e            ; save FAC1 exponent
00D5B8  1  A4 B7              LDY   FAC2_s            ; get FAC2 sign (b7)
00D5BA  1  84 B0              STY   FAC1_s            ; save FAC1 sign (b7)
00D5BC  1  49 FF              EOR   #$FF              ; complement A
00D5BE  1  69 00              ADC   #$00              ; +1 (twos complement, carry is set)
00D5C0  1  A0 00              LDY   #$00              ; clear Y
00D5C2  1  84 A3              STY   FAC2_r            ; clear FAC2 rounding byte
00D5C4  1  A2 AC              LDX   #FAC1_e           ; set index to FAC1 exponent addr
00D5C6  1  D0 04              BNE   LAB_249C          ; branch always
00D5C8  1               
00D5C8  1               LAB_2498
00D5C8  1  A0 00              LDY   #$00              ; clear Y
00D5CA  1  84 B9              STY   FAC1_r            ; clear FAC1 rounding byte
00D5CC  1               LAB_249C
00D5CC  1  C9 F9              CMP   #$F9              ; compare exponent diff with $F9
00D5CE  1  30 B6              BMI   LAB_2467          ; branch if range $79-$F8
00D5D0  1               
00D5D0  1  A8                 TAY                     ; copy exponent difference to Y
00D5D1  1  A5 B9              LDA   FAC1_r            ; get FAC1 rounding byte
00D5D3  1  56 01              LSR   PLUS_1,X          ; shift FAC? mantissa1
00D5D5  1  20 C2 D6           JSR   LAB_2592          ; shift FACX Y times right
00D5D8  1               
00D5D8  1                                             ; exponents are equal now do mantissa subtract
00D5D8  1               LAB_24A8
00D5D8  1  24 B8              BIT   FAC_sc            ; test sign compare (FAC1 EOR FAC2)
00D5DA  1  10 4C              BPL   LAB_24F8          ; if = add FAC2 mantissa to FAC1 mantissa and return
00D5DC  1               
00D5DC  1  A0 AC              LDY   #FAC1_e           ; set index to FAC1 exponent addr
00D5DE  1  E0 B3              CPX   #FAC2_e           ; compare X to FAC2 exponent addr
00D5E0  1  F0 02              BEQ   LAB_24B4          ; branch if =
00D5E2  1               
00D5E2  1  A0 B3              LDY   #FAC2_e           ; else set index to FAC2 exponent addr
00D5E4  1               
00D5E4  1                                             ; subtract smaller from bigger (take sign of bigger)
00D5E4  1               LAB_24B4
00D5E4  1  38                 SEC                     ; set carry for subtract
00D5E5  1  49 FF              EOR   #$FF              ; ones complement A
00D5E7  1  65 A3              ADC   FAC2_r            ; add FAC2 rounding byte
00D5E9  1  85 B9              STA   FAC1_r            ; save FAC1 rounding byte
00D5EB  1  B9 03 00           LDA   PLUS_3,Y          ; get FACY mantissa3
00D5EE  1  F5 03              SBC   PLUS_3,X          ; subtract FACX mantissa3
00D5F0  1  85 AF              STA   FAC1_3            ; save FAC1 mantissa3
00D5F2  1  B9 02 00           LDA   PLUS_2,Y          ; get FACY mantissa2
00D5F5  1  F5 02              SBC   PLUS_2,X          ; subtract FACX mantissa2
00D5F7  1  85 AE              STA   FAC1_2            ; save FAC1 mantissa2
00D5F9  1  B9 01 00           LDA   PLUS_1,Y          ; get FACY mantissa1
00D5FC  1  F5 01              SBC   PLUS_1,X          ; subtract FACX mantissa1
00D5FE  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00D600  1               
00D600  1               ; do ABS and normalise FAC1
00D600  1               
00D600  1               LAB_24D0
00D600  1  B0 03              BCS   LAB_24D5          ; branch if number is +ve
00D602  1               
00D602  1  20 67 D6           JSR   LAB_2537          ; negate FAC1
00D605  1               
00D605  1               ; normalise FAC1
00D605  1               
00D605  1               LAB_24D5
00D605  1  A0 00              LDY   #$00              ; clear Y
00D607  1  98                 TYA                     ; clear A
00D608  1  18                 CLC                     ; clear carry for add
00D609  1               LAB_24D9
00D609  1  A6 AD              LDX   FAC1_1            ; get FAC1 mantissa1
00D60B  1  D0 3E              BNE   LAB_251B          ; if not zero normalise FAC1
00D60D  1               
00D60D  1  A6 AE              LDX   FAC1_2            ; get FAC1 mantissa2
00D60F  1  86 AD              STX   FAC1_1            ; save FAC1 mantissa1
00D611  1  A6 AF              LDX   FAC1_3            ; get FAC1 mantissa3
00D613  1  86 AE              STX   FAC1_2            ; save FAC1 mantissa2
00D615  1  A6 B9              LDX   FAC1_r            ; get FAC1 rounding byte
00D617  1  86 AF              STX   FAC1_3            ; save FAC1 mantissa3
00D619  1  84 B9              STY   FAC1_r            ; clear FAC1 rounding byte
00D61B  1  69 08              ADC   #$08              ; add x to exponent offset
00D61D  1  C9 18              CMP   #$18              ; compare with $18 (max offset, all bits would be =0)
00D61F  1  D0 E8              BNE   LAB_24D9          ; loop if not max
00D621  1               
00D621  1               ; clear FAC1 exponent and sign
00D621  1               
00D621  1               LAB_24F1
00D621  1  A9 00              LDA   #$00              ; clear A
00D623  1               LAB_24F3
00D623  1  85 AC              STA   FAC1_e            ; set FAC1 exponent
00D625  1               
00D625  1               ; save FAC1 sign
00D625  1               
00D625  1               LAB_24F5
00D625  1  85 B0              STA   FAC1_s            ; save FAC1 sign (b7)
00D627  1  60                 RTS
00D628  1               
00D628  1               ; add FAC2 mantissa to FAC1 mantissa
00D628  1               
00D628  1               LAB_24F8
00D628  1  65 A3              ADC   FAC2_r            ; add FAC2 rounding byte
00D62A  1  85 B9              STA   FAC1_r            ; save FAC1 rounding byte
00D62C  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00D62E  1  65 B6              ADC   FAC2_3            ; add FAC2 mantissa3
00D630  1  85 AF              STA   FAC1_3            ; save FAC1 mantissa3
00D632  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00D634  1  65 B5              ADC   FAC2_2            ; add FAC2 mantissa2
00D636  1  85 AE              STA   FAC1_2            ; save FAC1 mantissa2
00D638  1  A5 AD              LDA   FAC1_1            ; get FAC1 mantissa1
00D63A  1  65 B4              ADC   FAC2_1            ; add FAC2 mantissa1
00D63C  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00D63E  1  B0 1A              BCS   LAB_252A          ; if carry then normalise FAC1 for C=1
00D640  1               
00D640  1  60                 RTS                     ; else just exit
00D641  1               
00D641  1               LAB_2511
00D641  1  69 01              ADC   #$01              ; add 1 to exponent offset
00D643  1  06 B9              ASL   FAC1_r            ; shift FAC1 rounding byte
00D645  1  26 AF              ROL   FAC1_3            ; shift FAC1 mantissa3
00D647  1  26 AE              ROL   FAC1_2            ; shift FAC1 mantissa2
00D649  1  26 AD              ROL   FAC1_1            ; shift FAC1 mantissa1
00D64B  1               
00D64B  1               ; normalise FAC1
00D64B  1               
00D64B  1               LAB_251B
00D64B  1  10 F4              BPL   LAB_2511          ; loop if not normalised
00D64D  1               
00D64D  1  38                 SEC                     ; set carry for subtract
00D64E  1  E5 AC              SBC   FAC1_e            ; subtract FAC1 exponent
00D650  1  B0 CF              BCS   LAB_24F1          ; branch if underflow (set result = $0)
00D652  1               
00D652  1  49 FF              EOR   #$FF              ; complement exponent
00D654  1  69 01              ADC   #$01              ; +1 (twos complement)
00D656  1  85 AC              STA   FAC1_e            ; save FAC1 exponent
00D658  1               
00D658  1               ; test and normalise FAC1 for C=0/1
00D658  1               
00D658  1               LAB_2528
00D658  1  90 0C              BCC   LAB_2536          ; exit if no overflow
00D65A  1               
00D65A  1               ; normalise FAC1 for C=1
00D65A  1               
00D65A  1               LAB_252A
00D65A  1  E6 AC              INC   FAC1_e            ; increment FAC1 exponent
00D65C  1  F0 36              BEQ   LAB_2564          ; if zero do overflow error and warm start
00D65E  1               
00D65E  1  66 AD              ROR   FAC1_1            ; shift FAC1 mantissa1
00D660  1  66 AE              ROR   FAC1_2            ; shift FAC1 mantissa2
00D662  1  66 AF              ROR   FAC1_3            ; shift FAC1 mantissa3
00D664  1  66 B9              ROR   FAC1_r            ; shift FAC1 rounding byte
00D666  1               LAB_2536
00D666  1  60                 RTS
00D667  1               
00D667  1               ; negate FAC1
00D667  1               
00D667  1               LAB_2537
00D667  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00D669  1  49 FF              EOR   #$FF              ; complement it
00D66B  1  85 B0              STA   FAC1_s            ; save FAC1 sign (b7)
00D66D  1               
00D66D  1               ; twos complement FAC1 mantissa
00D66D  1               
00D66D  1               LAB_253D
00D66D  1  A5 AD              LDA   FAC1_1            ; get FAC1 mantissa1
00D66F  1  49 FF              EOR   #$FF              ; complement it
00D671  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00D673  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00D675  1  49 FF              EOR   #$FF              ; complement it
00D677  1  85 AE              STA   FAC1_2            ; save FAC1 mantissa2
00D679  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00D67B  1  49 FF              EOR   #$FF              ; complement it
00D67D  1  85 AF              STA   FAC1_3            ; save FAC1 mantissa3
00D67F  1  A5 B9              LDA   FAC1_r            ; get FAC1 rounding byte
00D681  1  49 FF              EOR   #$FF              ; complement it
00D683  1  85 B9              STA   FAC1_r            ; save FAC1 rounding byte
00D685  1  E6 B9              INC   FAC1_r            ; increment FAC1 rounding byte
00D687  1  D0 0A              BNE   LAB_2563          ; exit if no overflow
00D689  1               
00D689  1               ; increment FAC1 mantissa
00D689  1               
00D689  1               LAB_2559
00D689  1  E6 AF              INC   FAC1_3            ; increment FAC1 mantissa3
00D68B  1  D0 06              BNE   LAB_2563          ; finished if no rollover
00D68D  1               
00D68D  1  E6 AE              INC   FAC1_2            ; increment FAC1 mantissa2
00D68F  1  D0 02              BNE   LAB_2563          ; finished if no rollover
00D691  1               
00D691  1  E6 AD              INC   FAC1_1            ; increment FAC1 mantissa1
00D693  1               LAB_2563
00D693  1  60                 RTS
00D694  1               
00D694  1               ; do overflow error (overflow exit)
00D694  1               
00D694  1               LAB_2564
00D694  1  A2 0A              LDX   #$0A              ; error code $0A ("Overflow" error)
00D696  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00D699  1               
00D699  1               ; shift FCAtemp << A+8 times
00D699  1               
00D699  1               LAB_2569
00D699  1  A2 74              LDX   #FACt_1-1         ; set offset to FACtemp
00D69B  1               LAB_256B
00D69B  1  B4 03              LDY   PLUS_3,X          ; get FACX mantissa3
00D69D  1  84 B9              STY   FAC1_r            ; save as FAC1 rounding byte
00D69F  1  B4 02              LDY   PLUS_2,X          ; get FACX mantissa2
00D6A1  1  94 03              STY   PLUS_3,X          ; save FACX mantissa3
00D6A3  1  B4 01              LDY   PLUS_1,X          ; get FACX mantissa1
00D6A5  1  94 02              STY   PLUS_2,X          ; save FACX mantissa2
00D6A7  1  A4 B2              LDY   FAC1_o            ; get FAC1 overflow byte
00D6A9  1  94 01              STY   PLUS_1,X          ; save FACX mantissa1
00D6AB  1               
00D6AB  1               ; shift FACX -A times right (> 8 shifts)
00D6AB  1               
00D6AB  1               LAB_257B
00D6AB  1  69 08              ADC   #$08              ; add 8 to shift count
00D6AD  1  30 EC              BMI   LAB_256B          ; go do 8 shift if still -ve
00D6AF  1               
00D6AF  1  F0 EA              BEQ   LAB_256B          ; go do 8 shift if zero
00D6B1  1               
00D6B1  1  E9 08              SBC   #$08              ; else subtract 8 again
00D6B3  1  A8                 TAY                     ; save count to Y
00D6B4  1  A5 B9              LDA   FAC1_r            ; get FAC1 rounding byte
00D6B6  1  B0 12              BCS   LAB_259A          ;.
00D6B8  1               
00D6B8  1               LAB_2588
00D6B8  1  16 01              ASL   PLUS_1,X          ; shift FACX mantissa1
00D6BA  1  90 02              BCC   LAB_258E          ; branch if +ve
00D6BC  1               
00D6BC  1  F6 01              INC   PLUS_1,X          ; this sets b7 eventually
00D6BE  1               LAB_258E
00D6BE  1  76 01              ROR   PLUS_1,X          ; shift FACX mantissa1 (correct for ASL)
00D6C0  1  76 01              ROR   PLUS_1,X          ; shift FACX mantissa1 (put carry in b7)
00D6C2  1               
00D6C2  1               ; shift FACX Y times right
00D6C2  1               
00D6C2  1               LAB_2592
00D6C2  1  76 02              ROR   PLUS_2,X          ; shift FACX mantissa2
00D6C4  1  76 03              ROR   PLUS_3,X          ; shift FACX mantissa3
00D6C6  1  6A                 ROR                     ; shift FACX rounding byte
00D6C7  1  C8                 INY                     ; increment exponent diff
00D6C8  1  D0 EE              BNE   LAB_2588          ; branch if range adjust not complete
00D6CA  1               
00D6CA  1               LAB_259A
00D6CA  1  18                 CLC                     ; just clear it
00D6CB  1  60                 RTS
00D6CC  1               
00D6CC  1               ; perform LOG()
00D6CC  1               
00D6CC  1               LAB_LOG
00D6CC  1  20 BA D8           JSR   LAB_27CA          ; test sign and zero
00D6CF  1  F0 02              BEQ   LAB_25C4          ; if zero do function call error then warm start
00D6D1  1               
00D6D1  1  10 03              BPL   LAB_25C7          ; skip error if +ve
00D6D3  1               
00D6D3  1               LAB_25C4
00D6D3  1  4C F8 CE           JMP   LAB_FCER          ; do function call error then warm start (-ve)
00D6D6  1               
00D6D6  1               LAB_25C7
00D6D6  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00D6D8  1  E9 7F              SBC   #$7F              ; normalise it
00D6DA  1  48                 PHA                     ; save it
00D6DB  1  A9 80              LDA   #$80              ; set exponent to zero
00D6DD  1  85 AC              STA   FAC1_e            ; save FAC1 exponent
00D6DF  1  A9 52              LDA   #<LAB_25AD        ; set 1/root2 pointer low byte
00D6E1  1  A0 E1              LDY   #>LAB_25AD        ; set 1/root2 pointer high byte
00D6E3  1  20 8F D5           JSR   LAB_246C          ; add (AY) to FAC1 (1/root2)
00D6E6  1  A9 56              LDA   #<LAB_25B1        ; set root2 pointer low byte
00D6E8  1  A0 E1              LDY   #>LAB_25B1        ; set root2 pointer high byte
00D6EA  1  20 D2 D7           JSR   LAB_26CA          ; convert AY and do (AY)/FAC1 (root2/(x+(1/root2)))
00D6ED  1  A9 C9              LDA   #<LAB_259C        ; set 1 pointer low byte
00D6EF  1  A0 E1              LDY   #>LAB_259C        ; set 1 pointer high byte
00D6F1  1  20 74 D5           JSR   LAB_2455          ; subtract (AY) from FAC1 ((root2/(x+(1/root2)))-1)
00D6F4  1  A9 45              LDA   #<LAB_25A0        ; set pointer low byte to counter
00D6F6  1  A0 E1              LDY   #>LAB_25A0        ; set pointer high byte to counter
00D6F8  1  20 22 DC           JSR   LAB_2B6E          ; ^2 then series evaluation
00D6FB  1  A9 5A              LDA   #<LAB_25B5        ; set -0.5 pointer low byte
00D6FD  1  A0 E1              LDY   #>LAB_25B5        ; set -0.5 pointer high byte
00D6FF  1  20 8F D5           JSR   LAB_246C          ; add (AY) to FAC1
00D702  1  68                 PLA                     ; restore FAC1 exponent
00D703  1  20 16 DA           JSR   LAB_2912          ; evaluate new ASCII digit
00D706  1  A9 5E              LDA   #<LAB_25B9        ; set LOG(2) pointer low byte
00D708  1  A0 E1              LDY   #>LAB_25B9        ; set LOG(2) pointer high byte
00D70A  1               
00D70A  1               ; do convert AY, FCA1*(AY)
00D70A  1               
00D70A  1               LAB_25FB
00D70A  1  20 5C D7           JSR   LAB_264D          ; unpack memory (AY) into FAC2
00D70D  1               LAB_MULTIPLY
00D70D  1  F0 4C              BEQ   LAB_264C          ; exit if zero
00D70F  1               
00D70F  1  20 82 D7           JSR   LAB_2673          ; test and adjust accumulators
00D712  1  A9 00              LDA   #$00              ; clear A
00D714  1  85 75              STA   FACt_1            ; clear temp mantissa1
00D716  1  85 76              STA   FACt_2            ; clear temp mantissa2
00D718  1  85 77              STA   FACt_3            ; clear temp mantissa3
00D71A  1  A5 B9              LDA   FAC1_r            ; get FAC1 rounding byte
00D71C  1  20 31 D7           JSR   LAB_2622          ; go do shift/add FAC2
00D71F  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00D721  1  20 31 D7           JSR   LAB_2622          ; go do shift/add FAC2
00D724  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00D726  1  20 31 D7           JSR   LAB_2622          ; go do shift/add FAC2
00D729  1  A5 AD              LDA   FAC1_1            ; get FAC1 mantissa1
00D72B  1  20 36 D7           JSR   LAB_2627          ; go do shift/add FAC2
00D72E  1  4C 3F D8           JMP   LAB_273C          ; copy temp to FAC1, normalise and return
00D731  1               
00D731  1               LAB_2622
00D731  1  D0 03              BNE   LAB_2627          ; branch if byte <> zero
00D733  1               
00D733  1  4C 99 D6           JMP   LAB_2569          ; shift FCAtemp << A+8 times
00D736  1               
00D736  1                                             ; else do shift and add
00D736  1               LAB_2627
00D736  1  4A                 LSR                     ; shift byte
00D737  1  09 80              ORA   #$80              ; set top bit (mark for 8 times)
00D739  1               LAB_262A
00D739  1  A8                 TAY                     ; copy result
00D73A  1  90 13              BCC   LAB_2640          ; skip next if bit was zero
00D73C  1               
00D73C  1  18                 CLC                     ; clear carry for add
00D73D  1  A5 77              LDA   FACt_3            ; get temp mantissa3
00D73F  1  65 B6              ADC   FAC2_3            ; add FAC2 mantissa3
00D741  1  85 77              STA   FACt_3            ; save temp mantissa3
00D743  1  A5 76              LDA   FACt_2            ; get temp mantissa2
00D745  1  65 B5              ADC   FAC2_2            ; add FAC2 mantissa2
00D747  1  85 76              STA   FACt_2            ; save temp mantissa2
00D749  1  A5 75              LDA   FACt_1            ; get temp mantissa1
00D74B  1  65 B4              ADC   FAC2_1            ; add FAC2 mantissa1
00D74D  1  85 75              STA   FACt_1            ; save temp mantissa1
00D74F  1               LAB_2640
00D74F  1  66 75              ROR   FACt_1            ; shift temp mantissa1
00D751  1  66 76              ROR   FACt_2            ; shift temp mantissa2
00D753  1  66 77              ROR   FACt_3            ; shift temp mantissa3
00D755  1  66 B9              ROR   FAC1_r            ; shift temp rounding byte
00D757  1  98                 TYA                     ; get byte back
00D758  1  4A                 LSR                     ; shift byte
00D759  1  D0 DE              BNE   LAB_262A          ; loop if all bits not done
00D75B  1               
00D75B  1               LAB_264C
00D75B  1  60                 RTS
00D75C  1               
00D75C  1               ; unpack memory (AY) into FAC2
00D75C  1               
00D75C  1               LAB_264D
00D75C  1  85 71              STA   ut1_pl            ; save pointer low byte
00D75E  1  84 72              STY   ut1_ph            ; save pointer high byte
00D760  1  A0 03              LDY   #$03              ; 4 bytes to get (0-3)
00D762  1  B1 71              LDA   (ut1_pl),Y        ; get mantissa3
00D764  1  85 B6              STA   FAC2_3            ; save FAC2 mantissa3
00D766  1  88                 DEY                     ; decrement index
00D767  1  B1 71              LDA   (ut1_pl),Y        ; get mantissa2
00D769  1  85 B5              STA   FAC2_2            ; save FAC2 mantissa2
00D76B  1  88                 DEY                     ; decrement index
00D76C  1  B1 71              LDA   (ut1_pl),Y        ; get mantissa1+sign
00D76E  1  85 B7              STA   FAC2_s            ; save FAC2 sign (b7)
00D770  1  45 B0              EOR   FAC1_s            ; EOR with FAC1 sign (b7)
00D772  1  85 B8              STA   FAC_sc            ; save sign compare (FAC1 EOR FAC2)
00D774  1  A5 B7              LDA   FAC2_s            ; recover FAC2 sign (b7)
00D776  1  09 80              ORA   #$80              ; set 1xxx xxx (set normal bit)
00D778  1  85 B4              STA   FAC2_1            ; save FAC2 mantissa1
00D77A  1  88                 DEY                     ; decrement index
00D77B  1  B1 71              LDA   (ut1_pl),Y        ; get exponent byte
00D77D  1  85 B3              STA   FAC2_e            ; save FAC2 exponent
00D77F  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00D781  1  60                 RTS
00D782  1               
00D782  1               ; test and adjust accumulators
00D782  1               
00D782  1               LAB_2673
00D782  1  A5 B3              LDA   FAC2_e            ; get FAC2 exponent
00D784  1               LAB_2675
00D784  1  F0 1D              BEQ   LAB_2696          ; branch if FAC2 = $00 (handle underflow)
00D786  1               
00D786  1  18                 CLC                     ; clear carry for add
00D787  1  65 AC              ADC   FAC1_e            ; add FAC1 exponent
00D789  1  90 04              BCC   LAB_2680          ; branch if sum of exponents <$0100
00D78B  1               
00D78B  1  30 31              BMI   LAB_269B          ; do overflow error
00D78D  1               
00D78D  1  18                 CLC                     ; clear carry for the add
00D78E  1  2C                 .byte $2C               ; makes next line BIT $1410
00D78F  1               LAB_2680
00D78F  1  10 12              BPL   LAB_2696          ; if +ve go handle underflow
00D791  1               
00D791  1  69 80              ADC   #$80              ; adjust exponent
00D793  1  85 AC              STA   FAC1_e            ; save FAC1 exponent
00D795  1  D0 03              BNE   LAB_268B          ; branch if not zero
00D797  1               
00D797  1  4C 25 D6           JMP   LAB_24F5          ; save FAC1 sign and return
00D79A  1               
00D79A  1               LAB_268B
00D79A  1  A5 B8              LDA   FAC_sc            ; get sign compare (FAC1 EOR FAC2)
00D79C  1  85 B0              STA   FAC1_s            ; save FAC1 sign (b7)
00D79E  1               LAB_268F
00D79E  1  60                 RTS
00D79F  1               
00D79F  1               ; handle overflow and underflow
00D79F  1               
00D79F  1               LAB_2690
00D79F  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00D7A1  1  10 1B              BPL   LAB_269B          ; do overflow error
00D7A3  1               
00D7A3  1                                             ; handle underflow
00D7A3  1               LAB_2696
00D7A3  1  68                 PLA                     ; pop return address low byte
00D7A4  1  68                 PLA                     ; pop return address high byte
00D7A5  1  4C 21 D6           JMP   LAB_24F1          ; clear FAC1 exponent and sign and return
00D7A8  1               
00D7A8  1               ; multiply by 10
00D7A8  1               
00D7A8  1               LAB_269E
00D7A8  1  20 9B D8           JSR   LAB_27AB          ; round and copy FAC1 to FAC2
00D7AB  1  AA                 TAX                     ; copy exponent (set the flags)
00D7AC  1  F0 F0              BEQ   LAB_268F          ; exit if zero
00D7AE  1               
00D7AE  1  18                 CLC                     ; clear carry for add
00D7AF  1  69 02              ADC   #$02              ; add two to exponent (*4)
00D7B1  1  B0 0B              BCS   LAB_269B          ; do overflow error if > $FF
00D7B3  1               
00D7B3  1  A2 00              LDX   #$00              ; clear byte
00D7B5  1  86 B8              STX   FAC_sc            ; clear sign compare (FAC1 EOR FAC2)
00D7B7  1  20 AC D5           JSR   LAB_247C          ; add FAC2 to FAC1 (*5)
00D7BA  1  E6 AC              INC   FAC1_e            ; increment FAC1 exponent (*10)
00D7BC  1  D0 E0              BNE   LAB_268F          ; if non zero just do RTS
00D7BE  1               
00D7BE  1               LAB_269B
00D7BE  1  4C 94 D6           JMP   LAB_2564          ; do overflow error and warm start
00D7C1  1               
00D7C1  1               ; divide by 10
00D7C1  1               
00D7C1  1               LAB_26B9
00D7C1  1  20 9B D8           JSR   LAB_27AB          ; round and copy FAC1 to FAC2
00D7C4  1  A9 DA              LDA   #<LAB_26B5        ; set pointer to 10d low addr
00D7C6  1  A0 E1              LDY   #>LAB_26B5        ; set pointer to 10d high addr
00D7C8  1  A2 00              LDX   #$00              ; clear sign
00D7CA  1               
00D7CA  1               ; divide by (AY) (X=sign)
00D7CA  1               
00D7CA  1               LAB_26C2
00D7CA  1  86 B8              STX   FAC_sc            ; save sign compare (FAC1 EOR FAC2)
00D7CC  1  20 4E D8           JSR   LAB_UFAC          ; unpack memory (AY) into FAC1
00D7CF  1  4C D5 D7           JMP   LAB_DIVIDE        ; do FAC2/FAC1
00D7D2  1               
00D7D2  1                                             ; Perform divide-by
00D7D2  1               ; convert AY and do (AY)/FAC1
00D7D2  1               
00D7D2  1               LAB_26CA
00D7D2  1  20 5C D7           JSR   LAB_264D          ; unpack memory (AY) into FAC2
00D7D5  1               
00D7D5  1                                             ; Perform divide-into
00D7D5  1               LAB_DIVIDE
00D7D5  1  F0 63              BEQ   LAB_2737          ; if zero go do /0 error
00D7D7  1               
00D7D7  1  20 AA D8           JSR   LAB_27BA          ; round FAC1
00D7DA  1  A9 00              LDA   #$00              ; clear A
00D7DC  1  38                 SEC                     ; set carry for subtract
00D7DD  1  E5 AC              SBC   FAC1_e            ; subtract FAC1 exponent (2s complement)
00D7DF  1  85 AC              STA   FAC1_e            ; save FAC1 exponent
00D7E1  1  20 82 D7           JSR   LAB_2673          ; test and adjust accumulators
00D7E4  1  E6 AC              INC   FAC1_e            ; increment FAC1 exponent
00D7E6  1  F0 D6              BEQ   LAB_269B          ; if zero do overflow error
00D7E8  1               
00D7E8  1  A2 FF              LDX   #$FF              ; set index for pre increment
00D7EA  1  A9 01              LDA   #$01              ; set bit to flag byte save
00D7EC  1               LAB_26E4
00D7EC  1  A4 B4              LDY   FAC2_1            ; get FAC2 mantissa1
00D7EE  1  C4 AD              CPY   FAC1_1            ; compare FAC1 mantissa1
00D7F0  1  D0 0A              BNE   LAB_26F4          ; branch if <>
00D7F2  1               
00D7F2  1  A4 B5              LDY   FAC2_2            ; get FAC2 mantissa2
00D7F4  1  C4 AE              CPY   FAC1_2            ; compare FAC1 mantissa2
00D7F6  1  D0 04              BNE   LAB_26F4          ; branch if <>
00D7F8  1               
00D7F8  1  A4 B6              LDY   FAC2_3            ; get FAC2 mantissa3
00D7FA  1  C4 AF              CPY   FAC1_3            ; compare FAC1 mantissa3
00D7FC  1               LAB_26F4
00D7FC  1  08                 PHP                     ; save FAC2-FAC1 compare status
00D7FD  1  2A                 ROL                     ; shift the result byte
00D7FE  1  90 0E              BCC   LAB_2702          ; if no carry skip the byte save
00D800  1               
00D800  1  A0 01              LDY   #$01              ; set bit to flag byte save
00D802  1  E8                 INX                     ; else increment the index to FACt
00D803  1  E0 02              CPX   #$02              ; compare with the index to FACt_3
00D805  1  30 04              BMI   LAB_2701          ; if not last byte just go save it
00D807  1               
00D807  1  D0 28              BNE   LAB_272B          ; if all done go save FAC1 rounding byte, normalise and
00D809  1                                             ; return
00D809  1               
00D809  1  A0 40              LDY   #$40              ; set bit to flag byte save for the rounding byte
00D80B  1               LAB_2701
00D80B  1  95 75              STA   FACt_1,X          ; write result byte to FACt_1 + index
00D80D  1  98                 TYA                     ; copy the next save byte flag
00D80E  1               LAB_2702
00D80E  1  28                 PLP                     ; restore FAC2-FAC1 compare status
00D80F  1  90 14              BCC   LAB_2704          ; if FAC2 < FAC1 then skip the subtract
00D811  1               
00D811  1  A8                 TAY                     ; save FAC2-FAC1 compare status
00D812  1  A5 B6              LDA   FAC2_3            ; get FAC2 mantissa3
00D814  1  E5 AF              SBC   FAC1_3            ; subtract FAC1 mantissa3
00D816  1  85 B6              STA   FAC2_3            ; save FAC2 mantissa3
00D818  1  A5 B5              LDA   FAC2_2            ; get FAC2 mantissa2
00D81A  1  E5 AE              SBC   FAC1_2            ; subtract FAC1 mantissa2
00D81C  1  85 B5              STA   FAC2_2            ; save FAC2 mantissa2
00D81E  1  A5 B4              LDA   FAC2_1            ; get FAC2 mantissa1
00D820  1  E5 AD              SBC   FAC1_1            ; subtract FAC1 mantissa1
00D822  1  85 B4              STA   FAC2_1            ; save FAC2 mantissa1
00D824  1  98                 TYA                     ; restore FAC2-FAC1 compare status
00D825  1               
00D825  1                                             ; FAC2 = FAC2*2
00D825  1               LAB_2704
00D825  1  06 B6              ASL   FAC2_3            ; shift FAC2 mantissa3
00D827  1  26 B5              ROL   FAC2_2            ; shift FAC2 mantissa2
00D829  1  26 B4              ROL   FAC2_1            ; shift FAC2 mantissa1
00D82B  1  B0 CF              BCS   LAB_26F4          ; loop with no compare
00D82D  1               
00D82D  1  30 BD              BMI   LAB_26E4          ; loop with compare
00D82F  1               
00D82F  1  10 CB              BPL   LAB_26F4          ; loop always with no compare
00D831  1               
00D831  1               ; do A<<6, save as FAC1 rounding byte, normalise and return
00D831  1               
00D831  1               LAB_272B
00D831  1  4A                 LSR                     ; shift b1 - b0 ..
00D832  1  6A                 ROR                     ; ..
00D833  1  6A                 ROR                     ; .. to b7 - b6
00D834  1  85 B9              STA   FAC1_r            ; save FAC1 rounding byte
00D836  1  28                 PLP                     ; dump FAC2-FAC1 compare status
00D837  1  4C 3F D8           JMP   LAB_273C          ; copy temp to FAC1, normalise and return
00D83A  1               
00D83A  1               ; do "Divide by zero" error
00D83A  1               
00D83A  1               LAB_2737
00D83A  1  A2 14              LDX   #$14              ; error code $14 ("Divide by zero" error)
00D83C  1  4C 02 C1           JMP   LAB_XERR          ; do error #X, then warm start
00D83F  1               
00D83F  1               ; copy temp to FAC1 and normalise
00D83F  1               
00D83F  1               LAB_273C
00D83F  1  A5 75              LDA   FACt_1            ; get temp mantissa1
00D841  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00D843  1  A5 76              LDA   FACt_2            ; get temp mantissa2
00D845  1  85 AE              STA   FAC1_2            ; save FAC1 mantissa2
00D847  1  A5 77              LDA   FACt_3            ; get temp mantissa3
00D849  1  85 AF              STA   FAC1_3            ; save FAC1 mantissa3
00D84B  1  4C 05 D6           JMP   LAB_24D5          ; normalise FAC1 and return
00D84E  1               
00D84E  1               ; unpack memory (AY) into FAC1
00D84E  1               
00D84E  1               LAB_UFAC
00D84E  1  85 71              STA   ut1_pl            ; save pointer low byte
00D850  1  84 72              STY   ut1_ph            ; save pointer high byte
00D852  1  A0 03              LDY   #$03              ; 4 bytes to do
00D854  1  B1 71              LDA   (ut1_pl),Y        ; get last byte
00D856  1  85 AF              STA   FAC1_3            ; save FAC1 mantissa3
00D858  1  88                 DEY                     ; decrement index
00D859  1  B1 71              LDA   (ut1_pl),Y        ; get last-1 byte
00D85B  1  85 AE              STA   FAC1_2            ; save FAC1 mantissa2
00D85D  1  88                 DEY                     ; decrement index
00D85E  1  B1 71              LDA   (ut1_pl),Y        ; get second byte
00D860  1  85 B0              STA   FAC1_s            ; save FAC1 sign (b7)
00D862  1  09 80              ORA   #$80              ; set 1xxx xxxx (add normal bit)
00D864  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00D866  1  88                 DEY                     ; decrement index
00D867  1  B1 71              LDA   (ut1_pl),Y        ; get first byte (exponent)
00D869  1  85 AC              STA   FAC1_e            ; save FAC1 exponent
00D86B  1  84 B9              STY   FAC1_r            ; clear FAC1 rounding byte
00D86D  1  60                 RTS
00D86E  1               
00D86E  1               ; pack FAC1 into Adatal
00D86E  1               
00D86E  1               LAB_276E
00D86E  1  A2 A4              LDX   #<Adatal          ; set pointer low byte
00D870  1               LAB_2770
00D870  1  A0 00              LDY   #>Adatal          ; set pointer high byte
00D872  1  F0 04              BEQ   LAB_2778          ; pack FAC1 into (XY) and return
00D874  1               
00D874  1               ; pack FAC1 into (Lvarpl)
00D874  1               
00D874  1               LAB_PFAC
00D874  1  A6 97              LDX   Lvarpl            ; get destination pointer low byte
00D876  1  A4 98              LDY   Lvarph            ; get destination pointer high byte
00D878  1               
00D878  1               ; pack FAC1 into (XY)
00D878  1               
00D878  1               LAB_2778
00D878  1  20 AA D8           JSR   LAB_27BA          ; round FAC1
00D87B  1  86 71              STX   ut1_pl            ; save pointer low byte
00D87D  1  84 72              STY   ut1_ph            ; save pointer high byte
00D87F  1  A0 03              LDY   #$03              ; set index
00D881  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00D883  1  91 71              STA   (ut1_pl),Y        ; store in destination
00D885  1  88                 DEY                     ; decrement index
00D886  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00D888  1  91 71              STA   (ut1_pl),Y        ; store in destination
00D88A  1  88                 DEY                     ; decrement index
00D88B  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00D88D  1  09 7F              ORA   #$7F              ; set bits x111 1111
00D88F  1  25 AD              AND   FAC1_1            ; AND in FAC1 mantissa1
00D891  1  91 71              STA   (ut1_pl),Y        ; store in destination
00D893  1  88                 DEY                     ; decrement index
00D894  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00D896  1  91 71              STA   (ut1_pl),Y        ; store in destination
00D898  1  84 B9              STY   FAC1_r            ; clear FAC1 rounding byte
00D89A  1  60                 RTS
00D89B  1               
00D89B  1               ; round and copy FAC1 to FAC2
00D89B  1               
00D89B  1               LAB_27AB
00D89B  1  20 AA D8           JSR   LAB_27BA          ; round FAC1
00D89E  1               
00D89E  1               ; copy FAC1 to FAC2
00D89E  1               
00D89E  1               LAB_27AE
00D89E  1  A2 05              LDX   #$05              ; 5 bytes to copy
00D8A0  1               LAB_27B0
00D8A0  1  B5 AB              LDA   FAC1_e-1,X        ; get byte from FAC1,X
00D8A2  1  95 B2              STA   FAC1_o,X          ; save byte at FAC2,X
00D8A4  1  CA                 DEX                     ; decrement count
00D8A5  1  D0 F9              BNE   LAB_27B0          ; loop if not all done
00D8A7  1               
00D8A7  1  86 B9              STX   FAC1_r            ; clear FAC1 rounding byte
00D8A9  1               LAB_27B9
00D8A9  1  60                 RTS
00D8AA  1               
00D8AA  1               ; round FAC1
00D8AA  1               
00D8AA  1               LAB_27BA
00D8AA  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00D8AC  1  F0 FB              BEQ   LAB_27B9          ; exit if zero
00D8AE  1               
00D8AE  1  06 B9              ASL   FAC1_r            ; shift FAC1 rounding byte
00D8B0  1  90 F7              BCC   LAB_27B9          ; exit if no overflow
00D8B2  1               
00D8B2  1               ; round FAC1 (no check)
00D8B2  1               
00D8B2  1               LAB_27C2
00D8B2  1  20 89 D6           JSR   LAB_2559          ; increment FAC1 mantissa
00D8B5  1  D0 F2              BNE   LAB_27B9          ; branch if no overflow
00D8B7  1               
00D8B7  1  4C 5A D6           JMP   LAB_252A          ; normalise FAC1 for C=1 and return
00D8BA  1               
00D8BA  1               ; get FAC1 sign
00D8BA  1               ; return A=FF,C=1/-ve A=01,C=0/+ve
00D8BA  1               
00D8BA  1               LAB_27CA
00D8BA  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00D8BC  1  F0 09              BEQ   LAB_27D7          ; exit if zero (already correct SGN(0)=0)
00D8BE  1               
00D8BE  1               ; return A=FF,C=1/-ve A=01,C=0/+ve
00D8BE  1               ; no = 0 check
00D8BE  1               
00D8BE  1               LAB_27CE
00D8BE  1  A5 B0              LDA   FAC1_s            ; else get FAC1 sign (b7)
00D8C0  1               
00D8C0  1               ; return A=FF,C=1/-ve A=01,C=0/+ve
00D8C0  1               ; no = 0 check, sign in A
00D8C0  1               
00D8C0  1               LAB_27D0
00D8C0  1  2A                 ROL                     ; move sign bit to carry
00D8C1  1  A9 FF              LDA   #$FF              ; set byte for -ve result
00D8C3  1  B0 02              BCS   LAB_27D7          ; return if sign was set (-ve)
00D8C5  1               
00D8C5  1  A9 01              LDA   #$01              ; else set byte for +ve result
00D8C7  1               LAB_27D7
00D8C7  1  60                 RTS
00D8C8  1               
00D8C8  1               ; perform SGN()
00D8C8  1               
00D8C8  1               LAB_SGN
00D8C8  1  20 BA D8           JSR   LAB_27CA          ; get FAC1 sign
00D8CB  1                                             ; return A=$FF/-ve A=$01/+ve
00D8CB  1               ; save A as integer byte
00D8CB  1               
00D8CB  1               LAB_27DB
00D8CB  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00D8CD  1  A9 00              LDA   #$00              ; clear A
00D8CF  1  85 AE              STA   FAC1_2            ; clear FAC1 mantissa2
00D8D1  1  A2 88              LDX   #$88              ; set exponent
00D8D3  1               
00D8D3  1               ; set exp=X, clearFAC1 mantissa3 and normalise
00D8D3  1               
00D8D3  1               LAB_27E3
00D8D3  1  A5 AD              LDA   FAC1_1            ; get FAC1 mantissa1
00D8D5  1  49 FF              EOR   #$FF              ; complement it
00D8D7  1  2A                 ROL                     ; sign bit into carry
00D8D8  1               
00D8D8  1               ; set exp=X, clearFAC1 mantissa3 and normalise
00D8D8  1               
00D8D8  1               LAB_STFA
00D8D8  1  A9 00              LDA   #$00              ; clear A
00D8DA  1  85 AF              STA   FAC1_3            ; clear FAC1 mantissa3
00D8DC  1  86 AC              STX   FAC1_e            ; set FAC1 exponent
00D8DE  1  85 B9              STA   FAC1_r            ; clear FAC1 rounding byte
00D8E0  1  85 B0              STA   FAC1_s            ; clear FAC1 sign (b7)
00D8E2  1  4C 00 D6           JMP   LAB_24D0          ; do ABS and normalise FAC1
00D8E5  1               
00D8E5  1               ; perform ABS()
00D8E5  1               
00D8E5  1               LAB_ABS
00D8E5  1  46 B0              LSR   FAC1_s            ; clear FAC1 sign (put zero in b7)
00D8E7  1  60                 RTS
00D8E8  1               
00D8E8  1               ; compare FAC1 with (AY)
00D8E8  1               ; returns A=$00 if FAC1 = (AY)
00D8E8  1               ; returns A=$01 if FAC1 > (AY)
00D8E8  1               ; returns A=$FF if FAC1 < (AY)
00D8E8  1               
00D8E8  1               LAB_27F8
00D8E8  1  85 73              STA   ut2_pl            ; save pointer low byte
00D8EA  1               LAB_27FA
00D8EA  1  84 74              STY   ut2_ph            ; save pointer high byte
00D8EC  1  A0 00              LDY   #$00              ; clear index
00D8EE  1  B1 73              LDA   (ut2_pl),Y        ; get exponent
00D8F0  1  C8                 INY                     ; increment index
00D8F1  1  AA                 TAX                     ; copy (AY) exponent to X
00D8F2  1  F0 C6              BEQ   LAB_27CA          ; branch if (AY) exponent=0 and get FAC1 sign
00D8F4  1                                             ; A=FF,C=1/-ve A=01,C=0/+ve
00D8F4  1               
00D8F4  1  B1 73              LDA   (ut2_pl),Y        ; get (AY) mantissa1 (with sign)
00D8F6  1  45 B0              EOR   FAC1_s            ; EOR FAC1 sign (b7)
00D8F8  1  30 C4              BMI   LAB_27CE          ; if signs <> do return A=FF,C=1/-ve
00D8FA  1                                             ; A=01,C=0/+ve and return
00D8FA  1               
00D8FA  1  E4 AC              CPX   FAC1_e            ; compare (AY) exponent with FAC1 exponent
00D8FC  1  D0 1A              BNE   LAB_2828          ; branch if different
00D8FE  1               
00D8FE  1  B1 73              LDA   (ut2_pl),Y        ; get (AY) mantissa1 (with sign)
00D900  1  09 80              ORA   #$80              ; normalise top bit
00D902  1  C5 AD              CMP   FAC1_1            ; compare with FAC1 mantissa1
00D904  1  D0 12              BNE   LAB_2828          ; branch if different
00D906  1               
00D906  1  C8                 INY                     ; increment index
00D907  1  B1 73              LDA   (ut2_pl),Y        ; get mantissa2
00D909  1  C5 AE              CMP   FAC1_2            ; compare with FAC1 mantissa2
00D90B  1  D0 0B              BNE   LAB_2828          ; branch if different
00D90D  1               
00D90D  1  C8                 INY                     ; increment index
00D90E  1  A9 7F              LDA   #$7F              ; set for 1/2 value rounding byte
00D910  1  C5 B9              CMP   FAC1_r            ; compare with FAC1 rounding byte (set carry)
00D912  1  B1 73              LDA   (ut2_pl),Y        ; get mantissa3
00D914  1  E5 AF              SBC   FAC1_3            ; subtract FAC1 mantissa3
00D916  1  F0 28              BEQ   LAB_2850          ; exit if mantissa3 equal
00D918  1               
00D918  1               ; gets here if number <> FAC1
00D918  1               
00D918  1               LAB_2828
00D918  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00D91A  1  90 02              BCC   LAB_282E          ; branch if FAC1 > (AY)
00D91C  1               
00D91C  1  49 FF              EOR   #$FF              ; else toggle FAC1 sign
00D91E  1               LAB_282E
00D91E  1  4C C0 D8           JMP   LAB_27D0          ; return A=FF,C=1/-ve A=01,C=0/+ve
00D921  1               
00D921  1               ; convert FAC1 floating-to-fixed
00D921  1               
00D921  1               LAB_2831
00D921  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00D923  1  F0 4A              BEQ   LAB_287F          ; if zero go clear FAC1 and return
00D925  1               
00D925  1  38                 SEC                     ; set carry for subtract
00D926  1  E9 98              SBC   #$98              ; subtract maximum integer range exponent
00D928  1  24 B0              BIT   FAC1_s            ; test FAC1 sign (b7)
00D92A  1  10 09              BPL   LAB_2845          ; branch if FAC1 +ve
00D92C  1               
00D92C  1                                             ; FAC1 was -ve
00D92C  1  AA                 TAX                     ; copy subtracted exponent
00D92D  1  A9 FF              LDA   #$FF              ; overflow for -ve number
00D92F  1  85 B2              STA   FAC1_o            ; set FAC1 overflow byte
00D931  1  20 6D D6           JSR   LAB_253D          ; twos complement FAC1 mantissa
00D934  1  8A                 TXA                     ; restore subtracted exponent
00D935  1               LAB_2845
00D935  1  A2 AC              LDX   #FAC1_e           ; set index to FAC1
00D937  1  C9 F9              CMP   #$F9              ; compare exponent result
00D939  1  10 06              BPL   LAB_2851          ; if < 8 shifts shift FAC1 A times right and return
00D93B  1               
00D93B  1  20 AB D6           JSR   LAB_257B          ; shift FAC1 A times right (> 8 shifts)
00D93E  1  84 B2              STY   FAC1_o            ; clear FAC1 overflow byte
00D940  1               LAB_2850
00D940  1  60                 RTS
00D941  1               
00D941  1               ; shift FAC1 A times right
00D941  1               
00D941  1               LAB_2851
00D941  1  A8                 TAY                     ; copy shift count
00D942  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00D944  1  29 80              AND   #$80              ; mask sign bit only (x000 0000)
00D946  1  46 AD              LSR   FAC1_1            ; shift FAC1 mantissa1
00D948  1  05 AD              ORA   FAC1_1            ; OR sign in b7 FAC1 mantissa1
00D94A  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00D94C  1  20 C2 D6           JSR   LAB_2592          ; shift FAC1 Y times right
00D94F  1  84 B2              STY   FAC1_o            ; clear FAC1 overflow byte
00D951  1  60                 RTS
00D952  1               
00D952  1               ; perform INT()
00D952  1               
00D952  1               LAB_INT
00D952  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00D954  1  C9 98              CMP   #$98              ; compare with max int
00D956  1  B0 1E              BCS   LAB_2886          ; exit if >= (already int, too big for fractional part!)
00D958  1               
00D958  1  20 21 D9           JSR   LAB_2831          ; convert FAC1 floating-to-fixed
00D95B  1  84 B9              STY   FAC1_r            ; save FAC1 rounding byte
00D95D  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00D95F  1  84 B0              STY   FAC1_s            ; save FAC1 sign (b7)
00D961  1  49 80              EOR   #$80              ; toggle FAC1 sign
00D963  1  2A                 ROL                     ; shift into carry
00D964  1  A9 98              LDA   #$98              ; set new exponent
00D966  1  85 AC              STA   FAC1_e            ; save FAC1 exponent
00D968  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00D96A  1  85 5B              STA   Temp3             ; save for EXP() function
00D96C  1  4C 00 D6           JMP   LAB_24D0          ; do ABS and normalise FAC1
00D96F  1               
00D96F  1               ; clear FAC1 and return
00D96F  1               
00D96F  1               LAB_287F
00D96F  1  85 AD              STA   FAC1_1            ; clear FAC1 mantissa1
00D971  1  85 AE              STA   FAC1_2            ; clear FAC1 mantissa2
00D973  1  85 AF              STA   FAC1_3            ; clear FAC1 mantissa3
00D975  1  A8                 TAY                     ; clear Y
00D976  1               LAB_2886
00D976  1  60                 RTS
00D977  1               
00D977  1               ; get FAC1 from string
00D977  1               ; this routine now handles hex and binary values from strings
00D977  1               ; starting with "$" and "%" respectively
00D977  1               
00D977  1               LAB_2887
00D977  1  A0 00              LDY   #$00              ; clear Y
00D979  1  84 5F              STY   Dtypef            ; clear data type flag, $FF=string, $00=numeric
00D97B  1  A2 09              LDX   #$09              ; set index
00D97D  1               LAB_288B
00D97D  1  94 A8              STY   numexp,X          ; clear byte
00D97F  1  CA                 DEX                     ; decrement index
00D980  1  10 FB              BPL   LAB_288B          ; loop until numexp to negnum (and FAC1) = $00
00D982  1               
00D982  1  90 7F              BCC   LAB_28FE          ; branch if 1st character numeric
00D984  1               
00D984  1               ; get FAC1 from string .. first character wasn't numeric
00D984  1               
00D984  1  C9 2D              CMP   #'-'              ; else compare with "-"
00D986  1  D0 04              BNE   LAB_289A          ; branch if not "-"
00D988  1               
00D988  1  86 B1              STX   negnum            ; set flag for -ve number (X = $FF)
00D98A  1  F0 04              BEQ   LAB_289C          ; branch always (go scan and check for hex/bin)
00D98C  1               
00D98C  1               ; get FAC1 from string .. first character wasn't numeric or -
00D98C  1               
00D98C  1               LAB_289A
00D98C  1  C9 2B              CMP   #'+'              ; else compare with "+"
00D98E  1  D0 05              BNE   LAB_289D          ; branch if not "+" (go check for hex/bin)
00D990  1               
00D990  1               ; was "+" or "-" to start, so get next character
00D990  1               
00D990  1               LAB_289C
00D990  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00D993  1  90 6E              BCC   LAB_28FE          ; branch if numeric character
00D995  1               
00D995  1               ; code here for hex and binary numbers
00D995  1               
00D995  1               LAB_289D
00D995  1  C9 24              CMP   #'$'              ; else compare with "$"
00D997  1  D0 03              BNE   LAB_NHEX          ; branch if not "$"
00D999  1               
00D999  1  4C 41 DE           JMP   LAB_CHEX          ; branch if "$"
00D99C  1               
00D99C  1               LAB_NHEX
00D99C  1  C9 25              CMP   #'%'              ; else compare with "%"
00D99E  1  D0 08              BNE   LAB_28A3          ; branch if not "%" (continue original code)
00D9A0  1               
00D9A0  1  4C 6F DE           JMP   LAB_CBIN          ; branch if "%"
00D9A3  1               
00D9A3  1               LAB_289E
00D9A3  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory (ignore + or get next number)
00D9A6  1               LAB_28A1
00D9A6  1  90 5B              BCC   LAB_28FE          ; branch if numeric character
00D9A8  1               
00D9A8  1               ; get FAC1 from string .. character wasn't numeric, -, +, hex or binary
00D9A8  1               
00D9A8  1               LAB_28A3
00D9A8  1  C9 2E              CMP   #'.'              ; else compare with "."
00D9AA  1  F0 2E              BEQ   LAB_28D5          ; branch if "."
00D9AC  1               
00D9AC  1               ; get FAC1 from string .. character wasn't numeric, -, + or .
00D9AC  1               
00D9AC  1  C9 45              CMP   #'E'              ; else compare with "E"
00D9AE  1  D0 30              BNE   LAB_28DB          ; branch if not "E"
00D9B0  1               
00D9B0  1                                             ; was "E" so evaluate exponential part
00D9B0  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00D9B3  1  90 17              BCC   LAB_28C7          ; branch if numeric character
00D9B5  1               
00D9B5  1  C9 B7              CMP   #TK_MINUS         ; else compare with token for -
00D9B7  1  F0 0E              BEQ   LAB_28C2          ; branch if token for -
00D9B9  1               
00D9B9  1  C9 2D              CMP   #'-'              ; else compare with "-"
00D9BB  1  F0 0A              BEQ   LAB_28C2          ; branch if "-"
00D9BD  1               
00D9BD  1  C9 B6              CMP   #TK_PLUS          ; else compare with token for +
00D9BF  1  F0 08              BEQ   LAB_28C4          ; branch if token for +
00D9C1  1               
00D9C1  1  C9 2B              CMP   #'+'              ; else compare with "+"
00D9C3  1  F0 04              BEQ   LAB_28C4          ; branch if "+"
00D9C5  1               
00D9C5  1  D0 07              BNE   LAB_28C9          ; branch always
00D9C7  1               
00D9C7  1               LAB_28C2
00D9C7  1  66 AB              ROR   expneg            ; set exponent -ve flag (C, which=1, into b7)
00D9C9  1               LAB_28C4
00D9C9  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00D9CC  1               LAB_28C7
00D9CC  1  90 5B              BCC   LAB_2925          ; branch if numeric character
00D9CE  1               
00D9CE  1               LAB_28C9
00D9CE  1  24 AB              BIT   expneg            ; test exponent -ve flag
00D9D0  1  10 0E              BPL   LAB_28DB          ; if +ve go evaluate exponent
00D9D2  1               
00D9D2  1                                             ; else do exponent = -exponent
00D9D2  1  A9 00              LDA   #$00              ; clear result
00D9D4  1  38                 SEC                     ; set carry for subtract
00D9D5  1  E5 A9              SBC   expcnt            ; subtract exponent byte
00D9D7  1  4C E2 D9           JMP   LAB_28DD          ; go evaluate exponent
00D9DA  1               
00D9DA  1               LAB_28D5
00D9DA  1  66 AA              ROR   numdpf            ; set decimal point flag
00D9DC  1  24 AA              BIT   numdpf            ; test decimal point flag
00D9DE  1  50 C3              BVC   LAB_289E          ; branch if only one decimal point so far
00D9E0  1               
00D9E0  1                                             ; evaluate exponent
00D9E0  1               LAB_28DB
00D9E0  1  A5 A9              LDA   expcnt            ; get exponent count byte
00D9E2  1               LAB_28DD
00D9E2  1  38                 SEC                     ; set carry for subtract
00D9E3  1  E5 A8              SBC   numexp            ; subtract numerator exponent
00D9E5  1  85 A9              STA   expcnt            ; save exponent count byte
00D9E7  1  F0 12              BEQ   LAB_28F6          ; branch if no adjustment
00D9E9  1               
00D9E9  1  10 09              BPL   LAB_28EF          ; else if +ve go do FAC1*10^expcnt
00D9EB  1               
00D9EB  1                                             ; else go do FAC1/10^(0-expcnt)
00D9EB  1               LAB_28E6
00D9EB  1  20 C1 D7           JSR   LAB_26B9          ; divide by 10
00D9EE  1  E6 A9              INC   expcnt            ; increment exponent count byte
00D9F0  1  D0 F9              BNE   LAB_28E6          ; loop until all done
00D9F2  1               
00D9F2  1  F0 07              BEQ   LAB_28F6          ; branch always
00D9F4  1               
00D9F4  1               LAB_28EF
00D9F4  1  20 A8 D7           JSR   LAB_269E          ; multiply by 10
00D9F7  1  C6 A9              DEC   expcnt            ; decrement exponent count byte
00D9F9  1  D0 F9              BNE   LAB_28EF          ; loop until all done
00D9FB  1               
00D9FB  1               LAB_28F6
00D9FB  1  A5 B1              LDA   negnum            ; get -ve flag
00D9FD  1  30 01              BMI   LAB_28FB          ; if -ve do - FAC1 and return
00D9FF  1               
00D9FF  1  60                 RTS
00DA00  1               
00DA00  1               ; do - FAC1 and return
00DA00  1               
00DA00  1               LAB_28FB
00DA00  1  4C C5 DB           JMP   LAB_GTHAN         ; do - FAC1 and return
00DA03  1               
00DA03  1               ; do unsigned FAC1*10+number
00DA03  1               
00DA03  1               LAB_28FE
00DA03  1  48                 PHA                     ; save character
00DA04  1  24 AA              BIT   numdpf            ; test decimal point flag
00DA06  1  10 02              BPL   LAB_2905          ; skip exponent increment if not set
00DA08  1               
00DA08  1  E6 A8              INC   numexp            ; else increment number exponent
00DA0A  1               LAB_2905
00DA0A  1  20 A8 D7           JSR   LAB_269E          ; multiply FAC1 by 10
00DA0D  1  68                 PLA                     ; restore character
00DA0E  1  29 0F              AND   #$0F              ; convert to binary
00DA10  1  20 16 DA           JSR   LAB_2912          ; evaluate new ASCII digit
00DA13  1  4C A3 D9           JMP   LAB_289E          ; go do next character
00DA16  1               
00DA16  1               ; evaluate new ASCII digit
00DA16  1               
00DA16  1               LAB_2912
00DA16  1  48                 PHA                     ; save digit
00DA17  1  20 9B D8           JSR   LAB_27AB          ; round and copy FAC1 to FAC2
00DA1A  1  68                 PLA                     ; restore digit
00DA1B  1  20 CB D8           JSR   LAB_27DB          ; save A as integer byte
00DA1E  1  A5 B7              LDA   FAC2_s            ; get FAC2 sign (b7)
00DA20  1  45 B0              EOR   FAC1_s            ; toggle with FAC1 sign (b7)
00DA22  1  85 B8              STA   FAC_sc            ; save sign compare (FAC1 EOR FAC2)
00DA24  1  A6 AC              LDX   FAC1_e            ; get FAC1 exponent
00DA26  1  4C 92 D5           JMP   LAB_ADD           ; add FAC2 to FAC1 and return
00DA29  1               
00DA29  1               ; evaluate next character of exponential part of number
00DA29  1               
00DA29  1               LAB_2925
00DA29  1  A5 A9              LDA   expcnt            ; get exponent count byte
00DA2B  1  C9 0A              CMP   #$0A              ; compare with 10 decimal
00DA2D  1  90 09              BCC   LAB_2934          ; branch if less
00DA2F  1               
00DA2F  1  A9 64              LDA   #$64              ; make all -ve exponents = -100 decimal (causes underflow)
00DA31  1  24 AB              BIT   expneg            ; test exponent -ve flag
00DA33  1  30 0E              BMI   LAB_2942          ; branch if -ve
00DA35  1               
00DA35  1  4C 94 D6           JMP   LAB_2564          ; else do overflow error
00DA38  1               
00DA38  1               LAB_2934
00DA38  1  0A                 ASL                     ; * 2
00DA39  1  0A                 ASL                     ; * 4
00DA3A  1  65 A9              ADC   expcnt            ; * 5
00DA3C  1  0A                 ASL                     ; * 10
00DA3D  1  A0 00              LDY   #$00              ; set index
00DA3F  1  71 C3              ADC   (Bpntrl),Y        ; add character (will be $30 too much!)
00DA41  1  E9 2F              SBC   #'0'-1            ; convert character to binary
00DA43  1               LAB_2942
00DA43  1  85 A9              STA   expcnt            ; save exponent count byte
00DA45  1  4C C9 D9           JMP   LAB_28C4          ; go get next character
00DA48  1               
00DA48  1               ; print " in line [LINE #]"
00DA48  1               
00DA48  1               LAB_2953
00DA48  1  A9 D6              LDA   #<LAB_LMSG        ; point to " in line " message low byte
00DA4A  1  A0 E7              LDY   #>LAB_LMSG        ; point to " in line " message high byte
00DA4C  1  20 A3 C8           JSR   LAB_18C3          ; print null terminated string from memory
00DA4F  1               
00DA4F  1                                             ; print Basic line #
00DA4F  1  A5 88              LDA   Clineh            ; get current line high byte
00DA51  1  A6 87              LDX   Clinel            ; get current line low byte
00DA53  1               
00DA53  1               ; print XA as unsigned integer
00DA53  1               
00DA53  1               LAB_295E
00DA53  1  85 AD              STA   FAC1_1            ; save low byte as FAC1 mantissa1
00DA55  1  86 AE              STX   FAC1_2            ; save high byte as FAC1 mantissa2
00DA57  1  A2 90              LDX   #$90              ; set exponent to 16d bits
00DA59  1  38                 SEC                     ; set integer is +ve flag
00DA5A  1  20 D8 D8           JSR   LAB_STFA          ; set exp=X, clearFAC1 mantissa3 and normalise
00DA5D  1  A0 00              LDY   #$00              ; clear index
00DA5F  1  98                 TYA                     ; clear A
00DA60  1  20 73 DA           JSR   LAB_297B          ; convert FAC1 to string, skip sign character save
00DA63  1  4C A3 C8           JMP   LAB_18C3          ; print null terminated string from memory and return
00DA66  1               
00DA66  1               ; convert FAC1 to ASCII string result in (AY)
00DA66  1               ; not any more, moved scratchpad to page 0
00DA66  1               
00DA66  1               LAB_296E
00DA66  1  A0 01              LDY   #$01              ; set index = 1
00DA68  1  A9 20              LDA   #$20              ; character = " " (assume +ve)
00DA6A  1  24 B0              BIT   FAC1_s            ; test FAC1 sign (b7)
00DA6C  1  10 02              BPL   LAB_2978          ; branch if +ve
00DA6E  1               
00DA6E  1  A9 2D              LDA   #$2D              ; else character = "-"
00DA70  1               LAB_2978
00DA70  1  99 EF 00           STA   Decss,Y           ; save leading character (" " or "-")
00DA73  1               LAB_297B
00DA73  1  85 B0              STA   FAC1_s            ; clear FAC1 sign (b7)
00DA75  1  84 BA              STY   Sendl             ; save index
00DA77  1  C8                 INY                     ; increment index
00DA78  1  A6 AC              LDX   FAC1_e            ; get FAC1 exponent
00DA7A  1  D0 05              BNE   LAB_2989          ; branch if FAC1<>0
00DA7C  1               
00DA7C  1                                             ; exponent was $00 so FAC1 is 0
00DA7C  1  A9 30              LDA   #'0'              ; set character = "0"
00DA7E  1  4C 7F DB           JMP   LAB_2A89          ; save last character, [EOT] and exit
00DA81  1               
00DA81  1                                             ; FAC1 is some non zero value
00DA81  1               LAB_2989
00DA81  1  A9 00              LDA   #$00              ; clear (number exponent count)
00DA83  1  E0 81              CPX   #$81              ; compare FAC1 exponent with $81 (>1.00000)
00DA85  1               
00DA85  1  B0 09              BCS   LAB_299A          ; branch if FAC1=>1
00DA87  1               
00DA87  1                                             ; FAC1<1
00DA87  1  A9 6A              LDA   #<LAB_294F        ; set pointer low byte to 1,000,000
00DA89  1  A0 E1              LDY   #>LAB_294F        ; set pointer high byte to 1,000,000
00DA8B  1  20 0A D7           JSR   LAB_25FB          ; do convert AY, FCA1*(AY)
00DA8E  1  A9 FA              LDA   #$FA              ; set number exponent count (-6)
00DA90  1               LAB_299A
00DA90  1  85 A8              STA   numexp            ; save number exponent count
00DA92  1               LAB_299C
00DA92  1  A9 66              LDA   #<LAB_294B        ; set pointer low byte to 999999.4375 (max before sci note)
00DA94  1  A0 E1              LDY   #>LAB_294B        ; set pointer high byte to 999999.4375
00DA96  1  20 E8 D8           JSR   LAB_27F8          ; compare FAC1 with (AY)
00DA99  1  F0 1E              BEQ   LAB_29C3          ; exit if FAC1 = (AY)
00DA9B  1               
00DA9B  1  10 12              BPL   LAB_29B9          ; go do /10 if FAC1 > (AY)
00DA9D  1               
00DA9D  1                                             ; FAC1 < (AY)
00DA9D  1               LAB_29A7
00DA9D  1  A9 62              LDA   #<LAB_2947        ; set pointer low byte to 99999.9375
00DA9F  1  A0 E1              LDY   #>LAB_2947        ; set pointer high byte to 99999.9375
00DAA1  1  20 E8 D8           JSR   LAB_27F8          ; compare FAC1 with (AY)
00DAA4  1  F0 02              BEQ   LAB_29B2          ; branch if FAC1 = (AY) (allow decimal places)
00DAA6  1               
00DAA6  1  10 0E              BPL   LAB_29C0          ; branch if FAC1 > (AY) (no decimal places)
00DAA8  1               
00DAA8  1                                             ; FAC1 <= (AY)
00DAA8  1               LAB_29B2
00DAA8  1  20 A8 D7           JSR   LAB_269E          ; multiply by 10
00DAAB  1  C6 A8              DEC   numexp            ; decrement number exponent count
00DAAD  1  D0 EE              BNE   LAB_29A7          ; go test again (branch always)
00DAAF  1               
00DAAF  1               LAB_29B9
00DAAF  1  20 C1 D7           JSR   LAB_26B9          ; divide by 10
00DAB2  1  E6 A8              INC   numexp            ; increment number exponent count
00DAB4  1  D0 DC              BNE   LAB_299C          ; go test again (branch always)
00DAB6  1               
00DAB6  1               ; now we have just the digits to do
00DAB6  1               
00DAB6  1               LAB_29C0
00DAB6  1  20 8B D5           JSR   LAB_244E          ; add 0.5 to FAC1 (round FAC1)
00DAB9  1               LAB_29C3
00DAB9  1  20 21 D9           JSR   LAB_2831          ; convert FAC1 floating-to-fixed
00DABC  1  A2 01              LDX   #$01              ; set default digits before dp = 1
00DABE  1  A5 A8              LDA   numexp            ; get number exponent count
00DAC0  1  18                 CLC                     ; clear carry for add
00DAC1  1  69 07              ADC   #$07              ; up to 6 digits before point
00DAC3  1  30 09              BMI   LAB_29D8          ; if -ve then 1 digit before dp
00DAC5  1               
00DAC5  1  C9 08              CMP   #$08              ; A>=8 if n>=1E6
00DAC7  1  B0 06              BCS   LAB_29D9          ; branch if >= $08
00DAC9  1               
00DAC9  1                                             ; carry is clear
00DAC9  1  69 FF              ADC   #$FF              ; take 1 from digit count
00DACB  1  AA                 TAX                     ; copy to A
00DACC  1  A9 02              LDA   #$02              ;.set exponent adjust
00DACE  1               LAB_29D8
00DACE  1  38                 SEC                     ; set carry for subtract
00DACF  1               LAB_29D9
00DACF  1  E9 02              SBC   #$02              ; -2
00DAD1  1  85 A9              STA   expcnt            ;.save exponent adjust
00DAD3  1  86 A8              STX   numexp            ; save digits before dp count
00DAD5  1  8A                 TXA                     ; copy to A
00DAD6  1  F0 02              BEQ   LAB_29E4          ; branch if no digits before dp
00DAD8  1               
00DAD8  1  10 13              BPL   LAB_29F7          ; branch if digits before dp
00DADA  1               
00DADA  1               LAB_29E4
00DADA  1  A4 BA              LDY   Sendl             ; get output string index
00DADC  1  A9 2E              LDA   #$2E              ; character "."
00DADE  1  C8                 INY                     ; increment index
00DADF  1  99 EF 00           STA   Decss,Y           ; save to output string
00DAE2  1  8A                 TXA                     ;.
00DAE3  1  F0 06              BEQ   LAB_29F5          ;.
00DAE5  1               
00DAE5  1  A9 30              LDA   #'0'              ; character "0"
00DAE7  1  C8                 INY                     ; increment index
00DAE8  1  99 EF 00           STA   Decss,Y           ; save to output string
00DAEB  1               LAB_29F5
00DAEB  1  84 BA              STY   Sendl             ; save output string index
00DAED  1               LAB_29F7
00DAED  1  A0 00              LDY   #$00              ; clear index (point to 100,000)
00DAEF  1  A2 80              LDX   #$80              ;
00DAF1  1               LAB_29FB
00DAF1  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00DAF3  1  18                 CLC                     ; clear carry for add
00DAF4  1  79 E0 E1           ADC   LAB_2A9C,Y        ; add -ve LSB
00DAF7  1  85 AF              STA   FAC1_3            ; save FAC1 mantissa3
00DAF9  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00DAFB  1  79 DF E1           ADC   LAB_2A9B,Y        ; add -ve NMSB
00DAFE  1  85 AE              STA   FAC1_2            ; save FAC1 mantissa2
00DB00  1  A5 AD              LDA   FAC1_1            ; get FAC1 mantissa1
00DB02  1  79 DE E1           ADC   LAB_2A9A,Y        ; add -ve MSB
00DB05  1  85 AD              STA   FAC1_1            ; save FAC1 mantissa1
00DB07  1  E8                 INX                     ;
00DB08  1  B0 04              BCS   LAB_2A18          ;
00DB0A  1               
00DB0A  1  10 E5              BPL   LAB_29FB          ; not -ve so try again
00DB0C  1               
00DB0C  1  30 02              BMI   LAB_2A1A          ;
00DB0E  1               
00DB0E  1               LAB_2A18
00DB0E  1  30 E1              BMI   LAB_29FB          ;
00DB10  1               
00DB10  1               LAB_2A1A
00DB10  1  8A                 TXA                     ;
00DB11  1  90 04              BCC   LAB_2A21          ;
00DB13  1               
00DB13  1  49 FF              EOR   #$FF              ;
00DB15  1  69 0A              ADC   #$0A              ;
00DB17  1               LAB_2A21
00DB17  1  69 2F              ADC   #'0'-1            ; add "0"-1 to result
00DB19  1  C8                 INY                     ; increment index ..
00DB1A  1  C8                 INY                     ; .. to next less ..
00DB1B  1  C8                 INY                     ; .. power of ten
00DB1C  1  84 95              STY   Cvaral            ; save as current var address low byte
00DB1E  1  A4 BA              LDY   Sendl             ; get output string index
00DB20  1  C8                 INY                     ; increment output string index
00DB21  1  AA                 TAX                     ; copy character to X
00DB22  1  29 7F              AND   #$7F              ; mask out top bit
00DB24  1  99 EF 00           STA   Decss,Y           ; save to output string
00DB27  1  C6 A8              DEC   numexp            ; decrement # of characters before the dp
00DB29  1  D0 06              BNE   LAB_2A3B          ; branch if still characters to do
00DB2B  1               
00DB2B  1                                             ; else output the point
00DB2B  1  A9 2E              LDA   #$2E              ; character "."
00DB2D  1  C8                 INY                     ; increment output string index
00DB2E  1  99 EF 00           STA   Decss,Y           ; save to output string
00DB31  1               LAB_2A3B
00DB31  1  84 BA              STY   Sendl             ; save output string index
00DB33  1  A4 95              LDY   Cvaral            ; get current var address low byte
00DB35  1  8A                 TXA                     ; get character back
00DB36  1  49 FF              EOR   #$FF              ;
00DB38  1  29 80              AND   #$80              ;
00DB3A  1  AA                 TAX                     ;
00DB3B  1  C0 12              CPY   #$12              ; compare index with max
00DB3D  1  D0 B2              BNE   LAB_29FB          ; loop if not max
00DB3F  1               
00DB3F  1                                             ; now remove trailing zeroes
00DB3F  1  A4 BA              LDY   Sendl             ; get output string index
00DB41  1               LAB_2A4B
00DB41  1  B9 EF 00           LDA   Decss,Y           ; get character from output string
00DB44  1  88                 DEY                     ; decrement output string index
00DB45  1  C9 30              CMP   #'0'              ; compare with "0"
00DB47  1  F0 F8              BEQ   LAB_2A4B          ; loop until non "0" character found
00DB49  1               
00DB49  1  C9 2E              CMP   #'.'              ; compare with "."
00DB4B  1  F0 01              BEQ   LAB_2A58          ; branch if was dp
00DB4D  1               
00DB4D  1                                             ; restore last character
00DB4D  1  C8                 INY                     ; increment output string index
00DB4E  1               LAB_2A58
00DB4E  1  A9 2B              LDA   #$2B              ; character "+"
00DB50  1  A6 A9              LDX   expcnt            ; get exponent count
00DB52  1  F0 2E              BEQ   LAB_2A8C          ; if zero go set null terminator and exit
00DB54  1               
00DB54  1                                             ; exponent isn't zero so write exponent
00DB54  1  10 08              BPL   LAB_2A68          ; branch if exponent count +ve
00DB56  1               
00DB56  1  A9 00              LDA   #$00              ; clear A
00DB58  1  38                 SEC                     ; set carry for subtract
00DB59  1  E5 A9              SBC   expcnt            ; subtract exponent count adjust (convert -ve to +ve)
00DB5B  1  AA                 TAX                     ; copy exponent count to X
00DB5C  1  A9 2D              LDA   #'-'              ; character "-"
00DB5E  1               LAB_2A68
00DB5E  1  99 F1 00           STA   Decss+2,Y         ; save to output string
00DB61  1  A9 45              LDA   #$45              ; character "E"
00DB63  1  99 F0 00           STA   Decss+1,Y         ; save exponent sign to output string
00DB66  1  8A                 TXA                     ; get exponent count back
00DB67  1  A2 2F              LDX   #'0'-1            ; one less than "0" character
00DB69  1  38                 SEC                     ; set carry for subtract
00DB6A  1               LAB_2A74
00DB6A  1  E8                 INX                     ; increment 10's character
00DB6B  1  E9 0A              SBC   #$0A              ;.subtract 10 from exponent count
00DB6D  1  B0 FB              BCS   LAB_2A74          ; loop while still >= 0
00DB6F  1               
00DB6F  1  69 3A              ADC   #':'              ; add character ":" ($30+$0A, result is 10 less that value)
00DB71  1  99 F3 00           STA   Decss+4,Y         ; save to output string
00DB74  1  8A                 TXA                     ; copy 10's character
00DB75  1  99 F2 00           STA   Decss+3,Y         ; save to output string
00DB78  1  A9 00              LDA   #$00              ; set null terminator
00DB7A  1  99 F4 00           STA   Decss+5,Y         ; save to output string
00DB7D  1  F0 08              BEQ   LAB_2A91          ; go set string pointer (AY) and exit (branch always)
00DB7F  1               
00DB7F  1                                             ; save last character, [EOT] and exit
00DB7F  1               LAB_2A89
00DB7F  1  99 EF 00           STA   Decss,Y           ; save last character to output string
00DB82  1               
00DB82  1                                             ; set null terminator and exit
00DB82  1               LAB_2A8C
00DB82  1  A9 00              LDA   #$00              ; set null terminator
00DB84  1  99 F0 00           STA   Decss+1,Y         ; save after last character
00DB87  1               
00DB87  1                                             ; set string pointer (AY) and exit
00DB87  1               LAB_2A91
00DB87  1  A9 F0              LDA   #<Decssp1         ; set result string low pointer
00DB89  1  A0 00              LDY   #>Decssp1         ; set result string high pointer
00DB8B  1  60                 RTS
00DB8C  1               
00DB8C  1               ; perform power function
00DB8C  1               
00DB8C  1               LAB_POWER
00DB8C  1  F0 42              BEQ   LAB_EXP           ; go do  EXP()
00DB8E  1               
00DB8E  1  A5 B3              LDA   FAC2_e            ; get FAC2 exponent
00DB90  1  D0 03              BNE   LAB_2ABF          ; branch if FAC2<>0
00DB92  1               
00DB92  1  4C 23 D6           JMP   LAB_24F3          ; clear FAC1 exponent and sign and return
00DB95  1               
00DB95  1               LAB_2ABF
00DB95  1  A2 9C              LDX   #<func_l          ; set destination pointer low byte
00DB97  1  A0 00              LDY   #>func_l          ; set destination pointer high byte
00DB99  1  20 78 D8           JSR   LAB_2778          ; pack FAC1 into (XY)
00DB9C  1  A5 B7              LDA   FAC2_s            ; get FAC2 sign (b7)
00DB9E  1  10 0F              BPL   LAB_2AD9          ; branch if FAC2>0
00DBA0  1               
00DBA0  1                                             ; else FAC2 is -ve and can only be raised to an
00DBA0  1                                             ; integer power which gives an x +j0 result
00DBA0  1  20 52 D9           JSR   LAB_INT           ; perform INT
00DBA3  1  A9 9C              LDA   #<func_l          ; set source pointer low byte
00DBA5  1  A0 00              LDY   #>func_l          ; set source pointer high byte
00DBA7  1  20 E8 D8           JSR   LAB_27F8          ; compare FAC1 with (AY)
00DBAA  1  D0 03              BNE   LAB_2AD9          ; branch if FAC1 <> (AY) to allow Function Call error
00DBAC  1                                             ; this will leave FAC1 -ve and cause a Function Call
00DBAC  1                                             ; error when LOG() is called
00DBAC  1               
00DBAC  1  98                 TYA                     ; clear sign b7
00DBAD  1  A4 5B              LDY   Temp3             ; save mantissa 3 from INT() function as sign in Y
00DBAF  1                                             ; for possible later negation, b0
00DBAF  1               LAB_2AD9
00DBAF  1  20 96 D5           JSR   LAB_279D          ; save FAC1 sign and copy ABS(FAC2) to FAC1
00DBB2  1  98                 TYA                     ; copy sign back ..
00DBB3  1  48                 PHA                     ; .. and save it
00DBB4  1  20 CC D6           JSR   LAB_LOG           ; do LOG(n)
00DBB7  1  A9 9C              LDA   #<garb_l          ; set pointer low byte
00DBB9  1  A0 00              LDY   #>garb_l          ; set pointer high byte
00DBBB  1  20 0A D7           JSR   LAB_25FB          ; do convert AY, FCA1*(AY) (square the value)
00DBBE  1  20 D0 DB           JSR   LAB_EXP           ; go do EXP(n)
00DBC1  1  68                 PLA                     ; pull sign from stack
00DBC2  1  4A                 LSR                     ; b0 is to be tested, shift to Cb
00DBC3  1  90 0A              BCC   LAB_2AF9          ; if no bit then exit
00DBC5  1               
00DBC5  1                                             ; Perform negation
00DBC5  1               ; do - FAC1
00DBC5  1               
00DBC5  1               LAB_GTHAN
00DBC5  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00DBC7  1  F0 06              BEQ   LAB_2AF9          ; exit if FAC1_e = $00
00DBC9  1               
00DBC9  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00DBCB  1  49 FF              EOR   #$FF              ; complement it
00DBCD  1  85 B0              STA   FAC1_s            ; save FAC1 sign (b7)
00DBCF  1               LAB_2AF9
00DBCF  1  60                 RTS
00DBD0  1               
00DBD0  1               ; perform EXP()   (x^e)
00DBD0  1               
00DBD0  1               LAB_EXP
00DBD0  1  A9 6E              LDA   #<LAB_2AFA        ; set 1.443 pointer low byte
00DBD2  1  A0 E1              LDY   #>LAB_2AFA        ; set 1.443 pointer high byte
00DBD4  1  20 0A D7           JSR   LAB_25FB          ; do convert AY, FCA1*(AY)
00DBD7  1  A5 B9              LDA   FAC1_r            ; get FAC1 rounding byte
00DBD9  1  69 50              ADC   #$50              ; +$50/$100
00DBDB  1  90 03              BCC   LAB_2B2B          ; skip rounding if no carry
00DBDD  1               
00DBDD  1  20 B2 D8           JSR   LAB_27C2          ; round FAC1 (no check)
00DBE0  1               LAB_2B2B
00DBE0  1  85 A3              STA   FAC2_r            ; save FAC2 rounding byte
00DBE2  1  20 9E D8           JSR   LAB_27AE          ; copy FAC1 to FAC2
00DBE5  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00DBE7  1  C9 88              CMP   #$88              ; compare with EXP limit (256d)
00DBE9  1  90 03              BCC   LAB_2B39          ; branch if less
00DBEB  1               
00DBEB  1               LAB_2B36
00DBEB  1  20 9F D7           JSR   LAB_2690          ; handle overflow and underflow
00DBEE  1               LAB_2B39
00DBEE  1  20 52 D9           JSR   LAB_INT           ; perform INT
00DBF1  1  A5 5B              LDA   Temp3             ; get mantissa 3 from INT() function
00DBF3  1  18                 CLC                     ; clear carry for add
00DBF4  1  69 81              ADC   #$81              ; normalise +1
00DBF6  1  F0 F3              BEQ   LAB_2B36          ; if $00 go handle overflow
00DBF8  1               
00DBF8  1  38                 SEC                     ; set carry for subtract
00DBF9  1  E9 01              SBC   #$01              ; now correct for exponent
00DBFB  1  48                 PHA                     ; save FAC2 exponent
00DBFC  1               
00DBFC  1                                             ; swap FAC1 and FAC2
00DBFC  1  A2 04              LDX   #$04              ; 4 bytes to do
00DBFE  1               LAB_2B49
00DBFE  1  B5 B3              LDA   FAC2_e,X          ; get FAC2,X
00DC00  1  B4 AC              LDY   FAC1_e,X          ; get FAC1,X
00DC02  1  95 AC              STA   FAC1_e,X          ; save FAC1,X
00DC04  1  94 B3              STY   FAC2_e,X          ; save FAC2,X
00DC06  1  CA                 DEX                     ; decrement count/index
00DC07  1  10 F5              BPL   LAB_2B49          ; loop if not all done
00DC09  1               
00DC09  1  A5 A3              LDA   FAC2_r            ; get FAC2 rounding byte
00DC0B  1  85 B9              STA   FAC1_r            ; save as FAC1 rounding byte
00DC0D  1  20 77 D5           JSR   LAB_SUBTRACT      ; perform subtraction, FAC2 from FAC1
00DC10  1  20 C5 DB           JSR   LAB_GTHAN         ; do - FAC1
00DC13  1  A9 72              LDA   #<LAB_2AFE        ; set counter pointer low byte
00DC15  1  A0 E1              LDY   #>LAB_2AFE        ; set counter pointer high byte
00DC17  1  20 38 DC           JSR   LAB_2B84          ; go do series evaluation
00DC1A  1  A9 00              LDA   #$00              ; clear A
00DC1C  1  85 B8              STA   FAC_sc            ; clear sign compare (FAC1 EOR FAC2)
00DC1E  1  68                 PLA                     ;.get saved FAC2 exponent
00DC1F  1  4C 84 D7           JMP   LAB_2675          ; test and adjust accumulators and return
00DC22  1               
00DC22  1               ; ^2 then series evaluation
00DC22  1               
00DC22  1               LAB_2B6E
00DC22  1  85 BA              STA   Cptrl             ; save count pointer low byte
00DC24  1  84 BB              STY   Cptrh             ; save count pointer high byte
00DC26  1  20 6E D8           JSR   LAB_276E          ; pack FAC1 into Adatal
00DC29  1  A9 A4              LDA   #<Adatal          ; set pointer low byte (Y already $00)
00DC2B  1  20 0A D7           JSR   LAB_25FB          ; do convert AY, FCA1*(AY)
00DC2E  1  20 3C DC           JSR   LAB_2B88          ; go do series evaluation
00DC31  1  A9 A4              LDA   #<Adatal          ; pointer to original # low byte
00DC33  1  A0 00              LDY   #>Adatal          ; pointer to original # high byte
00DC35  1  4C 0A D7           JMP   LAB_25FB          ; do convert AY, FCA1*(AY) and return
00DC38  1               
00DC38  1               ; series evaluation
00DC38  1               
00DC38  1               LAB_2B84
00DC38  1  85 BA              STA   Cptrl             ; save count pointer low byte
00DC3A  1  84 BB              STY   Cptrh             ; save count pointer high byte
00DC3C  1               LAB_2B88
00DC3C  1  A2 A8              LDX   #<numexp          ; set pointer low byte
00DC3E  1  20 70 D8           JSR   LAB_2770          ; set pointer high byte and pack FAC1 into numexp
00DC41  1  B1 BA              LDA   (Cptrl),Y         ; get constants count
00DC43  1  85 B1              STA   numcon            ; save constants count
00DC45  1  A4 BA              LDY   Cptrl             ; get count pointer low byte
00DC47  1  C8                 INY                     ; increment it (now constants pointer)
00DC48  1  98                 TYA                     ; copy it
00DC49  1  D0 02              BNE   LAB_2B97          ; skip next if no overflow
00DC4B  1               
00DC4B  1  E6 BB              INC   Cptrh             ; else increment high byte
00DC4D  1               LAB_2B97
00DC4D  1  85 BA              STA   Cptrl             ; save low byte
00DC4F  1  A4 BB              LDY   Cptrh             ; get high byte
00DC51  1               LAB_2B9B
00DC51  1  20 0A D7           JSR   LAB_25FB          ; do convert AY, FCA1*(AY)
00DC54  1  A5 BA              LDA   Cptrl             ; get constants pointer low byte
00DC56  1  A4 BB              LDY   Cptrh             ; get constants pointer high byte
00DC58  1  18                 CLC                     ; clear carry for add
00DC59  1  69 04              ADC   #$04              ; +4 to  low pointer (4 bytes per constant)
00DC5B  1  90 01              BCC   LAB_2BA8          ; skip next if no overflow
00DC5D  1               
00DC5D  1  C8                 INY                     ; increment high byte
00DC5E  1               LAB_2BA8
00DC5E  1  85 BA              STA   Cptrl             ; save pointer low byte
00DC60  1  84 BB              STY   Cptrh             ; save pointer high byte
00DC62  1  20 8F D5           JSR   LAB_246C          ; add (AY) to FAC1
00DC65  1  A9 A8              LDA   #<numexp          ; set pointer low byte to partial @ numexp
00DC67  1  A0 00              LDY   #>numexp          ; set pointer high byte to partial @ numexp
00DC69  1  C6 B1              DEC   numcon            ; decrement constants count
00DC6B  1  D0 E4              BNE   LAB_2B9B          ; loop until all done
00DC6D  1               
00DC6D  1  60                 RTS
00DC6E  1               
00DC6E  1               ; RND(n), 32 bit Galoise version. make n=0 for 19th next number in sequence or n<>0
00DC6E  1               ; to get 19th next number in sequence after seed n. This version of the PRNG uses
00DC6E  1               ; the Galois method and a sample of 65536 bytes produced gives the following values.
00DC6E  1               
00DC6E  1               ; Entropy = 7.997442 bits per byte
00DC6E  1               ; Optimum compression would reduce these 65536 bytes by 0 percent
00DC6E  1               
00DC6E  1               ; Chi square distribution for 65536 samples is 232.01, and
00DC6E  1               ; randomly would exceed this value 75.00 percent of the time
00DC6E  1               
00DC6E  1               ; Arithmetic mean value of data bytes is 127.6724, 127.5 would be random
00DC6E  1               ; Monte Carlo value for Pi is 3.122871269, error 0.60 percent
00DC6E  1               ; Serial correlation coefficient is -0.000370, totally uncorrelated would be 0.0
00DC6E  1               
00DC6E  1               LAB_RND
00DC6E  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00DC70  1  F0 07              BEQ   NextPRN           ; do next random # if zero
00DC72  1               
00DC72  1                                             ; else get seed into random number store
00DC72  1  A2 D8              LDX   #Rbyte4           ; set PRNG pointer low byte
00DC74  1  A0 00              LDY   #$00              ; set PRNG pointer high byte
00DC76  1  20 78 D8           JSR   LAB_2778          ; pack FAC1 into (XY)
00DC79  1               NextPRN
00DC79  1  A2 AF              LDX   #$AF              ; set EOR byte
00DC7B  1  A0 13              LDY   #$13              ; do this nineteen times
00DC7D  1               LoopPRN
00DC7D  1  06 D9              ASL   Rbyte1            ; shift PRNG most significant byte
00DC7F  1  26 DA              ROL   Rbyte2            ; shift PRNG middle byte
00DC81  1  26 DB              ROL   Rbyte3            ; shift PRNG least significant byte
00DC83  1  26 D8              ROL   Rbyte4            ; shift PRNG extra byte
00DC85  1  90 05              BCC   Ninc1             ; branch if bit 32 clear
00DC87  1               
00DC87  1  8A                 TXA                     ; set EOR byte
00DC88  1  45 D9              EOR   Rbyte1            ; EOR PRNG extra byte
00DC8A  1  85 D9              STA   Rbyte1            ; save new PRNG extra byte
00DC8C  1               Ninc1
00DC8C  1  88                 DEY                     ; decrement loop count
00DC8D  1  D0 EE              BNE   LoopPRN           ; loop if not all done
00DC8F  1               
00DC8F  1  A2 02              LDX   #$02              ; three bytes to copy
00DC91  1               CopyPRNG
00DC91  1  B5 D9              LDA   Rbyte1,X          ; get PRNG byte
00DC93  1  95 AD              STA   FAC1_1,X          ; save FAC1 byte
00DC95  1  CA                 DEX
00DC96  1  10 F9              BPL   CopyPRNG          ; loop if not complete
00DC98  1               
00DC98  1  A9 80              LDA   #$80              ; set the exponent
00DC9A  1  85 AC              STA   FAC1_e            ; save FAC1 exponent
00DC9C  1               
00DC9C  1  0A                 ASL                     ; clear A
00DC9D  1  85 B0              STA   FAC1_s            ; save FAC1 sign
00DC9F  1               
00DC9F  1  4C 05 D6           JMP   LAB_24D5          ; normalise FAC1 and return
00DCA2  1               
00DCA2  1               ; perform COS()
00DCA2  1               
00DCA2  1               LAB_COS
00DCA2  1  A9 8F              LDA   #<LAB_2C78        ; set (pi/2) pointer low byte
00DCA4  1  A0 E1              LDY   #>LAB_2C78        ; set (pi/2) pointer high byte
00DCA6  1  20 8F D5           JSR   LAB_246C          ; add (AY) to FAC1
00DCA9  1               
00DCA9  1               ; perform SIN()
00DCA9  1               
00DCA9  1               LAB_SIN
00DCA9  1  20 9B D8           JSR   LAB_27AB          ; round and copy FAC1 to FAC2
00DCAC  1  A9 A4              LDA   #<LAB_2C7C        ; set (2*pi) pointer low byte
00DCAE  1  A0 E1              LDY   #>LAB_2C7C        ; set (2*pi) pointer high byte
00DCB0  1  A6 B7              LDX   FAC2_s            ; get FAC2 sign (b7)
00DCB2  1  20 CA D7           JSR   LAB_26C2          ; divide by (AY) (X=sign)
00DCB5  1  20 9B D8           JSR   LAB_27AB          ; round and copy FAC1 to FAC2
00DCB8  1  20 52 D9           JSR   LAB_INT           ; perform INT
00DCBB  1  A9 00              LDA   #$00              ; clear byte
00DCBD  1  85 B8              STA   FAC_sc            ; clear sign compare (FAC1 EOR FAC2)
00DCBF  1  20 77 D5           JSR   LAB_SUBTRACT      ; perform subtraction, FAC2 from FAC1
00DCC2  1  A9 D6              LDA   #<LAB_2C80        ; set 0.25 pointer low byte
00DCC4  1  A0 E1              LDY   #>LAB_2C80        ; set 0.25 pointer high byte
00DCC6  1  20 74 D5           JSR   LAB_2455          ; perform subtraction, (AY) from FAC1
00DCC9  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00DCCB  1  48                 PHA                     ; save FAC1 sign
00DCCC  1  10 0D              BPL   LAB_2C35          ; branch if +ve
00DCCE  1               
00DCCE  1                                             ; FAC1 sign was -ve
00DCCE  1  20 8B D5           JSR   LAB_244E          ; add 0.5 to FAC1
00DCD1  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00DCD3  1  30 09              BMI   LAB_2C38          ; branch if -ve
00DCD5  1               
00DCD5  1  A5 63              LDA   Cflag             ; get comparison evaluation flag
00DCD7  1  49 FF              EOR   #$FF              ; toggle flag
00DCD9  1  85 63              STA   Cflag             ; save comparison evaluation flag
00DCDB  1               LAB_2C35
00DCDB  1  20 C5 DB           JSR   LAB_GTHAN         ; do - FAC1
00DCDE  1               LAB_2C38
00DCDE  1  A9 D6              LDA   #<LAB_2C80        ; set 0.25 pointer low byte
00DCE0  1  A0 E1              LDY   #>LAB_2C80        ; set 0.25 pointer high byte
00DCE2  1  20 8F D5           JSR   LAB_246C          ; add (AY) to FAC1
00DCE5  1  68                 PLA                     ; restore FAC1 sign
00DCE6  1  10 03              BPL   LAB_2C45          ; branch if was +ve
00DCE8  1               
00DCE8  1                                             ; else correct FAC1
00DCE8  1  20 C5 DB           JSR   LAB_GTHAN         ; do - FAC1
00DCEB  1               LAB_2C45
00DCEB  1  A9 93              LDA   #<LAB_2C84        ; set pointer low byte to counter
00DCED  1  A0 E1              LDY   #>LAB_2C84        ; set pointer high byte to counter
00DCEF  1  4C 22 DC           JMP   LAB_2B6E          ; ^2 then series evaluation and return
00DCF2  1               
00DCF2  1               ; perform TAN()
00DCF2  1               
00DCF2  1               LAB_TAN
00DCF2  1  20 6E D8           JSR   LAB_276E          ; pack FAC1 into Adatal
00DCF5  1  A9 00              LDA   #$00              ; clear byte
00DCF7  1  85 63              STA   Cflag             ; clear comparison evaluation flag
00DCF9  1  20 A9 DC           JSR   LAB_SIN           ; go do SIN(n)
00DCFC  1  A2 9C              LDX   #<func_l          ; set sin(n) pointer low byte
00DCFE  1  A0 00              LDY   #>func_l          ; set sin(n) pointer high byte
00DD00  1  20 78 D8           JSR   LAB_2778          ; pack FAC1 into (XY)
00DD03  1  A9 A4              LDA   #<Adatal          ; set n pointer low addr
00DD05  1  A0 00              LDY   #>Adatal          ; set n pointer high addr
00DD07  1  20 4E D8           JSR   LAB_UFAC          ; unpack memory (AY) into FAC1
00DD0A  1  A9 00              LDA   #$00              ; clear byte
00DD0C  1  85 B0              STA   FAC1_s            ; clear FAC1 sign (b7)
00DD0E  1  A5 63              LDA   Cflag             ; get comparison evaluation flag
00DD10  1  20 1A DD           JSR   LAB_2C74          ; save flag and go do series evaluation
00DD13  1               
00DD13  1  A9 9C              LDA   #<func_l          ; set sin(n) pointer low byte
00DD15  1  A0 00              LDY   #>func_l          ; set sin(n) pointer high byte
00DD17  1  4C D2 D7           JMP   LAB_26CA          ; convert AY and do (AY)/FAC1
00DD1A  1               
00DD1A  1               LAB_2C74
00DD1A  1  48                 PHA                     ; save comparison evaluation flag
00DD1B  1  4C DB DC           JMP   LAB_2C35          ; go do series evaluation
00DD1E  1               
00DD1E  1               ; perform USR()
00DD1E  1               
00DD1E  1               LAB_USR
00DD1E  1  20 0A 00           JSR   Usrjmp            ; call user code
00DD21  1  4C BE CB           JMP   LAB_1BFB          ; scan for ")", else do syntax error then warm start
00DD24  1               
00DD24  1               ; perform ATN()
00DD24  1               
00DD24  1               LAB_ATN
00DD24  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign (b7)
00DD26  1  48                 PHA                     ; save sign
00DD27  1  10 03              BPL   LAB_2CA1          ; branch if +ve
00DD29  1               
00DD29  1  20 C5 DB           JSR   LAB_GTHAN         ; else do - FAC1
00DD2C  1               LAB_2CA1
00DD2C  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00DD2E  1  48                 PHA                     ; push exponent
00DD2F  1  C9 81              CMP   #$81              ; compare with 1
00DD31  1  90 07              BCC   LAB_2CAF          ; branch if FAC1<1
00DD33  1               
00DD33  1  A9 C9              LDA   #<LAB_259C        ; set 1 pointer low byte
00DD35  1  A0 E1              LDY   #>LAB_259C        ; set 1 pointer high byte
00DD37  1  20 D2 D7           JSR   LAB_26CA          ; convert AY and do (AY)/FAC1
00DD3A  1               LAB_2CAF
00DD3A  1  A9 A8              LDA   #<LAB_2CC9        ; set pointer low byte to counter
00DD3C  1  A0 E1              LDY   #>LAB_2CC9        ; set pointer high byte to counter
00DD3E  1  20 22 DC           JSR   LAB_2B6E          ; ^2 then series evaluation
00DD41  1  68                 PLA                     ; restore old FAC1 exponent
00DD42  1  C9 81              CMP   #$81              ; compare with 1
00DD44  1  90 07              BCC   LAB_2CC2          ; branch if FAC1<1
00DD46  1               
00DD46  1  A9 8F              LDA   #<LAB_2C78        ; set (pi/2) pointer low byte
00DD48  1  A0 E1              LDY   #>LAB_2C78        ; set (pi/2) pointer high byte
00DD4A  1  20 74 D5           JSR   LAB_2455          ; perform subtraction, (AY) from FAC1
00DD4D  1               LAB_2CC2
00DD4D  1  68                 PLA                     ; restore FAC1 sign
00DD4E  1  10 16              BPL   LAB_2D04          ; exit if was +ve
00DD50  1               
00DD50  1  4C C5 DB           JMP   LAB_GTHAN         ; else do - FAC1 and return
00DD53  1               
00DD53  1               ; perform BITSET
00DD53  1               
00DD53  1               LAB_BITSET
00DD53  1  20 A9 D4           JSR   LAB_GADB          ; get two parameters for POKE or WAIT
00DD56  1  E0 08              CPX   #$08              ; only 0 to 7 are allowed
00DD58  1  B0 20              BCS   FCError           ; branch if > 7
00DD5A  1               
00DD5A  1  A9 00              LDA   #$00              ; clear A
00DD5C  1  38                 SEC                     ; set the carry
00DD5D  1               S_Bits
00DD5D  1  2A                 ROL                     ; shift bit
00DD5E  1  CA                 DEX                     ; decrement bit number
00DD5F  1  10 FC              BPL   S_Bits            ; loop if still +ve
00DD61  1               
00DD61  1  E8                 INX                     ; make X = $00
00DD62  1  01 11              ORA   (Itempl,X)        ; or with byte via temporary integer (addr)
00DD64  1  81 11              STA   (Itempl,X)        ; save byte via temporary integer (addr)
00DD66  1               LAB_2D04
00DD66  1  60                 RTS
00DD67  1               
00DD67  1               ; perform BITCLR
00DD67  1               
00DD67  1               LAB_BITCLR
00DD67  1  20 A9 D4           JSR   LAB_GADB          ; get two parameters for POKE or WAIT
00DD6A  1  E0 08              CPX   #$08              ; only 0 to 7 are allowed
00DD6C  1  B0 0C              BCS   FCError           ; branch if > 7
00DD6E  1               
00DD6E  1  A9 FF              LDA   #$FF              ; set A
00DD70  1               S_Bitc
00DD70  1  2A                 ROL                     ; shift bit
00DD71  1  CA                 DEX                     ; decrement bit number
00DD72  1  10 FC              BPL   S_Bitc            ; loop if still +ve
00DD74  1               
00DD74  1  E8                 INX                     ; make X = $00
00DD75  1  21 11              AND   (Itempl,X)        ; and with byte via temporary integer (addr)
00DD77  1  81 11              STA   (Itempl,X)        ; save byte via temporary integer (addr)
00DD79  1  60                 RTS
00DD7A  1               
00DD7A  1               FCError
00DD7A  1  4C F8 CE           JMP   LAB_FCER          ; do function call error then warm start
00DD7D  1               
00DD7D  1               ; perform BITTST()
00DD7D  1               
00DD7D  1               LAB_BTST
00DD7D  1  20 BC 00           JSR   LAB_IGBY          ; increment BASIC pointer
00DD80  1  20 A9 D4           JSR   LAB_GADB          ; get two parameters for POKE or WAIT
00DD83  1  E0 08              CPX   #$08              ; only 0 to 7 are allowed
00DD85  1  B0 F3              BCS   FCError           ; branch if > 7
00DD87  1               
00DD87  1  20 C2 00           JSR   LAB_GBYT          ; get next BASIC byte
00DD8A  1  C9 29              CMP   #')'              ; is next character ")"
00DD8C  1  F0 03              BEQ   TST_OK            ; if ")" go do rest of function
00DD8E  1               
00DD8E  1  4C D1 CB           JMP   LAB_SNER          ; do syntax error then warm start
00DD91  1               
00DD91  1               TST_OK
00DD91  1  20 BC 00           JSR   LAB_IGBY          ; update BASIC execute pointer (to character past ")")
00DD94  1  A9 00              LDA   #$00              ; clear A
00DD96  1  38                 SEC                     ; set the carry
00DD97  1               T_Bits
00DD97  1  2A                 ROL                     ; shift bit
00DD98  1  CA                 DEX                     ; decrement bit number
00DD99  1  10 FC              BPL   T_Bits            ; loop if still +ve
00DD9B  1               
00DD9B  1  E8                 INX                     ; make X = $00
00DD9C  1  21 11              AND   (Itempl,X)        ; AND with byte via temporary integer (addr)
00DD9E  1  F0 02              BEQ   LAB_NOTT          ; branch if zero (already correct)
00DDA0  1               
00DDA0  1  A9 FF              LDA   #$FF              ; set for -1 result
00DDA2  1               LAB_NOTT
00DDA2  1  4C CB D8           JMP   LAB_27DB          ; go do SGN tail
00DDA5  1               
00DDA5  1               ; perform BIN$()
00DDA5  1               
00DDA5  1               LAB_BINS
00DDA5  1  E0 19              CPX   #$19              ; max + 1
00DDA7  1  B0 48              BCS   BinFErr           ; exit if too big ( > or = )
00DDA9  1               
00DDA9  1  86 78              STX   TempB             ; save # of characters ($00 = leading zero remove)
00DDAB  1  A9 18              LDA   #$18              ; need A byte long space
00DDAD  1  20 09 D1           JSR   LAB_MSSP          ; make string space A bytes long
00DDB0  1  A0 17              LDY   #$17              ; set index
00DDB2  1  A2 18              LDX   #$18              ; character count
00DDB4  1               NextB1
00DDB4  1  46 11              LSR   nums_1            ; shift highest byte
00DDB6  1  66 12              ROR   nums_2            ; shift middle byte
00DDB8  1  66 13              ROR   nums_3            ; shift lowest byte bit 0 to carry
00DDBA  1  8A                 TXA                     ; load with "0"/2
00DDBB  1  2A                 ROL                     ; shift in carry
00DDBC  1  91 AD              STA   (str_pl),Y        ; save to temp string + index
00DDBE  1  88                 DEY                     ; decrement index
00DDBF  1  10 F3              BPL   NextB1            ; loop if not done
00DDC1  1               
00DDC1  1  A5 78              LDA   TempB             ; get # of characters
00DDC3  1  F0 0A              BEQ   EndBHS            ; branch if truncate
00DDC5  1               
00DDC5  1  AA                 TAX                     ; copy length to X
00DDC6  1  38                 SEC                     ; set carry for add !
00DDC7  1  49 FF              EOR   #$FF              ; 1's complement
00DDC9  1  69 18              ADC   #$18              ; add 24d
00DDCB  1  F0 1C              BEQ   GoPr2             ; if zero print whole string
00DDCD  1               
00DDCD  1  D0 0F              BNE   GoPr1             ; else go make output string
00DDCF  1               
00DDCF  1               ; this is the exit code and is also used by HEX$()
00DDCF  1               ; truncate string to remove leading "0"s
00DDCF  1               
00DDCF  1               EndBHS
00DDCF  1  A8                 TAY                     ; clear index (A=0, X=length here)
00DDD0  1               NextB2
00DDD0  1  B1 AD              LDA   (str_pl),Y        ; get character from string
00DDD2  1  C9 30              CMP   #'0'              ; compare with "0"
00DDD4  1  D0 07              BNE   GoPr              ; if not "0" then go print string from here
00DDD6  1               
00DDD6  1  CA                 DEX                     ; decrement character count
00DDD7  1  F0 03              BEQ   GoPr3             ; if zero then end of string so go print it
00DDD9  1               
00DDD9  1  C8                 INY                     ; else increment index
00DDDA  1  10 F4              BPL   NextB2            ; loop always
00DDDC  1               
00DDDC  1               ; make fixed length output string - ignore overflows!
00DDDC  1               
00DDDC  1               GoPr3
00DDDC  1  E8                 INX                     ; need at least 1 character
00DDDD  1               GoPr
00DDDD  1  98                 TYA                     ; copy result
00DDDE  1               GoPr1
00DDDE  1  18                 CLC                     ; clear carry for add
00DDDF  1  65 AD              ADC   str_pl            ; add low address
00DDE1  1  85 AD              STA   str_pl            ; save low address
00DDE3  1  A9 00              LDA   #$00              ; do high byte
00DDE5  1  65 AE              ADC   str_ph            ; add high address
00DDE7  1  85 AE              STA   str_ph            ; save high address
00DDE9  1               GoPr2
00DDE9  1  86 AC              STX   str_ln            ; X holds string length
00DDEB  1  20 BC 00           JSR   LAB_IGBY          ; update BASIC execute pointer (to character past ")")
00DDEE  1  4C 56 D1           JMP   LAB_RTST          ; check for space on descriptor stack then put address
00DDF1  1                                             ; and length on descriptor stack and update stack pointers
00DDF1  1               
00DDF1  1               BinFErr
00DDF1  1  4C F8 CE           JMP   LAB_FCER          ; do function call error then warm start
00DDF4  1               
00DDF4  1               ; perform HEX$()
00DDF4  1               
00DDF4  1               LAB_HEXS
00DDF4  1  E0 07              CPX   #$07              ; max + 1
00DDF6  1  B0 F9              BCS   BinFErr           ; exit if too big ( > or = )
00DDF8  1               
00DDF8  1  86 78              STX   TempB             ; save # of characters
00DDFA  1               
00DDFA  1  A9 06              LDA   #$06              ; need 6 bytes for string
00DDFC  1  20 09 D1           JSR   LAB_MSSP          ; make string space A bytes long
00DDFF  1  A0 05              LDY   #$05              ; set string index
00DE01  1               
00DE01  1               ; *** disable decimal mode patch - comment next line ***
00DE01  1               ;      SED                     ; need decimal mode for nibble convert
00DE01  1  A5 13              LDA   nums_3            ; get lowest byte
00DE03  1  20 20 DE           JSR   LAB_A2HX          ; convert A to ASCII hex byte and output
00DE06  1  A5 12              LDA   nums_2            ; get middle byte
00DE08  1  20 20 DE           JSR   LAB_A2HX          ; convert A to ASCII hex byte and output
00DE0B  1  A5 11              LDA   nums_1            ; get highest byte
00DE0D  1  20 20 DE           JSR   LAB_A2HX          ; convert A to ASCII hex byte and output
00DE10  1               ; *** disable decimal mode patch - comment next line ***
00DE10  1               ;      CLD                     ; back to binary
00DE10  1               
00DE10  1  A2 06              LDX   #$06              ; character count
00DE12  1  A5 78              LDA   TempB             ; get # of characters
00DE14  1  F0 B9              BEQ   EndBHS            ; branch if truncate
00DE16  1               
00DE16  1  AA                 TAX                     ; copy length to X
00DE17  1  38                 SEC                     ; set carry for add !
00DE18  1  49 FF              EOR   #$FF              ; 1's complement
00DE1A  1  69 06              ADC   #$06              ; add 6d
00DE1C  1  F0 CB              BEQ   GoPr2             ; if zero print whole string
00DE1E  1               
00DE1E  1  D0 BE              BNE   GoPr1             ; else go make output string (branch always)
00DE20  1               
00DE20  1               ; convert A to ASCII hex byte and output .. note set decimal mode before calling
00DE20  1               
00DE20  1               LAB_A2HX
00DE20  1  AA                 TAX                     ; save byte
00DE21  1  29 0F              AND   #$0F              ; mask off top bits
00DE23  1  20 2B DE           JSR   LAB_AL2X          ; convert low nibble to ASCII and output
00DE26  1  8A                 TXA                     ; get byte back
00DE27  1  4A                 LSR                     ; /2  shift high nibble to low nibble
00DE28  1  4A                 LSR                     ; /4
00DE29  1  4A                 LSR                     ; /8
00DE2A  1  4A                 LSR                     ; /16
00DE2B  1               LAB_AL2X
00DE2B  1  C9 0A              CMP   #$0A              ; set carry for +1 if >9
00DE2D  1               ; *** begin disable decimal mode patch ***
00DE2D  1               ; *** insert
00DE2D  1  90 02              BCC   LAB_AL20          ; skip adjust if <= 9
00DE2F  1  69 06              ADC   #$06              ; adjust for A to F
00DE31  1               LAB_AL20
00DE31  1               ; *** end   disable decimal mode patch ***
00DE31  1  69 30              ADC   #'0'              ; add ASCII "0"
00DE33  1  91 AD              STA   (str_pl),Y        ; save to temp string
00DE35  1  88                 DEY                     ; decrement counter
00DE36  1  60                 RTS
00DE37  1               
00DE37  1               LAB_NLTO
00DE37  1  85 AC              STA   FAC1_e            ; save FAC1 exponent
00DE39  1  A9 00              LDA   #$00              ; clear sign compare
00DE3B  1               LAB_MLTE
00DE3B  1  85 B8              STA   FAC_sc            ; save sign compare (FAC1 EOR FAC2)
00DE3D  1  8A                 TXA                     ; restore character
00DE3E  1  20 16 DA           JSR   LAB_2912          ; evaluate new ASCII digit
00DE41  1               
00DE41  1               ; gets here if the first character was "$" for hex
00DE41  1               ; get hex number
00DE41  1               
00DE41  1               LAB_CHEX
00DE41  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00DE44  1  90 0A              BCC   LAB_ISHN          ; branch if numeric character
00DE46  1               
00DE46  1  09 20              ORA   #$20              ; case convert, allow "A" to "F" and "a" to "f"
00DE48  1  E9 61              SBC   #'a'              ; subtract "a" (carry set here)
00DE4A  1  C9 06              CMP   #$06              ; compare normalised with $06 (max+1)
00DE4C  1  B0 2A              BCS   LAB_EXCH          ; exit if >"f" or <"0"
00DE4E  1               
00DE4E  1  69 0A              ADC   #$0A              ; convert to nibble
00DE50  1               LAB_ISHN
00DE50  1  29 0F              AND   #$0F              ; convert to binary
00DE52  1  AA                 TAX                     ; save nibble
00DE53  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00DE55  1  F0 E4              BEQ   LAB_MLTE          ; skip multiply if zero
00DE57  1               
00DE57  1  69 04              ADC   #$04              ; add four to exponent (*16 - carry clear here)
00DE59  1  90 DC              BCC   LAB_NLTO          ; if no overflow do evaluate digit
00DE5B  1               
00DE5B  1               LAB_MLTO
00DE5B  1  4C 94 D6           JMP   LAB_2564          ; do overflow error and warm start
00DE5E  1               
00DE5E  1               LAB_NXCH
00DE5E  1  AA                 TAX                     ; save bit
00DE5F  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00DE61  1  F0 06              BEQ   LAB_MLBT          ; skip multiply if zero
00DE63  1               
00DE63  1  E6 AC              INC   FAC1_e            ; increment FAC1 exponent (*2)
00DE65  1  F0 F4              BEQ   LAB_MLTO          ; do overflow error if = $00
00DE67  1               
00DE67  1  A9 00              LDA   #$00              ; clear sign compare
00DE69  1               LAB_MLBT
00DE69  1  85 B8              STA   FAC_sc            ; save sign compare (FAC1 EOR FAC2)
00DE6B  1  8A                 TXA                     ; restore bit
00DE6C  1  20 16 DA           JSR   LAB_2912          ; evaluate new ASCII digit
00DE6F  1               
00DE6F  1               ; gets here if the first character was  "%" for binary
00DE6F  1               ; get binary number
00DE6F  1               
00DE6F  1               LAB_CBIN
00DE6F  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00DE72  1  49 30              EOR   #'0'              ; convert "0" to 0 etc.
00DE74  1  C9 02              CMP   #$02              ; compare with max+1
00DE76  1  90 E6              BCC   LAB_NXCH          ; branch exit if < 2
00DE78  1               
00DE78  1               LAB_EXCH
00DE78  1  4C FB D9           JMP   LAB_28F6          ; evaluate -ve flag and return
00DE7B  1               
00DE7B  1               ; ctrl-c check routine. includes limited "life" byte save for INGET routine
00DE7B  1               ; now also the code that checks to see if an interrupt has occurred
00DE7B  1               
00DE7B  1               CTRLC
00DE7B  1  AD 00 02           LDA   ccflag            ; get [CTRL-C] check flag
00DE7E  1  D0 18              BNE   LAB_FBA2          ; exit if inhibited
00DE80  1               
00DE80  1  20 BD E0           JSR   V_INPT            ; scan input device
00DE83  1  90 0B              BCC   LAB_FBA0          ; exit if buffer empty
00DE85  1               
00DE85  1  8D 01 02           STA   ccbyte            ; save received byte
00DE88  1  A2 20              LDX   #$20              ; "life" timer for bytes
00DE8A  1  8E 02 02           STX   ccnull            ; set countdown
00DE8D  1  4C EB C4           JMP   LAB_1636          ; return to BASIC
00DE90  1               
00DE90  1               LAB_FBA0
00DE90  1  AE 02 02           LDX   ccnull            ; get countdown byte
00DE93  1  F0 03              BEQ   LAB_FBA2          ; exit if finished
00DE95  1               
00DE95  1  CE 02 02           DEC   ccnull            ; else decrement countdown
00DE98  1               LAB_FBA2
00DE98  1  A2 DC              LDX   #NmiBase          ; set pointer to NMI values
00DE9A  1  20 A3 DE           JSR   LAB_CKIN          ; go check interrupt
00DE9D  1  A2 DF              LDX   #IrqBase          ; set pointer to IRQ values
00DE9F  1  20 A3 DE           JSR   LAB_CKIN          ; go check interrupt
00DEA2  1               LAB_CRTS
00DEA2  1  60                 RTS
00DEA3  1               
00DEA3  1               ; check whichever interrupt is indexed by X
00DEA3  1               
00DEA3  1               LAB_CKIN
00DEA3  1  B5 00              LDA   PLUS_0,X          ; get interrupt flag byte
00DEA5  1  10 FB              BPL   LAB_CRTS          ; branch if interrupt not enabled
00DEA7  1               
00DEA7  1               ; we disable the interrupt here and make two new commands RETIRQ and RETNMI to
00DEA7  1               ; automatically enable the interrupt when we exit
00DEA7  1               
00DEA7  1  0A                 ASL                     ; move happened bit to setup bit
00DEA8  1  29 40              AND   #$40              ; mask happened bits
00DEAA  1  F0 F6              BEQ   LAB_CRTS          ; if no interrupt then exit
00DEAC  1               
00DEAC  1  95 00              STA   PLUS_0,X          ; save interrupt flag byte
00DEAE  1               
00DEAE  1  8A                 TXA                     ; copy index ..
00DEAF  1  A8                 TAY                     ; .. to Y
00DEB0  1               
00DEB0  1  68                 PLA                     ; dump return address low byte, call from CTRL-C
00DEB1  1  68                 PLA                     ; dump return address high byte
00DEB2  1               
00DEB2  1  A9 05              LDA   #$05              ; need 5 bytes for GOSUB
00DEB4  1  20 C9 C0           JSR   LAB_1212          ; check room on stack for A bytes
00DEB7  1  A5 C4              LDA   Bpntrh            ; get BASIC execute pointer high byte
00DEB9  1  48                 PHA                     ; push on stack
00DEBA  1  A5 C3              LDA   Bpntrl            ; get BASIC execute pointer low byte
00DEBC  1  48                 PHA                     ; push on stack
00DEBD  1  A5 88              LDA   Clineh            ; get current line high byte
00DEBF  1  48                 PHA                     ; push on stack
00DEC0  1  A5 87              LDA   Clinel            ; get current line low byte
00DEC2  1  48                 PHA                     ; push on stack
00DEC3  1  A9 8D              LDA   #TK_GOSUB         ; token for GOSUB
00DEC5  1  48                 PHA                     ; push on stack
00DEC6  1               
00DEC6  1  B9 01 00           LDA   PLUS_1,Y          ; get interrupt code pointer low byte
00DEC9  1  85 C3              STA   Bpntrl            ; save as BASIC execute pointer low byte
00DECB  1  B9 02 00           LDA   PLUS_2,Y          ; get interrupt code pointer high byte
00DECE  1  85 C4              STA   Bpntrh            ; save as BASIC execute pointer high byte
00DED0  1               
00DED0  1  4C 92 C4           JMP   LAB_15C2          ; go do interpreter inner loop
00DED3  1                                             ; can't RTS, we used the stack! the RTS from the ctrl-c
00DED3  1                                             ; check will be taken when the RETIRQ/RETNMI/RETURN is
00DED3  1                                             ; executed at the end of the subroutine
00DED3  1               
00DED3  1               ; get byte from input device, no waiting
00DED3  1               ; returns with carry set if byte in A
00DED3  1               
00DED3  1               INGET
00DED3  1  20 BD E0           JSR   V_INPT            ; call scan input device
00DED6  1  B0 09              BCS   LAB_FB95          ; if byte go reset timer
00DED8  1               
00DED8  1  AD 02 02           LDA   ccnull            ; get countdown
00DEDB  1  F0 09              BEQ   LAB_FB96          ; exit if empty
00DEDD  1               
00DEDD  1  AD 01 02           LDA   ccbyte            ; get last received byte
00DEE0  1  38                 SEC                     ; flag we got a byte
00DEE1  1               LAB_FB95
00DEE1  1  A2 00              LDX   #$00              ; clear X
00DEE3  1  8E 02 02           STX   ccnull            ; clear timer because we got a byte
00DEE6  1               LAB_FB96
00DEE6  1  60                 RTS
00DEE7  1               
00DEE7  1               ; these routines only enable the interrupts if the set-up flag is set
00DEE7  1               ; if not they have no effect
00DEE7  1               
00DEE7  1               ; perform IRQ {ON|OFF|CLEAR}
00DEE7  1               
00DEE7  1               LAB_IRQ
00DEE7  1  A2 DF              LDX   #IrqBase          ; set pointer to IRQ values
00DEE9  1  2C                 .byte $2C               ; make next line BIT abs.
00DEEA  1               
00DEEA  1               ; perform NMI {ON|OFF|CLEAR}
00DEEA  1               
00DEEA  1               LAB_NMI
00DEEA  1  A2 DC              LDX   #NmiBase          ; set pointer to NMI values
00DEEC  1  C9 93              CMP   #TK_ON            ; compare with token for ON
00DEEE  1  F0 11              BEQ   LAB_INON          ; go turn on interrupt
00DEF0  1               
00DEF0  1  C9 B5              CMP   #TK_OFF           ; compare with token for OFF
00DEF2  1  F0 07              BEQ   LAB_IOFF          ; go turn off interrupt
00DEF4  1               
00DEF4  1  49 A2              EOR   #TK_CLEAR         ; compare with token for CLEAR, A = $00 if = TK_CLEAR
00DEF6  1  F0 0E              BEQ   LAB_INEX          ; go clear interrupt flags and return
00DEF8  1               
00DEF8  1  4C D1 CB           JMP   LAB_SNER          ; do syntax error then warm start
00DEFB  1               
00DEFB  1               LAB_IOFF
00DEFB  1  A9 7F              LDA   #$7F              ; clear A
00DEFD  1  35 00              AND   PLUS_0,X          ; AND with interrupt setup flag
00DEFF  1  10 05              BPL   LAB_INEX          ; go clear interrupt enabled flag and return
00DF01  1               
00DF01  1               LAB_INON
00DF01  1  B5 00              LDA   PLUS_0,X          ; get interrupt setup flag
00DF03  1  0A                 ASL                     ; Shift bit to enabled flag
00DF04  1  15 00              ORA   PLUS_0,X          ; OR with flag byte
00DF06  1               LAB_INEX
00DF06  1  95 00              STA   PLUS_0,X          ; save interrupt flag byte
00DF08  1  4C BC 00           JMP   LAB_IGBY          ; update BASIC execute pointer and return
00DF0B  1               
00DF0B  1               ; these routines set up the pointers and flags for the interrupt routines
00DF0B  1               ; note that the interrupts are also enabled by these commands
00DF0B  1               
00DF0B  1               ; perform ON IRQ
00DF0B  1               
00DF0B  1               LAB_SIRQ
00DF0B  1  58                 CLI                     ; enable interrupts
00DF0C  1  A2 DF              LDX   #IrqBase          ; set pointer to IRQ values
00DF0E  1  2C                 .byte $2C               ; make next line BIT abs.
00DF0F  1               
00DF0F  1               ; perform ON NMI
00DF0F  1               
00DF0F  1               LAB_SNMI
00DF0F  1  A2 DC              LDX   #NmiBase          ; set pointer to NMI values
00DF11  1               
00DF11  1  86 78              STX   TempB             ; save interrupt pointer
00DF13  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory (past token)
00DF16  1  20 25 C7           JSR   LAB_GFPN          ; get fixed-point number into temp integer
00DF19  1  A5 79              LDA   Smeml             ; get start of mem low byte
00DF1B  1  A6 7A              LDX   Smemh             ; get start of mem high byte
00DF1D  1  20 00 C3           JSR   LAB_SHLN          ; search Basic for temp integer line number from AX
00DF20  1  B0 03              BCS   LAB_LFND          ; if carry set go set-up interrupt
00DF22  1               
00DF22  1  4C 42 C6           JMP   LAB_16F7          ; else go do "Undefined statement" error and warm start
00DF25  1               
00DF25  1               LAB_LFND
00DF25  1  A6 78              LDX   TempB             ; get interrupt pointer
00DF27  1  A5 AA              LDA   Baslnl            ; get pointer low byte
00DF29  1  E9 01              SBC   #$01              ; -1 (carry already set for subtract)
00DF2B  1  95 01              STA   PLUS_1,X          ; save as interrupt pointer low byte
00DF2D  1  A5 AB              LDA   Baslnh            ; get pointer high byte
00DF2F  1  E9 00              SBC   #$00              ; subtract carry
00DF31  1  95 02              STA   PLUS_2,X          ; save as interrupt pointer high byte
00DF33  1               
00DF33  1  A9 C0              LDA   #$C0              ; set interrupt enabled/setup bits
00DF35  1  95 00              STA   PLUS_0,X          ; set interrupt flags
00DF37  1               LAB_IRTS
00DF37  1  60                 RTS
00DF38  1               
00DF38  1               ; return from IRQ service, restores the enabled flag.
00DF38  1               
00DF38  1               ; perform RETIRQ
00DF38  1               
00DF38  1               LAB_RETIRQ
00DF38  1  D0 FD              BNE   LAB_IRTS          ; exit if following token (to allow syntax error)
00DF3A  1               
00DF3A  1  A5 DF              LDA   IrqBase           ; get interrupt flags
00DF3C  1  0A                 ASL                     ; copy setup to enabled (b7)
00DF3D  1  05 DF              ORA   IrqBase           ; OR in setup flag
00DF3F  1  85 DF              STA   IrqBase           ; save enabled flag
00DF41  1  4C 49 C6           JMP   LAB_16E8          ; go do rest of RETURN
00DF44  1               
00DF44  1               ; return from NMI service, restores the enabled flag.
00DF44  1               
00DF44  1               ; perform RETNMI
00DF44  1               
00DF44  1               LAB_RETNMI
00DF44  1  D0 F1              BNE   LAB_IRTS          ; exit if following token (to allow syntax error)
00DF46  1               
00DF46  1  A5 DC              LDA   NmiBase           ; get set-up flag
00DF48  1  0A                 ASL                     ; copy setup to enabled (b7)
00DF49  1  05 DC              ORA   NmiBase           ; OR in setup flag
00DF4B  1  85 DC              STA   NmiBase           ; save enabled flag
00DF4D  1  4C 49 C6           JMP   LAB_16E8          ; go do rest of RETURN
00DF50  1               
00DF50  1               ; MAX() MIN() pre process
00DF50  1               
00DF50  1               LAB_MMPP
00DF50  1  20 B8 CA           JSR   LAB_EVEZ          ; process expression
00DF53  1  4C 9F CA           JMP   LAB_CTNM          ; check if source is numeric, else do type mismatch
00DF56  1               
00DF56  1               ; perform MAX()
00DF56  1               
00DF56  1               LAB_MAX
00DF56  1  20 84 DF           JSR   LAB_PHFA          ; push FAC1, evaluate expression,
00DF59  1                                             ; pull FAC2 and compare with FAC1
00DF59  1  10 FB              BPL   LAB_MAX           ; branch if no swap to do
00DF5B  1               
00DF5B  1  A5 B4              LDA   FAC2_1            ; get FAC2 mantissa1
00DF5D  1  09 80              ORA   #$80              ; set top bit (clear sign from compare)
00DF5F  1  85 B4              STA   FAC2_1            ; save FAC2 mantissa1
00DF61  1  20 94 D5           JSR   LAB_279B          ; copy FAC2 to FAC1
00DF64  1  F0 F0              BEQ   LAB_MAX           ; go do next (branch always)
00DF66  1               
00DF66  1               ; perform MIN()
00DF66  1               
00DF66  1               LAB_MIN
00DF66  1  20 84 DF           JSR   LAB_PHFA          ; push FAC1, evaluate expression,
00DF69  1                                             ; pull FAC2 and compare with FAC1
00DF69  1  30 FB              BMI   LAB_MIN           ; branch if no swap to do
00DF6B  1               
00DF6B  1  F0 F9              BEQ   LAB_MIN           ; branch if no swap to do
00DF6D  1               
00DF6D  1  A5 B4              LDA   FAC2_1            ; get FAC2 mantissa1
00DF6F  1  09 80              ORA   #$80              ; set top bit (clear sign from compare)
00DF71  1  85 B4              STA   FAC2_1            ; save FAC2 mantissa1
00DF73  1  20 94 D5           JSR   LAB_279B          ; copy FAC2 to FAC1
00DF76  1  F0 EE              BEQ   LAB_MIN           ; go do next (branch always)
00DF78  1               
00DF78  1               ; exit routine. don't bother returning to the loop code
00DF78  1               ; check for correct exit, else so syntax error
00DF78  1               
00DF78  1               LAB_MMEC
00DF78  1  C9 29              CMP   #')'              ; is it end of function?
00DF7A  1  D0 05              BNE   LAB_MMSE          ; if not do MAX MIN syntax error
00DF7C  1               
00DF7C  1  68                 PLA                     ; dump return address low byte
00DF7D  1  68                 PLA                     ; dump return address high byte
00DF7E  1  4C BC 00           JMP   LAB_IGBY          ; update BASIC execute pointer (to chr past ")")
00DF81  1               
00DF81  1               LAB_MMSE
00DF81  1  4C D1 CB           JMP   LAB_SNER          ; do syntax error then warm start
00DF84  1               
00DF84  1               ; check for next, evaluate and return or exit
00DF84  1               ; this is the routine that does most of the work
00DF84  1               
00DF84  1               LAB_PHFA
00DF84  1  20 C2 00           JSR   LAB_GBYT          ; get next BASIC byte
00DF87  1  C9 2C              CMP   #','              ; is there more ?
00DF89  1  D0 ED              BNE   LAB_MMEC          ; if not go do end check
00DF8B  1               
00DF8B  1                                             ; push FAC1
00DF8B  1  20 AA D8           JSR   LAB_27BA          ; round FAC1
00DF8E  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign
00DF90  1  09 7F              ORA   #$7F              ; set all non sign bits
00DF92  1  25 AD              AND   FAC1_1            ; AND FAC1 mantissa1 (AND in sign bit)
00DF94  1  48                 PHA                     ; push on stack
00DF95  1  A5 AE              LDA   FAC1_2            ; get FAC1 mantissa2
00DF97  1  48                 PHA                     ; push on stack
00DF98  1  A5 AF              LDA   FAC1_3            ; get FAC1 mantissa3
00DF9A  1  48                 PHA                     ; push on stack
00DF9B  1  A5 AC              LDA   FAC1_e            ; get FAC1 exponent
00DF9D  1  48                 PHA                     ; push on stack
00DF9E  1               
00DF9E  1  20 BC 00           JSR   LAB_IGBY          ; scan and get next BASIC byte (after ",")
00DFA1  1  20 9C CA           JSR   LAB_EVNM          ; evaluate expression and check is numeric,
00DFA4  1                                             ; else do type mismatch
00DFA4  1               
00DFA4  1                                             ; pop FAC2 (MAX/MIN expression so far)
00DFA4  1  68                 PLA                     ; pop exponent
00DFA5  1  85 B3              STA   FAC2_e            ; save FAC2 exponent
00DFA7  1  68                 PLA                     ; pop mantissa3
00DFA8  1  85 B6              STA   FAC2_3            ; save FAC2 mantissa3
00DFAA  1  68                 PLA                     ; pop mantissa1
00DFAB  1  85 B5              STA   FAC2_2            ; save FAC2 mantissa2
00DFAD  1  68                 PLA                     ; pop sign/mantissa1
00DFAE  1  85 B4              STA   FAC2_1            ; save FAC2 sign/mantissa1
00DFB0  1  85 B7              STA   FAC2_s            ; save FAC2 sign
00DFB2  1               
00DFB2  1                                             ; compare FAC1 with (packed) FAC2
00DFB2  1  A9 B3              LDA   #<FAC2_e          ; set pointer low byte to FAC2
00DFB4  1  A0 00              LDY   #>FAC2_e          ; set pointer high byte to FAC2
00DFB6  1  4C E8 D8           JMP   LAB_27F8          ; compare FAC1 with FAC2 (AY) and return
00DFB9  1                                             ; returns A=$00 if FAC1 = (AY)
00DFB9  1                                             ; returns A=$01 if FAC1 > (AY)
00DFB9  1                                             ; returns A=$FF if FAC1 < (AY)
00DFB9  1               
00DFB9  1               ; perform WIDTH
00DFB9  1               
00DFB9  1               LAB_WDTH
00DFB9  1  C9 2C              CMP   #','              ; is next byte ","
00DFBB  1  F0 1B              BEQ   LAB_TBSZ          ; if so do tab size
00DFBD  1               
00DFBD  1  20 5D D4           JSR   LAB_GTBY          ; get byte parameter
00DFC0  1  8A                 TXA                     ; copy width to A
00DFC1  1  F0 0A              BEQ   LAB_NSTT          ; branch if set for infinite line
00DFC3  1               
00DFC3  1  E0 10              CPX   #$10              ; else make min width = 16d
00DFC5  1  90 45              BCC   TabErr            ; if less do function call error and exit
00DFC7  1               
00DFC7  1               ; this next compare ensures that we can't exit WIDTH via an error leaving the
00DFC7  1               ; tab size greater than the line length.
00DFC7  1               
00DFC7  1  E4 64              CPX   TabSiz            ; compare with tab size
00DFC9  1  B0 02              BCS   LAB_NSTT          ; branch if >= tab size
00DFCB  1               
00DFCB  1  86 64              STX   TabSiz            ; else make tab size = terminal width
00DFCD  1               LAB_NSTT
00DFCD  1  86 0F              STX   TWidth            ; set the terminal width
00DFCF  1  20 C2 00           JSR   LAB_GBYT          ; get BASIC byte back
00DFD2  1  F0 1A              BEQ   WExit             ; exit if no following
00DFD4  1               
00DFD4  1  C9 2C              CMP   #','              ; else is it ","
00DFD6  1  D0 A9              BNE   LAB_MMSE          ; if not do syntax error
00DFD8  1               
00DFD8  1               LAB_TBSZ
00DFD8  1  20 5A D4           JSR   LAB_SGBY          ; scan and get byte parameter
00DFDB  1  8A                 TXA                     ; copy TAB size
00DFDC  1  30 2E              BMI   TabErr            ; if >127 do function call error and exit
00DFDE  1               
00DFDE  1  E0 01              CPX   #$01              ; compare with min-1
00DFE0  1  90 2A              BCC   TabErr            ; if <=1 do function call error and exit
00DFE2  1               
00DFE2  1  A5 0F              LDA   TWidth            ; set flags for width
00DFE4  1  F0 06              BEQ   LAB_SVTB          ; skip check if infinite line
00DFE6  1               
00DFE6  1  E4 0F              CPX   TWidth            ; compare TAB with width
00DFE8  1  F0 02              BEQ   LAB_SVTB          ; ok if =
00DFEA  1               
00DFEA  1  B0 20              BCS   TabErr            ; branch if too big
00DFEC  1               
00DFEC  1               LAB_SVTB
00DFEC  1  86 64              STX   TabSiz            ; save TAB size
00DFEE  1               
00DFEE  1               ; calculate tab column limit from TAB size. The Iclim is set to the last tab
00DFEE  1               ; position on a line that still has at least one whole tab width between it
00DFEE  1               ; and the end of the line.
00DFEE  1               
00DFEE  1               WExit
00DFEE  1  A5 0F              LDA   TWidth            ; get width
00DFF0  1  F0 06              BEQ   LAB_SULP          ; branch if infinite line
00DFF2  1               
00DFF2  1  C5 64              CMP   TabSiz            ; compare with tab size
00DFF4  1  B0 03              BCS   LAB_WDLP          ; branch if >= tab size
00DFF6  1               
00DFF6  1  85 64              STA   TabSiz            ; else make tab size = terminal width
00DFF8  1               LAB_SULP
00DFF8  1  38                 SEC                     ; set carry for subtract
00DFF9  1               LAB_WDLP
00DFF9  1  E5 64              SBC   TabSiz            ; subtract tab size
00DFFB  1  B0 FC              BCS   LAB_WDLP          ; loop while no borrow
00DFFD  1               
00DFFD  1  65 64              ADC   TabSiz            ; add tab size back
00DFFF  1  18                 CLC                     ; clear carry for add
00E000  1  65 64              ADC   TabSiz            ; add tab size back again
00E002  1  85 10              STA   Iclim             ; save for now
00E004  1  A5 0F              LDA   TWidth            ; get width back
00E006  1  38                 SEC                     ; set carry for subtract
00E007  1  E5 10              SBC   Iclim             ; subtract remainder
00E009  1  85 10              STA   Iclim             ; save tab column limit
00E00B  1               LAB_NOSQ
00E00B  1  60                 RTS
00E00C  1               
00E00C  1               TabErr
00E00C  1  4C F8 CE           JMP   LAB_FCER          ; do function call error then warm start
00E00F  1               
00E00F  1               ; perform SQR()
00E00F  1               
00E00F  1               LAB_SQR
00E00F  1  A5 B0              LDA   FAC1_s            ; get FAC1 sign
00E011  1  30 F9              BMI   TabErr            ; if -ve do function call error
00E013  1               
00E013  1  A5 AC              LDA   FAC1_e            ; get exponent
00E015  1  F0 F4              BEQ   LAB_NOSQ          ; if zero just return
00E017  1               
00E017  1                                             ; else do root
00E017  1  20 9B D8           JSR   LAB_27AB          ; round and copy FAC1 to FAC2
00E01A  1  A9 00              LDA   #$00              ; clear A
00E01C  1               
00E01C  1  85 77              STA   FACt_3            ; clear remainder
00E01E  1  85 76              STA   FACt_2            ; ..
00E020  1  85 75              STA   FACt_1            ; ..
00E022  1  85 78              STA   TempB             ; ..
00E024  1               
00E024  1  85 AF              STA   FAC1_3            ; clear root
00E026  1  85 AE              STA   FAC1_2            ; ..
00E028  1  85 AD              STA   FAC1_1            ; ..
00E02A  1               
00E02A  1  A2 18              LDX   #$18              ; 24 pairs of bits to do
00E02C  1  A5 B3              LDA   FAC2_e            ; get exponent
00E02E  1  4A                 LSR                     ; check odd/even
00E02F  1  B0 0E              BCS   LAB_SQE2          ; if odd only 1 shift first time
00E031  1               
00E031  1               LAB_SQE1
00E031  1  06 B6              ASL   FAC2_3            ; shift highest bit of number ..
00E033  1  26 B5              ROL   FAC2_2            ; ..
00E035  1  26 B4              ROL   FAC2_1            ; ..
00E037  1  26 77              ROL   FACt_3            ; .. into remainder
00E039  1  26 76              ROL   FACt_2            ; ..
00E03B  1  26 75              ROL   FACt_1            ; ..
00E03D  1  26 78              ROL   TempB             ; .. never overflows
00E03F  1               LAB_SQE2
00E03F  1  06 B6              ASL   FAC2_3            ; shift highest bit of number ..
00E041  1  26 B5              ROL   FAC2_2            ; ..
00E043  1  26 B4              ROL   FAC2_1            ; ..
00E045  1  26 77              ROL   FACt_3            ; .. into remainder
00E047  1  26 76              ROL   FACt_2            ; ..
00E049  1  26 75              ROL   FACt_1            ; ..
00E04B  1  26 78              ROL   TempB             ; .. never overflows
00E04D  1               
00E04D  1  06 AF              ASL   FAC1_3            ; root = root * 2
00E04F  1  26 AE              ROL   FAC1_2            ; ..
00E051  1  26 AD              ROL   FAC1_1            ; .. never overflows
00E053  1               
00E053  1  A5 AF              LDA   FAC1_3            ; get root low byte
00E055  1  2A                 ROL                     ; *2
00E056  1  85 5B              STA   Temp3             ; save partial low byte
00E058  1  A5 AE              LDA   FAC1_2            ; get root low mid byte
00E05A  1  2A                 ROL                     ; *2
00E05B  1  85 5C              STA   Temp3+1           ; save partial low mid byte
00E05D  1  A5 AD              LDA   FAC1_1            ; get root high mid byte
00E05F  1  2A                 ROL                     ; *2
00E060  1  85 5D              STA   Temp3+2           ; save partial high mid byte
00E062  1  A9 00              LDA   #$00              ; get root high byte (always $00)
00E064  1  2A                 ROL                     ; *2
00E065  1  85 5E              STA   Temp3+3           ; save partial high byte
00E067  1               
00E067  1                                             ; carry clear for subtract +1
00E067  1  A5 77              LDA   FACt_3            ; get remainder low byte
00E069  1  E5 5B              SBC   Temp3             ; subtract partial low byte
00E06B  1  85 5B              STA   Temp3             ; save partial low byte
00E06D  1               
00E06D  1  A5 76              LDA   FACt_2            ; get remainder low mid byte
00E06F  1  E5 5C              SBC   Temp3+1           ; subtract partial low mid byte
00E071  1  85 5C              STA   Temp3+1           ; save partial low mid byte
00E073  1               
00E073  1  A5 75              LDA   FACt_1            ; get remainder high mid byte
00E075  1  E5 5D              SBC   Temp3+2           ; subtract partial high mid byte
00E077  1  A8                 TAY                     ; copy partial high mid byte
00E078  1               
00E078  1  A5 78              LDA   TempB             ; get remainder high byte
00E07A  1  E5 5E              SBC   Temp3+3           ; subtract partial high byte
00E07C  1  90 0E              BCC   LAB_SQNS          ; skip sub if remainder smaller
00E07E  1               
00E07E  1  85 78              STA   TempB             ; save remainder high byte
00E080  1               
00E080  1  84 75              STY   FACt_1            ; save remainder high mid byte
00E082  1               
00E082  1  A5 5C              LDA   Temp3+1           ; get remainder low mid byte
00E084  1  85 76              STA   FACt_2            ; save remainder low mid byte
00E086  1               
00E086  1  A5 5B              LDA   Temp3             ; get partial low byte
00E088  1  85 77              STA   FACt_3            ; save remainder low byte
00E08A  1               
00E08A  1  E6 AF              INC   FAC1_3            ; increment root low byte (never any rollover)
00E08C  1               LAB_SQNS
00E08C  1  CA                 DEX                     ; decrement bit pair count
00E08D  1  D0 A2              BNE   LAB_SQE1          ; loop if not all done
00E08F  1               
00E08F  1  38                 SEC                     ; set carry for subtract
00E090  1  A5 B3              LDA   FAC2_e            ; get exponent
00E092  1  E9 80              SBC   #$80              ; normalise
00E094  1  6A                 ROR                     ; /2 and re-bias to $80
00E095  1  69 00              ADC   #$00              ; add bit zero back in (allow for half shift)
00E097  1  85 AC              STA   FAC1_e            ; save it
00E099  1  4C 05 D6           JMP   LAB_24D5          ; normalise FAC1 and return
00E09C  1               
00E09C  1               ; perform VARPTR()
00E09C  1               
00E09C  1               LAB_VARPTR
00E09C  1  20 BC 00           JSR   LAB_IGBY          ; increment and scan memory
00E09F  1  20 79 CD           JSR   LAB_GVAR          ; get var address
00E0A2  1  20 BE CB           JSR   LAB_1BFB          ; scan for ")" , else do syntax error then warm start
00E0A5  1  A4 95              LDY   Cvaral            ; get var address low byte
00E0A7  1  A5 96              LDA   Cvarah            ; get var address high byte
00E0A9  1  4C 28 D0           JMP   LAB_AYFC          ; save and convert integer AY to FAC1 and return
00E0AC  1               
00E0AC  1               ; perform PI
00E0AC  1               
00E0AC  1               LAB_PI
00E0AC  1  A9 A4              LDA   #<LAB_2C7C        ; set (2*pi) pointer low byte
00E0AE  1  A0 E1              LDY   #>LAB_2C7C        ; set (2*pi) pointer high byte
00E0B0  1  20 4E D8           JSR   LAB_UFAC          ; unpack memory (AY) into FAC1
00E0B3  1  C6 AC              DEC   FAC1_e            ; make result = PI
00E0B5  1  60                 RTS
00E0B6  1               
00E0B6  1               ; perform TWOPI
00E0B6  1               
00E0B6  1               LAB_TWOPI
00E0B6  1  A9 A4              LDA   #<LAB_2C7C        ; set (2*pi) pointer low byte
00E0B8  1  A0 E1              LDY   #>LAB_2C7C        ; set (2*pi) pointer high byte
00E0BA  1  4C 4E D8           JMP   LAB_UFAC          ; unpack memory (AY) into FAC1 and return
00E0BD  1               
00E0BD  1               ; system dependant i/o vectors
00E0BD  1               ; these are in RAM and are set by the monitor at start-up
00E0BD  1               .ifdef SXB
00E0BD  1                 .pushcpu
00E0BD  1                 .p816
00E0BD  1               .endif
00E0BD  1               V_INPT
00E0BD  1               .ifdef SXB
00E0BD  1  DA                 phx
00E0BE  1  5A                 phy
00E0BF  1  A2 00              ldx   #$00
00E0C1  1  FC 84 80           jsr   (TREADY,x)
00E0C4  1  18                 clc
00E0C5  1  F0 04              beq   :+
00E0C7  1  FC 86 80           jsr   (TRECV,x)
00E0CA  1  38                 sec
00E0CB  1  7A           :     ply
00E0CC  1  FA                 plx
00E0CD  1  09 00              ora   #$00
00E0CF  1  60                 rts
00E0D0  1               .else
00E0D0  1                     JMP   (VEC_IN)          ; non halting scan input device
00E0D0  1               .endif
00E0D0  1               V_OUTP
00E0D0  1               .ifdef SXB
00E0D0  1  48                 pha
00E0D1  1  DA                 phx
00E0D2  1  5A                 phy
00E0D3  1  A2 00              ldx   #$00
00E0D5  1  FC 88 80           jsr   (TSEND,x)
00E0D8  1  7A                 ply
00E0D9  1  FA                 plx
00E0DA  1  68                 pla
00E0DB  1  60                 rts
00E0DC  1               .else
00E0DC  1                     JMP   (VEC_OUT)         ; send byte to output device
00E0DC  1               .endif
00E0DC  1               V_LOAD
00E0DC  1               .ifdef SXB
00E0DC  1  60                 rts
00E0DD  1               .else
00E0DD  1                     JMP   (VEC_LD)          ; load BASIC program
00E0DD  1               .endif
00E0DD  1               V_SAVE
00E0DD  1               .ifdef SXB
00E0DD  1               .else
00E0DD  1                     JMP   (VEC_SV)          ; save BASIC program
00E0DD  1               .endif
00E0DD  1               .ifdef SXB
00E0DD  1                 .popcpu
00E0DD  1               .endif
00E0DD  1               
00E0DD  1               
00E0DD  1               ; The rest are tables messages and code for RAM
00E0DD  1               
00E0DD  1               ; the rest of the code is tables and BASIC start-up code
00E0DD  1               
00E0DD  1               PG2_TABS
00E0DD  1  00                 .byte $00               ; ctrl-c flag           -     $00 = enabled
00E0DE  1  00                 .byte $00               ; ctrl-c byte           -     GET needs this
00E0DF  1  00                 .byte $00               ; ctrl-c byte timeout   -     GET needs this
00E0E0  1  7B DE              .word CTRLC             ; ctrl c check vector
00E0E2  1               ;     .word xxxx              ; non halting key input -     monitor to set this
00E0E2  1               ;     .word xxxx              ; output vector         -     monitor to set this
00E0E2  1               ;     .word xxxx              ; load vector           -     monitor to set this
00E0E2  1               ;     .word xxxx              ; save vector           -     monitor to set this
00E0E2  1               PG2_TABE
00E0E2  1               
00E0E2  1               ; character get subroutine for zero page
00E0E2  1               
00E0E2  1               ; For a 1.8432MHz 6502 including the JSR and RTS
00E0E2  1               ; fastest (>=":") =  29 cycles =  15.7uS
00E0E2  1               ; slowest (<":")  =  40 cycles =  21.7uS
00E0E2  1               ; space skip      = +21 cycles = +11.4uS
00E0E2  1               ; inc across page =  +4 cycles =  +2.2uS
00E0E2  1               
00E0E2  1               ; the target address for the LDA at LAB_2CF4 becomes the BASIC execute pointer once the
00E0E2  1               ; block is copied to it's destination, any non zero page address will do at assembly
00E0E2  1               ; time, to assemble a three byte instruction.
00E0E2  1               
00E0E2  1               ; page 0 initialisation table from $BC
00E0E2  1               ; increment and scan memory
00E0E2  1               
00E0E2  1               LAB_2CEE
00E0E2  1  E6 C3              INC   z:Bpntrl            ; increment BASIC execute pointer low byte
00E0E4  1  D0 02              BNE   LAB_2CF4          ; branch if no carry
00E0E6  1                                             ; else
00E0E6  1  E6 C4              INC   z:Bpntrh            ; increment BASIC execute pointer high byte
00E0E8  1               
00E0E8  1               ; page 0 initialisation table from $C2
00E0E8  1               ; scan memory
00E0E8  1               
00E0E8  1               LAB_2CF4
00E0E8  1  AD FF FF           LDA   $FFFF             ; get byte to scan (addr set by call routine)
00E0EB  1  C9 AC              CMP   #TK_ELSE          ; compare with the token for ELSE
00E0ED  1  F0 0E              BEQ   LAB_2D05          ; exit if ELSE, not numeric, carry set
00E0EF  1               
00E0EF  1  C9 3A              CMP   #':'              ; compare with ":"
00E0F1  1  B0 0A              BCS   LAB_2D05          ; exit if >= ":", not numeric, carry set
00E0F3  1               
00E0F3  1  C9 20              CMP   #' '              ; compare with " "
00E0F5  1  F0 EB              BEQ   LAB_2CEE          ; if " " go do next
00E0F7  1               
00E0F7  1  38                 SEC                     ; set carry for SBC
00E0F8  1  E9 30              SBC   #'0'              ; subtract "0"
00E0FA  1  38                 SEC                     ; set carry for SBC
00E0FB  1  E9 D0              SBC   #$D0              ; subtract -"0"
00E0FD  1                                             ; clear carry if byte = "0"-"9"
00E0FD  1               LAB_2D05
00E0FD  1  60                 RTS
00E0FE  1               
00E0FE  1               ; page zero initialisation table $00-$12 inclusive
00E0FE  1               
00E0FE  1               StrTab
00E0FE  1  4C                 .byte $4C               ; JMP opcode
00E0FF  1  00 C0              .word LAB_COLD          ; initial warm start vector (cold start)
00E101  1               
00E101  1  00                 .byte $00               ; these bytes are not used by BASIC
00E102  1  00 00              .word $0000             ;
00E104  1  00 00              .word $0000             ;
00E106  1  00 00              .word $0000             ;
00E108  1               
00E108  1  4C                 .byte $4C               ; JMP opcode
00E109  1  F8 CE              .word LAB_FCER          ; initial user function vector ("Function call" error)
00E10B  1  00                 .byte $00               ; default NULL count
00E10C  1  00                 .byte $00               ; clear terminal position
00E10D  1  00                 .byte $00               ; default terminal width byte
00E10E  1  F2                 .byte $F2               ; default limit for TAB = 14
00E10F  1  00 04              .word Ram_base          ; start of user RAM
00E111  1               EndTab
00E111  1               
00E111  1               LAB_MSZM
00E111  1  0D 0A 4D 65        .byte $0D,$0A,"Memory size ",$00
00E115  1  6D 6F 72 79  
00E119  1  20 73 69 7A  
00E120  1               
00E120  1               LAB_SMSG
00E120  1  20 42 79 74        .byte " Bytes free",$0D,$0A,$0A
00E124  1  65 73 20 66  
00E128  1  72 65 65 0D  
00E12E  1  45 6E 68 61        .byte "Enhanced BASIC 2.22p3",$0A,$00
00E132  1  6E 63 65 64  
00E136  1  20 42 41 53  
00E145  1               
00E145  1               ; numeric constants and series
00E145  1               
00E145  1                                             ; constants and series for LOG(n)
00E145  1               LAB_25A0
00E145  1  02                 .byte $02               ; counter
00E146  1  80 19 56 62        .byte $80,$19,$56,$62   ; 0.59898
00E14A  1  80 76 22 F3        .byte $80,$76,$22,$F3   ; 0.96147
00E14E  1               ;##   .byte $80,$76,$22,$F1   ; 0.96147
00E14E  1  82 38 AA 40        .byte $82,$38,$AA,$40   ; 2.88539
00E152  1               ;##   .byte $82,$38,$AA,$45   ; 2.88539
00E152  1               
00E152  1               LAB_25AD
00E152  1  80 35 04 F3        .byte $80,$35,$04,$F3   ; 0.70711   1/root 2
00E156  1               LAB_25B1
00E156  1  81 35 04 F3        .byte $81,$35,$04,$F3   ; 1.41421   root 2
00E15A  1               LAB_25B5
00E15A  1  80 80 00 00        .byte $80,$80,$00,$00   ; -0.5
00E15E  1               LAB_25B9
00E15E  1  80 31 72 18        .byte $80,$31,$72,$18   ; 0.69315   LOG(2)
00E162  1               
00E162  1                                             ; numeric PRINT constants
00E162  1               LAB_2947
00E162  1  91 43 4F F8        .byte $91,$43,$4F,$F8   ; 99999.9375 (max value with at least one decimal)
00E166  1               LAB_294B
00E166  1  94 74 23 F7        .byte $94,$74,$23,$F7   ; 999999.4375 (max value before scientific notation)
00E16A  1               LAB_294F
00E16A  1  94 74 24 00        .byte $94,$74,$24,$00   ; 1000000
00E16E  1               
00E16E  1                                             ; EXP(n) constants and series
00E16E  1               LAB_2AFA
00E16E  1  81 38 AA 3B        .byte $81,$38,$AA,$3B   ; 1.4427    (1/LOG base 2 e)
00E172  1               LAB_2AFE
00E172  1  06                 .byte $06               ; counter
00E173  1  74 63 90 8C        .byte $74,$63,$90,$8C   ; 2.17023e-4
00E177  1  77 23 0C AB        .byte $77,$23,$0C,$AB   ; 0.00124
00E17B  1  7A 1E 94 00        .byte $7A,$1E,$94,$00   ; 0.00968
00E17F  1  7C 63 42 80        .byte $7C,$63,$42,$80   ; 0.05548
00E183  1  7E 75 FE D0        .byte $7E,$75,$FE,$D0   ; 0.24023
00E187  1  80 31 72 15        .byte $80,$31,$72,$15   ; 0.69315
00E18B  1  81 00 00 00        .byte $81,$00,$00,$00   ; 1.00000
00E18F  1               
00E18F  1               ;##   .byte $07               ; counter
00E18F  1               ;##   .byte $74,$94,$2E,$40   ; -1/7! (-1/5040)
00E18F  1               ;##   .byte $77,$2E,$4F,$70   ;  1/6! ( 1/720)
00E18F  1               ;##   .byte $7A,$88,$02,$6E   ; -1/5! (-1/120)
00E18F  1               ;##   .byte $7C,$2A,$A0,$E6   ;  1/4! ( 1/24)
00E18F  1               ;##   .byte $7E,$AA,$AA,$50   ; -1/3! (-1/6)
00E18F  1               ;##   .byte $7F,$7F,$FF,$FF   ;  1/2! ( 1/2)
00E18F  1               ;##   .byte $81,$80,$00,$00   ; -1/1! (-1/1)
00E18F  1               ;##   .byte $81,$00,$00,$00   ;  1/0! ( 1/1)
00E18F  1               
00E18F  1                                             ; trigonometric constants and series
00E18F  1               LAB_2C78
00E18F  1  81 49 0F DB        .byte $81,$49,$0F,$DB   ; 1.570796371 (pi/2) as floating #
00E193  1               LAB_2C84
00E193  1  04                 .byte $04               ; counter
00E194  1  86 1E D7 FB        .byte $86,$1E,$D7,$FB   ; 39.7109
00E198  1               ;##   .byte $86,$1E,$D7,$BA   ; 39.7109
00E198  1  87 99 26 65        .byte $87,$99,$26,$65   ;-76.575
00E19C  1               ;##   .byte $87,$99,$26,$64   ;-76.575
00E19C  1  87 23 34 58        .byte $87,$23,$34,$58   ; 81.6022
00E1A0  1  86 A5 5D E1        .byte $86,$A5,$5D,$E1   ;-41.3417
00E1A4  1               ;##   .byte $86,$A5,$5D,$E0   ;-41.3417
00E1A4  1               LAB_2C7C
00E1A4  1  83 49 0F DB        .byte $83,$49,$0F,$DB   ; 6.28319 (2*pi) as floating #
00E1A8  1               ;##   .byte $83,$49,$0F,$DA   ; 6.28319 (2*pi) as floating #
00E1A8  1               
00E1A8  1               LAB_2CC9
00E1A8  1  08                 .byte $08               ; counter
00E1A9  1  78 3A C5 37        .byte $78,$3A,$C5,$37   ; 0.00285
00E1AD  1  7B 83 A2 5C        .byte $7B,$83,$A2,$5C   ;-0.0160686
00E1B1  1  7C 2E DD 4D        .byte $7C,$2E,$DD,$4D   ; 0.0426915
00E1B5  1  7D 99 B0 1E        .byte $7D,$99,$B0,$1E   ;-0.0750429
00E1B9  1  7D 59 ED 24        .byte $7D,$59,$ED,$24   ; 0.106409
00E1BD  1  7E 91 72 00        .byte $7E,$91,$72,$00   ;-0.142036
00E1C1  1  7E 4C B9 73        .byte $7E,$4C,$B9,$73   ; 0.199926
00E1C5  1  7F AA AA 53        .byte $7F,$AA,$AA,$53   ;-0.333331
00E1C9  1               
00E1C9  1               ;##   .byte $08               ; counter
00E1C9  1               ;##   .byte $78,$3B,$D7,$4A   ; 1/17
00E1C9  1               ;##   .byte $7B,$84,$6E,$02   ;-1/15
00E1C9  1               ;##   .byte $7C,$2F,$C1,$FE   ; 1/13
00E1C9  1               ;##   .byte $7D,$9A,$31,$74   ;-1/11
00E1C9  1               ;##   .byte $7D,$5A,$3D,$84   ; 1/9
00E1C9  1               ;##   .byte $7E,$91,$7F,$C8   ;-1/7
00E1C9  1               ;##   .byte $7E,$4C,$BB,$E4   ; 1/5
00E1C9  1               ;##   .byte $7F,$AA,$AA,$6C   ;-1/3
00E1C9  1               
00E1C9  1               LAB_1D96    = *+1             ; $00,$00 used for undefined variables
00E1C9  1               LAB_259C
00E1C9  1  81 00 00 00        .byte $81,$00,$00,$00   ; 1.000000, used for INC
00E1CD  1               LAB_2AFD
00E1CD  1  81 80 00 00        .byte $81,$80,$00,$00   ; -1.00000, used for DEC. must be on the same page as +1.00
00E1D1  1               
00E1D1  1                                             ; misc constants
00E1D1  1               LAB_1DF7
00E1D1  1  90                 .byte $90               ;-32768 (uses first three bytes from 0.5)
00E1D2  1               LAB_2A96
00E1D2  1  80 00 00 00        .byte $80,$00,$00,$00   ; 0.5
00E1D6  1               LAB_2C80
00E1D6  1  7F 00 00 00        .byte $7F,$00,$00,$00   ; 0.25
00E1DA  1               LAB_26B5
00E1DA  1  84 20 00 00        .byte $84,$20,$00,$00   ; 10.0000 divide by 10 constant
00E1DE  1               
00E1DE  1               ; This table is used in converting numbers to ASCII.
00E1DE  1               
00E1DE  1               LAB_2A9A
00E1DE  1               LAB_2A9B = LAB_2A9A+1
00E1DE  1               LAB_2A9C = LAB_2A9B+1
00E1DE  1  FE 79 60           .byte $FE,$79,$60       ; -100000
00E1E1  1  00 27 10           .byte $00,$27,$10       ; 10000
00E1E4  1  FF FC 18           .byte $FF,$FC,$18       ; -1000
00E1E7  1  00 00 64           .byte $00,$00,$64       ; 100
00E1EA  1  FF FF F6           .byte $FF,$FF,$F6       ; -10
00E1ED  1  00 00 01           .byte $00,$00,$01       ; 1
00E1F0  1               
00E1F0  1               LAB_CTBL
00E1F0  1  EE C4              .word LAB_END-1         ; END
00E1F2  1  2D C4              .word LAB_FOR-1         ; FOR
00E1F4  1  33 CA              .word LAB_NEXT-1        ; NEXT
00E1F6  1  5B C6              .word LAB_DATA-1        ; DATA
00E1F8  1  16 C9              .word LAB_INPUT-1       ; INPUT
00E1FA  1  2D CD              .word LAB_DIM-1         ; DIM
00E1FC  1  35 C9              .word LAB_READ-1        ; READ
00E1FE  1  83 C7              .word LAB_LET-1         ; LET
00E200  1  55 C7              .word LAB_DEC-1         ; DEC             new command
00E202  1  BA C5              .word LAB_GOTO-1        ; GOTO
00E204  1  79 C5              .word LAB_RUN-1         ; RUN
00E206  1  89 C6              .word LAB_IF-1          ; IF
00E208  1  0F C5              .word LAB_RESTORE-1     ; RESTORE         modified command
00E20A  1  9D C5              .word LAB_GOSUB-1       ; GOSUB
00E20C  1  37 DF              .word LAB_RETIRQ-1      ; RETIRQ          new command
00E20E  1  43 DF              .word LAB_RETNMI-1      ; RETNMI          new command
00E210  1  46 C6              .word LAB_RETURN-1      ; RETURN
00E212  1  ED C6              .word LAB_REM-1         ; REM
00E214  1  EC C4              .word LAB_STOP-1        ; STOP
00E216  1  F6 C6              .word LAB_ON-1          ; ON              modified command
00E218  1  4D C5              .word LAB_NULL-1        ; NULL            modified command
00E21A  1  58 C7              .word LAB_INC-1         ; INC             new command
00E21C  1  59 D5              .word LAB_WAIT-1        ; WAIT
00E21E  1  DB E0              .word V_LOAD-1          ; LOAD
00E220  1  DC E0              .word V_SAVE-1          ; SAVE
00E222  1  42 D0              .word LAB_DEF-1         ; DEF
00E224  1  DE D4              .word LAB_POKE-1        ; POKE
00E226  1  FA D4              .word LAB_DOKE-1        ; DOKE            new command
00E228  1  47 D5              .word LAB_CALL-1        ; CALL            new command
00E22A  1  83 C5              .word LAB_DO-1          ; DO              new command
00E22C  1  EC C5              .word LAB_LOOP-1        ; LOOP            new command
00E22E  1  24 C8              .word LAB_PRINT-1       ; PRINT
00E230  1  53 C5              .word LAB_CONT-1        ; CONT
00E232  1  78 C3              .word LAB_LIST-1        ; LIST
00E234  1  75 C3              .word LAB_CLEAR-1       ; CLEAR
00E236  1  25 C3              .word LAB_NEW-1         ; NEW
00E238  1  B8 DF              .word LAB_WDTH-1        ; WIDTH           new command
00E23A  1  F3 C7              .word LAB_GET-1         ; GET             new command
00E23C  1  1F D5              .word LAB_SWAP-1        ; SWAP            new command
00E23E  1  52 DD              .word LAB_BITSET-1      ; BITSET          new command
00E240  1  66 DD              .word LAB_BITCLR-1      ; BITCLR          new command
00E242  1  E6 DE              .word LAB_IRQ-1         ; IRQ             new command
00E244  1  E9 DE              .word LAB_NMI-1         ; NMI             new command
00E246  1               
00E246  1               ; function pre process routine table
00E246  1               
00E246  1               LAB_FTPL
00E246  1               LAB_FTPM    = LAB_FTPL+$01
00E246  1  33 CC              .word LAB_PPFN-1        ; SGN(n)    process numeric expression in ()
00E248  1  33 CC              .word LAB_PPFN-1        ; INT(n)          "
00E24A  1  33 CC              .word LAB_PPFN-1        ; ABS(n)          "
00E24C  1  B7 CA              .word LAB_EVEZ-1        ; USR(x)    process any expression
00E24E  1  BA CB              .word LAB_1BF7-1        ; FRE(x)          "
00E250  1  BA CB              .word LAB_1BF7-1        ; POS(x)          "
00E252  1  33 CC              .word LAB_PPFN-1        ; SQR(n)    process numeric expression in ()
00E254  1  33 CC              .word LAB_PPFN-1        ; RND(n)          "
00E256  1  33 CC              .word LAB_PPFN-1        ; LOG(n)          "
00E258  1  33 CC              .word LAB_PPFN-1        ; EXP(n)          "
00E25A  1  33 CC              .word LAB_PPFN-1        ; COS(n)          "
00E25C  1  33 CC              .word LAB_PPFN-1        ; SIN(n)          "
00E25E  1  33 CC              .word LAB_PPFN-1        ; TAN(n)          "
00E260  1  33 CC              .word LAB_PPFN-1        ; ATN(n)          "
00E262  1  33 CC              .word LAB_PPFN-1        ; PEEK(n)         "
00E264  1  33 CC              .word LAB_PPFN-1        ; DEEK(n)         "
00E266  1  00 00              .word $0000             ; SADD()    none
00E268  1  2D CC              .word LAB_PPFS-1        ; LEN($)    process string expression in ()
00E26A  1  33 CC              .word LAB_PPFN-1        ; STR$(n)   process numeric expression in ()
00E26C  1  2D CC              .word LAB_PPFS-1        ; VAL($)    process string expression in ()
00E26E  1  2D CC              .word LAB_PPFS-1        ; ASC($)          "
00E270  1  2D CC              .word LAB_PPFS-1        ; UCASE$($)       "
00E272  1  2D CC              .word LAB_PPFS-1        ; LCASE$($)       "
00E274  1  33 CC              .word LAB_PPFN-1        ; CHR$(n)   process numeric expression in ()
00E276  1  5A CC              .word LAB_BHSS-1        ; HEX$(n)         "
00E278  1  5A CC              .word LAB_BHSS-1        ; BIN$(n)         "
00E27A  1  00 00              .word $0000             ; BITTST()  none
00E27C  1  4F DF              .word LAB_MMPP-1        ; MAX()     process numeric expression
00E27E  1  4F DF              .word LAB_MMPP-1        ; MIN()           "
00E280  1  39 CC              .word LAB_PPBI-1        ; PI        advance pointer
00E282  1  39 CC              .word LAB_PPBI-1        ; TWOPI           "
00E284  1  00 00              .word $0000             ; VARPTR()  none
00E286  1  3E CC              .word LAB_LRMS-1        ; LEFT$()   process string expression
00E288  1  3E CC              .word LAB_LRMS-1        ; RIGHT$()        "
00E28A  1  3E CC              .word LAB_LRMS-1        ; MID$()          "
00E28C  1               
00E28C  1               ; action addresses for functions
00E28C  1               
00E28C  1               LAB_FTBL
00E28C  1               LAB_FTBM    = LAB_FTBL+$01
00E28C  1  C7 D8              .word LAB_SGN-1         ; SGN()
00E28E  1  51 D9              .word LAB_INT-1         ; INT()
00E290  1  E4 D8              .word LAB_ABS-1         ; ABS()
00E292  1  1D DD              .word LAB_USR-1         ; USR()
00E294  1  13 D0              .word LAB_FRE-1         ; FRE()
00E296  1  32 D0              .word LAB_POS-1         ; POS()
00E298  1  0E E0              .word LAB_SQR-1         ; SQR()
00E29A  1  6D DC              .word LAB_RND-1         ; RND()           modified function
00E29C  1  CB D6              .word LAB_LOG-1         ; LOG()
00E29E  1  CF DB              .word LAB_EXP-1         ; EXP()
00E2A0  1  A1 DC              .word LAB_COS-1         ; COS()
00E2A2  1  A8 DC              .word LAB_SIN-1         ; SIN()
00E2A4  1  F1 DC              .word LAB_TAN-1         ; TAN()
00E2A6  1  23 DD              .word LAB_ATN-1         ; ATN()
00E2A8  1  D3 D4              .word LAB_PEEK-1        ; PEEK()
00E2AA  1  E7 D4              .word LAB_DEEK-1        ; DEEK()          new function
00E2AC  1  25 D4              .word LAB_SADD-1        ; SADD()          new function
00E2AE  1  3E D4              .word LAB_LENS-1        ; LEN()
00E2B0  1  F4 D0              .word LAB_STRS-1        ; STR$()
00E2B2  1  6B D4              .word LAB_VAL-1         ; VAL()
00E2B4  1  49 D4              .word LAB_ASC-1         ; ASC()
00E2B6  1  03 D4              .word LAB_UCASE-1       ; UCASE$()        new function
00E2B8  1  E2 D3              .word LAB_LCASE-1       ; LCASE$()        new function
00E2BA  1  54 D3              .word LAB_CHRS-1        ; CHR$()
00E2BC  1  F3 DD              .word LAB_HEXS-1        ; HEX$()          new function
00E2BE  1  A4 DD              .word LAB_BINS-1        ; BIN$()          new function
00E2C0  1  7C DD              .word LAB_BTST-1        ; BITTST()        new function
00E2C2  1  55 DF              .word LAB_MAX-1         ; MAX()           new function
00E2C4  1  65 DF              .word LAB_MIN-1         ; MIN()           new function
00E2C6  1  AB E0              .word LAB_PI-1          ; PI              new function
00E2C8  1  B5 E0              .word LAB_TWOPI-1       ; TWOPI           new function
00E2CA  1  9B E0              .word LAB_VARPTR-1      ; VARPTR()        new function
00E2CC  1  66 D3              .word LAB_LEFT-1        ; LEFT$()
00E2CE  1  6F D3              .word LAB_RIGHT-1       ; RIGHT$()
00E2D0  1  9E D3              .word LAB_MIDS-1        ; MID$()
00E2D2  1               
00E2D2  1               ; hierarchy and action addresses for operator
00E2D2  1               
00E2D2  1               LAB_OPPT
00E2D2  1  79                 .byte $79               ; +
00E2D3  1  91 D5              .word LAB_ADD-1
00E2D5  1  79                 .byte $79               ; -
00E2D6  1  76 D5              .word LAB_SUBTRACT-1
00E2D8  1  7B                 .byte $7B               ; *
00E2D9  1  0C D7              .word LAB_MULTIPLY-1
00E2DB  1  7B                 .byte $7B               ; /
00E2DC  1  D4 D7              .word LAB_DIVIDE-1
00E2DE  1  7F                 .byte $7F               ; ^
00E2DF  1  8B DB              .word LAB_POWER-1
00E2E1  1  50                 .byte $50               ; AND
00E2E2  1  A3 CC              .word LAB_AND-1
00E2E4  1  46                 .byte $46               ; EOR             new operator
00E2E5  1  89 CC              .word LAB_EOR-1
00E2E7  1  46                 .byte $46               ; OR
00E2E8  1  96 CC              .word LAB_OR-1
00E2EA  1  56                 .byte $56               ; >>              new operator
00E2EB  1  4F CD              .word LAB_RSHIFT-1
00E2ED  1  56                 .byte $56               ; <<              new operator
00E2EE  1  37 CD              .word LAB_LSHIFT-1
00E2F0  1  7D                 .byte $7D               ; >
00E2F1  1  C4 DB              .word LAB_GTHAN-1
00E2F3  1  5A                 .byte $5A               ; =
00E2F4  1  E5 CB              .word LAB_EQUAL-1
00E2F6  1  64                 .byte $64               ; <
00E2F7  1  C4 CC              .word LAB_LTHAN-1
00E2F9  1               
00E2F9  1               ; keywords start with ..
00E2F9  1               ; this is the first character table and must be in alphabetic order
00E2F9  1               
00E2F9  1               TAB_1STC
00E2F9  1  2A                 .byte "*"
00E2FA  1  2B                 .byte "+"
00E2FB  1  2D                 .byte "-"
00E2FC  1  2F                 .byte "/"
00E2FD  1  3C                 .byte "<"
00E2FE  1  3D                 .byte "="
00E2FF  1  3E                 .byte ">"
00E300  1  3F                 .byte "?"
00E301  1  41                 .byte "A"
00E302  1  42                 .byte "B"
00E303  1  43                 .byte "C"
00E304  1  44                 .byte "D"
00E305  1  45                 .byte "E"
00E306  1  46                 .byte "F"
00E307  1  47                 .byte "G"
00E308  1  48                 .byte "H"
00E309  1  49                 .byte "I"
00E30A  1  4C                 .byte "L"
00E30B  1  4D                 .byte "M"
00E30C  1  4E                 .byte "N"
00E30D  1  4F                 .byte "O"
00E30E  1  50                 .byte "P"
00E30F  1  52                 .byte "R"
00E310  1  53                 .byte "S"
00E311  1  54                 .byte "T"
00E312  1  55                 .byte "U"
00E313  1  56                 .byte "V"
00E314  1  57                 .byte "W"
00E315  1  5E                 .byte "^"
00E316  1  00                 .byte $00               ; table terminator
00E317  1               
00E317  1               ; pointers to keyword tables
00E317  1               
00E317  1               TAB_CHRT
00E317  1  51 E3              .word TAB_STAR          ; table for "*"
00E319  1  53 E3              .word TAB_PLUS          ; table for "+"
00E31B  1  55 E3              .word TAB_MNUS          ; table for "-"
00E31D  1  57 E3              .word TAB_SLAS          ; table for "/"
00E31F  1  59 E3              .word TAB_LESS          ; table for "<"
00E321  1  5D E3              .word TAB_EQUL          ; table for "="
00E323  1  5F E3              .word TAB_MORE          ; table for ">"
00E325  1  63 E3              .word TAB_QEST          ; table for "?"
00E327  1  65 E3              .word TAB_ASCA          ; table for "A"
00E329  1  75 E3              .word TAB_ASCB          ; table for "B"
00E32B  1  8E E3              .word TAB_ASCC          ; table for "C"
00E32D  1  A5 E3              .word TAB_ASCD          ; table for "D"
00E32F  1  BE E3              .word TAB_ASCE          ; table for "E"
00E331  1  CD E3              .word TAB_ASCF          ; table for "F"
00E333  1  D7 E3              .word TAB_ASCG          ; table for "G"
00E335  1  E4 E3              .word TAB_ASCH          ; table for "H"
00E337  1  EA E3              .word TAB_ASCI          ; table for "I"
00E339  1  FC E3              .word TAB_ASCL          ; table for "L"
00E33B  1  21 E4              .word TAB_ASCM          ; table for "M"
00E33D  1  2F E4              .word TAB_ASCN          ; table for "N"
00E33F  1  41 E4              .word TAB_ASCO          ; table for "O"
00E341  1  49 E4              .word TAB_ASCP          ; table for "P"
00E343  1  5E E4              .word TAB_ASCR          ; table for "R"
00E345  1  8D E4              .word TAB_ASCS          ; table for "S"
00E347  1  B8 E4              .word TAB_ASCT          ; table for "T"
00E349  1  CC E4              .word TAB_ASCU          ; table for "U"
00E34B  1  DD E4              .word TAB_ASCV          ; table for "V"
00E34D  1  E9 E4              .word TAB_ASCW          ; table for "W"
00E34F  1  F8 E4              .word TAB_POWR          ; table for "^"
00E351  1               
00E351  1               ; tables for each start character, note if a longer keyword with the same start
00E351  1               ; letters as a shorter one exists then it must come first, else the list is in
00E351  1               ; alphabetical order as follows ..
00E351  1               
00E351  1               ; [keyword,token
00E351  1               ; [keyword,token]]
00E351  1               ; end marker (#$00)
00E351  1               
00E351  1               TAB_STAR
00E351  1  B8 00              .byte TK_MUL,$00        ; *
00E353  1               TAB_PLUS
00E353  1  B6 00              .byte TK_PLUS,$00       ; +
00E355  1               TAB_MNUS
00E355  1  B7 00              .byte TK_MINUS,$00      ; -
00E357  1               TAB_SLAS
00E357  1  B9 00              .byte TK_DIV,$00        ; /
00E359  1               TAB_LESS
00E359  1               LBB_LSHIFT
00E359  1  3C BF              .byte "<",TK_LSHIFT     ; <<  note - "<<" must come before "<"
00E35B  1  C2                 .byte TK_LT             ; <
00E35C  1  00                 .byte $00
00E35D  1               TAB_EQUL
00E35D  1  C1 00              .byte TK_EQUAL,$00      ; =
00E35F  1               TAB_MORE
00E35F  1               LBB_RSHIFT
00E35F  1  3E BE              .byte ">",TK_RSHIFT     ; >>  note - ">>" must come before ">"
00E361  1  C0                 .byte TK_GT             ; >
00E362  1  00                 .byte $00
00E363  1               TAB_QEST
00E363  1  9F 00              .byte TK_PRINT,$00      ; ?
00E365  1               TAB_ASCA
00E365  1               LBB_ABS
00E365  1  42 53 28 C5        .byte "BS(",TK_ABS      ; ABS(
00E369  1               LBB_AND
00E369  1  4E 44 BB           .byte "ND",TK_AND       ; AND
00E36C  1               LBB_ASC
00E36C  1  53 43 28 D7        .byte "SC(",TK_ASC      ; ASC(
00E370  1               LBB_ATN
00E370  1  54 4E 28 D0        .byte "TN(",TK_ATN      ; ATN(
00E374  1  00                 .byte $00
00E375  1               TAB_ASCB
00E375  1               LBB_BINS
00E375  1  49 4E 24 28        .byte "IN$(",TK_BINS    ; BIN$(
00E379  1  DC           
00E37A  1               LBB_BITCLR
00E37A  1  49 54 43 4C        .byte "ITCLR",TK_BITCLR ; BITCLR
00E37E  1  52 A8        
00E380  1               LBB_BITSET
00E380  1  49 54 53 45        .byte "ITSET",TK_BITSET ; BITSET
00E384  1  54 A7        
00E386  1               LBB_BITTST
00E386  1  49 54 54 53        .byte "ITTST(",TK_BITTST
00E38A  1  54 28 DD     
00E38D  1                                             ; BITTST(
00E38D  1  00                 .byte $00
00E38E  1               TAB_ASCC
00E38E  1               LBB_CALL
00E38E  1  41 4C 4C 9C        .byte "ALL",TK_CALL     ; CALL
00E392  1               LBB_CHRS
00E392  1  48 52 24 28        .byte "HR$(",TK_CHRS    ; CHR$(
00E396  1  DA           
00E397  1               LBB_CLEAR
00E397  1  4C 45 41 52        .byte "LEAR",TK_CLEAR   ; CLEAR
00E39B  1  A2           
00E39C  1               LBB_CONT
00E39C  1  4F 4E 54 A0        .byte "ONT",TK_CONT     ; CONT
00E3A0  1               LBB_COS
00E3A0  1  4F 53 28 CD        .byte "OS(",TK_COS      ; COS(
00E3A4  1  00                 .byte $00
00E3A5  1               TAB_ASCD
00E3A5  1               LBB_DATA
00E3A5  1  41 54 41 83        .byte "ATA",TK_DATA     ; DATA
00E3A9  1               LBB_DEC
00E3A9  1  45 43 88           .byte "EC",TK_DEC       ; DEC
00E3AC  1               LBB_DEEK
00E3AC  1  45 45 4B 28        .byte "EEK(",TK_DEEK    ; DEEK(
00E3B0  1  D2           
00E3B1  1               LBB_DEF
00E3B1  1  45 46 99           .byte "EF",TK_DEF       ; DEF
00E3B4  1               LBB_DIM
00E3B4  1  49 4D 85           .byte "IM",TK_DIM       ; DIM
00E3B7  1               LBB_DOKE
00E3B7  1  4F 4B 45 9B        .byte "OKE",TK_DOKE     ; DOKE note - "DOKE" must come before "DO"
00E3BB  1               LBB_DO
00E3BB  1  4F 9D              .byte "O",TK_DO         ; DO
00E3BD  1  00                 .byte $00
00E3BE  1               TAB_ASCE
00E3BE  1               LBB_ELSE
00E3BE  1  4C 53 45 AC        .byte "LSE",TK_ELSE     ; ELSE
00E3C2  1               LBB_END
00E3C2  1  4E 44 80           .byte "ND",TK_END       ; END
00E3C5  1               LBB_EOR
00E3C5  1  4F 52 BC           .byte "OR",TK_EOR       ; EOR
00E3C8  1               LBB_EXP
00E3C8  1  58 50 28 CC        .byte "XP(",TK_EXP      ; EXP(
00E3CC  1  00                 .byte $00
00E3CD  1               TAB_ASCF
00E3CD  1               LBB_FN
00E3CD  1  4E AE              .byte "N",TK_FN         ; FN
00E3CF  1               LBB_FOR
00E3CF  1  4F 52 81           .byte "OR",TK_FOR       ; FOR
00E3D2  1               LBB_FRE
00E3D2  1  52 45 28 C7        .byte "RE(",TK_FRE      ; FRE(
00E3D6  1  00                 .byte $00
00E3D7  1               TAB_ASCG
00E3D7  1               LBB_GET
00E3D7  1  45 54 A5           .byte "ET",TK_GET       ; GET
00E3DA  1               LBB_GOSUB
00E3DA  1  4F 53 55 42        .byte "OSUB",TK_GOSUB   ; GOSUB
00E3DE  1  8D           
00E3DF  1               LBB_GOTO
00E3DF  1  4F 54 4F 89        .byte "OTO",TK_GOTO     ; GOTO
00E3E3  1  00                 .byte $00
00E3E4  1               TAB_ASCH
00E3E4  1               LBB_HEXS
00E3E4  1  45 58 24 28        .byte "EX$(",TK_HEXS    ; HEX$(
00E3E8  1  DB           
00E3E9  1  00                 .byte $00
00E3EA  1               TAB_ASCI
00E3EA  1               LBB_IF
00E3EA  1  46 8B              .byte "F",TK_IF         ; IF
00E3EC  1               LBB_INC
00E3EC  1  4E 43 95           .byte "NC",TK_INC       ; INC
00E3EF  1               LBB_INPUT
00E3EF  1  4E 50 55 54        .byte "NPUT",TK_INPUT   ; INPUT
00E3F3  1  84           
00E3F4  1               LBB_INT
00E3F4  1  4E 54 28 C4        .byte "NT(",TK_INT      ; INT(
00E3F8  1               LBB_IRQ
00E3F8  1  52 51 A9           .byte "RQ",TK_IRQ       ; IRQ
00E3FB  1  00                 .byte $00
00E3FC  1               TAB_ASCL
00E3FC  1               LBB_LCASES
00E3FC  1  43 41 53 45        .byte "CASE$(",TK_LCASES
00E400  1  24 28 D9     
00E403  1                                             ; LCASE$(
00E403  1               LBB_LEFTS
00E403  1  45 46 54 24        .byte "EFT$(",TK_LEFTS  ; LEFT$(
00E407  1  28 E3        
00E409  1               LBB_LEN
00E409  1  45 4E 28 D4        .byte "EN(",TK_LEN      ; LEN(
00E40D  1               LBB_LET
00E40D  1  45 54 87           .byte "ET",TK_LET       ; LET
00E410  1               LBB_LIST
00E410  1  49 53 54 A1        .byte "IST",TK_LIST     ; LIST
00E414  1               LBB_LOAD
00E414  1  4F 41 44 97        .byte "OAD",TK_LOAD     ; LOAD
00E418  1               LBB_LOG
00E418  1  4F 47 28 CB        .byte "OG(",TK_LOG      ; LOG(
00E41C  1               LBB_LOOP
00E41C  1  4F 4F 50 9E        .byte "OOP",TK_LOOP     ; LOOP
00E420  1  00                 .byte $00
00E421  1               TAB_ASCM
00E421  1               LBB_MAX
00E421  1  41 58 28 DE        .byte "AX(",TK_MAX      ; MAX(
00E425  1               LBB_MIDS
00E425  1  49 44 24 28        .byte "ID$(",TK_MIDS    ; MID$(
00E429  1  E5           
00E42A  1               LBB_MIN
00E42A  1  49 4E 28 DF        .byte "IN(",TK_MIN      ; MIN(
00E42E  1  00                 .byte $00
00E42F  1               TAB_ASCN
00E42F  1               LBB_NEW
00E42F  1  45 57 A3           .byte "EW",TK_NEW       ; NEW
00E432  1               LBB_NEXT
00E432  1  45 58 54 82        .byte "EXT",TK_NEXT     ; NEXT
00E436  1               LBB_NMI
00E436  1  4D 49 AA           .byte "MI",TK_NMI       ; NMI
00E439  1               LBB_NOT
00E439  1  4F 54 B1           .byte "OT",TK_NOT       ; NOT
00E43C  1               LBB_NULL
00E43C  1  55 4C 4C 94        .byte "ULL",TK_NULL     ; NULL
00E440  1  00                 .byte $00
00E441  1               TAB_ASCO
00E441  1               LBB_OFF
00E441  1  46 46 B5           .byte "FF",TK_OFF       ; OFF
00E444  1               LBB_ON
00E444  1  4E 93              .byte "N",TK_ON         ; ON
00E446  1               LBB_OR
00E446  1  52 BD              .byte "R",TK_OR         ; OR
00E448  1  00                 .byte $00
00E449  1               TAB_ASCP
00E449  1               LBB_PEEK
00E449  1  45 45 4B 28        .byte "EEK(",TK_PEEK    ; PEEK(
00E44D  1  D1           
00E44E  1               LBB_PI
00E44E  1  49 E0              .byte "I",TK_PI         ; PI
00E450  1               LBB_POKE
00E450  1  4F 4B 45 9A        .byte "OKE",TK_POKE     ; POKE
00E454  1               LBB_POS
00E454  1  4F 53 28 C8        .byte "OS(",TK_POS      ; POS(
00E458  1               LBB_PRINT
00E458  1  52 49 4E 54        .byte "RINT",TK_PRINT   ; PRINT
00E45C  1  9F           
00E45D  1  00                 .byte $00
00E45E  1               TAB_ASCR
00E45E  1               LBB_READ
00E45E  1  45 41 44 86        .byte "EAD",TK_READ     ; READ
00E462  1               LBB_REM
00E462  1  45 4D 91           .byte "EM",TK_REM       ; REM
00E465  1               LBB_RESTORE
00E465  1  45 53 54 4F        .byte "ESTORE",TK_RESTORE
00E469  1  52 45 8C     
00E46C  1                                             ; RESTORE
00E46C  1               LBB_RETIRQ
00E46C  1  45 54 49 52        .byte "ETIRQ",TK_RETIRQ ; RETIRQ
00E470  1  51 8E        
00E472  1               LBB_RETNMI
00E472  1  45 54 4E 4D        .byte "ETNMI",TK_RETNMI ; RETNMI
00E476  1  49 8F        
00E478  1               LBB_RETURN
00E478  1  45 54 55 52        .byte "ETURN",TK_RETURN ; RETURN
00E47C  1  4E 90        
00E47E  1               LBB_RIGHTS
00E47E  1  49 47 48 54        .byte "IGHT$(",TK_RIGHTS
00E482  1  24 28 E4     
00E485  1                                             ; RIGHT$(
00E485  1               LBB_RND
00E485  1  4E 44 28 CA        .byte "ND(",TK_RND      ; RND(
00E489  1               LBB_RUN
00E489  1  55 4E 8A           .byte "UN",TK_RUN       ; RUN
00E48C  1  00                 .byte $00
00E48D  1               TAB_ASCS
00E48D  1               LBB_SADD
00E48D  1  41 44 44 28        .byte "ADD(",TK_SADD    ; SADD(
00E491  1  D3           
00E492  1               LBB_SAVE
00E492  1  41 56 45 98        .byte "AVE",TK_SAVE     ; SAVE
00E496  1               LBB_SGN
00E496  1  47 4E 28 C3        .byte "GN(",TK_SGN      ; SGN(
00E49A  1               LBB_SIN
00E49A  1  49 4E 28 CE        .byte "IN(",TK_SIN      ; SIN(
00E49E  1               LBB_SPC
00E49E  1  50 43 28 AF        .byte "PC(",TK_SPC      ; SPC(
00E4A2  1               LBB_SQR
00E4A2  1  51 52 28 C9        .byte "QR(",TK_SQR      ; SQR(
00E4A6  1               LBB_STEP
00E4A6  1  54 45 50 B2        .byte "TEP",TK_STEP     ; STEP
00E4AA  1               LBB_STOP
00E4AA  1  54 4F 50 92        .byte "TOP",TK_STOP     ; STOP
00E4AE  1               LBB_STRS
00E4AE  1  54 52 24 28        .byte "TR$(",TK_STRS    ; STR$(
00E4B2  1  D5           
00E4B3  1               LBB_SWAP
00E4B3  1  57 41 50 A6        .byte "WAP",TK_SWAP     ; SWAP
00E4B7  1  00                 .byte $00
00E4B8  1               TAB_ASCT
00E4B8  1               LBB_TAB
00E4B8  1  41 42 28 AB        .byte "AB(",TK_TAB      ; TAB(
00E4BC  1               LBB_TAN
00E4BC  1  41 4E 28 CF        .byte "AN(",TK_TAN      ; TAN(
00E4C0  1               LBB_THEN
00E4C0  1  48 45 4E B0        .byte "HEN",TK_THEN     ; THEN
00E4C4  1               LBB_TO
00E4C4  1  4F AD              .byte "O",TK_TO         ; TO
00E4C6  1               LBB_TWOPI
00E4C6  1  57 4F 50 49        .byte "WOPI",TK_TWOPI   ; TWOPI
00E4CA  1  E1           
00E4CB  1  00                 .byte $00
00E4CC  1               TAB_ASCU
00E4CC  1               LBB_UCASES
00E4CC  1  43 41 53 45        .byte "CASE$(",TK_UCASES
00E4D0  1  24 28 D8     
00E4D3  1                                             ; UCASE$(
00E4D3  1               LBB_UNTIL
00E4D3  1  4E 54 49 4C        .byte "NTIL",TK_UNTIL   ; UNTIL
00E4D7  1  B3           
00E4D8  1               LBB_USR
00E4D8  1  53 52 28 C6        .byte "SR(",TK_USR      ; USR(
00E4DC  1  00                 .byte $00
00E4DD  1               TAB_ASCV
00E4DD  1               LBB_VAL
00E4DD  1  41 4C 28 D6        .byte "AL(",TK_VAL      ; VAL(
00E4E1  1               LBB_VPTR
00E4E1  1  41 52 50 54        .byte "ARPTR(",TK_VPTR  ; VARPTR(
00E4E5  1  52 28 E2     
00E4E8  1  00                 .byte $00
00E4E9  1               TAB_ASCW
00E4E9  1               LBB_WAIT
00E4E9  1  41 49 54 96        .byte "AIT",TK_WAIT     ; WAIT
00E4ED  1               LBB_WHILE
00E4ED  1  48 49 4C 45        .byte "HILE",TK_WHILE   ; WHILE
00E4F1  1  B4           
00E4F2  1               LBB_WIDTH
00E4F2  1  49 44 54 48        .byte "IDTH",TK_WIDTH   ; WIDTH
00E4F6  1  A4           
00E4F7  1  00                 .byte $00
00E4F8  1               TAB_POWR
00E4F8  1  BA 00              .byte TK_POWER,$00      ; ^
00E4FA  1               
00E4FA  1               ; new decode table for LIST
00E4FA  1               ; Table is ..
00E4FA  1               ; byte - keyword length, keyword first character
00E4FA  1               ; word - pointer to rest of keyword from dictionary
00E4FA  1               
00E4FA  1               ; note if length is 1 then the pointer is ignored
00E4FA  1               
00E4FA  1               LAB_KEYT
00E4FA  1  03 45              .byte 3,'E'
00E4FC  1  C2 E3              .word LBB_END           ; END
00E4FE  1  03 46              .byte 3,'F'
00E500  1  CF E3              .word LBB_FOR           ; FOR
00E502  1  04 4E              .byte 4,'N'
00E504  1  32 E4              .word LBB_NEXT          ; NEXT
00E506  1  04 44              .byte 4,'D'
00E508  1  A5 E3              .word LBB_DATA          ; DATA
00E50A  1  05 49              .byte 5,'I'
00E50C  1  EF E3              .word LBB_INPUT         ; INPUT
00E50E  1  03 44              .byte 3,'D'
00E510  1  B4 E3              .word LBB_DIM           ; DIM
00E512  1  04 52              .byte 4,'R'
00E514  1  5E E4              .word LBB_READ          ; READ
00E516  1  03 4C              .byte 3,'L'
00E518  1  0D E4              .word LBB_LET           ; LET
00E51A  1  03 44              .byte 3,'D'
00E51C  1  A9 E3              .word LBB_DEC           ; DEC
00E51E  1  04 47              .byte 4,'G'
00E520  1  DF E3              .word LBB_GOTO          ; GOTO
00E522  1  03 52              .byte 3,'R'
00E524  1  89 E4              .word LBB_RUN           ; RUN
00E526  1  02 49              .byte 2,'I'
00E528  1  EA E3              .word LBB_IF            ; IF
00E52A  1  07 52              .byte 7,'R'
00E52C  1  65 E4              .word LBB_RESTORE       ; RESTORE
00E52E  1  05 47              .byte 5,'G'
00E530  1  DA E3              .word LBB_GOSUB         ; GOSUB
00E532  1  06 52              .byte 6,'R'
00E534  1  6C E4              .word LBB_RETIRQ        ; RETIRQ
00E536  1  06 52              .byte 6,'R'
00E538  1  72 E4              .word LBB_RETNMI        ; RETNMI
00E53A  1  06 52              .byte 6,'R'
00E53C  1  78 E4              .word LBB_RETURN        ; RETURN
00E53E  1  03 52              .byte 3,'R'
00E540  1  62 E4              .word LBB_REM           ; REM
00E542  1  04 53              .byte 4,'S'
00E544  1  AA E4              .word LBB_STOP          ; STOP
00E546  1  02 4F              .byte 2,'O'
00E548  1  44 E4              .word LBB_ON            ; ON
00E54A  1  04 4E              .byte 4,'N'
00E54C  1  3C E4              .word LBB_NULL          ; NULL
00E54E  1  03 49              .byte 3,'I'
00E550  1  EC E3              .word LBB_INC           ; INC
00E552  1  04 57              .byte 4,'W'
00E554  1  E9 E4              .word LBB_WAIT          ; WAIT
00E556  1  04 4C              .byte 4,'L'
00E558  1  14 E4              .word LBB_LOAD          ; LOAD
00E55A  1  04 53              .byte 4,'S'
00E55C  1  92 E4              .word LBB_SAVE          ; SAVE
00E55E  1  03 44              .byte 3,'D'
00E560  1  B1 E3              .word LBB_DEF           ; DEF
00E562  1  04 50              .byte 4,'P'
00E564  1  50 E4              .word LBB_POKE          ; POKE
00E566  1  04 44              .byte 4,'D'
00E568  1  B7 E3              .word LBB_DOKE          ; DOKE
00E56A  1  04 43              .byte 4,'C'
00E56C  1  8E E3              .word LBB_CALL          ; CALL
00E56E  1  02 44              .byte 2,'D'
00E570  1  BB E3              .word LBB_DO            ; DO
00E572  1  04 4C              .byte 4,'L'
00E574  1  1C E4              .word LBB_LOOP          ; LOOP
00E576  1  05 50              .byte 5,'P'
00E578  1  58 E4              .word LBB_PRINT         ; PRINT
00E57A  1  04 43              .byte 4,'C'
00E57C  1  9C E3              .word LBB_CONT          ; CONT
00E57E  1  04 4C              .byte 4,'L'
00E580  1  10 E4              .word LBB_LIST          ; LIST
00E582  1  05 43              .byte 5,'C'
00E584  1  97 E3              .word LBB_CLEAR         ; CLEAR
00E586  1  03 4E              .byte 3,'N'
00E588  1  2F E4              .word LBB_NEW           ; NEW
00E58A  1  05 57              .byte 5,'W'
00E58C  1  F2 E4              .word LBB_WIDTH         ; WIDTH
00E58E  1  03 47              .byte 3,'G'
00E590  1  D7 E3              .word LBB_GET           ; GET
00E592  1  04 53              .byte 4,'S'
00E594  1  B3 E4              .word LBB_SWAP          ; SWAP
00E596  1  06 42              .byte 6,'B'
00E598  1  80 E3              .word LBB_BITSET        ; BITSET
00E59A  1  06 42              .byte 6,'B'
00E59C  1  7A E3              .word LBB_BITCLR        ; BITCLR
00E59E  1  03 49              .byte 3,'I'
00E5A0  1  F8 E3              .word LBB_IRQ           ; IRQ
00E5A2  1  03 4E              .byte 3,'N'
00E5A4  1  36 E4              .word LBB_NMI           ; NMI
00E5A6  1               
00E5A6  1               ; secondary commands (can't start a statement)
00E5A6  1               
00E5A6  1  04 54              .byte 4,'T'
00E5A8  1  B8 E4              .word LBB_TAB           ; TAB
00E5AA  1  04 45              .byte 4,'E'
00E5AC  1  BE E3              .word LBB_ELSE          ; ELSE
00E5AE  1  02 54              .byte 2,'T'
00E5B0  1  C4 E4              .word LBB_TO            ; TO
00E5B2  1  02 46              .byte 2,'F'
00E5B4  1  CD E3              .word LBB_FN            ; FN
00E5B6  1  04 53              .byte 4,'S'
00E5B8  1  9E E4              .word LBB_SPC           ; SPC
00E5BA  1  04 54              .byte 4,'T'
00E5BC  1  C0 E4              .word LBB_THEN          ; THEN
00E5BE  1  03 4E              .byte 3,'N'
00E5C0  1  39 E4              .word LBB_NOT           ; NOT
00E5C2  1  04 53              .byte 4,'S'
00E5C4  1  A6 E4              .word LBB_STEP          ; STEP
00E5C6  1  05 55              .byte 5,'U'
00E5C8  1  D3 E4              .word LBB_UNTIL         ; UNTIL
00E5CA  1  05 57              .byte 5,'W'
00E5CC  1  ED E4              .word LBB_WHILE         ; WHILE
00E5CE  1  03 4F              .byte 3,'O'
00E5D0  1  41 E4              .word LBB_OFF           ; OFF
00E5D2  1               
00E5D2  1               ; opperators
00E5D2  1               
00E5D2  1  01 2B              .byte 1,'+'
00E5D4  1  00 00              .word $0000             ; +
00E5D6  1  01 2D              .byte 1,'-'
00E5D8  1  00 00              .word $0000             ; -
00E5DA  1  01 2A              .byte 1,'*'
00E5DC  1  00 00              .word $0000             ; *
00E5DE  1  01 2F              .byte 1,'/'
00E5E0  1  00 00              .word $0000             ; /
00E5E2  1  01 5E              .byte 1,'^'
00E5E4  1  00 00              .word $0000             ; ^
00E5E6  1  03 41              .byte 3,'A'
00E5E8  1  69 E3              .word LBB_AND           ; AND
00E5EA  1  03 45              .byte 3,'E'
00E5EC  1  C5 E3              .word LBB_EOR           ; EOR
00E5EE  1  02 4F              .byte 2,'O'
00E5F0  1  46 E4              .word LBB_OR            ; OR
00E5F2  1  02 3E              .byte 2,'>'
00E5F4  1  5F E3              .word LBB_RSHIFT        ; >>
00E5F6  1  02 3C              .byte 2,'<'
00E5F8  1  59 E3              .word LBB_LSHIFT        ; <<
00E5FA  1  01 3E              .byte 1,'>'
00E5FC  1  00 00              .word $0000             ; >
00E5FE  1  01 3D              .byte 1,'='
00E600  1  00 00              .word $0000             ; =
00E602  1  01 3C              .byte 1,'<'
00E604  1  00 00              .word $0000             ; <
00E606  1               
00E606  1               ; functions
00E606  1               
00E606  1  04 53              .byte 4,'S'             ;
00E608  1  96 E4              .word LBB_SGN           ; SGN
00E60A  1  04 49              .byte 4,'I'             ;
00E60C  1  F4 E3              .word LBB_INT           ; INT
00E60E  1  04 41              .byte 4,'A'             ;
00E610  1  65 E3              .word LBB_ABS           ; ABS
00E612  1  04 55              .byte 4,'U'             ;
00E614  1  D8 E4              .word LBB_USR           ; USR
00E616  1  04 46              .byte 4,'F'             ;
00E618  1  D2 E3              .word LBB_FRE           ; FRE
00E61A  1  04 50              .byte 4,'P'             ;
00E61C  1  54 E4              .word LBB_POS           ; POS
00E61E  1  04 53              .byte 4,'S'             ;
00E620  1  A2 E4              .word LBB_SQR           ; SQR
00E622  1  04 52              .byte 4,'R'             ;
00E624  1  85 E4              .word LBB_RND           ; RND
00E626  1  04 4C              .byte 4,'L'             ;
00E628  1  18 E4              .word LBB_LOG           ; LOG
00E62A  1  04 45              .byte 4,'E'             ;
00E62C  1  C8 E3              .word LBB_EXP           ; EXP
00E62E  1  04 43              .byte 4,'C'             ;
00E630  1  A0 E3              .word LBB_COS           ; COS
00E632  1  04 53              .byte 4,'S'             ;
00E634  1  9A E4              .word LBB_SIN           ; SIN
00E636  1  04 54              .byte 4,'T'             ;
00E638  1  BC E4              .word LBB_TAN           ; TAN
00E63A  1  04 41              .byte 4,'A'             ;
00E63C  1  70 E3              .word LBB_ATN           ; ATN
00E63E  1  05 50              .byte 5,'P'             ;
00E640  1  49 E4              .word LBB_PEEK          ; PEEK
00E642  1  05 44              .byte 5,'D'             ;
00E644  1  AC E3              .word LBB_DEEK          ; DEEK
00E646  1  05 53              .byte 5,'S'             ;
00E648  1  8D E4              .word LBB_SADD          ; SADD
00E64A  1  04 4C              .byte 4,'L'             ;
00E64C  1  09 E4              .word LBB_LEN           ; LEN
00E64E  1  05 53              .byte 5,'S'             ;
00E650  1  AE E4              .word LBB_STRS          ; STR$
00E652  1  04 56              .byte 4,'V'             ;
00E654  1  DD E4              .word LBB_VAL           ; VAL
00E656  1  04 41              .byte 4,'A'             ;
00E658  1  6C E3              .word LBB_ASC           ; ASC
00E65A  1  07 55              .byte 7,'U'             ;
00E65C  1  CC E4              .word LBB_UCASES        ; UCASE$
00E65E  1  07 4C              .byte 7,'L'             ;
00E660  1  FC E3              .word LBB_LCASES        ; LCASE$
00E662  1  05 43              .byte 5,'C'             ;
00E664  1  92 E3              .word LBB_CHRS          ; CHR$
00E666  1  05 48              .byte 5,'H'             ;
00E668  1  E4 E3              .word LBB_HEXS          ; HEX$
00E66A  1  05 42              .byte 5,'B'             ;
00E66C  1  75 E3              .word LBB_BINS          ; BIN$
00E66E  1  07 42              .byte 7,'B'             ;
00E670  1  86 E3              .word LBB_BITTST        ; BITTST
00E672  1  04 4D              .byte 4,'M'             ;
00E674  1  21 E4              .word LBB_MAX           ; MAX
00E676  1  04 4D              .byte 4,'M'             ;
00E678  1  2A E4              .word LBB_MIN           ; MIN
00E67A  1  02 50              .byte 2,'P'             ;
00E67C  1  4E E4              .word LBB_PI            ; PI
00E67E  1  05 54              .byte 5,'T'             ;
00E680  1  C6 E4              .word LBB_TWOPI         ; TWOPI
00E682  1  07 56              .byte 7,'V'             ;
00E684  1  E1 E4              .word LBB_VPTR          ; VARPTR
00E686  1  06 4C              .byte 6,'L'             ;
00E688  1  03 E4              .word LBB_LEFTS         ; LEFT$
00E68A  1  07 52              .byte 7,'R'             ;
00E68C  1  7E E4              .word LBB_RIGHTS        ; RIGHT$
00E68E  1  05 4D              .byte 5,'M'             ;
00E690  1  25 E4              .word LBB_MIDS          ; MID$
00E692  1               
00E692  1               ; BASIC messages, mostly error messages
00E692  1               
00E692  1               LAB_BAER
00E692  1  B6 E6              .word ERR_NF            ;$00 NEXT without FOR
00E694  1  C7 E6              .word ERR_SN            ;$02 syntax
00E696  1  CE E6              .word ERR_RG            ;$04 RETURN without GOSUB
00E698  1  E3 E6              .word ERR_OD            ;$06 out of data
00E69A  1  EF E6              .word ERR_FC            ;$08 function call
00E69C  1  FD E6              .word ERR_OV            ;$0A overflow
00E69E  1  06 E7              .word ERR_OM            ;$0C out of memory
00E6A0  1  14 E7              .word ERR_US            ;$0E undefined statement
00E6A2  1  28 E7              .word ERR_BS            ;$10 array bounds
00E6A4  1  35 E7              .word ERR_DD            ;$12 double dimension array
00E6A6  1  46 E7              .word ERR_D0            ;$14 divide by 0
00E6A8  1  55 E7              .word ERR_ID            ;$16 illegal direct
00E6AA  1  64 E7              .word ERR_TM            ;$18 type mismatch
00E6AC  1  72 E7              .word ERR_LS            ;$1A long string
00E6AE  1  82 E7              .word ERR_ST            ;$1C string too complex
00E6B0  1  95 E7              .word ERR_CN            ;$1E continue error
00E6B2  1  A4 E7              .word ERR_UF            ;$20 undefined function
00E6B4  1  B7 E7              .word ERR_LD            ;$22 LOOP without DO
00E6B6  1               
00E6B6  1               ; I may implement these two errors to force definition of variables and
00E6B6  1               ; dimensioning of arrays before use.
00E6B6  1               
00E6B6  1               ;     .word ERR_UV            ;$24 undefined variable
00E6B6  1               
00E6B6  1               ; the above error has been tested and works (see code and comments below LAB_1D8B)
00E6B6  1               
00E6B6  1               ;     .word ERR_UA            ;$26 undimensioned array
00E6B6  1               
00E6B6  1  4E 45 58 54  ERR_NF      .byte "NEXT without FOR",$00
00E6BA  1  20 77 69 74  
00E6BE  1  68 6F 75 74  
00E6C7  1  53 79 6E 74  ERR_SN      .byte "Syntax",$00
00E6CB  1  61 78 00     
00E6CE  1  52 45 54 55  ERR_RG      .byte "RETURN without GOSUB",$00
00E6D2  1  52 4E 20 77  
00E6D6  1  69 74 68 6F  
00E6E3  1  4F 75 74 20  ERR_OD      .byte "Out of DATA",$00
00E6E7  1  6F 66 20 44  
00E6EB  1  41 54 41 00  
00E6EF  1  46 75 6E 63  ERR_FC      .byte "Function call",$00
00E6F3  1  74 69 6F 6E  
00E6F7  1  20 63 61 6C  
00E6FD  1  4F 76 65 72  ERR_OV      .byte "Overflow",$00
00E701  1  66 6C 6F 77  
00E705  1  00           
00E706  1  4F 75 74 20  ERR_OM      .byte "Out of memory",$00
00E70A  1  6F 66 20 6D  
00E70E  1  65 6D 6F 72  
00E714  1  55 6E 64 65  ERR_US      .byte "Undefined statement",$00
00E718  1  66 69 6E 65  
00E71C  1  64 20 73 74  
00E728  1  41 72 72 61  ERR_BS      .byte "Array bounds",$00
00E72C  1  79 20 62 6F  
00E730  1  75 6E 64 73  
00E735  1  44 6F 75 62  ERR_DD      .byte "Double dimension",$00
00E739  1  6C 65 20 64  
00E73D  1  69 6D 65 6E  
00E746  1  44 69 76 69  ERR_D0      .byte "Divide by zero",$00
00E74A  1  64 65 20 62  
00E74E  1  79 20 7A 65  
00E755  1  49 6C 6C 65  ERR_ID      .byte "Illegal direct",$00
00E759  1  67 61 6C 20  
00E75D  1  64 69 72 65  
00E764  1  54 79 70 65  ERR_TM      .byte "Type mismatch",$00
00E768  1  20 6D 69 73  
00E76C  1  6D 61 74 63  
00E772  1  53 74 72 69  ERR_LS      .byte "String too long",$00
00E776  1  6E 67 20 74  
00E77A  1  6F 6F 20 6C  
00E782  1  53 74 72 69  ERR_ST      .byte "String too complex",$00
00E786  1  6E 67 20 74  
00E78A  1  6F 6F 20 63  
00E795  1  43 61 6E 27  ERR_CN      .byte "Can't continue",$00
00E799  1  74 20 63 6F  
00E79D  1  6E 74 69 6E  
00E7A4  1  55 6E 64 65  ERR_UF      .byte "Undefined function",$00
00E7A8  1  66 69 6E 65  
00E7AC  1  64 20 66 75  
00E7B7  1  4C 4F 4F 50  ERR_LD      .byte "LOOP without DO",$00
00E7BB  1  20 77 69 74  
00E7BF  1  68 6F 75 74  
00E7C7  1               
00E7C7  1               ;ERR_UV     .byte "Undefined variable",$00
00E7C7  1               
00E7C7  1               ; the above error has been tested and works (see code and comments below LAB_1D8B)
00E7C7  1               
00E7C7  1               ;ERR_UA     .byte "Undimensioned array",$00
00E7C7  1               
00E7C7  1  0D 0A 42 72  LAB_BMSG    .byte $0D,$0A,"Break",$00
00E7CB  1  65 61 6B 00  
00E7CF  1  20 45 72 72  LAB_EMSG    .byte " Error",$00
00E7D3  1  6F 72 00     
00E7D6  1  20 69 6E 20  LAB_LMSG    .byte " in line ",$00
00E7DA  1  6C 69 6E 65  
00E7DE  1  20 00        
00E7E0  1  0D 0A 52 65  LAB_RMSG    .byte $0D,$0A,"Ready",$0D,$0A,$00
00E7E4  1  61 64 79 0D  
00E7E8  1  0A 00        
00E7EA  1               
00E7EA  1  20 45 78 74  LAB_IMSG    .byte " Extra ignored",$0D,$0A,$00
00E7EE  1  72 61 20 69  
00E7F2  1  67 6E 6F 72  
00E7FB  1  20 52 65 64  LAB_REDO    .byte " Redo from start",$0D,$0A,$00
00E7FF  1  6F 20 66 72  
00E803  1  6F 6D 20 73  
00E80E  1               
00E80E  1               AA_end_basic
00E80E  1               
