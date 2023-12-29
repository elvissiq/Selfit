#INCLUDE "PROTHEUS.CH"
#INCLUDE "COLORS.CH"

Static __lClassifica	:= .T.

// ======================================================================= \\
/*/{Protheus.doc} MCATFP02
Campos Complementares Cadastro de Vendedor.
@protected
@author    Ederson Colen.
@since     09/01/2017
@obs       
/*/
// ======================================================================= \\
User Function MCATFP02()
// ======================================================================= \\

// Executa a filtragem dos dados
oProcess := MsNewProcess():New( {|| MCATFP02()} )
oProcess:Activate()

Return NIL


Static Function MCATFP02()

Local   aArea    := GetArea()
Local   cMarca   := oMark:Mark()
Local   lInverte 
Local   dDInDepr := CToD("")
Local   dMVUDepr := GETMV("MV_ULTDEPR")

Private cAliLot	 := "TMPLOT"
Private cAliTN1X := "TMPN1X"
Private cAliTN3  := "TMPN3"
Private cAliTN4  := "TMPN4"
Private cAliTNN  := "TMPNN"

lInverte := oMark:IsInvert()

FCrTrbL()

oProcess:SetRegua2(SN1->( reccount())+2)
oProcess:IncRegua2("Processando ...") 

SN3->(dbSetOrder(1)) //N3_FILIAL+N3_CBASE+N3_ITEM+N3_TIPO+N3_BAIXA+N3_SEQ
     
//Percorrendo os registros da SN1
SN1->(dbGoTop())

While SN1->(! Eof())
	oProcess:IncRegua2("Processando ...")
	
	//Caso esteja marcado, aumenta o contador
	If oMark:IsMark(cMarca)
		
		SN3->(dbSeek(xFilial("SN3")+SN1->N1_CBASE+SN1->N1_ITEM))
		If SN3->(! Eof())
			If ! Empty(SN3->N3_DINDEPR)
				dDInDepr := SN3->N3_DINDEPR
			Else
				If SN3->N3_AQUISIC > dMVUDepr
					dDInDepr := SN3->N3_AQUISIC
				EndIf
			EndIf
		EndIf

		RecLock(cAliLot, .T.)
		(cAliLot)->N1_FILIAL	:= SN1->N1_FILIAL
		(cAliLot)->N1_CBASE		:= SN1->N1_CBASE
		(cAliLot)->N1_ITEM		:= SN1->N1_ITEM		
		(cAliLot)->N1_DESCRIC	:= SN1->N1_DESCRIC
		(cAliLot)->N1_QUANTD	:= SN1->N1_QUANTD
		(cAliLot)->N1_FORNEC	:= SN1->N1_FORNEC
		(cAliLot)->N1_LOJA		:= SN1->N1_LOJA
		(cAliLot)->N1_NSERIE	:= SN1->N1_NSERIE
		(cAliLot)->N1_NFISCAL	:= SN1->N1_NFISCAL
		(cAliLot)->N1_RECNO		:= SN1->(RECNO())
		(cAliLot)->N3_DINDEPR	:= dDInDepr
		(cAliLot)->N3_DINDANT	:= dDInDepr		
		(cAliLot)->N3_AQUISIC	:= SN3->N3_AQUISIC
		(cAliLot)->N3_SEQ		:= SN3->N3_SEQ
		(cAliLot)->N3_TPSALDO	:= SN3->N3_TPSALDO
		(cAliLot)->N3_CCONTAB	:= SN3->N3_CCONTAB
		(cAliLot)->XX_DELETAD	:= "N"		 
		(cAliLot)->(MsUnlock())

		FGrRegTMP()

	EndIf

	SN1->(dbSkip())
 
EndDo

FPrClLot()

 //Restaurando área armazenada
 RestArea(aArea)

Return NIL



Static Function FCrTrbL()

Local aStruTRB	:= {}
Local cArqTrTRB	:= ""

Local aStruSN1	:= SN1->(DBSTRUCT())
Local aStruSN3	:= SN3->(DBSTRUCT())
Local aStruSN4	:= SN4->(DBSTRUCT())
Local aStruSNN	:= SNN->(DBSTRUCT())

Local cArqTrN1	:= ""
Local cArqTrN3	:= ""
Local cArqTrN4	:= ""
Local cArqTrNN	:= ""

Aadd(aStruTRB,{"N1_FILIAL",TAMSX3("N1_FILIAL")[03],TAMSX3("N1_FILIAL")[01],TAMSX3("N1_FILIAL")[02]})
Aadd(aStruTRB,{"N1_CBASE",TAMSX3("N1_CBASE")[03],TAMSX3("N1_CBASE")[01],TAMSX3("N1_CBASE")[02]})
Aadd(aStruTRB,{"N1_ITEM",TAMSX3("N1_ITEM")[03],TAMSX3("N1_ITEM")[01],TAMSX3("N1_ITEM")[02]})
Aadd(aStruTRB,{"N1_DESCRIC",TAMSX3("N1_DESCRIC")[03],TAMSX3("N1_DESCRIC")[01],TAMSX3("N1_DESCRIC")[02]})
Aadd(aStruTRB,{"N1_QUANTD",TAMSX3("N1_QUANTD")[03],TAMSX3("N1_QUANTD")[01],TAMSX3("N1_QUANTD")[02]})
Aadd(aStruTRB,{"N3_DINDEPR",TAMSX3("N3_DINDEPR")[03],TAMSX3("N3_DINDEPR")[01],TAMSX3("N3_DINDEPR")[02]})
Aadd(aStruTRB,{"N3_DINDANT",TAMSX3("N3_DINDEPR")[03],TAMSX3("N3_DINDEPR")[01],TAMSX3("N3_DINDEPR")[02]})
Aadd(aStruTRB,{"N3_AQUISIC",TAMSX3("N3_AQUISIC")[03],TAMSX3("N3_AQUISIC")[01],TAMSX3("N3_AQUISIC")[02]})
Aadd(aStruTRB,{"N1_FORNEC",TAMSX3("N1_FORNEC")[03],TAMSX3("N1_FORNEC")[01],TAMSX3("N1_FORNEC")[02]})
Aadd(aStruTRB,{"N1_LOJA",TAMSX3("N1_LOJA")[03],TAMSX3("N1_LOJA")[01],TAMSX3("N1_LOJA")[02]})
Aadd(aStruTRB,{"N1_NSERIE",TAMSX3("N1_NSERIE")[03],TAMSX3("N1_NSERIE")[01],TAMSX3("N1_NSERIE")[02]})
Aadd(aStruTRB,{"N1_NFISCAL",TAMSX3("N1_NFISCAL")[03],TAMSX3("N1_NFISCAL")[01],TAMSX3("N1_NFISCAL")[02]})
Aadd(aStruTRB,{"N3_SEQ",TAMSX3("N3_SEQ")[03],TAMSX3("N3_SEQ")[01],TAMSX3("N3_SEQ")[02]})
Aadd(aStruTRB,{"N3_CCONTAB",TAMSX3("N3_CCONTAB")[03],TAMSX3("N3_CCONTAB")[01],TAMSX3("N3_CCONTAB")[02]})
Aadd(aStruTRB,{"N3_TPSALDO",TAMSX3("N3_TPSALDO")[03],TAMSX3("N3_TPSALDO")[01],TAMSX3("N3_TPSALDO")[02]})
Aadd(aStruTRB,{"N1_RECNO","N",10,0})
Aadd(aStruTRB,{"XX_DELETAD","C",01,0})

//Fecha o arquivo caso esteja aberto
U_FCloseArea(cAliLot)

cArqTrTRB := CriaTrab(aStruTRB,.T.)
dbUseArea(.T.,,cArqTrTRB,cAliLot,.F.,.F.)
IndRegua(cAliLot,cArqTrTRB,"N1_CBASE+N1_ITEM",,,"Selecionando registros...")

//Fecha o arquivo caso esteja aberto
U_FCloseArea(cAliTN1X)

//SN1
cArqTrN1 := CriaTrab(aStruSN1,.T.)
dbUseArea(.T.,,cArqTrN1,cAliTN1X,.F.,.F.)
IndRegua(cAliTN1X,cArqTrN1,"N1_FILIAL+N1_CBASE+N1_ITEM",,,"Selecionando registros...")

//SN3
//Fecha o arquivo caso esteja aberto
U_FCloseArea(cAliTN3)

cArqTrN3 := CriaTrab(aStruSN3,.T.)
dbUseArea(.T.,,cArqTrN3,cAliTN3,.F.,.F.)
IndRegua(cAliTN3,cArqTrN3,"N3_FILIAL+N3_CBASE+N3_ITEM+N3_TIPO+N3_BAIXA+N3_SEQ",,,"Selecionando registros...")

//Fecha o arquivo caso esteja aberto
U_FCloseArea(cAliTN4)

//SN4
cArqTrN4 := CriaTrab(aStruSN4,.T.)
dbUseArea(.T.,,cArqTrN4,cAliTN4,.F.,.F.)
IndRegua(cAliTN4,cArqTrN4,"N4_FILIAL+N4_CBASE+N4_ITEM+N4_TIPO+DTOS(N4_DATA)+N4_OCORR+N4_SEQ",,,"Selecionando registros...")

//Fecha o arquivo caso esteja aberto
U_FCloseArea(cAliTNN)

//SNN
cArqTrNN := CriaTrab(aStruSNN,.T.)
dbUseArea(.T.,,cArqTrNN,cAliTNN,.F.,.F.)
IndRegua(cAliTNN,cArqTrNN,"NN_FILIAL+NN_CODIGO+NN_ITEM",,,"Selecionando registros...")

Return NIL



// ======================================================================= \\
Static Function FGrRegTMP()
// ======================================================================= \\

Local aStruSN1	:= SN1->(DBSTRUCT())
Local aStruSN3	:= SN3->(DBSTRUCT())
Local aStruSN4	:= SN4->(DBSTRUCT())
Local aStruSNN	:= SNN->(DBSTRUCT())

Local nXX		:= 0

RecLock(cAliTN1X, .T.)
For nXX := 1 To Len(aStruSN1)
	(cAliTN1X)->&(aStruSN1[nXX,01]) := SN1->&(aStruSN1[nXX,01])
Next nXX
(cAliTN1X)->(MsUnlock())

RecLock(cAliTN3, .T.)
For nXX := 1 To Len(aStruSN3)
	(cAliTN3)->&(aStruSN3[nXX,01]) := SN3->&(aStruSN3[nXX,01])
Next nXX
(cAliTN3)->(MsUnlock())

SN4->(dbSetOrder(4))
SN4->(msSeek(xFilial("SN4")+SN1->N1_CBASE+SN1->N1_ITEM))
While ! SN4->(Eof()) .AND. AllTrim(SN1->N1_CBASE+SN1->N1_ITEM) == AllTrim(SN4->(N4_CBASE+N4_ITEM))

	RecLock(cAliTN4, .T.)
	For nXX := 1 To Len(aStruSN4)
		(cAliTN4)->&(aStruSN4[nXX,01]) := SN4->&(aStruSN4[nXX,01])
	Next nXX
	(cAliTN4)->(MsUnlock())

	SN4->(dbSkip())
EndDo

SNN->(dbSetOrder(2))
If SNN->(dbSeek(xFilial("SNN")+SN1->N1_CBASE))
	RecLock(cAliTNN, .T.)
	For nXX := 1 To Len(aStruSNN)
		(cAliTNN)->&(aStruSNN[nXX,01]) := SNN->&(aStruSNN[nXX,01])
	Next nXX
	(cAliTNN)->(MsUnlock())
EndIf

Return NIL



// ======================================================================= \\
Static Function FPrClLot()
// ======================================================================= \\

Local aArea		 := GetArea()
Local aButtons	 := {}
Local aCpoEnch	 := {"N1_GRUPO","N1_CBASE","N1_CHAPA","N1_TPBEM","N1_CALCPIS","N1_ORIGCRD","N1_DETPATR","N1_UTIPATR","N1_CSTPIS","N1_ALIQPIS","N1_CSTCOFI",;
						"N1_ALIQCOF","N1_CODBCC","N1_MESCPIS","N1_CBCPIS","N3_TIPO","N3_HISTOR","N3_CUSTBEM","N3_CCUSTO","N3_DINDEPR"}

Local aAlterEnch := {"N1_GRUPO","N1_CHAPA","N1_TPBEM","N1_CALCPIS","N1_ORIGCRD","N1_DETPATR","N1_UTIPATR","N1_CSTPIS","N1_ALIQPIS","N1_CSTCOFI",;
						"N1_ALIQCOF","N1_CODBCC","N1_MESCPIS","N1_CBCPIS","N3_TIPO","N3_HISTOR","N3_CUSTBEM","N3_CCUSTO","N3_DINDEPR"}

Local lMemoria	 := .T.
Local aField	 := {}
Local aFolder	 := {"Parâmetros Classificação"}
Local lCreate    := .T.

// Propriedades da GetDados
// Local nX

Local aTamTela	:= {000,000,650,1200}
Local aTamGet	:= {012,300,325,0600}
Local aPDadRet	:= {035,005,320,0300}

Local lSaiTela := .T.

Local nOpcGD 		:= 5 //GD_UPDATE		//GD_INSERT+GD_DELETE+GD_UPDATE
Local cLinOk       	:= "AllwaysTrue"    // Funcao executada para validar o contexto da linha atual do aCols
Local cTudoOk      	:= "AllwaysTrue"    // Funcao executada para validar o contexto geral da MsNewGetDados (todo aCols)
Local cIniCpos     	:= ""               // Nome dos campos do tipo caracter que utilizarao incremento automatico. Este parametro deve ser no formato "+<nome do primeiro campo>+<nome do segundo campo>+..."
Local nFreeze      	:= 000              // Campos estaticos na GetDados.
Local nMax         	:= 999					// Numero maximo de linhas permitidas. Valor padrao 99
Local cFieldOk     	:= "AllwaysTrue"		// Funcao executada na validacao do campo
Local cSuperDel     := ""						// Funcao executada quando pressionada as teclas <Ctrl>+<Delete>                    
Local cDelOk      	:= "AllwaysTrue"		// Funcao executada para validar a exclusao de uma linha do aCols
Local aAlterGDa     := {}
Local aCols			:= {}
Local aHeader		:= {}

Private oGDadSN1

Private INCLUI	:= .F.
Private ALTERA	:= .T.
Private EXCLUI	:= .F.
Private VISUAL	:= .F.
Private nOpc	:= 4

aAlterGDa := {} 

// Montar a aHeader
FMoaHeader(@aHeader)

// Montar a aCols
FMoaCols(@aCols,aHeader)

SX3->(dbSetOrder(1))
SX3->(dbSeek("SN1"))

While SX3->(!Eof()) .And. SX3->X3_ARQUIVO == "SN1"

	If ascan(aCpoEnch,Alltrim(SX3->X3_CAMPO)) > 0

		Do Case
			Case AllTrim(SX3->X3_CAMPO) == "N1_GRUPO"
				bX3_VALID := {|| (Vazio() .Or. ExistCpo("SNG")) .And. U_MCATFV01("N1GRP")}
			Case AllTrim(SX3->X3_CAMPO) == "N1_CHAPA"
				bX3_VALID := {|| U_MCATFV01("N1CHAP")}
			Case AllTrim(SX3->X3_CAMPO) == "N1_CALCPIS"
				bX3_VALID := {|| Pertence("123") }
			Case AllTrim(SX3->X3_CAMPO) == "N1_DETPATR"
				bX3_VALID := {|| Vazio() .OR. ExistCpo('SN0','11'+M->N1_DETPATR) }
			Case AllTrim(SX3->X3_CAMPO) == "N1_UTIPATR"
				bX3_VALID := {|| Vazio().OR.ExistCpo('SN0','12'+M->N1_UTIPATR) }
			Case AllTrim(SX3->X3_CAMPO) == "N1_ORIGCRD"
				bX3_VALID := {|| Pertence(' 01') }
			Case AllTrim(SX3->X3_CAMPO) == "N1_CSTPIS"
				bX3_VALID := {|| Vazio().Or.ExistCpo('SX5','SX'+M->N1_CSTPIS) }
			Case AllTrim(SX3->X3_CAMPO) == "N1_ALIQPIS"
				bX3_VALID := {|| Positivo() }
			Case AllTrim(SX3->X3_CAMPO) == "N1_ALIQCOF"
				bX3_VALID := {|| Positivo() }
			Case AllTrim(SX3->X3_CAMPO) == "N1_CODBCC"
				bX3_VALID := {|| Vazio().Or.ExistCpo('SX5','MZ'+M->N1_CODBCC) }
			Case AllTrim(SX3->X3_CAMPO) == "N3_TIPO"
				bX3_VALID := {|| ExistCpo("SX5","G1"+M->N3_TIPO) }
			Case AllTrim(SX3->X3_CAMPO) == "N3_CUSTBEM"
				bX3_VALID := {|| Vazio() .or. Ctb105CC()}
			Case AllTrim(SX3->X3_CAMPO) == "N3_CCUSTO"
				bX3_VALID := {|| Vazio() .or. Ctb105CC()}
			OtherWise
				bX3_VALID := {|| .T. }
		EndCase

		Aadd(aField, {	X3TITULO(),;
						SX3->X3_CAMPO,;
						SX3->X3_TIPO,;
						SX3->X3_TAMANHO,;
						SX3->X3_DECIMAL,;
						SX3->X3_PICTURE,;
						bX3_VALID,;	//SX3->X3_VALID,;
						.F.,;
						SX3->X3_NIVEL,;
						SX3->X3_RELACAO,;
						SX3->X3_F3,;
						{|| .T.},; //SX3->X3_WHEN,;
						.F.,;
						.F.,;
						SX3->X3_CBOX,;
						001,;
						.F.,;
						SX3->X3_PICTVAR,;
						SX3->X3_TRIGGER})
	EndIf	

	SX3->(dbSkip())
	
EndDo 

SX3->(dbSetOrder(1))
SX3->(dbSeek("SN3"))

While SX3->(!Eof()) .And. SX3->X3_ARQUIVO == "SN3"

	If ascan(aCpoEnch,Alltrim(SX3->X3_CAMPO)) > 0
		Aadd(aField, {	X3TITULO(),;
						SX3->X3_CAMPO,;
						SX3->X3_TIPO,;
						SX3->X3_TAMANHO,;
						SX3->X3_DECIMAL,;
						SX3->X3_PICTURE,;
						Iif(AllTrim(SX3->X3_CAMPO) == "N3_DINDEPR",{|| U_MCATFV01("N3DID")},{|| .T.}),; //SX3->X3_VALID,;
						.F.,;
						SX3->X3_NIVEL,;
						SX3->X3_RELACAO,;
						SX3->X3_F3,;
						{|| .T.},; //SX3->X3_WHEN,;
						.F.,;
						.F.,;
						SX3->X3_CBOX,;
						001,;
						.F.,;
						SX3->X3_PICTVAR,;
						SX3->X3_TRIGGER})
	EndIf	

	SX3->(dbSkip())
	
EndDo 

Static oEnchoice1
Static oDlg

While lSaiTela
	oDlg := TDialog():New(aTamTela[01],aTamTela[02],aTamTela[03],aTamTela[04],"Parâmetros Classificação Lote",,,,,,,,oMainWnd,.T.,,,,,)
	oDlg:lCentered := .T.

	RegToMemory("SN1",.F.,4)
	RegToMemory("SN3",.F.,4)

	M->N3_DINDEPR := CToD(Space(08))

	oEnch := MsmGet():New(,,nOpc,/*aCRA*/,/*cLetras*/,/*cTexto*/,aCpoEnch,aTamGet,aAlterEnch,/*nModelo*/,;
							/*nColMens*/,/*cMensagem*/, /*cTudoOk*/,oDlg,/*lF3*/,lMemoria,/*lColumn*/,/*caTela*/,;
							/*lNoFolder*/,/*lProperty*/,aField,aFolder,lCreate,/*lNoMDIStretch*/,/*cTela*/)
	EnchoiceBar( oDlg, { || If(FGrClLot(@lSaiTela), oDlg:End(), .F. ) }, { || lSaiTela := .F., oDlg:End()}, , aButtons )

	oGDadSN1	:= MsNewGetDados():New(aPDadRet[01],aPDadRet[02],aPDadRet[03],aPDadRet[04],nOpcGD,cLinOk,cTudoOk,cIniCpos,/*aAlterGDa*/,nFreeze,nMax,cFieldOk,cSuperDel,cDelOk,oDlg,aHeader,@aCols)

	ACTIVATE MSDIALOG oDlg
EndDo

RestArea(aArea)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} FMoaHeader
Monta a aHeader

@protected
@author	   Ederson Colen
@since	   06/03/2013
@version	   P11
@obs	      
Projeto

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------
Static Function FMoaHeader(aHeader)

Local aArea		:= GetArea()
Local aCpoGDa	:= {"N1_CBASE","N1_ITEM","N1_DESCRIC","N1_QUANTD","N3_DINDEPR","N3_AQUISIC","N1_FORNEC","N1_LOJA","N1_NSERIE","N1_NFISCAL"}
Local nXX		:= 0

SX3->(dbSetOrder(2))

For nXX := 1 To Len(aCpoGDa)

	SX3->(dbSeek(aCpoGDa[nXX]))

	If SX3->(! Eof()) // .And. SX3->(X3Uso(SX3->X3_USADO)) .And. cNivel >= SX3->X3_NIVEL .And. AllTrim(SX3->X3_CAMPO) $ cCpoGDa
		AADD( aHeader, {AllTrim(SX3->X3_TITULO),; 
						SX3->X3_CAMPO,;
						SX3->X3_PICTURE,;
						SX3->X3_TAMANHO,;
						SX3->X3_DECIMAL,;
						SX3->X3_VALID,;
						SX3->X3_USADO,;
						SX3->X3_TIPO,;
						SX3->X3_F3,;
						SX3->X3_CONTEXT,;
						SX3->X3_CBOX,;
						SX3->X3_RELACAO,;
						SX3->X3_WHEN,;
						SX3->X3_VISUAL,;
						SX3->X3_VLDUSER,;
						SX3->X3_PICTVAR,;
						SX3->X3_OBRIGAT})
	EndIf

Next nXX

SX3->(dbSetOrder(1))

RestArea(aArea)

Return Nil



// ======================================================================= \\
/*/{Protheus.doc} FMoaCols
Monta aCols
@protected
@author	   Ederson Colen
@since	   06/03/2013
@version	   P11
@obs	      
Projeto
/*/
// ======================================================================= \\
Static Function FMoaCols(aCols,aHeader)
// ======================================================================= \\

Local aArea    := {} 
//Local nI     := 0 

aArea := GetArea()

aCols := {}
(cAliLot)->(dbGoTop())
While (cAliLot)->(! Eof())
	AADD(aCols,Array(Len(aHeader)+1))
	GdFieldPut("N1_CBASE",(cAliLot)->N1_CBASE,Len(aCols),aHeader,aCols)
	GdFieldPut("N1_ITEM",(cAliLot)->N1_ITEM,Len(aCols),aHeader,aCols)
	GdFieldPut("N1_DESCRIC",(cAliLot)->N1_DESCRIC,Len(aCols),aHeader,aCols)
	GdFieldPut("N1_QUANTD",(cAliLot)->N1_QUANTD,Len(aCols),aHeader,aCols)
	GdFieldPut("N3_DINDEPR",(cAliLot)->N3_DINDEPR,Len(aCols),aHeader,aCols)
	GdFieldPut("N3_AQUISIC",(cAliLot)->N3_AQUISIC,Len(aCols),aHeader,aCols)
	GdFieldPut("N1_FORNEC",(cAliLot)->N1_FORNEC,Len(aCols),aHeader,aCols)
	GdFieldPut("N1_LOJA",(cAliLot)->N1_LOJA,Len(aCols),aHeader,aCols)
	GdFieldPut("N1_NSERIE",(cAliLot)->N1_NSERIE,Len(aCols),aHeader,aCols)
	GdFieldPut("N1_NFISCAL",(cAliLot)->N1_NFISCAL,Len(aCols),aHeader,aCols)
	If ! Empty((cAliLot)->N3_DINDEPR)
		aCols[Len(aCols),Len(aHeader)+1] := .F.
	Else
		aCols[Len(aCols),Len(aHeader)+1] := .T.
		RecLock(cAliLot,.F.)
		(cAliLot)->XX_DELETAD	:= "S"		
		(cAliLot)->(MsUnlock())
	EndIf

	(cAliLot)->(dbSkip())
EndDo

Return Nil



// ======================================================================= \\
/*/{Protheus.doc} FGrClLot
Processa a Classificacao em Lote
@author		Ederson Colen.
@since	   	26/05/2017
@version	P12
@obs			
@param		
/*/
// ======================================================================= \\
Static Function FGrClLot(lSaiTela)
// ======================================================================= \\

Local aArea     := {} 
Local lRet 	    := .T.
Local aCols	    := {} 
Local aParam    := {}

Local lPriVez   := .T.

Local aStruSN1	:= CarregStru("SN1")
Local aStruSN3	:= CarregStru("SN3")

Local aAtCMPM1	:= {"N1_CALCPIS","N1_TPBEM","N1_ORIGCRD","N1_DETPATR","N1_UTIPATR","N1_CSTPIS","N1_ALIQPIS","N1_CSTCOFI",;
					"N1_ALIQCOF","N1_CODBCC","N1_MESCPIS","N1_CBCPIS"}
Local aAtCMPM3	:= {"N3_TIPO","N3_HISTOR","N3_CUSTBEM","N3_CCUSTO"}

Local aCmpN1Cab	:= {"N1_CBASE","N1_TPBEM","N1_GRUPO","N1_CHAPA","N1_CALCPIS","N1_ORIGCRD","N1_DETPATR","N1_UTIPATR","N1_CSTPIS","N1_ITEM",;
					"N1_ALIQPIS","N1_ALIQCOF","N1_CODBCC","N1_MESCPIS","N1_CSTCOFI","N1_CBCPIS","N1_NFESPEC","N1_NFITEM","N1_STATUS","N1_DTCLASS"}

Local aCmpN3It  := {"N3_CBASE","N3_TIPO","N3_HISTOR","N3_CUSTBEM","N3_CCUSTO","N3_CCONTAB","N3_CDEPREC","N3_CCDEPR","N3_TXDEPR1",;
					"N3_TXDEPR2","N3_TXDEPR3","N3_TXDEPR4","N3_TXDEPR5","N3_DINDEPR","N3_HISTOR"}

Local aAutoCab	:= {}
Local aAutoIt	:= {}
Local aAuNewIt	:= {}

Local nPCMPN3	:= 0
Local nXX		:= 0
Local nXV		:= 0

Local cGrpMemo	:= M->N1_GRUPO
//Local cChapMem	:= M->N1_CHAPA
//Local cCBasMem	:= M->N1_CBASE

Private aRotina     := {}
Private oModel 
Private lMsErroAuto := .F.

aCols := oGDadSN1:aCols
aArea := GetArea()

/* 	// --> Alterado PROX 22/04/2021   DE..: ---------------------------------
If (M->N1_CALCPIS <> "2" .And. ;
	(M->N1_MESCPIS <= 0 .Or. ;
	 Empty(M->N1_CSTPIS) .Or. ;
	 M->N1_ALIQPIS <= 0 .Or. ;
	 M->N1_ALIQCOF <= 0 .Or. ;
	 Empty(M->N1_CSTCOFI) .Or. ;
	 Empty(M->N1_CBCPIS)))
	Aviso("ATENÇÃO","Calc. PIS está diferente de Não desta forma os Campos Referentes ao cálculo deveram ser preenchidos." + CRLF + ;
					"Meses Cl.Pis"+CRLF+;
					"Sit.Trib.PIS"+CRLF+;
					"Aliq. PIS"+CRLF+;    
					"Sit.Trib.Cof"+CRLF+;
					"Aliq. Cofins"+CRLF+;
					"Base PIS/COF",{"OK"})
	lRet := .F.
	Return(lRet)
EndIf
*/ 	// --> Alterado PROX 22/04/2021   PARA: ---------------------------------
If (M->N1_CALCPIS <> "2" .And. ;
	(Empty(M->N1_CSTPIS) .Or. M->N1_ALIQPIS <= 0 .Or. M->N1_ALIQCOF <= 0 .Or. Empty(M->N1_CSTCOFI) .Or. Empty(M->N1_CBCPIS)))
	Aviso("Especifico SELFIT - MCATFP02","ATENÇÃO!  Campo 'Calc. PIS' está diferente de 'Não', desta forma os campos referentes ao cálculo devem ser preenchidos:" + CRLF + ;
					"Sit.Trib.PIS" +CRLF+;
					"Aliq. PIS"    +CRLF+;    
					"Sit.Trib.Cof" +CRLF+;
					"Aliq. Cofins" +CRLF+;
					"Base PIS/COF" , {"OK"})
	lRet := .F.
	Return(lRet)
EndIf

If ( (M->N1_CALCPIS = "1" .Or. M->N1_CALCPIS = "2") .And. ;
	 (M->N1_MESCPIS <> 0) )
	Aviso("Especifico SELFIT - MCATFP02","ATENÇÃO!  O campo 'Meses Cl. Pis' deve estar zerado para o a condição de Calculo de PIS igual a (Sim ou Não)." , {"OK"})
	lRet := .F.
	Return(lRet)
EndIf
// 	// --> Alterado PROX 22/04/2021   FINAL ---------------------------------

//aRotina   := MenuDef()
oModel      := FWLoadModel('ATFA012') //StaticCall('ATFA012', ModelDef)
lMsErroAuto := .F.

//Adicionando os dados do ExecAuto
(cAliTN1X)->(dbGoTop())
(cAliTN3)->(dbGoTop())
(cAliTN4)->(dbGoTop())
(cAliTNN)->(dbGoTop())

Begin TRANSACTION

(cAliLot)->(dbGoTop())

While (cAliLot)->(! Eof())

	(cAliTN1X)->(dbSeek((cAliLot)->N1_FILIAL+(cAliLot)->N1_CBASE+(cAliLot)->N1_ITEM))

	If (cAliTN1X)->(! Eof())

		RecLock(cAliTN1X,.F.)
		For nXV := 1 To Len(aAtCMPM1)
			(cAliTN1X)->&(aAtCMPM1[nXV]) := &("M->"+aAtCMPM1[nXV])
		Next nXV
		(cAliTN1X)->(MsUnlock())

		(cAliTN3)->(dbSeek((cAliTN1X)->N1_FILIAL+(cAliTN1X)->N1_CBASE+(cAliTN1X)->N1_ITEM))

		If (cAliTN3)->(! Eof())

			RecLock(cAliTN3,.F.)
			For nXV := 1 To Len(aAtCMPM3)
				(cAliTN3)->&(aAtCMPM1[nXV]) := &("M->"+aAtCMPM1[nXV])
			Next nXV
			(cAliTN3)->(MsUnlock())

		EndIf
	
	EndIf

	(cAliLot)->(dbSkip())

EndDo

(cAliLot)->(dbGoTop())

// guarda a data de depreciação informada para utilizar posteriormente pois quando passa pelo execauto ele limpa
dDtDepr := M->N3_DINDEPR

While (cAliLot)->(! Eof())

	If (cAliLot)->XX_DELETAD == "S"
		(cAliLot)->(dbSkip())
		Loop
	EndIf

	dbSelectArea("SN1")
	dbSetOrder(1)
	dbGoTo((cAliLot)->N1_RECNO)

	(cAliTN1X)->(dbSeek(SN1->N1_FILIAL+SN1->N1_CBASE+SN1->N1_ITEM))

	aAutoCab	:=	{{"N1_CBASE",	(cAliTN1X)->N1_CBASE,	NIL},;	
					 {"N1_ITEM",	(cAliTN1X)->N1_ITEM,	NIL} }

	aAutoItens	:= {{{"N3_SEQ",		(cAliLot)->N3_SEQ,		NIL},;
					 {"N3_CBASE",	(cAliTN1X)->N1_CBASE,	NIL},;	
					 {"N3_ITEM",	(cAliTN1X)->N1_ITEM,	NIL}}}
						
	lMsErroAuto := .F. 
	aAdd( aParam, {"MV_PAR01", 2} )
	aAdd( aParam, {"MV_PAR02", 1} )
	aAdd( aParam, {"MV_PAR03", 2} )
	MSExecAuto({|x,y,z,w| ATFA012(x,y,z,w)},aAutoCab,aAutoItens,5,aParam)
	
	If lMsErroAuto
		lRet := .F.
		MostraErro()
		DisarmTransaction()
		EXIT
	Else

		lMsErroAuto := .F. 
		aAutoIt		:= {}
		aAutoCab	:= {}
		aAuNewIt	:= {}

		SNG->(dbSetOrder(1))
		SNG->(dbSeek(xFilial("SNG")+cGrpMemo))

		FNG->(dbSetOrder(1))
		FNG->(dbSeek(xFilial("FNG")+cGrpMemo))

		If lPriVez
			cChapN1NEW := M->N1_CBASE
			cPlacN1NEW := M->N1_CHAPA
			lPriVez		:= .F.
		Else
			cChapN1NEW := AllTrim(cGrpMemo)+U_SEQATF(AllTrim(cGrpMemo),"CB","R")	
			cPlacN1NEW := U_SEQATF(AllTrim(cGrpMemo),"PL","R",Len(AllTrim(M->N1_CHAPA)))
		EndIf

		For nXX := 1 To Len(aStruSN1)
			nPCMPN1 := aScan(aCmpN1Cab,AllTrim(aStruSN1[nXX,02]))
			If nPCMPN1 > 0
				Do Case
					Case AllTrim(aStruSN1[nXX,02]) == "N1_GRUPO"
						AADD(aAutoCab,{"N1_GRUPO",cGrpMemo,NIL})
					Case AllTrim(aStruSN1[nXX,02]) == "N1_CBASE"
						AADD(aAutoCab,{"N1_CBASE",cChapN1NEW,NIL})
					Case Alltrim(aStruSN1[nXX,02]) == "N1_CHAPA"
						AADD(aAutoCab,{"N1_CHAPA",cPlacN1NEW,NIL})
					Case Alltrim(aStruSN1[nXX,02]) == "N1_NFESPEC"
						AADD(aAutoCab,{"N1_NFESPEC",(cAliTN1X)->N1_NFESPEC,NIL})
					Case Alltrim(aStruSN1[nXX,02]) == "N1_NFITEM"
						AADD(aAutoCab,{"N1_NFITEM",(cAliTN1X)->N1_NFITEM,NIL})
					Case Alltrim(aStruSN1[nXX,02]) == "N1_STATUS"
						AADD(aAutoCab,{"N1_STATUS","1",NIL})
					Case Alltrim(aStruSN1[nXX,02]) == "N1_DTCLASS"
						AADD(aAutoCab,{"N1_DTCLASS",dDataBase,NIL})
					Case Alltrim(aStruSN1[nXX,02]) == "N1_ITEM"
						AADD(aAutoCab,{"N1_ITEM",StrZero(1,Len(AllTrim((cAliTN1X)->N1_ITEM))),NIL})
//					Case Alltrim(aStruSN1[nXX,02]) $ "N1_CALCPIS#N1_CSTPIS#N1_ALIQPIS#N1_ALIQCOF#N1_MESCPIS#N1_CSTCOFI#N1_CBCPIS#" .And. (cAliTN1X)->N1_CALCPIS == "2" 
//						AADD(aAutoCab,{aStruSN1[nXX,02],(cAliTN1X)->&(aStruSN1[nXX,02]),.T.})
					OtherWise
						AADD(aAutoCab,{aStruSN1[nXX,02],(cAliTN1X)->&(aStruSN1[nXX,02]),NIL})
				EndCase
			Else
				AADD(aAutoCab,{aStruSN1[nXX,02],(cAliTN1X)->&(aStruSN1[nXX,02]),NIL})
			EndIf
		Next nXX

		(cAliTN3)->(dbSeek((cAliTN1X)->N1_FILIAL+(cAliTN1X)->N1_CBASE+(cAliTN1X)->N1_ITEM))


		// PROX - Aldo - 03/05/2022
		// Por algum motivo desconhecido, o trecho abaixo apresentava erro informando que o Campo N3_TIPO não estava preenchido
		// mesmo incluindo manualmente, o erro persistia.
		// Então foi feito um outro treho com a criação dos itens da SN3
/*		lExec := .F. // criei esta variaval para testes na rotina que está dando erro (.T.)
		if lExec
			aAutoIt := {}

			Aadd(aAutoIt, {"N3_CBASE"	,cChapN1NEW										,NIL})
			Aadd(aAutoIt, {"N3_ITEM"	,(cAliTn3)->N3_ITEM								,Nil})
			Aadd(aAutoIt, {"N3_TIPO"	,(cAliTn3)->N3_TIPO								,Nil})

			For nXX := 1 To Len(aStruSN3)
				if aStruSN3[nXx,2] $ "N3_CBASE/N3_ITEM/N3_TIPO"
					Loop
				Endif	

				nPCMPN3 := aScan(aCmpN3It,AllTrim(aStruSN3[nXX,02]))
				If nPCMPN3 > 0
					Do Case
						Case AllTrim(aStruSN3[nXX,02]) == "N3_CBASE"
							AADD(aAutoIt,{"N3_CBASE",cChapN1NEW,NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_CCONTAB"
							AADD(aAutoIt,{aStruSN3[nXX,02],SNG->NG_CCONTAB,NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_CDEPREC"
							AADD(aAutoIt,{aStruSN3[nXX,02],SNG->NG_CDEPREC,NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_CCDEPR"
							AADD(aAutoIt,{aStruSN3[nXX,02],SNG->NG_CCDEPR,NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_TXDEPR1"
							AADD(aAutoIt,{aStruSN3[nXX,02],If(!Empty(FNG->FNG_TXDEP1),FNG->FNG_TXDEP1,0),NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_TXDEPR2"
							AADD(aAutoIt,{aStruSN3[nXX,02],If(!Empty(FNG->FNG_TXDEP2),FNG->FNG_TXDEP2,0),NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_TXDEPR3"
							AADD(aAutoIt,{aStruSN3[nXX,02],If(!Empty(FNG->FNG_TXDEP3),FNG->FNG_TXDEP3,0),NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_TXDEPR4"
							AADD(aAutoIt,{aStruSN3[nXX,02],If(!Empty(FNG->FNG_TXDEP4),FNG->FNG_TXDEP4,0),NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_TXDEPR5"
							AADD(aAutoIt,{aStruSN3[nXX,02],If(!Empty(FNG->FNG_TXDEP5),FNG->FNG_TXDEP5,0),NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_DINDEPR"
							AADD(aAutoIt,{aStruSN3[nXX,02],(cAliLot)->N3_DINDEPR,NIL})
						Case Alltrim(aStruSN3[nXX,02]) == "N3_HISTOR"
							If Empty((cAliTN3)->N3_HISTOR)
								AADD(aAutoIt,{aStruSN3[nXX,02],(cAliTN1X)->N1_DESCRIC,NIL})
							Else
								AADD(aAutoIt,{aStruSN3[nXX,02],(cAliTN3)->N3_HISTOR,NIL})
							EndIf
						OtherWise
							AADD(aAutoIt,{aStruSN3[nXX,02],(cAliTN3)->&(aStruSN3[nXX,02]),NIL})
					EndCase
				Else
					AADD(aAutoIt,{aStruSN3[nXX,02],(cAliTN3)->&(aStruSN3[nXX,02]),NIL})
				EndIf
			Next nXX

			AADD(aAuNewIt,aAutoIt)

		Else
*/		
			// PROX - Aldo - 03/05/2022
			// Por algum motivo desconhecido, o trecho acima apresentava erro informando que o Campo N3_TIPO não estava preenchido
			// mesmo incluindo manualmente, o erro persistia.
			// Então foi feito o trecho abaixo com a criação dos itens da SN3
			aAutoIt2 := {}
			cHistor := If(Empty((cAliTN3)->N3_HISTOR), (cAliTN1X)->N1_DESCRIC, (cAliTN3)->N3_HISTOR)
			dDinDepr := If( ! Empty(dDtDepr), dDtDepr,if((cAliTn3)->N3_AQUISIC > GetMv("MV_ULTDEPR"), (cAliTn3)->N3_AQUISIC,dDtDepr))
			Aadd(aAutoIt2, {"N3_CBASE"	,cChapN1NEW										,NIL})
			Aadd(aAutoIt2, {"N3_ITEM"	,(cAliTn3)->N3_ITEM								,Nil})
			Aadd(aAutoIt2, {"N3_TIPO"	,(cAliTn3)->N3_TIPO								,Nil})
			Aadd(aAutoIt2, {"N3_HISTOR"	,cHistor										,Nil})
			Aadd(aAutoIt2, {"N3_CCONTAB",SNG->NG_CCONTAB								,Nil})
			Aadd(aAutoIt2, {"N3_CDEPREC",SNG->NG_CCDEPR									,Nil})
			Aadd(aAutoIt2, {"N3_VORIG1"	,(cAliTN3)->N3_VORIG1							,Nil})
			Aadd(aAutoIt2, {"N3_VORIG2"	,(cAliTN3)->N3_VORIG2							,Nil})
			Aadd(aAutoIt2, {"N3_VORIG3"	,(cAliTN3)->N3_VORIG3							,Nil})
			Aadd(aAutoIt2, {"N3_VORIG4"	,(cAliTN3)->N3_VORIG4							,Nil})
			Aadd(aAutoIt2, {"N3_VORIG5"	,(cAliTN3)->N3_VORIG5							,Nil})
			Aadd(aAutoIt2, {"N3_TXDEPR1",If(!Empty(FNG->FNG_TXDEP1),FNG->FNG_TXDEP1,0)	,Nil})
			Aadd(aAutoIt2, {"N3_TXDEPR2",If(!Empty(FNG->FNG_TXDEP2),FNG->FNG_TXDEP2,0)	,Nil})
			Aadd(aAutoIt2, {"N3_TXDEPR3",If(!Empty(FNG->FNG_TXDEP3),FNG->FNG_TXDEP3,0)	,Nil})
			Aadd(aAutoIt2, {"N3_TXDEPR4",If(!Empty(FNG->FNG_TXDEP4),FNG->FNG_TXDEP4,0)	,Nil})
			Aadd(aAutoIt2, {"N3_TXDEPR5",If(!Empty(FNG->FNG_TXDEP5),FNG->FNG_TXDEP5,0)	,Nil})
			Aadd(aAutoIt2, {"N3_DINDEPR", dDinDepr										,Nil})
			Aadd(aAutoIt2, {"N3_AQUISIC",(cAliTn3)->N3_AQUISIC									,Nil})
			Aadd(aAutoIt2, {"N3_TPSALDO",M->N3_TPSALDO									,Nil})
			Aadd(aAutoIt2, {"N3_CUSTBEM",M->N3_CUSTBEM									,Nil})
			Aadd(aAutoIt2, {"N3_CCUSTO"	,M->N3_CCUSTO									,Nil})
			Aadd(aAutoIt2, {"N3_INTP"	,M->N3_INTP										,Nil})
			Aadd(aAutoIt2, {"N3_CCDEPR"	,M->N3_CDEPREC									,Nil})
		
			AADD(aAuNewIt,aAutoIt2)
//		Endif

		// .T. executa via MVC, .F. executa como execauto normal
		lModoMVC := .F.
		if ! lModoMVC
			MSExecAuto({|x,y,z,w| ATFA012(x,y,z,w)},aAutoCab,aAuNewIt,3,aParam)
		Else
			FWMVCRotAuto(	oModel,;                        //Model
							"SN1",;                         //Alias
							3,;        //Operacao
							{{"SN1MASTER", aAutoCab},{"SN3DETAIL",aAuNewIt}})          //Dados
		Endif

		If lMsErroAuto
			lRet := .F.
			MostraErro()
			DisarmTransaction()
			EXIT
//		Else
//			MsgInfo("Registro incluido!", "Atenção")
		EndIf

	Endif
	
	(cAliLot)->(dbSkip())

EndDo

End Transaction

If lRet
	MsgInfo("Registro incluido/classificado com sucesso !!!" , "Especifico SELFIT - MCATFP02.prw")
	lSaiTela := .F.
EndIf

Return(lRet)



// ======================================================================= \\
Static Function CarregStru(cAlias,aStru)
// ======================================================================= \\

Local aAreaAnt		:= GetArea()
Local cCampoZero	:= "Zero"
Local cCMPN1N3		:=  "N1_CBASE#N1_GRUPO#N1_TPBEM#N1_CHAPA#N1_CALCPIS#N1_ORIGCRD#N1_DETPATR#N1_UTIPATR#N1_CSTPIS#N1_ALIQPIS#N1_ALIQCOF#N1_CODBCC#"+;
						"N1_MESCPIS#N1_CSTCOFI#N1_CBCPIS#N1_NFESPEC#N1_NFITEM#N1_STATUS#N1_DTCLASS#"+;						
						"N3_CDEPREC#N3_CCDEPR#N3_TXDEPR1#N3_TXDEPR2#N3_TXDEPR3#N3_TXDEPR4#N3_TXDEPR5#N3_DINDEPR#"
Local cNoCampo      := "N1_DIACTB#N3_SUBCTA#N3_SUBCCON#N3_SUBCDEP#N3_SUBCCDE#N3_SUBCDES#N3_SUBCCOR#N3_BXICMS#N3_CODIND#N3_ATFCPR#N3_CBASE#N3_ITEM#"

Default aStru		:= {}

dbSelectArea("SX3")
dbSetOrder(1)
SX3->(dbSeek(cAlias))

While ! SX3->(Eof()) .And. (SX3->X3_ARQUIVO == cAlias)
//	If AllTrim(SX3->X3_CAMPO) $ "N1_DIACTB#N3_SUBCTA#N3_SUBCCON#N3_SUBCDEP#N3_SUBCCDE#N3_SUBCDES#N3_SUBCCOR#N3_BXICMS#N3_CODIND#N3_ATFCPR#N3_CBASE#N3_ITEM#"
	If AllTrim(SX3->X3_CAMPO) $ cNoCampo
		SX3->(dbSkip())
		Loop
	EndIf

	If  (X3USO(SX3->X3_USADO) .And. cNivel >= SX3->X3_NIVEL) .Or. (AllTrim(SX3->X3_CAMPO) $ cCMPN1N3)  
		AADD(aStru,{TRIM(X3TITULO()),Alltrim(SX3->X3_CAMPO),SX3->X3_PICTURE,SX3->X3_TAMANHO,SX3->X3_DECIMAL,SX3->X3_VALID ,SX3->X3_USADO ,SX3->X3_TIPO ,cCampoZero ,SX3->X3_CONTEXT})
	EndIf

	SX3->(dbSkip())
EndDo

RestArea(aAreaAnt)

Return aStru 
