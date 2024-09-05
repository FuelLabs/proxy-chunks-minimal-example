contract;

const U8: u8 = 1u8;

abi SimpleContract {
    fn get_u8() -> u8;
}

impl SimpleContract for Contract {
    fn get_u8() -> u8{
        U8
    }
}
