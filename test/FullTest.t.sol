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

interface ICoreV1_FOR_TEST {
    struct Stake {
        uint256 stakedBalance;
        uint256 commitmentEnd;
        uint256 reservedRewards;
        uint256 storedCoreFragments;
        uint256 lastDistributionTime;
        uint256 coreFragmentsAPR;
    }

    function stakes(address _staker) external view returns (Stake memory);
    function fragmentsDistributed(address _staker) external view returns (uint256);

    function stake(uint256 _amount, uint256 _duration) external;
    function distributeCoreFragments(address _destination, uint256 _amount) external;
    function getFragments(address _user) external view returns (uint256);
}

// Contains additional functions that are needed to construct test cases but not in production
interface IPortalsV1_FOR_TEST {
    function claimRewardsHLPandHMX() external;
    function convert(address _token, uint256 _minReceived, uint256 _deadline) external;

    function getUpdateAccount(address _user, uint256 _amount)
        external
        view
        returns (
            address user,
            uint256 lastUpdateTime,
            uint256 lastMaxLockDuration,
            uint256 stakedBalance,
            uint256 maxStakeDebt,
            uint256 portalEnergy,
            uint256 availableToWithdraw
        );
}

// Contains additional functions that are needed to construct test cases but not in production
interface IPortalsV2_FOR_TEST {
    function getUpdateAccount(address _user, uint256 _amount, bool _isPositiveAmount)
        external
        view
        returns (
            uint256 lastUpdateTime,
            uint256 lastMaxLockDuration,
            uint256 stakedBalance,
            uint256 maxStakeDebt,
            uint256 portalEnergy,
            uint256 availableToWithdraw,
            uint256 portalEnergyTokensRequired
        );

    function buyPortalEnergy(address _recipient, uint256 _amountInputPSM, uint256 _minReceived, uint256 _deadline)
        external;

    function mintPortalEnergyToken(address _recipient, uint256 _amount) external;
}

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

error NotManager();
error IsRevoked();
error NullAddress();
error QuestsDisabled();
error MaximumScoreReached();

error InvalidQuest();
error QuestComplete();
error NotPasselExplorer();
error QuestCondition();

contract FullTest is Test {
    address private constant PSM_ADDRESS = 0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5;
    address private constant PE_ETH_ADDRESS = 0xA9Ee3b373843008a56178Fc3047fbD1C145c5a12;

    // prank addresses
    address payable Alice = payable(0x46340b20830761efd32832A74d7169B29FEB9758);
    address payable Bob = payable(0x490b1E689Ca23be864e55B46bf038e007b528208);
    address payable Karen = payable(0x3A30aaf1189E830b02416fb8C513373C659ed748);

    // Token Instances
    IERC20 psm = IERC20(PSM_ADDRESS);
    IERC20 peETH = IERC20(PE_ETH_ADDRESS);

    // Passel NFT Collection
    PasselNFT public passelNFT;

    // PasselMarket contract
    PasselMarket public passelMarket;

    // PasselExplorer
    PasselExplorer public passelExplorer;

    // PasselQuests
    PasselQuests public passelQuests;

    // Possum Protocols
    ICoreV1_FOR_TEST public constant CORE_V1 = ICoreV1_FOR_TEST(0xb12192f4E3AcCb5D33589Ed683701F69a272EA26);
    IPortalsV1_FOR_TEST public constant PORTALS_V1 = IPortalsV1_FOR_TEST(0x24b7d3034C711497c81ed5f70BEE2280907Ea1Fa);
    IPortalsV2_FOR_TEST public constant PORTALS_V2 = IPortalsV2_FOR_TEST(0xe771545aaDF6feC3815B982fe2294F7230C9c55b);

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
        vm.createSelectFork({urlOrAlias: "alchemy_arbitrum_api", blockNumber: 260000000});

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
        vm.prank(nftMinter);
        passelNFT.mint(Alice, "g34zwg435u65");
    }

    function helper_mintNFT_toBob() public {
        vm.prank(nftMinter);
        passelNFT.mint(Bob, "g34zwg435u65");
    }

    function helper_revokeManager() public {
        vm.prank(psmSender);
        passelExplorer.revokeManager();
    }

    function helper_setQuests() public {
        vm.prank(psmSender);
        passelExplorer.setPasselQuests(address(passelQuests));
    }

    function helper_stake_2M_PSM_inCore() public {
        psm.approve(address(CORE_V1), 1e55);
        CORE_V1.stake(2000000 * 1e18, 31536000); // stake 2M for 1 year
    }

    function helper_stake_200k_PSM_inCore() public {
        psm.approve(address(CORE_V1), 1e55);
        CORE_V1.stake(200000 * 1e18, 31536000); // stake 200k for 1 year
    }

    function helper_pass1Year() public {
        vm.warp(block.timestamp + 31536000);
    }

    function helper_verifyInitialState(uint256 _questID) public view {
        bool isCompleted_NFT0 = passelQuests.isQuestCompleted(0, _questID);
        bool isCompleted_NFT2 = passelQuests.isQuestCompleted(2, _questID);
        assertFalse(isCompleted_NFT0);
        assertFalse(isCompleted_NFT2);

        uint256 explorationScore_NFT0 = passelExplorer.getExplorationScore(0);
        uint256 explorationScore_NFT2 = passelExplorer.getExplorationScore(2);
        assertEq(explorationScore_NFT0, 0);
        assertEq(explorationScore_NFT2, 0);
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
    function testSuccess_revokeManager() public {
        assertEq(passelExplorer.manager(), psmSender);

        vm.prank(psmSender);
        passelExplorer.revokeManager();

        assertEq(passelExplorer.manager(), address(0));
    }

    function testRevert_revokeManager() public {
        assertEq(passelExplorer.manager(), psmSender);

        // Scenario 1: Caller is not Manager
        vm.startPrank(Alice);
        vm.expectRevert(NotManager.selector);
        passelExplorer.revokeManager();
        vm.stopPrank();

        // Scenario 2: Manager was revoked
        helper_revokeManager();

        vm.startPrank(psmSender);
        vm.expectRevert(NotManager.selector);
        passelExplorer.revokeManager();
    }

    function testSuccess_setPsmReceiver() public {
        assertEq(passelExplorer.psmReceiver(), psmSender);

        vm.prank(psmSender);
        passelExplorer.setPsmReceiver(Alice);

        assertEq(passelExplorer.psmReceiver(), Alice);

        vm.prank(psmSender);
        passelExplorer.setPsmReceiver(Bob);

        assertEq(passelExplorer.psmReceiver(), Bob);
    }

    function testRevert_setPsmReceiver() public {
        assertEq(passelExplorer.psmReceiver(), psmSender);

        // Scenario 1: Caller is not authorized
        vm.startPrank(Alice);
        vm.expectRevert(NotManager.selector);
        passelExplorer.setPsmReceiver(Alice);
        vm.stopPrank();

        // Scenario 2: new receiver is address(0)
        vm.startPrank(psmSender);
        vm.expectRevert(NullAddress.selector);
        passelExplorer.setPsmReceiver(address(0));
        vm.stopPrank();

        // Scenario 3: Manager was revoked already (not authorized)
        helper_revokeManager();
        vm.startPrank(psmSender);
        vm.expectRevert(NotManager.selector);
        passelExplorer.setPsmReceiver(Bob);
        vm.stopPrank();

        assertEq(passelExplorer.psmReceiver(), psmSender);
    }

    function testSuccess_setPasselQuests() public {
        assertEq(address(passelExplorer.passelQuests()), address(0));

        vm.prank(psmSender);
        passelExplorer.setPasselQuests(Alice);

        assertEq(address(passelExplorer.passelQuests()), Alice);

        vm.prank(psmSender);
        passelExplorer.setPasselQuests(address(0));

        assertEq(address(passelExplorer.passelQuests()), address(0));
    }

    function testRevert_setPasselQuests() public {
        assertEq(address(passelExplorer.passelQuests()), address(0));

        // Scenario 1: Caller is not authorized
        vm.startPrank(Alice);
        vm.expectRevert(NotManager.selector);
        passelExplorer.setPasselQuests(Alice);
        vm.stopPrank();

        // Scenario 2: Manager was revoked
        helper_revokeManager();

        vm.startPrank(psmSender);
        vm.expectRevert(NotManager.selector);
        passelExplorer.setPasselQuests(Alice);
        vm.stopPrank();

        assertEq(address(passelExplorer.passelQuests()), address(0));
    }

    function testSuccess_buyExperience() public {
        helper_mintNFT_toAlice();

        uint256 receiverBalance = psm.balanceOf(psmSender);

        assertEq(passelExplorer.getExperience(0), 0);

        uint256 expPurchased = 1e6;

        // Scenario 1: Alice purchases EXP for her own NFT
        vm.startPrank(Alice);
        psm.approve(address(passelExplorer), 1e55);
        passelExplorer.buyExperience(0, expPurchased);
        vm.stopPrank();

        // verify state changes of Scenario 1
        assertEq(passelExplorer.getExperience(0), expPurchased);
        assertEq(psm.balanceOf(psmSender), receiverBalance + expPurchased);

        // Scenario 2: Bob purchases EXP for Alice's NFT
        vm.startPrank(Bob);
        psm.approve(address(passelExplorer), 1e55);
        passelExplorer.buyExperience(0, expPurchased);
        vm.stopPrank();

        // verify state changes of Scenario 2
        assertEq(passelExplorer.getExperience(0), expPurchased * 2);
        assertEq(psm.balanceOf(psmSender), receiverBalance + (expPurchased * 2));
    }

    function testRevert_buyExperience() public {
        helper_mintNFT_toAlice();
        helper_mintNFT_toAlice();

        assertEq(passelExplorer.getExperience(0), 0);
        assertEq(passelExplorer.getExperience(1), 0);
        assertEq(passelExplorer.getExperience(2), 0);

        uint256 expPurchased = 1e6;

        // Scenario 1: Alice purchases EXP for a non-existing NFT
        vm.startPrank(Alice);
        vm.expectRevert("ERC721: invalid token ID");
        passelExplorer.buyExperience(2, expPurchased);
        vm.stopPrank();

        assertEq(passelExplorer.getExperience(0), 0);
        assertEq(passelExplorer.getExperience(1), 0);
        assertEq(passelExplorer.getExperience(2), 0);
    }

    function testSuccess_doQuest_1() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2
        helper_setQuests();

        uint256 questID = 1;

        // Verify initial state
        helper_verifyInitialState(questID);

        // Scenario 1: Alice has > 1M PSM balance (Score 2)
        vm.startPrank(Alice);
        passelExplorer.doQuest(0, questID);
        vm.stopPrank();

        // verify state changes of Scenario 1
        uint256 explorationScore_NFT0 = passelExplorer.getExplorationScore(0);
        bool isCompleted_NFT0 = passelQuests.isQuestCompleted(0, questID);

        assertEq(explorationScore_NFT0, 2);
        assertTrue(isCompleted_NFT0);

        //Scenario 2: Bob has 200k PSM (Score 1)
        uint256 amountRemain = 200000 * 1e18; // 200k PSM

        vm.startPrank(Bob);
        psm.transfer(psmSender, psmStartAmount - amountRemain); // reduce balance to 200k PSM
        passelExplorer.doQuest(2, questID);
        vm.stopPrank();

        // verify state changes of Scenario 2
        uint256 explorationScore_NFT2 = passelExplorer.getExplorationScore(2);
        bool isCompleted_NFT2 = passelQuests.isQuestCompleted(2, questID);

        assertEq(explorationScore_NFT2, 1);
        assertTrue(isCompleted_NFT2);
    }

    function testSuccess_doQuest_2() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2
        helper_setQuests();

        uint256 questID = 2;

        // Verify initial state
        helper_verifyInitialState(questID);

        // Scenario 1: Alice stakes 2M PSM in Core (Score 2)
        vm.startPrank(Alice);
        helper_stake_2M_PSM_inCore();
        passelExplorer.doQuest(0, questID);
        vm.stopPrank();

        // verify state changes of Scenario 1
        uint256 explorationScore_NFT0 = passelExplorer.getExplorationScore(0);
        bool isCompleted_NFT0 = passelQuests.isQuestCompleted(0, questID);

        assertEq(explorationScore_NFT0, 2);
        assertTrue(isCompleted_NFT0);

        //Scenario 2: Bob stakes 200k PSM in Core (Score 1)
        vm.startPrank(Bob);
        helper_stake_200k_PSM_inCore();
        passelExplorer.doQuest(2, questID);
        vm.stopPrank();

        // verify state changes of Scenario 2
        uint256 explorationScore_NFT2 = passelExplorer.getExplorationScore(2);
        bool isCompleted_NFT2 = passelQuests.isQuestCompleted(2, questID);

        assertEq(explorationScore_NFT2, 1);
        assertTrue(isCompleted_NFT2);
    }

    function testSuccess_doQuest_3() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2
        helper_setQuests();

        uint256 questID = 3;

        // Verify initial state
        helper_verifyInitialState(questID);

        // Scenario 1: Alice stakes 2M PSM in Core (Score 2), pass 1 year, distribute CF
        uint256 distributedCF = CORE_V1.fragmentsDistributed(Alice);
        assertEq(distributedCF, 0);

        vm.startPrank(Alice);
        helper_stake_2M_PSM_inCore();
        helper_pass1Year();

        uint256 aliceFragments = CORE_V1.getFragments(Alice);
        CORE_V1.distributeCoreFragments(psmSender, aliceFragments);

        passelExplorer.doQuest(0, questID);
        vm.stopPrank();

        // verify state changes of Scenario 1
        uint256 explorationScore_NFT0 = passelExplorer.getExplorationScore(0);
        bool isCompleted_NFT0 = passelQuests.isQuestCompleted(0, questID);
        distributedCF = CORE_V1.fragmentsDistributed(Alice);

        assertEq(explorationScore_NFT0, 2);
        assertTrue(isCompleted_NFT0);
        assertTrue(distributedCF >= 1000000 * 1e18);

        // Scenario 2: Bob stakes 200k PSM in Core (Score 1)
        vm.startPrank(Bob);
        helper_stake_200k_PSM_inCore();
        helper_pass1Year();

        uint256 bobFragments = CORE_V1.getFragments(Bob);
        CORE_V1.distributeCoreFragments(psmSender, bobFragments);

        passelExplorer.doQuest(2, questID);
        vm.stopPrank();

        // verify state changes of Scenario 2
        uint256 explorationScore_NFT2 = passelExplorer.getExplorationScore(2);
        bool isCompleted_NFT2 = passelQuests.isQuestCompleted(2, questID);
        distributedCF = CORE_V1.fragmentsDistributed(Bob);

        assertEq(explorationScore_NFT2, 1);
        assertTrue(isCompleted_NFT2);
        assertTrue(distributedCF >= 100000 * 1e18);
    }

    function testSuccess_doQuest_4() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2
        helper_setQuests();

        uint256 questID = 4;

        // Verify initial state
        helper_verifyInitialState(questID);

        // Scenario 1: Alice buys Portal Energy in the ETH Portal using 7M PSM (Score 2)
        uint256 portalEnergyAlice;
        uint256 amountSpendForAlice = 7000000 * 1e18; // 7M PSM
        uint256 minReceivedAlice = 10 * 1e18; // minimum PE purchased

        vm.startPrank(Alice);
        psm.approve(address(PORTALS_V2), 1e55); // Approve the ETH Portal to spend PSM
        PORTALS_V2.buyPortalEnergy(Alice, amountSpendForAlice, minReceivedAlice, block.timestamp); // Spend 7M PSM to acquire PE
        passelExplorer.doQuest(0, questID);
        vm.stopPrank();

        // verify state changes of Scenario 1
        uint256 explorationScore_NFT0 = passelExplorer.getExplorationScore(0);
        bool isCompleted_NFT0 = passelQuests.isQuestCompleted(0, questID);
        (,,,, portalEnergyAlice,,) = PORTALS_V2.getUpdateAccount(Alice, 0, true);

        assertEq(explorationScore_NFT0, 2);
        assertTrue(isCompleted_NFT0);
        assertTrue(portalEnergyAlice >= 10 * 1e18);

        // Scenario 2: Alice buys Portal Energy for Bob in the ETH Portal using 3M PSM. Bob Executes the Quest (Score 1)
        uint256 portalEnergyBob;
        uint256 amountSpendForBob = 3000000 * 1e18; // 3M PSM
        uint256 minReceivedBob = 1 * 1e18; // minimum PE purchased

        vm.prank(Alice);
        PORTALS_V2.buyPortalEnergy(Bob, amountSpendForBob, minReceivedBob, block.timestamp); // Spend 3M PSM to acquire PE for Bob

        vm.prank(Bob);
        passelExplorer.doQuest(2, questID);

        // verify state changes of Scenario 2
        uint256 explorationScore_NFT2 = passelExplorer.getExplorationScore(2);
        bool isCompleted_NFT2 = passelQuests.isQuestCompleted(2, questID);
        (,,,, portalEnergyBob,,) = PORTALS_V2.getUpdateAccount(Bob, 0, true);

        assertEq(explorationScore_NFT2, 1);
        assertTrue(isCompleted_NFT2);
        assertTrue(portalEnergyBob >= 1 * 1e18);
    }

    function testSuccess_doQuest_5() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2
        helper_setQuests();

        uint256 questID = 5;

        // Verify initial state
        helper_verifyInitialState(questID);

        // Scenario 1: Alice buys PE-ETH with PSM and mints 10 of them as PE tokens (Score 2)
        uint256 amountSpendForAlice = 7000000 * 1e18; // 7M PSM
        uint256 minReceivedAlice = 10 * 1e18; // minimum PE purchased

        vm.startPrank(Alice);

        psm.approve(address(PORTALS_V2), 1e55); // Approve the ETH Portal to spend PSM
        PORTALS_V2.buyPortalEnergy(Alice, amountSpendForAlice, minReceivedAlice, block.timestamp); // Spend 7M PSM to acquire PE
        PORTALS_V2.mintPortalEnergyToken(Alice, minReceivedAlice);

        passelExplorer.doQuest(0, questID);
        vm.stopPrank();

        // verify state changes of Scenario 1
        uint256 explorationScore_NFT0 = passelExplorer.getExplorationScore(0);
        bool isCompleted_NFT0 = passelQuests.isQuestCompleted(0, questID);
        uint256 peTokenBalanceAlice = peETH.balanceOf(Alice);

        assertEq(explorationScore_NFT0, 2);
        assertTrue(isCompleted_NFT0);
        assertEq(peTokenBalanceAlice, 10 * 1e18); // 10 PE tokens

        // Scenario 2: Alice buys Portal Energy for Bob in the ETH Portal using 3M PSM. Bob mints them as tokens and completes the Quest (Score 1)
        uint256 amountSpendForBob = 3000000 * 1e18; // 3M PSM
        uint256 minReceivedBob = 1 * 1e18; // minimum PE purchased

        vm.prank(Alice);
        PORTALS_V2.buyPortalEnergy(Bob, amountSpendForBob, minReceivedBob, block.timestamp); // Spend 3M PSM to acquire PE for Bob

        vm.startPrank(Bob);
        PORTALS_V2.mintPortalEnergyToken(Bob, minReceivedBob);
        passelExplorer.doQuest(2, questID);
        vm.stopPrank();

        // verify state changes of Scenario 2
        uint256 explorationScore_NFT2 = passelExplorer.getExplorationScore(2);
        bool isCompleted_NFT2 = passelQuests.isQuestCompleted(2, questID);
        uint256 peTokenBalanceBob = peETH.balanceOf(Bob);

        assertEq(explorationScore_NFT2, 1);
        assertTrue(isCompleted_NFT2);
        assertEq(peTokenBalanceBob, 1 * 1e18); // 1 PE token
    }

    function testSuccess_doQuest_6() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2
        helper_setQuests();

        uint256 questID = 6;

        // Verify initial state
        helper_verifyInitialState(questID);

        // Scenario 1: Alice executes convert via the quest function
        uint256 amountForConvert = 100000 * 1e18; // 100k PSM

        vm.startPrank(Alice);
        psm.approve(address(passelQuests), 1e55); // Approve the HLP Portal to spend PSM
        passelExplorer.doQuest(0, questID);
        vm.stopPrank();

        // verify state changes of Scenario 1
        uint256 explorationScore_NFT0 = passelExplorer.getExplorationScore(0);
        bool isCompleted_NFT0 = passelQuests.isQuestCompleted(0, questID);
        uint256 psmBalanceAlice = psm.balanceOf(Alice);

        assertEq(explorationScore_NFT0, 1);
        assertTrue(isCompleted_NFT0);
        assertEq(psmBalanceAlice, psmStartAmount - amountForConvert); // 100k PSM is deducted / sent to Portal
    }

    function testRevert_doQuest() public {
        helper_mintNFT_toAlice(); // ID 0
        helper_mintNFT_toAlice(); // ID 1
        helper_mintNFT_toBob(); // ID 2

        // Scenario 1: Alice tries to do a quest while quest contract is not set
        vm.startPrank(Alice);
        vm.expectRevert(QuestsDisabled.selector);
        passelExplorer.doQuest(0, 1);
        vm.stopPrank();

        // set the quest contract
        helper_setQuests();

        // Scenario 2: Alice tries to do quest for non-existing NFT
        vm.startPrank(Alice);
        vm.expectRevert("ERC721: invalid token ID");
        passelExplorer.doQuest(3, 1);
        vm.stopPrank();

        // Scenario 3: Alice tries to do a quest that doesn't exist in the quest contract
        vm.startPrank(Alice);
        vm.expectRevert(InvalidQuest.selector);
        passelExplorer.doQuest(0, 8);
        vm.stopPrank();

        // Scenario 4: Bob does not meet the quest condition (PSM balance)
        vm.startPrank(Bob);
        psm.transfer(psmSender, psmStartAmount); // reduce balance to 0 PSM
        vm.expectRevert(QuestCondition.selector);
        passelExplorer.doQuest(2, 1);
        vm.stopPrank();

        // Scenario 5: Alice tries to repeat a non-repeatable quest (1)
        vm.startPrank(Alice);
        passelExplorer.doQuest(0, 1);
        vm.expectRevert(QuestComplete.selector);
        passelExplorer.doQuest(0, 1);
        vm.stopPrank();

        // Scenario 6: Alice reaches the maximum Explorer Score and tries to get more Points
        vm.startPrank(Alice);
        // Alice got the first 2 Scores from having a PSM balance in Scenario 5
        psm.approve(address(passelQuests), 1e55); // approve PSM to be transferred by the passelQuest contract
        passelExplorer.doQuest(0, 7);
        passelExplorer.doQuest(0, 7);
        passelExplorer.doQuest(0, 7);
        passelExplorer.doQuest(0, 7);
        passelExplorer.doQuest(0, 7);
        passelExplorer.doQuest(0, 7);
        passelExplorer.doQuest(0, 7);
        passelExplorer.doQuest(0, 7); // get the remaining 8 Scores from spending 4M PSM
        vm.expectRevert(MaximumScoreReached.selector);
        passelExplorer.doQuest(0, 7);
        vm.stopPrank();

        // Scenario 7: Bob runs out of PSM for the repeatable quest after successful executions
        vm.prank(psmSender);
        psm.transfer(Bob, psmSendAmount); // Increase Bob's balance to 1M

        vm.startPrank(Bob);
        psm.approve(address(passelQuests), 1e55); // approve PSM to be spent by the quest contract
        passelExplorer.doQuest(2, 7);
        passelExplorer.doQuest(2, 7);
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        passelExplorer.doQuest(2, 7);
        vm.stopPrank();
    }

    function testRevert_quest() public {
        helper_mintNFT_toAlice();

        uint256 questID = 1;
        uint256 explorationScore_NFT0 = passelExplorer.getExplorationScore(0);
        assertEq(explorationScore_NFT0, 0);

        // Try to call the quest contract directly (not via Explorer)
        vm.startPrank(Alice);
        vm.expectRevert(NotPasselExplorer.selector);
        passelQuests.quest(Alice, 0, questID);
    }
}
