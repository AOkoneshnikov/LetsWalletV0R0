import "@stdlib/deploy";

contract LetsWalletV0R0 {
    publickeyOwner: Int as uint256;
    seqno: Int as uint32 = 0;
    currency: String;
    version: String = "LetsWalletV0R0";
    linkId: Int as uint64 = 0;
    addressSponsor: Address? = null;
    publickeySponsor: Int? as uint256 = null;
    content: Cell? = null;
    locality: String? = null;
    longitude: Int? = null;
    latitude: Int? = null;
    name: String? = null;
    phone: String? = null;
    email: String? = null;
    telegramId: Int? as uint64 = null; 
    telegramRef: String? = null;

    init(currency: String, publicKey: Int) {
        self.publickeyOwner = publicKey;
        self.currency = currency;
    }

    receive () {}

    external(msg: CreateTrustlineV0R0) {
        require(myBalance() > (msg.tontoTrustlineLink + msg.tontoTrustline + msg.tontoHubLink), "Error: not enough funds to create");

        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            let initTrustline: StateInit = initOf LetsTrustlineV0R0(myAddress(), msg.debitor);
            let initTrustlineLink: StateInit = initOf LetsTrustlineLinkV0R0(myAddress(),self.linkId);
            let initHub: StateInit = initOf LetsHubV0R0(self.currency);

            
            send(SendParameters{
                to: contractAddress(initTrustline),
                value: msg.tontoTrustline,              
                code: initTrustline.code,               
                data: initTrustline.data    
            }); 
            send(SendParameters{
                to: contractAddress(initTrustlineLink),
                value: msg.tontoTrustlineLink,      
                body: SetTrustlineV0R0 { creditor: myAddress(), debitor: msg.debitor }.toCell(),        
                code: initTrustlineLink.code,               
                data: initTrustlineLink.data    
            }); 
            send(SendParameters{
                to: contractAddress(initHub),
                value: msg.tontoHubLink,
                body: SetTrustlineV0R0 { creditor: myAddress(), debitor: msg.debitor }.toCell()
            });

            self.linkId = self.linkId + 1;
        }
    }

    external(msg: SetSponsorV0R0) {
        require((self.publickeySponsor == null) && (self.addressSponsor == null), "Error: Sponsor already exist");

        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            self.publickeySponsor = msg.publicKey;
            self.addressSponsor = msg.address; 
        }
        
    }

    external(msg: CancelSponsorV0R0) {
        require((self.publickeySponsor != null) || (self.addressSponsor != null), "Error: Sponsor no set");

        if (self.CheckMsg(msg.signature, msg.header, self.publickeySponsor!!)) {
            self.publickeySponsor = null;
            self.addressSponsor = null; 
        }
    }

    external(msg: SendMoneyV0R0) {
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            let i: Int = 0;
            let x: Address? = null;
            repeat(4) {
                x = msg.path.get(i);
                dump(i);
                i = i + 1;
            }
        }
    }

    external(msg: SendTonV0R0) {
        require ((self.addressSponsor == null) && (self.publickeySponsor == null), "Error: you cannot send money while the wallet has a sponsor");
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            send(SendParameters{
                to: msg.to,
                value: msg.value,      
                body: msg.comment.asComment()        
            });
        }
    }

    external(msg: SetCustomWalletDataV0R0) {
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            self.content = msg.content; 
            self.locality = msg.locality; 
            self.longitude = msg.longitude; 
            self.latitude = msg.latitude; 
            self.name = msg.name; 
            self.phone = msg.phone; 
            self.email = msg.email; 
            self.telegramId = msg.telegramId; 
            self.telegramRef = msg.telegramRef; 
        }
    }

    receive (msg: WidthrawV0R0) {
        require(sender() == self.addressSponsor, "Error: Only sponsor can widthraw funds");
        send(SendParameters{
                to: self.addressSponsor!!,
                value: msg.value,      
                body: "widthraw sponsored funds".asComment()        
            });
    }

    get fun Data(): WalletDataV0R0 {
        return WalletDataV0R0 { 
            publickeyOwner: self.publickeyOwner,
            publickeySponsor: self.publickeySponsor,
            seqno: self.seqno,
            currency: self.currency,
            version: self.version,
            linkId: self.linkId,
            addressSponsor: self.addressSponsor,
            balance: myBalance(),
            content: self.content,
            locality: self.locality,
            longitude: self.longitude,
            latitude: self.latitude,
            name: self.name,
            phone: self.phone,
            email: self.email,
            telegramId: self.telegramId, 
            telegramRef:self.telegramRef
        };
    }

    fun CheckMsg(signature: Slice, header: Slice, publickey: Int): Bool {
        let header_hash: Int = header.hash();
        let timeout: Int = header.loadInt(32);
        let seqno: Int = header.loadInt(32);

        require(checkSignature(header_hash, signature, publickey), "Error: Invalid signature");
        require(seqno == self.seqno, "Error: Invalid seqno");
        require(now() < timeout, "Error: timeout expired");

        acceptMessage();
        self.seqno = (self.seqno + 1) % 65536;

        return true;
    }
}

contract LetsTrustlineLinkV0R0 {
    wallet: Address;
    trustline: Address? = null;
    linkId: Int as uint64;
    version: String = "LetsTrustlineLinkV0R0";

    init (wallet: Address, linkId: Int) {
        require(sender() == wallet, "Error: Only wallet can create LetsTrustlineLinkV0R0");
        self.wallet = wallet;
        self.linkId = linkId;
    }

    receive () {}

    receive (msg: SetTrustlineV0R0) {
        require(sender() == self.wallet, "Error: Only wallet can set trustline address");
        self.trustline = contractAddress(initOf LetsTrustlineV0R0(msg.creditor, msg.debitor));
    }

    get fun Data(): TrustlineLinkDataV0R0 {
        return TrustlineLinkDataV0R0 { 
            trustline: self.trustline,
            version: self.version,
            balance: myBalance()
        };
    }
}

contract LetsTrustlineV0R0 {
    creditor: Address;
    debitor: Address;
    value: Int as coins = 0;
    limit: Int as coins = 0;
    interest: Int as uint16 = 0;
    version: String = "LetsTrustlineV0R0";

    init (creditor: Address, debitor: Address) {
        require (sender() == creditor, "Error: only creditor can create LetsTrustlineV0R0");
        self.creditor = creditor;
        self.debitor = debitor;
    }

    receive () {}
}

contract LetsHubV0R0 {
    version: String = "LetsHubV0R0";
    currency: String;
    linkTrustlineId: Int as uint64 = 0;

    init (currency: String) {
        self.currency = currency;
    }

    receive () {}

    receive (msg: SetTrustlineV0R0) {
        let initHubLink: StateInit = initOf LetsHubLinkV0R0(self.currency, self.linkTrustlineId);
        send(SendParameters{
                to: contractAddress(initHubLink),
                value: 0,
                mode: SendRemainingValue,      
                body: msg.toCell(),        
                code: initHubLink.code,               
                data: initHubLink.data    
            }); 
    }

    get fun Data(): HubDataV0R0 {
        return HubDataV0R0 {
            balance: myBalance(),
            version: self.version,
            linkTrustlineId: self.linkTrustlineId
        };
    }
}

contract LetsHubLinkV0R0 {
    currency: String;
    linkTrustlineId: Int as uint64;
    trustline: Address? = null;
    version: String = "LetsHubLinkV0R0";
    init (currency: String, linkTrustlineId: Int) {
        self.currency = currency;
        self.linkTrustlineId = linkTrustlineId;
    }
    
    receive () {}

    receive (msg: SetTrustlineV0R0) {
        let initHub: StateInit = initOf LetsHubV0R0(self.currency);
        require(sender() == contractAddress(initHub), "Error: Only LetsHubV0R0 can set trustline address");
        self.trustline = contractAddress(initOf LetsTrustlineV0R0(msg.creditor, msg.debitor));
    }

    get fun Data(): HubLinkDataV0R0 {
        return HubLinkDataV0R0 {
            balance: myBalance(),
            version: self.version,
            trustline: self.trustline
        };
    }
}

message HubLinkDataV0R0 {
    balance: Int as coins;
    version: String;
    trustline: Address?;
}

message HubDataV0R0 {
    balance: Int as coins;
    version: String;
    linkTrustlineId: Int as uint64;
}

message SetCustomWalletDataV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    content: Cell;
    locality: String;
    longitude: Int;
    latitude: Int;
    name: String;
    phone: String;
    email: String;
    telegramId: Int as uint64; 
    telegramRef: String;
}

message WalletDataV0R0 {
    publickeyOwner: Int as uint256;
    publickeySponsor: Int? as uint256;
    seqno: Int as uint64;
    currency: String;
    version: String;
    linkId: Int as uint64;
    addressSponsor: Address?;
    balance: Int as coins;
    content: Cell?;
    locality: String?;
    longitude: Int?;
    latitude: Int?;
    name: String?;
    phone: String?;
    email: String?;
    telegramId: Int? as uint64; 
    telegramRef: String?;
}

message TrustlineLinkDataV0R0 {
    trustline: Address?;
    version: String;
    balance: Int as coins;
}

message SetTrustlineV0R0 {
    creditor: Address;
    debitor: Address;
}

message SetWalletV0R0 {
    wallet: Address;
}

message SetSponsorV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    address: Address?;
    publicKey: Int? as uint256;
}

message CancelSponsorV0R0 {
    signature: Slice as bytes64;
    header: Slice;
}

message SendMoneyV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    path: map<Int as uint8, Address>;
}

message CreateTrustlineV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    debitor: Address;
    tontoTrustline: Int as coins;
    tontoTrustlineLink: Int as coins;
    tontoHubLink: Int as coins;
}

message WidthrawV0R0 {
    value: Int as coins;
}

message SendTonV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    to: Address;
    value: Int as coins;
    comment: String;
}