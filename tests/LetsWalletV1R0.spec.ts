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
import { text } from 'stream/consumers';



describe('LetsWalletV1R0', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let Sponsor: SandboxContract<TreasuryContract>;
    let hub: SandboxContract<LetsHubV0R0>;
    let wallets: SandboxContract<LetsWalletV0R0>[] = [];
    let keypairs: KeyPair[] = [];
    let pathTransfer = Dictionary.empty(Dictionary.Keys.Int(8), Dictionary.Values.Address());
    let trustlines: SandboxContract<LetsTrustlineV0R0>[] = [];
    
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

    let keypair_Sponsor: KeyPair;


    beforeEach(async () => {        
        keypair_Sponsor = await mnemonicToWalletKey(mnemonicSponsor); 

        blockchain = await Blockchain.create();
        hub = blockchain.openContract(await LetsHubV0R0.fromInit('RUB'));

        deployer = await blockchain.treasury('deployer');
        Sponsor = await blockchain.treasury('Sponsor');

        let deployResult = await hub.send(
            deployer.getSender(),
            {
                value: toNano('150'),
            },
            null,
        );

        let i = 0; let limit = 0n;
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
            limit = limit + 100n;

            if (i == 5) {
                await wallets[5].sendExternal({
                    $$type: 'SetLimitV0R0',
                    signature: header_signature,
                    header: header,
                    debitor: wallets[0].address,
                    limit: 3000n,
                    tontoTrustline: toNano('1'),
                });
            } 
            else {
                await wallets[i].sendExternal({
                    $$type: 'SetLimitV0R0',
                    signature: header_signature,
                    header: header,
                    debitor: wallets[i+1].address,
                    limit: 3000n,
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

        trustlines[0] = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[0].address, wallets[1].address));
        trustlines[1] = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[1].address, wallets[2].address));
        trustlines[2] = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[2].address, wallets[3].address));
        trustlines[3] = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[3].address, wallets[4].address));
        trustlines[4] = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[4].address, wallets[5].address));
        trustlines[5] = blockchain.openContract(await LetsTrustlineV0R0.fromInit(wallets[5].address, wallets[0].address));


    });

    
        /*let i = 0;
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



    it('Test #2', async () => {

        
    });

    it('Test #3', async () => {

    });


    it('Test #4', async () => {
    
    });


    it('Test #5', async () => {

        let header = beginCell()
        .storeUint(Math.floor(Date.now() / 1000) + 10, 32)
        .storeUint((await wallets[3].getData()).seqno,32)
        .storeUint(Math.floor(Math.random() * 65536),32)
        .endCell();
        let header_signature = sign(header.hash(), keypairs[3].secretKey);     

        console.log('---  Transfer PHASE #1 ---');

        pathTransfer.set(0, wallets[0].address);
        pathTransfer.set(1, wallets[5].address);
        pathTransfer.set(2, wallets[4].address);
        pathTransfer.set(3, wallets[3].address);
        pathTransfer.set(4, wallets[2].address);
        pathTransfer.set(5, wallets[1].address);
        
        header = beginCell()
            .storeUint(Math.floor(Date.now() / 1000) + 10, 32)
            .storeUint((await wallets[0].getData()).seqno,32)
            .storeUint(Math.floor(Math.random() * 65536),32)
            .endCell();
        header_signature = sign(header.hash(), keypairs[0].secretKey); 
        await wallets[0].sendExternal({
            $$type: 'TransferMoneyV0R0',
            signature: header_signature,
            header: header,
            amount: 200n,
            onCredit: true, // warning: must set for every payment
            currentStep: 0n,
            countStep: 0n,
            path: pathTransfer,
            tontoTrustline: toNano('1')
        });
        
        /*
        console.log('trustline[0] balance = ', await trustlines[0].getData());
        console.log('trustline[1] balance = ', await trustlines[1].getData());
        console.log('trustline[2] balance = ', await trustlines[2].getData());
        console.log('trustline[3] balance = ', await trustlines[3].getData()); 
        console.log('trustline[4] balance = ', await trustlines[4].getData()); 
        console.log('trustline[5] balance = ', await trustlines[5].getData()); */
        console.log('wallet[3] last destination = ', await wallets[0].getLastDestination(), 
                    ': amount = ', await wallets[0].getLastTransferAmount());

        console.log('---  Transfer PHASE #2 ---');
        pathTransfer.clear();
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
            onCredit: false, // warning: must set for every payment
            currentStep: 0n,
            countStep: 0n,
            path: pathTransfer,
            tontoTrustline: toNano('1')
        });
        
        /*console.log('trustline[0] balance = ', await trustlines[0].getData());
        console.log('trustline[1] balance = ', await trustlines[1].getData());
        console.log('trustline[2] balance = ', await trustlines[2].getData());
        console.log('trustline[3] balance = ', await trustlines[3].getData()); 
        console.log('trustline[4] balance = ', await trustlines[4].getData()); 
        console.log('trustline[5] balance = ', await trustlines[5].getData()); */

        console.log('wallet[3] last destination = ', await wallets[3].getLastDestination(), 
                    ': amount = ', await wallets[3].getLastTransferAmount());
    });

});
