script;

use large_contract_interface::LargeContract;

fn main(proxy_contract_id: b256) -> bool {
    let caller = abi(LargeContract, proxy_contract_id);
    
    caller.get_configurable_bool()
}
