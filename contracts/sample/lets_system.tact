import "@stdlib/deploy";
import "@stdlib/ownable"; 

contract LetsProviderV0 with Deployable, OwnableTransferable {
    seqno: Int as uint64 = 0;
    owner: Address;
    currency: String;

    init(codeCurrency: String) {
        self.owner = sender();
        self.currency = codeCurrency;
    } 

    receive ()
    {
        //default empty message
    }

    receive ("create wallet link") {
        let initWallet: StateInit = initOf LetsWalletV0(self.currency, sender());
        let initLink: StateInit = initOf LetsWalletlinkV0(self.currency, self.seqno);

        send(SendParameters{
            to: contractAddress(initLink),
            value: 0,              
            mode: SendRemainingValue,
            body: SetWallet{wallet: contractAddress(initWallet)}.toCell(),
            code: initLink.code,               
            data: initLink.data    
        });
        self.seqno = self.seqno + 1;
    }
}

contract LetsWalletlinkV0 with Deployable {
    seqno: Int as uint64 = 0;
    wallet: Address? = null;
    provider: Address;
    currency: String;

    init(codeCurrency: String, seqno: Int) {
        self.provider = contractAddress(initOf LetsProviderV0(codeCurrency)); 
        require(sender() == self.provider, "Error: Only provider can init link to wallet");
        self.seqno = seqno;
        self.currency = codeCurrency;
    }

    receive ()
    {
        //default empty message
    }

    receive (msg: Withdraw) {
        require(self.wallet != null, "Wallet address not specified"); 
        require(sender() == self.wallet, "Ony wallet can withdraw");
        send(SendParameters{
            to: self.wallet!!,
            value: msg.amount, 
            body: "withdraw".asComment() 
            });
    }

    receive (msg: SetWallet) {
        require(self.wallet == null, "The wallet address has already been determined"); 
        require(sender() == self.provider, "Ony provider can set wallet address");
        self.wallet = msg.wallet;
    }

    get fun Info(): WalletlinkInfo {
        return WalletlinkInfo {
            seqno: self.seqno, 
            wallet: self.wallet, 
            provider: self.provider,
            currency: self.currency,
            balance: myBalance()};
    }
}

contract LetsWalletV0 with Deployable, Ownable {
    seqno: Int as uint64 = 0; 
    owner: Address;
    currency: String;
    sponsor: Address? = null;

    init(codeCurrency: String, userAddress: Address) {
        require(sender() == userAddress, "002 Error: Only the user can create a wallet");
        self.owner = userAddress;
        self.currency = codeCurrency;
    }

    receive () {
        //default empty message
    }

    receive ("create trustline link") {
        let initLink: StateInit = initOf LetsTrustlinelinkV0(self.currency, self.owner, self.seqno);

        send(SendParameters{
            to: contractAddress(initLink),
            value: 0,              
            mode: SendRemainingValue,
            //body: SetTrustline{trustline: }.toCell(),
            code: initLink.code,               
            data: initLink.data    
        });
        self.seqno = self.seqno + 1;
    }

    receive (msg: Withdraw) {
        if (self.sponsor == null) {
            require(sender() == self.owner, "Error: Only owner can withdraw");
            send(SendParameters{
                to: self.owner,
                value: msg.amount, 
                body: "withdraw".asComment() 
            });
        }
        else {
            require(sender() == self.sponsor, "Error: Only sponsor can withdraw");
            send(SendParameters{
                to: self.sponsor!!,
                value: msg.amount, 
                body: "withdraw".asComment() 
            });
        }
    }

    get fun Info(): WalletInfo {
        return WalletInfo {
            seqno: self.seqno,
            owner: self.owner, 
            sponsor: self.sponsor,
            currency: self.currency,
            balance: myBalance()};
    }
}

contract LetsTrustlinelinkV0 with Deployable {
    seqno: Int as uint64 = 0;
    wallet: Address;
    trustline: Address? = null;
    currency: String;
    
    init(codeCurrency: String, userAddress: Address, seqno: Int) {
        self.wallet = contractAddress(initOf LetsWalletV0(codeCurrency, userAddress));  
        require(sender() == self.wallet, "Error: Only wallet can init link to trustline");
        self.seqno = seqno;
        self.currency = codeCurrency;
    }

    receive () {
        //default empty message
    }

    receive (msg: SetTrustline) {
        require(self.trustline != null, "Error: The trustline address has already been determined"); 
        require(sender() == self.wallet, "Error: Only wallet can set trustline address");
        self.trustline = msg.trustline;
    }
    receive (msg: Withdraw) {
        require(sender() == self.wallet, "Ony wallet can withdraw");
        send(SendParameters{
            to: self.wallet,
            value: msg.amount, 
            body: "withdraw".asComment() 
            });
    }
    get fun Info(): TrustlineLinkInfo {
        return TrustlineLinkInfo {
            seqno: self.seqno, 
            wallet: self.wallet, 
            trustline: self.trustline,
            currency: self.currency,
            balance: myBalance()};
    }
}

contract LetsTrustlineV0 with Deployable, Ownable {
    owner: Address;
    debitor: Address;
    currency: String;
    value: Int as coins = 0;
    limit: Int as coins = 0;
    addressWallet: Address;
    addressWalletDebitor: Address;
    feeMultiplicator: Int as uint8 = 10;  
    interest: Int as uint16 = 0;  

    init(creditor: Address, debitor: Address, currency: String) {
        require(sender() == creditor, "Error: creditor must sender");
        self.owner = creditor;
        self.debitor = debitor;
        self.currency = currency;
        self.addressWallet = contractAddress(initOf LetsWalletV0(currency, creditor)); 
        self.addressWalletDebitor = contractAddress(initOf LetsWalletV0(currency, debitor));
    }

    receive ()
    {
        //default empty message
    }

    receive (msg: SetLimit) {
        self.requireOwner();
        self.limit = msg.limit;
    }

    receive (msg: Withdraw) {
        require(sender() == self.addressWallet, "Ony wallet can withdraw");
        send(SendParameters{
            to: self.addressWallet,
            value: msg.amount, 
            body: "withdraw".asComment() 
            });
    }

    // return -1 if path incorrect or node count in chain if path is normal
    fun checkPath(msg: Transfer): Int {
        let startNodeAddress: Address? = null;
        let nextNodeAddress: Address? = null;
        let i: Int = 0;
        let y: Int = 0;

        startNodeAddress = msg.chain.get(0)!!;
            while (startNodeAddress!= null) {
                nextNodeAddress = msg.chain.get(i + 1)!!;
                while (nextNodeAddress != null) {
                    if (nextNodeAddress == startNodeAddress) {
                        self.reply("Error: path payment is ring".asComment());
                        return -1;
                    }
                    y = y + 1;
                    nextNodeAddress = msg.chain.get(y)!!;
                }
                i = i + 1;
                startNodeAddress = msg.chain.get(i)!!;
            }
        return i;
    }

    fun sendtoNext(nodeStart: Address, nodeNext: Address, msg: Transfer) {
        let sendAddress: Address = contractAddress(initOf LetsTrustlineV0(nodeStart, nodeNext, self.currency));
        send(SendParameters{
                        to: sendAddress,
                        bounce: true,
                        value: 0,
                        mode: SendRemainingValue,
                        body: msg.toCell()
                    });
    }

    fun payOperation(onCredit: Bool, amount: Int) {
        if (onCredit) {
            if (amount + self.value < self.limit) {
                self.value = self.value + amount;
            }
            else {
                throw (123);
            }
        }
        else {
            if (amount < self.value) {
                self.value = self.value - amount;
            }
            else {
                throw (123);
            }  
        }
    }

    bounced (src: bounced<Transfer>) {
        dump(12345678);
    }

    receive (msg: Transfer)
    {     
        let ctx: Context = context();
     
        if (msg.onCredit) { 
            if (sender() == self.addressWalletDebitor) {
                let countNodes: Int = self.checkPath(msg);
                if (countNodes == -1) { return; } else { msg.countNodes = countNodes; }
                if (ctx.value < countNodes * self.feeMultiplicator * ctx.readForwardFee()) {
                    self.reply("Error: not enouth ton for process transfer".asComment());
                    return;
                }
                self.payOperation(true, msg.amount);
                let nextNodeAddress: Address? = msg.chain.get(2);
                if (nextNodeAddress == null) {
                    self.reply("Transfer operation success".asComment());
                    return; 
                }
                msg.currentStep = 3; 
                self.sendtoNext(nextNodeAddress!!, self.owner, msg);
                }
            if (sender() == contractAddress(initOf LetsTrustlineV0(msg.chain.get(msg.currentStep-1)!!, msg.chain.get(msg.currentStep-2)!!, self.currency))) {
                self.payOperation(true, msg.amount);
                let nextNodeAddress: Address? = msg.chain.get(msg.currentStep);
                if (nextNodeAddress == null) {
                    send(SendParameters{
                        to: msg.chain.get(0)!!,
                        bounce: true,
                        value: 0,
                        mode: SendRemainingValue + SendIgnoreErrors,
                        body: "Transfer operation success".asComment()
                    });
                    return; 
                }
                msg.currentStep = msg.currentStep + 1;
                self.sendtoNext(nextNodeAddress!!, self.owner, msg);
            }
        } 
        else {  
            if (sender() == self.addressWallet) {
                let countNodes: Int = self.checkPath(msg);
                if (countNodes == -1) { return; } else { msg.countNodes = countNodes; }
                if (ctx.value < countNodes * self.feeMultiplicator * ctx.readForwardFee()) {
                    self.reply("Error: not enouth ton for process transfer".asComment());
                    return;
                }
                self.payOperation(false, msg.amount);
                let nextNodeAddress: Address? = msg.chain.get(2);
                if (nextNodeAddress == null) {
                    self.reply("Transfer operation success".asComment());
                    return; 
                } 
                msg.currentStep = 3;
                self.sendtoNext(self.debitor, nextNodeAddress!!, msg);
            }

            if (sender() == contractAddress(initOf LetsTrustlineV0(msg.chain.get(msg.currentStep-2)!!, msg.chain.get(msg.currentStep-1)!!, self.currency))) {
                self.payOperation(false, msg.amount);
                let nextNodeAddress: Address? = msg.chain.get(msg.currentStep);
                if (nextNodeAddress == null) {
                    send(SendParameters{
                        to: msg.chain.get(0)!!,
                        bounce: true,
                        value: 0,
                        mode: SendRemainingValue + SendIgnoreErrors,
                        body: "Transfer operation success".asComment()
                    });
                    return; 
                }
                msg.currentStep = msg.currentStep + 1;
                self.sendtoNext(self.debitor, nextNodeAddress!!, msg);
            }
            else {
                throw(123);
            }
        }

        send(SendParameters{
            to: msg.chain.get(0)!!,
            bounce: true,
            value: 0,
            mode: SendRemainingValue + SendIgnoreErrors,
            body: "Error: Transfer operation failed".asComment()
        });
    }

    get fun Info(): TrustlineInfo {
        return TrustlineInfo {
            owner: self.owner, 
            debitor: self.debitor, 
            currency: self.currency,
            value: self.value,
            limit: self.limit,
            addressWallet: self.addressWallet,
            addressWalletDebitor: self.addressWalletDebitor,
            feeMultiplicator: self.feeMultiplicator,
            interest: self.interest,
            balance: myBalance()};
    }
}

message(0x01) SetLimit {
    limit: Int as coins;
}

message(0x02) Transfer {
    amount: Int as coins = 0;
    onCredit: Bool = false;
    chain: map<Int as uint8, Address>;
    countNodes: Int as uint8 = 0;
    currentStep: Int as uint8 = 0;
}

message(0x03) Withdraw {
    amount: Int as coins;
}

message(0x04) SetWallet {
    wallet: Address;
}

message(0x05) SetTrustline {
    trustline: Address;
}

message(0x06) WalletlinkInfo {
    seqno: Int;
    wallet: Address?;
    provider: Address;
    currency: String;
    balance: Int as coins;
} 

message(0x07) WalletInfo {
    seqno: Int as uint64 = 0;
    owner: Address;
    sponsor: Address?;
    currency: String;
    balance: Int as coins;
}

message(0x08) TrustlineLinkInfo {
    seqno: Int as uint64;
    wallet: Address;
    trustline: Address?;
    currency: String;
    balance: Int as coins;
}

message(0x09) TrustlineInfo {
    owner: Address;
    debitor: Address;
    currency: String;
    value: Int as coins;
    limit: Int as coins;
    addressWallet: Address;
    addressWalletDebitor: Address;
    feeMultiplicator: Int as uint8;  
    interest: Int as uint16;
    balance: Int as coins;
}