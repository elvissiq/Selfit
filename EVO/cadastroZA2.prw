#include "protheus.ch"


User Function cadZA2()
	Local aArea    := GetArea()
	Local aAreaZA2  := ZA2->(GetArea())
	Local cDelOk   := ".T."
	Local cFunTOk  := ".T."

	//Chamando a tela de cadastros
	AxCadastro('ZA2', 'Amarração id Evo e Filial Protheus', cDelOk, cFunTOk)

	RestArea(aAreaZA2)
	RestArea(aArea)
Return



User Function cadZA3()
	Local aArea    := GetArea()
	Local aAreaZA3  := ZA3->(GetArea())
	Local cDelOk   := ".T."
	Local cFunTOk  := ".T."

	//Chamando a tela de cadastros
	AxCadastro('ZA3', 'Erros integração API EVO', cDelOk, cFunTOk)

	RestArea(aAreaZA3)
	RestArea(aArea)
Return
