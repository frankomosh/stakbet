// bet functionality to place bets on the event outcomes
// and to check the current bets
#[starknet::interface]
trait IBet<TContractState>{
    // place a bet on the event outcome
    fn place_bet(ref self: TContractState) ->u32;
    fn check_bets(self: @TContractState) ->u32;
}
#[starknet::contract]
mod Bet{
    #[storage]
    struct Storage{
        // the bet amount
        bet_amount: u32,
        // the bet outcome
        bet_outcome: u32,
        // the bettor
        bettor: u32,
    }
    #[exernal(v0)]
    impl Bet of super::IBet<ContractState>{
        fn place_bet(ref self: ContractState) ->u32{
            // check if the bet amount is valid
            assert!(self.bet_amount > 0, "Bet amount must be greater than 0");
            // check if the bet outcome is valid
            assert!(self.bet_outcome > 0, "Bet outcome must be greater than 0");
            // check if the bettor is valid
            assert!(self.bettor > 0, "Bettor must be greater than 0");
            // return the bet amount
            return self.bet_amount;
        }
        fn check_bets(self: @ContractState) ->u32{
            // check if the bet amount is valid
            assert!(self.bet_amount > 0, "Bet amount must be greater than 0");
            // check if the bet outcome is valid
            assert!(self.bet_outcome > 0, "Bet outcome must be greater than 0");
            // check if the bettor is valid
            assert!(self.bettor > 0, "Bettor must be greater than 0");
            // return the bet amount
            return self.bet_amount;
        }
    }
}