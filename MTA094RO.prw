#Include "RWMAKE.CH"
#Include "PROTHEUS.CH"
#Include "TbiConn.ch"

/*{Protheus.doc} MTA094RO.prw
Liberação de pedidos de compra em lote
@author  Marcos Bispo Abrahao
@since   09/09/2018
@version P12
@menu SIGACOM->Atualizações ->Liberação->Liberação de Doctos
*/
// ======================================================================= \\
User Function MTA094RO() 
// ======================================================================= \\

Local aRotina := PARAMIXB[1]

aAdd( aRotina, {OemToAnsi("Aprovação em lote"), "U_SFA094AL", 0, 4 } )

Return aRotina



// ======================================================================= \\
User Function SFA094AL()
// ======================================================================= \\
// Mark Browse - Aprovação em Lote

Local   aSize      := FWGetDialogSize( oMainWnd ) 		// Array com tamanho da janela.
Local   oMrkBrowse := Nil
Local   cAliasSCR  := "" 								// Alias Temporario 
Local   aAlias     := {}								// Array para o retorno da função MTA094QRY
Local   aColumns   := {}								// Colunas do Browse			

Local   aArea      := GetArea()

Private oTempTable := Nil

cAliasSCR := GetNextAlias() 

// Retorna as colunas para o preenchimento da FWMarkBrowse
aAlias   := SFA094QRY()
cAlias 	 := aAlias[1]
aColumns := aAlias[2]

DEFINE DIALOG oDlg TITLE "Liberação de Pedidos em Lote" FROM aSize[1],aSize[2] TO aSize[3],aSize[4] PIXEL
	// Criação da MarkBrowse
	oMrkBrowse:= FWMarkBrowse():New()
	oMrkBrowse:SetFieldMark("CR_OK")
	oMrkBrowse:SetOwner(oDlg)
	oMrkBrowse:oBrowse:SetDataQuery(.F.)
	oMrkBrowse:oBrowse:SetDataTable(.T.)
	oMrkBrowse:SetAlias(cAlias)
 //	oMrkBrowse:SetCustomMarkRec({|| SFA094MkB(oMrkBrowse) })
	oMrkBrowse:SetDescription("")
	oMrkBrowse:SetMenuDef("")
	oMrkBrowse:AddButton("Aprovar",{|| SFA09Apr(cAlias,oDlg)},,,,.F.,1) 	// "Aprovar PC"
	oMrkBrowse:AddButton("Fechar",{|| oDlg:End()},,,,.F.,1)
	oMrkBrowse:SetColumns(aColumns)
	oMrkBrowse:SetUseFilter(.T.)
	oMrkBrowse:Activate()
ACTIVATE DIALOG oDlg CENTERED

RestArea(aArea)

Return (.T.)



/*/{Protheus.doc} SFA094QRY()
Realiza a Query para criar e popular a MarkBrowse
@sample  SFA094QRY()
@return  ExpA	- Array[1] - Alias da Tabela Temporaria.
				- Array[2] - Colunas da Tabela.
@author  CRM
@since   09/09/2018       
@version P12  
/*/         
// ======================================================================= \\
Static Function SFA094QRY()
// ======================================================================= \\

Local aArea     := {} 					// Area a ser recuperada
Local aAreaSX3  := {} 					// Area do SX3
Local cAlias	:= GetNextAlias()		// Alias
Local cUsuario	:= __cUserID			// Armazena o codigo do usuario
Local aStruct	:= {}					// Estrutura da Tabela SC7 SC7->(DBSTRUCT())
Local aColumns	:= {}					// Array com as colunas da Tabela SC7
Local nX		:= 0					// Contador
Local cTempTab	:= GetNextAlias()		// Armazena nome da tabela temporaria
Local aCampos   := {"CR_EMISSAO","A2_NOME","CR_NUM","CR_TIPO","CR_TOTAL","CR_FILIAL","CR_GRUPO","CR_STATUS","CR_USER"}
Local cTipoSCR  := "PC"
Local cStatus   := "02"  				// 02=Aguardando Liberacao do usuario
Local cCampo    := ""

aArea    := GetArea() 
aAreaSX3 := SX3->(GetArea()) 

aStruct	 := ArToStru(aCampos) 
aAdd(aStruct , {"CR_OK"    , "C" , 2 , 0})
aAdd(aStruct , {"CR_RECNO" , "N" , 8 , 0})

// Verifica quais DAC´S o usuario tem acesso
BeginSQL alias cAlias
	SELECT 
		CR_EMISSAO,A2_NOME,CR_NUM,CR_TIPO,CR_TOTAL,CR_FILIAL,CR_GRUPO,CR_STATUS,CR_USER,Space(02) AS CR_OK  //,SCR.R_E_C_N_O_ AS CR_RECNO //SCR_OK é o campo criado para o campo de Marcação
	FROM 
		%table:SCR% SCR
	JOIN 
		%table:SC7% SC7 ON (SC7.C7_FILIAL=SCR.CR_FILIAL AND SC7.C7_NUM=SCR.CR_NUM AND SC7.%notDel%)
	JOIN
		%table:SB1% SB1 ON (SB1.B1_FILIAL=%xfilial:SB1% AND SB1.B1_COD=SC7.C7_PRODUTO AND SB1.%notDel%)
	JOIN
		%table:SA2% SA2 ON (SA2.A2_FILIAL=%xfilial:SA2% AND SA2.A2_COD=SC7.C7_FORNECE AND SA2.A2_LOJA=SC7.C7_LOJA AND SB1.%notDel%)
	WHERE
			SCR.CR_TIPO = %exp:cTipoSCR%
		AND
			SCR.CR_USER = %exp:cUsuario%
		AND
			SCR.CR_STATUS = %exp:cStatus%
		AND	
			SCR.%notDel%
	GROUP BY CR_EMISSAO,A2_NOME,CR_NUM,CR_TIPO,CR_TOTAL,CR_FILIAL,CR_GRUPO,CR_STATUS,CR_USER
EndSql

// Instancia tabela temporária.  
oTempTable	:= FWTemporaryTable():New(cTempTab)

// Atribui o  os índices.  
oTempTable:SetFields( aStruct )
oTempTable:AddIndex("1",{"CR_FILIAL","CR_NUM"})

// Criação da tabela
oTempTable:Create()

(cAlias)->(dbGoTop())
nTam := (cAlias)->(FCOUNT())

If	!(cAlias)->(Eof())	

	While !(cAlias)->(Eof())
		RecLock(cTempTab , .T.) 
		For nX := 1 To nTam 
			dbSelectArea(cAlias)
			nY     := aScan(aStruct,{|x|x[1]==ALLTRIM(FIELD(nX))})	
			gDado  := &((cAlias)->(ALLTRIM(FIELD(nX))))
			cCampo := ((cAlias)->(ALLTRIM(FIELD(nX))))
			If cCampo == "CR_STATUS"
				gDado := fTrazCombo(cCampo,gDado)
			EndIf

			If nY > 0
				dbSelectArea(cTempTab)
				If     ValType(&((cAlias)->(ALLTRIM(FIELD(nX))))) == "D"
					&((cTempTab)->(ALLTRIM(FIELD(nY)))) := StoD(gDado)
				ElseIf ValType(&((cAlias)->(ALLTRIM(FIELD(nX))))) == "L"
					x := gdado
				Else
					&((cTempTab)->(ALLTRIM(FIELD(nY)))) := gDado	
				EndIf
			EndIf
		Next	 	
		(cTempTab)->(MsUnLock())		
		(cAlias)->(dbSkip())			
	EndDo
	
EndIf 


If ( Select( cAlias ) > 0 )
	dbSelectArea(cAlias)
	dbCloseArea()
EndIf

For nX := 1 To Len(aStruct)
	If	!aStruct[nX][1] == "CR_OK" .and. !aStruct[nX][1] == "CR_RECNO"
		aAdd(aColumns,FWBrwColumn():New())
		aColumns[nX]:SetData( &("{||"+aStruct[nX][1]+"}") )
		aColumns[nX]:SetTitle(RetTitle(aStruct[nX][1])) 
		aColumns[nX]:SetSize(aStruct[nX][3])
		aColumns[nX]:SetDecimal(aStruct[nX][4]) 
		If	aStruct[nX][1] == "CR_TOTAL"
			aColumns[nX]:SetPicture("@E 999,999,999.99")
		EndIf 	
	EndIf 	
Next nX 

Return({cTempTab , aColumns}) 



/*/{Protheus.doc} SFA094MkB()
Atualiza Marcador do FWMarkBrowse
@param   ExpO    Objeto da MarkBrowse(FWMarkBrowse). 
@sample  SFA094MkB(oMrkBrowse)
@return  ExpL    Verdadeiro / Falso
@author  CRM
@since   24/05/2012       
@version P11   
/*/         
// ======================================================================= \\
Static Function SFA094MkB(oMrkBrowse)
// ======================================================================= \\

If ( !oMrkBrowse:IsMark() )
	RecLock(oMrkBrowse:Alias(),.F.)
	(oMrkBrowse:Alias())->CR_OK  := oMrkBrowse:Mark()
	(oMrkBrowse:Alias())->(MsUnLock())
Else
	RecLock(oMrkBrowse:Alias(),.F.)
	(oMrkBrowse:Alias())->CR_OK  := ""
	(oMrkBrowse:Alias())->(MsUnLock())
EndIf     

Return( .T. )



// ======================================================================= \\
Static Function ArToStru(aCampos)
// ======================================================================= \\

Local nI
Local aTamSX3
Local aStruc := {}

For nI := 1 To Len(aCampos)
	aTamSX3	:= TamSX3(aCampos[nI])
	If AllTrim(aCampos[nI])=="CR_STATUS"
		aAdd(aStruc,{aCampos[nI],aTamSX3[3],30,aTamSX3[2]})
	Else
		aAdd(aStruc,{aCampos[nI],aTamSX3[3],aTamSX3[1],aTamSX3[2]})
	EndIf
Next

Return aStruc



// ======================================================================= \\
Static Function SFA09Apr(cAlias , oDlg) 
// ======================================================================= \\

Local cFilOld := cFilAnt
Local lRet    := .F.
Local cForAnt := ""
Local cLojAnt := "" 
Local aTabSC7 := {}
Local aRecno  := {}
Local nPos    := 0
Local nPos1   := 0
Local cFilD   := ""
Local cNumD   := ""
Local lDebug  := .F.

Private _cMsg := ""		// para retornar o resumo dos envios

cForAnt := "" 
cLojAnt := "" 
lDebug  := .F. 

If MsgYesNo("Deseja aprovar todos os pedidos marcados?")
	lRet := .T.
	dbSelectArea(cAlias)
	dbGoTop()
	While !Eof()

		If (cAlias)->(Empty(CR_OK))
			dbSelectArea(cAlias)
			dbSkip() 
			Loop 
		EndIf 
	
		cFilD   := (cAlias)->CR_FILIAL 
		cNumD   := AllTrim( (cAlias)->CR_NUM ) 
		cFilAnt := cFilD 

		SCR->( dbSetOrder(2) )
		If SCR->( dbSeek( cFilD + "PC" + (cAlias)->CR_NUM + __cUserID) )
		 //	A097ProcLib( SCR->( recno() ), 2)         
		 	// Ajustado pois não estava preenchendo a data da liberação - Talvane (Tupi Consultoria) - 18/12/18
			A097ProcLib( SCR->(Recno()),2,,,,,dDataBase)
			
			SC7->( dbSetOrder(1) )
			If SC7->( dbSeek( cFilD + cNumD ) ) .And. SC7->C7_CONAPRO == "L"
				SC7->(aAdd(aTabSC7 , {C7_FORNECE,C7_LOJA,C7_NUM,Recno()})) 
			EndIf
		EndIf
		/*
		dbSelectArea("SC7")
		dbSetOrder(1)
		MsSeek(cFilD + Alltrim(cNumD))
		While SC7->(!Eof() .And. C7_FILIAL==cFilD .and. C7_NUM==cNumD)
			RecLock("SC7",.F.)
				SC7->C7_CONAPRO := "L"
			MsUnLock()
			SC7->(AAdd(aTabSC7,{C7_FORNECE,C7_LOJA,C7_NUM,Recno()}))
			SC7->(dbSkip())
		EndDo
	
		dbSelectArea("SAK")
		dbSetOrder(2)
		MsSeek(xFilial("SAK")+RetCodUsr())
			
		dbSelectArea("SCR")
		SCR->(dbSetOrder(1))
		SCR->( dbSeek( xFilial("SCR") + "PC" + cNumD ) )
		While ! SCR->( EOF() ) .and. alltrim( SCR->(CR_FILIAL+CR_TIPO+CR_NUM) ) == alltrim( xFilial("SCR") + "PC" + cNumD )
			If Reclock("SCR",.F.)
				SCR->CR_STATUS	:= "03"
				SCR->CR_DATALIB	:= dDataBase
				SCR->CR_USERLIB	:= SAK->AK_USER
				SCR->CR_LIBAPRO	:= SAK->AK_COD
				SCR->CR_VALLIB	:= SCR->CR_TOTAL  //nValDcto
				SCR->CR_TIPOLIM	:= SAK->AK_TIPO
				SCR->(MsUnLock())
				nRecAprov := SCR->(RecNo())
			EndIf
			SCR->( dbSkip() )
		EndDo

		cFilSCR  := SCR->CR_FILIAL
		cTipoDoc := SCR->CR_TIPO
		cDocto   := SCR->CR_NUM
		SCR->(dbSeek(cFilSCR + cTipoDoc + cDocto))  //Posiciona no SCR
		While SCR->(!Eof()) .And. SCR->(CR_FILIAL+CR_TIPO+CR_NUM) == cFilSCR + cTipoDoc + cDocto
			If SCR->CR_STATUS != "03" 
				If Reclock("SCR",.F.)
					SCR->CR_STATUS	:= "05"
					SCR->CR_DATALIB	:= dDataBase
					SCR->CR_USERLIB	:= SAK->AK_USER
				 //	SCR->CR_APROV	:= cAprov
				 //	SCR->CR_OBS		:= ""
					SCR->(MsUnLock())
				EndIf
			EndIf
			SCR->(dbSkip())
		EndDo
		*/
		dbSelectArea(cAlias)
		dbSkip()
	EndDo
	
	oDlg:End() 
EndIf 

aSort( aTabSC7, , , {|x,y| x[1]+x[2]+x[3] < y[1]+y[2]+y[3] } )  //Classifica por C7_FORNECE+C7_LOJA+C7_NUM

nPos := 1
While nPos <= Len( aTabSC7 ) 
	aRecno  := {}
	cPeds   := ""
	cForAnt := aTabSC7[nPos,1] + aTabSC7[nPos,2]
	While nPos <= Len(aTabSC7)  .And.  cForAnt == aTabSC7[nPos,1] + aTabSC7[nPos,2]
		If ! aTabSC7[nPos,3] $ cPeds
			cPeds += aTabSC7[nPos,3] + ";"
			aAdd( aRecno , aTabSC7[nPos,4] ) 
		EndIf
		nPos++
	EndDo

	ConOut("##_MTA094RO.prw - SFA09Apr() - Fornecedor: "+Transform(cForAnt, "@R 999999/99")) 
	VarInfo("aRecno" , aRecno) 

	_cMsg += CRLF + "Fornecedor: "+Transform(cForAnt, "@R 999999/99") + CRLF
	U_SFCMP06A(aRecno)  			// Envia e-mail com os pedidos de compra liberados do mesmo fornecedor
EndDo 

Aviso("LOG: envio de e-mail aos fornecedores", _cMsg, {"Ok"}, 3)

cFilAnt := cFilOld 

Return lRet



// ======================================================================= \\
Static Function fTrazCombo(cCampo,cValor)
// ======================================================================= \\

Local nInitcBox,nTam
Local aCombo := {}
Local nPos   := 0
Local cRet   := ""

SX3->(dbSetOrder(2))
SX3->(dbSeek(cCampo))
xxCombo:=X3Cbox()
aCombo:=RetSX3Box(X3Cbox(),@nInitCBox,@nTam,SX3->X3_TAMANHO)
SX3->(dbSetOrder(1))
nPos:=Ascan(aCombo,{|x|cValor$x[2]})

If nPos>0
	cRet:=aCombo[nPos,3]
EndIf

Return(cRet)

