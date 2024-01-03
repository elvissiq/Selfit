#include "TOTVS.ch"
#Include "PROTHEUS.ch"
#Include "TopConn.ch"
#Include "RWMAKE.ch"
#Include "FILEIO.ch"
#Include "TBICONN.ch"
#Include "TBICODE.ch"

#Define _cMsgPadrao "SELFIT - SFCMP10"

/*============================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			15/02/2022
Consultoria: 	PROX
Uso: 			SELFIT
Info: 			Ticket 21875 Inclusão de Solicitação de Compras através de Importação de arquivo
*=============================================================================================*/
User Function SFCMP10()

Private _cArqCSV

SC1->( DbSetOrder(1))

// ativa os atalhos do Help da rotina
Versao(.T.)

_cArqCSV := cGetFile("(*.csv) | *.csv | " , OemToAnsi("Arquivo de Solicitação de Compras") , , , .F. , GETF_LOCALHARD) 

if Empty(_cArqCSV)
	RETURN
Endif

if ! File(_cArqCSV)
	MsgAlert("Arquivo não localizado.", _cMsgPadrao)
	RETURN
Endif	

if MsgYesNo("Confirma a geração da Solicitação de Compras ?")
	oProcess := MsNewProcess():New( {|| ProcessaCSV( oProcess )} )
	oProcess:Activate()
Endif

// ativa os atalhos do Help da rotina
Versao(.F.)

Return

/*============================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			15/02/2022
Consultoria: 	PROX
Uso: 			SELFIT
Info: 			Importacao do arquivo CSV
*=============================================================================================*/
Static Function ProcessaCSV( oProcess )
Local lOk := .T.
Local _nG

if lOk
	oFile := FWFileReader():New(_cArqCSV)
	if !(oFile:Open())
		MsgAlert("Falha na abertura do arquivo.", _cMsgPadrao)
		lOk := .F.
	Endif
Endif

if lOk
	oProcess:SetRegua2( 6 ) 

	oProcess:IncRegua2("Carregando o Dicionário da tabela...") 

	// indices do vetor de dicionario da tabela SC1
	posTitulo  := 1
	posCampo   := 2
	posTipo    := 3
	posTamanho := 4
	posValid   := 5
	posVldUser := 6
	posRelacao := 7
	posContext := 8
	posVisual  := 9

	// carrega os dados do dicionario da SC1
	aCpoSC1 := {}
	SX3->( DbSetOrder(1))
	SX3->( Dbseek("SC1"))
	Do While SX3->( ! Eof()) .and. SX3->X3_ARQUIVO = "SC1"
		Aadd(aCpoSC1, {Alltrim(SX3->X3_TITULO), Alltrim(SX3->X3_CAMPO), Alltrim(SX3->X3_TIPO), SX3->X3_TAMANHO, Alltrim(SX3->X3_VALID), Alltrim(SX3->X3_VLDUSER), Alltrim(SX3->X3_RELACAO),Alltrim(SX3->X3_CONTEXT),Alltrim(SX3->X3_VISUAL)} )
		SX3->( Dbskip())
	Enddo

	oProcess:IncRegua2("Lendo dados do arquivo CSV ...") 
	aVetDados := {}
	aVetErro  := {}
	_aCabec   := {}
	aItemSC1  := {}  // dados dos itens da acols
	_nLinha   := 0
	Do while lOk .and. oFile:hasLine()
		_cLinha := oFile:GetLine()+";"
		_cLinha := Strtran(Strtran(StrTran(StrTran(_cLinha,";;","; ;"),";;","; ;"),";;","; ;"),";;","; ;")

		if "Item da SC" $ _cLinha .or. "Produto" $ _cLinha .or. "Quantidade" $ _cLinha .or. "Prc Estimado" $ _cLinha .or. Empty(_cLinha) .or. Len(aCabec) == 0
			aCabec := StrtoKarr(_cLinha,";")
			Loop
		Endif	

		if Empty(_cLinha) .or. Len(aCabec) == 0
			Loop
		Endif	

		aDados := StrtoKarr(_cLinha,";")
		_nLinha++

		// campos que devem ser incluidos no processo
		cIncluir := "C1_PRODUTO/C1_QUANT/C1_PRECO/C1_VUNIT/C1_CC/C1_OBS/C1_FORNECE/C1_LOJA/C1_DESCRIC/C1_CODCOMP/C1_XENTRE/"

		cIngorar := "ITEM DA SC;ALIAS WT;RECNO WT/NUM.SOLIC.IM/TIPO OP/CLASSE VALOR/SEQ MRP/GER.PROJETOS/ELIM.RESIDUO/QTD.ORIGINAL/ITEM GRADE/GRADE/"+;
					"TIPO SOLICIT/MODALIDADE/TIPO MODAL/CTR CONTRATO/NO ORCAMENTO/ATUAL.ESTOQ/PROGRAMA PRD/COD. EDITAL/NR. PROCESSO/RATEIO/REV.ESTRUTUR/"+;
					"PED. VENDA/PRECO COT/DT.ENV.EMAIL/DT FIM PROC/DT INI PROC/HR FIM PROC/HR INI PROC/CLASSIF.?/FILIAL CONT/PREFIXO/STATUS GCT/"+;
					"CONTR. PRECO/GRUPO APROV./NUM CONTRATO/REVISAO CT./REQUISITANTE/N. ADIT. CON/TIPO SC/N. PLANILHA/IT. PLANILHA/"


		// numero do item
		aLinhaC1 := {}
		Aadd(aLinhaC1,{"C1_ITEM" ,StrZero(_nLinha,len(SC1->C1_ITEM)),Nil})

		aLinhaSC1 := {}
		For _nG := 1 to Len(aCabec)
			// ignora as colunas em branco e colunas fora do dicionario
			if Empty(aCabec[_nG]) .or. Upper(aCabec[_nG]) $ cIngorar
				Loop
			Endif	

			// localiza o campo no dicionario
			posCpoSC1 := Ascan(aCpoSC1,{|e| Upper(e[1]) == Upper(aCabec[_nG])})
			if posCpoSC1 == 0
				MsgAlert("Campo '"+aCabec[_nG]+" na coluna "+CValToChar(_nG)+" não localizado na Tabela de Solicitação de Compras")
				lOk := .F.
				Exit
			Endif

			// o campo Item já foi incluido antes do loop
			if aCpoSC1[posCpoSC1,posCampo] == "C1_ITEM"
				Loop
			Endif	

			if aCpoSC1[posCpoSC1,posContext] == "V" // ignora campos virtuais
				Loop
			Endif

			// ignora as colunas em branco e colunas fora do dicionario
			if aCpoSC1[posCpoSC1,posCampo] $ cIncluir
				if _nG <= Len(aDados)
					if aCpoSC1[posCpoSC1,posTipo] == "N"
						uDado := Val(aDados[_nG])
					Elseif aCpoSC1[posCpoSC1,posTipo] == "D"	
						if aCpoSC1[posCpoSC1,posCampo] $ "C1_XENTRE"
							uDado := Date()
						Else 
							uDado := Ctod(aDados[_nG])
						Endif
					Else
						if aCpoSC1[posCpoSC1,posCampo] $ "C1_LOCAL/C1_FORNECE/C1_LOJA/"
							if Val(aDados[_nG]) > 0
								uDado := Strzero(Val(aDados[_nG]),aCpoSC1[posCpoSC1,posTamanho])
							Else	
								uDado := aDados[_nG]
							Endif
	//						__cReadVar := cVar := "M->"+aCpoSC1[posCpoSC1,posCampo]+" := '"+aDados[_nG]+"' "
	//						&cVar
						Elseif aCpoSC1[posCpoSC1,posCampo] == "C1_DESCRIC"//  .and. Empty(aDados[_nG])
							uDado := aDados[_nG]
							if Empty(uDado)
								posPrd := Ascan(aLinhaC1,{|e| e[1] == "C1_PRODUTO"})
								cProduto := Padr(aLinhaC1[posPrd,2],Len(SB1->B1_COD))
								SB5->( Dbseek( xFilial("SB1")+ cProduto))
								uDado := SB5->B5_CEME
							Endif	
						Elseif Empty(aDados[_nG]) .and. ! Empty(aCpoSC1[posCpoSC1,posRelacao]) 
							uDado := &(aCpoSC1[posCpoSC1,posRelacao])
						Else
							uDado := aDados[_nG]
						Endif
					Endif

					if X3Obrigat(aCpoSC1[posCpoSC1,posCampo] ) .and. Empty(uDado)
						MsgAlert("Campo '"+Alltrim(aCabec[_nG])+" é obrigatório mas está vazio na planilha")
						lOk := .F.
						Exit
					Endif

 					if ! Empty(uDado)
						Aadd(aLinhaC1,{aCpoSC1[posCpoSC1,posCampo], uDado,Nil})
					Endif	
				Endif	
			Else
				teste := 1	
			Endif
		Next
		Aadd(aItemSC1, Aclone(aLinhaC1))

	Enddo
	oFile:Close()
Endif

if lOk
	oProcess:IncRegua2("Validando dados do arquivo CSV ...") 
	
	// analisar os dados básicos

Endif

If lOk
	cNumSc := GetSXENum("SC1","C1_NUM")
	SC1->(dbSetOrder(1))
	While SC1->(dbSeek(xFilial("SC1")+cNumSc))
		ConfirmSX8()
		cNumSc := GetSXENum("SC1","C1_NUM")
	EndDo

	oProcess:IncRegua2("Incluindo Solicitação de Compras: "+cNumSc) 

	// Monta cabecalho da SC
	aCabSC   := {}
	Aadd(aCabSC,{"C1_NUM",		cNumSc})
	Aadd(aCabSC,{"C1_SOLICIT",	cUserName})
	Aadd(aCabSC,{"C1_EMISSAO",	dDataBase})
 
	Begin Transaction

		Private lMsHelpAuto := .T.
		PRIVATE lMsErroAuto := .F.

		MSExecAuto({|x,y| mata110(x,y)},aCabSC,aItemSC1)

		If lMsErroAuto
			MostraErro()
			DisarmTransaction()
		Else	
			MsgAlert("Solicitação incluida: "+cNumSc,_cMsgPadrao)
		Endif
	End Transaction

Endif

Return(.T.)


/*====================================================================================
Autor: 			Aldo Barbosa dos Santos
Data: 			11/02/2022
Consultoria: 	Prox
Uso: 			CARSON
Info: 			Exibição do Help da rotina
*=====================================================================================*/
Static Function Versao(lAtiva)
Local aHelp030 := {}
Local _cHelp   := ""
Local _nR
Local _lHtml := .F.

if lAtiva == Nil // exibicao do help
	Versao(.F.)  // desativa os atalhos do Help da rotina

	Aadd(aHelp030,"SFCMP10 - Importação de Dados para Solicitação de Compras v1.00 25-02-2022")
	Aadd(aHelp030,"")
	Aadd(aHelp030,"Utilização da Rotina:")
	Aadd(aHelp030,"  - Selecionar a planilha (formato CSV separator ponto-e-vírgula)")
	Aadd(aHelp030,"  - Confirmar a importação")
	Aadd(aHelp030,"")
	Aadd(aHelp030,"  Após a importação da planilha, será exibida uma mensagem. Esta mensagem pode ser de sucesso (será exibido o número da solicitação), ou de falha (que informará o motivo do problema)")
	Aadd(aHelp030,"")

	Aadd(aHelp030,"Validações da Rotina:")
	Aadd(aHelp030,"  1. As seguintes colunas serão importadas para a Solicitação de Compras>")
	Aadd(aHelp030,"     'Produto', 'Quantidade', 'Prc Unitario', 'Prc Estimado', 'Centro Custo', 'Observacao', 'Fornecedor','Loja do Forn','DescComplem','Cod. Comprad','Previsa Entr'")
	Aadd(aHelp030,"  2. O restante dos campos serão preenchidos automaticamente")
	Aadd(aHelp030,"  3. A primeira linha do arquivo deve ser a linha de cabeçalho")
	Aadd(aHelp030,"")
	
	Aadd(aHelp030,"Ajustes realizados:")
	Aadd(aHelp030,"")
	Aadd(aHelp030," 22-02-2022 Criação da Rotina")
	Aadd(aHelp030,"")

	// coloca as quebras de linha e os espacos no formato HTML ou Texto
	For _nR := 1 to Len(aHelp030)
		if _lHtml
			_cVarTxt := Strtran(Strtran(Strtran(aHelp030[_nR],"   ","&nbsp;&nbsp;&nbsp;"),"  ","&nbsp;&nbsp;")," ","&nbsp;")
			_cHelp += "<BR>"+_cVarTxt
		Else
			_cVarTxt := Strtran(StrTran(aHelp030[_nR],"<B>",""),"</B>","")
			_cHelp   += Chr(13)+Chr(10)+_cVarTxt
		Endif	
	Next

	DEFINE MSDIALOG oDlgHlp TITLE "Help da Rotina" FROM C(264),C(469) TO C(676),C(1010) PIXEL

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

