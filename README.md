# EVM-Contracts Documentation

## Overview
This repository contains a set of smart contracts built on the Ethereum Virtual Machine (EVM) designed to facilitate the secure and decentralized scheduling of tasks. It leverages several advanced technologies to create a robust and efficient infrastructure management system. The key components of this project include Solidity smart contracts, ChainLink VRF, ChainLink Functions, IPFS, and Kubernetes (k3s). Below is a detailed overview of the smart contracts utilised in our application.


## Project Structure

- **contracts/**: Contains Solidity contract files.
  - **TaskSchedule.sol**: Manages task scheduling.
  - **TaskScheduleOracle.sol**: Interacts with an oracle for task scheduling.
  - **WorkerRegistration.sol**: Manages worker registrations.
- **hardhat.config.js**: Hardhat configuration file.
- **package.json**: Project dependencies and scripts.

## Getting Started

### Prerequisites
- Node.js
- npm
- Hardhat

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/Cyborg-chainlink-hackathon/EVM-Contracts
   cd EVM-Contracts
   ```
2. Install dependencies:
    ```
    npm install
    ```
3. Compile:
   ```
   npx hardhat compile
   ```
### Contracts
**1. TaskScheduling.sol**
The TaskScheduling contract is responsible for managing the scheduling of tasks. It includes functionalities for creating, updating, and querying tasks, as well as interacting with the worker registry and the oracle.

- Constructor:
    - Initializes the contract with addresses of the worker registry and oracle contracts.

- Important Functions:
    - scheduleTask(string memory dockerImage): Schedules a new task by assigning a random worker and sending a request to the ChainLink oracle network


**2. TaskScheduleOracle.sol**
The TaskScheduleOracle contract interacts with an oracle to fetch external data required for task scheduling. It ensures that tasks are scheduled based on real-world data and conditions.

- Constructor:
    - Initializes the contract with the router address and sets the owner.

- Important Functions:
    - sendRequest(string[] memory args, uint256 taskID): Sends a request to the oracle.
    - updateTaskSchedulingContract(address taskScheduling): Updates the reference to the task scheduling contract.
    - fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err): Callback function used by the oracle to fulfill requests.
    
**3. WorkerRegistration.sol**
The WorkerRegistration contract manages the registration and details of workers. It includes functionalities for workers to register, update their details, and for others to query worker information. It also utilizes Chainlink VRF for selecting random workers.


- Constructor:
    - Initializes the contract with the subscription ID for Chainlink VRF.
    

- Important Functions:
    - registerWorker(string memory memoryInfo, string memory cpuCores, string memory storageInfo): Registers a new worker.
    - requestRandomWorker(bool enableNativePayment): Requests a random worker using Chainlink VRF.
    - fulfillRandomWords(uint256 _requestId, uint256[] calldata _randomWords): Callback function used by Chainlink VRF to fulfill random worker selection.
    - getWorkerCount(): Returns the number of registered workers.
    - getWorkerDetails(uint256 index): Returns the details of a specified worker.