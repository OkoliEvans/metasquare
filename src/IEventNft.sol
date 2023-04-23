//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


interface IEventNft {

    function safeMint(address to, uint256 _tokenId, string memory _uri) external;

    function getContract() external view returns(address);

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;
}