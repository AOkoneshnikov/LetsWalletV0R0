import "@stdlib/deploy";

contract LetsWalletV0R0 {
    publickeyOwner: Int as uint256;
    seqno: Int as uint32 = 0;
    currency: String;
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

    receive ("Operation success") {}

    external(msg: CreateTrustlineV0R0) {
        require(myBalance() > (msg.tontoTrustline + msg.tontoLink), "Error: not enough funds to create");

        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            let initTrustline: StateInit = initOf LetsTrustlineV0R0(myAddress(), msg.debitor);
            let initHub: StateInit = initOf LetsHubV0R0(self.currency);

            send(SendParameters{
                to: contractAddress(initTrustline),
                value: msg.tontoTrustline,              
                code: initTrustline.code,               
                data: initTrustline.data    
            }); 
            send(SendParameters{
                to: contractAddress(initHub),
                value: msg.tontoLink,
                body: SetTrustlineV0R0 { creditor: myAddress(), debitor: msg.debitor }.toCell()
            });
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

    external(msg: TransferTonV0R0) {
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

    external(msg: SetLimitV0R0) {
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            let initTrustline: StateInit = initOf LetsTrustlineV0R0(myAddress(), msg.debitor);
            send(SendParameters{
                to: contractAddress(initTrustline),
                value: msg.tontoTrustline,
                body: msg.toCell(),              
                code: initTrustline.code,               
                data: initTrustline.data    
            });
        }
    }

    external(msg: SetInterestProjectV0R0) {
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            let initTrustline: StateInit = initOf LetsTrustlineV0R0(myAddress(), msg.debitor);
            send(SendParameters{
                to: contractAddress(initTrustline),
                value: msg.tontoTrustline,
                body: msg.toCell(),              
                code: initTrustline.code,               
                data: initTrustline.data    
            });
        }
    }
    
    external(msg: ConfirmInterestV0R0) {
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            let initTrustline: StateInit = initOf LetsTrustlineV0R0(msg.creditor, myAddress());
            send(SendParameters{
                to: contractAddress(initTrustline),
                value: msg.tontoTrustline,
                body: msg.toCell(),              
                code: initTrustline.code,               
                data: initTrustline.data    
            });
        }
    }

    external(msg: TransferMoneyV0R0) {
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            dump(1);
            //if self.checkTransferParams(msg) {
          //      dump("-- success path --");
         //   }
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

    fun checkTransferParams(msg: TransferMoneyV0R0): Bool {
        require(msg.amount > 0, "Error: amount must be greater than zero");
        require((msg.currentStep == 0) && (msg.bounced == false), "Error: incorrect currentStep or bounced flag");
        let i: Int = 0;
        let startNodeAddress: Address? = msg.path.get(0);
        while (startNodeAddress!= null) {
            let nextNodeAddress: Address? = msg.path.get(i + 1);
            let y: Int = i;
            while (nextNodeAddress != null) {
                require(nextNodeAddress != startNodeAddress, "Error: path is ring");
                y = y + 1;
                nextNodeAddress = msg.path.get(y)!!;
            }
            i = i + 1;
            startNodeAddress = msg.path.get(i)!!;
        }
        require(i > 1, "Error: count node in path there must be more than one");
        return true; 
    }
}

contract LetsHubV0R0 {
    currency: String;
    linkId: Int as uint64 = 0;

    init (currency: String) {
        self.currency = currency;
    }

    receive () {}

    receive (msg: SetTrustlineV0R0) {
        require (sender() == msg.creditor, "Error: only creditor can make link");
        let initLink: StateInit = initOf LetsLinkV0R0(self.currency, self.linkId);
        send(SendParameters{
                to: contractAddress(initLink),
                value: 0,
                mode: SendRemainingValue,      
                body: msg.toCell(),        
                code: initLink.code,               
                data: initLink.data    
            }); 
        self.linkId = self.linkId + 1;
    }

    get fun Data(): HubDataV0R0 {
        return HubDataV0R0 {
            balance: myBalance(),
            linkId: self.linkId
        };
    }
}

contract LetsLinkV0R0 {
    currency: String;
    linkId: Int as uint64;
    trustline: Address? = null;
    wallet: Address? = null;

    init (currency: String, linkId: Int) {
        self.currency = currency;
        self.linkId = linkId;
    }
    
    receive () {
        require(sender() == self.wallet, "Error: Only owner wallet can send empty message");
    }

    receive (msg: SetTrustlineV0R0) {
        let initHub: StateInit = initOf LetsHubV0R0(self.currency);
        require(sender() == contractAddress(initHub), "Error: Only LetsHubV0R0 can set trustline address");
        self.trustline = contractAddress(initOf LetsTrustlineV0R0(msg.creditor, msg.debitor));
        self.wallet = msg.creditor;
    }

    get fun Data(): LinkDataV0R0 {
        return LinkDataV0R0 {
            balance: myBalance(),
            trustline: self.trustline,
            wallet: self.wallet
        };
    }
}

contract LetsTrustlineV0R0 {
    creditor: Address;
    debitor: Address;
    value: Int as coins = 0;
    limit: Int as coins = 0;
    interest: Int as uint16 = 0;
    interestProject: Int as uint16 = 0;

    init (creditor: Address, debitor: Address) {
        require (sender() == creditor, "Error: only creditor can create LetsTrustlineV0R0");
        self.creditor = creditor;
        self.debitor = debitor;
    }

    receive () {
        require(sender() == self.creditor, "Error: Only creditor wallet can send empty message");
    }

    receive (msg: SetLimitV0R0) {
        require((sender() == self.creditor) && (msg.debitor == self.debitor), "Error: only creditor can set limit or incorrect debitor address");
        self.limit = msg.limit;
        self.reply("Operation success".asComment());
    }

    receive (msg: SetInterestProjectV0R0) {
        require((sender() == self.creditor) && (msg.debitor == self.debitor), "Error: only creditor can set interest rate project or incorrect debitor address");
        self.interestProject = msg.interestProject;
        self.reply("Operation success".asComment());
    }

    receive (msg: ConfirmInterestV0R0) {
        require((sender() == self.debitor) && (msg.creditor == self.creditor), "Error: only debitor can confirm interest or incorrect creditor address");
        require(self.interestProject == msg.interestProject, "Error: incorrest interest rate project");
        self.interest = self.interestProject;
        self.interestProject = 0;
        self.reply("Operation success".asComment());
    }

    get fun Data(): TrustlineDataV0R0 {
        return TrustlineDataV0R0 {
            value: self.value,
            limit: self.limit,
            interest: self.interest,
            interestProject: self.interestProject,
            balance: myBalance()
        };
    }
}

message LinkDataV0R0 {
    balance: Int as coins;
    trustline: Address?;
    wallet: Address?;
}

message HubDataV0R0 {
    balance: Int as coins;
    linkId: Int as uint64;
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


message SetTrustlineV0R0 {
    creditor: Address;
    debitor: Address;
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

message CreateTrustlineV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    debitor: Address;
    tontoTrustline: Int as coins;
    tontoLink: Int as coins;
}

message WidthrawV0R0 {
    value: Int as coins;
}

message TransferTonV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    to: Address;
    value: Int as coins;
    comment: String;
}

message TrustlineDataV0R0 {
    value: Int as coins;
    limit: Int as coins;
    interest: Int as uint16;
    interestProject: Int as uint16;
    balance: Int as coins;
}

message SetLimitV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    debitor: Address;
    limit: Int as coins;
    tontoTrustline: Int as coins;
}

message SetInterestProjectV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    debitor: Address;
    interestProject: Int as uint16;
    tontoTrustline: Int as coins;
}

message ConfirmInterestV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    creditor: Address;
    interestProject: Int as uint16;
    tontoTrustline: Int as coins;
}

message TransferMoneyV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    amount: Int as coins;
    onCredit: Bool = false;
    currentStep: Int as uint8 = 0;
    bounced: Bool = false;
    path: map<Int as uint8, Address>;
}