// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {VRFConsumerBaseV2Plus} from "@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";
import {VRFV2PlusClient} from "@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";

contract WorkerRegistration is VRFConsumerBaseV2Plus {
    struct Worker {
        address workerAddress;
        string memoryInfo;
        string cpuCores;
        string storageInfo;
        bool isActive;
    }

    Worker[] public workers;
    address public randomWorker;

    // Chainlink VRF
    bytes32 public keyHash =
        0x787d74caea10b2b357790d5b5247c2f63d1d91572a9846f780606e4d953677ae;
    uint32 public callbackGasLimit = 100000;
    uint16 public requestConfirmations = 3;
    uint32 public numWords = 1;
    uint256 public s_subscriptionId;
    uint256 public lastRequestId;

    mapping(uint256 => uint256[]) public requestIdToRandomWords;
    mapping(uint256 => RequestStatus) public s_requests;

    struct RequestStatus {
        bool fulfilled;
        bool exists;
        uint256[] randomWords;
    }

    event WorkerRegistered(address indexed workerAddress, string memoryInfo, string cpuCores, string storageInfo);
    event RandomWorkerSelected(address indexed workerAddress);
    event RequestSent(uint256 requestId);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    constructor(
        uint256 subscriptionId
    ) VRFConsumerBaseV2Plus(0x9DdfaCa8183c41ad55329BdeeD9F6A8d53168B1B) {
        s_subscriptionId = subscriptionId;
    }

    function registerWorker(string memory memoryInfo, string memory cpuCores, string memory storageInfo) public {
        Worker memory newWorker = Worker({
            workerAddress: msg.sender,
            memoryInfo: memoryInfo,
            cpuCores: cpuCores,
            storageInfo: storageInfo,
            isActive: true
        });
        workers.push(newWorker);
        requestRandomWorker(false);
        emit WorkerRegistered(msg.sender, memoryInfo, cpuCores, storageInfo);
    }

    function requestRandomWorker(bool enableNativePayment) public returns (address) {
        require(workers.length > 0, "No workers registered");
        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            VRFV2PlusClient.RandomWordsRequest({
                keyHash: keyHash,
                subId: s_subscriptionId,
                requestConfirmations: requestConfirmations,
                callbackGasLimit: callbackGasLimit,
                numWords: numWords,
                extraArgs: VRFV2PlusClient._argsToBytes(
                    VRFV2PlusClient.ExtraArgsV1({
                        nativePayment: enableNativePayment
                    })
                )
            })
        );
        s_requests[requestId] = RequestStatus({
            randomWords: new uint256[](0) ,
            exists: true,
            fulfilled: false
        });
        lastRequestId = requestId;
        emit RequestSent(requestId);
        return randomWorker;
    }

    function fulfillRandomWords(
        uint256 _requestId,
        uint256[] calldata _randomWords
    ) internal override {
        require(s_requests[_requestId].exists, "request not found");
        s_requests[_requestId].fulfilled = true;
        s_requests[_requestId].randomWords = _randomWords;
        emit RequestFulfilled(_requestId, _randomWords);

        uint256 randomIndex = _randomWords[0] % workers.length;
        randomWorker = workers[randomIndex].workerAddress;
        emit RandomWorkerSelected(randomWorker);
    }

    function getWorkerCount() public view returns (uint256) {
        return workers.length;
    }

    function getWorkerDetails(uint256 index) public view returns (address, string memory, string memory, string memory, bool) {
        require(index < workers.length, "Worker index out of bounds");
        Worker memory worker = workers[index];
        return (worker.workerAddress, worker.memoryInfo, worker.cpuCores, worker.storageInfo, worker.isActive);
    }

    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
        require(s_requests[_requestId].exists, "request not found");
        RequestStatus memory request = s_requests[_requestId];
        return (request.fulfilled, request.randomWords);
    }
}
