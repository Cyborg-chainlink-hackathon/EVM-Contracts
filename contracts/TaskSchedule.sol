// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FunctionsConsumerExample} from "./TaskScheduleOracle.sol";
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
    string sourceCode = "async function downloadFromIPFS(){const ipfsResponse=await Functions.makeHttpRequest({url:args[0],method:'GET',headers:{'Content-Type':'application/json'}});if(ipfsResponse.error){throw new Error('Error downloading file from IPFS');}return ipfsResponse.data;}async function decryptData(encryptedData){const response=await Functions.makeHttpRequest({url:`http://${args[3]}:3000/decrypt`,method:'POST',headers:{Accept:'application/json','Content-Type':'application/json'},data:{data:encryptedData,key:args[2]}});if(response.error){throw new Error('Error decrypting data');}const decryptedData=JSON.parse(JSON.stringify(response.data));return decryptedData;}async function initiateCompute(imageSrc,ipAddress){const url_d=`http://${ipAddress}:3001/deploy`;const response=await Functions.makeHttpRequest({url:url_d,method:'POST',headers:{Accept:'application/json','Content-Type':'application/json'},data:{src:imageSrc}});if(response.error){throw new Error('Error decrypting data');}return response.data;}const encryptedJson=await downloadFromIPFS();const decryptedJson=await decryptData(JSON.parse(JSON.stringify(encryptedJson)));const deploymentStatus=await initiateCompute(args[1],decryptedJson.ipAddress.trim());return Functions.encodeString(deploymentStatus.message);";

    event TaskScheduled(uint256 indexed taskId, address indexed workerAddress, string dockerImage, TaskStatus status);
    event TaskStatusUpdated(uint256 indexed taskId, TaskStatus status);

    constructor(address workerRegistryAddress, address oracleAddress) {
        workerRegistry = WorkerRegistration(workerRegistryAddress);
        oracle = FunctionsConsumerExample(oracleAddress);
    }

    function scheduleTask(string memory ipfsURI, string memory dockerImage, ) public {
        address workerAddress = workerRegistry.getRandomWorker();
        Task memory newTask = Task({
            workerAddress: workerAddress,
            creator: msg.sender,
            status: TaskStatus.InProcess,
            dockerImage: dockerImage
        });
        taskCounter++;
        tasks[taskCounter] = newTask;

        string[] memory args = new string[](2);
        bytes[] memory emptyArgs = new bytes[](0);
        args[0] = ipfsURI;
        args[1] = dockerImage;
        //args[2] should be public address of the worker

        oracle.sendRequest(
            sourceCode,
            args
        );

        emit TaskScheduled(taskCounter, workerAddress, dockerImage, TaskStatus.InProcess);
    }

    function updateTaskStatus(uint256 taskId, TaskStatus status) public {
        require(tasks[taskId].creator == msg.sender, "Only task creator can update status");
        tasks[taskId].status = status;
        emit TaskStatusUpdated(taskId, status);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function fulfillTask(uint256 taskId) public {
        tasks[taskId].status = TaskStatus.Scheduled;
        emit TaskStatusUpdated(taskId, TaskStatus.Scheduled);
    }
}