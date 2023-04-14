//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


interface IPoap {

    function safeMint(address to, uint256 _tokenId, string memory uri) external;

}