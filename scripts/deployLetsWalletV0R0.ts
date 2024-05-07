import { toNano } from '@ton/core';
import { LetsWalletV0R0 } from '../wrappers/LetsWalletV0R0';
import { createNetworkProvider, NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const letsWalletV1R0 = provider.open(await LetsWalletV0R0.fromInit('RUB', 28380020640930882816474678098791656181399698421829659677949292647413603472760n));

    console.log(`wallet addres ${letsWalletV1R0.address}`);
    
    await letsWalletV1R0.send(
        provider.sender(),
        {
            value: toNano('0.1'),
        },
        null
    );

    await provider.waitForDeploy(letsWalletV1R0.address);

    // run methods on `letsWalletV1R0`
    
}
