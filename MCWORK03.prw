#Include "Protheus.ch" 
#Include "TopConn.ch" 

// =======================================================================
/*/{Protheus.doc} MCWORK03
Rotina de Envio do Email de Aprovação do de Medições de Contrato
@author  Aldo Barbosa dos Santos
@since   07/07/2022
/*/ 
// =======================================================================
User Function MCWORK03(cFilCnt, cContra, cRevisa, cNumMed, cPlanilha) 
// =======================================================================

Local cQry    := ""
Local aMail   := {}
Local cTstNrMed := ""  					// --> Incluso  ALDO 23/05/2022   (Para informar Medição de TESTE) 
Local nPos     := 0
Local nR       := 0
Local cPathMod := GetMV("MC_WFPMOD" , , "\WORKFLOW\") 
Local cUrlWf   := GetMV("MC_URLWF"  , , "http://172.16.24.26:81/wf") 				// --> Alterado PROX 20/03/2021   [ Era: GetMV("MC_URLWF" , , "http://54.207.46.24:81/wf") ] 

Private MSGP_NONE := ""												// Ajuste pra corrigir erro do padrao - Cristiam Rossi em 04/10/2018

Private cIdHtml  := ""
Private cPathMod := "\workflow\"
Private oProcess := Nil 
Private oHtml    := Nil 
Private cMailID  := ""
Private aAreas   := {GetArea()}
Private cAssunto :=  "Aprovacao Medição de Contrato"
Private cModelo  := "WFMEDCNT.HTML"
Private cNomSol  := ""
Private nTotSCom := 0

cNomeAprov	:= "Nome Aprovador"

oModelCND := oModel:GetModel('CNDMASTER')
oModelCXN := oModel:GetModel("CXNDETAIL")
oModelCNE := oModel:GetModel('CNEDETAIL')

cFilCnt := oModelCND:GetValue("CND_FILIAL")
cContra := oModelCND:getValue("CND_CONTRA")
cRevisa   := oModelCND:GetValue("CND_REVISA")
cNumMed   := oModelCND:GetValue("CND_NUMMED")
cPlanilha := oModelCXN:GetValue("CXN_NUMPLA")

// carrega os aprovadores (somente se ainda não aprovado)
cQry := "Select CR_GRUPO, CR_USER, CR_APROV, AK_EMAIL from "+RetSqlName("SCR")
cQry += "  Left Join "+RetSqlName("SAK")+" AK "
cQry += "         On AK.D_E_L_E_T_ <> '*' And AK_FILIAL = '"+xFilial("SAK")+"' AND AK_COD = CR_APROV  And AK_EMAIL <> ' ' "
cQry += " Where CR.D_E_L_E_T_ <> '*' And CR_DATALIB = ' ' And CR_FILIAL = '"+cFilCnt+"' And CR_TIPO = 'MD' And CR_NUM = '"+cNumMed+"' "
dbUseArea(.T. , "TopConn" , TcGenQry(,,cQry) , "TMPSCR" , .T. , .T.)

Do While TMPSCR->( ! Eof())
	_cGrupo := TMPSCR->CR_GRUPO
	_cUser  := TMPSCR->CR_USER
	_cAprov := TMPSCR->CR_APROV
	_cEmail := TMPSCR->AK_EMAIL

	Aadd(aMail, { _cEmail	,;
 				  _cGrupo	,;
				  _cUser	,;
				  _cAprov	} )

	TMPSCR->( Dbskip())
Enddo

TMPSCR->( DbcloseArea())

// criacao do Workflow
oHtml    := Nil 
oProcess := TWFProcess():New(cCodPrc , cAssunto) 					// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
oProcess:NewTask(cAssunto, cPathMod + cModelo )				// Cria o objeto referente a tareja, com o modelo do html a ser preenchido 
oProcess:cSubject := cAssunto										// Repasse o texto do assunto criado para a propriedade especifica do processo.

nPos := aScan(aDados , {|x| x[1] == "EMAIL" }) 					// Informe o endereço eletrônico do destinatário.
oProcess:cTo := aMail[1,1]
oProcess:cCC := ""
For nR := 2 to Len(aMail)
	oProcess:cCC += Alltrim(aMail[nE,1])+";"
Next

// Informe o nome da função de retorno a ser executada quando a mensagem de respostas retornarem ao Workflow:
oProcess:bReturn := "U_MCRETMED('"+"APROV1"+"')"
oProcess:oHTML:ValByName("ASSUNTO"		, cAssunto)
oProcess:oHTML:ValByName("MODELO_HTML"	, "WFMEDCNT.HTML")
oProcess:oHTML:ValByName("EMAIL"		, "aldo.santos@prox.com.br")
oProcess:oHTML:ValByName("FILMED"		, "FilMed")
oProcess:oHTML:ValByName("NUMMED"		, "NumMed")
oProcess:oHTML:ValByName("NOMEFIL"		, "Nome Filial")
oProcess:oHTML:ValByName("Link"			, cUrlWf + "/" + cIdHtmlWf + ".htm")
oProcess:oHTML:ValByName("F_RETURN"		, "U_MCRETMED")
oProcess:oHTML:ValByName("TIPLIB"		, "(APROVACAO MEDICAO DE CONTRATO)")
oProcess:oHTML:ValByName("WFUSER"		, __cUserId )
oProcess:oHTML:ValByName("APROVAD"		, cNomeAprov)
oProcess:oHTML:ValByName("WFID"			, oProcess:fProcessId)
oProcess:oHTML:ValByName("WFEMPRESA"	, cEmpAnt)
oProcess:oHTML:ValByName("WFFILIAL"		, CN9->CN9_FILIAL)
oProcess:oHTML:ValByName("WFMAILID"		, ""                 )
oProcess:oHTML:ValByName("CNDRECNO"		, "000001")
oProcess:oHTML:ValByName("CCUSTO"		, "CCUSTO")
oProcess:oHTML:ValByName("EMAIRES"		, "aldo.santos@prox.com.br" )

	While (cAliEmai)->(!Eof())  .And.  AllTrim((cAliEmai)->C1_FILIAL) == aDadEmai[03] .And. ; 
	      AllTrim((cAliEmai)->C1_CC) == aDadEmai[05]  .And.  AllTrim((cAliEmai)->C1_NUM) == aDadEmai[04] 
		aAdd((oProcess:oHTML:ValByName("IT.C1_DESCRI")) , AllTrim((cAliEmai)->C1_DESCRI)+" "+AllTrim((cAliEmai)->C1_DESCRIC)) 
		aAdd((oProcess:oHTML:ValByName("IT.C1_QUANT"))  ,       TransForm((cAliEmai)->C1_QUANT,"@E 999,999.99"  )) 
		aAdd((oProcess:oHTML:ValByName("IT.C1_PRECO"))  , "R$ "+TransForm((cAliEmai)->C1_VUNIT,"@E 999,999.99"  )) 
		aAdd((oProcess:oHTML:ValByName("IT.C1_TOTAL"))  , "R$ "+TransForm((cAliEmai)->C1_TOTAL,"@E 9,999,999.99")) 

		nTotSCom += ((cAliEmai)->C1_QUANT * (cAliEmai)->C1_VUNIT) 

		SC1->(dbGoTo((cAliEmai)->C1_RECNO)) 
		RecLock("SC1",.F.) 
			SC1->C1_DTENVEM	:= dDataBase 
		SC1->(MsUnLock()) 

		(cAliEmai)->(dbSkip()) 
	EndDo 

	// Dados do "Rodape" do pedido
	oProcess:oHTML:ValByName("TOTALSOLC" , "R$ "+Transform(nTotSCom , "@E 999,999,999.99")) 

	nTotSCom	:= 0


// Apos ter repassado todas as informacoes necessarias para o workflow, solicite a ser executado 
// o método Start() para se gerado todo processo e enviar a mensagem ao destinatário.
cMailID := oProcess:Start(cPathMod + "htmls")

If Empty(cAttachFile)
	WFSendMail({SM0->M0_CODIGO , SM0->M0_CODFIL}) 
EndIf

// Restaura a area
AEval(aAreas, {|x| RestArea(x)})
                
Return cMailID



// ======================================================================= \\
/*/{Protheus.doc} MCRETLPC
Função responsável pelo tratamento do retorno do workflow.
Desbloqueia a viagem e envia e-mail de ocnfirmação
@param   nFlag          Variável interna do WF
@param   oProcess       Objeto referente ao processo respondido
@author  Ederson Colen.
@since   05/10/2012
@Return  Nil
/*/ 
// ======================================================================= \\

/*  Elvis Siqueira 28/12/2023 (Retirado pois já existe no fonte MCWORK02)
User Function MCRETLSC(nFlag , oProcess) 
// ======================================================================= \\

Local lPrcemai	:= .F.
Local cMsgEmai	:= ""

Local cAprovS	:= oProcess:oHtml:RetByName("APROVAD")
Local cEmailAp	:= oProcess:oHtml:RetByName("EMAIRES")
Local cCCusto	:= oProcess:oHtml:RetByName("CCUSTO" )
Local cSolComp	:= oProcess:oHtml:RetByName("NUMSOLC")
Local cFILMed	:= oProcess:oHtml:RetByName("FILMED")

Local cTipRot	:= oProcess:oHtml:RetByName("WFTIPO" ) 
Local nC1RECNO	:= Val(oProcess:oHtml:RetByName("C1RECNO")) 

dDataBase := Date() 

ConOut("##_MCWORK02.prw - MCRETLSC() - Retorno Workflow - INICIO ----------") 

ConOut("##_MCWORK02.prw - nC1RECNO.: ["+cValToChar(nC1RECNO)+"]") 
ConOut("##_MCWORK02.prw - M0_CODFIL: ["+SM0->M0_CODFIL      +"]") 
ConOut("##_MCWORK02.prw - cEmailAp.: ["+cEmailAp            +"]") 

SC1->(dbSetOrder(1)) 
SC1->(dbGoTo(nC1RECNO)) 

ConOut("##_MCWORK02.prw - Posicionei") 

If SC1->(! Eof()) 

	ConOut("##_MCWORK02.prw - Achei o registro: C1_NUM: ["+SC1->C1_NUM+"]") 
	ConOut("##_MCWORK02.prw - TIPO = ["+cTipRot+"]") 

	While SC1->(!Eof())  .And.  SC1->C1_FILIAL == cFilMed  .And.  SC1->C1_NUM == cSolComp 

		If AllTrim(SC1->C1_CC) <> AllTrim(cCCusto)
			SC1->(dbSkip())
			Loop
		EndIf

		Do Case
		Case cTipRot == "LIBERAR"
			ConOut("##_MCWORK02.prw - Tinha que LIBERAR") 
			If RecLock("SC1")
				If SC1->C1_APROV $ " ,B,R"  .And.  SC1->C1_QUJE == 0 
					SC1->C1_APROV := "L" 
					If SC1->(FieldPos("C1_NOMAPRO")) > 0 
						SC1->C1_NOMAPRO := UsrRetName(cAprovS) 
					EndIf 
				EndIf 
				MaAvalSC("SC1" , 8) 
			EndIf 
			lPrcemai := .T. 
			cMsgEmai := "LIBERADA COM SUCESSO" 

		Case cTipRot == "REJEITAR" 
			ConOut("##_MCWORK02.prw - Tinha que REJEITAR") 
			If RecLock("SC1") 
				If SC1->C1_APROV $"B,L, "  .And.  SC1->C1_QUJE == 0 
					SC1->C1_APROV := "R" 
					If SC1->(FieldPos("C1_NOMAPRO")) > 0 
						SC1->C1_NOMAPRO := UsrRetName(cAprovS) 
					EndIf 
				EndIf 
				MaAvalSC("SC1" , 8) 
			EndIf 
			lPrcemai := .T. 
			cMsgEmai := "REJEITADA COM SUCESSO" 

		EndCase 

		SC1->(dbSkip()) 

	EndDo 

EndIf 

If lPrcemai  .And.  ! Empty(cEmailAp) 
	ConOut("##_MCWORK02.prw - Tinha que mandar Email.") 
	FAprWFOK(cFILMed , cSolComp , cMsgEmai , cEmailAp) 
EndIf 

ConOut("##_MCWORK02.prw - MCRETLSC() - Retorno Workflow - FINAL  ----------") 

Return Nil
*/


// ======================================================================= \\
/*/{Protheus.doc} FAprWFOK
Envia e-mail confirmando que a viagem foi liberada com sucesso para a 
conta cadastrada no parâmetro
@author  Ederson Colen
@since   29/05/2013
@param   cSolComp       Código da viagm
         cFunApr1       Codigo do Funcionar 1a Aprovacao
         cFunApr2       Codigo do Funcionar 2a Aprovacao
@Return  Nil
/*/ 
// ======================================================================= \\

/* Elvis Siqueira 28/12/2023 (Retirado pois já existe no fonte MCWORK02)
Static Function FAprWFOK(cFILMed , cSolComp , cMsgEmai , cEmailAp) 
// ======================================================================= \\
                         
Local cPathMod := "\workflow\" 
Local cCodPrc  := AllTrim(cSolComp) 

aDados := {}

aAdd(aDados , {"ASSUNTO"     , "Solicitaco Compra "+cSolComp+" - "+cMsgEmai}) 
aAdd(aDados , {"MODELO_HTML" , "WFERLISC.HTML"                             }) 
aAdd(aDados , {"EMAIL"       , cEmailAp                                    }) 
aAdd(aDados , {"FILMED"     , cFILMed+" - "+SM0->M0_FILIAL               }) 
aAdd(aDados , {"NUMSOLC"     , cSolComp                                    }) 
aAdd(aDados , {"TIPOCOR"     , cMsgEmai                                    }) 

FSendEml(cPathMod , cCodPrc , aDados , Nil) 

Return Nil
