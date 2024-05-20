
#Include "TOTVS.CH"
#Include "RESTFUL.CH"
#Include "tbiconn.ch"
#Include "topconn.ch"

#Define STR_PULA		Chr(13)+Chr(10)


/*
==========================================================================
|Func : APISKP()                                                         |
|Desc : Repete a execução da CONSAPI enquanto houverem registros         |
|Autor: Carolina Tavares --- 23/01/2024                                  |
==========================================================================
*/
USER FUNCTION APISKP()
	Local nCount   := 250
	Private nSkip  := 0

	While nCount = 250

		nCount := CONSAPI()
		nSkip := nSkip + 250
	EndDo


RETURN

/*
==========================================================================
|Func : CONSAPI()                                                        |
|Desc : Consome APi e grava os respectivos campos nas tabelas SF2 e SD2  |
|Autor: Carolina Tavares --- 22/01/2024                                  |
|Obs:	Para o ambiente de produção: Aumentar o tamanho dos campos       |
|	 	A1_NOME E A1_EMAIL PARA 70 CARACTERES;                           |
|   	Cadastrar as tabela ZA2 e ZA3 que estão em desenvolvimento.      |
==========================================================================
*/

static Function CONSAPI()

	Local cBaseUrl := "https://evo-integracao.w12app.com.br/"
	Local cPath    := 'api/v1/invoices/get-invoices'
	Local cRet     := '{ "itens": '
	Local dDataIni
	Local dDataFim
	Local cParams
	Local cAuth
	Local oJson
	Private nConta := 0

	RPCSetType(3) //Não consome licensas
	//RpcSetEnv("99", "01", , , , GetEnvServer(), { })//prepara o ambiente
	RpcSetEnv("01", "0101", , , , GetEnvServer(), { })//prepara o ambiente

	dDataIni := Escape(fwTimeStamp(6, ddatabase-1))
	dDataFim := Escape(fwTimeStamp(6, ddatabase-1))
	cParams  := "competencyDateStart="+dDataIni+"&competencyDateEnd="+dDataFim+"&take=250"+"&skip="+cValToChar(nSkip)
	cAuth    := GetMV("MV_APITOKE", , "c2VsZml0OkM1RkRDNEUzLUUyNkEtNEZDQi04NTMwLUVDNjI4N0EyQzI3MA==")

	oJson  := JsonObject():New()
	oParse := JsonObject():New()

	//issueDateStart=2023-01-22T13%3A12%3A46.286Z&issueDateEnd=2023-01-22T13%3A12%3A46.286Z&take=1&skip=0 //exemplo

	//Cabeçalho
	aHeader := {}
	aAdd(aHeader, 'accept: application/json')
	aAdd(aHeader, 'Authorization: Basic ' + cAuth) //colocar o token em um parâmetro

	//Monta a conexão com o servidor REST
	oRestClient := FWRest():New(cBaseUrl) // Ex.: "http://aaaaaaa/v1"
	oRestClient:setPath(cPath) // Ex.: "/produtos"
	oRestClient:SetGetParams(cParams)

	//Publica a alteração, e caso não dê certo, mostra erro
	If ! oRestClient:GET(aHeader,cParams)

	Else
		//Transforma o resultado da consulta em Json
		result := oRestClient:GetResult()
		cRet += result + '}'
		ret := oJson:FromJson(cRet)
		if ValType(ret) == "C"
			return
		Else
			//Chama a função pra ler os itens e fazer o execauto de cada um
			lerJSON(oJson)
			FreeObj(oJson)
		EndIf

	EndIf

	RpcClearEnv()   //Libera o Ambiente

Return nConta

static function lerJSON(jsonObj)
	local i, j
	local names
	local item
	Local aCabSF2 := {}
	Local aIteSD2 := {}
	Local aLinha  := {}
	Local cTES    := GetMV('MV_APITES',,'501') //incluir no configurador
	Local cCFOP   := GetMV('MV_APICF' ,,'5933') //incluir no configurador
	Local cProd   := GetMV('MV_APICOD',,'13060052')

	Local cCli    := ""
	Local cLoja   := ""
	Local nValor  := 0
	Local nFilial := 0

	Local lAutoriz := .F.

	names := jsonObj:GetNames()
	If len(names) == 1 .AND. names[1] == 'itens'
		item := jsonObj[names[1]]
		for j := 1 to len(item)
			lerJSON(item[j])
		next
	Else

		aAdd(aCabSF2,{"F2_TIPO"    ,  "N"            ,	Nil})
		aAdd(aCabSF2,{"F2_ESPECIE" ,  "NF"           ,	Nil})

		aadd(aLinha,{"D2_ITEM",'01'   , Nil}) //só há um item
		aadd(aLinha,{"D2_COD" , cProd , Nil}) //código fixo
		aadd(aLinha,{"D2_TES" , cTES  , Nil}) //precisa incluir o parametro com a TES
		aadd(aLinha,{"D2_CF"  , cCFOP , Nil}) //precisa incluir o parametro com a cfop

		for i := 1 to len(names)
			item := jsonObj[names[i]]
			DO CASE
			CASE names[i] == 'status'
				lAutoriz := (Alltrim(item) == "Autorizada") 

			CASE names[i] == 'dataCriacao'
				//formato da api -> 2023-01-22T12:28:28
				cData := substr(item,1,10)
				cData := sTod(replace(cData, '-',''))
				aadd(aCabSF2, {"F2_EMISSAO", cData, Nil})

			CASE names[i] == 'cliente'
				cCgc := item['cpfCnpj']
				DbSelectArea('SA1')
				SA1->(DbSetOrder(3))
				SA1->(DbGoTop())
				If SA1->(DbSeek(FWxFilial("SA1") + cCgc)) //A1_FILIAL + A1_CGC
					cCli  := SA1->A1_COD
					cLoja := SA1->A1_LOJA
					aadd(aCabSF2, {"F2_CLIENTE", SA1->A1_COD , Nil})
					aadd(aCabSF2, {"F2_LOJA"   , SA1->A1_LOJA, Nil})
					aAdd(aCabSF2, {"F2_TIPOCLI", SA1->A1_TIPO, Nil})

					SA1->(DbCloseArea())
				Else
					aRet := MATA030INC(item) //cadastra um novo cliente
					aadd(aCabSF2, {"F2_CLIENTE", aRet[1], Nil})
					aadd(aCabSF2, {"F2_LOJA"   , aRet[2], Nil})
					aAdd(aCabSF2, {"F2_TIPOCLI", aRet[3], Nil})

				EndIf

			CASE names[i] == 'numero' .And. lAutoriz
				If len(item) > 9
					aadd(aCabSF2, {"F2_DOC", RIGHT(item,9), Nil})
				Else
					aadd(aCabSF2, {"F2_DOC", item, Nil})
				EndIf

			CASE names[i] == 'serieRps' .And. lAutoriz
				aadd(aCabSF2, {"F2_SERIE", item, Nil})

			CASE names[i] == 'valorTotal'
				nValor := item
				aadd(aLinha,{"D2_QUANT" ,1   , Nil}) // a quantidade é unica
				aadd(aLinha,{"D2_PRCVEN",item, Nil})
				aadd(aLinha,{"D2_TOTAL" ,item, Nil})
			CASE names[i] == 'idFilial'
				DbSelectArea('ZA2') //ZA2 -> Correspondencia entre filiais da api e protheus
				ZA2->(DbSetOrder(1))//FILIAL+IDAPI
				ZA2->(DbGoTop())
				If ZA2->(DbSeek(FWxFilial("ZA2") + cValToChar(item) ))
					aadd(aLinha, {"D2_FILIAL", ZA2->ZA2_IDFILI, Nil})
					aAdd(aCabSF2,{"F2_FILIAL", ZA2->ZA2_IDFILI,	Nil})
				Else // caso não encontre nenhuma filial e não gerar erro
					nFilial := PADL(item,4,'0')
					aadd(aLinha, {"D2_FILIAL", nFilial, Nil})
					aAdd(aCabSF2,{"F2_FILIAL", nFilial,	Nil})
				EndIf


			ENDCASE
		next i

		aadd(aIteSD2, aLinha)

		/* MATA920 */
		IF lAutoriz
			MATA920INC(aCabSF2, aIteSD2)
		EndIF 

		cFilAnt := "0101" //volta pra filial original

		nConta += 1

	EndIf
return


static Function MATA920INC(aCabSF2, aIteSD2)
	Local nAux    := 0
	Local cLogAtu := ""
	Local cDirLog := '\system\' //falta definir
	Local cNomLog := 'erroMata920.log'  //falta definir

	aArea := SF2->(GetArea())
	DbSelectArea("SF2")
	SF2->(DbSetOrder(1)) //Posiciona no indice 1
	SF2->(DbGoTop())

	cFilAnt := aCabSF2[9][2] //troca a filial de acordo com o retorno da API

	If !SF2->(DbSeek(aCabSF2[9][2] + aCabSF2[7][2])) //verifica se já há um registro com essas informações
		//Iniciando transação
		Begin Transaction

			lMsErroAuto 	:= .F.
			lAutoErrNoFile	:= .T.
			l920Inclui		:= .T.

			MSExecAuto({|x, y, z| Mata920(x, y, z)}, aCabSF2, aIteSD2, 3)
			
			DbSelectArea("ZA3") //ZA3 -> guarda as informações das notas que não foram incluidas para serem conferidas posteriormente

			//Se houver erro
			If lMsErroAuto

				//Pegando log do ExecAuto
				aLogAuto := GetAutoGRLog()
				For nAux := 2 To Len(aLogAuto)
					cLogAtu += aLogAuto[nAux] + STR_PULA
				Next
				MemoWrite(cDirLog+cNomLog, cLogAtu)
				
				If !ZA3->(DbSeek(FWxFilial('ZA3') + aCabSF2[7][2] ))
					If RecLock('ZA3',.T.)
						ZA3->ZA3_FILIAL := FWxFilial('ZA3')
						ZA3->ZA3_NOTA   := aCabSF2[7][2]
						ZA3->ZA3_DATA   := (ddatabase - 1)
						ZA3->ZA3_ORDEM  := (nSkip + nConta)
						ZA3->ZA3_MOTIVO := substr(cLogAtu, 1, 100)
						ZA3->(MsUnlock())
					EndIf

				EndIf
				
				DisarmTransaction()
			Else
				
				If !ZA3->(DbSeek(FWxFilial('ZA3') + aCabSF2[7][2] ))
					If RecLock('ZA3',.T.)
						ZA3->ZA3_FILIAL := FWxFilial('ZA3')
						ZA3->ZA3_NOTA   := aCabSF2[7][2]
						ZA3->ZA3_DATA   := (ddatabase - 1)
						ZA3->ZA3_ORDEM  := (nSkip + nConta)
						ZA3->(MsUnlock())
					EndIf
				EndIf

			EndIf
		End Transaction
	EndIf
	SF2->(DbCloseArea())
	RestArea(aArea)

return

static function MATA030INC(aCli)
	Local lDeuCerto := .F.
	Local cQry      := ''
	Local cCodMun   := ''
	Local aRet      := {}
	Local cCod      := ""
	Local cCli      := Upper(FwNoAccent(DecodeUtf8(aCli["endereco"]["cidade"])))
	Local cEnd      := Upper(FwNoAccent(DecodeUtf8(aCli["endereco"]["logradouro"])))
	Local cbairro   := Upper(FwNoAccent(DecodeUtf8(aCli["endereco"]["bairro"])))
	Local cNome     := Upper(FwNoAccent(DecodeUtf8(aCli["nome"])))

	cQry := "SELECT CC2_CODMUN FROM " + RetSqlName("CC2")
	cQry += " WHERE CC2_MUN = '" +FwNoAccent(DecodeUtf8(aCli["endereco"]["cidade"]))+"'"
	MpSysOpenQuery(cQry, "CC2")

	cCodMun := CC2->CC2_CODMUN

	CC2->(DbCloseArea())

	//Os códigos de clientes seguem uma sequencia
	cQry2 := "SELECT SA1.A1_COD AS COD FROM " + RetSqlName("SA1") +" SA1"
	cQry2 += " ORDER BY SA1.A1_COD DESC"
	MpSysOpenQuery(cQry2, "SA1")

	//Pegando o último código e somando 1 garante que o código não seja repetido
	SA1->(DbGoTop())
	cCod := PADL((Val(SA1->COD) + 1),6,'0')

	SA1->(DbCloseArea())

	//Pegando o modelo de dados, setando a operação de inclusão
	oModel := FWLoadModel("MATA030")
	oModel:SetOperation(3)
	oModel:Activate()


	//Pegando o model dos campos da SA1
	oSA1Mod:= oModel:getModel("MATA030_SA1")
	oSA1Mod:setValue("A1_COD",       cCod        ) // Codigo
	oSA1Mod:setValue("A1_LOJA",      '01'       ) // Loja
	oSA1Mod:setValue("A1_NOME",      cNome) // Nome
	oSA1Mod:setValue("A1_NREDUZ",    substr(cNome,1,20)   ) // Nome reduz.
	oSA1Mod:setValue("A1_END",       cEnd  ) // Endereco
	oSA1Mod:setValue("A1_BAIRRO",    cbairro     ) // Bairro
	oSA1Mod:setValue("A1_TIPO",      "F"        ) // Tipo
	oSA1Mod:setValue("A1_EST",       aCli["endereco"]['uf']        ) // Estado
	oSA1Mod:setValue("A1_COD_MUN",   cCodMun     ) // Codigo Municipio
	oSA1Mod:setValue("A1_MUN",       cCli    ) // Municipio
	oSA1Mod:setValue("A1_CEP",       aCli["endereco"]["cep"]        ) // CEP
	//oSA1Mod:setValue("A1_INSCR",     cIE         ) // Inscricao Estadual
	oSA1Mod:setValue("A1_CGC",       aCli["cpfCnpj"]       ) // CNPJ/CPF
	//oSA1Mod:setValue("A1_PAIS",      "105"   ) // Pais
	oSA1Mod:setValue("A1_EMAIL",     aCli["email"]      ) // E-Mail
	//oSA1Mod:setValue("A1_DDD",       substr(aCli["telefone"],1,2)        ) // DDD
	//oSA1Mod:setValue("A1_TEL",       substr(aCli["telefone"],3)   ) // Fone
	oSA1Mod:setValue("A1_PESSOA",    aCli['tipoPessoa']  ) // Tipo Pessoa
	oSA1Mod:setValue("A1_CONTA",    "11201008            "  ) // Tipo Pessoa

	//Se conseguir validar as informações
	If oModel:VldData()

		//Tenta realizar o Commit
		If oModel:CommitData()
			lDeuCerto := .T.

			//Se não deu certo, altera a variável para false
		Else
			lDeuCerto := .F.
		EndIf

		//Se não conseguir validar as informações, altera a variável para false
	Else
		lDeuCerto := .F.
	EndIf

	//Se não deu certo a inclusão, mostra a mensagem de erro
	If ! lDeuCerto
		//Busca o Erro do Modelo de Dados
		aErro := oModel:GetErrorMessage()

		//Monta o Texto que será mostrado na tela
		AutoGrLog("Id do formulário de origem:"  + ' [' + AllToChar(aErro[01]) + ']')
		AutoGrLog("Id do campo de origem: "      + ' [' + AllToChar(aErro[02]) + ']')
		AutoGrLog("Id do formulário de erro: "   + ' [' + AllToChar(aErro[03]) + ']')
		AutoGrLog("Id do campo de erro: "        + ' [' + AllToChar(aErro[04]) + ']')
		AutoGrLog("Id do erro: "                 + ' [' + AllToChar(aErro[05]) + ']')
		AutoGrLog("Mensagem do erro: "           + ' [' + AllToChar(aErro[06]) + ']')
		AutoGrLog("Mensagem da solução: "        + ' [' + AllToChar(aErro[07]) + ']')
		AutoGrLog("Valor atribuído: "            + ' [' + AllToChar(aErro[08]) + ']')
		AutoGrLog("Valor anterior: "             + ' [' + AllToChar(aErro[09]) + ']')

		RollBackSX8()

		//Pra evitar erro de array out of bounds
		aAdd(aRet, ' ')
		aAdd(aRet, ' ')
		aAdd(aRet, ' ')

		//Mostra a mensagem de Erro
		//MostraErro()
	Else
		aAdd(aRet, cCod)
		aAdd(aRet, '01')
		aAdd(aRet, 'F')
		confirmSx8 ()

	EndIf

//Desativa o modelo de dados
	oModel:DeActivate()
return aRet


