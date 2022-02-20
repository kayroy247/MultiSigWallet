//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import "hardhat/console.sol";

/// @title A basic Multisig wallet
/// @author Kayode Okunlade
/// @notice For testing multisig wallet and security
/// @dev All functions tested
contract MultiSig {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredApprovals;
    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    struct Transaction {
        // to is the address of where the transaction is executed.
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Multisig: Not owner");
        _;
    }
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Multisig: Tx does not exist");
        _;
    }
    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "Multisig: Approed already");
        _;
    }
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Multisig: Executed already");
        _;
    }

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Multisig: Owners Required");
        require(
            _required > 0 && _required <= _owners.length,
            "Multisig: Invalid owner numbers"
        );

        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Multisig: Invalid owner");
            require(!isOwner[owner], "Multisig: owner is not unique");
            isOwner[owner] = true;
            owners.push(owner);
        }
        requiredApprovals = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, executed: false})
        );
        emit Submit(transactions.length - 1);
    }

    function approve(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function getApprovalCount(uint256 _txId)
        private
        view
        returns (uint256 count)
    {
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint256 _txId)
        external
        txExists(_txId)
        notExecuted(_txId)
    {
        require(
            getApprovalCount(_txId) >= requiredApprovals,
            "Multisig: Not enough approvals"
        );

        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        require(success, "Multisig: Tx execution failed");
        emit Execute(_txId);
    }

    function revoke(uint256 _txId)
        external
        onlyOwner
        notExecuted(_txId)
        txExists(_txId)
    {
        require(approved[_txId][msg.sender], "Multisig: Not Approved");
        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}
