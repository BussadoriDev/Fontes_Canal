#INCLUDE 'Totvs.ch'
#INCLUDE 'FWMVCDef.ch'

STATIC cTabPai := 'ZC5'
STATIC cTabFilho := 'ZC6'
STATIC cTitulo := "Cadastro de pedido de vendas (Via API)"

/*
------------------------------------------------------------------
{Protheus.doc} TelaAPI
    Função que monta a tela de pedido de vendas para API
    
    @author Matheus Bussadori
    @since 28/08/2023
    @version 1.00

------------------------------------------------------------------
*/
User Function TelaAPI()
	Local aArea := GetArea()
	Local oBrowse
	PRIVATE aRotina := {}

	//Opções do Browse
	aRotina := MenuDef()

	//Instanciando o Browse
	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias(cTabPai)
	oBrowse:SetDescription(cTitulo)
	oBrowse:DisableDetails()

	oBrowse:AddLegend( "ZC5->ZC5_STATUS == '1'",  "GREEN", "Pedido Importado")
	oBrowse:AddLegend( "! empty(ZC5->ZC5_ERRO) .AND. ZC5->ZC5_STATUS = '2'", 'RED', "Erro na geração do pedido")
	oBrowse:AddLegend( "empty(ZC5->ZC5_ERRO) .AND. ZC5->ZC5_STATUS = '2'", "YELLOW", "Aguardando geração de pedido")
	oBrowse:AddLegend( "ZC5->ZC5_STATUS = '4'", "BLUE", "Titulo Gerado")
	oBrowse:AddLegend( "ZC5->ZC5_STATUS = '5'", "GRAY", "Erro na Geração do Título")

	oBrowse:Activate()

	RestArea(aArea)
Return Nil

/*
------------------------------------------------------------------
{Protheus.doc} MenuDef()
    Função responsável por adicionar as opções do browse
    
    @author Matheus Bussadori
    @since 28/08/2023
    @version 1.00
------------------------------------------------------------------
*/
Static Function MenuDef()
	Local aRotina := {}
	ADD OPTION aRotina TITLE "Alterar" ACTION "VIEWDEF.TelaAPI" OPERATION 4 ACCESS 0
	ADD OPTION aRotina TITLE "Visualizar" ACTION "VIEWDEF.TelaAPI" OPERATION 1 ACCESS 0
	ADD OPTION aRotina TITLE "Processar" ACTION "U_zPedido" OPERATION 9 ACCESS 0

Return aRotina

/*
------------------------------------------------------------------
{Protheus.doc} ModelDef
    Modelos de dados da tela
    
    @author Matheus Bussadori
    @since 31/07/2023
    @version 1.00
------------------------------------------------------------------
*/
Static Function ModelDef()
	Local oStruPai      := FWFormStruct(1, cTabPai)
	Local oStruFilho    := FWFormStruct(1, cTabFilho)
	Local oModel
	Local aRelacao      := {}
	Local bPre          := Nil
	Local bVldPos       := Nil
	Local bCommit       := Nil
	Local bCancel       := Nil

	oModel := MPFormModel():New('TelaAPIM', bPre, bVldPos, bCommit, bCancel)
	oModel:AddFields('ZC5MASTER', , oStruPai)
	oModel:AddGrid('ZC6DETAIL', "ZC5MASTER", oStruFilho )
	oModel:SetDescription("Modelo de dados - " + cTitulo)
	oModel:GetModel('ZC5MASTER'):SetDescription( "Dados de - " + cTitulo)
	oModel:GetModel("ZC6DETAIL"):SetDescription( "Grid de - " + cTitulo)
	oModel:SetPrimaryKey({})

	aAdd(aRelacao, {'ZC6_FILIAL', "FWxFilial('ZC6')"})
	aAdd(aRelacao, {'ZC6_NUM',  "ZC5_NUM"})
	oModel:SetRelation("ZC6DETAIL", aRelacao, ZC6->(IndexKey(1)))



Return oModel

/*
------------------------------------------------------------------
{Protheus.doc} ViewDef()
    Visualiza os dados na função TelaAPI
    @type  Static Function
    @author Matheus Bussadori
    @since 31/07/2023
------------------------------------------------------------------
*/
Static Function ViewDef()
	Local oModel        := FWLoadModel('TelaAPI')
	Local oStruPai      := FWFormStruct(2, cTabPai)
	Local oStruFilho    := FWFormStruct(2, cTabFilho)
	Local oView

	oView := FWFormView():New()
	oView:SetModel(oModel)
	oView:AddField("VIEW_ZC5", oStruPai, "ZC5MASTER")
	oView:AddGrid("VIEW_ZC6", oStruFilho, "ZC6DETAIL")

	oView:CreateHorizontalBox("CABEC", 70)
	oView:CreateHorizontalBox("GRID", 30)
	oView:SetOwnerView("VIEW_ZC5", "CABEC")
	oView:SetOwnerView("VIEW_ZC6", "GRID")

	oView:EnableTitleView('VIEW_ZC5', "Cabeçalho - ZC5 (Pedido)")
	oView:EnableTitleView('VIEW_ZC6', "Grid - ZC6 (Itens)")

Return oView


/*
------------------------------------------------------------------
{Protheus.doc} User Function zPedido
    Função que processa o pedido de vendas da ZC5 para a SC5 

    @author Matheus Bussadori
    @since 29/08/2023
    @version 1.00
------------------------------------------------------------------
*/
User Function zPedido()
	Local aArea     := GetArea()
	Local aCabec    := {}
	Local aGrid     := {}
	Local aItens    := {}
	Local cQry      := ""
	Local nX        := 1
	Local cAliasZC6

	PRIVATE lMsErroAuto    := .F.
	Private lMSHelpAuto     := .T.
	Private lAutoErrNoFile  := .T.

	cAliasZC6 := GetNextAlias()
	DbSelectArea('SC5')
	DbSelectArea('SC6')

	cQry := " SELECT * FROM " + RetSqlnAME('ZC6')  + CRLF
	cQry += " WHERE D_E_L_E_T_ = '' " + CRLF
	cQry += " AND ZC6_NUM = '" + ZC5->ZC5_NUM + "'" + CRLF

	PlsQuery(cQry, cAliasZC6)

	aAdd(aCabec, {"C5_TIPO",        ZC5->ZC5_TIPO,                     NIL}) //Tipo
	aAdd(aCabec, {"C5_NUM",         ZC5->ZC5_NUM,                      NIL}) //Numero
	aAdd(aCabec, {"C5_CLIENTE",     ZC5->ZC5_CLIENT,                   NIL}) //CLIENTE
	aAdd(aCabec, {"C5_LOJACLI",     ZC5->ZC5_LOJACL,                   NIL}) //Loja do cliente
	aAdd(aCabec, {"C5_LOJAENT",     ZC5->ZC5_LOJACL,                   NIL}) //Loja do cliente
	aAdd(aCabec, {"C5_TIPOCLI",     ZC5->ZC5_TIPOCL,                   NIL}) //Tipo do cliente
	aAdd(aCabec, {"C5_CONDPAG",     ZC5->ZC5_CONDPA,                   NIL}) //Condição de pagamento
	aAdd(aCabec, {"C5_TRANSP",     "T00001",                           NIL}) //Transportadora

	While ! (cAliasZC6)->(EoF())
		aGrid := {}
		aAdd(aGrid, {"C6_ITEM",        	nX,              						NIL}) //Item
		aAdd(aGrid, {"C6_PRODUTO",     	Alltrim((cAliasZC6)->ZC6_PRODUT),		NIL}) //Produto
		aAdd(aGrid, {"C6_QTDVEN",     	(cAliasZC6)->ZC6_QTDVEN,            	NIL}) //Quantidade
		aAdd(aGrid, {"C6_PRCVEN",      	(cAliasZC6)->ZC6_PRCVEN ,           	NIL}) //Preço unitário
		aAdd(aGrid, {"C6_PRUNIT",      	(cAliasZC6)->ZC6_PRCVEN ,				NIL}) //Preço unitário
		aAdd(aGrid, {"C6_VALOR",       	(cAliasZC6)->ZC6_VALOR,             	NIL}) //Valor
		aAdd(aGrid, {"C6_TES",         	(cAliasZC6)->ZC6_TES,               	NIL}) //Tes
		aAdd(aGrid, {"C6_LOCAL",       	(cAliasZC6)->ZC6_LOCAL,					NIL}) //Local
		aAdd(aGrid, {"C6_NUM",         	(cAliasZC6)->ZC6_NUM,               	NIL}) //Numero do pedido
		aAdd(aItens, aGrid)
		nX ++
		(cAliasZC6)->(DbSkip())

	EndDo

	Begin transaction
		MsExecAuto({|x,y,z|MATA410(x,y,z)}, aCabec, aItens, 3)

		If lMsErroAuto
			MostraErro()
			DisarmTransaction()
		Else
			FwAlertSucces("Pedido processado com sucesso!", 'Sucesso')
		EndIf
	End Transaction

	RestArea(aArea)
Return
