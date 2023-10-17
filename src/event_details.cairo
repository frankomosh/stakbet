//main contract module
//defines all event details and functions
//createEvent will allow users to create events
//setEventTerms will allow users to set the terms of the event
use starknet::ContractAddress;
#[starknet::interface]
trait IEventDetails<TContractState> {
    fn create_event(ref self: TContractState) -> felt252;
    fn set_event_terms(ref self: TContractState) -> felt252;
}

#[starknet::contract]
mod EventDetails {
  #[storage]
    struct Storage{
        name: felt252,
        event_creators: LegacyMap::<ContractAddress, felt252>,
    }
    #[event]
    enum Event {
        EventCreated: felt252,
        EventTermsSet: felt252,
    }
    #[derive(Drop, starknet::Event)]
    struct EventCreated {
        event_id: felt252,
        description: felt252,        
    }
    #[derive(Drop, starknet::Event)]
    struct EventTermsSet {
        event_terms: felt252,
        start_time: felt252,
        end_time: felt252,
        winner_criteria: felt252,
    }
    #[constructor]
    fn constructor(ref self: ContractState, init_value: felt252){
        self.name.write(init_value);
        self.event_creators.write(init_value, 1);
    }
    #[external(v0)]
    impl EventDetails of super::IEventDetails<ContractState>{
        fn create_event(ref self: ContractState) -> felt252{
            let event_id = self.event_creators.read(1);
            self.event_creators.write(event_id + 1);
            Event::EventCreated(EventCreated{
                event_id: event_id,
                description: felt252,
            });
            event_id
        }
        fn set_event_terms(ref self: ContractState) -> felt252{
            Event::EventTermsSet(EventTermsSet{
                event_terms: felt252,
                start_time: felt252,
                end_time: felt252,
                winner_criteria: felt252,
            });
        }
    }
 }  