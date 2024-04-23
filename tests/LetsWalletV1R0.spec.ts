import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { beginCell, Cell, Dictionary, toNano } from '@ton/core';
import { LetsWalletV1R0 } from '../wrappers/LetsWalletV1R0';
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
    let keypair_User1: KeyPair;
    let keypair_User2: KeyPair;


    beforeEach(async () => {         
        keypair_User1 = await mnemonicToWalletKey(mnemonicWallet1);
        keypair_User2 = await mnemonicToWalletKey(mnemonicWallet2);

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
        let data = await wallet_1.getData();
        let timeout = Math.floor(Date.now() / 1000) + 20;

        console.log('wallet_1 data = ', data);
        
    });


    it('Test #2', async () => {
        let data = await wallet_1.getData();
        let timeout = Math.floor(Date.now() / 1000) + 20;

        console.log('wallet_1 data = ', data);

        let dictUser1 = Dictionary.empty(Dictionary.Keys.Int(8), Dictionary.Values.Address());

        dictUser1.set(0, User1.address);
        dictUser1.set(1, User2.address);
        dictUser1.set(2, User1.address);
        dictUser1.set(3, User2.address);
        dictUser1.set(4, User1.address);
        dictUser1.set(8, User1.address);

        let header = beginCell()
            .storeUint(timeout, 32)
            .storeUint(data.seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
        
        let header_signature = sign(header.hash(), keypair_User1.secretKey); 

        await wallet_1.sendExternal({
            $$type: 'SendMoney',
            signature: header_signature,
            header: header,
            path: dictUser1,
        });
        console.log('wallet_1 data = ', await wallet_1.getData());

    });

    it('Test #3', async () => {
        let data = await wallet_1.getData();
        let timeout = Math.floor(Date.now() / 1000) + 20;

        console.log('wallet_1 data = ', data);

        let header = beginCell()
            .storeUint(timeout, 32)
            .storeUint(data.seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
        
        
        let header_signature = sign(header.hash(), keypair_User1.secretKey); 
        
        await wallet_1.sendExternal({
            $$type: 'SetSponsor',
            signature: header_signature,
            header: header,
            address: User2.address,
            publicKey: toBigIntBE(keypair_User2.publicKey)
        });
        data = await wallet_1.getData()
        console.log('wallet_1 data = ', data);

        header = beginCell()
            .storeUint(timeout+20, 32)
            .storeUint(data.seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
        header_signature = sign(header.hash(), keypair_User2.secretKey); 

        await wallet_1.sendExternal({
            $$type: 'CancelSponsor',
            signature: header_signature,
            header: header
        });
        console.log('wallet_1 data = ', await wallet_1.getData());

    });


});
