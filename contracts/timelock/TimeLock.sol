// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.13;

//  abi.encode will apply ABI encoding rules. Therefore all elementary types are padded to 32 bytes
// and dynamic arrays include their length.
//  Therefore it is possible to also decode this data again (with abi.decode) when the type are known.
//  abi.encodePacked will only use the only use the minimal required memory to encode the data.
//  E.g. an address will only use 20 bytes and for dynamic arrays only the elements will be stored without length

contract TimeLock {
    // Events
    event Queued(bytes32 txID, address _target, uint256 _amount, string _func, bytes _params, uint256 _timeStamp);

    event Executed(bytes32 txID, address _target, uint256 _amount, string _func, bytes _params, uint256 _timeStamp);

    event Cancelled(bytes32 indexed TransactionID);

    // Data Variables
    address public owner;
    mapping(bytes32 => bool) public queued;
    uint256 public constant MIN_TIME = 10;
    uint256 public constant MAX_TIME = 100;
    uint256 public constant EXTRA_TIME = 100;

    constructor() {
        owner = msg.sender;
    }

    // errors
    error NoOwnerError();
    error AlreadyQueuedTxID(bytes32 _txID);
    error TimeStampNotInRange(uint256 currentTime, uint256 timestamp);
    error TransactionNotQueuedError(bytes32 txID);
    error TimestampRemainingError(uint256 blockTimestamp, uint256 timestamp);
    error TransactionExpired(uint256 blockTimestamp, uint256 timestamp);
    error TxFailedError();

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NoOwnerError();
        }
        _;
    }

    function getTxID(
        address _target,
        uint256 _amount,
        string calldata _func,
        bytes calldata _params,
        uint256 _timeStamp
    ) public pure returns (bytes32 _txID) {
        return keccak256(abi.encode(_target, _amount, _func, _params, _timeStamp));
    }

    function Queue(
        address _target,
        uint256 _amount,
        string calldata _func,
        bytes calldata _params,
        uint256 _timeStamp
    ) external {
        // get Transaction ID

        bytes32 txID = getTxID(_target, _amount, _func, _params, _timeStamp);
        // Check Tx ID

        if (queued[txID]) {
            revert AlreadyQueuedTxID(txID);
        }
        // check TimeStamp

        if (_timeStamp < block.timestamp + MIN_TIME || _timeStamp > block.timestamp + MAX_TIME) {
            revert TimeStampNotInRange(block.timestamp, _timeStamp);
        }

        // queue tx
        queued[txID] = true;

        emit Queued(txID, _target, _amount, _func, _params, _timeStamp);
    }

    function Execute(
        address _target,
        uint256 _amount,
        string calldata _func,
        bytes calldata _params,
        uint256 _timeStamp
    ) external payable onlyOwner {
        bytes32 txID = getTxID(_target, _amount, _func, _params, _timeStamp);
        if (!queued[txID]) {
            revert TransactionNotQueuedError(txID);
        }
        if (block.timestamp < _timeStamp) {
            revert TimestampRemainingError(block.timestamp, _timeStamp);
        }

        if (block.timestamp > _timeStamp + EXTRA_TIME) {
            revert TransactionExpired(block.timestamp, _timeStamp);
        }

        queued[txID] = false;

        bytes memory data;
        if (bytes(_func).length > 0) {
            data = abi.encodePacked(bytes4(keccak256(bytes(_func))), _params);
        }

        (bool success, bytes memory response) = _target.call{ value: _amount }(_params);

        if (!success) {
            revert TxFailedError();
        }

        emit Executed(txID, _target, _amount, _func, _params, _timeStamp);
    }

    function Cancel(bytes23 _transactionID) external onlyOwner {
        if (!queued[_transactionID]) {
            revert TransactionNotQueuedError(_transactionID);
        }
        queued[_transactionID] = false;
        emit Cancelled(_transactionID);
    }
}
