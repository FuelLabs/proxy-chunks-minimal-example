use utils::setup_script;

#[tokio::main]
async fn main() {
    println!("\n|||||||||||||||||||||||||||||||||||||||||||||||||\n-|- Getting target version -|-\n|||||||||||||||||||||||||||||||||||||||||||||||||");

    let (contract_instance, target_contract_id) = setup_script().await;

    let response = contract_instance
        .methods()
        .get_version()
        .with_contract_ids(&[target_contract_id])
        .call()
        .await;

    match response {
        Ok(call_response) => println!(
            "\t - Proxy response: target contract version {}",
            call_response.value
        ),
        Err(e) => println!("\t - Proxy response: Error {e}"),
    };
}
