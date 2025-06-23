# Healthcare Insurance Management Smart Contract

A decentralized healthcare insurance management system built on the Stacks blockchain. This smart contract provides comprehensive functionality for managing health insurance policies, processing medical claims, and maintaining transparent records of all insurance operations.

## Features

- **Policy Management**: Register and manage comprehensive health insurance policies
- **Claims Processing**: Submit, review, and process medical claims with full audit trails
- **Administrative Controls**: Secure administrative functions with proper access control
- **Transparent Operations**: All insurance operations are recorded on-chain for transparency
- **Status Tracking**: Real-time tracking of policy and claim statuses

## Contract Overview

### Core Functionality

1. **Policy Registration**: Policyholders can register new insurance policies with coverage limits and premium costs
2. **Claims Submission**: Submit medical claims linked to registered policies
3. **Claims Processing**: Administrators can review, approve, reject, or request additional information for claims
4. **Policy Administration**: Manage policy activation status, coverage limits, and termination schedules

### Key Components

- **Insurance Policy Registry**: Stores all active and inactive insurance policies
- **Medical Claims Database**: Comprehensive database of all submitted medical claims
- **Policy Identifier Ownership**: Ensures unique policy identifiers
- **Administrative Controls**: Secure functions for contract administration

## Data Structures

### Insurance Policy
```clarity
{
  unique-policy-identifier: (string-ascii 20),
  maximum-coverage-limit: uint,
  annual-premium-cost: uint,
  policy-activation-status: bool,
  policy-registration-block: uint,
  policy-termination-block: (optional uint)
}
```

### Medical Claim
```clarity
{
  policy-holder-address: principal,
  associated-policy-identifier: (string-ascii 20),
  requested-claim-amount: uint,
  medical-treatment-description: (string-ascii 50),
  current-processing-status: (string-ascii 15),
  claim-submission-timestamp: uint,
  claim-resolution-timestamp: (optional uint),
  administrative-notes: (optional (string-ascii 100))
}
```

## Claim Status Types

- `pending-review`: Initial status when claim is submitted
- `approved`: Claim has been approved for payment
- `rejected`: Claim has been rejected
- `needs-info`: Additional documentation required
- `investigating`: Claim is under investigation

## Public Functions

### For Policyholders

#### `register-comprehensive-insurance-policy`
Register a new health insurance policy.

**Parameters:**
- `unique-policy-identifier` (string-ascii 20): Unique identifier for the policy
- `maximum-coverage-limit` (uint): Maximum coverage amount
- `annual-premium-cost` (uint): Annual premium cost

**Example:**
```clarity
(contract-call? .healthcare-insurance register-comprehensive-insurance-policy "POLICY-12345" u50000 u2400)
```

#### `submit-comprehensive-medical-claim`
Submit a medical claim for processing.

**Parameters:**
- `associated-policy-identifier` (string-ascii 20): Policy identifier
- `requested-claim-amount` (uint): Claim amount in micro-STX
- `medical-treatment-description` (string-ascii 50): Description of medical treatment

**Example:**
```clarity
(contract-call? .healthcare-insurance submit-comprehensive-medical-claim "POLICY-12345" u1500 "Emergency room visit for chest pain")
```

### For Administrators

#### `process-medical-claim-resolution`
Process and finalize a submitted medical claim.

**Parameters:**
- `claim-reference-number` (uint): Unique claim reference number
- `final-processing-status` (string-ascii 15): Final status (approved/rejected/needs-info/investigating)
- `administrative-processing-notes` (optional string-ascii 100): Processing notes

#### `transfer-administrative-control`
Transfer administrative control to a new principal.

**Parameters:**
- `new-admin-address` (principal): New administrator address

#### `modify-policy-activation-status`
Change the activation status of a policy.

**Parameters:**
- `policy-holder-address` (principal): Policy holder's address
- `new-activation-status` (bool): New activation status

#### `update-policy-coverage-limit`
Update the maximum coverage limit for a policy.

**Parameters:**
- `policy-holder-address` (principal): Policy holder's address
- `new-coverage-limit` (uint): New coverage limit

#### `schedule-policy-termination`
Set a termination block for policy expiration.

**Parameters:**
- `policy-holder-address` (principal): Policy holder's address
- `termination-block` (uint): Block height for termination

## Read-Only Functions

### Query Functions

- `get-policy-information(policy-holder-address)`: Retrieve policy details
- `get-medical-claim-details(claim-reference-number)`: Get claim information
- `get-current-claim-status(claim-reference-number)`: Check claim status
- `verify-admin-privileges()`: Check if caller is admin
- `check-policy-identifier-availability(unique-policy-identifier)`: Check if policy ID is available

### Validation Functions

- `validate-policy-existence(policy-holder-address)`: Verify policy exists
- `validate-claim-existence(claim-reference-number)`: Verify claim exists
- `verify-policy-active-status(policy-holder-address)`: Check if policy is active

### Statistics Functions

- `get-total-submitted-claims()`: Get total number of claims
- `get-next-claim-reference()`: Get next available claim reference number

## Error Codes

### Access Control Errors (100-109)
- `u100`: Unauthorized access
- `u101`: Invalid admin credentials
- `u102`: Admin transfer failed

### Policy Management Errors (110-119)
- `u110`: Policy not found
- `u111`: Policy already expired
- `u112`: Duplicate policy registration
- `u113`: Insufficient coverage amount
- `u114`: Policy currently inactive

### Claims Processing Errors (120-129)
- `u120`: Claim record not found
- `u121`: Claim exceeds coverage limit
- `u122`: Invalid claim status transition
- `u123`: Claim already finalized
- `u124`: Claim amount insufficient

### Input Validation Errors (130-139)
- `u130`: Invalid input parameters
- `u131`: Zero value not permitted
- `u132`: Invalid block height
- `u133`: Invalid string length

## Security Features

- **Access Control**: Administrative functions require proper authorization
- **Input Validation**: All inputs are validated before processing
- **Policy Validation**: Claims are validated against active policies
- **Coverage Limits**: Claims cannot exceed policy coverage limits
- **Unique Identifiers**: Policy identifiers must be unique
- **Expiration Checks**: Expired policies cannot process new claims

## Deployment

1. Deploy the contract to the Stacks blockchain
2. The deployer becomes the initial contract administrator
3. Register insurance policies using `register-comprehensive-insurance-policy`
4. Submit claims using `submit-comprehensive-medical-claim`
5. Process claims using administrative functions

## Usage Examples

### Registering a Policy
```clarity
;; Register a new policy with $50,000 coverage and $2,400 annual premium
(contract-call? .healthcare-insurance 
  register-comprehensive-insurance-policy 
  "HEALTH-POLICY-001" 
  u5000000 ;; 50,000 STX in micro-STX
  u240000  ;; 2,400 STX in micro-STX
)
```

### Submitting a Claim
```clarity
;; Submit a claim for $1,500 for an emergency room visit
(contract-call? .healthcare-insurance 
  submit-comprehensive-medical-claim 
  "HEALTH-POLICY-001" 
  u150000 ;; 1,500 STX in micro-STX
  "Emergency room visit - chest pain evaluation"
)
```

### Processing a Claim (Admin Only)
```clarity
;; Approve a claim
(contract-call? .healthcare-insurance 
  process-medical-claim-resolution 
  u0 ;; claim reference number
  "approved"
  (some "Claim approved after medical review")
)
```