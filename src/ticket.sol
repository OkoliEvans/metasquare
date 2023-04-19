//SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";
import "./IPoap.sol";
import "./poap.sol";


contract iTicketing is ERC721, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Poap poap;

    uint256 public totalEthFromTicket;
    uint256 private OrganizersEthShare;
    uint256 private platformFee;
    uint256  totalExpectedParticipants;
    address public Controller;
    address public eventAdmin;
    address poapAddr;
    address factory;
    string baseUri;
    

    struct EventDetails {
        uint256  eventNftId;
        uint256  poapNftId;
        uint256  totalParticipants;
        uint256 regStartTime;
        uint256 regEndTime;
        uint256  eventFee;
        string eventUri;
    }
    ///////     INITIALIZE STRUCT    ////////
    EventDetails public eventDetails;

    //////////  MAPPINGS    /////////////
    mapping(address => bool) attendedEvent;
    mapping(address => bool) hasRegistered;
    mapping(address => bool) hasClaimed;
    mapping(uint256 => bool) private idExists;
    mapping(uint256 => string) private _tokenURIs;

    ///////     EVENTS      ///////    
    event EventCreated(uint256 NftId, address creator);
    event Registration_Status(string info);
    event Registered(address attendee, uint256 event_id, string tokenURI);
    event Attendance_Token_Claimed(address participant, uint256 AttendanceTokenID);
    event WithdrawEthAdmin(address admin, uint256 amount, uint256 withdrawal_time);
    event WithdrawEthPlatform(address admin, uint256 amount, address receiver, uint256 withdrawal_time);
    

    ///////   ERRORS      ////////
    error Not_Controller();
    error ID_Already_In_Use();
    error Address_Zero_Detected();
    error ID_Not_Found();
    error Invalid_Value();
    error Invalid_Address();
    error Already_Registered();
    error Amount_Is_Less_Than_Event_Fee();
    error Event_Already_Ended();
    error Registration_Not_Started();
    error Add_Date();
    error Record_Not_Found();
    error Insufficient_funds();
    error Max_No_Of_Participants_Reached();
    error Nft_Not_Minted_Yet();
    error Registration_Ended();
    error Invalid_Event_Uri();

    constructor(
        uint256 _id,
        uint256 _fee,
        uint256 _no_of_participants,
        uint256 _regStartTime,
        uint256 _regEndTime,
        string memory _eventUri,
        string memory _name,
        string memory _symbol,
        address _admin,
        address _controller,
        address _factory
        ) ERC721(_name, _symbol) {
        eventAdmin = _admin;
        Controller = _controller;
        factory = _factory;
        setBaseUri("https://ipfs.io/ipfs/");
        createEvent(
            _id,
            _fee,
            _no_of_participants,
            _regStartTime,
            _regEndTime,
            _eventUri
        );
    }

        //////////      MODIFIERS    ///////////////
        modifier onlyEventAdmin() {
            require(msg.sender == eventAdmin, "Unauthorized, not Admin");
            _;
        }


        ////////////////////////////////////////////////////

        //==============    FUNCTIONS       ==============//

        ////////////////////////////////////////////////////


       function supportsInterface(bytes4 interfaceId) public view virtual override( ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
        }

        function createEvent(
            uint256 _id,
            uint256 _fee,
            uint256 no_of_participants,
            uint256 _regStartTime,
            uint256 _regEndTime,
            string memory _eventUri
            ) internal {

            eventDetails.eventNftId = _id;
            eventDetails.eventFee = _fee;
            eventDetails.eventUri = _eventUri;
            eventDetails.regStartTime = _regStartTime;
            eventDetails.regEndTime = _regEndTime;

            idExists[_id] = true;
            totalExpectedParticipants = no_of_participants;

            emit EventCreated(_id, msg.sender);
        } 


        function setAttenders(address[] calldata _participants) external onlyEventAdmin {
            uint256 participants = _participants.length;
            for(uint256 i; i < participants; ++i){
                if(!hasRegistered[_participants[i]]) revert("Not a registered address");
                attendedEvent[_participants[i]] = true;
            }
        }


        function safeMint2(address to, uint256 _tokenId, string memory uri)
            internal

        {
            _safeMint(to, _tokenId);
            _setTokenURI(_tokenId, uri);
        }

        function _baseURI() internal view override returns (string memory) {
            return baseUri;
        }

        function setBaseUri(string memory _baseUri) internal {
            baseUri = _baseUri;
        }

        

        function register() external payable {
            _tokenIds.increment();
            uint256 currentNum = _tokenIds.current();
            uint256 eventId = eventDetails.eventNftId + currentNum;
            string memory _tokenURI = eventDetails.eventUri;

            if(totalExpectedParticipants == eventDetails.totalParticipants) revert Max_No_Of_Participants_Reached();
            if(hasRegistered[msg.sender] == true) revert Already_Registered();
            if(eventDetails.regStartTime > block.timestamp) revert Registration_Not_Started();
            if(eventDetails.regEndTime < block.timestamp) revert Registration_Ended();

            if(eventDetails.eventFee == 0 && msg.value == 0) {
                
                hasRegistered[msg.sender] = true;
                eventDetails.totalParticipants = eventDetails.totalParticipants + 1;

                safeMint2(msg.sender, eventId, _tokenURI);
                emit Registered(msg.sender, eventId, _tokenURI);
                
            } else if(msg.value == eventDetails.eventFee && eventDetails.eventFee > 0) {

                hasRegistered[msg.sender] = true;
                eventDetails.totalParticipants = eventDetails.totalParticipants + 1;
                totalEthFromTicket = totalEthFromTicket + msg.value;
       
                safeMint2(msg.sender, eventId, _tokenURI);

                emit Registered(msg.sender, eventId, _tokenURI);
                
            } else { revert("Not ticket fee");}
        }


        function setPoapAddr( address _poap) external {
            if(msg.sender != factory) revert("Unauthorized call[setPoapAddr]");
            poapAddr = _poap;
        }


        function claimAttendanceToken() external {
            _tokenIds.increment();
            uint256 currentNum = _tokenIds.current();
            uint256 poapNftId = eventDetails.eventNftId + currentNum;
            if(!attendedEvent[msg.sender]) revert Record_Not_Found();
            if(hasClaimed[msg.sender]) revert("Already claimed NFT");

            hasClaimed[msg.sender] = true;
            IPoap(poapAddr).safeMint(msg.sender, poapNftId);
            emit Attendance_Token_Claimed(msg.sender, poapNftId);
        }


        function tokenURI(uint256 tokenId) public view override(ERC721URIStorage, ERC721) returns (string memory) {
            _requireMinted(tokenId);

            string memory _tokenURI = _tokenURIs[tokenId];
            string memory base = _baseURI();

            // If there is no base URI, return the token URI.
            if (bytes(base).length == 0) {
                return _tokenURI;
            }
            // If both are set, concatenate thevirtual baseURI and tokenURI (via abi.encodePacked).
            if (bytes(_tokenURI).length > 0) {
                return string(abi.encodePacked(base, _tokenURI));
            }

            return super.tokenURI(tokenId);
        }

        function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721) {
            super._burn(tokenId);

            if (bytes(_tokenURIs[tokenId]).length != 0) {
                delete _tokenURIs[tokenId];
            }
        }

        //////////////   VIEW FUNCTIONS      ///////////////

        function checkClaimed(address _participant) external view returns(bool){
            return hasClaimed[_participant];
        }

        function showTotalParticipants() external view returns(uint) {
            return eventDetails.totalParticipants;
        }

        function EthBalanceOfOrganizer() external view returns(uint) {
            return OrganizersEthShare;
        }

        function showTotalSeatsAvailable() external view returns(uint256) {
            return totalExpectedParticipants;
        }
    
        //////////  TRANSACTION FUNCTIONS   ///////////
        function withdrawEthEventAdmin(uint256 _amount) external onlyEventAdmin {
            uint fee = calcQuotas();
            OrganizersEthShare = totalEthFromTicket - fee;

            if(_amount > OrganizersEthShare) revert Insufficient_funds();
            OrganizersEthShare = OrganizersEthShare - _amount;
            (bool success, ) = payable(msg.sender).call{value: _amount}("");
            require(success, "Ether transfer fail...");
            emit WithdrawEthAdmin(msg.sender, _amount, block.timestamp);
        }


        function withdraw() external {
            uint fee = calcQuotas();
            
            if(msg.sender != factory) revert("Unauthorized call[withdraw]");

            (bool success, ) = payable(factory).call{value: fee}("");
            require(success, "Ether transfer fail...");

            emit WithdrawEthPlatform(msg.sender, fee, factory, block.timestamp);
        }



        /////////////   CORE V2     /////////////
        function calcQuotas() internal returns(uint256) {
            uint fee = (totalEthFromTicket * 5) / 100;
            return platformFee = fee;
        }

        ///////////     OVERRIDES   ////////////
       
        receive() external payable {}
}

