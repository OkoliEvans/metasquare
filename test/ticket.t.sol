// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ticket.sol";
import "../src/ticketFactory.sol";
import "../src/ITicketing.sol";
import "../src/poap.sol";

contract CounterScript is Test {
        
        TicketFactory ticketFactory;
        address Controller = 0xc6d123c51c7122d0b23e8B6ff7eC10839677684d;
        address eventAdmin = 0x49207A3567EF6bdD0bbEc88e94206f1cf53c5AfC;
    function setUp() public {
        ticketFactory = new TicketFactory(Controller);
    }

    function test_CreateID() public {
        vm.prank(Controller);
        ticketFactory.createID(300,eventAdmin);
        vm.prank(Controller);
        ticketFactory.createID(500,eventAdmin);
    }

    function test_createEvent() public {
        test_CreateID();
        vm.startPrank(eventAdmin);
        // address event1 = ticketFactory.createEvent(
        //     200,
        //     0,
        //     60,
        //     "https://ipfs.io/ipfs/QmX84bZL51sJ4g4M8XoWQnBWQJ4Fh1TbT8TgfW2yyfNft",
        //     "Musika",
        //     "MSKA",
        //     "MusikaFlex",
        //     "mFlex"
        // );

        (address newPoap, address newEvent) = ticketFactory.createEvent(
            300,
            2 ether,
            50,
            "https://ipfs.io/ipfs/QmX84bZL51sJ4g4M8XoWQnBWQJ4Fh1TbT8TgfW2yyfNft",
            "Musika",
            "MSKA",
            "MusikaFlex",
            "mFlex"
        );

        vm.stopPrank();

        ticketFactory.checkEventId(newEvent);
        ticketFactory.showTotalEventAddresses();
        // ticketFactory.returnTotalNoOfEvents();
    }
        
        address[] attenders = [0x5D319012daEA8Fa10BbE8eBe79E4572988ecf0Ab,0x6ED60d1b94b0bB67DcA1c3e69b4Ee2F2eF10136F];

    function test_ticketContract() public {
        test_CreateID();
        vm.startPrank(eventAdmin);
            (address newPoap, address newEvent) = ticketFactory.createEvent(
            500,
            2 ether,
            50,
            "QmX84bZL51sJ4g4M8XoWQnBWQJ4Fh1TbT8TgfW2yyfNft",
            "Musika",
            "MSKA",
            "MusikaFlex",
            "mFlex"
        );


        ITicketing(newEvent).startRegistration(1 minutes, 5 minutes);

        vm.stopPrank();
 
        address user = 0x5D319012daEA8Fa10BbE8eBe79E4572988ecf0Ab;
        address user2 = 0x6ED60d1b94b0bB67DcA1c3e69b4Ee2F2eF10136F;
        address whisperer = 0xFA5f9EAa65FFb2A75de092eB7f3fc84FC86B5b18;
        vm.deal(user, 10 ether);
        vm.deal(user2, 50 ether);
        vm.deal(whisperer, 5 ether);

        vm.prank(user);
        ITicketing(newEvent).register{value: 2 ether}();

        vm.prank(user2);
        ITicketing(newEvent).register{value: 2 ether}();


        vm.startPrank(eventAdmin);
        ITicketing(newEvent).endRegistration();
        ITicketing(newEvent).setAttenders(attenders);
        ITicketing(newEvent).setPoapUri_Addr("QmX84bZL51sJ4g4M8XoWQnBWQJ4Fh1TbT8TgfW2yyfNft", address(newPoap));
        
        ITicketing(newEvent).withdrawEthEventAdmin(1.9 ether);
        vm.stopPrank();

        // vm.prank(Controller);
        // ITicketing(newEvent).withdraw(0.1 ether, user);


        vm.prank(user);
        ITicketing(newEvent).claimAttendanceToken();
        vm.prank(user2);
        ITicketing(newEvent).claimAttendanceToken();
        ITicketing(newEvent).EthBalanceOfOrganizer();
        ITicketing(newEvent).tokenURI(501);
        // ticketFactory.showPoaps();





    }
}
