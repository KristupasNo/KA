.model small
.stack 100h
.386
.data
	dazniu_masyvas	DB 256 dup(0) ;dazniu masyvas 
	buferis	DB 255 	dup('$')	
	pagalba    		DB "Parametrai programai turi buti paduodami komandine eilute. Pvz.: antra duom.txt rez.txt $"
	nauja_eilute    DB 13, 10, '$'
	duomenys        DB 100 dup(0)
	rezultatai      DB 100 dup(0) 
	failas  		DW ?     ;reikalinga sukurti ax kopijai, darbui su failu 
	simboliai     	DB ?         ;skaitymui is failo
	klaida1 		DB "Klaida. Failo atidaryti nepavyko $"
	klaida2 		DB "Tuscias duomenu failas $"
	kopija1 		DB 0      
	kopija2 		DB 0
	kopija 			DB 0 	; ivairus kintamieji reikALingi darbui 
	vien 			DB 0
	d 				DB 0
	try 			DB 0 
	pab 			DW 0 	; patikrinti ar duomenu failas tuscias
	nr 				DB '$'
	rez				DB "rez.txt", 0			; rezultato failas
	kopija_bx 		DW 0
.code

failai proc	
	XOR CX, CX      ;nuliai
	MOV BX, 80h     ;saugomas eilutes ilgis
	MOV CL, ES:[BX]     

ieskok_pagalba: 
	INC BX       ;ieskome pagalbos prasymo
	CMP ES:[BX], '?/' ;pirmesnis i zemesni registra kitas i aukstesni, todel atvirksciai
	JE klaustukas
	LOOP ieskok_pagalba

	MOV BX, 0
	MOV CX, 0     
	MOV CL, ES:[80h] 
	MOV SI, 0     

eilute:    ;nera pagalbos prasymo, nuskaitome
	MOV AL, byte ptr ES:[82h+SI] ;nuo 82 nes 81 tarpas	
	MOV buferis[SI], AL 
	INC SI 
	CMP AL, 20h
	JE tarpas
	LOOP eilute 
	JMP tarpas2

tarpas: ;skaiciuoja tarpus
	INC BX
	LOOP eilute

tarpas2: ;patikrina
	XOR SI, SI
	MOV kopija_bx, BX
	CMP BX, 0
	JE Duom_txt
	CMP BX, 01h
	JNE klaustukas 
	XOR BX, BX
	JMP Duom_txt

klaustukas: ;isveda pagalbos zinute
	MOV DX, offset pagalba
	MOV AH, 09h 
	INT 21h 
	JMP Pabaiga

Duom_txt:
	MOV AL, buferis[SI]
	INC SI   
	CMP AL, 20h                ;jei bus ivestas tarpas, vadinasi pirmas duomenu parametras uzfiksuotas
	JE  nuliai1
	CMP AL, 0Dh
	JE nuliai2
	MOV duomenys[BX], AL      ;jei simbolis ne tarpas vadinami tai parametras
	INC BX
	JMP Duom_txt                ;jei tai nebuvo tarpas tesiu pavadinimo paieskas

nuliai1: 
	MOV BX, 0
	
Rez_txt:
	MOV AL, buferis[SI] 
	CMP AL, 0Dh
	JE nuliai2           
	MOV rezultatai[BX], AL     
	INC SI
	INC BX
	JNE Rez_txt               ;jei tai nebuvo tarpas tesiu pavadinimo paieskas
	
nuliai2:

	RET
failai endp	

dazniai proc
;atidaryti faila
	MOV  AH, 3dh          ;atidaryti faila
	MOV  AL, 0            ;atidaryti kaip read only
	MOV  DX, offset duomenys
	INT  21h 
	JB fail
  
	MOV  failas, AX ;reikalinga darbui su failu
	JMP reading
  
fail:
	LEA DX, klaida1 ;isveda klaidos pranesima
	MOV AH,09h
	INT 21h
  
	jmp Pabaiga
;skaiciuoti simbolius
reading:  
;skaityti simboli is failo
	MOV  AH, 3fh          ;skaityti is failo
	MOV  BX, failas
	MOV  CX, 1            ;kiek baitu skaityti
	MOV  DX, offset simboliai ;kur laikyti nuskaitytus baitus
	INT  21h 
  

;tikrinti ar nesibaige failas
	CMP  AX, 0
	JE   baigti_skaityma      ;jei 0, baigti 
	INC  pab

;jei randa padidina
	MOV  SI, offset dazniu_masyvas
	MOV  AL, simboliai     ;naudojame simbolio ascii kaip vieta, kur padidinti
	MOV  AH, 0            ;isvalyti AH, kad naudoti ax
	ADD  SI, AX           ;SI nurodo i pozicija 
	CMP [SI], 255
	JE reading
	INC  [SI]  			;padidina

	JMP  reading          ;kartoja

baigti_skaityma:           
;failo uzdarymas
	MOV  AH, 3eh          ;uzdaryti faila
	MOV  BX, failas
	INT  21h
  
	CMP pab, 0 ;patikrinti ar duomenu failas tuscias
	JNE gALas2
  
	LEA DX, klaida2 ;isveda klaidos praneSIma
	MOV AH, 09h
	INT 21h
  
	JMP Pabaiga
  
gALas2:

	ret
dazniai endp

isvedimas proc
	LEA SI, dazniu_masyvas ;priskiriame dazniu masyvo adresa si
	LEA BX, nr
	
	CMP kopija_bx, 0
	JE rezult
	MOV AH,3CH ; sukurti faila
	MOV CX,0
	LEA DX, rezultatai
	INT 21h
	JB  openfailed       ; jei error, iseik
	JMP skip
	
rezult:
	MOV AH,3CH ; sukurti faila
	MOV CX,0
	LEA DX, rez
	INT 21h
	JB  openfailed       ; jei error, iseik
	
skip:	
  
	MOV failas, AX
  
	JMP vesk
  
openfailed:
	LEA DX, klaida1
	MOV AH,09h
	INT 21h
	
    MOV AH, 4Ch
    MOV AL, 0
    INT 21h
  
vesk:

	MOV AX, 0   ;nuliname ax kad butu galima naudoti toliau
    
    MOV AL,[SI] ;SI ascii desimtainiai, o AL rodo kiek ju yra
	
    CMP AL, 0 ;jei nulis sok i pabaiga0
    JE pabaiga0
	
    CMP AL, 10 ;jei <10 sok i vienas
    JB vienas
	
    CMP AL, 100   ;jei >9, bet <100 sok i du
    JB du
	;skaiciuoja jeigu >100
    MOV dl,10 
    DIV dl
  
	ADD AH, 48  ;pridedame 48/0 simboli kad registre atsidurtu ascii reiksme
    MOV kopija1, AH ;paskutinis trizenklio skaiciaus skaitmuo i kopija1
    MOV AH, 0
	
    DIV dl
	ADD AH, 48
    MOV kopija2, AH  ;priespaskutinis trizenklio skaiciaus skaitmuo i kopija2
	
	ADD AL, 48
    MOV kopija,AL ;pirmas trizenklio skaiciaus skaitmuo i kopija
	
   ; ADD dl,48
	INC try
    JMP pabaiga1	
	
	
trys2: ;idedame simbolio kartotiniu skaiciu isvedimui
	MOV AL, kopija 
	MOV [BX], AL
	INC CX
	INC BX
	MOV AL, kopija2
	MOV [BX], AL
	INC CX 
	INC BX
	MOV AL, kopija1
	MOV [BX], AL
	INC CX
	DEC try
	JMP tes2
	
du: ;isskaidom dvizenkli sk po viena, padarome simboliu dazniu skaiciaus kopijas 
    MOV DL, 10
    DIV DL
    ADD AL, 48
	ADD AH, 48
    MOV kopija1,AH
    MOV kopija2,AL
	INC d
    JMP pabaiga1
	
du2: ;idedame simbolio kartotiniu skaiciu isvedimui
	MOV AL, kopija2
	MOV [BX], AL
	INC CX
	INC BX
	MOV AL, kopija1
	MOV [BX], AL
	INC CX
	DEC d
	JMP tes2
	 
vienas:
    ADD AL, '0' ; kiek kartu kartojaSI 3
	MOV kopija, AL ;issisaugom, nes isvesti reiks veliau
	INC vien
    JMP pabaiga1
	
vienas2:
	MOV AL, kopija ;idedame simbolio kartotiniu skaiciu i eilute isvedimui
	MOV [BX], AL
    INC CX
	DEC vien
	JMP tes2
 
pabaiga0: ;kuomet char=0 duomenu faile
	CMP SI,255 ;tikrina ar nepriejome ascii lenteles galo
	JE gALas
	INC SI ;jei ne, tesk
	JMP vesk 
	
pabaiga1:      ;kuomet !=0
	CMP SI, 0Fh ;jeigu SI sudarytas is dvieju skaitmens
	JA du_pirm
	MOV AX, SI 
	ADD AH, 48
	CMP AL, 9
	JA raid3 ;jeigu sudarytas is raides
	ADD AL, 48
		
tol3: ;galejau palikti apacioje, isveda 0 ir kazkoki skaiciu/raide
	MOV [BX], AH
	INC CX 
	INC BX
	MOV [BX], AL
	INC BX
	INC CX  
tes:
	MOV [BX], 32 ;space
	INC BX
	INC CX
	CMP SI, 20h
	JB sok ; persoka simbolio isvedima, jei ascii jis maziau uz 20h, nes neimanoma isvesti
	MOV [BX], 28h ;skliaustai
	INC BX
	INC CX     
	MOV [BX], SI ;skaicius
	INC BX
	INC CX
	MOV [BX], 29h ;skliaustai
		
sokg:
	INC CX
	INC BX
	MOV [BX], 58 ; :
	INC CX
	INC BX
	MOV [BX], 32 ; space
	INC CX 
	INC BX
	CMP vien, 1 ; tikrina ar simbolis vienazenklis
    JE vienas2
    CMP d,1 ; tikrina ar dvizenklis
    JE du2
    CMP try, 1 ; tikrina ar trizenklis
    JE trys2
  
tes2: ;pats gALas, new line i masyva, ji isveda ir soka i pradzia
	INC BX
	MOV AL, 0AH
	MOV [BX], AL
	INC CX
	MOV AH,40h
	MOV BX, failas
	MOV DX, offset nr
	INT 21h
	LEA BX, nr
	MOV CX, 0
	CMP SI, 255
	JE gALas
	INC SI
	JMP VESK
			
sok: ;jei maziau uz 20h, vietoje simboliu rasomi tarpai
	MOV [BX], 20h 
	INC BX
	INC CX
	MOV [BX], 20h 
	INC BX
	INC CX 
	MOV [BX], 20h
	JMP sokg	
	
	;pradzioje reikia isvesti ascii numeri 
du_pirm:
	MOV DL,10h 
	MOV AX, SI
	DIV DL
	CMP AL, 9 ;jeigu ascii pirmo numerio sesioliktainis skaicius yra raide 
	JA raid
	ADD AL, 48 ;jei skaicius pridedame 48
tol:
	MOV [BX], AL ;isvedimui idedame pirmaji dvizenklio ascii nr skaitmeni
	INC CX
	INC BX
        
	CMP AH, 9
	JA raid2  ;jeigu ascii antro numerio sesioliktainis skaicius yra raide    
	ADD AH, 48; jeigu skaicius pridedame 48
tol2:
	MOV [BX], AH ;isvedimui idedame antraji dvizenklio ascii nr skaitmeni
	INC CX  ;didiname kad zinotume kiek simboliu isvesti
	INC BX ;didiname kad pereiti prie kito baito masyve
	JMP tes
  
raid3: ;jei si vienas simbolis ir raide
	ADD AL,55 ;prie raides pridedame 55
	JMP tol3
  
raid:
	ADD AL, 55;prie raides pridedame 55
	JMP tol 
  
raid2:
	ADD AH, 55;prie raides pridedame 55
	JMP tol2
  
gALas:  

	ret
isvedimas endp 

start:

	MOV  AX, @data ;reikALinga kad veiktu programa
	MOV DS, AX 
	 
	call failai
	call dazniai            ;uzpildo dazniu_masyvas su SImboliu dazniais. 
	call isvedimas			;isvedimas

Pabaiga:
	MOV  AX, 4c00h
	INT  21h
  
end start 
  
  
  
  
  
  
  
  
  