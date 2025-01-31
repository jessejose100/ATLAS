# ATLAS - Advanced Token with Layered Administration System

A sophisticated fungible token implementation in Clarity featuring governance controls and vesting capabilities. This contract provides a robust foundation for creating tokens with advanced functionality including operator approval and token vesting schedules.

## Features

- **Fungible Token Implementation**: Core fungible token functionality with minting and transfer capabilities
- **Operator Management**: Delegation system allowing approved operators to transfer tokens on behalf of owners
- **Token Vesting**: Configurable vesting schedules with cliff periods and gradual vesting
- **Governance Controls**: Owner-restricted administrative functions for contract management
- **Initialization Parameters**: Configurable token name, symbol, and decimal places

## Contract Architecture

### Constants

- `contract-owner`: The principal who deployed the contract
- `err-owner-only`: Error code for unauthorized owner actions (u100)
- `err-insufficient-balance`: Error code for insufficient token balance (u101)
- `err-invalid-amount`: Error code for invalid token amounts (u102)
- `err-unauthorized`: Error code for unauthorized operations (u103)
- `err-already-initialized`: Error code for repeated initialization attempts (u104)

### Data Storage

- **Token Metadata**
  - `total-supply`: Total token supply tracker
  - `initialized`: Contract initialization status
  - `token-name`: Token name (UTF-8 string, max 32 characters)
  - `token-symbol`: Token symbol (UTF-8 string, max 10 characters)
  - `token-decimals`: Token decimal places

- **Maps**
  - `allowed-operators`: Tracks operator approvals for token transfers
  - `vesting-schedules`: Stores vesting configuration for beneficiaries

## Public Functions

### Administrative Functions

```clarity
(initialize (name (string-utf8 32)) (symbol (string-utf8 10)) (decimals uint))
```
Initializes the token contract with basic parameters. Can only be called once by the contract owner.

```clarity
(mint (amount uint) (recipient principal))
```
Creates new tokens and assigns them to the specified recipient. Restricted to contract owner.

### Token Operations

```clarity
(transfer (amount uint) (sender principal) (recipient principal))
```
Transfers tokens between accounts. Can be called by the token owner or approved operators.

```clarity
(approve-operator (operator principal))
```
Grants transfer approval to an operator for the sender's tokens.

```clarity
(revoke-operator (operator principal))
```
Revokes previously granted operator approval.

### Vesting Management

```clarity
(create-vesting-schedule (beneficiary principal) (amount uint) (duration uint) (cliff-duration uint))
```
Creates a new vesting schedule for a beneficiary. Parameters:
- `beneficiary`: Address receiving the vested tokens
- `amount`: Total amount of tokens to vest
- `duration`: Total vesting duration in blocks
- `cliff-duration`: Initial period before vesting begins (in blocks)

```clarity
(release-vested-tokens (beneficiary principal))
```
Releases available vested tokens to the beneficiary based on the current block height.

## Error Codes

- `u100`: Unauthorized attempt to call owner-only function
- `u101`: Insufficient balance for transfer
- `u102`: Invalid token amount specified
- `u103`: Unauthorized operator action
- `u104`: Contract already initialized
- `u105`: Invalid vesting schedule parameters
- `u106`: Vesting schedule not found
- `u107`: No new tokens available for release

## Usage Examples

### Initializing the Token

```clarity
(contract-call? .advanced-token initialize "Advanced Token" "ADV" u6)
```

### Creating a Vesting Schedule

```clarity
;; Create a 1-year vesting schedule with 3-month cliff
(contract-call? .advanced-token create-vesting-schedule 
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7 
    u1000000 
    u52560    ;; ~1 year in blocks
    u13140)   ;; ~3 months in blocks
```

### Releasing Vested Tokens

```clarity
(contract-call? .advanced-token release-vested-tokens 
    'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

## Security Considerations

1. Only the contract owner can mint tokens and create vesting schedules
2. Vesting schedules cannot be modified once created
3. Token transfers require either direct owner authorization or operator approval
4. Mathematical operations use safe arithmetic to prevent overflow/underflow
5. Vesting releases are calculated based on block height for deterministic execution

## Development and Testing

To deploy and test this contract:

1. Ensure you have a Clarity development environment set up
2. Deploy the contract to your chosen network
3. Initialize the contract with desired parameters
4. Test all functionality, particularly:
   - Basic token operations
   - Operator approval system
   - Vesting schedule creation and release
   - Error conditions and access controls
