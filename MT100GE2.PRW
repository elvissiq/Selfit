#include "protheus.ch"
#include "parmtype.ch"

//--------------------------------------------------------------------------|
// FUNÇÃO: GRAVACC | DATA: 10/10/17 | DESENV.: SEMAR-EDUARDO SALES                |
// DESCRIÇÃO: GRAVAR CENTRO DE CUSTO NO CONTAS A PAGAR
//--------------------------------------------------------------------------|

User Function MT100GE2()

Local aArea    := GetArea()
Local cChaveP  := ""
Local nOpc     := PARAMIXB[2]
Local cTitulo  := "Alterar Vencimento"
Local cTexto   := "Vencimento:"
Local dVencto  := CriaVar("E2_VENCREA",.T.)

Private oDlg   := Nil

dbSelectArea("SD1")
DBSETORDER(1)
SD1->(DBSEEK(xFilial("SD1")+SF1->F1_DOC+SF1->F1_SERIE+SF1->F1_FORNECE+SF1->F1_LOJA,.T.))

//OSCAR 17/05/2022 - INCLUSÃO DA CHAVE PIX NO TÍTULO A PAGAR
cChaveP := Posicione("SA2",1,xFilial("SA2") + SF1->F1_FORNECE + SF1->F1_LOJA, "A2_XCHAVEP")

DbSelectArea("SE2")
SE2->(DbSetOrder(6))

If SE2->(DbSeek(xFilial("SE2")+SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC))

	While !Eof() .and. SE2->E2_FILIAL == xFilial("SE2") .and. (SE2->E2_FORNECE+SE2->E2_LOJA+SE2->E2_PREFIXO+SE2->E2_NUM == SF1->F1_FORNECE+SF1->F1_LOJA+SF1->F1_SERIE+SF1->F1_DOC)

		Reclock("SE2",.F.)
		SE2->E2_CCUSTO := SD1->D1_CC
		SE2->E2_XCHAVEP := cChaveP
		SE2->(MsUnlock())
		
		//incluso por Vinicius N. de Oliveira - 09/03/2023 - Ticket: 31163
		If nOpc == 1 //Inclusão 
			Reclock("SE2",.F.)
			SE2->E2_XUSRLGI := AllTrim(SubStr(cUsuario,7,15)) //Login do usuário que realizou a inclusão
			SE2->(MsUnlock())
		Endif 
		// ---

		If SE2->E2_VENCREA < Date()

			MsgAlert("O título possui uma data inferior a data do dia de hoje! Favor realizar a alteração da data!")

			DEFINE MSDIALOG oDlg TITLE cTitulo FROM 000,000 TO 180,380 PIXEL STYLE DS_MODALFRAME
	
			@005,005 TO 060,180 OF oDlg PIXEL
			@015,020 SAY cTexto SIZE 040,007 OF oDlg PIXEL
			@012,080 MSGET dVencto SIZE 055,011 OF oDlg PIXEL 
			
			DEFINE SBUTTON FROM 070,025 TYPE 1 ACTION IIf(dVencto >= Date(),xAtuVencto(oDlg,dVencto),MsgAlert("Favor informar uma data maior ou igual a data de hoje!","Atenção")) ENABLE OF oDlg
			//DEFINE SBUTTON FROM 070,145 TYPE 2 ACTION oDlg:End() ENABLE OF oDlg
		
			ACTIVATE MSDIALOG oDlg CENTERED

		Endif 

		SE2->(DbSkip())

	EndDo

EndIf

RestArea(aArea)

Return

/*=================================================================
Autor: Vinicius N. de Oliveira
Data: 01/06/2023
Info: Data de vencimentno do título
*==================================================================*/	
Static Function xAtuVencto(oDlg,dVencto)

	RecLock("SE2",.F.)
	SE2->E2_VENCTO  := dVencto 
	SE2->E2_VENCREA := DataValida(dVencto,.T.)
	SE2->(MsUnlock())

	oDlg:End()

Return 
