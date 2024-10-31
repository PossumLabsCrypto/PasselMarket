// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {PasselNFT} from "src/PasselNFT.sol";
import {PasselMarket} from "src/PasselMarket.sol";
import {PasselExplorer} from "src/PasselExplorer.sol";
import {PasselQuests} from "src/PasselQuests.sol";

// import {DeployPasselMarket} from "script/DeployPasselMarket.s.sol";
// import {DeployPasselNFT} from "script/DeployPasselNFT.s.sol";
// import {MintPasselBatch} from "script/MintPasselBatch.s.sol";

// ============================================
// ==              CUSTOM ERRORS             ==
// ============================================
error NotMinter();
error CollectionIncomplete();
error MintingDisabled();

error NotOwnerOfNFT();
error NotListedForSale();
error CallerIsOwner();
error PriceMismatch();

error NotController();
error IsRevoked();
error NullAddress();

error questComplete();
error NotPasselExplorer();

contract FullTest is Test {
    address private constant PSM_ADDRESS = 0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;

    // prank addresses
    address payable Alice = payable(0x46340b20830761efd32832A74d7169B29FEB9758);
    address payable Bob = payable(0x490b1E689Ca23be864e55B46bf038e007b528208);
    address payable Karen = payable(0x3A30aaf1189E830b02416fb8C513373C659ed748);

    // Token Instances
    IERC20 psm = IERC20(PSM_ADDRESS);

    // Passel NFT Collection
    PasselNFT public passelNFT;

    // PasselMarket contract
    PasselMarket public passelMarket;

    // PasselExplorer
    PasselExplorer public passelExplorer;

    // PasselQuests
    PasselQuests public passelQuests;

    // PSM Treasury
    address psmSender = 0xAb845D09933f52af5642FC87Dd8FBbf553fd7B33;

    /// NFT minter / deployer
    address nftMinter = 0xbFF0b8CcD7ebA169107bbE72426dB370407C8f2D;

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
        passelNFT = new PasselNFT("Possum Passel", "Passel", nftMinter);
        passelMarket = new PasselMarket(address(passelNFT));
        passelExplorer = new PasselExplorer(address(passelNFT), psmSender);
        passelQuests = new PasselQuests(address(passelExplorer));

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
    function helper_Explorer_setQuestsAddress() public {
        vm.prank(psmSender);
        passelExplorer.setPasselQuests(address(passelQuests));
    }

    function helper_mintAll_NFTs() public {
        vm.startPrank(nftMinter);
        uint256 i;
        for (i; i <= 324; i++) {
            passelNFT.mint(psmSender, "g34zwg435u65");
        }
        vm.stopPrank();
    }

    function helper_mintNFT_toAlice() public {
        vm.startPrank(nftMinter);
        passelNFT.mint(Alice, "g34zwg435u65");
        vm.stopPrank();
    }

    function helper_mintNFT_toBob() public {
        vm.startPrank(nftMinter);
        passelNFT.mint(Bob, "g34zwg435u65");
        vm.stopPrank();
    }

    //////////////////////////////////////
    /////// TESTS - Mint NFTs
    //////////////////////////////////////
    function testSuccess_mintNFT() public {
        assertEq(passelNFT.totalSupply(), 0);

        vm.prank(nftMinter);
        passelNFT.mint(psmSender, "g34zwg435u65");

        assertEq(passelNFT.totalSupply(), 1);
        assertEq(passelNFT.ownerOf(0), psmSender);
    }

    // Try to mint NFT without authorization
    function testRevert_mintNFT_1() public {
        vm.startPrank(Alice);

        vm.expectRevert(NotMinter.selector);
        passelNFT.mint(psmSender, "g34zwg435u65");

        vm.stopPrank();

        assertEq(passelNFT.totalSupply(), 0);
        assertFalse(passelNFT.mintingDisabled());
    }

    // Try to mint more NFTs than hard cap
    function testRevert_mintNFT_2() public {
        helper_mintAll_NFTs();

        vm.startPrank(nftMinter);

        vm.expectRevert(MintingDisabled.selector);
        passelNFT.mint(psmSender, "g34zwg435u65");

        vm.stopPrank();

        assertEq(passelNFT.totalSupply(), 325);
        assertTrue(passelNFT.mintingDisabled());
    }

    //////////////////////////////////////
    /////// TESTS - Marketplace
    //////////////////////////////////////
    function testSuccess_updateListing() public {
        helper_mintNFT_toAlice();

        // check for correct initial state
        assertEq(passelNFT.totalSupply(), 1);
        assertEq(passelNFT.ownerOf(0), Alice);

        assertFalse(passelMarket.isListedForSale(0));
        assertEq(passelMarket.listingPrices(0), 0);
        assertEq(passelMarket.ownedBy(0), address(0));

        // Scenario 1: Alice lists her NFT for sale for the first time
        uint256 tokenID = 0;
        uint256 listingPrice = 2345;
        bool getListed = true;

        vm.startPrank(Alice);

        IERC721(address(passelNFT)).approve(address(passelMarket), tokenID);
        passelMarket.updateListing(tokenID, listingPrice, getListed);

        vm.stopPrank();

        // verify state changes of Scenario 1
        assertEq(passelNFT.ownerOf(tokenID), address(passelMarket));
        assertTrue(passelMarket.isListedForSale(tokenID));
        assertEq(passelMarket.listingPrices(tokenID), listingPrice);
        assertEq(passelMarket.ownedBy(tokenID), Alice);

        // Scenario 2: Alice changes the price of her listed NFT
        uint256 listingPrice_NEW = 876543234567;

        vm.startPrank(Alice);

        passelMarket.updateListing(tokenID, listingPrice_NEW, getListed);

        vm.stopPrank();

        // verify state changes of Scenario 2
        assertEq(passelNFT.ownerOf(tokenID), address(passelMarket));
        assertTrue(passelMarket.isListedForSale(tokenID));
        assertEq(passelMarket.listingPrices(tokenID), listingPrice_NEW);
        assertEq(passelMarket.ownedBy(tokenID), Alice);

        // Scenario 3: Alice delists her listed NFT
        bool getListed_NEW = false;

        vm.startPrank(Alice);

        passelMarket.updateListing(tokenID, listingPrice_NEW, getListed_NEW);

        vm.stopPrank();

        // verify state changes of Scenario 3
        assertEq(passelNFT.ownerOf(tokenID), Alice);
        assertFalse(passelMarket.isListedForSale(tokenID));
        assertEq(passelMarket.listingPrices(tokenID), 0);
        assertEq(passelMarket.ownedBy(tokenID), address(0));
    }

    function testRevert_updateListing() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2

        // Scenario 1: Alice owns ID 0 & 1, lists ID 0 for sale, Bob tries to change listing price of Alice's NFT (not owner)
        uint256 tokenID_listed_Alice = 0;
        uint256 listingPrice_Alice = 2345;
        bool getListed_Alice = true;

        vm.startPrank(Alice);

        IERC721(address(passelNFT)).approve(address(passelMarket), tokenID_listed_Alice);
        passelMarket.updateListing(tokenID_listed_Alice, listingPrice_Alice, getListed_Alice);

        vm.stopPrank();

        uint256 listingPrice_manipulatedByBob = 99999999999;

        vm.startPrank(Bob);

        vm.expectRevert(NotOwnerOfNFT.selector);
        passelMarket.updateListing(tokenID_listed_Alice, listingPrice_manipulatedByBob, getListed_Alice);

        vm.stopPrank();

        // Scenario 2: Bob tries to list Alice's other NFT for sale (not owner)
        uint256 tokenID_tryToList_ownedByAlice = 1;
        uint256 listingPrice_Bob = 876543456789;
        bool getListed_Bob = true;

        vm.startPrank(Bob);

        IERC721(address(passelNFT)).setApprovalForAll(address(passelMarket), true);

        vm.expectRevert(NotOwnerOfNFT.selector);
        passelMarket.updateListing(tokenID_tryToList_ownedByAlice, listingPrice_Bob, getListed_Bob);

        vm.stopPrank();
    }

    function testSuccess_buyNFT() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2

        // Scenario 1: Alice lists NFT IDs 0 and 1 for sale, Bob purchases NFT ID 0
        uint256 tokenID_Alice_1 = 0;
        uint256 tokenID_Alice_2 = 1;
        uint256 tokenID_Bob = 2;
        uint256 listingPrice = 2345;
        bool getListed = true;

        vm.startPrank(Alice);

        IERC721(address(passelNFT)).setApprovalForAll(address(passelMarket), true);
        passelMarket.updateListing(tokenID_Alice_1, listingPrice, getListed);
        passelMarket.updateListing(tokenID_Alice_2, listingPrice, getListed);

        vm.stopPrank();

        vm.startPrank(Bob);

        psm.approve(address(passelMarket), 1e55);
        passelMarket.buyNFT(tokenID_Alice_1, 1e24);

        vm.stopPrank();

        // verify state changes of Scenario 1
        assertEq(passelNFT.ownerOf(tokenID_Alice_1), Bob);
        assertEq(passelNFT.ownerOf(tokenID_Alice_2), address(passelMarket));
        assertFalse(passelMarket.isListedForSale(tokenID_Alice_1));
        assertTrue(passelMarket.isListedForSale(tokenID_Alice_2));
        assertEq(passelMarket.listingPrices(tokenID_Alice_1), 0);
        assertEq(passelMarket.listingPrices(tokenID_Alice_2), listingPrice);
        assertEq(passelMarket.ownedBy(tokenID_Alice_1), address(0));
        assertEq(passelMarket.ownedBy(tokenID_Alice_2), Alice);
        assertEq(psm.balanceOf(Alice), psmStartAmount + listingPrice);
        assertEq(psm.balanceOf(Bob), psmStartAmount - listingPrice);
        assertEq(psm.balanceOf(Bob) + psm.balanceOf(Alice), 2 * psmStartAmount);

        // Scenario 2: Bob lists NFT IDs 0 and 2 for sale, Alice purchases both and withdraws listing - all 3 in wallet

        vm.startPrank(Bob);

        IERC721(address(passelNFT)).setApprovalForAll(address(passelMarket), true);
        passelMarket.updateListing(tokenID_Alice_1, listingPrice, getListed);
        passelMarket.updateListing(tokenID_Bob, listingPrice, getListed);

        vm.stopPrank();

        vm.startPrank(Alice);

        psm.approve(address(passelMarket), 1e55);
        passelMarket.buyNFT(tokenID_Alice_1, 1e24);
        passelMarket.buyNFT(tokenID_Bob, 1e24);
        passelMarket.updateListing(tokenID_Alice_2, listingPrice, false);

        vm.stopPrank();

        // verify state changes of Scenario 2
        assertEq(passelNFT.ownerOf(tokenID_Alice_1), Alice);
        assertEq(passelNFT.ownerOf(tokenID_Alice_2), Alice);
        assertEq(passelNFT.ownerOf(tokenID_Bob), Alice);
        assertFalse(passelMarket.isListedForSale(tokenID_Alice_1));
        assertFalse(passelMarket.isListedForSale(tokenID_Alice_2));
        assertFalse(passelMarket.isListedForSale(tokenID_Bob));
        assertEq(passelMarket.listingPrices(tokenID_Alice_1), 0);
        assertEq(passelMarket.listingPrices(tokenID_Alice_2), 0);
        assertEq(passelMarket.listingPrices(tokenID_Bob), 0);
        assertEq(passelMarket.ownedBy(tokenID_Alice_1), address(0));
        assertEq(passelMarket.ownedBy(tokenID_Alice_2), address(0));
        assertEq(passelMarket.ownedBy(tokenID_Bob), address(0));
        assertEq(psm.balanceOf(Alice), psmStartAmount - listingPrice);
        assertEq(psm.balanceOf(Bob), psmStartAmount + listingPrice);
        assertEq(psm.balanceOf(Bob) + psm.balanceOf(Alice), 2 * psmStartAmount);
    }

    function testRevert_buyNFT() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2

        // Scenario 1: Alice lists NFT IDs 0 and 1 for sale, Bob purchases NFT ID 0 then tries to purchase ID 0 again (not listed)
        uint256 tokenID_Alice_1 = 0;
        uint256 tokenID_Alice_2 = 1;
        uint256 tokenID_Bob = 2;
        uint256 listingPrice = 2345;
        bool getListed = true;

        vm.startPrank(Alice);

        IERC721(address(passelNFT)).setApprovalForAll(address(passelMarket), true);
        passelMarket.updateListing(tokenID_Alice_1, listingPrice, getListed);
        passelMarket.updateListing(tokenID_Alice_2, listingPrice, getListed);

        vm.stopPrank();

        vm.startPrank(Bob);

        psm.approve(address(passelMarket), 1e55);
        passelMarket.buyNFT(tokenID_Alice_1, 1e24);

        vm.expectRevert(NotListedForSale.selector);
        passelMarket.buyNFT(tokenID_Alice_1, 1e24);

        vm.stopPrank();

        // Scenario 2: Bob lists his NFT for sale and tries to purchase it (Caller Is Owner)
        vm.startPrank(Bob);

        IERC721(address(passelNFT)).setApprovalForAll(address(passelMarket), true);
        passelMarket.updateListing(tokenID_Bob, listingPrice, getListed);

        vm.expectRevert(CallerIsOwner.selector);
        passelMarket.buyNFT(tokenID_Bob, 1e24);

        vm.stopPrank();

        // Scenario 3: Bob tries to purchase ID 1 but fails because maxSpend is set too low
        vm.startPrank(Bob);

        vm.expectRevert(PriceMismatch.selector);
        passelMarket.buyNFT(tokenID_Alice_2, 1);

        vm.stopPrank();
    }

    //////////////////////////////////////
    /////// TESTS - Explorer & Quests
    //////////////////////////////////////
    function testSuccess_buyExperience() public {}

    function testSuccess_doQuest() public {}

    function testSuccess_setPsmReceiver() public {}

    function testSuccess_setPasselQuests() public {}

    function testSuccess_revokeController() public {}
}
