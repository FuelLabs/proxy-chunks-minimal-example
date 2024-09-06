# Proxy Call Script

- This script can be used to display the value of a target contract method by calling that method on a proxy contract.

## Usage instructions

From `proxy-chunks-minimal-example/programs/proxy_call_script/<you are here>`:

### get_target_version script

```bash
SIGNING_KEY=<SIGNING_KEY> cargo run -r --bin get_target_version -- --provider-url <PROVIDER_URL> --proxy-contract-id <PROXY_CONTRACT_ID> --target-contract-id <TARGET_CONTRACT_ID>
```

### pause_target script

```bash
SIGNING_KEY=<SIGNING_KEY> cargo run -r --bin pause_target -- --provider-url <PROVIDER_URL> --proxy-contract-id <PROXY_CONTRACT_ID> --target-contract-id <TARGET_CONTRACT_ID>
```

### unpause_target script

```bash
SIGNING_KEY=<SIGNING_KEY> cargo run -r --bin unpause_target -- --provider-url <PROVIDER_URL> --proxy-contract-id <PROXY_CONTRACT_ID> --target-contract-id <TARGET_CONTRACT_ID>
```

> **Note:** The optional flag `--provider-url <PROVIDER_URL>` sets the URL of the provider to be used in the script. If not manually set, it defaults to `127.0.0.1:4000` which is the default `fuel-core` URL.
> **Note:** There is also the optional flag `--signing-key <SIGNING_KEY>` which can be used instead of the environment variable `SIGNING_KEY`. However use of the environment variable `SIGNING_KEY` is preferred.
