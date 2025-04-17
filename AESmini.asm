.model small
.stack 100h

.data
; Define the S-Box (simplified version for illustration purposes)
SBOX DB 063h, 07Ch, 077h, 07Bh, 0F2h, 06Bh, 06Fh, 0C5h, 030h, 001h, 067h, 02Bh, 0FEh, 0D7h, 0ABh, 076h
     DB 0CAh, 082h, 0C9h, 07Dh, 0FAh, 059h, 047h, 0F0h, 0ADh, 0D4h, 0A2h, 0AFh, 09Ch, 0A4h, 072h, 0C0h
     DB 0B7h, 0FDh, 093h, 026h, 036h, 03Fh, 0F7h, 0CCh, 034h, 0A5h, 0E5h, 0F1h, 071h, 0D8h, 031h, 015h
     DB 004h, 0C7h, 023h, 0C3h, 018h, 096h, 005h, 09Ah, 007h, 012h, 080h, 0E2h, 0EBh, 027h, 0B2h, 075h
     DB 009h, 083h, 02Ch, 01Ah, 01Bh, 06Eh, 05Ah, 0A0h, 052h, 03Bh, 0D6h, 0B3h, 029h, 0E3h, 02Fh, 084h
     DB 053h, 0D1h, 000h, 0EDh, 020h, 0FCh, 0B1h, 05Bh, 06Ah, 0CBh, 0BEh, 039h, 04Ah, 04Ch, 058h, 0CFh
     DB 0D0h, 0EFh, 0AAh, 0FBh, 043h, 04Dh, 033h, 085h, 045h, 0F9h, 002h, 07Fh, 050h, 03Ch, 09Fh, 0A8h
     DB 051h, 0A3h, 040h, 08Fh, 092h, 09Dh, 038h, 0F5h, 0BCh, 0B6h, 0DAh, 021h, 010h, 0FFh, 0F3h, 0D2h
     DB 0CDh, 00Ch, 013h, 0ECh, 05Fh, 097h, 044h, 017h, 0C4h, 0A7h, 07Eh, 03Dh, 064h, 05Dh, 019h, 073h
     DB 060h, 081h, 04Fh, 0DCh, 022h, 02Ah, 090h, 088h, 046h, 0EEh, 0B8h, 014h, 0DEh, 05Eh, 00Bh, 0DBh
     DB 0E0h, 032h, 03Ah, 00Ah, 049h, 006h, 024h, 05Ch, 0C2h, 0D3h, 0ACh, 062h, 091h, 095h, 0E4h, 079h
     DB 0E7h, 0C8h, 037h, 06Dh, 08Dh, 0D5h, 04Eh, 0A9h, 06Ch, 056h, 0F4h, 0EAh, 065h, 07Ah, 0Aeh, 008h
     DB 0BAh, 078h, 025h, 02Eh, 01Ch, 0A6h, 0B4h, 0C6h, 0E8h, 0DDh, 074h, 01Fh, 04Bh, 0BDh, 08Bh, 08Ah
     DB 070h, 03Eh, 0B5h, 066h, 048h, 003h, 0F6h, 00Eh, 061h, 035h, 057h, 0B9h, 086h, 0C1h, 01Dh, 09Eh
     DB 0E1h, 0F8h, 098h, 011h, 069h, 0D9h, 08Eh, 094h, 09Bh, 01Eh, 087h, 0E9h, 0CEh, 055h, 028h, 0DFh
     DB 08Ch, 0A1h, 089h, 00Dh, 0BFh, 0E6h, 042h, 068h, 041h, 099h, 02Dh, 00Fh, 0B0h, 054h, 0BBh, 016h

; Define the state matrix (4x4, just an example)
state db 16 dup(00)
      
round_key db 0FFh, 0FFh, 0FFh, 0FFh  ; Row 1
          db 0FFh, 0FFh, 0FFh, 0FFh  ; Row 2
          db 0FFh, 0FFh, 0FFh, 0FFh  ; Row 3
          db 0FFh, 0FFh, 0FFh, 0FFh  ; Row 4

;Define the matrix used MixColumns (4x4)
galoisFieldMatrix  db 02h, 03h, 01h, 01h   ; Row 1
                   db 01h, 02h, 03h, 01h   ; Row 2
                   db 01h, 01h, 02h, 03h   ; Row 3
                   db 03h, 01h, 01h, 02h   ; Row 4                   
state_transposed db 16 dup(0)
counter db 9

msg1    db  "ENTER THE STRING: $"
s1      db 100,?, 32 dup(' ')  
 
   
;Define the output matrix
output db  32 dup(00)
                                        
.code
gmul macro
    local multiply_by_01
    local multiply_by_02
    local multiply_by_03
    local reduce_mod_0x11B      ; this is definitely divine intellect
    local done
    local skip_xor 
    ; Check the value of BL (matrix value)
    cmp al, 01h         ; Check if matrix value is 0x01
    je multiply_by_01   ; If it is, jump to multiply_by_01

    cmp al, 02h         ; Check if matrix value is 0x02
    je multiply_by_02   ; If it is, jump to multiply_by_02

    cmp al, 03h         ; Check if matrix value is 0x03
    je multiply_by_03   ; If it is, jump to multiply_by_03

    jmp done            ; If something goes wrong, just jump to done (should never happen)

; Case 1: Multiply by 0x01 (Identity: Result = AL)
multiply_by_01:
    ; Multiplying by 0x01 does nothing, so result is BL itself
    jmp done

; Case 2: Multiply by 0x02 (Shift left by 1 and reduce modulo 0x11B if necessary)
multiply_by_02:
    shl bl, 1           ; Shift BL left by 1 (multiply by 2)
    jnc done  ; If there is a carry (overflow), reduce modulo 0x11B
    xor bl,0x1B  ; If carry, reduce modulo the irreducible polynomial 0x11B
    jmp done

; Case 3: Multiply by 0x03 (Multiply by 0x02 and XOR with original value)
multiply_by_03:  
    mov al,bl   ; Save the original byte (AL) before modifying it       
    shl bl, 1   ; same steps as multiplying by 2        
    jnc skip_xor ; if there is no overflow then we skip the reduction step
    xor bl,0x1B    
skip_xor:                ; XOR the result with the original byte (multiply by 0x03)
    xor bl,al            ; XOR the result with the original byte (multiply by 0x03)
    jmp done

done: 
    mov al,bl    ; store the result in the al register
endm 
    
SubBytes macro
    local subbytes_loop
    ; Loop through the state matrix (4x4 = 16 bytes)
    lea si, state       ; SI points to the start of the state matrix
    mov cx, 16          ; We need to process 16 bytes

subbytes_loop:
    ; Load the current byte from the state matrix
    mov al, [si]        ; AL = state[si]

    ; Find the row index in the S-Box (high nibble of the byte)
    mov ah, al          ; Copy AL to AH for processing the high nibble
    shr ah, 4           ; Shift right 4 bits to get the high nibble (row index)

    ; Find the column index in the S-Box (low nibble of the byte)
    and al, 0Fh         ; Mask to get the low nibble (column index)

    ; Calculate the address of the S-Box entry: SBox[row*16 + col]
    mov bl, ah          ; Row index (high nibble) is in AH, so move it to BX
    shl bl, 4           ; Multiply by 16 (row * 16), using SHL (shift left by 4)
    add bl, al          ; Add the column index (BX = row*16 + column)
    lea dx, SBox        ; Load address of the S-Box
    add bx, dx          ; Get the final address of the S-Box entry

    ; Look up the value in the S-Box and store it back in the state matrix
    mov al, [bx]        ; AL = SBox[bx]
    mov [si], al        ; Replace the current byte in the state matrix with the S-Box value

    ; Increment to the next byte in the state matrix
    inc si
    loop subbytes_loop  ; Repeat for all 16 bytes
    mov ax, 0
    mov bx, 0
    mov cx,0
    mov dx,0
endm

ShiftRows macro
    local shifting_func
    local RotateOnce
    mov cl, 0
shifting_func:
    add cl, 1              ; row number
    lea si, state          ; Load base address of the table
    mov dl, cl      
    shl dx, 2              ; Multiply row number by 4 (each row is 4 bytes)
    add si, dx             ; Add offset to base address (now SI points to the desired row)

; === Load Row ===
    mov ax, [si]           ; Load first half (16 bits) of the row into AX
    mov bx, [si+2]         ; Load second half (16 bits) of the row into BX
    mov dl,cl              ; now that we no longer need the dx we can use it as a counter
RotateOnce:
    rol ax,8               ;steps to rotate 32 bit data, we rotate each 8 times to the left, then swap first halves
    rol bx,8
    mov ch, bh
    mov bh, ah
    mov ah, ch
    dec dl
    cmp dl, 0
    jne RotateOnce
; === Write Row Back ===
    mov [si], ax           ; Write the processed first half (AX) back to the row
    mov [si+2], bx         ; Write the processed second half (BX) back to the row
    cmp cl,3
    jne shifting_func
    mov ax,0
    mov bx, 0
    mov cx,0
    mov dx,0
endm
MixColumns macro
    local transpose_matrix  ;first we begin to transpose the state matrix for more efficient multiplication
    local row_insertion
    local next_element
    local element_insertion
    local check_4
    local done
    local next_row                      
    lea si, state           ;we point to state and to the empty array state_transposed we want to fill
    lea di, state_transposed
    sub si,4                ; this subtraction is so that we can add 4(necessary to traverse by column) to si everytime in the loop INCLUDING the beginning
    mov dx,4                ; this keeps track of our position in the array since it is 4x4 we add 4 to si 4 times to traverse the entire column
transpose_state:
    mov cx,4                ; this is for how many columns we need to traverse(4 in our case)
row_insertion:
    add si,4                ;simple loop that traverses the state by column and inserts in the state_transposed accordingly
    mov al,[si]
    mov [di],al
    inc di
    loop row_insertion
    dec dx
    sub si,15               ;subtract si by 15 when done with a column in order to jump to the next one
    cmp dx,0
    jnz transpose_state
    
    ;matrix multiplication using the transposed
    lea si, galoisFieldMatrix  ;si used to traverse the galois matrix
    lea bp, state_transposed   ;bp used to traverse the state_transposed
    lea di, state              ;di to traverse the original state matrix to change it
    mov dl,0                   ;counts how many elements we have finished inserting
next_element:
    mov cx,4                   ; counter for how many "additions" we make per element
    mov bl,0                   ; before beginning to insert an element in the state we set the element to 0 so the starting xor is correct
    mov [di],bl    
element_insertion:
    push si                    ;the bp doesnt work so we simply switch it with si temporarily through the stack and use si
    mov si,bp
    mov bl,[si]
    pop si
    mov al, [si]
    gmul                       ; do the modulo multiplication
    mov dh, [di]               ; move the element(current state) to dh for it to be updated
    xor dh,al                  ; 
    mov [di],dh                ; move it back after updating it
    inc si                     ; move to the next 2 operands
    inc bp                     ;
    loop element_insertion     ; repeat for the 4 operands required to get 1 element in the resulting matrix
    inc dl                     ; add 1 to the number of elements we finished adding
    inc di                     ; move to the next element we need to insert in the result matrix
    ror dl,1                   ; check if the number of elements we added is even
    jnc check_4                ; if it is check if it is a multiple of 4, so we know if we need to move on to the next row
    rol dl,1                   ; if it isnt even then we return it to what it was and advance to the next element
    sub si,4
    jmp next_element           ; jump back to the outside loop 
check_4:
    ror dl,1                   ; checking if it is a multiple of 4, if it is then we need to start inserting the next row
    jnc next_row
    rol dl,2                   ; if not then we return it to what it was and advance to the next element 
    sub si,4
    jmp next_element    
next_row:
    rol dl,2                   ; if we reach here then it means we need to advance to the next row
    cmp dl,16                  ; check if there is even a next row
    jnc done                   ; if there is no next row, we are done
    lea bp, state_transposed   ; if not we advance to the next row
    jmp next_element
done:
    mov ax, 0
    mov bx, 0
    mov cx,0
    mov dx,0
endm       

AddRoundKey macro
    local AddRoundKeyLoop
    lea si, state         ; Load the base address of the state array
    lea di, round_key     ; Load the base address of the round key
    mov cx, 16            ; Set loop counter to 16 (number of bytes in the state)

AddRoundKeyLoop:     
    mov al, [si]          ; Load a byte from the state
    xor al, [di]          ; XOR the byte with the corresponding round key byte
    mov [si], al          ; Write the result back to the state
    inc si                ; Increment state pointer
    inc di                ; Increment round key pointer
    loop AddRoundKeyLoop  ; Decrement counter and loop if not zero    
    mov ax, 0
    mov bx, 0
    mov cx,0
    mov dx,0
endm
print_new_line macro
    mov dl, 13
    mov ah, 2
    int 21h   
    mov dl, 10
    mov ah, 2
    int 21h      
endm
output_func macro
    mov bx, offset output[0]
    local print_char
    mov cx,32
    print_char:
    mov dl, [bx]
    mov ah, 2
    int 21h        
    inc bx
    loop print_char
endm
      
state_displayer macro
    lea di, state  
    lea si, output
    mov cx, 16 
    local displayer_loop, isDecimalH, isDecimalL, continue, loops
    displayer_loop:
        mov al, [di] ;move element di from state to al
        mov ah, [di] ;move element di from state to al
        inc di
        and al, 0x0F ;retrieve rightmost 4 bits
        and ah, 0xF0
        shr ah,4     ;retrieve leftmost 4 bits
        cmp ah, 10
        js isDecimalH  
        mov [si], 87
        add [si], ah
        inc si
        continue:
        cmp al, 10
        js isDecimalL 
        mov [si], 87
        add [si], al
        inc si 
        jmp loops
    isDecimalH:
        mov [si], 48
        add [si], ah
        inc si 
        jmp continue
    isDecimalL:
        mov [si], 48
        add [si], al
        inc si
    loops: loop displayer_loop
endm
input macro
    mov dx, offset msg1
    mov ah, 9
    int 21h
    ; input the string:
    mov dx, offset s1
    mov ah, 0ah
    int 21h
    print_new_line

endm

load_to_state macro
    local transform,IsDigit,second,skip_isDigit
    lea si , s1
    lea di, state
    add si,2
    mov cx,32
transform: 
    mov al,[si]
    cmp al,58
    js IsDigit
    sub al, 87
    jmp skip_isDigit
IsDigit:
    sub al, 48
skip_isDigit:
    ror cx,1
    jc second
    rol cx,1
    shl al,4
    add [di],al
    inc si
    loop transform
second:    
    rol cx,1
    add [di],al
    inc si
    inc di
    loop transform
endm

main proc
    mov ax, @data
    mov ds, ax
    input
    load_to_state ;the purpose of not storing directly in the state is for easier debugging and testing
                  ;also the input has to be taken with a 2 byte buffer before the actual data
    AddRoundKey
main_loop:           
    SubBytes
    ShiftRows
    MixColumns
    AddRoundKey
    lea si,counter
    dec [si]
    cmp [si],0
    jne main_loop
    SubBytes
    ShiftRows
    AddRoundKey 
    state_displayer
    output_func
main endp
