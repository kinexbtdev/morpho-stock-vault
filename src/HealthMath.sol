// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title HealthMath
/// @notice Morpho Blue health-factor and liquidation math for USDG loans
///         against Robinhood Stock Tokens. Constants match morpho-blue.
/// @dev    Prices use Morpho oracle scale: 1 collateral unit in loan units,
///         scaled by 1e36 (for 18/18 tokens).
library HealthMath {
    uint256 internal constant WAD = 1e18;
    uint256 internal constant ORACLE_SCALE = 1e36;

    /// @dev morpho-blue/src/libraries/ConstantsLib.sol
    uint256 internal constant MAX_LIQUIDATION_INCENTIVE_FACTOR = 1.15e18;
    uint256 internal constant LIQUIDATION_CURSOR = 0.3e18;

    error InvalidPrice();
    error InvalidLltv();

    function wMulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / WAD;
    }

    function wDivDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * WAD) / b;
    }

    function collateralValue(uint256 collateral, uint256 oraclePrice) internal pure returns (uint256) {
        if (oraclePrice == 0) revert InvalidPrice();
        return (collateral * oraclePrice) / ORACLE_SCALE;
    }

    /// @notice Max USDG that can be borrowed against `collateral` at `lltv`.
    function maxBorrow(uint256 collateral, uint256 oraclePrice, uint256 lltv) internal pure returns (uint256) {
        if (lltv == 0 || lltv >= WAD) revert InvalidLltv();
        return wMulDown(collateralValue(collateral, oraclePrice), lltv);
    }

    /// @notice WAD-scaled health factor. < 1e18 is liquidatable.
    ///         HF = (collateralValue * lltv) / borrowAssets
    function healthFactor(
        uint256 collateral,
        uint256 borrowAssets,
        uint256 oraclePrice,
        uint256 lltv
    ) internal pure returns (uint256) {
        if (borrowAssets == 0) return type(uint256).max;
        return wDivDown(maxBorrow(collateral, oraclePrice, lltv), borrowAssets);
    }

    function isLiquidatable(
        uint256 collateral,
        uint256 borrowAssets,
        uint256 oraclePrice,
        uint256 lltv
    ) internal pure returns (bool) {
        return healthFactor(collateral, borrowAssets, oraclePrice, lltv) < WAD;
    }

    /// @dev LIF = min(1.15e18, WAD / (WAD - 0.3e18 * (WAD - lltv)))
    function liquidationIncentiveFactor(uint256 lltv) internal pure returns (uint256) {
        if (lltv >= WAD) revert InvalidLltv();
        uint256 denom = WAD - wMulDown(LIQUIDATION_CURSOR, WAD - lltv);
        uint256 lif = wDivDown(WAD, denom);
        return lif > MAX_LIQUIDATION_INCENTIVE_FACTOR ? MAX_LIQUIDATION_INCENTIVE_FACTOR : lif;
    }

    /// @notice Collateral seized for a given USDG repay, including LIF bonus.
    function seizedCollateral(
        uint256 repaidAssets,
        uint256 oraclePrice,
        uint256 lltv
    ) internal pure returns (uint256) {
        if (oraclePrice == 0) revert InvalidPrice();
        uint256 lif = liquidationIncentiveFactor(lltv);
        return wMulDown(repaidAssets, lif) * ORACLE_SCALE / oraclePrice;
    }
}
