// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract GreenGiraffeTracibility is Ownable, ReentrancyGuard, Pausable {
    // Custom errors
    error UnauthorizedAccess(address caller);
    error InvalidTimeRange();
    error InvalidInput();
    error InvalidBatchId();
    error InvalidYield();
    error InvalidAreaCovered();
    error InvalidDate();
    error EmptyRequiredField();
    error StringTooLong();

    // Add specific events
    event BatchCreated(
        string indexed batchId,
        string cropName,
        uint64 start,
        uint64 end,
        string farmer,
        uint32 expectedYield,
        string land,
        string status,
        uint64 timestamp
    );

    event ActivityLogCreated(
        uint256 indexed id,
        string indexed batchId,
        string activityName,
        uint64 date,
        uint32 startTime,
        uint32 endTime,
        uint32 areaCovered,
        uint64 timestamp
    );

    event SustainabilityLogCreated(
        uint256 indexed id,
        string indexed batchId,
        string practiceName,
        uint64 implementationDate,
        string impactDescription,
        uint32 areaCovered,
        uint64 timestamp
    );

    // Add these events
    event BatchUpdated(string indexed batchId, string status);
    event ActivityLogUpdated(uint256 indexed logId, uint256 indexed batchId);
    event SustainabilityLogUpdated(uint256 indexed logId, uint256 indexed batchId);

    // Optimized structs
    struct Batch {
        string cropName;
        uint64 start;
        uint64 end;
        string farmer;
        uint32 expectedYield;
        string land;
        string status;
        uint64 createdAt;
        uint64 updatedAt;
        uint64 lastIndexedAt;
        string[] history;
    }

    struct ActivityDateTime {
        uint64 date;      // UNIX timestamp for the date (midnight)
        uint8 hour;       // 0-23
        uint8 minute;     // 0-59
    }

    struct ActivityLog {
        string batchId;
        string activityName;
        ActivityDateTime start;    // Start datetime
        ActivityDateTime end;      // End datetime
        uint32 areaCovered;
        uint64 createdAt;
        uint64 updatedAt;
        string[] history;
    }

    struct SustainabilityLog {
        string batchId;
        string practiceName;
        uint64 implementationDate;
        string impactDescription;
        uint32 areaCovered;
        uint64 createdAt;
        uint64 updatedAt;
        string[] history;
    }

    // Input structs
    struct BatchInput {
        string batchId;
        string cropName;
        uint64 start;
        uint64 end;
        string farmer;
        uint32 expectedYield;
        string land;
        string status;
    }

    struct ActivityLogInput {
        string batchId;
        string activityName;
        ActivityDateTime start; 
        ActivityDateTime end;
        uint32 areaCovered;
    }

    struct SustainabilityLogInput {
        string batchId;
        string practiceName;
        uint64 implementationDate;
        string impactDescription;
        uint32 areaCovered;
    }

    // Edit input structs
    struct BatchEditInput {
        string batchId;
        string cropName;
        uint64 start;
        uint64 end;
        string farmer;
        uint32 expectedYield;
        string land;
        string status;
    }

    struct ActivityLogEditInput {
        uint256 activityLogId;
        string activityName;
        uint64 date;
        uint32 startTime;
        uint32 endTime;
        uint32 areaCovered;
    }

    struct SustainabilityLogEditInput {
        uint256 sustainabilityLogId;
        string practiceName;
        uint64 implementationDate;
        string impactDescription;
        uint32 areaCovered;
    }

    // Mappings
    mapping(string => Batch) public batches;
    mapping(uint256 => ActivityLog) public activityLogs;
    mapping(uint256 => SustainabilityLog) public sustainabilityLogs;

    // Replace Counter with a simple uint256
    uint256 private _nextId;

    mapping(address => bool) public operators;
    
    modifier onlyOperator() {
        require(operators[msg.sender] || owner() == msg.sender, "Not authorized");
        _;
    }

    constructor() Ownable(msg.sender) {}

    // Modifiers
    modifier validateBatchInput(BatchInput calldata input) {
        if(bytes(input.batchId).length == 0) revert EmptyRequiredField();
        if(bytes(input.cropName).length == 0) revert EmptyRequiredField();
        if(bytes(input.farmer).length == 0) revert EmptyRequiredField();
        if(input.start >= input.end) revert InvalidTimeRange();
        if(input.expectedYield == 0) revert InvalidYield();
        _;
    }

    modifier validateActivityInput(ActivityLogInput calldata input) {
        if(!_batchExists(input.batchId)) revert InvalidBatchId();
        if(bytes(input.activityName).length == 0) revert EmptyRequiredField();
        if(input.start.hour > 23 || input.end.hour > 23) revert InvalidTimeRange();
        
        if(input.start.minute > 59 || input.end.minute > 59) revert InvalidTimeRange();
        if(input.start.date > input.end.date) revert InvalidTimeRange();
        if(input.start.date == input.end.date) {
            if(input.start.hour > input.end.hour) revert InvalidTimeRange();
            if(input.start.hour == input.end.hour && input.start.minute >= input.end.minute) 
                revert InvalidTimeRange();
        }
        
        if(input.areaCovered == 0) revert InvalidAreaCovered();
        if(input.start.date > block.timestamp) revert InvalidDate();
        _;
    }

    modifier validateSustainabilityInput(SustainabilityLogInput calldata input) {
        if(!_batchExists(input.batchId)) revert InvalidBatchId();
        if(bytes(input.practiceName).length == 0) revert EmptyRequiredField();
        if(bytes(input.impactDescription).length == 0) revert EmptyRequiredField();
        if(input.areaCovered == 0) revert InvalidAreaCovered();
        if(input.implementationDate > block.timestamp) revert InvalidDate();
        _;
    }

    modifier validateStringLength(string memory str, uint256 maxLength) {
        require(bytes(str).length <= maxLength, "String too long");
        _;
    }

    // Internal helper functions
    function _batchExists(string memory batchId) internal view returns (bool) {
        return bytes(batches[batchId].cropName).length > 0;
    }


    // Helper function to convert string to bytes32
    function stringToBytes32(string memory str) public pure returns (bytes32) {
        bytes memory strBytes = bytes(str);
        if (strBytes.length > 32) revert StringTooLong();
        if (strBytes.length == 0) return bytes32(0);
        
        bytes32 result;
        assembly {
            result := mload(add(str, 32))
        }
        return result;
    }
    // Create functions
    function createBatch(BatchInput calldata input) 
        external 
        onlyOwner 
        nonReentrant 
        whenNotPaused 
        validateBatchInput(input) 
        returns (string memory) 
    {

        batches[input.batchId] = Batch({
            cropName: input.cropName,
            start: input.start,
            end: input.end,
            farmer: input.farmer,
            expectedYield: input.expectedYield,
            land: input.land,
            status: input.status,
            createdAt: uint64(block.timestamp),
            updatedAt: uint64(block.timestamp),
            lastIndexedAt: 0,
            history: new string[](0)
        });

        emit BatchCreated(
            input.batchId,
            input.cropName,
            input.start,
            input.end,
            input.farmer,
            input.expectedYield,
            input.land,
            input.status,
            uint64(block.timestamp)
        );
        return input.batchId;
    }

    function createActivityLog(ActivityLogInput calldata input) 
        external 
        onlyOwner 
        nonReentrant 
        validateActivityInput(input) 
        returns (uint256) 
    {
        uint256 activityLogId = _nextId++;

        activityLogs[activityLogId] = ActivityLog({
            batchId: input.batchId,
            activityName: input.activityName,
            start: input.start,
            end: input.end,
            areaCovered: input.areaCovered,
            createdAt: uint64(block.timestamp),
            updatedAt: uint64(block.timestamp),
            history: new string[](0)
        });

        emit ActivityLogCreated(activityLogId, input.batchId, input.activityName, input.start.date, input.start.hour, input.end.hour, input.areaCovered, uint64(block.timestamp));
        return activityLogId;
    }

    function createSustainabilityLog(SustainabilityLogInput calldata input) 
        external 
        onlyOwner 
        nonReentrant 
        validateSustainabilityInput(input) 
        returns (uint256) 
    {
        uint256 sustainabilityLogId = _nextId++;

        sustainabilityLogs[sustainabilityLogId] = SustainabilityLog({
            batchId: input.batchId,
            practiceName: input.practiceName,
            implementationDate: input.implementationDate,
            impactDescription: input.impactDescription,
            areaCovered: input.areaCovered,
            createdAt: uint64(block.timestamp),
            updatedAt: uint64(block.timestamp),
            history: new string[](0)
        });

        emit SustainabilityLogCreated(sustainabilityLogId, input.batchId, input.practiceName, input.implementationDate, input.impactDescription, input.areaCovered, uint64(block.timestamp));
        return sustainabilityLogId;
    }

    // Edit functions
    function editBatch(BatchEditInput calldata input) 
        external 
        onlyOwner 
        nonReentrant 
    {
        if (!_batchExists(input.batchId)) revert InvalidBatchId();
        
        Batch storage batch = batches[input.batchId];
        
        if(input.start >= input.end) revert InvalidTimeRange();
        if (bytes(input.cropName).length == 0)  revert EmptyRequiredField();
        if(input.expectedYield == 0) revert InvalidYield();

        string memory timestamp = string(abi.encodePacked("Edited at: ", uint256(block.timestamp)));
        batch.history.push(timestamp);
        batch.cropName = input.cropName;
        batch.start = input.start;
        batch.end = input.end;
        batch.expectedYield = input.expectedYield;
        batch.land = input.land;
        batch.status = input.status;
        batch.updatedAt = uint64(block.timestamp);

        emit BatchCreated(
            input.batchId,
            input.cropName,
            input.start,
            input.end,
            input.farmer,
            input.expectedYield,
            input.land,
            input.status,
            uint64(block.timestamp)
        );
    }

    function editActivityLog(ActivityLogEditInput calldata input) 
        external 
        onlyOwner 
        nonReentrant 
    {
        ActivityLog storage log = activityLogs[input.activityLogId];
        
        if(bytes(input.activityName).length == 0) revert EmptyRequiredField();
        if(input.startTime >= input.endTime) revert InvalidTimeRange();
        if(input.areaCovered == 0) revert InvalidAreaCovered();
        if(input.date > block.timestamp) revert InvalidDate();

        string memory timestamp = string(abi.encodePacked("Edited at: ", uint256(block.timestamp)));
        log.history.push(timestamp);
        log.activityName = input.activityName;
        log.start = ActivityDateTime({
            date: input.date,
            hour: uint8(input.startTime / 3600),
            minute: uint8((input.startTime % 3600) / 60)
        });
        log.end = ActivityDateTime({
            date: input.date,
            hour: uint8(input.endTime / 3600),
            minute: uint8((input.endTime % 3600) / 60)
        });
        log.areaCovered = input.areaCovered;
        log.updatedAt = uint64(block.timestamp);

        emit ActivityLogCreated(input.activityLogId, log.batchId, input.activityName, input.date, input.startTime, input.endTime, input.areaCovered, uint64(block.timestamp));
    }

    function editSustainabilityLog(SustainabilityLogEditInput calldata input) 
        external 
        onlyOwner 
        nonReentrant 
    {
        SustainabilityLog storage log = sustainabilityLogs[input.sustainabilityLogId];
        if (bytes(input.practiceName).length == 0)  revert EmptyRequiredField();
        if (bytes(input.impactDescription).length == 0)  revert EmptyRequiredField();
        if(input.areaCovered == 0) revert InvalidAreaCovered();
        if(input.implementationDate > block.timestamp) revert InvalidDate();

        string memory timestamp = string(abi.encodePacked("Edited at: ", uint256(block.timestamp)));
        log.history.push(timestamp);
        log.practiceName = input.practiceName;
        log.implementationDate = input.implementationDate;
        log.impactDescription = input.impactDescription;
        log.areaCovered = input.areaCovered;
        log.updatedAt = uint64(block.timestamp);

        emit SustainabilityLogCreated(input.sustainabilityLogId, log.batchId, input.practiceName, input.implementationDate, input.impactDescription, input.areaCovered, uint64(block.timestamp));
    }

    // View functions
    function getBatchHistory(string memory batchId) external view returns (string[] memory) {
        if (!_batchExists(batchId)) revert InvalidBatchId();
        return batches[batchId].history;
    }

    function getActivityLogHistory(uint256 activityLogId) external view returns (string[] memory) {
        return activityLogs[activityLogId].history;
    }

    function getSustainabilityLogHistory(uint256 sustainabilityLogId) external view returns (string[] memory) {
        return sustainabilityLogs[sustainabilityLogId].history;
    }

    function deactivateBatch(string memory batchId) 
        external 
        onlyOwner 
        nonReentrant 
    {
        if (!_batchExists(batchId)) revert InvalidBatchId();
        batches[batchId].status = "Cancelled";
        emit BatchUpdated(batchId, "Cancelled");
    }

    function setOperator(address operator, bool status) external onlyOwner {
        operators[operator] = status;
        emit OperatorUpdated(operator, status);
    }

    event OperatorUpdated(address indexed operator, bool status);

    function pause() external onlyOperator {
        _pause();
    }

    function unpause() external onlyOperator {
        _unpause();
    }
}


