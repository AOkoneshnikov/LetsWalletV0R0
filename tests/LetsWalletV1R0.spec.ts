import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { beginCell, Cell, toNano } from '@ton/core';
import { LetsWalletV1R0, WalletOperationV1R0, DataSponsor } from '../wrappers/LetsWalletV1R0';
import '@ton/test-utils';
import { keyPairFromSeed, keyPairFromSecretKey, sign, signVerify, KeyPair, getSecureRandomBytes, mnemonicNew, mnemonicToWalletKey, sha256 } from 'ton-crypto';
import { TonClient } from '@ton/ton';
import { toBigIntBE, toBigIntLE } from '@trufflesuite/bigint-buffer';
import { Slice } from 'ton';
import 'json-bigint';


describe('LetsWalletV1R0', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let User1: SandboxContract<TreasuryContract>;
    let User2: SandboxContract<TreasuryContract>;
    let Sponsor: SandboxContract<TreasuryContract>;
    let wallet_1: SandboxContract<LetsWalletV1R0>;
    let wallet_2: SandboxContract<LetsWalletV1R0>;
    const mnemonicWallet1 =  [
        'release', 'junior',  'cake',
        'boost',   'stock',   'illness',
        'parent',  'move',    'gain',
        'acid',    'merge',   'search',
        'female',  'federal', 'apology',
        'art',     'trade',   'seminar',
        'message', 'tooth',   'scheme',
        'broom',   'mention', 'security'
      ];  
    const mnemonicWallet2 =  [
        'cover',   'orient', 'put',
        'large',   'ivory',  'crowd',
        'glow',    'sort',   'runway',
        'laundry', 'lawn',   'price',
        'prize',   'horror', 'turtle',
        'elbow',   'cheese', 'shoulder',
        'village', 'shell',  'jealous',
        'welcome', 'wink',   'mind'
      ];

    beforeEach(async () => {         
        const keypair_User1: KeyPair = await mnemonicToWalletKey(mnemonicWallet1);
        const keypair_User2: KeyPair = await mnemonicToWalletKey(mnemonicWallet2);

        blockchain = await Blockchain.create();
        wallet_1 = blockchain.openContract(await LetsWalletV1R0.fromInit('RUB', toBigIntBE(keypair_User1.publicKey)));

        deployer = await blockchain.treasury('deployer');
        User1 = await blockchain.treasury('User1');
        User2 = await blockchain.treasury('User2');

        const deployResult = await wallet_1.send(
            deployer.getSender(),
            {
                value: toNano('5'),
            },
            null,
        );
    });

    it('Test #1', async () => {
        const keypair_User1: KeyPair = await mnemonicToWalletKey(mnemonicWallet1);
        const keypair_User2: KeyPair = await mnemonicToWalletKey(mnemonicWallet2);

        let data = await wallet_1.getData();
        let timeout = Math.floor(Date.now() / 1000) + 20;

        console.log('wallet_1 data = ', data);

        let operation_data = beginCell()
            .storeUint(0,8)
            .storeUint(timeout, 32)
            .storeUint(data.seqno,64)
            .storeUint(1,8)
            .storeRef(
                beginCell()
                .storeAddress(User2.address)
                .storeUint(toBigIntBE(keypair_User2.publicKey),256)
                .endCell()
            )
            .endCell();
        
        
        let data_signature = sign(operation_data.hash(), keypair_User1.secretKey); 
        
        wallet_1.sendExternal({
            $$type: 'WalletOperationV1R0',
            signature: data_signature,
            operation: operation_data,
        });


            
    });

});
