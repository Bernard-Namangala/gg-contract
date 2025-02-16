# Green Giraffe Tracibility Smart Contract

This repository contains a blockchain-based traceability system for agricultural operations, implemented as a smart contract. The system allows tracking of crop batches, farming activities, and sustainability practices.

## Contract Overview

The GreenGiraffeTracibility contract is a comprehensive system that implements:

- Batch management for crops
- Activity logging for farming operations
- Sustainability practice tracking
- Access control with owner and operator roles
- Protection against reentrancy attacks
- Pausable functionality for emergency situations

### Key Features

1. **Batch Management**

   - Create and track crop batches with detailed information
   - Record crop name, farming period, farmer details, expected yield
   - Maintain status and history of each batch
   - Deactivation capability for batches

2. **Activity Logging**

   - Track farming activities with precise datetime information
   - Record area covered and activity details
   - Maintain historical records of all activities

3. **Sustainability Tracking**

   - Log sustainability practices
   - Track implementation dates and impact descriptions
   - Monitor area coverage for sustainable practices

4. **Security Features**
   - Reentrancy protection
   - Role-based access control (Owner and Operators)
   - Pausable functionality for emergency situations
   - Input validation and error handling

### Data Structures

The contract uses three main data structures:

1. **Batch**

   ```solidity
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
   ```

2. **Activity Log**

   ```solidity
   struct ActivityLog {
       string batchId;
       string activityName;
       ActivityDateTime start;
       ActivityDateTime end;
       uint32 areaCovered;
       uint64 createdAt;
       uint64 updatedAt;
       string[] history;
   }
   ```

3. **Sustainability Log**
   ```solidity
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
   ```

### Main Functions

1. **Batch Operations**

   - `createBatch()`: Create new crop batches
   - `editBatch()`: Modify existing batch details
   - `deactivateBatch()`: Deactivate a batch
   - `getBatchHistory()`: Retrieve batch history

2. **Activity Operations**

   - `createActivityLog()`: Record farming activities
   - `editActivityLog()`: Update activity records
   - `getActivityLogHistory()`: Retrieve activity history

3. **Sustainability Operations**

   - `createSustainabilityLog()`: Record sustainability practices
   - `editSustainabilityLog()`: Update sustainability records
   - `getSustainabilityLogHistory()`: Retrieve sustainability history

4. **Administrative Functions**
   - `setOperator()`: Manage operator access
   - `pause()`: Pause contract operations
   - `unpause()`: Resume contract operations

## Security Considerations

The contract implements several security measures:

- OpenZeppelin's `Ownable`, `ReentrancyGuard`, and `Pausable` contracts
- Custom error handling for better gas efficiency
- Input validation for all operations
- Role-based access control
- History tracking for all modifications

## Events

The contract emits events for all major operations:

- `BatchCreated`
- `ActivityLogCreated`
- `SustainabilityLogCreated`
- `BatchUpdated`
- `ActivityLogUpdated`
- `SustainabilityLogUpdated`
- `OperatorUpdated`

## License

This project is licensed under the MIT License.
