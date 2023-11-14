// Import necessary modules and traits
use starknet::ContractAddress;
use starknet::SyscallResult;
use starknet::testing::init_contract;
use starknet::get_contract_address;
use starknet::get_caller_address;
use starknet::storage_read_syscall;
use starknet::storage_write_syscall;

// Import the contract and its interface
use BetContract::IBetContract;
use BetContract::BetContractImpl;
use BetContract::Storage;

// Define the test contract
#[cfg(test)]
mod tests {
    use super::IERC20DispatcherTrait;
    use super::IERC20Dispatcher;

    // Test the make_prediction function
    #[test]
    fn test_make_prediction() {
        // Initialize the contract
        let mut contract = init_contract::<BetContractImpl, Storage>();

        // Set up test parameters
        let prediction_id: felt252 = 1;
        let candidate: felt252 = 42;
        let amount: u256 = 100;

        // Get the caller's address
        let caller_address = get_caller_address();

        // Make a prediction
        contract.make_prediction(prediction_id, candidate, amount);

        // Check if the prediction is stored correctly
        let stored_prediction: SyscallResult<Prediction> = storage_read_syscall(
            0, storage_address_from_base_and_offset(contract.get_base(), 0_u8),
        );
        assert(stored_prediction.is_ok(), "Error reading stored prediction");

        // Check if the stored prediction matches the expected values
        let stored_prediction_value = stored_prediction.unwrap();
        assert_eq!(
            stored_prediction_value.participant, caller_address, "Incorrect participant address"
        );
        assert_eq!(stored_prediction_value.tokenAmount, amount, "Incorrect token amount");
        assert_eq!(stored_prediction_value.candidate, candidate, "Incorrect candidate");
        assert_eq!(
            stored_prediction_value.redeemed, bool_to_felt252(false), "Incorrect redeemed status"
        );
    }

    // Test the redeem_reward function
    #[test]
    fn test_redeem_reward() {
        // Initialize the contract
        let mut contract = init_contract::<BetContractImpl, Storage>();

        // Set up test parameters
        let prediction_id: felt252 = 1;

        // Make a prediction (assume this has been tested separately)
        contract.make_prediction(prediction_id, 42, 100);

        // Call redeem_reward (assuming the oracle returns the correct winner)
        contract.redeem_reward(prediction_id);

        // Check if the user's balance has been updated
        let caller_address = get_caller_address();
        let user_balance: u256 = storage_read_syscall(
            0,
            storage_address_from_base_and_offset(
                storage_address_from_base_and_offset(contract.get_base(), 1_u8),
                caller_address.into(),
            ),
        )
            .unwrap();
        assert_eq!(
            user_balance,
            100, // Assuming the correct amount is 100
            "Incorrect user balance after redeeming reward"
        );

        // Check if the prediction's redeemed status has been updated
        let stored_prediction: SyscallResult<Prediction> = storage_read_syscall(
            0, storage_address_from_base_and_offset(contract.get_base(), 0_u8),
        );
        assert(stored_prediction.is_ok(), "Error reading stored prediction");
        let stored_prediction_value = stored_prediction.unwrap();
        assert_eq!(
            stored_prediction_value.redeemed,
            bool_to_felt252(true),
            "Incorrect redeemed status after redeeming reward"
        );
    }

    // Test the withdraw_tokens function
    #[test]
    fn test_withdraw_tokens() {
        // Initialize the contract
        let mut contract = init_contract::<BetContractImpl, Storage>();

        // Set up test parameters
        let amount: u256 = 100;

        // Make a prediction and redeem reward (assuming these have been tested separately)
        contract.make_prediction(1, 42, amount);
        contract.redeem_reward(1);

        // Call withdraw_tokens
        contract.withdraw_tokens(amount);

        // Check if the user's balance has been set to zero after withdrawal
        let caller_address = get_caller_address();
        let user_balance: u256 = storage_read_syscall(
            0,
            storage_address_from_base_and_offset(
                storage_address_from_base_and_offset(contract.get_base(), 1_u8),
                caller_address.into(),
            ),
        )
            .unwrap();
        assert_eq!(user_balance, 0, "Incorrect user balance after withdrawing tokens");
    }
}
