#INCLUDE "PROTHEUS.CH" 

// Ticket 21960 - controle de mensagem de alerta de nota já incluida com outra série
Static _cNumNf := ""
Static _cSerNf := ""
Static _cForNf := ""
Static _cLojNf := ""

//-------------------------------------------------------------------
/*/{Protheus.doc} SIESTV01
P.E para inserção de zeros no campo de numero das notas na entrada.

@author	  João Carlos Fonseca
@since	  03/02/2014
@version   P11.5
@obs	     Implantação Fiscal.

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------              
User Function SIESTV01()

Local lRetVld  := .T.
Local _cQry    := ""
Local _lExecJob := IsBlind()
Local _cSerie := ""

cNFiscal := StrZero(Val(cNFiscal),TamSX3("F1_DOC")[1])

// Ticket 21960 - se as variáveis de tela da nota existirem deve verificar se a numeração da nota ja existe
if INCLUI .and. !_lExecJob .and. Type("cTipo") == "C" .and. Type("cA100For") == "C" .and. Type("cLoja") == "C" .and. Type("cNFiscal") == "C"
	SF1->( Dbsetorder(1)) // F1_FILIAL+F1_TIPO+F1_DOC+F1_SERIE+F1_FORNECE+F1_LOJA
	if ( ! Empty(cTipo) .and. ! Empty(cA100For) .and.  ! Empty(cLoja) .and. ! Empty(cNFiscal) ) .and.;
					( _cNumNf <> cNFiscal .or. _cSerNf <> cSerie .or. _cForNf <> cA100For .or. _cLojNf <> cLoja)

		// guarda a nota para mostrar a mensagem somente uma vez por digitação 
		_cNumNf := cNFiscal
		_cSerNf := cSerie
		_cForNf := cA100For
		_cLojNf := cLoja

		_cQry := "Select F1_SERIE From "+RetSqlName("SF1")+" "
		_cQry += " Where F1_FILIAL = '"+xFilial("SF1")+"' And F1_FORNECE = '"+cA100For+"' And F1_LOJA = '"+cLoja+"'  "
		_cQry += "   And F1_TIPO = '"+cTipo+"' And F1_DOC = '"+cNFiscal+"' And D_E_L_E_T_ <> '*' "
		DbUseArea(.T.,"TOPCONN",TCGenQry(,,_cQry),"TMPSF1A",.F.,.T.)	

		Do WHile TMPSF1A->( ! Eof())
			// Ticket 21960 - controle de mensagem de alerta de nota já incluida com outra série
			_cSerie += '['+TMPSF1A->F1_SERIE+']' +" - "
			TMPSF1A->( Dbskip())
		Enddo
		TMPSF1A->( DbcloseArea())

		if Len(_cSerie) > 0
			MsgAlert("ATENÇÃO:"+Chr(13)+Chr(13)+"Existem as seguintes séries para este mesmo numero de nota: "+Chr(13)+Chr(13)+"Séries: "+Left(_cSerie,Len(_cSerie)-2)+" ", "SIESTV01")
		Endif	
	Endif
Endif

Return (lRetVld)

