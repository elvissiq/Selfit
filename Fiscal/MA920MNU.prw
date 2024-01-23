#INCLUDE 'TOTVS.CH'
#INCLUDE "TBICONN.CH"
#INCLUDE "XMLXFUN.CH"

#DEFINE ENTER  Chr(13)

/*/{Protheus.doc} MA920MNU

Disponibilizado ponto de entrada na rotina Nota Fiscal Manual de Saída (MATA920) para customização do menu de opções antes da abertura da tela.
Este ponto de entrada pode ser utilizado para inserir novas opções no array aRotina.

@type function
@author TOTVS Nordeste (Elvis Siqueira)
@since 10/01/2024

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
@since 10/01/2024
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
		
		FWAlertSuccess("Processo de importação de Notas Fiscais finalizado com Sucesso!","Importação de Notas Fiscais")
		
	EndIF 

Return

/*------------------------------------------------------------------------------*
 | Func:  ProcesXML                                                             |
 | Desc:  Ler e converte os arquivos XML para JSON e iniciar a inclusão das NFs |
 | Obs.:  /                                                                     |
 *-----------------------------------------------------------------------------*/

Static Function ProcesXML()

    Local aCabeca 	:= {}
	Local aLinhaIt 	:= {}
    Local aItens 	:= {}
	Local aLogError := {}
	Local aLoadSM0 	:= FWLoadSM0()
	Local cTESVend 	:= SuperGetMV("SE_TESVEND",.F.,"509")
	Local cTESReme 	:= SuperGetMV("SE_TESREME",.F.,"542")
	Local cTESDevo 	:= SuperGetMV("SE_TESDEVO",.F.,"551")
	Local cTESTran 	:= SuperGetMV("SE_TESTRAN",.F.,"581") 
	Local cTESUtil 	:= ""
	Local cProduto 	:= ""
	Local cAuxFil 	:= cFilAnt
	Local cCodCli 	:= ""
	Local cLojCli 	:= ""
	Local cCNPJCPF  := ""
	Local cErrorXML := ""
	Local cAlertXML := ""
	Local lRetFil 	:= .F.
	Local nY, nX 

	Private oXML := Nil
    Private lMsErroAuto := .F.
	Private lAutoErrNoFile := .T.
	Private lMsHelpAuto :=.T.
	
	ProcRegua(Len(aFiles))

    For nY := 1 To Len(aFiles)
        
		IncProc("Processando arquivo " + cValToChar(nY) + " de " + cValToChar(Len(aFiles)) + "...")

		oXml := XmlParser( MemoRead(cDirEsp+cBarra+aFiles[nY][01]), "_", @cErrorXML, @cAlertXML )

		If (oXml == NIL )
			Aviso('Atenção', "Falha ao gerar Objeto XML : "+cErrorXML+" / "+cAlertXML, {'Ok'}, 03)
			Loop
		Endif
		
		// ================================================================================================================
		//Loga na filial conforme Emitente do XML
		For nX := 1 To Len(aLoadSM0)
			If Alltrim(aLoadSM0[nX][18]) == Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_EMIT:_CNPJ:Text)
				lRetFil := .T.
				If Alltrim(aLoadSM0[nX][2]) != cFilAnt
					cFilAnt := Alltrim(aLoadSM0[nX][2])
				EndIF  
			EndIF 
		Next
		
		IF !lRetFil
			FWAlertError("Não foi possível encontrar uma filial cadastrada com o CNPJ: "+;
						 Transform(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_EMIT:_CNPJ:Text),"@R 99.999.999/9999-99");
						 ,'Pesquisa Filial (Função: ProcesXML, contida no fonte "MA920MNU.prw")')
			Loop
		EndIF
		
		// ================================================================================================================

		// ================================================================================================================
		//Verifica se o cliente existe na base, caso não exista incluí
		cCodCli := ""
		cLojCli := ""

		Do Case
			Case AttIsMemberOf( oXml:_NFEPROC:_NFE:_INFNFE:_DEST, "_CPF" )
				cCNPJCPF := Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_CPF:Text)
			Case AttIsMemberOf( oXml:_NFEPROC:_NFE:_INFNFE:_DEST, "_CNPJ" )
				cCNPJCPF := Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_CNPJ:Text)
		End Case 

		DBSelectArea("SA1")
		SA1->(DBSetOrder(3))
		If !SA1->(MsSeek(FWxFilial("SA1")+Pad(cCNPJCPF,FwTamSX3("A1_CGC")[1])))
			
			xCadCli(cCNPJCPF) //Função para cadastro do cliente que não existe na base

			If SA1->(MsSeek(FWxFilial("SA1")+Pad(cCNPJCPF,FwTamSX3("A1_CGC")[1])))

				cCodCli := SA1->A1_COD
				cLojCli := SA1->A1_LOJA

			EndIF 
		Else 
			cCodCli := SA1->A1_COD
			cLojCli := SA1->A1_LOJA
		EndIF 
		// ================================================================================================================

		If !Empty(cCodCli) .AND. !Empty(cLojCli)
			
			aCabeca   := {}
			aLinhaIt  := {}
			aItens    := {}

			Do CASE
				Case Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_MOD:Text) == "55"
					cEspec := "SPED"
				Case Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_MOD:Text) == "65"
					cEspec := "NFCE"
			End CASE

			aAdd(aCabeca,{ "F2_TIPO"    , "N"                                                                                			, Nil })
			aAdd(aCabeca,{ "F2_FORMUL"  , "N"     																			 			, Nil })
			aAdd(aCabeca,{ "F2_DOC"     , StrZero( Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NNF:Text)) , 9)              			, Nil })
			aAdd(aCabeca,{ "F2_SERIE"   , Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_SERIE:Text)  						 	 			, Nil })
			aAdd(aCabeca,{ "F2_EMISSAO" , FwDateTimeToLocal(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_DHEMI:Text),0)[1] 		 			, Nil })
			aAdd(aCabeca,{ "F2_CLIENTE" , cCodCli 																			 			, Nil })
			aAdd(aCabeca,{ "F2_LOJA"    , cLojCli 																		     			, Nil })
			aAdd(aCabeca,{ "F2_CLIENT" 	, cCodCli 																			 			, Nil })
			aAdd(aCabeca,{ "F2_LOJAENT" , cLojCli 																		     			, Nil })
			aAdd(aCabeca,{ "F2_ESPECIE" , cEspec  																		     			, Nil })
			aAdd(aCabeca,{ "F2_HORA"    , SubSTR(FwDateTimeToLocal(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_DHEMI:Text),0)[2],1,5)		, Nil })
			aAdd(aCabeca,{ "F2_BASEICM" , Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_TOTAL:_ICMSTOT:_VBC:Text))                 			, Nil })
			aAdd(aCabeca,{ "F2_VALICM"  , Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_TOTAL:_ICMSTOT:_VICMS:Text))		 		 			, Nil })
			aAdd(aCabeca,{ "F2_BASPIS"  , Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_TOTAL:_ICMSTOT:_VBC:Text))				 			, Nil })
			aAdd(aCabeca,{ "F2_VALPIS"  , Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_TOTAL:_ICMSTOT:_VPIS:Text))		 		 			, Nil })
			aAdd(aCabeca,{ "F2_BASCOFI" , Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_TOTAL:_ICMSTOT:_VBC:Text))				 			, Nil })
			aAdd(aCabeca,{ "F2_VALCOFI" , Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_TOTAL:_ICMSTOT:_VCOFINS:Text))		 	 			, Nil })
			aAdd(aCabeca,{ "F2_MENNOTA" , Pad(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_INFADIC:_INFCPL:Text),FwTamSX3("F2_MENNOTA")[1])		, Nil })
			aAdd(aCabeca,{ "F2_CHVNFE" 	, Alltrim(oXml:_NFEPROC:_PROTNFE:_INFPROT:_CHNFE:Text)											, Nil })
			aAdd(aCabeca,{ "F2_DAUTNFE"	, FwDateTimeToLocal(Alltrim(oXml:_NFEPROC:_PROTNFE:_INFPROT:_DHRECBTO:Text),0)[1]				, Nil })
			aAdd(aCabeca,{ "F2_HAUTNFE"	, SubSTR(FwDateTimeToLocal(Alltrim(oXml:_NFEPROC:_PROTNFE:_INFPROT:_DHRECBTO:Text),0)[2],1,5)	, Nil })

			

			If ValType(oXml:_NFEPROC:_NFE:_INFNFE:_DET) == "A"

				For nX := 1 To Len(oXml:_NFEPROC:_NFE:_INFNFE:_DET)
					
					aLinhaIt := {}

					// ==========================================================================================================================================
					//Identifica o Código do Produto para inclusão da NF
					cProduto := xPesqProd(oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD:_CPROD:Text)

					If Empty(cProduto)
						Aviso('Atenção', "A Nota Fiscal: " + StrZero( Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NNF:Text)) , 9) + " não será importada "+;
										 "devido o produto : " + oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD:_CPROD:Text + ;
										 ", não estar cadastrado. "+;
										 'Por favor solicitar o cadastro e o prenchimento do campo B1_XCODXML (Cod. XML NFe) do mesmo.', {'Ok'}, 03)
					EndIF
					// ==========================================================================================================================================

					// ==========================================================================================================================================
					//Identifica o Código do TES para inclusão da NF
					cTESUtil := xPesqTES(oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD:_CFOP:Text)
					If Empty(cTESUtil)
						Do Case
							Case "VENDA" $ (Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NATOP:Text)))
								cTESUtil := cTESVend
							Case "REMESSA" $ (Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NATOP:Text)))
								cTESUtil := cTESReme
							Case "DEVOLUCAO" $ (Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NATOP:Text)))
								cTESUtil := cTESDevo
							Case "TRANSFERENCIA" $ (Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NATOP:Text)))
								cTESUtil := cTESTran
						End Case 
					EndIF
					// ==========================================================================================================================================

					aAdd(aLinhaIt,{"D2_ITEM"   	, StrZero( Val(oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_NITEM:Text) , 2) 						, Nil })
					aAdd(aLinhaIt,{"D2_COD"    	, cProduto                 																	, Nil })
					aAdd(aLinhaIt,{"D2_QUANT"  	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD:_QCOM:Text )           					, Nil })
					aAdd(aLinhaIt,{"D2_PRCVEN" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD:_VUNCOM:Text )         					, Nil })
					aAdd(aLinhaIt,{"D2_TOTAL"  	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD:_VPROD:Text )          					, Nil })
					aAdd(aLinhaIt,{"D2_TES"    	, cTESUtil     															   					, Nil })
					aAdd(aLinhaIt,{"D2_CF"     	, oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD:_CFOP:Text						   				, Nil })
					
					//Tratamento da tag desconto
					IF AttIsMemberOf( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD, "_VDESC" )
						aAdd(aLinhaIt,{"D2_DESCON" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_PROD:_VDESC:Text )				   			, Nil })
					EndIF
					
					aAdd(aLinhaIt,{"D2_BASEICM"	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_IMPOSTO:_ICMS:_ICMS00:_VBC:Text )				, Nil })
					aAdd(aLinhaIt,{"D2_PICM"   	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_IMPOSTO:_ICMS:_ICMS00:_PICMS:Text ) 			, Nil })
					aAdd(aLinhaIt,{"D2_VALICM" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_IMPOSTO:_ICMS:_ICMS00:_VICMS:Text )				, Nil })
					aAdd(aLinhaIt,{"D2_BASEPIS"	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_IMPOSTO:_PIS:_PISALIQ:_VBC:Text )				, Nil })
					aAdd(aLinhaIt,{"D2_ALQPIS" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_IMPOSTO:_PIS:_PISALIQ:_PPIS:Text )				, Nil })
					aAdd(aLinhaIt,{"D2_VALPIS" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_IMPOSTO:_PIS:_PISALIQ:_VPIS:Text )				, Nil })
					aAdd(aLinhaIt,{"D2_BASECOF" , Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_IMPOSTO:_COFINS:_COFINSALIQ:_VBC:Text )			, Nil })
					aAdd(aLinhaIt,{"D2_ALQCOF" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_IMPOSTO:_COFINS:_COFINSALIQ:_PCOFINS:Text )		, Nil })
					aAdd(aLinhaIt,{"D2_VALCOF" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET[nX]:_IMPOSTO:_COFINS:_COFINSALIQ:_VCOFINS:Text )		, Nil })
					
					aAdd(aItens,aLinhaIt)
				
				Next 

			ElseIF ValType(oXml:_NFEPROC:_NFE:_INFNFE:_DET) == "O"
				
				aLinhaIt := {}

				// ==========================================================================================================================================
				//Identifica o Código do Produto para inclusão da NF
				cProduto := xPesqProd(oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_CPROD:Text)

				If Empty(cProduto)
					Aviso('Atenção', "A Nota Fiscal: " + StrZero( Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NNF:Text)) , 9) + " não será importada "+;
									 "devido o produto : " + oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_CPROD:Text + ;
									 ", não estar cadastrado. "+;
									 'Por favor solicitar o cadastro e o prenchimento do campo B1_XCODXML (Cod. XML NFe) do mesmo.', {'Ok'}, 03)
				EndIF
				// ==========================================================================================================================================

				// ==========================================================================================================================================
				//Identifica o Código do TES para inclusão da NF
				cTESUtil := xPesqTES(oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_CFOP:Text)
				If Empty(cTESUtil)
					Do Case
						Case "VENDA" $ (Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NATOP:Text)))
							cTESUtil := cTESVend
						Case "REMESSA" $ (Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NATOP:Text)))
							cTESUtil := cTESReme
						Case "DEVOLUCAO" $ (Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NATOP:Text)))
							cTESUtil := cTESDevo
						Case "TRANSFERENCIA" $ (Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_IDE:_NATOP:Text)))
							cTESUtil := cTESTran
					End Case 
				EndIF
				// ==========================================================================================================================================

				aAdd(aLinhaIt,{"D2_ITEM"   	, StrZero( Val(oXml:_NFEPROC:_NFE:_INFNFE:_DET:_NITEM:Text) , 2) 						, Nil })
				aAdd(aLinhaIt,{"D2_COD"    	, cProduto                 																, Nil })
				aAdd(aLinhaIt,{"D2_QUANT"  	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_QCOM:Text )           					, Nil })
				aAdd(aLinhaIt,{"D2_PRCVEN" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_VUNCOM:Text )         					, Nil })
				aAdd(aLinhaIt,{"D2_TOTAL"  	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_VPROD:Text )          					, Nil })
				aAdd(aLinhaIt,{"D2_TES"    	, cTESUtil     															   				, Nil })
				aAdd(aLinhaIt,{"D2_CF"     	, oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_CFOP:Text						   				, Nil })
				
				//Tratamento da tag desconto
				IF AttIsMemberOf( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD, "_VDESC" )
					aAdd(aLinhaIt,{"D2_DESCON" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_PROD:_VDESC:Text )				   			, Nil })
				EndIF
				
				aAdd(aLinhaIt,{"D2_BASEICM"	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_ICMS:_ICMS00:_VBC:Text )				, Nil })
				aAdd(aLinhaIt,{"D2_PICM"   	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_ICMS:_ICMS00:_PICMS:Text ) 			, Nil })
				aAdd(aLinhaIt,{"D2_VALICM" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_ICMS:_ICMS00:_VICMS:Text )				, Nil })
				aAdd(aLinhaIt,{"D2_BASEPIS"	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_PIS:_PISALIQ:_VBC:Text )				, Nil })
				aAdd(aLinhaIt,{"D2_ALQPIS" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_PIS:_PISALIQ:_PPIS:Text )				, Nil })
				aAdd(aLinhaIt,{"D2_VALPIS" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_PIS:_PISALIQ:_VPIS:Text )				, Nil })
				aAdd(aLinhaIt,{"D2_BASECOF" , Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_COFINS:_COFINSALIQ:_VBC:Text )			, Nil })
				aAdd(aLinhaIt,{"D2_ALQCOF" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_COFINS:_COFINSALIQ:_PCOFINS:Text )		, Nil })
				aAdd(aLinhaIt,{"D2_VALCOF" 	, Val( oXml:_NFEPROC:_NFE:_INFNFE:_DET:_IMPOSTO:_COFINS:_COFINSALIQ:_VCOFINS:Text )		, Nil })
				
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

Static Function xCadCli(pCNPJCPF)

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

	oSA1Mod:SetValue("A1_TIPO"   , "F"                                                                      								)
    oSA1Mod:SetValue("A1_PESSOA" , IIF(Len(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_CPF:Text)) > 11,"J","F")  								)
    oSA1Mod:SetValue("A1_CGC"    , pCNPJCPF											                         								)
    oSA1Mod:SetValue("A1_NOME"   , Upper(Pad(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_XNOME:Text),FwTamSX3("A1_NOME")[1]))            		)
    oSA1Mod:SetValue("A1_NREDUZ" , Upper(Pad(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_XNOME:Text),FwTamSX3("A1_NREDUZ")[1]))				)
    IF AttIsMemberOf( oXml:_NFEPROC:_NFE:_INFNFE:_DEST, "_EMAIL" )
		oSA1Mod:SetValue("A1_EMAIL"  , Pad(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_EMAIL:Text),FwTamSX3("A1_EMAIL")[1])                 	)
	EndIF 
    IF AttIsMemberOf( oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST, "_FONE" )
		oSA1Mod:SetValue("A1_TEL"    , Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_FONE:Text)           							)
	EndIF 
    oSA1Mod:SetValue("A1_END"    , Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_XLGR:Text))+" "+;
                                   Upper(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_NRO:Text))            						)
    oSA1Mod:SetValue("A1_BAIRRO" , Upper(Pad(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_XBAIRRO:Text),FwTamSX3("A1_BAIRRO")[1]))	)
    oSA1Mod:SetValue("A1_EST"    , Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_UF:Text)             					   			)
    oSA1Mod:SetValue("A1_COD_MUN", SubSTR(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_CMUN:Text),3) 								)
    oSA1Mod:SetValue("A1_MUN"    , Upper(Pad(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_XMUN:Text),FwTamSX3("A1_MUN")[1]))		)
    oSA1Mod:SetValue("A1_CEP"    , Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_CEP:Text)            								)
	oSA1Mod:SetValue("A1_CONTA"  , "11303003"            						                                                    		)
	oSA1Mod:SetValue("A1_PAIS"   , Pad(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_CPAIS:Text),FwTamSX3("A1_PAIS")[1])            	)
	oSA1Mod:LoadValue("A1_CODPAIS", StrZero(Val(Alltrim(oXml:_NFEPROC:_NFE:_INFNFE:_DEST:_ENDERDEST:_CPAIS:Text)),FwTamSX3("A1_CODPAIS")[1]))
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

/*------------------------------------------------------------------------------*
 | Func:  xPesqProd                                                             |
 | Desc:  Realiza a pesquisa do produto conforme De/Para no cadastro de produto |
 |        Campo B1_XCODXML                                                      |
 | Obs.:  /                                                                     |
 *-----------------------------------------------------------------------------*/

Static Function xPesqProd(pCodProd)
	Local cCodProd := ""
	Local cQry := ""
	Local cAlias := GetNextAlias()


	cQry := " SELECT B1_COD "
	cQry += " FROM "+RetSQLName("SB1")+" "
	cQry += " WHERE D_E_L_E_T_ <> '*'  "
	cQry += " AND B1_FILIAL = '"+FWxFilial("SB1")+"'  "
	cQry += " AND B1_XCODXML = '"+ pCodProd + "' "
	cQry := ChangeQuery(cQry)
	IF SELECT(cAlias) <> 0
		(cAlias)->(dbCloseArea())
	EndIF
  	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAlias,.F.,.T.)

	IF !(cAlias)->(EOF())  
		cCodProd := (cAlias)->B1_COD
	EndIF

	IF SELECT(cAlias) <> 0
		(cAlias)->(dbCloseArea())
	EndIF

Return cCodProd

/*------------------------------------------------------------------------------*
 | Func:  xPesqTES                                                              |
 | Desc:  Realiza a pesquisa do Código do TES conforme CFOP do Produto          |
 | Obs.:  /                                                                     |
 *-----------------------------------------------------------------------------*/

Static Function xPesqTES(pCFOP)
	Local cCodTES := ""
	Local cQry := ""
	Local cAlias := GetNextAlias()

	cQry := " SELECT F4_CODIGO "
	cQry += " FROM "+RetSQLName("SF4")+" "
	cQry += " WHERE D_E_L_E_T_ <> '*'  "
	cQry += " AND F4_FILIAL = '"+FWxFilial("SF4")+"'  "
	cQry += " AND F4_CF = '"+ pCFOP + "' "
	cQry := ChangeQuery(cQry)
	IF SELECT(cAlias) <> 0
		(cAlias)->(dbCloseArea())
	EndIF
  	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),cAlias,.F.,.T.)

	IF !(cAlias)->(EOF())  
		cCodTES := (cAlias)->F4_CODIGO
	EndIF

	IF SELECT(cAlias) <> 0
		(cAlias)->(dbCloseArea())
	EndIF

Return cCodTES
