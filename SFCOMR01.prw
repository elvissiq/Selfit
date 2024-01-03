#Include 'Protheus.ch'
#Include 'Parmtype.ch'

/***********************************************************************
Autor: Vinicius N. de Oliveira
Data: 05/01/2023
Consultoria: Prox 
Uso: Selfit
Tipo: Relatório
Rotina: Faturamento
Função: SFCOMR01
Info: Relatório SD1
************************************************************************/
User Function SFCOMR01()

	Local oReport := Nil
	Local cPerg   := Padr("SFCOMR01",10)
    Local aArea   := GetArea()
	
	Private aCabec := {}

	//Incluo/Altero as perguntas na tabela SX1
	AjustaSX1(cPerg)

	//Gero a pergunta
	If Pergunte(cPerg,.T.)
		
		xFilSX3()
		
		If Len(aCabec) > 0
			oReport := xCabecRel(cPerg)
			oReport:PrintDialog()
		Else 	
			MsgAlert("Não foram encontrados registro para o cabeçalho do relatório! Favor contatar o administrador!","Atenção")
		Endif 
		
	Endif 
	
	RestArea(aArea)
	
Return

/*=================================================================
Autor: Vinicius N. de Oliveira
Data: 05/01/2023
Consultoria: Prox
Uso: Selfit
Info: Cabeçalho do relatório  
*==================================================================*/
Static Function xCabecRel(cPerg)

	Local oReport   := Nil
	Local oSection1 := Nil
	Local nX        := 0

	oReport := TReport():New(cPerg,"Relatório SD1",cPerg,{|oReport| xFilDados(oReport)},"Relatório SD1")

	oReport:SetPortrait()
	oReport:SetTotalInLine(.F.)

	oSection1 := TRSection():New(oReport,"Relatório SD1", {""}, Nil, .F., .T.)

	//Cabeçalho
	For nX := 1 To Len(aCabec)
		
		If AllTrim(aCabec[nX,1]) == "D1_LOJA" 
			TRCell():New(oSection1,aCabec[nX,1]     ,"TMP",aCabec[nX,2]      ,aCabec[nX,4],aCabec[nX,3])
			TRCell():New(oSection1,"Nome Fornecedor","TMP","Nome Fornecedor" ,"@!",250)
		Else 
			TRCell():New(oSection1,aCabec[nX,1] ,"TMP",aCabec[nX,2] ,aCabec[nX,4],aCabec[nX,3])
		Endif 		

	Next nX	

	oReport:SetTotalInLine(.T.)

	//Quebra por seção
	oSection1:SetPageBreak(.T.)
	oSection1:SetTotalText(" ")

Return(oReport)

/*=================================================================
Autor: Vinicius N. de Oliveira
Data: 05/01/2023
Consultoria: Prox
Uso: Laborental
Info: Filtra os dados do relatório
*==================================================================*/
Static Function xFilDados(oReport)

	Local oSection1 := oReport:Section(1)
	Local cQuery    := ""
	Local cTemp     := GetNextAlias()
	Local nX        := 0 
	Local nQtdRegs  := Len(aCabec)	
	
	cQuery += " SELECT "
	
	For nX := 1 To Len(aCabec)

		cQuery += aCabec[nX,1]
		
		If nX < nQtdRegs
			cQuery += ","
		Endif 
		
	Next nX	
	
	cQuery += " FROM "+RetSQLName("SD1")
	cQuery += " WHERE D1_FILIAL BETWEEN '"+mv_par01+"' AND '"+mv_par02+"'"
	cQuery += " 	AND D1_DTDIGIT BETWEEN '"+DToS(mv_par03)+"' AND '"+DToS(mv_par04)+"'"
	cQuery += " 	AND D1_FORNECE BETWEEN '"+mv_par05+"' AND '"+mv_par08+"'"
	cQuery += " 	AND D1_LOJA BETWEEN '"+mv_par06+"' AND '"+mv_par07+"'"
	cQuery += " 	AND D_E_L_E_T_ <> '*'"

	If Select(cTemp) > 0
    	(cTemp)->(DbCloseArea())
    	cTemp := GetNextAlias()
    Endif
	
	cQuery := ChangeQuery(cQuery)
    
    DbUseArea(.T.,"TOPCONN",TcGenQry(,,cQuery),cTemp,.F.,.T.)

	DbSelectArea(cTemp)
	(cTemp)->(DbGoTop())
		
	While !((cTemp)->(Eof()))
	// --

		//Retorna se o relatório foi cancelado pelo usuário
		If oReport:Cancel()
			Exit
		Endif
		// ---

		//Inicializo a primeira seção
		oSection1:init()
		// ---

		//Régua de processamento na tela - total de registros processados no relatório
		oReport:IncMeter() 

		//Gravo as informações filtradas na query
		For nX := 1 To Len(aCabec)
		
			If AllTrim(aCabec[nX,1]) == "D1_LOJA" 
				oSection1:Cell(aCabec[nX,1]):SetValue((cTemp)->&(aCabec[nX,1]))
				oSection1:Cell("Nome Fornecedor"):SetValue(AllTrim(Posicione("SA2",1,xFilial("SA2") + (cTemp)->D1_FORNECE + (cTemp)->D1_LOJA,"A2_NOME")))	
			Else 
				oSection1:Cell(aCabec[nX,1]):SetValue((cTemp)->&(aCabec[nX,1])) 
			Endif
			
		Next nX 		
		
		//Gravar conteúdo na primeira seção
		oSection1:Printline()
		
		//Posiciono no próximo registro
		(cTemp)->(DbSkip())
		// ---
	
	EndDo
	// ---

	//Finalizo a primeira seção
	oSection1:Finish()
	// ---

	(cTemp)->(DbCloseArea())

Return

/*=================================================================
Autor: Vinicius N. de Oliveira
Data: 05/01/2023
Consultoria: Prox
Uso: Laborental
Info: Filtra os dados do cabeçalho
*==================================================================*/
Static Function xFilSX3()

	//Varredura na tabela para pegar os registros referente ao álias informado
	DbSelectArea("SX3")
	SX3->(DbSetOrder(1))

	If SX3->(DbSeek("SD1"))

		While !SX3->(EOF())
		
			If AllTrim(SX3->X3_ARQUIVO) == "SD1" 
				If !AllTrim(SX3->X3_CAMPO) $ 'D1_OPER|D1_GERAPV|D1_CODGRP|D1_CODITE|D1_DESEST|D1_ITEMMED|D1_LEGENDA|D1_ITXML'
					aAdd(aCabec,{SX3->X3_CAMPO,SX3->X3_TITULO,SX3->X3_TAMANHO,SX3->X3_PICTURE})
				Endif 
			Endif
			
			SX3->(DbSkip())
			
		EndDo

	Endif

Return

/*=================================================================
Autor: Vinicius N. de Oliveira
Data: 05/01/2023
Consultoria: Prox
Uso: Selfit
Info: Perguntas da SX1
*==================================================================*/
Static Function AjustaSX1(cPerg)

	Local aRegs := {}
	Local I, J

	//Adiciono um novo elemento no final do array
	aAdd(aRegs,{cPerg,"01","Filial de?"        ,"","","mv_ch1","C",04,00,0,"G","","mv_par01","","","","","","","","","","","","","","","","","","","","","","","","","SM0"})
	aAdd(aRegs,{cPerg,"02","Filail até?"       ,"","","mv_ch2","C",04,00,0,"G","","mv_par02","","","","","","","","","","","","","","","","","","","","","","","","","SM0"})	
	aAdd(aRegs,{cPerg,"03","Dt.Digitação de?"  ,"","","mv_ch3","D",08,00,0,"G","","mv_par03","","","","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"04","Dt.Digitação até?" ,"","","mv_ch4","D",08,00,0,"G","","mv_par04","","","","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"05","Fornecedor de?"    ,"","","mv_ch5","C",06,00,0,"G","","mv_par05","","","","","","","","","","","","","","","","","","","","","","","","","SA2"})
	aAdd(aRegs,{cPerg,"06","Loja de?"          ,"","","mv_ch6","C",02,00,0,"G","","mv_par06","","","","","","","","","","","","","","","","","","","","","","","","",""})
	aAdd(aRegs,{cPerg,"07","Fornecedor até"    ,"","","mv_ch7","C",06,00,0,"G","","mv_par07","","","","","","","","","","","","","","","","","","","","","","","","","SA2"})
	aAdd(aRegs,{cPerg,"08","Loja até?"         ,"","","mv_ch8","C",02,00,0,"G","","mv_par08","","","","","","","","","","","","","","","","","","","","","","","","",""})
	
	DbSelectArea("SX1")
	DbSetOrder(1)
	
	For I := 1 To Len(aRegs)
		If !DbSeek(cPerg + aRegs[I,2])
			RecLock("SX1",.T.)
			For J := 1 To FCount()
				If J <= Len(aRegs[I])
					FieldPut(J,aRegs[I,J])
				Endif
			Next
			SX1->(MsUnlock())
		Endif
	Next

Return
 