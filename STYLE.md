# Compose Coding Style Guide

This style guide documents the coding conventions required for all Compose code. All contributors must follow these rules to ensure consistency and readability.

## 1. Naming Conventions
- **Parameter Names:** All parameters for events, errors, and functions must be preceded with an underscore (`_`).
  - Example:
    ```solidity
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    error ERC20InvalidSender(address _sender);
    function transfer(address _to, uint256 _amount) external {}
    ```
- **Camel Case:** Use camelCase for variable, function, contract, and library names, except for standard uppercase abbreviations (e.g., ERC).
  - Example: `totalSupply`, `LibERC20`, `ERC721Facet`

## 2. Control Structures
- **Brackets Required:** One-line `if` statements without code block brackets `{}` are not allowed. Always use a newline and brackets.
  - Example:
    ```solidity
    // Bad
    if (x > 0) return;
    // Good
    if (x > 0) {
        return;
    }
    ```

## 3. Internal Functions
- **Facets:** Internal function names in facets should be prefixed with `internal` if they otherwise have the same name as an external function in the same facet. Usually should be few or no internal functions in facets; repeat code if it improves readability.
- **Libraries:** All functions in libraries use the `internal` visibility specifier. 

## 4. Value Resetting
- Use `delete` to set a value to zero.
  - Example:
    ```solidity
    delete balances[_owner];
    ```

## 5. Formatting
- Format code using the default settings of `forge fmt`. Run `forge fmt` before submitting code.

## 6. References and Examples
- For more examples, see:
  - [`src/token/ERC721/ERC721/ERC721Facet.sol`](src/token/ERC721/ERC721/ERC721Facet.sol)
  - [`src/token/ERC721/ERC721/LibERC721.sol`](src/token/ERC721/ERC721/LibERC721.sol)

## 7. Additional Rules
- More rules may be derived from the above example files. When in doubt, follow the patterns established in those files.

---

**All contributors must follow this style guide.**
