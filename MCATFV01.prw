#INCLUDE "PROTHEUS.CH"

//-------------------------------------------------------------------
/*/{Protheus.doc} MCATVV01
Validacao do Ativo Fixos

@protected
@author    Ederson Colen.
@since     30/05/2016
@obs       

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------
User Function MCATFV01(cTipVLD,xParam01,xParam02,xParam03)

Local lRetVld := .T.

Do Case
	Case cTipVLD == 'N1GRP'
		lRetVld := FVldN1GRP()
	Case cTipVLD == "N3DID"
		lRetVld := FVlN3DID()
	Case cTipVLD == "N1CHAP"
		lRetVld := FVN1CHAP()
	OtherWise
		Aviso("ATENÇÃO","Parâmetro de Validação não informado. Favor entrar em Contato com a TI.",{"OK"})
EndCase

Return(lRetVld)



//-------------------------------------------------------------------
/*/{Protheus.doc} FVldN1GRP
Valida o Grupo Ativo Fixo

@protected
@author    Ederson Colen.
@since     30/0516
@obs       

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------
Static Function FVldN1GRP()

Local lRetVld	:= .T.
Local aAreaN1	:= {SN1->(GetArea()), GetArea()}

M->N1_CBASE := AllTrim(M->N1_GRUPO)+U_SEQATF(AllTrim(M->N1_GRUPO),"CB","R")
M->N1_CHAPA := U_SEQATF(AllTrim(M->N1_GRUPO),"PL","R",6)

AEval(aAreaN1,{|x| RestArea(x)})

Return(lRetVld)





//-------------------------------------------------------------------
/*/{Protheus.doc} FVN1CHAP
Valida a Chapa

@protected
@author    Ederson Colen.
@since     30/0516
@obs       

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------
Static Function FVN1CHAP()

Local lRetVld	:= .T.
Local aAreaN1	:= {SN1->(GetArea()), GetArea()}

SN1->(dbSetOrder(2)) //N1_FILIAL+N1_CHAPA
SN1->(dbSeek(xFilial("SN1")+M->N1_CHAPA))

If SN1->(! Eof())
	Aviso("ATENÇÃO","Numero da CHAPA já cadastrada no Sistema. Favor informar um outro Numero.",{"OK"})
	lRetVld	:= .F.
EndIf

AEval(aAreaN1,{|x| RestArea(x)})

Return(lRetVld)



//-------------------------------------------------------------------
/*/{Protheus.doc} FVlN3DID
Valida N3 Data de Inicio Depreciação

@protected
@author    Ederson Colen.
@since     31/05/2017
@obs       

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------
Static Function FVlN3DID()

Local lRetVld	:= .T.
Local aCols		:= oGDadSN1:aCols
Local aHeader	:= oGDadSN1:aHeader
Local nXT		:= 0
Local dMVUDepr	:= GETMV("MV_ULTDEPR")
Local nOpcao	:= 0

If Empty(M->N3_DINDEPR)

	For nXT := 1 To Len(aCols)
		(cAliLot)->(dbSeek(aCols[nXT,GDFieldPos("N1_CBASE",aHeader)]+aCols[nXT,GDFieldPos("N1_ITEM",aHeader)]))	//"N1_CBASE+N1_ITEM"
		If (cAliLot)->(! Eof()) 
			GdFieldPut("N3_DINDEPR",(cAliLot)->N3_DINDANT,nXT,aHeader,aCols)
			RecLock(cAliLot,.F.)
			(cAliLot)->N3_DINDEPR := (cAliLot)->N3_DINDANT
			If ! Empty((cAliLot)->N3_DINDEPR)
				aCols[nXT,Len(aHeader)+1] := .F.
			Else
				aCols[nXT,Len(aHeader)+1] := .T.
				(cAliLot)->XX_DELETAD	:= "S"		
			EndIf
			(cAliLot)->(MsUnlock())
		EndIf
	Next
	oGDadSN1:Refresh()

Else

	If M->N3_DINDEPR <= dMVUDepr
		Aviso("ATENÇÃO","Dada de Inicio de Depreciação não pode ser menor que o ultimo fechamento.",{"OK"})
		lRetVld	:= .F.
	Else

		For nXT := 1 To Len(aCols)
			If ! GDdeleted(nXT,aHeader,aCols)
				If M->N3_DINDEPR < aCols[nXT,GDFieldPos("N3_DINDEPR",aHeader)]
					Aviso("ATENÇÃO","Existem Itens com Data de Aquisição Maior que a data Informada.",{"OK"})
					lRetVld	:= .F.
					EXIT
				EndIf
			EndIf
		Next
	EndIf

	If lRetVld

		nOpcao := Aviso("A T E N Ç Ã O ","A Data informada será replicada para Inicio de Depreciação de Todos os Itens."+CRLF+;
										"Deseja continuar?",{"Sim","Não"},1) 
		If (nOpcao <> 1)
			lRetVld := .F.
		Else			
			For nXT := 1 To Len(aCols)
				(cAliLot)->(dbSeek(aCols[nXT,GDFieldPos("N1_CBASE",aHeader)]+aCols[nXT,GDFieldPos("N1_ITEM",aHeader)]))	//"N1_CBASE+N1_ITEM"
				If GDdeleted(nXT,aHeader,aCols)
					aCols[nXT,Len(aHeader)+1] := .F.
					If (cAliLot)->(! Eof())
						RecLock(cAliLot,.F.)
						(cAliLot)->XX_DELETAD	:= "N"
						(cAliLot)->(MsUnlock())
					EndIf
				EndIf
				GdFieldPut("N3_DINDEPR",M->N3_DINDEPR,nXT,aHeader,aCols)
				If (cAliLot)->(! Eof()) 
					RecLock(cAliLot,.F.)
					(cAliLot)->N3_DINDEPR := M->N3_DINDEPR
					(cAliLot)->(MsUnlock())
				EndIf
			Next
			oGDadSN1:Refresh()
		EndIf
	EndIf	

EndIf

Return(lRetVld)
