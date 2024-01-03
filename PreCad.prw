#Include "totvs.ch"
#Include "rwmake.ch"
#Include "tbiconn.ch"
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÉÍÍÍÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍËÍÍÍÍÍÍÑÍÍÍÍÍÍÍÍÍÍÍÍÍ»±±
±±ºPrograma  ³PreCad    ºAutor  ³ Cristiam Rossi     º Data ³  08/08/18   º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÊÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºDesc.     ³ Rotina de tratamento dos anexos de registros               º±±
±±ÌÍÍÍÍÍÍÍÍÍÍØÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¹±±
±±ºUso       ³ NEW TECHS                                                  º±±
±±ÈÍÍÍÍÍÍÍÍÍÍÏÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍÍ¼±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
// ======================================================================= \\
User Function PreCad()
// ======================================================================= \\

Local   aArea     := getArea()
Local   oDlg
Local   oGet
Local   aHeader   := {}
Local   aCols     := {}
Local   nStyle    := 0
Local   lRet      := .F.
Local   oBtnInc
Local   oBtnVis
Local   oBtnExc
Local   oBtnExp
Local   oBtnOut

Private cTitulo   := "Pre Cadastro de Produtos"

If ! verTabela()
	RestArea( aArea )
	Return .F.
EndIf

dbSelectArea( "P_P")

aAdd(aHeader,{"Status"	 , "STATP_P"  , "@X", 15, 0, /*"u_MudaData()"*/  ,"û","C","","V" } )
aAdd(aHeader,{"Descrição", "P_P_DESCR", "@X", 60, 0, /*"u_MudaValor()"*/ ,"û","C","","R" } )
aAdd(aHeader,{"Resposta" , "P_P_RESP" , "@X", 60, 0, /*"u_MudaData()"*/  ,"û","C","","R" } )
aAdd(aHeader,{"#Record"  , "RENOP_P"  , "@X", 09, 0, /*"u_MudaData()"*/  ,"û","C","","V" } )

aCols := fCargaDad()

define msDialog oDlg title cTitulo from 0,0 to 360,800 pixel
	@ 2,002 button oBtn1 prompt "Incluir"    size 45,12 action fInclui( oGet ) of oDlg pixel
	@ 2,052 button oBtn1 prompt "Visualizar" size 45,12 action fVisual( oGet ) of oDlg pixel
	@ 2,102 button oBtn2 prompt "Sair"       size 45,12 action oDlg:end() of oDlg pixel

	oGet := MsNewGetDados():New( 17, 2, 180, 401, nStyle,"Allwaystrue()","AllWaysTrue()","",,0,9999,,,,oDlg,@aHeader,@aCols)
	oGet:OBROWSE:BLDBLCLICK := {|| fVisual( oGet ) }
activate msDialog oDlg centered

restArea( aArea )

return lRet



// ======================================================================= \\
Static Function fInclui( oGet )
// ======================================================================= \\

local nRet  := 0
local aCols

	nRet := axInclui( "P_P", P_P->(recno()), 3 )

	If nRet == 1		// 1=Incluir; 3=Cancelar
		fSndWF()

		aCols := fCargaDad()
		oGet:aCols := aClone( aCols )
		oGet:oBrowse:Refresh()
	EndIf

Return Nil



// ======================================================================= \\
Static Function fVisual( oGet )
// ======================================================================= \\

Local N := oGet:nAt

If Empty( oGet:aCols[N,1] )
	Return Nil
EndIf

P_P->(dbGoTo(oGet:aCols[N,4]))

axVisual("P_P" , P_P->(Recno()) , 2)

Return Nil



// ======================================================================= \\
Static Function fSalvar( oGet )
// ======================================================================= \\

Local   aArea   := getArea()
Local   cPasta  := ""

Private aHeader := oGet:aHeader
Private aCols   := oGet:aCols
Private N       := oGet:nAt

If Empty( aCols[N,1] )
	return .F.
EndIf

J_A->( dbGoto( aCols[N,3] ) )

If msgYesNo( "Deseja exportar o anexo para uma pasta?", cTitulo )
	cPasta := cGetFile( , 'Selecione uma Pasta',, "C:\", .F., GETF_NETWORKDRIVE + GETF_LOCALFLOPPY + GETF_LOCALHARD + GETF_RETDIRECTORY, .F.)
	If ! Empty( cPasta )
		If __CopyFile( cSrvDir+"\"+J_A->J_A_FILE, cPasta+J_A->J_A_ARQ )
			msgInfo( "Anexo copiado para a pasta: "+cPasta, cTitulo)
		else
			msgAlert( "Não foi possível copiar o anexo!", cTitulo)
		EndIf
	EndIf
EndIf

restArea( aArea )

Return Nil



// ======================================================================= \\
Static Function fCargaDad()
// ======================================================================= \\

Local   aRet   := {}
Local   aTemp  := {}
Local   aStat  := {}

aTemp := RetSX3Box(GetSX3Cache('P_P_STAT', "X3_CBOX"),,,1)

aEval( aTemp, { | aIT | aAdd(aStat, aIt[3]) } )

P_P->( dbSetOrder( 1 ) )
P_P->( dbSeek( xFilial("P_P") + __cUserID, .T. ) )

While ! P_P->( EOF() ) .and. P_P->(P_P_FILIAL+P_P_USRCOD) == xFilial("P_P")+__cUserID
	aAdd( aRet, { aStat[ val(P_P->P_P_STAT )], P_P->P_P_DESCR, P_P->P_P_RESP, P_P->( recno() ), .F. } )
	P_P->( dbSkip() )
EndDo

If len( aRet ) == 0
	aAdd( aRet, { "", "", "", 0, .F.} )
EndIf

return aClone( aRet )



// ======================================================================= \\
Static Function verTabela()
// ======================================================================= \\

local aSX3 := {}
local nI

	If ! SX2->( dbSeek( "P_P" ) )
		recLock("SX2", .T.)
		SX2->X2_CHAVE   := "P_P"
		SX2->X2_ARQUIVO := "P_P"+cEmpAnt+"0"
		SX2->X2_NOME    := "Pre Cadastro Produto"
		SX2->X2_MODO    := "E"
		SX2->X2_MODOUN  := "E"
		SX2->X2_MODOEMP := "E"
		msUnlock()

//                   1            2    3            4               5                  6                  7                 8
		aAdd( aSX3, {"P_P_FILIAL","C", len(cFilAnt),"Filial"      , "Filial"         , "€€€€€€€€€€€€€€€", "xFilial('P_P')", "N", "V" } )
		aAdd( aSX3, {"P_P_ID"    ,"C",  9          ,"Cod.Seq"     , "Cod. Sequencial", "€€€€€€€€€€€€€€€", "getSXEnum('P_P','P_P_ID')", "N", "V" } )
		aAdd( aSX3, {"P_P_DESCR" ,"C",100          ,"Descricao"   , "Descricao"      , "€€€€€€€€€€€€€€ ", ""              , "S", "A" } )
		aAdd( aSX3, {"P_P_UM"    ,"C",  2          ,"U.M."        , "U.M."           , "€€€€€€€€€€€€€€ ", ""              , "S", "A" } )
		aAdd( aSX3, {"P_P_USRCOD","C",  6          ,"Cod. User"   , "Cod. Usuario"   , "€€€€€€€€€€€€€€ ", "__cUserID"     , "N", "V" } )
		aAdd( aSX3, {"P_P_USRNOM","C", 30          ,"Solicitante" , "Nome Usuario"   , "€€€€€€€€€€€€€€ ", "UsrRetName(__cUserID)", "S", "V" } )
		aAdd( aSX3, {"P_P_DATAI" ,"D",  8          ,"Dt Solicit." , "Data Solicit."  , "€€€€€€€€€€€€€€ ", "dDatabase"     , "S", "V" } )
		aAdd( aSX3, {"P_P_DATAR" ,"D",  8          ,"Dt Resposta" , "Data Resposta"  , "€€€€€€€€€€€€€€ ", ""              , "S", "V" } )
		aAdd( aSX3, {"P_P_RESP"  ,"C",100          ,"Resposta"    , "Resposta"       , "€€€€€€€€€€€€€€ ", ""              , "S", "V" } )
		aAdd( aSX3, {"P_P_STAT"  ,"C",  1          ,"Status"      , "Status"         , "€€€€€€€€€€€€€€ ", "'1'"           , "N", "V", "1=Inserida;2=Enviada;3=Existente;4=Sera incluido;5=Nao trabalhamos;6=Outros" } )

		for nI := 1 to len( aSX3 )
			recLock("SX3", .T.)
			SX3->X3_ARQUIVO := "P_P"
			SX3->X3_ORDEM   := strZero(nI,2)
			SX3->X3_CAMPO   := aSX3[nI,1]
			SX3->X3_TIPO    := aSX3[nI,2]
			SX3->X3_TAMANHO := aSX3[nI,3]
			SX3->X3_TITULO  := aSX3[nI,4]
			SX3->X3_DESCRIC := aSX3[nI,5]
			SX3->X3_USADO   := aSX3[nI,6]
			SX3->X3_RELACAO := aSX3[nI,7]
			SX3->X3_NIVEL   := 1
			SX3->X3_RESERV  := "þÀ"
			SX3->X3_PROPRI  := "U"
			SX3->X3_BROWSE  := aSX3[nI,8]
			SX3->X3_VISUAL  := aSX3[nI,9]
			SX3->X3_CONTEXT := "R"

			If len( aSX3[nI] ) > 9
				SX3->X3_CBOX := aSX3[nI,10]
			EndIf

			If aSX3[nI,1] == "P_P_UM"
				SX3->X3_PICTURE := "@!"
				SX3->X3_VALID   := 'vazio().or.ExistCpo("SAH")'
				SX3->X3_F3      := 'SAH'
				SX3->X3_OBRIGAT := "€"
			EndIf

			If aSX3[nI,1] == "P_P_DESCR"
				SX3->X3_OBRIGAT := "€"
			EndIf

			msUnlock()
		next

		recLock("SIX", .T.)
		SIX->INDICE    := "P_P"
		SIX->ORDEM     := "1"
		SIX->CHAVE     := "P_P_FILIAL+P_P_USRCOD+P_P_DATAI+P_P_ID"
		SIX->DESCRICAO := "Cod User + Data Solicitacao"
		SIX->PROPRI    := "U"
		SIX->SHOWPESQ  := "S"
		msUnlock()

		recLock("SIX", .T.)
		SIX->INDICE    := "P_P"
		SIX->ORDEM     := "2"
		SIX->CHAVE     := "P_P_FILIAL+P_P_ID"
		SIX->DESCRICAO := "Identificador"
		SIX->PROPRI    := "U"
		SIX->SHOWPESQ  := "N"
		msUnlock()

	EndIf

	If ! chkFile("P_P")
		msgAlert( "tabela P_P não pode ser aberta, verifique!", cTitulo)
		return .F.
	EndIf

Return .T.



// ======================================================================= \\
User Function preCadRT
// ======================================================================= \\

Local   aArea     := getArea()
Local   cString   := "P_P"
Local   aCores    := {}

Private aRotina   := {}
Private CCADASTRO := "Pré Cadastro de Produtos"
Private bRespond  := {|| fResponder()}
Private bLegenda  := {|| fLegenda()  }

If ! __cUserID $ superGetMV("FS_PRECAD",,"000000")
	msgStop( "Seu usuário não está cadastrado no parâmetro FS_PRECAD, acesso negado!", cCadastro)
	Return Nil
EndIf

aAdd(aCores, { "P_P_STAT == '1'" , "BR_AMARELO" })
aAdd(aCores, { "P_P_STAT != '1'" , "BR_PRETO"  })

aAdd(aRotina, {"Pesquisar"       , "axPesqui"      , 0, 1} )
aAdd(aRotina, {"Visualizar"      , "axVisual"      , 0, 2} )
aAdd(aRotina, {"Responder"       , "eval(bRespond)", 0, 4} )
aAdd(aRotina, {"Legenda"         , "eval(bLegenda)", 0, 3} )

If ! verTabela()
	restArea( aArea )
	Return Nil
EndIf

dbSelectArea(cString)
dbGotop()

mBrowse(,,,,cString,,,,,,aCores )

restArea( aArea )

Return Nil



// ======================================================================= \\
static function fResponder()
// ======================================================================= \\

local oDlg
local cDescr := P_P->P_P_DESCR
local cUM    := P_P->P_P_UM
local cUser  := P_P->P_P_USRNOM
local cResp  := P_P->P_P_RESP
local aItem  := { "Existente", "Será incluído", "Não trabalhamos", "Outros" }
local cItem  := ""
local lGrv   := .F.

If P_P_STAT != "1"
	If ! msgYesNo( "Solicitação já respondida, deseja interagir novamente?", cCadastro )
		Return Nil
	EndIf
EndIf

define msDialog oDlg title cCadastro from 0,0 to 200,650 pixel
	@ 12,007 say "Descrição informada:" of oDlg pixel
	@ 22,007 msGet cDescr size 190,9 when .F. of oDlg pixel

	@ 12,210 say "U.M.:" of oDlg pixel
	@ 22,210 msGet cUM size 15,9 when .F. of oDlg pixel

	@ 12,235 say "Solicitante:" of oDlg pixel
	@ 22,235 msGet cUser size 90,9 when .F. of oDlg pixel

	@ 45,007 say "Observações:" of oDlg pixel
	@ 55,007 msGet cResp size 220,9 of oDlg pixel

	@ 45,235 say "Resposta:" of oDlg pixel
	@ 55,235 combobox cItem ITEMS aItem size 90,9 of oDlg pixel

	@ 73,220 button oBtn1 prompt "Gravar"    size 45,14 action iif( Empty(cResp), nil, ( lGrv := .T., oDlg:end() )) of oDlg pixel
	@ 73,270 button oBtn2 prompt "Sair"      size 45,14 action oDlg:end() of oDlg pixel
activate msDialog oDlg centered

If lGrv
	recLock("P_P", .F.)
	P_P->P_P_RESP  := cResp
	P_P->P_P_DATAR := Date()
	P_P->P_P_STAT  := cValToChar( aScan( aItem, cItem ) + 2  )
	msUnlock()

	fSndMail(cItem, cResp)
EndIf

Return Nil



// ======================================================================= \\
Static Function fLegenda()
// ======================================================================= \\

local aCores := {	{"BR_AMARELO","Aguardando retorno"},;
					{"BR_PRETO"  ,"Respondidas"}}

	brwLegenda(cCadastro,"Legenda",aCores)

Return Nil



// ======================================================================= \\
Static Function fSndWF()
// ======================================================================= \\

Local cPathMod     := SuperGetMV("MC_WFPMOD" , , "\WORKFLOW\")
// --> Conferido parâmetro "MC_WFPMOD"  (SX6010) em 20/03/2021 (ambiente produção 12.1.17) e este existe, porém DELETADO e com conteudo 'WORKFLOW'

Local cUrlWf       := SuperGetMV("MC_URLWF"  , , "http://172.16.24.26:81/wf") 		// --> Alterado PROX 20/03/2021   [ Era: SuperGetMV("MC_URLWF"  , , "http://localhost:8080/wf") ] 
// --> Conferido parâmetro "MC_URLWF"   (SX6010) em 20/03/2021 (ambiente produção 12.1.17) e estava com conteúdo 'http://54.207.46.24:82/wf' 
// --> No ambiente novo (release 27) o IP será o 172.16.24.26.

Local cCodProcesso := "WFpreCadastro"
Local cHtmlModelo  := cPathMod + "WFpreCad.html"
Local cAssunto     := "[Workflow] Pré-Cadastro de Produtos"
Local oProcess     := TWFProcess():New(cCodProcesso, cAssunto)
Local cUsrComp     := superGetMV("MV_XUSRCMP",,"aprendiz_cris@yahoo.com.br")
// --> Conferido parâmetro "MV_XUSRCMP" (SX6010) em 20/03/2021 (ambiente produção 12.1.17) e este existe, porém DELETADO e sem conteúdo.

Private MSGP_NONE  := ""

	makeDir(cPathMod)
	makeDir(cPathMod + "htmls")

	oProcess:NewTask(cAssunto, cHtmlModelo)
	oHtml := oProcess:oHTML
	oProcess:oHtml:ValByName("IDPRECAD"   , cValToChar( P_P->(recno()) ) )
	oProcess:oHtml:ValByName("DESCRICAO"  , alltrim(encodeUTF8(P_P->P_P_DESCR)) )
	oProcess:oHtml:ValByName("UM"         , alltrim(P_P->P_P_UM) )
	oProcess:oHtml:ValByName("SOLICITANTE", alltrim(P_P->P_P_USRNOM) )
	oProcess:oHtml:ValByName("RESPOSTA"   , "" )
	oProcess:oHtml:ValByName("OBSERVACOES", "" )
	oProcess:bReturn  := "U_WFpreProd()"
	cMailID := oProcess:Start(cPathMod + "htmls")

	//comeca agora a montar a mensagem que vai no e-mail dos destinatarios
	cHtmlModelo := cPathMod + "WfLinkPreCad.html"
	oProcess:NewTask(cAssunto, cHtmlModelo)  
	oProcess:cSubject := cAssunto
	oProcess:cTo      := usrRetMail(cUsrComp) // usrRetMail(__cUserID)

	//assinalar valores das macros do html
	oProcess:ohtml:ValByName("LINK", cUrlWf +"/"+ cMailID + ".htm")		
	oProcess:Start()
//	ConOut("(FINAL -> OK <- |WF preCad) Processo: " + oProcess:fProcessID + " - Task: " + oProcess:fTaskID )	

Return Nil



// ======================================================================= \\
User Function WFpreProd(oProcess)
// ======================================================================= \\

Local nRECNO
Local cResposta
Local cObserv

ConOut( "[PreCad.prw -> WFpreProd()] - Retorno WF pre-cadastro de produtos: "+DtoC(Date()) + " " + Time() )

nRECNO    := Val( oProcess:oHtml:RetByName("IDPRECAD") )
cResposta := oProcess:oHtml:RetByName("RESPOSTA")
cObserv   := decodeUTF8( oProcess:oHtml:RetByName("OBSERVACOES") )
cObserv   := strtran( cObserv, CRLF, "")

varInfo("nRECNO"      , nRECNO)
varInfo("cResposta"   , cResposta)
varInfo("cObserv"     , cObserv)

If chkFile("P_P")
	P_P->( dbGoto( nRECNO ) )
	recLock("P_P", .F.)
		P_P->P_P_DATAR := date()
		P_P->P_P_RESP  := cObserv
		P_P->P_P_STAT  := left( cResposta, 1 )
	msUnlock()

	fSndMail(substr(cResposta, 3), cObserv)
Else
	conout("[PreCad.prw -> WFpreProd()] - Nao abriu P_P")
EndIf

Return Nil



// ======================================================================= \\
Static Function fSndMail(cResposta, cObserv)
// ======================================================================= \\

Local cBody

	cBody := "Prezado(a) colaborador(a),<br /><br />"
	cBody += "O departamento de Suprimentos respondeu sobre sua pré-solicitação.<br /><br />"
	cBody += "<strong>sua solicitação:</strong> "+alltrim(P_P->P_P_DESCR)+"<br /><br />"
	cBody += "<strong>Resposta:</strong><br />"
	cBody += cResposta+"<br /><br />"

	cBody += "<strong>Observações:</strong><br />"
	cBody += cObserv+"<br /><br /><br /><br />"		
	cBody += "<i>resposta automática favor não responder</i>"

	U_xMail( usrRetMail( P_P->P_P_USRCOD ), "resposta WF pré-cadastro de produto", cBody )

Return Nil
