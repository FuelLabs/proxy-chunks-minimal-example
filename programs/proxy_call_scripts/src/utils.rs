use std::str::FromStr;

use clap::Parser;
use fuels::{
    accounts::{provider::Provider, wallet::WalletUnlocked},
    crypto::SecretKey,
    macros::abigen,
    types::{bech32::Bech32ContractId, ContractId},
};

#[derive(Parser, Debug)]
#[command(author, version, about, long_about = None)]
pub struct Args {
    /// Provider URL
    #[arg(short, long, default_value = "127.0.0.1:4000")]
    pub provider_url: String,
    /// Signing key
    #[arg(short, long, required = true, env = "SIGNING_KEY")]
    pub signing_key: String,
    /// Proxy `ContractId`
    #[arg(long, required = true)]
    pub proxy_contract_id: String,
    /// Target `ContractId`
    #[arg(long, required = true)]
    pub target_contract_id: String,
}

abigen!(Contract(
    name = "SimpleTargetContract",
    abi = "../simple_contract/out/release/simple_contract-abi.json"
));

pub async fn setup_script() -> (SimpleTargetContract<WalletUnlocked>, Bech32ContractId) {
    let args = Args::parse();

    let provider = Provider::connect(&args.provider_url).await.unwrap();
    let secret = SecretKey::from_str(&args.signing_key).unwrap();
    let signing_wallet = WalletUnlocked::new_from_private_key(secret, Some(provider));

    let proxy_contract_id: Bech32ContractId = ContractId::from_str(&args.proxy_contract_id)
        .unwrap()
        .into();

    let contract_instance = SimpleTargetContract::new(proxy_contract_id, signing_wallet);

    let target_contract_id: Bech32ContractId = ContractId::from_str(&args.target_contract_id)
        .unwrap()
        .into();

    (contract_instance, target_contract_id)
}
