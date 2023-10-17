//main contract module
//defines all event details and functions
//create_event will allow users to create events
//set_event_terms will allow users to set the terms of the event
use starknet::ContractAddress;
#[starknet::interface]
trait IEventDetails<TContractState> {
    fn create_event(ref self: TContractState) -> felt252;
    fn set_event_terms(
        ref self: TContractState, 
        event_terms: felt252,
        start_time: felt252,
        end_time: felt252,
        winner_criteria: felt252,) -> felt252;
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
            let event_id = self.event_creators.read(1)+1;
            self.event_creators.write(1, event_id);
             self.emit(EventCreated {event_id: event_id, description: self.name.read()});
                        
            event_id
        }
        fn set_event_terms(
            ref self: ContractState, 
            event_terms: felt252,
            start_time: felt252,
            end_time: felt252,
            winner_criteria: felt252,
        ) -> felt252{
           
        // Ensure that provided event ID exists and corresponds to the caller.
        assert(self.event_creators.read().contract_address.is_zero(), "Caller is not an event creator.");
       // Get the event ID for the caller from storage.
        let event_id = self.event_creators.read().contract_address;
       // Ensure that the event with the provided ID exists.
        assert(self.event_id.is_zero(), "Event does not exist.");
       // Update the event details in storage with the provided values.
        let event = self.event_details.read(event_id);
          event.event_terms = event_terms;
          event.start_time = start_time;
          event.end_time = end_time;
          event.winner_criteria = winner_criteria;
        self.event_details.write(event_id, event);
       // Emit the EventTermsSet event.
        self.emit(EventTermsSet {event_terms, start_time, end_time, winner_criteria});
       // Return the event_terms as confirmation.
        return event_terms;
     }
 }
   #[generate_trait]
     impl InternalFunctions of InternalFunctionsTrait{
        fn _create_event(ref self: ContractState) -> felt252 {
            let name = self.name.read();
            
        }
     }
 }  