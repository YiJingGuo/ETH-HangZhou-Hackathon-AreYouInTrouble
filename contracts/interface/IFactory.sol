// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

interface IFactory {
    function addMaintainAddr(address maintainer, address contractAddr) external;
    function removeMaintainAddr(address maintainer, address contractAddr) external;
    function addFatherList(address inheritor, address contractAddr) external;
}