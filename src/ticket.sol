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
    string baseUri;
    

    struct EventDetails {
        bool hasRegistrationStarted;
        uint256  eventNftId;
        uint256  poapNftId;
        uint256  totalParticipants;
        uint256 regStartTime;
        uint256 regEndTime;
        uint256  eventStartTime;
        uint256  eventEndTime;
        uint256  eventFee;
        string  eventDate;
        string poapUri;
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
    event RegistrationStarted(string info);
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
        string memory _eventUri,
        string memory _name,
        string memory _symbol,
        address _admin,
        address _controller
        ) ERC721(_name, _symbol) {
        eventAdmin = _admin;
        Controller = _controller;
        setBaseUri("https://ipfs.io/ipfs/");
        createEvent(
            _id,
            _fee,
            _no_of_participants,
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
            string memory _eventUri
            ) internal {

            eventDetails.eventNftId = _id;
            eventDetails.eventFee = _fee;
            eventDetails.eventUri = _eventUri;

            idExists[_id] = true;
            totalExpectedParticipants = no_of_participants;

            emit EventCreated(_id, msg.sender);
        } 
        

        function startRegistration(uint _startTime, uint _endTime) external onlyEventAdmin {
            require(!eventDetails.hasRegistrationStarted, "Registration Already started");

            eventDetails.hasRegistrationStarted = true;
            eventDetails.eventStartTime = _startTime;
            eventDetails.eventEndTime = _endTime;
            emit RegistrationStarted("Registration started!!!");
        }

        function endRegistration() external onlyEventAdmin {
            require(eventDetails.hasRegistrationStarted, "Registration Already ended");
            eventDetails.hasRegistrationStarted = false;
            emit RegistrationStarted("Registration Ended!!!");
        }


        function setAttenders(address[] calldata _participants) external onlyEventAdmin {
            uint256 participants = _participants.length;
            for(uint256 i; i < participants; ++i){
                if(!hasRegistered[_participants[i]]) revert("Not a registered address");
                attendedEvent[_participants[i]] = true;
            }
        }


        function safeMint(address to, uint256 _tokenId, string memory uri)
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
            if(!eventDetails.hasRegistrationStarted) revert Registration_Not_Started();

            if(eventDetails.eventFee == 0 && msg.value == 0) {
                
                hasRegistered[msg.sender] = true;
                eventDetails.totalParticipants = eventDetails.totalParticipants + 1;

                safeMint(msg.sender, eventId, _tokenURI);
                emit Registered(msg.sender, eventId, _tokenURI);
                
            } else if(msg.value == eventDetails.eventFee && eventDetails.eventFee > 0) {

                hasRegistered[msg.sender] = true;
                eventDetails.totalParticipants = eventDetails.totalParticipants + 1;
                totalEthFromTicket = totalEthFromTicket + msg.value;
       
                safeMint(msg.sender, eventId, _tokenURI);

                emit Registered(msg.sender, eventId, _tokenURI);
                
            } else { revert("Not ticket fee");}
        }

        


        function setPoapUri_Addr(string memory _uri, address _poap) external onlyEventAdmin {
            bytes32 zeroHash = keccak256(abi.encode(""));
            if(_poap == address(0)) revert Invalid_Address();
            if(zeroHash == keccak256(abi.encode(_uri))) revert Invalid_Event_Uri();

            eventDetails.poapUri = _uri;
            poapAddr = _poap;
        }


        function claimAttendanceToken() external {
            _tokenIds.increment();
            uint256 currentNum = _tokenIds.current();
            uint256 poapNftId = eventDetails.eventNftId + currentNum;
            string memory _poapUri = eventDetails.poapUri;
            if(!attendedEvent[msg.sender]) revert Record_Not_Found();
            if(hasClaimed[msg.sender]) revert("Already claimed NFT");

            hasClaimed[msg.sender] = true;
            IPoap(poapAddr).safeMint(msg.sender, poapNftId, _poapUri);
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
      
        function showEventDate() external view returns(string memory){ 
            return eventDetails.eventDate;
        }

        function checkClaimed(address _participant) external view returns(bool){
            return hasClaimed[_participant];
        }

        function showTotalParticipants() external view returns(uint) {
            return eventDetails.totalParticipants;
        }

        function EthBalanceOfOrganizer() external view returns(uint) {
            return OrganizersEthShare;
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


        function withdraw(uint256 _amount, address _to) external {
            uint fee = calcQuotas();
            
            if(msg.sender != Controller) revert Not_Controller();
            if(_to == address(0x0)) revert Invalid_Address();
            if(_amount > fee) revert Insufficient_funds();
            platformFee = platformFee - _amount;

            (bool success, ) = payable(_to).call{value: _amount}("");
            require(success, "Ether transfer fail...");

            emit WithdrawEthPlatform(msg.sender, _amount, _to, block.timestamp);
        }



        /////////////   CORE V2     /////////////
        function calcQuotas() internal returns(uint256) {
            uint fee = (totalEthFromTicket * 5) / 100;
            return platformFee = fee;
        }

        ///////////     OVERRIDES   ////////////
       
        receive() external payable {}
}

