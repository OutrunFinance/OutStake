//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

interface IBlastPoints {
    function configurePointsOperator(address operator) external;

    function configurePointsOperatorOnBehalf(address contractAddress, address operator) external;
}