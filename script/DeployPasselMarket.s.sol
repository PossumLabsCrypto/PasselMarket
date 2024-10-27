// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {PasselMarket} from "src/PasselMarket.sol";

contract DeployPasselMarket is Script {
    address constant PASSEL_NFT_ADDRESS = address(0); // REPLACE WITH CORRECT NFT ADDRESS BEFORE DEPLOYMENT

    function setUp() public {}

    function run() public returns (address deployedAddress) {
        vm.startBroadcast();

        // Configure optimizer settings
        vm.store(address(this), bytes32("optimizer"), bytes32("true"));
        vm.store(address(this), bytes32("optimizerRuns"), bytes32(uint256(1000)));

        // deploy the NFT contract
        PasselMarket passelMarket = new PasselMarket(PASSEL_NFT_ADDRESS);
        deployedAddress = address(passelMarket);

        vm.stopBroadcast();
    }
}

// forge script script/DeployPasselMarket.s.sol --rpc-url $ARB_MAINNET_URL --private-key $PRIVATE_KEY --broadcast --verify --verifier etherscan --etherscan-api-key $ARBISCAN_API_KEY --optimize --optimizer-runs 1000
