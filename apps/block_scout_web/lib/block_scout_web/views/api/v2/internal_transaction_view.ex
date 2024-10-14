defmodule BlockScoutWeb.API.V2.InternalTransactionView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.V2.{Helper, TransactionView}

  def render("internal_transaction.json", %{internal_transaction: nil}) do
    nil
  end

  def render("internal_transaction.json", %{
        internal_transaction: internal_transaction,
        block: block
      }) do
    prepare_internal_transaction(internal_transaction, block)
  end

  def render("internal_transactions.json", %{
        internal_transactions: internal_transactions,
        next_page_params: next_page_params
      }) do
    %{
      "items" => Enum.map(internal_transactions, &prepare_internal_transaction(&1, &1.block)),
      "next_page_params" => next_page_params
    }
  end

  def prepare_internal_transaction(internal_transaction, block \\ nil) do
    %{
      "error" => internal_transaction.error,
      "success" => is_nil(internal_transaction.error),
      "type" => internal_transaction.call_type || internal_transaction.type,
      "tx_hash" => internal_transaction.transaction_hash,
      "from" =>
        Helper.address_with_info(nil, internal_transaction.from_address, internal_transaction.from_address_hash, false),
      "to" =>
        Helper.address_with_info(nil, internal_transaction.to_address, internal_transaction.to_address_hash, false),
      "created_contract" =>
        Helper.address_with_info(
          nil,
          internal_transaction.created_contract_address,
          internal_transaction.created_contract_address_hash,
          false
        ),
      "value" => internal_transaction.value,
      "block_number" => internal_transaction.block_number,
      "timestamp" =>
        TransactionView.block_timestamp(block) || TransactionView.block_timestamp(internal_transaction.block),
      "index" => internal_transaction.index,
      "gas_limit" => internal_transaction.gas,
      "block_index" => internal_transaction.block_index
    }
  end
end
