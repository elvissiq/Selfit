#Include "AP5MAIL.ch"
#Include "MSOLE.CH" 
#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#Include "FWPrintSetup.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ MCCOMR01  ³ Autor ³                    ³ Data ³ 12/08/2016 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Imprimir Pedido de Compras Grafico                         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ Especifico SELFIT                                          ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß/ 
*/
User Function MCCOMR01(cOpcEx , cNomFile) 

Private cNomARQ
Private cDesc1
Private cDesc2
Private cDesc3
Private _cString
Private aOrd
Private j
Private oFont1
Private oFont2
Private oFont3
Private oFont4
Private oFont5
Private oFont6
Private oFont7
Private lAuto      := .F.
Private nPag       := 1
Private nPagd      := 0
Private NumPed     := Space(6)
Private cPFornec , cEmailForn , cEmailNome , cFornece , cObsPed , cPedEntr 
Private cPerg      := "MCCOMR01" , cMsg , nLinha , nLinhaD , nLinhaO , cObs 
Private oDlg , oGet
Private cGet1      := Space(2)
Private cCodIni , cCodFim 
Private lAux       := .F. 
Private nValIPI    := 0 
Private nValICMS   := 0 
Private nLinMaxIte := 1600 							// 1700 

Private nNewFret   := 0 							// --> Incluso  LAVOR/PROX 11/05/2021 
Private nNewDesp   := 0 							// --> Incluso  LAVOR/PROX 11/05/2021 
Private nNewSegu   := 0 							// --> Incluso  LAVOR/PROX 11/05/2021 
Private lMedicao   := Iif(Empty(SC7->C7_MEDICAO) , .F. , .T.) 				// --> Incluso  LAVOR/PROX 15/06/2021 

Default cOpcEx     := "1"
Default cNomFile   := ""

ConOut("##_MCCOMR01.prw - #INICIO# ----------------------------------------------------") 
cNomARQ := cNomFile 

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Verifica as perguntas selecionadas                           ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Variaveis utilizadas para parametros                         ³
//³ mv_par01	       Do Pedido                                 ³
//³ mv_par02     	   Ate o Pedido 		                     ³
//³ mv_par03	       A partir da Data                          ³
//³ mv_par04           Ate a Data                  	     	     ³
//³ mv_par05           Unidade de Medida             	     	 ³
//³ mv_par06           Nr.Vias                                   ³
//³ mv_par07           Qual Moeda?                               ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ      
ValidPerg()  

If cOpcEx == "1" 									// Via menu ou ações relacionadas
	If !Pergunte(cPerg,.T.) 
		Return 
	EndIf
	cParam1 := MV_PAR01
	cParam2 := MV_PAR02
	dParam3 := MV_PAR03
	dParam4 := MV_PAR04
	nParam5 := MV_PAR05
	nParam6 := MV_PAR06
	nParam7 := MV_PAR07
Else	
	cParam1 := SC7->C7_NUM 
	cParam2 := SC7->C7_NUM 
	dParam3 := SC7->C7_EMISSAO 
	dParam4 := SC7->C7_EMISSAO 
	nParam5 := 1 
	nParam6 := 1 
	nParam7 := 1 
EndIf

ConOut("##_MCCOMR01.prw - Antes da funcao 'Relato()' -- SC7->C7_NUM: ["+SC7->C7_NUM+"] -- cNomFile: ["+cNomFile+"] -- cNomARQ: ["+cNomARQ+"] -- nParam6 (vias): ["+AllTrim(Str(nParam6))+"] ") 

Relato() 

ConOut("##_MCCOMR01.prw - #FINAL#  ----------------------------------------------------") 
//RptStatus({|| Relato()})

Return



/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Programa  ³ RELATO    ³ Autor ³ Leandro Eber       ³ Data ³ 17/09/2015 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Desc.     ³                                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Uso       ³ AP8                                                        ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function Relato() 

Local   nOrder                                                         `
Local   cCondBus
Local   nSavRec
Local   aSavRec  := {}
Local   nRegSM0	 := SM0->(Recno()) 
Local   cEmpAnt	 := SM0->M0_CODIGO 
Local   nCw      := 0 
Local   i        := 0 
Local   c_xC7FIL := "" 

Private lEnc     := .F.
Private cTitulo
Private oFont , cCode , oPrn 
Private cCGCPict , cCepPict 
Private lPrimPag := .T. 
Private nTotPag  := 0 
Private nReem
Private dDtEntrega

ConOut("##_MCCOMR01.prw - Relato() - #INICIO# - - - - - - - - - - - - - - - -") 

// --> Definir as pictures.
cCepPict := PesqPict("SA2" , "A2_CEP")
cCGCPict := PesqPict("SA2" , "A2_CGC")

oFont    := TFont():New( "Arial"          ,, 23 ,, .T. ,,,,, .F. )
oFont1   := TFont():New( "Arial"          ,, 23 ,, .T. ,,,,, .F. )
oFont2   := TFont():New( "Arial"          ,, 23 ,, .F. ,,,,, .F. )
oFont3   := TFont():New( "Arial"          ,, 15 ,, .T. ,,,,, .F. )
oFont4   := TFont():New( "Arial"          ,, 15 ,, .F. ,,,,, .F. )
oFont5   := TFont():New( "Arial"          ,, 12 ,, .T. ,,,,, .F. )  
oFont6   := TFont():New( "Arial"          ,, 12 ,, .F. ,,,,, .F. )
oFont7   := TFont():New( "Arial"          ,, 21 ,, .T. ,,,,, .F. )  
oFont8   := TFont():New( "Arial"          ,, 21 ,, .F. ,,,,, .F. )
oFont9   := TFont():New( "Arial"          ,, 18 ,, .T. ,,,,, .F. )  
oFont10  := TFont():New( "Arial"          ,, 18 ,, .F. ,,,,, .F. ) 
oFont11  := TFont():New( "Arial"          ,, 11 ,, .T. ,,,,, .F. )  
oFont12  := TFont():New( "Arial"          ,, 11 ,, .F. ,,,,, .F. )
oFont1c  := TFont():New( "Courier New"    ,, 24 ,, .T. ,,,,, .F. )
oFont2c  := TFont():New( "Courier New"    ,, 24 ,, .F. ,,,,, .F. )
oFont3c  := TFont():New( "Courier New"    ,, 15 ,, .T. ,,,,, .F. )
oFont4c  := TFont():New( "Courier New"    ,, 13 ,, .F. ,,,,, .F. )
oFont5c  := TFont():New( "Courier New"    ,, 14 ,, .T. ,,,,, .F. )  
oFont6c  := TFont():New( "Courier New"    ,, 14 ,, .T. ,,,,, .F. )
oFont7c  := TFont():New( "Courier New"    ,, 21 ,, .T. ,,,,, .F. )  
oFont8c  := TFont():New( "Courier New"    ,, 21 ,, .F. ,,,,, .F. )
oFont9c  := TFont():New( "Courier New"    ,, 18 ,, .T. ,,,,, .F. )  
oFont10c := TFont():New( "Courier New"    ,, 18 ,, .F. ,,,,, .F. ) 
oFont6v  := TFont():New( "Lucida Console" ,, 12 ,, .F. ,,,,, .F. )

nDescProd  := 0
nTotal     := 0
nTotMerc   := 0
cCondBus   := cParam1
nOrder     := 1
nPagD      := 1   
cObsPed    := ""      
cPedEntr   := "" 
nValFrete2 := 0   
cCodIni    := cParam1
cCodFim    := cParam2 

If Empty(cCodIni)
	cCodIni  := SC7->C7_NUM 
	cCodFim  := SC7->C7_NUM 
	cCondBus := SC7->C7_NUM	
EndIf 

ConOut("##_MCCOMR01.prw - Relato() -- SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] -- xFilial('SC7'): ["+xFilial("SC7")+"] ") 
ConOut("##_MCCOMR01.prw - Relato() -- cCodIni/cCodFim/cCondBus (SC7->C7_NUM): ["+SC7->C7_NUM+"]") 

If AtIsRotina("U_SFCMP06A") 
	c_xC7FIL := SC7->C7_FILIAL 
	ConOut("##_MCCOMR01.prw - Relato() -- Via: U_SFCMP06A() -- c_xC7FIL: ["+c_xC7FIL+"] -- SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] ") 
Else 
	c_xC7FIL := xFilial("SC7") 
	If AtIsRotina("U_SFCMP06") 
		ConOut("##_MCCOMR01.prw - Relato() -- Via: U_SFCMP06() -- c_xC7FIL: ["+c_xC7FIL+"] -- SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] ") 
	EndIf 
EndIf 

dbSelectArea("SC7") 
dbSetOrder(nOrder) 
/*	// --> Alterado DE..: 
dbSeek(xFilial("SC7") + cCondBus , .T.) 
*/	// --> Alterado PARA: 
dbSeek(c_xC7FIL       + cCondBus , .T.) 
//	// --> Alterado FINAL 

// --> Faz contagem de paginas 
/*	// --> Alterado DE..: 
While !Eof()  .And.  C7_FILIAL == xFilial("SC7")  .And.  C7_NUM >= cCodIni  .And.  C7_NUM <= cCodFim 
*/	// --> Alterado PARA: 
While !Eof()  .And.  C7_FILIAL == c_xC7FIL        .And.  C7_NUM >= cCodIni  .And.  C7_NUM <= cCodFim 
//	// --> Alterado FINAL 
	nTotPag++ 
	dbSkip() 
EndDo 

nTotPag := nTotPag/15 

If nTotPag > Int(nTotPag) 
	nTotPag := Int(nTotPag)+1 
Else 
	nTotPag	:= Int(nTotPag) 
EndIf 
	
If Empty(nTotPag) 
	nTotPag := 1 
EndIf 

dbSelectArea("SC7") 
dbSetOrder(nOrder) 
//Seek(xFilial("SC7") + cCondBus , .T.) 
dbSeek(c_xC7FIL       + cCondBus , .T.) 
	
// --> Faz manualmente porque nao chama a funcao Cabec() 
/*	// --> Alterado DE..: 
While !Eof()  .And.  C7_FILIAL == xFilial("SC7")  .And.  C7_NUM >= cCodIni  .And.  C7_NUM <= cCodFim 
*/	// --> Alterado PARA: 
While !Eof()  .And.  C7_FILIAL == c_xC7FIL        .And.  C7_NUM >= cCodIni  .And.  C7_NUM <= cCodFim 
//	// --> Alterado FINAL 		
	// --> Cria as variaveis para armazenar os valores do pedido 
	nOrdem := 1 
	nReem  := 0 
	nPag   := 1 

	If (C7_EMISSAO < dParam3)  .Or.  (C7_EMISSAO > dParam4) 
		dbSkip() 
		Loop 
	EndIf 
	
	ConOut(        "##_MCCOMR01.prw - Relato() -- SM0 (_antes_) - cFilAnt: ["+cFilAnt+"]  --  SM0->M0_CODFIL: ["+AllTrim(SM0->M0_CODFIL)+"] ["+AllTrim(SM0->M0_CIDCOB)+"/"+SM0->M0_ESTCOB+"] ") 

	If     ! Empty(SC7->C7_FILENT)  .And.  SC7->C7_FILIAL <> SC7->C7_FILENT 
		SM0->(dbSetOrder(1)) 
		SM0->(dbSeek(cEmpAnt + SC7->C7_FILENT)) 
		If SM0->(! Eof()) 
			ConOut("##_MCCOMR01.prw - Relato() -- SM0 (Cond: 1) - cFilAnt: ["+cFilAnt+"]  --  SM0->M0_CODFIL: ["+AllTrim(SM0->M0_CODFIL)+"] ["+AllTrim(SM0->M0_CIDCOB)+"/"+SM0->M0_ESTCOB+"] ") 
			aDadEmp := { SM0->M0_NOMECOM, SM0->M0_TEL, SM0->M0_FAX, SM0->M0_CGC, SM0->M0_INSC, SM0->M0_ENDENT, SM0->M0_BAIRENT, SM0->M0_CIDENT, ;
						 SM0->M0_ESTENT, SM0->M0_CEPENT, SM0->M0_ENDCOB, SM0->M0_BAIRCOB, SM0->M0_CIDCOB, SM0->M0_ESTCOB, SM0->M0_CEPCOB}
		Else 
			ConOut("##_MCCOMR01.prw - Relato() -- SM0 (Cond: 2) - cFilAnt: ["+cFilAnt+"]  --  SM0->M0_CODFIL: ["+AllTrim(SM0->M0_CODFIL)+"] ["+AllTrim(SM0->M0_CIDCOB)+"/"+SM0->M0_ESTCOB+"] ") 
			SM0->(dbGoTo(nRegSM0)) 
			aDadEmp := { SM0->M0_NOMECOM, SM0->M0_TEL, SM0->M0_FAX, SM0->M0_CGC, SM0->M0_INSC, SM0->M0_ENDENT, SM0->M0_BAIRENT, SM0->M0_CIDENT, ;
						 SM0->M0_ESTENT, SM0->M0_CEPENT, SM0->M0_ENDCOB, SM0->M0_BAIRCOB, SM0->M0_CIDCOB, SM0->M0_ESTCOB, SM0->M0_CEPCOB} 
		EndIf 
//	--> Incluso  (*INICIO*) 
	ElseIf ! Empty(SC7->C7_FILENT)  .And.  SC7->C7_FILIAL == SC7->C7_FILENT  .And.  AllTrim(SC7->C7_FILENT) <> AllTrim(SM0->M0_CODFIL) 
		SM0->(dbSetOrder(1)) 
		SM0->(dbSeek(cEmpAnt + SC7->C7_FILENT)) 
		If SM0->(! Eof()) 
			ConOut("##_MCCOMR01.prw - Relato() -- SM0 (Cond: 3) - cFilAnt: ["+cFilAnt+"]  --  SM0->M0_CODFIL: ["+AllTrim(SM0->M0_CODFIL)+"] ["+AllTrim(SM0->M0_CIDCOB)+"/"+SM0->M0_ESTCOB+"] ") 
			aDadEmp := { SM0->M0_NOMECOM, SM0->M0_TEL, SM0->M0_FAX, SM0->M0_CGC, SM0->M0_INSC, SM0->M0_ENDENT, SM0->M0_BAIRENT, SM0->M0_CIDENT, ;
						 SM0->M0_ESTENT, SM0->M0_CEPENT, SM0->M0_ENDCOB, SM0->M0_BAIRCOB, SM0->M0_CIDCOB, SM0->M0_ESTCOB, SM0->M0_CEPCOB}
		Else 
			ConOut("##_MCCOMR01.prw - Relato() -- SM0 (Cond: 4) - cFilAnt: ["+cFilAnt+"]  --  SM0->M0_CODFIL: ["+AllTrim(SM0->M0_CODFIL)+"] ["+AllTrim(SM0->M0_CIDCOB)+"/"+SM0->M0_ESTCOB+"] ") 
			SM0->(dbGoTo(nRegSM0)) 
			aDadEmp := { SM0->M0_NOMECOM, SM0->M0_TEL, SM0->M0_FAX, SM0->M0_CGC, SM0->M0_INSC, SM0->M0_ENDENT, SM0->M0_BAIRENT, SM0->M0_CIDENT, ;
						 SM0->M0_ESTENT, SM0->M0_CEPENT, SM0->M0_ENDCOB, SM0->M0_BAIRCOB, SM0->M0_CIDCOB, SM0->M0_ESTCOB, SM0->M0_CEPCOB} 
		EndIf 
//	--> Incluso  (*FINAL* ) 
	Else 
		ConOut(    "##_MCCOMR01.prw - Relato() -- SM0 (Cond: 5) - cFilAnt: ["+cFilAnt+"]  --  SM0->M0_CODFIL: ["+AllTrim(SM0->M0_CODFIL)+"] ["+AllTrim(SM0->M0_CIDCOB)+"/"+SM0->M0_ESTCOB+"] ") 
		SM0->(dbGoTo(nRegSM0)) 
		aDadEmp     := { SM0->M0_NOMECOM, SM0->M0_TEL, SM0->M0_FAX, SM0->M0_CGC, SM0->M0_INSC, SM0->M0_ENDENT, SM0->M0_BAIRENT, SM0->M0_CIDENT,;
						 SM0->M0_ESTENT, SM0->M0_CEPENT, SM0->M0_ENDCOB, SM0->M0_BAIRCOB, SM0->M0_CIDCOB, SM0->M0_ESTCOB, SM0->M0_CEPCOB} 
	EndIf 
		
	MaFisEnd() 
	R110FIniPC(SC7->C7_NUM , , , ) 
		
	For nCw := 1 To nParam6							// Imprime o numero de vias informadas
		nTotal    := 0
		nTotMerc  := 0
		nDescProd := 0
   		nReem     := 1
		nSavRec   := SC7->(Recno()) 
		NumPed    := SC7->C7_NUM 
        li        := 465 
        nTotDesc  := 0 
        cFornece  := SC7->(C7_FORNECE+C7_LOJA) 
        
		ImpCabec(aDadEmp) 
/*	// --> Alterado DE..: 
		While !Eof()  .And.  SC7->C7_FILIAL == xFilial("SC7")  .And.  SC7->C7_NUM == NumPed 
*/	// --> Alterado PARA: 
		While !Eof()  .And.  SC7->C7_FILIAL == c_xC7FIL        .And.  SC7->C7_NUM == NumPed 
//	// --> Alterado FINAL 		
			dbSelectArea("SC7")
			If aScan(aSavRec,Recno()) == 0			// Guardo recno p/gravacao
				aAdd(aSavRec,Recno()) 
			EndIf 

		 //	IncRegua() 

			// --> Verifica se havera salto de formulario 
			If li > 1500 
				nOrdem++ 
			 //	nPag++
				ImpRodape()							// Imprime rodape do formulario e salta para a proxima folha
				ImpCabec(aDadEmp) 
				li  := 465 
			EndIf 

			If !Empty(SC7->C7_RESIDUO)  .And.  SC7->C7_QUJE == 0
				dbSkip()
				Loop 
			EndIf 
			
			If !Empty(SC7->C7_RESIDUO)  .And.  SC7->C7_QUJE <> 0
				lAux := .T. 
			EndIf 
				
	        li := li+60
			
			oPrn:Say( li, 0050, StrZero(Val(SC7->C7_ITEM),4) , oFont6 , 100 ) 
            oPrn:Say( li, 0135, Upper(SC7->C7_PRODUTO)       , oFont6 , 100 ) 

			// --> Pesquisa Descricao do Produto 
			ImpProd() 

			If SC7->C7_DESC1 != 0  .Or.  SC7->C7_DESC2 != 0  .Or.  SC7->C7_DESC3 != 0 
				nDescProd += CalcDesc(SC7->C7_TOTAL , SC7->C7_DESC1 , SC7->C7_DESC2 , SC7->C7_DESC3) 
			Else 
				nDescProd += SC7->C7_VLDESC 
			EndIf 

			dbSkip() 
		EndDo 
			
		dbGoTo(nSavRec)

		If li > 1550 
			nOrdem++
			ImpRodape()								// Imprime rodape do formulario e salta para a proxima folha
			ImpCabec(aDadEmp)
			li  := 465
		EndIf

		FinalPed(aDadEmp)							// Imprime os dados complementares do PC
	Next nCw 
	
	MaFisEnd()  
      
	dbSelectArea("SC7")
	If Len(aSavRec)>0
		For i:=1 To Len(aSavRec)
			dbGoTo(aSavRec[i])
		 //	RecLock("SC7",.F.)  					// Atualizacao do flag de Impressao
		 //	MsUnLock()
		Next
		dbGoTo(aSavRec[Len(aSavRec)])				// Posiciona no ultimo elemento e limpa array
	EndIf              	 
			
	If Len(aSavRec)>0
		dbGoTo(aSavRec[Len(aSavRec)])					// Posiciona no ultimo elemento e limpa array
	Endif	

	aSavRec := {}
	
	dbSkip()
EndDo

dbSelectArea("SC7") 
Set Filter To 
dbSetOrder(1) 

dbSelectArea("SX3")
dbSetOrder(1)

If lEnc 
	oPrn:EndPage() 
	oPrn:Preview() 

	ConOut(    "##_MCCOMR01.prw - Relato() - cNomARQ.........: ["+cNomARQ +"] ") 
	ConOut(    "##_MCCOMR01.prw - Relato() - GetSrvProfString: ["+GetSrvProfString("Startpath","")+"] ") 
	If Empty(cNomARQ) 
		ConOut("##_MCCOMR01.prw - Relato() - Apagando.cNomArq: ["+cNomARQ +"] ") 
		fErase( GetSrvProfString("Startpath","") + "MCCOMR01_"+__cUserID+".pdf") 
	EndIf 
EndIf 

SM0->(dbGoTo(nRegSM0)) 

ConOut("##_MCCOMR01.prw - Relato() - #FINAL#  - - - - - - - - - - - - - - - -") 

Return .T. 



/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ ImpCabec  ³ Autor ³ Wagner Xavier      ³ Data ³            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Imprime o Cabecalho do Pedido de Compra                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ImpCabec(Void)                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MatR110                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ImpCabec(aDadEmp) 

Local   nOrden , cCGC
Local   cMoeda
Local   cAlter     := "" 
Local   cCompr     := "" 
Local   cAprov     := "" 
Local   cTipoSC7   := "" 
//cal   oMainPrt 
Local   cStartPath := GetSrvProfString("Startpath","") 
Local   c_xC7FIL   := "" 

Public  cAprovador := "" 

Private cSubject 

ConOut("##_MCCOMR01.prw - Relato() - ImpCabec() - #INICIO#  - - - - - - - - -") 

nOrden := 0 
cCGC   := "" 
cMoeda := Iif(nParam7<10 , Str(nParam7,1) , Str(nParam7,2)) 
cAlter := "" 

ConOut(            "##_MCCOMR01.prw - Relato() - ImpCabec() - cStartPath...: ["+cStartPath+"] ") 

If ! lPrimPag 
	ConOut(        "##_MCCOMR01.prw - Relato() - ImpCabec() - lPrimPag.....: [.F.] - SC7->C7_NUM: ["+SC7->C7_NUM+"] ") 
	oPrn:EndPage() 
	oPrn:StartPage() 
Else
	lPrimPag := .F. 
	lEnc     := .T. 

	ConOut(        "##_MCCOMR01.prw - Relato() - ImpCabec() - lPrimPag.....: [.T.] - SC7->C7_NUM: ["+SC7->C7_NUM+"] ") 
	ConOut(        "##_MCCOMR01.prw - Relato() - ImpCabec() - cNomARQ......: ["+cNomARQ +"] ") 
	If Empty(cNomARQ) 
		ConOut(    "##_MCCOMR01.prw - Relato() - -- [ If Empty(cNomARQ) ]") 
		ConOut(    "##_MCCOMR01.prw - Relato() - ImpCabec() - GetTempPath(): ["+GetTempPath()+"] ") 
		ConOut(    "##_MCCOMR01.prw - Relato() - ImpCabec() - __cUserID....: ["+__cUserID    +"] ") 
		If File(GetTempPath()+"MCCOMR01_"+__cUserID+".pdf") 
			ConOut("##_MCCOMR01.prw - Relato() - ImpCabec() - Apagando.....: ["+GetTempPath()+"MCCOMR01_"+__cUserID+".pdf"+"] ") 
			fErase(GetTempPath()+"MCCOMR01_"+__cUserID+".pdf") 
		EndIf 

		oPrn := FWMSPrinter():New("MCCOMR01_"+__cUserID , IMP_SPOOL ,     ,            , .T.) 
		oPrn:SetLandscape()
		oPrn:SetPaperSize(9)						// 9 - A4     210mm x 297mm  620 x 876
		oPrn:SetMargin( 40, 0, 0, -40 ) 			// nEsquerda, nSuperior, nDireita, nInferior

		oPrn:nDevice  := IMP_PDF
		oPrn:cPathPDF := AllTrim(GetTempPath()) 
		oPrn:SetViewPDF(.T.) 
	Else
		ConOut(    "##_MCCOMR01.prw - Relato() - -- [ Else | If Empty(cNomARQ) ]") 
		ConOut(    "##_MCCOMR01.prw - Relato() - ImpCabec() - cStartPath...: ["+cStartPath+"] ") 
		ConOut(    "##_MCCOMR01.prw - Relato() - ImpCabec() - cNomARQ......: ["+cNomARQ   +"] ") 
		oPrn := FWMSPrinter():New( cNomARQ              , IMP_PDF   , .T. , cStartPath , .T.) 
		oPrn:SetLandscape() 
		oPrn:SetPaperSize(9)
	//	oPrn:SetMargin(20,20,20,20)
		oPrn:SetMargin( 40, 0, 0, -40 ) 			// nEsquerda, nSuperior, nDireita, nInferior
		oPrn:cPathPDF := AllTrim(cStartPath) 
		oPrn:SetViewPDF(.F.) 
	EndIf
	oPrn:StartPage()
EndIf

//oPrn:Say( 0020, 0020, " ",oFont,100 ) 			// startando a impressora 
cCompr   := Left(UsrFullName(SC7->C7_USER),20) 
cTipoSC7 := Iif(SC7->C7_TIPO==1 , "PC" , "AE") 

If AtIsRotina("U_SFCMP06A") 
	c_xC7FIL := SC7->C7_FILIAL 
	ConOut("##_MCCOMR01.prw - Relato() - ImpCabec() -- Via: U_SFCMP06A() -- c_xC7FIL: ["+c_xC7FIL+"] -- SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] ") 
Else 
	c_xC7FIL := xFilial("SC7") 
	If AtIsRotina("U_SFCMP06") 
		ConOut("##_MCCOMR01.prw - Relato() - ImpCabec() -- Via: U_SFCMP06() -- c_xC7FIL: ["+c_xC7FIL+"] -- SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] ") 
	EndIf 
EndIf 

dbSelectArea("SCR")
dbSetOrder(1)
/*	// --> Alterado DE..: 
dbSeek(xFilial("SC7") + "PC" + SC7->C7_NUM) 
*/	// --> Alterado PARA: 
dbSeek(c_xC7FIL       + "PC" + SC7->C7_NUM) 
//	// --> Alterado FINAL 

cAprov := "A G U A R.   L I B."

/*	// --> Alterado DE..: 
While !Eof()  .And.  SCR->CR_FILIAL+AllTrim(SCR->CR_NUM) == xFilial("SC7")+SC7->C7_NUM  .And.  SCR->CR_TIPO == cTipoSC7 
*/	// --> Alterado PARA: 
While !Eof()  .And.  SCR->CR_FILIAL+AllTrim(SCR->CR_NUM) == c_xC7FIL      +SC7->C7_NUM  .And.  SCR->CR_TIPO == cTipoSC7 
//	// --> Alterado FINAL 
 //	TODO Migração de dicionario não permite mais o loop - UsrFullName(SCR->CR_USER): tranpondo para função statica
 //	cAprovador := AllTrim(UsrFullName(SCR->CR_USER))		
	cAprovador := getAllName(SCR->CR_USER) 			// SCR->CR_USER
	Do Case
	Case SCR->CR_STATUS=="03" 						// Liberado
		cAprov := "L I B E R A D O"
	Case SCR->CR_STATUS=="04" 						// Bloqueado
		cAprov := "B L O Q E A D O"
	Case SCR->CR_STATUS=="05" 						// Nivel Liberado
		cAprov := "N I V E L   L I B."
	OtherWise                 						// Aguar.Lib
		cAprov := "A G U A R.   L I B."
	EndCase
	dbSelectArea("SCR")
	dbSkip()
EndDo

// cAprovador := AllTrim(UsrFullName(_cxApvAux))
// --> Incluso  LAVOR/PROX  15/06/2021   (*INICIO*) 
If lMedicao 
	cAprov := "PEDIDO AUTOMATICO" 
EndIf 
// --> Incluso  LAVOR/PROX  15/06/2021   (*FINAL* ) 

// Cabecalho (Logomarca e Titulo)
oPrn:Box( 0040, 0040, 0170,2920,"-5")
oPrn:SayBitmap( 0030,0050,"selfitlogopc.jpg",0140,0135 ) 

// Cabecalho (Enderecos da Empresa e Fornecedor)
oPrn:Box( 0170, 0040, 0420,0910,"-5")
oPrn:Box( 0170, 0910, 0420,2300,"-5")
oPrn:Box( 0170, 2300, 0420,2920,"-5")

// Cabecalho Produto do Pedido
oPrn:Box( 0420, 0040, 0480,0125,"-5") 				// Item
oPrn:Box( 0420, 0125, 0480,0340,"-5") 				// Codigo  
oPrn:Box( 0420, 0340, 0480,1190,"-5") 				// Desc  
oPrn:Box( 0420, 1190, 0480,1545,"-5") 				// Obs
oPrn:Box( 0420, 1545, 0480,1650,"-5") 				// Un     
oPrn:Box( 0420, 1650, 0480,1790,"-5") 				// Qtde
oPrn:Box( 0420, 1790, 0480,2050,"-5") 				// Valor Total
oPrn:Box( 0420, 2050, 0480,2160,"-5") 				// ICM
oPrn:Box( 0420, 2160, 0480,2300,"-5") 				// IPI
oPrn:Box( 0420, 2300, 0480,2490,"-5") 				// Valor Uni
oPrn:Box( 0420, 2490, 0480,2620,"-5") 				// Dt Entr 
oPrn:Box( 0420, 2620, 0480,2810,"-5") 				// Centro Custo
oPrn:Box( 0420, 2810, 0480,2920,"-5") 				// Solic.

// Espaco dos Itens do Pedido                      
oPrn:Box( 0480, 0040, nLinMaxIte,0125,"-5") 		// Item 
oPrn:Box( 0480, 0125, nLinMaxIte,0340,"-5") 		// Codigo
oPrn:Box( 0480, 0340, nLinMaxIte,1190,"-5") 		// Descri
oPrn:Box( 0480, 1190, nLinMaxIte,1545,"-5") 		// Obs
oPrn:Box( 0480, 1545, nLinMaxIte,1650,"-5") 		// UN
oPrn:Box( 0480, 1650, nLinMaxIte,1790,"-5") 		// Qtde
oPrn:Box( 0480, 1790, nLinMaxIte,2050,"-5") 		// Valor Total
oPrn:Box( 0480, 2050, nLinMaxIte,2160,"-5") 		// ICM
oPrn:Box( 0480, 2160, nLinMaxIte,2300,"-5") 		// IPI
oPrn:Box( 0480, 2300, nLinMaxIte,2490,"-5") 		// Valor Uni
oPrn:Box( 0480, 2490, nLinMaxIte,2620,"-5") 		// Dt Entr
oPrn:Box( 0480, 2620, nLinMaxIte,2810,"-5") 		// Centro Custo
oPrn:Box( 0480, 2810, nLinMaxIte,2920,"-5") 		// Solic.

dbSelectArea("SA2")
dbSetOrder(1)
dbSeek(xFilial("SA2")+SC7->C7_FORNECE+SC7->C7_LOJA)

// Titulo                       
If SC7->C7_TIPO==1
	oPrn:Say( 0130, 0955, "P E D I D O   D E   C O M P R A S"                  , oFont1, 50 )
Else
	oPrn:Say( 0130, 0955, "A U T O R I Z A Ç Ã O   D E   E N T R E G A"        , oFont1,100 )
EndIf

// Numero do pedido
oPrn:Say( 0120, 2650, "FOLHA:" ,oFont3,100 )
oPrn:Say( 0120, 2790, AllTrim(StrZero(nPag,2))+"/"+AllTrim(StrZero(nTotPag,2)) , oFont3,100 )
oPrn:Say( 0235, 2360, "Nº "            + SC7->C7_NUM                           , oFont7,100 )
oPrn:Say( 0220, 2550, Str(nReem) + "º Via"                                     , oFont5,100 )
oPrn:Say( 0315, 2360, "DATA EMISSÃO: " + DtoC(SC7->C7_EMISSAO)                 , oFont6,100 )
oPrn:Say( 0350, 2360, "PEDIDO: "       + cAprov                                , oFont6,100 )
// oPrn:Say( 0350, 2820, cAprov,oFont5,100 )

// --> Incluso  LAVOR/PROX  15/06/2021   (*INICIO*) 
If lMedicao  
	cFil := SC7->C7_FILCRT    
	If Empty(SC7->C7_FILCRT)
		cFil := SC7->C7_FILIAL 
	EndIf           
	nRec := SC7->(Recno())
    dbSelectArea("CND")
    dbSetOrder(1)
    If dbSeek(cFil+SC7->(C7_CONTRA+C7_CONTREV+Space(TamSx3("CND_NUMERO")[1])+C7_MEDICAO))
		oPrn:Say( 0380, 2360, "COMPETÊNCIA: " + CND->CND_COMPET,        oFont6,100 )
	EndIf   
EndIf
// --> Incluso  LAVOR/PROX  15/06/2021   (*FINAL* ) 

// Dados da empresa coluna 1
oPrn:Say( 0210, 0060, "EMPRESA: "      + aDadEmp[01]                           , oFont6,100 )
oPrn:Say( 0245, 0060, "CNPJ/CPF"+" "   + Transform(aDadEmp[04],cCgcPict)       , oFont6,100 ) 
oPrn:Say( 0280, 0060, "ENDEREÇO: "     + SubStr(Upper(aDadEmp[06]),1,25)       , oFont6,100 )
oPrn:Say( 0315, 0060, "BAIRRO: "       + Upper(SubStr(aDadEmp[07],1,25))       , oFont6,100 )
oPrn:Say( 0350, 0060, Upper("CEP: "    + Transform(aDadEmp[10],cCepPict))      , oFont6,100 )
oPrn:Say( 0385, 0060, "TEL: "          + aDadEmp[02]                           , oFont6,100 )

// Dados da empresa coluna 2
oPrn:Say( 0245, 0610, "IE: "           + aDadEmp[05]                           , oFont6,100 )
oPrn:Say( 0315, 0610, Upper(Trim(aDadEmp[08])+" - "+aDadEmp[09])               , oFont6,100 )
oPrn:Say( 0385, 0610, "FAX: "          + aDadEmp[03]                           , oFont6,100 )

// Dados do fornecedor coluna 1
oPrn:Say( 0210, 0950, "FORNECEDOR: "   + AllTrim(SubStr(SA2->A2_NOME,1,40))+" - ("+SA2->A2_COD+")" , oFont6,100 )
oPrn:Say( 0245, 0950, "CNPJ: "         + Transform(SA2->A2_CGC,cCgcPict)       , oFont6,100 )
oPrn:Say( 0280, 0950, "ENDEREÇO: "     + Upper(SubStr(SA2->A2_END,1,40))       , oFont6,100 )
oPrn:Say( 0315, 0950, "CEP: "          + SA2->A2_CEP                           , oFont6,100 )
oPrn:Say( 0350, 0955, "FONE: " + "("+SubStr(SA2->A2_DDD,1,3)+") "+SubStr(SA2->A2_TEL,1,15) , oFont6,100 )

// Dados do fornecedor coluna 2
oPrn:Say( 0245, 1950, "IE: "           + SA2->A2_INSCR                         , oFont6,100 )
oPrn:Say( 0280, 1950, "BAIRRO: "       + SubStr(SA2->A2_BAIRRO,1,25)           , oFont6,100 )
oPrn:Say( 0315, 1950, Upper(Trim(SA2->A2_MUN)+" - "+SA2->A2_EST)               , oFont6,100 )
oPrn:Say( 0350, 1950, "FAX: " + "("+SubStr(SA2->A2_DDD,1,3)+") "+SA2->A2_FAX   , oFont6,100 )
oPrn:Say( 0385, 1950, "VENDEDOR: "     + Upper(SubStr(SC7->C7_CONTATO,1,25))   , oFont6,100 )

// Titulos
oPrn:Say( 0465, 0050, "Item"                               , oFont3,100 )
oPrn:Say( 0465, 0135, "Código"                             , oFont3,100 )
oPrn:Say( 0465, 0350, "Descrição do Material e/ou Serviço" , oFont3,100 )
oPrn:Say( 0465, 1200, "Observações"                        , oFont3,100 )
oPrn:Say( 0465, 1555, "UN"                                 , oFont3,100 )
oPrn:Say( 0465, 1660, "Qtde"                               , oFont3,100 )
oPrn:Say( 0465, 1800, "Valor Unit."                        , oFont3,100 )
oPrn:Say( 0465, 2060, "ICM%"                               , oFont3,100 )
oPrn:Say( 0465, 2170, "IPI%"                               , oFont3,100 )
oPrn:Say( 0465, 2310, "Valor Total"                        , oFont3,100 )
oPrn:Say( 0465, 2500, "Dt Entr"                            , oFont3,100 )
oPrn:Say( 0465, 2630, "Centro C."                          , oFont3,100 )
oPrn:Say( 0465, 2820, "SC"                                 , oFont3,100 )

cSubject := "Pedido de Compras nr."+SC7->C7_NUM+" / "+AllTrim(Left(SA2->A2_NOME,30))

ConOut("##_MCCOMR01.prw - Relato() - ImpCabec() - #FINAL#   - - - - - - - - -") 

Return .T.



/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ ImpProd   ³ Autor ³ Wagner Xavier      ³ Data ³            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Pesquisar e imprimir  dados Cadastrais do Produto.         ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ImpProd(Void)                                              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MatR110                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ImpProd()

Local cDesc , nLinRef := 0 , nBegin := 0 , cDescri := "" , nLinha := 0 , ; 
      nTamDesc := 50 , aColuna := {} 

cDesc   := "" 
nLinRef := 1 
aColuna := Array(8) 

// --> Impressao da descricao generica do Produto. 
cObs    := AllTrim(SC7->C7_OBS)
cDescri := AllTrim(SC7->C7_DESCRI)

If SC7->( FieldPos("C7_DESCRIC") ) > 0 .And. ! Empty(SC7->C7_DESCRIC)		// Cristiam
	cDescri += " " + AllTrim(SC7->C7_DESCRIC)
EndIf

If SC7->( FieldPos("C7_ZOBSUS1") ) > 0 .And. ! Empty(SC7->C7_ZOBSUS1)		// Cristiam
	cDescri += " " + AllTrim(SC7->C7_ZOBSUS1)
EndIf

If SC7->( FieldPos("C7_ZOBSUS2") ) > 0 .And. ! Empty(SC7->C7_ZOBSUS2)		// Cristiam
	cDescri += " " + AllTrim(SC7->C7_ZOBSUS2)
EndIf

SB1->( dbSetOrder(1) )
If SB1->( dbSeek( xFilial("SB1") + SC7->C7_PRODUTO ) )
	If SB1->( FieldPos("B1_YDSCOMP") ) > 0 .And. ! Empty(SB1->B1_YDSCOMP)	// Cristiam
		cDescri := AllTrim(cDescri) + " - Desc. Completa: " + AllTrim(SB1->B1_YDSCOMP)
	EndIf
EndIf

dbSelectArea("SC7")
nLinhaD := MLCount(cDescri,nTamDesc)
nLinhaO := MLCount(cObs,20)
nLinha  := Iif(nLinhaD>nLInhaO , nLinhaD , nLinhaO)
oPrn:Say( li, 0350, MemoLine(cDescri,nTamDesc,1)            , oFont6,100 )
oPrn:Say( li, 1200, Iif(nLinhaO>0 , MemoLine(cObs,20,1),"") , oFont6,100 )

ImpCampos()

For nBegin := 2 To nLinha
	li+=35
	If nLinhaD>=nBegin
		oPrn:Say( li, 0350, MemoLine(cDescri,nTamDesc,nBegin) ,oFont6,100 )
	EndIf
	If nLinhaO>=nBegin
		oPrn:Say( li, 1200, MemoLine(cObs,20,nBegin),oFont6,100 )
	EndIf
Next nBegin

Return Nil 



/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ ImpCampos ³ Autor ³ Wagner Xavier      ³ Data ³            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Imprimir dados Complementares do Produto no Pedido.        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ImpCampos(Void)                                            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MatR110                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ImpCampos()

dbSelectArea("SC7") 
     
//	Unidade
If nParam5 == 2 .And. !Empty(SC7->C7_SEGUM)
	oPrn:Say( li, 1555, SC7->C7_SEGUM ,oFont6,100 )
Else
	oPrn:Say( li, 1555, SC7->C7_UM    ,oFont6,100 )
EndIf             

// Quantidade
If nParam5 == 2 .And. !Empty(SC7->C7_QTSEGUM) 
	If !lAux
		oPrn:Say( li,1660, Transform(SC7->C7_QTSEGUM,"@E 999,999.99") ,oFont6,100 )
	Else
		oPrn:Say( li,1660, Transform(SC7->C7_QUJE   ,"@E 999,999.99") ,oFont6,100 )   
	EndIf 
Else
	If !lAux 
		oPrn:Say( li,1660, Transform(SC7->C7_QUANT  ,"@E 999,999.99") ,oFont6,100 )
	Else 
		oPrn:Say( li,1660, Transform(SC7->C7_QUJE   ,"@E 999,999.9" ) ,oFont6,100 )   
	EndIf 
EndIf                                       

// Valor Unitario
If nParam5 == 2 .And. !Empty(SC7->C7_QTSEGUM)  
	If !lAux
		oPrn:Say( li, 1800, Transform(xMoeda((SC7->C7_TOTAL/SC7->C7_QTSEGUM),SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF),PesqPict("SC7","C7_PRECO",14, nParam7)) ,oFont6,100 )
	Else 
		oPrn:Say( li, 1800, Transform(xMoeda((SC7->C7_PRECO),SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF),PesqPict("SC7","C7_PRECO",14, nParam7)) ,oFont6,100 )   
	EndIf    
Else
	oPrn:Say( li, 1800, Transform(SC7->C7_PRECO,"@E 9,999,999.99") ,oFont6,100 )
EndIf

// ICM
//oPrn:Say(li,2250, Transform(SC7->C7_PICM , "@E 99.9") , oFont6,100 ) 		// Excluido solicitado pelo chamado 15666

// IPI
oPrn:Say( li, 2170, Transform(SC7->C7_IPI  , "@E 99.9") , oFont6,100 ) 

// Valor Total
If !lAux 
	oPrn:Say( li, 2310, Transform(SC7->C7_TOTAL               ,"@E 9,999,999.99") ,oFont6,100 )
Else
	oPrn:Say( li, 2310, Transform(SC7->C7_PRECO * SC7->C7_QUJE,"@E 9,999,999.99") ,oFont6,100 )
EndIf

 oPrn:Say( li, 2500, DtoC(SC7->C7_DATPRF) ,oFont6,100 )

// Centro de Custo
oPrn:Say( li, 2630, Transform(SC7->C7_CC,"@E 9999999999") ,oFont6,100 )
// Solic.
oPrn:Say( li, 2820, SC7->C7_NUMSC ,oFont6,100 )

//nTotal := nTotal + Iif(!lAux , SC7->C7_TOTAL , SC7->C7_PRECO * SC7->C7_QUJE) 
nTotal   := nTotal + SC7->C7_TOTAL

nTotMerc := nTotal 						// MaFisRet(,"NF_TOTAL") -> antes
nTotDesc += SC7->C7_VLDESC 

If lAux 
	nValIPI  += (SC7->C7_VALIPI/SC7->C7_QUANT) * SC7->C7_QUJE 
Else 
	nValIPI  +=  SC7->C7_VALIPI 
EndIf 

// --> Incluso  LAVOR/PROX 11/05/2021   (*INICIO*)
// --> Novo calculo FRETE   - Em substituição do MaFisRet() 
If lAux 
	nNewFret += (SC7->C7_VALFRE /SC7->C7_QUANT) * SC7->C7_QUJE 
Else 
	nNewFret +=  SC7->C7_VALFRE 
EndIf 
// --> Novo calculo DESPESA - Em substituição do MaFisRet() 
If lAux 
	nNewDesp += (SC7->C7_DESPESA/SC7->C7_QUANT) * SC7->C7_QUJE 
Else 
	nNewDesp +=  SC7->C7_DESPESA 
EndIf 
// --> Novo calculo SEGURO  - Em substituição do MaFisRet() 
If lAux 
	nNewSegu += (SC7->C7_SEGURO /SC7->C7_QUANT) * SC7->C7_QUJE 
Else 
	nNewSegu +=  SC7->C7_SEGURO  
EndIf 
// --> Incluso  LAVOR/PROX 11/05/2021   (*FINAL* )


lAux := .F. 

Return .T.  



/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ ImpRodape ³ Autor ³Leandro Eber Ribeiro³ Data ³            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Imprime o rodape do formulario e salta para a proxima folha³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ ImpRodape(Void)   			         					  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MatR110                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ImpRodape()

oPrn:Say( 1650, 1810, "***************  CONTINUA  ***************" ,oFont3,100 )
nPag++

Return .T. 



/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³ FinalPed  ³ Autor ³Leandro Eber Ribeiro³ Data ³            ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Imprime os dados complementares do Pedido de Compra        ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ FinalPed(Void)                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MatR110                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function FinalPed(aDadEmp)

Local nK         := 1
Local nG         := 0 
Local nQuebra    := 0
Local lNewAlc	 := .F.
Local lLiber 	 := .F.
Local lImpLeg	 := .T.
Local cComprador := ""
Local cAlter     := ""
Local cAprova	 := ""
Local cCompr     := ""
Local cEmail     := ""
Local cTele      := ""
Local cObsPe     := ""
Local aColuna    := {} 
Local nTotLinhas := 0 
Local nTotIPI	 := nValIPI
Local nTotIcms	 := 0
Local nTotDesp	 := MaFisRet(,'NF_DESPESA')
Local nTotFrete  := 0					// MaFisRet(,'NF_FRETE')
Local nTotalNF	 := MaFisRet(,'NF_TOTAL'  )
Local nTotSeguro := MaFisRet(,'NF_SEGURO' )
Local aValIVA    := MaFisRet(,"NF_VALIMP" )
Local cTPFrete
Local c_xC7FIL   := "" 

// --> Incluso  LAVOR/PROX 11/05/2021   (*INICIO*) 
Local nTNewFre   := nNewFret 
Local nTNewDsp   := nNewDesp 
Local nTNewSeg   := nNewSegu 

// ticket 22804 - SELFIT - Retirar determinadas linhas do email e da impressão do pedido de compras
Local _dDtLimite := Ctod("30/03/2022") // se emitido após esta data deve eliminar as mensagens informadas no ticket

nTotDesp   := nTNewDsp 
nTotSeguro := nTNewSeg 
// --> Incluso  LAVOR/PROX 11/05/2021   (*FINAL* ) 

nK         := 1
nQuebra    := 0
lNewAlc    := .F.
lLiber     := .F.
lImpLeg    := .T.
cComprador := ""
cAlter     := ""
aColuna    := Array(8) 
nTotLinhas := 0 
nTotalNF   := nTotalNF  

// Rodape
oPrn:Box( nLinMaxIte, 0040, nLinMaxIte + 100,2250,"-5") 			// Desconto
oPrn:Box( nLinMaxIte, 2250, nLinMaxIte + 100,2920,"-5") 			// Sub Total  

oPrn:Box( nLinMaxIte + 100, 0040, nLinMaxIte + 200,0800,"-5") 		// Impostos IPI
oPrn:Box( nLinMaxIte + 100, 0800, nLinMaxIte + 200,1500,"-5") 		// Impostos Frete
oPrn:Box( nLinMaxIte + 100, 1500, nLinMaxIte + 200,2250,"-5") 		// Impostos Pagto
oPrn:Box( nLinMaxIte + 100, 2250, nLinMaxIte + 200,2920,"-5") 		// Total S IMpostos

oPrn:Box( nLinMaxIte + 200, 0040, nLinMaxIte + 350,1500,"-5") 		// Endereco
oPrn:Box( nLinMaxIte + 200, 1500, nLinMaxIte + 350,2250,"-5") 		// Comprador
oPrn:Box( nLinMaxIte + 200, 2250, nLinMaxIte + 350,2920,"-5") 		// Total geral

oPrn:Box( nLinMaxIte + 350, 0040, nLinMaxIte + 590,2920,"-5") 		// 2130 Obs Finais   

If cPaisLoc <> "BRA"  .And.  !Empty(aValIVA) 
	For nG:=1 To Len(aValIVA) 
		nValIVA += aValIVA[nG] 
	Next nG 
EndIf 

If AtIsRotina("U_SFCMP06A") 
	c_xC7FIL := SC7->C7_FILIAL 
	ConOut("##_MCCOMR01.prw - Relato() - FinalPed() -- Via: U_SFCMP06A() -- c_xC7FIL: ["+c_xC7FIL+"] -- SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] ") 
Else 
	c_xC7FIL := xFilial("SC7") 
	If AtIsRotina("U_SFCMP06") 
		ConOut("##_MCCOMR01.prw - Relato() - FinalPed() -- Via: U_SFCMP06() -- c_xC7FIL: ["+c_xC7FIL+"] -- SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] ") 
	EndIf 
EndIf 
   
// Seleciona o Aprovador se existir
dbSelectArea("SCR")
dbSetOrder(1)
/*	// --> Alterado DE..: 
dbSeek(xFilial("SC7") + "PC" + SC7->C7_NUM) 
*/	// --> Alterado PARA: 
dbSeek(c_xC7FIL       + "PC" + SC7->C7_NUM) 
//	// --> Alterado FINAL 

/*	// --> Alterado DE..: 
While !Eof()  .And.  SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)==xFilial("SC7")+SC7->C7_NUM  .And.  SCR->CR_TIPO == "PC" 
*/	// --> Alterado PARA: 
While !Eof()  .And.  SCR->CR_FILIAL+AllTrim(SCR->CR_NUM)==c_xC7FIL      +SC7->C7_NUM  .And.  SCR->CR_TIPO == "PC" 
//	// --> Alterado FINAL 
	If SCR->CR_STATUS == "03"
		//TODO Migração de dicionario não permite mais o loop - UsrFullName(SCR->CR_USER): tranpondo para função statica
		//AllTrim(UsrFullName(SCR->CR_USER))
		cAprova += GetAllName(SCR->CR_USER) 
	EndIf
	dbSelectArea("SCR")
	dbSkip()
EndDo  

cAprova := "Não Aprovado"     

// --> Incluso  LAVOR/PROX  15/06/2021   (*INICIO*)
If lMedicao 
	cFil := SC7->C7_FILCRT    
	If Empty(SC7->C7_FILCRT)
		cFil := SC7->C7_FILIAL 
	EndIf 
	dbSelectArea("CN9") 
	dbSetOrder(1) 
	If dbSeek(cFil+SC7->(C7_CONTRA+C7_CONTREV))  .And.  !Empty(CN9->CN9_USRCMP) 
		// Seleciona o Comprador 
		cCompr  := Left(UsrFullName(CN9->CN9_USRCMP),20) 
		cObsPe  := SC7->C7_OBS 
		cEmail  := AllTrim(UsrRetMail(CN9->CN9_USRCMP)) 
		cTele   := Posicione("SY1" , 3 , xFilial("SY1")+CN9->CN9_USRCMP , "Y1_TEL"  ) 
	Else 
		cCompr  := Left(UsrFullName(SC7->C7_USER),20) 
		cObsPe  := SC7->C7_OBS 
		cEmail	:= Posicione("SY1" , 3 , xFilial("SY1")+SC7->C7_USER    , "Y1_EMAIL") 
		cTele	:= Posicione("SY1" , 3 , xFilial("SY1")+SC7->C7_USER    , "Y1_TEL"  ) 
	EndIf 
Else 
// --> Incluso  LAVOR/PROX  15/06/2021   (*FINAL* )
	// Seleciona o Comprador
	cCompr      := Left(UsrFullName(SC7->C7_USER),20)
	cObsPe      := SC7->C7_OBS                                         
	cEmail	    := Posicione("SY1" , 3 , xFilial("SY1")+SC7->C7_USER    , "Y1_EMAIL")
	cTele	    := Posicione("SY1" , 3 , xFilial("SY1")+SC7->C7_USER    , "Y1_TEL"  )
// --> Incluso  LAVOR/PROX  15/06/2021   (*INICIO*)
EndIf 
// --> Incluso  LAVOR/PROX  15/06/2021   (*FINAL* )

//nTotIPI	 := SC7->C7_VALIPI
//nTotIcms	 := SC7->C7_VALICM
//nTotDesp	 := SC7->C7_DESPESA
//nTotalNF	 := SC7->C7_TOTAL
//nTotSeguro := SC7->C7_SEGURO
//aValIVA    := SC7->C7_VALIMP

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Impressso de Descontos Logo abaixo dos itens                 ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
oPrn:Say( nLinMaxIte + 60, 0420, "D E S C O N T O -->" ,oFont3,100 ) 

oPrn:Say( nLinMaxIte + 60, 0850, Transform(SC7->C7_DESC1,"@E999.99")+" %" ,oFont4,100 )
oPrn:Say( nLinMaxIte + 60, 0950, Transform(SC7->C7_DESC2,"@E999.99")+" %" ,oFont4,100 )
oPrn:Say( nLinMaxIte + 60, 1050, Transform(SC7->C7_DESC3,"@E999.99")+" %" ,oFont4,100 ) 
                                                      
// Aglutina os desconto de itens com do pedido
//nTotDesc += SC7->C7_DESC1+SC7->C7_DESC1+SC7->C7_DESC1 

oPrn:Say( nLinMaxIte + 60, 1300, Transform(xMoeda(nTotDesc,SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF),PesqPict("SC7","C7_VLDESC",14, nParam7)) ,oFont4,100 )

dbSelectArea("SM4")
dbSetOrder(1)

dbSelectArea("SC7") 

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³ Impressso de dos impostos                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
If SC7->C7_TPFRETE == "C"
	cTPFrete   := "CIF" 
	nTotFrete2 := MaFisRet(,'NF_FRETE') 
	nTotFrete  := MaFisRet(,'NF_FRETE') 
	nTotFrete2 := nTNewFre  			// --> Incluso  LAVOR/PROX 11/05/2021 
	nTotFrete  := nTNewFre  			// --> Incluso  LAVOR/PROX 11/05/2021 
Else
	cTPFrete   := "FOB" 
	nTotFrete2 := MaFisRet(,'NF_FRETE') 
	nTotFrete  := 0 
	nTotFrete2 := nTNewFre 				// --> Incluso  LAVOR/PROX 11/05/2021 
	nTotFrete  := 0  					// --> Incluso  LAVOR/PROX 11/05/2021 
EndIf

// Primeira Caixa de Impostos
oPrn:Say( nLinMaxIte + 140, 0060, "IPI :"                 , oFont3,100 )
oPrn:Say( nLinMaxIte + 140, 0200, Transform(xMoeda(nTotIPI ,SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF)            , Tm(nTotIPI  ,14,MsDecimais(nParam7))) , oFont4c,100 )
oPrn:Say( nLinMaxIte + 180, 0060, "ICMS :"                , oFont3,100 )
oPrn:Say( nLinMaxIte + 180, 0200, Transform(xMoeda(nTotIcms,SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF)            , Tm(nTotIcms ,14,MsDecimais(nParam7))) , oFont4c,100 )

// Segunda Caixa de Impostos
oPrn:Say( nLinMaxIte + 140, 0820, "Frete + Despesas:"     , oFont3 ,100 )
oPrn:Say( nLinMaxIte + 140, 1100, Transform(xMoeda(nTotFrete2+nTotDesp,SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF) , Tm(nTotFrete,14,MsDecimais(nParam7))) , oFont4c,100 )
oPrn:Say( nLinMaxIte + 180, 0820, "Obs. Frete :"          , oFont3 ,100 )
oPrn:Say( nLinMaxIte + 180, 1100, AllTrim(cTPFrete)       , oFont4c,100 )

// Terceira Caixa de Impostos
dbSelectArea("SE4")
dbSetOrder(1)
dbSeek("    "+SC7->C7_COND)     		// Tabela de Condição de pagamentos compartilhada
dbSelectArea("SC7")

oPrn:Say( nLinMaxIte + 140, 1520, "Condição de Pagto :"   , oFont3,100 )
oPrn:Say( nLinMaxIte + 140, 1850, AllTrim(SE4->E4_DESCRI) , oFont6,100 )
oPrn:Say( nLinMaxIte + 180, 1520, "Seguro :"              , oFont3,100 )
oPrn:Say( nLinMaxIte + 180, 1850, Transform(xMoeda(nTotSeguro,SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF) , Tm(nTotSeguro,14,MsDecimais(nParam7))) , oFont6,100 )

oPrn:Say( nLinMaxIte +  60, 2270, "SUB TOTAL: "           , oFont3,100 )
oPrn:Say( nLinMaxIte +  55, 2550, Transform(xMoeda(nTotal    ,SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF) , Tm(nTotal    ,14,MsDecimais(nParam7))) , oFont6,100 )

oPrn:Say( nLinMaxIte + 270 , 0060, "Local de Entrega  : " , oFont3,100 )

//Verifica se foi digitado algo no local de entrega
If Empty(AllTrim(cPedEntr))
	oPrn:Say( nLinMaxIte + 270 , 0420, AllTrim(SubStr(aDadEmp[06],1,30))+" - "+ AllTrim(SubStr(aDadEmp[07],1,10))+" - "+AllTrim(SubStr(aDadEmp[08],1,10))+" / "+aDadEmp[09]+ " - "+Upper("CEP: "+Trans(aDadEmp[10],cCepPict)) , oFont6,100 )
Else  
	oPrn:Say( nLinMaxIte + 270 , 0420, Upper(AllTrim(cPedEntr))         , oFont6,100 )            
EndIf	

oPrn:Say( nLinMaxIte + 330 , 0060, "Local de Cobrança  : "              , oFont3,100 )
oPrn:Say( nLinMaxIte + 330 , 0420, AllTrim(SubStr(aDadEmp[11],1,30))+" - "+AllTrim(SubStr(aDadEmp[12],1,10))+" - "+AllTrim(SubStr(aDadEmp[13],1,10))+" / "+aDadEmp[14]+ " - "+Upper("CEP: "+Trans(aDadEmp[15],cCepPict)) , oFont6,100 )

oPrn:Say( nLinMaxIte + 140 , 2270, "TOTAL S/ IMP.: "                    , oFont3,100 )
oPrn:Say( nLinMaxIte + 140 , 2580, Transform(xMoeda((nTotal+nTotFrete+nTotDesp+nTotSeguro)-(nTotDesc+nTotIcms),SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF) , Tm((nTotal+nTotFrete+nTotDesp+nTotSeguro)-(nTotDesc+nTotIcms),14,MsDecimais(nParam7))) , oFont6 ,100 )

oPrn:Say( nLinMaxIte + 280 , 2270, "TOTAL GERAL: "                      , oFont9,100 )
oPrn:Say( nLinMaxIte + 280 , 2450, Transform(xMoeda((nTotal+nTotFrete+nTotDesp+nTotSeguro+nTotIPI)-nTotDesc,SC7->C7_MOEDA,nParam7,SC7->C7_DATPRF)    , Tm((nTotal+nTotFrete+nTotDesp+nTotSeguro+nTotIPI)-nTotDesc,14,MsDecimais(nParam7)))    , oFont9c,100 )

oPrn:Say( nLinMaxIte + 230 , 1520, "COMPRADOR: "                        , oFont5,100 )
oPrn:Say( nLinMaxIte + 230 , 1850, Upper(AllTrim(cCompr))               , oFont6,100 )
//oPrn:Say( nLinMaxIte+280 , 1750, "E-MAIL: "                           , oFont5,100 )
oPrn:Say( nLinMaxIte + 280 , 1520, "E-MAIL: "                           , oFont5,100 )
oPrn:Say( nLinMaxIte + 280 , 1850, Upper(AllTrim(cEmail))               , oFont6,100 ) 
oPrn:Say( nLinMaxIte + 330 , 1520, "TEL: "                              , oFont5,100 )
oPrn:Say( nLinMaxIte + 330 , 1850, TransForm(cTele, "@R (99)9999.9999") , oFont6,100 ) 

// efetuado backup por Fernando Lins e esta na pasta: D:\Totvs 12\Microsiga\Protheus\Projeto\Relatorios
// backup foi efetuado em 21-03-2018 para atendimento ao chamado: 56606 - de Jessica Melo.
// Linhas Originas antes das alterações:
// ---------------------------------------------------------------------------------------------------------                                                     
// oPrn:Say( nLinMaxIte + 470 , 0040,  " NOTAS: ",oFont7,100 )
// oPrn:Say( nLinMaxIte + 420 , 0265,  "1) Horário de recebimento de segunda à sexta feira de 08h às 16h30.",oFont4,100 ) 
// oPrn:Say( nLinMaxIte + 470 , 0265,  "2) É obrigatório constar o Nº e Item deste pedido na NOTA FISCAL, sob pena de não ser aceita a mercadoria e/ou serviço.",oFont4,100 ) 
// oPrn:Say( nLinMaxIte + 520 , 0265,  "3) Não serão aceitas entregas em desconformidade com as condições expressas neste Pedido de Compras.",oFont4,100 )
// oPrn:Say( nLinMaxIte + 570 , 0265,  "4) Toda nota fiscal emitida entre os dias 25 e 31 do mês atual, o fornecedor OBRIGATÓRIAMENTE deverá emitir a NF com data do primeiro dia do mês subseqüente.",oFont4,100 )
// oPrn:Say( nLinMaxIte + 620 , 0265,  "5) Produtos quimicos e reagentes não serão recebidos sem os respectivos CERTIFICADOS DE QUALIDADE.",oFont4,100 )
// ---------------------------------------------------------------------------------------------------------

//  Alterardo abaixo por Fernando Lins em 21-03-2018 - Inicio 
oPrn:Say( nLinMaxIte + 450 , 0040,  " NOTAS: ",oFont7,100 )
oPrn:Say( nLinMaxIte + 400 , 0265,  "1) É obrigatório constar o Nº e Item deste pedido na NOTA FISCAL, sob pena de não ser aceita a mercadoria e/ou serviço.",oFont4,100 ) 
oPrn:Say( nLinMaxIte + 450 , 0265,  "2) Não serão aceitas entregas em desconformidade com as condições expressas neste Pedido de Compras.",oFont4,100 ) 
//  Alterardo abaixo por Fernando Lins em 21-03-2018 - Termino

// ticket 22804 - SELFIT - Retirar determinadas linhas do email e da impressão do pedido de compras
// Verifica se os pedidos foram emitidos após o inicio da nova regra
if SC7->C7_EMISSAO <= _dDtLimite 	// a alteração deve ocorrer somente se o pedido foi emitido antes de determinada data
	oPrn:Say( nLinMaxIte + 500 , 0265,  "3) Notas Fiscais de Serviço só poderão ser emitidas até o dia 23 de cada mês, caso contrário, a nota fiscal não será lançada e não seguirá para pagamento.",oFont4,100 )
	oPrn:Say( nLinMaxIte + 550 , 0265,  "4) Produtos quimicos e reagentes não serão recebidos sem os respectivos CERTIFICADOS DE QUALIDADE.",oFont4,100 )
Else	
	oPrn:Say( nLinMaxIte + 500 , 0265,  "3) Produtos quimicos e reagentes não serão recebidos sem os respectivos CERTIFICADOS DE QUALIDADE.",oFont4,100 )
Endif	

Return .T.



/*/
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³ Funcao   ³ VALIDPERG ³ Autor ³ Adalberto Moreno B.³ Data ³ 11/02/2000 ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function ValidPerg()

Local _aAlias := Alias() , aRegs 
Local i := 0 
Local j := 0 

dbSelectArea("SX1")
dbSetOrder(1)
aRegs:={}
// Grupo/Ordem/Pergunta/Variavel/Tipo/Tamanho/Decimal/Presel/GSC/Valid/Var01/Def01/Cnt01/Var02/Def02/Cnt02/Var03/Def03/Cnt03/Var04/Def04/Cnt04/Var05/Def05/Cnt05
aAdd(aRegs,{cPerg,"01","Do Pedido ?"          , "¿De Pedido?"          , "From Order ?"          , "mv_ch1","C",6,0,0,"G","","MV_PAR01","","","","000001","","","","","","","","","","","","","","","","","","","","","","S","",""})
aAdd(aRegs,{cPerg,"02","Até o Pedido ?"       , "¿A  Pedido?"          , "To Order ?"            , "mv_ch2","C",6,0,0,"G","","MV_PAR02","","","","000001","","","","","","","","","","","","","","","","","","","","","","S","",""})
aAdd(aRegs,{cPerg,"03","A partir da Data ?"   , "¿De Fecha?"           , "From Date ?"           , "mv_ch3","D",8,0,0,"G","","mv_par03","","","","'01/01/2016'","","","","","","","","","","","","","","","","","","","","","","S","",""})
aAdd(aRegs,{cPerg,"04","Até a Data ?"         , "¿A  Fecha?"           , "To Date ?"             , "mv_ch4","D",0,0,0,"G","","mv_par04","","","","'31/12/2016'","","","","","","","","","","","","","","","","","","","","","","S","",""})
aAdd(aRegs,{cPerg,"05","Qual Unid. de Med. ?" , "¿Cual Unidad Medida?" , "Which Unit of Meas. ?" , "mv_ch5","N",1,0,1,"C","","mv_par05","Primaria","Primaria","Primary","","","Secundaria","Secundaria","Secondary","","","","","","","","","","","","","","","","","","S","",""})
aAdd(aRegs,{cPerg,"06","Numero de Vias ?"     , "¿Numero de Copias?"   , "Number of Copies ?"    , "mv_ch6","N",2,0,0,"G","","mv_par06","","",""," 1","","","","","","","","","","","","","","","","","","","","","","S","",""})
aAdd(aRegs,{cPerg,"07","Qual Moeda ?"         , "¿Cual Moneda?"        , "Currency ?"            , "mv_ch7","N",1,0,1,"C","","mv_par07","Moeda 1","Moneda 1","Currency 1","","","Moeda 2","Moneda 2","Currency 2","","","Moeda 3","Moneda 3","Currency 3","","","Moeda 4","Moneda 4","Currency 4","","","Moeda 5","Moneda 5","Currency 5","","","S","",""})

For i:=1 To Len(aRegs)
   //	If !dbSeek(cPerg+aRegs[i,2])  
    If SX1->( !MsSeek(PadR(cPerg,10)+aRegs[i,2]) )
		RecLock("SX1",.T.)
		For j:=1 To FCount()
			If j <= Len(aRegs[i])
				FieldPut(j,aRegs[i,j])
			EndIf
		Next
		MsUnLock()
	EndIf
Next

dbSelectArea(_aAlias)   

Return




/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Funcao    ³R110FIniPC ³ Autor ³ Edson Maricate     ³ Data ³ 20/05/2000 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descricao ³ Inicializa as funcoes Fiscais com o Pedido de Compras      ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ R110FIniPC(ExpC1,ExpC2)                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 := Numero do Pedido                                  ³±±
±±³          ³ ExpC2 := Item do Pedido                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATR110,MATR120,Fluxo de Caixa                             ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function R110FIniPC(cPedido , cItem , cSequen , cFiltro) 

Local aArea     := GetArea()
Local aAreaSC7  := SC7->(GetArea())
Local cValid    := ""
Local nPosRef   := 0
Local nItem     := 0
Local cItemDe   := Iif(cItem==Nil , ""                               , cItem) 
Local cItemAte  := Iif(cItem==Nil , Replicate("Z",Len(SC7->C7_ITEM)) , cItem) 
Local cRefCols  := ""
Local c_xC7FIL  := "" 

// TODO novos campos para migração de dicionario
Local lOpen     := .F.                                             	// VALIDAÇÃO DE ABERTURA DE TABELA
Local cAlias    := GetNextAlias()                                  	// APELIDO DO ARQUIVO DE TRABALHO
Local cFilter   := cAlias + "->" + "X3_ARQUIVO" + " == " + "'SC7'" 	// FILTRO PARA A TABELA SX3
Local _aXHeader := GetColumns()

Default cSequen := "" 
Default cFiltro := "" 

If AtIsRotina("U_SFCMP06A") 
	c_xC7FIL := SC7->C7_FILIAL 
	ConOut("##_MCCOMR01.prw - Relato() - R110FIniPC() -- Via: U_SFCMP06A() -- c_xC7FIL: ["+c_xC7FIL+"] -- SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] ") 
Else 
	c_xC7FIL := xFilial("SC7") 
	If AtIsRotina("U_SFCMP06") 
		ConOut("##_MCCOMR01.prw - Relato() - R110FIniPC() -- Via: U_SFCMP06() -- c_xC7FIL: ["+c_xC7FIL+"] -- SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] ") 
	EndIf 
EndIf 

dbSelectArea("SC7") 
dbSetOrder(1) 
/*	// --> Alterado DE..: 
If dbSeek(xFilial("SC7") + cPedido + cItemDe + AllTrim(cSequen)) 
*/	// --> Alterado PARA: 
If dbSeek(c_xC7FIL       + cPedido + cItemDe + AllTrim(cSequen)) 
//	// --> Alterado FINAL 
	MaFisEnd() 
	MaFisIni(SC7->C7_FORNECE , SC7->C7_LOJA , "F" , "N" , "R" , {}) 

/*	// --> Alterado DE..: 
	While !Eof() .And. SC7->C7_FILIAL+SC7->C7_NUM == xFilial("SC7")+cPedido  .And.  ; 
                       SC7->C7_ITEM <= cItemAte  .And.  (Empty(cSequen) .Or. cSequen == SC7->C7_SEQUEN) 
*/	// --> Alterado PARA: 
	While !Eof() .And. SC7->C7_FILIAL+SC7->C7_NUM == c_xC7FIL      +cPedido  .And.  ; 
                       SC7->C7_ITEM <= cItemAte  .And.  (Empty(cSequen) .Or. cSequen == SC7->C7_SEQUEN) 
//	// --> Alterado FINAL 

		// Nao processar os Impostos se o item possuir residuo eliminado  
		If &cFiltro
			dbSelectArea("SC7")
			dbSkip()
			Loop
		EndIf

		// Inicia a Carga do item nas funcoes MATXFIS  
		nItem++
		MaFisIniLoad(nItem)
	
		// ABERTURA DO DICIONÁRIO SX3 - manipulação descontinuada na migração de dicionario							   
	 //	dbSelectArea("SX3")
	 //	dbSetOrder(1)
		dbSeek("SC7")
		OpenSXs(Nil , Nil , Nil , Nil , cEmpAnt , cAlias , "SX3" , Nil , .F.) 
		lOpen := Select(cAlias) > 0

		// CASO ABERTO FILTRA O ARQUIVO PELO X3_ARQUIVO "SN1",
		If (lOpen)
			// DEFINE COMO TABELA CORRENTE E POSICIONA NO TOPO
			dbSelectArea(cAlias)
			dbSetFilter({|| &(cFilter)} , cFilter)
			(cAlias)->(dbGoTop())

			While (cAlias)->(!Eof()) 								// .AND. (X3_ARQUIVO == "SC7")
				cValid    := StrTran(Upper(&(_aXHeader[aScan(_aXHeader,'X3_VALID')]))," ","")
				cValid    := StrTran(cValid,"'",'"')
				If "MAFISREF" $ cValid
					nPosRef  := AT('MAFISREF("',cValid) + 10
					cRefCols := SubStr(cValid,nPosRef,AT('","MT120",',cValid)-nPosRef )

					If &(_aXHeader[aScan(_aXHeader,'X3_CAMPO')]) != 'C7_OPER'
						// Carrega os valores direto do SC7.           
						MaFisLoad(cRefCols,&("SC7->"+ &(_aXHeader[aScan(_aXHeader,'X3_CAMPO')])),nItem)
					EndIf
				EndIf
				(cAlias)->(dbSkip())
			Enddo
		EndIf
		MaFisEndLoad(nItem,2)
		dbSelectArea("SC7")
		dbSkip()
	EndDo
EndIf

RestArea(aAreaSC7)
RestArea(aArea)

Return .T.



// TODO Migração de dicionario Não permite mais o loop AllTrim(UsrFullName(SCR->CR_USER)), tranpondo para função statica
// ======================================================================= \\
Static Function getAllName(_CRUSER) 
// ======================================================================= \\

Local _cNameFull := "" 

_cNameFull := AllTrim(UsrFullName(_CRUSER))

Return _cNameFull



// TODO Migração de dicionario - substituindo função FMoaHeader
// CAMPOS QUE DESEJO UTILIZAR NA MINHA ESTRUTURA
// ======================================================================= \\
Static Function GetColumns()
// ======================================================================= \\
Local aFields := {} 				// VETOR DE CAMPOS

// ADIÇÃO DOS CAMPOS DESEJADOS
aAdd(aFields, "X3_TITULO")
aAdd(aFields, "X3_CAMPO")
aAdd(aFields, "X3_PICTURE")
aAdd(aFields, "X3_TAMANHO")
aAdd(aFields, "X3_DECIMAL")
aAdd(aFields, "X3_VALID")
aAdd(aFields, "X3_USADO")
aAdd(aFields, "X3_TIPO")
aAdd(aFields, "X3_F3")
aAdd(aFields, "X3_CONTEXT")
aAdd(aFields, "X3_CBOX")
aAdd(aFields, "X3_RELACAO")
aAdd(aFields, "X3_WHEN")
aAdd(aFields, "X3_VISUAL")
aAdd(aFields, "X3_VLDUSER")
aAdd(aFields, "X3_PICTVAR")
aAdd(aFields, "X3_OBRIGAT")

Return (aFields)
