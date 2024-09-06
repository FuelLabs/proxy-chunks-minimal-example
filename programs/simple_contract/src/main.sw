contract;

const VERSION: u8 = 1u8;

abi SimpleContract {
    fn get_version() -> u8;
}

impl SimpleContract for Contract {
    fn get_version() -> u8 {
        VERSION
    }
}
