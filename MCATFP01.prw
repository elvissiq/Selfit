#Include 'Protheus.ch'
#Include 'FwMVCDef.ch'
 
//-------------------------------------------------------------------
/*/{Protheus.doc} MCATFP01
MarkBrowse Classificacao em Lote.

@protected
@author    Ederson Colen.
@since     08/06/2017
@obs       

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------
User Function MCATFP01()

Local cDtUlDep	:= DToS(GetMV('MV_ULTDEPR')) 
Local cFiltro 	:= ""

Private oMark

chkFile("SN1")

If SubStr(cDtUlDep,5,2) == "12"
	cDtUlDep := StrZero(Val(Left(cDtUlDep,4))+1,4)+"0201"
Else
	cDtUlDep := Left(cDtUlDep,4)+StrZero(Val(SubStr(cDtUlDep,5,2))+2,2)+"01"
EndIf

cFiltro := "'NFE' $ SN1->N1_CBASE .AND. DTOS(SN1->N1_AQUISIC) < '"+cDtUlDep+"'"
     
//Criando o MarkBrow
oMark := FWMarkBrowse():New()
oMark:SetAlias('SN1')
 
//Setando semáforo, descrição e campo de mark
oMark:SetSemaphore(.T.)
oMark:SetDescription('Classificação Compras em Lote')
oMark:SetFieldMark('N1_OK')
oMark:SetFilterDefault(cFiltro)
 
//Ativando a janela
oMark:Activate()

Return NIL


 
//-------------------------------------------------------------------
/*/{Protheus.doc} MenuDef
Rotina MenuDef.

@protected
@author    Ederson Colen.
@since     08/06/2017
@obs       

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------
Static Function MenuDef()
Local aRotina := {}
 
//Criação das opções
ADD OPTION aRotina TITLE 'Visualizar'	ACTION 'VIEWDEF.ATFA012' OPERATION 2 ACCESS 0
ADD OPTION aRotina TITLE 'Classificar'	ACTION 'U_MCATFP02()'     OPERATION 2 ACCESS 0

Return aRotina
 


//-------------------------------------------------------------------
/*/{Protheus.doc} ModelDef
ModelDef (Carrega do Ativo Fixo)

@protected
@author    Ederson Colen.
@since     08/06/2017
@obs       

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------
Static Function ModelDef()
Return FWLoadModel('ATFA012')


 
//-------------------------------------------------------------------
/*/{Protheus.doc} ViewDef()
Carrega a ViewDef do Cadastro de Ativo.

@protected
@author    Ederson Colen.
@since     08/06/2017
@obs       

Alteracoes Realizadas desde a Estruturacao Inicial
Data       Programador     Motivo
/*/
//-------------------------------------------------------------------
Static Function ViewDef()
Return FWLoadView('ATFA012')
