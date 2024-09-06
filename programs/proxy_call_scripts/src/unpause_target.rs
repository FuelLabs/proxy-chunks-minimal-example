use utils::setup_script;

#[tokio::main]
async fn main() {
    println!("\n|||||||||||||||||||||||||||||||||||||||||||||||||\n-|- Unpausing target -|-\n|||||||||||||||||||||||||||||||||||||||||||||||||");

    let (contract_instance, target_contract_id) = setup_script().await;

    let unpause_response = contract_instance
        .methods()
        .unpause()
        .with_contract_ids(&[target_contract_id.clone()])
        .call()
        .await;
    if let Err(e) = unpause_response {
        println!("\t - Proxy response: Error {e}");
        return;
    };

    let is_paused_response = contract_instance
        .methods()
        .is_paused()
        .with_contract_ids(&[target_contract_id])
        .call()
        .await;

    match is_paused_response {
        Ok(call_response) => println!(
            "\t - Proxy response: target paused = {}",
            call_response.value
        ),
        Err(e) => println!("\t - Proxy response: Error {e}"),
    };
}
