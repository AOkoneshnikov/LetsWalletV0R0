import { toNano } from '@ton/core';
import { LetsHubV0R0 } from '../build/LetsWalletV0R0/tact_LetsHubV0R0';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
    const letsHubV0R0 = provider.open(await LetsHubV0R0.fromInit('RUB'));

    console.log(`Hub addres ${letsHubV0R0.address}`);
    
    await letsHubV0R0.send(
        provider.sender(),
        {
            value: toNano('0.5'),
        },
        null
    );

    await provider.waitForDeploy(letsHubV0R0.address);

    // run methods on `letsWalletV1R0`
}
