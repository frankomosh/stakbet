#[starknet::interface]
trait IBetDetails<TContractState>{
    fn create_bet(ref self: TContractState,) -> u64;
    fn join_and_place_bet(ref self: TContractState,) -> bool;

}

#[starknet::contract]

mod BetDetails{
    use starknet::ContractAddress;
    use starknet::get_caller_address;
   #[storage]
    struct Storage{
        creator: ContractAddress,
        bet_id: u64,
        participants: LegacyMap::<ParticipantDetail, felt252>,
        description: EventDescription,
        stake_amount: u128,  
        is_settled: bool,    
    

    }
    #[event]
    enum Event {
        ParticipantDetail: ParticipantDetail,    
        
    }
    #[derive(Drop, starknet::Event)]
    struct ParticipantDetail {
        #[key]
        participant: ContractAddress,
        bet_choice: u128,
    }
    #[derive(copy, Drop, Serde, starknet::Store)]
    struct EventDescription{
        start_time: u128,
        end_time: u128,
        outcome: u128,
    }
    #[constructor]
    fn constructor(
        ref self: ContractState, 
        creator: ContractAddress,
        description: EventDescription,
        stake_amount: u128,
        is_settled: bool,
    ) {
        self.creator.write(creator);
        self.bet_id.write(1);
        self.description.write(EventDescription{
            start_time: description.start_time,
            end_time: description.end_time,
            outcome: description.outcome,
        });
        self.stake_amount.write(stake_amount);
        self.is_settled.write(true);
    }
    
 }   

