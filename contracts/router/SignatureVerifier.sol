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

pragma solidity 0.8.4;

import { EIP712 } from "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import { ISignatureVerifier } from "../interfaces/ISignatureVerifier.sol";
import { UsedHash } from "../shared/Errors.sol";
import {
    AbsoluteTokenAmount,
    Fee,
    Input,
    Permit,
    SwapDescription,
    TokenAmount
} from "../shared/Structs.sol";

contract SignatureVerifier is ISignatureVerifier, EIP712 {
    mapping(bytes32 => mapping(address => bool)) internal isHashUsed_;

    bytes32 internal constant EXECUTE_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Execute(",
                "Input input,",
                "AbsoluteTokenAmount requiredOutput,",
                "SwapDescription swapDescription,",
                "address account,",
                "uint256 salt",
                ")",
                "AbsoluteTokenAmount(address token,uint256 absoluteAmount)",
                "Fee(uint256 share,address beneficiary)",
                "Input(TokenAmount tokenAmount,Permit permit)",
                "Permit(uint8 permitType,bytes permitCallData)",
                "SwapDescription(",
                "uint8 swapType,",
                "Fee fee,",
                "address destination,",
                "address caller,",
                "bytes callData",
                ")",
                "TokenAmount(address token,uint256 amount,uint8 amountType)"
            )
        );
    bytes32 internal constant ABSOLUTE_TOKEN_AMOUNT_TYPEHASH =
        keccak256(abi.encodePacked("AbsoluteTokenAmount(address token,uint256 absoluteAmount)"));
    bytes32 internal constant SWAP_DESCRIPTION_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "SwapDescription(",
                "uint8 swapType,",
                "Fee fee,",
                "address destination,",
                "address caller,",
                "bytes callData",
                ")",
                "Fee(uint256 share,address beneficiary)"
            )
        );
    bytes32 internal constant FEE_TYPEHASH =
        keccak256(abi.encodePacked("Fee(uint256 share,address beneficiary)"));
    bytes32 internal constant INPUT_TYPEHASH =
        keccak256(
            abi.encodePacked(
                "Input(TokenAmount tokenAmount,Permit permit)",
                "Permit(uint8 permitType,bytes permitCallData)",
                "TokenAmount(address token,uint256 amount,uint8 amountType)"
            )
        );
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256(abi.encodePacked("Permit(uint8 permitType,bytes permitCallData)"));
    bytes32 internal constant TOKEN_AMOUNT_TYPEHASH =
        keccak256(abi.encodePacked("TokenAmount(address token,uint256 amount,uint8 amountType)"));

    /**
     * @param name String with EIP712 name.
     * @param version String with EIP712 version.
     */
    constructor(string memory name, string memory version) EIP712(name, version) {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @inheritdoc ISignatureVerifier
     */
    function isHashUsed(bytes32 hashToCheck, address account)
        public
        view
        override
        returns (bool hashUsed)
    {
        return isHashUsed_[hashToCheck][account];
    }

    /**
     * @inheritdoc ISignatureVerifier
     */
    function hashData(
        Input memory input,
        AbsoluteTokenAmount memory requiredOutput,
        SwapDescription memory swapDescription,
        address account,
        uint256 salt
    ) public view override returns (bytes32 hashedData) {
        return _hashTypedDataV4(hash(input, requiredOutput, swapDescription, account, salt));
    }

    /**
     * @inheritdoc ISignatureVerifier
     */
    function getAccountFromSignature(bytes32 hashedData, bytes memory signature)
        public
        pure
        override
        returns (address payable account)
    {
        return payable(ECDSA.recover(hashedData, signature));
    }

    /**
     * @dev Marks hash as used by the given account.
     * @param hashToMark Hash to be marked as used one.
     * @param account Account using the hash.
     */
    function markHashUsed(bytes32 hashToMark, address account) internal {
        if (isHashUsed_[hashToMark][account]) {
            revert UsedHash(hashToMark, account);
        }
        isHashUsed_[hashToMark][account] = true;
    }

    /**
     * @param input Input struct to be hashed.
     * @param requiredOutput AbsoluteTokenAmount struct to be hashed.
     * @param swapDescription SwapDescription struct to be hashed.
     * @param account Account address to be hashed.
     * @param salt Salt parameter preventing double-spending to be hashed.
     * @return Execute data hashed.
     */
    function hash(
        Input memory input,
        AbsoluteTokenAmount memory requiredOutput,
        SwapDescription memory swapDescription,
        address account,
        uint256 salt
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    EXECUTE_TYPEHASH,
                    hash(input),
                    hash(requiredOutput),
                    hash(swapDescription),
                    account,
                    salt
                )
            );
    }

    /**
     * @param input Input struct to be hashed.
     * @return Hashed Input structs array.
     */
    function hash(Input memory input) internal pure returns (bytes32) {
        return keccak256(abi.encode(INPUT_TYPEHASH, hash(input.tokenAmount), hash(input.permit)));
    }

    /**
     * @param tokenAmount TokenAmount struct to be hashed.
     * @return Hashed TokenAmount struct.
     */
    function hash(TokenAmount memory tokenAmount) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    TOKEN_AMOUNT_TYPEHASH,
                    tokenAmount.token,
                    tokenAmount.amount,
                    tokenAmount.amountType
                )
            );
    }

    /**
     * @param permit Permit struct to be hashed.
     * @return Hashed Permit struct.
     */
    function hash(Permit memory permit) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    PERMIT_TYPEHASH,
                    permit.permitType,
                    keccak256(abi.encodePacked(permit.permitCallData))
                )
            );
    }

    /**
     * @param absoluteTokenAmount AbsoluteTokenAmount struct to be hashed.
     * @return Hashed AbsoluteTokenAmount struct.
     */
    function hash(AbsoluteTokenAmount memory absoluteTokenAmount) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    ABSOLUTE_TOKEN_AMOUNT_TYPEHASH,
                    absoluteTokenAmount.token,
                    absoluteTokenAmount.absoluteAmount
                )
            );
    }

    /**
     * @param swapDescription SwapDescription struct to be hashed.
     * @return Hashed SwapDescription struct.
     */
    function hash(SwapDescription memory swapDescription) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SWAP_DESCRIPTION_TYPEHASH,
                    swapDescription.swapType,
                    hash(swapDescription.fee),
                    swapDescription.destination,
                    swapDescription.caller,
                    keccak256(abi.encodePacked(swapDescription.callData))
                )
            );
    }

    /**
     * @param fee Fee struct to be hashed.
     * @return Hashed Fee struct.
     */
    function hash(Fee memory fee) internal pure returns (bytes32) {
        return keccak256(abi.encode(FEE_TYPEHASH, fee.share, fee.beneficiary));
    }
}
