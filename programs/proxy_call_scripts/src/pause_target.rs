use utils::setup_script;

#[tokio::main]
async fn main() {
    println!("\n|||||||||||||||||||||||||||||||||||||||||||||||||\n-|- Pausing target -|-\n|||||||||||||||||||||||||||||||||||||||||||||||||");

    let (contract_instance, target_contract_id) = setup_script().await;

    let pause_response = contract_instance
        .methods()
        .pause()
        .with_contract_ids(&[target_contract_id.clone()])
        .call()
        .await;
    if let Err(e) = pause_response {
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
