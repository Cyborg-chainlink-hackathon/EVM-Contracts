// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WorkerRegistration {
    struct Worker {
        address workerAddress;
        string memoryInfo;
        string cpuCores;
        string storageInfo;
        bool isActive;
    }

    Worker[] public workers;
    address public randomWorker;
    event WorkerRegistered(address indexed workerAddress, string memoryInfo, string cpuCores, string storageInfo);
    event RandomWorkerSelected(address indexed workerAddress);

    function registerWorker(string memory memoryInfo, string memory cpuCores, string memory storageInfo) public {
        Worker memory newWorker = Worker({
            workerAddress: msg.sender,
            memoryInfo: memoryInfo,
            cpuCores: cpuCores,
            storageInfo: storageInfo,
            isActive: true
        });
        workers.push(newWorker);
        emit WorkerRegistered(msg.sender, memoryInfo, cpuCores, storageInfo);
    }

    function getRandomWorker() public returns (address) {
        require(workers.length > 0, "No workers registered");
        uint256 randomIndex = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % workers.length;
        randomWorker = workers[randomIndex].workerAddress;
        emit RandomWorkerSelected(randomWorker);
        return randomWorker;
    }

    function getWorkerCount() public view returns (uint256) {
        return workers.length;
    }

    function getWorkerDetails(uint256 index) public view returns (address, string memory, string memory, string memory, bool) {
        require(index < workers.length, "Worker index out of bounds");
        Worker memory worker = workers[index];
        return (worker.workerAddress, worker.memoryInfo, worker.cpuCores, worker.storageInfo, worker.isActive);
    }
}


//deployed: 0x84d9184A17672B8a2Ce04B3c2b492EdF43658d56