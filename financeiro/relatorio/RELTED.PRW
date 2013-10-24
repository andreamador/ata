/*______________________________________________________________________
   �Autor     � Breno Ferreira                      � Data � 10/09/13 �
   +----------+-------------------------------------------------------�
   �Descri��o � Relacao de titulos pagos com TED                      �
  ����������������������������������������������������������������������*/
#include "rwmake.ch"
#include "topconn.ch"

user function RELTED()
	private aOrd    := {}
	private aReturn := {"Especial",1,"Administracao",1,2,1,"",1}
	private cPerg   := "RELTED"
	private Cabec1  := ""
	private Cabec2  := "ITM  DOCUMENTO  FORNECEDOR            BANCO                 PREVISAO  EMISSAO   TITULO         PARC               VALOR"
	private cDesc1  := "RELACAO DE TED"
	private ContFun := 0
	private cString := "SE5"
	private m_pag   := 1
	private nOrdem  := 0
	private nTipo   := 0
	private Tamanho := "M"
	private Titulo  := cDesc1
	private wnrel   := FunName()
	private lAborta := .T.
	
	private nLin	:= 014
	private cQry 	:= ""
	private nRdpPag	:= 1
	private nInd	:= 0
	private cRdpLeg	:= ""
	private cCbcRef	:= ""
	private cCbcNum	:= ""
	private cEmpresa := SubStr(cNumEmp,1,2)
	
	private cDataIni	:= ""
	private cDataFin	:= ""
	private cTedIni 	:= ""
	private cTedFin 	:= ""
	
	//��������������������������������������������������������������Ŀ
	//� Parametros utilizados pelo programa                          �
	//� mv_par01 - Emissao de                                        �
	//� mv_par02 - Emissao ate                                       �
	//� mv_par03 - TED de                                            �
	//� mv_par04 - TED ate                                           �
	//����������������������������������������������������������������
	
	Pergunte(cPerg,.F.)
	
	wnrel := SetPrint(cString,wnrel,cPerg,Titulo,cDesc1,,,.T.,aOrd,,Tamanho)
	
	if nLastKey == 27 ; return ; endif
	
	SetDefault(aReturn,cString)
	nOrdem  := aReturn[8]
	
	cDataIni := DToS(mv_par01)
	cDataFin := DToS(mv_par02)
	cTedIni := mv_par03
	cTedFin := mv_par04
	
	Processa({|| Impr()},"","Aguarde processando...",lAborta)
	
	set device to screen
	
	if aReturn[5] == 1
		set printer to
		
		DbCommitAll()
		DbCloseArea()
		OurSpool(wnrel)
	else
		DbCloseArea()
	endif
	
	Ms_Flush()
return

static function Impr()
	local nTotItem := 1
	local nValor := 0
	local nTotValor := 0
	
	cQry := "select E5_DTDISPO, E5_DOCUMEN, E5_DATA, E5_BANCO, E5_AGENCIA, E5_CONTA, E5_BENEF, E5_HISTOR, E5_VALOR, E5_CLIFOR, E5_LOJA, E2_NUM, E2_PREFIXO, E2_PARCELA, E2_EMISSAO, (E2_VALOR + E2_ACRESC - E2_DECRESC) as E2_VALOR, E2_VALLIQ "
	cQry += "from "+RetSqlName("SE5")+" SE5 inner join "+RetSqlName("SE2")+" SE2 on (E5_NUMERO = E2_FATURA and E5_PREFIXO = E2_FATPREF) "
	cQry += "where (E5_DTDISPO between '"+cDataIni+"' and '"+cDataFin+"') and (E5_DOCUMEN between 'TED"+cTedIni+"' and 'TED"+cTedFin+"') and E5_NATUREZ = '40103' and SE5.D_E_L_E_T_ <> '*' and SE2.D_E_L_E_T_ <> '*' "
	cQry += "order by E5_DOCUMEN, E2_NUM, E2_PARCELA"
	
	tcquery cQry new alias "TEMP"
	
	DbSelectArea("TEMP")
	ProcRegua(TEMP->(RecCount()))
	TEMP->(DbGoTop())
	
	Cabec1 := PadC("Periodo de "+U_ConvData(cDataIni)+" a "+U_ConvData(cDataFin),132)
	
	U_Cbc(cEmpAnt,cCbcNum,cDesc1,Cabec1,Cabec2,cCbcRef,Tamanho,wnrel)
	
	nLin++
	
	while !TEMP->(Eof())
//		ITM  DOCUMENTO  FORNECEDOR            BANCO                 PREVISAO  EMISSAO   TITULO         PARC               VALOR
//		999  AAA999999  AAAAAAAAAAAAAAAAAAAA  AAAAAAAAAAAAAAAAAAAA  99/99/99  99/99/99  999999999-999  999     9,999,999,999.99
//		01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890
//		          1         2         3         4         5         6         7         8         9        10        11        12        13
		
		cTed := AllTrim(TEMP->E5_DOCUMEN)
		nValor := 0
		
		while !TEMP->(Eof()) .and. AllTrim(TEMP->E5_DOCUMEN) == cTed
			@nLin,000 psay StrZero(nTotItem,3)
			@nLin,005 psay cTed
			@nLin,016 psay IIf(SA2->(DbSeek(xFilial("SA2")+TEMP->(E5_CLIFOR+E5_LOJA),.F.)),SA2->A2_NREDUZ," ")
			@nLin,038 psay IIf(SA6->(DbSeek(xFilial("SA6")+TEMP->(E5_BANCO+E5_AGENCIA+E5_CONTA),.F.)),SA6->A6_NREDUZ," ")
			@nLin,060 psay U_ConvData(TEMP->E5_DTDISPO,"yy")
			@nLin,070 psay U_ConvData(TEMP->E2_EMISSAO,"yy")
			@nLin,080 psay TEMP->E2_NUM+"-"+TEMP->E2_PREFIXO
			@nLin,095 psay TEMP->E2_PARCELA
			@nLin,103 psay Transf(TEMP->E2_VALLIQ,"@E 9,999,999,999.99")
			
			nLin++
			nTotItem++
			nValor += TEMP->E2_VALLIQ
			nTotValor += TEMP->E2_VALLIQ
			
			U_SaltaFolha()
			IncProc()
			TEMP->(DbSkip())
		enddo
		
		@nLin,080 psay "T O T A L"
		@nLin,103 psay Transf(nValor,"@E 9,999,999,999.99")
		
		nLin++
		
		U_SaltaFolha()
	enddo
	
	nLin += 2
	
	U_SaltaFolha()
	
	@nLin,000 psay "T O T A L  G E R A L -----> ("+AllTrim(Str(nTotItem - 1))+" MOVIMENTACOES)"
	@nLin,103 psay Transf(nTotValor,"@E 9,999,999,999.99")
	
	U_Rdp(nRdpPag,cRdpLeg,Tamanho)
	TEMP->(DbCloseArea())
return