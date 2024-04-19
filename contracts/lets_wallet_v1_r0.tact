import "@stdlib/deploy";

contract LetsWalletV1R0 {
    publicKey: Int as uint256;
    seqno: Int as uint64;
    walletId: Int as uint64;
    currency: String;
    version: String = "LetsWalletV1R0";

    init(currency: String, publicKey: Int, walletId: Int) {
        self.publicKey = publicKey;
        self.seqno = 0;
        self.walletId = walletId;
        self.currency = currency;
    }
}
