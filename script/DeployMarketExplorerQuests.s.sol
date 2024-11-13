// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {PasselMarket} from "src/PasselMarket.sol";
import {PasselExplorer} from "src/PasselExplorer.sol";
import {PasselQuests} from "src/PasselQuests.sol";

contract DeployMarketExplorerQuests is Script {
    address constant PASSEL_NFT_ADDRESS = 0xa9c2833Bb3658Db2b0d7b3CC41D851b75E3508Cf;
    address constant MANAGER = 0xAb845D09933f52af5642FC87Dd8FBbf553fd7B33;

    function setUp() public {}

    function run() public returns (address passelMarket, address passelExplorer, address passelQuests) {
        vm.startBroadcast();

        // Configure optimizer settings
        vm.store(address(this), bytes32("optimizer"), bytes32("true"));
        vm.store(address(this), bytes32("optimizerRuns"), bytes32(uint256(1800)));

        // deploy the Passel Market contract
        PasselMarket deployPasselMarket = new PasselMarket(PASSEL_NFT_ADDRESS);
        passelMarket = address(deployPasselMarket);

        // deploy the Passel Explorer
        PasselExplorer deployPasselExplorer = new PasselExplorer(PASSEL_NFT_ADDRESS, MANAGER);
        passelExplorer = address(deployPasselExplorer);

        // deploy the Passel Quests
        PasselQuests deployPasselQuests = new PasselQuests(passelExplorer);
        passelQuests = address(deployPasselQuests);

        vm.stopBroadcast();
    }
}

// forge script script/DeployMarketExplorerQuests.s.sol --rpc-url $ARB_MAINNET_URL --private-key $PRIVATE_KEY --broadcast --verify --verifier etherscan --etherscan-api-key $ARBISCAN_API_KEY --optimize --optimizer-runs 1800
