// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "hardhat/console.sol";

contract BullBear is ERC721, ERC721Enumerable, ERC721URIStorage, KeeperCompatibleInterface, Ownable {

    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

		AggregatorV3Interface public pricefeed;

		/**
		 * Use interval and timestamp to set time schedule execution of Upkeep 
		 */
		 uint public interval;
		 uint public lastTimestamp;

		 int256 public currentPrice;

    /**
     * My IPFS node urls to json nft files
		 */

    string[] bullUrisIpfs = [
        // gamer bull
        "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
        // party bull
        "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
        // simple bull
        "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json"
    ];
    string[] bearUrisIpfs = [
        // beanie bear
        "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
        // coolio bear
        "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
        // simple bear
        "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
    ];

    event TokensUpdated(string marketTrend);

		/**
		 * Test data:
		 * `updateInterval` = 10
		 *	this value is in seconds.
		 * `_priceFeed` = 0xD753A1c190091368EaC67bbF3Ee5bAEd265aC420
		 *	this value is the address of the deployed `MockPriceFeed.sol` contract.
		 * An alternative for _priceFeed value can be the address of BTC/USD price feed contract on Rinkeby: https://rinkeby.etherscan.io/address/0xECe365B379E1dD183B20fc5f022230C044d51404
		 * `_priceFeed` = 0xECe365B379E1dD183B20fc5f022230C044d51404
		 */
    constructor(uint updateInterval, address _priceFeed) ERC721("Bull&Bear", "BBTK") {

		/**
		 * Set time schedule for the keeper.
		 * `block.timestamp` returns seconds since unix epoch.
		 */
		interval = updateInterval;
		lastTimeStamp = block.timestamp;

		/**
		 * Takes the `_priceFeed` and pass it to the `AggregatorV3Interface` to get the value to pass in the mock.
		 */
		priceFeed = AggregatorV3Interface(_priceFeed);

		/**
		 * Set the price for the chosen currency pair.
		 */
		currentPrice = getLatestPrice();
}
			
    function safeMint(address to) public {
        // Current counter value will be the minted token's token ID.
        uint256 tokenId = _tokenIdCounter.current();

        // Increment it so next time it's correct when we call .current()
        _tokenIdCounter.increment();

        // Mint the token
        _safeMint(to, tokenId);

        // Default to a bull NFT
        string memory defaultUri = bullUrisIpfs[0];
        _setTokenURI(tokenId, defaultUri);

        console.log(
            "Token", tokenId, 
            " minted successfully and url assigned: ", defaultUri
        );
    }

    /**
     * Check if time from the last upkeep update is enough to need another update.
		 */
    function checkUpKeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory) {
			upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata) external override {
			if ((block.timestamp - lastTimeStamp) > interval){
				lastTimeStamp = block.timestamp;
				int latestPrice = getLatestPrice();

				if (latestPrice == currentPrice) {
					console.log("No price change. Exiting.");
					return;
				}

				/**
				 * Bear or bull time
				 */
				if (latestPrice < currentPrice) {
					console.log("It's bear time!");
					updateAllTokenUris("bear");
				} else {
					console.log("It's bull time!");
				}

				currentPrice = latestPrice;
			} else {
				console.log("Interval not up yet.");
				return;
			}
    }

    /**
     * Helpers functions
     */

    function getLatestPrice() public view returns (int256) {
			(
				/* uint80 roundID */,
				int price,
				/* uint startedAt */,
				/* uint timeStamp */,
				/* uint80 answeredInRound */
			) = pricefeed.latestRoundData();

			return price;
    }

    function updateAllTokenUris(string memory trend) internal {
    	if (compareStrings("bear", trend)) {
    		console.log("Updating token uris with ", trend, "trend");

    		for (uint i = 0; i < _tokenIdCounter.current(); i++) {
    			_setTokenURI(i, bearUrisIpfs[0]);
    		}
    	} else {
				console.log("Updating token uris with ", trend, "trend");

				for (uint i = 0; i < _tokenIdCounter.current(); i++) {
					_setTokenURI(i, bullUrisIpfs[0]);
				}
    	}

    	emit TokensUpdated(trend);
    }

    function setPriceFeed(address newFeed) public onlyOwner {
			priceFeed = AggregatorV3Interface(newFeed);
    }

    function setInterval(uint256 newInterval) public onlyOwner {
			interval = newInterval;
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
			return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

		/**
     * The following functions are overrides required by Solidity.
     */
    function _beforeTokenTransfer(
       	address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
