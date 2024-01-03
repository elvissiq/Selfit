#Include "PROTHEUS.CH"
#Include "TOPCONN.CH"

/*/{Protheus.doc} CN120ENMED
(FUNCAO )
@author   Kelveng Carlisson - Tupi Consultoria
@since    02/10/2019
@version  1.0
/*/                
// ======================================================================= \\
User Function MEDMATRIZ() 
// ======================================================================= \\

Local aPlanilhas := GetPlanilhas() 
Local nPlan      := 0 

ConOut("##_MEDMATRIZ.prw   #_INICIO_# ================================================================== ##")

For nPlan := 1 To Len(aPlanilhas) 
	If aPlanilhas[nPlan][2] == "1" 					// 1-Indica se a planilha  da medicao gera PEDIDO DE COMPRAS 
		GeraPC(aPlanilhas[nPlan][1]) 
	Else 
		GeraTit(aPlanilhas[nPlan][1]) 				// 2-Indica se a planilha  da medicao gera TITULO A PAGAR
	EndIf	
Next nPlan 

ConOut("##_MEDMATRIZ.prw   #_FINAL__# ================================================================== ##")

Return 



// ======================================================================= \\
Static Function GeraPC(cPlanilha) 
// ======================================================================= \\

Local   cSQL        := ""
Local   lNEncontrou := .T.
Local   aPrdMatrz   := {}
Local   aFilMatrz   := {}
Local   aPrdNErro   := {} 
Local   nDesconto   := 0
Local   aRec        := {}
Local   lMedEve     := CN300RetSt("MEDEVE" , 0 , cPlanilha , CND->CND_CONTRA , CND->CND_FILIAL , .F.)
Local   lDesc       := .F.
Local   aDesc       := {}
Local   nI          := 0 
Local   nJ          := 0 
Local   nK          := 0 
Local   aAreaAux    := {} 

Private aItFil      := {}
Private aItens      := {}
Private aCabec      := {}       

Private cAxC7FIL    := ""
Private cAxC7NUM    := ""
Private cAxC7PRO    := ""
Private cAxC7RAT    := ""
Private aProcRat    := {} 
Private cRat_Sim    := " " 
Private cRat_Nao    := " " 
Private lCCRet      := .F.

ConOut("##_MEDMATRIZ.prw   --  GeraPC("+cPlanilha+")  --  #_INICIO_#")

RetPrdMatriz( cPlanilha , lMedEve , aFilMatrz , aPrdMatrz ) 

cSQL := " Select R_E_C_N_O_ AS ID  "                  + CRLF 
cSQL += " From  "+RetSqlName("SC7")+" (NoLock) "      + CRLF 
cSQL += " Where  D_E_L_E_T_ = '' "                    + CRLF 
cSQL += "   And  C7_FILIAL  = '"+xFilial("SC7") +"' " + CRLF 
cSQL += "   And  C7_CONTRA  = '"+CND->CND_CONTRA+"' " + CRLF 
cSQL += "   And  C7_CONTREV = '"+CND->CND_REVISA+"' " + CRLF 
cSQL += "   And  C7_PLANILH = '"+cPlanilha      +"' " + CRLF 
cSQL += "   And  C7_MEDICAO = '"+CND->CND_NUMMED+"' " + CRLF 
ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  cSQL: "  + Chr(13)+Chr(10) + cSQL) 

MPSysOpenQuery(cSQL , "TRJ") 

While TRJ->(!Eof()) 
	
	aItem := {} 

	lNEncontrou := .F. 
	
	dbSelectArea("SC7") 
	dbGoTo(TRJ->ID) 
	
	aAdd(aRec , SC7->(Recno())) 

	aItem  := {} 
	aDados := {}																	// Gera item do pedido de compra
	nPos   := aScan(aPrdMatrz , {|x|AllTrim(x[1]) == AllTrim(SC7->C7_PRODUTO)}) 

	If nPos > 0 

		cFornece := SC7->C7_FORNECE 
		cLoja    := SC7->C7_LOJA 
		cCond    := SC7->C7_COND 
		nPrcIni  := U_SFCONTA2()
		
		aAdd(aItem , {"C7_PRODUTO" , SC7->C7_PRODUTO				    , Nil}) 	// Produto 
		aAdd(aItem , {"C7_QUANT"   , SC7->C7_QUANT						, Nil}) 	// Quantidade 
		aAdd(aItem , {"C7_PRECO"   , SC7->C7_PRECO						, Nil}) 	// Preco unitario 
		aAdd(aItem , {"C7_TOTAL"   , SC7->C7_TOTAL			   			, Nil}) 	// Valor total 
		aAdd(aItem , {"C7_VLDESC"  , 0			               			, Nil}) 	// Desconto Item 
		aAdd(aItem , {"C7_CC"      , SC7->C7_CC						   	, Nil}) 	// Centro de custo 
		aAdd(aItem , {"C7_TIPO"    , SC7->C7_TIPO				  		, Nil}) 	// Numero do Pedido 
		aAdd(aItem , {"C7_LOCAL"   , SC7->C7_LOCAL						, Nil}) 	// Local 
		aAdd(aItem , {"C7_MSG"     , SC7->C7_MSG					    , Nil}) 	// Mensagem 
		aAdd(aItem , {"C7_OBS"     , SC7->C7_OBS				  	    , Nil}) 	// Observacao 
		aAdd(aItem , {"C7_SEQMRP"  , SC7->C7_SEQMRP						, Nil}) 	// Sequencia MRP 
		aAdd(aItem , {"C7_TES"     , SC7->C7_TES					    , Nil}) 	// TES 
		aAdd(aItem , {"C7_CONTRA"  , SC7->C7_CONTRA					    , Nil}) 	// Numero do Contrato 
		aAdd(aItem , {"C7_CONTREV" , SC7->C7_CONTREV				    , Nil}) 	// Numero da Revisao do Contrato
		aAdd(aItem , {"C7_PLANILH" , SC7->C7_PLANILH				    , Nil}) 	// Numero da Planilha do Contrato 
		aAdd(aItem , {"C7_MEDICAO" , SC7->C7_MEDICAO				    , Nil}) 	// Numero da Medicao do Contrato 
		aAdd(aItem , {"C7_ITEMED"  , SC7->C7_ITEMED   					, Nil}) 	// Item da Medicao do Contrato 
		aAdd(aItem , {"C7_FILCRT"  , SC7->C7_FILIAL   					, Nil}) 	// Filial contrato original 
		aAdd(aItem , {"C7_ZMEDAUT" , SC7->C7_ZMEDAUT  					, Nil}) 	// Gerado via Medicao Autom. (Job)	// --> Incluso  LAVOR (PROX) 11/11/2021   (MEDICAO AUTOMATICA) 
        aAdd(aItem , {"C7_ZPRCINI" , nPrcIni          					, Nil})     // Preço inicial // --> Incluso por Vinicius N. de Oliveira (PROX) 06/12/2022
		aAdd(aItem , {"C7_XTOTAL"  , nPrcIni * SC7->C7_QUANT   			, Nil})     // Preço Total inicial // --> Incluso por Vinicius N. de Oliveira (PROX) 12/01/2023
		
		If SC7->C7_VLDESC > 0
        	aAdd(aDesc , {C7_PRODUTO , SC7->C7_VLDESC})
        	lDesc := .T.
        EndIf
		aAdd(aItens , aClone(aItem))
		If SC7->C7_RATEIO = "1" 
			cRat_Sim := "X" 
		EndIf 
		If SC7->C7_RATEIO = "2" 
			cRat_Nao := "X" 
		EndIf 
	Else
		aAdd(aPrdNErro , SC7->C7_PRODUTO) 
	EndIf
	
	TRJ->(dbSkip())
	
EndDo 	

If cRat_Sim = "X" .And. cRat_Nao = " "
	// --> Todos os itens do PEDIDO são COM RATEIO... Não executa o processo de EXCLUIR e INCLUIR pedidos. 
	ConOut("##_MEDMATRIZ.prw   --  GeraPC("+cPlanilha+")  --  #_FINAL_(Com Rateio)_#")
	Return 
EndIf 

If Len(aPrdNErro) > 0

	cMsg := "Produtos não encontrados na matriz de referência. Realizar seguinte procedimento: "+CRLF
	cMsg += " - Estornar Medição "            +CRLF
	cMsg += " - Ajustar Matriz de referência "+CRLF
	cMsg += " - Encerrar medição "            +CRLF
	MsgAlert(cMsg , "Especifico SELFIT - MEDMATRIZ.prw") 

Else

	aAreaAux := GetArea() 
	For nI := 1 To Len(aRec) 
		dbSelectArea("SC7") 
		dbGoTo(aRec[nI]) 
		
		ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  Incluindo MEDICAO ["+CND->CND_NUMMED+"] com ALIAS [SC7] na tabela 'SZN'   (ZN_ORIG: 'S')")
		RecLock("SZN",.T.) 
			SZN->ZN_FILIAL := xFilial("SZN") 
			SZN->ZN_NUMMED := CND->CND_NUMMED 
			SZN->ZN_RECNO  := SC7->(Recno()) 
			SZN->ZN_ALIAS  := "SC7" 
			SZN->ZN_ORIG   := "S"
		SZN->(MsUnLock()) 
		
		cAxC7FIL := SC7->C7_FILIAL 
		cAxC7NUM := SC7->C7_NUM 
		cAxC7PRO := SC7->C7_PRODUTO 
		cAxC7RAT := SC7->C7_RATEIO 
		If aScan(aProcRat , {|x|x[1] = SC7->C7_FILIAL+SC7->C7_NUM}) = 0 
			aAdd(aProcRat , {SC7->C7_FILIAL+SC7->C7_NUM , SC7->C7_FILIAL , SC7->C7_NUM , SC7->C7_FORNECE , SC7->C7_LOJA , nI}) 
		EndIf 

		ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  Deletando C7_NUM: ["+SC7->C7_NUM+"] C7_MEDICAO: ["+SC7->C7_MEDICAO+"] da tabela 'SC7' ") 
		RecLock("SC7",.F.) 
			SC7->(dbDelete()) 
		SC7->(MsUnLock()) 
	Next nI 

	For nI := 1 To Len(aFilMatrz) 
		aItFil    := {} 
		nDesconto := 0
		For nJ := 1 To Len(aItens) 
			aItem := aClone(aItens[nJ])                
			If lMedEve 
				nPos := aScan(aPrdMatrz,{|x|AllTrim(x[1]) == AllTrim(aItem[1][2]) .And. x[2] == aFilMatrz[nI][1] .And. AllTrim(x[4]) == AllTrim(aItem[6][2])}) 
			Else    
				nPos := aScan(aPrdMatrz,{|x|AllTrim(x[1]) == AllTrim(aItem[1][2]) .And. x[2] == aFilMatrz[nI][1]}) 
			EndIf	
			If nPos > 0
				aItens[nJ][04][2] := aPrdMatrz[nPos][3]*aItem[2][2] 
				aItens[nJ][03][2] := aPrdMatrz[nPos][3] 
				aAdd(aItFil , aClone(aItens[nJ])) 
			EndIf
    	Next nJ 

   		If Len(aItFil) > 0 
    		If !Empty(aFilMatrz[nI][2]) .And. !Empty(aFilMatrz[nI][3])
    			cFornece := aFilMatrz[nI][2]
    			cLoja    := aFilMatrz[nI][3]
    		EndIf
    		
			nDesconto := (aFilMatrz[nI][4] / Len(aItFil)) 

			// Aplica desconto em todos os itens
			For nK := 1 To Len(aItFil) 
				If nDesconto > 0 
					aItFil[nK][5][2] := nDesconto 
				EndIf 
				// Altera CC de acordo com CTT+FILIAL2 
				If aFilMatrz[nI][1] <> "0101" 
					aItFil[nK][6][2] := aFilMatrz[nI][5] 
				EndIf 
			Next nK 

			ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  Antes da Chamada: u_TPMT120()") 
			aRecnos := u_TPMT120(aFilMatrz[nI][1] , cFornece , cLoja , cCond , nDesconto) 
			
			For nK := 1 To Len(aRecnos)
				ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  Incluindo MEDICAO ["+CND->CND_NUMMED+"] com ALIAS [SC7] na tabela 'SZN'   (ZN_ORIG: 'N')")
				RecLock("SZN",.T.) 
					SZN->ZN_FILIAL := xFilial("SZN") 
					SZN->ZN_NUMMED := CND->CND_NUMMED 
					SZN->ZN_RECNO  := aRecnos[nK] 
					SZN->ZN_ALIAS  := "SC7" 
					SZN->ZN_ORIG   := "N" 
				SZN->(MsUnLock()) 
			Next nK 
		EndIf
	Next nI 
EndIf
 
If !lMedEve 
	ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  Antes da Chamada: delPR()")
	delPR()											// Deleta previsto na SE2. Tablea CNF já está posicionada.
EndIf

ConOut("##_MEDMATRIZ.prw   --  GeraPC("+cPlanilha+")  --  #_FINAL__#")

Return 



// ======================================================================= \\
Static Function RetPrdMatriz(cPlanilha , lMedEve , aFilMatrz , aPrdMatrz) 
// ======================================================================= \\

ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  RetPrdMatriz()  --  #_INICIO_#")

If lMedEve 

	cSQL := " SELECT   ZM_FILREF AS FIL , ZM_PRODUTO AS PROD , ZM_PRC AS PRCUNIT , " + CRLF 
	cSQL += "        ( SELECT TOP 1 ZP_FORNECE+'|'+ZP_LOJA "                         + CRLF 
	cSQL += "          FROM   "+RetSqlName("SZP")+" SZP "                            + CRLF 
	cSQL += "                 INNER JOIN "+RetSqlName("SZA")+" SZA ON (ZA_FILIAL = ZP_FILIAL  AND  ZA_CODIGO = ZP_CODIGO) " + CRLF 
	cSQL += "          WHERE  SZP.D_E_L_E_T_ = '' "                                  + CRLF 
	cSQL += "            AND  SZA.D_E_L_E_T_ = '' "                                  + CRLF 
	cSQL += "            AND  ZA_FILIAL  = '"+xFilial("SZM") +"' "                   + CRLF 
	cSQL += "            AND  ZA_NROCONT = '"+CND->CND_CONTRA+"' "                   + CRLF 
	cSQL += "            AND  ZA_REVISA  = '"+CND->CND_REVISA+"' "                   + CRLF 
	cSQL += "            AND  ZA_NROPLAN = '"+cPlanilha      +"' "                   + CRLF 
	cSQL += "            AND  ZP_FILREF  = ZM_FILREF )             AS FORN   , "     + CRLF 
	cSQL += "        ( SELECT TOP 1 ZJ_VLRDESC "                                     + CRLF 
	cSQL += "          FROM   "+RetSqlName("SZJ")+" "                                + CRLF 
	cSQL += "          WHERE  D_E_L_E_T_ = '' "                                      + CRLF 
	cSQL += "            AND  ZJ_CODMED  = '"+CND->CND_NUMMED+"' "                   + CRLF 
	cSQL += "            AND  ZJ_CONTRA  = '"+CND->CND_CONTRA+"' "                   + CRLF 
	cSQL += "            AND  ZJ_FILREF  = ZM_FILREF "                               + CRLF 
	cSQL += "            AND  ZJ_FILIAL  = '"+xFilial("SZM") +"' "                   + CRLF 
	cSQL += "            AND  ZJ_PLANIL  = '"+cPlanilha      +"' ) AS VLDESC , "     + CRLF 
	cSQL += "          ZM_TITULO AS CC " 

	cSQL += " FROM   "+RetSqlName("SZM")+" (nolock) "                                + CRLF 
	cSQL += " WHERE    D_E_L_E_T_ = '' "                                             + CRLF 
	cSQL += "   AND    ZM_FILIAL = '"+xFilial("SZM") +"' "                           + CRLF 
	cSQL += "   AND    ZM_NUMMED = '"+CND->CND_NUMMED+"' "                           + CRLF 
	cSQL += "   AND    ZM_CONTRA = '"+CND->CND_CONTRA+"' "                           + CRLF 
	cSQL += "   AND    ZM_NUMERO = '"+cPlanilha      +"' "                           + CRLF 
	ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  RetPrdMatriz()  --  lMedEve = .T. (Verdadeiro) --> cSQL: " + Chr(13)+Chr(10) + cSQL) 

Else

	cSQL := " SELECT   ZB_FILREF AS FIL , ZB_PRODUTO AS PROD , ZB_PRCREF AS PRECO , ZB_PRCUNIT AS PRCUNIT , "             + CRLF  
	cSQL += "        ( SELECT TOP 1 ZP_FORNECE+'|'+ZP_LOJA "                         + CRLF 
	cSQL += "          FROM   "+RetSqlName("SZP")+" SZP "                            + CRLF 
	cSQL += "                 INNER JOIN "+RetSqlName("SZA")+" SZA ON (ZA_FILIAL = ZP_FILIAL AND ZA_CODIGO = ZP_CODIGO) " + CRLF 
	cSQL += "          WHERE  SZP.D_E_L_E_T_ = '' "                                  + CRLF 
	cSQL += "            AND  SZA.D_E_L_E_T_ = '' "                                  + CRLF 
	cSQL += "            AND  ZA_FILIAL  = '"+xFilial("SZA") +"' "                   + CRLF 
	cSQL += "            AND  ZA_NROCONT = '"+CND->CND_CONTRA+"' "                   + CRLF 
	cSQL += "            AND  ZA_NROPLAN = '"+cPlanilha      +"' "                   + CRLF 
	cSQL += "            AND  ZA_REVISA  = '"+CND->CND_REVISA+"' "                   + CRLF 
	cSQL += "            AND  ZP_FILREF  = ZB_FILREF )       AS FORN   , "           + CRLF 
	cSQL += "        ( SELECT TOP 1 ZJ_VLRDESC "                                     + CRLF 
	cSQL += "          FROM   "+RetSqlName("SZJ")+"  "                               + CRLF 
	cSQL += "          WHERE  D_E_L_E_T_ = '' "                                      + CRLF 
	cSQL += "            AND  ZJ_CODMED  = '"+CND->CND_NUMMED+"' "                   + CRLF 
	cSQL += "            AND  ZJ_CONTRA  = '"+CND->CND_CONTRA+"' "                   + CRLF 
	cSQL += "            AND  ZJ_FILREF  = ZB_FILREF "                               + CRLF 
	cSQL += "            AND  ZJ_FILIAL  = '"+xFilial("SZM")+"' "                    + CRLF 
	cSQL += "            AND  ZJ_PLANIL  = '"+cPlanilha+"' ) AS VLDESC , "           + CRLF 
	cSQL += "        ( SELECT TOP 1 CTT_CUSTO "                                      + CRLF 
	cSQL += "          FROM "+RetSqlName("CTT")+" "                                  + CRLF 
	cSQL += "          WHERE  D_E_L_E_T_ = '' "                                      + CRLF 
	cSQL += "            AND  CTT_FILUNI = ZB_FILREF )       AS CC "                 + CRLF 
	cSQL += " FROM   "+RetSqlName("SZB")+" SZB "                                     + CRLF 
	cSQL += "          INNER JOIN "+RetSqlName("SZA")+" SZA ON (ZA_CODIGO = ZB_CODIGO AND ZA_FILIAL = ZB_FILIAL) "        + CRLF 
	cSQL += " WHERE    SZA.D_E_L_E_T_ = '' "                                         + CRLF 
	cSQL += "   AND    SZB.D_E_L_E_T_ = '' "                                         + CRLF 
	cSQL += "   AND    ZA_FILIAL  = '"+xFilial("SZA") +"' "                          + CRLF 
	cSQL += "   AND    ZA_NROCONT = '"+CND->CND_CONTRA+"' "                          + CRLF 
	cSQL += "   AND    ZA_NROPLAN = '"+cPlanilha      +"' "                          + CRLF 
	cSQL += "   AND    ZA_REVISA  = '"+CND->CND_REVISA+"' "                          + CRLF 
	ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  RetPrdMatriz()  --  lMedEve = .F. (Falso)      --> cSQL: " + Chr(13)+Chr(10) + cSQL)
	
EndIf     

MemoWrite("consultaprodutoszb.sql",cSQL)
MPSysOpenQuery(cSQL , "TRB") 

nValPlan := 0

While TRB->(!Eof())

	//Validação inclusa por Vinicius N. de Oliveira - 25/10/2022 - Ticket: 25342 --
	//Como na tabela SZM está gravando outras filiais mas o centro de custo é de uma única filial então realizo a validação para que o pedido de compras não seja gerado em filiais incorretas
	DbSelectArea("CTT")
	CTT->(DbSetOrder(10))
	
	If CTT->(DbSeek(xFilial("CTT")+AvKey(TRB->FIL,"CTT_FILUNI")+AvKey(TRB->CC,"CTT_CUSTO"))) 
	
		If aScan(aFilMatrz,{|x|x[1] == TRB->FIL}) == 0
			cFornece := ""
			cLoja    := ""
			If Len(Alltrim(TRB->FORN)) > 1
				cFornece := StrTokArr( TRB->FORN,"|" )[1]
				cLoja    := StrTokArr( TRB->FORN,"|" )[2]
			EndIf
			aAdd(aFilMatrz , {TRB->FIL,cFornece,cLoja,TRB->VLDESC,TRB->CC}) 
		EndIf

		aAdd(aPrdMatrz , {TRB->PROD,TRB->FIL,TRB->PRCUNIT,TRB->CC}) 		// Gera item do pedido de compra
		
		lCCRet := .T.
		
	Endif 
	
	TRB->(dbSkip())

EndDo

	//Regra para registros que não constam com centro de custo na mesma filial que o contrato na Matriz de Referência - Vinicius N. de Oliveira - 08/08/2023
	//Esta regra foi acordada com o Artur Dowsley para evitar pedidos de compras deletados no ambiente sem que seja realizado o envio dos pedidos raiz pois estes serão lançados na filial da Matriz de Referência do Contrato
	If !lCCRet
	
		ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  RetPrdMatriz()  --  lCCRet = .F. (Falso)")
		
		TRB->(DbGoTop())
		
		While TRB->(!Eof())
		
			If aScan(aFilMatrz,{|x|x[1] == TRB->FIL}) == 0
			
				cFornece := ""
				cLoja    := ""
				
				If Len(Alltrim(TRB->FORN)) > 1
					cFornece := StrTokArr( TRB->FORN,"|" )[1]
					cLoja    := StrTokArr( TRB->FORN,"|" )[2]
				Endif 
				
				aAdd(aFilMatrz , {TRB->FIL,cFornece,cLoja,TRB->VLDESC,TRB->CC}) 
				aAdd(aPrdMatrz , {TRB->PROD,TRB->FIL,TRB->PRCUNIT,TRB->CC})
				
			Endif 			
		
			TRB->(DbSkip())
		
		EndDo 
		
	Endif 
	// ---
	
TRB->(dbCloseArea()) 

ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  RetPrdMatriz()  --  VarInfo( 'aPrdMatrz' , aPrdMatrz ) ") 
VarInfo( "aPrdMatrz" , aPrdMatrz ) 

ConOut("##_MEDMATRIZ.prw   --  GeraPC()  --  RetPrdMatriz()  --  #_FINAL__#")

Return 



// ======================================================================= \\
Static Function GeraTit(cPlanilha)
// ======================================================================= \\

Local cSQL        := ""
Local aTitOri
Local nPosVal     := 0
Local lMedEve     := CN300RetSt("MEDEVE" , 0 , cPlanilha , CND->CND_CONTRA , CND->CND_FILIAL , .F.)
Local nField      := 0 

ConOut("##_MEDMATRIZ.prw   --  GeraTit("+cPlanilha+")  --  #_INICIO_#")

// Busca os titulos da medicao.
cSQL += " SELECT R_E_C_N_O_ AS ID "                   + CRLF
cSQL += " FROM  "+RetSqlName("SE2")+" (nolock) "      + CRLF
cSQL += " WHERE  D_E_L_E_T_ = '' "                    + CRLF
cSQL += "   AND  E2_MDCONTR = '"+CND->CND_CONTRA+"' " + CRLF
cSQL += "   AND  E2_MEDNUME = '"+CND->CND_NUMMED+"' " + CRLF
cSQL += "   AND  E2_PREFIXO = 'MED' "                 + CRLF
ConOut("##_MEDMATRIZ.prw   --  GeraTit()  --  cSQL: " + cSQL)
MPSysOpenQuery(cSQL , "TRJ")

While TRJ->(!Eof())
	aTitOri := {}
	dbSelectArea("SE2")
	dbGoTo(TRJ->ID)

	dbSelectArea("SX3") 
	dbSetOrder(1) 
	dbSeek("SE2") 
	
	While !Eof() .And. (sx3->x3_arquivo=="SE2")
	 	If X3USO(SX3->X3_USADO) .And. AllTrim(SX3->X3_CAMPO) != "E2_NOMOPE"
			aAdd(aTitOri , {SX3->X3_CAMPO, SE2->&(SX3->X3_CAMPO), Nil})
		EndIf
		SX3->(dbSkip())
	EndDo 
	
	nPosVal  := aScan(aTitOri,{|X|AllTrim(X[1])=="E2_VALOR"  }) 
	aTitulo  := aClone(aTitOri)

	If lMedEve
		cSQL := " SELECT   ZM_FILREF AS FIL , SUM(ZM_TOTAL) AS SALDO " 
 		cSQL += " From   "+RetSqlName("SZM") 
 		cSQL += " WHERE    D_E_L_E_T_ = '' "
 		cSQL += "   AND    ZM_TIPDOC  = '2' "
 		cSQL += "   AND    ZM_NUMMED  = '"+CND->CND_NUMMED+"' "
 		cSQL += "   AND    ZM_CONTRA  = '"+SE2->E2_MDCONTR+"' "
 		cSQL += "   AND    ZM_NUMERO  = '"+cPlanilha      +"' "
 		cSQL += " GROUP BY ZM_FILREF "
	Else 
		// Busca rateio das filiais 
		cSQL := " SELECT   ZC_FILREF AS FIL , ZC_SALDO AS SALDO "
		cSQL += " FROM   "+RetSqlName("SZC") 
		cSQL += " WHERE    D_E_L_E_T_ = '' "
		cSQL += "   AND    ZC_FILIAL  = '"+SE2->E2_FILIAL +"' "
		cSQL += "   AND    ZC_CONTRA  = '"+SE2->E2_MDCONTR+"' "
		cSQL += "   AND    ZC_NUMPLA  = '"+SE2->E2_MDPLANI+"' "
		cSQL += "   AND    ZC_PARCEL  = '"+SE2->E2_MDPARCE+"' "
		cSQL += "   AND    ZC_REVISA  = '"+SE2->E2_MDREVIS+"' "
	EndIf	

	If Select("TRW") > 0
		TRW->(dbCloseArea())
	EndIf
	TcQuery cSQL New Alias "TRW"
	
	While TRW->(!Eof()) 

		aTitOri[nPosVal][2]  := TRW->SALDO 

		ConOut("##_MEDMATRIZ.prw   --  GeraTit()  --  Incluindo TITULO PAGAR na tabela 'SE2'  --  Processando Filial: ["+TRW->FIL+"]") 

		RecLock("SE2",.T.)
			For nField := 1 To Len(aTitOri)
				SE2->&(aTitOri[nField][1]) := aTitOri[nField][2] 
			Next nField 
			SE2->E2_FILIAL  := TRW->FIL 
			SE2->E2_FILORIG	:= TRW->FIL 
		SE2->(MsUnLock()) 

		ConOut("##_MEDMATRIZ.prw   --  GeraTit() --  Incluindo MEDICAO ["+CND->CND_NUMMED+"] com ALIAS [SE2] na tabela 'SZN'   (ZN_ORIG: 'N')")
		
		RecLock("SZN",.T.) 
			SZN->ZN_FILIAL := xFilial("SZN")
			SZN->ZN_NUMMED := CND->CND_NUMMED
			SZN->ZN_RECNO  := SE2->(Recno())
			SZN->ZN_ALIAS  := "SE2"  
			SZN->ZN_ORIG   := "N"
		SZN->(MsUnLock())	

		U_LogSZE(.F.) 								// GRAVA NO LOG REGISTRO EXCLUIDO. POIS SERA NECESSARIO CASO HAJA ESTORNO

		TRW->(dbSkip())
	EndDo 
	
	dbSelectArea("SE2") 
	dbGoTo(TRJ->ID) 
	
	If SE2->(!Eof())
		ConOut("##_MEDMATRIZ.prw   --  GeraTit() --  Incluindo MEDICAO ["+CND->CND_NUMMED+"] com ALIAS [SE2] na tabela 'SZN'   (ZN_ORIG: 'S')") 
		RecLock("SZN",.T.) 
			SZN->ZN_FILIAL := xFilial("SZN")
			SZN->ZN_NUMMED := CND->CND_NUMMED
			SZN->ZN_RECNO  := SE2->(Recno())
			SZN->ZN_ALIAS  := "SE2"  
			SZN->ZN_ORIG   := "S"
		SZN->(MsUnLock())

		ConOut("##_MEDMATRIZ.prw   --  GeraTit() --  Deletando E2_NUM: ["+SE2->E2_NUM+"] E2_MDCRON: ["+SE2->E2_MDCRON+"] da tabela 'SE2' ") 
		RecLock("SE2",.F.)
			SE2->(dbDelete()) 
		SE2->(MsUnLock()) 
	EndIf 
	
	U_LogSZE(.F.) 									// GRAVA NO LOG REGISTRO EXCLUIDO. POIS SERA NECESSARIO CASO HAJA ESTORNO
	
	TRJ->(dbSkip())
EndDo        

If !lMedEve
	ConOut("##_MEDMATRIZ.prw   --  GeraTit() --  Antes da Chamada: delPR()")
	delPR()											// DELETA PR das parcelas
EndIf

TRW->(dbCloseArea())
TRJ->(dbCloseArea())

ConOut("##_MEDMATRIZ.prw   --  GeraTit("+cPlanilha+")  --  #_FINAL__#")

Return .T.



// ======================================================================= \\
Static Function delPR()
// ======================================================================= \\

Local cSQL := ""

cSQL += " SELECT R_E_C_N_O_ AS ID "                   + CRLF
cSQL += " FROM "+RetSqlName("SE2")+" (nolock) "       + CRLF
cSQL += " WHERE  D_E_L_E_T_ = '' "                    + CRLF
cSQL += "   AND  E2_MDCONTR = '"+CND->CND_CONTRA+"' " + CRLF
cSQL += "   AND  E2_MDREVIS = '"+CND->CND_REVISA+"' " + CRLF
cSQL += "   AND  E2_MDCRON  = '"+CNF->CNF_NUMERO+"' " + CRLF
cSQL += "   AND  E2_MDPARCE = '"+CNF->CNF_PARCEL+"' " + CRLF
cSQL += "   AND  E2_PREFIXO = '' "                    + CRLF
cSQL += "   AND  E2_TIPO    = 'PR' "                  + CRLF
MPSysOpenQuery(cSQL , "TRV") 

While TRV->(!Eof())
	dbSelectArea("SE2") 
	dbGoTo(TRV->ID) 
	If SE2->(!Eof()) 
		U_LogSZE(.T.)
		ConOut("##_MEDMATRIZ.prw   --  delPR()   --  Deletando E2_NUM: ["+SE2->E2_NUM+"] E2_MDCRON: ["+SE2->E2_MDCRON+"] da tabela 'SE2' ") 
		RecLock("SE2",.F.) 
	   		SE2->(dbDelete()) 
		SE2->(MsUnlock()) 
	Else 
		ConOut("##_MEDMATRIZ.prw  --  delPR()  --  NÃO POSICIONOU TITULO PR !") 
	EndIf
	TRV->(dbSkip())
EndDo

TRV->(dbCloseArea())

Return



// ======================================================================= \\
Static Function GetPlanilhas()
// ======================================================================= \\

Local aPlanilhas := {} 

ConOut("##_MEDMATRIZ.prw   --  GetPlanilhas()  --  #_INICIO_#")

cSQL := " SELECT   CNE_NUMERO , CNE_PEDTIT "
cSQL += " FROM    "+RetSqlName("CNE")+" CNE (NoLock) "
cSQL += "          INNER JOIN "+RetSqlName("CNA")+" CNA (NoLock) ON (CNA_NUMERO = CNE_NUMERO AND CNA_FILIAL = CNE_FILIAL AND CNA_CONTRA = CNE_CONTRA AND CNA_REVISA = CNE_REVISA) "
cSQL += "          INNER JOIN "+RetSqlName("CNL")+" CNL          ON (CNA_TIPPLA = CNL_CODIGO) "
cSQL += " WHERE    CNE_CONTRA     = '"+CND->CND_CONTRA+"' "
cSQL += "   AND    CNE_NUMMED     = '"+CND->CND_NUMMED+"' " 
cSQL += "   AND    CNE_FILIAL     = '"+CND->CND_FILIAL+"' "  
cSQL += "   AND    CNL_MATRIZ     = '1' "
cSQL += "   AND    CNE.D_E_L_E_T_ = ''  "
cSQL += "   AND    CNL.D_E_L_E_T_ = ''  "
cSQL += "   AND    CNA.D_E_L_E_T_ = ''  "
cSQL += " GROUP BY CNE_NUMERO , CNE_PEDTIT " 
ConOut("##_MEDMATRIZ.prw   --  GetPlanilhas()  --  cSQL: "  + cSQL)

MemoWrite("getPlanilhas.sql" , cSQL) 
MPSysOpenQuery(cSQL , "TRK") 

While TRK->(!Eof()) 
	aAdd(aPlanilhas , {TRK->CNE_NUMERO,TRK->CNE_PEDTIT}) 
	TRK->(dbSkip())	
EndDo 
TRK->(dbCloseArea())

ConOut("##_MEDMATRIZ.prw   --  GetPlanilhas()  --  VarInfo( 'aPlanilhas' , aPlanilhas ) ") 
VarInfo( "aPlanilhas" , aPlanilhas ) 

ConOut("##_MEDMATRIZ.prw   --  GetPlanilhas()  --  #_FINAL__#")

Return aPlanilhas 



// ======================================================================= \\
User Function TPMT120(cFil , cFornece , cLoja , cCond , nDesctoX ) 
// ======================================================================= \\

Local   aCabec         := {} 
Local   cDoc           := "" 
Local   aRecnos        := {} 
Local   aGeraRat       := {} 
Local   nXX            := 0 
Local   aAreaAux       := {} 

// --> Incluso  LAVOR/PROX 08/06/2021   (*INICIO*) 
Local   cFwCdEmp       := "" 
Local   cErro          := "" 
Local   aErro          := {} 
Local   nZ             := 0 
Local   lPCFilEn       := GetMV("MV_PCFILEN") 										// --> Utiliza filial de Entrega (T) numeracao do PC por empresa, (F) numeracao do PC por filial.
// --> Incluso  LAVOR/PROX 08/06/2021   (*FINAL* ) 

Private lMsErroAuto    := .F.
Private lAutoErrNoFile := .T. 						// --> Para gravação do LOG. 	// --> Incluso  LAVOR/PROX 08/06/2021 

Default nDesctoX       := 0 

cFilBak  := cFilAnt 
cFilAnt  := cFil 
cFwCdEmp := AllTrim(FWCodEmp("SC7")) 

ConOut("##_---------------------------------------------------------------_## ") 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- #_INICIO_# "+Time())
ConOut("##_---------------------------------------------------------------_## ") 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- cFilAnt.......: ["+cFilAnt       +"] ") 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- cFil..........: ["+cFil          +"] ") 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- xFilial('SC7'): ["+xFilial("SC7")+"] ") 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- cFwCdEmp......: ["+cFwCdEmp      +"] == AllTrim(FWCodEmp('SC7'))") 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (Antes_) --> SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] / SC7->C7_NUM: ["+SC7->C7_NUM+"] ") 

// --> Verifica o ultimo documento valido para um Fornecedor.
dbSelectArea("SC7") 
SC7->(dbSetOrder(1)) 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (Pto.01) --> SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] / SC7->C7_NUM: ["+SC7->C7_NUM+"] ") 
MsSeek(xFilial("SC7")+"zzzzzz" , .T.) 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (Pto.02) --> SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] / SC7->C7_NUM: ["+SC7->C7_NUM+"] ") 
SC7->(dbSkip(-1)) 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (Pto.03) --> SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] / SC7->C7_NUM: ["+SC7->C7_NUM+"] ") 
cDoc := SC7->C7_NUM 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (Pto.04) --> cDoc..........: ["+cDoc+"] ") 

If Empty(cDoc) 
	cDoc := StrZero(1,Len(SC7->C7_NUM)) 
	ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (Pto.05) --> cDoc..........: ["+cDoc+"] ") 
Else 
	cDoc := Soma1(cDoc) 					// --> O CORRETO É APENAS ESTA LINHA !!! O IF É PARA FORÇAR ERRO !!
	ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (Pto.06) --> cDoc..........: ["+cDoc+"] ") 
	cDoc := CheckNroPC(cDoc , cFil) 
	ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (Pto.07) --> cDoc..........: ["+cDoc+"] - Depois do CheckNroPC() ") 
EndIf

aAdd(aCabec,{"C7_NUM"     , cDoc       }) 
aAdd(aCabec,{"C7_EMISSAO" , dDataBase  }) 
aAdd(aCabec,{"C7_FORNECE" , cFornece   }) 
aAdd(aCabec,{"C7_LOJA"    , cLoja      }) 
aAdd(aCabec,{"C7_COND"    , cCond      }) 
aAdd(aCabec,{"C7_CONTATO" , "AUTO"     }) 
aAdd(aCabec,{"C7_FILENT"  , cFilAnt    }) 
aAdd(aCabec,{"ALCADA"     , "S"   , Nil}) 			// Alcada 
aAdd(aCabec,{"MED_GCT"    , "GCT" , Nil}) 			// Originador 

MsExecAuto({|v,x,y,z,w| MATA120(v,x,y,z,w)} , 1 , aCabec , aItFil , 3 , .F.) 

If !lMsErroAuto 

ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (SC7)Pedido/Documento ["+cDoc+"], (EA) INCLUSO COM SUCESSO! # "+Chr(13)+Chr(10)+" SC7->C7_NUM: ["+SC7->C7_NUM+"]") 
	dbSelectArea("SC7") 
	SC7->(dbSetOrder(1)) 
	SC7->(dbSeek(xFilial("SC7")+cDoc)) 
	While SC7->(!Eof())  .And.  cDoc == SC7->C7_NUM 
		aAdd(aRecnos , SC7->(Recno())) 
		SC7->(dbSkip()) 
	EndDo 

	If Len(aProcRat) = 1 							// --> Realizar a cópia do Rateio para o novo pedido gerado via: MATA120(1 , aCabec , aItFil , 3) 
		aAreaAux := GetArea() 
		dbSelectArea("SCH")
		SCH->(dbSetOrder(1)) 						// --> Indice 01: CH_FILIAL + CH_PEDIDO + CH_FORNECE + CH_LOJA + CH_ITEMPD + CH_ITEM 
		SCH->(dbSeek(aProcRat[1][02] + aProcRat[1][03] + aProcRat[1][04] + aProcRat[1][05])) 
		While SCH->(!Eof())  .And.  SCH->CH_FILIAL  = aProcRat[1][02]  .And.  SCH->CH_PEDIDO = aProcRat[1][03]  .And. SCH->CH_FORNECE = aProcRat[1][04]  .And.  SCH->CH_LOJA   = aProcRat[1][05]  
			aAdd(aGeraRat , { SCH->CH_FILIAL , cDoc          , SCH->CH_ITEMPD  , SCH->CH_ITEM , SCH->CH_FORNECE , SCH->CH_LOJA   , ; 
			                  SCH->CH_CC     , SCH->CH_CONTA , SCH->CH_ITEMCTA , SCH->CH_CLVL , SCH->CH_PERC    , SCH->CH_CUSTO1 } ) 
			RecLock("SCH",.F.) 
				SCH->(dbDelete()) 
			SCH->(MsUnLock()) 
			SCH->(dbSkip()) 
		EndDo 
		If Len(aGeraRat) > 0 
			For nXX := 1 To Len(aGeraRat) 
				RecLock("SCH",.T.) 
					SCH->CH_FILIAL  := aGeraRat[nXX][01]
					SCH->CH_PEDIDO  := aGeraRat[nXX][02]
					SCH->CH_ITEMPD  := aGeraRat[nXX][03]
					SCH->CH_ITEM    := aGeraRat[nXX][04]
					SCH->CH_FORNECE := aGeraRat[nXX][05]
					SCH->CH_LOJA    := aGeraRat[nXX][06]
					SCH->CH_CC      := aGeraRat[nXX][07]
					SCH->CH_CONTA   := aGeraRat[nXX][08]
					SCH->CH_ITEMCTA := aGeraRat[nXX][09]
					SCH->CH_CLVL    := aGeraRat[nXX][10]
					SCH->CH_PERC    := aGeraRat[nXX][11]
					SCH->CH_CUSTO1  := aGeraRat[nXX][12]
				SCH->(MsUnLock()) 
			Next nXX
		EndIf 
		RestArea(aAreaAux) 
	EndIf 

Else 

	cErro := "" 
	aErro := GetAutoGRLog() 														// --> So funciona se lAutoErrNoFile estiver .T. 
	For nZ := 1 To Len(aErro) 
		cErro += aErro[nZ] + Chr(13)+Chr(10) 
	Next nZ 

ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (SC7)Pedido/Documento ["+cDoc+"], (EA) ERRO  NA  INCLUSAO ! # " +Chr(13)+Chr(10)+ cErro ) 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (EA) ERRO NA INCLUSAO - VarInfo( 'aCabec' , aCabec ) ") 
VarInfo( "aCabec" , aCabec ) 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (EA) ERRO NA INCLUSAO - VarInfo( 'aItFil' , aItFil ) ") 
VarInfo( "aItFil" , aItFil ) 

	If Upper("utilizado em outra filial") $ Upper(cErro) 

		If lPCFilEn 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- Parametro MV_PCFILEN definido como .T."                              + Chr(13)+Chr(10) + ;  
       "                                 Será ajustado para .F. para tentar resolver automaticamente o erro!" + Chr(13)+Chr(10) + ; 
       "                                  Clique <enter> para continuar...") 

			lMsErroAuto    := .F.
			lAutoErrNoFile := .T. 					// --> Para gravação do LOG. 

			MsExecAuto({|v,x,y,z,w| MATA120(v,x,y,z,w)} , 1 , aCabec , aItFil , 3 , .F.) 



			If !lMsErroAuto 
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (SC7)Pedido/Documento ["+cDoc+"], (EA - segunda tentativa) INCLUSO COM SUCESSO! # "+Chr(13)+Chr(10)+" SC7->C7_NUM: ["+SC7->C7_NUM+"]") 
				dbSelectArea("SC7") 
				SC7->(dbSetOrder(1)) 
				SC7->(dbSeek(xFilial("SC7")+cDoc)) 
				While SC7->(!Eof())  .And.  cDoc == SC7->C7_NUM 
					aAdd(aRecnos , SC7->(Recno())) 
					SC7->(dbSkip()) 
				EndDo 
				If Len(aProcRat) = 1 				// --> Realizar a cópia do Rateio para o novo pedido gerado via: MATA120(1 , aCabec , aItFil , 3) 
					aAreaAux := GetArea() 
					dbSelectArea("SCH")
					SCH->(dbSetOrder(1)) 			// --> Indice 01: CH_FILIAL + CH_PEDIDO + CH_FORNECE + CH_LOJA + CH_ITEMPD + CH_ITEM 
					SCH->(dbSeek(aProcRat[1][02] + aProcRat[1][03] + aProcRat[1][04] + aProcRat[1][05])) 
					While SCH->(!Eof())  .And.  SCH->CH_FILIAL  = aProcRat[1][02]  .And.  SCH->CH_PEDIDO = aProcRat[1][03]  .And. SCH->CH_FORNECE = aProcRat[1][04]  .And.  SCH->CH_LOJA   = aProcRat[1][05]  
						aAdd(aGeraRat , { SCH->CH_FILIAL , cDoc          , SCH->CH_ITEMPD  , SCH->CH_ITEM , SCH->CH_FORNECE , SCH->CH_LOJA   , ; 
						                  SCH->CH_CC     , SCH->CH_CONTA , SCH->CH_ITEMCTA , SCH->CH_CLVL , SCH->CH_PERC    , SCH->CH_CUSTO1 } ) 
						RecLock("SCH",.F.) 
							SCH->(dbDelete()) 
						SCH->(MsUnLock()) 
						SCH->(dbSkip()) 
					EndDo 
					If Len(aGeraRat) > 0 
						For nXX := 1 To Len(aGeraRat) 
							RecLock("SCH",.T.) 
								SCH->CH_FILIAL  := aGeraRat[nXX][01]
								SCH->CH_PEDIDO  := aGeraRat[nXX][02]
								SCH->CH_ITEMPD  := aGeraRat[nXX][03]
								SCH->CH_ITEM    := aGeraRat[nXX][04]
								SCH->CH_FORNECE := aGeraRat[nXX][05]
								SCH->CH_LOJA    := aGeraRat[nXX][06]
								SCH->CH_CC      := aGeraRat[nXX][07]
								SCH->CH_CONTA   := aGeraRat[nXX][08]
								SCH->CH_ITEMCTA := aGeraRat[nXX][09]
								SCH->CH_CLVL    := aGeraRat[nXX][10]
								SCH->CH_PERC    := aGeraRat[nXX][11]
								SCH->CH_CUSTO1  := aGeraRat[nXX][12]
							SCH->(MsUnLock()) 
						Next nXX
					EndIf 
					RestArea(aAreaAux) 
				EndIf 
			Else 
				cErro := "" 
				aErro := GetAutoGRLog() 														// --> So funciona se lAutoErrNoFile estiver .T. 
				For nZ := 1 To Len(aErro) 
					cErro += aErro[nZ] + Chr(13)+Chr(10) 
				Next nZ 
				MsgAlert("Ocorreu um ERRO na segunda tentativa de geração do Pedido de Compras na filial ["+cFil+"] !!!" + Chr(13)+Chr(10) + Chr(13)+Chr(10) + ; 
						 "Acione o administrador do sistema !" + Chr(13)+Chr(10) + Chr(13)+Chr(10) + ; 
				         SubStr(cErro,1,800) + Iif(Len(cErro)>800 , "<continua...>" , "") , "Especifico SELTIT - MEDMATRIZ.prw") 
			
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (SC7)Pedido/Documento ["+cDoc+"], (EA - segunda tentativa) ERRO  NA  INCLUSAO ! # " +Chr(13)+Chr(10)+ cErro ) 
			EndIf 

		EndIf 
	EndIf 

EndIf 

ConOut("##_MEDMATRIZ.prw -- TPMT120() -- (Depois) --> SC7->C7_FILIAL: ["+SC7->C7_FILIAL+"] / SC7->C7_NUM: ["+SC7->C7_NUM+"] ") 

ConOut("##_---------------------------------------------------------------_##")
ConOut("##_MEDMATRIZ.prw -- TPMT120() -- #_FINAL__# "+Time()) 
ConOut("##_---------------------------------------------------------------_##")

cFilAnt := cFilBak 

Return aRecnos 



// ======================================================================= \\
Static Function CheckNroPC(cNumIni , cFilIni) 
// ======================================================================= \\
// --> Incluso  LAVOR 08/06/2021   ( Toda a Funcao ) 

Local aAreaAtu := GetArea() 
Local cSqlPC   := "" 
Local cRetNrPC := "" 

cRetNrPC := cNumIni 

If Select("TRZ1") > 0
	TRZ1->(dbCloseArea())
EndIf
cSqlPC := " Select   DISTINCT C7_NUM , C7_FILIAL , C7_FILENT "                              + Chr(13)+Chr(10) 
cSqlPC += " From     "+RetSqlName("SC7")+" SC7 (NoLock) "                                   + Chr(13)+Chr(10) 
cSqlPC += " Where    SC7.C7_NUM     =  '"+cNumIni+"' "                                      + Chr(13)+Chr(10) 
cSqlPC += "   And  ( SC7.C7_FILIAL  =  '"+cFilIni+"'  Or  SC7.C7_FILENT = '"+cFilIni+"' ) " + Chr(13)+Chr(10) 
cSqlPC += "   And    SC7.D_E_L_E_T_ <> '*' "                                                + Chr(13)+Chr(10) 
cSqlPC += " Order By C7_FILIAL , C7_FILENT "
ConOut("##_MEDMATRIZ.prw   --  CheckNroPC()  --  cSqlPC (1): " + Chr(13)+Chr(10) + cSqlPC) 
cSqlPC := ChangeQuery(cSqlPC) 
TcQuery cSqlPC New Alias "TRZ1" 

If TRZ1->(!Eof()) 
	If Select("TRZ2") > 0
		TRZ2->(dbCloseArea())
	EndIf
	cSqlPC := "" 
	cSqlPC := " Select   Max(C7_NUM) As C7_NUM "              + Chr(13)+Chr(10) 
	cSqlPC += " From     "+RetSqlName("SC7")+" SC7 (NoLock) " + Chr(13)+Chr(10) 
	cSqlPC += " Where    SC7.D_E_L_E_T_ <> '*' "              + Chr(13)+Chr(10) 
	cSqlPC += "   And  ( SC7.C7_FILIAL  =  '"+cFilIni+"'  Or  SC7.C7_FILENT = '"+cFilIni+"' )
ConOut("##_MEDMATRIZ.prw   --  CheckNroPC()  --  cSqlPC (2): " + Chr(13)+Chr(10) + cSqlPC) 
	cSqlPC := ChangeQuery(cSqlPC) 
	TcQuery cSqlPC New Alias "TRZ2" 
	If TRZ2->(!Eof()) 
		cRetNrPC := Soma1(TRZ2->C7_NUM) 
	EndIf 	
EndIf 

If Select("TRZ1") > 0
	TRZ1->(dbCloseArea())
EndIf

If Select("TRZ2") > 0
	TRZ2->(dbCloseArea())
EndIf

RestArea(aAreaAtu) 

Return cRetNrPC
