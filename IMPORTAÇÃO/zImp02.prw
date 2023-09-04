#INCLUDE 'Totvs.ch'
#INCLUDE 'TopConn.ch'


/*
-------------------------------------------------------------------
{Protheus.doc} zImp02
	Abre o prompt para selecionar o o arquivo .CSV

    @author Matheus Bussadori
    @since 27/07/2023
	@version 1.00

-------------------------------------------------------------------
*/

User Function zImp02()
	Local aArea     := GetArea()
	Private cArquivo  := ""

	cArquivo := tFileDialog("CVS Files (*.csv)", "Seleção de arquivos", , , .F.,)

	//Se o arquivo de origem não estiver vazio
	If ! Empty(cArquivo)

		If File(cArquivo) .AND. UPPER(SubSTR(cArquivo, Rat(".",cArquivo) + 1,3)) == "CSV"
			Processa({|| fImporta()}, "Importando...")
		Else
			MsgStop("Arquivo e/ou extensão invalida", "Atenção!!")
		EndIf
	EndIf

	RestArea(aArea)
Return

/*
-------------------------------------------------------------------
{Protheus.doc} fImporta
    Importação de arquivos coringa 

    @author Matheus Bussadori
    @since 27/07/2023
	@version 1.00
	@Obs O cabeçalho precisa conter os nomes dos campos da tabela escolhida

-------------------------------------------------------------------
*/
Static Function fImporta()
	Local aArea         := GetArea()
	Local aLinha        := {}
	Local cLinhaAtu     := ""
	Local aCabecalho    := {}
	Local nPos          := 0
	Local cPergs        := 'XCSVCORING'
	Local oArquivo

	//Pergunta qual tabela vai ser selecionada
	If Pergunte(cPergs)
	Else
		MsgAlert("Operação cancelada!", "Cancelada")
		Return
	EndIf

	DbSelectArea(MV_PAR01)

	//Definindo o arquivo a ser lido
	oArquivo := FWFileReader():New(cArquivo)

	//Se o arquivo for aberto
	If (oArquivo:Open())

		//Se não estiver no final do arquivo
		If ! (oArquivo:Eof())

			oArquivo:GoTop()
			
			//Pegando a primeira linha para pegar os campos da tabela
			oArquivo:HasLine()
			cLinhaAtu := oArquivo:GetLine()
			aCabecalho :=  StrTokArr(Alltrim(cLinhaAtu),";")

			//Enquanto houver linhas
			While (oArquivo:HasLine())
				cLinhaAtu := oArquivo:GetLine()
				aLinha := StrTokArr(Alltrim(cLinhaAtu),";")

				For nPos := 1 to Len(aCabecalho)

					//Verifica se existe o campo
					If ! FieldPos(aCabecalho[nPos])
						MsgStop("O campo " + aCabecalho[nPos] + " não existe no dicionario", "Alerta - Dicionario" )
						Return
					EndiF

				Next

				//Pegando os dados da linha
				nPos := Len(aLinha)

				//Numero de dados da linha
				nRegistros := 1

				//Se a linha não estiver vazia
				If ! Empty(aLinha)

					RecLock(MV_PAR01,.T.)

					//Enquanto os dados não forem maior que o cabeçalho
					While ! nRegistros > nPos
						&( aCabecalho[nRegistros] + " := aLinha[nRegistros]")

						nRegistros += 1

					EndDo
					MsUnLock()
				EndIf
			EndDo
		Else
			MsgStop("O arquivo está vazio", "Atenção")
		EndIf
	Else
		MsgStop("O arquivo não pode ser aberto", "Atenção!")
	EndIf

	RestArea(aArea)
Return
