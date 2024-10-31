// SPDX-License-Identifier: GPL-2.0-only
pragma solidity =0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

// ===================================
//    ERRORS
// ===================================
error NotOwnerOfNFT();
error NotListedForSale();
error CallerIsOwner();
error PriceMismatch();

/// @title Custom NFT Marketplace for the Possum Passel Collection
/// @author Possum Labs
/**
 * @notice This NFT Marketplace allows to trade the Possum Passel Collection for PSM
 * Users can list their NFT for sale, adjust or cancel their listing and buy listed NFTs
 * NFT prices are quoted in PSM, a standard ERC20
 * PSM is the only accepted currency on this marketplace
 */
contract PasselMarket is ERC721Holder {
    constructor(address _passelNFT) {
        PASSEL_NFT = IERC721(_passelNFT);
    }

    // ===================================
    //    VARIABLES
    // ===================================
    IERC20 private constant PSM = IERC20(0x17A8541B82BF67e10B0874284b4Ae66858cb1fd5); // PSM on Arbitrum

    IERC721 private immutable PASSEL_NFT;

    mapping(uint256 passelID => bool isListed) public isListedForSale;
    mapping(uint256 passelID => uint256 price) public listingPrices;
    mapping(uint256 passelID => address owner) public ownedBy;

    // ===================================
    //    EVENTS
    // ===================================
    event PasselListingUpdated(address indexed owner, uint256 indexed tokenID, uint256 price, bool isListed);
    event PasselPurchased(address indexed newOwner, uint256 tokenID, uint256 price);

    // ===================================
    //    FUNCTIONS
    // ===================================
    /// @notice Create, update or cancel the sale listing of a specific Passel NFT ID
    /// @dev Use the NFT ID for listing ID
    /// @dev The price is defined in PSM tokens
    /// @dev To deposit an NFT to the marketplace set _getListed to true
    /// @dev To cancel a listing & withdraw the NFT back to the owner, set _getListed to false
    function updateListing(uint256 _tokenID, uint256 _price, bool _getListed) external {
        // Checks
        /// @dev Caller must be the current owner of the NFT ID or the same who has listed it for sale
        if (msg.sender != PASSEL_NFT.ownerOf(_tokenID)) {
            if (msg.sender != ownedBy[_tokenID]) {
                revert NotOwnerOfNFT();
            }
        }

        // Effects
        /// @dev Update the NFT listing status & ownership information
        /// @dev if NFT gets delisted, reset other related information to default values
        /// @dev Only update if values change to save gas
        if (_getListed == false) {
            isListedForSale[_tokenID] = false;
            listingPrices[_tokenID] = 0;
            ownedBy[_tokenID] = address(0);
        } else {
            if (_getListed != isListedForSale[_tokenID]) isListedForSale[_tokenID] = _getListed;
            if (_price != listingPrices[_tokenID]) listingPrices[_tokenID] = _price;
            if (msg.sender != ownedBy[_tokenID]) ownedBy[_tokenID] = msg.sender;
        }

        // Interactions
        /// @dev Transfer the NFT from the marketplace back to the original owner if delisted
        if (_getListed == false) PASSEL_NFT.safeTransferFrom(address(this), msg.sender, _tokenID);

        /// @dev Transfer the NFT to the marketplace if it gets listed the first time
        /// @dev Following updates of the listing do not move the NFT because the owner is the marketplace
        if (_getListed == true && msg.sender == PASSEL_NFT.ownerOf(_tokenID)) {
            PASSEL_NFT.safeTransferFrom(msg.sender, address(this), _tokenID);
        }

        ///@dev Emit event that a listing has been updated
        emit PasselListingUpdated(msg.sender, _tokenID, _price, _getListed);
    }

    /// @notice Pay the listing price of a specific Passel NFT ID and receive the NFT
    /// @dev Transfer PSM from the buyer to the seller & the NFT from the marketplace to the buyer
    /// @dev Delete listing information of the purchased NFT
    function buyNFT(uint256 _tokenID, uint256 maxSpend) external {
        // Checks
        /// @dev Ensure that the NFT ID is listed for sale
        if (isListedForSale[_tokenID] == false) revert NotListedForSale();

        /// @dev Prevent caller from buying their own NFT
        if (msg.sender == ownedBy[_tokenID]) revert CallerIsOwner();

        /// @dev Get the amount of PSM to pay & recipient of payment (seller)
        uint256 price = listingPrices[_tokenID];
        address seller = ownedBy[_tokenID];

        /// @dev Check for maxSpend to protect buyer from bait and switch price change and frontrunning (MEV)
        if (price > maxSpend) revert PriceMismatch();

        // Effects
        /// @dev delete the listing information of the NFT ID
        isListedForSale[_tokenID] = false;
        listingPrices[_tokenID] = 0;
        ownedBy[_tokenID] = address(0);

        // Interactions
        /// @dev Transfer the PSM price from the buyer directly to the seller
        PSM.transferFrom(msg.sender, seller, price);

        /// @dev Transfer the NFT from the marketplace to the buyer
        PASSEL_NFT.safeTransferFrom(address(this), msg.sender, _tokenID);

        /// @dev Emit Event that an NFT purchase was executed
        emit PasselPurchased(msg.sender, _tokenID, price);
    }
}
