// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {PasselNFT} from "src/PasselNFT.sol";

contract DeployPasselNFT is Script {
    string _name = "The Possum Passel";
    string _symbol = "Possum";
    address nftMinter = 0xbFF0b8CcD7ebA169107bbE72426dB370407C8f2D;

    function setUp() public {}

    function run() public returns (address deployedAddress) {
        vm.startBroadcast();

        // Configure optimizer settings
        vm.store(address(this), bytes32("optimizer"), bytes32("true"));
        vm.store(address(this), bytes32("optimizerRuns"), bytes32(uint256(1800)));

        // deploy the NFT contract
        PasselNFT passelNFT = new PasselNFT(_name, _symbol, nftMinter);
        deployedAddress = address(passelNFT);

        vm.stopBroadcast();
    }
}

// forge script script/DeployPasselNFT.s.sol --rpc-url $ARB_MAINNET_URL --private-key $PRIVATE_KEY --broadcast --verify --verifier etherscan --etherscan-api-key $ARBISCAN_API_KEY --optimize --optimizer-runs 1800
