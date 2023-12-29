#Include "PROTHEUS.CH"
#Include "FWMVCDEF.CH"
#Include "TOPCONN.CH"
#Include "TbiConn.ch"
/*
//ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄ¿±±
//±±³Programa  ³ CNTA121  ³ Autor ³ Talvane Augusto     ³ Data ³ 30/10/2019 ³±±
//±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄ´±±
//±±³Descricao ³ Ponto de entrada MEDICAO DE CONTRATOS.                     ³±±
//±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ³±±
//±±³Uso       ³ SELFIT                                                     ³±±
//±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
//±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
//ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
User Function CNTA121()

Local aParam     := PARAMIXB
Local oObj
Local cIdPonto
Local cIdModel
Local oModelCND
Local oModel
Local cFil
Local cContrato
Local cRevisa
Local lRet       := .T.
Local aCpos      := {}
Local cTipPlan
Local cSQL
Local nOpc       := 3
Local aArea      := GetArea()
Local aSaveLines := FWSaveRows()
Local _cCod
Local aCposZL    := {}
Local aCposZI    := {}
Local cNumMed
Local _lFlag     := .F.
Local nK         := 0 
Local aAreaAux   := {} 									// --> Incluso  LAVOR 09/11/2021  --  Ticket: 18261 
Local aAreaSC1   := {} 									// --> Incluso  LAVOR 09/11/2021  --  Ticket: 18261 
Local _cFil_OK   := "" 									// --> Incluso  LAVOR (PROX) 11/11/2021   (MEDICAO AUTOMATICA) 

If aParam <> Nil
	
	oObj     := aParam[1]
	cIdPonto := aParam[2]
	cIdModel := aParam[3]
	oModel   := FWModelActive()

/*
 If FwIsInCallStack('CN121Estorn') //Garante que o ponto só será utilizado no estorno da medição
	If cIdPonto == "MODELVLDACTIVE"
		Alert("Estornado com sucesso")
		xRet := .T.
	Else
		xRet := .F.
		Alert("Não foi é possível realizar o estorno")
	EndIf
EndIf
*/


	If     cIdPonto == "FORMLINEPRE"
			oModelCNE := oModel:GetModel( 'CNEDETAIL' )
/*
			oModelCNE := oModel:GetModel('CNEDETAIL')
			oModelCND := oModel:GetModel('CNDMASTER')
			cNumPla   := oModelCXN:GetValue("CXN_NUMPLA")
			cRevisa   := oModelCND:GetValue("CND_REVISA")
			cContra   := oModelCND:GetValue("CND_CONTRA")
			cChave	  := cFilCXN + cContra + cRevisa + cNumPla

			oStruCNE:SetProperty("CNE_NUMMED" 	,MODEL_FIELD_INIT,{|| oModelCND:GetValue('CND_NUMMED')})
			oStruCNE:SetProperty("CNE_NUMERO" 	,MODEL_FIELD_INIT,{|| oModelCXN:GetValue('CXN_NUMPLA')})
			oStruCNE:SetProperty("CNE_CONTRA" 	,MODEL_FIELD_INIT,{|| oModelCND:GetValue("CND_CONTRA")})
			oStruCNE:SetProperty("CNE_REVISA" 	,MODEL_FIELD_INIT,{|| oModelCND:GetValue("CND_REVISA")})
			oStruCNE:SetProperty("CNE_IDPED" 	,MODEL_FIELD_INIT,{|| cIdPD})
			oStruCNE:SetProperty("CNE_DTENT" 	,MODEL_FIELD_INIT,{|| dDataBase})
			oStruCNE:SetProperty("CNE_TES" 		,MODEL_FIELD_OBRIGAT,.T.)
*/

 //	If     cIdPonto == 'MODELCOMMITTTS' .And. INCLUI 								// Após a gravação total do modelo e DENTRO da transação.
	ElseIf     cIdPonto == "MODELCOMMITTTS"
		ConOut("##_PE_CNTA121.prw - 01 - Aqui ***") 
		If oModel:GetOperation() == MODEL_OPERATION_INSERT
			ConOut("##_PE_CNTA121.prw - 02 - Antes da chamada do funcao GravaMatriz()") 
			GravaMatriz() 
		EndIf 

/*	// --> Alterado ÉDER (PROX) 28/07/2021   (*DE..:*) 
	ElseIf cIdPonto == 'MODELCOMMITNTTS' .And. oModel:GetOperation() == MODEL_OPERATION_INSERT 	// Após a gravação total do modelo e FORA   da transação.
*/	// --> Alterado ÉDER (PROX) 28/07/2021   (*PARA:*) 
	ElseIf cIdPonto == 'MODELCOMMITNTTS' 	
		If 	oModel:GetOperation() == MODEL_OPERATION_INSERT 						// Após a gravação total do modelo e FORA   da transação.
//	// --> Alterado ÉDER (PROX) 28/07/2021   (*FINAL*) 
			oModelCND := oModel:GetModel( 'CNDMASTER' )
			cFil      := oModelCND:GetValue( 'CND_FILIAL' )
			cContrato := oModelCND:GetValue( 'CND_CONTRA' )
			cRevisa   := oModelCND:GetValue( 'CND_REVISA' )
			cNumMed   := oModelCND:GetValue( 'CND_NUMMED' )
			lAvalia   := .F.
			ConOut("##_PE_CNTA121.prw - 03 - Aqui ***") 
		
			dbSelectArea("CN9")
			dbSetOrder(1)
			MsSeek( cFil + cContrato + cRevisa )

			dbSelectArea("CNA")
			dbSetOrder(1)								// --> Indice 01: CNA_FILIAL + CNA_CONTRA + CNA_REVISA + CNA_NUMERO 
			If MsSeek( cFil + cContrato + cRevisa )
				ConOut("##_PE_CNTA121.prw - 04 - Aqui") 
				While CNA->(!Eof())  .And.  CNA->(CNA_FILIAL + CNA_CONTRA + CNA_REVISA) == cFil + cContrato + cRevisa 
					ConOut("##_PE_CNTA121.prw - 05 - Aqui") 
					cTipPlan := CNA->CNA_TIPPLA

					If !Posicione("CXN",1,CNA->( CNA_FILIAL + CNA_CONTRA + CNA_REVISA )+cNumMed+CNA->CNA_NUMERO,"CXN_CHECK")
						CNA->( dbSkip() )
						Loop
					EndIf

					dbSelectArea("CNL") 
					MsSeek( xFilial("CNL") + cTipPlan )

					If CNL->CNL_GERAVA == "1" 			// Gera avaliacao/questionario
						lAvalia := .T.
						ConOut("##_PE_CNTA121.prw - 06 - Aqui - If CNL->CNL_GERAVA == '1'") 
						If Select("TRB") > 0
							TRB->(dbCloseArea())
						EndIf
						cSQL := " SELECT   ZB_FILREF "
						cSQL += " FROM   "+RetSqlName("SZA")+" SZA (NOLOCK) "
						cSQL += "          INNER JOIN "+RetSqlName("SZB")+" SZB (NOLOCK) ON (ZA_FILIAL=ZB_FILIAL AND ZA_CODIGO=ZB_CODIGO) "
						cSQL += " WHERE    SZA.D_E_L_E_T_ = '' "
						cSQL += "   AND    SZB.D_E_L_E_T_ = '' "
						cSQL += "   AND    ZA_FILIAL  = '" + cFil            + "' "
						cSQL += "   AND    ZA_NROCONT = '" + cContrato       + "' "
						cSQL += "   AND    ZA_NROPLAN = '" + CNA->CNA_NUMERO + "' "
						cSQL += " GROUP BY ZB_FILREF "
						ConOut("##_PE_CNTA121.prw - 06 - cSQL: "+cSQL) 
						MPSysOpenQuery(cSQL , 'TRB')

						If TRB->( !Eof() )

							While TRB->( !Eof() )
								ConOut("##_PE_CNTA121.prw - 07 - Aqui") 
								_cCod := GetSxeNum( "SZJ", "ZJ_CODIGO" )
								ConfirmSx8()

								aAdd( aCpos , { 'ZJ_FILIAL'  , CNA->CNA_FILIAL } )
								aAdd( aCpos , { 'ZJ_CODIGO'  , _cCod           } )
								aAdd( aCpos , { 'ZJ_CONTRA'  , CNA->CNA_CONTRA } )
								aAdd( aCpos , { 'ZJ_REVISA'  , CNA->CNA_REVISA } )
								aAdd( aCpos , { 'ZJ_CONDPG'  , CN9->CN9_CONDPG } )
								aAdd( aCpos , { 'ZJ_DTINI'   , CN9->CN9_DTINIC } )
								aAdd( aCpos , { 'ZJ_DTFIM'   , CN9->CN9_DTFIM  } )
								aAdd( aCpos , { 'ZJ_VIGENC'  , CN9->CN9_VIGE   } )
								aAdd( aCpos , { 'ZJ_UNDVIG'  , CN9->CN9_UNVIGE } )
								aAdd( aCpos , { 'ZJ_PLANIL'  , CNA->CNA_NUMERO } )
								aAdd( aCpos , { 'ZJ_TPPLAN'  , cTipPlan        } )
							 //	aAdd( aCpos , { 'ZJ_PRODUTO' ,                 } )
							 //	aAdd( aCpos , { 'ZJ_USUARI'  ,                 } )
								aAdd( aCpos , { 'ZJ_STATUS'  , '1'             } )
								aAdd( aCpos , { 'ZJ_FILREF'  , TRB->ZB_FILREF  } )
								aAdd( aCpos , { 'ZJ_DTMEDI'  , dDataBase       } )
								aAdd( aCpos , { 'ZJ_CODMED'  , cNumMed         } )
								aAdd( aCpos , { 'ZJ_OBS'     , 'Avaliacao'     } )

								// Tipo de Questionario
								dbSelectArea("SZG") 
								SZG->( dbGoTop() )
								While SZG->( !Eof() )
									aAdd( aCposZL, { 'ZL_FILIAL' , CNA->CNA_FILIAL } )
									aAdd( aCposZL, { 'ZL_CODIGO' , _cCod           } )
									aAdd( aCposZL, { 'ZL_CODQUE' , SZG->ZG_CODIGO  } )
									aAdd( aCposZL, { 'ZL_TPAVAL' , SZG->ZG_TPAVAL  } )

									// Questionario
									dbSelectArea("SZH") 
									SZH->( dbGoTop() )
									SZH->( MsSeek( xFilial("SZH") + SZG->ZG_CODIGO ) )

									While SZH->( !Eof() ) .And. SZH->ZH_CODIGO == SZG->ZG_CODIGO
										aAdd( aCposZI, { 'ZI_FILIAL' , CNA->CNA_FILIAL } )
										aAdd( aCposZI, { 'ZI_CODIGO' , _cCod           } )
										aAdd( aCposZI, { 'ZI_CODITE' , SZH->ZH_ITEM    } )
										aAdd( aCposZI, { 'ZI_EVIDENC', SZH->ZH_EVIDENC } )
										aAdd( aCposZI, { 'ZI_CONCEIT', SZH->ZH_CONCEIT } )
										aAdd( aCposZI, { 'ZI_CODQUES', SZG->ZG_CODIGO  } )

									 //	Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCposZI, nOpc, "QUES" )
									 //	FWMsgRun(, {|| Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCposZI, nOpc, "QUES" ) }, "Processando", "Processando Questionario de Avaliacao...")
										FWMsgRun(, {|| u_xImp( cEmpAnt, cFilAnt, aCposZI, nOpc, "QUES" ) }, "Processando", "Processando Questionario de Avaliacao...")
										aCposZI := {}

										SZH->( dbSkip() )
									EndDo 

								 //	Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCposZL, nOpc, "TIPO" )
								 //	FWMsgRun(, {|| Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCposZL, nOpc, "TIPO" ) }, "Processando", "Processando Tipo de Avaliacao...")
									FWMsgRun(, {|| u_xImp( cEmpAnt, cFilAnt, aCposZL, nOpc, "TIPO" ) }, "Processando", "Processando Tipo de Avaliacao...")
									aCposZL := {}

									SZG->( dbSkip() )
								EndDo 

							 //	Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCpos, nOpc, "CAB" )
							 //	FWMsgRun(, {|| Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCpos, nOpc, "CAB" ) }, "Processando", "Processando Cabecalho de Avaliacao...")
								FWMsgRun(, {|| u_xImp( cEmpAnt, cFilAnt, aCpos, nOpc, "CAB" ) }, "Processando", "Processando Cabecalho de Avaliacao...")
								aCpos := {}

								TRB->( dbSkip() )
							End
							TRB->(dbCloseArea())

						Else

							_cCod := GetSxeNum( "SZJ", "ZJ_CODIGO" )
							ConfirmSx8()

							aAdd( aCpos, { 'ZJ_FILIAL'  , CNA->CNA_FILIAL } )
							aAdd( aCpos, { 'ZJ_CODIGO'  , _cCod           } )
							aAdd( aCpos, { 'ZJ_CONTRA'  , CNA->CNA_CONTRA } )
							aAdd( aCpos, { 'ZJ_REVISA'  , CNA->CNA_REVISA } )
							aAdd( aCpos, { 'ZJ_CONDPG'  , CN9->CN9_CONDPG } )
							aAdd( aCpos, { 'ZJ_DTINI'   , CN9->CN9_DTINIC } )
							aAdd( aCpos, { 'ZJ_DTFIM'   , CN9->CN9_DTFIM  } )
							aAdd( aCpos, { 'ZJ_VIGENC'  , CN9->CN9_VIGE   } )
							aAdd( aCpos, { 'ZJ_UNDVIG'  , CN9->CN9_UNVIGE } )
							aAdd( aCpos, { 'ZJ_PLANIL'  , CNA->CNA_NUMERO } )
							aAdd( aCpos, { 'ZJ_TPPLAN'  , cTipPlan        } )
						 //	aAdd( aCpos, { 'ZJ_PRODUTO' ,                 } )
						 //	aAdd( aCpos, { 'ZJ_USUARI'  ,                 } )
							aAdd( aCpos, { 'ZJ_STATUS'  , '1'             } )
							aAdd( aCpos, { 'ZJ_FILREF'  , CNA->CNA_FILIAL } )
							aAdd( aCpos, { 'ZJ_DTMEDI'  , dDataBase       } )
							aAdd( aCpos, { 'ZJ_CODMED'  , cNumMed         } )
							aAdd( aCpos, { 'ZJ_OBS'     , 'Avaliacao'     } )

							// Tipo de Questionario
							dbSelectArea("SZG") 
							SZG->( dbGoTop() )
							While SZG->( !Eof() )
								aAdd( aCposZL, { 'ZL_FILIAL' , CNA->CNA_FILIAL } )
								aAdd( aCposZL, { 'ZL_CODIGO' , _cCod           } )
								aAdd( aCposZL, { 'ZL_CODQUE' , SZG->ZG_CODIGO  } )
								aAdd( aCposZL, { 'ZL_TPAVAL' , SZG->ZG_TPAVAL  } )

								//Questionario
								dbSelectArea("SZH") 
								SZH->( dbGoTop() )
								SZH->( MsSeek( xFilial("SZH") + SZG->ZG_CODIGO ) )

								While SZH->( !Eof() ) .And. SZH->ZH_CODIGO == SZG->ZG_CODIGO
									aAdd( aCposZI, { 'ZI_FILIAL' , CNA->CNA_FILIAL } )
									aAdd( aCposZI, { 'ZI_CODIGO' , _cCod           } )
									aAdd( aCposZI, { 'ZI_CODITE' , SZH->ZH_ITEM    } )
									aAdd( aCposZI, { 'ZI_EVIDENC', SZH->ZH_EVIDENC } )
									aAdd( aCposZI, { 'ZI_CONCEIT', SZH->ZH_CONCEIT } )
									aAdd( aCposZI, { 'ZI_CODQUES', SZG->ZG_CODIGO  } )

								//	Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCposZI, nOpc, "QUES" )
								//	FWMsgRun(, {|| Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCposZI, nOpc, "QUES" ) }, "Processando", "Processando Questionario de Avaliacao...")
									FWMsgRun(, {|| u_xImp( cEmpAnt, cFilAnt, aCposZI, nOpc, "QUES" ) }, "Processando", "Processando Questionario de Avaliacao...")
									aCposZI := {}

									SZH->( dbSkip() )
								EndDo 

							 //	Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCposZL, nOpc, "TIPO" )
							 //	FWMsgRun(, {|| Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCposZL, nOpc, "TIPO" ) }, "Processando", "Processando Tipo de Avaliacao...")
								FWMsgRun(, {|| u_xImp( cEmpAnt, cFilAnt, aCposZL, nOpc, "TIPO" ) }, "Processando", "Processando Tipo de Avaliacao...")
								aCposZL := {}

								SZG->( dbSkip() )
							EndDo 

						 //	Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCpos, nOpc, "CAB" )
						 //	FWMsgRun(, {|| Startjob( "u_xImp", getenvserver(), .T., cEmpAnt, cFilAnt, aCpos, nOpc, "CAB" ) }, "Processando", "Processando Cabecalho de Avaliacao...")
							FWMsgRun(, {|| u_xImp( cEmpAnt, cFilAnt, aCpos, nOpc, "CAB" ) }, "Processando", "Processando Cabecalho de Avaliacao...")

							aCpos := {}

						EndIf
					EndIf

					CNA->( dbSkip() )
				EndDo 									// While CNA->(!Eof())  .And.  CNA->(CNA_FILIAL + CNA_CONTRA + CNA_REVISA) == cFil + cContrato + cRevisa 

				If Select("TRB") > 0
					TRB->(dbCloseArea())			
				EndIf

				If lAvalia
					Reclock("CND",.F.)
						CND->CND_SITUAC := "B"
					CND->(MsUnLock())
				EndIf

				If oModel != Nil
					oModel:Activate()
				EndIf
			EndIf
	 //	EndIf 											// --> Retirado ÉDER (PROX) 28/07/2021 

/*	// --> Alterado ÉDER (PROX) 28/07/2021   (*DE..:*) 
		
		ElseIf cIdPonto == 'MODELCOMMITNTTS' .And. oModel:GetOperation() == MODEL_OPERATION_UPDATE .And. IsIncallstack("CN121Encerr") 		// Após a gravação total do modelo e fora da transação. 
*/	// --> Alterado ÉDER (PROX) 28/07/2021   (*PARA:*) 
		ElseIf oModel:GetOperation() == MODEL_OPERATION_UPDATE .And. (FwIsIncallstack('CN120MedEnc') .Or. FwIsIncallstack('CN121Encerr')) 	// Após a gravação total do modelo e fora da transação. 
//	// --> Alterado ÉDER (PROX) 28/07/2021   (*FINAL*) 
			oModel    := FWModelActive()
			nOpc      := oModel:GetOperation()
			oModelCND := oModel:GetModel( 'CNDMASTER' )
			cFil      := oModelCND:GetValue( 'CND_FILIAL' )
			cContrato := oModelCND:GetValue( 'CND_CONTRA' )
			cRevisa   := oModelCND:GetValue( 'CND_REVISA' )
			cNumMed   := oModelCND:GetValue( 'CND_NUMMED' )
			aPeds     := {}

			ConOut("##_PE_CNTA121.prw - 08 - MODELCOMMITNTTS")
			ConOut("##_PE_CNTA121.prw - 08 - INICIANDO RATEIO DA MATRIZ DE REFERENCIA")
			// CONTRATO DE VEICULACAO (FACE E GOOGLE)
			If !(CNL->CNL_CTRFIX == "2" .And. CNL->CNL_LPU == "2" )		// if !(CNL->CNL_MEDEVE == "1" .And. (CNL->CNL_CTRFIX=="2" .or. CNL->CNL_CTRFIX=="3" ) .And. CNL->CNL_MATRIZ=="1" .And. CNL->CNL_LPU=="2") 
				u_MEDMATRIZ()  											// medicao da matriz de referencia
			EndIf

			// --> ALTERAÇÃO PARA GRAVAR O PEDIDO NA SC1 - ÉDER PROX 28/07/2021
			// Envia e-mail para fornecedor
			cSQL := " SELECT C7_FILIAL+C7_NUM AS CHV , CNE_NUMSC , CNE_ITEMSC , CNE_OBS , SC7.R_E_C_N_O_ AS ID , C7_VLDESC "
			cSQL += " FROM  "+RetSqlName("SC7")+" SC7 "
			cSQL += "        INNER JOIN "+RetSqlName("CNE")+" CNE ON (CNE_FILIAL = '"+cFil+"' AND CNE_CONTRA = C7_CONTRA AND CNE_NUMERO = C7_PLANILH AND C7_MEDICAO = CNE_NUMMED AND C7_PRODUTO = CNE_PRODUT) "
			cSQL += " WHERE  SC7.D_E_L_E_T_ = ''             "
			cSQL += "   AND  C7_CONTRA  = '"+cContrato+"'    "
			cSQL += "   AND  C7_MEDICAO = '"+cNumMed  +"'    "
			cSQL += "   AND (C7_FILCRT  = '"+cFil     +"' OR C7_FILIAL = '"+cFil+"' ) "
			MemoWrite("consultasc7medicao.sql" , cSQL) 
			MPSysOpenQuery(cSQL , "TRX") 

			dbSelectArea("SC7")
			dbSelectArea("SC1")

			While TRX->(!Eof())
		         nPos := aScan(aPeds,{|x|x==TRX->CHV})

		         If nPos == 0
		         	aAdd(aPeds,TRX->CHV)
		         EndIf

				If !Empty(TRX->CNE_NUMSC) .Or. TRX->C7_VLDESC > 0
					SC7->(dbGoTo(TRX->ID))
					If SC7->(!Eof())
						SC7->(RecLock("SC7",.F.)) 
							If !Empty(TRX->CNE_NUMSC)
		    					SC7->C7_NUMSC  := TRX->CNE_NUMSC 
		    					SC7->C7_ITEMSC := TRX->CNE_ITEMSC 
		    					SC7->C7_OBS    := TRX->CNE_OBS 
							EndIf
							If TRX->C7_VLDESC > 0 
								SC7->C7_PRECO  := SC7->C7_PRECO-SC7->C7_VLDESC 
								SC7->C7_TOTAL  := SC7->C7_PRECO*SC7->C7_QUANT 
								SC7->C7_VLDESC := 0 
							EndIf 
						SC7->(MsUnLock()) 
					EndIf 
/*	// --> Alterado ÉDER (PROX) 28/07/2021   (*DE..:*) 
    			If !Empty(TRX->CNE_NUMSC) .And. SC1->(dbSeek(SC7->C7_FILIAL+TRX->CNE_NUMSC+TRX->CNE_ITEMSC))
*/	// --> Alterado ÉDER (PROX) 28/07/2021   (*PARA:*) 
					dbSelectArea("SC1")
					SC1->(dbSetOrder(1))
					If SC1->(dbSeek(SC7->C7_FILIAL + TRX->CNE_NUMSC + TRX->CNE_ITEMSC))
//	// --> Alterado ÉDER (PROX) 28/07/2021   (*FINAL*) 
						If RecLock("SC1",.F.) 
							SC1->C1_PEDIDO  := SC7->C7_NUM 
							SC1->C1_ITEMPED := SC7->C7_ITEM 
							SC1->(MsUnLock()) 
						EndIf 
					EndIf 
				EndIf

				TRX->(dbSkip())
			EndDo

			For nK := 1 To Len(aPeds)
				_cFil_OK := cFilAnt 					// --> Incluso  LAVOR (PROX) 11/11/2021   (MEDICAO AUTOMATICA) 
				SC7->(dbSetOrder(1))
				If SC7->(dbSeek(aPeds[nK]))
					Processa( {|| u_SFCMP06(,, .T.,.T. )  }, "Aguarde...", "Enviando emails...  Filial - " + SC7->C7_FILIAL +" Pedido - " +SC7->C7_NUM )     
				EndIf                   
				cFilAnt  := _cFil_OK 					// --> Incluso  LAVOR (PROX) 11/11/2021   (MEDICAO AUTOMATICA) 
			Next nK 
			TRX->(dbCloseArea())

		EndIf	 										// --> Incluso  ÉDER (PROX) 28/07/2021 

		// 24950 - [SELFIT] Aprovação Workflow Medições
		// se inclusão ou alteração verifica se tem aprovadores e envia email
		If 	oModel:GetOperation() == MODEL_OPERATION_INSERT .or. oModel:GetOperation() == MODEL_OPERATION_UPDATE
			if FindFunction("U_MCWORK03")
				// envia workflow de aprovação caso necessario
				U_MCWORK03()
			Endif	
		Endif


/*	// --> Alterado ÉDER (PROX) 28/07/2021   (*DE..:*) 
	ElseIf cIdPonto == 'MODELPOS' .And. !IsIncallstack("CN121Encerr") 				// Após a gravação total do modelo e fora da transação.
*/	// --> Alterado ÉDER (PROX) 28/07/2021   (*PARA:*) 
	ElseIf cIdPonto == 'MODELPOS' .And. !FwIsIncallstack("CN121Encerr") 			// Após a gravação total do modelo e fora da transação.
//	// --> Alterado ÉDER (PROX) 28/07/2021   (*FINAL*) 
		ConOut("##_PE_CNTA121.prw - 09 - MODELPOS") 
	
		oModel    := FWModelActive()
		nOpc      := oModel:GetOperation()
		oModelCND := oModel:GetModel( 'CNDMASTER' )
		cFil      := oModelCND:GetValue( 'CND_FILIAL' )
		cContrato := oModelCND:GetValue( 'CND_CONTRA' )
		cRevisa   := oModelCND:GetValue( 'CND_REVISA' )
		cNumMed   := oModelCND:GetValue( 'CND_NUMMED' )
		
		If nOpc == MODEL_OPERATION_DELETE 
			ConOut("##_PE_CNTA121.prw - 09a - MODEL_OPERATION_DELETE") 

			Begin Transaction
				If Select("TRB") > 0 
					TRB->(dbCloseArea()) 
				EndIf 
				cSQL := " SELECT   ZJ_FILIAL , ZJ_CODIGO , ZJ_STATUS , R_E_C_N_O_ AS RECNO "
				cSQL += " FROM " + RetSqlName("SZJ") + " "
				cSQL += " WHERE    D_E_L_E_T_ = '' "
				cSQL += "   AND    ZJ_FILIAL = '" + cFil      + "' "
				cSQL += "   AND    ZJ_CONTRA = '" + cContrato + "' "
				cSQL += "   AND    ZJ_REVISA = '" + cRevisa   + "' "
				cSQL += "   AND    ZJ_CODMED = '" + cNumMed   + "' "
				cSQL += " ORDER BY ZJ_STATUS DESC "	
				MPSysOpenQuery(cSQL , 'TRB') 
				
				If TRB->( !Eof() ) 
					_cCod   := TRB->ZJ_CODIGO 
					_nRecno := TRB->RECNO 
					_lFlag  := .T. 
					If TRB->ZJ_STATUS == "1"
						lRet := MsgYesNo("Existe avaliação pendente, deseja continuar?"  , "Especifico SELFIT - PE_CNTA121.prw") 
					Else
						lRet := MsgYesNo("Existe avaliação encerrada, deseja continuar?" , "Especifico SELFIT - PE_CNTA121.prw")
					EndIf
				EndIf
				
				While TRB->( !Eof() )  .And.  lRet  .And.  _lFlag 
					_cCod   := TRB->ZJ_CODIGO
					_nRecno := TRB->RECNO
					SZJ->( dbGoTo( _nRecno ) )
					SZJ->( RecLock("SZJ",.F.) )
					SZJ->( dbDelete() )
					SZJ->( MsUnLock() )
					
					dbSelectArea("SZL") 
					dbSeek( cFil + _cCod )
					While SZL->( !Eof() )  .And.  SZL->( ZL_FILIAL + ZL_CODIGO ) == cFil + _cCod 
						SZL->( RecLock("SZL",.F.) )
							SZL->( dbDelete() )
						SZL->( MsUnLock() )
						
						SZL->( dbSkip() )
					EndDo 
					
					dbSelectArea("SZI")
					dbSeek( cFil + _cCod )
					While SZI->( !Eof() )  .And.  SZI->( ZI_FILIAL + ZI_CODIGO ) == cFil + _cCod 
						SZI->( RecLock("SZI",.F.) )
							SZI->( dbDelete() )
						SZI->( MsUnLock() )
						
						SZI->( dbSkip() )
					EndDo 
					TRB->( dbSkip() )	
				EndDo

				// --> Incluso  LAVOR 09/11/2021   (*INICIO*)  --  Ticket: 18261 
				aAreaAux := GetArea() 
				aAreaSC1 := SC1->(GetArea()) 

				dbSelectArea("SC1") 
				SC1->(dbSetOrder(1)) 
				SC1->(dbGoTop()) 

				If Select("TRBX") > 0 
					TRBX->(dbCloseArea()) 
				EndIf 
				cSQL := " Select   C1_FILIAL , C1_NUM , C1_ITEM , C1_CONTRA , C1_MEDICAO , R_E_C_N_O_ AS SC1_RECNO "
				cSQL += " From " + RetSqlName("SC1") + " SC1 (NOLOCK) "
				cSQL += " Where    D_E_L_E_T_ = '' "
				cSQL += "   And    C1_FILIAL  = '" + cFil      + "' "
				cSQL += "   And    C1_CONTRA  = '" + cContrato + "' "
				cSQL += "   And    C1_MEDICAO = '" + cNumMed   + "' "
				cSQL += " Order By C1_FILIAL , C1_NUM , C1_ITEM " 
				MPSysOpenQuery(cSQL , "TRBX") 
				While TRBX->(!Eof()) 
					SC1->(dbGoTo(TRBX->SC1_RECNO)) 
					If SC1->(!Eof())  .And.  SC1->C1_NUM == TRBX->C1_NUM  .And.  SC1->C1_CONTRA == TRBX->C1_CONTRA  .And.  SC1->C1_MEDICAO == TRBX->C1_MEDICAO 
						ConOut("##_PE_CNTA121.prw - 09a - Medição Excluída ["+SC1->C1_MEDICAO+"] -- Eliminada SC: ["+SC1->C1_NUM+"/"+SC1->C1_ITEM+"] por residuo !") 
						RecLock("SC1",.F.) 
							SC1->C1_CONTRA  := ""						
							SC1->C1_PLANILH := ""						
							SC1->C1_MEDICAO := ""						
							SC1->C1_FLAGGCT := ""						
							SC1->C1_PEDIDO  := ""
							SC1->C1_ITEMPED := ""
							SC1->C1_RESIDUO := "S" 
							SC1->C1_QUJE    := 0 
							if SC1->( FieldPos("C1_ZSTATMD")) > 0
								SC1->C1_ZSTATMD := "E" 			// A=Aprovada ; B=Bloqueada ; R=Rejeitada ; S=Estornada ; E=Excluida
							Endif	
							SC1->( Dbdelete())
						SC1->(MsUnLock()) 
					EndIf 
					TRBX->(dbSkip()) 
				EndDo 
			End Transaction

			RestArea(aAreaSC1) 
			RestArea(aAreaAux) 
			// --> Incluso  LAVOR 09/11/2021   (*FINAL* )  --  Ticket: 18261 

		EndIf
		
		If Select("TRB") > 0
			TRB->(dbCloseArea())			
		EndIf
		
		If oModel != Nil
			oModel:Activate()
		EndIf
	EndIf
	
EndIf

FWRestRows( aSaveLines )
RestArea( aArea )

Return lRet



// ======================================================================= \\
User Function xImp( cEmpAnt, cFilAnt, aCpos, nOpc, cTipo )
// ======================================================================= \\
// Job

// RpcSetEnv( cEmpAnt , cFilAnt , , , "GCT" , , ) 

Import(aCpos , nOpc , cTipo)

// RpcClearEnv()

Return




// ======================================================================= \\
Static Function ModelDef( cTipo )
// ======================================================================= \\
// ModelDef SLA Contratos

Local oModel  := MPFormModel():New("MODEL")
Local oStru   := FWFormStruct(1,'SZJ')
Local cMaster := 'SZJMASTER'

If     cTipo == "TIPO"
	cMaster := 'SZLDETAIL'
	oStru   := FWFormStruct(1,'SZL')
ElseIf cTipo == "QUES"
	cMaster := 'SZIDETAIL'
	oStru   := FWFormStruct(1,'SZI')
EndIf

oModel:addFields(cMaster , , oStru) 
oModel:SetPrimaryKey({})

Return oModel



// ======================================================================= \\
Static Function Import( aCpoMaster, nOpc, cTipo )
// ======================================================================= \\
// --> Importacao para tabela SLA Contratos

Local  oModel, oAux, oStruct
Local  nI        := 0
Local  nPos      := 0
Local  lRet      := .T.
Local  aAux	     := {}
Local  nItErro   := 0
Local  lAux      := .T.
Local  cMaster	 := 'SZJMASTER'

If     cTipo == "TIPO"
	cMaster := "SZLDETAIL"
ElseIf cTipo == "QUES"
	cMaster := "SZIDETAIL"
EndIf

oModel := ModelDef( cTipo )
oModel:SetOperation( nOpc )

lRet := oModel:Activate()

If lRet
	oAux    := oModel:GetModel( cMaster )
	oStruct := oAux:GetStruct()
	aAux	:= oStruct:GetFields()
	
	If lRet
		For nI := 1 To Len( aCpoMaster )
			// Verifica se os campos passados existem na estrutura do field
			If ( nPos := aScan( aAux, { |x| AllTrim( x[3] ) ==  AllTrim( aCpoMaster[nI][1] ) } ) ) > 0
				// È feita a atribuicao do dado aos campo do Model do cabeçalho
				If !( lAux := oModel:SetValue( cMaster, aCpoMaster[nI][1], aCpoMaster[nI][2] ) )
					// Caso a atribuição não possa ser feita, por algum motivo (validação, por exemplo)
					// o método SetValue retorna .F.
					lRet := .F.
					Exit
				EndIf
			EndIf
		Next
	EndIf
EndIf

If lRet
	// Faz-se a validação dos dados, note que diferentemente das tradicionais "rotinas automáticas"
	// neste momento os dados não são gravados, são somente validados.
	If ( lRet := oModel:VldData() )
		// Se o dados foram validados faz-se a gravação efetiva dos dados (commit)
		lRet := oModel:CommitData()
	EndIf
EndIf

If !lRet
	// Se os dados não foram validados obtemos a descrição do erro para gerar LOG ou mensagem de aviso
	aErro   := oModel:GetErrorMessage()
	
	// A estrutura do vetor com erro é:
	//  [1] Id do formulário de origem
	//  [2] Id do campo de origem
	//  [3] Id do formulário de erro
	//  [4] Id do campo de erro
	//  [5] Id do erro
	//  [6] mensagem do erro
	//  [7] mensagem da solução
	//  [8] Valor atribuido
	//  [9] Valor anterior
	
	AutoGrLog( "Id do formulário de origem:" + ' [' + AllToChar( aErro[1]  ) + ']' )
	AutoGrLog( "Id do campo de origem:     " + ' [' + AllToChar( aErro[2]  ) + ']' )
	AutoGrLog( "Id do formulário de erro:  " + ' [' + AllToChar( aErro[3]  ) + ']' )
	AutoGrLog( "Id do campo de erro:       " + ' [' + AllToChar( aErro[4]  ) + ']' )
	AutoGrLog( "Id do erro:                " + ' [' + AllToChar( aErro[5]  ) + ']' )
	AutoGrLog( "Mensagem do erro:          " + ' [' + AllToChar( aErro[6]  ) + ']' )
	AutoGrLog( "Mensagem da solução:       " + ' [' + AllToChar( aErro[7]  ) + ']' )
	AutoGrLog( "Valor atribuido:           " + ' [' + AllToChar( aErro[8]  ) + ']' )
	AutoGrLog( "Valor anterior:            " + ' [' + AllToChar( aErro[9]  ) + ']' )
	
	If nItErro > 0
		AutoGrLog( "Erro no Item:              " + ' [' + AllTrim( AllToChar( nItErro  ) ) + ']' )
	EndIf
	
	MostraErro()
 //	Help(Nil , Nil , "HELP" , Nil , "Informe a data" , 1 , 0 , Nil , Nil , Nil , Nil , Nil , {AutoGrLog}) 		// --> Retirado ÉDER (PROX) 28/07/2021 
EndIf

// Desativamos o Model
oModel:DeActivate()
oModel:Destroy()

Return lRet



// ======================================================================= \\
Static Function MedXMatriz()
// ======================================================================= \\

Local oModel	:= FWModelActive()
Local oModelCND	:= oModel:GetModel('CNDMASTER')
Local oModelCXN := oModel:GetModel("CXNDETAIL")
Local cNumMed   := oModelCND:GetValue("CND_NUMMED")
Local cContra   := oModelCND:GetValue("CND_CONTRA")
Local cRevisa   := oModelCND:GetValue("CND_REVISA")
Local cPlanilha := oModelCXN:GetValue("CXN_NUMPLA")
Local oModelCNE := oModelCXN:GetModel("CNEDETAIL")
Local lMedEve   := CN300RetSt("MEDEVE" , 0 , cPlanilha , cContra , xFilial("CND") , .F.)
Local nK        := 0 

If !lMedEve
	Aviso("Medição Eventual" , "Opção disponivel para planilhas de medição eventual", { "Ok"}, 1)
	Return 
EndIf 

If MsgYesNo("Medição eventual"+Chr(13)+Chr(10)+;
            "Deseja selecionar os itens para a planilha "+cPlanilha+" ?" , "Especifico SELFIT - PE_CNTA121.prw")
	aItens := u_TPVIEW02(cPlanilha , cContra , cRevisa , cNumMed) 
EndIf

For nK := 1 To Len(aItens)
	If oModelCNE:GetModel("CNEDETAIL"):SeekLine({{"CNE_PRODUT",aItens[nK][1]}})
		nValUnt := oModelCNE:GetModel("CNEDETAIL"):GetValue("CNE_VLUNIT")
		oModelCNE:GetModel("CNEDETAIL"):LoadValue("CNE_QUANT",aItens[nK][2])
		oModelCNE:GetModel("CNEDETAIL"):LoadValue("CNE_VLTOT",aItens[nK][2]*nValUnt)
	EndIf
Next nK 

Return



// ======================================================================= \\
Static Function GravaMatriz() 
// ======================================================================= \\

Local oModel	:= FWModelActive()
Local oModelCND	:= oModel:GetModel("CNDMASTER")
Local oModelCXN := oModel:GetModel("CXNDETAIL")
Local cNumMed   := oModelCND:GetValue("CND_NUMMED")
Local cContra   := oModelCND:GetValue("CND_CONTRA")
Local cRevisa   := oModelCND:GetValue("CND_REVISA")
Local cPlanilha := oModelCXN:GetValue("CXN_NUMPLA")
Local oModelCNE := oModelCXN:GetModel("CNEDETAIL")
Local lMedEve   := CN300RetSt("MEDEVE" , 0 , cPlanilha , cContra , xFilial("CND") , .F.)
Local cAprova   := CN9->CN9_GRPAPR
Local lBlqParc  := .F. 
Local lItens    := Type("__Itens" )  == "A" 
Local lFil      := Type("__FilRef")  == "C" 
Local lParc     := Type("__Parcel")  == "C" 
Local lExiForn  := Type("__Fornece") == "C"
Local lExiLojF  := Type("__Loja")    == "C"

Local nK        := 0 
Local nJ        := 0 

If lMedEve 
	ConOut("##_PE_CNTA121.prw - 10 - lMedEve  ==> .T. (Verdadeiro) -- Via: cPlanilha") 
Else
	ConOut("##_PE_CNTA121.prw - 10 - lMedEve  ==> .F. (Falso)      -- Via: cPlanilha") 
EndIf 

If lItens 
	ConOut("##_PE_CNTA121.prw - 11 - lItens   ==> .T. (Verdadeiro)") 
EndIf 

If lFil
	ConOut("##_PE_CNTA121.prw - 12 - lFil     ==> .T. (Verdadeiro)") 
	ConOut("##_PE_CNTA121.prw - 12 - __FilRef.: [" + __FilRef  +"]") 
EndIf 

If lExiForn 
	ConOut("##_PE_CNTA121.prw - 13 - lExiForn ==> .T. (Verdadeiro)") 
	ConOut("##_PE_CNTA121.prw - 13 - __Fornece: [" + __Fornece +"]") 
EndIf 

If lExiLojF 
	ConOut("##_PE_CNTA121.prw - 14 - lExiLojF ==> .T. (Verdadeiro)") 
	ConOut("##_PE_CNTA121.prw - 14 - __Loja...: [" + __Loja    +"]") 
EndIf 


For nK := 1 To oModelCXN:GetQtdLine()
	oModelCXN:GoLine(nK)
	
	If oModelCXN:GetValue("CXN_CHECK")
		oModelCNE := oModelCXN:GetModel("CNEDETAIL"):GetModel("CNEDETAIL")
		cPlanilha := oModelCXN:GetValue("CXN_NUMPLA")
		lMedEve   := CN300RetSt("MEDEVE" , 0 , oModelCXN:GetValue("CXN_NUMPLA") , cContra , xFilial("CND") , .F.) 

		If lMedEve 
			ConOut("##_PE_CNTA121.prw - 15 - lMedEve ==> .T. (Verdadeiro) -- Via: oModelCXN:GetValue('CXN_NUMPLA')") 
		Else
			ConOut("##_PE_CNTA121.prw - 15 - lMedEve ==> .F. (Falso)      -- Via: oModelCXN:GetValue('CXN_NUMPLA')") 
		EndIf 

		If IsMatriz(cContra , cPlanilha , cRevisa)  				// Tem matriz de referencia
			ConOut("##_PE_CNTA121.prw - 16 - Tem matriz de referencia")
			For nJ := 1 To oModelCNE:GetQtdLine()
				oModelCNE:GoLine(nJ)
				If oModelCNE:GetValue("CNE_VLTOT") > 0 
					ConOut("##_PE_CNTA121.prw - 17 - oModelCNE:GetValue('CNE_VLTOT') > 0 ") 
					cSQL     := " SELECT ZB_FILREF , ZB_PRCUNIT , ZB_XPRINI"
					cSQL     += " FROM "+RetSqlName("SZB")+" SZB "
					cSQL     += "        INNER JOIN "+RetSqlName("SZA")+" SZA ON (ZA_CODIGO = ZB_CODIGO AND ZA_FILIAL = ZB_FILIAL)
					cSQL     += " WHERE  SZB.D_E_L_E_T_ = '' "
					cSQL     += "   AND  SZA.D_E_L_E_T_ = '' "
					cSQL     += "   AND  ZA_NROCONT = '"+cContra  +"' "
					cSQL     += "   AND  ZA_NROPLAN = '"+cPlanilha+"' "
					cSQL     += "   AND  ZB_PRODUTO = '"+oModelCNE:GetValue("CNE_PRODUT")+"' "
					If CNL->CNL_CTRFIX <> '2'  .And.  lFil 			// Os contratos de LPU tem o mesmo valor para todas as filiais
						cSQL += "   AND  ZB_FILREF  = '"+__FilRef +"' "
					EndIf
					cSQL     += "   AND  ZA_REVISA  = '"+cRevisa  +"' "
					cSQL     += "   AND  ZA_FILIAL  = '"+xFilial("CND")+"' "
					ConOut("##_PE_CNTA121.prw - 17 - cSQL: "+cSQL) 

					MemoWrite("buscaszb.sql" , cSQL) 
					MPSysOpenQuery(cSQL , 'TRV')
					
					While TRV->(!Eof())  
						If CNL->CNL_CTRFIX == "2"
							nValor := oModelCNE:GetValue("CNE_VLUNIT")
						Else
						    nValor := TRV->ZB_PRCUNIT
						EndIf

						nPrcIni := TRV->ZB_XPRINI
						oModelCNE:SetValue("CNE_XPRINI",nPrcIni)
						
						dbSelectArea("SZM")
						RecLock("SZM",.T.)
							SZM->ZM_FILIAL      := xFilial("SZM")
							SZM->ZM_NUMMED      := cNumMed
							SZM->ZM_CONTRA      := cContra
							SZM->ZM_NUMERO      := cPlanilha
							If lMedEve  .And.  lFil
								SZM->ZM_FILREF  := __FilRef 		// Deve considerar a filial da SC por conta da medição de LPU.
							Else
								SZM->ZM_FILREF  := TRV->ZB_FILREF
							EndIf
							SZM->ZM_PRODUTO     := oModelCNE:GetValue("CNE_PRODUT")
							SZM->ZM_QTD         := oModelCNE:GetValue("CNE_QUANT")
							SZM->ZM_TITULO      := oModelCNE:GetValue("CNE_CC")						
							SZM->ZM_PRC         := nValor
							SZM->ZM_TOTAL       := oModelCNE:GetValue("CNE_QUANT")*nValor
							SZM->ZM_BLQAVL      := Iif(!Empty(cAprova) , "1" , "2")
							SZM->ZM_CODIGO      := GetSxENum("SZM","ZM_CODIGO")
							If lFil 
							  If lExiForn 
								SZM->ZM_FORNECE := __Fornece 
							  EndIf 
							  If lExiLojF
								SZM->ZM_LOJA    := __Loja 
							  EndIf 
							EndIf
						SZM->(MsUnLock())
						ConfirmSX8() 
						
						TRV->(dbSkip())
					EndDo
					
					TRV->(dbCloseArea())
				EndIf
				
			Next
			
		EndIf
	EndIf
Next

If lParc 		// Caso seja regra de negociacao
	dbSelectArea("SZU")
	dbSetOrder(1)
	If dbSeek(xFilial("SZU")+cContra+cPlanilha+__Parcel)
		cStatus := "1"
		If SZU->ZU_AVLMED == "1"
			U_TpGerMed( xFilial("SZU") , cNumMed , cPlanilha , xFilial("SZU") , CND->CND_VLTOT , CND->CND_APROV , "ZU" ) 
			lBlqParc := .T. 
			cStatus  := "3" 
		EndIf
		RecLock("SZU",.F.)
			SZU->ZU_STATUS := cStatus
		SZU->(MsUnLock())
	EndIf
EndIf

If lBlqParc
	// BLoqueia medicao
	RecLock("CND",.F.)
		CND->CND_SITUAC := "B"
	CND->(MsUnLock())
EndIf

Return



// ======================================================================= \\
Static Function IsMatriz(cContra , cPlanilha , cRevisa) 
// ======================================================================= \\

Local lRet := .F.

cSQL := " SELECT * "
cSQL += " FROM   "+RetSqlName("CNA")+" CNA (NoLock) "
cSQL += "        INNER JOIN "+RetSqlName("CNL")+" CNL ON (CNA_TIPPLA = CNL_CODIGO) "
cSQL += " WHERE  CNA_CONTRA = '"+cContra       +"' "
cSQL += "   AND  CNA_NUMERO = '"+cPlanilha     +"' "
cSQL += "   AND  CNA_REVISA = '"+cRevisa       +"' "
cSQL += "   AND  CNA_FILIAL = '"+xFilial("CNA")+"' "
cSQL += "   AND  CNL_MATRIZ = '1' "
cSQL += "   AND  CNL.D_E_L_E_T_ = '' "
cSQL += "   AND  CNA.D_E_L_E_T_ = '' "
MemoWrite("TEM_MATRIZ.sql" , cSQL) 
MPSysOpenQuery(cSQL , 'TRK')

If TRK->(!EOF())
	lRet := .T.
EndIf

TRK->(dbCloseArea())

Return lRet
