#include "PROTHEUS.CH"
#INCLUDE "FWBROWSE.CH"
#INCLUDE "FWMVCDEF.CH"
#DEFINE DEF_SVIGE  "05" //Vigente
#DEFINE DEF_COLPROD 1
#DEFINE DEF_QUANT   2
#DEFINE DEF_CC      3
#DEFINE DEF_ITEM    4
#DEFINE DEF_OBS     5
#DEFINE DEF_VALOR   6
#DEFINE DEF_TPCTG   7
                
User Function TPCNT121(lJob,cContrato,cPlanilha,aItens,cFilRef,cFornece,cLoja,cParcela,cNumSC)
Local aArea	     	:= GetArea()
Local aSaveLines	:= FwSaveRows()
Local oModel 		:= Nil
Local oModelCNA		:= Nil
Local oModelCND		:= Nil
Local oModelCNE		:= Nil
Local oModelCXN		:= Nil
Local cRevisao      := ""
Local cCompet       := StrZero( Month( dDatabase ), 2 ) + "/" + CValToChar( Year( dDatabase ) )
Local cTxLog   		:= ""//Texto do log
Local cHelp			:= ""
Local cTxPlan		:= ""
Local cQuebra		:= ""    
Local NSTACK
Local lRet          := .t.   

Private __Itens     := Aclone(aItens) 
Private __FilRef    := cFilRef
Private __Fornece   := cFornece
Private __Loja      := cLoja         
Private __Parcel    := ""
Private __NumSC     := ""
Default lJob      := .f.
Default cContrato := ""
Default cPlanilha := ""
Default cParcela  := ""
Default aItens    := {}         

__NumSC := cNumSC

__Parcel := cParcela

If (Empty(cContrato) .OR. Empty(cPlanilha) .OR. Len(aItens) == 0)  
	cTxLog := "Parametros inválidos. Favor validar contrato, planilha e itens"
	imprime(lJob,cTxLog)
	Return {.f.,"",cTxLog}
EndIf

oModel := FWLoadModel("CNTA121")

cRevisao := CnGetRevAt(cContrato) 
      
Conout("Iniciando medição contrato"+cContrato+" Revisao:"+cRevisao+" Hora:"+Time())                
Conout("Revisao vigente "+CnGetRevVg(cContrato))
conout("filial "+xFilial("CN9")) 

DbSelectArea("CN9")
CN9->(dbSetOrder(1))
If !(CN9->(MsSeek(xFilial("CN9")+cContrato+CnGetRevVg(cContrato),.T.))) .And. CnGetRevVg(cContrato) == cRevisao
	cTxLog := "Não é possível realizar medição, situação do contrato diferente de vigente."
	imprime(lJob,cTxLog)
	Return {.f.,cTxLog,cTxLog}
EndIf

nStack 	:= GetSX8Len()

A260SComp(cCompet)

oModel:SetOperation(MODEL_OPERATION_INSERT)

If oModel:Activate()
	oModelCND := oModel:GetModel("CNDMASTER")
	oModelCXN := oModel:GetModel("CXNDETAIL")
	oModelCNE := oModel:GetModel("CNEDETAIL")
	oModelCND:GetStruct():SetProperty('*',MODEL_FIELD_WHEN,{||.T.})
	oModelCXN:GetStruct():SetProperty('*',MODEL_FIELD_WHEN,{||.T.})
	oModelCNE:GetStruct():SetProperty('*',MODEL_FIELD_WHEN,{||.T.})
	
	If (lVldCtr := oModelCND:SetValue("CND_CONTRA",cContrato))
		oModelCND:SetValue("CND_REVISA"	,cRevisao)
		oModelCND:SetValue("CND_COMPET"	,cCompet)
		CN121Carga(cContrato,cRevisao)
	EndIf
EndIf


nLinha := MTFindMVC(oModelCXN,{{"CXN_NUMPLA",cPlanilha}})

If nLinha > 0
	oModelCXN:GoLine(nLinha)
	lVldCtr := oModelCXN:SetValue("CXN_CHECK" , .T. )
	
	If lVldCtr            
		For nI := 1 To Len(aItens)        
			lCC := .F.
			If len(aItens[nI]) > 2
				lCC := .T.
			endif 
			/*
			If lCC
				nLinPrd := MTFindMVC(oModelCNE,{{"CNE_PRODUT",aItens[nI][DEF_COLPROD]},{"CNE_CC",aItens[nI][DEF_CC]}})   				
			Else                                                                                                         
				nLinPrd := MTFindMVC(oModelCNE,{{"CNE_PRODUT",aItens[nI][DEF_COLPROD]}})   
			EndIf
			*/                                                                             
			if CNL->CNL_CTRFIX == '2'// .and. CNL->CNL_PLSERV == '1'
					 	nValor  := aItens[nI][DEF_VALOR]
				if nI > 1                   
					If !oModelCNE:CanUpdateLine()
						oModelCNE:SetNoUpdateLine(.F.)
					EndIf

					oModelCNE:SetNoInsertLine(.F.)
					lUpdCNE := oModelCNE:CanUpdateLine()

					If !lUpdCNE
						oModelCNE:SetNoUpdateLine(.F.)
					EndIf
			
					oModelCNE:SetNoInsertLine(.F.)
					nNewLine := oModelCNE:AddLine()
					oModelCNE:GoLine( nNewLine )   
					oModelCNE:SetNoInsertLine(.T.)																		
				endif
				oModelCNE:LoadValue( 'CNE_ITEM'	, strZero( nI,TamSx3("CNE_ITEM")[1] ))
				oModelCNE:LoadValue("CNE_PRODUT",aItens[nI][DEF_COLPROD])                
				oModelCNE:SetValue("CNE_VLUNIT",nValor)   				
				oModelCNE:SetValue("CNE_QUANT" , aItens[nI][DEF_QUANT])				
				oModelCNE:SetValue("CNE_VLTOT",aItens[nI][2]*nValor)
				oModelCNE:LoadValue("CNE_NUMSC" ,__NumSc) 
				oModelCNE:LoadValue("CNE_ITEMSC",aItens[nI][DEF_ITEM])
			    oModelCNE:LoadValue("CNE_CC",aItens[nI][DEF_CC])											  
 				oModelCNE:LoadValue("CNE_OBS"   ,aItens[nI][DEF_OBS]) 				
				
			else
				nLinPrd := MTFindMVC(oModelCNE,{{"CNE_PRODUT",aItens[nI][DEF_COLPROD]}})   
				If oModelCNE:GoLine(nLinPrd)   > 0
					 If aItens[nI][DEF_TPCTG] == "2"	  
					 	nValor  := aItens[nI][DEF_VALOR]
					 Else			
						 nValor  := oModelCNE:GetValue("CNE_VLUNIT")
						 lVldCtr := oModelCNE:SetValue("CNE_QUANT" , aItens[nI][DEF_QUANT])
					 EndIf				 	 				  
	
					 oModelCNE:LoadValue("CNE_VLUNIT",nValor)   
					 oModelCNE:LoadValue("CNE_NUMSC" ,__NumSc) 
					 oModelCNE:LoadValue("CNE_ITEMSC",aItens[nI][DEF_ITEM])
	 				 oModelCNE:LoadValue("CNE_OBS"   ,aItens[nI][DEF_OBS])
					
					If lCC            			
						  oModelCNE:LoadValue("CNE_CC",aItens[nI][DEF_CC])											  
					EndIf	  
					 oModelCNE:SetValue("CNE_VLTOT",aItens[nI][2]*nValor)
				EndIf  
			endif // CTRFIX	
		Next		
	EndIf
	cQuebra:= cContrato+cCompet
	cTxPlan += "Planilha"+" - "+cPlanilha+CHR(13)+CHR(10)
EndIf

lFind:= .F.
conout("Validando medicao ")
//-- Commit na medição
If (lContinua := oModel:VldData())
conout("Comitando medicao ")
	lContinua := oModel:CommitData()
Else             
	cHelp+= cContrato+" - "+cPlanilha+": não foi possivel validar o modelo ("+oModel:AERRORMESSAGE[6]+")"+CRLF
	conout(cHelp)
EndIf
oModel:DeActivate()
cMedicao := ""
If lContinua
	While ( GetSX8Len() > nStack )
		ConfirmSX8() //-- Retorna controle de numeracao
	EndDo
	
	cTxLog += "Medicao gerada com sucesso"+" - "+CND->CND_NUMMED+CHR(13)+CHR(10)//
	cTxLog += "Contrato"+" - "+cContrato+CHR(13)+CHR(10)
	cTxLog += "Filial"+" - "+xFilial("CN9")+CHR(13)+CHR(10)
	cTxLog += cTxPlan
	cTxLog += "Competencia"+" - "+cCompet+CHR(13)+CHR(10)
	
	cTxPlan:= ""
	
	ConOut( Replicate("-",128) )
	ConOut("Medicao"+" - "      + CND->CND_NUMMED )
	ConOut( "Contrato"+" - "    + cContrato )
	ConOut( "Competencia"+" - " + cCompet )
	ConOut( Replicate("-",128) )
	
	// Rotina de encerramento de medição      
	If CND->CND_SITUAC <> 'B'
		lContinua := CN121Encerr(.t.)
		
		If lContinua
			ConOut( Replicate("-",128) )
			ConOut( "Medicao encerrada com sucesso"+" - " + CND->CND_NUMMED )
			ConOut( "Contrato"+" - " + cContrato )
			ConOut( Replicate("-",128) )
		Endif                    
	Else 
		cHelp := "Medição bloqueada. Os pedidos serão gerados após aprovação."
	EndIf 
  	cMedicao := CND->CND_NUMMED
Else
	While GetSX8Len() > nStack
		RollBackSX8()
	EndDo 
	cTxLog += "Falha"+CHR(13)+CHR(10)
	cTxLog += "Contrato"+" - "+cContrato+CHR(13)+CHR(10)
	cTxLog += "Filial"+" - "+xFilial("CN9")+CHR(13)+CHR(10)
	cTxLog += "Planilha"+" - "+cPlanilha+CHR(13)+CHR(10)
	cTxLog += "Competencia"+" - "+cCompet+CHR(13)+CHR(10)
	cTxLog += Replicate("-",128)+CHR(13)+CHR(10)

	imprime(lJob,cHelp)

Endif

conout(cTxLog)
Conout("Finalizando medição contrato"+cContrato+" Hora:"+Time())
Return {lContinua,cMedicao,cHelp}


Static Function imprime(lJob,cMsg)

If lJob
	conout(cMsg)
Else
	Aviso("Medição Automatica",cMsg,{"OK"})
EndIf

Return
