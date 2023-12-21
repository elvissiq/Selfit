#Include "PROTHEUS.CH"
#Include "topconn.ch" 


// Funcao da chamada padrão do workflow de pedido de compras WFW120P
User Function WFW120P()

	Local aArea := GetArea()

	//Private cNumPed   := "TEUDQZ" 
	Private cEmailTst := ""//"vinicius.oliveira@prox.com.br"
	
	//If MsgYesNo("Deseja enviar WF/Email para aprovação?")	
		U_MWORK01(SC7->C7_NUM,cEmailTst)
	//Endif 	
	
	RestArea(aArea)

Return


//-------------------------------------------------------------------
/*/{Protheus.doc} MCWORK01
Rotina de Re-Envio do Email de Aprovação do Adiantamento ou Contrato e Complemento.

@protected
@author    Ederson Colen
@since     20/06/2013
@obs       

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/ 
//-------------------------------------------------------------------
User Function MWORK01(cNumPed,cEmailTst)

Local cAliEmai	:= "QPCLIB"

Local cQuery    := ""
Local cEmail    := ""
Local cIdHtmlWf := ""
//Local nRegSM0	:= SM0->(Recno())
//Local cFilOld	:= SM0->M0_CODFIL
Local cNomFil	:= ""
Local nRecNoCR	:= 0
Private MSGP_NONE := ""		// ajuste pra corrigir erro do padrao - Cristiam Rossi em 04/10/2018

If Select(cAliEmai) <> 0
	(cAliEmai)->(dbCloseArea())
EndIf

cQuery += " SELECT CR.R_E_C_N_O_ AS CR_RECNO, * "
cQuery += " FROM "+RetSQLName("SCR")+" CR  "
cQuery += " INNER JOIN "+RetSQLName("SAK")+" AK ON(AK.D_E_L_E_T_ = '' AND AK.AK_FILIAL = '"+xFilial("SAK")+"' AND AK.AK_COD = CR.CR_APROV)  "
cQuery += " INNER JOIN "+RetSQLName("SC7")+" C7 ON(C7.D_E_L_E_T_ = '' AND C7.C7_FILIAL = CR.CR_FILIAL AND C7.C7_NUM = CR.CR_NUM AND C7.C7_RESIDUO <> 'S') "
cQuery += " INNER JOIN "+RetSQLName("SA2")+" A2 ON(A2.D_E_L_E_T_ = '' AND A2.A2_FILIAL = '"+xFilial("SAK")+"' AND A2.A2_COD = C7.C7_FORNECE AND A2.A2_LOJA = C7.C7_LOJA) "
cQuery += " LEFT OUTER JOIN "+RetSQLName("CTT")+" CTT ON(CTT.D_E_L_E_T_ = '' AND CTT.CTT_FILIAL = '"+xFilial("CTT")+"' AND CTT.CTT_CUSTO = C7.C7_CC) "
cQuery += " WHERE CR.D_E_L_E_T_ = ''  "
cQuery += " AND CR.CR_FILIAL = '"+xFilial("SCR")+"'  "
cQuery += " AND CR.CR_TIPO = 'PC'  "
cQuery += " AND CR.CR_STATUS = '02'  "
cQuery += " AND (CR.CR_DTENVEM = '' OR (CR.CR_DTENVEM <= '"+DToS(dDataBase-2)+"' AND CR.CR_STATUS = '02')) "

if ! Empty(cNumPed)
	cQuery += " AND C7_NUM = '"+cNumPed+"' "
Endif
cQuery += " ORDER BY CR.CR_FILIAL, CR.CR_NUM, CR.CR_APROV, C7.C7_ITEM "

//Cria o arquivo de trabalho da query posicionada
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliEmai,.F.,.T.)

(cAliEmai)->(dbGoTop())

While (cAliEmai)->(! Eof())

	nRecNoCR	:= (cAliEmai)->CR_RECNO
	aDadEmai	:= {AllTrim((cAliEmai)->CR_NUM),;
					if(Empty(cEmailTst),AllTrim((cAliEmai)->AK_EMAIL),cEmailTst),;
					AllTrim((cAliEmai)->CR_FILIAL),;
					AllTrim((cAliEmai)->CR_NUM)}

	cNomFil	:= SM0->M0_FILIAL

	//Montando apenas um html para aprovação do Pedido de Compra . Este html será enviado para todos os aprovadores.
	cIdHtmlWf := FGrArqHtml(cAliEmai,cNomFil)
	
	//Enviando o workflow com o link, ao clicar no link, o usuário será encaminhado para o html com Id = o id passado
	FEnvEmiWf(cIdHtmlWf,aDadEmai,cNomFil,cAliEmai)
   
	dbSelectArea("SCR")
	dbGoTo(nRecNoCR)
	RecLock("SCR",.F.)
	SCR->CR_DTENVEM	:= dDataBase
	SCR->(MsUnLock())

EndDo

If Select(cAliEmai) <> 0
	(cAliEmai)->(dbCloseArea())
EndIf

Return Nil



//------------------------------------------------------------------- 
/*/{Protheus.doc} FGrArqHtml
Monta o Html com os dados do Pedido de Compra para Liberacao

@author		Ederson Colen
@since   	9/08/2016

@param		

@Return		cIdHtml		Id do processo gerado, será também o nome do html
            
Alteracoes Realizadas desde a Estruturacao Inicial 
Data       Programador     Motivo 
/*/ 
//------------------------------------------------------------------- 
Static Function FGrArqHtml(cAliEmai,cNomFil)

Local cIdHtml	:= ""
Local cPathMod	:= "\workflow\"

Local cCodPrc	:= AllTrim((cAliEmai)->CR_NUM)
Local aDados	:= {}   

AAdd(aDados,{"MODELO_HTML"		, "WFLIBPEDC.HTML"		})
AAdd(aDados,{"EMAIL"		  		, ""					})//Não mandar esse e-mail pra ninguém
AAdd(aDados,{"FILPEDC"			, AllTrim((cAliEmai)->CR_FILIAL)	})
AAdd(aDados,{"NPEDIDO"			, AllTrim((cAliEmai)->CR_NUM)	})
AAdd(aDados,{"WFUSER"			, AllTrim((cAliEmai)->AK_NOME)	})
AAdd(aDados,{"APROVAD"			, AllTrim((cAliEmai)->CR_APROV)	})
AAdd(aDados,{"CRRECNO"			, AllTrim(Str((cAliEmai)->CR_RECNO))})

//Dados necessários ao workflow em si
AAdd(aDados,{"ASSUNTO"			, "Aprovacao do Pedido de Compra"	})
AAdd(aDados,{"F_RETURN"			, "U_MCRETLPC"			})
AAdd(aDados,{"TIPLIB"			,"(APROVACAO PEDIDO COMPRA)"})

cIdHtml := FSendEml(cPathMod,cCodPrc,aDados,"000001",cAliEmai)

Return cIdHtml



//-----------------------------------------------------------------------------------
/*/{Protheus.doc} FEnvEmiWf
Monta o Html com os dados da viagem e retorna o id do html gerado.
O html será montado separadamente, pois um único  Html será enviado
para vários aprovadores

@author		Ederson Colen
@since   	29/05/2013

@param		cIdHtmlWf	Código do processo WF gerado
				cEmail		Endereço de e-mail para onde será enviaod o wf
				cMsgBlq		Mensagem do bloqueio
				cDTYNUMCTC
                  
@Return		Nil
            
Alteracoes Realizadas desde a Estruturacao Inicial 
Data       Programador     Motivo 
/*/ 
// ======================================================================= \\
Static Function FEnvEmiWf(cIdHtmlWf,aDadEmai,cNomFil,cAliEmai)
// ======================================================================= \\
	            
Local cPathMod	:= GetMv("MC_WFPMOD" , , "\WORKFLOW\")
// --> Conferido parâmetro "MC_WFPMOD"  (SX6010) em 20/03/2021 (ambiente produção 12.1.17) e este existe, porém DELETADO e com conteudo 'WORKFLOW'

Local cUrlWf	:= GetMv("MC_URLWF"  , , "http://172.16.24.26:81/wf") 				// --> Alterado PROX 20/03/2021   [ Era: GetMv("MC_URLWF" , , "http://54.207.46.24:81/wf") ] 
// --> Conferido parâmetro "MC_URLWF"   (SX6010) em 20/03/2021 (ambiente produção 12.1.17) e estava com conteúdo 'http://54.207.46.24:82/wf' 
// --> No ambiente novo (release 27) o IP será o 172.16.24.26.

Local cCodPrc	:= aDadEmai[01]

//Monta o link com o id do html gerado e dispara para os aprovadores do e-mail
//Preencher os dados do html do link
aDados := {}

AAdd(aDados,{"ASSUNTO"		,"Aprovacao Pedido de Compra"	})
AAdd(aDados,{"MODELO_HTML"	, "WFEELIPC.HTML"				})
AAdd(aDados,{"EMAIL"		, aDadEmai[02]					})
AAdd(aDados,{"FILPEDC"		, aDadEmai[03] 					})
AAdd(aDados,{"PEDIDOC"		, aDadEmai[04] 					})
AAdd(aDados,{"NOMEFIL"		, AllTrim(cNomFil)				})
AAdd(aDados,{"Link"			, cUrlWf + "/" + cIdHtmlWf + ".htm"})

FSendEml(cPathMod,cCodPrc,aDados,Nil,cAliEmai)

Return Nil



//--------------------------------------------------------------------------------------------------
/*/{Protheus.doc} FSendEml
Função para enviar e-mails conforme os protocolos vão sendo alterados.

@author		Ederson Colen
@since   	10/08/2016

@param		cPathMod   	Pasta à partir da pasta raiz, onde estão os arquivos html de layout
			cCodPrc		Código do processo do workflow
			aDados 		Dados a serem enviados. Preenche o workflow e envia
			cAttachFile Caminho do arquivo, a partir da pasta raiz, para ser anexado

@Return cMailID	Id gerado no processo de envio de e-mail
            
Alteracoes Realizadas desde a Estruturacao Inicial 
Data       Programador     Motivo 
/*/
//---------------------------------------------------------------------------------------------------
Static Function FSendEml(cPathMod,cCodPrc,aDados,cAttachFile,cAliEmai)

Local   oProcess	:= Nil
Local   oHtml		:= Nil    
Local   cMailID	:= ""
Local   aAreas	:= {GetArea()}
Local   nPos		:= 0
Local   cAssunto	:= ""
Local   nX	  	 := 0
                
Local   nTotPed 	:= 0
Local   nTotDes 	:= 0
Local   nTotIpi 	:= 0 
Local   nTotFrt 	:= 0  
Local   nToDesp 	:= 0  
Local   cCCusto 	:= ""

default cAliEmai := ""

nPos := AScan(aDados,{|x| x[1] == "ASSUNTO" })//Buscando o Assunto do e-mail
cAssunto := aDados[nPos][2] //Lendo o assunto

oProcess := TWFProcess():New(cCodPrc, cAssunto) // Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
                                                                                                                               
nPos := AScan(aDados,{|x| x[1] == "MODELO_HTML" })//Buscando o Assunto do e-mail
oProcess:NewTask(cAssunto, cPathMod + aDados[nPos][2] )//Cria o objeto referente a tareja, com o modelo do html a ser preenchido 

oProcess:cSubject := cAssunto// Repasse o texto do assunto criado para a propriedade especifica do processo.

nPos := AScan(aDados,{|x| x[1] == "EMAIL" })// Informe o endereço eletrônico do destinatário.
oProcess:cTo := aDados[nPos][2] 

varinfo("aDados: ", aDados)


// Informe o nome da função de retorno a ser executada quando a mensagem de
// respostas retornarem ao Workflow:
nPos := AScan(aDados,{|x| x[1] == "F_RETURN" })// Informe a função que o wf irá excutar ao retornar
If(nPos > 0)
	oProcess:bReturn := AllTrim(aDados[nPos][2]) + "(1)"
EndIf

If (!Empty(cAttachFile))
	oProcess:AttachFile(cAttachFile)
EndIf

If Empty(cAttachFile)

	//Preenchendo as variáveis do html
	//Fazer, posteriormente uma alteração neste ponto para preencher tabelas
	For nX := 1 to Len(aDados)
		If !(aDados[nX][1] $ "ASSUNTO/MODELO_HTML/EMAIL/F_RETURN") //Não usar as Variáveis especiais do WF
			oProcess:oHTML:ValByName(aDados[nX][1],aDados[nX][2])
		EndIf
	Next

Else

	oProcess:oHTML:ValByName("FILPEDC"	, aDados[03,02])
	oProcess:oHTML:ValByName("NPEDIDO"	, aDados[04,02])
	oProcess:oHTML:ValByName("WFUSER"	, aDados[05,02])
	oProcess:oHTML:ValByName("APROVAD"	, aDados[06,02])
	oProcess:oHTML:ValByName("WFID"		, oProcess:fProcessId)
	oProcess:oHTML:ValByName("WFEMPRESA", SM0->M0_CODIGO)
	oProcess:oHTML:ValByName("WFFILIAL"	, aDados[03,02])
	oProcess:oHTML:ValByName("WFMAILID"	, "")
	oProcess:oHTML:ValByName("CRRECNO"	, aDados[07,02])
	
	if ! empty(cAliEmai)
		oProcess:oHTML:ValByName("A2_COD",	(cAliEmai)->A2_COD)
		oProcess:oHTML:ValByName("A2_LOJA",	(cAliEmai)->A2_LOJA)
		oProcess:oHTML:ValByName("A2_NOME",	(cAliEmai)->A2_NOME)
		
		oProcess:oHTML:ValByName("C7_NUM",	(cAliEmai)->C7_NUM)
		oProcess:oHTML:ValByName("C7_EMISSAO",	DTOC(SToD((cAliEmai)->C7_EMISSAO)))		

		While (cAliEmai)->(! Eof()) .And. ;
			AllTrim((cAliEmai)->CR_FILIAL)  == aDados[03,02] .And. ;
			AllTrim((cAliEmai)->CR_NUM)		== aDados[04,02] .And. ;
			AllTrim((cAliEmai)->CR_APROV)		== aDados[06,02]

			cCCusto := AllTrim((cAliEmai)->C7_CC)+"-"+AllTrim((cAliEmai)->CTT_DESC01)

			aAdd((oProcess:oHTML:ValByName("IT.C7_DESCRI"))		, AllTrim((cAliEmai)->C7_DESCRI)+" "+AllTrim((cAliEmai)->C7_DESCRIC))
			aAdd((oProcess:oHTML:ValByName("IT.C7_QUANT"))		, TransForm((cAliEmai)->C7_QUANT,"@E 999,999.99"))
			aAdd((oProcess:oHTML:ValByName("IT.C7_PRECO"))		, "R$ "+TransForm((cAliEmai)->C7_PRECO,"@E 999,999.99"))
			aAdd((oProcess:oHTML:ValByName("IT.C7_TOTAL"))		, "R$ "+TransForm((cAliEmai)->C7_TOTAL,"@E 9,999,999.99"))
			aAdd((oProcess:oHTML:ValByName("IT.C7_ALIIPI"))		, TransForm((cAliEmai)->C7_VALIPI,"@E 999,999.99"))
			aAdd((oProcess:oHTML:ValByName("IT.C7_DESC"))		, TransForm((cAliEmai)->C7_VLDESC,"@E 999,999.99"))
			aAdd((oProcess:oHTML:ValByName("IT.C7_CC"))			, cCCusto)

			nTotPed += ((cAliEmai)->C7_QUANT * (cAliEmai)->C7_PRECO)
			nTotDes	+= (cAliEmai)->C7_VLDESC
			nTotIpi	+= (cAliEmai)->C7_VALIPI 
			nTotFrt	+= (cAliEmai)->C7_VALFRE 
			nToDesp	+= ((cAliEmai)->C7_DESPESA + (cAliEmai)->C7_SEGURO)

			(cAliEmai)->(dbSkip())

		EndDo

		//Dados do "Rodape" do pedido
		oProcess:oHTML:ValByName("SUBTOTAL"		, "R$ "+Transform(nTotPed,'@E 999,999,999.99'))
		oProcess:oHTML:ValByName("TOTALDESC"	, "R$ "+Transform(nTotDes,'@E 999,999,999.99'))
		oProcess:oHTML:ValByName("TOTALIPI"		, "R$ "+Transform(nTotIpi,'@E 999,999,999.99'))
		oProcess:oHTML:ValByName("TOTAFRE"		, "R$ "+Transform(nTotFrt,'@E 999,999,999.99'))
		oProcess:oHTML:ValByName("TOTDESP"		, "R$ "+Transform(nToDesp,'@E 999,999,999.99'))
		oProcess:oHTML:ValByName("TOTALPEDC"	, "R$ "+Transform(((nTotPed + nTotFrt + nTotIpi + nToDesp) - nTotDes),'@E 999,999,999.99'))

		nTotPed	:= 0
		nTotDes	:= 0
		nTotIpi	:= 0 
		nTotFrt	:= 0  
		nToDesp	:= 0
	endif
EndIf

// Apos ter repassado todas as informacoes necessarias para o workflow, solicite a
// a ser executado o método Start() para se gerado todo processo e enviar a mensagem
// ao destinatário.
cMailID := oProcess:Start(cPathMod + "htmls")

If Empty(cAttachFile)
	WFSendMail({SM0->M0_CODIGO,SM0->M0_CODFIL})
EndIf

//restaura a area
AEval(aAreas, {|x| RestArea(x)})
                
Return cMailID



//------------------------------------------------------------------- 
/*/{Protheus.doc} MCRETLPC
Função responsável pelo tratamento do retorno do workflow.
Desbloqueia a viagem e envia e-mail de ocnfirmação

@param		nFlag			Variável interna do WF
@param 		oProcess		Objeto referente ao processo respondido
                  
@author		Ederson Colen.
@since   	05/10/2012

@Return		Nil
            
Alteracoes Realizadas desde a Estruturacao Inicial 
Data       Programador     Motivo 
/*/ 
//------------------------------------------------------------------- 
User Function MCRETLPC(nflag, oProcess)

Local cAprovS	:= ""
Local lPrcemai	:= .F.
Local cMsgEmai	:= ""
Local cEmailAp	:= ""

Local cPedComp	:= oProcess:oHtml:RetByName("NPEDIDO")
Local cFilPedC	:= oProcess:oHtml:RetByName("FILPEDC")

Local cTipRot	:= oProcess:oHtml:RetByName("WFTIPO")
Local nCRRECNO	:= Val(oProcess:oHtml:RetByName("CRRECNO"))
Local cMotRej	:= oProcess:oHtml:RetByName("MOTIVOREJE")
Local _cCodUsr  := ""
Local _cPedSCR  := ""


dDataBase := DATE()

CONOUT("CHEGUEI")
CONOUT(nCRRECNO)

CONOUT(SM0->M0_CODFIL)

SCR->(dbSetOrder(1))
SCR->(dbGoTo(nCRRECNO))
                 
CONOUT("POSICIONEI")

If SCR->(! Eof())

	CONOUT("ACHEI O REGISTRO")

	SAK->(dbSetOrder(1))
	SAK->(MsSeek(xFilial("SAK")+SCR->CR_APROV))

	If SAK->(!Eof())                
		_cCodUsr    := SAK->AK_USER
		cEmailAp	:= SAK->AK_EMAIL
	EndIf

	CONOUT("TIPO = "+cTipRot)

	Do Case
		Case cTipRot == "LIBERAR"

			dbSelectArea("SCR")
			RecLock("SCR",.F.)
			SCR->CR_DATALIB	:= dDataBase
			SCR->(MsUnLock())

			dbSelectArea("SC7")
			dbSetOrder(1)
			MsSeek(xFilial("SC7")+Substr(SCR->CR_NUM,1,Len(SC7->C7_NUM)))
			
			_cPedSCR := Substr(SCR->CR_NUM,1,Len(SC7->C7_NUM))

			CONOUT("TINHA QUE LIBERAR")
		
			//A097ProcLib(SCR->(Recno()),2)
			//Ajustado pois não estava preenchendo a data da liberação - Talvane (Tupi Consultoria) - 18/12/18
		    //A097ProcLib( nReg,nOpc,nTotal,cCodLiber,cGrupo,cObs,dRefer,oModelCT)
			//A097ProcLib( SCR->(Recno()),2,,_cCodUsr,,,dDataBase) //Ao passar o usuario a regra se prede.
			A097ProcLib( SCR->(Recno()),2,,,,,dDataBase)

			lPrcemai	:= .T.
			cMsgEmai	:= "APROVADO COM SUCESSO"
		
		Case cTipRot == "TRANSFERE"

			CONOUT("TINHA QUE TRANSFERIR")

			If ! Empty(SAK->AK_APROSUP)
				cAprovS:= SAK->AK_APROSUP
				A097ProcTf(SCR->(Recno()),2,cAprovS,AllTrim(SCR->CR_OBS)+"/EMAIL->"+cMotRej,dDataBase)
				lPrcemai	:= .T.
				cMsgEmai	:= "TRANSFERIDO COM SUCESSO"

			EndIf
		Case cTipRot == "BLOQUEIA"     

			CONOUT("TINHA QUE BLOQUIAR")
		
			If SCR->CR_STATUS $ "02"
				//A097ProcLib(SCR->(Recno()),6,/*nTotal*/,/*cCodLiber*/,/*cGrupo*/,AllTrim(SCR->CR_OBS)+"/EMAIL->"+cMotRej,/*dReger*/)
				A097ProcLib(SCR->(Recno()),6,/*nTotal*/,,/*cGrupo*/,AllTrim(SCR->CR_OBS)+"/EMAIL->"+cMotRej,/*dReger*/,dDataBase)
				lPrcemai	:= .T.
				cMsgEmai	:= "REJEITADO COM SUCESSO"
			EndIf
	EndCase
EndIf

If lPrcemai .And. ! Empty(cEmailAp)
	CONOUT("TINHA QUE MANDAR EMAIL.")
	FAprWFOK(cFilPedC,cPedComp,cMsgEmai,cEmailAp)
	//Se houver novas aprovacoes... - Talvane - Tupi Consultoria - 21/12/18
	u_MCWORK01P( _cPedSCR )
EndIf

Return Nil



//------------------------------------------------------------------- 
/*/{Protheus.doc} FAprWFOK
Envia e-mail confirmando que a viagem foi liberada com sucesso
para a conta cadastrada no parâmetro

@author		Ederson Colen
@since   	29/05/2013

@param		cPedComp		Código da viagm
				cFunApr1		Codigo do Funcionar 1a Aprovacao
				cFunApr2		Codigo do Funcionar 2a Aprovacao
                  
@Return		Nil
            
Alteracoes Realizadas desde a Estruturacao Inicial 
Data       Programador     Motivo 
/*/ 
//------------------------------------------------------------------- 
Static Function FAprWFOK(cFilPedC,cPedComp,cMsgEmai,cEmailAp)
                         
Local cPathMod	:= "\workflow\"
Local cCodPrc	:= AllTrim(cPedComp)

aDados := {}

AAdd(aDados,{"ASSUNTO"		,"Pedido "+cPedComp+" - "+cMsgEmai	})
AAdd(aDados,{"MODELO_HTML"	,"WFERLIPC.HTML"	})
AAdd(aDados,{"EMAIL"			,cEmailAp		})

AAdd(aDados,{"FILPEDC"		,cFilPedC+" - "+SM0->M0_FILIAL})
AAdd(aDados,{"PEDIDOC"		,cPedComp							})
AAdd(aDados,{"TIPOCOR"		,cMsgEmai							})



//AAdd(aDados,{"NPEDIDO"			, AllTrim((cAliEmai)->CR_NUM)	})
//AAdd(aDados,{"WFUSER"			, AllTrim((cAliEmai)->AK_NOME)	})
//AAdd(aDados,{"APROVAD"			, AllTrim((cAliEmai)->CR_APROV)	})
//AAdd(aDados,{"CRRECNO"			, AllTrim(Str((cAliEmai)->CR_RECNO))})

//Dados necessários ao workflow em si
AAdd(aDados,{"F_RETURN"			, "#"			})
//AAdd(aDados,{"TIPLIB"			,"(APROVACAO PEDIDO COMPRA)"})



FSendEml(cPathMod,cCodPrc,aDados,Nil)

Return Nil



/*-------------------------------------------------------------------------
| 
|
-------------------------------------------------------------------------*/
User Function MCWORK01P( cPedido )
Local aArea     := getArea()
Local cAliEmai	:= "QPCLIB"
Local cQuery    := ""
Local cEmail    := ""
Local cIdHtmlWf := ""
//Local nRegSM0	:= SM0->(Recno())
//Local cFilOld	:= SM0->M0_CODFIL
Local cNomFil	:= ""
Local nRecNoCR	:= 0

If Select(cAliEmai) <> 0
	(cAliEmai)->(dbCloseArea())
EndIf

cQuery += " SELECT CR.R_E_C_N_O_ AS CR_RECNO, * "
cQuery += " FROM "+RetSQLName("SCR")+" CR  "
cQuery += " INNER JOIN "+RetSQLName("SAK")+" AK ON(AK.D_E_L_E_T_ = '' AND AK.AK_FILIAL = '"+xFilial("SAK")+"' AND AK.AK_COD = CR.CR_APROV)  "
cQuery += " INNER JOIN "+RetSQLName("SC7")+" C7 ON(C7.D_E_L_E_T_ = '' AND C7.C7_FILIAL = CR.CR_FILIAL AND C7.C7_NUM = CR.CR_NUM AND C7.C7_RESIDUO <> 'S') "
cQuery += " INNER JOIN "+RetSQLName("SA2")+" A2 ON(A2.D_E_L_E_T_ = '' AND A2.A2_FILIAL = '"+xFilial("SAK")+"' AND A2.A2_COD = C7.C7_FORNECE AND A2.A2_LOJA = C7.C7_LOJA) "
cQuery += " LEFT OUTER JOIN "+RetSQLName("CTT")+" CTT ON(CTT.D_E_L_E_T_ = '' AND CTT.CTT_FILIAL = '"+xFilial("CTT")+"' AND CTT.CTT_CUSTO = C7.C7_CC) "
cQuery += " WHERE CR_FILIAL = '"+xFilial("SCR")+"' "
cQuery += " AND CR_TIPO = 'PC' "
cQuery += " AND CR_NUM = '"+cPedido+"' "
cQuery += " AND CR_STATUS = '02' "
cQuery += " AND CR.D_E_L_E_T_ = ' ' "
cQuery += " ORDER BY CR_FILIAL, CR_NUM, CR_APROV, C7_ITEM "

//Cria o arquivo de trabalho da query posicionada
dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cAliEmai,.F.,.T.)

While (cAliEmai)->(! Eof())

	nRecNoCR	:= (cAliEmai)->CR_RECNO
	aDadEmai	:= {AllTrim((cAliEmai)->CR_NUM),;
					AllTrim((cAliEmai)->AK_EMAIL),;
					AllTrim((cAliEmai)->CR_FILIAL),;
					AllTrim((cAliEmai)->CR_NUM)}

	cNomFil	:= SM0->M0_FILIAL

	//Montando apenas um html para aprovação do Pedido de Compra . Este html será enviado para todos os aprovadores.
	cIdHtmlWf := FGrArqHtml(cAliEmai,cNomFil)
	
	//Enviando o workflow com o link, ao clicar no link, o usuário será encaminhado para o html com Id = o id passado
	FEnvEmiWf(cIdHtmlWf,aDadEmai,cNomFil,cAliEmai)
   
	dbSelectArea("SCR")
	dbGoTo(nRecNoCR)
	RecLock("SCR",.F.)
	SCR->CR_DTENVEM	:= dDataBase
	SCR->(MsUnLock())

	(cAliEmai)->( dbSkip() )
EndDo

	If Select(cAliEmai) <> 0
		(cAliEmai)->(dbCloseArea())
	EndIf

	restArea(aArea)
Return Nil
