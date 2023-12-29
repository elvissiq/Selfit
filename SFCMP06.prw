#Include "totvs.ch"
#Include "tbiconn.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ SFCMP06   º Autor ³ Cristiam Rossi     º Data ³ 24/07/2018 º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Rotina envio de e-mail p/ fornecedor com pedido de compras º±±
±±º          ³ em anexo (.PDF)                                            º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ SELFIT                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function SFCMP06( _Filial , _Pedido , lApv , lMedicao ) 

Local   aArea      := GetArea()
Local   aAreaSC7   := SC7->( GetArea() )
Local   aAreaSA2   := SA2->( GetArea() )
Local   cTo        := ""
Local   cSubject
Local   cBody      := ""
Local   aAttach    := {}
Local   _FilOld    := ""
Local   _lPesqPC   := .F.
Local   cNomForn   := ""
Local   cNomArq
Local   lRet       := .F.
Local   _DonoPC    := ""
Local   cMailVnd   := ""
Local   cMailSol   := ""                     
Local   cMailCmp   := ""
Local   cMailAud   := ""
Local   cMailApr   := ""
Local   lMedMatriz 
Local   lEnvTeste  := SuperGetMV("MC_EMPCTST" , .F. , .F.) 
// --> .T. ==> Define se e-mail será enviado como TESTE, ou seja, nao enviara para o Forncedor/Aprovador/Compradores reais. 
// --> .F. ==> Se o parâmetro não existir, ou estiver .F. enviará para normal para o Forncedor/Aprovador/Compradores reais. 

Default _Filial    := SC7->C7_FILIAL
Default _Pedido    := SC7->C7_NUM
Default lApv       := .F.
Default lMedicao   := .F.

Private cTitulo    := "Envio de Ped. Compras p/ Fornecedor"

aAttach    := {}
_FilOld    := cFilAnt
cMailCmp   := "" 
lMedMatriz := FWIsInCallStack("u_MEDMATRIZ")

//ConOut("-------------------")
//ConOut("-------------------")
//ConOut("-------------------")
//ConOut("-------Rotina SFCMP06 Init------")
//ConOut(ProcName(1)) //Verificar rotina
//ConOut("-------------------")
//ConOut("-------------------")
//ConOut("-------------------")
//ConOut("-------Rotina SFCMP06 Fim------")

ConOut("##_SFCMP06.prw - SFCMP06()  - INICIO ===================================== ##")

// Necessario verificar o motivo do ponto de entrada MT097APR tambem esta chamado essa rotina de envio de email - Talvane - 17/12/2018
If (AllTrim(ProcName(1)) != "U_MT097GRV") 
	// Pedidos vindos da medicao, não passa pela aprovacao de pc. Mas deve enviar email. - Kelveng - 09/01/2020
	If Empty(SC7->C7_MEDICAO) 
		ConOut("##_SFCMP06.prw - SFCMP06()  - FINAL  == (antecipado) ===================== ##")
		lRet := .T.
		Return lRet
	ElseIf (!lMedicao)  				// Necessário esse teste,por conta do campo medicao
		ConOut("##_SFCMP06.prw - SFCMP06()  - FINAL  == (antecipado) ===================== ##")
		lRet := .T.
		Return lRet
	EndIf	
EndIf

cNomArq := "PC_"+AllTrim(_Filial)+"_"+AllTrim(_Pedido)+".pdf"
ConOut("##_SFCMP06.prw - Envio pedido compras para fornecedor  --  cNomArq: ["+cNomArq+"] ") 
//ConOut("SFCMP06 - envio de e-mail fornecedor - arquivo:"+cNomArq)

If _Filial != xFilial("SC7")
	cFilAnt  := _Filial 
	_lPesqPC := .T. 
EndIf

SC7->( dbSetOrder(1) )

If _Pedido != SC7->C7_NUM  .Or.  _lPesqPC 
	If ! SC7->( dbSeek( _Filial + _Pedido , .T. ) )
		ConOut("##_SFCMP06.prw - Envio pedido compras para fornecedor  --  PEDIDO NAO ENCONTRADO !  --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 
		MsgStop("Envio pedido compras para fornecedor" + Chr(13)+Chr(10) + ; 
		        "PEDIDO NAO ENCONTRADO !"              + Chr(13)+Chr(10) + ; 
		        ". . Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]" , "Especifico SELFIT - SFCMP06.prw") 
		SC7->( RestArea(aAreaSC7) ) 
		RestArea(aArea) 
		Return .F. 
	EndIf 
EndIf 

If ! lApv  .And.  SC7->C7_CONAPRO != "L" 
	ConOut("##_SFCMP06.prw - Envio pedido compras para fornecedor  --  PEDIDO NÃO APROVADO !    --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 
	MsgStop("Envio pedido compras para fornecedor" + Chr(13)+Chr(10) + ; 
	        "PEDIDO NÃO APROVADO !"                + Chr(13)+Chr(10) + ; 
	        ". . Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]" , "Especifico SELFIT - SFCMP06.prw") 
	SC7->( RestArea(aAreaSC7) )
	RestArea(aArea)
	Return .F.
EndIf

If SC7->C7_XMEM == "S"
	ConOut("##_SFCMP06.prw - Envio pedido compras para fornecedor  --  PEDIDO EM RASCUNHO       --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 
	MsgStop("Envio pedido compras para fornecedor" + Chr(13)+Chr(10) + ; 
	        "PEDIDO EM RASCUNHO "                  + Chr(13)+Chr(10) + ; 
            ". . Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]" , "Especifico SELFIT - SFCMP06.prw") 
	SC7->( RestArea(aAreaSC7) )
	RestArea(aArea)
	Return .F.
EndIf

If IsInCallStack("MATA121") 
	If ! MsgYesNo( "Deseja enviar e-mail para o fornecedor com o pedido anexado?" , cTitulo ) 
		SC7->( RestArea(aAreaSC7) ) 
		RestArea(aArea) 
		Return .F. 
	EndIf 
EndIf 

If ! Empty(SC7->C7_USER)  .And.  Empty(SC7->C7_MEDICAO) 
	_DonoPC  := AllTrim(UsrFullName(SC7->C7_USER)) + "<br />
	cMailVnd := AllTrim(UsrRetMail(SC7->C7_USER)) 
	_DonoPC  += cMailVnd + "<br /><br />" 
	ConOut("##_SFCMP06.prw - (email - a) _DonoPC: ["+_DonoPC+"]  SC7->C7_USER: ["+SC7->C7_USER+"]    SC7->C7_NUM: ["+SC7->C7_NUM+"]  --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 

ElseIf !Empty(SC7->C7_MEDICAO) 
	cSQL := " SELECT CN9_USRAUD , CN9_USRCMP AS USRCMP , ( SELECT TOP 1 CR_USERLIB "
	cSQL += "                                              FROM  "+RetSqlName("SCR")+" "
	cSQL += "                                              WHERE  CR_TIPO    = 'MD' " 
	cSQL += "                                                AND  D_E_L_E_T_ = '' " 
	cSQL += "                                                AND  CR_NUM     = '"+SC7->C7_MEDICAO+"' "
	cSQL += "                                                AND  CR_FILIAL  = '"+Iif(Empty(SC7->C7_FILCRT) , SC7->C7_FILIAL , SC7->C7_FILCRT)+"' "
	cSQL += "                                                AND  CR_STATUS  = '03' ) AS USRAPR "
	cSQL += " FROM   "+RetSqlName("CN9")+" " 
	cSQL += " WHERE  D_E_L_E_T_ = '' "   
	cSQL += "   AND  CN9_NUMERO = '"+SC7->C7_CONTRA+"' "
	cSQL += "   AND  CN9_FILIAL = '"+Iif(Empty(SC7->C7_FILCRT) , SC7->C7_FILIAL , SC7->C7_FILCRT)+"' "
	cSQL += "   AND  CN9_REVISA = '"+SC7->C7_CONTREV+"' " //Trecho adicionado por conta do ticket: 30469 - Vinicius N. de Oliveira - 23/03/2023
	MemoWrite("consultaemail.sql" , cSQL) 

	cAlias := MPSysOpenQuery(cSQL) 
	If (cAlias)->(!Eof()) 
		cUserAux     := "" 
		If !Empty((cAlias)->USRCMP) 
			cUserAux := (cAlias)->USRCMP 
		EndIf 
		If !Empty(cUserAux) 
			_DonoPC  := AllTrim(UsrFullName(cUserAux)) + "<br /> 
			cMailVnd := AllTrim(UsrRetMail(cUserAux)) 
			_DonoPC  += cMailVnd + "<br /><br />" 
		EndIf 
		cMailAud     := AllTrim(UsrRetMail((cAlias)->CN9_USRAUD)) 
        cMailApr     := AllTrim(UsrRetMail((cAlias)->USRAPR)) 
		ConOut("##_SFCMP06.prw - (email - b) (cAlias)->USRCMP.....: ["+(cAlias)->USRCMP    +"]   cUserAux: ["+cUserAux+"]   SC7->C7_NUM: ["+SC7->C7_NUM+"]  --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 
		ConOut("##_SFCMP06.prw - (email - b) (cAlias)->CN9_USRAUD.: ["+(cAlias)->CN9_USRAUD+"]   cMailAud: ["+cMailAud+"]   SC7->C7_NUM: ["+SC7->C7_NUM+"]  --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 
		ConOut("##_SFCMP06.prw - (email - b) (cAlias)->USRAPR(SCR): ["+(cAlias)->USRAPR    +"]   cMailApr: ["+cMailApr+"]   SC7->C7_NUM: ["+SC7->C7_NUM+"]  --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 	
	EndIf 
	(cAlias)->(dbCloseArea()) 
EndIf 

If !Empty( SC7->C7_NUMSC )
	SC1->( dbSetOrder(1) ) 
	If SC1->( dbSeek( SC7->C7_FILIAL + SC7->C7_NUMSC ) ) 
		cMailSol := AllTrim( UsrRetMail(SC1->C1_USER) ) 
		ConOut("##_SFCMP06.prw - (email - c) SC1->C1_USER: ["+SC1->C1_USER+"]   cMailSol: ["+cMailSol+"]   SC7->C7_NUM: ["+SC7->C7_NUM+"]  SC1->C1_NUM: ["+SC1->C1_NUM+"]  --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 
	EndIf 
EndIf 

SA2->( dbSetOrder(1) )
If ! SA2->( dbSeek( xFilial("SA2") + SC7->(C7_FORNECE+C7_LOJA) ) )
	ConOut("##_SFCMP06.prw - Envio pedido compras para fornecedor  --  Fornecedor não encontrado !!  --  Código: ["+SC7->C7_FORNECE+"] | Loja: ["+SC7->C7_LOJA+"]") 
	MsgStop("Fornecedor não encontrado (Código: "+SC7->C7_FORNECE+", Loja: "+SC7->C7_LOJA+")" , cTitulo)
	SC7->( RestArea(aAreaSC7) )
	SA2->( RestArea(aAreaSA2) )
	RestArea(aArea)
	Return .F.
EndIf

If Empty( SA2->A2_EMAIL )
	ConOut("##_SFCMP06.prw - Envio pedido compras para fornecedor  --  Fornecedor não possui e-mail  --  Código: ["+SC7->C7_FORNECE+"] | Loja: ["+SC7->C7_LOJA+"]") 
	MsgStop( "Fornecedor não possui e-mail cadastrado (Código: "+SC7->C7_FORNECE+", Loja: "+SC7->C7_LOJA+")" , cTitulo)
	SC7->( RestArea(aAreaSC7) )
	SA2->( RestArea(aAreaSA2) )
	RestArea(aArea)
	Return .F.
EndIf

cTo      := AllTrim(SA2->A2_EMAIL)
cNomForn := AllTrim(SA2->A2_NOME )

ConOut("##_SFCMP06.prw - SFCMP06()  - Antes  da chamada: U_MCCOMR01('PDF' , cNomArq)  --  cNomArq: ["+cNomArq+"] ") 

U_MCCOMR01("PDF" , cNomArq)				// Chama impressão do PC em PDF 

ConOut("##_SFCMP06.prw - SFCMP06()  - Depois da chamada: U_MCCOMR01('PDF' , cNomArq)  --  cNomArq: ["+cNomArq+"] ") 

If ! File( cNomArq )					// Verifica se o arquivo .PDF existe 
	ConOut("##_SFCMP06.prw - SFCMP06()  - #ERRO# Ocorreu algum problema na impressão PDF do Pedido de Compras: ["+_Pedido+"] - cNomArq: ["+cNomArq+"] ") 
	MsgStop( "Ocorreu algum problema na impressão PDF do Pedido de Compras: "+_Pedido , cTitulo)
	SC7->( RestArea(aAreaSC7) )
	SA2->( RestArea(aAreaSA2) )
	RestArea(aArea)
	Return .F.
EndIf

cSubject := "Pedido "+_Pedido+" Aprovado"

cBody    := 'Prezado(a) Proponente,<br /><br />'
cBody    += 'Segue em anexo o pedido de compra da Selfit;<br />'
cBody    += _Pedido+'<br /><br />'
cBody    += '<u>INCLUIR O NÚMERO DO PEDIDO DE COMPRA NA NOTA FISCAL</u><br /><br />'
cBody    += 'O fornecedor deverá faturar exatamente o que foi solicitado, caso contrário poderá ocorrer devolução.<br /><br />'
cBody    += '<b>Endereço de Faturamento:</b><br />'
cBody    += 'O endereço de entrega de material/ prestação de serviços está inserido no pedido de compra em anexo.<br /><br />'
cBody    += '<b>Faturamento:</b><br />'
cBody    += 'A nota fiscal deverá ser espelho da ordem de compra em anexo.<br />'
cBody    += 'Todas as notas fiscais deverão conter os números de ordem de compra em questão.<br />'
cBody    += 'Todas as notas fiscais eletrônicas e XML deverão ser envidas para o e-mail: <a href="mailto:fiscal.nfe@selfitacademias.com.br">fiscal.nfe@selfitacademias.com.br</a><br />'
cBody    += '<b>Todas as notas fiscais de serviço só poderão ser faturadas até o dia 20 de cada mês.<br />'
cBody    += 'No corpo das notas fiscais deverão ter descrito o vencimento negociado conforme o pedido de compra.<br />'
//cBody    += 'Nossos pagamentos ocorrem as terças e quintas. Caso o vencimento negociado não esteja para um desses dois dias, pedimos para adequar o vencimento para a terça ou quinta subsequente.<br /><br />'
//cBody  += 'Contas a Pagar:</b><br />'
//cBody  += 'Em caso de dúvidas no pagamento favor entrar em contato no número (81) 3036-5763.<br /><br />'
cBody    += '</b>Telefone do Contas a Pagar: (81) 3036-5763.<br /><br />'
cBody    += '<b>Contato Comercial:</b><br />'
cBody    += 'Em caso de dúvidas e/ou observações, favor entrar em contato através do e-mail<br /><br />'
// Dados de quem gerou o pedido
cBody    += _DonoPC
//
cBody    += '<i>Atenciosamente,</i><br /><br />'
cBody    += 'Self It Academias.<br /><br /><br />'
cBody    += '<center>Documento Confidencial</center>'

cEnvMail := cMailVnd + ";" + cMailSol 
If !Empty(cMailAud) 
	cEnvMail += ";" + cMailAud 
EndIf 

If !Empty(cMailApr) 
	cEnvMail += ";" + cMailApr 
EndIf 
ConOut("##_SFCMP06.prw - (email - d) cEnvMail: ["+cEnvMail+"]  cMailVnd: ["+cMailVnd+"]  cMailSol: ["+cMailSol+"]  cMailAud: ["+cMailAud+"]  cMailApr: ["+cMailApr+"]  --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 

// --> Utilizado para envio de e-mail para destinatários não oficiais... ou seja... envia para destinatários TESTES   (*INICIO*) 
If lEnvTeste 
	cTo      := "teste01.selfit@outlook.com" 			// --> www.hotmail.com -- senha: 123@selfit
	cEnvMail := "teste02.selfit@outlook.com" 			// --> www.hotmail.com -- senha: 123@selfit
EndIf 
// --> Utilizado para envio de e-mail para destinatários não oficiais... ou seja... envia para destinatários TESTES   (*FINAL* ) 

If U_xMail( cTo , cSubject , cBody , {GetSrvProfString("StartPath","") + cNomArq} , cEnvMail )
	lRet := .T. 
	ConOut("##_SFCMP06.prw - SFCMP06()  - Email enviado com SUCESSO -----------------") 
	ConOut("##      cTo.....: ["+cTo     +"]") 
	ConOut("##      cSubject: ["+cSubject+"]") 
	ConOut("##      cBody...: ["+cBody   +"]") 
	ConOut("##      Anexo...: ["+GetSrvProfString("StartPath","")+cNomArq+"]") 
	ConOut("##      cEnvMail: ["+cEnvMail+"]") 
 //	ConOut("e-mail enviado") 
Else 
	ConOut("##_SFCMP06.prw - SFCMP06()  - FALHA no envio do Email -------------------") 
 //	ConOut("falha de envio e-mail") 
EndIf 

SC7->( RestArea(aAreaSC7) ) 
SA2->( RestArea(aAreaSA2) ) 
RestArea(aArea) 

fErase( cNomArq ) 

ConOut("##_SFCMP06.prw - SFCMP06()  - FINAL  ===================================== ##")
//ConOut("encerrando SFCMP06 e excluindo anexo") 

Return lRet




/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³ SFCMP06A ºAutor  ³ Marcos B. Abrahão  º Data ³  18/09/18   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDescricao ³ Rotina envio de e-mail p/ fornecedor com pedidos de comprasº±±
±±º          ³ anexos (.PDF)  --  EM LOTE, via P.E. MTA094RO.prw          º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ Selfit                                                     º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function SFCMP06A(aRecno) 

Local   aArea     := GetArea()
Local   aAreaSC7  := SC7->( GetArea() )
Local   aAreaSA2  := SA2->( GetArea() )
Local   cTo       := ""
Local   cSubject
Local   cBody     := ""
Local   aAttach   := {}
Local   _FilOld   := "" 
Local   _lPesqPC  := .F.
Local   cNomForn  := ""
Local   cNomArq 
Local   aNomArq   := {}
Local   lRet      := .F.
Local   _DonoPC   := ""
Local   cMailVnd  := ""
Local   nPos      := 0
Local   _Filial   := "" 				// SC7->C7_FILIAL
Local   _Pedido   := "" 				// SC7->C7_NUM
Local   xPedido   := "" 				// Pedidos enviados por e-mail
Local   xMailVnd  := ""
Local   aAreaSC7M := {}
Local   lDebug    := .F.
Local   lEnvTeste := SuperGetMV("MC_EMPCTST" , .F. , .F.) 
// --> .T. ==> Define se e-mail será enviado como TESTE, ou seja, NÃO enviara para o Forncedor/Aprovador/Compradores reais. 
// --> .F. ==> Se o parâmetro não existir, ou estiver .F. enviará para normal para o Forncedor/Aprovador/Compradores reais. 

Private cTitulo   := ""

aAttach  := {}
_FilOld  := cFilAnt 
_lPesqPC := .F.
cTitulo  := "Envio de Peds. de Compras p/ Fornecedor"

ConOut("##_SFCMP06.prw - SFCMP06A() - INICIO ===================================== ##") 

For nPos := 1 To Len(aRecno)
	SC7->(dbGoTo(aRecno[nPos])) 		// Posiciona no SC7
	
	_cMsg   += "Pedido: "+SC7->C7_NUM + " - "
	
	_Filial := SC7->C7_FILIAL 
	_Pedido := SC7->C7_NUM 
	
	cNomArq := "PC_"+AllTrim(_Filial)+"_"+AllTrim(_Pedido)+".pdf"
	
	If SC7->C7_CONAPRO != "L"
	 //	MsgStop( "Pedido não aprovado (Filial: "+_Filial+", Pedido: "+_Pedido+")" , cTitulo) 
		_cMsg += "Pedido não aprovado" + CRLF 
		Loop
	EndIf
	
	If SC7->C7_XMEM == "S"
	 //	MsgStop( "Pedido em rascunho (Filial: "+_Filial+", Pedido: "+_Pedido+")" , cTitulo)
	EndIf
	
	If !Empty( SC7->C7_USER )
	 //	cAprovador := GetAllName(SCR->CR_USER) 							// SCR->CR_USER
		_DonoPC    := AllTrim(GetAllName(SC7->C7_USER)) + "<br />
		cMailVnd   := AllTrim(UsrRetMail(SC7->C7_USER)) 
		_DonoPC    += cMailVnd + "<br /><br />" 
		If !cMailVnd $ xMailVnd 
			If !Empty(xMailVnd) 
				xMailVnd += ";" 
			EndIf 
			xMailVnd += cMailVnd 
		EndIf 
		ConOut("##_SFCMP06.prw - SFCMP06A() - (email - e) cMailVnd: ["+cMailVnd+"]  xMailVnd: ["+xMailVnd+"]  SC7->C7_NUM: ["+SC7->C7_NUM+"]  SC7->C7_USER: ["+SC7->C7_USER+"] --  Filial: ["+_Filial+"] / Pedido: ["+_Pedido+"]") 
	EndIf 
	
	SA2->( dbSetOrder(1) )
	If ! SA2->( dbSeek( xFilial("SA2") + SC7->(C7_FORNECE+C7_LOJA) ) )
	 //	MsgStop( "Fornecedor não encontrado (Código: "+SC7->C7_FORNECE+", Loja: "+SC7->C7_LOJA+")" , cTitulo)
	 //	SC7->( RestArea(aAreaSC7) )
	 //	SA2->( RestArea(aAreaSA2) )
	 //	RestArea(aArea)
	 //	Return .F.
		_cMsg += "Fornecedor não encontrado" + CRLF
		Loop
	EndIf
	
	If Empty( SA2->A2_EMAIL )
	 //	MsgStop( "Fornecedor não possui e-mail cadastrado (Código: "+SC7->C7_FORNECE+", Loja: "+SC7->C7_LOJA+")" , cTitulo) 
	 //	SC7->( RestArea(aAreaSC7) )
	 //	SA2->( RestArea(aAreaSA2) )
	 //	RestArea(aArea)
	 //	Return .F.
		_cMsg += "Fornecedor sem e-mail" + CRLF
		Loop
	EndIf
	
	cTo      := AllTrim( SA2->A2_EMAIL ) 
	cNomForn := AllTrim( SA2->A2_NOME  ) 
	
	If lDebug 
		MsgAlert("[debug] C7_NUM: ["+SC7->C7_NUM+"]  |  "+Chr(13)+Chr(10)+"cNomArq: ["+cNomArq+"] - GeraPDF" , cTitulo) 
	EndIf 
	
	aAreaSC7M := SC7->(GetArea()) 

	ConOut("##_SFCMP06.prw - SFCMP06A() - Antes  da chamada: U_MCCOMR01('PDF' , cNomArq)  --  cNomArq: ["+cNomArq+"] ") 

	U_MCCOMR01("PDF" , cNomArq)			// Chama impressão do PC em PDF 

	ConOut("##_SFCMP06.prw - SFCMP06A() - Depois da chamada: U_MCCOMR01('PDF' , cNomArq)  --  cNomArq: ["+cNomArq+"] ") 

	SC7->(RestArea(aAreaSC7M))
	
	If ! File( cNomArq )				// Verifica se o arquivo .PDF existe
	 //	MsgStop( "Ocorreu algum problema na impressão PDF do Pedido de Compras: "+_Pedido , cTitulo)
	 //	SC7->( RestArea(aAreaSC7) )
	 //	SA2->( RestArea(aAreaSA2) )
	 //	RestArea(aArea) 
	 //	Return .F. 
		ConOut("##_SFCMP06.prw - SFCMP06A() - #ERRO# Ocorreu algum problema na impressão PDF do Pedido de Compras: ["+_Pedido+"] - cNomArq: ["+cNomArq+"] ") 
		_cMsg += "Ocorreu problema na geracao do anexo em PDF" + CRLF
		Loop 
	EndIf 

	aAdd(aNomArq , GetSrvProfString("StartPath","") + cNomArq) 
	
	If !Empty(xPedido) 
		xPedido += "/"
	EndIf
	xPedido += SC7->C7_NUM 
Next nPos 

//If lDebug
//	MsgAlert("xPedido: ["+xPedido+"]"+Chr(13)+Chr(10)+"xMailVnd: ["+xMailVnd+"]")
//EndIf

cMailVnd := xMailVnd 
_DonoPC  := "<br />" + cMailVnd + "<br /><br />" 

If Len( aNomArq ) == 0
	SC7->( RestArea(aAreaSC7) )
	SA2->( RestArea(aAreaSA2) )
	RestArea(aArea) 
	Return .F.
EndIf

If Len(aRecno)==1
	cSubject := "Pedido "+xPedido+" Aprovado"
	cBody    := 'Prezado(a) Proponente,<br /><br />'
	cBody    += 'Segue em anexo o pedido de compra da Selfit;<br />'
	cBody    += xPedido+'<br /><br />'
	cBody    += '<u>INCLUIR O NÚMERO DO PEDIDO DE COMPRA NA NOTA FISCAL</u><br /><br />'
Else
	cSubject := "Pedido(s) "+xPedido+" Aprovado(s)"
	cBody    := 'Prezado(a) Proponente,<br /><br />'
	cBody    += 'Segue(m) anexo(s) pedido(s) de compra da Selfit;<br />'
	cBody    += xPedido+'<br /><br />'
	cBody    += '<u>INCLUIR OS NÚMEROS DOS PEDIDOS DE COMPRA NA NOTA FISCAL</u><br /><br />'
EndIf

cBody    += 'O fornecedor deverá faturar exatamente o que foi solicitado, caso contrário poderá ocorrer devolução.<br /><br />'
cBody    += '<b>Endereço de Faturamento:</b><br />'
cBody    += 'O endereço de entrega de material/ prestação de serviços está inserido no pedido de compra em anexo.<br /><br />'
cBody    += '<b>Faturamento:</b><br />'
cBody    += 'A nota fiscal deverá ser espelho da ordem de compra em anexo.<br />'
cBody    += 'Todas as notas fiscais deverão conter os números de ordem de compra em questão.<br />'
cBody    += 'Todas as notas fiscais eletrônicas e XML deverão ser envidas para o e-mail: <a href="mailto:fiscal.nfe@selfitacademias.com.br">fiscal.nfe@selfitacademias.com.br</a><br />'
cBody    += '<b>Todas as notas fiscais de serviço só poderão ser faturadas até o dia 20 de cada mês.<br />'
cBody    += 'No corpo das notas fiscais deverão ter descrito o vencimento negociado conforme o pedido de compra.<br />'
//cBody    += 'Nossos pagamentos ocorrem as terças e quintas. Caso o vencimento negociado não esteja para um desses dois dias, pedimos para adequar o vencimento para a terça ou quinta subsequente.<br /><br />'
//cBody  += 'Contas a Pagar:</b><br />'
//cBody  += 'Em caso de dúvidas no pagamento favor entrar em contato no número (81) 3036-5763.<br /><br />'
cBody    += '</b>Telefone do Contas a Pagar: (81) 3036-5763.<br /><br />'
cBody    += '<b>Contato Comercial:</b><br />'
cBody    += 'Em caso de dúvidas e/ou observações, favor entrar em contato através do e-mail<br /><br />'

// Dados de quem gerou o pedido
cBody    += _DonoPC

cBody    += '<i>Atenciosamente,</i><br /><br />'
cBody    += 'Self It Academias.<br /><br /><br />'
cBody    += '<center>Documento Confidencial</center>'

If lDebug 
 //	cTo  += ";jcsjoaocarlossilva@gmail.com"
 //	MsgAlert("cTo: ["+cTo+"]xMail")
	cTo := "aprendiz_cris@yahoo.com.br"
EndIf

If lEnvTeste 
	cTo      := "teste01.selfit@outlook.com" 			// --> www.hotmail.com -- senha: 123@selfit
	cMailVnd := "teste02.selfit@outlook.com" 			// --> www.hotmail.com -- senha: 123@selfit
EndIf 

If ! Empty(cTo) 
	If U_xMail(cTo , cSubject , cBody , aNomArq , cMailVnd , .F. )  // Ultimo parametro: Mostra a mensagem de E-mail enviado com êxito
		lRet  := .T.
		_cMsg += "E-mail enviado com sucesso" + CRLF 
		ConOut("##_SFCMP06.prw - SFCMP06A() - Email enviado com SUCESSO -- [LOTE] -------") 
		ConOut("##      cTo.....: ["+cTo     +"]") 
		ConOut("##      cSubject: ["+cSubject+"]") 
		ConOut("##      cMailVnd: ["+cMailVnd+"]") 
		ConOut("##      aNomArq: ") 
		VarInfo("aNomArq" , aNomArq) 
	Else
		lRet  := .F.
		_cMsg += "Falha no envio do e-mail"   + CRLF 
		ConOut("##_SFCMP06.prw - SFCMP06A()  - FALHA no envio do Email  -- [LOTE] -------") 
		ConOut("##      cSubject: ["+cSubject+"]") 
		ConOut("##      aNomArq: ") 
		VarInfo("aNomArq" , aNomArq) 
	EndIf
EndIf

SC7->( RestArea(aAreaSC7) )
SA2->( RestArea(aAreaSA2) )
RestArea(aArea)

For nPos := 1 To Len(aNomArq) 
	fErase( aNomArq[nPos] ) 
Next nPos 

ConOut("##_SFCMP06.prw - SFCMP06A() - FINAL  ===================================== ##") 

Return lRet



// TODO Migração de dicionario Não permite mais o loop AllTrim(UsrFullName(SCR->CR_USER)), tranpondo para função statica
// ======================================================================= \\
Static Function GetAllName(_CRUSER) 
// ======================================================================= \\

Local _cNameFull := "" 

_cNameFull := AllTrim(UsrFullName(_CRUSER))

Return _cNameFull
