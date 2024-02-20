; asmsyntax=nasm

global addf

%define a[ebp+8]
%define b[ebp+12]
%define x[ebp+16]

%define s1[ebp-4]	; sign bit for a
%define s2[ebp-8]	; sign bit for b
%define m1[ebp-12]	; fraction for a
%define m2[ebp-16]	; fraction for bi
%define s3[ebp-20]
%define d[ebp-24]
addf:

  push ebp
  mov ebp, esp
  sub esp, 24
 
  mov eax, a
  shr eax, 23	; shift exp to last byte => al = exp vals for a

  mov ecx, b
  shr ecx, 23	; shift exp to last byte => cl = exp vals for b
 

  mov edx, a
  and edx, 8388607
  mov m1, edx		; m1 contains fraction for a

  mov edx, b
  and edx, 8388607
  mov m2, edx		; m2 contains fraction for b

;***********************************************
;zero case

  cmp al, cl
  jne .conAl

  mov edx, m1
  cmp edx, dword m2
  jne .conAl

  mov edx, a
  mov s1, edx
  mov edx, b
  mov s2, edx

  shr dword s1, 31      ;s1 bit
  shr dword s2, 31      ;s2 bit

  mov edx, s1
  cmp edx, dword s2
  je .conAl
.ret0:
  xor edx, edx
  xor eax, eax
  jmp .end
;************************************************


;******************************************
.conAl:

;if the fraction and  0 do not add the j bit
  cmp dword m1, 0
  je .ch_E1
  jmp .addj1

.ch_E1:

  cmp al, 0
  je .j2
  jmp .addj1

.addj1:
  or m1, dword 8388608	;add 1 jbit

.j2:

  cmp dword m2, 0
  je .ch_E2
  jmp .addj2

.ch_E2:
  
  cmp cl, 0
  je .con
  jmp .addj2

.addj2:

  cmp dword m2, 0
  or m2, dword 8388608  ;add 2 jbit

.con:

;******************************************

  cmp al, cl		; al => e1,	cl => e2
  jg .while2		; if (e1 > e2)
  jl .while1		; if (e2 > e1)
  jmp .equal_exp
  
.while1:
  
  inc al		; e1 <- e1 + 1
  shr dword m1, 1	; f1 <- f1/2
  cmp cl, al		 
  jg .while1		; if (e2 > e1)
  je .equal_exp

.while2:

  inc cl		; e2 <- e2 + 1
  shr dword m2, 1	; f2 <- f2/2
  cmp al, cl
  jg .while2		; if (e1 > e2)
  je .equal_exp

.equal_exp:

  ; al = e1, cl = e2 (e1 = e2 = e3*), m1 = f1, m2 = f2

  mov edx, a
  mov s1, edx
  mov edx, b
  mov s2, edx

  shr dword s1, 31	;s1 bit
  shr dword s2, 31	;s2 bit

  test dword s1, 1	; check if 0(+) or 1(-)
  jne .then1

.if2:
  test dword s2, 1
  jne .then2
  jmp .if_done

.then1:
  neg dword m1
  jmp .if2

.then2:
  neg dword m2

.if_done:

  mov edx, m1
  add edx, m2	; f3 = f1 + f2
  
  cmp edx, 0	; edx = f3
  jge .else

  neg edx
  mov dword s3, 1	; s3 = 1 for (-) number

  jmp .done

.else:
  mov dword s3, 0	; s3 = 0 for (+) number

.done:

;************************************************************

  mov m1, edx
  ;normalize s3, m1 = f3 and al/cl = e3
  ; use cl as e3 to free eax for use

  cmp dword m1, 0
  je .combine

.while3:
  
  mov edx, m1

  and edx ,4278190080	;extract bit 31-24
  cmp edx, 0
  jle .while4
  
  shr dword m1, 1;
  inc cl;

  jmp .while3

.while4:  

  mov edx, m1
 
  test edx, 8388608
  jne .combine


  shl dword m1, 1
  dec cl
  jmp .while4

;*************************************************************

.combine:

  mov edx, s3	;s3 added
  shl edx, 8	; make space for 8bit e3

  mov dl, cl	; e3 added
  shl edx, 23	; make space for fraction => last 23 bits are 0

  ;eax and ecx now free to use

  and dword m1, 8388607	; extract 23 bit fraction from f3
  or edx, m1		; combine (s3, e3) and f3

.end:

  mov eax, x
  mov [eax], edx

  mov esp, ebp
  pop ebp

  ret 
