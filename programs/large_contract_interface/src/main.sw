library;

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

    fn get_configurable_bool() -> bool;
}
