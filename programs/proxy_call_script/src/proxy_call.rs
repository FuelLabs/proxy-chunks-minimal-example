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
struct Args {
    /// Provider URL
    #[arg(short, long, default_value = "127.0.0.1:4000")]
    provider_url: String,
    /// Signing key
    #[arg(short, long, required = true, env = "SIGNING_KEY")]
    signing_key: String,
    /// Proxy `ContractId`
    #[arg(long, required = true)]
    proxy_contract_id: String,
    /// Target `ContractId`
    #[arg(long, required = true)]
    target_contract_id: String,
}

abigen!(Contract(
    name = "SimpleTargetContract",
    abi = "../simple_contract/out/release/simple_contract-abi.json"
));

#[tokio::main]
async fn main() {
    println!("\n|||||||||||||||||||||||||||||||||||||||||||||||||\n-|- Calling Proxy Contract -|-\n|||||||||||||||||||||||||||||||||||||||||||||||||");

    let args = Args::parse();

    let signing_wallet = setup_signing_wallet(&args.provider_url, &args.signing_key).await;

    let proxy_contract_id: Bech32ContractId = ContractId::from_str(&args.proxy_contract_id)
        .unwrap()
        .into();

    let contract_instance = SimpleTargetContract::new(proxy_contract_id, signing_wallet);

    let target_contract_id: Bech32ContractId = ContractId::from_str(&args.target_contract_id)
        .unwrap()
        .into();

    let response = contract_instance
        .methods()
        .get_u8()
        .with_contract_ids(&[target_contract_id])
        .call()
        .await
        .unwrap();

    println!("\t - Proxy response: {}", response.value);
}

async fn setup_signing_wallet(provider_url: &str, signing_key: &str) -> WalletUnlocked {
    let provider = Provider::connect(provider_url).await.unwrap();
    let secret = SecretKey::from_str(signing_key).unwrap();
    WalletUnlocked::new_from_private_key(secret, Some(provider))
}
