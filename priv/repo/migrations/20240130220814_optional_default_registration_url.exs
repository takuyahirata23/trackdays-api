defmodule Trackdays.Repo.Migrations.OptionalDefaultRegistrationUrl do
  use Ecto.Migration

  def change do
     alter table(:organizations) do
       modify :trackdays_registration_url, :string, from: {:string, null: false}
     end
  end
end
