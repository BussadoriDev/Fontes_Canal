#INCLUDE 'Totvs.ch'
#INCLUDE 'RESTFUL.CH'
#INCLUDE 'TopConn.ch'
#INCLUDE 'Protheus.ch'


WSRESTFUL CADASTRO_PEDIDO_DE_VENDAS DESCRIPTION 'API para cadastro de pedido de vendas' FORMAT APPLICATION_JSON

	WSMETHOD POST cadastroPedido;
	DESCRIPTION 'Methodo post para cadastro do pedido de vendas';
	PATH '/cadastrar/pedido_de_vendas/'

END WSRESTFUL

WSMETHOD POST cadastroPedido WSSERVICE CADASTRO_PEDIDO_DE_VENDAS

    Local oJson        := JsonObject():New()
    //lOCAL nNumPed       := 0
   // Local nOpc          := 0
    Local nAtual        := 0
   // Local aDados        := {}
   // Local aItens        := {}
    Local cJson         := self:GetContent()
    Local oResponse     := JsonObject():New()
    Local lRet          := .T.
    Local cNumPed       := GetSxeNum("SC5","C5_NUM")
    Local lCabecalho    := .F.
    Local lGrid         := .F.
    //Local cJson         := self:GetContent()


    //PRIVATE lMsErroAuto := .F.

    
    self:SetContentType( 'application/json' )

    oJson:FromJson(cJson)

    DbSelectArea('ZC5')
    DbSelectArea('ZC6')
    DbSelectArea('SB1')
    
    ZC5->(RecLock('ZC5', .T.))
        ZC5->ZC5_FILIAL := FWxFilial('ZC5')
        ZC5->ZC5_NUM  := cNumPed
        ZC5->ZC5_TIPO := oJson['Tipo']
        ZC5->ZC5_CLIENT := oJson["Cliente"]
        ZC5->ZC5_LOJACL := oJson["Loja"]
        ZC5->ZC5_TIPOCL := oJson['Tipo Cliente']
        ZC5->ZC5_CONDPA := oJson["Cond. Pagamento"]
        ZC5->ZC5_STATUS := "2"
        ZC5->ZC5_JSON := cJson
        
        lCabecalho := .T.
    ZC5->(MsUnLock())

    For nAtual := 1 to Len(oJson['Itens'])
        ZC6->(RecLock('ZC6', .T.))
            ZC6->ZC6_FILIAL := ' '
            ZC6->ZC6_ITEM := oJson['Itens'][nAtual]['item']
            ZC6->ZC6_PRODUT :=  oJson['Itens'][nAtual]['produto']
            ZC6->ZC6_UM := POSICIONE('SB1', 1, FWxFilial('SB1') + oJson['Itens'][nAtual]['produto'], 'B1_UM')
            ZC6->ZC6_QTDVEN := oJson['Itens'][nAtual]['quantidade']  
            ZC6->ZC6_PRCVEN := oJson['Itens'][nAtual]['precoUnitario']  
            ZC6->ZC6_VALOR := oJson['Itens'][nAtual]['quantidade']  *  oJson['Itens'][nAtual]['precoUnitario']  
            ZC6->ZC6_TES   := '501'
            ZC6->ZC6_LOCAL := '01'
            ZC6->ZC6_CF := '000'
            ZC6->ZC6_NUM := cNumPed

            lGrid := .T.

        ZC6->(MsUnLock())
    Next 


If lCabecalho .AND. lGrid
    oResponse['Mensagem'] := 'Ok'
    self:SetResponse( EncodeUtf8(oResponse:ToJson()))

Else 
    oResponse['Mensagem'] := "Falha"
    self:SetResponse( EncodeUtf8(oResponse:ToJson()))

EndIf
    
Return lRet
