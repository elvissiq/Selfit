#Include "Protheus.ch" 
#Include "TopConn.ch" 

// ======================================================================= \\
/*/{Protheus.doc} MCWORK02
Rotina de Envio do Email de Aprovação do Solicitacao de Compras
@author  Ederson Colen
@since   20/06/2016
/*/ 
// ======================================================================= \\
User Function MCWORK02(cOrig) 
// ======================================================================= \\

Local   cAliEmai  := "QPCLIB"
Local   cQuery    := ""
Local   cEmail    := ""
Local   cIdHtmlWf := ""
Local   nRegSM0   := 0 
Local   cFilOld   := "" 
Local   cNomFil   := ""
Local   nRecNoCR  := 0
Local   cTstNrSC  := GetMV("MC_TSTNRSC" , , "")  					// --> Incluso  LAVOR 23/05/2022   (Para informar SC de TESTE) 

Private MSGP_NONE := ""												// Ajuste pra corrigir erro do padrao - Cristiam Rossi em 04/10/2018

Default cOrig     := ""  											// --> Incluso  LAVOR 23/05/2022 

cEmail   := "" 
nRegSM0  := SM0->(Recno()) 
cFilOld  := SM0->M0_CODFIL 
nRecNoCR := 0 

If Select(cAliEmai) <> 0
	(cAliEmai)->(dbCloseArea())
EndIf

cQuery     += " SELECT   SC1.R_E_C_N_O_ AS C1_RECNO , "
cQuery     += "          SC1.C1_FILIAL , SC1.C1_EMISSAO , SC1.C1_CC      , SC1.C1_NUM     , SC1.C1_QUANT   , SC1.C1_VUNIT , "
cQuery     += "         (SC1.C1_QUANT * SC1.C1_VUNIT) AS C1_TOTAL , "
cQuery     += "          SC1.C1_DESCRI , SC1.C1_DESCRIC , SC1.C1_USER    , SC1.C1_SOLICIT , SC1.C1_DTENVEM , SC1.C1_APROV , "
cQuery     += "          CTT.CTT_CUSTO , CTT.CTT_DESC01 , CTT.CTT_EMARES , CTT.CTT_USRRES " 
cQuery     += " FROM     "+RetSQLName("SC1")+" SC1 "
cQuery     += "          INNER JOIN "+RetSQLName("CTT")+" CTT  ON  (CTT.D_E_L_E_T_ = ''         AND  CTT.CTT_FILIAL =  '"+xFilial("CTT")+"' " 
cQuery     += "                                                AND  CTT.CTT_CUSTO  = SC1.C1_CC  AND  CTT.CTT_EMARES <> '') " 
cQuery     += " WHERE    SC1.D_E_L_E_T_ =  '' " 
cQuery     += "   AND    SC1.C1_FILIAL  =  '"+xFilial("SC1")+"' " 
cQuery     += "   AND    SC1.C1_APROV   =  'B' " 
cQuery     += "   AND    SC1.C1_RESIDUO <> 'S' " 
cQuery     += "   AND   (SC1.C1_DTENVEM =  '' OR (SC1.C1_DTENVEM <= '"+DtoS(dDataBase-2)+"' AND SC1.C1_APROV = 'B')) " 
If !Empty(cTstNrSC) 												// --> Incluso  LAVOR 23/05/2022   ( Todo o If ) 
	cQuery += "   AND    SC1.C1_NUM     =  '"+cTstNrSC+"' " 
EndIf 
If cOrig == "MATA110" 												// --> Incluso  LAVOR 23/05/2022   ( Todo o If ) 
	cQuery += "   AND    SC1.C1_FILIAL  =  '"+SC1->C1_FILIAL+"' " 
	cQuery += "   AND    SC1.C1_NUM     =  '"+SC1->C1_NUM   +"' " 
EndIf 
cQuery     += " ORDER BY SC1.C1_FILIAL , SC1.C1_CC , SC1.C1_NUM , SC1.C1_ITEM " 
// Cria o arquivo de trabalho da query posicionada 
dbUseArea(.T. , "TOPCONN" , TcGenQry(,,cQuery) , cAliEmai , .F. , .T.) 

(cAliEmai)->(dbGoTop()) 

While (cAliEmai)->(!Eof()) 
	cFilSCAu := (cAliEmai)->C1_FILIAL 
	cCCustAu := (cAliEmai)->C1_CC 
	cNumSCAu := (cAliEmai)->C1_NUM 
	cNomFil  := SM0->M0_FILIAL 

	aDadEmai := { AllTrim((cAliEmai)->C1_NUM    ) , ; 
				  AllTrim((cAliEmai)->CTT_EMARES) , ; 
				  AllTrim((cAliEmai)->C1_FILIAL ) , ; 
				  AllTrim((cAliEmai)->C1_NUM    ) , ; 
				  AllTrim((cAliEmai)->C1_CC     ) } 

	// Montando apenas um html para aprovação do Pedido de Compra. Este html será enviado para todos os aprovadores.
	cIdHtmlWf := FGrArqHtml(cAliEmai , cNomFil) 

	// Enviando o workflow com o link, ao clicar no link, o usuário será encaminhado para o html com Id = o Id passado 
	FEnvEmiWf(cIdHtmlWf , aDadEmai , cNomFil , cAliEmai) 
EndDo 

If Select(cAliEmai) <> 0 
	(cAliEmai)->(dbCloseArea()) 
EndIf 

Return Nil 



// ======================================================================= \\
/*/{Protheus.doc} FGrArqHtml
Monta o Html com os dados do Pedido de Compra para Liberacao
@author  Ederson Colen
@since   09/08/2016
@Return  cIdHtml        Id do processo gerado, será também o nome do html
/*/ 
// ======================================================================= \\
Static Function FGrArqHtml(cAliEmai , cNomFil) 
// ======================================================================= \\

Local cIdHtml  := ""
Local cPathMod := "\workflow\"

Local cCodPrc  := AllTrim((cAliEmai)->C1_NUM)
Local aDados   := {}   

aAdd(aDados , {"MODELO_HTML" , "WFLIBSOLC.HTML"                   })		// [01] 
aAdd(aDados , {"EMAIL"       , ""                                 })		// [02]			// Não mandar esse e-mail pra ninguém
aAdd(aDados , {"FILSOLC"     , AllTrim((cAliEmai)->C1_FILIAL)     }) 		// [03] 
aAdd(aDados , {"NUMSOLC"     , AllTrim((cAliEmai)->C1_NUM)        }) 		// [04] 
aAdd(aDados , {"WFUSER"      , ""                                 }) 		// [05] 
aAdd(aDados , {"APROVAD"     , AllTrim((cAliEmai)->CTT_USRRES)	  }) 		// [06] 
aAdd(aDados , {"C1RECNO"     , AllTrim(Str((cAliEmai)->C1_RECNO)) }) 		// [07] 
aAdd(aDados , {"CCUSTO"	     , AllTrim((cAliEmai)->C1_CC)         }) 		// [08] 
aAdd(aDados , {"EMAIRES"     , AllTrim((cAliEmai)->CTT_EMARES)    }) 		// [09] 
// Dados necessários ao workflow em si
aAdd(aDados , {"ASSUNTO"     , "Aprovacao da Solicitacao Compra"  }) 		// [10] 
aAdd(aDados , {"F_RETURN"    , "U_MCRETLSC"                       }) 		// [11] 
aAdd(aDados , {"TIPLIB"      , "(APROVACAO SOLICITACAO DE COMPRA)"}) 		// [12] 

cIdHtml := FSendEml(cPathMod , cCodPrc , aDados , "000001" , cAliEmai) 

Return cIdHtml



// ======================================================================= \\
/*/{Protheus.doc} FEnvEmiWf
Monta o Html com os dados da viagem e retorna o id do html gerado.
O html será montado separadamente, pois um único  Html será enviado
para vários aprovadores
@author  Ederson Colen
@since   29/05/2013
@param   cIdHtmlWf      Código do processo WF gerado
         cEmail         Endereço de e-mail para onde será enviaod o wf
         cMsgBlq        Mensagem do bloqueio
         cDTYNUMCTC 
@Return  Nil
/*/ 
// ======================================================================= \\
Static Function FEnvEmiWf(cIdHtmlWf , aDadEmai , cNomFil , cAliEmai) 
// ======================================================================= \\
	            
Local cPathMod := GetMV("MC_WFPMOD" , , "\WORKFLOW\") 
// --> Conferido parâmetro "MC_WFPMOD"  (SX6010) em 20/03/2021 (ambiente produção 12.1.17) e este existe, porém DELETADO e com conteudo 'WORKFLOW'

Local cUrlWf   := GetMV("MC_URLWF"  , , "http://172.16.24.26:81/wf") 				// --> Alterado PROX 20/03/2021   [ Era: GetMV("MC_URLWF" , , "http://54.207.46.24:81/wf") ] 
// --> Conferido parâmetro "MC_URLWF"   (SX6010) em 20/03/2021 (ambiente produção 12.1.17) e estava com conteúdo 'http://54.207.46.24:82/wf' 
// --> No ambiente novo (release 27) o IP será o 172.16.24.26.

Local cCodPrc  := aDadEmai[01] 

// Monta o link com o id do html gerado e dispara para os aprovadores do e-mail
// Preencher os dados do html do link
aDados := {}

aAdd(aDados , {"ASSUNTO"     , "Aprovacao Solicitacao de Compra"})
aAdd(aDados , {"MODELO_HTML" , "WFEELISC.HTML"                  })
aAdd(aDados , {"EMAIL"	     , aDadEmai[02]                     })
aAdd(aDados , {"FILSOLC"     , aDadEmai[03]                     })
aAdd(aDados , {"NUMSOLC"     , aDadEmai[04]                     })
aAdd(aDados , {"NOMEFIL"     , AllTrim(cNomFil)				    })
aAdd(aDados , {"Link"	     , cUrlWf + "/" + cIdHtmlWf + ".htm"})

FSendEml(cPathMod , cCodPrc , aDados , Nil , cAliEmai) 

Return Nil



// ======================================================================= \\
/*/{Protheus.doc} FSendEml
Função para enviar e-mails conforme os protocolos vão sendo alterados.
@author  Ederson Colen
@since   10/08/2016
@param   cPathMod       Pasta à partir da pasta raiz, onde estão os arquivos html de layout
         cCodPrc        Código do processo do workflow
         aDados         Dados a serem enviados. Preenche o workflow e envia
         cAttachFile    Caminho do arquivo, a partir da pasta raiz, para ser anexado
@Return cMailID	Id gerado no processo de envio de e-mail
/*/
// ======================================================================= \\
Static Function FSendEml(cPathMod, cCodPrc, aDados, cAttachFile, cAliEmai)
// ======================================================================= \\

Local   oProcess := Nil 
Local   oHtml    := Nil 
Local   cMailID  := ""
Local   aAreas   := {GetArea()}
Local   nPos     := 0
Local   cAssunto := ""
Local   nX       := 0
Local   cNomSol  := ""
Local   nTotSCom := 0
//Local nTotDes  := 0
//Local nTotIpi  := 0 
//Local nTotFrt  := 0  
//Local cCCusto  := ""

oHtml    := Nil 

nPos     := aScan(aDados , {|x| x[1] == "ASSUNTO" })				// Buscando o Assunto do e-mail
cAssunto := aDados[nPos][2] 										// Lendo o assunto

oProcess := TWFProcess():New(cCodPrc , cAssunto) 					// Inicialize a classe TWFProcess e assinale a variável objeto oProcess:
                                                                                                                               
nPos     := aScan(aDados , {|x| x[1] == "MODELO_HTML" })			// Buscando o Assunto do e-mail
oProcess:NewTask(cAssunto, cPathMod + aDados[nPos][2] )				// Cria o objeto referente a tareja, com o modelo do html a ser preenchido 

oProcess:cSubject := cAssunto										// Repasse o texto do assunto criado para a propriedade especifica do processo.

nPos     := aScan(aDados , {|x| x[1] == "EMAIL" }) 					// Informe o endereço eletrônico do destinatário.
oProcess:cTo := aDados[nPos][2] 

// Informe o nome da função de retorno a ser executada quando a mensagem de respostas retornarem ao Workflow:
nPos     := aScan(aDados , {|x| x[1] == "F_RETURN" }) 				// Informe a função que o wf irá excutar ao retornar
If(nPos > 0)
	oProcess:bReturn := AllTrim(aDados[nPos][2]) + "(1)"
EndIf

If (!Empty(cAttachFile))
	oProcess:AttachFile(cAttachFile)
EndIf

If Empty(cAttachFile)
	// Preenchendo as variáveis do HTML 
	// Fazer, posteriormente uma alteração neste ponto para preencher tabelas 
	For nX := 1 To Len(aDados)
		If !(aDados[nX][1] $ "ASSUNTO/MODELO_HTML/EMAIL/F_RETURN") 	// Não usar as Variáveis especiais do WF
			oProcess:oHTML:ValByName(aDados[nX][01],aDados[nX][02])
		EndIf
	Next nX 
Else
	// Defino a ordem
	PswOrder(1) 													// Ordem de nome  

	// Efetuo a pesquisa, definindo se pesquiso usuário ou grupo
	If PswSeek((cAliEmai)->C1_USER,.T.)
	   // Obtenho o resultado conforme vetor
		cNomSol	:= Upper(PswRet()[1][4])
	Else
		cNomSol	:= AllTrim((cAliEmai)->C1_SOLICIT)
	EndIf

	oProcess:oHTML:ValByName("FILSOLC"	  , aDados[03][02]     )
	oProcess:oHTML:ValByName("NUMSOLC"	  , aDados[04][02]     )
	oProcess:oHTML:ValByName("WFUSER"	  , aDados[05][02]     )
	oProcess:oHTML:ValByName("APROVAD"	  , aDados[06][02]     )
	oProcess:oHTML:ValByName("WFID"		  , oProcess:fProcessId)
	oProcess:oHTML:ValByName("WFEMPRESA"  , SM0->M0_CODIGO     )
	oProcess:oHTML:ValByName("WFFILIAL"	  , aDados[03][02]     )
	oProcess:oHTML:ValByName("WFMAILID"   , ""                 )
	oProcess:oHTML:ValByName("C1RECNO"	  , aDados[07][02]     )
	oProcess:oHTML:ValByName("CCUSTO"	  , aDados[08][02]     )
	oProcess:oHTML:ValByName("EMAIRES"	  , aDados[09][02]     )

	oProcess:oHTML:ValByName("C1_CC"      ,	(cAliEmai)->CTT_CUSTO+" - "+(cAliEmai)->CTT_DESC01) 
	oProcess:oHTML:ValByName("C1_NUM"     ,	(cAliEmai)->C1_NUM ) 
	oProcess:oHTML:ValByName("C1_EMISSAO" ,	DtoC(StoD((cAliEmai)->C1_EMISSAO))) 
	oProcess:oHTML:ValByName("XX_NOME"    ,	AllTrim(cNomSol)   ) 

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
EndIf

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
User Function MCRETLSC(nFlag , oProcess) 
// ======================================================================= \\

Local lPrcemai	:= .F.
Local cMsgEmai	:= ""

Local cAprovS	:= oProcess:oHtml:RetByName("APROVAD")
Local cEmailAp	:= oProcess:oHtml:RetByName("EMAIRES")
Local cCCusto	:= oProcess:oHtml:RetByName("CCUSTO" )
Local cSolComp	:= oProcess:oHtml:RetByName("NUMSOLC")
Local cFILSOLC	:= oProcess:oHtml:RetByName("FILSOLC")

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

	While SC1->(!Eof())  .And.  SC1->C1_FILIAL == cFilSolc  .And.  SC1->C1_NUM == cSolComp 

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
	FAprWFOK(cFILSOLC , cSolComp , cMsgEmai , cEmailAp) 
EndIf 

ConOut("##_MCWORK02.prw - MCRETLSC() - Retorno Workflow - FINAL  ----------") 

Return Nil



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
Static Function FAprWFOK(cFILSOLC , cSolComp , cMsgEmai , cEmailAp) 
// ======================================================================= \\
                         
Local cPathMod := "\workflow\" 
Local cCodPrc  := AllTrim(cSolComp) 

aDados := {}

aAdd(aDados , {"ASSUNTO"     , "Solicitaco Compra "+cSolComp+" - "+cMsgEmai}) 
aAdd(aDados , {"MODELO_HTML" , "WFERLISC.HTML"                             }) 
aAdd(aDados , {"EMAIL"       , cEmailAp                                    }) 
aAdd(aDados , {"FILSOLC"     , cFILSOLC+" - "+SM0->M0_FILIAL               }) 
aAdd(aDados , {"NUMSOLC"     , cSolComp                                    }) 
aAdd(aDados , {"TIPOCOR"     , cMsgEmai                                    }) 

FSendEml(cPathMod , cCodPrc , aDados , Nil) 

Return Nil
