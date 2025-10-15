# Compose

Forget everything you know about designing and organizing smart contracts -- because Compose is different.

We are building a high quality smart contract library by banning Solidity functionality and consistently following conventions and design principles that are oriented to smart contracts.

We are breaking existing software development rules in order to write good software specifically for smart contracts. This is smart contract oriented programming.

## Banned Solidity Features

None of the following features in the Solidity programming language are allowed to be used in this smart contract library. Anyone submitting a pull request that uses any of these features will be fined **$100 USDC**.

Endless discussion about what and why Solidity features should or shouldn't be allowed in this library is *encouraged*.

It isn't that any of these features are bad, that isn't the point. It is that we are writing the best software we can, and part of that is using a limited feature set. This is the "less is more" idea or keep it simple stupid (KISS).

If this feature ban breaks your mind, just realize that this smart contract library is different than what you have encountered before -- it has different importances, different design principles and it has different ways of doing things. Open your mind and be willing to look at smart contracts a different way. Let the design section rewrite your brain.

1. ### Inheritance is **banned**.
   
   No contract may inherit any other contract or interface. For example `MyContract is OtherContract` or `MyContract is IMyInterface` etc. is not allowed.

2. ### No constructor functions

   No contracts other than a diamond contract (proxy contract), may have a constructor function. For example: `constructor() {owner = msg.sender; }` etc.

3. ### No modifiers

   No contract may use modifiers. For example: `modifier onlyOwner() { require(msg.sender == owner, "Caller is not the owner"); _; }` etc.

4. ### No public or private or internal variables

   No contract or library may have variables declared private or public or internal. For example: `uint256 public counter;`. These visibility labels are not needed because the library uses ERC-8042 Diamond Storage through out.

5. ### No private functions

   No contract or library may have a function declared private. For example: `function approve(address _spender, uint256 _value) private { ...`. This means all functions in contracts must be delcared `internal` or `external`.

6. ### No external functions in Solidity libraries

   No Solidity library may have any external functions. For example: `function name() external view returns (string memory)`. All functions in Solidity libraries must be delcared `internal`.

7. ### No `using for` in Solidity libraries

   No Solidity library may use the `using` directive. For example: `using LibSomething for uint`.

8. ### No `selfdestruct`.

   No contract or libary may use `selfdestruct`.

Other Solidity features will likely be added to this ban list.

Note that the feature ban applies to the smart contracts and libraries within Compose. It does not apply to the users that use Compose. Users can do what they want to do and it is our job to help them.




## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
