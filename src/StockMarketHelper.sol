// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {HealthMath} from "./HealthMath.sol";
import {IMorpho, IMorphoOracle, MarketParams, Position, Market, MarketId} from "./interfaces/IMorpho.sol";

/// @title StockMarketHelper
/// @notice Read-only helper: USDG loans against Robinhood Stock Tokens on Morpho Blue.
///         Does not custody funds. Robinhood Earn is Morpho-shaped (USDG vaults);
///         this repo is the "I get the money layer" view of that stack.
contract StockMarketHelper {
    using HealthMath for uint256;

    uint256 public constant CHAIN_ID = 4663;
    address public immutable morpho;
    address public immutable usdg;

    error WrongChain();
    error LoanTokenNotUsdg();

    constructor(address morpho_, address usdg_) {
        if (block.chainid != CHAIN_ID) revert WrongChain();
        morpho = morpho_;
        usdg = usdg_;
    }

    struct AccountHealth {
        bytes32 marketId;
        uint256 collateral;
        uint256 borrowAssets;
        uint256 oraclePrice;
        uint256 lltv;
        uint256 healthFactorWad;
        uint256 maxBorrowAssets;
        bool liquidatable;
        uint256 lifWad;
    }

    function inspect(MarketParams calldata p, address user) external view returns (AccountHealth memory h) {
        if (p.loanToken != usdg) revert LoanTokenNotUsdg();
        bytes32 mid = MarketId.id(p);
        Position memory pos = IMorpho(morpho).position(mid, user);
        Market memory mkt = IMorpho(morpho).market(mid);

        uint256 borrowAssets = 0;
        if (mkt.totalBorrowShares > 0 && pos.borrowShares > 0) {
            borrowAssets = uint256(pos.borrowShares) * uint256(mkt.totalBorrowAssets) / uint256(mkt.totalBorrowShares);
        }

        uint256 price = IMorphoOracle(p.oracle).price();
        h.marketId = mid;
        h.collateral = pos.collateral;
        h.borrowAssets = borrowAssets;
        h.oraclePrice = price;
        h.lltv = p.lltv;
        h.healthFactorWad = HealthMath.healthFactor(pos.collateral, borrowAssets, price, p.lltv);
        h.maxBorrowAssets = HealthMath.maxBorrow(pos.collateral, price, p.lltv);
        h.liquidatable = HealthMath.isLiquidatable(pos.collateral, borrowAssets, price, p.lltv);
        h.lifWad = HealthMath.liquidationIncentiveFactor(p.lltv);
    }

    function previewLiquidation(MarketParams calldata p, uint256 repayUsdg)
        external
        view
        returns (uint256 seizedCollateral, uint256 lifWad)
    {
        if (p.loanToken != usdg) revert LoanTokenNotUsdg();
        uint256 price = IMorphoOracle(p.oracle).price();
        lifWad = HealthMath.liquidationIncentiveFactor(p.lltv);
        seizedCollateral = HealthMath.seizedCollateral(repayUsdg, price, p.lltv);
    }
}
