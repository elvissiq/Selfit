#Include 'Protheus.ch'
#Include 'Parmtype.ch'

/***********************************************************************
Autor: Vinicius N. de Oliveira
Data: 14/07/2023
Consultoria: Prox
Uso: Selfit
Tipo: Ponto de Entrada 
Rotina: Compras
Função: MT120ISC
Info: 
************************************************************************/
User Function MT120ISC()

	Local nPosPrc  := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_PRECO"}) 
	Local nPosTot  := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_TOTAL"})
	Local nPosDesc := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_DESCRIC"}) 
	Local nPosNome := aScan(aHeader,{|x| AllTrim(x[2]) == "C7_NOMEFOR"})

 	//Variavel 'n' é do MATA120
	aCols[n,nPosPrc]  := SC1->C1_VUNIT
	aCols[n,nPosTot]  := (SC1->C1_QUANT - SC1->C1_QUJE) * SC1->C1_VUNIT
	aCols[n,nPosDesc] := SC1->C1_DESCRIC
	aCols[n,nPosNome] := SA2->A2_NOME

Return(.T.) 
