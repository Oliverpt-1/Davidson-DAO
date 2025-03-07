# 🏛️ Davidson DAO

![Davidson DAO Banner](https://www.davidson.edu/sites/default/files/styles/max_650x650/public/2023-08/Primary-Lockup-NewsStory.png?itok=BJeJoK6D)

### NOTE - This is the preemptive DAO I have built with plans to start Davidson's blockchain club this year.  It is still in early development and is NOT runnable.

## Vision

The Davidson DAO serves as the central governance mechanism for the Davidson Blockchain Club, empowering members to participate in decision-making processes and shape the future of our community.

---

## 🎯 Purpose

- **Decentralized Governance**: Enable fair and transparent decision-making
- **Financial Management**: Oversee and allocate club resources
- **Project Prioritization**: Vote on which initiatives to pursue
- **Member Empowerment**: Give every member a voice in club operations

---

## 🛠️ Key Features

| Feature | Description |
|---------|-------------|
| 💼 Proposal Submission | Any member can submit proposals for consideration |
| 🗳️ Voting System | Secure and transparent voting on all major decisions |
| 📊 Fund Allocation | Democratic distribution of club funds |
| 🔗 On-Chain Governance | All decisions recorded on the blockchain for transparency |

---

## 📋 Technical Overview

The Davidson DAO is built using Solidity smart contracts and follows the OpenZeppelin Governor framework. It consists of the following components:

1. **GovernanceToken**: An ERC20Votes token that allows token holders to vote on proposals
2. **GovernorContract**: The main governance contract that handles proposals, voting, and execution
3. **Timelock**: A delay mechanism to ensure proposals are not executed immediately
4. **Box**: The contract controlled by the DAO that manages club resources and operations

---

## 🚀 Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [Node.js](https://nodejs.org/en/download/)
- [Yarn](https://yarnpkg.com/getting-started/install)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-username/Davidson-DAO.git
   cd Davidson-DAO
   ```

2. Install dependencies:
   ```bash
   yarn install
   ```

3. Install Foundry dependencies:
   ```bash
   forge install OpenZeppelin/openzeppelin-contracts
   ```

### Testing

Run the test suite using Foundry:

```bash
forge test
```

### Deployment

1. Deploy the DAO:
   ```bash
   forge script scripts/DeployDAO.s.sol --rpc-url <your-rpc-url> --private-key <your-private-key> --broadcast
   ```

## 🧠 How the DAO Works

### 1. Token Distribution

The governance token is initially minted to the deployer, who can distribute it to club members. Each token represents voting power in the DAO.

### 2. Proposal Creation

Any token holder can create a proposal to:
- Update the treasury
- Elect club officers
- Create and fund projects
- Form partnerships

### 3. Voting Process

1. **Proposal Creation**: A proposal is submitted with specific actions to be executed
2. **Voting Delay**: A short delay before voting begins (1 block)
3. **Voting Period**: Members vote on the proposal (approximately 1 week)
4. **Quorum**: At least 4% of the total token supply must vote for the proposal to be valid
5. **Queue**: If approved, the proposal is queued in the timelock
6. **Timelock Delay**: A delay before execution (1 hour)
7. **Execution**: The proposal is executed, and the actions are performed

### 4. Club Operations

The Box contract manages:
- Treasury funds
- Club officers and their terms
- Projects and their funding
- Partnerships with other organizations

---

## 📅 Upcoming Votes

- [x] Club logo redesign
- [ ] Fall semester budget allocation
- [ ] New project selection for Q4

---

## 📬 Contact

- **Email**: dao@davidsonblockchain.edu
- **Discord**: [Join our server](https://discord.gg/davidsonblockchain)
- **Twitter**: [@DavidsonDAO](https://twitter.com/DavidsonDAO)

---

<p align="center">
  <i>Empowering the future of blockchain education, one vote at a time.</i>
</p>
