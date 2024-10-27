// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {PasselMarket} from "src/PasselMarket.sol";
import {PasselNFT} from "src/PasselNFT.sol";
import {DeployPasselMarket} from "script/DeployPasselMarket.s.sol";
import {DeployPasselNFT} from "script/DeployPasselNFT.s.sol";
import {MintPasselBatch} from "script/MintPasselBatch.s.sol";

// ============================================
// ==              CUSTOM ERRORS             ==
// ============================================
error NullAddress();

contract FullTest is Test {
    address private constant PSM_ADDRESS = 0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;

    // prank addresses
    address payable Alice = payable(0x46340b20830761efd32832A74d7169B29FEB9758);
    address payable Bob = payable(0xDD56CFdDB0002f4d7f8CC0563FD489971899cb79);
    address payable Karen = payable(0x3A30aaf1189E830b02416fb8C513373C659ed748);

    // Token Instances
    IERC20 psm = IERC20(PSM_ADDRESS);

    // PasselMarket contract
    PasselMarket public passelMarket;

    // Passel NFT Collection
    PasselNFT public passelNFT;

    // PSM Treasury
    address psmSender = 0xAb845D09933f52af5642FC87Dd8FBbf553fd7B33;

    // starting token amounts
    uint256 psmStartAmount = 1e25; // 10M PSM
    uint256 psmSendAmount = 1e24; // 1M PSM

    //////////////////////////////////////
    /////// SETUP
    //////////////////////////////////////
    function setUp() public {
        // Create main net fork
        vm.createSelectFork({urlOrAlias: "alchemy_arbitrum_api", blockNumber: 210000000});

        // Create contract instances
        passelNFT = new PasselNFT("Possum Passe", "Passel");
        passelMarket = new PasselMarket(address(passelNFT));

        // Deal tokens to addresses
        vm.prank(psmSender);
        psm.transfer(Alice, psmStartAmount);

        vm.prank(psmSender);
        psm.transfer(Bob, psmStartAmount);

        vm.prank(psmSender);
        psm.transfer(Karen, psmStartAmount);
    }

    //////////////////////////////////////
    /////// HELPER FUNCTIONS
    //////////////////////////////////////
    function helper_do_something() public {}

    //////////////////////////////////////
    /////// TESTS - Mint NFTs
    //////////////////////////////////////
    function testSuccess_mintNFT() public {}

    //////////////////////////////////////
    /////// TESTS - Marketplace
    //////////////////////////////////////
    function testSuccess_listNFT() public {}

    function testSuccess_delistNFT() public {}

    function testSuccess_buyNFT() public {}

    //////////////////////////////////////
    /////// TESTS - Explorer & Quests
    //////////////////////////////////////
    function testSuccess_buyExperience() public {}

    function testSuccess_doQuest() public {}

    function testSuccess_changePsmReceiver() public {}

    function testSuccess_changePasselQuests() public {}

    function testSuccess_revokeController() public {}
}
