import "@stdlib/deploy";

contract LetsWalletV1R0 {
    publicKey: Int as uint256;
    seqno: Int as uint64 = 0;
    walletId: Int as uint64;
    currency: String;
    version: String = "LetsWalletV1R0";
    linkId: Int as uint64 = 0;

    init(currency: String, publicKey: Int, walletId: Int) {
        self.publicKey = publicKey;
        self.walletId = walletId;
        self.currency = currency;
    }
}

contract LetsLinkV1R0 {
    wallet: Address;
    trustline: Address? = null;
    linkId: Int as uint64;
    version: String = "LetsLinkV1R0";

    init (wallet: Address, linkId: Int) {
        self.wallet = wallet;
        self.linkId = linkId;
    }
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
}
