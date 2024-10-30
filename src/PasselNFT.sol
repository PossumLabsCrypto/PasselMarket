// SPDX-License-Identifier: GPL-2.0-only
pragma solidity =0.8.19;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

// ===================================
//    ERRORS
// ===================================
error NotMinter();
error CollectionIncomplete();
error MintingDisabled();

/// @title Possum Passel NFT Collection
/// @author Possum Labs
/// @notice The on-chain anniversary collection by Possum Labs
contract PasselNFT is ERC721URIStorage {
    constructor(string memory _name, string memory _symbol, address _minter) ERC721(_name, _symbol) {
        minter = _minter;
    }

    // ===================================
    //    VARIABLES
    // ===================================
    uint256 public totalSupply;
    bool public mintingDisabled;
    uint256 private constant MINTING_CAP = 325;

    address private immutable minter;

    // ===================================
    //    FUNCTIONS
    // ===================================
    ///@notice Enable the minter to mint NFTs up to the minting cap
    function mint(address _recipient, string memory metadataURI) external returns (uint256 nftID) {
        if (msg.sender != minter) revert NotMinter();
        if (mintingDisabled == true) revert MintingDisabled();

        _safeMint(_recipient, totalSupply);
        _setTokenURI(totalSupply, metadataURI);

        nftID = totalSupply; // start first NFT at ID = 0, last NFT ID = 324
        totalSupply++; // value = 325 after the last mint

        if (totalSupply >= MINTING_CAP) {
            mintingDisabled = true;
        }
    }
}
