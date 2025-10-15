// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title OwnerCall - Minimal owner-gated arbitrary call executor
/// @notice Use to perform admin/maintenance ops like proxy upgrades or fund recovery.
///         The owner is immutable and set at deployment time.
contract OwnerCall {
    /// @dev Immutable owner set in the constructor.
    address public immutable owner;

    /// @dev Emitted on every successful call.
    event Executed(address indexed target, uint256 value, bytes data, bytes result);

    /// @dev Custom errors for gas-efficient reverts.
    error NotOwner();
    error ZeroTarget();
    error MsgValueMismatch();

    constructor(address _owner) {
        require(_owner != address(0), "owner=0");
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    /// @notice Execute an arbitrary call.
    /// @param target The destination address to call.
    /// @param value  The amount of ETH to send (must equal msg.value).
    /// @param data   The calldata to forward to the target.
    /// @return result Raw returned bytes from the target call.
    ///
    /// @dev Security notes:
    /// - Restricted to the immutable owner.
    /// - Bubbles up the exact revert reason from the target, if any.
    /// - Requires msg.value == value to avoid accidental mismatches.
    function execute(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable onlyOwner returns (bytes memory result) {
        if (target == address(0)) revert ZeroTarget();
        if (msg.value != value) revert MsgValueMismatch();

        (bool ok, bytes memory res) = target.call{value: value}(data);
        if (!ok) {
            // Bubble up revert reason from the target
            assembly {
                revert(add(res, 32), mload(res))
            }
        }

        emit Executed(target, value, data, res);
        return res;
    }

    /// @notice Accept ETH so the contract can hold funds if desired.
    receive() external payable {}
    fallback() external payable {}
}
