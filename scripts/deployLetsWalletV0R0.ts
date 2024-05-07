import { toNano } from '@ton/core';
import { LetsWalletV0R0 } from '../wrappers/LetsWalletV0R0';
import { createNetworkProvider, NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const letsWalletV1R0 = provider.open(await LetsWalletV0R0.fromInit('RUB', 4986475416839105905744086359049208668692504628780654146611869429749505348094n));

    console.log(`wallet addres ${letsWalletV1R0.address}`);
    
    await letsWalletV1R0.send(
        provider.sender(),
        {
            value: toNano('0.1'),
        },
        {
            $$type: 'Deploy',
            queryId: 0n,
        }
    );

    await provider.waitForDeploy(letsWalletV1R0.address);

    // run methods on `letsWalletV1R0`
    
}
