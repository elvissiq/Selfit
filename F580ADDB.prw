#Include 'Protheus.ch'
#Include 'Parmtype.ch'

/***********************************************************************
Autor: Vinicius N. de Oliveira
Data: 08/11/2022
Uso: Financeiro
Tipo: Ponto de Entrada
Rotina: Financeiro
Fun��o: F580ADDB
Info: Inclus�o de bot�es no menu da rotina Libera��o para baixa
************************************************************************/
User Function F580ADDB()

    Local aRet := aClone(ParamIxb[1])
	
	Aadd(aRet,{"Conhecimento","MsDocument('SE2',SE2->(RecNo()),4)",0,4,0,Nil})
	
Return(aRet)
