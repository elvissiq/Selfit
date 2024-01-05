#INCLUDE 'TOTVS.CH'
#INCLUDE "TBICONN.CH"
#INCLUDE "XMLXFUN.CH"

#DEFINE ENTER  Chr(13)

/*/{Protheus.doc} MA920MNU

Disponibilizado ponto de entrada na rotina Nota Fiscal Manual de Saída (MATA920) para customização do menu de opções antes da abertura da tela.
Este ponto de entrada pode ser utilizado para inserir novas opções no array aRotina.

@type function
@author TOTVS Nordeste (Elvis Siqueira)
@since 05/01/2024

@history 
/*/
User Function MA920MNU()

     aadd(aRotina,{'Importar Notas Fiscais','U_MA920AUT' , 0 , 3,2,NIL})
  
Return 

/*/{Protheus.doc} MA920AUT
Importação MATA920 - Documentos Fiscais de Saída
@type function
@version 
@author TOTVS Nordeste (Elvis Siqueira)
@since 05/01/2024
@return
/*/
User Function MA920AUT()

     Private aFiles := {}
     Private cDirEsp := ""
     Private cBarra := IIF(GetRemoteType() == 1,"\","/")

     cDirEsp := TFileDialog( "Arquivo XML (*.xml)",,,, .F., GETF_RETDIRECTORY ) 
     aFiles := Directory(cDirEsp+cBarra+"*.xml")
     
     IF ValType(aFiles) == "A" .AND. Len(aFiles) > 0
          
        Processa( {|| ProcesXML()}, "Processando...", "Aguarde...")
		
     EndIF 

Return

/*------------------------------------------------------------------------------*
 | Func:  ProcesXML                                                             |
 | Desc:  Ler e converte os arquivos XML para JSON e iniciar a inclusão das NFs |
 | Obs.:  /                                                                     |
 *-----------------------------------------------------------------------------*/

Static Function ProcesXML()

	Local oRest := Nil
    Local aCabeca := {}
	Local aLinhaIt := {}
    Local aItens := {}
	Local aLogError := {}
	Local aHeader := {}
	Local aLoadSM0 := FWLoadSM0()
	Local cTESVend := SuperGetMV("SE_TESVEND",.F.,"509")
	Local cTESReme := SuperGetMV("SE_TESREME",.F.,"542")
	Local cTESDevo := SuperGetMV("SE_TESDEVO",.F.,"551")
	Local cTESUtil := ""
	Local cJson := ""
	Local cAuxFil := cFilAnt
	Local cCodCli := ""
	Local cLojCli := ""
	Local lRetFil := .F.
	Local nY, nX 

	Private oJson := Nil
    Private lMsErroAuto := .F.
	Private lAutoErrNoFile := .T.
	Private lMsHelpAuto :=.T.
	
	ProcRegua(Len(aFiles))

    For nY := 1 To Len(aFiles)
        
		IncProc("Processando arquivo " + cValToChar(nY) + " de " + cValToChar(Len(aFiles)) + "...")

		aAdd(aHeader, 'Content-Type: Application/XML')
		oRest := FwRest():New("https://v1.nocodeapi.com/elvissiqueira/xml_to_json/RJbWTtucvMScRlSF/")
		oRest:SetPath("data2json")
		oRest:SetPostParams(MemoRead(cDirEsp+cBarra+aFiles[nY][01])) 

		If oRest:Post(aHeader)
			cJson := oRest:GetResult()
			oJson := JsonObject():New()
			cJson := oJson:FromJson(cJson)
		Else 
			Aviso('Atenção', "Erros: "+oRest:GetLastError(), {'Ok'}, 03)
		EndIF 
		
		// ================================================================================================================
		//Loga na filial conforme Emitente do XML
		For nX := 1 To Len(aLoadSM0)
			If Alltrim(aLoadSM0[nX][18]) == Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["emit"]["cnpj"])
				lRetFil := .T.
				If Alltrim(aLoadSM0[nX][2]) != cFilAnt
					cFilAnt := Alltrim(aLoadSM0[nX][2])
				EndIF  
			EndIF 
		Next
		
		IF !lRetFil
			FWAlertError("Não foi possível encontrar uma filial cadastrada com o CNPJ: "+;
						 Transform(oJson["nfeproc"]["nfe"]["infnfe"]["emit"]["cnpj"],"@R 99.999.999/9999-99");
						 ,'Pesquisa Filial (Função: ProcesXML, contida no fonte "MA920MNU.prw")')
			Loop
		EndIF 
		
		// ================================================================================================================

		// ================================================================================================================
		//Verifica se o cliente existe na base, caso não exista incluí
		cCodCli := ""
		cLojCli := ""
		DBSelectArea("SA1")
		SA1->(DBSetOrder(3))
		If !SA1->(MsSeek(FWxFilial("SA1")+Pad(oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["cpf"],FwTamSX3("A1_CGC")[1])))
			
			xCadCli() //Função para cadastro do cliente que não existe na base

			If SA1->(MsSeek(FWxFilial("SA1")+Pad(oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["cpf"],FwTamSX3("A1_CGC")[1])))

				cCodCli := SA1->A1_COD
				cLojCli := SA1->A1_LOJA

			EndIF 
		Else 
			cCodCli := SA1->A1_COD
			cLojCli := SA1->A1_LOJA
		EndIF 
		// ================================================================================================================

		// ================================================================================================================
		//Identifica a TES a ser utilizada na inclusão da NF
		cTESUtil := ""
		Do Case
			Case "Venda" $ (Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["ide"]["natop"]))
				cTESUtil := cTESVend
			Case "Remessa" $ (Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["ide"]["natop"]))
				cTESUtil := cTESReme
			Case "Devolucao" $ (Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["ide"]["natop"]))
				cTESUtil := cTESDevo
		End Case 
		// ================================================================================================================

		If !Empty(cCodCli) .AND. !Empty(cLojCli)
			
			aCabeca   := {}
			aLinhaIt  := {}
			aItens    := {}

			Do CASE
				Case Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["ide"]["mod"]) == "55"
					cEspec := "SPED"
				Case Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["ide"]["mod"]) == "65"
					cEspec := "NFCE"
			End CASE 

			aAdd(aCabeca,{ "F2_TIPO"    , "N"                                                                                , Nil })
			aAdd(aCabeca,{ "F2_FORMUL"  , "N"     																			 , Nil })
			aAdd(aCabeca,{ "F2_DOC"     , StrZero( Val(oJson["nfeproc"]["nfe"]["infnfe"]["ide"]["nnf"]) , 9)                 , Nil })
			aAdd(aCabeca,{ "F2_SERIE"   , Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["ide"]["serie"])  						 , Nil })
			aAdd(aCabeca,{ "F2_EMISSAO" , FwDateTimeToLocal(Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["ide"]["dhemi"]),0)[1] , Nil })
			aAdd(aCabeca,{ "F2_CLIENTE" , cCodCli 																			 , Nil })
			aAdd(aCabeca,{ "F2_LOJA"    , cLojCli 																		     , Nil })
			aAdd(aCabeca,{ "F2_ESPECIE" , cEspec  																		     , Nil })
			aAdd(aCabeca,{ "F2_HORA"    , FwDateTimeToLocal(Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["ide"]["dhemi"]),0)[2] , Nil })
			aAdd(aCabeca,{ "F2_BASEICM" , Val(Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["total"]["icmstot"]["vbc"]))         , Nil })
			aAdd(aCabeca,{ "F2_VALICM"  , Val(Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["total"]["icmstot"]["vicms"])) 		 , Nil })
			aAdd(aCabeca,{ "F2_BASPIS"  , Val(Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["total"]["icmstot"]["vbc"]))		 , Nil })
			aAdd(aCabeca,{ "F2_VALPIS"  , Val(Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["total"]["icmstot"]["vpis"])) 		 , Nil })
			aAdd(aCabeca,{ "F2_BASCOFI" , Val(Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["total"]["icmstot"]["vbc"])) 		 , Nil })
			aAdd(aCabeca,{ "F2_VALCOFI" , Val(Alltrim(oJson["nfeproc"]["nfe"]["infnfe"]["total"]["icmstot"]["vcofins"])) 	 , Nil })

			If Len(oJson["nfeproc"]["nfe"]["infnfe"]["det"]) > 0

				For nX := 1 To Len(oJson["nfeproc"]["nfe"]["infnfe"]["det"])
					aLinhaIt := {}
					aAdd(aLinhaIt,{"D2_ITEM"   	, StrZero( Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["$"]["nItem"]) , 2) 					, Nil })
					aAdd(aLinhaIt,{"D2_COD"    	, oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["prod"]["cprod"]                 					, Nil })
					aAdd(aLinhaIt,{"D2_QUANT"  	, Val( oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["prod"]["qcom"] )           					, Nil })
					aAdd(aLinhaIt,{"D2_PRCVEN" 	, Val( oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["prod"]["vuncom"] )         					, Nil })
					aAdd(aLinhaIt,{"D2_TOTAL"  	, Val( oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["prod"]["vprod"] )          					, Nil })
					aAdd(aLinhaIt,{"D2_TES"    	, cTESUtil     															       						, Nil })
					aAdd(aLinhaIt,{"D2_CF"     	, oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["prod"]["cfop"]				   						, Nil })
					aAdd(aLinhaIt,{"D2_DESCON" 	, oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["prod"]["vdesc"]				   						, Nil })
					aAdd(aLinhaIt,{"D2_BASEICM"	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["imposto"]["icms"]["icms00"]["vbc"])				, Nil })
					aAdd(aLinhaIt,{"D2_PICM"   	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["imposto"]["icms"]["icms00"]["picms"])			, Nil })
					aAdd(aLinhaIt,{"D2_VALICM" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["imposto"]["icms"]["icms00"]["vicms"])			, Nil })
					aAdd(aLinhaIt,{"D2_BASEPIS"	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["imposto"]["pis"]["pisaliq"]["vbc"])			   	, Nil })
					aAdd(aLinhaIt,{"D2_ALQPIS" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["imposto"]["pis"]["pisaliq"]["ppis"])			, Nil })
					aAdd(aLinhaIt,{"D2_VALPIS" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["imposto"]["pis"]["pisaliq"]["vpis"])			, Nil })
					aAdd(aLinhaIt,{"D2_BASECOF" , Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["imposto"]["cofins"]["cofinsaliq"]["vbc"])		, Nil })
					aAdd(aLinhaIt,{"D2_ALQCOF" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["imposto"]["cofins"]["cofinsaliq"]["pcofins"])	, Nil })
					aAdd(aLinhaIt,{"D2_VALCOF" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"][nX]["imposto"]["cofins"]["cofinsaliq"]["vcofins"])	, Nil })

					aAdd(aItens,aLinhaIt)
				Next 

			Else
				aLinhaIt := {}
				aAdd(aLinhaIt,{"D2_ITEM"   	, StrZero( Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["$"]["nItem"]) , 2) 					, Nil })
				aAdd(aLinhaIt,{"D2_COD"    	, oJson["nfeproc"]["nfe"]["infnfe"]["det"]["prod"]["cprod"]                 					, Nil })
				aAdd(aLinhaIt,{"D2_QUANT"  	, Val( oJson["nfeproc"]["nfe"]["infnfe"]["det"]["prod"]["qcom"] )           					, Nil })
				aAdd(aLinhaIt,{"D2_PRCVEN" 	, Val( oJson["nfeproc"]["nfe"]["infnfe"]["det"]["prod"]["vuncom"] )         					, Nil })
				aAdd(aLinhaIt,{"D2_TOTAL"  	, Val( oJson["nfeproc"]["nfe"]["infnfe"]["det"]["prod"]["vprod"] )          					, Nil })
				aAdd(aLinhaIt,{"D2_TES"    	, cTESUtil     															   						, Nil })
				aAdd(aLinhaIt,{"D2_CF"     	, oJson["nfeproc"]["nfe"]["infnfe"]["det"]["prod"]["cfop"]				   						, Nil })
				aAdd(aLinhaIt,{"D2_DESCON" 	, oJson["nfeproc"]["nfe"]["infnfe"]["det"]["prod"]["vdesc"]				   						, Nil })
				aAdd(aLinhaIt,{"D2_BASEICM"	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["imposto"]["icms"]["icms00"]["vbc"])				, Nil })
				aAdd(aLinhaIt,{"D2_PICM"   	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["imposto"]["icms"]["icms00"]["picms"])			, Nil })
				aAdd(aLinhaIt,{"D2_VALICM" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["imposto"]["icms"]["icms00"]["vicms"])			, Nil })
				aAdd(aLinhaIt,{"D2_BASEPIS"	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["imposto"]["pis"]["pisaliq"]["vbc"])			   	, Nil })
				aAdd(aLinhaIt,{"D2_ALQPIS" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["imposto"]["pis"]["pisaliq"]["ppis"])			, Nil })
				aAdd(aLinhaIt,{"D2_VALPIS" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["imposto"]["pis"]["pisaliq"]["vpis"])			, Nil })
				aAdd(aLinhaIt,{"D2_BASECOF" , Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["imposto"]["cofins"]["cofinsaliq"]["vbc"])		, Nil })
				aAdd(aLinhaIt,{"D2_ALQCOF" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["imposto"]["cofins"]["cofinsaliq"]["pcofins"])	, Nil })
				aAdd(aLinhaIt,{"D2_VALCOF" 	, Val(oJson["nfeproc"]["nfe"]["infnfe"]["det"]["imposto"]["cofins"]["cofinsaliq"]["vcofins"])	, Nil })
				aAdd(aItens,aLinhaIt)
			EndIF  

			Begin Transaction
				lMsErroAuto := .F.
				MSExecAuto({|a, b| MATA920(aCabeca,aItens)}, aCabeca, aItens, 3)
						
				If lMsErroAuto //Se ocorrer erro FWAlertError na tela para o usuario
					cErroExec := ""
					aLogError := GetAutoGRLog()

					For nX := 1 To Len(aLogError)
						If !Empty(cErroExec)
							cErroExec += CRLF
						EndIf
						cErroExec += aLogError[nX]
					Next nX
							
					FWAlertError(cErroExec,"Erro ao gravar a Nota Fiscal de Saída:")
					DisarmTransaction()
				EndIf	
			End Transaction 
		
		EndIf 
    
	Next 

	cFilAnt := cAuxFil

Return

/*------------------------------------------------------------------------------*
 | Func:  xCadCli                                                               |
 | Desc:  Realiza a inclusão dos clientes que não existem na base               |
 | Obs.:  /                                                                     |
 *-----------------------------------------------------------------------------*/

Static Function xCadCli()

	Local oModel   := Nil
  	Local oSA1Mod  := Nil
	Local aLogErro := {}
	Local cErro    := ""
	Local nY, lOk

	Private lMsErroAuto := .F.
	Private lAutoErrNoFile := .T.
	Private lMsHelpAuto :=.T.

	oModel := FWLoadModel("CRMA980")
	oModel:SetOperation(3)
	oModel:Activate()
	oSA1Mod := oModel:GetModel("SA1MASTER")

	oSA1Mod:SetValue("A1_TIPO"   , "F"                                                                      						)
    oSA1Mod:SetValue("A1_PESSOA" , IIF(Len(oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["cpf"]) > 11,"J","F")  						)
    oSA1Mod:SetValue("A1_CGC"    , oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["cpf"]                         						)
    oSA1Mod:SetValue("A1_NOME"   , Pad(oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["xnome"],FwTamSX3("A1_NOME")[1])                 	) 
    oSA1Mod:SetValue("A1_NREDUZ" , Pad(oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["xnome"],FwTamSX3("A1_NREDUZ")[1]) 				) 
    oSA1Mod:SetValue("A1_EMAIL"  , Pad(oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["email"],FwTamSX3("A1_EMAIL")[1])                 	)  
    oSA1Mod:SetValue("A1_TEL"    , oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["enderdest"]["fone"]           						)
    oSA1Mod:SetValue("A1_END"    , oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["enderdest"]["xlgr"]+" "+;
                                   oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["enderdest"]["nro"]            						)
    oSA1Mod:SetValue("A1_BAIRRO" , Pad(oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["enderdest"]["xbairro"],FwTamSX3("A1_BAIRRO")[1]) 	)
    oSA1Mod:SetValue("A1_EST"    , oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["enderdest"]["uf"]             					   	)
    oSA1Mod:SetValue("A1_COD_MUN", SubSTR(oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["enderdest"]["cmun"],3) 						)
    oSA1Mod:SetValue("A1_MUN"    , Pad(oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["enderdest"]["xmun"],FwTamSX3("A1_MUN")[1])     	)
    oSA1Mod:SetValue("A1_CEP"    , oJson["nfeproc"]["nfe"]["infnfe"]["dest"]["enderdest"]["cep"]            						)

	If oModel:VldData()
      If oModel:CommitData()
          lOk := .T.
      Else
          Ok := .F.
      EndIf
    Else
      lOk := .F.
    EndIf

	If !lOk
      	cErro := ""
		aLogErro := oModel:GetErrorMessage()

		For nY := 1 To Len(aLogErro)
			If ValType(aLogErro[nY]) != "U"
				cErro += aLogErro[nY] + CRLF
			EndIF
		Next nY
				
		FWAlertError(cErro,"Erro na tentativa de inclusão do cliente")
	EndIF 

	oModel:DeActivate()

Return
