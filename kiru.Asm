;alvaro martín abril 2003
.386
.model flat,stdcall
option casemap:none

include kiru.inc
include une.inc

.code

start:

	invoke GetModuleHandle,NULL
	mov    hInstance,eax
	invoke InitCommonControls
;	invoke division,33,4
	invoke WinMain,hInstance,NULL,0,SW_SHOWDEFAULT
	invoke ExitProcess,eax

WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
	LOCAL	wc:WNDCLASSEX
	LOCAL	msg:MSG

	mov		wc.cbSize,SIZEOF WNDCLASSEX
	mov		wc.style,CS_HREDRAW or CS_VREDRAW
	mov		wc.lpfnWndProc,OFFSET WndProc
	mov		wc.cbClsExtra,NULL
	mov		wc.cbWndExtra,DLGWINDOWEXTRA
	push	hInst
	pop		wc.hInstance
	mov		wc.hbrBackground,COLOR_BTNFACE+1
	mov		wc.lpszMenuName,0
	mov		wc.lpszClassName,OFFSET ClassName
	invoke LoadIcon,hInst,offset szIcono
	mov		wc.hIcon,eax
	mov		wc.hIconSm,eax
	invoke LoadCursor,NULL,IDC_ARROW
	mov		wc.hCursor,eax
	invoke RegisterClassEx,addr wc
	invoke CreateDialogParam,hInstance,addr DlgName,NULL,addr WndProc,NULL
	mov hWnd,eax
	invoke ShowWindow,hWnd,SW_SHOWNORMAL
	invoke UpdateWindow,hWnd

;////por defecto estará marcada la casilla de generar ejecutable
	invoke GetDlgItem,hWnd,chkExe
	mov hChkExe,eax
	invoke SendMessage,hChkExe,BM_CLICK,NULL,NULL

;////obtengo los handles a las etiquetas del tamaño del fichero origen
	invoke GetDlgItem,hWnd,txtTamOrigen0
	mov hTxtTamOrigen0,eax
	invoke GetDlgItem,hWnd,txtTamOrigen
	mov hTxtTamOrigen,eax
	invoke GetDlgItem,hWnd,txtTamOrigen2
	mov hTxtTamOrigen2,eax

;////handles de las demás ventanas
	invoke GetDlgItem,hWnd,chkExe
	mov hChkExe,eax
	invoke GetDlgItem,hWnd,chkDisk
	mov hChkDisk,eax
	invoke GetDlgItem,hWnd,barraTamanio
	mov hBarraTamanio,eax
	invoke SendDlgItemMessage,hWnd,btInfo,BM_SETIMAGE,IMAGE_ICON,wc.hIcon

;////hago subclassing de las cajas de texto para que sólo admitan números
;////y gestionar los cambios de tamaño y número de partes
	invoke GetDlgItem,hDialog,txtNumPartes
	mov hNumPartes,eax
	invoke GetDlgItem,hDialog,txtTamPartes
	mov hTamPartes,eax
	invoke SetWindowLong,hNumPartes,GWL_WNDPROC,addr editProc
	invoke SetWindowLong,hTamPartes,GWL_WNDPROC,addr editProc
	mov nOldEditProc,eax

;	invoke GetDlgItem,hDialog,txtNumTotal
;	mov hTxtNumTotal,eax
;	invoke GetDlgItem,hDialog,txtFicheroBat
;	mov hTxtFicheroBat,eax
;;	invoke GetDlgItem,hDialog,txtTamPrimeras
;;	mov hTxtTamPrimeras,eax
	invoke GetDlgItem,hDialog,txtTamUltima
	mov hTxtTamUltima,eax
;	invoke GetDlgItem,hDialog,txtNumUltima
;	mov hTxtNumUltima,eax

	invoke GetDlgItem,hDialog,IDC_STC23
	mov hStatic23,eax
	invoke GetDlgItem,hDialog,IDC_STC8
	mov hStatic8,eax
	invoke GetDlgItem,hDialog,IDC_STC9
	mov hStatic9,eax
	invoke GetDlgItem,hDialog,IDC_STC14
	mov hStatic14,eax
	invoke GetDlgItem,hDialog,IDC_STC15
	mov hStatic15,eax
	invoke GetDlgItem,hDialog,txtFicheroOrigen
	mov hTxtFicheroOrigen,eax
	invoke GetDlgItem,hDialog,barraP
	mov hProgreso,eax
	invoke GetDlgItem,hDialog,btCortar
	mov hCortar,eax

;////bucle de mensajes
	.while TRUE
		invoke GetMessage,addr msg,NULL,0,0
	  .BREAK .if !eax
		invoke IsDialogMessage, hWnd, ADDR msg
		.if eax==FALSE
			invoke TranslateMessage,addr msg
			invoke DispatchMessage,addr msg
		.endif
	.endw
	mov		eax,msg.wParam
	ret

WinMain endp

WndProc proc hWin:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM

	.if uMsg==WM_INITDIALOG
		push	hWin
		pop		hDialog
		mov eax,00640000h
		invoke SendDlgItemMessage, hDialog,barraTamanio, TBM_SETRANGE, TRUE, eax
		invoke SendDlgItemMessage,hDialog,barraTamanio,TBM_SETTICFREQ,50,NULL
		invoke SetDlgItemInt,hDialog,porcentaje,0,0
		;////inicializo la estructura ofn
		mov ofn.lStructSize,SIZEOF ofn
		push hDialog
		pop ofn.hWndOwner
		push hInstance
		pop ofn.hInstance
		mov ofn.lpstrFilter,offset szFiltro
		mov ofn.lpstrFile,offset szOFNNombreFichero
		mov ofn.nMaxFile,MAX_PATH
		mov nChkExe,TRUE
		invoke GetLocaleInfo,LOCALE_USER_DEFAULT, LOCALE_STHOUSAND,addr separador,4

	.elseif uMsg==WM_COMMAND
		mov eax,wParam
		mov edx,wParam
		shr edx,16
		.if dx==BN_CLICKED
			.if ax==btCortar
					;////primero compruebo que los datos introducidos son correctos
					;////path de los ficheros, tamaño y número de partes
					invoke compruebaDatos
					.if eax==0
						;////los paths son correctos por lo que empiezo a cortar
						;////ejecuto el thread encargado de cortar
						mov eax,offset cortar
						invoke CreateThread,NULL,NULL,eax,NULL,NORMAL_PRIORITY_CLASS,addr idThread
						invoke CloseHandle,eax
					.elseif eax==1
						mensaje 'error al abrir el fichero origen, por favor comprueba los datos'
					.elseif eax==3
						mensaje 'el tamaño del fichero debe ser mayor que 0 bytes'
					.elseif eax==4
						mensaje 'el número de partes debe estar entre 2 y 999'
					.endif
			.elseif ax==btFicheroOrigen
				invoke abrirFichero
			.elseif ax==btFicheroDestino
				invoke guardarFichero
			.elseif ax==btInfo
				invoke DialogBoxParam,hInstance, addr szAcerca,hWin,OFFSET acercaScroll,NULL
			.elseif ax==chkDisk
				invoke IsDlgButtonChecked, hWin, chkDisk
				mov nChkDisk,eax
				.if eax==TRUE
					invoke SetDlgItemInt,hDialog,txtTamPartes,nTamDisquete,0
					mov bResultado,1
					invoke actualizaPartes
				.endif
			.elseif ax==chkExe
				invoke IsDlgButtonChecked,hDialog,chkExe
				mov nChkExe,eax
				mov bResultado,0
				invoke actualizaPartes
			.endif
		.endif;////del if dx
	.elseif uMsg==WM_FIN
		;////comprobar si se ha pulsado cancel
		;////para borrar los ficheros correspondientes
    .elseif uMsg==WM_DROPFILES
    	invoke SetForegroundWindow,hDialog
        invoke DragQueryFile,wParam,0,ADDR szOFNNombreFichero,MAX_PATH
		invoke abreOrigen,addr szOFNNombreFichero,1
		.if bResultado==1
			mov eax,nTamFicheroOLo
			invoke rellenaTexto
			invoke IsDlgButtonChecked, hDialog, chkDisk
			.if eax==TRUE
				.if nTamFicheroOLo>nTamDisquete
					invoke SetDlgItemInt,hDialog,txtTamPartes,nTamDisquete,0
					invoke actualizaPartes
				.else
					invoke EnableWindow,hChkDisk,FALSE
				.endif
			.endif
		.endif
	.elseif uMsg==WM_HSCROLL
		mov eax,lParam
		.if eax==hBarraTamanio
			invoke SendMessage, hBarraTamanio, TBM_GETPOS,NULL,NULL
			push eax
			invoke SetDlgItemInt,hDialog,porcentaje,eax,0
			pop eax
			;////si el tamaño del fichero origen es mayor de cien bytes multiplico el valor
			;////de la posición de la barra por tamañoDelFicheroDivididoEntreCien
			.if nTamFicheroOLo100!=0
				mul nTamFicheroOLo100
			.else
				;////si el tamaño es menor multiplico el tamaño por el valor de la barra y lo divido entre cien
				mul nTamFicheroOLo
				xor edx,edx
				div nCien
				mov nAux,edx
			.endif
			;////en ambos casos después de este if en nAux está el resto de la división
			;////que corresponderá al tamaño de la última parte

			;////en nTamFicheroOLo100 tengo el tamaño del fichero original dividido entre 100 por lo que
			;////al multiplicarlo por el valor de la trackbar obtengo el porcentaje.
			;////si el % es <> 0 le a�ado el resto obtenido al dividir el tamaño del fichero entre 100
			;////para que en el máximo valor del trackbar coincidan los valores de la casilla y la
			;////etiqueta de tamaños.
			.if eax!=0 && nTamFicheroOLo100!=0
				add eax,nAux
			.endif
			invoke SetDlgItemInt,hDialog,txtTamPartes,eax,0
			;////pongo bResultado a cero para evitar que actualizaPartes llame a actualizaBarraTamanio ya que
			;////la barra ha sido actulizada ya aqu�
			mov bResultado,0
			invoke actualizaPartes
		.endif
	.elseif uMsg==WM_CLOSE
		invoke DestroyWindow,hWin
	.elseif uMsg==WM_DESTROY
		invoke PostQuitMessage,NULL
	.else
		invoke DefWindowProc,hWin,uMsg,wParam,lParam
		ret
	.endif
	xor    eax,eax
	ret

WndProc endp

generaNombre proc lpRuta:DWORD,nCaida:DWORD
;////genera el nombre de las partes
;////recibe como entrada un puntero al nombre del fichero destino (sin ruta) y
;////el número que indica la extensión correspondiente
	invoke lstrcpy,addr szExtensionAux,addr szExtensionPartes
	mov eax,nCaida
	mov esi,4 ;extensión partes es '.0000'
;bucle de conversión a ascii del n�mero de la extensi�n
gN0:
	mov ebx,10
	xor edx,edx
	div ebx
	add dl,30h
	mov byte ptr szExtensionAux[esi],dl
	dec esi
	or ax,ax
	jnz gN0

	;la extensión se añade al final del nombre del fichero
	invoke lstrcat,lpRuta,addr szExtensionAux
;	invoke lstrcat,addr szBufferAux,addr szExtensionAux
	;si se está procesando el último fichero se le añade la extensión .exe
	.if bUltimo==1 && nChkExe==TRUE
		invoke lstrcat,eax,addr szExtensionUltimo
;		invoke lstrcat,addr szBufferAux,addr szExtensionUltimo
	.endif
	ret

generaNombre endp
guardaDatos proc nLongDatos:dword,lpNom:dword
LOCAL nTamanioBuffer:DWORD
LOCAL nBytesTotales:DWORD
	;////1024*1024*256 bytes
	mov nBytesTotales,0
	.if nLongDatos>=nTamBufferLectura
		mov nTamanioBuffer,nTamBufferLectura
	.else
		push nLongDatos
		pop nTamanioBuffer
	.endif

	;////reservo un buffer de datos para guardar los datos leídos en bloques del
	;////fichero origen
	invoke HeapAlloc,hHeap,0,nTamanioBuffer
	mov lpBufferDatos,eax

	invoke CreateFile,lpNom,GENERIC_WRITE,FILE_SHARE_WRITE,0,CREATE_ALWAYS,0,0

	.if eax!=-1
		mov hFileP,eax
		;////el puntero se va reposicionando sólo al ir leyendo del fichero
		invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
		invoke ReadFile,hFileO,lpBufferDatos,nTamanioBuffer,addr nBytesLeidos,0
		invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0

		push nBytesLeidos
		pop nBytesTotales

	;en este bucle sólo entra cuando el tamaño de las partes es superior a nTamBufferLectura y es motivo de error (29.08.2004)
		.while nBytesLeidos==nTamBufferLectura
			invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
			invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
			invoke WriteFile,hFileP,lpBufferDatos,nBytesLeidos,addr nBytesEscritos,0
			invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
			invoke HeapFree,hHeap,0,lpBufferDatos
			invoke HeapAlloc,hHeap,0,nTamanioBuffer
			mov lpBufferDatos,eax
			invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0

			mov eax,nLongDatos
			sub eax,nBytesTotales
			.if eax>=nTamanioBuffer
				invoke ReadFile,hFileO,lpBufferDatos,nTamanioBuffer,addr nBytesLeidos,0
			.else
				invoke ReadFile,hFileO,lpBufferDatos,eax,addr nBytesLeidos,0
			.endif
			mov eax,nBytesTotales
			add eax,nBytesLeidos
			mov nBytesTotales,eax
			;invoke ReadFile,hFileO,lpBufferDatos,nTamanioBuffer,addr nBytesLeidos,0
			invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
		.endw

		;////si no se trata de la última parte vuelco los últimos bytes leidos directamente
		.if bUltimo!=1
			invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
			invoke WriteFile,hFileP,lpBufferDatos,nBytesLeidos,addr nBytesEscritos,0
			invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
		.else
			;////mientras que si se trata de la última parte tengo que modificar las variables
			;////y guardar tambi�n el join.exe (si está marcada la casilla del ejecutable)
			.if nChkExe==TRUE
				;////inicializo las variables del 5.exe
				;////offset de szNombreFichero en 5.exe
				mov esi,lpFicheroAux
				mov edi,offset join
				add edi,0e00h
				invoke lstrlen,lpFicheroAux
				;////le quito la extensión para quedarme sólo con el nombre original del fichero
				;////ya que en une.exe se genera de nuevo la extensión
				sub al,9
				mov nFicheroP,al
				xor ecx,ecx
				mov cl,al
			bucleCopiar:
				movsb
				loop bucleCopiar

				mov byte ptr [edi],0
				;////offset de nLongNombreFichero en 5.exe
				mov esi,offset nFicheroP
				mov edi,offset join
				add edi,0f00h
				movsb
				;////offset de nTamUltParte en 5.exe
				mov eax,nLongDatos

				;modificación para evitar que la última parte contenga más datos de los correctos
				sub eax,nFicheroJoin

				mov edi,offset join
				add edi,0f01h
				mov [edi],eax
				;////offset de nPartes en 5.exe
				mov eax,nNumPartes
				mov edi,offset join
				add edi,0f05h
				mov [edi],eax
				;////y lo vuelco al fichero destino antes de los datos de la parte
				invoke WriteFile,hFileP,addr join,nFicheroJoin,addr nBytesEscritos,0
				;////ahora copio los datos correspondientes a la parte
				invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
				invoke WriteFile,hFileP,lpBufferDatos,nBytesLeidos,addr nBytesEscritos,0
				invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
			.else
				invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
				invoke WriteFile,hFileP,lpBufferDatos,nBytesLeidos,addr nBytesEscritos,0
				invoke GetFullPathName,addr szFicheroDestino,MAX_PATH,addr szBufferAux,addr lpFicheroAux
				;////guardo la longitud de la cadena
				push eax
				invoke lstrcat,addr szBufferAux,addr szExtensionBat
				invoke CreateFile,addr szBufferAux,GENERIC_WRITE,FILE_SHARE_WRITE,0,CREATE_ALWAYS,0,0
				mov hFileBat,eax
				invoke WriteFile,eax,addr szTextoBat1,19,addr nBytesEscritos,0

				invoke lstrlen,lpFicheroAux
				mov nLen,eax

				invoke lstrcpy,offset szBufferAux,lpFicheroAux

				mov esi,offset szBufferAux
				pop eax
				add esi,eax
				mov byte ptr[esi],0
				invoke lstrcat,lpFicheroAux,offset szExtensionAst
				push nLen
				invoke WriteFile,hFileBat,lpFicheroAux,nLen,addr nBytesEscritos,0
				;////le quito el .bat
				pop nLen
				sub nLen,4
				invoke WriteFile,hFileBat,addr szBufferAux,nLen,addr nBytesEscritos,0
				invoke CloseHandle,hFileBat
				invoke SendMessage,hProgreso,PBM_DELTAPOS,1,0
			.endif
		.endif

		invoke HeapFree,hHeap,0,lpBufferDatos
		invoke CloseHandle,hFileP
		mov bResultado,1
	.else
		mov bResultado,0
	.endif
finGd:
	ret
guardaDatos endp

compruebaDatos proc
	invoke GetDlgItemText,hDialog,txtFicheroOrigen,addr szFicheroOrigen,MAX_PATH
	invoke CreateFile,addr szFicheroOrigen,GENERIC_READ,0,0,OPEN_EXISTING,0,0
	.if eax!=-1
		invoke CloseHandle,eax
		invoke GetDlgItemText,hDialog,txtFicheroDestino,addr szFicheroDestino,MAX_PATH
;;;;;;;compruebo si el fichero de destino se puede crear con createfile y create_new
;;;;;;;si existe (eax=50h) cierro el handle, si no existe borro el fichero recién creado
;;;;;;;		int 3
;;;;;;		invoke CreateFile,addr szFicheroDestino,GENERIC_WRITE,0,0,CREATE_NEW,0,0
;;;;;;		mov hFileD,eax
;;;;;;		invoke GetLastError
;;;;;;;si el fichero ya existe (significar� que el path es correcto) o no hay error
;;;;;;;a la hora de crearlo continuamos
;;;;;;		.if eax==050h || eax==0
;;;;;;			push eax
;;;;;;			.if hFileD!=-1
;;;;;;				invoke CloseHandle,hFileD
;;;;;;			.endif
;;;;;;			pop eax
;;;;;;			.if eax==0
;;;;;;				invoke DeleteFile,addr szFicheroDestino
;;;;;;			.endif
;;;;;;			xor eax,eax
;;;;;;		.else
;;;;;;			mov eax,2
;;;;;;			jmp @f
;;;;;;		.endif
	.else
		mov eax,1
		jmp @f
	.endif

	invoke GetDlgItemInt,hDialog,txtNumPartes,0,0
	.if eax<=1 || eax>999
		mov eax,4
		jmp @f
	.endif

	invoke GetDlgItemInt,hDialog,txtTamPartes,0,0
	.if eax<=0
		mov eax,3
		jmp @f
	.endif

	mov eax,0
@@:
	ret

compruebaDatos endp

abrirFichero proc
	mov bResultado,0
	mov ofn.Flags,OFN_FILEMUSTEXIST or OFN_PATHMUSTEXIST or OFN_LONGNAMES or OFN_EXPLORER or OFN_HIDEREADONLY
	invoke GetOpenFileName,addr ofn
	;si no hay error actualizo la editBox del nombre del fichero origen
	.if eax==TRUE
		invoke abreOrigen,addr szOFNNombreFichero,1
		.if bResultado==1
			invoke rellenaTexto
			invoke IsDlgButtonChecked, hDialog, chkDisk
			.if eax==TRUE
				invoke SetDlgItemInt,hDialog,txtTamPartes,nTamDisquete,0
			.endif
		.endif
		invoke actualizaTamanio
		mov bResultado,1
	.endif
salirOpenFile:
	xor eax,eax
	ret

abrirFichero endp

guardarFichero proc
	invoke GetDlgItemText,hDialog,txtFicheroDestino,addr szFicheroAux,MAX_PATH
	mov ofn.Flags,OFN_OVERWRITEPROMPT
;	mov ofn.lpstrFileTitle,offset szDialogGuardar
	invoke GetSaveFileName,addr ofn
	.if eax!=0
		invoke SetDlgItemText,hDialog,txtFicheroDestino,addr szOFNNombreFichero
	.endif
	xor eax,eax
	ret

guardarFichero endp
abreOrigen proc lpRutaFichero:DWORD,bCerrar:DWORD

	mov nAux,0
	mov nTamFicheroOLo100,0
	mov bResultado,0
	invoke CreateFile,lpRutaFichero,GENERIC_READ,0,0,OPEN_EXISTING,0,0
	.if eax==-1
		mensaje 'error al abrir el fichero origen'
		jmp salirAbreOrigen
	.endif
	mov hFileO,eax
	invoke GetFileSize,hFileO,addr nTamFicheroOHi
	mov nTamFicheroOLo,eax
	;////sólo si el tamaño del fichero es mayor de cien bytes divido entre cien
	.if nTamFicheroOLo>=100
		xor edx,edx
		div nCien
		mov nAux,edx
		mov nTamFicheroOLo100,eax
	.endif

	.if nTamFicheroOHi != 0
		push MB_OK
		mensaje 'el tamaño del fichero origen ha de ser menor de 4 GBytes'
		invoke CloseHandle,hFileO
		jmp salirAbreOrigen
	.endif

	.if bCerrar==1
		invoke CloseHandle,hFileO
	.endif
	mov bResultado,1
salirAbreOrigen:
	ret

abreOrigen endp

rellenaTexto proc
;crear macro o proc para borrar memoria en lugar de llamar al api

			invoke RtlZeroMemory,offset szTamFicheroC,sizeof szTamFicheroC

			invoke GetDlgItem,hDialog,txtFicheroOrigen
			invoke EnableWindow,eax,TRUE
			invoke GetDlgItem,hDialog,txtFicheroDestino
			invoke EnableWindow,eax,TRUE

			invoke SetDlgItemText,hDialog,txtFicheroOrigen,offset szOFNNombreFichero
			invoke SetDlgItemText,hDialog,txtFicheroDestino,offset szOFNNombreFichero
			;relleno las cajas de tama�o y n�mero de partes con los valores adecuados
			invoke SetDlgItemInt,hDialog,txtTamPartes,nTamFicheroOLo,0
			invoke SetDlgItemInt,hDialog,txtNumPartes,2,0
			;invoke SendMessage,hBarraTamanio,TBM_SETPOS,TRUE,50
			invoke actualizaTamanio
			;invoke SendMessage,hDialog,WM_HSCROLL,0,hBarraTamanio

			invoke dwtoa,nTamFicheroOLo,addr szBufferAux
			invoke lstrlen,addr szBufferAux
			invoke insertaSeparador, eax,addr szBufferAux,addr szTamFicheroC

			invoke IsDlgButtonChecked, hDialog, chkDisk
			.if eax==TRUE
				invoke SendDlgItemMessage,hDialog,chkDisk,BM_SETCHECK,0,0
			.endif

			.if nTamFicheroOLo>=nTamDisquete
				invoke EnableWindow,hChkDisk,TRUE
			.else
				invoke EnableWindow,hChkDisk,FALSE
			.endif

;			invoke EnableWindow,hTxtNumTotal,TRUE
;			invoke EnableWindow,hTxtFicheroBat,TRUE
;			invoke EnableWindow,hTxtTamPrimeras,TRUE
			invoke EnableWindow,hTxtTamUltima,TRUE
;			invoke EnableWindow,hTxtNumUltima,TRUE
			invoke EnableWindow,hStatic23,TRUE
			invoke EnableWindow,hStatic8,TRUE
			invoke EnableWindow,hStatic9,TRUE
			invoke EnableWindow,hStatic14,TRUE
			invoke EnableWindow,hStatic15,TRUE

;;			invoke ShowWindow,hTxtNumTotal,SW_SHOWNORMAL
;;			invoke ShowWindow,hTxtFicheroBat,SW_SHOWNORMAL
;;			invoke ShowWindow,hTxtTamPrimeras,SW_SHOWNORMAL
;;			invoke ShowWindow,hTxtTamUltima,SW_SHOWNORMAL
;;			invoke ShowWindow,hTxtNumUltima,SW_SHOWNORMAL

			invoke EnableWindow,hTxtTamOrigen0,TRUE
			invoke EnableWindow,hTxtTamOrigen,TRUE
			invoke EnableWindow,hTxtTamOrigen2,TRUE
			invoke EnableWindow,hTamPartes,TRUE
			invoke EnableWindow,hNumPartes,TRUE
			invoke EnableWindow,hBarraTamanio,TRUE
			invoke EnableWindow,hChkExe,TRUE
;;;;//////////////////////////////////
;;;;de momento sólo muestro el tamaño en bytes
;;;;			mov eax,nTamFicheroOLo
;;;;			xor edx,edx
;;;;			.if eax>=1024 ;&& eax<1048576; KB
;;;;				mov ebx,1024
;;;;				div ebx
;;;;				invoke dwtoa,eax,addr szBufferAux
;;;;				invoke lstrcat,addr szBufferAux,addr szKB
;;;;				invoke SetDlgItemText,hDialog,txtTamOrigenKB,addr szBufferAux
;;;;			.endif
			invoke SetDlgItemText,hDialog,txtTamOrigen, addr szTamFicheroC
			invoke actualizaEtiquetas
			ret

rellenaTexto endp

insertaSeparador proc len:DWORD,lpszIn:DWORD,lpszOut:DWORD

	push ebx
	mov esi,lpszIn
	mov edi,lpszOut
	;////el número de dígitos separadores de miles lo obtengo dividiendo la longitud de la cadena
	;////entre 3 y rest�ndole uno si el resto es igual a cero
	mov ebx,3
	mov eax,len
	push eax
	xor edx,edx
	div ebx
	.if edx==0
		dec eax
	.endif
	mov nPuntos,eax
	pop eax

	add esi,eax
	add edi,eax
	;////pongo un cero para borrar los restos de la cadena anterior (aunque creo que no va a funcionar
	;////para números muy grandes)
	mov word ptr [edi],0
	add edi,nPuntos
	mov ebx,0
bS1:
	dec esi
	dec edi
	push eax
	mov al,byte ptr [esi]
	mov byte ptr[edi],al
	pop eax
	dec eax
	je finSeparador
	inc ebx
	.if ebx==3
		dec edi
		push eax
		mov al,byte ptr [separador]
		mov byte ptr[edi],al
		pop eax
		mov ebx,0
	.endif
	jmp bS1
finSeparador:
	dec edi
	pop ebx
	ret

insertaSeparador endp

editProc PROC hEdit:DWORD,uMsg:DWORD,wParam:DWORD,lParam:DWORD
;procedimiento de los editBoxes que hace que sólo admitan entrada numérica
;y actualiza las cajas de tamaño/número de partes según el valor de la otra
;añado el procesamiento del wm_keydown para interceptar la tecla supr
    .if uMsg==WM_CHAR
        mov eax,wParam
        .if (al>="0" && al<="9") || al==VK_BACK
            invoke CallWindowProc,nOldEditProc,hEdit,uMsg,eax,lParam
	        mov eax,hNumPartes
			.if hEdit==eax
				invoke actualizaTamanio
			.endif
	         mov eax,hTamPartes
	         .if hEdit==eax
;////el 1 en bResultado es para que llame a actualizar la barra de tamaño
				mov bResultado,1
	         	invoke actualizaPartes
			.endif
       .endif
    .else
			invoke CallWindowProc,nOldEditProc,hEdit,uMsg,wParam,lParam
	      	ret
	 .endif
    xor eax,eax
    ret

editProc endp

actualizaPartes proc

	invoke GetDlgItemInt,hDialog,txtTamPartes,0,0
	push eax
	invoke IsDlgButtonChecked,hDialog,chkDisk
	;////si está marcado el check de tamaño disquete pero se modifica el tamaño de la caja
	;////de texto desmarco el check
	.if eax==TRUE
		pop eax
		push eax
		.if eax!=nTamDisquete
			invoke SendDlgItemMessage,hDialog,chkDisk,BM_SETCHECK,0,0
		.endif
	.endif
	pop eax
	push eax
	.if eax>nTamFicheroOLo
		invoke SetDlgItemInt,hDialog,txtTamPartes,nTamFicheroOLo,0
		invoke SendMessage,hTamPartes,EM_SETSEL,0,-1
		mov eax,nTamFicheroOLo
	.endif
	pop eax
	.if eax!=0
		mov nTamPartes,eax
		invoke calculaPartes,1,nTamPartes
		invoke SetDlgItemInt,hDialog,txtNumPartes,nNumPartes,0
		.if bResultado==1
			invoke actualizaBarraTamanio,1
		.endif
	.else
		invoke SetDlgItemInt,hDialog,txtNumPartes,0,0
		invoke SendMessage,hBarraTamanio,TBM_SETPOS,TRUE,0
		invoke SetDlgItemInt,hDialog,porcentaje,eax,0
	.endif
	invoke actualizaEtiquetas
	ret

actualizaPartes endp

actualizaTamanio proc

	invoke IsDlgButtonChecked,hDialog,chkDisk
	;////si está marcado el check de tamaño disquete pero se modifica el tamaño de la caja
	;////de texto desmarco el check
	.if eax==TRUE
		invoke SendDlgItemMessage,hDialog,chkDisk,BM_SETCHECK,0,0
	.endif

	invoke GetDlgItemInt,hDialog,txtNumPartes,0,0
	mov nNumPartes,eax

	.if eax>999
		invoke SetDlgItemInt,hDialog,txtNumPartes,999,0
		invoke SendMessage,hNumPartes,EM_SETSEL,0,-1
	.endif

	.if nNumPartes!=0
		invoke calculaPartes,0,nNumPartes
		invoke SetDlgItemInt,hDialog,txtTamPartes,nTamPrimeras,0
		invoke actualizaBarraTamanio,0
	.else
		invoke SetDlgItemInt,hDialog,txtTamPartes,0,0
		invoke SendMessage,hBarraTamanio,TBM_SETPOS,TRUE,0
		invoke SetDlgItemInt,hDialog,porcentaje,eax,0
	.endif
	invoke actualizaEtiquetas
	ret

actualizaTamanio endp

actualizaEtiquetas proc

	invoke GetDlgItemInt,hDialog,txtNumPartes,0,0
	.if eax!=0
		invoke RtlZeroMemory,offset szTamFicheroC,sizeof szTamFicheroC
;		invoke dwtoa,nTamPrimeras,addr szBufferAux
;		invoke lstrlen,addr szBufferAux
;		invoke insertaSeparador, eax,addr szBufferAux,addr szTamFicheroC

;		invoke SetDlgItemText,hDialog,txtTamPrimeras,addr szTamFicheroC

		invoke RtlZeroMemory,offset szTamFicheroC,sizeof szTamFicheroC
		invoke dwtoa,nTamUltima,addr szBufferAux
		invoke lstrlen,addr szBufferAux
		invoke insertaSeparador, eax,addr szBufferAux,addr szTamFicheroC

		invoke SetDlgItemText,hDialog,txtTamUltima,addr szTamFicheroC
;		invoke SetDlgItemInt,hDialog,txtNumTotal,nNumPartes,0
;		mov eax,nNumPartes
;		sub eax,1
;		invoke SetDlgItemInt,hDialog,txtNumUltima,eax,0
	.else
;		invoke SetDlgItemInt,hDialog,txtNumTotal,0,0
;		invoke SetDlgItemInt,hDialog,txtTamPrimeras,0,0
;		invoke SetDlgItemInt,hDialog,txtNumUltima,0,0
		invoke SetDlgItemInt,hDialog,txtTamUltima,0,0
	.endif
	ret

actualizaEtiquetas endp

acercaScroll proc hWin:HWND,iMsg:UINT,wParam:WPARAM,lParam:LPARAM
LOCAL 	re:RECT
LOCAL	ps:PAINTSTRUCT

	.if iMsg==WM_INITDIALOG
		push	hWin
		pop		hWnd
		invoke CenterWindow,hDialog,hWin
		invoke SetTimer, hWin, NULL, 30, NULL
		mov hTimer,eax
		invoke GetClientRect,hWin,addr rect
		invoke GetClientRect,hWin,addr re
		push rect.bottom
		pop nPosY
		push rect.bottom
		pop nAltoR
		push rect.right
		pop nAnchoR
		mov nPosX,0
		mov nX,0
		push rect.top
		pop nY
	.elseif iMsg==WM_TIMER
		dec nPosY
		.if nPosY==0ffffff00h
			push rect.bottom
			pop nPosY
		.endif
		push nPosY
		pop rect.top
		invoke InvalidateRect,hWin,NULL,FALSE
	.elseif iMsg==WM_PAINT
		invoke BeginPaint,hWin,addr ps
		mov hDC,eax
		invoke CreateCompatibleDC,hDC
		mov hOtro,eax
		invoke CreateCompatibleBitmap,hDC,nAnchoR,nAltoR
		mov hBitmap,eax
		invoke SelectObject,hOtro,hBitmap
		mov hOld,eax

		RGB 0,0,0
		invoke CreateSolidBrush,eax
		push eax
		;////uso otra estructura rect porque la posición del original está ya desplazada
		;////y empezaría a rellenarse de abajo hacia arriba siguiendo al scroll
		invoke FillRect,hOtro,addr re,eax
		pop eax
		invoke DeleteObject,eax

        invoke CreateFont,-100,-70,900,0,40,0,0,0,ANSI_CHARSET,\
                                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
                                       DEFAULT_QUALITY,DEFAULT_PITCH or FF_ROMAN ,\
                                       ADDR fontName
        invoke SelectObject, hOtro, eax
		invoke SetBkMode,hOtro,OPAQUE
		RGB 100,0,0
		invoke SetTextColor,hOtro,eax
		RGB 64,0,0
		invoke SetBkColor,hOtro,eax
		push rect.top
		add rect.top,255
		push rect.left
		mov rect.left,0
		invoke DrawText,hOtro,addr appName,-1,addr rect,DT_CENTER + DT_NOCLIP
		pop rect.left
		pop rect.top


        invoke CreateFont,-14,-9,0,0,40,0,0,0,ANSI_CHARSET,\
                                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
                                       DEFAULT_QUALITY,DEFAULT_PITCH or FF_ROMAN ,\
                                       ADDR fontName
        invoke SelectObject, hOtro, eax

		invoke SetBkMode,hOtro,TRANSPARENT
		RGB 255,255,255
		invoke SetTextColor,hOtro,eax
		invoke DrawText,hOtro,addr szTxtAcercade,-1,addr rect,DT_CENTER+ DT_NOCLIP



        invoke CreateFont,-8,-8,0,0,40,0,0,0,ANSI_CHARSET,\
                                       OUT_DEFAULT_PRECIS,CLIP_DEFAULT_PRECIS,\
                                       DEFAULT_QUALITY,DEFAULT_PITCH or FF_ROMAN ,\
                                       ADDR fontNameAsc
        invoke SelectObject, hOtro, eax
		RGB 255,0,0
		invoke SetTextColor,hOtro,eax
		add rect.top,160
		invoke DrawText,hOtro,addr szTxtAcercade2,-1,addr rect,DT_CENTER+DT_NOCLIP

		invoke BitBlt,hDC,rect.left,0,nAnchoR,nAltoR,hOtro,0,0,SRCCOPY
		invoke SelectObject,hOtro,hOld
		invoke DeleteDC,hOtro
		invoke DeleteObject,hBitmap
		invoke EndPaint,hWin,addr ps

	.elseif iMsg==WM_LBUTTONDOWN
		invoke SendMessage,hWin,WM_CLOSE,0,0
	.elseif iMsg==WM_CLOSE
		invoke KillTimer,hWin,hTimer
		invoke EndDialog,hWin,NULL
	.else
		mov eax,FALSE
		ret
	.endif
	mov eax,TRUE
	ret

acercaScroll endp

RandomNumGen PROC uses ebx min:DWORD, max:DWORD
;    mov     ebx, max
;    sub     ebx, min
;    inc     ebx
;    xor     edx, edx
;    mov     eax, RandSeed
;    div     ebx
;    add     RandSeed, eax
;    add     edx, min
;    mov     eax, edx
;    ret
RandomNumGen ENDP

calculaPartes proc origen:DWORD,divisor:DWORD

	mov eax,nTamFicheroOLo
	xor edx,edx
	div divisor
	mov nResto,edx
	mov nCociente,eax
;////origen=0 => se ha modificado el número de las partes (por lo tanto se divide entre el número
;////de partes
	.if origen==0
		mov eax,divisor
		sub eax,nResto
		sub eax,1
		mov nValorCritico,eax
		mov eax,nCociente
		.if nValorCritico<=eax
			add eax,1
			mov nTamPrimeras,eax
			sub eax,1
			sub eax,nValorCritico
			mov nTamUltima,eax
			.if nChkExe==TRUE
				add nTamUltima,nFicheroJoin
;				.if nNumPartes==1
;					push nTamPrimeras
;					pop eax
;					add nTamUltima,eax
;				.endif
			.endif

		.else
			mov nTamPrimeras,eax
			add eax,nResto
			mov nTamUltima,eax
			.if nTamUltima==0
				push nTamPrimeras
				pop nTamUltima
			.endif
			.if nChkExe==TRUE
				add nTamUltima,nFicheroJoin
			.endif
		.endif

		mov eax,nNumPartes
	.else
;////origen=1 => se ha modificado el tamaño de las partes (por lo tanto se divide entre el tamaño
;////de las partes
		push divisor
		pop nTamPrimeras
		mov nTamUltima,edx
		.if nTamUltima==0
			push nTamPrimeras
			pop nTamUltima
		.endif
		.if nChkExe==TRUE
			add nTamUltima,nFicheroJoin
		.endif
		.if nResto!=0
			inc eax
		.endif
		mov nNumPartes,eax
	.endif
	ret

calculaPartes endp

CenterWindow PROC USES ebx esi edi mainWndHndl:DWORD, targetWndHndl:DWORD

    LOCAL   mainWnd     :RECT
    LOCAL   targetWnd   :RECT
    xor     eax, eax
    push    eax
    lea     eax, DWORD PTR [ebp-20h]
    push    eax
    mov     edx, DWORD PTR [ebp+0Ch]
    push    edx
    call    GetWindowRect               ;MROM Penalty
    mov     esi, targetWnd.bottom
    mov     edi, targetWnd.right
    sub     esi, targetWnd.top
    sub     edi, targetWnd.left
    push    esi
    push    edi
    shr     esi, 1
    shr     edi, 1
    lea     eax, DWORD PTR [ebp-10h]
    push    eax
    mov     edx, DWORD PTR [ebp+8]
    push    edx
    call    GetWindowRect               ;MROM Penalty
    mov     eax, mainWnd.bottom         ;Bank Conflict
    mov     ecx, mainWnd.right
    sub     eax, mainWnd.top
    sub     ecx, mainWnd.left
    shr     eax, 1
    shr     ecx, 1
    sub     eax, esi
    sub     ecx, edi
    mov     ebx, mainWnd.top
    mov     edx, mainWnd.left
    add     ebx, eax
    add     edx, ecx
    push    ebx
    push    edx
    mov     eax, targetWndHndl
    push    eax
    call    MoveWindow                  ;MROM Penalty
    ret

CenterWindow ENDP

cortar proc parametro:DWORD

	invoke SetDlgItemText,hDialog,btCortar,addr szCortando
	invoke EnableWindow,hCortar,FALSE
	invoke abreOrigen,addr szFicheroOrigen,0
	invoke GetProcessHeap
	mov hHeap,eax
	;////inicializo la barra de progreso
	mov eax,nNumPartes
	mov ebx,4
	mul ebx
	shl eax,16
	;////en la hiword de eax va el máximo del rango de valores y en la lowword el mínimo
	invoke SendMessage,hProgreso,PBM_SETRANGE,0,eax
	mov bUltimo,0
	mov nNumExt,0
	;////se repite nNumPartes-1 porque la última la genero de forma distinta
	;////(hay que añadirle la parte del une.exe)

	;////después de esta llamada tengo en lpFicheroAux un puntero al nombre del fichero destino
	;////bucle principal
	mov ecx,1
	.while ecx<nNumPartes
		push ecx
		invoke GetFullPathName,addr szFicheroDestino,MAX_PATH,addr szBufferAux,addr lpFicheroAux
		invoke generaNombre,lpFicheroAux,nNumExt
		invoke guardaDatos,nTamPrimeras,addr szBufferAux
		.if bResultado==0
			jmp @f
		.endif
		inc nNumExt
		pop ecx
		inc ecx
	.endw
	mov bUltimo,1
	;////en el tamaño de la última parte ya debería ir incluido el del join.exe
	invoke GetFullPathName,addr szFicheroDestino,MAX_PATH,addr szBufferAux,addr lpFicheroAux
	invoke generaNombre	,lpFicheroAux,nNumExt
	;////szBufferAux ha sido modificado también en la anterior llamada
	;////ya que la función getFullPathName coloca concatenados a los dos �ltimos
	;////par�metros (en realidad el último es un puntero al lugar donde comienza
	;////el nombre del fichero en el segundo parámetro)
	invoke guardaDatos,nTamUltima,addr szBufferAux
	;////aviso al thread principal de que he terminado de cortar
	invoke CloseHandle,hFileO
	mensaje 'el fichero ha sido cortado correctamente'
	invoke SendMessage,hProgreso,PBM_SETPOS,0,0
	invoke SendMessage,hDialog,WM_FIN,NULL,NULL
	invoke EnableWindow,hCortar,TRUE
	invoke SetDlgItemText,hDialog,btCortar,addr szCortar
	ret
@@:
	mensaje 'error al crear una de las partes. por favor comprueba que la ruta y el nombre de destino son correctos'
	invoke CloseHandle,hFileO
	invoke EnableWindow,hCortar,TRUE
	invoke SendMessage,hProgreso,PBM_SETPOS,0,0
	invoke SendMessage,hDialog,WM_FIN,NULL,NULL
	invoke SetDlgItemText,hDialog,btCortar,addr szCortar
	ret
cortar endp

division proc dividendo:DWORD, divisor:DWORD
;////devuelve eax=parte decimal del cociente (en hex)
;////         nCocienteEntero=parte entera del cociente
	push edi
	xor eax,eax
	mov eax,dividendo
	mov ebx,divisor
	mov nCocienteEntero,0
	mov edi,offset nDigitos
	mov word ptr [edi],0
	mov nContador,0

	xor ecx,ecx
@@:
	  cmp eax,ebx
	  jl @f
	    sub eax,ebx
	    inc ecx
	jmp @b
@@:
	;////aquí ya tenemos la parte entera del cociente
	;////en ecx y el resto en eax
	;////si eax es cero la división ha sido entera
	mov nCocienteEntero,ecx
	.if eax==0
		mov eax,ecx
		mov ecx,0
		jmp fin
	.endif
	;////esto no puede ocurrir salvo cuando tamaño de las partes = tamaño original
	xor ecx,ecx
	mov nContador,0
	mov ebx,divisor
masDigitos:
	inc nContador
	cmp nContador,3
	jz fin
	;////shift a la izquierda del resto
	shl eax,1
	;////este sub pone el carry a uno si ebx>eax
	sub eax,ebx
	;////en el carry voy teniendo el resultado de la parte fraccionaria
	cmc
	rcl ecx,1
	jmp masDigitos
;;;;////mi intento
;;;;@@:
;;;;	cmp eax,ebx
;;;;	jl @f
;;;;		sub eax,ebx
;;;;		inc ecx
;;;;	jmp @b
;;;;@@:
;;;;	cmp eax,0
;;;;	jz fin2
;;;;	cmp nContador,2
;;;;	;////ahora habría que añadir un cero al cociente
;;;;	jz fin2
;;;;	jmp masDigitos
;;;;fin2:
;;;;	;////aquí eax=parte entera del cociente
;;;;	;////	  ecx=parte decimal del cociente
;;;;	mov eax,nCocienteEntero
;;;;	pop edi
fin:
	ret

division endp
actualizaBarraTamanio proc origen:DWORD
;////origen=0 -> se ha cambiado el número de partes por lo que el porcentaje
;////			 se calcula dividiendo 100 entre el número de partes
;////origen=1 -> se ha cambiado el tamaño por lo que el porcentaje se calcula
;////			 dividiendo el tamaño de las partes entre el tamaño original y multiplicando
;////			 por cien

;;	mov eax,nTamPartes
;;	xor edx,edx
;;	div nTamFicheroOLo
;;	mul nCien
;;	push eax
;;	invoke SendMessage,hBarraTamanio,TBM_SETPOS,TRUE,eax
;;	pop eax
;;	invoke SetDlgItemInt,hDialog,porcentaje,eax,0


;10.04.2003
;para obtener el porcentaje (y la posición de la trackbar) divido directamente 100 entre el número
;de partes en lugar de como lo hacía antes para evitar problemas con ficheros grandes

;	.if origen==0
		mov eax,nCien
		xor edx,edx
		div nNumPartes
;	.else
;		invoke division,nTamPartes,nTamFicheroOLo
;		.if eax==0
;			mov eax,ecx
;			mov ebx,100
;			mul ebx
;		.endif
;	.endif
	push eax
	invoke SendMessage,hBarraTamanio,TBM_SETPOS,TRUE,eax
	pop eax
	invoke SetDlgItemInt,hDialog,porcentaje,eax,0

	ret

actualizaBarraTamanio endp

end start
