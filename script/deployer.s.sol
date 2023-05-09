// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "forge-std/Script.sol";
import "../src/ticket.sol";
import "../src/ticketFactory.sol";
import "../src/ITicketing.sol";


contract TicketScript is Script {
    TicketFactory public ticketFactory;
    function setUp() public {}

    address[] attenders = [0xBd032b770f364605BfE8D16E27ae4D241b9061c8];
    function run() public {
        address deployer = 0xc6d123c51c7122d0b23e8B6ff7eC10839677684d;
        address eventAdmin = 0x49207A3567EF6bdD0bbEc88e94206f1cf53c5AfC;
        address user = 0xBd032b770f364605BfE8D16E27ae4D241b9061c8;
        uint256 deployerKey = vm.envUint("PRIVATE_KEY");
        uint256 eventAdminKey = vm.envUint("PRIVATE_KEY3");
        uint256 userKey = vm.envUint("PRIVATE_KEY4");

        vm.startBroadcast(deployerKey);
        ticketFactory = new TicketFactory(deployer);
        ticketFactory.createID(10, eventAdmin);
        vm.stopBroadcast();

        vm.startBroadcast(eventAdminKey);
        (address newPoap, address newEvent) = ticketFactory.createEvent(
            10,
            0.2 ether,
            50,
            2 minutes,
            5 minutes + block.timestamp,
            "QmU1Av1YCoMph5hoLgKUc32ZbexmCYPx8JoFGzUBxkXpbC",
            "Musika",
            "MDKA-055"
        );

        vm.stopBroadcast();

        vm.startBroadcast(userKey);
        ITicketing(newEvent).register{value: 0.2 ether}(0.2 ether);
        vm.stopBroadcast();

        vm.startBroadcast(eventAdminKey);

        ITicketing(newEvent).setAttenders(attenders);

        vm.stopBroadcast();

        vm.startBroadcast(userKey);
        ITicketing(newEvent).claimAttendanceToken();
        vm.stopBroadcast();
    }


}
