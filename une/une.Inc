include windows.inc
include user32.inc
include kernel32.inc
include shell32.inc
include comctl32.inc
include comdlg32.inc

includelib user32.lib
includelib kernel32.lib
includelib shell32.lib
includelib comctl32.lib
includelib comdlg32.lib

dlgProc				PROTO :DWORD,:DWORD,:DWORD,:DWORD
procPpal			PROTO :DWORD,:DWORD,:DWORD,:DWORD
generaNombre		PROTO :DWORD,:DWORD,:DWORD
uneDatos	 		PROTO :DWORD

.const
rcBtUnir		equ 1001
rcProgreso		equ 1002
txtNumPartes	equ	1006
.data

mensaje MACRO texto:REQ
		local @texto
	.data
		@texto db texto,0
	.code
		invoke MessageBox, hDialog, addr @texto, addr appName, MB_OK
endm

szNombreFichero						db						256 dup ('#')
;szNombreFichero						  db 129,189,139,212,129,33,86,120,194,109,37,119,167,81,139,92
;;  db 121,83,45,165,195,172,192,233,109,136,41,245,56,70,20,91
;;  db 210,138,168,254,91,202,36,177,29,235,75,16,170,126,144,162
;;  db 214,255,157,15,162,169,180,79,151,117,223,8,34,181,89,224
;;  db 64,239,6,18,51,173,63,39,28,243,146,193,208,254,235,184
;;  db 132,53,191,74,63,45,211,181,138,30,28,188,222,160,28,204
;;  db 64,135,158,104,158,154,37,30,77,225,228,66,129,16,252,62
;;  db 208,151,58,81,195,16,111,20,169,138,242,21,81,246,64,84
;;  db 68,166,204,197,127,135,132,27,252,30,162,129,208,201,215,128
;;  db 165,18,72,49,11,19,170,167,82,188,103,134,143,235,162,39
;;  db 137,195,51,34,230,161,186,246,94,233,182,245,211,59,135,170
;;  db 227,205,13,35,128,225,69,248,69,94,141,80,1,118,138,154
;;  db 218,211,25,116,98,127,57,238,227,223,28,33,139,0,224,66
;;  db 195,97,151,47,167,79,161,33,44,88,107,64,128,223,243,159
;;  db 137,194,37,221,0,127,58,107,7,195,194,1,145,16,0,0
;;  db 109,176,37,63,2,200,137,2,5,72,135,244,111,16,65,111
nLongNombreFichero					db						'$'
nTamUltParte						dd						'@@@@'
nPartes								dd						'$$$$'

nMiTamanio							dd						6144

szExtensionPartes					db						'.k000',0
szExtensionUltimo					db						'.exe',0
DlgName								db	'une',0
szIcono								db	'icono',0
ClassName			db 'DLGCLASS',0
appName				db 'kiru',0




.data?

hInstance			dd ?
CommandLine			dd ?
hWnd				dd ?
hHeap				dd ?
hFileD				dd ?
hFileP				dd ?
hProgreso			dd ?
hDialog				dd ?


nNumExt				dd ?
bUltimo				db ?
bErrorUnir			db ?

szRutaD				db 65000 dup(?)
szAux				db	MAX_PATH dup (?)
szExtensionAux		db	6 dup (?)

nBytesLeidos							dd						?
lpSacoDatos								dd						?
nBytesEscritos							dd						?
nTamFicheroLo							dd						?
