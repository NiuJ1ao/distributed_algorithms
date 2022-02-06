defmodule ERB do

  def start do
    receive do
      {:bind, c, beb} ->
        next c, beb, MapSet.new
    end
  end

  defp next c, beb, delivered do
    receive do
      {:rb_broadcast, msg} ->
        send beb, {:beb_broadcast, {:rb_data, node(), msg}}
        next c, beb, delivered

      {:beb_deliver, _from, {:rb_data, sender, msg} = rb_msg} ->
        if msg in delivered do
          next c, beb, delivered
        else
          send c, {:rb_deliver, sender, msg}
          send beb, {:beb_broadcast, rb_msg}
          next c, beb, MapSet.put(delivered, msg)
        end
    end

  end

end
