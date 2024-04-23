import "@stdlib/deploy";

contract LetsWalletV1R0 {
    publickeyOwner: Int as uint256;
    seqno: Int as uint32 = 0;
    currency: String;
    version: String = "LetsWalletV1R0";
    linkId: Int as uint64 = 0;
    addressSponsor: Address? = null;
    publickeySponsor: Int? as uint256 = null;
    owner: Address;
    content: Cell? = null;

    init(currency: String, publicKey: Int) {
        self.publickeyOwner = publicKey;
        self.currency = currency;
        self.owner = sender();
    }

    receive () {}

    external(msg: SetSponsor) {
        require((self.publickeySponsor == null) && (self.addressSponsor == null), "Error: Sponsor already exist");

        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            acceptMessage();
            self.seqno = (self.seqno + 1) % 65536;
            self.publickeySponsor = msg.publicKey;
            self.addressSponsor = msg.address; 
        }
        
    }

    external(msg: CancelSponsor) {
        require((self.publickeySponsor != null) || (self.addressSponsor != null), "Error: Sponsor no set");

        if (self.CheckMsg(msg.signature, msg.header, self.publickeySponsor!!)) {
            acceptMessage();
            self.seqno = (self.seqno + 1) % 65536;
            self.publickeySponsor = null;
            self.addressSponsor = null; 
        }
    }

    external(msg: SendMoney) {
        if (self.CheckMsg(msg.signature, msg.header, self.publickeyOwner)) {
            acceptMessage();
            self.seqno = (self.seqno + 1) % 65536;
        }
        let i: Int = 0;
        let x: Address? = null;
        repeat(4) {
            x = msg.path.get(i);
            dump(i);
            i = i + 1;
        }
    }

    get fun Data(): WalletDataV1R0 {
        return WalletDataV1R0 { 
            publickeyOwner: self.publickeyOwner,
            publickeySponsor: self.publickeySponsor,
            seqno: self.seqno,
            currency: self.currency,
            version: self.version,
            linkId: self.linkId,
            addressSponsor: self.addressSponsor,
            addressOwner: myAddress(),
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

        return true;
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


message WalletDataV1R0 {
    publickeyOwner: Int as uint256;
    publickeySponsor: Int? as uint256;
    seqno: Int as uint64;
    currency: String;
    version: String;
    linkId: Int as uint64;
    addressSponsor: Address?;
    addressOwner: Address;
    balance: Int as coins;
}

message SetSponsor {
    signature: Slice as bytes64;
    header: Slice;
    address: Address? = null;
    publicKey: Int? as uint256 = null;
}

message CancelSponsor {
    signature: Slice as bytes64;
    header: Slice;
}

message SendMoney {
    signature: Slice as bytes64;
    header: Slice;
    path: map<Int as uint8, Address>;
}