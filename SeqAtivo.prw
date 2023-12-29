#Include "RwMake.ch" 
#INCLUDE "protheus.ch" 
//-------------------------------------------------------------------
/* {Protheus.doc} SeqAtivo

@protected
@author    Rodrigo Carvalho
@since     13/08/2014
@obs        
Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------

User Function SeqAtivo()

//Local cGrupo  := ALLTRIM(M->N1_GRUPO)
Local aArea   := GetArea()
//Local nSeque  := 0
Local cCodNew := Space(6)
//Local cCod    := Space(6)
Local cProcura := ALLTRIM(M->N1_GRUPO)

If INCLUI .OR. Alltrim(Funname())$ "ATFA240" 
	M->N1_CBASE := Space(6)
	M->N1_CHAPA := Space(6)
	SysRefresh()

	cCodNew		:= cProcura+U_SEQATF(cProcura,"CB","G")
	cPlacN1NEW	:= U_SEQATF(AllTrim(cProcura),"PL","R",6)
	
/*
	dbSelectArea("SN1")
	dbSetOrder(1)
	dbSeek(xFilial("SN1")+cProcura,.T.)
	
	While ! SN1->(Eof()) .And. SN1->N1_FILIAL == xFilial("SN1") .And. Substr(SN1->N1_CBASE,1,2)= cProcura
		nSeque := Val(Substr(SN1->N1_CBASE,3,4))
		dbSelectArea("SN1")
		dbSkip()		
	End Do
	nSeque++
	nSeque := Strzero(nSeque,6-(len(cProcura)))        
	  
	While .T.
		cCodNew := cProcura + nSeque
		dbSelectArea("SN1")
		dbSetOrder(1)
		
		If ! dbSeek(xFilial("SN1")+cCodNew)
			Exit
		Else
			nSeque := VAL(nSeque)+1                      
			nSeque := Strzero(nSeque,6-(len(cProcura)))        
		EnDif
		
		Loop
		
	EndDo
*/
	
    M->N1_CHAPA	:= cPlacN1NEW //cCodNew
    M->N1_CBASE	:= cCodNew
    M->N1_ITEM	:= "0001"
    
Else
	cCodNew  := M->N1_CBASE
EndIf

RestArea(aArea)

Return(.T.)
