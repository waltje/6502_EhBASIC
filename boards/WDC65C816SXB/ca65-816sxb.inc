.feature labels_without_colons

SXB       = 1

WDCBASE   = $8080
SRESET    = WDCBASE+2             ; this is a reset routine
TREADY    = SRESET+2              ; TIDE FIFO receive ready (0 = no char, 1 = char)
TRECV     = TREADY+2              ; TIDE FIFO receive
TSEND     = TRECV+2               ; TIDE FIFO send
SYSCODE   = TSEND+2               ; holds address of SYSCODE variable, set to 0 to use our vectors
VERSTR    = SYSCODE+2             ; holds address of version string
S_NMI     = $7E72                 ; Shadow NMI vector
S_NNMI    = $7E76
S_IRQBRK  = $7E70
S_NBRK    = $7E74
S_BRK     = $7EFE                 ; Shadow BRK vector
