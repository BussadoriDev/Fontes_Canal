#INCLUDE 'Totvs.ch'
#INCLUDE 'Topconn.ch'
#INCLUDE 'RESTFUL.CH'


//Declarando o nome da API
WSRESTFUL consultaPA2 DESCRIPTION "Consulta de produtos externos" FORMAT APPLICATION_JSON

//Declarando as variaveis 
	WSDATA CodProduto AS CHARACTER OPTIONAL
	WSDATA Tipo AS CHARACTER OPTIONAL

	WSMETHOD GET ConsultaProdutosExternos;
		DESCRIPTION "Consultar Produtos"; //Descrição
	WSSYNTAX "/consultar/Tipo/produtos/?{Tipo}&{CodProduto}"; //Sintaxe para pesquisa + parametros
	PATH "/consultar/Tipo/produtos/" //Sintaxe para pesquisa

END WSRESTFUL

WSMETHOD GET ConsultaProdutosExternos HEADERPARAM Tipo, CodProduto WSSERVICE consultaPA2

	Local cQry := ""
	Local cCodProd := ""
	Local cTipo := ""
	Local cAliasPA1
	Local cAliasPA2
	Local cProdAtu := ""
	Local oProd
	Local aAtributos := {}
	Local aDescAtr := {}
	Local oAtrib
	Local lRet := .T.
	Local aResponse := {}
	Local oResponse := NIL

	cAliasPA1 := GetNextAlias()
	cAliasPA2 := GetNextAlias()


	If ( ValType(self:CODPRODUTO ) == "C" .AND. !Empty(self:CODPRODUTO))
		cCodProd := self:CODPRODUTO
	EndIf

	If  (ValType (self:Tipo) == "C" .AND. ! Empty(self:Tipo))
		cTipo := Upper(self:tipo)
	EndIf

	cQry := " SELECT " + CRLF
	cQry += " PA1.PA1_COD, " + CRLF
	cQry += " PA1.PA1_NOME, " + CRLF
	cQry += " PA1.PA1_DESC, " + CRLF
	cQry += " PA1.PA1_PRECO " + CRLF
	cQry += " FROM " + RetSqlName("PA1")+" PA1 " + CRLF
	cQry += " WHERE PA1.D_E_L_E_T_ = '' " + CRLF
	If "ESPECIFICO" $ Upper(cTipo)
		cQry += " AND PA1_COD = '" + cCodProd + "'"+ CRLF
	EndIf

	PlsQuery(cQry, cAliasPA1)

	cQry := " SELECT PA2_ATRIB, PA2_VLRATR, PA2_COD " + CRLF
	cQry += " FROM " + RetSqlName("PA2") + CRLF
	cQry += " WHERE D_E_L_E_T_ = '' " + CRLF
	If "ESPECIFICO" $ Upper(cTipo)
		cQry += " AND PA2_COD = '" + (cAliasPA1)->PA1_COD + "'" + CRLF
	EndIf
	PlsQuery(cQry, cAliasPA2)


	IF (cAliasPA1)->(EoF())
		(cAliasPA1)->(DbCloseArea())
		oResponse := JsonObject():New()
		oResponse["ConsultarResultado"] := {}
		self:SetResponse( oResponse:ToJson() )
		FreeObj( oResponse )
		Return(lRet)

		//Se o tipo de pesquisa for especifico
	Elseif "ESPECIFICO" $ Upper(cTipo)

		While ! (cAliasPA1)->(EoF())
			oProd := Nil
			oAtrib := Nil
			oAtrib := JsonObject():New()
			oProd := JsonObject():New()

			If ! cProdAtu == Alltrim((cAliasPA1)->PA1_COD)
				oProd["Cod. Produto"] := Alltrim((cAliasPA1)->PA1_COD)
				oProd["Nome"] := Alltrim((cAliasPA1)->PA1_NOME)
				oProd["Descrição"] := Alltrim((cAliasPA1)->PA1_DESC)
				oProd["Preço Produto"] := ALLTRIM(TRANSFORM((cAliasPA1)->PA1_PRECO, "@E 999,999,999.99"))
				cProdAtu := Alltrim((cAliasPA1)->PA1_COD)
			EndIf

			While ! (cAliasPA2)->(EoF())
				aAdd(aAtributos , oAtrib["Atributo"] :=  Alltrim((cAliasPA2)->PA2_ATRIB))
				aAdd(aAtributos, oAtrib["Vlr. Atr"] :=  Alltrim((cAliasPA2)->PA2_VLRATR))
				aAdd(aDescatr, aAtributos)
				aAtributos := {}
				(cAliasPA2)->(DbSkip())

			EndDo
			oProd["Atributos"] := aDescatr

			aAdd(aResponse, oProd)

			//Transforma esses itens em um array
			(cAliasPA1)->(DbSkip())

		EndDo

		(cAliasPA1)->(DbCloseArea())
		(cAliasPA2)->(DbCloseArea())

		oResponse := JsonObject():New()

		oResponse["Resultado"] := aResponse

	Elseif "TODOS" $ Upper(cTipo)
		While ! (cAliasPA1)->(EoF())
			oProd := Nil
			oAtrib := Nil
			oAtrib := JsonObject():New()
			oProd := JsonObject():New()
			(cAliasPA2)->(DbGoTop())

			If ! cProdAtu == Alltrim((cAliasPA1)->PA1_COD)
				oProd["Cod. Produto"] := Alltrim((cAliasPA1)->PA1_COD)
				oProd["Nome"] := Alltrim((cAliasPA1)->PA1_NOME)
				oProd["Descrição"] := Alltrim((cAliasPA1)->PA1_DESC)
				oProd["Preço Produto"] := ALLTRIM(TRANSFORM((cAliasPA1)->PA1_PRECO, "@E 999,999,999.99"))
				cProdAtu := Alltrim((cAliasPA1)->PA1_COD)
			EndIf

			While ! (cAliasPA2)->(EoF())
				If (cAliasPA2)->PA2_COD == cProdAtu
					aAdd(aAtributos , oAtrib["Atributo"] :=  Alltrim((cAliasPA2)->PA2_ATRIB))
					aAdd(aAtributos, oAtrib["Vlr. Atr"] :=  Alltrim((cAliasPA2)->PA2_VLRATR))
					aAdd(aDescatr, aAtributos)
					aAtributos := {}
				EndIf
				(cAliasPA2)->(DbSkip())
			EndDo

			oProd["Atributos"] := aDescatr

			aAdd(aResponse, oProd)

			(cAliasPA1)->(DbSkip())
			//(cAliasPA2)->(DbSkip())
			aDescatr := {}
		EndDo

		(cAliasPA1)->(DbCloseArea())
		(cAliasPA2)->(DbCloseArea())

		//Cria o Json Object
		oResponse := JsonObject():New()

		//Atribui o array de informação ao resultado e declara a mensagem que ira aparecer
		oResponse["Resultado"] := aResponse

	Else
		oProd := Nil
		oProd := JsonObject():New()
		oProd["Erro"] := "Tipo de consulta '" + Upper(cTipo) + "' Invalido"
		aAdd(aResponse, oProd)

		oResponse := JsonObject():New()
		oResponse["Resultado"] := aResponse

	EndIf

	//Responsavel por mostrar no postman o resultado
	self:SetResponse( EncodeUTF8(oResponse:ToJson()))


	FreeObj( oResponse )
	oResponse := Nil

Return (lRet)
