//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./IPoap.sol";
import "./IEventNft.sol";


contract iTicketing {
    // Poap poap;

    uint256 public totalEthFromTicket;
    uint256 private OrganizersEthShare;
    uint256 private platformFee;
    uint256  totalExpectedParticipants;
    address public Controller;
    address public eventAdmin;
    address poapAddr;
    address factory;
    address eventNftAddr;
    string baseUri;
    bool withdrawIsOpen;
    

    struct EventDetails {
        uint256  eventNftId;
        uint256  poapNftId;
        uint256  totalParticipants;
        uint256 regStartDate;
        uint256 regDeadline;
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
        uint256 _regStartDate,
        uint256 _regDeadline,
        string memory _eventUri,
        string memory _name,
        string memory _symbol,
        address _admin,
        address _controller,
        address _factory
        ) {
        eventAdmin = _admin;
        Controller = _controller;
        factory = _factory;
        // setBaseUri("https://ipfs.io/ipfs/");
        createEvent(
            _id,
            _fee,
            _no_of_participants,
            _regStartDate,
            _regDeadline,
            _eventUri
        );
    }

        //////////      MODIFIERS    ///////////////
        modifier onlyEventAdmin() {
            require(msg.sender == eventAdmin, "Unauthorized, not Admin");
            _;
        }

           modifier onlyEventAdminOrController() {
            require(msg.sender == eventAdmin || msg.sender == Controller, "Unauthorized, not Admin");
            _;
        }


        ////////////////////////////////////////////////////

        //==============    FUNCTIONS       ==============//

        ////////////////////////////////////////////////////


    //    function supportsInterface(bytes4 interfaceId) public view virtual override( ERC721) returns (bool) {
    //     return super.supportsInterface(interfaceId);
    //     }

        function createEvent(
            uint256 _id,
            uint256 _fee,
            uint256 no_of_participants,
            uint256 _regStartDate,
            uint256 _regDeadline,
            string memory _eventUri
            ) internal {

            eventDetails.eventNftId = _id;
            eventDetails.eventFee = _fee;
            eventDetails.eventUri = _eventUri;
            eventDetails.regStartDate = _regStartDate;
            eventDetails.regDeadline = _regDeadline;

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


        // function safeMint2(address to, uint256 _tokenId, string memory uri)
        //     internal

        // {
        //     _safeMint(to, _tokenId);
        //     _setTokenURI(_tokenId, uri);
        // }

        // function _baseURI() internal view override returns (string memory) {
        //     return baseUri;
        // }

        // function setBaseUri(string memory _baseUri) internal {
        //     baseUri = _baseUri;
        // }

        

        function register() external payable {

            uint256 eventId = eventDetails.eventNftId ++;
            string memory _tokenURI = eventDetails.eventUri;

            if(totalExpectedParticipants == eventDetails.totalParticipants) revert Max_No_Of_Participants_Reached();
            if(hasRegistered[msg.sender] == true) revert Already_Registered();
            if(eventDetails.regStartDate > block.timestamp) revert Registration_Not_Started();
            if(eventDetails.regDeadline < block.timestamp) revert Registration_Ended();
            
            if(eventDetails.eventFee == 0 && msg.value == 0) {
                
                hasRegistered[msg.sender] = true;
                eventDetails.totalParticipants = eventDetails.totalParticipants + 1;

                IEventNft(eventNftAddr).safeMint(msg.sender, eventId, _tokenURI);

                emit Registered(msg.sender, eventId, _tokenURI);
                
            } else if(msg.value == eventDetails.eventFee && eventDetails.eventFee > 0) {

                hasRegistered[msg.sender] = true;
                eventDetails.totalParticipants = eventDetails.totalParticipants + 1;
                totalEthFromTicket = totalEthFromTicket + msg.value;
       
                IEventNft(eventNftAddr).safeMint(msg.sender, eventId, _tokenURI);
            
                emit Registered(msg.sender, eventId, _tokenURI);
                
            } else { revert("Not ticket fee");}
        }


        function setPoapAddr( address _poap) external {
            if(msg.sender != factory) revert("Unauthorized call[setPoapAddr]");
            poapAddr = _poap;
        }

          function setEventNftAddr( address _eventNft) external {
            if(msg.sender != factory) revert("Unauthorized call[setPoapAddr]");
            eventNftAddr = _eventNft;
        }



        function claimAttendanceToken() external {
            uint256 poapNftId = eventDetails.eventNftId ++;
            if(!attendedEvent[msg.sender]) revert Record_Not_Found();
            if(hasClaimed[msg.sender]) revert("Already claimed NFT");

            hasClaimed[msg.sender] = true;
            IPoap(poapAddr).safeMint(msg.sender, poapNftId);
            emit Attendance_Token_Claimed(msg.sender, poapNftId);
        }


        // function tokenURI(uint256 tokenId) public view override(ERC721URIStorage, ERC721) returns (string memory) {
        //     _requireMinted(tokenId);

        //     string memory _tokenURI = _tokenURIs[tokenId];
        //     string memory base = _baseURI();

        //     // If there is no base URI, return the token URI.
        //     if (bytes(base).length == 0) {
        //         return _tokenURI;
        //     }
        //     // If both are set, concatenate thevirtual baseURI and tokenURI (via abi.encodePacked).
        //     if (bytes(_tokenURI).length > 0) {
        //         return string(abi.encodePacked(base, _tokenURI));
        //     }

        //     return super.tokenURI(tokenId);
        // }

        // function _burn(uint256 tokenId) internal override(ERC721URIStorage, ERC721) {
        //     super._burn(tokenId);

        //     if (bytes(_tokenURIs[tokenId]).length != 0) {
        //         delete _tokenURIs[tokenId];
        //     }
        // }

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

        function openWithdrawal() external {
            if(msg.sender != factory) revert("Unauthorized call[openWithdrawal]");
            if(withdrawIsOpen) revert("Withdrawal already open");

            withdrawIsOpen = true;
        }

        function pauseWithdrawal() external {
            if(msg.sender != factory) revert("Unauthorized call[openWithdrawal]");
            if(!withdrawIsOpen) revert("Withdrawal already paused");

            withdrawIsOpen = false;
        }

        function withdrawEthEventAdmin(uint256 _amount) external onlyEventAdminOrController {
            uint fee = calcQuotas();
            OrganizersEthShare = totalEthFromTicket - fee;

            if(!withdrawIsOpen) revert("Withdrawal closed. Contact controller");
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

