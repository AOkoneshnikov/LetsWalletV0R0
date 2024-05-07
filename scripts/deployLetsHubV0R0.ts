import { toNano, Address } from '@ton/core';
import { LetsHubV0R0 } from '../build/LetsWalletV0R0/tact_LetsHubV0R0';
import { NetworkProvider } from '@ton/blueprint';

export async function run(provider: NetworkProvider) {
<<<<<<< HEAD
    const ui = provider.ui();
    provider.
    const addr = Address.parseFriendly('EQCiHSzOpf8_1Li5A5a-1cZoJ8Rq8nkTyhFSZmsVumhOw67X')
    const counter = provider.open(await LetsHubV0R0.fromInit('RUB'))
        
  
    const letsHubV0R0 = provider.open();
=======
    const letsHubV0R0 = provider.open(await LetsHubV0R0.fromInit('TEST'));
>>>>>>> 72c616d8ce0cd1aa953e8e2e8a62a95be32e19fa

    console.log(`Hub addres ${letsHubV0R0.address}`);
    
    await letsHubV0R0.send(
        provider.sender(),
        {
            value: toNano('0.1'),
        },
        null
    );

    await provider.waitForDeploy(letsHubV0R0.address);

    // run methods on `letsWalletV1R0`
}
