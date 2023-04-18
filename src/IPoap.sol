//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


interface IPoap {

    function safeMint(address to, uint256 _tokenId) external;

    function getContract() external view returns(address);
}