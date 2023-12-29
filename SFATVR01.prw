#INCLUDE "Protheus.ch"
#INCLUDE "Topconn.ch"
#INCLUDE "DBINFO.CH"

Static cFtnPad := "SFATVR01"
Static cTitRel := "Posição Valorizada SELFIT"
Static cDesRel := "Esta rotina permite gerar uma planilha com a Posição Valorizada por Data dos Bens."
Static _cVersao := cFtnPad+" v1.01"
Static _cDtVersao := "19-05-2022"

Static aComboATF

/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			19/05/2022
Consultoria: 	Prox
Uso: 			SELFIT
Info: 			Relatório de Posição Valorizada do Ativo - Selfit
*=====================================================================================*/
User Function SFATVR01()
Local oFont1014N := TFont():New("Arial",10,14,,.T.,,,,.T.,.F.)

Private aSelFil	:= {}		// seleção de filiais
Private aSelMoed:= {"01"}	// seleção de moedas

Private aSelClass:= {} 
Private lTodasFil:= .F.
Private cPerg   := "AFR072"

Private aStrut     := Estrutura()  // carrega a estrutura do relatorio
Private oFWMsExcel := Nil

SN1->( Dbsetorder(1))
SA2->( Dbsetorder(1))

// ativa os atalhos do Help da rotina
Versao(.T.)

if Parametros(.T.)
	DEFINE MSDIALOG oDlg FROM 264,182 TO 430,700 TITLE cTitRel OF oDlg PIXEL
		@ 004,010 TO 070,190 LABEL "" OF oDlg PIXEL

		@ 015,017 SAY "Este programa emitirá a posição "		OF oDlg PIXEL Size 190,010 FONT oFont1014N COLOR CLR_HBLUE
		@ 030,017 SAY "valorizada analítica dos bens por data"	OF oDlg PIXEL Size 190,010 FONT oFont1014N COLOR CLR_HBLUE
		@ 045,017 SAY "conforme parâmetros"						OF oDlg PIXEL Size 190,010 FONT oFont1014N COLOR CLR_HBLUE

		@ 06,210 BUTTON "&Gera Excel" 	SIZE 036,012 ACTION if(Parametros(.F.),PrtAnalitico(),Nil) OF oDlg PIXEL
		@ 26,210 BUTTON "&Parâmetros"	SIZE 036,012 ACTION Parametros(.T.)   OF oDlg PIXEL
		@ 46,210 BUTTON "Sai&r"    		SIZE 036,012 ACTION oDlg:End()     OF oDlg PIXEL
	ACTIVATE MSDIALOG oDlg CENTERED
Endif

Versao(.F.)

Return


/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			19/05/2022
Consultoria: 	Prox
Uso: 			SELFIT
Info: 			Validação dos parâmetros do relatório
*=====================================================================================*/
Static Function Parametros(lExibe)
Local lRet := .T.
Default lExibe := .T.

Pergunte( cPerg , .F. )

if lExibe 
	lRet := Pergunte( cPerg , lExibe )
Endif

If lRet
	If mv_par20 == 1 .And. Len( aSelFil ) <= 0
		aSelFil := AdmGetFil(@lTodasFil)
		If Len( aSelFil ) <= 0
			MsgAlert("Os parâmetros informados exigem a escolha de pelo menos uma filial.", cFtnPad)
			lRet := .F.
		EndIf
	EndIf
Endif

If lRet
	If mv_par03 == 1  // .and. Len(aSelMoed) <= 0
		MsgAlert("O parâmetro de Seleção de Moedas foi desabilitado para a geração deste relatório.", cFtnPad)
		SetMVValue(cPerg,"MV_PAR03",2) 
		aSelMoed:= {"01"}
	EndIf
Endif
if lRet
	//Seleciona as classificacoes patrimoniais
	If mv_par26 == 1 .And. Len( aSelClass ) <= 0
		aSelClass := AdmGetClas()
		If Len( aSelClass ) <= 0
			MsgAlert("Os parâmetros informados exigem a escolha de pelo menos uma Classificacao Patrimonial.", cFtnPad)
			lRet := .F.
		EndIf 
	EndIf
Endif
if lRet
	//Valida o Tipo de Saldo
	If !VldTpSald( MV_PAR25, .T. )
		MsgAlert("Tipo de saldo inválido.", cFtnPad)
		Return
	EndIf
Endif

if ! lRet
	MsgAlert("Falha no preenchimento dos parâmetros. Preencha corretamente antes de gerar o relatório.", cFtnPad)
Endif

Return( lRet )	


/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			19/05/2022
Consultoria: 	Prox
Uso: 			SELFIT
Info: 			Impressão do relatório de Posição Valorizada do Ativo
*=====================================================================================*/
Static Function PrtAnalitico()
Local nR 

Local oMeter
Local oText
Local oDlg
Local lEnd
Local cAliasQry  := GetNextAlias()
Local dDataSLD   := MV_PAR01
Local dAquIni	 := MV_PAR04
Local dAquFim    := MV_PAR05
Local cBemIni    := MV_PAR06
Local cBemFim    := MV_PAR08
Local cItemIni   := MV_PAR07
Local cItemFim   := MV_PAR09
Local cContaIni  := MV_PAR12
Local cContaFim  := MV_PAR13
Local cCCIni   	 := MV_PAR14
Local cCCFim   	 := MV_PAR15
Local cItCtbIni	 := MV_PAR16
Local cItCtbFim	 := MV_PAR17
Local cClvlIni	 := MV_PAR18
Local cClVlFim	 := MV_PAR19
Local cGrupoIni	 := MV_PAR10
Local cGrupoFim	 := MV_PAR11
Local nTipoTotal := MV_PAR24
Local cTipoSLD	 := MV_PAR25
Local cChave	 := ""
Local aTipo		 := {}                     
Local cDescSld	 := ""
Local lRealProv	 := .T.
Local cArquivo   := GetTempPath()+cFtnPad+".xml"
Local uConteudo  := ""

aSelMoed := IIF(Empty(aSelMoed), {"01"} , aSelMoed )

If nTipoTotal == 1 //Fiscal
	aTipo := ATFXTpBem(1,.T.)
ElseIf nTipoTotal == 2 //Gerencial
	aTipo := ATFXTpBem(2,.T.)
ElseIf nTipoTotal == 3 //Incentivada
	aTipo := ATFXTpBem(3,.T.)
EndIf

//Ordem do Arquivo
cChave := "FILIAL+CONTA+CCUSTO+CBASE+ITEM+TIPO+SEQ+SEQREAV+MOEDA"

// Verificacao do campo para ativos de custo de provisao
DbSelectArea("SN3")
lRealProv := (MV_PAR27 == 1)

//Monta Arquivo Temporario para Impressao
MsgMeter({|	oMeter, oText, oDlg, lEnd | ;
			ATFGERSLDM(	oMeter,oText,oDlg,lEnd,cAliasQry,dAquIni,dAquFim,dDataSLD,cBemIni,cBemFim,cItemIni,cItemFim,cContaIni,cContaFim,;
						cCCIni,cCCFim,cItCtbIni,cItCtbFim,cClvlIni,cClVlFim,cGrupoIni,cGrupoFim,aSelMoed,aSelFil,lTodasFil,cChave,.T.,;
						aTipo,Nil,Nil,cTipoSLD,aSelClass,lRealProv) },;
						OemToAnsi(OemToAnsi("Gerando informações do relatório ...")),; 
						OemToAnsi("Processando..."))
/*
FILIAL CBASE ITEM MOEDA	CLASSIF TIPO DESC_SINT AQUISIC DTBAIXA DTSALDO CHAPA GRUPO CONTA CCUSTO SUBCTA CLVL QUANTD ORIGINAL AMPLIACAO ATUALIZ DEPRECACM
RESIDUAL CORRECACM CORDEPACM VLBAIXAS
*/

//Descricao do tipo de saldo
SX5->(MsSeek(xFilial("SX5") + "SL"+ IIF(Empty(cTipoSLD),'1',cTipoSLD) ))
cDescSld := Alltrim(SX5->(X5Descri()))

//Criando o objeto que irá gerar o conteúdo do Excel
oFWMsExcel := FWMSExcel():New()

// gravando os parametros na aba
cAbaPar := "PARAMETROS"
cTitPar := "Parâmetros do Relatório"
oFWMsExcel:AddworkSheet(cAbaPar) //Não utilizar número junto com sinal de menos. Ex.: 1-
oFWMsExcel:AddTable(cAbaPar,cTitPar)
oFWMsExcel:AddColumn(cAbaPar,cTitPar,"Parâmetro",1)
oFWMsExcel:AddColumn(cAbaPar,cTitPar,"Conteúdo"	,1)

SX1->( Dbseek(cPerg))
Do While SX1->( ! Eof()) .and. Alltrim(SX1->X1_GRUPO) == cPerg
	uConteudo := &(Alltrim(SX1->X1_VAR01))
	if ValType(uConteudo) == "D"
		uConteudo := Dtoc(uConteudo)
	elseif ValType(uConteudo) == "N"
		uConteudo := CValToChar(uConteudo)		
	Endif	
	oFWMsExcel:AddRow(cAbaPar,cTitPar,{SX1->X1_PERGUNT, uConteudo})
	SX1->( Dbskip())
Enddo

// inicio da aba do relatorio
cAbaExcel := "RELATORIO"
cTitExcel := "Relatório de Posição Valorizada Ativo na Data - SELFIT"
oFWMsExcel:AddworkSheet(cAbaExcel) //Não utilizar número junto com sinal de menos. Ex.: 1-

//Criando a Tabela
oFWMsExcel:AddTable(cAbaExcel,cTitExcel)

// Criando as Colunas ro relatorio
For nR := 1 to Len(aStrut)
	oFWMsExcel:AddColumn(cAbaExcel,cTitExcel,aStrut[nR,1],aStrut[nR,2],aStrut[nR,3])
//                      cWorkSheet, cTable  ,  cColumn   , nAlign     , nFormat     , lTotal
Next

// Orderna de acordo com a Ordem do relatorio
(cAliasQry)->( dbGoTop())
Do While (cAliasQry)->(!EOF()) 
	// carrega cada linha da planilha
	aLinha := {}
	For nR := 1 to Len(aStrut)
		uDado := Eval(aStrut[nR,4])
		Aadd(aLinha, uDado)
	Next
	oFWMsExcel:AddRow(cAbaExcel,cTitExcel,aLinha)

	(cAliasQry)->( Dbskip())
EndDo

(cAliasQry)->( DbcloseArea())

//Ativando o arquivo e gerando o xml
oFWMsExcel:Activate()
oFWMsExcel:GetXMLFile(cArquivo)
		 
//Abrindo o excel e abrindo o arquivo xml
oExcel := MsExcel():New()             //Abre uma nova conexão com Excel
oExcel:WorkBooks:Open(cArquivo)     //Abre uma planilha
oExcel:SetVisible(.T.)                 //Visualiza a planilha
oExcel:Destroy()                        //Encerra o processo do gerenciador de tarefas

Return


/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			19/05/2022
Consultoria: 	Prox
Uso: 			SELFIT
Info: 			Estrutura de geração do relatório
*=====================================================================================*/
Static Function Estrutura()
Local aStrut := {}

Aadd(aStrut, {"Filial"			 ,1,	1, {|| (cAliasQry)->FILIAL		}}) // 01
Aadd(aStrut, {"Cod Base Bem"	 ,1,	1, {|| (cAliasQry)->CBASE		}}) // 02
Aadd(aStrut, {"Conta contábil"	 ,1,	1, {|| (cAliasQry)->ITEM		}}) // 03
Aadd(aStrut, {"Fornecedor"		 ,1,	1, {|| Localiza("FORNECE",(cAliasQry)->FILIAL,(cAliasQry)->CBASE,(cAliasQry)->ITEM)	}}) // 04
Aadd(aStrut, {"Cod. Nota Fiscal" ,1,	1, {|| Localiza("NOTA"   ,(cAliasQry)->FILIAL,(cAliasQry)->CBASE,(cAliasQry)->ITEM)	}}) // 05
Aadd(aStrut, {"Codigo Item"		 ,1,	1, {|| (cAliasQry)->ITEM		}}) // 06
Aadd(aStrut, {"Tipo Ativo"		 ,1,	1, {|| (cAliasQry)->TIPO		}}) // 07
Aadd(aStrut, {"Descricao Tipo"	 ,1,	1, {|| Posicione("SX5",1, xFilial("SX5")+"G1"+(cAliasQry)->TIPO,"X5Descri()")			}}) // 08
Aadd(aStrut, {"Tipo Depr."		 ,1,	1, {|| GetAdvFVal("SN0","N0_DESC01",xFilial("SN0")+"04"+GetAdvFVal("SN3","N3_TPDEPR",(cAliasQry)->(FILIAL+CBASE+ITEM+TIPO+FLAGBAIXA+SEQ))) }}) // 09
Aadd(aStrut, {"Classificac."	 ,1,	1, {|| X3ATF('N1_PATRIM',(cAliasQry)->CLASSIF) }}) // 10
Aadd(aStrut, {"Descr. Sint."	 ,1,	1, {|| (cAliasQry)->DESC_SINT	}}) // 11
Aadd(aStrut, {"Dt.Aquisicao"	 ,2,	4, {|| (cAliasQry)->AQUISIC		}}) // 12
Aadd(aStrut, {"Dt.de Baixa"		 ,2,	4, {|| (cAliasQry)->DTBAIXA		}}) // 13
Aadd(aStrut, {"Quantidade"		 ,3,	2, {|| (cAliasQry)->QUANTD		}}) // 14
Aadd(aStrut, {"Num.Plaqueta"	 ,1,	1, {|| (cAliasQry)->CHAPA		}}) // 15
Aadd(aStrut, {"Tipo Saldo"		 ,2,	1, {|| cDescSld					}}) // 16
Aadd(aStrut, {"Conta"			 ,1,	1, {|| (cAliasQry)->CONTA		}}) // 17
Aadd(aStrut, {"C Custo Bem"		 ,1,	1, {|| (cAliasQry)->CCUSTO		}}) // 18
Aadd(aStrut, {"Item do Bem"		 ,1,	1, {|| (cAliasQry)->SUBCTA		}}) // 19
Aadd(aStrut, {"Cl Vlr Bem"		 ,1,	1, {|| (cAliasQry)->CLVL		}}) // 20
Aadd(aStrut, {"Valor Original"	 ,3,	2, {|| (cAliasQry)->ORIGINAL	}}) // 21
Aadd(aStrut, {"Val Amplia"		 ,1,	1, {|| (cAliasQry)->AMPLIACAO	}}) // 22
Aadd(aStrut, {"Valor Atualizado" ,3,	2, {|| (cAliasQry)->ATUALIZ		}}) // 23
Aadd(aStrut, {"Deprec. Acumulada",3,	2, {|| (cAliasQry)->DEPRECACM	}}) // 24
Aadd(aStrut, {"Valor Residual"	 ,3,	2, {|| (cAliasQry)->RESIDUAL 	}}) // 25
Aadd(aStrut, {"Cor Dep Acum"	 ,3,	2, {|| (cAliasQry)->CORDEPACM	}}) // 26
Aadd(aStrut, {"Corr Acum M1"	 ,3,	2, {|| (cAliasQry)->CORRECACM	}}) // 27
Aadd(aStrut, {" "				 ,1,	1, {|| Space(1)					}}) // 27
//              Coluna          Align  Format              Conteudo
// Align  = 1-Left,2-Center,3-Right
// Format = 1-General,2-Number,3-Monetário,4-DateTime
Return( aStrut )


/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			19/05/2022
Consultoria: 	Prox
Uso: 			SELFIT
Info: 			Tratamento de campos que não estão no arquivo temporario
*=====================================================================================*/
Static Function Localiza(cCampo, cFil, cBase, cItem)
Local cRet := "nao loc."

SN1->( Dbsetorder(1))  // N1_FILIAL+N1_CBASE+N1_ITEM
SN1->( Dbseek(cFil+cBase+cItem))

if cCampo == "FORNECE"
	cRet := SN1->N1_FORNEC+"-"+SN1->N1_LOJA+" "+Posicione("SA2",1,xFilial("SA2")+SN1->N1_FORNEC+SN1->N1_LOJA,"A2_NOME")
Elseif cCampo == "NOTA"
	cRet := SN1->N1_NFISCAL
Endif	

Return( cRet )


/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			19/05/2022
Consultoria: 	Prox
Uso: 			SELFIT
Info: 			Função para tratamendo dos campo do tipo combo
*=====================================================================================*/
Static Function X3ATF(cCampo, cCombo)
Local cDescription	:= ""
Local nPosicao1		:= 0

Default cCampo := ''
Default cCombo := ''

If aComboATF == NIL
	aComboATF := GetComboATF(cCampo, cCombo)
Endif

nPosicao1 := aScan(aComboATF,{|x| AllTrim(x[1]) == AllTrim(cCombo) })

If ( nPosicao1 <> 0 )
	cDescription := AllTrim(aComboATF[nPosicao1][2])
EndIf

Return cDescription


/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			19/05/2022
Consultoria: 	Prox
Uso: 			SELFIT
Info: 			Função para tratamendo dos campo do tipo combo
*=====================================================================================*/
Static Function GetComboATF(cCampo, cCombo)
Local aArea    := GetArea()		//Guarda a area atual
Local cBox     := ""			//Conteudo do ComboBox
Local aBox     := {}			//Array com os dados do Combo
Local nPosicao1:= 0				//Posicao 1 no array aBox
Local nPosicao2:= 0				//Posicao do "=" na string

Default cCampo := ''
Default cCombo := ''

DbSelectArea("SX3")
DbSetOrder(2)
If ( DbSeek(cCampo) )
	cBox  := X3CBox()
	While ( !Empty(cBox) )
		nPosicao1   := At(";",cBox)
		If ( nPosicao1 == 0 )
			nPosicao1 := Len(cBox)+1
		EndIf
		nPosicao2   := At("=",cBox)
		aadd(aBox,{ StrTran(SubStr(cBox,1,nPosicao2-1),"&"),SubStr(cBox,nPosicao2+1,nPosicao1-nPosicao2-1) })
		cBox := SubStr(cBox,nPosicao1+1)
	EndDo
EndIf
DbSelectArea("SX3")
DbSetOrder(1)
RestArea(aArea)

Return(aBox)


/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			20/04/2022
Consultoria: 	Prox
Uso: 			HLB
Info: 			Exibição do Help da rotina
*=====================================================================================*/
Static Function Versao(lAtiva)
Local aHelpVer := {}
Local _cHelp   := ""
Local _nR
Local _lHtml := .F.

if lAtiva == Nil // exibicao do help
	Versao(.F.)  // desativa os atalhos do Help da rotina

	Aadd(aHelpVer,cTitRel+"  "+_cVersao+" "+_cDtVersao)
	Aadd(aHelpVer,"")
	Aadd(aHelpVer,cDesRel)
	Aadd(aHelpVer,"")
	Aadd(aHelpVer,"Esta rotina gera uma planilha Excel contendo os bens valorizados conforme os parâmetros informados.")
	Aadd(aHelpVer,"")
	Aadd(aHelpVer,"Será apresentada uma janela com um botão que permite ajustar os parâmetros e outro botão que permite gerar a planilha Excel")
	Aadd(aHelpVer,"")
	Aadd(aHelpVer,"Restrições:")
	Aadd(aHelpVer," - O parâmetro 'Tipo' não será considera para a geração do relatório sendo sempre 'Analítico'.")
 	Aadd(aHelpVer," - O parâmetro 'Seleciona Moedas' também não será considerado, sendo sempre gerado em Reais.")
	Aadd(aHelpVer," - Os parâmetros 'Folha inicial', 'Folha Final', 'No.Pag. Reiniciar' não serão considerados pois se trata de geração em planilha.")
	Aadd(aHelpVer,"")
	Aadd(aHelpVer,"O relatório será gerado na pasta temporária da máquina do usuário e será aberto no excel (caso o aplicativo esteja instalado).")
	Aadd(aHelpVer,"")
	Aadd(aHelpVer,"A planilha Excel gerada será composta de duas abas: ")
	Aadd(aHelpVer," - Aba Parâmetros : Parâmetros utilizados para gerar o relatório")
	Aadd(aHelpVer," - Aba Relatório  : Dados do relatório")
	Aadd(aHelpVer,"")
	Aadd(aHelpVer,"  ATENÇÃO: Não haverá quebras nem totalizadores no novo relatório.")
	Aadd(aHelpVer,"")
	Aadd(aHelpVer,"Ajustes realizados:")
	Aadd(aHelpVer,"")
	Aadd(aHelpVer," 17-05-2022 Desenvolvimento da rotina .")
	Aadd(aHelpVer,"")

	// coloca as quebras de linha e os espacos no formato HTML ou Texto
	For _nR := 1 to Len(aHelpVer)
		if _lHtml
			_cVarTxt := Strtran(Strtran(Strtran(aHelpVer[_nR],"   ","&nbsp;&nbsp;&nbsp;"),"  ","&nbsp;&nbsp;")," ","&nbsp;")
			_cHelp += "<BR>"+_cVarTxt
		Else
			_cVarTxt := Strtran(StrTran(aHelpVer[_nR],"<B>",""),"</B>","")
			_cHelp   += Chr(13)+Chr(10)+_cVarTxt
		Endif	
	Next

	DEFINE MSDIALOG oDlgHlp TITLE "Help da Rotina "+cFtnPad FROM C(264),C(469) TO C(676),C(1010) PIXEL

		// Cria Componentes Padroes do Sistema
		@ C(002),C(002) GET oMemo1 Var _cHelp MEMO When .F. Size C(266),C(186) PIXEL OF oDlgHlp
		@ C(191),C(230) Button "Ok" Size C(037),C(012) Action (oDlgHlp:End()) PIXEL OF oDlgHlp
		
	ACTIVATE MSDIALOG oDlgHlp CENTERED 

	Versao(.T.) // ativa os atalhos do Help da rotina

Elseif lAtiva 
	//Ativo os atalhos do Help da rotina
	SetKey(K_CTRL_F1, {|| Versao() })
	SetKey(K_ALT_F1 , {|| Versao() })
	SetKey(K_SH_F1  , {|| Versao() })

Elseif ! lAtiva
	//Ativo os atalhos do Help da rotina
	SetKey(K_CTRL_F1, Nil )
	SetKey(K_ALT_F1 , Nil )
	SetKey(K_SH_F1  , Nil )
Endif

Return

