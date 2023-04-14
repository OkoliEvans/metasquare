// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


interface ITicketing {
    function register() external payable;

    function startRegistration(uint _startTime, uint _endTime) external;

    function endRegistration() external;

    function claimAttendanceToken() external;

    function setAttenders(address[] calldata _participants) external;

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;

    function setPoapUri_Addr(string memory _uri, address _poap) external;

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function showEventDate() external view returns(string memory);

    function checkClaimed(address _participant) external view returns(bool);

    function showTotalParticipants() external view returns(uint);

    function balanceOf(address _participant, uint256 _tokenId) external view returns (uint256);

    function withdrawEthEventAdmin(uint256 _amount) external;

    function withdraw(uint256 _amount, address _to) external;

    function EthBalanceOfOrganizer() external view returns(uint);
}