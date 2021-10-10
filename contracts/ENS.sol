// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IResolver {
    function addr(bytes32 node) external view returns (address);
}

interface IENS {
    function resolver(bytes32 node) external view returns (IResolver);
}