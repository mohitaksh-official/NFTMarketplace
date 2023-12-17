// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol"; //using Counters Utility
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol"; //Using URIStorage utility
import "@openzeppelin/contracts/token/ERC721/ERC721.sol"; //ERC721 for secured NFT mint and transfer

import "hardhat/console.sol";

contract NFTMarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; //counter for tokenIds
    Counters.Counter private _itemsSold; //counter for the number of items in sold state

    uint256 listingPrice = 0.025 ether; //Fixed Listing price for the token
    address payable owner; //owner can reveive ether

    mapping(uint256 => MarketItem) private idToMarketItem; //mapping key:value pair of tokenId:Structure

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "only the owner of this marketplace can perform this function"
        );
        _;
    }

    //using ERC721 from OpenZeppelin secure and tested contract
    constructor() ERC721("Metaverse Tokens", "METT") {
        owner = payable(msg.sender); //owner of Smart Contract is the deployer. Defined through constructor.
    }

    //Update the listing price of the contract
    function updateListingPrice(uint256 _listingPrice)
        public
        payable
        onlyOwner
    {
        require(
            owner == msg.sender,
            "Only marketplace owner can update listing price."
        );
        listingPrice = _listingPrice;
    }

    //Tells about the current fixed listing price for the NFTs
    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    //Mint a token and list it in the marketplace
    function createToken(string memory tokenURI, uint256 price)
        public
        payable
        returns (uint256)
    {
        _tokenIds.increment(); //using increment from the Counter Utility
        uint256 newTokenId = _tokenIds.current(); //declare a new tokenId after incrementing the tokenIds.

        _mint(msg.sender, newTokenId); //ERC721 Mint
        _setTokenURI(newTokenId, tokenURI); //ERC721 set token uri as a key value pair to newTokenId
        createMarketItem(newTokenId, price); //Call function to list the NFT in the marketplace
        return newTokenId; //Return the tokenId at which the NFT was created
    }

     //Function to create market listing
    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be at least 1 wei");
        
        //using Fixed listing price
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        //Create market data using the MarketItem structure
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId); //ERC721 Transfer function
        
        //emit event to tell what item was created
        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    //Resell a token they have purchased
    function resellToken(uint256 tokenId, uint256 price) public payable {
        //check URI token owner from idToMarketItem
        require(
            idToMarketItem[tokenId].owner == msg.sender,
            "Only item owner can perform this operation"
        );
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        idToMarketItem[tokenId].sold = false;
        idToMarketItem[tokenId].price = price;
        idToMarketItem[tokenId].seller = payable(msg.sender);
        idToMarketItem[tokenId].owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), tokenId);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 tokenId) public payable {
        uint256 price = idToMarketItem[tokenId].price;
        require(
            msg.value == price,
            "Please submit the asking price in order to complete the purchase"
        );
        idToMarketItem[tokenId].owner = payable(msg.sender); //transfer ownership
        idToMarketItem[tokenId].sold = true;
        _itemsSold.increment();
        _transfer(address(this), msg.sender, tokenId);
        payable(owner).transfer(listingPrice); //take the amount of ether for transfer
        payable(idToMarketItem[tokenId].seller).transfer(msg.value);
        idToMarketItem[tokenId].seller = payable(address(0));
    }

    /* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current(); //calculate number of unsold items
        uint256 currentIndex = 0;
        //loop to fill array with unsold items
        MarketItem[] memory items = new MarketItem[](unsoldItemCount); //create array with definite size
        for (uint256 i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Returns only items that a user has purchased
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        
        //loop to count number of items owned
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount); //create array with definite size
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    // Returns only items a user has listed
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        //find number of items owned
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        //find the items which are listed
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}
