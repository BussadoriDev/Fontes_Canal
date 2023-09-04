#INCLUDE 'Totvs.ch'
#INCLUDE 'Topconn.ch'


/*
-------------------------------------------------------------------
{Protheus.doc} zImp04
	Abre o prompt para selecionar o o arquivo .CSV

    @author Matheus Bussadori
    @since 01/08/2023
	@Version 1.00

-------------------------------------------------------------------
*/
User Function zImp04()
	Local aArea     := GetArea()
	Private cArqOri   := ""
	cArqOri := tFileDialog( "CSV files (*.csv) ", "Seleção de arquivos", , , .F.,)

	If ! (Empty(cArqOri))

		If FilE(cArqOri) .AND. Upper(SubStr(cArqOri, Rat('.',cArqOri)+ 1,3)) == "CSV"
			Processa({|| fImporta()}, "Importando...")
		Else
			MsgStop("Arquivo e/ou extensão invalida", "Atenção")
		EndIf

	EndIf


	RestArea(aArea)
Return

/*
-------------------------------------------------------------------
{Protheus.doc} fImporta
    Função para importar os produtos via MsExecAuto

    @author Matheus Bussadori
    @since 01/08/2023
	@Version 1.00
	@Obs Integra os dados via ExecAuto

-------------------------------------------------------------------
*/
Static Function fImporta()
	Local aArea         := GetArea()
	Local oArquivo
	Local cPergs        := "ZIMPCSV"
	Local aDados        := {}
	Local nColunCod     := 0
	Local nColunDesc    := 0
	Local nColunGarant  := 0
	Local nColunLocal   := 0
	Local nColunTipo    := 0
	Local nColunUm      := 0
	Local nColunQA      := 0
	Local cCodProd      := ""
	Local cDescProd     := ""
	Local cTipoProd     := ""
	Local cGarantProd   := ""
	Local cQAProd       := ""
	Local cUmProd       := ""
	Local cLocalProd    := ""
	Local nOpcX 		:= 0
	Local nPos          := 0
	Local lAlt          := .F.
	Local lInclui       := .F.
	Local lExclui       := .F.
	Local cProdErro     := ""
	Local lEncontrou    := .F.
	Local aErroAuto 	:= {}
	Local nAtual 		:= 0

	PRIVATE cProdOk 		:= ""
	PRIVATE cLogErro 		:= ""
	PRIVATE lMsErroAuto    	:= .F.
	Private lMSHelpAuto     := .T.
	Private lAutoErrNoFile  := .T.



	If Pergunte(cPergs)
	else
		MsgStop("A operação foi cancelada", "Cancelamento")
		Return
	EndIf

	IF MV_PAR01 == 1
		lInclui := .T.
	ElseIf  MV_PAR01 == 2
		lAlt    := .T.
	ElseIf MV_PAR01 == 3
		lExclui := .T.
	EndIf


	//Definindo qual arquivo vai ser lido
	oArquivo := FWFileReader():New(cArqOri)

	//Abrindo o arquivo
	If (oArquivo:Open())

		//Se não for o fim do arquivo
		If ! (oArquivo:EoF())

			cLinhaAtu := oArquivo:GetLine()
			aLinha    := StrTokArr(Alltrim(cLinhaAtu), ";")
			If "codigo" $ Lower(Alltrim(cLinhaAtu))

				If nPos == 0
					nColunCod       := aScan(aLinha, {|x| lower(Alltrim(x)) == "codigo"})
					nColunDesc      := aScan(aLinha, {|x| lower(Alltrim(x)) == "descricao"})
					nColunTipo      := aScan(aLinha, {|x| Lower(Alltrim(x)) == "tipo"})
					nColunGarant    := aScan(aLinha, {|x| Lower(Alltrim(x)) == "garantia"})
					nColunLocal     := aScan(aLinha, {|x| Lower(Alltrim(x)) == "local" .OR. "estoque"})
					nColunQA        := aScan(aLinha, {|x| Lower(Alltrim(x)) == "qa"})
					nColunUm        := aScan(aLinha, {|x| Lower(Alltrim(x)) == "um"})
				EndIf
			EndIf

			Begin transaction

				While (oArquivo:HasLine())
					cLinhaAtu := oArquivo:GetLine()
					aLinha := StrTokArr(Alltrim(cLinhaAtu), ";")
					If ! Empty(aLinha)
						If ! "codigo" $ Alltrim(aLinha)
							cCodProd    := aLinha[nColunCod]
							cDescProd   := aLinha[nColunDesc]
							cTipoProd   := aLinha[nColunTipo]
							cUmProd     := aLinha[nColunUm]
							cLocalProd  := aLinha[nColunLocal]
							cQAProd     := aLinha[nColunQA]
							cGarantProd := aLinha[nColunGarant]
						EndIf

						DbSelectArea("SB1")
						SB1->(DbSetOrder(1))

						//Definindo a variavel como .F. para toda vez que for ler um produto novos
						lMsErroAuto := .F.

						iF  ! lInclui

							If 	SB1->(DbSeek(FWxFilial("SB1") + Alltrim(cCodProd)))
								lEncontrou := .T.
							Else
								cProdErro += "Produto não encontrado: " + cCodProd + CRLF
							EndIf
						EndIf
						//Em caso de inclusão
						If ! lEncontrou .AND. lInclui
							aDados := {}
							aAdd(aDados, 	{"B1_COD",      cCodProd,       	Nil})
							aAdd(aDados,	{"B1_DESC",     cDescProd,      	Nil})
							aAdd(aDados,	{"B1_TIPO",     cTipoProd,      	Nil})
							aAdd(aDados,	{"B1_UM",       cUmProd,        	Nil})
							aAdd(aDados,	{"B1_LOCPAD",   cLocalProd,     	Nil})
							aAdd(aDados,	{"B1_GARANT",   cGarantProd,    	Nil})
							aAdd(aDados,	{"B1_XCODQA",   cQAProd,        	Nil})
							nOpcX := 3
							MsExecAuto({|x,y| Mata010(x,y)}, aDados, nOpcX)
							If lMsErroAuto
								aErroAuto := GetAutoGRLog()
								For nAtual := 1 To Len(aErroAuto)
									cLogErro += StrTran(StrTran(aErroAuto[nAtual], "<", ""), "-", "") + " " + CRLF
								Next nAtual
								DisarmTransaction()
							Else
								cProdOk += cCodProd + CRLF
							EndIf
						EndIf

						//Em caso de alteração
						If lEncontrou .AND. lAlt
							aDados := {}
							aAdd(aDados, 	{"B1_COD",      cCodProd,       	Nil})
							aAdd(aDados,	{"B1_DESC",     cDescProd,      	Nil})
							aAdd(aDados,	{"B1_TIPO",     cTipoProd,      	Nil})
							aAdd(aDados,	{"B1_UM",       cUmProd,        	Nil})
							aAdd(aDados,	{"B1_LOCPAD",   cLocalProd,     	Nil})
							aAdd(aDados,	{"B1_GARANT",   cGarantProd,    	Nil})
							aAdd(aDados,	{"B1_XCODQA",   cQAProd,        	Nil})
							nOpcX := 4
							MsExecAuto({|x,y| Mata010(x,y)}, aDados, nOpcX)
							If lMsErroAuto
								aErroAuto := GetAutoGRLog()
								For nAtual := 1 To Len(aErroAuto)
									cLogErro += StrTran(StrTran(aErroAuto[nAtual], "<", ""), "-", "") + " " + CRLF
								Next nAtual
								DisarmTransaction()
							Else
								cProdOk += cCodProd + CRLF
							EndIf
						EndIf

						//Em caso de exclusão
						If lEncontrou .AND. lExclui
							aDados := {}
							aAdd(aDados, 	{"B1_COD",      cCodProd,       	Nil})

							DbSelectArea('SC6')
							SC6->(DbSetOrder(2))
							IF ! SC6->(DbSeek(FWxFilial("SC6") + Alltrim(cCodProd)))
								nOpcX := 5
								MsExecAuto({|x,y| Mata010(x,y)}, aDados, nOpcX)
								If lMsErroAuto
									aErroAuto := GetAutoGRLog()
									For nAtual := 1 To Len(aErroAuto)
										cLogErro += StrTran(StrTran(aErroAuto[nAtual], "<", ""), "-", "") + " " + CRLF
									Next nAtual
									DisarmTransaction()
								Else
									cProdOk += cCodProd + CRLF
								EndIf
							Else
								cProdErro += "Produto: " + cCodProd + " Erro: O produto está está vinculado a um pedido de vendas " + CRLF
							EndIf
						EndIF

					Else
						FwAlertErro("A linha do arquivo se encontra vazia" , "Erro")
					EndIf
				EndDo


			End Transaction

			GeraLog(nOpcX, cProdOk, cProdErro, cLogErro)
		EndIf
	EndIf

	RestArea(aArea)
Return


/*
-------------------------------------------------------------------
{Protheus.doc} GeraLog
	Gera um .txt para armazenar a log da rotina

	@author Matheus Bussadori
	@since 01/09/2023
	@version 1.00
	@param nOpc, "N", Tipo de operação realizada
	@param cProdutoOk, "C", Proutos que efetuaram corretamente a operação
	@param cProdutoErro, "C", Produtos que deram problema durante a operação 
	@param cLog, "C", Log do ExecAuto 

-------------------------------------------------------------------
*/
Static Function GeraLog(nOpc, cProdutoOk, cProdutoErro, cLog)
	Local aArea := GetArea()
	Local cDir := ""
	Local cArquivo := "\log_" + dToS(dATE()) + "_" + StrTran(Time(), ":", "-") + ".txt"
	Local oArquivo := Nil
	Local cOperacao := ""


	IF nOpc == 3
		cOperacao = "INCLUSÃO"
	ElseIf nOpc == 4
		cOperacao = "ALTERAÇÃO"
	Else
		cOperacao = "EXCLUSÃO"
	EndIF

	cDir := "C:\Windows\Temp" + cArquivo
	oArquivo := FWFILEWRITER():New(cDir, .T.)
	oArquivo:Create()
	oArquivo:Write("Codigo do Usuário: " + RetCodUsr() + CRLF)
	oArquivo:Write("Nome do Usuário: " + UsrRetName(RetCodUsr()) + CRLF)
	oArquivo:Write("Função: zImp04() " + CRLF)
	oArquivo:Write(CRLF)
	oArquivo:Write("Tipo de operação realizada: " + cOperacao + CRLF)
	oArquivo:Write("Produtos OK: " + CRLF + cProdutoOk + CRLF)
	oArquivo:Write("Produtos com Erro: " + CRLF + cProdutoErro + CRLF)
	oArquivo:Write("Log de Erro no ExecAuto: " + CRLF + cLog + CRLF + "-----------------------------------------------" + CRLF)

	oArquivo:Close()

	If MsgYesNo("Deseja Abrir o  log? ", "Atenção")
		ShellExecute("OPEN", cArquivo, "", "C:\Windows\Temp", 1 )
	EndIf

	RestArea(aArea)

Return
