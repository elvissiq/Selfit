#Include 'Protheus.ch'
#Include 'Parmtype.ch'

/***********************************************************************
Autor: Vinicius N. de Oliveira
Data: 08/11/2022
Uso: Financeiro
Tipo: Ponto de Entrada
Rotina: Financeiro
Função: F580ADDB
Info: Inclusão de botões no menu da rotina Liberação para baixa
************************************************************************/
User Function F580ADDB()

    Local aRet := aClone(ParamIxb[1])
	
	Aadd(aRet,{"Conhecimento","MsDocument('SE2',SE2->(RecNo()),4)",0,4,0,Nil})
	
Return(aRet)
