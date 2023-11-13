#[starknet::contract]
mod Oracle {
    use core::starknet::event::EventEmitter;
    #[storage]
    struct Storage {
        winningCandidate: felt252,
    }

    #[constructor]
    fn constructor(ref self: ContractState, _winningCandidate: felt252) {
        self.winningCandidate.write(_winningCandidate);
    }

    #[external(v0)]
    fn getPredictionWinner(self: @ContractState) -> felt252 {
        self.winningCandidate.read()
    }
}

