// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import { AxiomV2Client } from "https://github.com/axiom-crypto/axiom-v2-periphery/blob/main/src/client/AxiomV2Client.sol";
import { IERC20 } from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";

contract Verifier is AxiomV2Client {
    bytes32 immutable QUERY_SCHEMA;
    uint64 immutable SOURCE_CHAIN_ID;
    IERC20 private BASE_TOKEN;
    uint256 immutable REWARD_AMOUNT;

    event TransferedAmountEvent(uint256 blockNumber, address sender, address receiver, address token, uint256 amount);

    constructor(address _axiomV2QueryAddress, uint64 _callbackSourceChainId, bytes32 _querySchema, address _token, uint256 _reward)
        AxiomV2Client(_axiomV2QueryAddress)
    {
        QUERY_SCHEMA = _querySchema;
        SOURCE_CHAIN_ID = _callbackSourceChainId;
        BASE_TOKEN = IERC20(_token);
        REWARD_AMOUNT = _reward;
    }

    /// @inheritdoc AxiomV2Client
    function _validateAxiomV2Call(
        AxiomCallbackType,
        uint64 sourceChainId,
        address,
        bytes32 querySchema,
        uint256,
        bytes calldata
    ) internal view override {
        require(sourceChainId == SOURCE_CHAIN_ID, "Source chain ID does not match");
        require(querySchema == QUERY_SCHEMA, "Invalid query schema");
    }

    /// @inheritdoc AxiomV2Client
    function _axiomV2Callback(
        uint64,
        address,
        bytes32, 
        uint256,
        bytes32[] calldata axiomResults,
        bytes calldata
    ) internal override {
        uint256 blockNumber = uint256(axiomResults[0]);
        address sender = address(uint160(uint256(axiomResults[1])));
        address receiver = address(uint160(uint256(axiomResults[2])));
        address token = address(uint160(uint256(axiomResults[3])));
        uint256 amount = uint256(axiomResults[4]);

        BASE_TOKEN.transfer(sender, REWARD_AMOUNT);

        emit TransferedAmountEvent(blockNumber, sender, receiver, token, amount);
    }
}