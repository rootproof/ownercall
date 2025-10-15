# ownercall

A minimal Solidity contract for owner-gated arbitrary calls — useful for upgrading proxies, recovering assets, or performing controlled maintenance.

## ⚙️ Overview

`OwnerCall` is a tiny contract that:

- Sets an **immutable owner** at deployment.
- Exposes a single function, `execute`, gated by the owner.
- Can perform arbitrary calls with optional ETH value.

### Typical uses

- Upgrade a proxy contract (`Transparent` / `UUPS`)
- Recover lost ERC20 or ETH
- Admin maintenance / migration scripts

## 🧩 Contract

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract OwnerCall {
    address public immutable owner;
    event Executed(address indexed target, uint256 value, bytes data, bytes result);
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

    function execute(address target, uint256 value, bytes calldata data)
        external
        payable
        onlyOwner
        returns (bytes memory result)
    {
        if (target == address(0)) revert ZeroTarget();
        if (msg.value != value) revert MsgValueMismatch();
        (bool ok, bytes memory res) = target.call{value: value}(data);
        if (!ok) assembly { revert(add(res, 32), mload(res)) }
        emit Executed(target, value, data, res);
        return res;
    }

    receive() external payable {}
    fallback() external payable {}
}
````

## 🚀 Deploy

**Using Foundry:**

```bash
forge create --rpc-url <RPC_URL> --private-key <PK> src/OwnerCall.sol:OwnerCall --constructor-args <OWNER_ADDRESS>
```

**Using Hardhat:**

```js
await ethers.deployContract("OwnerCall", [owner]);
```

## 🔒 Notes

* The owner is immutable; cannot be changed.
* Always double-check calldata and `value` before executing.
* Gas usage is minimal; no dependencies.

## 🧠 License

MIT — free to use, fork, or build upon.



