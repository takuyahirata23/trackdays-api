defmodule Trackdays.Event do
  import Ecto.Query, warn: false

  alias Trackdays.Repo
  alias Trackdays.Event.{TrackdayNote, Trackday, UserTrackdayCalendar}
  alias Trackdays.Park.{Facility, Track}
  alias Trackdays.Accounts.{User}
  alias Trackdays.Vehicle.{Motorcycle}

  use Timex

  def save_trackday_note(attrs, user) do
    %TrackdayNote{}
    |> TrackdayNote.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Repo.insert()
  end

  def update_trackday_note(attrs) do
    case get_trackday_note_by_id(attrs.id) do
      %TrackdayNote{} = trackday ->
        attrs = Map.drop(attrs, [:id])

        changeset = Ecto.Changeset.change(trackday, attrs)
        Repo.update(changeset)

      _ ->
        {:error, nil}
    end
  end

  def get_trackday_notes_by_user_id(id) when is_binary(id) do
    Repo.all(from t in TrackdayNote, where: t.user_id == ^id)
  end

  def get_trackday_notes_by_month(id, %{year: year, month: month}) when is_binary(id) do
    start = Timex.beginning_of_month(year, month)
    last = Timex.end_of_month(year, month)

    Repo.all(
      from t in TrackdayNote, where: t.user_id == ^id and t.date <= ^last and t.date >= ^start
    )
  end

  # TODO: users cannot query other's trackday notes but checking user id is safer just in case
  def get_trackday_note_by_id(id) when is_binary(id) do
    Repo.one(from t in TrackdayNote, where: t.id == ^id)
  end

  def get_best_lap_for_each_track(id) when is_binary(id) do
    Repo.all(
      from t in TrackdayNote,
        where: t.user_id == ^id,
        distinct: t.track_id,
        order_by: t.lap_time
    )
  end

  def delete_trackday_note(trackday_note_id, user_id)
      when is_binary(trackday_note_id) and is_binary(user_id) do
    case Repo.one(
           from t in TrackdayNote, where: t.id == ^trackday_note_id and t.user_id == ^user_id
         ) do
      %TrackdayNote{} = trackday_note ->
        Repo.delete(trackday_note)

      _ ->
        {:error, %{message: "Trackday note not found"}}
    end
  end

  def get_trackdays_by_month(%{year: year, month: month}) do
    start = Timex.beginning_of_month(year, month) |> Timex.to_naive_datetime()
    last = Timex.end_of_month(year, month) |> Timex.to_naive_datetime()

    Repo.all(from t in Trackday, where: t.end_datetime <= ^last and t.start_datetime >= ^start)
  end

  def get_trackday_by_id(id) when is_binary(id) do
    Repo.one(from t in Trackday, where: t.id == ^id)
  end

  def save_user_trackday_calendar(attrs) do
    %UserTrackdayCalendar{}
    |> UserTrackdayCalendar.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_trackday_calendar(user_id, trackday_id)
      when is_binary(user_id) and is_binary(trackday_id) do
    Repo.one(
      from u in UserTrackdayCalendar,
        where: u.user_id == ^user_id and u.trackday_id == ^trackday_id
    )
  end

  def delete_user_trackday_calendar(user_id, trackday_id)
      when is_binary(user_id) and is_binary(trackday_id) do
    with %UserTrackdayCalendar{} = user_trackday_calendar <-
           get_user_trackday_calendar(user_id, trackday_id),
         res <- Repo.delete(user_trackday_calendar) do
      res
    else
      nil -> {:error, error: true, message: "User trackday calendar not found"}
      error -> error
    end
  end

  def get_upcoming_trackdays(user_id) when is_binary(user_id) do
    trackday_ids =
      from utc in UserTrackdayCalendar,
        where: utc.user_id == ^user_id,
        select: utc.trackday_id

    today = NaiveDateTime.local_now()

    query =
      from t in Trackday,
        where: t.id in subquery(trackday_ids) and t.end_datetime >= ^today,
        order_by: [:start_datetime],
        limit: 1

    Repo.all(query)
  end

  def get_facility_leaderboard(facility_id) do
    ids =
      Repo.all(
        from f in Facility,
          where: f.id == ^facility_id,
          join: t in Track,
          on: t.facility_id == f.id,
          select: t.id
      )

    track_query =
      from t in Track,
        where: t.id in ^ids

    Repo.all(track_query)
    |> Enum.map(fn track ->
      res = get_leaderboard(track.id)
      Map.put(track, :trackday_notes, res)
    end)
  end

  defp get_leaderboard(track_id) do
    tn_query =
      from tn in TrackdayNote,
        where: tn.track_id == ^track_id,
        join: u in User,
        on: tn.user_id == u.id and u.is_private == false,
        distinct: tn.user_id,
        order_by: [tn.lap_time]

    query =
      from tn in TrackdayNote,
        join: m in subquery(tn_query),
        on: tn.id == m.id,
        order_by: tn.lap_time,
        preload: [motorcycle: [model: :make]]

    Repo.all(query)
  end

  def datasource do
    Dataloader.Ecto.new(Repo, query: &query/2)
  end

  def query(TrackdayNote, %{scope: :motorcycle}) do
    TrackdayNote
    |> order_by([desc: :date])
    |> limit(2)
  end

  def query(queryable, _) do
    queryable
  end
end
