// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "../src/ticket.sol";
import "../src/ticketFactory.sol";
import "../src/ITicketing.sol";
import "../src/eventNFT.sol";
import "../src/poap.sol";


contract TicketScript is Script {
    EventNFT public eventNFT;
    Poap public poap;
    TicketFactory public ticketFactory;
    function setUp() public {}

    address[] attenders = [0xD27e651784905002439cD2276d3B99782c2D59b1];
    function run() public {
        address deployer = 0xc6d123c51c7122d0b23e8B6ff7eC10839677684d;
        address eventAdmin = 0x49207A3567EF6bdD0bbEc88e94206f1cf53c5AfC;
        address user = 0xD27e651784905002439cD2276d3B99782c2D59b1;
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        uint256 eventAdminKey = vm.envUint("PRIVATE_KEY3");
        uint256 userKey = vm.envUint("PRIVATE_KEY5");

        vm.startBroadcast(deployerKey);
        poap = new Poap(eventAdmin);
        eventNFT = new EventNFT("MetaSquare", "MetaSq");
        ticketFactory = new TicketFactory(deployer, address(poap), address(eventNFT));
        ticketFactory.createID(10, eventAdmin);
        vm.stopBroadcast();

        vm.startBroadcast(eventAdminKey);
        (address newEvent) = ticketFactory.createEvent(
            10,
            0 ether,
            50,
            2 minutes,
            5 minutes + block.timestamp,
            "QmU1Av1YCoMph5hoLgKUc32ZbexmCYPx8JoFGzUBxkXpbC",
            "Musika",
            "MDKA-055"
        );

        vm.stopBroadcast();

        vm.startBroadcast(userKey);
        ITicketing(newEvent).register{value: 0 ether}();
        vm.stopBroadcast();

        vm.startBroadcast(eventAdminKey);

        ITicketing(newEvent).setAttenders(attenders);

        vm.stopBroadcast();

        vm.startBroadcast(userKey);
        ITicketing(newEvent).claimAttendanceToken();
        vm.stopBroadcast();
    }


}
