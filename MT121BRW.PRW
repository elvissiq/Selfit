#include "totvs.ch"
/*
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
�������������������������������������������������������������������������ͻ��
���Programa  �MT121BRW  �Autor  � Cristiam Rossi     � Data �  24/07/18   ���
�������������������������������������������������������������������������͹��
���Desc.     � P.E. Menudef - pedido de compras                           ���
���          �                                                            ���
�������������������������������������������������������������������������͹��
���Uso       � SELFIT                                                     ���
�������������������������������������������������������������������������ͼ��
�����������������������������������������������������������������������������
�����������������������������������������������������������������������������
*/
user function MT121BRW()

	aAdd(aRotina,{"Enviar E-mail forn.","U_SFCMP06()", 0, 6, 0, Nil })

	aAdd(aRotina,{"Impress�o Gr�fica"  ,"U_MCCOMR01('2')", 0, 6, 0, Nil })

return nil
