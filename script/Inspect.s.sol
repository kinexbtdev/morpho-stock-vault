// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {StockMarketHelper} from "../src/StockMarketHelper.sol";
import {MarketParams} from "../src/interfaces/IMorpho.sol";

/// @dev forge script script/Inspect.s.sol --rpc-url $RH_RPC_URL --broadcast
///      Only deploy if you intend to leave a verified helper on 4663.
contract Inspect is Script {
    address constant MORPHO = 0x9D53d5E3bd5E8d4Cbfa6DB1ca238AEA02E651010;
    address constant USDG = 0x5fc5360D0400a0Fd4f2af552ADD042D716F1d168;

    function run() external {
        require(block.chainid == 4663, "not robinhood");
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);
        StockMarketHelper helper = new StockMarketHelper(MORPHO, USDG);
        vm.stopBroadcast();
        console.log("StockMarketHelper", address(helper));
        MarketParams memory empty;
        empty; // silence unused in dry inspect
    }
}
