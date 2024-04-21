import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { beginCell, Cell, toNano } from '@ton/core';
import { LetsWalletV1R0, WalletOperationV1R0 } from '../wrappers/LetsWalletV1R0';
import '@ton/test-utils';
import { keyPairFromSeed, keyPairFromSecretKey, sign, signVerify, KeyPair, getSecureRandomBytes, mnemonicNew, mnemonicToWalletKey } from 'ton-crypto';
import { TonClient } from '@ton/ton';

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

        console.log('keypair = ', keypair_User1.publicKey.toString('hex'));
        let wallet_1_publicKey = BigInt('0x' + keypair_User1.publicKey.toString('hex'));

        console.log('key bigint = ', wallet_1_publicKey);
        
        

        wallet_1 = blockchain.openContract(await LetsWalletV1R0.fromInit('RUB', wallet_1_publicKey));

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

        console.log('wallet_1 data = ', data);

        let wallet_1_operation_data = beginCell()
                                    .storeUint(0,32)
                                    .storeUint(1,8)                        
                                    .endCell();

        //console.log(wallet_1_operation_data.toBoc());
        const wallet_1_data_signature = sign(wallet_1_operation_data.toBoc(), keypair_User1.secretKey); 
        console.log('wallet_1_data_signature = ', wallet_1_data_signature);

        let sss = Cell.fromBoc(wallet_1_operation_data.toBoc());
        console.log('sss', sss);

        //wallet_1.sendExternal()


            
    });

});
