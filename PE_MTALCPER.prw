#Include 'totvs.ch'
#Include 'Topconn.ch'
#Include 'FWMVCDef.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} MTALCPER
Ponto de entrada executado durante a aprovacao do documento especifico
@author  Talvane Augusto - Tupi Consultoria
@since   07/11/19
@version 1.0
/*/
//-------------------------------------------------------------------

User function MTALCPER()

Local aAlc := {}

If SCR->CR_TIPO == "TP"
    aAdd( aAlc, { SCR->CR_TIPO, 'SZM', 1, 'SZM->ZM_NUMMED',{|| } ,{|| } , { 'SZM->ZM_BLQAVL', "A", "", "2" } } )
EndIf

If SCR->CR_TIPO == "ZM"
    aAdd( aAlc, { SCR->CR_TIPO, 'SZM', 1, 'SZM->ZM_NUMMED',{|| } ,{|| } , { 'SZM->ZM_BLQQTD', "A", "", "2" } } )
EndIf

If SCR->CR_TIPO == "ZU"
    aAdd( aAlc, { SCR->CR_TIPO, 'CND', 1, 'CND->CND_NUMMED',{|| } ,{|| } , { 'CND->CND_SITUAC', "A", "", "2" } } )
EndIf                                   

If SCR->CR_TIPO == "ZV"
    aAdd( aAlc, { SCR->CR_TIPO, 'SZV', 1, 'SZV->ZV_CODIGO',{|| } ,{|| } , { 'SZV->ZV_STATUS', "A", "", "2" } } )
EndIf        

Return aAlc


User Function TpGerAlc( cFilOri, cNumMed, cPlanil, cFilRef, nVlrTot, nGrpAprov )

Local cTipo  := "TP"
Local nOper  := 1
Local nMoeda := 1

cFilAnt := cFilRef

MaAlcDoc( { cNumMed, cTipo, nVlrTot, , , nGrpAprov, , nMoeda, , dDataBase } , , nOper )

Return

User Function TpGerMed( cFilOri, cNumMed, cPlanil, cFilRef, nVlrTot, nGrpAprov,cTp )

Local cTipo  := cTp
Local nOper  := 1
Local nMoeda := 1

cFilAnt := cFilRef

MaAlcDoc( { cNumMed, cTipo, nVlrTot, , , nGrpAprov, , nMoeda, , dDataBase } , , nOper )

Return