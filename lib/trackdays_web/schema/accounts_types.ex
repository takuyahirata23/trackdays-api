defmodule TrackdaysWeb.Schema.AccountsTypes do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers, only: [dataloader: 1]

  alias Trackdays.Accounts
  alias TrackdaysWeb.Resolvers

  object :user do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :email, non_null(:string)
    field :image_url, :string
    field :is_private, non_null(:boolean)
    field :group, non_null(:group), resolve: dataloader(Accounts)
  end

  object :group do
    field :id, non_null(:id)
    field :name, non_null(:string)
  end

  object :deletion do
    field :message, non_null(:string)
  end

  object :accounts_queries do
    @desc "Get current user"
    field :user, non_null(:user) do
      resolve(&Resolvers.Accounts.get_user/3)
    end

    @desc "Get groups for signup"
    field :groups, list_of(non_null(:group)) do
      resolve(&Resolvers.Accounts.get_groups/3)
    end
  end

  object :accounts_mutations do
    @desc "Update group"
    field :update_group, non_null(:user) do
      arg(:group_id, non_null(:id))
      resolve(&Resolvers.Accounts.update_group/3)
    end

    @desc "Update account type"
    field :update_account_type, non_null(:user) do
      arg(:is_private, non_null(:boolean))
      resolve(&Resolvers.Accounts.update_account_type/3)
    end
  end
end
