defmodule TrackdaysWeb.Schema.VehicleTypes do
  use Absinthe.Schema.Notation

  import Absinthe.Resolution.Helpers, only: [dataloader: 1, dataloader: 3]

  # alias Trackdays.Vehicle
  alias TrackdaysWeb.Resolvers
  alias Trackdays.Vehicle
  alias Trackdays.Event

  object :make do
    field :id, non_null(:id)
    field :name, non_null(:string)
  end

  object :model do
    field :id, non_null(:id)
    field :name, non_null(:string)
    field :make, non_null(:make), resolve: dataloader(Vehicle)
  end

  object :motorcycle do
    field :id, non_null(:id)
    field :year, non_null(:integer)
    field :model, non_null(:model), resolve: dataloader(Vehicle)

    field :trackday_notes, list_of(non_null(:trackday_note)),
      resolve: dataloader(Event, :trackday_notes, args: %{scope: :motorcycle})
  end

  input_object :register_motorcycle_input do
    field :model_id, non_null(:id)
    field :year, non_null(:integer)
  end

  object :vehicle_queries do
    @desc "Get makes"
    field :makes, list_of(non_null(:make)) do
      resolve(&Resolvers.Vehicle.get_makes/3)
    end

    @desc "Get models of a make"
    field :models, list_of(non_null(:model)) do
      arg(:make_id, non_null(:id))
      resolve(&Resolvers.Vehicle.get_models/3)
    end

    @desc "Get all motorcycles"
    field :motorcycles, list_of(non_null(:motorcycle)) do
      resolve(&Resolvers.Vehicle.get_motorcycles/3)
    end

    @desc "Get motorcycle"
    field :motorcycle, non_null(:motorcycle) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Vehicle.get_motorcycle/3)
    end
  end

  object :vehicle_mutations do
    @desc "Register motorcycle"
    field :register_motorcycle, non_null(:motorcycle) do
      arg(:register_motorcycle_input, non_null(:register_motorcycle_input))
      resolve(&Resolvers.Vehicle.register_motorcycle/3)
    end

    @desc "Archive motorcycle. Not deleting becasue trackday notes need motorcycle"
    field :archive_motorcycle, non_null(:motorcycle) do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Vehicle.archive_motorcycle/3)
    end
  end
end
