// Copyright (C) 2020 Zerion Inc. <https://zerion.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// SPDX-License-Identifier: LGPL-3.0-only

pragma solidity 0.7.6;

/**
 * @dev OusdVault contract interface.
 * Only the functions required for OusdTokenAdapter contract are added.
 */
interface OusdVault {
    function calculateRedeemOutputs(uint256 _amount) external view returns (uint256[] memory);

    function getAllAssets() external view returns (address[] memory);

    function mint(
        address _asset,
        uint256 _amount,
        uint256 _minimumOusdAmount
    ) external;

    function mintMultiple(
        address[] calldata _assets,
        uint256[] calldata _amounts,
        uint256 _minimumOusdAmount
    ) external;

    function redeem(uint256 _amount, uint256 _minimumUnitAmount) external;
}