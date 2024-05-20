#Include "Totvs.ch"
User Function RelEVO()
	Local aPergs	 := {}
	Local cQuery	 := ""
	Private oReport  := Nil
	Private oSecCab	 := Nil

	aAdd(aPergs,{1,"De filial: ",Space(TamSx3('F2_FILIAL')[1]),"","","SM0","",50,.F.})    //MV_PAR01
	aAdd(aPergs,{1,"Ate filial: ",Space(TamSx3('F2_FILIAL')[1]),"","","SM0","",50,.F.})   //MV_PAR02
	aAdd(aPergs,{1,"De Emissão ",Date()   , "", ".T.", "", ".T.", 80 , .F.}) //MV_PAR03
	aAdd(aPergs,{1,"Ate Emissão ",Date()   , "", ".T.", "", ".T.", 80 , .T.}) //MV_PAR04
	aAdd(aPergs,{1,"De Cliente ",Space(TamSx3('F2_CLIENTE')[1]),"","","SA1","",50,.F.}) 		        //MV_PAR05
	aAdd(aPergs,{1,"Ate Cliente ",Space(TamSx3('F2_CLIENTE')[1]),"","","SA1","",50,.F.}) 		        //MV_PAR06
	aAdd(aPergs,{1,"De  NF ",Space(TamSx3('F2_DOC')[1]),"","","SF2","",50,.F.}) 		        //MV_PAR07
	aAdd(aPergs,{1,"Ate NF ",Space(TamSx3('F2_DOC')[1]),"","","SF2","",50,.F.})		        //MV_PAR08

	If !ParamBox(aPergs,"Informe os Parametros ")
		Return
	EndIf

	cQuery := "	SELECT F2_FILIAL, F2_DOC,F2_SERIE, F2_CLIENTE,F2_LOJA, A1_NREDUZ ,         "
	cQuery += "	F2_EMISSAO,F2_VALBRUT ,F2_VALIMP6 ,F2_VALIMP5 ,F2_VALISS                    "
	cQuery += " FROM " +RetSqlName("SF2") + " SF2                                          "
	cQuery += "	INNER JOIN  " +RetSqlName("SA1") + " SA1                                   "
	cQuery += " ON SA1.A1_COD = SF2.F2_CLIENTE AND SA1.A1_LOJA = SF2.F2_LOJA               "
	cQuery += " WHERE SF2.F2_FILIAL BETWEEN '"+MV_PAR01+"' AND '"+MV_PAR02+"'              "
	cQuery += " AND SF2.F2_EMISSAO  BETWEEN '"+DtoS(MV_PAR03)+"' AND '"+DtoS(MV_PAR04)+"'  "
	cQuery += " AND SF2.F2_CLIENTE  BETWEEN '"+MV_PAR05+"' AND '"+MV_PAR06+"'              "
	cQuery += " AND SF2.F2_DOC      BETWEEN '"+MV_PAR07+"' AND '"+MV_PAR08+"'              "
	cQuery += " ORDER BY SF2.F2_DOC                                                         "
   
	MpSysOpenQuery(cQuery,"cQry")

	oReport := reportDef()
	oReport:printDialog()

Return

Static Function reportDef()
	local oReport
	Local oSection1
	local cTitulo := ' Relatorio EVO de '+DtoC(MV_PAR03)+' Até '+DtoC(MV_PAR04)+' ' //titulo do relatorio
	oReport := TReport():New('RELEVO', cTitulo, , {|oReport| PrintReport(oReport)},'Relatorio EVO')
	oReport:SetPortrait()

	//Primeira sessao
	oSection1:= TRSection():New(oReport, "Relatorio de Apuração Retidos", {"cQry"}, , .F., .T., , , ,.F., .F.)
	oSection1:SetHeaderSection(.T.)
	TRCell():new(oSection1, "F2_FILIAL"   , "cQry", 'FILIAL'	   ,PesqPict('SF2',"F2_FILIAL")   ,TamSX3("F2_FILIAL")[1]+2   ,,,  "LEFT"    ,,    "LEFT"  )
	TRCell():new(oSection1, "F2_DOC"      , "cQry", 'DOCUMENTO'	   ,PesqPict('SF2',"F2_DOC")      ,TamSX3("F2_DOC")[1]+2      ,,,  "LEFT"    ,,    "LEFT"  )
	TRCell():new(oSection1, "F2_SERIE"    , "cQry", 'SERIE'	       ,PesqPict('SF2',"F2_SERIE")    ,TamSX3("F2_SERIE")[1]+2    ,,,  "CENTER"  ,,    "CENTER")
	TRCell():new(oSection1, "A1_NREDUZ"   , "cQry", 'CLIENTE'	   ,PesqPict('SA1',"A1_NREDUZ")   ,TamSX3("A1_NREDUZ")[1]+30  ,,,  "LEFT"    ,,    "LEFT"  )
	TRCell():new(oSection1, "F2_EMISSAO"  , "cQry", 'EMISSAO'	   ,PesqPict('SF2',"F2_EMISSAO")  ,TamSX3("F2_EMISSAO")[1]+2  ,,,  "CENTER"  ,,    "CENTER")
	TRCell():new(oSection1, "F2_VALBRUT"  , "cQry", 'VALOR'	       ,PesqPict('SF2',"F2_VALBRUT")  ,TamSX3("F2_VALBRUT")[1]+2  ,,,  "RIGHT"   ,,    "RIGHT" )
	TRCell():new(oSection1, "F2_VALISS"   , "cQry", 'VALOR ISS'	   ,PesqPict('SF2',"F2_VALISS")   ,TamSX3("F2_VALISS")[1]+2   ,,,  "RIGHT"   ,,    "RIGHT" )
	TRCell():new(oSection1, "F2_VALIMP6"  , "cQry", 'VALOR PIS'   ,PesqPict('SF2',"F2_VALIMP6")  ,TamSX3("F2_VALIMP6")[1]+2   ,,,  "RIGHT"   ,,    "RIGHT" )
	TRCell():new(oSection1, "F2_VALIMP5"   , "cQry",'VALOR COFI'	   ,PesqPict('SF2',"F2_VALIMP5")   ,TamSX3("F2_VALIMP5")[1]+2   ,,,  "RIGHT"   ,,    "RIGHT" )


return (oReport)

Static Function PrintReport(oReport)
	Local oSection1 := oReport:Section(1)
	Local nTotISS  := 0
	Local nTot     := 0
	Local nTotPIS  := 0
	Local nTotCOFI := 0
	DbSelectArea('cQry')
	cQry->(dbGoTop())
	oReport:SetMeter(cQry->(RecCount()))
	oReport:IncMeter()
	oSection1:Init()
	oReport:SkipLine()

	While cQry->(!Eof())

		If oReport:Cancel()
			Exit
		EndIf

		oSection1:Cell("F2_FILIAL"):SetValue(cQry->F2_FILIAL)
		oSection1:Cell("F2_DOC"):SetValue(cQry->F2_DOC)
		oSection1:Cell("F2_SERIE"):SetValue(cQry->F2_SERIE)
		oSection1:Cell("A1_NREDUZ"):SetValue(cQry->A1_NREDUZ)
		oSection1:Cell("F2_EMISSAO"):SetValue(sTod(cQry->F2_EMISSAO))
		oSection1:Cell("F2_VALBRUT"):SetValue(cQry->F2_VALBRUT)
		oSection1:Cell("F2_VALISS"):SetValue(cQry->F2_VALISS)
		oSection1:Cell("F2_VALIMP5"):SetValue(cQry->F2_VALIMP5)
		oSection1:Cell("F2_VALIMP6"):SetValue(cQry->F2_VALIMP6)
		oSection1:PrintLine()

		nTot     += cQry->F2_VALBRUT
		nTotISS  += cQry->F2_VALISS
		nTotPIS  += cQry->F2_VALIMP5
		nTotCOFI += cQry->F2_VALIMP6


		cQry->(DbSkip())
	Enddo
	oSection1:Cell("F2_FILIAL"):SetValue(" ")
	oSection1:Cell("F2_DOC"):SetValue(" ")
	oSection1:Cell("F2_SERIE"):SetValue(" ")
	oSection1:Cell("A1_NREDUZ"):SetValue("TOTAL ---------> ")
	oSection1:Cell("F2_EMISSAO"):SetValue(" ")
	oSection1:Cell("F2_VALBRUT"):SetValue(nTot)
	oSection1:Cell("F2_VALISS"):SetValue(nTotISS)
	oSection1:Cell("F2_VALIMP5"):SetValue(nTotPIS)
	oSection1:Cell("F2_VALIMP6"):SetValue(nTotCOFI)
	oSection1:PrintLine()

	oSection1:Finish()
	cQry->(DbCloseArea())

return
