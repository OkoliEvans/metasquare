// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

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
        (address newPoap, address newEvent) = ticketFactory.createEvent(
            300,
            0.2 ether,
            50,
            1 minutes,
            5 minutes,
            "https://ipfs.io/ipfs/QmX84bZL51sJ4g4M8XoWQnBWQJ4Fh1TbT8TgfW2yyfNft",
            "Musika",
            "MSKA"
        );

        vm.stopPrank();
        address user = 0x5D319012daEA8Fa10BbE8eBe79E4572988ecf0Ab;
        vm.deal(user, 50 ether);
        vm.warp(1 minutes);
        vm.prank(user);
        ITicketing(newEvent).register{value: 0.2 ether}();


        ticketFactory.checkEventId(newEvent);
        ticketFactory.showTotalEventAddresses();


        vm.prank(Controller);
        ticketFactory.withdrawFromChild(300);
    }
        
    address[] attenders = [0x5D319012daEA8Fa10BbE8eBe79E4572988ecf0Ab,0x6ED60d1b94b0bB67DcA1c3e69b4Ee2F2eF10136F];

    function test_ticketContract() public {
        test_CreateID();
        vm.startPrank(eventAdmin);
            (address newPoap, address newEvent) = ticketFactory.createEvent(
            500,
            0.2 ether,
            50,
            1 minutes,
            10 minutes,
            "QmX84bZL51sJ4g4M8XoWQnBWQJ4Fh1TbT8TgfW2yyfNft",
            "Musika",
            "MSKA"
        );

        vm.stopPrank();
 
        address user = 0x5D319012daEA8Fa10BbE8eBe79E4572988ecf0Ab;
        address user2 = 0x6ED60d1b94b0bB67DcA1c3e69b4Ee2F2eF10136F;
        address whisperer = 0xFA5f9EAa65FFb2A75de092eB7f3fc84FC86B5b18;
        vm.deal(user, 10 ether);
        vm.deal(user2, 50 ether);
        vm.deal(whisperer, 5 ether);

        vm.warp(1 minutes);
        vm.prank(user);
        ITicketing(newEvent).register{value: 0.2 ether}();

        vm.prank(user2);
        ITicketing(newEvent).register{value: 0.2 ether}();


        vm.prank(eventAdmin);
        ITicketing(newEvent).setAttenders(attenders);
        
           vm.prank(Controller);
        ticketFactory.openWithdrawalChild(500);

        vm.prank(eventAdmin);
        ITicketing(newEvent).withdrawEthEventAdmin(0.01 ether);

        //        vm.prank(Controller);
        // ticketFactory.pauseWithdrawalChild(500);

              vm.prank(eventAdmin);
        ITicketing(newEvent).withdrawEthEventAdmin(0.09 ether);

        vm.prank(Controller);
        ticketFactory.withdrawFromChild(500);

        vm.prank(address(ticketFactory));
        ITicketing(newEvent).withdraw();



        vm.prank(user);
        ITicketing(newEvent).claimAttendanceToken();
        vm.prank(user2);
        ITicketing(newEvent).claimAttendanceToken();


        ITicketing(newEvent).EthBalanceOfOrganizer();
        ITicketing(newEvent).tokenURI(501);

    }
}
