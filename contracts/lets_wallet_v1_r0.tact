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

    init(currency: String, publicKey: Int) {
        self.publickeyOwner = publicKey;
        self.currency = currency;
    }

    receive () {}

    external(msg: CreateTrustlineV0R0) {
        require(myBalance() > (msg.tontoLinkId + msg.tontoTrustline), "Error: not enough funds to create");

        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            let initTrustline: StateInit = initOf LetsTrustlineV0R0(myAddress(), msg.debitor);
            let initLink: StateInit = initOf LetsTrustlineLinkV0R0(myAddress(),self.linkId);
            send(SendParameters{
                to: contractAddress(initTrustline),
                value: msg.tontoTrustline,              
                code: initTrustline.code,               
                data: initTrustline.data    
            }); 
            send(SendParameters{
                to: contractAddress(initLink),
                value: msg.tontoLinkId,      
                body: SetTrustlineV0R0 { trustline: contractAddress(initTrustline) }.toCell(),        
                code: initLink.code,               
                data: initLink.data    
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

    get fun Data(): WalletDataV0R0 {
        return WalletDataV0R0 { 
            publickeyOwner: self.publickeyOwner,
            publickeySponsor: self.publickeySponsor,
            seqno: self.seqno,
            currency: self.currency,
            version: self.version,
            linkId: self.linkId,
            addressSponsor: self.addressSponsor,
            balance: myBalance()
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

    receive (msg: SetTrustlineV0R0) {
        require(sender() == self.wallet, "Error: Only wallet can set trustline address");
        self.trustline = msg.trustline;
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

    receive () {
        require (sender() == self.creditor, "Error: Only creditor can send empty message");
    }
}

contract LetsHubV0R0 {
    version: String = "LetsHubV0R0";
    currency: String;
    linkTrustlineId: Int as uint64 = 0;
    linkWalletId: Int as uint64 = 0;

    init (currency: String) {
        self.currency = currency;
    }

    get fun Data(): HubDataV0R0 {
        return HubDataV0R0 {
            balance: myBalance(),
            version: self.version,
            linkTrustlineId: self.linkTrustlineId,
            linkWalletId: self.linkWalletId
        };
    }
}

message HubDataV0R0 {
    balance: Int as coins;
    version: String;
    linkTrustlineId: Int as uint64;
    linkWalletId: Int as uint64;
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
}

message TrustlineLinkDataV0R0 {
    trustline: Address?;
    version: String;
    balance: Int as coins;
}

message SetTrustlineV0R0 {
    trustline: Address;
}

message SetSponsorV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    address: Address? = null;
    publicKey: Int? as uint256 = null;
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
    tontoLinkId: Int as coins;
}