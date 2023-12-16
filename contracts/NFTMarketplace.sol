// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

//INTERNAL IMPORT FOR NFT OPENZEPPLIN
import "@openzeppelin/contracts/utils/Counters.sol"; //using a counter
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "openzeppelin/contracts/token/ERC721/ERC721.sol";

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage{
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    address payable owner;

    mapping(uint256 => MarketItem) private idMarketItem;

    struct MarkerItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event idMarketItemCreated(
        uint indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor() ERC721("NFT Metaverse Token", "Mohitaksh_NFT"){
        owner == payable(msg.sender) //owner for ERC721 will be the deployer
    }

    function updateListingPrice(uint256 _ListingPrice) public payable{
        
    }
}