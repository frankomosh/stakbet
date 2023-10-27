#[starknet::interface]
trait IBetDetails<TContractState>{
    fn create_bet(ref self: TContractState) -> felt252;
    fn set_bet_terms(ref self: TContractState,) -> u128;
    fn join_and_place_bet(ref self: TContractState, bet_choice: u128) -> u128;
    

} 
#[starknet::contract]
mod BetDetails{
    use starknet::ContractAddress;
    use starknet::get_caller_address;
   #[storage]
    struct Storage{
        creator: ContractAddress,
        bet_id: felt252,
        participants: LegacyMap::<ContractAddress, ParticipantDetail>,
        description: EventDescription,
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
        stake_amount: u128,
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
        // stake_amount: u128,
        is_settled: bool,
    ) {
        self.creator.write(creator);
        self.bet_id.write(1);
        self.description.write(description); 
        // EventDescription{
        //     start_time: description.start_time,
        //     end_time: description.end_time,
        //     outcome: description.outcome,
        // });
        // self.stake_amount.write(stake_amount);
        self.is_settled.write(false);
    }
    #[external(v0)]
    fn create_bet(ref self: ContractState) -> felt252{
       
      //ensure that event is not already created
      assert(self.bet_id.read() == 1,"Bet already created");
      
      //Allows users to create a new betting event with unique event details.
      //Event creators provide event details, including descriptions, start time, end time, and payout mode. The function assigns a unique bet_id and initializes the event.
       let caller = get_caller_address();
       let bet_id = self.bet_id.read();
       self.bet_id.write(bet_id + 1);
       return bet_id;

    }
    fn set_bet_terms(ref self: ContractState,) -> u128{
        //check if all participants chose the same outcome
        let unique_choices = self.participants.iter().map(|participant_detail| participant_detail.bet_choice).collect::<HashSet<_>>();
        if unique_choices.len() <= 1 {
            //All participants chose the same outcome, bet is not accepted
            return 0;
        }
        //Now bet is valid and bet terms can be stored *
        self.description.write(EventDescription{
            start_time: self.description.read().start_time,
            end_time: self.description.read().end_time,
            outcome: self.description.read().outcome,
        });
        //define that winner takes everything and loser takes nothing
        let winner_choice = unique_choices.iter().next().unwrap(); //Assuming a single winner situation
        if let some(winner) = self.participants.iter().find(|participant_detail| participant_detail.bet_choice == winner_choice){
            //winner takes all
            self.participants.insert(participant_detail, self.stake_amount.read());
        }
        else{
            //loser takes nothing
            self.participants.insert(participant_detail, 0);
        } 
        //Mark bet as settled
        self.is_settled.write(true);
        //return winner payout
        return self.stake_amount.read();
        
    }
    fn join_and_place_bet(ref self: ContractState,) -> u128{
        //Ensure that event is not settled before joining
        assert(self.is_settled.read() == false, "Bet is already settled");
        //Get address of participant
        let participant = get_caller_address();
        //Add participant's bet details to the bet
        self.participants.insert(ParticipantDetail{
            participant: participant,
            bet_choice: bet_choice,
        }, stake_amount);

    }
    
   #[generate_trait]
   impl InternalFunctions  of InternalFunctionsTrait{
        fn cancel_bet(ref self: ContractState,) -> u128{
            //Only the creator of the bet can cancel the bet
            assert(self.creator.read() == get_caller_address(), "Only the creator of the bet can cancel the bet");
            //Implement logic to cancel the bet and refund all participants
            //In the logic, ensure that there are not enough participants  or for other specified reasons.
            if self.participants.len() <=1{
                //Refund all participants
                for (participant_address, detail) in self.participants.iter(){
                    self.participants.insert(participant_address, 0);
                }
                //Mark bet as settled
                self.is_settled.write(true);
                //return 0
                return 0;
            }
            else{
                //Enough participants have joined the bet, so the bet cannot be cancelled
                assert (self.participants.len() > 1, "Enough participants have joined the bet, so the bet cannot be cancelled");
                //Mark bet as settled
                self.is_settled.write(true);
                //return 0
                return 0;

            
    }

        }
        fn get_bet_details(ref self: ContractState,) -> u128{
           //Ensure tht the bet exist and participant is taking part in the bet
              assert(self.bet_id.read() != 0, "Bet does not exist");
                assert(self.participants.get(participant_detail) != 0, "Participant is not taking part in the bet");
                //return bet details
                return self.description.read().get(participant_detail);
        }
        fn calculate_winnings(ref self: ContractState,) -> u128{
         //   Initialize total winnings to 0
            let mut total_winnings = 0;
         // Determine winning outcome based on criteria for event outome
            let winning_outcome = self.description.read().outcome;
         //Check if participant's bet choice matches the winning outcome
            if participant_detail.bet_choice == winning_outcome{
                //Calculate winnings
                total_winnings = total_winnings + participant_detail.stake_amount;
            }
            else{
                //Participant's bet choice does not match the winning outcome
                total_winnings = total_winnings + 0;
            }
            let total_stake_amount = self.participants.iter().map(|participant_detail| participant_detail.stake_amount).sum();
            let num_winners = self.participants.iter().filter(|participant_detail| participant_detail.bet_choice == winning_outcome).count();
            if num_winners > 0{
                //Calculate winnings
                total_winnings = total_winnings + (total_stake_amount/num_winners);
            }
            else{
                //Participant's bet choice does not match the winning outcome
                total_winnings = total_winnings + 0;
            }
            //return total winnings
            return total_winnings;

        }
        
        
   }
    
 }   

