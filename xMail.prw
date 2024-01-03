#Include "totvs.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÝÝÝÝÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝÝËÝÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝËÝÝÝÝÝÝÑÝÝÝÝÝÝÝÝÝÝÝÝ»±±
±±ºPrograma  ³ XMAIL     º Autor ³ Cristiam Rossi     º Data ³ 24/07/2018 º±±
±±ÌÝÝÝÝÝÝÝÝÝÝØÝÝÝÝÝÝÝÝÝÝÝÊÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÊÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¹±±
±±ºDescricao ³ Rotina genérica - envio de e-mail                          º±±
±±º          ³ Utilizada nos seguinte Fontes:           (Ref. 27/04/2021) º±±
±±º          ³   - PRECAD.prw                                             º±±
±±º          ³   - WFFISCTB.prw                                           º±±
±±º          ³   - SFCMP06.prw                                            º±±
±±ÌÝÝÝÝÝÝÝÝÝÝØÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¹±±
±±ºUso       ³ SELFIT                                                     º±±
±±ÈÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝÝ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function xMail( cTO , cSubject , cBody , aAttach , cCC , lMensagem ) 

Local   oSrv
Local   oMsg
Local   nI
//Local   cSTMP      := "smtp.office365.com"
Local   cConta     := GetMV("MV_RELACNT")	// "protheus@selfitacademias.com.br"
Local   cPass      := GetMV("MV_RELAPSW")	// "!Selfit@admin"
Local   nSmtpPORT  := 587
Local   cSTMP      := GetMv("MV_RELSERV")
Local   lAuth      := GetMv("MV_RELAUTH")

Default cTO        := ""
Default cSubject   := ""
Default cBody      := ""
Default aAttach    := {}
Default cCC        := ""
Default lMensagem  := .F.  					// Mostra a mensagem de E-mail enviado com êxito

Private __ISTELNET := .F.

oSrv := tMailManager():new()

oSrv:setUseSSL( .F. )
oSrv:setUseTLS( .T. )

cSTMP := Strtran(cSTMP,":"+Alltrim(cValtoChar(nSmtpPORT)),"")

oSrv:init( "" , cSTMP , cConta , cPass , 0 , nSmtpPORT )

nRet := oSrv:SetSMTPtimeout( 120 )
If nRet != 0
	MsgAlert("Falha ajuste timeout !" , "Especifico SELFIT - XMAIL.prw")
	ConOut( "##_XMAIL.prw - Falha ajuste timeout" ) 
EndIf

nRet := oSrv:SMTPconnect()
If nRet != 0
	MsgAlert("Falha conexao smtp: "+oSrv:getErrorString(nRet) , "Especifico SELFIT - XMAIL.prw") 
	ConOut( "##_XMAIL.prw - Falha conexao smtp: "+oSrv:getErrorString(nRet) )
	Return .F.
EndIf


nRet := oSrv:SMTPauth( cConta, cPass )
If nRet != 0
	MsgAlert("Falha autenticacao SMTP: "+oSrv:getErrorString(nRet) , "Especifico SELFIT - XMAIL.prw") 
	ConOut( "##_XMAIL.prw - Falha autenticacao SMTP: "+oSrv:getErrorString(nRet) ) 
	oSrv:SMTPdisconnect()
	oSrv := Nil
	Return .F.
EndIf

oMsg := tMailMessage():new()
oMsg:clear()

oMsg:cdate    := cValToChar( date() )
oMsg:cFrom    := cConta
oMsg:cTo      := cTo
oMsg:cSubject := cSubject
oMsg:cBody    := cBody

If ! Empty( cCC )
	oMsg:cCC := cCC
EndIf

For nI := 1 To Len(aAttach) 
	If oMsg:AttachFile( aAttach[nI] ) < 0 
		MsgAlert("Não foi possível anexar o arquivo: "+aAttach[nI] , "Especifico SELFIT - XMAIL.prw") 
	EndIf 
Next nI 

nRet := oMsg:Send( oSrv )
If nRet != 0
	MsgAlert("Falha envio mensagem: "+oSrv:getErrorString(nRet) , "Especifico SELFIT - XMAIL.prw") 
	ConOut( "##_XMAIL.prw - Falha envio mensagem: "+oSrv:getErrorString(nRet) )
	Return .F.
Else
	If lMensagem  							// Mostra a mensagem de E-mail enviado com êxito
		MsgInfo("E-mail enviado com êxito" , "Especifico SELFIT - XMAIL.prw") 
	Else
		ConOut( "##_XMAIL.prw - E-mail enviado com êxito - Destino: "+cTo+" - Assunto: "+cSubject ) 
	EndIf
EndIf

oSrv:SMTPdisconnect()
oSrv := Nil

Return .T.




User Function xTestMail()

WfPrepEnv("01","0101")

cTO := "aldo.santos@prox.com.br"
cSubject := "email de teste "+Time()
cBody  := "email de teste "+Time()

aAttach := {}

lMensagem := .T.



U_xMail( cTO , cSubject , cBody , aAttach , "" , lMensagem ) 

Return
