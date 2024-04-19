import { Blockchain, SandboxContract, TreasuryContract } from '@ton/sandbox';
import { toNano } from '@ton/core';
import { LetsWalletV1R0 } from '../wrappers/LetsWalletV1R0';
import '@ton/test-utils';

describe('LetsWalletV1R0', () => {
    let blockchain: Blockchain;
    let deployer: SandboxContract<TreasuryContract>;
    let letsWalletV1R0: SandboxContract<LetsWalletV1R0>;

    beforeEach(async () => {
        blockchain = await Blockchain.create();

        letsWalletV1R0 = blockchain.openContract(await LetsWalletV1R0.fromInit());

        deployer = await blockchain.treasury('deployer');

        const deployResult = await letsWalletV1R0.send(
            deployer.getSender(),
            {
                value: toNano('0.05'),
            },
            {
                $$type: 'Deploy',
                queryId: 0n,
            }
        );

        expect(deployResult.transactions).toHaveTransaction({
            from: deployer.address,
            to: letsWalletV1R0.address,
            deploy: true,
            success: true,
        });
    });

    it('should deploy', async () => {
        // the check is done inside beforeEach
        // blockchain and letsWalletV1R0 are ready to use
    });
});
