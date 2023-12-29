#Include "Protheus.ch"
#INCLUDE "report.ch"
#Include "CTBR357.ch"  

//-------------------------------------------------------------------
/*/{Protheus.doc}CTBA012
RELATORIO DE LOG DE CONTABILIZAÇÃO
@author Mayara Alves
@since  24/04/2014
@version 12
/*/
//-------------------------------------------------------------------

/*
------------------------------------------------
* Prox Consultoria
* Melhorias: Chamado nr. 23893 - 06/05/2022
* Relatorio Padrao - CTBR357
* Grupo de Perguntas original - CTR357
* Grupo de Perguntas novo XSLF357
* Consultor: Tatiana Pontes
------------------------------------------------
*/

User Function SLFTR357()

Local oReport
Local aArea        := GetArea()
Local aCtbMoeddesc := {}

Private aSelFil    := {}
Private cFil	   := CFILANT
Private cPerg      := "XSLF357"

If pergunte(cPerg,.T.)

	//valida moeda
	If Empty( MV_PAR04 ) 
		Help(" ",1,"NOMOEDA")
		Return
	EndIf

	 aCtbMoeddesc := CtbMoeda(mv_par04) // Moeda?

	 If Empty( aCtbMoeddesc[1] )
		Help(" ",1,"NOMOEDA")
		aCtbMoeddesc := nil
	    Return
	Endif		

	If mv_par10 == 1 .And. Len( aSelFil ) <= 0  .And. !IsBlind()
		aSelFil := AdmGetFil()
		If Len( aSelFil ) <= 0
			Return
		EndIf
	EndIf

	oReport := ReportDef()
	oReport:PrintDialog()
EndIf

RestArea(aArea)

Return

/*{Protheus.doc} ReportDef
ROTINA PARA CRIAR O RELATORIO EM TREPORT
@author Mayara Alves
@version P12
@since   24/04/2015
*/

Static Function ReportDef()
Local oReport
Local oSection1
Local oBreak	//-- Objeto de quebra       
Local cAliasQry := GetNextAlias() 
Local cTexto := ""
Local cTitFun :=""

Local cTitulo	:= STR0001 //"Relatório de Log de Contabização"

Local aOrd    := {	STR0002,; //"Fil+DtLcto+NumLote+SubLote+NumDoc"
						STR0003,; //"Cta Debito+Data 'Lcto'"
						STR0004	} //"Cta Credito+Data Lcto"
Local lSepPart	:= MV_PAR09 == 2 //Separa partida dobrada

//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
//³Criacao dos componentes de impressao                                    ³
//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ

DEFINE REPORT oReport NAME "CTBR357" TITLE cTitulo PARAMETER cPerg ACTION {|oReport| PrintReport(oReport,cAliasQry)} DESCRIPTION STR0005//"Este programa emite a Impressão de Relatório de Log de Contabização."

oReport:SetUseGC(.F.) 
oReport:nfontbody 	:= 6   //Tamanho da Fonte
oReport:SetLandscape()		//orientação paisagem

DEFINE SECTION oSection1 OF oReport TITLE "LOG" TABLES "CT2" TOTAL IN COLUMN ORDERS aOrd  //Contratos

DEFINE CELL NAME "CT2_FILIAL" 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_FILIAL")[1]	TITLE PadR(Alltrim(RetTitle("CT2_FILIAL")),TamSX3("CT2_FILIAL" )[1]+1)
DEFINE CELL NAME "CT2_DATA" 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_DATA" )[1]+2   // 10
DEFINE CELL NAME "CT2_LOTE"		OF oSection1 ALIAS "CT2" size TamSX3("CT2_LOTE" )[1]  TITLE STR0013	//"Lote"
DEFINE CELL NAME "CT2_SBLOTE"	OF oSection1 ALIAS "CT2" size TamSX3("CT2_SBLOTE")[1]	TITLE PadR(Alltrim(RetTitle("CT2_SBLOTE")),TamSX3("CT2_SBLOTE")[1])	// 10  
DEFINE CELL NAME "CT2_DOC"	 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_DOC" )[1]	 TITLE STR0014 //"Documento"
DEFINE CELL NAME "CT2_LINHA" 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_LINHA")[1]	TITLE STR0015 //"linha"

If lSepPart
	DEFINE CELL NAME "CT2_DEBITO" 	OF oSection1 BLOCK {|| If((cAliasQry)->TIPO == "1",(cAliasQry)->CONTA,"")} ALIAS "CT2" 	size TamSX3("CT2_DEBITO")[1]	// 10
	DEFINE CELL NAME "CT2_CREDIT" 	OF oSection1 BLOCK {|| If((cAliasQry)->TIPO == "2",(cAliasQry)->CONTA,"")} ALIAS "CT2" 	size TamSX3("CT2_CREDIT")[1]	// 10
	DEFINE CELL NAME "CT2_CCD" 	 	OF oSection1 BLOCK {|| If((cAliasQry)->TIPO == "1",(cAliasQry)->CUSTO,"")} ALIAS "CT2" 	size TamSX3("CT2_CCD"   )[1]	// 10
	DEFINE CELL NAME "CT2_CCC" 	 	OF oSection1 BLOCK {|| If((cAliasQry)->TIPO == "2",(cAliasQry)->CUSTO,"")} ALIAS "CT2" 	size TamSX3("CT2_CCC"   )[1]	// 10
	DEFINE CELL NAME "CT2_ITEMD" 	OF oSection1 BLOCK {|| If((cAliasQry)->TIPO == "1",(cAliasQry)->ITEM,"")}  ALIAS "CT2" 	size TamSX3("CT2_ITEMD" )[1]	// 10
	DEFINE CELL NAME "CT2_ITEMC" 	OF oSection1 BLOCK {|| If((cAliasQry)->TIPO == "2",(cAliasQry)->ITEM,"")}  ALIAS "CT2" 	size TamSX3("CT2_ITEMC" )[1]	// 10
Else
	DEFINE CELL NAME "CT2_DEBITO" 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_DEBITO")[1]	// 10
	DEFINE CELL NAME "CT2_CREDIT" 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_CREDIT")[1]	// 10
	DEFINE CELL NAME "CT2_CCD" 	 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_CCD"   )[1]	// 10
	DEFINE CELL NAME "CT2_CCC" 	 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_CCC"   )[1]	// 10
	DEFINE CELL NAME "CT2_ITEMD" 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_ITEMD" )[1]	// 10
	DEFINE CELL NAME "CT2_ITEMC" 	OF oSection1 ALIAS "CT2" size TamSX3("CT2_ITEMC" )[1]	// 10
EndIf

DEFINE CELL NAME "CT2_VALOR" 	OF oSection1 ALIAS "CT2" size (TamSX3("CT2_VALOR" )[1]+TamSX3("CT2_VALOR" )[2])	// 10
DEFINE CELL NAME "CT2_HIST" 	OF oSection1 BLOCK {|| FHist((cAliasQry)->CT2_FILIAL,(cAliasQry)->CT2_DATA,(cAliasQry)->CT2_LOTE,(cAliasQry)->CT2_SBLOTE,(cAliasQry)->CT2_DOC,(cAliasQry)->CT2_MOEDLC,(cAliasQry)->CT2_SEQLAN)} ALIAS "CT2"  size 25

DEFINE CELL NAME STR0016		OF oSection1 BLOCK {|| Posicione('SX5',1,xFilial('SX5')+'SL'+(cAliasQry)->CT2_TPSALD, "X5DESCRI()")} ALIAS "CT2" size TamSX3("CT2_TPSALD" )[1] //"Tp Saldo"
DEFINE CELL NAME STR0017		OF oSection1 BLOCK {|| Iif((Alltrim((cAliasQry)->CT2_MANUAL) == "1"), STR0011,STR0012)} size TamSX3("CT2_MANUAL" )[1]+6  //"Tp Lcto"  10 //"Tipo" ## "Manual" ## "Sistema"
DEFINE CELL NAME STR0008 		OF oSection1 BLOCK {|| FUserLg((cAliasQry)->R_E_C_N_O_,.T.)} 	size 10 //"Usuário"
DEFINE CELL NAME STR0009 		OF oSection1 BLOCK {|| FUserLg((cAliasQry)->R_E_C_N_O_,.F.)} 	size 10 //"Data"

oSection1:Cell("CT2_HIST"):SetLineBreak(.T.) //Quebra linha 

Return (oReport)

//-------------------------------------------------------------------
/*/{Protheus.doc}PrintReport
ROTINA QUE ORDENA E REALIZA A QUERY	
@author Mayara Alves
@since  24/04/2014
@param oReport 		- Objeto do relatorio 
@param cAliasQry	- alias
@version 12
/*/
//-------------------------------------------------------------------
Static Function PrintReport(oReport,cAliasQry)

Local oSection := oReport:Section(1)
Local nOrdem   := oSection:GetOrder()

Local dPerg

Local cConta   := "" //MV_PAR05	//Conta
Local cCC      := "" //MV_PAR06	//Centro de Custo
Local cItem    := "" //MV_PAR07	//Item Contabil
Local cClVal   := "" //MV_PAR08	//Classe de Valor
Local cWQuery  := ""
Local lPartDob := .T.
Local nX       := 1

Default cAliasQry := ""
Default oReport	:= Nil

//Transforma parametros do tipo Range em expressao ADVPL para ser utilizada no filtro
MakeSqlExpr(cPerg)

If Len(aSelFil) > 0
	cFil := ""
	For nX := 1 to Len(aSelFil)
		cFil += "'"+aSelFil[nX]+"'"
		If nX < Len(aSelFil)
			cFil += ","
		Endif
	Next
	cFil := "%" + cFil + "%"
Endif

If !Empty(MV_PAR01) //DATA
	cWQuery := "AND "+MV_PAR01
EndIf

If !Empty(MV_PAR02) .And. MV_PAR02 <> 3 //LANCAMENTO
	cWQuery += "AND CT2_MANUAL = '"+cValToChar(MV_PAR02)+"'"
EndIf

If !Empty(MV_PAR03) //TIPO SALDO
	cWQuery += "AND CT2_TPSALD ='"+MV_PAR03+"'"	
EndIf

If !Empty(MV_PAR04)  //MOEDA
	cWQuery += "AND CT2_MOEDLC = '"+MV_PAR04+"'"
EndIf

If !Empty(MV_PAR05) //CONTA
	cContaD	:= MV_PAR05
	cContaC	:= STRTRAN(cContaD,'CT2_DEBITO','CT2_CREDIT')
	cWQuery += " AND( "+cContaD + " OR "+ cContaC +" )"
EndIf
If !Empty(MV_PAR06) //Centro de Custo
	cCCD		:= MV_PAR06	
	cCCC		:= STRTRAN(cCCD,'CT2_CCD','CT2_CCC')
	cWQuery += " AND( "+cCCD + " OR "+ cCCC +" )"
EndIf
If !Empty(MV_PAR07)//Item Contabil
	cItemD		:= MV_PAR07	
	cItemC		:= STRTRAN(cItemD,'CT2_ITEMD','CT2_ITEMC')
	cWQuery += " AND( "+cItemD + " OR "+ cItemC +" )"
EndIf
If !Empty(MV_PAR08)//Classe de Valor
	cClValD	:= MV_PAR08	
	cClValC	:= STRTRAN(cClValD,'CT2_CLVLDB','CT2_CLVLCR')
	cWQuery += " AND( "+cClValD + " OR "+ cClValC +" )"
EndIf
If !Empty(MV_PAR09)//Divide partida
	If MV_PAR09 == 2
		lPartDob := .F.
	EndIf
EndIf

cWQuery := "%"+cWQuery+"%"

If nOrdem == 1
	cOrdem := "%CT2_FILIAL,CT2_DATA,CT2_LOTE,CT2_SBLOTE%"
ElseIf nOrdem == 2
	cOrdem := "%CT2_FILIAL,CT2_DEBITO,CT2_DATA)%"
ElseIf nOrdem == 3
	cOrdem := "%CT2_FILIAL,CT2_CREDIT,CT2_DATA)%"
Endif

If lPartDob
	BEGIN REPORT QUERY oSection
		BeginSql alias cAliasQry

			SELECT CT2_FILIAL,CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC,CT2_LINHA,
			CT2_DEBITO,CT2_CREDIT,CT2_CCD,CT2_CCC,CT2_ITEMD,CT2_ITEMC,CT2_CLVLDB,
			CT2_CLVLCR,CT2_VALOR,CT2_HIST,CT2_TPSALD, R_E_C_N_O_,CT2_MANUAL, CT2_MOEDLC
			,CT2_SEQLAN
			FROM %table:CT2% CT2
			//WHERE CT2_FILIAL = %xfilial:CT2%
			WHERE CT2_FILIAL IN (%exp:cFil%)
			%exp:Upper(cWQuery)%
			AND CT2_DC <> '4'
			AND CT2.%notDel%
   			ORDER BY %exp:cOrdem%
		EndSql

	END REPORT QUERY oSection
Else
	BeginSql alias cAliasQry
	 SELECT CT2_FILIAL,CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC,CT2_DC,'1' TIPO,CT2_DEBITO CONTA,CT2_LINHA,
		CT2_CCD CUSTO, CT2_ITEMD ITEM, CT2_VALOR, CT2_HIST, CT2_TPSALD, R_E_C_N_O_,CT2_MANUAL, CT2_MOEDLC,CT2_SEQLAN

		FROM %table:CT2% CT2
	  //WHERE CT2_FILIAL = %xfilial:CT2%
		WHERE CT2_FILIAL IN (%exp:cFil%)
			AND CT2_DC IN ('1','3')
			%exp:Upper(cWQuery)%
			AND CT2.%notDel%

		UNION
		
		SELECT CT2_FILIAL,CT2_DATA,CT2_LOTE,CT2_SBLOTE,CT2_DOC,CT2_DC,'2' TIPO ,CT2_CREDIT CONTA,CT2_LINHA,
		CT2_CCC CUSTO, CT2_ITEMC ITEM, CT2_VALOR, CT2_HIST, CT2_TPSALD,R_E_C_N_O_,CT2_MANUAL, CT2_MOEDLC,CT2_SEQLAN

		FROM %table:CT2% CT2
			//WHERE CT2_FILIAL = %xfilial:CT2%
			WHERE CT2_FILIAL IN (%exp:cFil%)
			AND CT2_DC IN ('2','3')
			%exp:Upper(cWQuery)%
			AND CT2.%notDel%

		ORDER BY %exp:cOrdem%
	EndSql

END REPORT QUERY oSection
EndIf

TcSetField(cAliasQry, "CT2_DATA", "D", 8, 0)

//-- Define o total da regua da tela de processamento do relatorio
oReport:SetMeter( 100 )  

oSection:Print()	 //Imprimir

Return ()

//-------------------------------------------------------------------
/*/{Protheus.doc}FUserLg
ROTINA PARA TRAZER O NOME DO USUARIO OU A DATA DE ALTERAÇÃO DA CONTABILIZAÇÃO
@author Mayara Alves
@since  24/04/2014
@param cRecno - numero do registro 
@param lUser	- Se é o nome do usuario
@return cRet - Nome ou Data do usuario da alteração
@version 12
/*/
//-------------------------------------------------------------------
Static Function FUserLg(cRecno,lUser)
Local aArea 		:= GetArea()
Local aAreaCT2	:= CT2->(GetArea())
Local cRet			:= ""

Default cRecno := ""
Default lUser := .T.

dbSelectArea("CT2") 
CT2->(dbGoto(cRecno))
If lUser
	If EMPTY(CT2->CT2_USERGA)
		cRet:=	FWLeUserlg("CT2->CT2_USERGI",1)//+ " "+FWLeUserlg("CT2->CT2_USERGI",2)
	Else
		cRet:= FWLeUserlg("CT2->CT2_USERGA",1)//+ " "+FWLeUserlg("CT2->CT2_USERGA",2)
	EndIf
Else
	If EMPTY(CT2->CT2_USERGA)
		cRet:=	FWLeUserlg("CT2->CT2_USERGI",2)//+ " "+FWLeUserlg("CT2->CT2_USERGI",2)
	Else
		cRet:= FWLeUserlg("CT2->CT2_USERGA",2)//+ " "+FWLeUserlg("CT2->CT2_USERGA",2)
	EndIf
EndIf

RestArea(aAreaCT2)
RestArea(aArea)
Return cRet

//-------------------------------------------------------------------
/*/{Protheus.doc}FHist
TRAZ O HISTORICO DA CONTABILIZAÇÃO
@author Mayara Alves
@since  24/04/2014
@param cFIL - Filial
@param dDATA	- data
@param cLOTE	- lote
@param cSBLOTE	- sub lote
@param cDOC	- doc
@param cMoeda	- Moeda do lancamento
@param cSeqLan	- Sequencia do lancamento
@return cRet - historico concatenado
@version 12
/*/
//-------------------------------------------------------------------
Static Function FHist(cFil,dData,cLote,cSBLote,cDoc,cMoeda,cSeqLan)
Local aArea		:= GetArea()
Local cAliasCT2	:= GetNextAlias()
Local cRet		:= ""

Default cFil	:= ""
Default dData	:= SToD("")
Default cLote	:= ""
Default cSBLote	:= ""
Default cDoc	:= ""
Default cMoeda	:= ""
Default cSeqLan	:= ""

BeginSQL Alias cAliasCT2
	SELECT
		CT2_HIST
	FROM
		%Table:CT2% CT2
	WHERE
		CT2_FILIAL		= %Exp:cFil%
		AND CT2_DATA	= %Exp:dData% 
		AND CT2_LOTE	= %Exp:cLote%
		AND CT2_SBLOTE	= %Exp:cSBLote%
		AND CT2_DOC		= %Exp:cDoc%
		AND CT2_MOEDLC	= %Exp:cMoeda%
		AND CT2_SEQLAN	= %Exp:cSeqLan%
		AND CT2.%NotDel%
	ORDER BY %Order:CT2%
EndSQL

While !(cAliasCT2)->(EOF())
	cRet += (cAliasCT2)->CT2_HIST
(cAliasCT2)->( DbSkip() )
EndDo

(cAliasCT2)->( DbCloseArea() )

RestArea(aArea)

Return cRet

/*
==============================================================
Autor: Fernando Pessoa
Data: 31/03/2022
Uso: OAB
Info: Perguntas da SX1
==================================================================*/

Static Function AjustaSX1(cPerg)
	
	Local aRegs := {}
	Local I, J
	
	//Adiciono um novo elemento no final do array
	aadd(aRegs, {cPerg, "01", "Data ? "                  , "", "", "mv_ch1", "D", 08, 00, 0, "R", "", "mv_par01", ""      , ""      , ""      , "CT2_DATA"  , "", ""       , ""       , ""       , "", "", ""     , ""     , ""    , "", "", "", "", "", "", "", "", "", "", "", ""})
	aadd(aRegs, {cPerg, "02", "Lançamento ? "            , "", "", "mv_ch2", "C", 01, 00, 0, "C", "", "mv_par02", "Manual", "Manual", "Manual", ""          , "", "Sistema", "Sistema", "Sistema", "", "", "Ambos", "Ambos", "Both", "", "", "", "", "", "", "", "", "", "", "", ""})
	aadd(aRegs, {cPerg, "03", "Tipo de Saldo ? "         , "", "", "mv_ch3", "C", 01, 00, 0, "G", "", "mv_par03", ""      , ""      , ""      , ""          , "", ""       , ""       , ""       , "", "", ""     , ""     , ""    , "", "", "", "", "", "", "", "", "", "", "", "SLW"})
	aadd(aRegs, {cPerg, "04", "Moeda ? "                 , "", "", "mv_ch4", "C", 02, 00, 0, "G", "", "mv_par04", ""      , ""      , ""      , ""          , "", ""       , ""       , ""       , "", "", ""     , ""     , ""    , "", "", "", "", "", "", "", "", "", "", "", "CTO"})
	aadd(aRegs, {cPerg, "05", "Conta ? "                 , "", "", "mv_ch5", "C", 20, 00, 0, "R", "", "mv_par05", ""      , ""      , ""      , "CT2_DEBITO", "", ""       , ""       , ""       , "", "", ""     , ""     , ""    , "", "", "", "", "", "", "", "", "", "", "", "CT1"})
	aadd(aRegs, {cPerg, "06", "Centro de Custo ? "       , "", "", "mv_ch6", "C", 09, 00, 0, "R", "", "mv_par06", ""      , ""      , ""      , "CT2_CCD"   , "", ""       , ""       , ""       , "", "", ""     , ""     , ""    , "", "", "", "", "", "", "", "", "", "", "", "CTT"})
	aadd(aRegs, {cPerg, "07", "Item Contábil ? "         , "", "", "mv_ch7", "C", 09, 00, 0, "R", "", "mv_par07", ""      , ""      , ""      , "CT2_ITEMD" , "", ""       , ""       , ""       , "", "", ""     , ""     , ""    , "", "", "", "", "", "", "", "", "", "", "", "CTD"})
	aadd(aRegs, {cPerg, "08", "Classe de Valor ? "       , "", "", "mv_ch8", "C", 09, 00, 0, "R", "", "mv_par08", ""      , ""      , ""      , "CT2_CLVLDB", "", ""       , ""       , ""       , "", "", ""     , ""     , ""    , "", "", "", "", "", "", "", "", "", "", "", "CTH"})
	aadd(aRegs, {cPerg, "09", "Divide partida dobrada ? ", "", "", "mv_ch9", "C", 01, 00, 0, "C", "", "mv_par09", "Nao"   , "No"    , "No"    , ""          , "", "Sim"    , "Si"     , "Yes"    , "", "", ""     , ""     , ""    , "", "", "", "", "", "", "", "", "", "", "", ""})
	aadd(aRegs, {cPerg, "10", "Seleciona Filiais ? "     , "", "", "mv_chA", "N", 01, 00, 1, "C", "", "mv_par10", "Sim"   , "Si"    , "Yes"   , ""          , "", "Nao"    , "No"     , "No"     , "", "", ""     , ""     , ""    , "", "", "", "", "", "", "", "", "", "", "", ""})
	
	DbSelectArea("SX1")
	SX1->(DbSetOrder(1))
	
	For I := 1 To Len(aRegs)
		If !DbSeek(cPerg + aRegs[I,2])
			RecLock("SX1",.T.)
			For J := 1 To FCount()
				If J <= Len(aRegs[I])
					FieldPut(J,aRegs[I,J])
				Endif
			Next
			SX1->(MsUnlock())
		Endif
	Next

Return
