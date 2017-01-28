include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc
include masm32.inc
include gdi32.inc

includelib gdi32.lib
includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib
includelib masm32.lib

WinMain					PROTO :DWORD,:DWORD,:DWORD,:DWORD
WndProc					PROTO :DWORD,:DWORD,:DWORD,:DWORD
abrirFichero			PROTO
abreOrigen				PROTO :DWORD, :DWORD
rellenaTexto			PROTO
insertaSeparador		proto :DWORD, :DWORD,:DWORD
editProc				PROTO :DWORD,:DWORD,:DWORD,:DWORD
actualizaPartes			PROTO
actualizaTamanio		PROTO
actualizaBarraTamanio	PROTO :DWORD
actualizaInfo			proto
actualizaEtiquetas		proto
acercaScroll			PROTO :DWORD,:DWORD,:DWORD,:DWORD
calculaPartes			PROTO :DWORD,:DWORD
CenterWindow			PROTO :DWORD, :DWORD
RandomNumGen			PROTO :DWORD, :DWORD
compruebaDatos			proto
guardarFichero			proto
generaNombre			proto :DWORD, :DWORD
guardaDatos				proto :DWORD, :DWORD
division				proto :DWORD, :DWORD

.const

btFicheroOrigen		equ	1003
btFicheroDestino	equ	1004
txtFicheroOrigen	equ	1001
txtFicheroDestino	equ	1002
chkExe				equ 1007
txtTamOrigen0		equ	1010
txtTamOrigen		equ	1011
txtTamOrigen2		equ 1012
txtNumPartes		equ	1013
txtTamPartes		equ	1014
chkDisk				equ 1008
btCortar			equ	1006
barraP				equ	1019
btInfo				equ	1020
barraTamanio		equ	1005
porcentaje			equ	1021
;txtNumTotal			equ	1026
;txtFicheroBat		equ	1033
;txtTamPrimeras		equ	1029
txtTamUltima		equ	1030
;txtNumUltima		equ	1034
IDC_STC23			equ	1025
IDC_STC8			equ	1027
IDC_STC9			equ	1028
IDC_STC14			equ	1031
IDC_STC15			equ	1032
txtTamPrimerasKB	equ	1022
txtTamOrigenKB		equ	1035
txtPos				equ	2001
;btDetalles			equ	1024

nTamDisquete		equ	1457664
WM_FIN				equ WM_USER+100
nFicheroJoin		equ 6144
nTamBufferLectura	equ 1024*1024*16

.data

mensaje MACRO texto:REQ
		local @texto
	.data
		@texto db texto,0
	.code
		invoke MessageBox, hDialog, addr @texto, addr appName, MB_OK
endm

RGB macro red,green,blue
	xor eax,eax
	mov ah,blue
	shl eax,8
	mov ah,green
	mov al,red
endm

appName				db	'kiru',0
ClassName			db 'DLGCLASS',0
DlgName				db 'dlgKiru',0
szIcono				db	'icono',0
szFiltro			db	"todos los ficheros (*.*)",0,"*.*",0,0
szAcerca			db	'dlgAcerca',0
szDialogGuardar		db	'guardar como...',0
;;szTxtAcerca1		db	'kiru',0
;;szTxtAcerca2		db	'Kiru',0
;;szTxtAcerca3		db	'KIru',0
;;szTxtAcerca4		db	'KIRu',0
;;szTxtAcerca5		db	'KIRU',0
szTxtAcercade		db	'kiru 1.0.1',13,10,'alvaro martín 2004'
					db	 13,10,'escrito en ensamblador para win32',13,10
					db	' ',13,10,13,10
					db	' ',13,10,' ',13,10,0

szTxtAcercade2		db  'esta no es una versión definiva',13,10
					db  'por lo que es muy probable que',13,10
					db  'existan muchos errores',13,10
					db	'envíalos a alvaro@solomartin.com',13,10
					db	'gracias',0

;szTxtAcercade2		db  '_    _            ',13,10
;					db  '| | _(_)_ __ _   _ ',13,10
;					db  '| |/ / | �__| | | |',13,10
;					db	'|   <| | |  | |_| |',13,10
;					db	'|_|\_\_|_|   \__,_|',0

szCortar			db	'cortar',0
szCortando			db	'cortando',0

nCien				dd	100
ofn					OPENFILENAME	<>
fontName			db	'arial',0
fontNameAsc			db	'arial',0
szBytes				db	' bytes',0
szKB				db	' KB',0
szExtensionPartes	db	'.k000',0
szExtensionUltimo	db	'.exe',0
szExtensionBat		db	'.bat',0
szExtensionAst		db	'.k* ',0
szTextoBat1			db	'@echo off',13,10,'copy /b ',0
szCancelar			db	'cancelar',0

pixel struct
	x		dd	?
	y		dd	?
	color	dd	?
pixel ends

pixels	pixel	50 dup (<>)
.data?


hInstance			dd	?
hWnd				dd	?
hDialog				dd	?
hChkDisk			dd	?
hChkExe				dd	?
hFileO				dd	?
hFileD				dd	?
hTxtTamOrigen0		dd	?
hTxtTamOrigen		dd	?
hTxtTamOrigen2		dd	?
hBarraTamanio		dd	?
hNumPartes			dd	?
hTamPartes			dd	?
hProgreso			dd	?
hCortar				dd	?
hFileBat			dd	?

;handles acercaDlg
hOtro				dd	?
hDC					dd	?
hBrush				dd	?
hMemDC				dd	?
hTimer				dd	?
hFont				dd	?
hBitmap				dd	?

;hTxtNumUltima		dd	?
hTxtTamUltima		dd	?
;hTxtTamPrimeras		dd	?
hTxtFicheroOrigen	dd	?
;hTxtNumTotal		dd	?

hStatic23			dd	?
hStatic8			dd	?
hStatic9			dd	?
hStatic14			dd	?
hStatic15			dd	?

nAux				dd	?
nResto				dd	?
nCociente			dd	?
nOldEditProc		dd	?
nTamPartes			dd	?
nNumPartes			dd	?
nTamFicheroOLo		dd	?
nTamFicheroOLo100	dd	?
nTamFicheroOHi		dd	?
nPuntos				dd	?

idThread			dd	?

nNumExt				dd	?
lpFicheroAux		dd	?
;bytes
bResultado			db	?
bUltimo				db	?
szExtensionAux		db	5 dup(?)
nDigitos			db	2 dup (?)
nFicheroP			db	?
bVibra				dd  ?
nContador			db	?
;buffers
szOFNNombreFichero	db	MAX_PATH dup (?)
szTamFicheroC		db	12 dup(?)
szBufferAux			db	MAX_PATH dup(?)
szRutaDestino		db	MAX_PATH dup(?)
szCadenaInfo		db	100 dup(?)
nLen				dd	?
separador			dd	?
rect				RECT			<?>
tamTexto			POINT			<?>

nPosX				dd	?
nPosY				dd	?
nPosOri				dd	?

nAnchoR				dd	?
nAltoR				dd	?

nTamPrimeras		dd	?
nTamUltima			dd	?
nValorCritico		dd	?

nX					dd	?
nY					dd	?

RandSeed			dd	?
hOld				dd	?
nColor				dd	?

nChkExe				dd	?
nChkDisk			dd	?

lpBufferDatos		dd	?
nBytesLeidos		dd	?
nBytesEscritos		dd	?
hHeap				dd	?
hFileP				dd	?

nCocienteEntero		dd	?
nCocienteFrac		dd	?

;cadenas
szFicheroAux		db	MAX_PATH dup (?)
szFicheroOrigen		db	MAX_PATH dup (?)
szFicheroDestino	db	MAX_PATH dup (?)
