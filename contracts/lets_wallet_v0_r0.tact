import "@stdlib/deploy";

contract LetsWalletV0R0 with Deployable {
    publickeyOwner: Int as uint256;
    seqno: Int as uint32 = 0;
    currency: String;
    addressSponsor: Address? = null;
    publickeySponsor: Int? as uint256 = null;
    content: Cell? = null;
    lastDestination: Address? = null;
    lastTransferAmount: Int as coins = 0;

    init(publicKey: Int, currency: String) {
        self.publickeyOwner = publicKey;
        self.currency = currency;
    }

    receive () {}

    receive ("payment chain end") {
        self.lastDestination = sender();
    }

    receive ("Operation success") {
    }

    external(msg: CreateTrustlineV0R0) {
        require(myBalance() > (msg.tontoTrustline + msg.tontoLink), "Error: not enough funds to create");
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            let initTrustline: StateInit = initOf LetsTrustlineV0R0(myAddress(), msg.debitor);
            let initHub: StateInit = initOf LetsHubV0R0(self.currency);
            send(SendParameters{
                to: contractAddress(initTrustline),
                value: msg.tontoTrustline,
                body: "fund".asComment(),              
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

    external(msg: SetContentWalletDataV0R0) {
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            self.content = msg.content; 
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
        if self.CheckMsg(msg.signature, msg.header, self.publickeyOwner) {
            let countStep: Int = self.checkTransferParams(msg);
            if  countStep > 0 {
                let nextNode: Address? = msg.path.get(1);
                let initTrustline: StateInit? = null;
                if msg.onCredit {
                    initTrustline = initOf LetsTrustlineV0R0(nextNode!!, myAddress());
                } else {
                    initTrustline = initOf LetsTrustlineV0R0(myAddress(), nextNode!!);
                }
                send(SendParameters{
                    to: contractAddress(initTrustline!!),
                    value: msg.tontoTrustline,
                    body: TransferMoneyV0R0 { 
                        signature: msg.signature, 
                        header: msg.header,
                        onCredit: msg.onCredit,
                        amount: msg.amount,
                        currentStep: 1,
                        countStep:countStep,
                        path: msg.path,
                        tontoTrustline: msg.tontoTrustline
                        }.toCell()               
                });
                self.lastTransferAmount = msg.amount;
            }
        }
    }

    receive (msg: WidthrawV0R0) {
        require(sender() == self.addressSponsor, "Error: Only sponsor can widthraw funds");
        send(SendParameters{
                to: self.addressSponsor!!,
                value: msg.value,      
                body: "widthraw sponsored funds".asComment()        
            });
        self.seqno = (self.seqno + 1) % 65536;
    }

    get fun data(): WalletDataV0R0 {
        return WalletDataV0R0 { 
            publickeyOwner: self.publickeyOwner,
            publickeySponsor: self.publickeySponsor,
            currency: self.currency,
            addressSponsor: self.addressSponsor,
            balance: myBalance(),
            content: self.content,
            seqno: self.seqno
        };
    }

    get fun seqno(): Int {
        return self.seqno;
    }

    get fun lastDestination(): Address? {
        return self.lastDestination;
    }

    get fun lastTransferAmount(): Int {
        return self.lastTransferAmount;
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

    fun checkTransferParams(msg: TransferMoneyV0R0): Int {
        require(msg.amount > 0, "Error: amount must be greater than zero");
        let i: Int = 0;
        let y: Int = 0;
        let i_a: Address? = null;
        let y_a: Address? = null;
        i_a = msg.path.get(0);
        require(i_a == myAddress(), "Error: first node in path must wallet");
        while (i_a != null) {
            y = i + 1;
            y_a = msg.path.get(y);
            while (y_a != null) {
                require(i_a != y_a, "Error: path is ring");
                y = y + 1;
                y_a = msg.path.get(y);
            }
            i = i + 1; 
            i_a = msg.path.get(i);
        }
        return i - 1; 
    }
}

contract LetsHubV0R0 with Deployable {
    currency: String;
    linkId: Int as uint64 = 0;

    init (currency: String) {
        self.currency = currency;
    }

    receive () {}

    receive (msg: SetTrustlineV0R0) {
        require (sender() == msg.creditor, "Error: only creditor can make link");
        let initLink: StateInit = initOf LetsLinkV0R0(self.linkId, self.currency);
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

    get fun data(): HubDataV0R0 {
        return HubDataV0R0 {
            balance: myBalance(),
            linkId: self.linkId
        };
    }
}

contract LetsLinkV0R0 with Deployable {
    currency: String;
    linkId: Int as uint64;
    trustline: Address? = null;
    creditor: Address? = null;
    debitor: Address? = null;

    init (linkId: Int, currency: String) {
        self.currency = currency;
        self.linkId = linkId;
    }
    
    receive () {
        require(sender() == self.creditor, "Error: Only owner wallet can send empty message");
    }

    receive (msg: SetTrustlineV0R0) {
        let initHub: StateInit = initOf LetsHubV0R0(self.currency);
        require(sender() == contractAddress(initHub), "Error: Only LetsHubV0R0 can set trustline address");
        self.trustline = contractAddress(initOf LetsTrustlineV0R0(msg.creditor, msg.debitor));
        self.creditor = msg.creditor;
        self.debitor = msg.debitor;
    }

    get fun data(): LinkDataV0R0 {
        return LinkDataV0R0 {
            balance: myBalance(),
            trustline: self.trustline,
            creditor: self.creditor,
            debitor: self.debitor
        };
    }
}

contract LetsTrustlineV0R0 with Deployable {
    creditor: Address;
    debitor: Address;
    value: Int as coins = 0;
    limit: Int as coins = 0;
    interest: Int as uint16 = 0;
    interestProject: Int as uint16 = 0;
    active: Bool = false;
    seqno: Int as uint32 = 0;
    lastAccrualTime: Int as uint32 = 0;

    init (creditor: Address, debitor: Address) {
        require (sender() == creditor, "Error: only creditor can create LetsTrustlineV0R0");
        self.creditor = creditor;
        self.debitor = debitor;
    }

    receive ("fund") {
        require(sender() == self.creditor, "Error: Only creditor can funds wallet");
        self.active = true;
        self.seqno = (self.seqno + 1) % 65536;
    }

    receive ("accrual of interest") {
        require(sender() == self.creditor, "Error: only creditor can accrual of interest");
        require(now() - self.lastAccrualTime > 24*60*60, "Error: accrual of interest on the loan no more than once a day");
        self.value = self.value + self.value * self.interest *(now()-self.lastAccrualTime) / (365*24*60*60*100);
        self.lastAccrualTime = now();
        self.seqno = (self.seqno + 1) % 65536;
    }

    receive (msg: SetLimitV0R0) {
        require(self.active, "Error: contract not active");
        require((sender() == self.creditor) && (msg.debitor == self.debitor), "Error: only creditor can set limit or incorrect debitor address");
        self.limit = msg.limit;
        self.reply("Operation success".asComment());
        self.seqno = (self.seqno + 1) % 65536;
    }

    receive (msg: SetInterestProjectV0R0) {
        require(self.active, "Error: contract is not active");
        require((sender() == self.creditor) && (msg.debitor == self.debitor), "Error: only creditor can set interest rate project or incorrect debitor address");
        self.interestProject = msg.interestProject;
        self.reply("Operation success".asComment());
        self.seqno = (self.seqno + 1) % 65536;
    }

    receive (msg: ConfirmInterestV0R0) {
        require(self.active, "Error: contract is not active");
        require((sender() == self.debitor) && (msg.creditor == self.creditor), "Error: only debitor can confirm interest or incorrect creditor address");
        require(self.interestProject == msg.interestProject, "Error: incorrest interest rate project");
        self.interest = self.interestProject;
        self.interestProject = 0;
        self.reply("Operation success".asComment());
        self.lastAccrualTime = now();
        self.seqno = (self.seqno + 1) % 65536;
    }

    fun AddPathBounce(msg: TransferMoneyV0R0):TransferMoneyV0R0 {
        let y: Int = msg.currentStep;
        let i: Int = 1;
        repeat (y) {
            msg.path.set(y + i, msg.path.get(y - i));
            i = i + 1;
        }
        msg.currentStep = y + 2;
        msg.countStep = y * 2;
        return msg;
    }

    fun Mint(msg: TransferMoneyV0R0): Bool {
        if (self.value + msg.amount) <= self.limit {
            self.value = self.value + msg.amount;
            if msg.currentStep == msg.countStep {
                send(SendParameters{
                    to: msg.path.get(0)!!,
                    value: 0,
                    mode: SendRemainingValue,
                    body: "payment chain end".asComment()
                });
                return true; 
            } 
            msg.currentStep = msg.currentStep + 1;
            let startNode: Address? = msg.path.get(msg.currentStep-1);
            let endNode: Address? = msg.path.get(msg.currentStep);
            send(SendParameters{
                to: contractAddress(initOf LetsTrustlineV0R0(endNode!!, startNode!!)),
                value: 0,
                mode: SendRemainingValue,
                body: msg.toCell() });
            return true;
        } else 
        {
            msg = self.AddPathBounce(msg);
            let startNode: Address? = msg.path.get(msg.currentStep-1);
            let endNode: Address? = msg.path.get(msg.currentStep);
            send(SendParameters{
                to: contractAddress(initOf LetsTrustlineV0R0(startNode!!, endNode!!)),
                value: 0,
                mode: SendRemainingValue,
                body: msg.toCell() });
            send(SendParameters{
                    to: msg.path.get(0)!!,
                    value: 0,
                    mode: SendRemainingValue,
                    body: "Operation error".asComment()
                });
            return false;
        }
    } 

    fun Burn(msg: TransferMoneyV0R0): Bool {
        if (self.value >= msg.amount) {
            self.value = self.value - msg.amount;
            if msg.currentStep == msg.countStep { 
                send(SendParameters{
                    to: msg.path.get(0)!!,
                    value: 0,
                    mode: SendRemainingValue,
                    body: "payment chain end".asComment()
                });
                return true; 
            } 
            msg.currentStep = msg.currentStep + 1;
            let startNode: Address? = msg.path.get(msg.currentStep-1);
            let endNode: Address? = msg.path.get(msg.currentStep);
            send(SendParameters{
                to: contractAddress(initOf LetsTrustlineV0R0(startNode!!, endNode!!)),
                value: 0,
                mode: SendRemainingValue,
                body: msg.toCell()
            });  
            return true;
        } else 
        {
            msg = self.AddPathBounce(msg);
            let startNode: Address? = msg.path.get(msg.currentStep-1);
            let endNode: Address? = msg.path.get(msg.currentStep);
            send(SendParameters{
                to: contractAddress(initOf LetsTrustlineV0R0(endNode!!, startNode!!)),
                value: 0,
                mode: SendRemainingValue,
                body: msg.toCell() });
            send(SendParameters{
                    to: msg.path.get(0)!!,
                    value: 0,
                    mode: SendRemainingValue,
                    body: "Operation error".asComment()
                });
            return false;
        }
    }

    receive (msg: TransferMoneyV0R0) {
        require(self.active, "Error: contract not active");
        if (sender() == self.creditor) {
            self.Burn(msg); self.seqno = (self.seqno + 1) % 65536; return;
        }
        if (sender() == self.debitor) {
            self.Mint(msg); self.seqno = (self.seqno + 1) % 65536; return;
        }
        let startNode: Address? = msg.path.get(msg.currentStep-2);
        let endNode: Address? = msg.path.get(msg.currentStep-1);
        let trustlineBurn: Address = contractAddress(initOf LetsTrustlineV0R0(startNode!!, endNode!!));
        let trustlineMint: Address = contractAddress(initOf LetsTrustlineV0R0(endNode!!, startNode!!));
        if (sender() == trustlineMint) {
            self.Mint(msg); 
            self.seqno = (self.seqno + 1) % 65536;
            return;
        }
        if (sender() == trustlineBurn) {
            self.Burn(msg);
            self.seqno = (self.seqno + 1) % 65536;
            return;
        }
    }

    get fun data(): TrustlineDataV0R0 {
        return TrustlineDataV0R0 {
            value: self.value,
            limit: self.limit,
            interest: self.interest,
            interestProject: self.interestProject,
            balance: myBalance(),
            seqno: self.seqno,
            creditor: self.creditor,
            debitor: self.debitor
        };
    }

    get fun seqno(): Int {
        return self.seqno;
    }
}

message LinkDataV0R0 {
    balance: Int as coins;
    trustline: Address?;
    creditor: Address?;
    debitor: Address?;
}

message HubDataV0R0 {
    balance: Int as coins;
    linkId: Int as uint64;
}

message SetContentWalletDataV0R0 {
    signature: Slice as bytes64;
    header: Slice;
    content: Cell;
}

message WalletDataV0R0 {
    publickeyOwner: Int as uint256;
    publickeySponsor: Int? as uint256;
    currency: String;
    addressSponsor: Address?;
    balance: Int as coins;
    content: Cell?;
    seqno: Int as uint32;
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
    seqno: Int as uint32;
    creditor: Address;
    debitor: Address;
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
    currentStep: Int as uint8;
    countStep: Int as uint8;
    path: map<Int as uint8, Address>; 
    tontoTrustline: Int as coins;
}
