# How To Use Proxy contracts & large contract chunking (Minimal Example)

Below is a summary of how to use proxies and chunking in Sway.

**Proxies** refer to a blockchain design pattern that enables contract upgrades by forwarding calls made to the proxy contract to an implementation contract without changing the contract's address or state. On Fuel a proxy contract executes instructions from another contract while retaining it's own storage context.

**Chunking** addresses the issue of deploying contracts that exceed Sway's 100KB contract size limit. It splits the oversized contract into multiple blobs and uses a loader contract. When the loader contract is called upon, it automatically loads the blobs into memory, allowing the contract to function as normal.

Both features are abstracted from developers and work out of the box with the latest version of `forc`. Below is a reference on how to use `Proxies`, `Chunking`, and how to combine them.

## Prerequisites

If you already have `fuelup` installed, run the commands below to make sure you are on the most up-to-date toolchain.

```sh
fuelup self update
fuelup update
fuelup default latest
```

At the time of writing you should be on `v0.63.5` or above

```sh
fuelup show
```

The command above should yield a similar output below

```sh
active toolchain
----------------
latest-aarch64-apple-darwin (default)
  forc : 0.63.5
    - forc-client
      - forc-deploy : 0.63.5
      - forc-run : 0.63.5
    - forc-crypto : 0.63.5
    - forc-debug : 0.63.5
    - forc-doc : 0.63.5
    - forc-fmt : 0.63.5
    - forc-lsp : 0.63.5
    - forc-tx : 0.63.5
    - forc-wallet : 0.9.0
  fuel-core : 0.34.0
  fuel-core-keygen : 0.34.0

fuels versions
--------------
forc : 0.66.1
forc-wallet : 0.66.0
```

## Proxy

> Note: Please refer to [using the Proxy](#using-the-proxy) section to safely incoporate proxies into your project.
 
We recommend implementing the SRC-14 standard via , as they are designed to help you avoid potential issues such as storage collisions and access control concerns. The SRC-14 standard itself, along with the examples in the sway-standards repository, are intended for educational purposes, and direct usage in production environments isn't advised for these reasons.

#### [SRC-14 Simple Upgradeable Proxies](https://docs.fuel.network/docs/sway-standards/src-14-simple-upgradeable-proxies/)

The SRC-14 standard is similar to upgradeable proxies in Ethereum like [UUPS](https://eips.ethereum.org/EIPS/eip-1822), where an implementation/target contract is stored in storage of the proxy contract and all calls are delegated to it. Unlike in [UUPS](https://eips.ethereum.org/EIPS/eip-1822), this standard requires that the upgrade function is part of the proxy and not its target. This prevents irrecoverable updates if a proxy is made to point to another proxy and no longer has access to upgrade logic.

In FuelVM, this behavior is implemented using the `LDC` instruction, which Sway's `std::execution::run_external` leverages to mimic EVM's `delegatecall`, allowing execution of instructions from another contract while retaining the original contract's storage context.

Essential functions to note are `set_proxy_target(new_target: ContractId)` and `proxy_target()` as mentioned above.

```sway
abi SRC14 {
    #[storage(read, write)]
    fn set_proxy_target(new_target: ContractId);
    #[storage(read)]
    fn proxy_target() -> Option<ContractId>;
}
 
abi SRC14Extension {
    #[storage(read)]
    fn proxy_owner() -> State;
}
```

#### [Upgradable Libraries](https://docs.fuel.network/docs/sway-libs/upgradability/)

To use the SRC-14 standard along with the upgradability library, you simply need to import the necessary modules as shown below:

```sway
use sway_libs::upgradability::*;
use standards::{src14::*, src5::*};
```

With these imports, your implementation file will look like this

```sway
use sway_libs::upgradability::{_proxy_owner, _proxy_target, _set_proxy_target};
use standards::{src14::{SRC14, SRC14Extension}, src5::State};
 
#[namespace(SRC14)]
storage {
    // target is at sha256("storage_SRC14_0")
    target: Option<ContractId> = None,
    proxy_owner: State = State::Uninitialized,
}
 
impl SRC14 for Contract {
    #[storage(read, write)]
    fn set_proxy_target(new_target: ContractId) {
        _set_proxy_target(new_target);
    }
 
    #[storage(read)]
    fn proxy_target() -> Option<ContractId> {
        _proxy_target()
    }
}
 
impl SRC14Extension for Contract {
    #[storage(read)]
    fn proxy_owner() -> State {
        _proxy_owner(storage.proxy_owner)
    }
}
```

The [owned proxy implementation](https://github.com/FuelLabs/sway-standard-implementations/tree/master/src14/owned_proxy) extends the SRC-14 standard and includes initialization functionality to ensure secure ownership upon deployment. This contract is precompiled and utilized in the `forc` deploy proxy feature.

```sway
impl OwnedProxy for Contract {
    /// Initializes the proxy contract.
    ///
    /// # Additional Information
    ///
    /// This method sets the storage values using the values of the configurable constants `INITIAL_TARGET` and `INITIAL_OWNER`.
    /// This then allows methods that write to storage to be called.
    /// This method can only be called once.
    ///
    /// # Reverts
    ///
    /// * When `storage.proxy_owner` is not [State::Uninitialized].
    ///
    /// # Number of Storage Accesses
    ///
    /// * Writes: `2`
    #[storage(write)]
    fn initialize_proxy() {
        require(
            _proxy_owner(storage.proxy_owner) == State::Uninitialized,
            InitializationError::CannotReinitialized,
        );

        storage.target.write(INITIAL_TARGET);
        storage.proxy_owner.write(INITIAL_OWNER);
    }

    /// Changes proxy ownership to the passed State.
    ///
    /// # Additional Information
    ///
    /// This method can be used to transfer ownership between Identities or to revoke ownership.
    ///
    /// # Arguments
    ///
    /// * `new_proxy_owner`: [State] - The new state of the proxy ownership.
    ///
    /// # Reverts
    ///
    /// * When the sender is not the current proxy owner.
    /// * When the new state of the proxy ownership is [State::Uninitialized].
    ///
    /// # Number of Storage Accesses
    ///
    /// * Reads: `1`
    /// * Writes: `1`
    #[storage(write)]
    fn set_proxy_owner(new_proxy_owner: State) {
        _set_proxy_owner(new_proxy_owner, storage.proxy_owner);
    }
}
```

The library assumes the `proxy_owner` will be stored at `sha256("storage_SRC14_1")`

```sway
/// The storage slot to store the proxy owner's state.
///
/// The value is `sha256("storage_SRC14_1")`.
pub const PROXY_OWNER_STORAGE: b256 = 0xbb79927b15d9259ea316f2ecb2297d6cc8851888a98278c0a2e03e1a091ea754;
```

Therefore, any proxy contract using this library and following the SRC-14 standard should set up the storage values for `target` and `proxy_owner` as follows:

```sway
storage {
    SRC14 {
        /// The [ContractId] of the target contract.
        ///
        /// # Additional Information
        ///
        /// The `target` is stored at `sha256("storage_SRC14_0")`.
        target in 0x7bb458adc1d118713319a5baa00a2d049dd64d2916477d2688d76970c898cd55: Option<ContractId> = None,
        
        /// The [State] of the proxy owner.
        ///
        /// # Additional Information
        ///
        /// The `proxy_owner` is stored at `sha256("storage_SRC14_1")`.
        proxy_owner in 0xbb79927b15d9259ea316f2ecb2297d6cc8851888a98278c0a2e03e1a091ea754: State = State::Uninitialized,
    },
}
```

#### Using the Proxy

Now that you understand the proxy standard and the library used to implement it, let's cover how to use the proxy. Unlike other blockchain ecosystems, Sway intentionally separates the proxy contract from the implementation, allowing developers to focus solely on building their contracts. There are two methods to deploy: the first is using a `forc` plugin, and the second is using deployment scripts.

[1. Using `Forc` (Recommended)](https://docs.fuel.network/docs/forc/plugins/forc_client/#proxy-contracts)

In your Sway project’s `forc.toml` file, you can add a [proxy] tag to automate the deployment of both your implementation contract and a proxy contract that points to it. The owner is automatically set to the account that signs the deployments.

```toml
[project]
name = "test_contract"
...

[proxy]
enabled = true
```

If you already have a proxy contract deployed from a previous deployment and want to point it to a new implementation contract you're about to deploy, you can update the proxy to reference the new implementation without needing to redeploy the proxy itself.

```toml
[project]
name = "test_contract"
...

[proxy]
enabled = true
address = "0xd8c4b07a0d1be57b228f4c18ba7bca0c8655eb6e9d695f14080f2cf4fc7cd946" # example proxy contract address
```

There is currently no way to change the owner via `forc`. If needed, you can use the `set_proxy_owner.rs` script provided below in the second method to update the proxy owner.

[2. Using the scripts](https://github.com/FuelLabs/sway-standard-implementations/blob/master/src14/owned_proxy/README.md)

You can organize the scripts mentioned above exactly as they are within your `forc` project to make use of them. These scripts are provided to give more context to those interested in understanding the underlying mechanics.

Once you have implemented the scripts in your repository, you can deploy and initialize your implementation contract, along with a proxy contract pointed at it, by running the `deploy_and_init.rs` script.

```sh
SIGNING_KEY=<SIGNING_KEY> cargo run -r --bin deploy_and_init -- --initial-target <INITIAL_TARGET> --initial-owner <INITIAL_OWNER> --provider-url <PROVIDER_URL>
```

Where:
- `SIGNING_KEY` is the private key used for signing transactions

- `INITIAL_TARGET` is the address of the implementation contract you have deployed

- `INITIAL_OWNER` is the owner of the proxy contract.

- `PROVIDER_URL` is the RPC endpoint, such as `https://testnet.fuel.network/v1/graphql`.

To set a new implementation contract, you can use the `set_proxy_target.rs` script. This allows you to update the target contract that the proxy points to without redeploying the proxy itself.

```sh
SIGNING_KEY=<SIGNING_KEY> cargo run -r --bin set_proxy_target -- --proxy-contract-id <PROXY_CONTRACT_ID> --new-target-id <NEW_TARGET_ID> --provider-url <PROVIDER_URL>
```

Finally, the only functionality not available in the `forc` plugin is switching owners. To change the owner of the proxy contract, you can use the `set_proxy_owner.rs` script. This script allows you to manually update the proxy contract's owner when needed.

```sh
SIGNING_KEY=<SIGNING_KEY> cargo run -r --bin set_proxy_owner -- --proxy-contract-id <PROXY_CONTRACT_ID> --new-owner <NEW_OWNER> --provider-url <PROVIDER_URL>
```

## Chunking

When deploying:

1. The original contract code is replaced with the loader contract code.
2. The original contract code is split into blobs, which are deployed via blob transactions before deploying the contract itself.
3. The new loader code, when invoked, loads these blobs into memory and executes your original contract.

For more information, please refer to [documentation on large contracts](https://docs.fuel.network/docs/fuels-rs/deploying/large_contracts/).

#### Using chunking

As long as your `forc` is up to date, the process of deploying an oversized contract through multiple blob transactions is abstracted from the developer during deployment. When you compile the oversized project, even if the contract exceeds 400 KB—almost four times the maximum contract size—it will still compile successfully. This is handled automatically by `forc`.

```sh
...
Compiling contract large_contract (/Users/calldelegation/Projects/Fuel/proxy-chunks-minimal-example/programs/large_contract)
Finished debug [unoptimized + fuel] target(s) [400.04 KB] in 1.83s
```

## Putting It All Together (Chunking + Proxies Demo) 
#### Chunking 

https://github.com/user-attachments/assets/158ddc9b-5248-4783-a84a-594404c41e22

#### Chunking with Proxies

https://github.com/user-attachments/assets/cddef4d3-3861-44d1-ad04-6cdaf106d9b9

#### Upgrading Proxies

https://github.com/user-attachments/assets/b1143ebb-9d7f-415d-937e-b144d438c3ef

#### Pausing and Unpausing

https://github.com/user-attachments/assets/705a8ad7-8096-4e47-ba5c-4f5e4d2ad5d3

## Appendix

#### Proxy

- [SRC-14 Simple Upgradeable Proxies Standard](https://docs.fuel.network/docs/sway-standards/src-14-simple-upgradeable-proxies/)
- [Upgradable Library](https://docs.fuel.network/docs/sway-libs/upgradability/)
- [Audited Simple SRC-14 implementation](https://github.com/FuelLabs/sway-standard-implementations/blob/master/src14/owned_proxy/contract/src/main.sw)
- [Using `Forc` (Prefered) to Deploy and Init, Deploy new Target ]()
- [Using Scripts to Deploy and Init, Setting Proxy Target and Setting New Proxy Owner](https://github.com/FuelLabs/sway-standard-implementations/tree/master/src14/owned_proxy/scripts/src)
#### Chunks
- [Chunking Feature Basics](https://docs.fuel.network/docs/forc/plugins/forc_client/#large-contracts)
- [Chunking Feature Under The Hood (Rust-SDK](https://docs.fuel.network/docs/fuels-rs/deploying/large_contracts/)
