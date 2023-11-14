use starknet::ContractAddress;
#[starknet::interface]
// #[abi()]
trait IOracle<TContractState> {
    #[external]
    fn getPredictionWinner(self: @TContractState) -> felt252;
}
