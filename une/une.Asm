.386
.model flat,stdcall
option casemap:none

include une.inc

.code

principioPrograma:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke GetCommandLine
	invoke InitCommonControls
	invoke procPpal,hInstance,NULL,CommandLine,SW_SHOWDEFAULT
	invoke ExitProcess,eax

procPpal proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,SIZEOF WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,OFFSET dlgProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,0
	mov		wc.lpszClassName,OFFSET ClassName
	invoke LoadIcon,hInst,addr szIcono
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,addr DlgName,NULL,addr dlgProc,NULL
	mov hDialog,eax
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd
	
	push offset szRutaD
	push MAX_PATH
	call GetCurrentDirectory	
	
	
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke TranslateMessage,addr msg
		invoke DispatchMessage,addr msg
	.endw
	mov		eax,msg.wParam
	ret

procPpal endp

dlgProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	.if uMsg==WM_COMMAND
		mov eax,wParam
		mov edx,eax
		shr edx,16
		.if dx==BN_CLICKED
			.if ax==rcBtUnir
				call une
			.endif
		.endif
	.elseif uMsg==WM_INITDIALOG
		invoke SetDlgItemInt,hWin,txtNumPartes,nPartes,0
	.elseif uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

dlgProc endp

une proc
	
	invoke GetProcessHeap
	mov hHeap,eax
	
	mov nNumExt,0
	mov bUltimo,0
	mov bErrorUnir,0
	
	invoke CreateFile,addr szNombreFichero,GENERIC_WRITE,0,0,CREATE_ALWAYS,0,0
	mov hFileD,eax
	
	invoke GetDlgItem,hDialog,rcProgreso
	mov hProgreso,eax
	
	xor eax,eax
	mov eax,nPartes
	shl eax,16
	invoke SendMessage,hProgreso,PBM_SETRANGE,0,eax
	
	mov ecx,nPartes
	dec ecx
bucleUnir:
	push ecx
;	xor eax,eax
;	mov al,nLongNombreFichero
	invoke generaNombre,addr szNombreFichero,nNumExt,nNumExt
	
	invoke uneDatos,addr szAux
	;si hay algún error al unir termino el proceso	
	.if bErrorUnir==1
		jmp finUne
	.endif

	invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
	
	inc nNumExt
	pop ecx
	loop bucleUnir
	;ahora falta volcar los datos que contiene el une.exe
	mov bUltimo,1
;	xor eax,eax
;	mov al,nLongNombreFichero
	invoke generaNombre,addr szNombreFichero,nNumExt,nNumExt

	invoke CreateFile, addr szAux,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,0,0
	
	.if eax==-1
		mensaje 'error al abrir una de las partes'
		jmp finUne
	.endif

	mov hFileP,eax
	
	invoke SetFilePointer,hFileP,nMiTamanio,0,0

	invoke HeapAlloc,hHeap,0,nTamUltParte
	mov lpSacoDatos,eax

	invoke ReadFile,hFileP,lpSacoDatos,nTamUltParte,addr nBytesLeidos,0

	invoke WriteFile,hFileD,lpSacoDatos,nTamUltParte,addr nBytesEscritos,0
	
	invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0

	invoke CloseHandle,hFileD
	invoke CloseHandle,hFileP

	mensaje 'proceso terminado con éxito'
	
	invoke HeapFree,hHeap,0,lpSacoDatos
;tendría que cerrar el heap y los ficheros si ocurre algún error
finUne:
	invoke SendMessage,hProgreso,PBM_SETPOS,0,0
	invoke PostQuitMessage,0
	ret

une endp

uneDatos proc lpParte:dword

	invoke CreateFile,lpParte,GENERIC_READ,FILE_SHARE_READ,0,OPEN_EXISTING,0,0
	
	.if eax==-1
		mensaje 'error al abrir una de las partes'
		mov bErrorUnir,1		
		jmp finUnir
	.endif

	mov hFileP,eax
	
;////////obtengo el tamaño del fichero de la parte	
	;aquí va el offset de la hi double word del fichero, pero no
	;lo voy a usar (limitando el tamaño a 2^32 bytes)
	invoke GetFileSize,hFileP,0
	mov nTamFicheroLo,eax	
	
;////////asigno memoria para leer cada una de las partes
	invoke HeapAlloc,hHeap,0,nTamFicheroLo
	mov lpSacoDatos,eax
;////////leo los datos del fichero	
	invoke ReadFile,hFileP,lpSacoDatos,nTamFicheroLo,addr nBytesLeidos,0
;////////y los vuelco en el fichero destino
	invoke WriteFile,hFileD,lpSacoDatos,nTamFicheroLo,addr nBytesEscritos,0
	
	invoke CloseHandle,hFileP

	invoke HeapFree,hHeap,0,lpSacoDatos

finUnir:
	ret		
uneDatos endp

generaNombre proc lpRuta:DWORD,nLongF:DWORD,nCaida:DWORD
	push eax
	push ebx
	push edx
	push esi
	push edi
	;convierto a ascii el número de extensión para añadirlo a la extensión del fichero
	invoke lstrcpy,addr szAux,lpRuta
	invoke lstrcpy,addr szExtensionAux,addr szExtensionPartes
	mov eax,nCaida
	;ahora nCaida es una dword por lo que no hay que actualizar al
	;shr eax,16
	mov esi,4 ;extensión partes es '.0000'
gN0:
	mov ebx,10
	xor edx,edx
	div ebx
	add dl,30h
	mov byte ptr szExtensionAux[esi],dl
	dec esi
	or ax,ax
	jz finGN
	jmp gN0
finGN:
	;la extensión se añade al final del nombre del fichero
	invoke lstrcat,addr szAux,addr szExtensionAux
	;si se está procesando el último fichero se le añade la extensión .exe
	.if bUltimo==1
		invoke lstrcat,eax,addr szExtensionUltimo
	.endif

	pop edi
	pop esi
	pop edx
	pop ebx
	pop eax
	
	ret
generaNombre endp

end principioPrograma
