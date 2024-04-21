import "@stdlib/deploy";

contract LetsWalletV1R0 {
    publicKey: Int as uint256;
    seqno: Int as uint64 = 0;
    currency: String;
    version: String = "LetsWalletV1R0";
    linkId: Int as uint64 = 0;
    sponsor: Address? = null;

    init(currency: String, publicKey: Int) {
        self.publicKey = publicKey;
        self.currency = currency;
    }

    receive () {}

    external(msg: WalletOperationV1R0) {
        dump(1);

        // Check Signature
        let op_hash: Int = msg.operation.hash();
        require(checkSignature(op_hash, msg.signature, self.publicKey), "Invalid signature");

        dump(2);

        let pkg: Slice = msg.operation;
        let seqno: Int = pkg.loadInt(32);
        require(seqno == self.seqno, "Invalid seqno");
        acceptMessage();
        self.seqno = (self.seqno + 1);
        commit();

        dump(3);

        let mode: Int = pkg.loadUint(8); // Operation type
        if (mode == 0) { 
            dump(4);
        } else if (mode == 1) {
            dump(5);
        } else if (mode == 2) {
            dump(6);
        } else if (mode == 3) {
            dump(7);
        }
    }

    get fun Data(): WalletDataV1R0 {
        return WalletDataV1R0 { 
            publicKey: self.publicKey,
            seqno: self.seqno,
            currency: self.currency,
            version: self.version,
            linkId: self.linkId,
            sponsor: self.sponsor,
            balance: myBalance()
        };
    }
}

contract LetsLinkV1R0 {
    wallet: Address;
    trustline: Address? = null;
    linkId: Int as uint64;
    version: String = "LetsLinkV1R0";

    init (wallet: Address, linkId: Int) {
        require(sender() == wallet, "Error: Only wallet can create LetsLinkV1R0");
        self.wallet = wallet;
        self.linkId = linkId;
    }

    receive () {}
}

contract LetsTrustlineV1R0 {
    creditor: Address;
    debitor: Address;
    value: Int as coins = 0;
    limit: Int as coins = 0;
    interest: Int as uint16 = 0;
    feeMultiplicator: Int as uint8 = 10;

    init (creditor: Address, debitor: Address) {
        require (sender() == creditor, "Error: ");
        self.creditor = creditor;
        self.debitor = debitor;
    }

    receive () {}
}

message (0x01) WalletOperationV1R0 {
    signature: Slice as bytes64;
    operation: Slice as remaining;
}

message(0x02) WalletDataV1R0 {
    publicKey: Int as uint256;
    seqno: Int as uint64;
    currency: String;
    version: String;
    linkId: Int as uint64;
    sponsor: Address?;
    balance: Int as coins;
}

