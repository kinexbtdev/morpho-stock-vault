// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {HealthMath} from "../src/HealthMath.sol";

contract HealthMathTest is Test {
    uint256 constant WAD = 1e18;
    uint256 constant LLTV_91_5 = 0.915e18;

    function _price(uint256 usd8) internal pure returns (uint256) {
        // 18/18 tokens: Morpho price = tokenUsd / usdgUsd * 1e36
        // USDG ~ $1, tokenUsd has 8 decimals → price = usd8 * 1e28
        return usd8 * 1e28;
    }

    function test_maxBorrowAt915() public pure {
        uint256 collat = 1e18;
        uint256 price = _price(218_75000000); // $218.75 NVDA
        uint256 maxB = HealthMath.maxBorrow(collat, price, LLTV_91_5);
        // 218.75 * 0.915 ≈ 200.15625 USDG
        assertEq(maxB, 200156250000000000000);
    }

    function test_healthFactorHealthy() public pure {
        uint256 hf = HealthMath.healthFactor(1e18, 100e18, _price(218_75000000), LLTV_91_5);
        assertGt(hf, WAD);
        assertEq(HealthMath.isLiquidatable(1e18, 100e18, _price(218_75000000), LLTV_91_5), false);
    }

    function test_healthFactorLiquidatable() public pure {
        uint256 price = _price(100_00000000);
        uint256 maxB = HealthMath.maxBorrow(1e18, price, LLTV_91_5);
        uint256 hf = HealthMath.healthFactor(1e18, maxB + 1, price, LLTV_91_5);
        assertLt(hf, WAD);
        assertTrue(HealthMath.isLiquidatable(1e18, maxB + 1, price, LLTV_91_5));
    }

    function test_zeroDebtIsInfiniteHealth() public pure {
        assertEq(HealthMath.healthFactor(1e18, 0, _price(1_00000000), LLTV_91_5), type(uint256).max);
    }

    function test_lifAt915MatchesMorphoCurve() public pure {
        uint256 lif = HealthMath.liquidationIncentiveFactor(LLTV_91_5);
        // denom = 1 - 0.3 * 0.085 = 0.9745 → LIF ≈ 1.026167...
        assertGt(lif, 1.02e18);
        assertLt(lif, 1.03e18);
        assertLt(lif, HealthMath.MAX_LIQUIDATION_INCENTIVE_FACTOR);
    }

    function test_lifCapsAt115() public pure {
        uint256 lif = HealthMath.liquidationIncentiveFactor(0.50e18);
        assertEq(lif, HealthMath.MAX_LIQUIDATION_INCENTIVE_FACTOR);
    }

    function test_seizedCollateralIncludesBonus() public pure {
        uint256 price = _price(100_00000000); // 1 token = 100 USDG
        uint256 seized = HealthMath.seizedCollateral(100e18, price, LLTV_91_5);
        assertGt(seized, 1e18); // bonus > 1 token for 100 USDG repaid
    }

    function test_revertBadLltv() public {
        vm.expectRevert(HealthMath.InvalidLltv.selector);
        HealthMath.maxBorrow(1e18, _price(1_00000000), 0);
    }
}
