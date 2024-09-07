contract;

use std::storage::storage_vec::*;
use std::hash::*;

const VERSION: u8 = 2u8;

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

abi Versioned {
    #[storage(read)]
    fn get_version() -> u8;
}

configurable {
    PAUSER_ROLE: Identity = Identity::Address(Address::from(0xb365fa96ea3ebc33aed490abeddb6e3aa56539b67c07523462276070c07330c6)),
    // the configurables below this point are only there to increase the contract size to > 100KB so that it will be chunked.
    BOOL: bool = true,
    U8: u8 = 1,
    U16: u16 = 2,
    U32: u32 = 3,
    U64: u32 = 4,
    U256: u256 = 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAu256,
    B256: b256 = 0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB,
    CONFIGURABLE_STRUCT: SimpleStruct = SimpleStruct { a: true, b: 5 },
    CONFIGURABLE_ENUM: Location = Location::Earth(1),
    ARRAY_BOOL: [bool; 3] = [true, false, true],
    ARRAY_U64: [u64; 3] = [9, 8, 7],
    ARRAY_LOCATION: [Location; 2] = [Location::Earth(10), Location::Mars],
    ARRAY_SIMPLE_STRUCT: [SimpleStruct; 3] = [
        SimpleStruct { a: true, b: 5 },
        SimpleStruct { a: false, b: 0 },
        SimpleStruct {
            a: true,
            b: u64::max(),
        },
    ],
    TUPLE_BOOL_U64: (bool, u64) = (true, 11),
    STR_4: str[4] = __to_str_array("abcd"),
}

storage {
    is_paused: bool = false,
    // the storage variables below this point are only there to increase the contract size to > 100KB so that it will be chunked.
    my_vec: StorageVec<u16> = StorageVec {},
    my_simple_vec: StorageVec<SimpleStruct> = StorageVec {},
    my_location_vec: StorageVec<Location> = StorageVec {},
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
    storage.is_paused.try_read().unwrap_or(false)
}

fn only_pauser_role() {
    require(PAUSER_ROLE == msg_sender().unwrap(), PauseError::NotPauser);
}

impl Versioned for Contract {
    #[storage(read)]
    fn get_version() -> u8 {
        require(_is_paused() == false, PauseError::ContractPaused);

        VERSION
    }
}

// Everything below this point is only there to increase the contract size to > 100KB so that it will be chunked.

pub enum Location {
    pub Earth: u64,
    pub Mars: (),
    pub SimpleJupiter: Color,
    pub Jupiter: [Color; 2],
    pub SimplePluto: SimpleStruct,
    pub Pluto: [SimpleStruct; 2],
}

pub enum Color {
    pub Red: (),
    pub Blue: u64,
}

pub struct Person {
    pub name: str,
    pub age: u64,
    pub alive: bool,
    pub location: Location,
    pub some_tuple: (bool, u64),
    pub some_array: [u64; 2],
    pub some_b256: b256,
}

pub struct SimpleStruct {
    pub a: bool,
    pub b: u64,
}

abi LargeContract {
    fn large_blob() -> bool;

    fn enum_input_output(loc: Location) -> Location;

    fn struct_input_output(person: Person) -> Person;

    fn array_of_enum_input_output(aoe: [Location; 2]) -> [Location; 2];

    #[storage(read, write)]
    fn push_storage_u16(value: u16);

    #[storage(read)]
    fn get_storage_u16(index: u64) -> u16;

    #[storage(read, write)]
    fn push_storage_simple(value: SimpleStruct);

    #[storage(read)]
    fn get_storage_simple(index: u64) -> SimpleStruct;

    #[storage(read, write)]
    fn push_storage_location(value: Location);

    #[storage(read)]
    fn get_storage_location(index: u64) -> Location;

    fn assert_configurables() -> bool;
}

impl core::ops::Eq for Color {
    fn eq(self, other: Color) -> bool {
        match (self, other) {
            (Color::Red, Color::Red) => true,
            (Color::Blue(inner1), Color::Blue(inner2)) => inner1 == inner2,
            _ => false,
        }
    }
}

impl core::ops::Eq for SimpleStruct {
    fn eq(self, other: SimpleStruct) -> bool {
        self.a == other.a && self.b == other.b
    }
}

impl core::ops::Eq for Location {
    fn eq(self, other: Location) -> bool {
        match (self, other) {
            (Location::Earth(inner1), Location::Earth(inner2)) => inner1 == inner2,
            (Location::Mars, Location::Mars) => true,
            (Location::SimpleJupiter(inner1), Location::SimpleJupiter(inner2)) => inner1 == inner2,
            (Location::Jupiter(inner1), Location::Jupiter(inner2)) => (inner1[0] == inner2[0] && inner1[1] == inner2[1]),
            (Location::SimplePluto(inner1), Location::SimplePluto(inner2)) => inner1 == inner2,
            (Location::Pluto(inner1), Location::Pluto(inner2)) => (inner1[0] == inner2[0] && inner1[1] == inner2[1]),
            _ => false,
        }
    }
}

impl LargeContract for Contract {
    fn large_blob() -> bool {
        asm() {
            blob i91000;
        }
        true
    }

    fn enum_input_output(loc: Location) -> Location {
        loc
    }

    fn struct_input_output(person: Person) -> Person {
        person
    }

    fn array_of_enum_input_output(aoe: [Location; 2]) -> [Location; 2] {
        aoe
    }

    #[storage(read, write)]
    fn push_storage_u16(value: u16) {
        storage.my_vec.push(value);
    }

    #[storage(read)]
    fn get_storage_u16(index: u64) -> u16 {
        storage.my_vec.get(index).unwrap().read()
    }

    #[storage(read, write)]
    fn push_storage_simple(value: SimpleStruct) {
        storage.my_simple_vec.push(value);
    }

    #[storage(read)]
    fn get_storage_simple(index: u64) -> SimpleStruct {
        storage.my_simple_vec.get(index).unwrap().read()
    }

    #[storage(read, write)]
    fn push_storage_location(value: Location) {
        storage.my_location_vec.push(value);
    }

    #[storage(read)]
    fn get_storage_location(index: u64) -> Location {
        storage.my_location_vec.get(index).unwrap().read()
    }

    fn assert_configurables() -> bool {
        assert(BOOL == true);
        assert(U8 == 1);
        assert(U16 == 2);
        assert(U32 == 3);
        assert(U64 == 4);
        assert(U256 == 0xAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAu256);
        assert(B256 == 0xBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB);
        assert(CONFIGURABLE_STRUCT.a == true);
        assert(CONFIGURABLE_STRUCT.b == 5);
        assert(CONFIGURABLE_ENUM == Location::Earth(1));
        assert(ARRAY_BOOL[0] == true);
        assert(ARRAY_BOOL[1] == false);
        assert(ARRAY_BOOL[2] == true);
        assert(ARRAY_U64[0] == 9);
        assert(ARRAY_U64[1] == 8);
        assert(ARRAY_U64[2] == 7);
        assert(ARRAY_LOCATION[0] == Location::Earth(10));
        assert(ARRAY_LOCATION[1] == Location::Mars);
        assert(ARRAY_SIMPLE_STRUCT[0].a == true);
        assert(ARRAY_SIMPLE_STRUCT[0].b == 5);
        assert(ARRAY_SIMPLE_STRUCT[1].a == false);
        assert(ARRAY_SIMPLE_STRUCT[1].b == 0);
        assert(ARRAY_SIMPLE_STRUCT[2].a == true);
        assert(ARRAY_SIMPLE_STRUCT[2].b == u64::max());
        assert(ARRAY_LOCATION[1] == Location::Mars);
        assert(ARRAY_LOCATION[1] == Location::Mars);
        assert(TUPLE_BOOL_U64.0 == true);
        assert(TUPLE_BOOL_U64.1 == 11);
        assert(sha256_str_array(STR_4) == sha256("abcd"));

        // Assert address do not change
        let addr_1 = asm(addr: __addr_of(&BOOL)) {
            addr: u64
        };
        let addr_2 = asm(addr: __addr_of(&BOOL)) {
            addr: u64
        };
        assert(addr_1 == addr_2);
        true
    }
}
