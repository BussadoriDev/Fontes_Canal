#include "protheus.ch"
#include "rwmake.ch"
#include "msole.ch"
#INCLUDE "totvs.ch"
#INCLUDE "topconn.ch"
#INCLUDE 'FWPrintSetup.ch'
#INCLUDE 'rptdef.ch.'
#INCLUDE 'parmtype.ch.'
#INCLUDE "FILEIO.ch"
#INCLUDE "TBICONN.CH"

/*
-------------------------------------------------------------------
{Protheus.doc} JobEmail
    Prepara o ambiemte para executar o Job

    @author Matheus Bussadori	
    @since 16/08/2023
	@version 1.00

-------------------------------------------------------------------
*/
User Function JobEmail()
	RpcSetType(3)
	PREPARE ENVIRONMENT EMPRESA '99' FILIAL '01' MODULO 'FAT'

	u_zEnvRec()
Return

/*
-------------------------------------------------------------------
{Protheus.doc} zEnvRec
    Verifica os se o pedido possui titulo em aberto

    @author Matheus Bussadori
    @since 16/08/2023
	@version 1.00

-------------------------------------------------------------------
*/
USER Function zEnvRec()
	Local aArea := GetArea()
	Local cPedido := ""
	PRIVATE cAlias
	PRIVATE cQry := ""
	PRIVATE aTeste

	cAlias := GetNextAlias()

	cQry := " SELECT " + CRLF
	cQry += " SE1.E1_NUM, " + CRLF
	cQry += " SE1.E1_PEDIDO, " + CRLF
	cQry += " SE1.E1_XRECENV, " + CRLF
	cQry += " SE1.E1_STATUS, " + CRLF
	cQry += " SA1.A1_EMAIL, " + CRLF
	cQry += " SE1.R_E_C_N_O_ " + CRLF
	cQry += " FROM " + RetSqlName('SE1')+" SE1" + CRLF
	cQry += " JOIN " + RetSqlName('SA1')+" SA1 ON SE1.E1_CLIENTE = SA1.A1_COD" + CRLF
	cQry += " WHERE E1_PEDIDO <> '' " + CRLF
	cQry += " AND E1_XRECENV = 2 OR E1_XRECENV = '' " + CRLF
	cQry += " AND E1_STATUS = 'B' " + CRLF
	cQry += " AND E1_NUM <> " + SE1->E1_NUM + CRLF
	cQry += " AND SE1.D_E_L_E_T_ = '' " + CRLF
	cQry += " AND SA1.D_E_L_E_T_ = '' " + CRLF


	PlsQuery(cQry, cAlias)


	While ! (cAlias)->(EoF())
		SE1->(DbGoTo((cAlias)->R_E_C_N_O_))

		//Verificação para não enviar duas vezes o mesmo email
		IF  cPedido <> (cAlias)->E1_PEDIDO
			u_zEmail02()
			cPedido := (cAlias)->E1_PEDIDO
		EndIf
		(cAlias)->(DbSkip())
	EndDo

	RestArea(aArea)
Return

//Cores 
	#Define COR_CINZA RGB(180,180,180)
	#Define COR_PRETO RGB(000,000,000)

//Colunas 
	#DEFINE COL_ITEM 0030
	#DEFINE COL_DESC 0130
	#DEFINE COL_QUANT 0230
	#DEFINE COL_PRECO 0330
	#DEFINE COL_TOTAL 0430


/*
-------------------------------------------------------------------
{Protheus.doc} User Function zEmail02
    Função responsavel pelo envio do email pra o cliente

    @author Matheus Bussadori
    @since 15/08/2023
    @version 1.00
    @param cPara, Charter, Destinatario que recebera o email 
    @param cAssunto, Charter, Assunto que se trata o email
    @param cCopro, Charter, Corpo do email
    @param aAnexos, Array , Anexos do email
    @param lMostraLog, Logico, Mostra a log de mensagens (se tiver)
    @param lUsaTls, Logico, Se o email usa TLS
    @see https://terminaldeinformacao.com/2017/10/17/funcao-dispara-e-mail-varios-anexos-em-advpl/
    
    @Obs Configurar os seguintes parametros antes 
    MV_RELACNT - Email responsavel pelo envio das mensagens 
    MV_RELPSW - Senha do Email 
    MV_RELSERV - Servidor e porta do email 
    MV_RELTIME - Timeout do email (padrão 120)

-------------------------------------------------------------------
*/
User Function zEmail02(cPara, cAssunto, cCorpo, aAnexos, lMostraLog, lUsaTls)
	Local aArea := GetArea()
	Local nRet := 0
	Local lRet := .T.
	Local oMsg := Nil
	Local oSrv := Nil
	Local cFrom := Alltrim(GETMV("MV_RELACNT"))
	Local cUser := SubStr(cFrom,1,At('@', cFrom)-1)
	Local cPass := Alltrim(GETMV("MV_RELPSW"))
	Local cSrvFull := Alltrim(GETMV("MV_RELSERV"))
	Local cServer := IIF(":" $ cSrvFull,SubStr(cSrvFull,1,At(":", cSrvFull)-1), cSrvFull)
	Local nPort := IIF(":" $ cSrvFull, Val(SubStr(cSrvFull,At(':', cSrvFull)+1,len(cSrvFull))), 587)
	Local nTimeOut := GETMV("MV_RELTIME")
	Local cLog := ''
	Local nAtual := 0
	LOCAL cAliasRec
	Local cArq := "xrel\gw - recibo de pedido de vendas " + SE1->E1_PEDIDO + ".pdf"
	PRIVATE cQry1 := ""
	DEFAULT cPara := ""
	DEFAULT cAssunto := "GW - Recibo do pedido de vendas"
	DEFAULT cCorpo := "<strong>Segue em anexo recibo do pedido:  <strong> " + SE1->E1_PEDIDO
	DEFAULT aAnexos := {}
	DEFAULT lMostraLog := .T.
	DEFAULT lUsaTls := .T.

	DbSelectArea('SE1')
	cAliasRec := GetNextAlias()

	(cAlias)->(DbGoTop())
	While ! (cAlias)->(EoF())

		//SE ALGUM DOS TITULOS ESTIVER EM ABERTO (STATUS = A)
		IF  (cAlias)->E1_STATUS == "A"
			Help('',1,'Erro!',,'Não é possível gerar recibos de pedidos com titulos em aberto',1,0)
			Return
		EndIf

		(cAlias)->(DbSkip())

	EndDo

	//Função que gera o word para anexo
	u_zRecRel()

	//Adicionando o arquivo nos anexos
	aAdd(aAnexos, cArq)

	(cAlias)->(DbGoTop())
	//Preenchendo o email do cliente
	cPara := Alltrim((cAlias)->A1_EMAIL)

	//Verificando se não está vazio o destinatario, assunto ou corpo
	IF Empty(cPara) .OR. Empty(cAssunto) .OR. Empty(cCorpo)
		cLog := "Destinatário, assunto ou corpo do email vazio(s)" + CRLF
		lRet := .F.
	EndIf

	If lRet
		//Criando a mensagem
		oMsg := TMailMessage():New()
		oMsg:Clear()

		oMsg:cFrom      := cFrom
		oMsg:cTo        := cPara
		oMsg:cSubject   := cAssunto
		oMsg:cBody      := cCorpo

	EndIf

	For nAtual := 1 To Len(aAnexos)

		//Verificando se o arquivo existe
		If File(aAnexos[nAtual])

			nRet := oMsg:AttachFile(aAnexos[nAtual])
			If nRet < 0
				cLog += "002 - Nao foi possivel anexar o arquivo '"+aAnexos[nAtual]+"'!" + CRLF
				lRet := .F.
			EndIf

		Else
			cLog += "003 - Arquivo '"+aAnexos[nAtual]+"' nao encontrado!" + CRLF
			lRet := .F.
		EndIf
	Next

	If lRet
		oSrv := tMailManager():New()

		//Define se usa TLS
		if lUsaTls
			oSrv:SetUseTls(.T.)
		EndIf

		nRet := oSrv:Init("", cServer, cUser, cPass, 0, nPort)
		If nRet != 0
			cLog += "Não foi possivel inicializar o servidor SMPT: " + oSrv:GetErrorString(nRet) + CRLF
			lRet := .F.
		EndIf

		If lRet

			//Define o Timeout
			nRet := oSrv:SetSMTPTimeout(nTimeOut)
			If nRet != 0
				cLog := "Não foi possivel definir o timeout: " + oSrv:GetErrorString(nRet) + CRLF
			EndIf

			//Conecta no servidor SMPT
			nRet := oSrv:SMTPConnect()
			if nRet != 0
				cLog += "Erro ao conectar no servidor SMPT: " + oSrv:GetErrorString(nRet) + CRLF
				lRet := .F.
			EndIf

			//Autentica usuario e senha
			IF lRet
				nRet := oSrv:SMTPAuth(cFrom, cPass)
				If nRet != 0
					cLog += "Erro ao conectar no servidor, rever usuario/senha: " + oSrv:GetErrorString(nRet) + CRLF
					lRet := .F.
				ENDIF
			EndIf

			//Envia a mensagem
			If lRet
				nRet := oMsg:Send(oSrv)
				If nRet != 0
					cLog += "Erro ao enviar a mensagem: " + oSrv:GetErrorString(nRet) + CRLF
					lRet := .F.
				EndIF
			EndIf

			//Disconecta do servidor SMPT
			nRet := oSrv:SMTPDisconnect()
			If nRet != 0
				cLog += "Não foi possivel desconectar do servidor SMPT: " + oSrv:GetErrorString(nRet) + CRLF
			EndIf
		EndIf
	EndIf

	cQry1 := " SELECT     " + CRLF
	cQry1 += " SE1.E1_NUM," + CRLF 
	cQry1 += " SE1.E1_STATUS, " + CRLF 
	cQry1 += " SE1.E1_XRECENV, " + CRLF 
	cQry1 += " SE1.R_E_C_N_O_ " + CRLF 
	cQry1 += " FROM " + RetSqlName('SE1')+" SE1 " + CRLF
	cQry1 += " WHERE E1_PEDIDO = '" + (cAlias)->E1_PEDIDO + "'" + CRLF

	PlsQuery(cQry1, cAliasRec)

	If Empty(cLog)

		While ! (cAliasRec)->(EoF())

			SE1->(DbGoTo((cAliasRec)->R_E_C_N_O_))
			RecLock('SE1',.F.)
			SE1->E1_XRECENV := '1' //ALTERANDO O CAMPO QUE INDICA SE O CLIENTE RECEBEU O RECIBO PARA SIM
			SE1->(MsUnLock())

			(cAliasRec)->(DbSkip())
		EndDo
	EndIf

	If ! IsBlind()
		IF ! Empty(cLog)
			MsgAlert(cLog, "Atenção")
		Else
			FWAlertSuccess('Email enviado com sucesso!', "Sucesso!")
		EndIf
	EndIf

	//Exclui o arquivo da ProtheusData
	For nAtual := 1 to len(aAnexos)
		FERASE(aAnexos[nAtual])
	Next

	(cAliasRec)->(DbCloseArea())
	RestArea(aArea)
Return lRet

/*
-------------------------------------------------------------------
{Protheus.doc}  zRecRel
	Cria o recibo do pedido

    @author Matheus Bussadori
    @since 18/08/2023
    @version 1.00
    @see https://terminaldeinformacao.com/knowledgebase/fwmsprinter/
-------------------------------------------------------------------
*/
User Function zRecRel()
	Local aArea := GetArea()
	Local cQry := ''
	Local cAliasPdf
	Local cArquivo
	Local cCaminho := "\xrel\" //"C:\TOTVS\ERP\protheus_data\xrel\"
	Local cNomeEmp := "GroundWork Tecnologia"
	Local cEndEmp := "R. Marambaia, 424 - Sala 53"
	PRIVATE nPagina := 1
	PRIVATE nLinCab := 30
	//Linhas e colunas
	PRIVATE nLinhaAtu := 000
	PRIVATE nLinTab := 380
	PRIVATE nTamLin := 010
	PRIVATE nLinFin := 820
	PRIVATE nColIni := 010
	PRIVATE nColFin := 550
	PRIVATE nColMeio := (nColFin-nColIni)/2 
	//Objeto de Impressão
	PRIVATE oPrintRec
	//Fontes
	PRIVATE cNomeFont := "Arial"
	PRIVATE oFontTit := TFont():New(cNomeFont, , -026, , .T. , , , ,.F.)
	PRIVATE oFontDados := TFont():New(cNomeFont, , -016, , .T. , , , ,.F.)
	PRIVATE oFontLin := TFont():New(cNomeFont, , -15, , .F. , , , ,.F.)

	If ! ExistDir(cCaminho)
		MakeDir(cCaminho)
	EndIf

	cAliasPdf := GetNextAlias()
	DbSelectArea("SE1")

	//Nome do arquivo que será gerado
	cArquivo := "GW - Recibo de pedido de vendas " + SE1->E1_PEDIDO + ".pdf"

	oPrintRec := FWMsPrinter():New(cArquivo, IMP_PDF, .F., "",.T., , @oPrintRec, "", , , , .F.)

	//Atributos do relatorio
	oPrintRec:SetResolution(72)
	oPrintRec:SetPortrait()
	oPrintRec:SetPaperSize(9)
	oPrintRec:SetMargin(60, 60, 60, 60)
	oPrintRec:cPathPDF := cCaminho

	cQry := " SELECT " + CRLF
	cQry += " SA1.A1_COD,  "   + CRLF //CODIGO DO CLIENTE
	cQry += " SA1.A1_NOME,  "   + CRLF //NOME DO CLIENTE
	cQry += " SA1.A1_END,  "   + CRLF //ENDEREÇO DO CLIENTE
	cQry += " SA1.A1_EMAIL, "   + CRLF //EMAIL DO CLIENTE
	cQry += " SC6.C6_ITEM, "   + CRLF //ITEM DO PEDIDO
	cQry += " SC6.C6_DESCRI,  "   + CRLF //DESCRIÇÃO DO PRODUTO
	cQry += " SC6.C6_QTDVEN, "   + CRLF //QUANTIDADE DO PRODUTO
	cQry += " SC6.C6_PRCVEN,  "   + CRLF // PREÇO DO PRODUTO
	cQry += " SC6.C6_VALOR,  "   + CRLF // VALOR TOTAL DO PRODUTO (QUANT * PREÇO)
	cQry += " SC5.C5_XVALPED, " + CRLF //Valor total do pedido
	cQry += " SE1.E1_NUM " + CRLF //Numero do pedido
	cQry += " FROM " + RetSqlName("SC5")+" SC5 "   + CRLF
	cQry += " JOIN " + RetSQLName("SC6")+" SC6 ON SC6.C6_NUM = SC5.C5_NUM "   + CRLF
	cQry += " JOIN " + RetSQLName("SA1")+" SA1 ON SA1.A1_COD = SC5.C5_CLIENTE "   + CRLF
	cQry += " JOIN " + RetSqlName('SE1')+" SE1 ON SE1.E1_PEDIDO = SC5.C5_NUM " + CRLF
	cQry += " WHERE SC5.D_E_L_E_T_ = ''  "   + CRLF
	cQry += " AND SC6.D_E_L_E_T_ = '' "   + CRLF
	cQry += " AND SA1.D_E_L_E_T_ = '' "   + CRLF
	cQry += " AND SE1.D_E_L_E_T_ = '' "   + CRLF
	cQry += " AND SC5.C5_NUM =  '" +  SE1->E1_PEDIDO + "'" + CRLF
	cQry += " AND SE1.E1_NUM =  '" + SE1->E1_NUM + "'"  + CRLF

	PlsQuery(cQry, cAliasPdf)

	//Montando o cabeçalho
	ImpCabec()

	oPrintRec:SayAlign(090, 030, "NOME DA EMPRESA:", oFontDados, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(090, 165, cNomeEmp, oFontLin, 200, 030, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(120 , 030, "ENDEREÇO: ", oFontDados, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(120, 110, cEndEmp, oFontLin, 200, 030, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(150 , 030, "TELEFONE:", oFontDados, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(150, 105, "(11) 94234-3915", oFontLin, 200, 030, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(180 , 030, "DATA DO RECIBO:", oFontDados, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(180, 150, DtoC(Date()), oFontLin, 200, 030, COR_PRETO, 0, 0)


	oPrintRec:SayAlign(240 , 030, "DADOS DO CLIENTE:", oFontDados, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(265 , 030, "Nome: ", oFontLin, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(265 , 070, Alltrim((cAliasPdf)->A1_NOME), oFontLin, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(285 , 030, "Endereço: ", oFontLin, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(285 , 090, Alltrim((cAliasPdf)->A1_END), oFontLin, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(310 , 030, "Email: ", oFontLin, 200, 020, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(310 , 070, Alltrim((cAliasPdf)->A1_EMAIL), oFontLin, 200, 020, COR_PRETO, 0, 0)

	oPrintRec:SayAlign(360 , 030, "DETALHES DO PEDIDO", oFontDados, 200, 020, COR_PRETO, 0, 0)

	nLinTab += 020
	While ! (cAliasPdf)->(EoF())

		//Se for o final da pagina 
		If nLinTab + nTamLin > nLinFin
			nPagina++

			oPrintRec:EndPage()
			oPrintRec:StartPage()

			nLinTab := 100

			oPrintRec:SayAlign(40, 50 , "Recibo do pedido: " + (cAliasPdf)->E1_NUM, oFontDados, 240, 20, COR_PRETO, 2, 0)
			oPrintRec:SayAlign(40, 300 , "Pagina: " + cValToChar(nPagina), oFontDados, 240, 20, COR_PRETO, 2, 0)
			oPrintRec:Line(60, 0, 60, nColFin, COR_PRETO)

			nLinCab += nTamLin

			oPrintRec:SayAlign(nLinTab, COL_ITEM, "Item", oFontDados, 100, 20, COR_PRETO, 0, 0)
			oPrintRec:SayAlign(nLinTab, COL_DESC, "Desc. Prod", oFontDados, 100, 20, COR_PRETO, 0, 0)
			oPrintRec:SayAlign(nLinTab, COL_QUANT, "Quantidade", oFontDados, 100, 20, COR_PRETO, 2, 0)
			oPrintRec:SayAlign(nLinTab, COL_PRECO, "Preço Uni", oFontDados, 100, 20, COR_PRETO, 2, 0)
			oPrintRec:SayAlign(nLinTab, COL_TOTAL, "Total", oFontDados, 100, 20, COR_PRETO, 2, 0)

			nLinTab := nLinCab + 50
		EndIf
		oPrintRec:SayAlign(nLinTab, COL_ITEM, Alltrim((cAliasPdf)->C6_ITEM), oFontLin, 0080, nTamLin, COR_PRETO, 0, 0)
		oPrintRec:SayAlign(nLinTab, COL_DESC, Alltrim((cAliasPdf)->C6_DESCRI),  oFontLin, 0080, nTamLin, COR_PRETO, 0, 0)
		oPrintRec:SayAlign(nLinTab, COL_QUANT, cValtoChar((cAliasPdf)->(C6_QTDVEN)),  oFontLin, 0080, nTamLin, COR_PRETO, 2, 0)
		oPrintRec:SayAlign(nLinTab, COL_PRECO, TRANSFORM((cAliasPdf)->C6_PRCVEN,"@E 999,999,999.99"),  oFontLin, 0080, nTamLin, COR_PRETO, 2, 0)
		oPrintRec:SayAlign(nLinTab, COL_TOTAL, TRANSFORM((cAliasPdf)->C6_VALOR,"@E 999,999,999.99"),  oFontLin, 0080, nTamLin, COR_PRETO, 2, 0)

		nLinTab += nTamLin + 0010
		(cAliasPdf)->(DbSkip())
	EndDo

	//Gera o arquivo na protheus data e na temp do usuario
	oPrintRec:Print()

	(cAliasPdf)->(DbCloseArea())
	RestArea(aArea)
Return


/*
-------------------------------------------------------------------
{Protheus.doc} ImpCabec
    Imprimi o cabeçalho  do recibo

    @author Matheus Bussadori
    @since 18/08/2023
    @version 1.00
-------------------------------------------------------------------    
	*/
Static Function ImpCabec()
	Local cTexto := ""

	//Iniicando pagina
	oPrintRec:StartPage()

	//Cabeçalho
	cTexto := "Recibo do pedido " + SE1->E1_PEDIDO
	oPrintRec:SayAlign(nLinCab, nColMeio - 120, cTexto, oFontTit, 240, 20, COR_PRETO, 2, 0)
	oPrintRec:SayAlign(40, 300 , "Pagina: " + cValToChar(nPagina), oFontDados, 240, 20, COR_PRETO, 2, 0)

	//Linha que separa o cabeçalho
	nLinCab += (nTamLin * 2) 
	oPrintRec:Line(60, 0, 60, nColFin, COR_PRETO)

	//Cabeçalho e colunas
	nLinCab += nTamLin
	oPrintRec:SayAlign(nLinTab, COL_ITEM, "Item", oFontDados, 100, 20, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(nLinTab, COL_DESC, "Desc. Prod", oFontDados, 100, 20, COR_PRETO, 0, 0)
	oPrintRec:SayAlign(nLinTab, COL_QUANT, "Quantidade", oFontDados, 100, 20, COR_PRETO, 2, 0)
	oPrintRec:SayAlign(nLinTab, COL_PRECO, "Preço Uni", oFontDados, 100, 20, COR_PRETO, 2, 0)
	oPrintRec:SayAlign(nLinTab, COL_TOTAL, "Total", oFontDados, 100, 20, COR_PRETO, 2, 0)

	//Atualizando a linha inicial do relatorio
	nLinhaAtu := nLinCab + 3
Return

