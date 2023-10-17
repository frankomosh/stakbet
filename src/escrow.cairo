//users can deposit their funds into this escrow and would only be released upon conclusion of event
//funds would only be released to the winning participants
//funds returned to participants if event is cancelled or no winner is declared

#[starknet::interface]
trait IEscrow<TContractStorage> {
    fn place_in_escrow(ref self: TContractState) -> u128;
    fn release_escrow(ref self: TContractState) -> u128;
    fn refund_escrow(ref self: TContractState) -> u128;
}
#[starknet::contract]
mod Escrow{
    #[storage]
    struct Storage{
        escrow: u128,
        participants: LegacyMap::<ContractAddress, felt252>,
        winner: u128,
        event_status: bool,
    }
    #[external(v0)]
    impl Escrow of super::IEscrow<ContractState>{
        fn place_in_escrow(ref self: TContractState) -> u128{
            let sender = starknet::get_tx_sender();
            let amount = starknet::get_tx_amount();
            self.storage.escrow += amount;
            self.storage.participants.insert(sender, amount);
            return self.storage.escrow;
        }
        fn release_escrow(ref self: TContractState) -> u128{
            let sender = starknet::get_tx_sender();
            let amount = starknet::get_tx_amount();
            if self.storage.event_status == true{
                if self.storage.winner == sender{
                    self.storage.escrow -= amount;
                    return amount;
                }
            }
            return 0;
        }
        fn refund_escrow(ref self: TContractState) -> u128{
            let sender = starknet::get_tx_sender();
            let amount = starknet::get_tx_amount();
            if self.storage.event_status == false{
                self.storage.escrow -= amount;
                return amount;
            }
            return 0;
        }
    }
}