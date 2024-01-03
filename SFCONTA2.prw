#Include 'Protheus.ch'
#Include 'Parmtype.ch'

/***********************************************************************
Autor: Vinicius N. de Oliveira
Data: 05/12/2022
Consultoria: Prox
Uso: Selfit
Tipo: Validação (Gatilho CNE_QUANT x CNE_XPRINI)
Rotina: Contratos
Função: SFCONTA2
Info: Preenchimento do campo de Preço inicial 
************************************************************************/
User Function SFCONTA2()
	
	Local aArea     := GetArea()
	Local cQuery    := ""
	Local cFilEmp   := SC7->C7_FILIAL
	Local cContrato := SC7->C7_CONTRA
	Local cMedicao  := SC7->C7_MEDICAO
	Local cItemMed  := SC7->C7_ITEMED
	Local cCodProd  := SC7->C7_PRODUTO
	Local cRevisao  := SC7->C7_CONTREV
	local cPlan     := SC7->C7_PLANILH
	Local cTemp     := GetNextAlias()
	Local nPreco    := 0
	
	cQuery := " SELECT CNE_XPRINI AS PRECOINI FROM "+RetSQLName("CNE")
	cQuery += " WHERE CNE_FILIAL = '"+cFilEmp+"'"
	cQuery += "		AND CNE_NUMMED = '"+cMedicao+"'"
	cQuery += " 	AND CNE_CONTRA = '"+cContrato+"'"
	cQuery += " 	AND CNE_ITEM   = '"+cItemMed+"'"
	cQuery += " 	AND CNE_PRODUT = '"+cCodProd+"'"
	cQuery += " 	AND D_E_L_E_T_ <> '*'"
	
	//Verifico se o alias alocado para a tabela já consta como existente, se sim fecho o alias e aloco um novo
	If Select(cTemp) > 0
		(cTemp)->(DbCloseArea())
		cTemp := GetNextAlias()
	Endif
	
	cQuery := ChangeQuery(cQuery)

	ConOut("##_SFCONTA2.prw --  cQuery : "+cQuery) 

	DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTemp,.T.,.T.)
	
	DbSelectArea(cTemp)
	
	(cTemp)->(DbGoTop())
	
	nPreco := (cTemp)->PRECOINI

	(cTemp)->(DbCloseArea())

	//Exceção para contratos que não possuem o valor inicial preenchido na manutenção de contratos 
	If nPreco == 0

		cQuery := ""
		cTemp  := GetNextAlias()	

		cQuery := " SELECT ZB_XPRINI AS PRECOINI FROM "+RetSQLName("SZA")+" SZA"
		cQuery += " INNER JOIN "+RetSQLName("SZB")+" SZB"
		cQuery += " 	ON ZB_FILIAL = ZA_FILIAL"
		cQuery += " 	AND ZB_CODIGO = ZA_CODIGO"
		cQuery += " 	AND SZB.D_E_L_E_T_ <> '*'"
		cQuery += " WHERE ZA_FILIAL = '"+cFilEmp+"'"
		cQuery += " 	AND ZA_NROCONT = '"+cContrato+"'"
		cQuery += " 	AND ZA_REVISA = '"+cRevisao+"'"
		cQuery += "		AND ZA_NROPLAN = '"+cPlan+"'"
		cQuery += " 	AND ZB_PRODUTO = '"+cCodProd+"'"
		cQuery += " 	AND SZA.D_E_L_E_T_ <> '*'"
		
		//Verifico se o alias alocado para a tabela já consta como existente, se sim fecho o alias e aloco um novo
		If Select(cTemp) > 0
			(cTemp)->(DbCloseArea())
			cTemp := GetNextAlias()
		Endif
		
		cQuery := ChangeQuery(cQuery)

		ConOut("##_SFCONTA2.prw -- Contratos com Excecao -- cQuery : "+cQuery) 

		DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTemp,.T.,.T.)
		
		DbSelectArea(cTemp)
		
		(cTemp)->(DbGoTop())
		
		nPreco := (cTemp)->PRECOINI

		(cTemp)->(DbCloseArea())

	Endif 
	
	RestArea(aArea)

Return(nPreco) 
