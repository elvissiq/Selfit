#include "protheus.ch"
#include "topconn.ch"

User Function M110STTS()
Local cNumSol   := Paramixb[1]
Local nOpt      := Paramixb[2]
Local lCopia    := Paramixb[3]

//Éder Prox 28/06/2022 Inclusão do IF para decidir se envia ou não aprovação de SC por e-mail (U_MCWORK02)
If nOpt == 1
   // If MsgYesNo("Deseja enviar WF/Email para aprovação?")
        U_MCWORK02('MATA110')
   // EndIf
EndIf

If nOpt == 1 .AND. (funname() == "MATA110")
	Processa( {|| TpExecMed(cNumSol) }, "Aguarde...", "Gerando Medicao...",.F.)
EndIf

Return Nil

//Executa a medicao
Static Function TpExecMed( cNumSol )
Local cContra   := ""
Local cPlanilha := ""
Local aRecno    := {}
Local aItens    :={}
Local cPedido  := ""
Local nK	

cSQL := " SELECT C1_ITEM,C1_NUM,C1_PRODUTO,C1_QUANT,C1_VUNIT,C1_CC,C1_CONTRA,C1_PLANILH,C1_PAROBRA,C1_OBS,C1_FILCONT,R_E_C_N_O_ AS ID,C1_TPCTG "+CRLF
cSQL += " FROM "+RetSqlName("SC1")+" "+CRLF
cSQL += " WHERE D_E_L_E_T_ = '' "+CRLF
cSQL += " AND C1_TPCTG <> '' "+CRLF           
cSQL += " AND C1_FILIAL = '"+xFilial("SC1")+"'                              "+CRLF           
cSQL += " AND C1_NUM = '"+cNumSol+"'
cSQL += " ORDER BY C1_NUM,C1_FILCONT,C1_CONTRA,C1_CC,C1_PLANILH,C1_PAROBRA "+CRLF
MPSysOpenQuery( cSQL, 'TRS' )

While !TRS->(EOF())          
	cFilContra   := TRS->C1_FILCONT
	cContra   := TRS->C1_CONTRA
	cPlanilha := TRS->C1_PLANILH  
	cParcela  := TRS->C1_PAROBRA //Contrato com regra de negociação só permite um SC por vez
	aItens := {}
	aRecno := {}
	
	While !TRS->(EOF()) .AND. TRS->C1_NUM ==  cNumSol  .AND. cContra == TRS->C1_CONTRA .AND. cPlanilha == TRS->C1_PLANILH .AND. cParcela  == TRS->C1_PAROBRA .AND. cFilContra == TRS->C1_FILCONT
		If !Empty(TRS->C1_CONTRA)
			aadd(aItens,{TRS->C1_PRODUTO,TRS->C1_QUANT,TRS->C1_CC,TRS->C1_ITEM,TRS->C1_OBS,TRS->C1_VUNIT,TRS->C1_TPCTG})
			aadd(aRecno,TRS->ID)
		EndIf
		TRS->(DbSkip())
	Enddo
	
	If Len(aItens) > 0  
		//aRet := StartJob( "U_ExcMed110", GetEnvServer(), .T.,{cContra,cPlanilha,aItens,xFilial("SC1"),"","",cParcela,cFilContra} )
		aRet := u_ExcMedEnv({cContra,cPlanilha,aItens,xFilial("SC1"),"","",cParcela,cFilContra,cNumSol})
	EndIf
	
	If Type("aRet") == "A" .And. aRet[1]
		For nK := 1 To Len(aRecno)
			SC1->(DbGoto(aRecno[nK]))
			If Reclock("SC1",.f.)
				SC1->C1_FLAGGCT := "1"
				SC1->C1_QUJE    := SC1->C1_QUANT
				SC1->C1_MEDICAO := aRet[2]
				SC1->(MsUnLock())
			EndIf
		Next                     
		
		cSQL := " SELECT * FROM "+RetSqlName("SC7")+" "
		cSQL += " WHERE D_E_L_E_T_ = ''
		cSQL += " AND C7_MEDICAO = '"+aRet[2]+"'
		cSQL += " AND C7_FILIAL = '"+xFilial("SC1")+"'
		MPSysOpenQuery( cSQL, 'TRN' )
		If TRN->(!Eof())
			cPedido += TRN->C7_NUM+CRLF
		EndIf       
		TRN->(DbCloseArea())		
	ElseIf Type("aRet") == "A" .And. !aRet[1]	
		Alert(aRet[3])                          
	ElseIf 	 Type("aRet") == "A" .And. !Empty(aRet[3])	
		Aviso("Medição Automatica",aRet[3],{"OK"})
	EndIf
	
EndDo

If !Empty(cPedido)
	Aviso("Medição de Contratos","Pedidos gerados com sucesso!"+CRLF+cPedido,{"OK"})
ElseIf  Type("aRet") == "A" .And. aRet[1]
	Aviso("Medição de Contratos",aRet[3],{"OK"})	
EndIf


Return

User Function ExcMed110(aConf)
Local aRet := {}

conout("iniciando ambiente na filial "+aConf[8])
RpcSetEnv( "01" , aConf[8],,, "GCT", GetEnvServer() )
aRet := U_TPCNT121(.F.,aConf[1],aConf[2],aConf[3],aConf[4],aConf[5],aConf[6],aConf[7],aConf[9])

RpcClearEnv()

Return aRet

User Function ExcMedEnv(aConf)
Local aRet := {}          
Local cFilBak := cFilAnt

conout("iniciando ambiente na filial "+aConf[8])
//RpcSetEnv( "01" , aConf[8],,, "GCT", GetEnvServer() )
cFilAnt := aConf[8]
//U_TPCNT121(.F.,aGCTMed[_x][2],aGCTMed[_x][3],aItens,aGCTMed[_x][5],aGCTMed[_x][6],aGCTMed[_x][7])
aRet := U_TPCNT121(.F.,aConf[1],aConf[2],aConf[3],aConf[4],aConf[5],aConf[6],aConf[7],aConf[9])

//RpcClearEnv()

cFilAnt := cFilBak

Return aRet
