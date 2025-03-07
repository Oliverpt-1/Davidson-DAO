# Davidson DAO

A simple DAO (Decentralized Autonomous Organization) for the Davidson Blockchain Club. This DAO allows token holders to create proposals, vote on them, and execute successful proposals.

## Overview

The Davidson DAO consists of three main contracts:

1. **GovernanceToken**: An ERC20 token with voting capabilities
2. **DavidsonDAO**: The main DAO contract that handles proposals and voting
3. **Box**: A contract controlled by the DAO that manages club resources

## Features

- **Token-based Governance**: Members with tokens can vote on proposals
- **Proposal Creation**: Any member with enough tokens can create a proposal
- **Voting**: Members can vote for or against proposals
- **Execution**: Successful proposals can be executed to perform actions

## Contract Details

### GovernanceToken

- ERC20 token with voting capabilities (using OpenZeppelin's ERC20Votes)
- Total supply: 1,000,000 tokens
- Allows delegation of voting power

### DavidsonDAO

- Manages proposals and voting
- Requires a minimum token threshold to create proposals (1% of total supply)
- Voting period: ~1 week (50,400 blocks with 12s block time)
- Proposals need more votes for than against to pass

### Box

- Controlled by the DAO
- Manages club resources:
  - Treasury
  - Officers
  - Projects
  - Partnerships

## How to Use

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/Davidson-DAO.git
   cd Davidson-DAO
   ```

2. Install dependencies:
   ```bash
   forge install
   ```

### Testing

Run the tests:

```bash
forge test
```

### Deployment

1. Create a `.env` file with your private key and RPC URL:
   ```
   PRIVATE_KEY=your-private-key
   RPC_URL=your-rpc-url
   ```

2. Deploy the contracts:
   ```bash
   forge script script/DeployDAO.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
   ```

## Usage Examples

### Creating a Proposal

```solidity
// Encode the function call
bytes memory callData = abi.encodeWithSelector(
    box.updateTreasury.selector,
    1000 ether
);

// Create the proposal
uint256 proposalId = dao.propose(
    "Update Treasury",
    "Set the treasury balance to 1000 ether",
    address(box),
    callData
);
```

### Voting on a Proposal

```solidity
// Vote in favor
dao.castVote(proposalId, true);

// Vote against
dao.castVote(proposalId, false);
```

### Executing a Proposal

```solidity
// Execute a successful proposal
dao.execute(proposalId);
```

## License

MIT
