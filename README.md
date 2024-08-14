## Staker Contract

**The Staker contract is a flexible staking solution that allows users to stake various ERC-20 tokens with different notice periods. It supports two types of stake tokens: one with a 1-week notice period and another with a 4-week notice period.**

Features:

- Stake any whitelisted ERC-20 token
- Two notice periods: 1 week and 4 weeks
- 5% annual interest rate on staked tokens
- Withdrawal requests with notice periods
- Admin yield deposits
- Pausable functionality
- Token whitelisting


## Usage
- Owner can Whitelist staking tokens using updateTokenWhitelistStatus.
- Users can stake tokens using deposit with a specific notice period and earn stake tokens (St4wToken, St1wToken).
- Users earn 5% fixed interest as long as they hold the tokens.
- Users can transfer and use the stake tokens like any other ERC-20 tokens.
- Users can stake multiple ERC20 tokens with different notice periods.
- Users can request withdrawals using requestWithdraw with a specific notice period.
- If users have enough notice period tokens at the time of withdrawal, the contract burns the tokens. 
- Users will stop earning interest once they request withdrawal. 
- After the notice period, users can claim their tokens and yield using claim.
- Admin can deposit yield using adminYieldDeposit.
- Users are able to check their balance.

## Security Considerations
- The contract uses OpenZeppelin's SafeERC20 for safe token transfers
- Only whitelisted tokens can be staked
- The contract is pausable for emergency situations
- Only the owner can perform administrative functions

## Possible Improvements
- The interest rate can vary depending on the notice period, with longer notice periods potentially offering higher rates.
- The code is designed to be scalable, allowing for dynamic notice periods with minimal adjustments to the code, rather than being limited to two fixed notice periods.
- Currently, when a user deposits any ERC20 token, the contract issues an equivalent amount of notice period tokens. However, since different ERC20 tokens have varying market values, users could exploit the system by depositing large quantities of low-value tokens to receive more notice period tokens compared to users who deposit fewer high-value tokens. This could lead to higher profits on other platforms that accept these notice period tokens. A potential solution is to implement a system where each whitelisted token has its own exchange rate to the notice period tokens.

## Dependencies
- OpenZeppelin Contracts (SafeERC20, IERC20, Pausable, Ownable)
- Custom St1wToken and St4wToken contracts

## License
This project is licensed under the MIT License.

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test  --match-path test/Staker.t.sol -vvv
$ forge test --fork-url < Mainnet URL endpont > --match-path test/Staker.fork.t.sol -vvv
```


