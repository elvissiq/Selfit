#include "rwmake.ch"        

/*
+-------------------------------------------------------------------+
|Programa | MTA130C8 | Autor Juliana Hilarina    | Data |  01/12/15 |
|---------+---------------------------------------------------------|
|Desc.    |Ponto de Entrada para gravar informacao C7 p/ D1         |       
|         |                                                         |
|---------+---------------------------------------------------------|        
|Uso      |SELFIT                                                   |
|         |                                                         |        
+-------------------------------------------------------------------+

*/

User Function MT103IPC()

Local cNumIteA := PARAMIXB
Local cNumIteB := PARAMIXB[01]

Local aArqSC8 := {"SC8",SC8->(IndexOrd()),SC8->(Recno())}
Local aArqSC7 := {"SC7",SC7->(IndexOrd()),SC7->(Recno())}
Local aArqSD1 := {"SD1",SD1->(IndexOrd()),SD1->(Recno())}     
Local nPosDesc   := aScan(aHeader,{|aAux1|AllTrim(aAux1[2]) == "D1_DESCRI"})
Local nPosDesc1   := aScan(aHeader,{|aAux1|AllTrim(aAux1[2]) == "D1_DESCRIC"})     
Local nPosForn   := aScan(aHeader,{|aAux1|AllTrim(aAux1[2]) == "D1_NOMEFOR"})
Local nxI := cNumIteB //Len(aCols)
Local nxT := 0

aCols[nXI,nPosDesc]  := SC7->C7_DESCRI  
aCols[nXI,nPosDesc1]  := SC7->C7_DESCRIC    
aCols[nXI,nPosForn]  := SC7->C7_NOMEFOR  


dbSelectArea(aArqSC7[1])
dbSetOrder(aArqSC7[2])
dbGoTo(aArqSC7[3])

dbSelectArea(aArqSC8[1])
dbSetOrder(aArqSC8[2])
dbGoTo(aArqSC8[3])

dbSelectArea(aArqSD1[1])
dbSetOrder(aArqSD1[2])
dbGoTo(aArqSD1[3])
  
Return
