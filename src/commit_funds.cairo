// commitFunds
#[starknet::interface]
trait ICommitFunds<TContractState> {
    /// Commits funds to the contract.
    ///
    /// # Arguments
    ///
    /// * `amount` - The amount of funds to commit.
    // #[starknet::invoke]
    fn commit_funds(ref self: TContractState, amount: u128);
}
#[starknet::contract]
mod CommitFunds{
  #[storage]
  struct ContractState{
    amount: u128
  }
  #[external(v0)]
   impl CommitFunds of super::ICommitFunds<ContractState>{
    fn commit_funds(ref self: ContractState, amount: u128) {
      self.amount = amount;
    }
   }
}