#Include "PROTHEUS.ch"
#Include "FWMVCDEF.ch"
#Include "TopConn.ch"

/*{Protheus.doc} SFCMP09
Importa o arquivo de Rateio - Especifico SELFIT 
@author  Sergio Lavor (PROX) 
@since   26/10/2021
@version P12
*/
// ======================================================================= //
User Function SFCMP09() 
// ======================================================================= //

Local   aHeader  := {}				// Array com o  cabecalho do arquivo CSV 
Local   aCols    := {}				// Array com os itens     do arquivo CSV 
Local   lVld     := .F. 
Local   lRegrava := .F. 
Local   nRegrava := 0 
Local   cZQuery  := "" 
Local   lContinZ := .T. 
Local   cTxtMsgZ := "" 

Private lErroAll     := .F. 
Private __cProcPrinc := "SFCMP09" 	// "CTBA120" 
Private cNomArqZ     := "" 
Private nQtdRegZ     := 0 
Private cCtaDebi     := "" 
Private lCtaTdIg     := .T. 

// ativa os atalhos do Help da rotina
Versao(.T.)

// --> Le o arquivo de importação, e realiza as validações no arquvio
//     aHeader  - Cabeçalho do arquivo de importação 
//     aCols    - Itens     do arquivo de importação 
//     nRegrava - Sobresqueve arquivo sim ou não
lVld     := U_SFCMP09R(@aHeader , @aCols , @nRegrava) 
lRegrava := .F. 					// Iif(nRegrava == 1 , .T. , .F.) 

If lVld 
	lVld := U_SFCMP09V(@aHeader , @aCols , lRegrava) 
EndIf 

If lCtaTdIg
	If Select("QRY") > 0 
		QRY->(dbCloseArea()) 
	EndIf 
	cZQuery := "Select  * "
	cZQuery += "From    ( "
	cZQuery += "         Select   CTJ_RATEIO , CTJ_DESC , CTJ_DEBITO , Round(Sum(CTJ_PERCEN),2) As CTJ_PERCEN , Count(*) As QTDE_REGS "
	cZQuery += "         From     " + RetSQLName("CTJ") + " CTJ (NoLock) "
	cZQuery += "         Where    CTJ.D_E_L_E_T_ <> '*' "
	cZQuery += "         Group By CTJ_RATEIO , CTJ_DESC , CTJ_DEBITO "
	cZQuery += "        ) As AUX "
	cZQuery += "Where    AUX.CTJ_PERCEN = 100 "
	cZQuery += "  And    AUX.QTDE_REGS  =  "+AllTrim(Str(Len(aCols)))+"  "
	cZQuery += "  And    AUX.CTJ_DEBITO = '"+cCtaDebi+"' "
	cZQuery += "Order By AUX.CTJ_RATEIO , AUX.CTJ_DESC , AUX.CTJ_DEBITO "
	cZQuery := ChangeQuery(cZQuery)
	TCQuery cZQuery New Alias "QRY"
	While QRY->(!Eof()) 
		cTxtMsgZ += "Rateio: ["+QRY->CTJ_RATEIO+"] Descricao: ["+AllTrim(QRY->CTJ_DESC)+"] "+Chr(13)+Chr(10) 
		QRY->(dbSkip()) 
	EndDo 
	If !Empty(cTxtMsgZ) 
		lContinZ := MsgYesNo("Já existe(m) rateio(s) com ["+StrZero(Len(aCols),4)+"] linhas com conta débito ["+cCtaDebi+"], conforme relação abaixo." + Chr(13)+Chr(10) + ; 
		                     "Confirma a efetivação da importação do arquivo de rateio ???" + Chr(13)+Chr(10) + Chr(13)+Chr(10) + ; 
		                     cTxtMsgZ , "Especifico SELFIT - SFCMP09.prw") 
	EndIf 
	If Select("QRY") > 0 
		QRY->(dbCloseArea()) 
	EndIf 
EndIf 

If lContinZ 
	// --> Gravação da importação 
	If lVld 
		Begin Transaction
			U_SFCMP09G(@aHeader , @aCols , lRegrava) 
		End Transaction	
	EndIf 
	
	If lErroAll 
		ProcLogView( , __cProcPrinc) 																					// ##_Grava_LOG_## (final)
	Else 
		nQtdRegZ := Len(aCols) 
		MsgInfo("Arquivo de Rateio Importado com sucesso !" + Chr(13)+Chr(10) + ; 
		        "Arquivo..: "+cNomArqZ                      + Chr(13)+Chr(10) + ; 
		        "Qtde Regs: "+StrZero(nQtdRegZ,4) , "Especifico SELFIT - SFCMP09.prw") 
	EndIf 
Else 
	MsgAlert("Operação cancelada !" , "Especifico SELFIT - SFCMP09.prw") 
EndIf 

// desativa os atalhos do Help da rotina
Versao(.F.)

Return 


/*{Protheus.doc} CTBArqRat
Importa o arquivo de Rateio - Especifico SELFIT 
@author  Sergio Lavor 
@since   26/10/2021
@param   aHeader  - Cabeçalho do arquivo de importação 
@param   aCols    - Itens     do arquivo de importação 
@param   nRegrava - Sobresqueve arquivo 1=SIM ou 2=NÃO 
@version P12 
*/
// ======================================================================= //
User Function SFCMP09R(aHeader , aCols , nRegrava) 
// ======================================================================= //

Local aPar	    := {}  							// Array ParamBox 
Local aRet	    := {} 							// Array retorno ParamBox 
Local aRetAux   := {}  
Local cLinha    := "" 							// Linha de leitura do arquivo 
Local aCampo    := {} 							// CVN->(dbStruct()) 
Local cAli	    := ""							// Tabela de importação 
Local lRet	    := .T.
Local cMensIni  := ""
Local cLogErro  := ""
Local cId	    := ""
Local nX        := 0
Local nY        := 0
Local aErros    := {}
Local nErros    := 0

Local aHeadAux  := {} 
Local cFiliPad  := "    "
Local cRatePad  := "" 
Local cMoedPad  := "01" 
Local cTpSaPad  := "1" 
Local lCabAjus  := .F. 

//Default nRegrava := 2 

aCampo := CTJ->(dbStruct()) 
cAli   := "CTJ" 

dbSelectArea("CTJ") 
CTJ->(dbSetOrder(1)) 							// --> Indice 01: CTJ_FILIAL + CTJ_RATEIO + CTJ_SEQUEN 
CTJ->(dbGoBottom()) 
If CTJ->(!Eof()) 
	cRatePad := Soma1(CTJ->CTJ_RATEIO) 
Else 
	cRatePad := "000001" 
EndIf 

// --> Define o valor do array conforme estrutura. 
aPosCampos := Array(Len(aCampo)) 

aAdd(aPar,{6,"Arquivo para Importação",PadR("",150),"",,"",90 ,.T.,"Arquivo .CSV |*.CSV","",GETF_LOCALHARD+GETF_LOCALFLOPPY+GETF_NETWORKDRIVE})	// STR_0023 
//aAdd(aPar,{2,"Sobrescreve regra existente",2,{"Sim","Não"},30,,.T.}) 						// STR_0024  ##  STR_0025  ##  STR_0026

// --> Exportar para arquivo plano referencial. 
If ParamBox(aPar , "Rateio - Importação CSV - Especifico SELFIT" , @aRetAux) 				// STR_0027
	
	aRet     := SFC9RetPar(aRetAux , aPar) 
	nRegrava := 2 																			// aRet[2] 

	// --> Começa o log de processamento. 
	ProcLogIni( {} , __cProcPrinc , "Importação Rateio - SELFIT" , @cId ) 					// STR_0028 				// ##_Grava_LOG_## (inicio) 
	
	cMensIni := "Importação arquivo: " 														// STR_0029 
	ProcLogAtu("INICIO" , cMensIni , , , .T.) 												// STR_0030 				// ##_Grava_LOG_## 

	cNomArqZ := AllTrim(aRet[1]) 
	
	// --> Valida se o arquivo exite. 
	If FT_FUse(AllTrim(aRet[1])) == -1 
		Help(" " , 1 , "NOFILEIMPOR" , , "Arquivo não encontrado." , 3 , 1) 				// STR_0031
		lRet     := .F.
		cLogErro := "Arquivo não encontrado."+AllTrim(aRet[1])								// STR_0031
		ProcLogAtu("ERRO" , cMensIni , cLogErro , , .T.) 									// STR_0032					// ##_Grava_LOG_## 
		lErroAll := .T. 
	EndIf
	
	// --> Vai para o começo do arquivo. 
	FT_FGOTOP()
	
	// --> Valida se o arquivo não está vazio
	If lRet  .And.  FT_FLastRec() < 2
		Help(" " , 1 , "ARQVAZIO" , , "Arquivo Vazio." , 3 , 1) 							// STR_0033
		lRet     := .F.
		cLogErro := "Arquivo Vazio." 														// STR_0033
		ProcLogAtu("ERRO" , cMensIni , cLogErro , , .T.) 									// STR_0032 				// ##_Grava_LOG_## 
		lErroAll := .T. 
	EndIf
	
	// --> Pega o Cabecalho. 
	cLinha := FT_FREADLN() 

	// --> Valida se o cabeçalho do arquivo pertece a tabela certa. 
	If lRet  .And.  !(cAli $ cLinha) 
		aHeadAux := StrTokArr(cLinha , ";") 
		If Len(aHeadAux) <> 8 
			Help(" " , 1 , "CABINCORRETO" , , "Arquivo incorreto" , 3 , 1) 					// STR_0034
			lRet     := .F.
			cLogErro := "Arquivo com cabeçalho incorreto" 									// STR_0035
			ProcLogAtu("ERRO" , cMensIni , cLogErro , , .T.) 								// STR_0032 				// ##_Grava_LOG_## 
			lErroAll := .T. 
		Else 
			//           arquivo ;arquivo   ;arquivo   ;arquivo   ;arquivo   ;arquivo;arquivo;arquivo ;padrão    ;padrao    ;padrao    ;padrao    
			// Descrição do Rateio;Sequencia;Percentual;Conta Debito;Conta Credito;CCusto Debito;CCusto Credito;Historico
			cLinha   := "CTJ_DESC;CTJ_SEQUEN;CTJ_PERCEN;CTJ_DEBITO;CTJ_CREDIT;CTJ_CCD;CTJ_CCC;CTJ_HIST;CTJ_FILIAL;CTJ_RATEIO;CTJ_MOEDLC;CTJ_TPSALD"
			lCabAjus := .T. 
		EndIf 
	EndIf
	
	// --> Cabeçalho -- Valida se todos os campos existem na tabela para não gerar erro na leitura do arquivo 
	If lRet 
		aHeader := StrTokArr(cLinha , ";") 
		For nY := 1 To Len(aHeader) 
			If	FieldPos(aHeader[nY]) == 0 
				lRet     := .F. 
				cLogErro += aHeader[nY] + CRLF 
			EndIf 
		Next nY 
		If !lRet 
			ProcLogAtu("ERRO" , cMensIni , "Exite campo no cabeçalho do arquivo que não existe no dicionario."+CRLF+cLogErro , , .T.)	// STR_0032 # STR_0041 		// ##_Grava_LOG_## 
			Help(" " , 1 , "CAMPOINCORRETO" , , "Exite campo no cabeçalho do arquivo que não existe no dicionario." , 3 , 1) 			// STR_0041
			lErroAll := .T. 
		EndIf 
	EndIf 
	
	// --> Itens -- Le o arquivo 
	If lRet
		nPos := 0 
		FT_FSKIP()
		// --> Le o primeiro item do arquivo
		While !FT_FEOF() 
			If lCabAjus
				cLinha := FT_FREADLN() + ";" + cFiliPad + ";" + cRatePad + ";" + cMoedPad + ";" + cTpSaPad 
			Else 
				cLinha := FT_FREADLN() 
			EndIf 
			aColsAux := SFC9CArray(cLinha,";",Len(aHeader)) 
			// --> Array com as linhas do arquivo 
			aAdd(aCols , aColsAux) 
			FT_FSKIP() 
		EndDo 
		FT_FUSE() 

		// --> Verifica se o tamanho de coluna dos arquivos estão iguais
		If lRet
			nHeader := Len(aHeader)
			For nX := 1 To Len(aCols)
				If nHeader <> Len(aCols[nX])
					lRet := .F. 
				EndIf 
			Next nX
			If !lRet 
				Help(" ", 1, "NOITENS", , "As colunas dos itens não bate com o numero das colunas", 3, 1) 	// STR_0036 
				cLogErro := "As colunas dos itens não bate com o numero das colunas do cabeçalho" 			// STR_0036 
				ProcLogAtu("ERRO" , cMensIni , cLogErro , , .T.) 											// STR_0032	// ##_Grava_LOG_## 
				lErroAll := .T. 
			EndIf 
		EndIf 
		
		// --> Verificar se o tamanho de cada dado não extrapola a capacidade do campo 
		If lRet  .And.  SFC9TamSX3(aHeader , aCols , @aErros) 
			lRet := .F.
			Help(" " , 1 , "DADOSINC" , , "Inconsistencia nos dados" , 3 , 1) 								// STR_0037	
			cLogErro := "Há dados que extrapolam a capacidade do campo: " + CRLF
			For nErros := 1 To Len(aErros)
				cLogErro += "Linha: " + aErros[nErros,1] + " Campo: " + aErros[nErros,2] + CRLF
			Next nErros
			ProcLogAtu("ERRO" , cMensIni , cLogErro , , .T.) 												// STR_0032	// ##_Grava_LOG_## 
			lErroAll := .T. 
		EndIf
		
	EndIf
EndIf

aSize(aErros,0)
aErros	:= Nil

Return lRet



// ======================================================================= //
/*{Protheus.doc} SFC9RetPar  
Ajusta o retorno da Parambox - Especifico SELFIT 
@author  Sergio Lavor (PROX) 
@since   26/10/2021
@return  aRet 
@version P12
*/
// ======================================================================= //
Static Function SFC9RetPar(aRet , aParamBox) 
// ======================================================================= //

Local nX := 1 

If ValType(aRet) == "A"  .And.  Len(aRet) == Len(aParamBox) 
	For nX := 1 To Len(aParamBox)
		If     aParamBox[nX][1] == 1 
			aRet[nX] := aRet[nX] 
		ElseIf aParamBox[nX][1] == 2  .And.  ValType(aRet[nX]) == "C" 
			aRet[nX] := aScan(aParamBox[nX][4],{|x| AllTrim(x) == aRet[nX]}) 
		ElseIf aParamBox[nX][1] == 2  .And.  ValType(aRet[nX]) == "N" 
			aRet[nX] := aRet[nX] 
		EndIf 
	Next nX 
EndIf 

Return aRet 



/*{Protheus.doc} SFC9CArray
Cria array com os itens do arquivo - Especifico SELFIT 
@author  Sergio Lavor (PROX) 
@since   26/10/2021
@param   cLinha - conteudo da linha do arquivo
@param   cSep   - separador
@param   nCab   - numero de colunas do cabeçalho
@version P12
*/
// ======================================================================= //
Static Function SFC9CArray(cLinha , cSep , nCab) 
// ======================================================================= //

Local aRet   := {}
Local nPos   := 0

While At(cSep , cLinha) > 0  .Or.  !Empty(cLinha)
	nPos := At(cSep , cLinha)
	If nPos <> 0
		aAdd( aRet , SubStr(cLinha , 1 , nPos-1) )
		cLinha := SubStr(cLinha , nPos+1) 
	Else
		aAdd(aRet , cLinha) 
		cLinha := "" 
	EndIf 

	If Empty(cLinha)  .And.  (Len(aRet) <> nCab) 
		aAdd(aRet , cLinha) 
	EndIf 
EndDo 

Return aRet 



/*{Protheus.doc} SFC9TamSX3
Verificar se o tamanho de cada dado não extrapola a capacidade do campo admin 
@author  Sergio Lavor (PROX) 
@since   26/10/2021 
@param   aHeader - Cabeçalho do arquivo 
@param   aCols   - Itens     do arquivo 
@version P12 
*/
// ======================================================================= //
Static Function SFC9TamSX3(aHeader , aCols , aErros) 
// ======================================================================= //

Local lRet		:= .F.
Local nHead		:= 0
Local nCols		:= 0
Local cCampo	:= ""
Local aAliasSX3	:= SX3->(GetArea())

//Default aErros := {}

For nCols := 1 To Len(aCols)
	For nHead := 1 To Len(aHeader)
		cCampo := AllTrim(aHeader[nHead])
		SX3->(dbSetOrder(2))
		If SX3->(dbSeek(cCampo)) 
			If Len(aCols[nCols][nHead]) > (TamSX3(cCampo)[1])
				lRet := .T.
				aAdd(aErros , {AllTrim(Str(nCols+1)),cCampo}) 
			EndIf
		EndIf
	Next nHead
Next nCols

RestArea(aAliasSX3)

Return lRet



/*{Protheus.doc} SFCMP09V
Validação Dados Arquivo - C.Custo / C.Contabil - Especifico SELFIT 
@author  Sergio Lavor (PROX) 
@since   26/10/2021
@param   aHeader  - Cabeçalho do arquivo de importação
@param   aCols	  - Itens do arquivo de importação
@param   nRegrava - Sobresqueve arquivo 1=SIM ou 2=NÃO
@version P12
*/
// ======================================================================= //
User Function SFCMP09V(aHeader , aCols , lRegrava) 
// ======================================================================= //

Local aAreaAtu  := GetArea() 
Local nZ        := 0 

Local c_CtaDeb  := "" 
Local c_CtaCre  := "" 
Local c_CCuDeb  := "" 
Local c_CCuCre  := "" 

Local nPoCtaDeb := 0 
Local nPoCtaCre := 0 
Local nPoCCuDeb := 0 
Local nPoCCuCre := 0 

Local lLinhaOk  := .T. 
Local cErroAux  := "" 
Local cErroArq  := "" 
Local cMensIni  := "Importação arquivo: " 
Local lCtaFirs  := .T. 


Local lRetZ     := .T. 

nPoCtaDeb := aScan(aHeader , "CTJ_DEBITO") 
nPoCtaCre := aScan(aHeader , "CTJ_CREDIT") 
nPoCCuDeb := aScan(aHeader , "CTJ_CCD"   ) 
nPoCCuCre := aScan(aHeader , "CTJ_CCC"   ) 

dbSelectArea("CT1") 
CT1->(dbSetOrder(1)) 									// --> Indice 01: CT1_FILIAL + CT1_CONTA 

dbSelectArea("CTT") 
CTT->(dbSetOrder(1))									// --> Indice 01: CTT_FILIAL + CTT_CUSTO 

For nZ := 1 To Len(aCols) 

	lLinhaOk := .T. 
	cErroAux := "" 

	c_CtaDeb := aCols[nZ][nPoCtaDeb] 					// --> Conta  Contabil - DEBITO  
	If !Empty(c_CtaDeb) 
		CT1->(dbSeek(xFilial("CT1")+c_CtaDeb))
		If CT1->(!Eof()) 
			If CT1->CT1_BLOQ = "1" 
				cErroAux := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  Conta Debito   : ["+c_CtaDeb+"] - Bloqueada" 
				ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 							// ##_Grava_LOG_##
				lLinhaOk := .F. 
			EndIf 
		Else 
			cErroAux     := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  Conta Debito   : ["+c_CtaDeb+"] - Não cadastrada" 
			ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 								// ##_Grava_LOG_##
			lLinhaOk     := .F. 
		EndIf 
	EndIf 
	c_CtaCre := aCols[nZ][nPoCtaCre] 					// --> Conta  Contabil - CREDITO 
	If !Empty(c_CtaCre) 
		CT1->(dbSeek(xFilial("CT1")+c_CtaCre))
		If CT1->(!Eof()) 
			If CT1->CT1_BLOQ = "1" 
				lLinhaOk := .F. 
				cErroAux := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  Conta Credito  : ["+c_CtaCre+"] - Bloqueada" 
				ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 							// ##_Grava_LOG_##
				cErroArq := cErroArq + cErroAux + Chr(13)+Chr(10) 
			EndIf 
		Else 
			lLinhaOk     := .F. 
			cErroAux     := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  Conta Credito  : ["+c_CtaCre+"] - Não cadastrada" 
			ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 								// ##_Grava_LOG_##
			cErroArq     := cErroArq + cErroAux + Chr(13)+Chr(10) 
		EndIf 
	EndIf 
	If lLinhaOk 										// --> Conta  Contabil - DEBITO / CREDITO 
		If Empty(c_CtaDeb) .And. Empty(c_CtaCre) 
			cErroAux     := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  Nao possui Conta Credito nem Conta Debito" 
			ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 								// ##_Grava_LOG_##
			cErroArq     := cErroArq + cErroAux + Chr(13)+Chr(10) 
		EndIf 
	EndIf 
	If lCtaFirs 
		cCtaDebi := c_CtaDeb 
		lCtaFirs := .F. 
	Else 
		If cCtaDebi <> c_CtaDeb 
			lCtaTdIg := .F. 
		EndIf 
	EndIf 

	lLinhaOk := .T. 
	cErroAux := "" 

	c_CCuDeb := aCols[nZ][nPoCCuDeb] 					// --> Centro de Custo - DEBITO  
	If !Empty(c_CCuDeb) 
		CTT->(dbSeek(xFilial("CTT")+c_CCuDeb))
		If CTT->(!Eof()) 
			If CTT->CTT_BLOQ = "1" 
				lLinhaOk := .F. 
				cErroAux := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  C.Custo Debito : ["+c_CCuDeb+"] - Bloqueado" 
				ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 							// ##_Grava_LOG_##
				cErroArq := cErroArq + cErroAux + Chr(13)+Chr(10) 
			EndIf 
		Else 
			lLinhaOk     := .F. 
			cErroAux     := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  C.Custo Debito : ["+c_CCuDeb+"] - Não cadastrado" 
			ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 								// ##_Grava_LOG_##
			cErroArq     := cErroArq + cErroAux + Chr(13)+Chr(10) 
		EndIf 
	EndIf 
	c_CCuCre := aCols[nZ][nPoCCuCre] 					// --> Centro de Custo - CREDITO 
	If !Empty(c_CCuCre) 
		CTT->(dbSeek(xFilial("CTT")+c_CCuCre))
		If CTT->(!Eof()) 
			If CTT->CTT_BLOQ = "1" 
				lLinhaOk := .F. 
				cErroAux := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  C.Custo Credito: ["+c_CCuCre+"] - Bloqueado" 
				ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 							// ##_Grava_LOG_##
				cErroArq := cErroArq + cErroAux + Chr(13)+Chr(10) 
			EndIf 
		Else 
			lLinhaOk     := .F. 
			cErroAux     := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  C.Custo Credito: ["+c_CCuCre+"] - Não cadastrado" 
			ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 								// ##_Grava_LOG_##
			cErroArq     := cErroArq + cErroAux + Chr(13)+Chr(10) 
		EndIf 
	EndIf 
	If lLinhaOk 										// --> Centro de Custo - DEBITO / CREDITO 
		If Empty(c_CCuDeb) .And. Empty(c_CCuCre) 
			cErroAux     := "Linha: ["+AllTrim(StrZero(nZ,4))+"]  Nao possui C.Custo Credito nem C.Custo Debito" 
			ProcLogAtu("ERRO" , cMensIni , cErroAux , , .T.) 							 								// ##_Grava_LOG_##
			cErroArq     := cErroArq + cErroAux + Chr(13)+Chr(10) 
		EndIf 
	EndIf 
	
Next nZ 

If !Empty(cErroArq) 
	lErroAll := .T. 
	lRetZ    := .F. 
EndIf 

RestArea(aAreaAtu) 

Return lRetZ 



/*{Protheus.doc} SFCMP09G
Grava importação -  Especifico SELFIT 
@author  Sergio Lavor (PROX) 
@since   26/10/2021
@param   aHeader  - Cabeçalho do arquivo de importação
@param   aCols	  - Itens do arquivo de importação
@param   nRegrava - Sobresqueve arquivo 1=SIM ou 2=NÃO
@version P12
*/
// ======================================================================= //
User Function SFCMP09G(aHeader , aCols , lRegrava) 
// ======================================================================= //

Local oModelCAB	
Local oModelCTJ	
Local nX	     := 0
Local nDadArq    := 0
Local nHeaArq    := 0
Local nPosEv     := aScan(aHeader , "CTJ_EVENTO") 
Local cEventAnt	 := ""
Local cAlias     := ""
Local aCampo     := {}
Local aInd	     := {}
Local oModel     := FWLoadModel("CTBA120") 
Local aErro	     := {}
Local lExiCpoEve := nPosEv > 0
Local nPosCodR   := aScan(aHeader , "CTJ_RATEIO")
Local nPosSeq    := aScan(aHeader , "CTJ_SEQUEN")
Local cMensIni   := "Importação arquivo: "									// STR_0027
Local cLogErro   := ""
Local lErro	     := .F.
Local lGrvCab    := .T.
Local cCodRat    := ""
Local cSeq	     := ""
Local nTamCodR   := TamSX3("CTJ_SEQUEN")[1]

INCLUI := .T. 

cAlias := GetNextAlias() 
aCampo := {} 
aInd   := {} 

oModel:SetOperation(MODEL_OPERATION_INSERT)  								// --> 3=Inclusão  |  4=Alteração  |  5=Exclusão 

oModel:Activate() 

oModelCAB := oModel:GetModel("CTJMASTER") 
oModelCTJ := oModel:GetModel("CTJDETAIL") 

For nX := 1 To Len(aCols)
	If lExiCpoEve .And. !Empty(aCols[nX][nPosEv]) 
		cEventAnt := aCols[nX][nPosEv]
		lErro     := SFC9GrvEv(aCols[nX][nPosEv] , aHeader , aCols , oModel , @nX , lRegrava) 
		Loop
	Else
		cCodRat	  := aCols[nX][nPosCodR]
		
		For nDadArq := nX To Len(aCols)
			cCodRat := aCols[nDadArq][nPosCodR]
			
			If Empty(aCols[nDadArq][nPosSeq])
				cSeq    := StrZero(0,TamSX3("CTJ_SEQUEN")[1])
			Else
				cSeq    := PadL(aCols[nDadArq][nPosSeq],nTamCodR,"0")
			EndIf			
		
			// --> Validação para gravar cabeçalho 
			If nDadArq > 1  .And.  AllTrim(cCodRat) == AllTrim(aCols[nDadArq-1][nPosCodR]) 
				lGrvCab := .F.
				nLinha  := oModelCTJ:AddLine()
				oModelCTJ:goLine(nLinha)
			EndIf
		
			For nHeaArq := 1 To Len(aHeader)
				If     "PERCEN" $ aHeader[nHeaArq] .Or. "QTDDIS" $ aHeader[nHeaArq] .Or. ("VALOR" $ aHeader[nHeaArq])
					oModelCTJ:SetValue(aHeader[nHeaArq],Val(StrTran(aCols[nDadArq,nHeaArq],",",".")))
				ElseIf lGrvCab .And. "CTJ_RATEIO" $ aHeader[nHeaArq]
					oModelCAB:SetValue("CTJ_RATEIO",AllTrim(cCodRat))
				ElseIf lGrvCab .And. "CTJ_DESC"   $ aHeader[nHeaArq]
					oModelCAB:SetValue("CTJ_DESC",aCols[nDadArq,nHeaArq])
				ElseIf lGrvCab .And. "CTJ_MOEDLC" $ aHeader[nHeaArq]
					oModelCAB:SetValue("CTJ_MOEDLC",aCols[nDadArq,nHeaArq])
				ElseIf lGrvCab .And. "CTJ_TPSALD" $ aHeader[nHeaArq]
					oModelCAB:SetValue("CTJ_TPSALD",aCols[nDadArq,nHeaArq])
				ElseIf lGrvCab .And. "CTJ_QTDTOT" $ aHeader[nHeaArq]	
					oModelCAB:SetValue("CTJ_QTDTOT",Val(StrTran(aCols[nX,nHeaArq],",",".")))
				ElseIf "CTJ_RATEIO" $ aHeader[nHeaArq] .Or. "CTJ_DESC" $ aHeader[nHeaArq].Or. "CTJ_MOEDLC" $ aHeader[nHeaArq] .Or. "CTJ_TPSALD" $ aHeader[nHeaArq] .Or. "CTJ_QTDTOT" $ aHeader[nHeaArq] 
					Loop
				ElseIf !lGrvCab .And. "CTJ_SEQUEN" $ aHeader[nHeaArq] .And. !Empty(aCols[nDadArq,nHeaArq])
					oModelCTJ:SetValue(aHeader[nHeaArq],cSeq)
				Else
					oModelCTJ:SetValue(aHeader[nHeaArq],aCols[nDadArq,nHeaArq])
				EndIf
			Next nHeaArq
			
			If Empty(aCols[nX][nPosSeq])
				cSeq	:= Soma1(cSeq)
			EndIf
				
			oModelCTJ:SetValue("CTJ_SEQUEN",cSeq)
		Next nDadArq
		
		nX := nDadArq
		
		If oModel:VldData() 
			oModel:CommitData() 
			oModel:DeActivate() 
			oModel:Activate() 
		Else
			aErro := oModel:GetErrorMessage() 
			// A estrutura do vetor com erro é:
			//    [1] identificador (ID) do formulário de origem
			//    [2] identificador (ID) do campo de origem
			//    [3] identificador (ID) do formulário de erro
			//    [4] identificador (ID) do campo de erro
			//    [5] identificador (ID) do erro
			//    [6] mensagem do erro
			//    [7] mensagem da solução
			//    [8] Valor atribuído
			//    [9] Valor anterior
			cLogErro := aErro[4] + " - " + aErro[6] 
			ProcLogAtu("ERRO" , cMensIni , cLogErro , , .T.) 				// STR_0028 								// ##_Grava_LOG_## 
			lErro    := .T. 
		EndIf
		
		nX := nDadArq -1 
	EndIf
Next nX

ProcLogAtu("FIM" , cMensIni , , , .T.) 										// STR_0029 								// ##_Grava_LOG_## 

// --> Se teve algum erro, mostra o log de erros.
If lErro 
 //	ProcLogView( , __cProcPrinc) 																						// ##_Grava_LOG_## (final)
	lErroAll := .T. 
EndIf 

Return 



/*{Protheus.doc} SFC9GrvEv
Grava arquivo de importação com evento - Especifico SELFIT 
@author  Sergio Lavor (PROX) 
@since   26/10/2021
@version P12
*/
// ======================================================================= //
Static Function SFC9GrvEv(cEvento, aHeader, aCols, oModel, nX, lRegrava) 
// ======================================================================= //

Local aArea	    := GetArea()
Local aAreaCQK  := CQK->(GetArea())
Local nPosEv    := aScan(aHeader , "CTJ_EVENTO") 
Local nPosMoe   := aScan(aHeader , "CTJ_MOEDLC")
Local nPoTp	    := aScan(aHeader , "CTJ_TPSALD")
Local nPoQt	    := aScan(aHeader , "CTJ_QTDTOT")
Local cSeq	    := ""
Local oModelCAB	:= oModel:GetModel("CTJMASTER")
Local oModelCTJ	:= oModel:GetModel("CTJDETAIL")
Local nLinha    := 0
Local aErro	    := {}
Local lRet	    := .F. 						// --> Retorna se teve erro na gravação
Local cMensIni  := "Importação arquivo: " 									// STR_0027
Local nQTDDIS   := 0
Local nHeaArq   := 0
Local nDadArq   := 0

nQTDDIS := 0

dbSelectArea("CQK") 						// --> Tabela...: Itens do Evento 
CQK->(dbSetOrder(1)) 						// --> Indice 01: CQK_FILIAL + CQK_CODEVE + CQK_ITEM 

If CQK->(dbSeek(xFilial("CQK")+cEvento))

	While CQK->(!Eof())  .And.  AllTrim(CQK->CQK_CODEVE) == cEVENTO
		cSeq := "001"
		
		// --> Grava cabeçalho
		oModelCAB:SetValue("CTJ_RATEIO" , CQK->CQK_CODRAT)
		oModelCAB:SetValue("CTJ_DESC"   , CQK->CQK_DESC  )
			
		// --> CARREGA DADOS DA PRIMEIRA LINAH NO CABEÇALHO
		If nPoQT > 0
			oModelCAB:SetValue("CTJ_QTDTOT",Val(StrTran(aCols[nX,nPoQT],",",".")))
		EndIf
		If nPosMoe > 0
			oModelCAB:SetValue("CTJ_MOEDLC",aCols[nX,nPosMoe])
		EndIf
		If nPoTp > 0
			oModelCAB:SetValue("CTJ_TPSALD",aCols[nX,nPoTp])
		EndIf
		
		// --> Inclusao da partida originada da CQK
		oModelCTJ:SetValue("CTJ_PERCEN",100)		
		oModelCTJ:SetValue("CTJ_SEQUEN",cSeq)
		
		If CQK->CQK_ENTBAS == "2"
			oModelCTJ:SetValue("CTJ_CREDIT" , CQK->CQK_CREDIT)
			oModelCTJ:SetValue("CTJ_CCC"    , CQK->CQK_CCC   )
			oModelCTJ:SetValue("CTJ_ITEMC"  , CQK->CQK_ITEMC )
			oModelCTJ:SetValue("CTJ_CLVLCR" , CQK->CQK_CLVLCR)
		Else 				// Debito
			oModelCTJ:SetValue("CTJ_DEBITO" , CQK->CQK_DEBITO)
			oModelCTJ:SetValue("CTJ_CCD"    , CQK->CQK_CCD   )
			oModelCTJ:SetValue("CTJ_ITEMD"  , CQK->CQK_ITEMD )
			oModelCTJ:SetValue("CTJ_CLVLDB" , CQK->CQK_CLVLDB)
		EndIf

		// --> Inclusao da partida destino do arquivo + CQK 
		For nDadArq := nX To Len(aCols)
			If cEvento == aCols[nDadArq][nPosEv] 
				nLinha := oModelCTJ:AddLine()
				
				oModelCTJ:goLine(nLinha)
				
				For nHeaArq := 1 To Len(aHeader)
					If     ("PERCEN" $ aHeader[nHeaArq]) .Or. ("QTDDIS" $ aHeader[nHeaArq]) .Or. ("VALOR" $ aHeader[nHeaArq])
						oModelCTJ:SetValue(aHeader[nHeaArq],Val(StrTran(aCols[nDadArq,nHeaArq],",",".")))
					ElseIf "CTJ_RATEIO" $ aHeader[nHeaArq] .Or. "CTJ_DESC" $ aHeader[nHeaArq].Or. "CTJ_MOEDLC"$ aHeader[nHeaArq] .Or. "CTJ_QTDTOT" $ aHeader[nHeaArq] .Or. "CTJ_TPSALD" $ aHeader[nHeaArq] 
						Loop
					Else 
						oModelCTJ:SetValue(aHeader[nHeaArq],aCols[nDadArq,nHeaArq])
					EndIf
				Next nHeaArq
				
				If CQK->CQK_ENTBAS == "2"
					oModelCTJ:SetValue("CTJ_DEBITO",CQK->CQK_DEBITO )
				Else
					oModelCTJ:SetValue("CTJ_CREDIT",CQK->CQK_CREDITO)
				EndIf
				
				cSeq := Soma1(cSeq)
				
				oModelCTJ:SetValue("CTJ_SEQUEN",cSeq)
			Else
				Exit
			EndIf
		Next nDadArq
		
		If oModel:VldData()
			oModel:CommitData()
			oModel:DeActivate()
			oModel:Activate()
		Else
			aErro   := oModel:GetErrorMessage()
			// A estrutura do vetor com erro é:
			// [1] identificador (ID) do formulário de origem
			// [2] identificador (ID) do campo de origem
			// [3] identificador (ID) do formulário de erro
			// [4] identificador (ID) do campo de erro
			// [5] identificador (ID) do erro
			// [6] mensagem do erro
			// [7] mensagem da solução
			// [8] Valor atribuído
			// [9] Valor anterior
			cLogErro := aErro[4] + " - " + aErro[6]
			ProcLogAtu("ERRO" , cMensIni , cLogErro , , .T.) 					// STR_0028 							// ##_Grava_LOG_##
			lRet := .T.
		EndIf

		CQK->(dbSkip())
	EndDo

	nX := nDadArq - 1 

Else

	cLogErro := "Arquivo com valor inválido. Coluna: " + "CTJ_EVENTO" + "." 	// STR_0030 
	ProcLogAtu("ERRO" , cMensIni , cLogErro , , .T.) 							// STR_0028 							// ##_Grava_LOG_##
	lRet     := .T.

EndIf 

RestArea(aAreaCQK) 
RestArea(aArea) 

Return lRet





/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			11/02/2022
Consultoria: 	Prox
Uso: 			SELFIT
Info: 			Exibição do Help da rotina
*=====================================================================================*/
Static Function Versao(lAtiva)
Local aHelp030 := {}
Local _cHelp   := ""
Local _nR
Local _lHtml := .F.

if lAtiva == Nil // exibicao do help
	Versao(.F.)  // desativa os atalhos do Help da rotina

	Aadd(aHelp030,"SFCMP09 - Importação de Dados de Rateio v1.01 29-03-2022")
	Aadd(aHelp030,"")
	Aadd(aHelp030,"Utilização da Rotina:")
	Aadd(aHelp030,"  - Entrar na opção no menu 'Importação Rateio'")
	Aadd(aHelp030,"  - Selecionar o arquivo CSV a ser importado")
	Aadd(aHelp030,"")
	Aadd(aHelp030,"  Após a importação da planilha, será exibida uma mensagem. Esta mensagem pode ser de sucesso (será exibido o número da solicitação), ou de falha (que informará o motivo do problema)")
	Aadd(aHelp030,"")

	Aadd(aHelp030,"Validações da Rotina:")
	Aadd(aHelp030,"  1. As seguintes colunas serão importadas para a Solicitação de Compras>")
	Aadd(aHelp030,"     'Produto', 'Quantidade', 'Prc Unitario', 'Prc Estimado', 'Centro Custo', 'Observacao', 'Fornecedor','Loja do Forn','DescComplem','Cod. Comprad','Previsa Entr'")
	Aadd(aHelp030,"  2. O restante dos campos serão preenchidos automaticamente")
	Aadd(aHelp030,"  3. A primeira linha do arquivo deve ser a linha de cabeçalho")
	Aadd(aHelp030,"")
	
	Aadd(aHelp030,"Ajustes realizados:")
	Aadd(aHelp030,"")
	Aadd(aHelp030," 22-02-2022 Criação da Rotina")
	Aadd(aHelp030,"")
	Aadd(aHelp030," 29-03-2022 Rotina transforma valores com vírgula decimal para ponto decimal (exemplo: 1532,32 será transformado para 1523.32) ")
	Aadd(aHelp030,"")

	// coloca as quebras de linha e os espacos no formato HTML ou Texto
	For _nR := 1 to Len(aHelp030)
		if _lHtml
			_cVarTxt := Strtran(Strtran(Strtran(aHelp030[_nR],"   ","&nbsp;&nbsp;&nbsp;"),"  ","&nbsp;&nbsp;")," ","&nbsp;")
			_cHelp += "<BR>"+_cVarTxt
		Else
			_cVarTxt := Strtran(StrTran(aHelp030[_nR],"<B>",""),"</B>","")
			_cHelp   += Chr(13)+Chr(10)+_cVarTxt
		Endif	
	Next

	DEFINE MSDIALOG oDlgHlp TITLE "Help da Rotina" FROM C(264),C(469) TO C(676),C(1010) PIXEL

		// Cria Componentes Padroes do Sistema
		@ C(002),C(002) GET oMemo1 Var _cHelp MEMO When .F. Size C(266),C(186) PIXEL OF oDlgHlp
		@ C(191),C(230) Button "Ok" Size C(037),C(012) Action (oDlgHlp:End()) PIXEL OF oDlgHlp
		
	ACTIVATE MSDIALOG oDlgHlp CENTERED 

	Versao(.T.) // ativa os atalhos do Help da rotina

Elseif lAtiva 
	//Ativo os atalhos do Help da rotina
	SetKey(K_CTRL_F1, {|| Versao() })
	SetKey(K_ALT_F1 , {|| Versao() })
	SetKey(K_SH_F1  , {|| Versao() })

Elseif ! lAtiva
	//Ativo os atalhos do Help da rotina
	SetKey(K_CTRL_F1, Nil )
	SetKey(K_ALT_F1 , Nil )
	SetKey(K_SH_F1  , Nil )
Endif

Return

