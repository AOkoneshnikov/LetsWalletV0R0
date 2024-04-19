import "@stdlib/deploy";

contract LetsHubV0R0 {
    currency: String;
    queryId: Int as uint128 = 0;
    accountId: Int as uint64 = 0;
    version: String = "LetsHubV0R0";

    init(currency: String) {
        self.currency = currency;
    }

    receive ("fund") {
        self.reply("Info: LetsHubV0R0 funded".asComment());
    }

    receive (msg: CreateAccountV0R0) {
        let init: StateInit = initOf LetsAccountV0R0(self.currency, self.accountId); 
        let account: Address = contractAddress(init);
        self.accountId = self.accountId + 1;
        send(SendParameters{
            to: account,
            value: 0,              
            mode: SendRemainingValue + SendIgnoreErrors,
            body: CreateAccountV0R0 { owner: msg.owner, publicKey: msg.publicKey }.toCell(),
            code: init.code,               
            data: init.data    
        }); 
    }

    get fun Data(): HubDataV0R0 {
        return HubDataV0R0 {
            currency: self.currency, 
            queryId: self.queryId, 
            accountId: self.accountId,
            version: self.version
            };
    } 

    get fun queryId(): Int {
        return self.queryId;
    }
}

contract LetsAccountV0R0 {
    currency: String;
    queryId: Int as uint128 = 0;
    accountId: Int as uint64 = 0;
    linkId: Int as uint32 = 0;
    hub: Address;
    owner: Address? = null;
    publicKey: Int? as uint256 = null;
    sponsor: Address? = null;
    locality: String? = null;
    longitude: Int? = null;
    latitude: Int? = null;
    name: String? = null;
    phone: String? = null;
    email: String? = null;
    version: String = "LetsAccountV0R0";

    init(currency: String, accountId: Int) {
        self.currency = currency;
        self.hub = contractAddress(initOf LetsHubV0R0(currency));
        require (sender() == self.hub, "Error: Init LetsAccountV0R0 can only LetsHubV0R0"); 
        self.accountId = accountId;
    }

    receive ("fund") {
        require((sender () == self.sponsor) || (sender() == self.owner), "Error: LetsAccountV0R0 can fund only Owner or Sponsor");
        self.reply("Info: LetsAccountV0R0 funded".asComment());
    }

    get fun Data(): AccountDataV0R0 {
        return AccountDataV0R0 {
            currency: self.currency, 
            queryId: self.queryId, 
            accountId: self.accountId, 
            linkId: self.linkId,
            hub: self.hub,
            owner: self.owner,
            publicKey: self.publicKey,
            sponsor: self.sponsor,
            locality: self.locality,
            longitude: self.longitude,
            latitude: self.latitude,
            name: self.name,
            phone: self.phone,
            email: self.email,
            version: self.version
            };
    } 

    get fun queryId(): Int {
        return self.queryId;
    }
}

contract LetsLinkV0R0 {
    queryId: Int as uint128 = 0;
    linkId: Int as uint32;
    trustline: Address? = null;
    account: Address;
    version: String = "LetsLinkV0R0";

    init(currency: String, accountId: Int, linkId: Int) {
        let account: Address = contractAddress(initOf LetsAccountV0R0(currency, accountId));
        require (sender () == account, "Error: Only LetsAccountV0R0 can create LetsLinkV0R0");
        self.account = account;
        self.linkId = linkId;
    }

    receive ("fund") {
        require(sender () == self.account, "Error: LetsAccountV0R0 can fund only Account");
        self.reply("Info: LetsLinkV0R0 funded".asComment());
    }

    get fun Data(): LinkDataV0R0 {
        return LinkDataV0R0 {
            queryId: self.queryId, 
            linkId: self.linkId,
            trustline: self.trustline,
            account: self.account,
            version: self.version
            };
    } 

    get fun queryId(): Int {
        return self.queryId;
    }
}

contract LetsTrustlineV0R0 {
    queryId: Int as uint128 = 0;
    currency: String;
    creditorAccount: Address;
    debitorAccount: Address;
    value: Int as coins = 0;
    limit: Int as coins = 0;
    interest: Int as uint16 = 0;
    feeMultiplicator: Int as uint8 = 10;
    creditorId: Int as uint64;
    debitorId: Int as uint64;
    version: String = "LetsTrustlineV0R0";

    init(currency: String, creditorId: Int, debitorId: Int) {
        let creditorAccount: Address = contractAddress(initOf LetsAccountV0R0(currency, creditorId));
        require (sender () == creditorAccount, "Error: Only LetsAccountV0R0 can create LetsTrustlineV0R0");
        let debitorAccount: Address = contractAddress(initOf LetsAccountV0R0(currency, debitorId));
        self.creditorAccount = creditorAccount;
        self.debitorAccount = debitorAccount;
        self.currency = currency;
        self.creditorId = creditorId;
        self.debitorId = debitorId;
    }

    receive ("fund") {
        require(sender () == self.creditorAccount, "Error: LetsAccountV0R0 can fund only creditorAccount");
        self.reply("Info: LetsLinkV0R0 funded".asComment());
    }

    get fun Data(): TrustlineDataV0R0 {
        return TrustlineDataV0R0 {
            queryId: self.queryId,
            currency: self.currency,
            creditorAccount: self.creditorAccount,
            debitorAccount: self.debitorAccount,
            value: self.value,
            limit: self.limit,
            interest: self.interest,
            feeMultiplicator: self.feeMultiplicator,
            creditorId: self.creditorId,
            debitorId: self.debitorId,
            version: self.version
            };
    } 

    get fun queryId(): Int {
        return self.queryId;
    }
}

message(0x01) HubDataV0R0 {
    currency: String;
    queryId: Int as uint128;
    accountId: Int as uint64;
    version: String;
}

message(0x02) AccountDataV0R0 {
    currency: String;
    queryId: Int as uint128;
    accountId: Int as uint64;
    linkId: Int as uint32;
    hub: Address;
    owner: Address?;
    publicKey: Int? as uint256;
    sponsor: Address?;
    locality: String?;
    longitude: Int?;
    latitude: Int?;
    name: String?;
    phone: String?;
    email: String?;
    version: String;
}

message(0x03) LinkDataV0R0 {
    queryId: Int as uint128;
    linkId: Int as uint32;
    trustline: Address?;
    account: Address;
    version: String;
}

message(0x04) TrustlineDataV0R0 {
    queryId: Int as uint128;
    currency: String;
    creditorAccount: Address;
    debitorAccount: Address;
    value: Int as coins;
    limit: Int as coins;
    interest: Int as uint16;
    feeMultiplicator: Int as uint8;
    creditorId: Int as uint64;
    debitorId: Int as uint64;
    version: String ;
}

message (0x05) CreateAccountV0R0 {
    owner: Address? = null;
    publicKey: Int? as uint256 = null;  
}
    
    

