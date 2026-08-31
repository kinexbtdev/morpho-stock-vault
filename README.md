# morpho-stock-vault — Morpho Blue USDG Loans Against Robinhood Stock Tokens

Foundry (Solidity) helper for **Morpho Blue** on **Robinhood Chain** (chain ID **4663**). It computes **health factor** and **liquidation math** for borrowing **USDG** against Robinhood **Stock Token** collateral (for example NVDA, AAPL, SPY).

## What this repo does

Robinhood Earn is built around Morpho and USDG. This repository is the protocol-level view of that stack:

1. `HealthMath.sol` implements Morpho Blue’s collateral value, max borrow, health factor, and liquidation incentive factor (LIF) in WAD math.
2. `StockMarketHelper.sol` is a **read-only** wrapper: it inspects a user’s Morpho position (collateral, borrow shares, oracle price) and previews how much collateral a USDG repay would seize.
3. The helper **reverts** unless `block.chainid == 4663` and the market’s `loanToken` is USDG. It does not custody tokens or originate a new lending market.

Use it to understand USDG borrowing against tokenized equities, test liquidation numbers, or fork-read live Morpho markets on 4663.

Stock Tokens are not DTCC shares. See [Stock Token documentation](https://docs.robinhood.com/chain/stock-tokens/).

## Keywords

Morpho Blue Robinhood Chain, USDG lending, Stock Token collateral, health factor, liquidation incentive, Foundry fork 4663, Robinhood Earn, Paxos USDG.

## Contracts

| Contract | Address | Source |
| --- | --- | --- |
| Morpho Blue | `0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010` | [Morpho addresses](https://docs.morpho.org/developers/contracts/addresses/) |
| Adaptive Curve IRM | `0x2BD3d5965B26B51814AC95127B2b80dD6CcC0fa1` | Morpho registry; live `irm_address` on API markets |
| USDG | `0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168` | [Token contracts](https://docs.robinhood.com/chain/contracts/) |

Do not use Ethereum mainnet Morpho (`0xBBBB…FFCb`) on 4663. Listed Blue markets here lend USDG, typically at 91.5% LLTV. Curated vaults are Morpho Vault V2 (MetaMorpho V1 lists are empty).

```
collateralValue = collateral * oraclePrice / 1e36
maxBorrow       = collateralValue * lltv / 1e18
healthFactor    = maxBorrow / borrowAssets          // WAD; < 1e18 is liquidatable
LIF             = min(1.15e18, 1e18 / (1e18 - 0.3e18 * (1e18 - lltv)))
seized          = repaidUSDG * LIF * 1e36 / oraclePrice
```

## Quick start

```bash
forge install foundry-rs/forge-std --no-commit
forge test -vv
forge test --fork-url $RH_RPC_URL --fork-chain-id 4663
```

Local unit tests cover `HealthMath`. Use a 4663 fork to exercise `inspect`.

## References

- [Robinhood Chain ecosystem (Morpho, USDG)](https://docs.robinhood.com/chain/)
- [Building with Stock Tokens — lending](https://docs.robinhood.com/chain/building-with-stock-tokens/)
- [Morpho Blue markets API](https://api.morpho.org/v1/blue/markets?chain_id=4663)
- [eip155-4663.json](https://github.com/ethereum-lists/chains/blob/master/_data/chains/eip155-4663.json)

## Contact

Telegram: [kinexbtdev](https://t.me/kinexbtdev)
