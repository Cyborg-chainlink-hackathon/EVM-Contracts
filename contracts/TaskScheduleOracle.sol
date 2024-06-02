// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {TaskScheduling} from "./TaskSchedule.sol";

contract TaskScheduleOracle is FunctionsClient, ConfirmedOwner {
using FunctionsRequest for FunctionsRequest.Request;

    bytes32 public s_lastRequestId;
    bytes public s_lastResponse;
    bytes public s_lastError;
    bytes32 donID =
        0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000;
    uint32 gasLimit = 290_000;
    uint64 subscriptionId = 2893;
    uint8 donHostedSecretsSlotID = 0;
    uint64 donHostedSecretsVersion = 1717325489;
    address router = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    string sourceCode = "if(!secrets.staticUrl){throw Error('DECRYPT_KEY environment variable not set. Set the static url in the secrets.');}async function downloadFromIPFS(){const ipfsResponse=await Functions.makeHttpRequest({url:'https://experience-having-dream.quicknode-ipfs.com/ipfs/QmXatx6QSPeffjGdZyngiNFLgvyL5vNR3nuN9pfFxzLPV8/0',method:'GET',headers:{'Content-Type':'application/json'}});if(ipfsResponse.error){throw new Error('Error downloading file from IPFS');}return ipfsResponse.data;}async function decryptData(encryptedData){const static_url=`http://${secrets.staticUrl}:3000/decrypt`;console.log('static_url: ',static_url);const response=await Functions.makeHttpRequest({url:static_url,method:'POST',headers:{Accept:'application/json','Content-Type':'application/json'},data:{data:encryptedData,key:args[1]}});console.log('response: ',response);if(response.error){throw new Error('Error decrypting data');}const decryptedData=JSON.parse(JSON.stringify(response.data));return decryptedData;}async function initiateCompute(imageSrc,ipAddress){const urld=`http://${ipAddress}:3001/deploy`;console.log('urld: ',urld);const response=await Functions.makeHttpRequest({url:urld,method:'POST',headers:{Accept:'application/json','Content-Type':'application/json'},data:{src:imageSrc}});if(response.error){throw new Error('Error decrypting data');}return response.data;}const encryptedJson=await downloadFromIPFS();const decryptedJson=await decryptData(JSON.parse(JSON.stringify(encryptedJson)));const deploymentStatus=await initiateCompute(args[0],decryptedJson.worker_ipaddress.trim());return Functions.encodeString(deploymentStatus.message);";
    mapping(bytes32 => uint256) requestIDToTaskID;
    TaskScheduling taskScheduleAddr;

    error UnexpectedRequestID(bytes32 requestId);

    event Response(bytes32 indexed requestId, bytes response, bytes err);

    constructor() FunctionsClient(router) ConfirmedOwner(msg.sender) {}

    function sendRequest(
        string[] memory args,
        uint256 taskID
    ) external returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(sourceCode);
        if (donHostedSecretsVersion > 0) {
            req.addDONHostedSecrets(
                donHostedSecretsSlotID,
                donHostedSecretsVersion
            );
        }
        if (args.length > 0) req.setArgs(args);
        s_lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );
        requestIDToTaskID[s_lastRequestId] = taskID;
        return s_lastRequestId;
    }

    function updateTaskSchedulingContract(address taskScheduling) public{
        taskScheduleAddr = TaskScheduling(taskScheduling);
    }


    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (s_lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId);
        }
        s_lastResponse = response;
        s_lastError = err;
        taskScheduleAddr.fulfillTask(requestIDToTaskID[s_lastRequestId]);
        emit Response(requestId, s_lastResponse, s_lastError);
    }
}