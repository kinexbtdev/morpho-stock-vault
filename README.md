# morpho-stock-vault

Network: Robinhood Chain (Arbitrum Orbit) · chainId 4663 · gas: ETH  
Stack: Foundry, Morpho Blue, Chainlink  
Disclaimer: Stock Tokens are not equity ownership

View helper for USDG loans against Robinhood Stock Tokens on Morpho Blue. Health factor and liquidation incentive use Morpho Blue’s published formulas. The contracts do not custody funds.

Robinhood lists Morpho as the lending partner and Paxos USDG as the stablecoin ([ecosystem](https://docs.robinhood.com/chain/)). Earn-style USDG vaults sit on top of Morpho; this repository talks to Blue markets directly.

Stock Tokens are not DTCC shares. See [Stock Token documentation](https://docs.robinhood.com/chain/stock-tokens/).

| Contract | Address | Source |
| --- | --- | --- |
| Morpho Blue | `0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010` | [Morpho addresses](https://docs.morpho.org/developers/contracts/addresses/) |
| Adaptive Curve IRM | `0x2BD3d5965B26B51814AC95127B2b80dD6CcC0fa1` | Morpho registry; confirmed on live markets |
| USDG | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` | [Token contracts](https://docs.robinhood.com/chain/contracts/) |

Do not use Ethereum mainnet Morpho (`0xBBBB…FFCb`) on 4663. Listed Blue markets on this chain lend USDG, typically at 91.5% LLTV. Vaults are Morpho Vault V2; MetaMorpho V1 listings are empty.

```
collateralValue = collateral * oraclePrice / 1e36
maxBorrow       = collateralValue * lltv / 1e18
healthFactor    = maxBorrow / borrowAssets          // WAD; < 1e18 is liquidatable
LIF             = min(1.15e18, 1e18 / (1e18 - 0.3e18 * (1e18 - lltv)))
seized          = repaidUSDG * LIF * 1e36 / oraclePrice
```

`StockMarketHelper` reverts unless `block.chainid == 4663` and `loanToken == USDG`.

```bash
forge install foundry-rs/forge-std --no-commit
forge test -vv
forge test --fork-url $RH_RPC_URL --fork-chain-id 4663
```

Local unit tests cover `HealthMath`. Fork tests are required for `inspect`.

These addresses are not in [github.com/robinhood](https://github.com/robinhood). Chain ID 4663 matches [eip155-4663.json](https://github.com/ethereum-lists/chains/blob/master/_data/chains/eip155-4663.json).

## References

- [Building with Stock Tokens](https://docs.robinhood.com/chain/building-with-stock-tokens/)
- [Morpho Blue markets](https://api.morpho.org/v1/blue/markets?chain_id=4663)
