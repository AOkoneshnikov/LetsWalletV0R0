import { CompilerConfig } from '@ton/blueprint';

export const compile: CompilerConfig = {
    lang: 'tact',
    target: 'contracts/lets_wallet_v0_r0.tact',
    options: {
       // debug: true,
        "external": true
    }
};
