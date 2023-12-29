#include "protheus.ch"
#include "fileio.ch"
#include "common.ch"

#Define cEol Chr(13)+Chr(10)
#Define _LIMSTR 	1048576

//--------------------------------------------------------------------------------------- 
/*/{Protheus.doc} MCLIB001
Função criada para efeitos de compatibilidade evitando que seja criada uma função com o 
nome deste prw.

@author 		Ederson Colen
@since 		30/07/2012
@version		P11
@param
@return	Nil

@obs	      

-MC3CriBox  : Versão mais nova Cria Box.
-MCSeqSX6	: Gera um Sequencial pelo Arquivo de Parâmetros.



Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/ 
//---------------------------------------------------------------------------------------
User Function MCLIB001()
Return Nil           



//---------------------------------------------------------------------------------------
/*/{Protheus.doc} FCloseArea
Função criada para fechar arquivos de Trabalho.

@author		Ederson Colen
@since		25/05/2012
@version		P11
/*/
//---------------------------------------------------------------------------------------
User Function FCloseArea(cArqTrb) 
  
//Fecha o Arquivo de Trabalho 
If (Select(cArqTrb)!= 0)
	(cArqTrb)->(dbCloseArea())

	If File(cArqTrb + GetDbExtension())
		FErase(cArqTrb + GetDbExtension())
	EndIf

EndIf

Return Nil



//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MCSETERR
Salva o erro ocorrido nas rotinas de integração WebService ECOFROTAS
        
@author	Ederson Colen
@since	28/11/2014
@version	P11
@param	cFilOri	-	Filial de Origem do erro
@param	dDatErr	-	Data da ocorrência do erro
@param	cHorErr	-	Hora da ocorrência do erro
@param	cChvReg	-	Número do Transporte
@param	cRot		-	Rotina que disparou o erro
@param	mErr		- 	Mensagem de erro.
@return	Nil

@obs	      
Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//---------------------------------------------------------------------------------------
User Function MCSETERR(cFilOri, dDatErr, cHorErr, cChvReg, cRot, mErr,cCodErr, cMsgErro)

Local lEnvEmai	:= SuperGetMV('MC_ENVEMAI',.F.,.F.)
Local lGrvArEi	:= SuperGetMV('MC_GRVARQE',.F.,.F.)
Local cMesAdic := ""

Default	cFilOri	:=	""
Default	dDatErr	:=	""
Default	cHorErr	:=	""
Default	cChvReg	:=	""
Default	cRot		:=	""
Default	mErr		:= ""

If ! U_MCAliInDic("PZZ")
	If lEnvEmai
		FEnvEmai("MCLIB001","ARQUIVO DE LOG NÃO CRIADO","XXXXXX","XXXXXX - ARQUIVO GRAVACAO DE LOG NAO CRIADO - FAVOR RODAR ROTINAS DE UPDATE DO PROJETO")
	EndIf
	Return Nil
EndIf

If (Empty(dDatErr) .Or. Empty(cHorErr) .Or. Empty(cChvReg) .Or. Empty(cRot) .Or. Empty(mErr))
	Conout("Nao foi possivel gravar o erro. Parametros informados, sao insuficientes para realizar a gravacao.")
Else

	If lEnvEmai
		cMesAdic := FEnvEmai(cRot,cChvReg,cCodErr,cMsgErro)
		If ! Empty(cMesAdic)
			mErr += CHR(10)+CHR(13)+"ARQ.HTML:"+cMesAdic
		EndIf
	EndIf

	cChvReg := Iif(ValType(cChvReg) == "N",cValToChar(cChvReg),cChvReg)
	RecLock("PZZ",.T.)
	PZZ->PZZ_FILIAL 	:=	xFilial("PZZ")
	PZZ->PZZ_ID			:=	GetSXENum("PZZ","PZZ_ID")
	PZZ->PZZ_FILORI 	:= cFilOri
	PZZ->PZZ_DTERRO 	:=	dDatErr
	PZZ->PZZ_HORA		:=	cHorErr
	PZZ->PZZ_CHVREG	:=	cChvReg
	PZZ->PZZ_ROTINA 	:=	cRot
	PZZ->PZZ_ERRO		:=	mErr
	PZZ->PZZ_CODERR	:= cCodErr
	PZZ->(MsUnLock())
	ConfirmSX8()

	If lGrvArEi
		FGrvArqE()
	EndIf

EndIf

Return Nil



//---------------------------------------------------------------------------------------
/*/{Protheus.doc} FEnvEmai
Envia o Email do Erro.
        
@author	Ederson Colen
@since	19/01/2015
@version	P11
@param	
@return	

@obs	      
Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//---------------------------------------------------------------------------------------
Static Function FEnvEmai(cRot,cChvReg,cCodErr,cMsgErro)

Local cPathMod	:= "\web\webservice\"
Local cNomMod	:= "errows.html"
Local cCodPrc	:= Right(AllTrim(RetCodUsr()),6)
Local oProcess	:= Nil
//Local oHtml		:= Nil
Local cMailID	:= ""
Local aAreas	:= {GetArea()}
Local nPos		:= 0
Local cAssunto	:= ""
Local cEmailTo := Lower(AllTrim(SuperGetMV('MC_EMAILTI',.F.,"edersoncolen@gmail.com")))
Local cDescErr := ""

If U_MCAliInDic("PZY")
	
	PZY->(dbSetOrder(1))
	PZY->(dbSeek(xFilial("PZY")+cCodErr))

	If PZY->(! Eof())
		If ! Empty(PZY->PZY_EMAIL)
			cEmailTo := Lower(AllTrim(PZY->PZY_EMAIL))
			cAssunto := "Integracao WebService"+AllTrim(PZY->PZY_DESERR)
		EndIf
		cDescErr := cMsgErro
	Else
		cAssunto := "Integracao WebService"+cRot
		cDescErr := "ERRO NAO CADASTRADO. FAVOR CADASTRAR.(ERRO:"+cMsgErro+")"
	EndIf
Else
	cAssunto := "Integracao WebService"+cRot
	cDescErr := "ERRO NAO CADASTRADO. FAVOR CADASTRAR.(ERRO:"+cMsgErro+")"
EndIf

oProcess := TWFProcess():New(cCodPrc,cAssunto) // Inicialize a classe TWFProcess e assinale a variável objeto oProcess:

oProcess:NewTask(cAssunto,cPathMod+cNomMod)//Cria o objeto referente a tareja, com o modelo do html a ser preenchido

oProcess:cSubject := cAssunto// Repasse o texto do assunto criado para a propriedade especifica do processo.

oProcess:cTo := cEmailTo

oProcess:oHTML:ValByName("CHAVREGS",cChvReg)
oProcess:oHTML:ValByName("MERROWS",cDescErr)
oProcess:oHTML:ValByName("ROTERRO",cRot)

// Apos ter repassado todas as informacoes necessarias para o workflow, solicite a
// a ser executado o método Start() para se gerado todo processo e enviar a mensagem
// ao destinatário.
cMailID := oProcess:Start(cPathMod+"htmls")

WFSendMail()

//restaura a area
AEval(aAreas, {|x| RestArea(x)})
                
Return cMailID



//---------------------------------------------------------------------------------------
/*/{Protheus.doc} MCRSTRING
Retorna uma Stringa conforme os parâmetros passados.
        
@author	Ederson Colen
@since	24/06/2014
@version	P11
@param	cTextoIn	- Texto Inicial da Procura na String
@param	cTextoFi	- Texto Final da Procura na String
@param	cTextCon	- Texto contendo os dados.
@param	cTipoStr	- Tipo de Retorno STRING = Data em String e TEXTO = Texto Normal.

@return	cRetTex		- Texto Formatado.

@obs	      
Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//---------------------------------------------------------------------------------------
User Function MCRSTRING(cTextoIn,cTextoFi,cTextCon,cTipoStr)

Local cRetTex := ""

Default	cTextoIn := ""
Default	cTextoFi := ""
Default	cTextCon := ""
Default	cTipoStr := ""

nPosTIni := AT(cTextoIn,Upper(cTextCon))+Len(cTextoIn)
nPosTFina := AT(cTextoFi,Upper(cTextCon))
If cTipoStr == "STRING"
	cRetTex := SubStr(cTextCon,nPosTIni,(nPosTFina - nPosTIni))
	cRetTex := SubStr(cRetTex,7,4)+SubStr(cRetTex,4,2)+Left(cRetTex,2)
Else
	cRetTex := SubStr(cTextCon,nPosTIni,(nPosTFina - nPosTIni))
EndIf

Return(cRetTex)



//-------------------------------------------------------------------
/*/{Protheus.doc} MAviso
Tela de Erro SQL

@author	  Ederson Colen
@since	  28/11/2014
@version   P11
@obs	     
@param     

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------                          
User Function MAviso(cMemo,cTitulo)

Local oMemo, oBtn
Local aTMTela  := {000,000,260,715}
Local aTGMemo  := {005,005,350,100}
Local aPosBut  := {110,300}
Local lSaiTMem := .T.

Private oDlgMemo

Default cMemo := ""

While lSaiTMem

   DEFINE MSDIALOG oDlgMemo FROM aTMTela[01],aTMTela[02] TO aTMTela[03],aTMTela[04] PIXEL TITLE cTitulo
   oMemo:= tMultiget():New(aTGMemo[01],aTGMemo[02],{|u|if(Pcount()>0,cMemo:=u,cMemo)},oDlgMemo,aTGMemo[03],aTGMemo[04],,,,,,.T.,,,,,,.F.)
   @ aPosBut[01],aPosBut[02] BUTTON oBtn PROMPT "Fecha" OF oDlgMemo PIXEL ACTION FFecTMem(@lSaiTMem) Of oDlgMemo Pixel

   ACTIVATE MSDIALOG oDlgMemo CENTERED

EndDo

Return()



//-------------------------------------------------------------------
/*/{Protheus.doc} FFecTMem
Fecha a Tela de Aviso

@author	  Ederson Colen
@since	  28/11/2014
@version   P11
@obs	     
@param     

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------                          
Static Function FFecTMem(lSaiTMem)

lSaiTMem := .F.
oDlgMemo:End()

Return()



//-------------------------------------------------------------------
/*/{Protheus.doc} FGrvArqE
Grava Arquivo de Log para Futura Análise.

@author	  Ederson Colen
@since	  28/11/2014
@version   P11
@obs	     
@param     

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------                          
Static Function FGrvArqE()

Local cGetDir	:= "\LOGWS\"
Local nHandle	:= 0
//Local nXI		:= 0

If ! File(cGetDir)
   MakeDir(cGetDir)
EndIF

nHandle 	:= FCreate(cGetDir+AllTrim(PZZ->PZZ_ID)+".TXT")

If (nHandle > -1)

	//Gera Registro 
  	FWrite(nHandle,"FILIAL: "+PZZ->PZZ_FILIAL+CRLF)
  	FWrite(nHandle,"ID: "+PZZ->PZZ_ID+CRLF)
	FWrite(nHandle,"FILIAL ORIGEM: "+PZZ->PZZ_FILORI+CRLF)
	FWrite(nHandle,"DATA ERRO: "+DTOC(PZZ->PZZ_DTERRO)+CRLF)
	FWrite(nHandle,"HORA ERRO: "+PZZ->PZZ_HORA+CRLF)
	FWrite(nHandle,"CHAVE REGISTRO: "+PZZ->PZZ_CHVREG+CRLF)
	FWrite(nHandle,"ROTINA ORIGEM ERRO: "+PZZ->PZZ_ROTINA+CRLF)
	FWrite(nHandle,"CODIGO DO ERRO: "+PZZ->PZZ_CODERR+CRLF)
	FWrite(nHandle,"DADOS DO ERRO:"+CRLF)
	FWrite(nHandle,PZZ->PZZ_ERRO+CRLF)
	FWrite(nHandle,CRLF)

   //Fecha o arquivo
   FClose(nHandle)

EndIf

Return()



User Function MCMsgErr(aMsgErr,cMsg,nPosHist,aPosCol)

//-- Mensagem, codigo, rotina
Local aButtons	:= {}
Local cLbx		:= ''
Local oDlgEsp
Local oLbxEsp
Local nOpcao	:= 0
//Local aColMsg	:= {}

Default cMsg     := 'Mensagem'
Default nPosHist	:= 0
Default aPosCol	:= {1,1}

If Len(aMsgErr) > 0 

	If nPosHist >= 1
		AAdd( aButtons, { 'DESTINOS', { || U_MAviso(aMsgErr[oLbxEsp:nAT,nPosHist],cMsg) },"Mais detalhes","Mais detalhes"})
	EndIf

	DEFINE MSDIALOG oDlgEsp TITLE "Verifique os dados..." FROM 00,00 TO 350,769 PIXEL

	@ 30,01 LISTBOX oLbxEsp VAR cLbx FIELDS HEADER cMsg,"Rotina" SIZE 383,142 OF oDlgEsp PIXEL
	oLbxEsp:SetArray(aMsgErr)
	oLbxEsp:bLine	:= {|| {aMsgErr[oLbxEsp:nAT,aPosCol[1]],aMsgErr[oLbxEsp:nAT,aPosCol[2]]}}
	ACTIVATE MSDIALOG oDlgEsp CENTERED ON INIT EnchoiceBar( oDlgEsp, {|| oDlgEsp:End(), nOpcao := 1 },{|| oDlgEsp:End() },, aButtons )

EndIf

Return(nOpcao == 1)



//-------------------------------------------------------------------
/*/{Protheus.doc} MCUFIBGE
Retorna o Codigo IBGE do Estado.

@Return	Nil
@author  Ederson Colen
@since   28/11/2014

/*/
//------------------------------------------------------------------- 
User Function MCUFIBGE(cUf)

Local nX         := 0
Local cRetorno   := ""
Local aUF := {{"RO","11"},{"AC","12"},{"AM","13"},{"RR","14"},{"PA","15"},{"AP","16"},{"TO","17"},{"MA","21"},{"PI","22"},;
				  {"CE","23"},{"RN","24"},{"PB","25"},{"PE","26"},{"AL","27"},{"SE","28"},{"BA","29"},{"MG","31"},{"ES","32"},;
				  {"RJ","33"},{"SP","35"},{"PR","41"},{"SC","42"},{"RS","43"},{"MS","50"},{"MT","51"},{"GO","52"},{"DF","53"},{"EX","99"}}

If ! Empty(cUF)
	nX := aScan(aUF,{|x| x[1] == cUF})
	If nX == 0
		nX := aScan(aUF,{|x| x[2] == cUF})
		If nX <> 0
			cRetorno := aUF[nX][1]
		EndIf
	Else
		cRetorno := aUF[nX][2]
	EndIf
EndIf

Return(cRetorno)



//-------------------------------------------------------------------
/*/{Protheus.doc} MCGrvAEr
Realiza a Gravacao do Arrey de Erro Log

@Return	Nil
@author  Ederson Colen
@since   28/11/2014

/*/
//------------------------------------------------------------------- 
User Function MCGrvAEr(aErro)

Local nXY

If Len(aErro) > 0

	For nXY := 1 To Len(aErro)

		If ! aErro[nXY,03] $ "MC0001_MC0000_MC0002_MC0003_MC0004_MC0005_"
			cXMLEnv := ""
			cXMLEnv += StrTran(aErro[nXY,05],"><",">"+chr(13)+chr(10)+"<")
			cXMLEnv += chr(13)+chr(10)
			cXMLEnv += "###################################### ACIMA DADOS WEBSERVICE ######################################"+chr(13)+chr(10)
			cXMLEnv += "###################################### RETORNO ERRO ######################################"+chr(13)+chr(10)
			cXMLEnv += aErro[nXY,02]
		Else 
			cXMLEnv := ""
			cXMLEnv += aErro[nXY,02]
			If ! Empty(aErro[nXY,05])
				cXMLEnv += chr(13)+chr(10)
				cXMLEnv += AllTrim(aErro[nXY,05])+chr(13)+chr(10)
				cXMLEnv += StrTran(aErro[nXY,05],"><",">"+chr(13)+chr(10)+"<")
				cXMLEnv += chr(13)+chr(10)
			EndIf
		EndIf

		U_MCSETERR(SM0->M0_CODFIL,dDataBase,Time(),aErro[nXY,01],aErro[nXY,04],cXMLEnv,aErro[nXY,03],aErro[nXY,02])

		cXMLEnv := ""

	Next nXY

EndIf

Return NIL



//------------------------------------------------------------------- 
/*/{Protheus.doc} MC3CriBox
Realiza o desenho em relatórios TMSPrinter.


@author 	Fernando dos Santos Ferreira 
@since 	24/04/2012 
@version P11
@param	oPrint		Objeto de Impressão TMSPrinter,
@param	oFont			Fonte utilizada para impressão
@param 	nPerX			Posicão em percentuais da página no eixo X do início do quadro
@param 	nPercLarg	Largura do quadrado em percentuais da página
@param 	nPerY			Posicão em percentuais da página no eixo Y do início do quadro
@param 	nPercAlt		Altura do quadrado em percentuais da página
@param 	cTexto		Texto a Ser impresso
@param 	nAlignH		Alinhamento na horizontal. 1 = esquerda, 2 = centro, 3 = direita. Se Nil padrao = 1
@param 	nAlignV		Alinhamento na vertical. 1 = topo, 2 = centro, 3 = fundo. Se Nil padrao = 1
@param 	lShowBox		Vizualiza os retangulo. Sim ou não. Se não apenas posicionará o texto. Se Nil padrao = .T.
@param 	nMargem		Largura em pixels da margem da página, Se Nil Padrão = 100
@param 	nEspaco		Distância onde o texto irá ser impresso em relação a margem do retângulo. Se Nil padrao = 20
@param 	nColor		Cor a ser utilizada no preenchimento do Box.
@param 	cCabec		Texto do Cabeçalho do box.                           
@param 	oFntCab		Fonte utilizada na impressão do cabeçalho. Se Nil, arial tamanho 9
@obs  
 
@Return aCoords	 {	Percentual da página em Y onde terminou o retangulo
							Percentual da página em X onde terminou o retangulo
							Posicao em pontos de Y onde comecou o retangulo
							Posicao em pontos de X onde comecou o retangulo
							Posicao em pontos de Y onde Terminou o retangulo
							Posicao em pontos de X onde Terminou o retangulo }
							

Alteracoes Realizadas desde a Estruturacao Inicial 
Data       Programador     Motivo 
/*/ 
//------------------------------------------------------------------
User Function MC3CriBox(oPrint,oFont, nPerX,nPercLarg,nPercY,nPercAlt, cTexto,nAlignH,nAlignV,lShowBox,nMargem,nEspaco,nColor, cCabec, oFntCab)

Local PixelX := 300/oPrint:nLogPixelX()
Local PixelY := 300/oPrint:nLogPixelY()

Local nHorSize	:= oprint:NHORZRES() * PixelX  - nMargem * 2
Local nVertSize:= oprint:NVERTRES() * PixelY - nMargem * 2
Local nRetY := 0 
Local nRetX := 0 
Local nX :=	0   
Local aTxt := Separa(cTexto,chr(13))
Local nAltFont := 0           
Local nPosY := 0
Local nPosX := 0
Local oBrush:=Nil     

Local nNewPerX := nPerX
Local nNewPerY := nPercY          

Local nBegBoxX := 0
Local nBegBoxY := 0
Local nEndBoxX := 0
Local nEndBoxY := 0

Default nMargem := 100
Default nAlignH := 1
Default nAlignV := 1
Default lShowBox := .T.
Default nEspaco  := 10 
Default oFntCab  := TFont():New("Arial",9,8 ,.T.,.F.,5,.T.,5,.T.,.F.)

nRetY := nPercY  + nPercAlt
nRetX := nPerX   + nPercLarg

//Passando os valores informados de percentual para coordenadas físicas
nNewPerX	:= nMargem + nNewPerX	* nHorSize / 100
nPercLarg:= nPercLarg * nHorSize / 100
nNewPerY	:=	nMargem + nNewPerY * nVertSize / 100
nPercAlt	:= nPercAlt * nVertSize / 100

If(lShowBox)
	If(nColor != Nil )
		oBrush := TBrush():New( , nColor )
		oPrint:FillRect( {nNewPerY, nNewPerX, nNewPerY + nPercAlt, nNewPerX + nPercLarg}, oBrush )
   EndIf
	oPrint:Box(nNewPerY,nNewPerX, nNewPerY + nPercAlt,nNewPerX + nPercLarg)	
	nBegBoxX := nNewPerX
	nBegBoxY := nNewPerY
	nEndBoxX := nNewPerX + nPercLarg
	nEndBoxY := nNewPerY + nPercAlt

EndIf

If(!Empty(cCabec))                         
	oPrint:Say(nNewPerY+05,nNewPerX +15,cCabec ,oFntCab,100)
EndIf

If(!Empty(cTexto))

	nAltFont := oPrint:GetTextHeight("Aa",oFont) * PixelY + 2 

	For nX := 1 to Len(aTxt)  
		If(nAlignH == 3)                                                                                                                         		
			nPosX := nNewPerX + nPercLarg  -  oPrint:GetTextWidth(aTxt[nX],oFont) * PixelX - 10 * PixelX
		ElseIf(nAlignH == 2)
			nPosX := nNewPerX + nPercLarg/2 - oPrint:GetTextWidth(aTxt[nX],oFont) * PixelX / 2                                                             
		ElseIf(nAlignH == 1)
			nPosX := nNewPerX +  nEspaco //Dando uma distáncia da margem
		EndIf 
	                   
		If(nAlignV == 3)                                       
			nPosY := nNewPerY + nPercAlt   -  nAltFont *  Len(aTxt) - 05
		ElseIf(nAlignV == 2)
	      nPosY := nNewPerY +  nPercAlt/ 2  - nAltFont*PixelY / 2
		ElseIf(nAlignV == 1)                                                                       	
	 		nPosY := nNewPerY + 10 //Dando uma distáncia da margem
		EndIf          
	
		oPrint:Say(nPosY + (nX - 1) * nAltFont ,nPosX,aTxt[nX] ,oFont,nPercLarg)
	Next
	
EndIf

Return {nRetY,nRetX,nBegBoxY,nBegBoxX,nEndBoxY,nEndBoxX}



User Function MCLeUserLg(cCampo,nTipo)

Local nPos			:= 0
Local cAux			:= ""
Local cID			:= ""
Local cUsrName 	:= ""
Local cRet			:= ""
//Local cAlias		:= ""
//Local cSvAlias  	:= Alias()
//Local lChgAlias 	:= .F.
Local __aUserLg 	:= {}

Default nTipo := 1

cAux := Embaralha(cCampo,1)

If ! Empty(cAux)
	If Subs(cAux, 1, 2) == "#@"
		cID := Subs(cAux, 3, 6)
		If Empty(__aUserLg) .Or. Ascan(__aUserLg, {|x| x[1] == cID}) == 0
			PSWORDER(1)
			If (PSWSEEK(cID))
				cUsrName	:= Alltrim(PSWRET()[1][4])
			EndIf		
			Aadd(__aUserLg,{cID,cUsrName})
		EndIf
		
		If nTipo == 1 // retorna o usuário
			nPos := Ascan(__aUserLg, {|x| x[1] == cID})
			cRet := __aUserLg[nPos][2]
		Else
			cRet := Dtoc(CTOD("01/01/96","DDMMYY") + Load2In4(Substr(cAux,16)))
		Endif                         
	Else
		If nTipo == 1 // retorna o usuário
			cRet := Subs(cAux,1,15)
		Else   
			cRet := Dtoc(CTOD("01/01/96","DDMMYY") + Load2In4(Substr(cAux,16)))
		Endif                         
	EndIf
EndIf                 

Return(cRet)



//--------------------------------------------------------------------------------------- 
/*/{Protheus.doc} MCAcePar
Acerta os parâmetros passados.

@author 		Ederson Colen
@since 		01/12/2014
@version		P11
@param
@return	Nil

@obs	      
Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/ 
//---------------------------------------------------------------------------------------
User Function MCAcePar(cTexAcer,cTipStr)

If cTipStr == "C"
	cTexAcer := "'"+AllTrim(cTexAcer)+"'"
Else
	cTexAcer := AllTrim(cTexAcer)
EndIf

If Len(AllTrim(cTexAcer)) >= 2
	Do Case
		Case AT("_",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"_","','"),StrTran(cTexAcer,"_",","))
		Case AT("#",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"#","','"),StrTran(cTexAcer,"#",","))
		Case AT("@",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"@","','"),StrTran(cTexAcer,"@",","))
		Case AT("*",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"*","','"),StrTran(cTexAcer,"*",","))
		Case AT("/",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"/","','"),StrTran(cTexAcer,"/",","))
		Case AT("!",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"!","','"),StrTran(cTexAcer,"!",","))
		Case AT("$",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"$","','"),StrTran(cTexAcer,"$",","))
		Case AT("%",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"%","','"),StrTran(cTexAcer,"%",","))
		Case AT("&",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"&","','"),StrTran(cTexAcer,"&",","))
		Case AT("(",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"(","','"),StrTran(cTexAcer,"(",","))
		Case AT(")",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,")","','"),StrTran(cTexAcer,")",","))
		Case AT("-",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"-","','"),StrTran(cTexAcer,"-",","))
		Case AT("=",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"=","','"),StrTran(cTexAcer,"=",","))
		Case AT("+",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"+","','"),StrTran(cTexAcer,"+",","))
		Case AT("\",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"\","','"),StrTran(cTexAcer,"\",","))
		Case AT("|",cTexAcer) > 1
				cTexAcer := Iif(cTipStr == "C",StrTran(cTexAcer,"|","','"),StrTran(cTexAcer,"|",","))
	EndCase

	If cTipStr == "C"
		If Right(cTexAcer,3) == ",''"
			cTexAcer := StrTran(cTexAcer,",''","'")
		EndIf

  		If Right(cTexAcer,2) == "''"
			cTexAcer := StrTran(cTexAcer,"''","'")
		EndIf
	Else
		If Right(cTexAcer,2) == ",,"
			cTexAcer := StrTran(cTexAcer,",,","")
		EndIf

  		If Right(cTexAcer,1) == ","
			cTexAcer := Left(cTexAcer,Len(cTexAcer)-1)
		EndIf

	EndIf

EndIf

Return(cTexAcer)



User Function MCAliInDic(cAlVld)

Local aArea     := GetArea()
Local aAreaSX2  := SX2->(GetArea())
Local aAreaSX3  := SX3->(GetArea())
Local lRet		:= .F.

SX2->(dbSetOrder(1))
SX3->(dbSetOrder(1))
lRet := (SX2->(dbSeek(cAlVld)) .And. SX3->(dbSeek(cAlVld)))

SX3->(RestArea(aAreaSX3))
SX2->(RestArea(aAreaSX2))
RestArea(aArea)

Return(lRet)




User Function MCReMsgE(aAutoErro)

Local cMsg	:= ""
Local nPx	:= 0
Local cCpox	:= ""
Local nTotV	:= 0
Local nFor1	:= 0

If Len(aAutoErro) >= 2

	cCpox := ' - '+alltrim(substr(aAutoErro[1],at('_',aAutoErro[1])-2,10))
	nPx		:= ascan(aAutoErro,{|W| cCpox$W })

	If nPx <= 0
		nPx := ascan(aAutoErro,{|W| '< -- '$W })
	EndIf

EndIf

nTotV := Iif(Len(aAutoErro)>20,20,Len(aAutoErro))

For nFor1 := 1 to nTotV

	If ! Empty(Alltrim(STRTRAN(STRTRAN(aAutoErro[nFor1],"'",'"'),'---','')))
		cMsg += alltrim(STRTRAN(STRTRAN(aAutoErro[nFor1],"'",'"'),'---',''))+CRLF
	EndIf

Next nFor1

If nPx > 0
	cMsg	+= alltrim(STRTRAN(STRTRAN(aAutoErro[nPx],"'",'"'),'---',''))+CRLF
EndIf

Return(cMsg)



User Function MCSeqSX6(cParSeq,nTamSeq)

Local cSeqRet := Replicate("0",nTamSeq-1)+"1"

If Select("SX6") <= 0
	dbUseArea( .T.,, "SX6990", "SX6", .T., .F. ) 
EndIf

SX6->(dbSetOrder(1))
If ! SX6->(dbSeek(xFilial("SX6")+cParSeq,.T.))
	RecLock("SX6",.T.)
	SX6->X6_FIL		 	:= xFilial("SX6")
	SX6->X6_VAR 		:= cParSeq
	SX6->X6_TIPO 		:= "C"
	SX6->X6_DESCRIC	:= "Sequencial do Parâmetro "+cParSeq
	SX6->X6_DESC1		:= ""
	SX6->X6_CONTEUD	:= cSeqRet
	SX6->X6_PROPRI		:= "U"
	SX6->X6_PYME		:= "S"
	MsUnlock()
Else
	cSeqRet := SOMA1(Left(SX6->X6_CONTEUD,nTamSeq),nTamSeq)
	RecLock("SX6",.F.)
	SX6->X6_CONTEUD	:= cSeqRet
	MsUnlock()
EndIf

Return(cSeqRet)



User Function FCOM8ReF()

Local cFils            := ""
Local nXi                   := 0
//Local j                   := 0
Local nXj				:= 0
// --------------------------------------------------------------------------
// SIGAPSW.PRW:RSWRET()      Retorna um vetor com informacoes do ultimo usuario ou
//                                                                                          grupo posicionado pela funcao PswSeek.
// RSWRET()[2][6]                          Vetor contendo as empresas, cada elemento contem a
//                                                                                          empresa e a filial. Ex:"9901", se existir "@@@@"
//                                                                                          significa acesso a todas as empresas.
// --------------------------------------------------------------------------

aPswUser := PswRet()
PswOrder( 2 )
PswSeek( aPswUser[1][2], .T. )

// Prioriza informacao do grupo?
If (ValType(aPswUser ) == "A" ) .And. (aPswUser[2][11])
	
	For nXi := 1 To Len(aPswUser[1][10])

		// Pesquisa o(s) Grupo(s) que o Usuario participa
		PswOrder(1)

		If PswSeek(aPswUser[1][10][nXi],.F.)

			aPswGrupo := FwGrpEmp(aPswUser[1][10][nXi])

			If (ValType(aPswGrupo) == "A")

				For nXj := 1 To Len(aPswGrupo)

					If aPswGrupo[nXj] == "@@@@"
						cFils := "@@"
						Exit
					ElseIf SubStr(aPswGrupo[nXj],1,2) == cEmpAnt
						If SubStr(aPswGrupo[nXj], 3, 4 ) <> "0100"
							cFils += SubStr( aPswGrupo[nXj], 3, 4 ) + "/"
						EndIf
					EndIf

				Next nXj

			EndIf

		EndIf

	Next nXi

// Prioriza Informacao do Usuario

Else
	
	If (ValType(aPswUser) == "A")

		For nXi := 1 To Len(aPswUser[2][6])

			If aPswUser[2][6][nXi] == "@@@@"
				cFils := "@@"
				Exit
			ElseIf SubStr( aPswUser[2][6][nXi],1,2) == cEmpAnt
				If SubStr(aPswUser[2][6][nXi],3,Len(aPswUser[2][6][nXi])) <> "0100"
					cFils += SubStr( aPswUser[2][6][nXi], 3, Len(aPswUser[2][6][nXi]) ) + "/"
				EndIf
			EndIf

		Next nXi

	EndIf

EndIf

Return cFils



User Function TSEGMSEG()

Local nHH, nMM , nSS, nMS := seconds()

nHH := int(nMS/3600) 
nMS -= (nHH*3600) 
nMM := int(nMS/60) 
nMS -= (nMM*60) 
nSS := int(nMS) 
nMS := (nMs - nSS)*1000 

Return strzero(nHH,2)+":"+strzero(nMM,2)+":"+strzero(nSS,2)+"."+strzero(nMS,3) 



User Function FBusFil(cnpjempr)
**********************************************************************
* Retorna a Filial conforme o CNPJ
***

Local cCodEmp	:= SM0->M0_CODIGO
Local cRetFil	:= SM0->M0_CODFIL
Local nRecM0	:= SM0->(Recno()) 

SM0->(dbSetOrder(1))
SM0->(dbSeek(cCodEmp))

While SM0->(!Eof()) .And. SM0->M0_CODIGO == cCodEmp

	If AllTrim(SM0->M0_CGC) == cnpjempr 
		cRetFil := SM0->M0_CODFIL
		EXIT
	EndIf

	SM0->(dbSkip())

EndDo	

SM0->(dbGoTo(nRecM0))

Return(cRetFil)



User Function F3MOTBX() 

Local aRet		:= {}       //Array do retorno da opcao selecionada
Local oDlg                  //Objeto Janela
Local oLbx                  //Objeto List box
Local cTitulo   := "TIPOS DE BAIXA"
//Local cNoCpos   := ""   
Local lRet 		:= .F.
Local aF3MBX	:= ReadMotBx()
Local aMotOK	:= {}
Local nXX		:= 0.00

If Len(aF3MBX) > 0

	For nXX := 1 To Len(aF3MBX)
		
		If ascan(aMotOK,Left(aF3MBX[nXX],3)+"-"+SubStr(aF3MBX[nXX],7,10)) == 0
			AADD(aMotOK,Left(aF3MBX[nXX],3)+"-"+SubStr(aF3MBX[nXX],7,10))
		Endif

	Next nXX 

	DEFINE MSDIALOG oDlg TITLE cTitulo FROM 0,0 TO 240,500 PIXEL
	
   @ 10,10 LISTBOX oLbx FIELDS HEADER "TIPO BAIXA"  SIZE 230,95 OF oDlg PIXEL	
	
   oLbx:SetArray(aMotOK)
   oLbx:bLine     := {|| {aMotOK[oLbx:nAt]}}
   oLbx:bLDblClick := {|| {oDlg:End(), aRet := {oLbx:aArray[oLbx:nAt]}}}

	DEFINE SBUTTON FROM 107,213 TYPE 1 ACTION (oDlg:End(), aRet := {oLbx:aArray[oLbx:nAt]})  ENABLE OF oDlg

	ACTIVATE MSDIALOG oDlg CENTER
	 
	If Len(aRet) > 0
		lRet := .T.
		cRetBXTI := aRet[01]
	EndIf
	
EndIf	

Return lRet



User Function SEQATF(cProcura,cTpSeq,cTpRot,nTamPL)

Local aArea   	:= GetArea()
//Local cPrxNATF	:= "0001"
Local xSeque	:= 0
Local cCodNew	:= ""

Default nTamPL	:= 6

/*
If Select("TMPN1") > 0
	dbSelectArea("TMPN1")
	dbCloseArea()
Endif
*/
If cTpRot == "G" .Or. cTpSeq == "CB"

	dbSelectArea("SN1")
	dbSetOrder(1)
	dbSeek(xFilial("SN1")+cProcura,.T.)
	
	While ! SN1->(Eof()) .And. SN1->N1_FILIAL == xFilial("SN1") .And. Substr(SN1->N1_CBASE,1,2)= cProcura
		xSeque := Val(Substr(SN1->N1_CBASE,3,4))
		dbSelectArea("SN1")
		dbSkip()		
	End Do
	xSeque ++
	xSeque := Strzero(xSeque,6-(len(cProcura)))        
	  
	While .T.
		cCodNew := cProcura + xSeque
		dbSelectArea("SN1")
		dbSetOrder(1)
		
		If ! dbSeek(xFilial("SN1")+cCodNew)
			Exit
		Else
			xSeque := VAL(xSeque)+1                      
			xSeque := Strzero(xSeque,6-(len(cProcura)))        
		EnDif
		
		Loop
		
	EndDo
/*
	cQuery := "" 
	cQuery += CRLF + " SELECT MAX(SUBSTRING(N1.N1_CBASE,3,4))+1 AS N1_PRXCBAS "
	cQuery += CRLF + " FROM "+RetSqlName("SN1")+" N1 "
	cQuery += CRLF + " WHERE N1.D_E_L_E_T_ = '' "
	cQuery += CRLF + " AND N1.N1_FILIAL = '"+xFilial("SN1")+"' "
	cQuery += CRLF + " AND SUBSTRING(N1.N1_CBASE,1,2) = '"+cProcura+"' "

	If TcSqlExec(cQuery) <> 0
		cMsgErro :=  "ERRO SQL "+TCSqlError()
		cMsgErro += CRLF + "CONSULTA SQL"
		cMsgErro += CRLF + cQuery
		U_MAviso(cMsgErro,"ERRO CONSULTA SQL")
		Return(.F.)
	Else

		dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),"TMPN1",.F.,.T.)

		TMPN1->(dbGoTop())

		If TMPN1->(! Eof())

			cPrxNATF := StrZero(TMPN1->N1_PRXCBAS,4)

		EndIf

	EndIf
*/
Else

	dbSelectArea("SN1")
	dbSetOrder(2)
	dbSeek(xFilial("SN1")+cProcura,.T.)
	
	While ! SN1->(Eof()) .And. SN1->N1_FILIAL == xFilial("SN1") .And. Substr(SN1->N1_CHAPA,1,2)= cProcura
		xSeque := Val(Left(SN1->N1_CHAPA,nTamPL))
		dbSelectArea("SN1")
		dbSkip()		
	End Do
	xSeque ++
	xSeque := Strzero(xSeque,nTamPL)
	  
	While .T.
		dbSelectArea("SN1")
		dbSetOrder(2)
		
		If ! dbSeek(xFilial("SN1")+xSeque)
			Exit
		Else
			xSeque := VAL(xSeque)+1                      
			xSeque := Strzero(xSeque,nTamPL)        
		EnDif
		
		Loop
		
	EndDo
	
/*
	cQuery := "" 
	cQuery += CRLF + " SELECT MAX(N1.N1_CHAPA)+1 AS N1_PRXCHAP "
	cQuery += CRLF + " FROM "+RetSqlName("SN1")+" N1 "
	cQuery += CRLF + " WHERE N1.D_E_L_E_T_ = '' "
	cQuery += CRLF + " AND N1.N1_FILIAL = '"+xFilial("SN1")+"' "
	cQuery += CRLF + " AND N1.N1_GRUPO = '"+cProcura+"' "

	If TcSqlExec(cQuery) <> 0
		cMsgErro :=  "ERRO SQL "+TCSqlError()
		cMsgErro += CRLF + "CONSULTA SQL"
		cMsgErro += CRLF + cQuery
		U_MAviso(cMsgErro,"ERRO CONSULTA SQL")
		Return(.F.)
	Else

		dbUseArea(.T.,"TOPCONN",TCGenQry(,,cQuery),"TMPN1",.F.,.T.)

		TMPN1->(dbGoTop())

		If TMPN1->(! Eof())

			cPrxNATF := StrZero(TMPN1->N1_PRXCHAP,nTamPL)

		EndIf

	EndIf
*/
EndIf

/*
If Select("TMPN1") > 0
	dbSelectArea("TMPN1")
	dbCloseArea()
Endif
*/

 //Restaurando área armazenada
 RestArea(aArea)

Return(xSeque)