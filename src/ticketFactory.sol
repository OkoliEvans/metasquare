// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./ticket.sol";
import "./poap.sol";
import "./ITicketing.sol";

contract TicketFactory {

    error Not_Controller();
    error ID_Already_In_Use();
    error Address_Zero_Detected();
    error ID_Not_Found();
    error Invalid_Value();
    error Invalid_Address();
    error Add_Date();
    error Record_Not_Found();
    error Invalid_Event_Uri();

    event ID_Created(address eventAdmin, uint16 eventId, uint256 creationTime);
    event EventCreated(address eventAddress, address creator,uint256 regId);
    event WithdrawEthFactory(address Controller, uint256 amount, address receiver, uint256 time);

    struct EventDetail {
        uint256 id;
        address eventAddress;
        address admin;
        bool ID_Is_Used;
        bool ID_Is_Created;
    }
 
    mapping(address => uint256) eventAddressToID;
    mapping(uint => EventDetail) event_To_ID;

    address[] registeredEvents;

    address public Controller;


    modifier onlyController() {
        require(msg.sender == Controller, "Unauthorized, Not Controller");
        _;
    }

    constructor(address admin) {
        Controller = admin;
    }

    function createID(uint256 _regId, address _eventAdmin) external onlyController {
            EventDetail storage eventDetail = event_To_ID[_regId];
            if(eventDetail.ID_Is_Created == true) revert ID_Already_In_Use();
            if(_eventAdmin == address(0x0)) revert Address_Zero_Detected();
            
            eventDetail.admin = _eventAdmin;
            eventDetail.ID_Is_Created = true;
            eventDetail.id = _regId;
        } 
   
            /// @param  _eventUri: takes the details of the event, the event details/flier should be
        /// uploaded to a file base and the uri passed in the function
        function createEvent(
            uint256 _id,
            uint256 _fee,
            uint256 _no_of_participants,
            uint256 _regStartTime,
            uint256 _regEndTime,
            string memory _eventUri,
            string memory _name,
            string memory _symbol
            ) external returns(address poapAddr, address iticketingAddr){

            bytes32 zeroHash = keccak256(abi.encode(""));
            EventDetail storage eventDetail = event_To_ID[_id];

            require(eventDetail.admin == msg.sender, "Not Admin");
            if(eventDetail.ID_Is_Used == true) revert ID_Already_In_Use();
            if(eventDetail.id == 0) revert ID_Not_Found();
            if(_regStartTime <= 0 || _regEndTime <= _regStartTime) revert("Invalid reg. start or end time");
            if(zeroHash == keccak256(abi.encode(_eventUri))) revert Invalid_Event_Uri();
            if(zeroHash == keccak256(abi.encode(_name))) revert Invalid_Value();
            if(zeroHash == keccak256(abi.encode(_symbol))) revert Invalid_Value();
            
            iTicketing iticketing = new iTicketing(
                _id,
                _fee,
                _no_of_participants,
                _regStartTime,
                _regEndTime,
                _eventUri,
                _name,
                _symbol,
                msg.sender,
                Controller,
                address(this)
            );

            Poap poap = new Poap(
                address(iticketing)
            );
            
            eventDetail.ID_Is_Used = true;
            registeredEvents.push(address(iticketing));
            eventDetail.eventAddress = address(iticketing);
            eventDetail.admin = msg.sender;
            eventDetail.id = _id;
            eventAddressToID[address(iticketing)] = _id;
            

            poapAddr = address(poap);
            iticketingAddr = address(iticketing);
            ITicketing(iticketingAddr).setPoapAddr(poapAddr);

        } 

        function checkEventId(address _eventAddress) external view returns(uint256 id) {
            id = eventAddressToID[_eventAddress];
        }

        function showTotalEventAddresses() external view returns(address[] memory) {
            return registeredEvents;
        }

        function changeController(address _newController) external onlyController {
            if(_newController == address(0)) revert Address_Zero_Detected();
            Controller = _newController;
        }


        function returnTotalNoOfEvents() external view returns(uint256) {
            return registeredEvents.length;
        }

        function withdrawFromChild(uint256 _id) external onlyController {
            EventDetail storage eventDetail = event_To_ID[_id];

            if(eventDetail.id != _id) revert ID_Not_Found();

            address childContract = eventDetail.eventAddress;
            ITicketing(childContract).withdraw();
        }

        function openWithdrawalChild(uint256 _id) external onlyController {
            EventDetail storage eventDetail = event_To_ID[_id];
            if(eventDetail.id != _id) revert ID_Not_Found();
            address childContract = eventDetail.eventAddress;
            ITicketing(childContract).openWithdrawal();

        }

          function pauseWithdrawalChild(uint256 _id) external onlyController {
            EventDetail storage eventDetail = event_To_ID[_id];
            if(eventDetail.id != _id) revert ID_Not_Found();
            address childContract = eventDetail.eventAddress;
            ITicketing(childContract).pauseWithdrawal();

        }


        function withdraw(uint256 _amount, address _to) external onlyController {

            if(_to == address(0x0)) revert Invalid_Address();

            (bool success, ) = payable(_to).call{value: _amount}("");
            require(success, "Ether transfer fail...");

            emit WithdrawEthFactory(msg.sender, _amount, _to, block.timestamp);
        }

        receive() external payable {}
        
}

