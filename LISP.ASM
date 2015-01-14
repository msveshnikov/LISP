        ideal

        DESCRIPTOR='|'
        STACK_SIZE=30000
        MIN_ALLOC=50

        nowarn BRK
        nowarn RES
        jumps
        locals __

enum    TYPES none,subr,_fsubr,expr,fexpr,apval,fix,_macro

SEGMENT code
        assume ds:code,es:code,cs:code,ss:sseg
Start:
        dw offset nilval,0
        db apval*4+2
nilval  dw 0,0
        db 0
twonil  dw 0,0

PROC    MAIN
        cld
        mov ah,4ah
        mov bx,1011h+STACK_SIZE/16
        int 21h
        call findcomspec

        push cs cs
        pop ds es

        call move_list
        call init_hash
        call make_trans
        call prepare_memory
        call create_list
        call randomize

        call autoname
        mov ax,3d00h
        int 21h
        jc skipauto
        mov inhandle,ax
        mov savedaddr,offset endauto
autoloop:
        call read
        mov si,bx
        mov curreval,bx
        call eval
        jmp autoloop
endauto:
        cmp al,32
        jne autoerror
        mov bx,inhandle
        mov ah,3eh
        int 21h
skipauto:
        call copyright
        call activefile
StartPoint:
        mov sp,STACK_SIZE
        mov ax,aptr
        mov savedaptr,ax
        mov savedaddr,offset exit
        mov command,1
        call read
        mov command,0
        mov si,bx
        mov curreval,bx
        test echo,2
        jz __nocr
        cmp inhandle,0
        je __nocr
        call cr
__nocr:
        call eval
        test echo,2
        jz StartPoint
        mov si,bx
        call print
        jmp StartPoint

exit:
        cmp al,32
        jne StartPoint
        mov bx,inhandle
        mov ah,3eh
        int 21h
        mov inhandle,0
        mov linelen,0           ;очистка буфера
        and echo,11111100b
        or echo,00000010b
        cmp outhandle,0
        je StartPoint
quit:   call flush
        mov bx,outhandle
        mov ah,3eh
        int 21h
        mov ax,4c00h
        int 21h
autoerror:
        mov dx,offset __err
        call prdos
        mov ax,4c01h
        int 21h

__err           db 13,10,'Ошибка в AUTO.LSP - исправьте или удалите',13,10,'$'
prompt          db 13,10,'>$'
echo            db 2            ;бит 0 - эхо ввода
                                ;бит 1 - вывод результатов
                                ;бит 2 - сообщения мусорщика
inhandle        dw 0
outhandle       dw 0
autoexec        db 'auto.lsp',0
command         db 0            ;1-вводится команда
ENDP


;*****************************************
;               ---Реализация---
; Для всех SUBR si=a1, di=a2, bp=("a3"  "a4" ...) если есть (либо NIL);
;               bx=result
; Для всех FSUBR si=("a1"  "a2"  ... )
;*****************************************

PROC    changenames
;(defun поменяй-имена (терм уровень)
;; На каждом уровне имена уникальные
;   (cond
;       ((atom терм) терм)
;       ((переменная-p терм)
;          (append терм уровень))
;       (t (cons
;          (поменяй-имена
;               (first терм) уровень)
;          (поменяй-имена
;               (rest терм) уровень)))))
        test [byte si+4],2
        jnz __atom
        mov bx,[si]
        cmp bx,ask_sign
        je append
        push [si+2] di
        mov si,[si]
        call changenames
        pop di si
        push bx
        call changenames
        mov di,bx
        pop si
        jmp cons
__atom:
        mov bx,si
        ret
ENDP

PROC    combine
        test [byte si+4],2
        jnz err19
        mov di,offset pnbuf
        mov numprop,0
__loop:
        mov bx,[si]
        mov bx,[bx+2]
        mov bx,[bx]
        mov al,[bx]
        stosb
        mov si,[si+2]
        or si,si
        jnz __loop
        xor al,al
        stosb
        jmp intern
ENDP

PROC    split
        call notdigit
        mov numprop,0
        mov bx,[si+2]
        xor di,di
__next4:
        mov si,[bx]
        mov cx,4
__loop:
        lodsb
        or al,al
        jz __end
        push si bx cx di
        mov [byte pnbuf],al
        mov [byte pnbuf+1],0
        call intern
        pop di
        mov si,bx
        call cons
        mov di,bx
        pop cx bx si
        loop __loop
        mov bx,[bx+2]
        or bx,bx
        jnz __next4
__end:
        mov si,di
        jmp dreverse
ENDP

PROC    putpixel        ;класс SUBR
;печатает графическую точку (колонка строка цвет) (cx dx al)
        call loadsi
        push ax
        mov si,di
        call loadsi
        push ax
        mov si,bp
        call car
        mov si,bx
        call eval
        mov si,bx
        call loadsi
        pop dx
        pop cx
        xor bh,bh
        mov ah,0ch
        int 10h
        mov bx,t
        ret
ENDP

PROC    autoname
;Определяет полное имя файла AUTO.LSP в каталоге LISP.EXE
;В DX - полное имя
        push ds es
        mov ax,cs
        sub ax,10h
        mov es,ax
        mov es,[es:2ch]
        xor di,di
        mov cx,32000
        xor al,al
__scan:
        repnz scasb
        cmp [byte es:di],0
        jne __scan
        add di,3
        push ds es
        pop ds es
        mov si,di
        mov di,offset fname
        mov dx,di
__loop:
        movsb
        cmp [byte si],0
        jne __loop
__back:
        dec si
        dec di
        cmp [byte si],'\'
        je __ok
        cmp [byte si],0
        jne __back
__ok:
        pop es ds
        inc di
        mov si,offset autoexec
        mov cx,9
        rep movsb
        ret
ENDP

PROC    dreverse
;(defun dreverse (x &aux u v) (loop
;       (if (null x) (return u))
;       (setq v x) (pop x)
;       (setq u (rplacd v u)) ))
; Скомпилирована в LISP.EXE 24.12.97
        xor bx,bx
__loop:
        test [byte si+4],2
        jnz __all
        xchg [si+2],bx
        xchg si,bx
        jmp __loop
__all:
        ret
ENDP

PROC    value
;Функция "значение" (скомпилирована для повышения быстродействия в 40 раз)
;текст:
;(defun значение (x связи)
;  (if (переменная-p x)
;      (let ((связь (assoc x связи)))
;       (if (null связь) x
;          (значение (second связь) связи)))
;      x))
        call perem
        or bx,bx
        jz __notvar
        push si di
        call _assoc
        pop di si
        or bx,bx
        jz __notvar
        mov bx,[bx+2]
        mov si,[bx]
        jmp value
__notvar:
        mov bx,si
        ret
ENDP

PROC    perem
;Предикат "переменная-p"
;(defun переменная-p (x)
;       (and (not (atom x)) (eq (first x) '?)))
        test [byte si+4],2
        jnz __nil
        mov bx,[si]
        cmp bx,ask_sign
        jne __nil
        mov bx,t
        ret
__nil:
        xor bx,bx
        ret
ENDP

PROC    _assoc
        test [byte di+4],2
        jnz __nil
        mov bx,[di]
        push si di
        mov di,[bx]
        call equal
        pop di si
        or bx,bx
        jnz __ok
        mov di,[di+2]
        jmp _assoc
__ok:
        mov bx,[di]
        ret
__nil:
        xor bx,bx
        ret
ENDP

PROC    bindlist
        push [si]               ;список переменных
        mov si,[si+2]
        mov si,[si]             ;список значений
        call list
        mov di,bx
        pop si
__A:
        test [byte si+4],2
        jnz __ret
        push si di
        mov si,[si]
        call assoc
        pop di
        mov si,[di]
        mov [bx+2],si
        pop si
        mov si,[si+2]
        mov di,[di+2]
        jmp __A
__ret:
        ret
ENDP

PROC    let
        push [si+2]
        mov si,[si]     ;список переменных
        xor cx,cx       ;параметры
        xor dx,dx       ;значения
__A:
        push si
        call car        ;пара типа (х значение)
        push bx
        mov si,[bx]     ;х
        mov di,cx
        push dx         ;для мусорщика (чтобы не убрал)
        call cons
        pop dx
        mov cx,bx
        pop si
        call cadr       ;значение
        mov si,bx
        mov di,dx
        push cx
        call cons
        pop cx
        mov dx,bx
        pop si
        mov si,[si+2]
        test [byte si+4],2
        jz __A
        pop di          ;тело
        mov si,cx
        push dx
        call cons       ; bx=((пар-ры) тело)
        mov di,bx
        mov si,lambda
        call cons
        mov si,bx
        pop di
        jmp apply
ENDP

PROC    stop
        cmp inhandle,0
        mov al,32
        jne error
        xor bx,bx
        ret
ENDP

PROC    reverse
        xor bx,bx
__loop:
        or si,si
        jz __ret
        mov di,bx
        push [si+2]
        call sure
        mov si,[si]
        call cons
        pop si
        jmp __loop
__ret:
        ret
ENDP

PROC    truetime
        push ds
        xor ax,ax
        mov ds,ax
        cli
        out 43h,al
        in al,40h
        mov dx,[46ch]
        mov ah,al
        in al,40h
        xchg al,ah
        not ax
        sti
        pop ds
        ret
ENDP

PROC    notdigit
        cmp [byte si+4],fix*4+2
        je err26
        test [byte si+4],2
        jz err25
        ret
err26:  mov al,26
        jmp error
err25:  mov al,25
        jmp error
ENDP

PROC    toupper
        push bx
        mov bx,offset conv_table
        xlat [bx]
        pop bx
        ret
ENDP

PROC    make_trans
        mov di,offset conv_table
        xor bx,bx
        mov cx,'a'
__l1:   mov al,bl
        stosb
        inc bl
        loop __l1
        mov bh,'A'
        mov cx,26
__l2:   mov al,bh
        stosb
        inc bl
        inc bh
        loop __l2
        mov cx,25h
__l3:   mov al,bl
        stosb
        inc bl
        loop __l3
        mov cx,16
        mov bh,'А'
__l4:   mov al,bh
        stosb
        inc bl
        inc bh
        loop __l4
        mov cx,48
__l5:   mov al,bl
        stosb
        inc bl
        loop __l5
        mov cx,16
__l6:   mov al,bh
        stosb
        inc bh
        inc bl
        loop __l6
        mov cx,16
__l7:   mov al,bl
        stosb
        inc bl
        loop __l7
        mov [conv_table+'ё'],'Ё'
        ret
ENDP

PROC    pprint
        mov bx,_pprint
        cmp [byte bx+4],expr*4+2
        jne notinst
        xor di,di
        call cons
        mov di,bx
        mov si,quote
        call cons
        mov si,bx
        xor di,di
        call cons
        mov di,bx
        mov si,_pprint
        call cons
        mov si,bx
        jmp eval
notinst:
        call prin0
        jmp cr
ENDP

PROC    dos
        call notdigit
        mov com_str,offset __null
        or si,si
        jz __nocommand
        mov di,offset fname
        mov dx,di
        inc di
        mov ax,'C/'
        stosw
        mov dl,2
        mov bx,[si+2]
__next4:
        mov si,[bx]
        mov cx,4
__loop:
        lodsb
        or al,al
        jz __end
        stosb
        inc dl
        loop __loop
        mov bx,[bx+2]
        or bx,bx
        jnz __next4
__end:
        mov al,0dh
        stosb
        mov [byte fname],dl
        mov com_str,offset fname
__nocommand:
        mov ax,4b00h
        push ds es bp
        lds dx,[dword pcommand]
        mov bx,offset EPB
        int 21h
        pop bp es ds
        jc __error
        mov bx,t
        ret
__error:xor bx,bx
        ret
pcommand        dw ?,?
EPB             dw 0
com_str         dw offset __null,code
                dd ?,?
__null          db 0,0dh
ENDP

PROC    findcomspec
        mov es,[2ch]
        push cs
        pop ds
        xor di,di
__loop:
        mov si,offset __com
        mov cx,8
        repz cmpsb
        jz __found
        xor al,al
        dec di
        mov cx,32000
        repnz scasb
        jcxz __ret
        cmp [byte es:di],0
        jne __loop
__ret:
        ret
__found:
        mov [pcommand],di
        mov [pcommand+2],es
        ret
__com   db 'COMSPEC='
ENDP

PROC    mode
        call checksi
        call loadsi
        mov _mode,al
        xor ah,ah
        int 10h
        mov bx,t
        ret
ENDP

PROC    time
        mov si,[si]
        call truetime
        mov btime,ax
        mov btime+2,dx
        call eval
        call truetime
        sub ax,btime
        sbb dx,btime+2
        cmp dx,400h
        ja __ret
        mov cx,1193
        div cx
        mov dx,offset mess4
        call prdos
        xor dx,dx
        call wrdec
        mov dx,offset mess4b
        call prdos
__ret:  ret
btime   dw ?,?
mess4   db 'Время вычисления $'
mess4b  db ' мсек',13,10,'$'
ENDP

PROC    trace
        push si
__loop:
        or si,si
        jz __ok
        push si
        mov si,[si]
        call checkfun
        or [byte si+4],20h
        pop si
        mov si,[si+2]
        jmp __loop
__ok:
        pop bx
        ret
ENDP

PROC    untrace
        push si
__loop:
        or si,si
        jz __ok
        push si
        mov si,[si]
        call checkfun
        and [byte si+4],not 20h
        pop si
        mov si,[si+2]
        jmp __loop
__ok:
        pop bx
        ret
ENDP

PROC    checkfun
        mov al,[si+4]
        and al,not 20h
        cmp al,subr*4+2
        je __ok
        cmp al,_fsubr*4+2
        je __ok
        cmp al,expr*4+2
        je __ok
        cmp al,fexpr*4+2
        je __ok
        cmp al,_macro*4+2
        je __ok
        mov al,7
        jmp error
__ok:   ret
ENDP

PROC    _push
        push [si+2]
        mov si,[si]
        call eval
        pop si
        mov si,[si]
        push bx
        call assoc
        pop si
        mov di,[bx+2]
        push bx
        call cons
        pop si
        mov [si+2],bx
        ret
ENDP

PROC    _pop
        mov si,[si]
        call assoc
        mov si,[bx+2]
        or si,si
        jz __nil
        test [byte si+4],2
        jnz __nil
        mov di,[si]
        mov si,[si+2]
        mov [bx+2],si
        mov bx,di
        ret
__nil:
        xor bx,bx
        ret
ENDP

PROC    _error
        mov al,15
        jmp error
ENDP

PROC    fboundp
        mov al,[si+4]
        and al,not 20h
        cmp al,expr*4+2
        je __t
        cmp al,fexpr*4+2
        je __t
        cmp al,_macro*4+2
        je __t
        xor bx,bx
        ret
__t:
        mov bx,t
        ret
ENDP

PROC    boundp
        mov al,[si+4]
        cmp al,fix*4+2
        je __t
        cmp al,apval*4+2
        je __t
        call assocn
        jnc __t
__nil:  xor bx,bx
        ret
__t:    mov bx,t
        ret
ENDP

PROC    terpri
        call cr
        mov bx,t
        ret
ENDP

PROC    proplist
        call notdigit
        mov bx,[si]
        mov bx,[bx+2]
        ret
ENDP

PROC    spropl
        call notdigit
        mov bx,si
        mov si,[si]
        mov [si+2],di
        ret
ENDP

PROC    alist
        mov bx,aptr
        ret
ENDP

PROC    _echo
        call checksi
        mov bx,si
        call loadsi
        mov echo,al
        ret
ENDP

PROC    _count
        xor ax,ax
__loop:
        test [byte si+4],2
        jnz __ok
        mov bx,[si]
        test [byte bx+4],2
        jnz __atom
        push si ax
        mov si,bx
        call _count
        pop bx si
        add ax,bx
        jmp __next
__atom:
        inc ax
__next:
        mov si,[si+2]
        jmp __loop
__ok:
        ret
ENDP

PROC    count
        call _count
        xor dx,dx
        jmp gointern
ENDP

PROC    setblank
        call checksi
        call loadsi
        mov cx,ax
        jcxz __ok
        mov al,' '
__loop: call pri
        loop __loop
__ok:
        mov bx,t
        ret
ENDP

PROC    _if
        push si
        mov si,[si]
        call eval
        pop si
        or bx,bx
        jz __third
        call cadr
        mov si,bx
        jmp eval
__third:
        call caddr
        mov si,bx
        jmp eval
ENDP

PROC    append
        or si,si
        jz firstnil
        test [byte si+4],2
        jnz err19
        push di
        push si
        mov si,[si]
        call cons
        pop si
        push bx
__A:
        mov di,bx
        mov si,[si+2]
        or si,si
        jz __ok
        test [byte si+4],2
        jnz err19
        push si
        mov si,[si]
        call cons
        mov [di+2],bx
        pop si
        jmp __A
__ok:
        pop bx
        pop si
        mov [di+2],si
        ret
firstnil:
        mov bx,di
        ret
ENDP

PROC    random
        call checksi
        call loadsi
        call rrandom
        xor dx,dx
        jmp gointern
ENDP

PROC    rrandom
;INPUT: ax-range
;OUTPUT:ax-random num 0..range-1
        or ax,ax
        jz __ret
        mov bx,ax
        in al,40h
        mov ah,al
        in al,40h
        mov cx,13473
        xor ax,[seed]
        mul cx
        xor dx,dx
        add ax,53521
        mov [seed],ax
        div bx
        mov ax,dx
__ret:  ret
seed    dw 0
ENDP

PROC    randomize
        mov ah,2ch
        int 21h
        xor cx,dx
        mov [seed],cx
        ret
ENDP

PROC    cls
        mov al,_mode
        xor ah,ah
        int 10h
        mov bx,t
        ret
_mode   db 3
ENDP

PROC    load
        call notdigit
        mov __name,si
        mov di,offset fname
        mov dx,di
        mov bx,[si+2]
__next4:
        mov si,[bx]
        mov cx,4
__loop:
        lodsb
        or al,al
        jz __end
        stosb
        loop __loop
        mov bx,[bx+2]
        or bx,bx
        jnz __next4
__end:
        mov ax,'l.'
        stosw
        mov ax,'ps'
        stosw
        xor al,al
        stosb
        mov ax,3d00h
        int 21h
        jc err16
        mov inhandle,ax
        or echo,1
        mov linelen,0
        jmp StartPoint
err16:
        mov si,__name
        mov al,16
        jmp error
__name  dw ?
ENDP

PROC    last
;ax,cx are not destroyed
__A:    call sure
        mov di,[si+2]
        or di,di
        xchg si,di
        jnz __A
        mov bx,[di]
        ret
ENDP

PROC    nconc
        or si,si
        jz __nil
        mov cx,si
        xchg ax,di
        call last
        mov [di+2],ax
        mov bx,cx
        ret
__nil:
        mov bx,di
        ret
ENDP

PROC    nth
        mov si,[si+2]
        mov cx,[si]
        mov si,di
        jcxz __ok
__loop:
        call sure
        mov si,[si+2]
        loop __loop
__ok:
        call sure
        mov bx,[si]
        ret
ENDP

PROC    funcall
        mov di,[si+2]
        push di
        mov si,[si]
        call eval
        mov si,bx
        pop di
        jmp apply
ENDP

PROC    _loop
        push si
        call progn
        pop si
        cmp switch,0
        jz _loop
        mov switch,0
        ret
ENDP

PROC    progn
        xor bx,bx
        mov switch,0
__A:    or si,si
        jz __ok
        push si
        mov si,[si]
        call eval
        pop si
        mov si,[si+2]
        cmp switch,0
        jz __A
__ok:
        ret
ENDP

PROC    prog1
        push si
        mov si,[si]
        call eval
        pop si
        push bx
        mov si,[si+2]
__A:    or si,si
        jz __ok
        push si
        mov si,[si]
        call eval
        pop si
        mov si,[si+2]
        jmp __A
__ok:
        pop bx
        ret
ENDP

PROC    memb
__A:
        or di,di
        jz __nret
        cmp si,[di]
        je __found
        mov di,[di+2]
        jmp __A
__nret: xor bx,bx
        ret
__found:mov bx,di
        ret
ENDP

PROC    member
__A:
        or di,di
        jz __nret
        push si di
        mov di,[di]
        call equal
        pop di si
        or bx,bx
        jnz __found
        mov di,[di+2]
        jmp __A
__found:
        mov bx,di
        ret
__nret:
        xor bx,bx
        ret
ENDP

PROC    equal
        cmp si,di
        je __tret
        mov al,[si+4]
        or al,[di+4]
        test al,2
        jnz __nret
        push si di
        mov si,[si]
        mov di,[di]
        call equal
        pop di si
        mov si,[si+2]
        mov di,[di+2]
        or bx,bx
        jnz equal
        ret
__tret: mov bx,t
        ret
__nret: xor bx,bx
        ret
ENDP

PROC    selectq
        mov di,[si+2]
        push di
        mov di,[di]
        mov si,[si]
        push di
        call eval
        pop di
__loop:
        or di,di
        jz default
        cmp bx,[di]
        je __found
        mov di,[di+2]
        or di,di
        jz err31
        mov di,[di+2]
        jmp __loop
__found:
        mov di,[di+2]
        or di,di
        jz err31
        mov si,[di]
        pop di
        jmp eval
default:pop si
        mov si,[si+2]
        mov si,[si]
        jmp eval
err31:  mov al,31
        jmp error
ENDP

PROC    gensym
        mov ax,heapptr
        mov oldheap,ax
__A:    call next
        call intern
        mov ax,heapptr
        cmp oldheap,ax
        je __A
        ret
        db 10 dup(0)
gsym    db 'G000000',0
oldheap dw ?
ENDP

PROC    next
        mov si,offset gsym+6
__A:    inc [byte si]
        cmp [byte si],'9'
        jbe __ok
        mov [byte si],'0'
        dec si
        jmp __A
__ok:
        mov si,offset gsym
        mov di,offset pnbuf
        mov cx,4
        rep movsw
        ret
ENDP

PROC    loadsidi
        mov di,[di+2]
        mov bx,[di]
        mov cx,[di+2]
loadsi:
        mov si,[si+2]
        mov ax,[si]
        mov dx,[si+2]
        ret
ENDP

PROC    gointern
        mov [word pnbuf],ax
        mov [word pnbuf+2],dx
        mov numprop,1
        jmp intern
ENDP

PROC    greqp
        call checksidi
        call loadsidi
        cmp dx,cx
        jg __yes
        jl __no
        cmp ax,bx
        jb __no
__yes:
        mov bx,t
        ret
__no:   xor bx,bx
        ret
ENDP

PROC    greaterp
        call checksidi
        call loadsidi
        cmp dx,cx
        jg __yes
        jl __no
        cmp ax,bx
        jbe __no
__yes:
        mov bx,t
        ret
__no:   xor bx,bx
        ret
ENDP

PROC    lessp
        call checksidi
        call loadsidi
        cmp dx,cx
        jl __yes
        jg __no
        cmp ax,bx
        jae __no
__yes:
        mov bx,t
        ret
__no:   xor bx,bx
        ret
ENDP

PROC    add1
        call checksi
        call loadsi
        add ax,1
        adc dx,0
        jmp gointern
ENDP

PROC    sub1
        call checksi
        call loadsi
        sub ax,1
        sbb dx,0
        jmp gointern
ENDP

PROC    expt
        call checksidi
        mov si,[si+2]
        mov bx,[si]
        mov cx,[si+2]
        mov si,di
        mov di,[di+2]
        mov di,[di]
        mov ax,1
        xor dx,dx
        or di,di
        js err29
        jz __ok
__loop:
        push dx ax cx bx
        call longmul
        dec di
        jnz __loop
__ok:
        jmp gointern
err29:  mov al,29
        jmp error
ENDP

PROC    leftshift
        call checksidi
        call loadsidi
        mov cx,bx
        or cx,cx
        js __right
        jz __l
__loop2:
        shl ax,1
        rcl dx,1
        loop __loop2
__l:    jmp gointern
__right:
        neg cx
__loop:
        sar dx,1
        rcr ax,1
        loop __loop
        jmp gointern
ENDP

PROC    minus
        call checksi
        call loadsi
        call invert
        jmp gointern
ENDP

PROC    minusp
        call checksi
        mov si,[si+2]
        test [byte si+3],80h
        jnz _zero
        xor bx,bx
        ret
ENDP

PROC    zerop
        cmp si,zero
        je _zero
        xor bx,bx
        ret
_zero:
        mov bx,t
        ret
ENDP

PROC    onep
        cmp si,one
        je _zero
        xor bx,bx
        ret
ENDP

PROC    numberp
        cmp [byte si+4],fix*4+2
        je _zero
        xor bx,bx
        ret
ENDP

PROC    sure
        or si,si
        jz __nil
        test [byte si+4],2
        jnz err19
        ret
__nil:  mov si,offset twonil
        ret
err19:  mov al,19
        jmp error
ENDP

PROC    cadddr
        call sure
        mov si,[si+2]
caddr:
        call sure
        mov si,[si+2]
cadr:
        call sure
        mov si,[si+2]
car:
        call sure
car2:   mov bx,[si]
        ret
ENDP

PROC    caar
        call sure
        mov si,[si]
        call sure
        mov bx,[si]
        ret
ENDP

PROC    cddr
        call sure
        mov si,[si+2]
cdr:
        call sure
cdr2:   mov bx,[si+2]
        ret
ENDP

cadar:
        call sure
        mov si,[si]
        call sure
        mov si,[si+2]
        call sure
        mov bx,[si]
        ret
cdar:
        call sure
        mov si,[si]
        call sure
        mov bx,[si+2]
        ret

PROC    atom
        test [byte si+4],2
        jnz t_ret
nil_ret:
        xor bx,bx
        ret
t_ret:
        mov bx,t
        ret
ENDP

PROC    _eq
        cmp si,di
        je t_ret
        xor bx,bx
        ret
ENDP

PROC    null
        or si,si
        jz t_ret
        xor bx,bx
        ret
ENDP

PROC    cons
        mov bx,heapptr
        or bx,bx
        jnz __ok
        push si di
        call reclaim
        pop di si
        mov bx,heapptr
__ok:
        mov bx,[bx+2]
        xchg heapptr,bx
        mov [bx],si
        mov [bx+2],di
        ret
ENDP

PROC    sadd1
        mov si,[si]
        call assoc
        mov si,[bx+2]
        call checksi
        push bx
        call loadsi
        add ax,1
        adc dx,0
        call gointern
        pop si
        mov [si+2],bx
        ret
ENDP

PROC    ssub1
        mov si,[si]
        call assoc
        mov si,[bx+2]
        call checksi
        push bx
        call loadsi
        sub ax,1
        sbb dx,0
        call gointern
        pop si
        mov [si+2],bx
        ret
ENDP

PROC    rplaca
        test [byte si+4],2
        jnz err19
        mov [si],di
        mov bx,si
        ret
ENDP

PROC    rplacd
        test [byte si+4],2
        jnz err19
        mov [si+2],di
        mov bx,si
        ret
ENDP

PROC    setq
        push si
        mov si,[si+2]
        mov si,[si]
        call eval
        pop si
        push bx
        mov si,[si]
        call assocn
        jc _novar
        pop si
        mov [bx+2],si
        mov bx,si
        ret
_novar:
        pop di
        push di
        call pairlis1
        pop bx
        ret
ENDP

PROC    set
        push di
        call assocn
        jc _novar
        pop ax
        mov [bx+2],ax
        xchg bx,ax
        ret
ENDP

PROC    csetq
        mov di,[si+2]
        mov si,[si]
        call notdigit
        push si
        mov si,[di]
        call eval
        pop si
        mov di,[si]
        mov [di],bx
        mov [byte si+4],apval*4+2
        mov bx,si
        ret
ENDP

PROC    cset
        call notdigit
        mov [byte si+4],apval*4+2
        mov bx,si
        mov si,[si]
        mov [si],di
        ret
ENDP

PROC    oper
        shl si,1
        mov di,[optable+si]
        mov si,bx
__A:
        or si,si
        jz gointern
        mov bx,[si]
        mov si,[si+2]
        cmp [byte bx+4],fix*4+2
        jne _err10
        mov bx,[bx+2]
        mov cx,[bx+2]
        mov bx,[bx]
        call di
        jmp __A
_err10:
        mov al,10
        MOV SI,BX
        jmp error
ENDP

optable dw offset _plus
        dw offset _times
        dw offset _logor
        dw offset _logand
        dw offset _logxor
        dw offset _max
        dw offset _min

PROC    max
        call list
        mov ax,0
        mov dx,8000h
        mov si,5
        jmp oper
ENDP

PROC    min
        call list
        mov ax,0ffffh
        mov dx,7fffh
        mov si,6
        jmp oper
ENDP

PROC    plus
        call list
        xor ax,ax
        xor dx,dx
        mov si,0
        jmp oper
ENDP

PROC    logor
        call list
        xor ax,ax
        xor dx,dx
        mov si,2
        jmp oper
ENDP

PROC    logand
        call list
        mov ax,0ffffh
        mov dx,0ffffh
        mov si,3
        jmp oper
ENDP

PROC    logxor
        call list
        xor ax,ax
        xor dx,dx
        mov si,4
        jmp oper
ENDP

PROC    _max
        cmp cx,dx
        jl _no2
        jg _yes2
        cmp bx,ax
        jbe _no2
_yes2:
        mov ax,bx
        mov dx,cx
_no2:
        ret
ENDP

PROC    _min
        cmp cx,dx
        jg _no2
        jl _yes2
        cmp bx,ax
        jb _yes2
        ret
ENDP

PROC    _plus
        add ax,bx
        adc dx,cx
        ret
ENDP

PROC    _logor
        or ax,bx
        or dx,cx
        ret
ENDP

PROC    _logand
        and ax,bx
        and dx,cx
        ret
ENDP

PROC    _logxor
        xor ax,bx
        xor dx,cx
        ret
ENDP

PROC    TIMES
        call list
        mov ax,1
        xor dx,dx
        mov si,1
        jmp oper
ENDP

PROC    _times
        push dx ax cx bx
        call longmul
        ret
ENDP

PROC    checksidi
        cmp [byte si+4],fix*4+2
        jne err10
        cmp [byte di+4],fix*4+2
        jne err10di
        ret
checksi:
        cmp [byte si+4],fix*4+2
        jne err10
        ret
err10di:mov si,di
err10:  MOV AL,10
        jmp error
ENDP

PROC    diff
        or di,di
        jz minus
        call checksidi
        call loadsidi
        sub ax,bx
        sbb dx,cx
        jmp gointern
ENDP

PROC    quotient
        call checksidi
        call loadsidi
        push dx ax cx bx
        call longdiv
        jmp gointern
ENDP

PROC    remainder
        call checksidi
        call loadsidi
        push dx ax cx bx
        call longdiv
        xchg ax,bx
        xchg dx,cx
        jmp gointern
ENDP


;****************************
;       Implementation
;****************************

PROC    clear
        cmp inhandle,0
        jne __ok
        mov linelen,0
__ok:   ret
ENDP

PROC    activefile
        mov inhandle,0
        mov outhandle,0
        mov linelen,0
        push ds es
        mov ax,ds
        sub ax,10h
        mov ds,ax
        mov es,ax
        mov cl,[byte ds:80h]
        cmp cl,2
        jb __nofile
        xor ch,ch
        mov di,82h
        mov al,' '
        repnz scasb
        mov [byte di-1],0
        mov dx,82h
        mov ax,3d00h
        int 21h
        jc __nofile
        mov cs:inhandle,ax
        or cs:echo,1
        jcxz __nofile
        mov dx,di
        mov al,0dh
        repnz scasb
        mov [byte di-1],0
        xor cx,cx
        mov ah,3ch
        int 21h
        jc __nofile
        mov cs:outhandle,ax
        and cs:echo,not 1
__nofile:
        pop es ds
        ret
ENDP

PROC    prdos
        push ax si
        mov si,dx
__loop: lodsb
        cmp al,'$'
        je __ok
        call pri
        jmp __loop
__ok:   pop si ax
        ret
ENDP

PROC    prepare_memory
        progsize=heapbeg-start
        cells=(65534-progsize)/5
        heapend=offset heapbeg+cells*5
        mov cx,cells*5
        mov di,offset heapbeg
        xor al,al
        rep stosb
        call freemem
        ret
ENDP

PROC    escape
        push ax
        mov ah,1
        int 16h
        jz __ok
        cmp al,27
        jnz __ok
        mov ah,0
        int 16h
        mov al,11
        jmp error
__ok:
        pop ax
        ret
ENDP

PROC    wratom
        push bx cx di           ;нормально для мусорщика
        call escape
        mov dl,[si+4]
        and dl,00011100b
        shl dl,1
        xor dh,dh
        add dx,offset ftable
        call prdos
        push si
        call prin1
        pop si
        mov al,9
        call pri
        mov al,[si+4]
        and al,not 20h
        mov dx,si
        mov si,[si]
        cmp al,2
        je __var
        cmp al,fix*4+2
        je __ex
        cmp al,subr*4+2
        je __sub
        cmp al,_fsubr*4+2
        je __sub
        mov si,[si]
        call pprint
        jmp __nocr
__ex:
        call cr
__nocr: pop di cx bx
        ret
__sub:
        mov dx,offset __adr
        call prdos
        mov ax,[si]
        xor dx,dx
        call wrdec
        jmp __ex
__var:
        mov si,dx
        call assocn
        jc __ex
        mov si,[bx+2]
        call prin0
        jmp __ex

ftable  db 'Атом   $SUBR   $FSUBR  $EXPR   $FEXPR  $APVAL  $FIX    $MACRO  $'
__adr   db 'Адрес:$'
ENDP

PROC    objects
        mov bx,offset hashtable
        mov cx,256
        mov [countob],0
__loop:
        mov di,[bx]
__A:    or di,di
        jz __ok
        mov si,[di]
        call wratom
        inc countob
        mov di,[di+2]
        jmp __A
__ok:
        inc bx
        inc bx
        loop __loop
        mov dx,offset __pr1
        call prdos
        mov ax,countob
        xor dx,dx
        jmp gointern
countob dw ?
__pr1   db 'Число атомов в системе:$'
ENDP

PROC    copyright
        mov dx,offset maxsoft
        jmp prdos
maxsoft db 'LISP v1.5+  (c) MaxSoft,','   Автор:Свешников М.',13,10,'$'
ENDP

PROC    cr
        push ax
        mov al,13
        call pri
        mov al,10
        call pri
        pop ax
        ret
ENDP

PROC    move_list
        mov si,offset subr_list
        mov cx,end_list-subr_list
        xor bp,bp
__loop:
        lodsb
        mov [ss:bp],al
        inc bp
        loop __loop
        ret
ENDP

PROC    convert
        push si bx
        mov si,offset pnbuf
        mov sign,0
        xor ax,ax
        xor dx,dx
        mov bl,[si]
        cmp bl,'+'
        je __plus
        cmp bl,'-'
        jne __loop
        mov sign,1
__plus: inc si
__loop:
        mov bl,[si]
        inc si
        sub bl,'0'
        xor bh,bh
        add ax,bx
        adc dx,0
        cmp [byte si],0
        jz __done
        push dx
        push ax
        xor ax,ax
        push ax
        mov ax,10
        push ax
        call longmul
        jmp __loop
__done:
        cmp sign,1
        jne __pl
        call invert
__pl:
        mov [word pnbuf],ax
        mov [word pnbuf+2],dx
        pop bx si
        ret
sign    db ?
ENDP

PROC    wrdec
        push ax bx dx si di
        mov di,offset buf
        or dx,dx
        jns __plus
        push ax
        mov al,'-'
        call pri
        pop ax
        call invert
__plus:
        push dx
        push ax
__loop:
        xor ax,ax
        push ax
        mov ax,10
        push ax
        call longdiv
        push dx
        push ax
        or dx,ax
        mov al,bl
        add al,'0'
        stosb
        or dx,dx
        jnz __loop
        pop ax
        pop ax
        std
        mov si,di
        dec si
__l:
        lodsb
        or al,al
        jz __ok
        call pri
        jmp __l
__ok:
        cld
        pop di si dx bx ax
        ret

        db 0
buf     db 12 dup(?)
ENDP

PROC    invert
        not ax
        not dx
        add ax,1
        adc dx,0
        ret
ENDP

PROC    absnum
        mov dx,[ss:bx+2]
        or dx,dx
        jns __ok
        mov ax,[ss:bx]
        call invert
        mov [ss:bx],ax
        mov [ss:bx+2],dx
__ok:   ret
ENDP

PROC    longmul  x1:word:2,x2:word:2
;OUTPUT DX:AX-result
;       err27 if overflow
        push bp
        mov bp,sp
        push bx cx si di
        mov al,[byte x1+3]
        xor al,[byte x2+3]
        mov signs,al
        lea bx,x1
        call absnum
        lea bx,x2
        call absnum
        mov di,[x1+2]
        or di,di
        jz x1less
        mov ax,[x2+2]
        or ax,ax
        jnz err27
        mov si,[x1]
        mov ax,[x2]
        jmp __mul
x1less:
        mov di,[x2+2]
        mov si,[x2]
        mov ax,[x1]
__mul:  push ax
        mul si
        mov bx,ax
        mov cx,dx
        pop ax
        mul di
        jc err27
        add ax,cx
        jc err27
        mov dx,bx
        xchg ax,dx
        test dh,10000000b
        jnz err27
        test signs,80h
        jz __done
        call invert
__done:
        pop di si cx bx
        pop bp
        ret 8
err27:  mov al,27
        jmp error
signs   db ?
ENDP

PROC    longdiv  B:word:2,A:word:2
;OUTPUT DX:AX-частное A/@
;       CX:BX-остаток
;       err27 if overflow
        push bp
        mov bp,sp
        push si
        mov al,[byte B+3]
        xor al,[byte A+3]
        mov signs,al
        lea bx,A
        call absnum
        lea bx,B
        call absnum
        mov ax,[word B]
        or ax,[word B+2]
        jz err27
        xor cx,cx
__l:    test [word B+2],8000h
        jnz __ok
        shl [word B],1
        rcl [word B+2],1
        inc cx
        jmp __l
__ok:
        inc cx
        mov ax,[word A]
        mov dx,[word A+2]
        xor si,si
        xor bx,bx
cyc:    sub ax,[word B]
        sbb dx,[word B+2]
        jc less
        stc
        jmp __all
less:   add ax,[word B]
        adc dx,[word B+2]
        clc
__all:
        rcl si,1
        rcl bx,1
        shr [word B+2],1
        rcr [word B],1
        loop cyc
        mov cx,dx
        mov dx,bx
        mov bx,ax
        mov ax,si
        test signs,80h
        jz __done
        call invert
__done:
        pop si
        pop bp
        ret 8
ENDP

PROC    reclaim
        mov stackptr,sp
        push ax cx dx bp
        call truetime
        mov [rtime],ax
        mov [rtime+2],dx
        mov ah,0bh
        int 21h
        test echo,4
        jz __nomess1
        mov dx,offset __mess1
        call prdos
__nomess1:
        call mark
        call freemem
        mov freed,dx
        cmp dx,MIN_ALLOC
        jb err4
        test echo,4
        jz __nomess2
        mov ax,dx
        xor dx,dx
        call wrdec
        mov dx,offset __mess2
        call prdos
__nomess2:
        call truetime
        sub ax,[rtime]
        sbb dx,[rtime+2]
        add [btime],ax
        adc [btime+2],dx
        pop bp dx cx ax
        ret
err4:
        mov al,4
        jmp error
freed   dw ?
rtime   dw ?,?
__mess1 db 13,10,'Сборка мусора ... $'
__mess2 db ' ячеек свободно',13,10,'$'
ENDP

PROC    recl
        call reclaim
        mov ax,freed
        xor dx,dx
        jmp gointern
ENDP

PROC    hash
;OUTPUT:di-start address
        mov al,[pnbuf]
        rol al,1
        rol al,1
        xor al,[pnbuf+1]
        add al,[pnbuf+2]
        add al,[pnbuf+3]
        xor ah,ah
        shl ax,1
        mov di,offset hashtable-2
        add di,ax
        ret
ENDP

PROC    comp
;INPUT: si-atom info address
;       pnbuf-ASCIIZ string
;OUTPUT:ZF if equal
;       NZ if diff
        push si di
        mov bx,[si+2]
        cmp numprop,0
        jne __numbers
__chars:
        test [byte bx+4],1
        jnz __ok
        mov di,offset pnbuf
__loop:
        mov si,[bx]
        mov cx,4
__ll:
        cmpsb
        jnz __ok
        cmp [byte di-1],0
        je __ok
        loop __ll
        mov bx,[bx+2]
        cmp bx,0
        jne __loop
        cmp [byte di],0
        jmp __ok
__numbers:
        test [byte bx+4],1
        jz __bad
        mov ax,[bx]
        cmp ax,[word pnbuf]
        jne __ok
        mov ax,[bx+2]
        cmp ax,[word pnbuf+2]
__ok:
        pop di si
        ret
__bad:  or al,1
        pop di si
        ret
ENDP

PROC    intern
;INPUT: pnbuf-ASCIIZ string or dword
;       numprop=0 if atom
;              =1 if number
;OUTPUT bx-address of atom
        call hash
__A:
        mov bx,[di+2]
        or bx,bx
        jz __nopresent
        mov di,bx
        mov si,[di]
        call comp
        jnz __A
        jmp __ex
__nopresent:
        push di
        call newatom
        mov si,bx
        xor di,di
        call cons
        pop di
        mov [di+2],bx
__ex:   mov bx,si
        cmp bx,nil
        jne __ok
        xor bx,bx
__ok:
        ret
ENDP

PROC    len
;INPUT  pnbuf-ASCIIZ
;OUTPUT cx-length of string
        push di
        mov di,offset pnbuf
        mov cx,256
        xor al,al
        repnz scasb
        sub cx,255
        neg cx
        pop di
        ret
ENDP

PROC    newatom
;INPUT  pnbuf-ASCIIZ string or dword
;OUTPUT bx-address
        xor si,si
        call cons
        push bx
        mov di,bx
        mov si,offset pnbuf
        cmp numprop,0
        jne __num
__char:
        mov [byte bx+4],2
        call len
        sub cx,1
        shr cx,1
        shr cx,1
        inc cx
__copy:
        call cons
        mov [di+2],bx
        mov di,bx
        call cons
        mov [byte bx+4],1
        mov [di],bx
        push di
        mov di,bx
        movsw
        movsw
        pop di
        loop __copy
        mov [word di+2],0
        xor si,si
        xor di,di
        call cons
        xchg ax,bx
        pop bx
        mov [bx],ax
        ret
__num:
        mov [bx],bx
        mov [byte bx+4],fix*4+2
        call cons
        mov [di+2],bx
        mov [byte bx+4],1
        mov di,bx
        movsw
        movsw
        pop bx
        ret
ENDP

PROC    init_hash
        mov DI,offset hashtable
        mov cx,256
        XOR AX,AX
        rep stosw
        ret
ENDP

PROC    create_list
        mov bp,offset apv_list
        xor si,si
__loop:
        call InsertItem
        cmp si,end_list-subr_list
        jb __loop

        mov bx,nil
        mov bx,[bx+2]
        mov [ds:2],bx

        mov cx,num_of_syms
        mov si,offset assign_list
__ll:
        mov bx,[si+num_of_syms*2]
        mov bx,[bx]
        mov ax,[si]
        mov [bx],ax
        inc si
        inc si
        loop __ll
        ret
ENDP

PROC    InsertItem
        mov numprop,0
        mov di,offset pnbuf
        mov [word di+2],0
__copy:
        lods [byte ss:si]
        call toupper
        stosb
        or al,al
        jnz __copy
        lods [byte ss:si]
        mov attr,al
        push si
        and al,7fh
        cmp al,fix*4+2
        jne __noconvert
        mov numprop,1
        call convert
__noconvert:
        call intern
        mov di,[bx]
        pop si
        mov cl,attr
        and cl,7fh
        mov [bx+4],cl
        cmp cl,subr*4+2
        je __subr
        cmp cl,_fsubr*4+2
        jne __nosubr
__subr:
        lods [word ss:si]
        mov [di],ax
__nosubr:
        cmp cl,apval*4+2
        jne __noapv
__apval:
        mov [di],bx
__noapv:
        test attr,80h
        jz __nolist
        mov [ds:bp],bx
        inc bp
        inc bp
__nolist:
        ret
attr    db ?
ENDP

PROC    pri
        call vbreak
        cmp outhandle,0
        jne pridos
        cmp al,9
        je __tab
        inc counter
        cmp al,0ah
        jne __ok
        mov counter,0
        int 29h
        push ax
        mov ah,0bh
        int 21h
        pop ax
        ret
__ok:
        int 29h
        ret
__tab:
        push dx
        xor dx,dx
        xchg dx,counter
        and dx,111b
        add dx,offset blanks
        call prdos
        pop dx
        ret
blanks  db '        $'
counter dw 0
ENDP

PROC    pridos
;INPUT  al-symbol to print
        push bx
        mov bx,outptr
        cmp bx,254
        jb __ok
        call flush
__ok:
        mov [outbuf+bx],al
        inc [outptr]
        pop bx
        ret
outptr  dw 0
ENDP

PROC    flush
        push ax cx dx
        mov dx,offset outbuf
        mov cx,outptr
        mov bx,outhandle
        mov ah,40h
        int 21h
        xor bx,bx
        mov outptr,bx
        pop dx cx ax
        ret
ENDP

PROC    prin1
        or si,si
        jz __good
        cmp si,offset heapbeg
        jb err21
__good:
        test [byte si+4],11000001b
        jnz err21
        cmp [byte si+4],fix*4+2
        je __number
__chars:
        mov bx,[si+2]
next4:
        mov si,[bx]
        mov cx,4
__loop:
        lodsb
        or al,al
        jz __ok
        call pri
        loop __loop
        mov bx,[bx+2]
        or bx,bx
        jnz next4
__ok:   ret
__number:
        call loadsi
        jmp wrdec
err21:  mov al,21
        jmp error
ENDP

PROC    print
        call _prin1
        jmp cr
ENDP

PROC    _prin1
        push si
        call prin0
        pop bx
        ret
ENDP

PROC    prin0
        test [byte si+4],11000011b
        jnz prin1
        mov di,si
        mov al,'('
        call pri
__A:
        mov si,[di]
        push di
        call prin0
        pop di
        mov di,[di+2]
        or di,di
        jz __done
        mov al,' '
        call pri
        test [byte di+4],2
        jz __A
        mov al,'.'
        call pri
        mov al,' '
        call pri
        mov si,di
        call prin1
__done:
        mov al,')'
        jmp pri
ENDP

PROC    ungetc
        dec lineptr
        mov ung,1
        ret
ung     db 0
ENDP

PROC    readsym
;OUTPUT:al-read symbol
        push bx
again:  mov si,lineptr
        cmp si,linelen
        jae enterfileline
        mov al,[si+readbuf+2]
        test echo,1
        jz noecho
        cmp ung,1
        je noecho
        call pri
noecho:
        mov ung,0
        inc lineptr
        pop bx
        ret
enterfileline:
        mov bx,inhandle
        or bx,bx
        jz enterkeyline
        mov ah,3fh
        mov cx,254
        mov dx,offset readbuf+2
        int 21h
        or ax,ax
        jz eof
        mov linelen,ax
        mov lineptr,0
        jmp again
eof:    mov al,32
        jmp error
enterkeyline:
        cmp command,0
        je notcom
        mov dx,offset prompt
        call prdos
notcom: mov ah,0ah
        mov dx,offset readbuf
        mov [byte readbuf],254
        mov [byte readbuf+1],0
        int 21h
        mov al,[readbuf+1]
        xor ah,ah
        inc ax
        mov linelen,ax
        mov lineptr,0
        call cr
        jmp again
lineptr         dw 0
linelen         dw 0
ENDP

PROC    error
        mov field,-3
        mov tracing,0
        mov switch,0
        cmp al,32
        jb __ok2
        jz __eof
        xor al,al
__ok2:
        mov dx,offset __erpr
        call prdos
        mov di,offset errtable
        mov cx,enderrtable-errtable
        repnz scasb
        push ax
__loop1:
        mov al,[di]
        inc di
        cmp al,'$'
        je __ok
        cmp al,'%'
        je __format
        call pri
        jmp __loop1
__format:
        push di
        call prin0
        pop di
        jmp __loop1
__ok:
        cmp [byte di],'$'
        jne __ret
        mov si,curreval
        mov cx,[si]
        cmp cx,quote
        je __ret
        call cr
        mov dx,offset __pr
        call prdos
        call prin0
__ret:
        call cr
        call clear
        pop ax
__eof:
        mov bx,savedaptr
        mov aptr,bx
        jmp [savedaddr]

__erpr  db 13,10,'Ошибка    : $'
__pr    db       'Выражение : $'
savedaptr       dw 0
savedaddr       dw ?
ENDP

PROC    isblank
;INPUT  al-symbol
;OUTPUT:CF if blank
        cmp al,33
        ret
ENDP

PROC    isdelim
        cmp al,';'
        je delim
        cmp al,"'"
        je delim
        cmp al,'('
        je delim
        cmp al,')'
        je delim
        cmp al,'.'
_sel:   je delim
_no:    clc
        ret
delim:  stc
_ret:   ret
ENDP

PROC    isspec
        call isblank
        jnc isdelim
        ret
ENDP

PROC    isdigit
        cmp al,'9'+1
        jnc _ret
        cmp al,'0'
        cmc
        ret
ENDP

PROC    issign
        cmp al,'+'
        je delim
        cmp al,'-'
        jmp _sel
ENDP

PROC    reada
;OUTPUT:numprop=0 if chars
;       numprop=1 if number
digit           equ bl
signonly        equ bh
        mov bx,0101h
        mov di,offset pnbuf
        xor ax,ax
        mov [di],ax
        mov [di+2],ax
skip:   call readsym
        call isblank
        jc skip
        call isdelim
        jc __delim
        call issign
        jc __store
        call isdigit
        jc _maybenum2
        mov digit,0
_maybenum2:
        mov signonly,0
__store:
        cmp al,descriptor
        jne __usual
        call copyto
        jmp __skip
__usual:
        call toupper
        stosb
        cmp di,offset pnbuf+254
        ja err24
__skip:
        call readsym
        call isspec
        jc __end
        call isdigit
        jc __may
        mov digit,0
__may:
        mov signonly,0
        jmp __store
__end:
        call ungetc
__ok:
        xor al,al
        stosb
        cmp digit,0
        jz __done
        cmp signonly,1
        je __done
        mov numprop,1
        jmp convert
__delim:
        cmp al,';'
        je comme
        mov [pnbuf],al
__done:
        mov numprop,0
        ret
err24:  mov al,24
        jmp error
comme:
        call readsym
        cmp al,13
        jne comme
        jmp reada
ENDP

PROC    copyto
        call readsym
        cmp al,descriptor
        je __ok
        cmp di,offset pnbuf+254
        ja err24
        stosb
        jmp copyto
__ok:
        ret
ENDP

PROC    read1
        call reada
        jmp intern
ENDP

PROC    readq
        call read
        mov si,bx
        xor di,di
        call cons
        mov di,bx
        mov si,quote
        jmp cons
ENDP

PROC    read2
        call read1
        cmp bx,lpar
        je read0
        cmp bx,apostrof
        je readq
        ret
ENDP

PROC    read
        call read2
        cmp bx,rpar
        je err1
        cmp bx,period
        je err1
        ret
err1:   mov al,1
        mov si,bx
        jmp error
ENDP

PROC    read0
        xor si,si
        xor di,di
        call cons
        push bx
        mov di,bx
__A:
        push di
        call read2
        pop di
        cmp bx,rpar
        je __E
        cmp bx,period
        je __B
        push di
        mov si,bx
        xor di,di
        call cons
        pop di
        mov [di+2],bx
        mov di,bx
        jmp __A
__B:
        pop si
        push si
        cmp si,di
        je err23
        push di
        call read2
        pop di
        cmp bx,rpar
        je err2
        cmp bx,period
        je err2
        mov [di+2],bx
        call read1
        cmp bx,rpar
        jne err22
__E:
        pop bx
        mov bx,[bx+2]
        ret
err2:   mov al,2
        mov si,bx
        jmp error
err22:  mov al,22
        jmp error
err23:  mov al,23
        jmp error
ENDP

PROC    pairlis1
        cmp tracing,1
        jne __no
        call argument
__no:
        call cons
        mov si,bx
        mov di,aptr
        call cons
        mov aptr,bx
        ret
ENDP

PROC    pairlis
        mov plist,di
        mov flist,si
        xor ax,ax
__A:
        test [byte si+4],2
        jnz __ret
        push si
        mov si,[si]
        cmp si,aux
        je __cont
        cmp si,opt
        jne __noopt
        mov ax,1
        pop si
        mov si,[si+2]
        jmp __A
__noopt:
        cmp si,rest
        jne __no
        pop si
        mov si,[si+2]
        test [byte si+4],2
        jnz err17
        push si
        mov si,[si]
        call pairlis1
        jmp __cont
__no:
        or di,di
        jz __endlist
        push di
        test [byte si+4],2
        jnz __noinit
        mov si,[si]
__noinit:
        mov di,[di]
        call pairlis1
        pop di si
        mov si,[si+2]
        mov di,[di+2]
        jmp __A
__endlist:
        pop si
        or ax,ax
        jz err3
__loop:
        push si
        mov si,[si]
        test [byte si+4],2
        jnz __atom
        push [si]
        mov si,[si+2]
        test [byte si+4],2
        jnz __one               ;н-р (k)
        mov si,[si]
        push tracing
        call eval
        pop tracing
        pop si
        mov di,bx
        call pairlis1
        jmp __cont
__one:  pop si
__atom:
        cmp si,rest
        je __cont
        cmp si,aux
        je __cont
        xor di,di
        call pairlis1
__cont:
        pop si
        mov si,[si+2]
        or si,si
        jnz __loop
__ret:
        mov tracing,0
        ret

err3:   mov al,3
        mov si,plist
        jmp error
err17:  mov al,17
        mov si,flist
        jmp error
plist           dw ?
flist           dw ?
ENDP

PROC    assoc
        call assocn
        jc err5
        ret
ENDP

PROC    assocn
;OUTPUT:bx-adress of var cell
;si is not destroyed
;CF if not bound
        call notdigit
        mov bx,aptr
__A:
        or bx,bx
        jz __no
        mov di,[bx]
        mov bx,[bx+2]
        cmp [di],si
        jne __A
__yes:
        mov bx,di
        clc
        ret
__no:   stc
        ret
ENDP

PROC    eval
        or si,si
        jz __nil
        cmp si,offset heapbeg
        jb err14
        test [byte si+4],1
        jnz err14
        test [byte si+4],2
        jnz evatom
        mov curreval,si
        mov di,[si+2]
        mov si,[si]
        or di,di
        jz apply
        test [byte di+4],3
        jz apply
err14:  mov al,14
        jmp error
__nil:  xor bx,bx
        ret
ENDP

PROC    evatom
        cmp [byte si+4],fix*4+2
        jz __fix
        call assocn
        jc __notbound
        mov bx,[bx+2]
        ret
__notbound:
        cmp [byte si+4],apval*4+2
        jne err5
        mov si,[si]
        mov bx,[si]
        ret
__fix:
        mov bx,si
        ret
err5:   mov al,5
        jmp error
ENDP

PROC    vbreak
        dec [cbcount]
        jnz __ok
        push ax
        mov ah,0bh
        int 21h
        pop ax
        mov cbcount,300
__ok:
        ret
cbcount dw 300
ENDP

PROC    apply
        cmp sp,200
        jb err28
        call vbreak
        test [byte si+4],2
        jnz evfun
        mov bx,si
        mov ax,[si]
        mov si,[si+2]
        cmp ax,lambda
        jne __l
        push si
        mov si,di
        call list
        mov di,bx
        pop si
        jmp evlam
__l:
        cmp ax,funarg
        je evfarg
        cmp ax,ffarg
        je evffarg
        mov al,6
        mov si,bx
        jmp error
err28:  mov al,28
        jmp error
ENDP

PROC    list
        xor di,di
        call cons
        push bx
        mov di,bx
__A:
        or si,si
        jz __ok
        push si di
        mov si,[si]
        call eval
        mov si,bx
        xor di,di
        call cons
        pop di si
        mov [di+2],bx
        mov si,[si+2]
        mov di,bx
        jmp __A
__ok:
        pop bx
        mov bx,[bx+2]
        ret
ENDP

PROC    evfun
        mov al,[si+4]
        test al,20h
        jz _evfun
        cmp al,subr*4+2+20h
        je __subr
        cmp al,_fsubr*4+2+20h
        je __subr
__expr:
        add field,3
        push si di
        call indent
        call prin1
        mov al,':'
        call pri
        call cr
        pop di si
        push si
        mov tracing,1
        call _evfun
        pop si
        push bx
        call indent
        call prin1
        mov dx,offset eqsign
        call prdos
        pop si
        push si
        call prin0
        call cr
        sub field,3
        pop bx
        ret
__subr:
        jmp _evfun
tracing dw 0
ENDP

PROC    argument
        push si di
        push di
        call indent
        call prin1
        mov dx,offset eqsign
        call prdos
        pop si
        call prin0
        call cr
        pop di si
        ret
eqsign  db ' = $'
ENDP

PROC    indent
        push ax cx
        mov cx,field
        cmp cx,0
        jle __ok
        mov al,' '
__loop:
        call pri
        loop __loop
__ok:
        pop cx ax
        ret
field   dw -3
ENDP

PROC    _evfun
        mov al,[si+4]
        and al,not 20h
        cmp al,subr*4+2
        je __subr
        cmp al,_fsubr*4+2
        je __fsubr
        cmp al,expr*4+2
        je __expr
        cmp al,fexpr*4+2
        je __fexpr
        cmp al,_macro*4+2
        je __macro
        cmp al,none*4+2
        je __none
err7:   mov al,7
        jmp error
__subr:
        mov bx,[si]
        push [bx]
        xor si,si
        xor bp,bp
        or di,di
        jz arg1
        mov si,[di]
        push di
        call eval
        pop di
        mov si,bx
        mov di,[di+2]
        or di,di
        jz arg1
        push bx
        mov si,[di]
        push [di+2]
        call eval
        mov di,bx
        pop bp
        pop si
arg1:   ret
__fsubr:
        xchg si,di
        mov di,[di]
        jmp [word di]
__expr:
        mov bx,[si]
        push [bx]
        mov si,di
        push tracing
        mov tracing,0
        call list
        pop tracing
        mov di,bx
        pop si
        jmp evlam
__fexpr:
        mov si,[si]
        mov si,[si]
        jmp evlam
__macro:
        mov si,[si]
        mov si,[si]
        jmp evmacro
__none:
        push di
        call assocn
        jc err7
        pop di
        mov si,[bx+2]
        jmp apply
ENDP

PROC    evlam
        push aptr
        push si
        mov si,[si]
        call pairlis
        pop si
        mov si,[si+2]
        call progn
        pop aptr
        ret
ENDP

PROC    evmacro
        call evlam
        mov si,bx
        jmp eval
ENDP

PROC    macroexpand
        mov bx,[si]
        mov al,not 20h
        and al,[bx+4]
        cmp al,_macro*4+2
        jne err18
        mov di,[si+2]
        mov si,[bx]
        mov si,[si]
        jmp evlam
err18:
        mov al,18
        jmp error
ENDP

PROC    sexpr
        mov cl,expr*4+2
ent:
        mov di,[si+2]
        mov si,[si]
        call notdigit
        mov di,[di]
        mov ax,[di]
        cmp ax,lambda
        jne _err6
        mov [byte si+4],cl
        mov bx,si
        mov si,[si]
        mov ax,[di+2]
        mov [si],ax
        ret
_err6:  mov al,6
        mov si,di
        jmp error
ENDP

PROC    sfexpr
        mov cl,fexpr*4+2
        jmp ent
ENDP

PROC    defmacro
        mov cl,_macro*4+2
def:
        mov di,[si+2]
        mov si,[si]
        call notdigit
        mov [byte si+4],cl
        mov bx,si
        mov si,[si]
        mov [si],di
        ret
ENDP

PROC    defun
        mov cl,expr*4+2
        jmp def
ENDP

PROC    deffun
        mov cl,fexpr*4+2
        jmp def
ENDP

PROC    evfarg
        push aptr
        push [si]
        push [si+2]
        mov si,di
        call list
        pop di
        mov ax,[di]
        mov aptr,ax
        mov di,bx
        pop si
        call evlam
        pop aptr
        ret
ENDP

PROC    _and
        xor bx,bx
__A:
        or si,si
        jz __ret
        push si
        mov si,[si]
        call eval
        pop si
        or bx,bx
        mov si,[si+2]
        jnz __A
__ret:  ret
ENDP

PROC    _or
__A:
        or si,si
        jz __nil
        push si
        mov si,[si]
        call eval
        pop si
        mov si,[si+2]
        or bx,bx
        jz __A
        ret
__nil:
        xor bx,bx
        ret
ENDP

PROC    prog
        push aptr
        push [si+2]
        mov si,[si]
        mov di,offset nillist
        call pairlis
        pop dx
        mov si,dx
        call _segment
        mov switch,0
__A:
        xor bx,bx
        or dx,dx
        je __exit
        mov si,dx
        mov si,[si]
        test [byte si+4],2
        jnz __l2
        push dx di
        call eval
        pop di dx
        cmp switch,0
        jz __l2
        js __B
        mov si,[bx]
        push di
        call lassoc
        pop di
        mov dx,bx
        mov switch,0
__l2:
        mov bx,dx
        mov dx,[bx+2]
        jmp __A
__B:
        mov switch,0
__exit:
        pop aptr
        ret

switch  dw 0
nillist dw 0,offset nillist
ENDP

PROC    _segment
;result-di
        xor di,di
__A:
        or si,si
        jnz __l
        ret
__l:
        mov bx,[si]
        test [byte bx+4],2
        jz __l2
        call cons
        mov di,bx
__l2:
        mov si,[si+2]
        jmp __A
ENDP

PROC    lassoc
__A:
        or di,di
        jz err9
        mov bx,[di]
        cmp si,[bx]
        mov di,[di+2]
        jne __A
        ret
err9:   mov al,9
        jmp error
ENDP

_A:     mov si,[si+2]
PROC    cond
        or si,si
        jz xorret
        push si
        mov si,[si]
        mov si,[si]
        call eval
        pop si
        or bx,bx
        jz _A
        mov si,[si]
        mov si,[si+2]
        or si,si
        jz __ret
        jmp progn
xorret: xor bx,bx
__ret:  ret
ENDP

PROC    return
        mov switch,-1
        mov bx,si
        ret
ENDP

PROC    go
        mov switch,1
bxsi:   mov bx,si
        ret
ENDP

PROC    function
        mov si,[si]
        mov al,[byte si+4]
        and al,not 20h
        mov dx,funarg
        test al,2
        jz __lambda
        cmp al,expr*4+2
        je __expr
        cmp al,fexpr*4+2
        je __fexpr
        cmp al,subr*4+2
        je bxsi
        cmp al,_fsubr*4+2
        je bxsi
        mov al,7
        jmp error
__fexpr:
        mov dx,ffarg
__expr:
        mov si,[si]
        mov si,[si]
        jmp __A
__lambda:
        mov ax,[si]
        cmp ax,lambda
        jne err6
        mov si,[si+2]
__A:
        push si
        mov si,aptr
        xor di,di
        call cons
        mov di,bx
        pop si
        call cons
        mov di,bx
        mov si,dx
        jmp cons
err6:
        mov al,6
        jmp error
ENDP

PROC    evffarg
        push aptr
        mov bx,[si+2]
        mov bx,[bx]
        mov aptr,bx
        mov si,[si]
        call evlam
        pop aptr
        ret
ENDP

;Reclaim procedures
        cm=40h
        cb=80h

MACRO   rb0
        and [byte di+4],not cb
ENDM

MACRO   rb1
        or [byte di+4],cb
ENDM

PROC    marklist
        xor di,di
__A:
        cmp si,offset heapbeg
        jb __B
        test [byte si+4],cm
        jnz __B
        or [byte si+4],cm
        test [byte si+4],1
        jnz __B
        mov dx,di
        mov di,si
        mov si,[di]
        rb0
        mov [di],dx
        jmp __A
__B:
        or di,di
        jz __ret
        test [byte di+4],cb
        jnz __C
        mov dx,[di]
        mov [di],si
        rb1
        mov si,[di+2]
        mov [di+2],dx
        jmp __A
__C:
        mov dx,[di+2]
        mov [di+2],si
        rb0
        mov si,di
        mov di,dx
        jmp __B
__ret:  ret
ENDP

PROC    mark
        call marksystem
        call markatoms
        call markassoc
        mov bp,stackptr
__loop:
        mov si,[bp]
        call marklist
        inc bp
        inc bp
        cmp bp,STACK_SIZE
        jb __loop
        jmp markoblist
ENDP

PROC    markassoc
        mov si,aptr
        jmp marklist
ENDP

PROC    markoblist
        mov cx,256
        mov dx,offset hashtable-2
__A:
        mov bx,dx
        mov si,dx
__B:
        mov bx,[bx+2]
        or bx,bx
        jz __l
        mov di,[bx]
        test [byte di+4],cm
        jz __B
        or [byte bx+4],cm
        mov [si+2],bx
        mov si,bx
        jmp __B
__l:
        mov [word si+2],0
        add dx,2
        loop __A
        ret
ENDP

PROC    markatoms
        mov bx,offset hashtable
        mov cx,256
__loop:
        mov si,[bx]
__A:    or si,si
        jz __ok
        push si
        mov si,[si]
        mov al,[si+4]
        cmp al,none*4+2
        jne __l1
        mov di,[si]
        cmp [word di+2],0
        je __nomark
__l1:
        cmp al,fix*4+2
        je __nomark
        call marklist
__nomark:
        pop si
        mov si,[si+2]
        jmp __A
__ok:
        add bx,2
        loop __loop
        ret
ENDP

PROC    marksystem
        mov bx,offset apv_list
__loop:
        mov si,[bx]
        call marklist
        inc bx
        inc bx
        cmp bx,offset end_apv_list
        jb __loop
        mov si,[nilval+2]
        jmp marklist
ENDP

PROC    freemem
        xor si,si
        xor dx,dx
        mov bx,heapend
        mov cx,cells
__loop:
        sub bx,5
        test [byte bx+4],cm
        jnz __marked
        mov [byte bx+4],0
        mov [bx+2],si
        mov si,bx
        inc dx
__marked:
        and [byte bx+4],not (cb+cm)
        loop __loop
        mov heapptr,si
        ret
ENDP

errtable:
                db 1,'Неверный символ : "%"$'
                db 2,'Неверные символы : ".%"$'
                db 3,'Список аргументов % слишком короток$$'
                db 4,'Мало списочной памяти - очистка$'
                db 5,'Атом % не связан со значением$$'
                db 6,'В списке нет LAMBDA : %$$'
                db 7,'Функция % не определена$$'
                db 9,'Метка % не найдена$$'
                db 10,'% не является числом$$'
                db 11,'Прерывание от клавиатуры$'
                db 14,'Выражение невозможно вычислить$'
                db 15,'Прерывание пользователя : %$'
                db 16,'Файл %.LSP не найден$'
                db 17,'За &REST нет параметра : %$$'
                db 18,'Не макровызов : %$'
                db 19,'% не список$$'
                db 21,'Непечатаемое выражение$'
                db 22,'Нужна ")" после точечной пары$'
                db 23,'Неверные символы : "(."$'
                db 24,'Слишком длинное имя атома$'
                db 25,'% не атом$$'
                db 26,'% не идентификатор$$'
                db 27,'Арифметическое переполнение$'
                db 28,'Мало стековой памяти - очистка$'
                db 29,'% отрицательная степень$$'
                db 31,'Неверное обращение к SELECTQ$'
enderrtable     db 'Неопределенная ошибка$'

aptr            dw 0

MACRO   at n1,n2
        db n1,0
        db subr*4+2
        dw offset n2
ENDM

MACRO   atf n1,n2
        db n1,0
        db _fsubr*4+2
        dw offset n2
ENDM

MACRO   atff n1,n2
        db n1,0
        db _fsubr*4+2+80h
        dw offset n2
ENDM

MACRO   ap n1
        db n1,0
        db apval*4+2+80h
ENDM

MACRO   af n1
        db n1,0
        db fix*4+2+80h
ENDM

MACRO   av n1
        db n1,0
        db none*4+2+80h
ENDM

                dw 1
subr_list:
                at 'eq',_eq
                at '=',_eq
                at 'car',car
                at 'first',car
                at 'cdr',cdr
                at 'rest',cdr
                at 'cadr',cadr
                at 'second',cadr
                at 'caar',caar
                at 'cddr',cddr
                at 'cdar',cdar
                at 'caddr',caddr
                at 'third',caddr
                at 'cadddr',cadddr
                at 'cadar',cadar
                at 'fourth',cadddr
                at 'null',null
                at 'not',null
                at 'cons',cons
                at 'atom',atom
                at 'rplaca',rplaca
                at 'rplacd',rplacd
                at 'eval',eval
                at 'print',print
                at 'prin1',_prin1
                at 'read',read
                atf 'list',list
                atf 'sexpr',sexpr
                atf 'sfexpr',sfexpr
                atf 'or',_or
                atf 'and',_and
                atf 'prog',prog
                atf 'cond',cond
                at 'return',return
                atf 'go',go
                atf 'setq',setq
                at 'set',set
                atf 'csetq',csetq
                atf 'plus',plus
                atf '+',plus
                atf 'times',times
                atf '*',times
                atf 'logor',logor
                atf 'logand',logand
                atf 'logxor',logxor
                atf 'max',max
                atf 'min',min
                atf 'sadd1',sadd1
                atf '1+',sadd1
                atf 'ssub1',ssub1
                atf '1-',ssub1
                at 'difference',diff
                at '-',diff
                atf 'function',function
                at 'zerop',zerop
                at '0?',zerop
                at 'onep',onep
                at 'minusp',minusp
                at 'numberp',numberp
                at 'minus',minus
                at 'quotient',quotient
                at '/',quotient
                at 'remainder',remainder
                at 'reclaim',recl
                at 'objects',objects
                at 'cset',cset
                at 'leftshift',leftshift
                at 'expt',expt
                at 'add1',add1
                at 'sub1',sub1
                at 'lessp',lessp
                at '<',lessp
                at 'greaterp',greaterp
                at '>',greaterp
                at 'greqp',greqp
                at '>=',greqp
                at 'gensym',gensym
                atf 'selectq',selectq
                at 'equal',equal
                at 'member',member
                at 'memb',memb
                at 'terpri',terpri
                at 'proplist',proplist
                at 'spropl',spropl
                atf 'progn',progn
                atf 'funcall',funcall
                at 'exit',quit
                at 'nth',nth
                at 'last',last
                at 'nconc',nconc
                at 'load',load
                at 'alist',alist
                at 'echo',_echo
                atf 'defun',defun
                atf 'deffun',deffun
                atf 'defmacro',defmacro
                atf 'prog1',prog1
                at 'macroexpand',macroexpand
                at 'cls',cls
                at 'car2',car2
                at 'cdr2',cdr2
                at 'random',random
                atf 'if',_if
                at 'append',append
                at 'установи',setblank
                at 'count',count
                at 'boundp',boundp
                at 'fboundp',fboundp
                at 'error',_error
                atf 'push',_push
                atf 'pop',_pop
                atf 'trace',trace
                atf 'untrace',untrace
                atf 'time',time
                at 'dos',dos
                at 'mode',mode
                at 'reverse',reverse
                atf 'loop',_loop
                atf 'stop',stop
                atf 'let',let
                atf 'bindlist',bindlist
                at 'assoc',_assoc
                at 'переменная-p',perem
                at 'значение',value
                at 'dreverse',dreverse
                at 'putpixel',putpixel
                at 'split',split
                at 'combine',combine
                at 'поменяй-имена',changenames

                ap 'nil'
                ap 't'
                av 'ffarg'
                av 'funarg'
                av 'lambda'
                av '&optional'
                av '&rest'
                av '&aux'
                av '?'
                av 'pprint'
                af '0'
                af '1'
                atff 'quote',car2

                av '('
                av ')'
                av '.'
                av ' '
                av "'"
                ap 'lpar'
                ap 'rpar'
                ap 'period'
                ap 'blank'
                ap 'apostrof'
end_list:

        org subr_list-2
apv_list:
nil             dw ?
t               dw ?
ffarg           dw ?
funarg          dw ?
lambda          dw ?
opt             dw ?
rest            dw ?
aux             dw ?
ask_sign        dw ?
_pprint         dw ?
zero            dw ?
one             dw ?
quote           dw ?
        num_of_syms=5
assign_list:
lpar            dw ?
rpar            dw ?
period          dw ?
blank           dw ?
apostrof        dw ?
                dw num_of_syms dup (?)
end_apv_list:

numprop         db ?
stackptr        dw ?
heapptr         dw ?
curreval        dw ?

readbuf         db 256 dup(?)
outbuf          db 254 dup(?)
hashtable       dw 256 dup(?)
pnbuf           db 256 dup(?)
conv_table      db 256 dup(?)
fname           db 80 dup(?)

heapbeg:        org 65534
ENDS    code

SEGMENT sseg stack
        db STACK_SIZE dup(?)
ENDS

        end main