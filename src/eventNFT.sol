//SPDX-License-Identifier:MIT
pragma solidity 0.8.15;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";


contract EventNFT is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    address Admin;

    constructor( string memory _name, string memory _symbol) ERC721( _name, _symbol) {
        Admin = msg.sender;
    }

    //   function setTokenURI(uint256 tokenId, string memory _tokenURI) external {
    //     require(isContract(msg.sender), " unauthorized call[setTokenURI]");
    //     _setTokenURI(tokenId,_tokenURI);
    // }


    function safeMint(address to, uint256 _tokenId, string memory _uri)
        external

    {
        // require(isContract(msg.sender), " unauthorized call[safeMint]");
        _safeMint(to, _tokenId);
        _setTokenURI(_tokenId, _uri);
    }

    function getContract() external view returns(address) {
        return address(this);
    }


    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        // super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
