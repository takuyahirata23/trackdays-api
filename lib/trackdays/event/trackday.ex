defmodule Trackdays.Event.Trackday do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "trackdays" do
    field :start_datetime, :naive_datetime
    field :end_datetime, :naive_datetime
    field :price, :float
    field :description, :string
    field :trackdays_registration_url, :string

    belongs_to :organization, Trackdays.Business.Organization
    belongs_to :track, Trackdays.Park.Track

    timestamps()
  end

  def changeset(trackday, attrs \\ %{}) do
    trackday
    |> cast(attrs, [
      :start_datetime,
      :end_datetime,
      :price,
      :description,
      :organization_id,
      :track_id,
      :trackdays_registration_url
    ])
    |> validate_required([:start_datetime, :end_datetime, :price, :organization_id, :track_id])
    |> validate_number(:price, greater_than: 10)
    |> validate_length(:trackdays_registration_url, min: 2, max: 100)
    |> unique_constraint([:organization_id, :start_date, :track_id],
      name: :trackdays_constraint,
      message: "Your trackday on this date already exists"
    )
  end
end
