defmodule BlockScoutWeb.API.V2.ScrollView do
  use BlockScoutWeb, :view

  alias BlockScoutWeb.API.V2.TransactionView
  alias Explorer.Chain.Scroll.{L1FeeParam, Reader}
  alias Explorer.Chain.{Data, Transaction}

  @api_true [api?: true]

  @doc """
    Function to render GET requests to `/api/v2/scroll/deposits` and `/api/v2/scroll/withdrawals` endpoints.
  """
  def render("scroll_bridge_items.json", %{
        items: items,
        next_page_params: next_page_params
      }) do
    %{
      items:
        Enum.map(items, fn item ->
          %{
            "block_number" => item.block_number,
            "index" => item.index,
            "l1_transaction_hash" => item.l1_transaction_hash,
            "timestamp" => item.block_timestamp,
            "l2_transaction_hash" => item.l2_transaction_hash,
            "value" => item.amount
          }
        end),
      next_page_params: next_page_params
    }
  end

  @doc """
    Function to render GET requests to `/api/v2/scroll/deposits/count` and `/api/v2/scroll/withdrawals/count` endpoints.
  """
  def render("scroll_bridge_items_count.json", %{count: count}) do
    count
  end

  @doc """
    Extends the json output with a sub-map containing information related Scroll.

    ## Parameters
    - `out_json`: A map defining output json which will be extended.
    - `transaction`: Transaction structure containing Scroll related data

    ## Returns
    - A map extended with the data related to Scroll rollup.
  """
  @spec extend_transaction_json_response(map(), %{
          :__struct__ => Transaction,
          :block_number => non_neg_integer(),
          :index => non_neg_integer(),
          :input => Data.t(),
          optional(any()) => any()
        }) :: map()
  def extend_transaction_json_response(out_json, %Transaction{} = transaction) do
    config = Application.get_all_env(:explorer)[L1FeeParam]

    l1_fee_scalar = get_param(:scalar, transaction, config)
    l1_fee_commit_scalar = get_param(:commit_scalar, transaction, config)
    l1_fee_blob_scalar = get_param(:blob_scalar, transaction, config)
    l1_fee_overhead = get_param(:overhead, transaction, config)
    l1_base_fee = get_param(:l1_base_fee, transaction, config)
    l1_blob_base_fee = get_param(:l1_blob_base_fee, transaction, config)

    l1_gas_used = L1FeeParam.l1_gas_used(transaction, l1_fee_overhead)

    l2_fee =
      transaction
      |> Transaction.l2_fee(:wei)
      |> TransactionView.format_fee()

    params =
      %{}
      |> add_optional_transaction_field(transaction, :l1_fee)
      |> add_optional_transaction_field(transaction, :queue_index)
      |> Map.put("l1_fee_scalar", l1_fee_scalar)
      |> Map.put("l1_fee_commit_scalar", l1_fee_commit_scalar)
      |> Map.put("l1_fee_blob_scalar", l1_fee_blob_scalar)
      |> Map.put("l1_fee_overhead", l1_fee_overhead)
      |> Map.put("l1_base_fee", l1_base_fee)
      |> Map.put("l1_blob_base_fee", l1_blob_base_fee)
      |> Map.put("l1_gas_used", l1_gas_used)
      |> Map.put("l2_fee", l2_fee)

    Map.put(out_json, "scroll", params)
  end

  defp add_optional_transaction_field(out_json, transaction, field) do
    case Map.get(transaction, field) do
      nil -> out_json
      value -> Map.put(out_json, Atom.to_string(field), value)
    end
  end

  # sobelow_skip ["DOS.BinToAtom"]
  defp get_param(name, transaction, config)
       when name in [:scalar, :commit_scalar, :blob_scalar, :overhead, :l1_base_fee, :l1_blob_base_fee] do
    name_init = :"#{name}#{:_init}"

    case Reader.get_l1_fee_param_for_transaction(name, transaction, @api_true) do
      nil -> config[name_init]
      value -> value
    end
  end
end
