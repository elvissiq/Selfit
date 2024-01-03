#include 'totvs.ch'
/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
ฑฑษออออออออออัออออออออออหอออออออัออออออออออออออออออออหออออออัอออออออออออออปฑฑ
ฑฑบPrograma  ณMTA110MNU บAutor  ณCristiam Rossi      บ Data ณ  23/08/18   บฑฑ
ฑฑฬออออออออออุออออออออออสอออออออฯออออออออออออออออออออสออออออฯอออออออออออออนฑฑ
ฑฑบDesc.     ณ P.E. adicionar itens no menu Solicita็ใo de Compras        บฑฑ
ฑฑบ          ณ                                                            บฑฑ
ฑฑฬออออออออออุออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออนฑฑ
ฑฑบUso       ณ SELFIT                                                     บฑฑ
ฑฑศออออออออออฯออออออออออออออออออออออออออออออออออออออออออออออออออออออออออออผฑฑ
ฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑฑ
฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿฿
*/
user function MTA110MNU()
	aadd(aRotina, { "Pr้ Cadastro"		, "u_preCad", 0 , 6, 0, .F.})
	aadd(aRotina, { "Inclui SC via CSV" , "U_SFCMP10", 0 , 6, 0, .F.})  // ticket 21875 

	if "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername 
		aadd(aRotina, { "INTRALOX Follow Up" , "U_IXFAT01", 0 , 6, 0, .F.})
	Endif

	if "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername 
		aadd(aRotina, { "Transf.Armazem" , "U_R7EST003", 0 , 6, 0, .F.})
		aadd(aRotina, { "Bloqueia Armazem" , "U_R7EST004", 0 , 6, 0, .F.})
	Endif

	if cEmpAnt == "ZO" .and. ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername )
		if FindFunction("U_FISRZO01")
			aadd(aRotina, { "Rel.Quebra Seq." , "U_FISRZO01", 0 , 3, 0, .F.})
		Endif	
	Endif

	if cEmpAnt == "FG" .and.( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_FISRZO01")
			aadd(aRotina, { "Importa็ใo de XML" , "U_FISFG001", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_FTBER001")
			aadd(aRotina, { "Romaneio de Venda" , "U_FTBER001", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFFINR01")
			aadd(aRotina, { "SELFIT Relatorio Baixas " , "U_SFFINR01", 0 , 3, 0, .F.})
		Endif	
	Endif
	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFCMR04")
			aadd(aRotina, { "SELFIT Posicao Fornecedores" , "U_SFCMR04", 0 , 3, 0, .F.})
		Endif	
	Endif
	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFFiR350")
			aadd(aRotina, { "SELFIT Posicao Fornecedores Compras" , "U_SFFiR350", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFCMR01")
			aadd(aRotina, { "SELFIT Notas Excluidas " , "U_SFCMR01", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFATVR01")
			aadd(aRotina, { "SELFIT Posi็ใo Valorizada " , "U_SFATVR01", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_CTBR040")
			aadd(aRotina, { "SELFIT Balancete OLD " , "U_CTBR040", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFCMR02")
			aadd(aRotina, { "SELFIT Novo Balancete " , "U_SFCMR02", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFCMR03")
			aadd(aRotina, { "SELFIT Novo Contas Pagar " , "U_SFCMR03", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFCMX08")
			aadd(aRotina, { "SELFIT Compras SC x PC" , "U_SFCMX08", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFCMR05")
			aadd(aRotina, { "SELFIT Relatorio Notas Entrada " , "U_SFCMR05", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_FISRZO01")
			aadd(aRotina, { "Quebra Seq. AUTOZONE" , "U_FISRZO01", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_ZOFAT002")
			aadd(aRotina, { "Importa Planilha AUTOZONE" , "U_ZOFAT002", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_ZLCTB003")
			aadd(aRotina, { "Importa People AUTOZONE" , "U_ZLCTB003", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_TSPDFIS02")
			aadd(aRotina, { "Teste SPED AUTOZONE" , "U_TSPDFIS02", 0 , 3, 0, .F.})
		Endif	
	Endif


	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_FISNN001")
			aadd(aRotina, { "BROWN IMP XML" , "U_FISNN001", 0 , 3, 0, .F.})
		Endif	
	Endif
	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_FIS50001")
			aadd(aRotina, { "AKAMAI IMP XML" , "U_FIS50001", 0 , 3, 0, .F.})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_MT097APR")
			Aadd(aRotina,{"AUTOZONE envio PC","U_MT097APR",0,3,0,NIL})
		Endif	
	Endif

	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_INTPRYOR")
			Aadd(aRotina,{"AUTOZONE Importa็๕es","U_INTPRYOR",0,2,0,NIL})
		Endif
	Endif

//	if ( "aldo.santos" $ cUsername .or. "aldo.prox" $ cUsername)
		if FindFunction("U_SFCMP09")
			aadd(aRotina, { "Importa Rateios" , "U_SFCMP09", 0 , 6, 0, .F.})
		Endif	
//	Endif	

return nil



/*
AUTOZONE - IMPORTACAO DE DADOS
*/
User Function FISRZO02()
Local cCpo := "<>;SKU;DESCRIวรO;QTD FISICA;QTD NOTA ;QTD RTBD;Vlr Produto ;Vlr Parcial ;Base ICMS;Alq. ICMS;Vlr ICMS;Alq. IPI;Vlr IPI;BC p/ Calc. ICMS ST;MVA;Vlr MVA;BC ICMS ST;Aliq. ICMS ST;Vlr ICMS ST BRUTO;ICMS ST ;Desp. Acess.;Vlr NF;NF DEV Nบ;DATA EMISSรO;EAN CODIGO;Cfop DEV;UN - MEDIDA;NCM;CST;Dt Operacao;Dt Emissao;Chave NFe;CNPJ/CPF;Descricao;UF;Sequencial;CFOP;Natureza;C.Fiscal;Estoque Fisico;Custo;Produto;Descricao;Ori.Des;Descontos;Quantidade;Vlr Produto ;Vlr Parcial ;Vlr ICMS ;Vlr ICMS N/C;Alq IPI ;Vlr IPI ;Vlr IPI N/C;Vlr II ;Alq PIS;Vlr PIS ;Alq COFINS;Vlr COFINS ;COFINS Dev.;Alq SUBS;MVA-ST;Vlr SUBS ;Vlr SUBS N/C;Vlr INSS;Base INSS;Base ICMS;Base SUBS;Base IPI;Vencimentos ;Tx.Rateio ;Oper Ctb ;C/Fiscal;COR+CCU+CRT;C.Medio Unit;Desp.Aces.;Frete;Munc.Frete;Observacao ;Sit.Trib. "

cChave := "35220414310170000349550020000908721640004655"
cSerie := Substr(cChave,23,3)
cNf    := Substr(cChave,26,9)
cEmissor := Substr(cNf,07,14)

/*
FALTA DATA DE EMISSAO
FALTA NUMERO E SERIE DA NOTA

// Opera็ใo G = Devolu็ใo de Consigna็ใo
// tes = 5AT = Devolu็ใo de compra
/*
Notas geradas 000000010-2 e 000000011-2
exemplo
Nota  043684003
Serie 1 (ou Z)
Fornecedor 66539370000100
Produto 100036780
Item 0010
Qtd 4
Valor 123.8440
CHAVE 35220266539370000100550010000436841000189269
*/


Return


