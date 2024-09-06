contract;

const VERSION: u8 = 1u8;

pub enum PauseError {
    /// Emitted when the contract is paused.
    ContractPaused: (),
    /// Emitted when the caller is not the `PAUSER_ROLE`.
    NotPauser: (),
}

abi Pauseable {
    #[storage(read)]
    fn is_paused() -> bool;

    #[storage(write)]
    fn pause();

    #[storage(write)]
    fn unpause();
}

abi SimpleContract {
    #[storage(read)]
    fn get_version() -> u8;
}

configurable {
    PAUSER_ROLE: Identity = Identity::Address(Address::from(0x0000000000000000000000000000000000000000000000000000000000000000)),
}

storage {
    is_paused: bool = false,
}

impl Pauseable for Contract {
    #[storage(read)]
    fn is_paused() -> bool {
        _is_paused()
    }

    #[storage(write)]
    fn pause() {
        only_pauser_role();
        storage.is_paused.write(true);
    }

    #[storage(write)]
    fn unpause() {
        only_pauser_role();
        storage.is_paused.write(false);
    }
}

#[storage(read)]
fn _is_paused() -> bool {
    storage.is_paused.read()
}

fn only_pauser_role() {
    require(PAUSER_ROLE == msg_sender().unwrap(), PauseError::NotPauser);
}

impl SimpleContract for Contract {
    #[storage(read)]
    fn get_version() -> u8 {
        require(_is_paused() == false, PauseError::ContractPaused);

        VERSION
    }
}
