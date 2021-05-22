defmodule SharedModules.Bson do
  @moduledoc false

  # An ObjectId consists of a machine id, process id, seconds since unix epoch
  # and a counter. The counter is used to differentiate between generated
  # ObjectIds during a single second.
  #
  # A counter is generated for each second in an hour, the counter is
  # initialized to a random number based on MongoDB documentation's
  # recommendation. Each time a new ObjectId is generated we take the counter
  # for the current second and increment it.
  #
  # To keep the counters random and to make sure they don't grow infinitely they
  # need to be reset. Care needs to be taken to ensure a counter is not reset
  # during its second's window during which it is being used. Once each minute
  # ~60 counters should be reset, only counters that will be used ~30 minutes in
  # the future are reset to ensure the current second's counter is not touched.

  use GenServer

  @name __MODULE__
  @num_counters 3600
  @reset_timer 60_000
  @counter_max 16_777_216
  @gs_epoch :calendar.datetime_to_gregorian_seconds({{1970, 1, 1}, {0, 0, 0}})
  @uuid_gap_fill 3133731337

  def start_link(_ \\ nil) do
    with {:error, {:already_started, _pid}} <- GenServer.start_link(__MODULE__, [], name: @name) do
      :ignore
    end
  end

  def init([]) do
    :ets.new(@name, [:named_table, :public, write_concurrency: true])
    :ets.insert(@name, machineprocid: {machine_id(), process_id()})
    :ets.insert(@name, gen_counters(0..@num_counters))

    Process.send_after(self(), :reset_counters, @reset_timer)

    {:ok, opposite_on_window(:calendar.universal_time())}
  end

  def handle_info(:reset_counters, last_reset) do
    new_reset = opposite_on_window(:calendar.universal_time())
    :ets.insert(@name, gen_counters((last_reset + 1)..new_reset))
    Process.send_after(self(), :reset_counters, @reset_timer)

    {:noreply, new_reset}
  end

  def raw_objectid do
    {machine_id, proc_id} = :ets.lookup_element(@name, :machineprocid, 2)

    now = :calendar.universal_time()
    secs = :calendar.datetime_to_gregorian_seconds(now) - @gs_epoch
    counter = :ets.update_counter(@name, in_window(now), 1)
    counter = rem(counter, @counter_max)

    <<secs::unsigned-big-32, machine_id::unsigned-big-24, proc_id::unsigned-big-16,
      counter::unsigned-big-24>>
  end

  def objectid,
    do: Base.encode16(raw_objectid(), case: :lower)

  def objectid(uuid) do
    with {:ok, _} <- UUID.info(uuid) do
      <<secs::unsigned-big-32, machine_id::unsigned-big-24, proc_id::unsigned-big-16,
        counter::unsigned-big-24, _::unsigned-big-32>> = UUID.string_to_binary!(uuid)

      <<secs::unsigned-big-32, machine_id::unsigned-big-24, proc_id::unsigned-big-16,
        counter::unsigned-big-24>>
        |> Base.encode16(case: :lower)
    else
      _ -> uuid
    end
  end

  def uuid(objectid) do
    with {:error, _} <- UUID.info(objectid) do
      objectid
      |> Base.decode16!(case: :lower)
      |> raw_objectid_to_uuid()
    else
      _ -> objectid
    end
  end

  def uuid,
    do: uuid(objectid())

  def raw_objectid_to_uuid(objectid) do
    <<secs::unsigned-big-32, machine_id::unsigned-big-24, proc_id::unsigned-big-16,
      counter::unsigned-big-24>> = objectid

    <<secs::unsigned-big-32, machine_id::unsigned-big-24, proc_id::unsigned-big-16,
      counter::unsigned-big-24, @uuid_gap_fill::unsigned-big-32>> |> UUID.binary_to_string!()
  end

  defp gen_counters(range) do
    for ix <- range do
      {ix, :rand.uniform(@counter_max) - 1}
    end
  end

  defp in_window(now) do
    secs = :calendar.datetime_to_gregorian_seconds(now)
    window = @num_counters

    rem(secs, window)
  end

  defp opposite_on_window(now) do
    secs = :calendar.datetime_to_gregorian_seconds(now)
    window = @num_counters
    half_window = div(window, 2)

    rem(secs + half_window, window)
  end

  defp machine_id do
    {:ok, hostname} = :inet.gethostname()
    <<machine_id::unsigned-big-24, _::binary>> = :crypto.hash(:md5, hostname)
    machine_id
  end

  defp process_id do
    :os.getpid() |> List.to_integer()
  end
end
