import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { beginCell, Cell, Dictionary, fromNano, toNano } from '@ton/core';
import { LetsWalletV0R0, CreateTrustlineV0R0 } from '../wrappers/LetsWalletV0R0';
import '@ton/test-utils';
import { keyPairFromSeed, keyPairFromSecretKey, sign, signVerify, KeyPair, getSecureRandomBytes, mnemonicNew, mnemonicToWalletKey, sha256 } from 'ton-crypto';
import { TonClient } from '@ton/ton';
import { toBigIntBE, toBigIntLE } from '@trufflesuite/bigint-buffer';
import { Slice } from 'ton';
import 'json-bigint';
import { LetsTrustlineLinkV0R0 } from '../build/LetsWalletV0R0/tact_LetsTrustlineLinkV0R0';
import { LetsHubV0R0 } from '../build/LetsWalletV0R0/tact_LetsHubV0R0';
import { LetsHubLinkV0R0 } from '../build/LetsWalletV0R0/tact_LetsHubLinkV0R0';
import { LetsLinkV0R0 } from '../build/LetsWalletV0R0/tact_LetsLinkV0R0';
import { LetsTrustlineV0R0 } from '../build/LetsWalletV0R0/tact_LetsTrustlineV0R0';



describe('LetsWalletV1R0', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let User1: SandboxContract<TreasuryContract>;
    let User2: SandboxContract<TreasuryContract>;
    let User3: SandboxContract<TreasuryContract>;
    let User4: SandboxContract<TreasuryContract>;
    let User5: SandboxContract<TreasuryContract>;
    let User6: SandboxContract<TreasuryContract>;
    let Sponsor: SandboxContract<TreasuryContract>;
    let wallet_1: SandboxContract<LetsWalletV0R0>;
    let wallet_2: SandboxContract<LetsWalletV0R0>;
    let wallet_3: SandboxContract<LetsWalletV0R0>;
    let wallet_4: SandboxContract<LetsWalletV0R0>;
    let wallet_5: SandboxContract<LetsWalletV0R0>;
    let wallet_6: SandboxContract<LetsWalletV0R0>;
    let hub: SandboxContract<LetsHubV0R0>;

    let wallets = [];
    let keypairs = [];
    
    const mnemonicSponsor =   [
        'student', 'pattern', 'arctic',
        'false',   'swim',    'avocado',
        'bring',   'flock',   'lend',
        'hurry',   'lift',    'actual',
        'basic',   'assist',  'carpet',
        'skate',   'life',    'chest',
        'awake',   'smoke',   'dumb',
        'weird',   'oxygen',  'gravity'
      ];

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

      const mnemonicWallet3 =  [
        'silk',   'say',     'valve',
        'usual',  'present', 'mammal',
        'you',    'drama',   'sauce',
        'tail',   'flag',    'barely',
        'ginger', 'tribe',   'magnet',
        'mango',  'team',    'poet',
        'tree',   'supreme', 'bright',
        'arctic', 'calm',    'come'
      ];

      const mnemonicWallet4 = [
        'chuckle', 'chair',   'because',
        'emerge',  'same',    'slot',
        'mansion', 'army',    'state',
        'slogan',  'kingdom', 'lift',
        'issue',   'slice',   'negative',
        'dragon',  'bullet',  'service',
        'table',   'ugly',    'smart',
        'pull',    'leader',  'nose'
      ];

      const mnemonicWallet5 = [
        'muscle',   'prepare', 'guilt',
        'empower',  'depend',  'couch',
        'roof',     'shy',     'cupboard',
        'civil',    'eagle',   'butter',
        'enemy',    'wonder',  'buyer',
        'current',  'hollow',  'razor',
        'mountain', 'inmate',  'concert',
        'ordinary', 'type',    'ankle'
      ];

      const mnemonicWallet6 =[
        'hat',     'hidden',   'canoe',
        'future',  'wasp',     'good',
        'town',    'dutch',    'police',
        'fortune', 'you',      'horror',
        'armor',   'innocent', 'oval',
        'improve', 'practice', 'logic',
        'ketchup', 'love',     'clerk',
        'always',  'auto',     'goose'
      ];

    let keypair_User1: KeyPair;
    let keypair_User2: KeyPair;
    let keypair_User3: KeyPair;
    let keypair_User4: KeyPair;
    let keypair_User5: KeyPair;
    let keypair_User6: KeyPair;
    let keypair_Sponsor: KeyPair;


    beforeEach(async () => {        
        keypair_Sponsor = await mnemonicToWalletKey(mnemonicSponsor); 
        keypair_User1 = await mnemonicToWalletKey(mnemonicWallet1);
        keypair_User2 = await mnemonicToWalletKey(mnemonicWallet2);
        keypair_User3 = await mnemonicToWalletKey(mnemonicWallet3);
        keypair_User4 = await mnemonicToWalletKey(mnemonicWallet4);
        keypair_User5 = await mnemonicToWalletKey(mnemonicWallet5);
        keypair_User6 = await mnemonicToWalletKey(mnemonicWallet6);
        

        blockchain = await Blockchain.create();
        wallet_1 = blockchain.openContract(await LetsWalletV0R0.fromInit('RUB', toBigIntBE(keypair_User1.publicKey)));
        wallet_2 = blockchain.openContract(await LetsWalletV0R0.fromInit('RUB', toBigIntBE(keypair_User2.publicKey)));
        wallet_3 = blockchain.openContract(await LetsWalletV0R0.fromInit('RUB', toBigIntBE(keypair_User3.publicKey)));
        wallet_4 = blockchain.openContract(await LetsWalletV0R0.fromInit('RUB', toBigIntBE(keypair_User4.publicKey)));
        wallet_5 = blockchain.openContract(await LetsWalletV0R0.fromInit('RUB', toBigIntBE(keypair_User5.publicKey)));
        wallet_6 = blockchain.openContract(await LetsWalletV0R0.fromInit('RUB', toBigIntBE(keypair_User6.publicKey)));
        hub = blockchain.openContract(await LetsHubV0R0.fromInit('RUB'));

        deployer = await blockchain.treasury('deployer');
        Sponsor = await blockchain.treasury('Sponsor');
        User1 = await blockchain.treasury('User1');
        User2 = await blockchain.treasury('User2');
        User3 = await blockchain.treasury('User3');
        User4 = await blockchain.treasury('User4');
        User5 = await blockchain.treasury('User5');
        User6 = await blockchain.treasury('User6');

        let deployResult = await hub.send(
            deployer.getSender(),
            {
                value: toNano('150'),
            },
            null,
        );

        deployResult = await wallet_1.send(
            deployer.getSender(),
            {
                value: toNano('10'),
            },
            null,
        );

        deployResult = await wallet_2.send(
            deployer.getSender(),
            {
                value: toNano('10'),
            },
            null,
        );

        deployResult = await wallet_3.send(
            deployer.getSender(),
            {
                value: toNano('10'),
            },
            null,
        );

        deployResult = await wallet_4.send(
            deployer.getSender(),
            {
                value: toNano('10'),
            },
            null,
        );


        deployResult = await wallet_5.send(
            deployer.getSender(),
            {
                value: toNano('10'),
            },
            null,
        );

        deployResult = await wallet_6.send(
            deployer.getSender(),
            {
                value: toNano('10'),
            },
            null,
        );
    });

    it('Test #1', async () => {
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
            $$type: 'CreateTrustlineV0R0',
            signature: header_signature,
            header: header,
            debitor: User2.address,
            tontoTrustline: toNano('5'),
            tontoLink: toNano('0.2'),
        });
        console.log('wallet_1 data = ', await wallet_1.getData());
;

        let link = blockchain.openContract(await LetsLinkV0R0.fromInit('RUB', 0n));
        console.log('linkHub 0n balance = ', await link.getData());

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
        
        /*await wallet_1.sendExternal({
            $$type: 'SetSponsorV0R0',
            signature: header_signature,
            header: header,
            address: Sponsor.address,
            publicKey: toBigIntBE(keypair_Sponsor.publicKey)
        });*/
        data = await wallet_1.getData()
        console.log('wallet_1 data = ', data);
        console.log('wallet_1 balance = ', fromNano(data.balance));


        let  txResult = await wallet_1.send(
            Sponsor.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'WidthrawV0R0',
                value: toNano('5')
            }
        );
        console.log('wallet_1 balance = ', fromNano((await wallet_1.getData()).balance));

        console.log('User2 balance = ', await User2.getBalance());
        data = await wallet_1.getData();
        header = beginCell()
            .storeUint(timeout, 32)
            .storeUint(data.seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
        header_signature = sign(header.hash(), keypair_User1.secretKey); 
        await wallet_1.sendExternal({
            $$type: 'TransferTonV0R0',
            signature: header_signature,
            header: header,
            to: User2.address,
            value: toNano('1'),
            comment: 'HELLO'
        });
        console.log('User2 balance = ', await User2.getBalance());
    });


    it('Test #4', async () => {
        let timeout = Math.floor(Date.now() / 1000) + 10;
        console.log('User2 balance = ', await User2.getBalance());
        let data = await wallet_1.getData();
        let header = beginCell()
            .storeUint(timeout, 32)
            .storeUint(data.seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
        let header_signature = sign(header.hash(), keypair_User1.secretKey); 
        await wallet_1.sendExternal({
            $$type: 'TransferTonV0R0',
            signature: header_signature,
            header: header,
            to: User2.address,
            value: toNano('1'),
            comment: 'HELLO'
        });
        console.log('User2 balance = ', await User2.getBalance());

        data = await wallet_1.getData();
        timeout = Math.floor(Date.now() / 1000) + 20;
        console.log('Wallet_1 Data = ', data);
        header = beginCell()
            .storeUint(timeout, 32)
            .storeUint(data.seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
        header_signature = sign(header.hash(), keypair_User1.secretKey); 
        await wallet_1.sendExternal({
                $$type: 'SetCustomWalletDataV0R0',
                signature: header_signature,
                header: header,
                content: Cell.EMPTY,
                locality: "Yakutsk",
                phone: '+79841091087',
                email: 'AOkoneshnikov@gmail.com',
                longitude: 0n,
                latitude: 0n,
                name: 'Aleksei Okoneshnikov',
                telegramId: 0n,
                telegramRef: '@aokoneshnikov'});

        data = await wallet_1.getData();
        console.log('Wallet_1 Data = ', data);
    });


    it('Test #5', async () => {

        let i = 0;
        while (i < 10) {
            let seed = await getSecureRandomBytes(32);
            keypairs[i] = keyPairFromSeed(seed);
            wallets[i] = blockchain.openContract(await LetsWalletV0R0.fromInit('RUB', toBigIntBE(keypairs[i].publicKey)));
            let deployResult = await wallets[i].send(
                deployer.getSender(),
                {
                    value: toNano('10'),
                },
                null,
            ); 
            i = i + 1;
        }

        i = 0;
        while (i < 6) {
            let header = beginCell()
            .storeUint(Math.floor(Date.now() / 1000) + 10, 32)
            .storeUint((await wallets[i].getData()).seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
            let header_signature = sign(header.hash(), keypairs[i].secretKey); 

            if (i == 5) {
                await wallets[5].sendExternal({
                    $$type: 'CreateTrustlineV0R0',
                    signature: header_signature,
                    header: header,
                    debitor: wallets[0].address,
                    tontoTrustline: toNano('5'),
                    tontoLink: toNano('0.2'),
                });
            } 
            else {
                await wallets[i].sendExternal({
                    $$type: 'CreateTrustlineV0R0',
                    signature: header_signature,
                    header: header,
                    debitor: wallets[i+1].address,
                    tontoTrustline: toNano('5'),
                    tontoLink: toNano('0.2'),
                });
            }
            i = i + 1;
        }

        i = 0;
        while (i < 6) {
            let header = beginCell()
            .storeUint(Math.floor(Date.now() / 1000) + 10, 32)
            .storeUint((await wallets[i].getData()).seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
            let header_signature = sign(header.hash(), keypairs[i].secretKey); 

            if (i == 5) {
                await wallets[5].sendExternal({
                    $$type: 'SetLimitV0R0',
                    signature: header_signature,
                    header: header,
                    debitor: wallets[0].address,
                    limit: 300000n,
                    tontoTrustline: toNano('1'),
                });
            } 
            else {
                await wallets[i].sendExternal({
                    $$type: 'SetLimitV0R0',
                    signature: header_signature,
                    header: header,
                    debitor: wallets[i+1].address,
                    limit: 300000n,
                    tontoTrustline: toNano('1'),
                });
            }
            i = i + 1;
        }

        i = 0;
        while (i < 6) {
            let header = beginCell()
            .storeUint(Math.floor(Date.now() / 1000) + 10, 32)
            .storeUint((await wallets[i].getData()).seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
            let header_signature = sign(header.hash(), keypairs[i].secretKey); 

            if (i == 5) {
                await wallets[5].sendExternal({
                    $$type: 'SetInterestProjectV0R0',
                    signature: header_signature,
                    header: header,
                    debitor: wallets[0].address,
                    interestProject: 1000n,
                    tontoTrustline: toNano('1'),
                });
            } 
            else {
                await wallets[i].sendExternal({
                    $$type: 'SetInterestProjectV0R0',
                    signature: header_signature,
                    header: header,
                    debitor: wallets[i+1].address,
                    interestProject: 1000n,
                    tontoTrustline: toNano('1'),
                });
            }
            i = i + 1;
        }

        i = 0;
        while (i < 6) {
            let header = beginCell()
            .storeUint(Math.floor(Date.now() / 1000) + 10, 32)
            .storeUint((await wallets[i].getData()).seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
            let header_signature = sign(header.hash(), keypairs[i].secretKey); 

            if (i == 0) {
                await wallets[0].sendExternal({
                    $$type: 'ConfirmInterestV0R0',
                    signature: header_signature,
                    header: header,
                    creditor: wallets[5].address,
                    interestProject: 1000n,
                    tontoTrustline: toNano('1'),
                });
            } 
            else {
                await wallets[i].sendExternal({
                    $$type: 'ConfirmInterestV0R0',
                    signature: header_signature,
                    header: header,
                    creditor: wallets[i-1].address,
                    interestProject: 1000n,
                    tontoTrustline: toNano('1'),
                });
            }
            i = i + 1;
        }

        /*i = 0;
        while (i < 6) {
            let link = blockchain.openContract(await LetsLinkV0R0.fromInit('RUB', BigInt(i)));
            console.log('link[',i,'] balance = ', await link.getData());
            if (i == 5) {
                let trustline = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[5].address, wallets[0].address));
                console.log('trustline[', i, '] balance = ', await trustline.getData());
            }
            else {
                let trustline = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[i].address, wallets[i+1].address));
                console.log('trustline[', i, '] balance = ', await trustline.getData());
            }
            i = i + 1;        
        }*/


        let pathTransfer = Dictionary.empty(Dictionary.Keys.Int(8), Dictionary.Values.Address());

        pathTransfer.set(0, wallets[0].address);
        pathTransfer.set(1, wallets[5].address);
        pathTransfer.set(2, wallets[4].address);
        pathTransfer.set(3, wallets[3].address);

        let header = beginCell()
            .storeUint(Math.floor(Date.now() / 1000) + 10, 32)
            .storeUint((await wallets[0].getData()).seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
        let header_signature = sign(header.hash(), keypairs[0].secretKey); 

        await wallets[0].sendExternal({
            $$type: 'TransferMoneyV0R0',
            signature: header_signature,
            header: header,
            amount: 100n,
            onCredit: true,
            currentStep: 0n,
            countStep: 0n,
            bounced: false,
            path: pathTransfer,
            tontoTrustline: toNano('1')
        });

        let trustline1 = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[5].address, wallets[0].address));
        let trustline2 = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[4].address, wallets[5].address));
        let trustline3 = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[3].address, wallets[4].address));
        console.log('trustline[WA] balance = ', await trustline1.getData());
        console.log('trustline[EW] balance = ', await trustline2.getData());
        console.log('trustline[DE] balance = ', await trustline3.getData());


        pathTransfer.set(0, wallets[3].address);
        pathTransfer.set(1, wallets[4].address);
        pathTransfer.set(2, wallets[5].address);
        pathTransfer.set(3, wallets[0].address);

        header = beginCell()
            .storeUint(Math.floor(Date.now() / 1000) + 10, 32)
            .storeUint((await wallets[3].getData()).seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
        header_signature = sign(header.hash(), keypairs[3].secretKey); 
        await wallets[3].sendExternal({
            $$type: 'TransferMoneyV0R0',
            signature: header_signature,
            header: header,
            amount: 50n,
            onCredit: false,
            currentStep: 0n,
            countStep: 0n,
            bounced: false,
            path: pathTransfer,
            tontoTrustline: toNano('1')
        });
        
        console.log('trustline[WA] balance = ', await trustline1.getData());
        console.log('trustline[EW] balance = ', await trustline2.getData());
        console.log('trustline[DE] balance = ', await trustline3.getData());


    });



});
