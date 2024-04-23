import "@stdlib/deploy";

contract LetsWalletV1R0 {
    publickeyOwner: Int as uint256;
    seqno: Int as uint64 = 0;
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
        //let pkg: Slice = msg.data;
    }

    external(msg: WalletOperationV1R0) {

        let pkg: Slice = msg.operation;
        let owner: Int = pkg.loadInt(8);

        // Check Signature
        let op_hash: Int = msg.operation.hash();
        if (owner == 0) { // owner self
            require(checkSignature(op_hash, msg.signature, self.publickeyOwner), "Error: Invalid signature");
        }
        else {   // sponsor
            require(checkSignature(op_hash, msg.signature, self.publickeySponsor!!), "Error: Invalid signature");
        }
        
        // Check parameters
        let timeout: Int = pkg.loadInt(32);
        let seqno: Int = pkg.loadInt(64);
        let mode: Int = pkg.loadUint(8); // Operation type

        require(seqno == self.seqno, "Error: Invalid seqno");
        require(now() < timeout, "Error: Transfer expired");

        acceptMessage();
        self.seqno = (self.seqno + 1);
        commit();

        if (mode == 0) && (owner == 0) { // send money
            dump(4);
        } else if (mode == 1) && (owner == 0) { // set Sponsor
            let cellSponsor: Slice = pkg.loadRef().asSlice();
            let addressSponsor: Address = cellSponsor.loadAddress();
            let publickeySponsor: Int = cellSponsor.loadUint(256);
            self.setSponsor(addressSponsor, publickeySponsor);
        } else if (mode == 2) && (owner == 1) { // disable Sponsor
            dump(6);
        } else if (mode == 3) && (owner == 0){ // create trustline
            dump(7);
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
            balance: myBalance()
        };
    }

    fun setSponsor(addressSponsor: Address, publickeySponsor: Int) {
        require((self.addressSponsor == null) && (self.publickeySponsor == null), "Error: Sponsor wallet already set");
        self.addressSponsor = addressSponsor;
        self.publickeySponsor = publickeySponsor;
        dump("sponsor set");
    }

    fun disableSponsor() {
        self.addressSponsor = null;
        self.publickeySponsor = null;
        dump("sponsor disabled");
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
    publickeyOwner: Int as uint256;
    publickeySponsor: Int? as uint256;
    seqno: Int as uint64;
    currency: String;
    version: String;
    linkId: Int as uint64;
    addressSponsor: Address?;
    balance: Int as coins;
}

struct DataSponsor {
    address: Address? = null;
    publicKey: Int? as uint256 = null;
} 

message(0x03) SetSponsor {
    signature: Slice as bytes64;
    data: DataSponsor; 
}

