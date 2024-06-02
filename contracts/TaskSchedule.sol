// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {TaskScheduleOracle} from "./TaskScheduleOracle.sol";
import {WorkerRegistration} from "./WorkerRegistration.sol";

contract TaskScheduling {
    WorkerRegistration workerRegistry;
    FunctionsConsumerExample oracle;

    enum TaskStatus { InProcess, Scheduled }

    struct Task {
        address workerAddress;
        address creator;
        TaskStatus status;
        string dockerImage;
    }

    uint256 public taskCounter;
    mapping(uint256 => Task) public tasks;

    event TaskScheduled(uint256 indexed taskId, address indexed workerAddress, string dockerImage, TaskStatus status);
    event TaskStatusUpdated(uint256 indexed taskId, TaskStatus status);

    constructor(address workerRegistryAddress, address oracleAddress) {
        workerRegistry = WorkerRegistration(workerRegistryAddress);
        oracle = FunctionsConsumerExample(oracleAddress);
    }

    function scheduleTask(string memory dockerImage) public {
        address workerAddress = workerRegistry.getRandomWorker();
        require(workerAddress != address(0));
        Task memory newTask = Task({
            workerAddress: workerAddress,
            creator: msg.sender,
            status: TaskStatus.InProcess,
            dockerImage: dockerImage
        });
        taskCounter++;
        tasks[taskCounter] = newTask;

        string[] memory args = new string[](2);
        args[0] = dockerImage;
        args[1] = addressToString(workerAddress);

        oracle.sendRequest(
            args
        );

        emit TaskScheduled(taskCounter, workerAddress, dockerImage, TaskStatus.InProcess);
    }

    function addressToString(address _addr) internal pure returns (string memory) {
        bytes memory addressBytes = abi.encodePacked(_addr);
        bytes memory hexAlphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + addressBytes.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < addressBytes.length; i++) {
            str[2 + i * 2] = hexAlphabet[uint8(addressBytes[i] >> 4)];
            str[3 + i * 2] = hexAlphabet[uint8(addressBytes[i] & 0x0f)];
        }
        return string(str);
    }

    function updateTaskStatus(uint256 taskId, TaskStatus status) public {
        require(tasks[taskId].creator == msg.sender, "Only task creator can update status");
        tasks[taskId].status = status;
        emit TaskStatusUpdated(taskId, status);
    }

    function fulfillTask(uint256 taskId) public {
        tasks[taskId].status = TaskStatus.Scheduled;
        emit TaskStatusUpdated(taskId, TaskStatus.Scheduled);
    }
}


//deployed: 0x14c27f300f74901CC54755291890311Bb281aBd1